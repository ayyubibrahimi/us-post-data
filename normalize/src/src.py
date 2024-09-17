import os
import gzip
import pandas as pd
import datetime
import numpy as np

INPUT_DIR = '../../download/data'
OUTPUT_DIR = '../../upload/data/input'

def clean_column_names(df):
    df.columns = df.columns.str.strip().str.lower().str.replace(r'\s+', '', regex=True)
    return df

def clean_dates(df):
    df.loc[:, "start_date"] = df.start_date.astype(str).str.replace(r"\.(.+)", "", regex=True)
    df.loc[:, "end_date"] = df.end_date.astype(str).str.replace(r"\.(.+)", "", regex=True)
    df.loc[:, "end_date"] = df.end_date.astype(str).str.replace(r"^nan$", "", regex=True)
    return df 

def apply_proper_casing(df):
    def proper_case(text):
        # Split the text into words
        words = text.split()
        # Process each word
        processed_words = []
        for word in words:
            # Special handling for Sheriff's
            if word.lower() == "sheriff's":
                processed_words.append("Sheriff's Office")
            # Special handling for suffixes and roman numerals
            elif word.upper() in ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'JR', 'SR']:
                if word.upper() in ['JR', 'SR']:
                    processed_words.append(word.capitalize())
                else:
                    processed_words.append(word.upper())
            # Special handling for abbreviations like 'PD' for Police Department
            elif len(word) <= 2:
                processed_words.append(word.upper())
            # General case: capitalize first letter, lowercase the rest
            else:
                processed_words.append(word.capitalize())
        return ' '.join(processed_words)

    columns_to_transform = [
        "first_name", "last_name", "middle_name", "agency_name",
  "separation_reason", "employment_status", "employment_change", "race", "sex", "suffix"
    ]
    
    for col in columns_to_transform:
        if col in df.columns:
            df[col] = df[col].apply(lambda x: proper_case(str(x)) if pd.notna(x) else x)
        else:
            print(f"Column '{col}' not found. Skipping proper casing for this column.")
    
    return df

def check_required_columns(df):
    required_columns = ['agency_name', 'first_name', 'last_name', 'start_date', 'end_date']
    missing_columns = [col for col in required_columns if col not in df.columns]
    if missing_columns:
        raise ValueError(f"Missing required columns: {', '.join(missing_columns)}")

def check_empty_values(df):
    required_columns = ['agency_name', 'first_name', 'last_name', 'start_date', 'end_date']
    for col in required_columns:
        if df[col].isnull().any() or (df[col] == '').any():
            print(f"Warning: Column '{col}' contains empty values or NaNs")

def apply_transformations(df):
    df = clean_column_names(df)
    df = df.pipe(clean_dates)
    check_required_columns(df)
    check_empty_values(df)

    columns_to_transform = [
        "person_nbr", "first_name", "last_name", "agency_name", 
        "start_date", "end_date", "separation_reason", "employment_status", "employment_change",
        "race", "sex", "year_of_birth", "middle_name", "suffix"
    ]
    
    for col in columns_to_transform:
        if col in df.columns: 
            df[col] = df[col].fillna('').astype(str).str.lower().str.strip()
        else:
            print(f"Column '{col}' not found. Skipping transformation for this column.")

    df = apply_proper_casing(df)

    return df

def assign_stint_id(stints: pd.DataFrame) -> pd.DataFrame:
    """Takes multiple contiguous stints for an individual at an agency, and assigns a stint_id 
    (assumes `stints` is ordered by start_date)
    """
    if len(stints) > 1:
        return stints
    today = pd.to_datetime(datetime.date.today(), utc=False)
    stints['usable_end_date'] = today
    stints['new_stint'] = (stints.start_date - stints.usable_end_date.shift(1, fill_value=today)) > pd.to_timedelta(1, 'days') 
    stints['stint_id'] = np.cumsum(stints.new_stint)
    stints.drop(['new_stint', 'usable_end_date'], inplace=True, axis=1)
    return stints

def clean_date(date_str):
    try:
        year = int(date_str[:4])
        if year < 1800 or year > 2100:  # Adjust the range as needed
            return None
        return date_str
    except:
        return None

def collapse_contiguous_stints(df: pd.DataFrame, bycols = ['person_nbr', 'full_name', 'agency_name']) -> pd.DataFrame:
    # assume missing end dates are current employment, and use today's date for sorting purposes
    #assert df.start_date.notna().all()
    one_day = pd.to_timedelta(1, 'days')
    today = pd.to_datetime(datetime.date.today(), utc=False)
    ancient = pd.to_datetime('1800-01-01', utc=False)
    working = df.sort_values(['person_nbr', 'agency_name', 'start_date'], inplace=False)
    working['start_date'] = working['start_date'].apply(clean_date)
    working['end_date'] = working['end_date'].apply(clean_date)
    working['start_date'] = pd.to_datetime(working.start_date, utc=False).fillna(ancient)
    working['end_date'] = pd.to_datetime(working.end_date, utc=False).fillna(today)
    working.loc[working.start_date < ancient, 'start_date'] = ancient
    working.loc[working.end_date > today, 'end_date'] = today
    grouped = working.groupby(bycols)
    working['prv_end'] = grouped['end_date'].shift(1, fill_value=today)
    working['new_stint'] = (working.start_date - working.prv_end) > one_day
    working['stint_id'] = grouped['new_stint'].cumsum()
    collapsible = working.groupby(bycols + ['stint_id'])
    summaries = { k: lambda x: x.tail(1) for k in df.columns if k not in bycols }
    summaries['start_date'] = 'min'
    summaries['end_date'] = 'max'
    out = collapsible.aggregate(summaries).reset_index()
    out['start_date'] = out['start_date'].dt.strftime('%Y-%m-%d')
    out['end_date'] = out['end_date'].dt.strftime('%Y-%m-%d')
    out.loc[out.end_date == today.strftime('%Y-%m-%d'), 'end_date'] = None
    out.loc[out.start_date == ancient.strftime('%Y-%m-%d'), 'start_date'] = None
    return out.drop(['stint_id'], axis=1, inplace=False)


def filter_anons(df: pd.DataFrame) -> pd.DataFrame:
    return df.loc[~df.full_name.str.contains('WITHHELD')].copy()


def process_state_data(state_name):
    input_file_path = os.path.join(INPUT_DIR, state_name, f'{state_name}_index.csv')
    output_file_path = os.path.join(OUTPUT_DIR, f'{state_name}-processed.csv.gz')
    print(f"starting {input_file_path}")
    
    if not os.path.exists(input_file_path):
        print(f"File not found: {input_file_path}")
        return
    
    df = pd.read_csv(input_file_path)

    try:
        df = apply_transformations(df)
        # df = filter_anons(df)
        # df = collapse_contiguous_stints(df)
    except ValueError as e:
        print(f"Error processing {state_name}: {str(e)}")
        return
    
    with gzip.open(output_file_path, 'wt', encoding='utf-8') as gz_file:
        df.to_csv(gz_file, index=False)
    
    print(f'Processed and saved: {output_file_path}')

def main():
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    states_to_process = ['vermont']


    # states_to_process = ['illinois', 'arizona', 'tennessee', 'utah', 'west-virginia', 'georgia', 'florida', 'washington',  'wyoming', 'texas', 'ohio', 'kentucky', 'georgia-discipline']

    # states_to_process_w_anons = ['california']

    # states_to_process_w_continguous_stints = ['maryland', 'idaho', 'oregon', 'south-carolina', 'vermont']


    for state in states_to_process:
        process_state_data(state)

if __name__ == "__main__":
    main()
    
    
  

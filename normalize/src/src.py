import os
import gzip
import pandas as pd

INPUT_DIR = '../../download/data'
OUTPUT_DIR = '../../upload/data/input'

def clean_column_names(df):
    df.columns = df.columns.str.strip().str.lower().str.replace(r'\s+', '', regex=True)
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
    check_required_columns(df)
    check_empty_values(df)

    columns_to_transform = [
        "person_nbr", "first_name", "last_name", "agency_name", 
        "start_date", "end_date", "separation_reason", "employment_status",
        "race", "sex", "year_of_birth", "rank", "middle_name", 
    ]
    
    for col in columns_to_transform:
        if col in df.columns:
            df[col] = df[col].fillna('').astype(str).str.lower().str.strip()
        else:
            print(f"Column '{col}' not found. Skipping transformation for this column.")
    
    return df

def process_state_data(state_name):
    input_file_path = os.path.join(INPUT_DIR, state_name, f'{state_name}_index.csv')
    output_file_path = os.path.join(OUTPUT_DIR, f'{state_name}-processed.csv.gz')
    
    if not os.path.exists(input_file_path):
        print(f"File not found: {input_file_path}")
        return
    
    df = pd.read_csv(input_file_path)

    try:
        df = apply_transformations(df)
    except ValueError as e:
        print(f"Error processing {state_name}: {str(e)}")
        return
    
    with gzip.open(output_file_path, 'wt', encoding='utf-8') as gz_file:
        df.to_csv(gz_file, index=False)
    
    print(f'Processed and saved: {output_file_path}')

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    states_to_process = ['arizona', 'california', 'tennessee', 'utah', 'west-virginia', 'georgia', 'florida', 'tennessee', 'washington',  'wyoming', 'maryland', 'texas', 'ohio', 'kentucky' ]

    
    # states_to_process = ['illinois']  # Add more states as needed

    for state in states_to_process:
        process_state_data(state)

if __name__ == "__main__":
    main()
    
    
  
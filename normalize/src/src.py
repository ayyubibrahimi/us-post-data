import os
import gzip
import pandas as pd

INPUT_DIR = '../download/data'
OUTPUT_DIR = '../../upload/data/input'

def apply_transformations(df):
    # Define the columns we want to transform
    columns_to_transform = [
        "person_nbr", "first_name", "last_name", "agency_name", "start_date", "end_date", "separation_reason"
    ]
    
    # Only transform columns that exist in the dataframe
    for col in columns_to_transform:
        if col in df.columns:
            df[col] = df[col].astype(str).str.lower().str.strip()
    
    return df

def process_state_data(state_name):
    input_file_path = os.path.join(INPUT_DIR, state_name, f'{state_name}_index.csv')
    output_file_path = os.path.join(OUTPUT_DIR, f'{state_name}-processed.csv.gz')
    
    if not os.path.exists(input_file_path):
        print(f"File not found: {input_file_path}")
        return
    
    df = pd.read_csv(input_file_path)
    df = apply_transformations(df)
    
    # Check if 'separation_reason' column doesn't exist
    if 'separation_reason' not in df.columns:
        print(f"'separation_reason' column not found for {state_name}. Skipping this column.")
    
    with gzip.open(output_file_path, 'wt', encoding='utf-8') as gz_file:
        df.to_csv(gz_file, index=False)
    
    print(f'Processed and saved: {output_file_path}')

def main():
    # Ensure the output directory exists
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # List of states to process
    states_to_process = ['arizona', 'illinois', 'tennessee', 'utah', 'west-virginia']
    
    for state in states_to_process:
        process_state_data(state)

# Run the main function directly
if __name__ == "__main__":
    main()
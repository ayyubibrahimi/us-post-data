import os
import requests
import pandas as pd
import io

# Dictionary of states with their respective Dropbox links
state_links = {
    "Arizona": "https://www.dropbox.com/scl/fi/iz7qapn9k4pw5qxgmwm4v/az-2023-index-enhanced.csv?rlkey=45ftkb9f4k4xiiuoc4v12hq9e&st=bnd5oir7&dl=1",
    "California": "https://www.dropbox.com/scl/fi/pxdpyw5xo496xd6rv1quo/ca-2023-2024-index.csv?rlkey=bcgdnrpa4rcobns1xsbvrmy88&st=gpmjodc2&dl=1",
    "Florida": "https://www.dropbox.com/scl/fi/xjyscaapny8bx7h9vlibm/fl-2023-index-enhanced.csv?rlkey=hljaaklh5768gcbhry1qxjg1y&st=pky91pgw&dl=1",
    "Georgia": "https://www.dropbox.com/scl/fi/4o9gmc8jrm2ludkxbx2v6/ga-2024-enhanced-work-history.csv?rlkey=a3ykfd3s7udhueaa7yph29lg4&st=zqrfyhyq&dl=1",
    "Illinois": "https://www.dropbox.com/scl/fi/a30g6j0o5t7jf9pk4wi9j/illinois-index.csv?rlkey=6yohhjtvob5fmuxjup8cnbpp1&st=oqjizzhh&dl=1",
    "Maryland": "https://www.dropbox.com/scl/fi/685ikwoi46ek5dwrw2ekf/md-2023-index-enhanced.csv?rlkey=jzx045s9or8u4iari3btzfzbu&st=oerr2dfw&dl=1",
    "Ohio": "https://www.dropbox.com/scl/fi/6is42e5c12suu3iacu8as/oh-2023-index.csv?rlkey=2z4g8aljqyl6mov6bppvlbp51&st=1pwy64nr&dl=1",
    "Oregon": "https://www.dropbox.com/scl/fi/2thwgk4o3oeadabppus5v/or-2023-index.csv?rlkey=gftk2k0zlgmfwqzyktum9pfma&st=oso64lbz&dl=1",
    "South Carolina": "https://www.dropbox.com/scl/fi/clqckb5aje74u9r11d4ha/sc-2023-index-enhanced.csv?rlkey=q4ltth3rr7knn7dhn1f23hequ&st=bprwyxxm&dl=1",
    "Tennessee": "https://www.dropbox.com/scl/fi/umcchekukm9po2c5gcdfj/tn-2024-enhanced-work-history.csv?rlkey=3z16b466rml17qeha8zt799co&st=0fj9uju5&dl=1",
    "Texas": "https://www.dropbox.com/scl/fi/6d9a74w5hkqh4vg29qvmi/tx-2023-index-enhanced.csv?rlkey=mz79cw0yjo0qe92a318wqzqxd&st=c14wwzy9&dl=1",
    "Vermont": "https://www.dropbox.com/scl/fi/n5gb9z7nhxtxb86kf6jxg/vt-2023-index.csv?rlkey=60brq1sks5ymr5g5iolm9ar44&st=helg1pay&dl=1",
    "Washington": "https://www.dropbox.com/scl/fi/x7ctc400wd1gb32a87kkc/wa-2023-enhanced-work-history.csv?rlkey=u0dl1jtsixg2fv8sxjz0kb77s&st=8h13p1sl&dl=1",
    "West Virginia": "https://www.dropbox.com/scl/fi/5aesd3u0izcom5fh64v77/wv-2024-enhanced-work-history.csv?rlkey=olhz1vy8e2xrmjov0mi27irw6&st=njmi7vay&dl=1",
    "Utah": "https://www.dropbox.com/scl/fi/v6de7503zseqcefcms6bp/ut-2024-index.csv?rlkey=bhuwqvyp8iu02drev2pibe0ls&st=y36ma1q0&dl=1",
    "Alaska": "https://www.dropbox.com/scl/fi/pzrtdx2w5dn5jbt3o2ywr/ak-2023-index-enhanced.csv?rlkey=rx9g8mboaw42p97uunl26z7l4&st=o7wigq1t&dl=1",
}

# Directory to save the CSV files
output_dir = "data"

# Create the directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# Download and save the CSV files
for state, url in state_links.items():
    state_dir = os.path.join(output_dir, state)
    os.makedirs(state_dir, exist_ok=True)
    file_path = os.path.join(state_dir, f"{state}_index.csv")
    
    # Check if the file already exists
    if os.path.exists(file_path):
        print(f"{file_path} already exists. Skipping download.")
        continue
    
    # Download the file if it doesn't exist
    response = requests.get(url)
    response.raise_for_status()  # Ensure the download was successful
    
    # Read the CSV file into a pandas DataFrame
    csv_data = pd.read_csv(io.StringIO(response.text))
    
    # Save the DataFrame to a CSV file
    csv_data.to_csv(file_path, index=False)
    
    print(f"Saved {state} data to {file_path}")

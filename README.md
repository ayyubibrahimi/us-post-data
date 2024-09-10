# US State-level POST Dataset Analysis

*Overview*
- This repository contains scripts and notebooks for exploratory analysis of state Peace Officer Standards and Training (POST) datasets. 

*Objective*
- To analyze POST datasets from different states.
- To perform entity matching on names to identify individuals across multiple datasets.
- To provide insights and patterns that may emerge from cross-state data analysis.

## Repository Structure

```
.
├── LICENSE
├── README.md
├── bln
│   ├── AK
│   ├── AZ
│   ├── CA
│   ├── FL
│   ├── GA
│   ├── ID
│   ├── IL
│   ├── MD
│   ├── NE
│   ├── NJ
│   ├── OH
│   ├── OR
│   ├── SC
│   ├── TN
│   ├── TX
│   ├── VT
│   └── WA
├── data
│   ├── AK
│   ├── AL
│   ├── AR
│   ├── AZ
│   ├── CA
│   ├── CO
│   ├── CT
│   ├── DC
│   ├── DE
│   ├── FL
│   ├── GA
│   ├── HI
│   ├── IA
│   ├── ID
│   ├── IL
│   ├── IN
│   ├── KS
│   ├── KY
│   ├── LA
│   ├── MA
│   ├── MD
│   ├── ME
│   ├── MI
│   ├── MN
│   ├── MO
│   ├── MS
│   ├── MT
│   ├── NC
│   ├── ND
│   ├── NE
│   ├── NH
│   ├── NJ
│   ├── NM
│   ├── NV
│   ├── NY
│   ├── OH
│   ├── OK
│   ├── OR
│   ├── PA
│   ├── RI
│   ├── SC
│   ├── SD
│   ├── TN
│   ├── TX
│   ├── UT
│   ├── VA
│   ├── VT
│   ├── WA
│   ├── WI
│   ├── WV
│   ├── WY
│   └── rename_log-20231220144255.txt
├── download
│   ├── Makefile
│   ├── data
│   └── src.py
├── eda
│   ├── archive
│   ├── clean
│   ├── match
│   └── standardize
├── normalize
│   └── src
├── preprocess
│   ├── clean
│   └── download
├── requirements.txt
└── upload
    ├── Makefile
    ├── data
    ├── firebase_upload.py
```

# US State-level POST Dataset Analysis

## Directory Structure

### Main Directories

- `bln/`: Clean scripts from the BLN (Big Local News) repository, organized by state.
- `eda/`: Notebooks and scripts for exploratory data analysis.

### Pipeline Stages

#### 1. Preprocess
Location: `preprocess/`

- **Download**: 
  - Contains a directory for BLN tables.
  - Running `make` downloads available tables from the BLN repo stored in Dropbox.
  - Tables not in BLN repo/Dropbox are accessed locally.

- **Processing**:
  - Scripts for additional processing of BLN data.
  - Examples: Added separation reason data and demographic data.

- **Output**:
  - Manually upload cleaned tables to Dropbox.

#### 2. Download
Location: `download/`

- Running `make` downloads each cleaned table from Dropbox (uploaded after the preprocess stage).

#### 3. Normalize
Location: `normalize/`

- Running `make` iterates over each downloaded table for normalization.
- Example: Ensures consistent casing across data.

#### 4. Upload
Location: `upload/`

- Running `make` uploads each normalized table into Firebase storage.

## Demo

A video demonstration of the tool is available [here](https://www.dropbox.com/scl/fi/unj5cwnxspepehgf9ih3d/Georgia-without-map.mov?rlkey=hfwl05t8ain20grdafqe6jnz7&st=4m0nedbv&dl=0).

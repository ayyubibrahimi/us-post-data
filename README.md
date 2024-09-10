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

- `bln/`: Contains clean scripts from the BLN (Big Local News) repository, organized by state.
- `eda/`: Contains notebooks and scripts for exploratory data analysis.

Pipeline:
- `preprocess/`: 
1. Contains a download directory for BLN tables. Running Make downloads available the tables from the BLN repo that are stored in Dropbox. Any tables not in the BLN repo/BLN Dropbox were accessed locally. 
2. Contains scripts for additional processing of BLN data, e.g., added separation reason data and demographic data. 
3. Manually upload cleaned tables to Dropbox

- `download/`: 
1. Running Make downloads each cleaned table from Dropbox that was uploaded after the `preprocess/` stage

- `normalize/`: 
1. Running Make iterates over each table downloaded from Dropbox for normalization, e.g., consistent casing 

- `upload/`: 
1. Running Make uploads each normalized table into Firebase storage 

A video demo of the tool can be found [here](https://www.dropbox.com/scl/fi/unj5cwnxspepehgf9ih3d/Georgia-without-map.mov?rlkey=hfwl05t8ain20grdafqe6jnz7&st=4m0nedbv&dl=0).

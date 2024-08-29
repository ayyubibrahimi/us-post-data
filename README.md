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
├── requirements.txt
├── bln/
│   ├── AK/
│   ├── AZ/
│   ├── CA/
│   ├── FL/
│   ├── GA/
│   ├── ID/
│   ├── IL/
│   ├── MD/
│   ├── NE/
│   ├── NJ/
│   ├── OH/
│   ├── OR/
│   ├── SC/
│   ├── TN/
│   ├── TX/
│   ├── VT/
│   └── WA/
├── eda/
│   ├── clean/
│   ├── match/
│   └── standardize/
├── normalize/
│   ├── download/
│   └── src/
└── preprocess/
    ├── download/
    ├── eda/
    └── preprocess/
```

- `bln/`: Contains clean scripts from the BLN (Big Local News) repository, organized by state.
- `eda/`: Contains notebooks and scripts for exploratory data analysis.
- `preprocess/`: Contains scripts for additional processing of BLN data, e.g., added separation reason data and demographic data. Output has been added to dropbox. 
- `normalize/`: Contains a download directory where the dropbox links point to the output of the preprocess stage. Will contain scripts to apply consistent normalization functions across all tables, e.g., consistent casing.

A video demo of the tool can be found [here](https://www.dropbox.com/scl/fi/unj5cwnxspepehgf9ih3d/Georgia-without-map.mov?rlkey=hfwl05t8ain20grdafqe6jnz7&st=4m0nedbv&dl=0).

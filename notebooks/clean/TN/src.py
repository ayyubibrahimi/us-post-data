import pandas as pd

def read_csv():
    df = pd.read_csv("../../../data/TN/23-6-1/tn_ad-hoc-export-2023-filtered-20231220144255.csv")
    print(df)
    return df 


if __name__ == "__main__":
    read_csv()
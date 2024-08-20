import pandas as pd
import re


def read_csv():
    df_header = pd.read_csv(
        "../data/input/tn_ad-hoc-export-2023-filtered-20231220144255.csv",
        nrows=0,
    )
    first_126_columns = df_header.columns[:127]
    df = pd.read_excel(
        "../data/input/tn_ad-hoc-export-2023-filtered-20231220144255.xlsx",
        usecols=first_126_columns,
    )
    df = df[~((df["Person PSID"].fillna("") == ""))]

    original_columns = df.columns

    new_columns = [
        "Person PSID",
        "Person First Name",
        "Person Middle Name",
        "Person Last Name",
        "Person Suffix",
        "Person Gender",
        "Employment Start Date_0",
        "Employment End Date_0",
        "Employment Appointment Type_0",
        "Employment Employment Type_0",
        "Employment Title/Rank (Current)_0",
        "Employment Status_0",
        "Employment Change Reason_0",
        "Employment Change Comment_0",
        "Is Primary Employment_0",
        "Employing Organization Name_0",
        "Employing Organization ID_0",
        "Employment Start Date_1",
        "Employment End Date_1",
        "Employment Appointment Type_1",
        "Employment Employment Type_1",
        "Employment Title/Rank (Current)_1",
        "Employment Status_1",
        "Employment Change Reason_1",
        "Employment Change Comment_1",
        "Is Primary Employment_1",
        "Employing Organization Name_1",
        "Employing Organization ID_1",
        "Employment Start Date_2",
        "Employment End Date_2",
        "Employment Appointment Type_2",
        "Employment Employment Type_2",
        "Employment Title/Rank (Current)_2",
        "Employment Status_2",
        "Employment Change Reason_2",
        "Employment Change Comment_2",
        "Is Primary Employment_2",
        "Employing Organization Name_2",
        "Employing Organization ID_2",
        "Employment Start Date_3",
        "Employment End Date_3",
        "Employment Appointment Type_3",
        "Employment Employment Type_3",
        "Employment Title/Rank (Current)_3",
        "Employment Status_3",
        "Employment Change Reason_3",
        "Employment Change Comment_3",
        "Is Primary Employment_3",
        "Employing Organization Name_3",
        "Employing Organization ID_3",
        "Employment Start Date_4",
        "Employment End Date_4",
        "Employment Appointment Type_4",
        "Employment Employment Type_4",
        "Employment Title/Rank (Current)_4",
        "Employment Status_4",
        "Employment Change Reason_4",
        "Employment Change Comment_4",
        "Is Primary Employment_4",
        "Employing Organization Name_4",
        "Employing Organization ID_4",
        "Employment Start Date_5",
        "Employment End Date_5",
        "Employment Appointment Type_5",
        "Employment Employment Type_5",
        "Employment Title/Rank (Current)_5",
        "Employment Status_5",
        "Employment Change Reason_5",
        "Employment Change Comment_5",
        "Is Primary Employment_5",
        "Employing Organization Name_5",
        "Employing Organization ID_5",
        "Employment Start Date_6",
        "Employment End Date_6",
        "Employment Appointment Type_6",
        "Employment Employment Type_6",
        "Employment Title/Rank (Current)_6",
        "Employment Status_6",
        "Employment Change Reason_6",
        "Employment Change Comment_6",
        "Is Primary Employment_6",
        "Employing Organization Name_6",
        "Employing Organization ID_6",
        "Employment Start Date_7",
        "Employment End Date_7",
        "Employment Appointment Type_7",
        "Employment Employment Type_7",
        "Employment Title/Rank (Current)_7",
        "Employment Status_7",
        "Employment Change Reason_7",
        "Employment Change Comment_7",
        "Is Primary Employment_7",
        "Employing Organization Name_7",
        "Employing Organization ID_7",
        "Employment Start Date_8",
        "Employment End Date_8",
        "Employment Appointment Type_8",
        "Employment Employment Type_8",
        "Employment Title/Rank (Current)_8",
        "Employment Status_8",
        "Employment Change Reason_8",
        "Employment Change Comment_8",
        "Is Primary Employment_8",
        "Employing Organization Name_8",
        "Employing Organization ID_8",
        "Employment Start Date_9",
        "Employment End Date_9",
        "Employment Appointment Type_9",
        "Employment Employment Type_9",
        "Employment Title/Rank (Current)_9",
        "Employment Status_9",
        "Employment Change Reason_9",
        "Employment Change Comment_9",
        "Is Primary Employment_9",
        "Employing Organization Name_9",
        "Employing Organization ID_9",
        "Employment Start Date_10",
        "Employment End Date_10",
        "Employment Appointment Type_10",
        "Employment Employment Type_10",
        "Employment Title/Rank (Current)_10",
        "Employment Status_10",
        "Employment Change Reason_10",
        "Employment Change Comment_10",
        "Is Primary Employment_10",
        "Employing Organization Name_10",
        "Employing Organization ID_10",
    ]

    df = df.rename(columns=dict(zip(original_columns, new_columns)))

    id_cols = [
        "Person PSID",
        "Person First Name",
        "Person Middle Name",
        "Person Last Name",
        "Person Suffix",
        "Person Gender",
    ]

    split_rows = []

    for _, row in df.iterrows():
        for i in range(11):
            new_row = row[id_cols].tolist()

            for col in df.columns:
                if col.endswith(f"_{i}"):
                    new_row.append(row[col])

            split_rows.append(new_row)

    cols_0 = [col for col in df.columns if col.endswith("_0")]

    new_df = pd.DataFrame(
        split_rows, columns=id_cols + [col.rsplit("_", 1)[0] for col in cols_0]
    )

    return new_df


def clean_column_names(df):
    df = df.rename(
        columns={
            "Person PSID": "person_nbr",
            "Person First Name": "first_name",
            "Person Middle Name": "middle_name",
            "Person Last Name": "last_name",
            "Employing Organization Name": "agcy_name",
            "Employment Change Reason": "type",
            "Employment Title/Rank (Current)": "rank_desc",
            "Employment Start Date": "start_date",
            "Employment End Date": "end_date",
        }
    )

    df = df[
        [
            "person_nbr",
            "first_name",
            "middle_name",
            "last_name",
            "agcy_name",
            "type",
            "rank_desc",
            "start_date",
            "end_date",
        ]
    ]

    return df


def clean_names(df):
    suffixes = ["Jr", "Sr", "I", "II", "III", "IV", "V"]
    pattern = r"\b(" + "|".join(suffixes) + r")\b\.?"

    def parse_suffix(last_name):
        last_name = str(last_name)
        match = re.search(pattern, last_name, re.IGNORECASE)
        if match:
            suffix = match.group(1).upper()
            last_name = re.sub(pattern, "", last_name, flags=re.IGNORECASE).strip()
            return last_name, suffix
        return last_name, ""

    df[["last_name", "suffix"]] = df.apply(
        lambda row: parse_suffix(row["last_name"]),
        axis=1,
        result_type="expand",
    )

    df.loc[:, "first_name"] = df.first_name.str.strip().str.title()
    df.loc[:, "middle_name"] = df.middle_name.str.strip().str.title()
    df.loc[:, "last_name"] = df.last_name.str.strip().str.title()
    df.loc[:, "suffix"] = df.suffix.str.strip().str.title()

    df.loc[:, "suffix"] = df.suffix.str.replace(r"Ii", "II", regex=False).str.replace(
        r"Iii", "III", regex=False
    )
    return df


def set_full_name_col(df):
    df.loc[:, "full_name"] = (
        df.first_name.astype(str).fillna("")
        + " "
        + df.middle_name.astype(str).fillna("")
        + " "
        + df.last_name.astype(str).fillna("")
        + " "
        + df.suffix.astype(str).fillna("")
    ).str.strip()

    df.loc[:, "full_name"] = df.full_name.str.replace(
        r"\bnan\b ", "", regex=True
    ).str.title()
    return df


def clean_date_cols(df):
    df["start_date"] = pd.to_datetime(df["start_date"], errors="coerce")
    df["end_date"] = pd.to_datetime(df["end_date"], errors="coerce")

    df["start_date"] = df["start_date"].dt.date
    df["end_date"] = df["end_date"].dt.date

    df["start_date"] = df["start_date"].apply(
        lambda x: x.strftime("%Y-%m-%d") if not pd.isnull(x) else ""
    )
    df["end_date"] = df["end_date"].apply(
        lambda x: x.strftime("%Y-%m-%d") if not pd.isnull(x) else ""
    )

    df = df[~((df["start_date"] == "") & (df["end_date"] == ""))]
    return df


def clean_uids(df):
    df.loc[:, "person_nbr"] = df.person_nbr.astype(str).str.replace(
        r"^\*\*", "", regex=True
    )
    return df


def clean_agcy_name(df):
    df.loc[:, "agcy_name"] = (
        df.agcy_name.str.lower()
        .str.strip()
        .str.replace(r"^ (\w+)", r"\1", regex=True)
        .str.replace(r"(\w+) $", r"\1", regex=True)
        .str.replace(r"(.+)\btbd\b(.+)", "", regex=True)
        .str.replace(r"(.+)?fire(.+)?", "", regex=True)
        .str.replace(r"(.+) vfd-? ?(.+)?", "", regex=True)
        .str.replace(r"dept\.?", "department", regex=True)
        .str.replace(r"(\w+) \btn\b (\w+)", r"\1 tennessee \2", regex=True)
        .str.replace(r"comm\.? college", "community college", regex=True)
        .str.replace(r"^tn ", "tennesee ", regex=True)
        .str.replace(r" & ", " and ", regex=False)
        .str.replace(r"(.+)\bems\b(.+)", "", regex=True)
        .str.replace(r"(.+) em(s|a)$", "", regex=True)
        .str.replace(r" tn$", " tennesee", regex=True)
    ).str.title()

    df.loc[:, "agcy_name"] = df.agcy_name.str.replace(r"\'S", "'s", regex=True)
    return df[~((df.agcy_name.fillna("") == ""))]


def clean_rank(df):
    df.loc[:, "rank_desc"] = (
        df.rank_desc.str.lower()
        .str.strip()
        .str.replace(r"(.+)?fire(.+)?", "", regex=True)
        .str.title()
    )

    df.loc[:, "rank_desc"] = df.rank_desc.str.replace(r"\'S", "'s", regex=True)
    df = df[~((df.rank_desc.fillna("") == ""))]
    df = df.rename(columns={"rank_desc": "rank"})
    return df


def clean_type(df):
    df.loc[:, "type"] = df.type.str.replace(r"(\w+) $", r"\1", regex=True).str.title()
    return df


if __name__ == "__main__":
    df = read_csv()
    df = df.pipe(clean_column_names)

    df.to_csv("../data/processed/tn-2024-original-leo.csv", index=False)

    df = (
        df.pipe(clean_names)
        .pipe(set_full_name_col)
        .pipe(clean_date_cols)
        .pipe(clean_uids)
        .pipe(clean_agcy_name)
        .pipe(clean_rank)
        .pipe(clean_type)
    )

    enhanced_work_history = df.copy()
    enhanced_work_history.to_csv(
        "../data/processed/tn-2024-enhanced-work-history.csv", index=False
    )

    index = enhanced_work_history.copy()
    index = index.drop(columns=["type"])
    index.to_csv("../data/processed/tn-2024-index.csv", index=False)
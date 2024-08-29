import pandas as pd
import os
import re

def clean_disposition(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    """Cleans disposition columns

    Args:
        df (pd.DataFrame):
            the frame to process
        cols (list of str):
            allegation columns

    Returns:
        the updated frame
    """
    for col in cols:
        df.loc[:, col] = (
            df[col]
            .str.strip()
        )
        df = standardize_from_lookup_table(
            df,
            col,
            [
                [
                    "Negoitated Settlement",
                    "NEGOTIATED SETTLEMENT",
                ],
                ["Data Inconsistency",
                 "NULL",
                 "CHARGES DISPROVEN",
                 "DUPLICATE",
                 "INFO",
                 "ABANDONMENT",
                 "CHARGES PROVEN RESIGNED",
                 "NAT",
                 "CANCELLED",
                 "CHARGES WITHDRAWN",
                 "CHARGES PROVEN",
                 "WITHDRAWN",
                 "INVESTIGATION CANCELLED",
                 "NO VIOLATIONS OBSERVED",
                 "RECLASSIFIED AS DI-3",
                 "RECLASSIFIED AS INFO",
                 "DUI",
                 "DECEASED",
                 "Dismissal - Rule 9",
                 "DUI-Dismiss Under Invest",
                 "RETIRED UNDER INVEST.",
                 "RUI-Resigned Under Inves",
                 "RUI-Retired Under Invest",
                 "See note",
                 "Resigned",
                 "DI-3",
                 ],
                ["NFIM", "NFIM CASE",
                "DI-3 NFIM"],
                [
                    "Not Sustained",
                    "NOT SUSTAINED",
                    "NOT SUSTAINED - RUI",
                    "RUI NOT SUSTAINED",
                    "DUI-NOT SUSTAINED",
                ],
                [
                    "Pending",
                    "PENDING",
                    "PENDING INVESTIGATION",
                    "AWAITING HEARING",
                ],
                ["Sustained",
                "SUSTAINED", 
                "RUI SUSTAINED",
                "SUSTAINED - RUI",
                "SUSTAINED - DUI",
                "DUI SUSTAINED",
                "SUSTAINED - Deceased",
                "SUSTAINED - RUI - RESIGN",
                "SUSTAINED - RUI - RETIRE",
                "Sustained - Dismissed",
                "SUSTAINED-OVERTURNED",
                "SUSTAINED - Prescribed",
                "SUSTAINED"],
                ["Unfounded", "UNFOUNDED- DUI", "UNFOUNDED"],
                ["Supervisory Feedback Log", "DI-2", "RECLASSIFIED AS DI-2"],
                ["test", "Withdrawn - Mediation"]
            ],
        )
    return df


def standardize_disposition(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    """Standardizes disposition columns

    Args:
        df (pd.DataFrame):
            the frame to process
        cols (list of str):
            allegation columns

    Returns:
        the updated frame
    """
    for col in cols:
        df.loc[:, col] = (
            df[col]
            .str.strip()
            .str.replace(r"(.+)?Not Sustained(.+)?", "1", regex=True)
            .str.replace(r"(.+)?Sustained(.+)?", "0", regex=True)
        )
    ## Function should be used to generate OIPM col. All PIB ids should have the same disposition and assignment
    ## Presumably, all actions should be the same. CHECK.
    return df


def names_to_title_case(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    """Converts name columns to title case

    Args:
        df (pd.DataFrame):
            the frame to process
        cols (list of str):
            name columns

    Returns:
        the updated frame
    """
    cols_set = set(df.columns)
    for col in cols:
        if col not in cols_set:
            continue
        df.loc[:, col] = (
            df[col]
            .str.title()
            .str.replace(
                r" I(i|ii|v|x)$", lambda m: " I" + m.group(1).upper(), regex=True
            )
            .str.replace(
                r" V(i|ii|iii)$", lambda m: " V" + m.group(1).upper(), regex=True
            )
        )
    return df


def standardize_uids(df: pd.DataFrame) -> pd.DataFrame:
    """Removes spaces and unwanted characters from unique key

    Args:
        df (pd.DataFrame):
            the frame to process

    Returns:
        the updated frame
    """
    df.loc[:, "aio_num"] = (df.aio_num
                              .astype(str)
                              .str.lower()
                              .str.strip()
                              .str.replace(r"\s+", "", regex=True)
                              .str.replace(r"(\.|\,)", "", regex=True)
    )
    return df




def clean_sex(df: pd.DataFrame) -> pd.DataFrame:
    """Removes spaces and unwanted characters from unique key

    Args:
        df (pd.DataFrame):
            the frame to process

    Returns:
        the updated frame
    """

    df.loc[:, "officer_sex"] = (df.off_sex
                              .astype(str)
                              .str.strip()
                              .fillna("")
                              .str.replace(r"^F$", "Female", regex=True)
                              .str.replace(r"^M$", "Male", regex=True)
                              .str.replace(r"^$", "Unknown Sex", regex=True)
                            .str.replace(r"nan", "Unknown Sex", regex=True)
    )
    df.loc[:, "citizen_sex"] = (df.sex
                              .astype(str)
                              .str.strip()
                              .fillna("")
                              .str.replace(r"^M$", "Male", regex=True)
                              .str.replace(r"^F", "Female", regex=False)
                              .str.replace(r"^$", "Unknown Sex", regex=True)
                               .str.replace(r"nan", "Unknown Sex", regex=True)

    )
    return df


def map_race(officer_race):
    if officer_race == "White":
        return "White"
    elif officer_race == "Black":
        return "Black / African American"
    elif officer_race == "American Ind":
        return "Native American"
    elif officer_race == "Hispanic":
        return "Hispanic"
    elif officer_race == "India":
        return "Indian"
    elif officer_race == "Asian":
        return "Asian"
    else:
        return "Unknown Race"
    

def clean_race(df):
    off_race = df.off_yr_employ_off_race.str.extract(r"(\w+? ?-?\w+)$")
    df.loc[:, "officer_race"] = off_race[0]
    df["officer_race"] = df["officer_race"].apply(map_race)

    df.loc[:, "citizen_race"] = (df.race
                              .astype(str)
                              .str.strip()
                              .fillna("")
                              .str.replace(r"Hispa$", "Hispanic", regex=False)
                              .str.replace(r"^w", "White", regex=False)
                              .str.replace(r"India$", "Indian", regex=False)
                              .str.replace(r"Black", "Black / African American", regex=False)
                              .str.replace(r"Race-", "", regex=False)
                              .str.replace(r"^$", "Unknown Race", regex=True)
                              .str.replace(r"nan", "Unknown Race", regex=True)
    )

    return df 


def clean_findings(df):
    df.loc[:, "disposition"] = df.disposition.str.replace(r"(\w+) $", r"\1", regex=True)
    findings = ({
    'NEGOTIATED SETTLEMENT': 'Negotiated Settlement',
    'NULL': 'Data Inconsistency',
    'CHARGES DISPROVEN': 'Data Inconsistency',
    'DUPLICATE': 'Data Inconsistency',
    'INFO': 'Data Inconsistency',
    'ABANDONMENT': 'Data Inconsistency',
    'CHARGES PROVEN RESIGNED': 'Data Inconsistency',
    'NAT': 'Data Inconsistency',
    'CANCELLED': 'Data Inconsistency',
    'CHARGES WITHDRAWN': 'Data Inconsistency',
    'CHARGES PROVEN': 'Data Inconsistency',
    'WITHDRAWN': 'Data Inconsistency',
    'INVESTIGATION CANCELLED': 'Data Inconsistency',
    'NO VIOLATIONS OBSERVED': 'Data Inconsistency',
    'RECLASSIFIED AS DI-3': 'Data Inconsistency',
    'RECLASSIFIED AS INFO': 'Data Inconsistency',
    'DUI': 'Data Inconsistency',
    'DECEASED': 'Data Inconsistency',
    'Dismissal - Rule 9': 'Data Inconsistency',
    'DUI-Dismiss Under Invest': 'Data Inconsistency',
    'RETIRED UNDER INVEST.': 'Data Inconsistency',
    'RUI-Resigned Under Inves': 'Data Inconsistency',
    'RUI-Retired Under Invest': 'Data Inconsistency',
    'See note': 'Data Inconsistency',
    'Resigned': 'Data Inconsistency',
    'DI-3': 'Data Inconsistency',
    'DI-2': 'Data Inconsistency',
    'RUI': 'Data Inconsistency',
    'INFO ONLY CASE': 'Data Inconsistency',
    'OTHER': 'Data Inconsistency',
    'RECLASSIFIED AS DI-2': 'Data Inconsistency',
    'DUPLICATE INVESTIGATION': 'Data Inconsistency',
    'DUPLICATE ALLEGATION': 'Data Inconsistency',
    'Proscribed': 'Data Inconsistency',
    'UNFOUNDED - RUI': 'Data Inconsistency',
    'Non-Applicable': 'Data Inconsistency',
    'INFO CASE': 'Data Inconsistency',
    'DI-3': 'Data Inconsistency',
    'WITHDRAWN- MEDIATION': 'Data Inconsistency',
    'NSA - RUI': 'Data Inconsistency',
    'BWC - Redirection': 'Data Inconsistency',
    'REDIRECTION': 'Data Inconsistency',
    'Moot /Per R.S. 40:2531': 'Data Inconsistency',
    'Exonerated - RUI': 'Data Inconsistency',
    'GRIEVANCE': 'Data Inconsistency',
    'Moot/ Per R.S. 40:2531': 'Data Inconsistency',
    'REDIRECTION(SFL)': 'Data Inconsistency',
    'REDIRECTION (SFL)': 'Data Inconsistency',
    'Moot': 'Data Inconsistency',
    'EXONERATED': 'Data Inconsistency',
    'Exonerated': 'Data Inconsistency',
    'NFIM CASE': 'NFIM',
    'NFIM': 'NFIM',
    'DI-3 NFIM': 'NFIM',
    'NOT SUSTAINED': 'Not Sustained',
    'NOT SUSTAINED - RUI': 'Not Sustained',
    'RUI NOT SUSTAINED': 'Not Sustained',
    'DUI-NOT SUSTAINED': 'Not Sustained',
    'PENDING': 'Pending',
    'PENDING INVESTIGATION': 'Pending',
    'AWAITING HEARING': 'Pending',
    'SUSTAINED': 'Sustained',
    'RUI SUSTAINED': 'Sustained',
    'SUSTAINED - RUI': 'Sustained',
    'SUSTAINED - DUI': 'Sustained',
    'DUI SUSTAINED': 'Sustained',
    'SUSTAINED - Deceased': 'Sustained',
    'SUSTAINED - RUI - RESIGN': 'Sustained',
    'SUSTAINED - RUI - RETIRE': 'Sustained',
    'Sustained - Dismissed': 'Sustained',
    'SUSTAINED-OVERTURNED': 'Sustained',
    'SUSTAINED - Prescribed': 'Sustained',
    'UNFOUNDED- DUI': 'Unfounded',
    'UNFOUNDED': 'Unfounded',
    'UNFOUNDED.': 'Unfounded',
    })
    df["disposition"] = df.disposition.str.strip().map(findings)
    return df[~((df.disposition.fillna("") == ""))]




def clean_column_names(df: pd.DataFrame) -> pd.DataFrame:
    """Removes unnamed columns and convert column names to snake case

    Args:
        df (pd.DataFrame):
            the frame to process

    Returns:
        the updated frame
    """
    df = df[[col for col in df.columns if not col.startswith("Unnamed:")]]
    df.columns = [
        re.sub(r"[\s\W]+", "_", col.strip()).lower().strip("_") for col in df.columns
    ]
    return df

def set_values(df: pd.DataFrame, value_dict: dict) -> pd.DataFrame:
    """Set entire column to a value.

    Multiple columns can be specified each as a single key in value_dict

    Examples:
        >>> df = set_values(df, {
        ...     "agency": "Brusly PD",
        ...     "data_production_year": 2020
        ... })

    Args:
        df (pd.DataFrame):
            the frame to process
        value_dict (dict):
            the mapping between column name and what value should be set
            for that column.

    Returns:
        the updated frame
    """
    for col, val in value_dict.items():
        df.loc[:, col] = val
    return df


def combine_date_columns(
    df: pd.DataFrame, year_col: str, month_col: str, day_col: str
) -> pd.Series:
    """Combines date columns into a single column

    Args:
        df (pd.DataFrame):
            the frame to process
        year_col (str):
            year column
        month_col (str):
            month column
        day_col (str):
            day column

    Returns:
        the combined datetime series
    """
    dates = df[[year_col, month_col, day_col]]
    dates.columns = ["year", "month", "day"]
    return pd.to_datetime(dates, errors="coerce")

def combine_datetime_columns(
    df: pd.DataFrame, year_col: str, month_col: str, day_col: str, time_col: str
) -> pd.Series:
    """Combines datetime columns into a single column

    Args:
        df (pd.DataFrame):
            the frame to process
        year_col (str):
            year column
        month_col (str):
            month column
        day_col (str):
            day column
        time_col (str):
            time column

    Returns:
        the combined datetime series
    """
    time_frame = df[time_col].str.split(":", expand=True)
    dates = pd.concat([df[[year_col, month_col, day_col]], time_frame], axis=1)
    dates.columns = ["year", "month", "day", "hour", "minute"]
    return pd.to_datetime(dates)


def standardize_from_lookup_table(
    df: pd.DataFrame, col: str, lookup_table: list[list[str]], quiet: bool = False
) -> pd.DataFrame:
    """Standardize a column with a lookup table.

    Each entry in lookup table contains all variations of a string that need to be standardize.
    The first string in an entry is considered canonical and all variations will be replaced
    with it.

    For example with lookup table:
    [
        ...
        ["the university of sydney", "sydney uni", "university sydney"],
        ...
    ]
    The strings "sydney uni", "university sydney" will be replaced with "the university of sydney"

    This function also prints unmatched strings after a successful run

    Args:
        df (pd.DataFrame):
            the frame to process
        col (str):
            the column to standardize
        lookup_table (list of list of str):
            list of entries that need to be standardized. The first string in an entry
            is considered canonical and all subsequent strings are variations that need
            to be replaced with the canonical string.
        quiet (bool):
            if set to True then this will not print unmatched sequences

    Returns:
        the processed frame
    """
    # create list of sequences sorted by length
    table = []
    for i, seqs in enumerate(lookup_table):
        for s in seqs:
            if len(s) == 0:
                raise ValueError("empty sequence found in lookup table")
            table.append((len(s), s, i))
    table.sort(key=lambda x: x[0], reverse=True)
    sorted_lens, sorted_seqs, sorted_inds = zip(*table)

    unmatched_seqs = set()

    def find_seq(s):
        if pd.isna(s):
            return []
        seqs = []
        sub_ranges = [(0, len(s))]
        while len(sub_ranges) > 0:
            start, end = sub_ranges.pop()
            sub_str = s[start:end]
            str_len = len(sub_str)
            for start_ind, n in enumerate(sorted_lens):
                if n <= str_len:
                    break
            for i, seq in enumerate(sorted_seqs[start_ind:]):
                try:
                    pat_start_ind = sub_str.index(seq)
                    break
                except ValueError:
                    pass
            else:
                unmatched_seqs.add(sub_str)
                continue
            i = i + start_ind
            seqs.append((start + pat_start_ind, sorted_inds[i]))
            if pat_start_ind > 0:
                sub_ranges.append((start, start + pat_start_ind))
            pat_end_ind = pat_start_ind + sorted_lens[i]
            if pat_end_ind < str_len:
                sub_ranges.append((start + pat_end_ind, end))
        return [ind for _, ind in sorted(seqs, key=lambda x: x[0])]

    def join_seqs(seqs):
        return "; ".join(list(map(lambda x: lookup_table[x][0], seqs)))

    df.loc[:, col] = df[col].map(find_seq).map(join_seqs)

    if not quiet:
        print(
            "standardize_from_lookup_table: unmatched sequences:\n  %s" % unmatched_seqs
        )

    return df
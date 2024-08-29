import sys
import re
import json
from typing import List, Tuple
import pandas as pd
import numpy as np
import datetime



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


def clean_sexes(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    """Cleans and standardizes sex columns

    Args:
        df (pd.DataFrame):
            the frame to process
        cols (list of str):
            sex columns

    Returns:
        the updated frame
    """
    for col in cols:
        df.loc[:, col] = (
            df[col]
            .str.strip()
            .str.lower()
            .str.replace(r"^m$", "male", regex=True)
            .str.replace(r"^f$", "female", regex=True)
            .str.replace(r"^unknown.*", "", regex=True)
            .str.replace(r"^null$", "", regex=True)
        )
        df = standardize_from_lookup_table(
            df, col, [["male"], ["female", "femaale", "famale", "femal"]]
        )
    return df



def clean_races(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    """Cleans and standardize race columns

    Args:
        df (pd.DataFrame):
            the frame to process
        cols (list of str):
            race columns

    Returns:
        the updated frame
    """
    for col in cols:
        # replacing one-letter race because they are too short
        # to use with standardize_from_lookup_table safely
        df.loc[:, col] = (
            df[col]
            .str.strip()
            .str.lower()
            .str.replace(r"^w$", "white", regex=True)
            .str.replace(r"^h$", "hispanic", regex=True)
            .str.replace(r"^b$", "black", regex=True)
            .str.replace(r"\bislande\b", "islander", regex=True)
        )
        df = standardize_from_lookup_table(
            df,
            col,
            [
                [
                    "black",
                    "african american",
                    "black / african american",
                    "black or african american",
                    "black/african american",
                    "blk"
                ],
                ["white", "wh"],
                ["hispanic", "latino", "his"],
                [
                    "native american",
                    "american indian",
                    "american indian or alaskan native",
                    "amer. ind.",
                    "american ind",
                    "american indian/alaska native",
                    "american indian/alaskan native",
                ],
                [
                    "asian / pacific islander",
                    "asian/pacific islander",
                    "asian",
                    "native hawaiian or other pacific islander",
                    "islander",
                    "asian/pacif",
                    "as"
                ],
                ["mixed", "two or more races", "multi-racial", "2 or more races"],
                ["indian"],
                ["middle eastern"],
            ],
        )
    return df




def clean_name(series: pd.Series) -> pd.Series:
    """Cleans and standardize name series

    Args:
        series (pd.Series):
            the series to process

    Returns:
        the updated series
    """
    return (
        series.str.strip()
        .str.replace(r"[^\w-]+", " ", regex=True)
        .str.replace(r"\s+", " ", regex=True)
        .str.replace(r"\s*-\s*", "-", regex=True)
        .str.lower()
        .str.strip()
        .fillna("")
        .str.strip("-")
    )


def clean_rank(series: pd.Series) -> pd.Series:
    """Cleans and standardize name series

    Args:
        series (pd.Series):
            the series to process

    Returns:
        the updated series
    """
    return (
        series.str.strip()
        .str.replace("s/ofc", "senior officer", regex=False)
        .str.replace("sgt", "sergeant", regex=False)
        .str.replace("ofc", "officer", regex=False)
        .str.replace("lt", "lieutenant", regex=False)
        .str.replace("cpt", "captain", regex=False)
        .str.replace("a/supt", "superintendent", regex=False)
        .str.replace(r"\(|\)", " ", regex=True)
        .str.lower()
        .str.strip()
        .fillna("")
        .str.strip("-")
    )


def clean_ranks(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    """Cleans and standardize description columns

    Args:
        df (pd.DataFrame):
            the frame to process
        cols (list of str):
            descriptive columns such as rank_desc and department_desc

    Returns:
        the updated frame
    """
    for col in cols:
        df.loc[:, col] = clean_rank(df[col])
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


def clean_names(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    """Cleans and standardize name columns

    Args:
        df (pd.DataFrame):
            the frame to process
        cols (list of str):
            name columns

    Returns:
        the updated frame
    """
    for col in cols:
        df.loc[:, col] = clean_name(df[col])
    return df


name_pattern_1 = re.compile(r"^(\w{2,}) (\w\.) (\w{2,}.+)$")
name_pattern_2 = re.compile(r"^([-\w\']+), (\w{2,})$")
name_pattern_3 = re.compile(r'^(\w{2,}) ("\w+") ([-\w\']+)$')
name_pattern_4 = re.compile(r"^(\w{2,}) ([-\w\']+ (?:i|ii|iii|iv|v|jr|sr)\W?)$")
name_pattern_5 = re.compile(r"^([\w-]{2,}) (\w+) ([-\w\']+)$")
name_pattern_6 = re.compile(r"^([\w-]{2,}) ([-\w\']+)$")
name_pattern_7 = re.compile(r"^\w+$")


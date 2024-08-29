import hashlib

import pandas as pd


class InvalidEventKindException(Exception):
    pass


class InvalidEventDateException(Exception):
    pass


class NonUniqueUIDException(Exception):
    pass


class InvalidSalaryFreqException(Exception):
    pass


class HashCollisionException(Exception):
    pass



def gen_uid_from_dict(d: dict, id_keys: list[str]) -> str:
    """Generates uid (MD5 hash) of a dict from specified identifier keys

    Args:
        d (dict):
            the dictionary to process
        id_keys (list of str):
            the identifier keys

    Returns:
        the generated uid
    """
    return hashlib.md5(
        ", ".join([str(d.get(key, "")) for key in id_keys]).encode("utf-8")
    ).hexdigest()


def gen_uid(
    df: pd.DataFrame, id_cols: list[str], uid_name: str = "uid"
) -> pd.DataFrame:
    """Generates a uid (MD5 hash) column from a list of identifier columns

    Args:
        df (pd.DataFrame):
            the frame to process
        id_cols (list of str):
            the identifier columns
        uid_name: (str):
            uid column name. Defaults to "uid"

    Returns:
        the updated frame

    Raises:
        HashCollisionException:
            there's a hash collision
    """
    df.loc[:, uid_name] = (
        df[id_cols]
        .astype("str")
        .agg(", ".join, axis=1)
        .map(lambda x: hashlib.md5(x.encode("utf-8")).hexdigest())
    )
    uniq_df = df[[uid_name] + id_cols].drop_duplicates()
    if uniq_df[uid_name].duplicated().any():
        raise HashCollisionException(
            "uid hash collide!\n%s"
            % (uniq_df[uniq_df[uid_name].duplicated(keep=False)].to_string())
        )
    return df


def ensure_uid_unique(
    df: pd.DataFrame, uid_cols: list[str] or str, output_csv: bool = False
) -> None:
    """Ensures that uid columns are unique together

    Args:
        df (pd.DataFrame):
            the frame to process
        uid_cols (str or list of str):
            columns that should be unique together
        output_csv (bool):
            whether to output duplicates to data/duplicates.csv

    Returns:
        no value

    Raises:
        NonUniqueUIDException:
            there are duplicates
    """
    if type(uid_cols) == str:
        uid_cols = [uid_cols]
    if df[df[uid_cols].duplicated()].shape[0] == 0:
        return
    dup_df = (
        df[df[uid_cols].duplicated(keep=False)]
        .dropna(axis=1, how="all")
        .sort_values(uid_cols)
    )
    if output_csv:
        dup_df.to_csv(("duplicates.csv"), index=False)
        print("duplications written to data/duplicates.csv")
    raise NonUniqueUIDException("rows are not unique:\n%s" % dup_df)

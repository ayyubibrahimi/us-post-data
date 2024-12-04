# Authors: LB
# Mainrainers: LB
# Copyright:   2023, HRDAG, GPL v2 or later
# =========================================
# us-post-data/preprocess/clean/KS/import/src
import pandas as pd
from pathlib import Path
from nameparser import HumanName
import logging

# Configue the logger
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

# Create logger instance
logger = logging.getLogger(__name__)

"""
Column standard naming convention use all names that are present in dataframe.

column_names = [
    "person_nbr",
    "full_name",
    "last_name",
    "first_name",
    "middle_name",
    "middle_initial",
    "suffix",
    "birth_year",
    "age",
    "agcy_name",
    "type",
    "rank",
    "start_date",
    "end_date"]
"""

column_names = [
    "person_nbr",
    "full_name",
    "last_name",
    "first_name",
    "middle_name",
    "middle_initial",
    "suffix",
    "agcy_name",
    "rank",
    "status",
    "start_date",
    "end_date",
]


def clean_names(df):
    out = df
    hn = out.officer_name.apply(HumanName)
    out["last_name"] = hn.apply(lambda x: x.last)
    out["first_name"] = hn.apply(lambda x: x.first)
    out["middle_name"] = hn.apply(lambda x: x.middle)
    out["middle_initial"] = hn.apply(lambda x: x.middle[:1])
    out["suffix"] = hn.apply(lambda x: x.suffix)
    return out


if __name__ == "__main__":
    #   logger.info("Starting the main program")
    data_input = Path("../input/")
    complete = pd.concat(
        pd.read_excel(x, skiprows=5, usecols="c:k") for x in data_input.glob("*.xls")
    )
    complete.columns = complete.columns.str.lower()
    complete.columns = complete.columns.str.replace(" ", "_")
    new_complete = clean_names(complete)
    new_complete.drop(["unnamed:_3", "unnamed:_4"], axis=1, inplace=True)
    logger.info(new_complete[new_complete["cert_id"] == 16215])
    new_complete_2 = new_complete.copy()
    new_complete_2.drop_duplicates(inplace=True)
    logger.info(new_complete_2[new_complete_2["cert_id"] == 16215])

    logger.info(new_complete_2.columns)
    new_complete_2.rename(
        columns={
            "officer_name": "full_name",
            "officers_rank": "rank",
            "stop_or_leave_date": "end_date",
            "cert_id": "person_nbr",
            "agency_name": "agcy_name",
        },
        inplace=True,
    )
    new_complete_2 = new_complete_2.loc[:, column_names]
    logger.info(new_complete_2.columns)

# Done

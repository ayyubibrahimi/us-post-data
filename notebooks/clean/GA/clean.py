# ADD to README: 

# RANKS
# 1. the array has values for both "peace officer" and "police officer". should one be picked?
# 2. is "certified corrections officer" analagous to "sworn corrections officer"? Currently these are two distinct values in the rank 
# 3. reserve officer ranks were simplified by removing "officer" when the rank contained a higher rank. 
#    For example "reserve ofc - lt (peace ofc)" was changed to reserve lieutenant (peace officer)

# AGENCIES
# 1. agency_data-20231220144255.csv was used as the groundtruth dataset. 
# Agency data in employment-history.csv was replaced by agency_data-20231220144255.csv.
# Both datasets were nearly analagous, however, as you can see from the get_unique_fuzzy_matches function 
# there was a discrepancy in 11 rows between the datasets. 
# the chosen rows were derived from agency_data-20231220144255.csv

import pandas as pd
from fuzzywuzzy import fuzz

def read_personnel_and_employment_hist():
    df = pd.read_csv("../../../data/GA/2022-09-27/employment-history.csv")
    
    df = df.rename(columns={" NAME": "full_name", 
                            " START DATE": "start_date", 
                            " END DATE ":"end_date", 
                            "OKEY": "person_nbr",
                            " AGENCY": "agcy_name",
                            " RANK": "ofc_rank",
                            " STATUS": "type"
       
                           })
    return df


def split_names(df):
    names = df.full_name.str.title().str.strip().str.extract(r"(\w+) (\w+) ?(.+)")

    df.loc[:, "last_name"] = names[0]
    df.loc[:, "middle_name"] = names[2].str.title()
    df.loc[:, "first_name"] = names[1]

    df.loc[:, "full_name"] = df.full_name.str.title()
    return df 


def clean_per_nbr(df):
    df.loc[:, "person_nbr"] = df.person_nbr.str.lower().str.strip().str.replace(r"\s+", "", regex=True)
    return df 


def clean_rank(df):
    df.loc[:, "rank"] = (df
                             .ofc_rank
                             .str.lower()
                             .str.strip()
                             .str.replace(r"^ (\w+)", r"\1", regex=True)
                             .str.replace(r"(\w+) $", r"\1", regex=True)
                             .str.replace(r"comm\.", "communications", regex=True)
                             .str.replace(r"corr\. \/", "corrections", regex=True)
                             .str.replace(r"transfer ofc \(corr ofc certified\)", "transfer officer (certified corrrections officer)", regex=True)
                             .str.replace(r"unit manager \(corr ofc certified\)", "unit manager (certified corrections officer)", regex=True)
                             .str.replace(r"reserve ofc - lt \(peace ofc\)", "reserve lieutenant (peace officer)", regex=True)
                             .str.replace(r"(.+)? ?fire (.+)?", "", regex=True)
                             .str.replace(r" \(s\.a\.c\.\)", "", regex=True)
                             .str.replace(r"reserve ofc-lt\. col\.\(peace ofc\)", "reserve lieutenant colonel (peace officer)", regex=True)
                             .str.replace(r"\(corr ofc - sworn\)", "(sworn corrections officer)")
                             .str.replace(r"corr\. off\.", "corrections officer", regex=True)
                             .str.replace(r"ofc$", "officer", regex=True)
                             .str.replace(r"asst\.? ", "assistant ", regex=True)
                             .str.replace(r"med\.", "medical", regex=True)
                             .str.replace(r"admin\.", "administrative", regex=True)
                             .str.replace(r"reserve ofc - sgt \(peace ofc\)", "reserve sergeant (peace officer)", regex=True)
                             .str.replace(r"crime scene inv ", "crime scene investigator ", regex=True)
                             .str.replace(r"- peace ofc \(sworn\)", "(sworn peace officer)", regex=True)
                             .str.replace(r"reserve ofc - major \(peace ofc\)", "reserve major", regex=True)
                             .str.replace(r"\(corr ofc - sworn\)", "(sworn corrections officer)", regex=True)
                             .str.replace(r"part time", "part-time", regex=False)
                             .str.replace(r"\(corr ofc certified\)", "(certified corrections officer)")
                             .str.replace(r"mun\. prob\.", "municipal probation", regex=True)
                             .str.replace(r"reg\. director", "regional director", regex=True)
                             .str.replace(r"\(corr ofc certified\)", "certified corrections officer", regex=True)
                             .str.replace(r"inv\.", "investigator", regex=True)
                             .str.replace(r"reserve ofc - cpt \(peace ofc\)", "reserve captain", regex=True)
                             .str.replace(r"dep\.", "deputy", regex=True)
                             .str.replace(r"commissnr", "commissioner", regex=False)
                             .str.replace(r"comm ", "communications ", regex=False)
                             .str.replace(r"chief probation ofc", "chief probation officer", regex=False)
                             .str.replace(r"i\.d\. technician", "identification technician", regex=True)
                             .str.replace(r"gbi agent", "georgia bureau of investigation agent", regex=False)
                             .str.replace(r"(\w+)-(\w+)", r"\1 \2", regex=True)
                             .str.replace(r"non sworn", "non-sworn", regex=False)
                             .str.replace(r"part time", "part-time", regex=False)
                             .str.replace(r"(\w+)- (\w+)", r"\1-\2", regex=True)
    ).str.title()

    df.loc[:, "agcy_name"] = df.agcy_name.str.replace(r"Iii", "III", regex=False)
    return df



def read_demo_data():
    df = pd.read_csv("../../../data/GA/2022-09-27/officer_data-20231220144255.csv", encoding="latin1")

    df = df.rename(columns={" SEX": "sex", 
                            " RACE ": "race", 
                              " YOB": "birth_year", 
                              " MIDDLE": "middle_name",
                              " LAST NAME": "last_name", 
                              " FIRST NAME": "first_name",
                                "OKEY": "person_nbr",
                              })
    return df



def clean_agency(df):
    df.loc[:, "agcy_name"] = (df.agcy_name
                              .str.lower()
                              .str.strip()
                              .str.replace(r"^g(\w{4}) (.+)", r"\2", regex=True)
                              .str.replace(r" \/ (\w+)$", "", regex=True)
                              .str.replace(r" 911$", "", regex=True)
                              .str.replace(r"c\.i\.", "correctional institution", regex=True)
                              .str.replace(r"dept\.?", "department ", regex=True)
                              .str.replace(r"sheriffs", "sheriff's", regex=False)
                              .str.replace(r"dept\.$", "department", regex=True)
                              .str.replace(r"^ (\w+)", r"\1", regex=True)
                              .str.replace(r"(\w+) $", r"\1", regex=True)
                              .str.replace(r"georgia d\.n\.r\. (.+)", "georgia department of natural resources", regex=True)
                              .str.replace(r"\/(inactive|18 mos\.)$", "", regex=True)
                              .str.replace(r"l\.e\.a\.", "law enforcement academy", regex=True)
                              .str.replace(r"d\.p\.s\.", "department of public safety", regex=True)
                              .str.replace(r" \(inactive\)$", "", regex=True)
                              .str.replace(r"c\. ?i?\.?$", "correctional institution", regex=True)
                              .str.replace(r"^not found$", "", regex=True)
                              .str.replace(r" & ", " and ", regex=False)
                              .str.replace(r"juv\.justice", "juvenile justice", regex=True)
                              .str.replace(r"(\w)  (\w+)", r"\1 \2", regex=True)
                              .str.replace(r"metro\.", "metro", regex=True)
                              .str.replace(r"tech\.", "tech", regex=True)
                              .str.replace(r"^gdc ", "georgia department of corrections", regex=True)
                              .str.replace(r"d\.o\.t\.", "department of transportation", regex=True)
                              .str.replace(r"eot \(equivalency of training\)", "equivalency of training", regex=True)
                              .str.replace(r"co\. ", "county ", regex=True)
                              .str.replace(r"e?-?9-1-1", "911", regex=True)
                              .str.replace(r" ci$", "correctional institute", regex=True) 
                              .str.replace(r"cherokee co\.", "cherokee county", regex=True)
                              .str.replace(r"^ (\w+)", r"\1", regex=True)
                              .str.replace(r"(\w+) $", r"\1", regex=True)
                 
    ).str.title()

    df.loc[:, "agcy_name"] = df.agcy_name.str.replace(r"\'S", "s", regex=True)
    return df 

def extract_agcy_uid(df):
  df.loc[:, "agcy_uid"] = df.agcy_name.str.replace(r"G(\w+) (.+)", r"G\1", regex=True)
  return df 


def read_agency():
    df = pd.read_csv("../../../data/GA/2022-09-27/agency_data-20231220144255.csv", encoding="latin1")

    df = df.rename(columns={"AKEY": "agcy_name"})

    df = df[["agcy_name"]]
    return df


def clean_gt_agcy(df): 
    df.loc[:, "agcy_name"] = (df
                                    .agcy_name
                                    .str.lower()
                                    .str.strip()
                                    .str.replace(r"^ (\w+)", r"\1", regex=True)
                                    .str.replace(r"(\w+) $", r"\1", regex=True)
                                    .str.replace(r" ?\/ ?i]nactive$", "", regex=True)
                                    .str.replace(r"dept\.?", "department", regex=True)
                                    .str.replace(r"dept$", "department", regex=True)
                                    .str.replace(r"d\.n\.r\.", "department of natural resources", regex=True)
                                    .str.replace(r"^gdc", "georgia department of corrections", regex=True)
                                    .str.replace(r"c\.? ?i\.?$", "correctional institution", regex=True)
                                    .str.replace(r"d\.p\.s\.", "department of public safety", regex=True)
                                    .str.replace(r"d\.o\.t\.", "department of transportation", regex=True)
                                    .str.replace(r" ?\/ ?inactive$", "", regex=True)
                                    .str.replace(r"co\.", "county", regex=True)
                                    .str.replace(r"e - 911", "911", regex=False)
                                    .str.replace(r"&", "and", regex=False)
                                    .str.replace(r"juv\.justice", "juvenile justice", regex=True)
                                    .str.replace(r"sheriffs", "sheriff's", regex=True)
                                    .str.replace(r"tech\.", "tech", regex=True)
                                    .str.replace(r"metro\.", "metro", regex=True)
                                    .str.replace(r"standards-investigation", "standards and investigation", regex=False)
                                    .str.replace(r"(\w+)  (\w+)", r"\1 \2", regex=True)
                                    .str.replace(r"(.+)? fire (.+)?", "", regex=True)
                                    .str.replace(r"spalding co ", "spalding county ", regex=False)
                                    .str.replace(r"athens-clarke co ", "athens-clarke county ", regex=False)
                                    ).str.title()
    df.loc[:, "agcy_name"] = df.agcy_name.str.replace(r"\'S", "s", regex=True)
    return df[~((df.agcy_name.fillna("") == ""))] 


def get_unique_fuzzy_matches(df, threshold):
    # Create an empty list to store the results
    results = []
    
    # Get the unique fuzzy scores between the threshold and 100
    unique_scores = df[(df['fuzzy_score'] < 100) & (df['fuzzy_score'] >= threshold)]['fuzzy_score'].unique()
    unique_scores = sorted(unique_scores)
    
    for score in unique_scores:
        subset_df = df[df['fuzzy_score'] == score]
        agcy_name_x = subset_df['agcy_name_x'].iloc[0]
        agcy_name_y = subset_df['agcy_name_y'].iloc[0]
        results.append({'fuzzy_score': score, 'agcy_name_x': agcy_name_x, 'agcy_name_y': agcy_name_y})
    
    comparison_df = pd.DataFrame(results)
    return comparison_df

if __name__ == "__main__":
    dfa = read_personnel_and_employment_hist()
    dfa = dfa.pipe(split_names).pipe(clean_per_nbr).pipe(clean_rank)
    dfa = dfa[~((dfa.agcy_name.fillna("") == ""))]
    dfa = dfa.drop(columns=["ofc_rank"])

    dfb = read_demo_data()
    dfb = dfb.pipe(clean_per_nbr)
    dfb = dfb[["birth_year", "person_nbr"]]

    df = pd.merge(dfa, dfb, on="person_nbr")
    df = df.drop(df.columns[0], axis=1)
    df = df.pipe(extract_agcy_uid).pipe(clean_agency)

    agencies = read_agency().reset_index()
    agencies = agencies.rename(columns={"index": "agcy_uid"})
    agencies.loc[:, "agcy_uid"] = agencies.agcy_uid.str.replace(r"^ (\w+)", r"\1", regex=True).str.replace(r"(\w+) $", r"\1", regex=True)
    agencies = agencies.pipe(clean_gt_agcy)

    merged_df = pd.merge(df, agencies, on="agcy_uid")
    merged_df['fuzzy_score'] = merged_df.apply(lambda x: fuzz.ratio(x['agcy_name_x'], x['agcy_name_y']), axis=1)

    comparison_df = get_unique_fuzzy_matches(merged_df, 1)
    print(comparison_df)

    merged_df = merged_df.drop(columns=["agcy_name_x", "agcy_uid", "fuzzy_score"])
    cleaned_df = merged_df.rename(columns={"agcy_name_y": "agcy_name"})
    cleaned_df.to_csv("data/cleaned_df.csv", index=False)
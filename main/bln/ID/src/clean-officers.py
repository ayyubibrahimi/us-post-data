# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

import pandas as pd
import sys

def select_or_create_indexcols(df):
    out = df.rename(columns = {'agency': 'agcy_name',
                               'employment_classification': 'type'} )
    out['full_name'] = out.first_name + ' ' + out.last_name
    outcols = ['full_name', 'last_name', 'first_name',
               'agcy_name', 'type',
               'start_date', 'start_action',
               'end_date', 'end_action']
    return out[outcols]


def clean_dates(df):
    df.loc[df.start_date.dt.year <= 1901, 'start_date'] = None
    df.loc[df.end_date.dt.year <= 1901, 'end_date'] = None
    return df


def format_cols(df):
    out = df
    stringcols = ['full_name', 'last_name', 'first_name',
                  'agcy_name', 'type', 'start_action', 'end_action']
    datecols   = ['start_date', 'end_date']
    for col in stringcols:
        out[col] = out[col].str.upper()
    for col in datecols:
        out[col] = out[col].dt.strftime('%Y-%m-%d')
    return out


if __name__ == '__main__':
    infile  = sys.argv[1]
    output  = sys.argv[2]
    raw = pd.read_csv(infile, parse_dates=['start_date', 'end_date'])
    out = raw \
            .pipe(select_or_create_indexcols) \
            .pipe(clean_dates) \
            .pipe(format_cols) \
            .drop_duplicates()
    out.to_csv(output, index=False)


# done

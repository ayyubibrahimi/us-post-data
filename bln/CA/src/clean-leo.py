# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

import pandas as pd
import sys
import nameparser
import re

def select_or_create_indexcols(df):
    out = df.rename(columns = {'agency': 'agcy_name',
                               'post_id': 'person_nbr',
                               'employment_start_date': 'start_date',
                               'employment_end_date': 'end_date'} )
    out['type'] = 'POLICE'
    out['full_name'] = out.first_name + ' ' + out.middle_name + ' ' + out.last_name + ' ' + out.suffix
    out.full_name = out.full_name.str.replace('\s+', ' ', regex=True)
    outcols = ['person_nbr', 'full_name', 'last_name', 'first_name',
               'middle_name', 'middle_initial', 'suffix',
               'agcy_name', 'type', 'rank',
               'start_date', 'end_date']
    return out[outcols]


def clean_names(df):
    out = df
    hn = out.officer_name.apply(nameparser.HumanName)
    out['last_name']      = hn.apply(lambda x: x.last)
    out['first_name']     = hn.apply(lambda x: x.first)
    out['middle_name']    = hn.apply(lambda x: x.middle)
    out['middle_initial'] = hn.apply(lambda x: x.middle[:1])
    out['suffix']         = hn.apply(lambda x: x.suffix)
    return out


def format_cols(df):
    out = df
    stringcols = ['full_name', 'last_name', 'first_name',
                  'middle_name', 'middle_initial', 'suffix',
                  'agcy_name', 'type', 'rank']
    datecols   = ['start_date', 'end_date']
    for col in stringcols:
        out[col] = out[col].str.upper().str.strip()
    for col in datecols:
        out[col] = out[col].dt.strftime('%Y-%m-%d')
    return out


def clean_dates(df):
    out = df
    out.loc[out.end_date == '1901-01-01', 'end_date'] = None
    assert all(out.start_date.dt.year > 1901)
    assert all(out.end_date.dropna().dt.year > 1901)
    return out


if __name__ == '__main__':
    infile  = sys.argv[1]
    output  = sys.argv[2]

    raw = pd.read_csv(infile,
                      parse_dates=['employment_start_date', 'employment_end_date'])

    out = raw \
            .pipe(clean_names) \
            .pipe(select_or_create_indexcols) \
            .pipe(clean_dates) \
            .pipe(format_cols)

    out.to_csv(output, index=False)


# done

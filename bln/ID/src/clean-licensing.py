# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

import pandas as pd
import sys

def select_or_create_indexcols(df):
    out = df.rename(columns = {'level': 'certification_level'} )
    out['full_name'] = out.first_name + ' ' + out.last_name
    outcols = ['full_name', 'last_name', 'first_name',
               'certification',
               'certification_classification', 'certification_level',
               'issue_date', 'status', 'status_date']
    return out[outcols]


def format_cols(df):
    out = df
    stringcols = ['full_name', 'last_name', 'first_name',
                  'certification',
                  'certification_classification']
    datecols   = ['issue_date', 'status_date']
    for col in stringcols:
        out[col] = out[col].str.upper()
    for col in datecols:
        out[col] = pd.to_datetime(out[col], errors='coerce')
        out[col] = out[col].dt.strftime('%Y-%m-%d')
    return out


if __name__ == '__main__':
    infile  = sys.argv[1]
    output  = sys.argv[2]
    raw = pd.read_csv(infile)
    out = raw \
            .pipe(select_or_create_indexcols) \
            .pipe(format_cols) \
            .drop_duplicates()
    out.to_csv(output, index=False)


# done


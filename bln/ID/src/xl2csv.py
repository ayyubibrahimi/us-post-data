# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

import pandas as pd
import sys

def clean_colnames(df):
    df.columns = df.columns.str.lower().str.replace(' ', '_')
    return df


def read(filename):
    sheets = pd.ExcelFile(filename).sheet_names
    return pd.read_excel(filename)


if __name__ == '__main__':
    infile  = sys.argv[1]
    output  = sys.argv[2]
    out = read(filename=infile).pipe(clean_colnames)
    out.to_csv(output, index=False)


# done.

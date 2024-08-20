# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

import pandas as pd
import sys

if __name__ == '__main__':
    inleo  = sys.argv[1]
    incor  = sys.argv[2]
    outname = sys.argv[3]

    leo = pd.read_csv(inleo).reset_index(drop=True)
    cor = pd.read_csv(incor).reset_index(drop=True)
    cor.person_nbr = cor.person_nbr.astype(str)
    out = pd.concat([leo, cor])
    out.to_csv(outname, index=False)


# done

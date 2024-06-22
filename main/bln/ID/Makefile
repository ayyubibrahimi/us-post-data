# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

id2023xl  := input/id-2023-employee-public-record-report-5-23.xlsx
id2023csv := output/id-2023-original-emp+licensing.csv

indexfile := output/id-2023-index.csv
licenses  := output/id-2023-licenses.csv

.PHONY: all clean

all: $(indexfile) $(licenses) output/id-2017-original-decertified-officers.csv

clean: 
	-rm -r output/*

$(indexfile): src/clean-officers.py $(id2023csv)
	python $< $(id2023csv) $@

$(licenses): src/clean-licensing.py $(id2023csv)
	python $< $(id2023csv) $@

output/id-2017-original-decertified-officers.csv: \
	src/xl2csv.py \
	input/id-2017-decertified-officers-20170420.xls
	mkdir -p output
	python $< input/id-2017-decertified-officers-20170420.xls $@

$(id2023csv): src/xl2csv.py $(id2023xl)
	mkdir -p output
	python $< $(id2023xl) $@

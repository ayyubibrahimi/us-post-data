# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

leoxl  := input/CPRA_2024_R000304-011624.xlsx
leocsv := output/ca-2024-original-leo.csv
cleanleo := output/ca-2024-clean-leo.csv

correctionsxl  := input/PDSQ118B-C_CDCR-Appts-Seps-2005-2023_Final.xlsx
correctionscsv := output/ca-2023-original-corrections.csv
cleancorrections := output/ca-2023-clean-corrections.csv

cleanindex := output/ca-2023-2024-index.csv

.PHONY: all clean

all: $(cleanindex)

clean: 
	-rm -r output/*

$(cleanindex): src/concat-cleaned.py $(cleanleo) $(cleancorrections)
	python $< $(cleanleo) $(cleancorrections) $@

$(cleanleo): src/clean-leo.py $(leocsv)
	python $< $(leocsv) $@

$(cleancorrections): src/clean-corrections.py $(correctionscsv)
	python $< --input=$(correctionscsv) --output=$@

$(leocsv): src/xl2csv.py $(leoxl)
	mkdir -p output
	python $< \
		--input=$(leoxl) \
		--output=$@

$(correctionscsv): src/xl2csv.py $(correctionsxl)
	mkdir -p output
	python $< \
		--input=$(correctionsxl) \
		--header=6 \
		--output=$@

# done

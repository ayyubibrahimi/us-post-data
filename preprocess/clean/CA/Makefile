# Authors: LB
# Maintainers: LB, TS
# Copyright:   2025, HRDAG, GPL v2 or later
# =========================================
# us-post-data/preprocess/clean/CA/Make

officers := input/cpra-23-3241-officers.csv
employment := input/cpra-23-3241-employment.csv

.PHONY: all clean

all: output/poca_df.csv output/ca-23-index-with-sep-reason.csv

clean:
	-rm -r output/*

output/poca_df.csv: scraper/scraper.py
	mkdir -p output
	cd scraper && python scraper.py

output/ca-23-index-with-sep-reason.csv: \
	src/concat-cleaned.py \
	output/ca-23-leo-processed.csv \
	output/ca-23-corrections-processed.csv
	mkdir -p output
	python $< output/ca-23-leo-processed.csv output/ca-23-corrections-processed.csv $@

output/ca-23-leo-processed.csv: src/clean-cpra-23-3241.py $(officers) $(employment)
	mkdir -p output
	python $<

output/ca-23-corrections-processed.csv: src/clean-corrections.py output/ca-23-corrections-raw.csv
	mkdir -p output
	python $< \
		--input=output/ca-23-corrections-raw.csv \
		--output=$@

output/ca-23-corrections-raw.csv: input/PDSQ118B-C_CDCR-Appts-Seps-2005-2023_Final.xlsx src/xl2csv.py
	mkdir -p output
	python src/xl2csv.py \
		--input=$< \
		--header=6 \
		--output=$@

input/cpra-23-3241-officers.csv:
	mkdir -p input
	curl -o $@ -L "https://www.dropbox.com/scl/fi/4wsm43uau7l82otwoahb9/CPRA-23-3241-Officers.csv?rlkey=a02ovkzukt2bio40kdoiqz7ba&st=v808ijue&dl=1"

input/cpra-23-3241-employment.csv:
	mkdir -p input
	curl -o $@ -L "https://www.dropbox.com/scl/fi/o0hod3qky1mjic69t0724/CPRA-23-3241-Employment.csv?rlkey=rt0rktkj27l6suht1i6x4t76v&st=hyagcw2u&dl=1"

input/PDSQ118B-C_CDCR-Appts-Seps-2005-2023_Final.xlsx:
	mkdir -p input
	curl -o $@ -L "https://www.dropbox.com/scl/fi/wi29v2g8puc447wod9f2v/PDSQ118B-C_CDCR-Appts-Seps-2005-2023_Final.xlsx?rlkey=ujf7s1c2ox2w7m2rto1p1wg0r&st=ywlgwqrp&dl=1"

# Done

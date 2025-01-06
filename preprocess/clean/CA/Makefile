# Authors: LB
# Mainrainers: LB
# Copyright:   2024, HRDAG, GPL v2 or later
# =========================================
# us-post-data/preprocess/clean/CA/Make
#
# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:


all: output/poca_df.csv

clean: 
	-rm -r output/*

output/poca_df.csv: scraper/scraper.py
	cd scraper && python scraper.py

# Done

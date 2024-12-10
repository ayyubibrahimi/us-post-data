# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

dropbox_url := https://www.dropbox.com/scl/fo/ersykuvzt32dd7d70xd7k/APVe23r1FRoScwu6xxV6NDc?rlkey=s5md5wk85b3r7bud0j3d4zkjt&st=sz64s1v7&dl=1


.PHONY: all clean

all: output/ks-2022-index.csv

clean: 
	-rm -r output/*

output/ks-2022-index.csv: src/import.py output/downloaded-from-dropbox.done
	cd src && python import.py

output/downloaded-from-dropbox.done: input/ks.zip
	mkdir -p output
	7zz x input/ks.zip -oinput
	touch $@

input/ks.zip:
	mkdir -p input
	curl -L -o input/ks.zip "$(dropbox_url)"

# done.

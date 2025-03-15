INPUT_DIR := ../download/data/output
OUTPUT_DIR := data/output

run:
	python3 src/src.py --input-dir $(INPUT_DIR) --output-dir $(OUTPUT_DIR)

# Force reprocessing of all files
run-force:
	python3 src/src.py --input-dir $(INPUT_DIR) --output-dir $(OUTPUT_DIR) --force

clean:
	rm -rf $(OUTPUT_DIR)/*/*.csv.gz

setup:
	mkdir -p $(INPUT_DIR) $(OUTPUT_DIR)

.PHONY: run clean setup

mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

RST_OUTPUT    = $(mkfile_path)user_guide/tutorials
TUTORIALS_DIR = $(abspath $(mkfile_path)/../tutorials)
ITUTORIALS    = $(shell find $(TUTORIALS_DIR) -maxdepth 1 -name '*.ipynb')
TUTORIALS     = $(patsubst $(TUTORIALS_DIR)/%.ipynb,$(RST_OUTPUT)/%.rst, $(ITUTORIALS))

.PHONY: execute convert clear

$(RST_OUTPUT)/%.rst: $(TUTORIALS_DIR)/%.ipynb
	jupyter nbconvert --to rst --output-dir=$(@D) $<
	sed -i 's|$(HOME)|$$HOME|g' $@

convert: $(TUTORIALS)

execute:
	jupyter execute --inplace $(ITUTORIALS)

clear:
	jupyter nbconvert --clear-output --inplace $(ITUTORIALS)

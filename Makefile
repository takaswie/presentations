dirs := $(shell find . -maxdepth 1 -type d ! -path ./.git ! -path .)

.PHONY: all clean $(dirs)

all:
	@echo 'Please give one of entries in below list as a target.'
	@echo $(dirs)

clean:
	$(foreach i, $(dirs), $(MAKE) --directory=$i clean;)

$(dirs):
	$(MAKE) --directory=$@

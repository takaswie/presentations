slides := $(subst .md,.pdf,$(wildcard *.md))

.PHONY: all images clean

all: images $(slides)

images:
	$(MAKE) --directory=img

clean:
	$(RM) $(slides)
	$(MAKE) --directory=img clean

%.pdf:	%.md
	pandoc --latex-engine=lualatex -H ./header.tex $< -t beamer -o $@

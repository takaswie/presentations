slides := $(subst .md,.pdf,$(wildcard *.md))

.PHONY: all images clean

all: $(slides)

clean:
	$(RM) $(slides)

%.pdf:	%.md
	pandoc --latex-engine=lualatex -H ./header.tex $< -t beamer -o $@

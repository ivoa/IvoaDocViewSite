.SUFFIXES: .tex .md
texsource := $(shell cd src;for f in */ivoatex; do echo "$${f%/ivoatex}" ; done)
htmlsource := UWS

#find the CWD for this makefile
ROOTDIR:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
export TEXINPUTS=.:ivoatex:

SRCDIR := src
SPHINXDIR :=sphinxSource/idoc
BUILDDIR :=build
PANDCUST :=../../pandocCustomization

TEXDIRS=$(foreach t,$(texsource), $(SRCDIR)/$(t))
SPDIRS=$(foreach t,$(texsource) $(htmlsource), $(SPHINXDIR)/$(t))


ALLTEX=$(foreach t,$(texsource), $(SRCDIR)/$(t)/$(t).tex )

# do not include the html sources for now...
ALLSP=$(foreach t,$(texsource), $(SPHINXDIR)/$(t)/$(t).rst )

doSphinx: subdirs dolink_ivoatex $(ALLSP)
	sphinx-build -M html ./sphinxSource $(BUILDDIR)


subdirs: $(SPDIRS);
$(SPDIRS):
	mkdir -p $@

# this is probably gnu make 4.x specific - does not work on native MacOS (make 3.x)
# pandoc does poor job of getting relative links correct

# note that it is necessary to stop line wrapping in the pandoc translation - not sure why this is not the default for rst conversion
define pandoc_rst_template =
$$(SPHINXDIR)/$(1)/$(1).rst : $$(SRCDIR)/$(1)/$(1).tex
	make -C $$(dir $$<)
	cd $$(dir $$<);pandoc $$(notdir $$<) -f latex+raw_tex -t rst\
	  --metadata=status:$$(shell make -s -C $$(dir $$<) -f $$(ROOTDIR)/util.mak -f Makefile docIdentity)\
	   -s --wrap=none --lua-filter=$$(PANDCUST)/number-sections.lua --template=$$(PANDCUST)/default.rst\
	     > $$(ROOTDIR)/$$@
	make -C $$(dir $$<) -f $$(ROOTDIR)/util.mak -f Makefile copyRequiredFiles TODIR=$$(ROOTDIR)/$$(dir $$@)
endef

$(foreach f, $(texsource), $(eval $(call pandoc_rst_template,$(f))))

#not working
define pandoc_html_template =
$$(PREPDIR)/$(1)/$(1).md : $$(SRCDIR)/$(1)/$(1).html
	cd $$(dir $$<);pandoc $$(notdir $$<) -f html -t rst -o $$(ROOTDIR)/$$@ --extract-media=$$(ROOTDIR)/$$(dir $$@)
endef

$(foreach f, $(htmlsource), $(eval $(call pandoc_html_template,$(f))))

.PHONY: clean dolink_ivoatex restore_ivoatex clean_deps

clean:
	rm -rf $(SPHINXDIR)/*

clean_deps:
	rm -rf src/*
	git submodule update --init


# these manipulations of ivoatex subdirs are done because some projects do not get their subdirs for some reason
# also want to use single customized ivoatex
# also pandoc only looks in the cwd for tex modules
dolink_ivoatex:
	for i in $(texsource); do \
     (rm -rf $(SRCDIR)/$$i/ivoatex; cd $(SRCDIR)/$$i; ln -s ../ivoatex; ln -f -s ../ivoatex/ivoa.cls)\
     done
restore_ivoatex:
	for i in $(texsource); do \
     (rm -rf $(SRCDIR)/$$i/ivoatex; cd $(SRCDIR)/$$i; rm -f ivoa.cls; git restore ivoatex;)\
     done




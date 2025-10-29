.SUFFIXES: .tex .md
texsource := $(shell cd src;for f in */ivoatex; do echo "$${f%/ivoatex}" ; done)
htmlsource := UWS

#find the CWD for this makefile
ROOTDIR:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
export TEXINPUTS=.:ivoatex:

SRCDIR := src
SPHINXDIR := sphinxSource/idoc
PREPDIR := doc/generated
BUILDDIR := build

TEXDIRS=$(foreach t,$(texsource), $(SRCDIR)/$(t))
MDDIRS=$(foreach t,$(texsource) $(htmlsource), $(PREPDIR)/$(t))
SPDIRS=$(foreach t,$(texsource) $(htmlsource), $(SPHINXDIR)/$(t))


ALLTEX=$(foreach t,$(texsource), $(SRCDIR)/$(t)/$(t).tex )

ALLMD=$(foreach t,$(texsource) $(htmlsource), $(PREPDIR)/$(t)/$(t).md )

ALLSP=$(foreach t,$(texsource), $(SPHINXDIR)/$(t)/$(t).rst )

doSphinx: subdirs $(ALLSP)
	sphinx-build -M html ./sphinxSource $(BUILDDIR)

dosite: subdirs $(ALLMD)
	mkdocs serve

mdfiles: subdirs $(ALLMD)


subdirs: $(MDDIRS) $(SPDIRS);
$(MDDIRS) $(SPDIRS):
	mkdir -p $@

# this is probably gnu make 4.x specific - does not work on native MacOS (make 3.x)
# pandoc does poor job of getting relative links correct
define pandoc_tex_template =
$$(PREPDIR)/$(1)/$(1).md : $$(SRCDIR)/$(1)/$(1).tex
	make -C $$(dir $$<)
	cd $$(dir $$<);pandoc $$(notdir $$<) -f latex -t markdown   --extract-media=$$(ROOTDIR)/$$(dir $$@) --shift-heading-level-by=1 > $$(ROOTDIR)/$$@
endef

$(foreach f, $(texsource), $(eval $(call pandoc_tex_template,$(f))))

define pandoc_rst_template =
$$(SPHINXDIR)/$(1)/$(1).rst : $$(SRCDIR)/$(1)/$(1).tex
	make -C $$(dir $$<)
	cd $$(dir $$<);pandoc $$(notdir $$<) -f latex -t rst --metadata=title:$(1) --extract-media=$$(ROOTDIR)/$$(dir $$@) > $$(ROOTDIR)/$$@
endef

$(foreach f, $(texsource), $(eval $(call pandoc_rst_template,$(f))))


define pandoc_html_template =
$$(PREPDIR)/$(1)/$(1).md : $$(SRCDIR)/$(1)/$(1).html
	cd $$(dir $$<);pandoc $$(notdir $$<) -f html -t markdown -o $$(ROOTDIR)/$$@ --extract-media=$$(ROOTDIR)/$$(dir $$@)
endef

$(foreach f, $(htmlsource), $(eval $(call pandoc_html_template,$(f))))

.PHONY: clean dolink_ivoatex restore_ivoatex

clean:
	rm -rf $(PREPDIR)/* $(SPHINXDIR)/*

dolink_ivoatex:
	for i in $(texsource); do \
     (rm -rf $(SRCDIR)/$$i/ivoatex; cd $(SRCDIR)/$$i; ln -s ../ivoatex;)\
     done
restore_ivoatex:
	for i in $(texsource); do \
     (rm -rf $(SRCDIR)/$$i/ivoatex; cd $(SRCDIR)/$$i; git restore ivoatex;)\
     done

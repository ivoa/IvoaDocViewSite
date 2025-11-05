print-%  : ; @echo $* = $($*)

.PHONY: docIdentity copyRequiredFiles

docIdentity: ; @echo \"$(DOCNAME) $(DOCVERSION) $(DOCTYPE) $(DOCDATE)\"

docMeta.yaml: Makefile
	echo "DOCNAME": $(DOCNAME) > $@
	echo "DOCVERSION": $(DOCVERSION)>> $@
	echo "DOCTYPE": $(DOCTYPE)>> $@
	echo "DOCDATE": $(DOCDATE)>> $@
	echo "status": $(DOCNAME) $(DOCVERSION) $(DOCTYPE) $(DOCDATE) >> $@


# this is trying to be specific
ALL_FILES_TO_COPY=$(filter-out %.tex,$(SOURCES)) $(FIGURES) $(VECTORFIGURES)
copyRequiredFiles:
	if [ -n "$(strip $(ALL_FILES_TO_COPY))" ]; then cp -R $(ALL_FILES_TO_COPY) $(TODIR); fi




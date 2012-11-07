# Copyright (C) The IETF Trust (2012)
#

YEAR=`date +%Y`
MONTH=`date +%B`
DAY=`date +%d`
PREVVERS=00
VERS=00
XML2RFC=xml2rfc.tcl
DRAFT_BASE=draft-haynes-nfsv4-minorversioning
DOC_PREFIX=minorv

autogen/%.xml : %.x
	@mkdir -p autogen
	@rm -f $@.tmp $@
	@cat $@.tmp | sed 's/^\%//' | sed 's/</\&lt;/g'| \
	awk ' \
		BEGIN	{ print "<figure>"; print" <artwork>"; } \
			{ print $0 ; } \
		END	{ print " </artwork>"; print"</figure>" ; } ' \
	| expand > $@
	@rm -f $@.tmp

all: html txt

#
# Build the stuff needed to ensure integrity of document.
common: testx html

txt: ${DRAFT_BASE}-$(VERS).txt

html: ${DRAFT_BASE}-$(VERS).html

nr: ${DRAFT_BASE}-$(VERS).nr

xml: ${DRAFT_BASE}-$(VERS).xml

clobber:
	$(RM) ${DRAFT_BASE}-$(VERS).txt \
		${DRAFT_BASE}-$(VERS).html \
		${DRAFT_BASE}-$(VERS).nr
	export SPECVERS := $(VERS)
	export VERS := $(VERS)

clean:
	rm -f $(AUTOGEN)
	rm -rf autogen
	rm -f ${DRAFT_BASE}-$(VERS).xml
	rm -rf draft-$(VERS)
	rm -f draft-$(VERS).tar.gz
	rm -rf testx.d
	rm -rf draft-tmp.xml

# Parallel All
pall: 
	$(MAKE) xml
	( $(MAKE) txt ; echo .txt done ) & \
	( $(MAKE) html ; echo .html done ) & \
	wait

${DRAFT_BASE}-$(VERS).txt: ${DRAFT_BASE}-$(VERS).xml
	rm -f $@ draft-tmp.txt
	$(XML2RFC) ${DRAFT_BASE}-$(VERS).xml draft-tmp.txt
	mv draft-tmp.txt $@

${DRAFT_BASE}-$(VERS).html: ${DRAFT_BASE}-$(VERS).xml
	rm -f $@ draft-tmp.html
	$(XML2RFC) ${DRAFT_BASE}-$(VERS).xml draft-tmp.html
	mv draft-tmp.html $@

${DRAFT_BASE}-$(VERS).nr: ${DRAFT_BASE}-$(VERS).xml
	rm -f $@ draft-tmp.nr
	$(XML2RFC) ${DRAFT_BASE}-$(VERS).xml $@.tmp
	mv draft-tmp.nr $@

${DOC_PREFIX}_front_autogen.xml: ${DOC_PREFIX}_front.xml Makefile
	sed -e s/DAYVAR/${DAY}/g -e s/MONTHVAR/${MONTH}/g -e s/YEARVAR/${YEAR}/g < ${DOC_PREFIX}_front.xml > ${DOC_PREFIX}_front_autogen.xml

${DOC_PREFIX}_rfc_start_autogen.xml: ${DOC_PREFIX}_rfc_start.xml Makefile
	sed -e s/DRAFTVERSION/${DRAFT_BASE}_${VERS}/g < ${DOC_PREFIX}_rfc_start.xml > ${DOC_PREFIX}_rfc_start_autogen.xml

AUTOGEN =	\
		${DOC_PREFIX}_front_autogen.xml \
		${DOC_PREFIX}_rfc_start_autogen.xml

START_PREGEN = ${DOC_PREFIX}_rfc_start.xml
START=	${DOC_PREFIX}_rfc_start_autogen.xml
END=	${DOC_PREFIX}_rfc_end.xml

FRONT_PREGEN = ${DOC_PREFIX}_front.xml

IDXMLSRC_BASE = \
	${DOC_PREFIX}_middle_start.xml \
	${DOC_PREFIX}_middle_introduction.xml \
	${DOC_PREFIX}_middle_iana.xml \
	${DOC_PREFIX}_middle_end.xml \
	${DOC_PREFIX}_back_front.xml \
	${DOC_PREFIX}_back_references.xml \
	${DOC_PREFIX}_back_acks.xml \
	${DOC_PREFIX}_back_back.xml

IDCONTENTS = ${DOC_PREFIX}_front_autogen.xml $(IDXMLSRC_BASE)

IDXMLSRC = ${DOC_PREFIX}_front.xml $(IDXMLSRC_BASE)

draft-tmp.xml: $(START) Makefile $(END)
		rm -f $@ $@.tmp
		cp $(START) $@.tmp
		chmod +w $@.tmp
		for i in $(IDCONTENTS) ; do echo '<?rfc include="'$$i'"?>' >> $@.tmp ; done
		cat $(END) >> $@.tmp
		mv $@.tmp $@

${DRAFT_BASE}-$(VERS).xml: draft-tmp.xml $(IDCONTENTS) $(AUTOGEN)
		rm -f $@
		cp draft-tmp.xml $@

genhtml: Makefile gendraft html txt draft-$(VERS).tar
	./gendraft draft-$(PREVVERS) \
		${DRAFT_BASE}-$(PREVVERS).txt \
		draft-$(VERS) \
		${DRAFT_BASE}-$(VERS).txt \
		${DRAFT_BASE}-$(VERS).html \
		${DRAFT_BASE}-dot-x-04.txt \
		${DRAFT_BASE}-dot-x-05.txt \
		draft-$(VERS).tar.gz

testx: 
	rm -rf testx.d
	mkdir testx.d
	( cd testx.d ; \
		rpcgen -a ${DOC_PREFIX}.x ; \
		$(MAKE) -f make* )

spellcheck: $(IDXMLSRC)
	for f in $(IDXMLSRC); do echo "Spell Check of $$f"; spell +dictionary.txt $$f; done

AUXFILES = \
	dictionary.txt \
	gendraft \
	Makefile \
	errortbl \
	rfcdiff \
	xml2rfc_wrapper.sh \
	xml2rfc

DRAFTFILES = \
	${DRAFT_BASE}-$(VERS).txt \
	${DRAFT_BASE}-$(VERS).html \
	${DRAFT_BASE}-$(VERS).xml

draft-$(VERS).tar: $(IDCONTENTS) $(START_PREGEN) $(FRONT_PREGEN) $(AUXFILES) $(DRAFTFILES)
	rm -f draft-$(VERS).tar.gz
	tar -cvf draft-$(VERS).tar \
		$(START_PREGEN) \
		$(END) \
		$(FRONT_PREGEN) \
		$(IDCONTENTS) \
		$(AUXFILES) \
		$(DRAFTFILES) \
		gzip draft-$(VERS).tar

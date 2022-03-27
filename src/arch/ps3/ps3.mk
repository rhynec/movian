.DEFAULT_GOAL := ${PROG}

#
# Source modification and extra flags
#
SRCS += src/arch/ps3/ps3_main.c \
	src/arch/ps3/ps3_threads.c \
	src/arch/ps3/ps3_trap.c \
	src/arch/ps3/ps3_vdec.c \
	src/arch/ps3/ps3_audio.c \
	src/arch/ps3/ps3_tlsf.c \
	src/arch/ps3/ps3_webpopup.c \
	src/networking/net_psl1ght.c \
	src/networking/asyncio_posix.c \
	src/fileaccess/fa_funopen.c \
	src/fileaccess/fa_fs.c \

SRCS += src/htsmsg/persistent_file.c

#
# Install
#

SFO := $(PSL1GHT)/host/bin/sfo.py
PKG := $(PSL1GHT)/host/bin/pkg.py
MAKE_SELF := $(PSL1GHT)/host/bin/make_self
MAKE_SELF_NPDRM := $(PSL1GHT)/host/bin/make_self_npdrm
SPRXLINKER := $(PSL1GHT)/host/bin/sprxlinker
PACKAGE_FINALIZE := $(PSL1GHT)/host/bin/package_finalize

ICON0 := $(TOPDIR)/support/ps3icon.png
PIC1 := $(TOPDIR)/support/ps3gb.png
APPID		:=	HP0MOVIAN
CONTENTID	:=	UP0001-$(APPID)_00-0000000000000000

SFOXML          := $(TOPDIR)/support/sfo.xml

EBOOT=${BUILDDIR}/EBOOT.BIN

ELF=${BUILDDIR}/${APPNAME}.elf
SELF=${BUILDDIR}/${APPNAME}.self
SYMS=${BUILDDIR}/${APPNAME}.syms
ZS=${BUILDDIR}/${APPNAME}.zs

$(BUILDDIR)/pkg/PARAM.SFO: $(SFOXML)
	$(SFO) --title "$(APPNAMEUSER)" --appid "$(APPID)" -f $< $@


${EBOOT}: support/ps3/eboot.c src/arch/ps3/ps3.mk
	$(CC) $(CFLAGS_com) $(CFLAGS) $(CFLAGS_cfg)  -o $@ $< ${LDFLAGS_EBOOT}
	${STRIP} $@
	${SPRXLINKER} $@

${ELF}: ${BUILDDIR}/${APPNAME}.ziptail src/arch/ps3/ps3.mk
	${STRIP} -o $@ $<
	${SPRXLINKER} $@

${SYMS}: ${BUILDDIR}/${APPNAME}.ziptail src/arch/ps3/ps3.mk
	${OBJDUMP} -t -j .text $< | awk '{print $$1 " " $$NF}'|sort >$@

${ZS}:  ${BUILDDIR}/zipbundles/bundle.zip ${SYMS} src/arch/ps3/ps3.mk
	cp $< $@
	zip -9j ${ZS} ${SYMS}

${SELF}: ${ELF} ${ZS} src/arch/ps3/ps3.mk
	${MAKE_SELF} $< $@
	cat ${ZS} >>$@

$(BUILDDIR)/pkg/USRDIR/${APPNAME}.self: ${SELF}  src/arch/ps3/ps3.mk
	cp $< $@

$(BUILDDIR)/pkg/USRDIR/EBOOT.BIN: ${EBOOT}  src/arch/ps3/ps3.mk
	@mkdir -p $(BUILDDIR)/pkg/USRDIR
	${MAKE_SELF_NPDRM} $< $@ $(CONTENTID)

$(BUILDDIR)/${APPNAME}.pkg: $(BUILDDIR)/pkg/USRDIR/EBOOT.BIN $(BUILDDIR)/pkg/USRDIR/${APPNAME}.self $(BUILDDIR)/pkg/PARAM.SFO
	cp $(ICON0) $(BUILDDIR)/pkg/ICON0.PNG
	cp $(PIC1) $(BUILDDIR)/pkg/PIC1.PNG
	$(PKG) --contentid $(CONTENTID) $(BUILDDIR)/pkg/ $@

$(BUILDDIR)/${APPNAME}_geohot.pkg: $(BUILDDIR)/${APPNAME}.pkg  src/arch/ps3/ps3.mk
	cp $< $@
	${PACKAGE_FINALIZE} $@

pkg: $(BUILDDIR)/${APPNAME}.pkg $(BUILDDIR)/${APPNAME}_geohot.pkg
self: ${SELF}

install: $(BUILDDIR)/${APPNAME}.pkg
	cp $< $(PS3INSTALL)/${APPNAME}.pkg
	sync

$(BUILDDIR)/dist/${APPNAME}-$(VERSION).self: ${SELF}
	@mkdir -p $(dir $@)
	cp $< $@

$(BUILDDIR)/dist/${APPNAME}-$(VERSION).pkg: $(BUILDDIR)/${APPNAME}.pkg
	@mkdir -p $(dir $@)
	cp $< $@

$(BUILDDIR)/dist/${APPNAME}_geohot-$(VERSION).pkg: $(BUILDDIR)/${APPNAME}_geohot.pkg
	@mkdir -p $(dir $@)
	cp $< $@

dist:  $(BUILDDIR)/dist/${APPNAME}-$(VERSION).self $(BUILDDIR)/dist/${APPNAME}-$(VERSION).pkg $(BUILDDIR)/dist/${APPNAME}_geohot-$(VERSION).pkg

upgrade: ${SELF}
	curl --data-binary @$< http://$(PS3HOST):42000/showtime/replace

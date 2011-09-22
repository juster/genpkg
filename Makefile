TWEAKS = $(PWD)/tweaks
PKGS = $(PWD)/pkg
BIN = $(PWD)/bin
PKGVAR = $(PWD)/var

.PHONY: checkpkgarg package tweakmeta PKGBUILD

package: $(PKGS)/$(PKG)/PKGBUILD
#	cd "$(PKGS)/$(PKG)"; makepkg --clean

PKGBUILD: $(PKGS)/$(PKG)/PKGBUILD

$(PKGS)/$(PKG)/PKGBUILD: tweakmeta
	@cd '$(PKGS)/$(PKG)'; \
	TDIR='$(BIN)/templ' $(BIN)/makepkgbuild
	@echo 'Built pkg/$(PKG)/PKGBUILD.'

tweakmeta: $(PKGS)/$(PKG)/PKGMETA
	@if [ -r '$(TWEAKS)/$(PKG)' ]; \
	then \
		cd '$(PKGS)/$(PKG)'; \
		$(BIN)/tweakmeta >PKGMETA.new <'$(TWEAKS)/$(PKG)'; \
		mv PKGMETA PKGMETA.old; \
		mv PKGMETA.new PKGMETA; \
		echo 'Tweaked PKGMETA with tweaks/$(PKG)'; \
	fi

$(PKGS)/$(PKG)/PKGMETA: prepare
	@[ -d '$(PKGS)/$(PKG)' ] || mkdir '$(PKGS)/$(PKG)'
	@cd '$(PKGS)/$(PKG)'; \
		PATH="$$PATH:$(BIN)" METABIN="$(BIN)/metas" \
		PKGVAR="$(PKGVAR)" \
		$(BIN)/makepkgmeta $(PKG) >PKGMETA
	@echo 'Created pkg/$(PKG)/PKGMETA.'

prepare:
	@case '$(PKG)' in \
	'') echo 'error: Specify the package name in the PKG variable.' 1>&2 ;\
	   false ;; \
	esac
	@[ -d var ] || mkdir var


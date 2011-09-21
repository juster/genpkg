TWEAKS = $(PWD)/tweaks
PKGS = $(PWD)/pkg
BIN = $(PWD)/bin
PKGVAR = $(PWD)/var

.PHONY: checkpkgarg package tweakmeta

package: $(PKGS)/$(PKG)/PKGBUILD
#	cd "$(PKGS)/$(PKG)"; makepkg --clean

$(PKGS)/$(PKG)/PKGBUILD: tweakmeta

tweakmeta: $(PKGS)/$(PKG)/PKGMETA
	@if [ -r '$(TWEAKS)/$(PKG)' ]; \
	then \
		cd '$(PKGS)/$(PKG)'; \
		$(BIN)/tweakmeta >PKGMETA.new <'$(TWEAKS)/$(PKG)'; \
		mv PKGMETA PKGMETA.old; \
		mv PKGMETA.new PKGMETA; \
	fi

$(PKGS)/$(PKG)/PKGMETA: prepare
	@rm -rf tmp
	@mkdir tmp
	@cd tmp; \
		PATH="$$PATH:$(BIN)" METABIN="$(BIN)/metas" \
		PKGVAR="$(PKGVAR)" \
		$(BIN)/makepkgmeta $(PKG) >PKGMETA
	@rm -rf "$(PKGS)/$(PKG)"
	@mv tmp "$(PKGS)/$(PKG)"
	@echo 'Created pkg/$(PKG)/PKGMETA.'

prepare:
.ifndef PKG
	@echo 'error: Specify the package name in the PKG variable.' 1>&2
	@false
.endif

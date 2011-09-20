TWEAKS = $(PWD)/tweaks
PKGS = $(PWD)/pkg
BIN = $(PWD)/bin
PKGVAR = $(PWD)/var

.PHONY: checkpkgarg package tweakmeta

package: $(PKGS)/$(PKG)/PKGBUILD
#	cd "$(PKGS)/$(PKG)"; makepkg --clean

$(PKGS)/$(PKG)/PKGBUILD: tweakmeta

tweakmeta: $(PKGS)/$(PKG)/PKGMETA

$(PKGS)/$(PKG)/PKGMETA: checkpkgarg
	@rm -rf tmp
	@mkdir tmp
	@cd tmp; \
		PATH="$$PATH:$(BIN)" METABIN="$(BIN)/metas" PKGVAR="$(PKGVAR)" \
		$(BIN)/makepkgmeta $(PKG) >PKGMETA
	@rm -rf "$(PKGS)/$(PKG)"
	@mv tmp "$(PKGS)/$(PKG)"
	@echo 'Created $@.'

checkpkgarg:
.ifndef PKG
	@echo 'error: Specify the package name in the PKG variable.' 1>&2
	@false
.endif

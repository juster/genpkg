usage:
	@echo 'Run "make install" to install into your home directory.'
	@echo 'Run "make install_tweaks" to install tweak files, too.'

install:
	mkdir -p $$HOME/bin
	install -m 755 bin/makepkgbuild bin/makepkgmeta bin/genpkg \
		bin/tweakmeta $$HOME/bin
	mkdir -p $$HOME/lib/genpkg/
	cp -R lib/* $$HOME/lib/genpkg/
	mkdir -p $$HOME/pkg/dest

install_tweaks:
	-mkdir $$HOME/pkg
	cp -R tweaks $$HOME/pkg/

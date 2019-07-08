.POSIX:

BUNDLE = bundle
SFNTLY = https://github.com/googlei18n/sfntly
SFNT2WOFF = https://github.com/bramstein/sfnt2woff

dry: _staging
	rm -Rf _site
	mkdir -p _site
	$(BUNDLE) exec jekyll build

	rsync -a --delete _site _staging
	git -C _staging diff --cached --quiet
	git -C _staging add _site

examine: _staging
	git -C _staging diff --cached

deploy: _staging _production
	git -C _staging commit --allow-empty --allow-empty-message -m ''
	git -C _production pull

reject: _staging
	git -C _staging reset --hard

assets: helper/font.sh
	> _sass/fonts.scss printf '@import "font";\n'
	>> _sass/fonts.scss helper/font.sh cmunrm.woff 'CMU Serif' normal normal
	>> _sass/fonts.scss helper/font.sh cmunti.woff 'CMU Serif' normal italic
	>> _sass/fonts.scss helper/font.sh cmunbx.woff 'CMU Serif' bold normal
	>> _sass/fonts.scss helper/font.sh cmunbi.woff 'CMU Serif' bold italic
	>> _sass/fonts.scss helper/font.sh cmuntt.woff 'CMU Typewriter Text' normal normal
	>> _sass/fonts.scss helper/font.sh Symbola.ttf 'Symbola' normal normal

helper/font.sh: helper/sfntly/fontinfo.jar
helper/font.sh: helper/sfntly/sfnttool.jar
helper/font.sh: helper/sfnt2woff/woff2sfnt

helper/sfntly/fontinfo.jar:
	set -eu; \
	old=$$(pwd); \
	scratch=$$(mktemp -d); \
	cd $$scratch; \
	git clone $(SFNTLY); \
	cd sfntly; \
	git checkout 9620b607af5b796badefebcf16d7ce6e6786f205; \
	cd java; \
	ant; \
	cp dist/tools/fontinfo/fontinfo.jar $$old/$@; \
	cd $$old; \
	rm -Rf $$scratch

helper/sfntly/sfnttool.jar:
	set -eu; \
	old=$$(pwd); \
	scratch=$$(mktemp -d); \
	cd $$scratch; \
	git clone $(SFNTLY); \
	cd sfntly; \
	git checkout 9620b607af5b796badefebcf16d7ce6e6786f205; \
	cd java; \
	ant; \
	cp dist/tools/sfnttool/sfnttool.jar $$old/$@; \
	cd $$old; \
	rm -Rf $$scratch

helper/sfnt2woff/woff2sfnt:
	set -eu; \
	old=$$(pwd); \
	scratch=$$(mktemp -d); \
	cd $$scratch; \
	git clone $(SFNT2WOFF); \
	cd sfnt2woff; \
	git checkout b4098d5dda521f369008f5c62a6e2388611c0725; \
	> Makefile. < Makefile tr '<' '?'; \
	mv Makefile. Makefile; \
	> Makefile. < Makefile sed 's/ woff[.]h / /'; \
	mv Makefile. Makefile; \
	> Makefile. < Makefile sed 's/ woff-private[.]h / /'; \
	mv Makefile. Makefile; \
	> Makefile. < Makefile sed 's/ Makefile$$//'; \
	mv Makefile. Makefile; \
	> Makefile. < Makefile sed 's/ woff[.]o -lz$$/ -lz/'; \
	mv Makefile. Makefile; \
	make; \
	cp woff2sfnt $$old/$@; \
	cd $$old; \
	rm -Rf $$scratch

_staging:
	mkdir -p -- '$@'
	cd -- '$@' && git init

_production:
	git clone _staging _production

.PHONY: dry examine deploy reject assets

.POSIX:

BUNDLE = bundle

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
	>> _sass/fonts.scss helper/font.sh Inconsolata@3.001,wdth,wght.ttf 'Inconsolata' normal normal
	>> _sass/fonts.scss helper/font.sh monof55.ttf 'monofur' normal normal
	>> _sass/fonts.scss helper/font.sh Symbola.ttf 'Symbola' normal normal
	>> _sass/fonts.scss helper/font.sh NotoNaskhArabic-Regular.ttf 'Noto Naskh Arabic' normal normal
	>> _sass/fonts.scss helper/font.sh NotoSansSC-Regular.otf 'Noto Sans SC' normal normal
	>> _sass/fonts.scss helper/font.sh SourceSerifPro-Regular.ttf 'Source Serif Pro' normal normal
	>> _sass/fonts.scss helper/font.sh SourceSerifPro-Italic.ttf 'Source Serif Pro' normal italic
	>> _sass/fonts.scss helper/font.sh SourceSerifPro-Bold.ttf 'Source Serif Pro' bold normal
	>> _sass/fonts.scss helper/font.sh SourceSerifPro-BoldItalic.ttf 'Source Serif Pro' bold italic
	>> _sass/fonts.scss helper/font.sh Atkinson-Hyperlegible-Regular-102.ttf 'Atkinson Hyperlegible' normal normal
	>> _sass/fonts.scss helper/font.sh Atkinson-Hyperlegible-Italic-102.ttf 'Atkinson Hyperlegible' normal italic
	>> _sass/fonts.scss helper/font.sh Atkinson-Hyperlegible-Bold-102.ttf 'Atkinson Hyperlegible' bold normal
	>> _sass/fonts.scss helper/font.sh Atkinson-Hyperlegible-BoldItalic-102.ttf 'Atkinson Hyperlegible' bold italic
	>> _sass/fonts.scss helper/font.sh Comic_Sans_MS.ttf 'Comic Sans MS' normal normal
	>> _sass/fonts.scss helper/font.sh Comic_Sans_MS_Bold.ttf 'Comic Sans MS' bold normal

init: helper/.venv helper/requirements.txt
	. helper/.venv/bin/activate && pip install -r helper/requirements.txt
	cd helper && npm install

init-clean:
	rm -Rf helper/.venv
	rm -Rf helper/node_modules

_staging:
	mkdir -p -- '$@'
	cd -- '$@' && git init

_production:
	git clone _staging _production

helper/.venv:
	python3 -m venv -- '$@'

.PHONY: dry examine deploy reject assets init init-clean

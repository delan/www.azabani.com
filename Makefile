.POSIX:

BUNDLE = bundle

dry: _staging
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

_staging:
	mkdir -p -- '$@'
	cd -- '$@' && git init

_production:
	git clone _staging _production

.PHONY: dry examine deploy reject

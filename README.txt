Welcome! You’ll need:

• Nix and one of the following
  • nix-shell [--pure]
  • direnv allow
• or your own environment with
  • make(1) + git(1) + rsync(1) + less(1)
  • Ruby 2.1+
  • Bundler: gem install bundler
  • Python 3.5+ (for make assets)
  • Node.js 10+ (for make assets)

# install dependencies
bundle install
make [init-clean] init

# spin up a dev server
bundle exec jekyll serve

# compile (jekyll always, soupault only if needed)
make [BUNDLE=bundle24]

# compile and stage
# you must deploy or reject any previous changes first
make [BUNDLE=bundle24] dry

# examine staging area
make examine

# deploy to production
make deploy

# reject staged changes
make reject

# recompile assets
make assets

# recompile soupault
make soupault

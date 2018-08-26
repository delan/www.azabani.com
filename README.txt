# install dependencies
gem install bundler
bundle install

# compile the site
bundle exec jekyll build

# spin up a dev server
bundle exec jekyll serve

# compile and stage
make # BUNDLE=bundle24

# examine staging area
make examine

# deploy to production
make deploy

# reject staged changes
make reject

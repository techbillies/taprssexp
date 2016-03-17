
_site:
	rbenv global 2.2.3
	bundle exec planet generate
	bundle exec jekyll build

clean:
	rm -rf ./_site

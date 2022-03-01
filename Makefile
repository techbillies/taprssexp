public:
	bundle exec planet generate --extension html
	bundle exec jekyll build

clean:
	rm -rf ./public

serve:
	bundle exec jekyll serve
public:
	bundle exec planet generate
	bundle exec jekyll build

clean:
	rm -rf ./public

serve:
	bundle exec jekyll serve
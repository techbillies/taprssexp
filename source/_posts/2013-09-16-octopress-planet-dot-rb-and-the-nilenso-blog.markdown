---
layout: post
title: "Octopress, Planet.rb and the Nilenso Blog"
date: 2013-09-16 16:26
comments: true
categories: 
---

We use [Octopress](http://octopress.com) with [planet.rb](https://github.com/pote/planet.rb) for this blog. It aggregates our personal blogs and also lets us post on the company's behalf. It works pretty well.

We started off with [planetplanet](http://www.planetplanet.org/), tried [planetvenus](http://www.intertwingly.net/code/venus/docs/index.html) and then settled on planet.rb. The plusses are:

-  We can now use the blog as both: a company blog and an aggregator at the same time.
-  Octopress is great for us Ruby devs. We needed partials, sass, themeability, extensibility and a static site.
-  planet.rb generates markdown files for all the feeds it parses. This keeps it consistent with the rest of the blog, and we love writing markdown.

##The tweaks we needed
Planet.rb is still in development, and there were a couple of things that needed to change before we could release. We sent pull requests for these which are now merged in to [planet.rb v0.5.0](https://github.com/pote/planet.rb/releases/tag/v0.5.0).

###A whitelist
   One such feature was the ability to filter posts that are not suitable for the company blog. We implemented this as a whitelist of tags. Only posts that have any tags in the whitelist will be imported.

{% codeblock planet.yml lang:java %}
planet:
    posts_directory: source/_posts/
    templates_directory: source/_layouts/
    whitelisted_tags: ["nilenso", "open source", "software", "gsoc", "gnome", "lifehacks", "dev"]
{% endcodeblock %}

###Fault tolerance
Another issue with planet.rb was that it quit abruptly when it failed to parse a blog because the blog was unreacheable. We fixed that and then it was good to go. Here's how it looks now when we run `planet generate`:

{% codeblock $planet generate lang:bash %}
planet-nilenso|master $ planet generate
=> Parsing https://blog.kitallis.in/feeds/posts/default
=> Found post titled GSoC - 1 & 2 - by Akshay Gupta
        => Ignored post titled: Computers with categories: [personal]
=> Found post titled GSoC 2011 - 0 - by Akshay Gupta
=> Found post titled "Open Containing Folder" for EoG and gedit - by Akshay Gupta
        => Ignored post titled: Init with categories: [personal]
=> Parsing https://blog.deobald.ca/feeds/posts/default                                                         
        => Failed to fetch https://blog.deobald.ca/feeds/posts/default with response_code: 0                                                      
=> Parsing https://blog.timothyandrew.net/atom.xml
=> Found post titled Encrypt Your Emails on OS X - by Timothy Andrew
=> Found post titled Pow Over HTTPS - by Timothy Andrew                   
{% endcodeblock %}

##The deploy hook and cronjob

We use [Capistrano](https://github.com/capistrano/capistrano) to deploy our blog. Here's the post deploy hook that we use on it:
{% codeblock config/deploy.rb lang:ruby %}
task :octopress_planet_generate do
  run "cd #{deploy_to}/current && bundle exec planet generate && bundle exec rake generate"
end

after "deploy", :octopress_planet_generate
{% endcodeblock %}

Taking the final step in automating this, we set up a simple cronjob to aggregate posts everyday:
{% codeblock $crontab -l lang:bash %}
@daily cd /path/to/blog && planet generate && rake generate
{% endcodeblock %}


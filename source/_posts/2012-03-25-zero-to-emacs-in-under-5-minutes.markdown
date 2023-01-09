---
title: "zero to emacs in under 5 minutes"
kind: article
created_at: 2012-03-25 15:16:00 UTC
author: Steven Deobald
post_url: "https://blog.deobald.ca/2012/03/zero-to-emacs-in-under-5-minutes.html"
layout: post
---
<div dir="ltr" style="text-align: left;" trbidi="on"><div dir="ltr" style="text-align: left;" trbidi="on">You want to write Clojure. You want to write it in Emacs. Here's how.<br /><br /><span style="font-size: large;">1. Grab Leiningen.</span><br /><blockquote class="tr_bq"><pre><code><br />mkdir -p ~/bin<br />cd ~/bin<br />wget https://raw.github.com/technomancy/leiningen/stable/bin/lein<br />chmod +x lein<br />echo 'PATH=$PATH:~/bin' &gt;&gt; ~/.profile<br />lein self-install<br /></code><br /></pre></blockquote>This will get you leiningen, Clojure's build tool.<br /><br /><br /><span style="font-size: large;">2. Grab Clojure.</span><br /><br /><blockquote class="tr_bq"><pre><code><br />cd ~/code<br />lein new my-first-clojure-project<br />cd my-first-clojure-project<br />lein deps<br /></code></pre></blockquote>`lein deps` will bring down a local copy of Clojure. Look in <span style="font-family: 'Courier New', Courier, monospace;">~/code/my-first-clojure-project/lib</span>&nbsp;!<br /><br /><br /><span style="font-size: large;">3. Grab swank-clojure.</span><br /><br /><blockquote class="tr_bq"><pre><code><br />lein plugin install swank-clojure 1.4.0<br /></code></pre></blockquote>This gives you the `clojure-jack-in` command in emacs. It's your samurai sword.<br /><br /><br /><span style="font-size: large;">4. Grab a healthy .emacs config. </span><br /><blockquote class="tr_bq"><pre><code><br />mv ~/.emacs ~/.emacs.bak<br />mv ~/.emacs.d ~/.emacs.d.bak<br />git clone git@github.com:c42/dotfiles.git<br />ln -s dotfiles/emacs.d ~/.emacs.d<br /></code></pre></blockquote></div><span style="font-size: large;"><br /></span><span style="font-size: large;">5. Grab an emacs. </span><br /><br />Ubuntu:&nbsp;<a href="https://launchpad.net/~cassou/+archive/emacs">https://launchpad.net/~cassou/+archive/emacs</a><br />OS X:&nbsp;<a href="http://emacsformacosx.com/emacs-builds/Emacs-pretest-24.0.94-universal-10.6.8.dmg">http://emacsformacosx.com/emacs-builds/Emacs-pretest-24.0.94-universal-10.6.8.dmg</a><br /><br />Running emacs for the first time will automatically install all the packages you need. Now run your first emacs repl!<br /><blockquote class="tr_bq"><pre><code>M-x clojure-jack-in<br /></code></pre></blockquote><br /><span style="font-size: large;">TADA!</span></div>
<div class="author">
  <img src="https://nilenso.com/images/alumni/steven.webp" style="width: 96px; height: 96;">
  <span style=" padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/deobald">Steven Deobald</a> - check out <a href="https://blog.deobald.ca/">Hungry, horny, sleepy, curious.</a></i>
  </span>
</div>

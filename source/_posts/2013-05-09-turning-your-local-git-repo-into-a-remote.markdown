---
title: "Turning Your Local Git Repo Into a Remote"
kind: article
created_at: 2013-05-09 14:48:00 UTC
author: Timothy Andrew
post_url: "https://blog.timothyandrew.net/blog/2013/05/09/turning-your-local-git-repo-into-a-remote/"
layout: post
---
<p>Need to pull some changes from a friend&#8217;s local Git repo without having to push to <code>origin</code>? This post will show you how to do that.</p>

<p>You can access a local Git repo using SSH, but setting up keys and such will probably take some time. For a quick-and-dirty solution, HTTP is <em>much</em> easier.</p>

<p>On the machine you want to use as the server, navigate to your project and then into the <code>.git</code> directory.</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
</pre></td><td class='code'><pre><code class='bash'><span class='line'><span class="nv">$ </span><span class="nb">cd</span> /path/to/project
</span><span class='line'><span class="nv">$ </span><span class="nb">cd</span> .git
</span></code></pre></td></tr></table></div></figure>


<p>Stand up a HTTP server using Python&#8217;s <code>SimpleHTTPServer</code> module. You can use any port number you like.</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
</pre></td><td class='code'><pre><code class='bash'><span class='line'><span class="nv">$ </span>python -m SimpleHTTPServer 5000
</span></code></pre></td></tr></table></div></figure>


<p>You&#8217;ll need the IP address of this machine as well. (Use <code>ifconfig</code>)</p>

<p>Make sure you can access the python server from a browser on the client machine. You should be able to see something like this at <code>http://ip.address:5000/</code></p>

<p><img src="images/2013-05-09-python-server.png" alt="Python Server Browser Screenshot" /></p>

<p>On the client, you should be now able to access the git repo over HTTP as though it were a normal git remote.</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
</pre></td><td class='code'><pre><code class='bash'><span class='line'><span class="nv">$ </span>git ls-remote http://ip.address:5000
</span><span class='line'><span class="nv">$ </span>git pull http://ip.address:5000 master
</span></code></pre></td></tr></table></div></figure>


<p>Add it as a remote to avoid typing out the entire IP each time.</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
</pre></td><td class='code'><pre><code class='bash'><span class='line'><span class="nv">$ </span>git remote add http://ip.address:5000 <span class="nb">local</span>-foo
</span><span class='line'><span class="nv">$ </span>git pull <span class="nb">local</span>-foo master
</span></code></pre></td></tr></table></div></figure>


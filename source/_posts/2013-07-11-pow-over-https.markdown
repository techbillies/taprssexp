---
title: "Pow Over HTTPS"
kind: article
created_at: 2013-07-11 06:56:00 UTC
author: Timothy Andrew
post_url: "http://blog.timothyandrew.net/blog/2013/07/11/pow-over-https/"
layout: post
---
<p>I use <a href="http://pow.cx">Pow</a> to manage web servers on my development machine. It works pretty well.
To start my server, I just hit a URL like <code>http://surveyweb.dev</code>, which starts the server (if it isn&#8217;t running) and spins it down automatically in 5 minutes.</p>

<p>It doesn&#8217;t work over HTTPS by default; here&#8217;s how you get that done.</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
</pre></td><td class='code'><pre><code class='bash'><span class='line'><span class="nv">$ </span>gem install tunnels
</span></code></pre></td></tr></table></div></figure>


<p>This gem lets you route traffic from one port to another port.</p>

<p>We need to route traffic from port 443, to port 80 (where the Pow server runs).</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
</pre></td><td class='code'><pre><code class='bash'><span class='line'><span class="nv">$ </span>sudo tunnels 443 80
</span></code></pre></td></tr></table></div></figure>


<p>While the tunnel is open, I can access <code>https://surveyweb.dev</code> just fine.</p>

<p>Pow also has a feature where I can access my server from another machine on the LAN using a URL like <code>http://surveyweb.192.168.1.10.xip.io/</code> where <code>192.168.1.10</code> is the IP address of my machine. Even with the tunnel open, HTTPS doesn&#8217;t work for this URL.</p>

<p>We need to start another tunnel:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
</pre></td><td class='code'><pre><code class='bash'><span class='line'><span class="nv">$ </span>sudo tunnels 192.168.1.10:443 127.0.0.1:80 <span class="c"># Replace 192.168.1.10 with your IP address</span>
</span></code></pre></td></tr></table></div></figure>


<p>And now, both URLs work over HTTPS.</p>
<div class="author">
  <img src="http://nilenso.com/images/alumni/tim.webp" style="width: 96px; height: 96;">
  <span style=" padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/timothyandrew">Timothy Andrew</a> - check out <a href="http://blog.timothyandrew.net/">Timothy&#39;s Blog</a></i>
  </span>
</div>

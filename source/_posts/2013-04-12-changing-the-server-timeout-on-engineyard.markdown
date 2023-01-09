---
title: "Changing the Server Timeout on EngineYard"
kind: article
created_at: 2013-04-12 16:59:00 UTC
author: Timothy Andrew
post_url: "https://blog.timothyandrew.net/blog/2013/04/12/changing-the-server-timeout-on-engineyard/"
layout: post
---
<p>While working on <a href="http://github.com/c42/survey-web">survey-web</a> today, we were stuck for a really long time trying to figure out this problem.</p>

<p>Unless otherwise specified, image uploads while adding a response are capped at 5MB per image.
Adding a larger image (like this 20MB image) should result in a validation error showing up.</p>

<p><img src="https://blog.timothyandrew.net/images/2013-04-12-image-too-big.png" alt="Validation Error" /></p>

<p>On production, we&#8217;d see this.</p>

<p><img src="https://blog.timothyandrew.net/images/2013-04-12-502.png" alt="Production" /></p>

<p>After a <em>lot</em> of digging, including looking at Carrierwave (and <a href="https://github.com/lardawge/carrierwave_backgrounder">Backgrounder</a>), delayed_job server logs, and our controller logic pretty closely, we noticed in <code>production.log</code> that Rails was sending down a <code>200</code>, but the browser was recieving a <code>502</code>.</p>

<p><code>unicorn.log</code> showed that a worker process was being killed with a <code>SIGIOP</code> whenever the error page showed up.</p>

<p>Only then did we realise that the worker was being killed around 60s every time. It had to be a timeout issue.</p>

<p>On EngineYard, the unicorn config already had:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
<span class='line-number'>6</span>
<span class='line-number'>7</span>
<span class='line-number'>8</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="c1"># sets the timeout of worker processes to +seconds+.  Workers</span>
</span><span class='line'><span class="c1"># handling the request/app.call/response cycle taking longer than</span>
</span><span class='line'><span class="c1"># this time period will be forcibly killed (via SIGKILL).  This</span>
</span><span class='line'><span class="c1"># timeout is enforced by the master process itself and not subject</span>
</span><span class='line'><span class="c1"># to the scheduling limitations by the worker process.  Due the</span>
</span><span class='line'><span class="c1"># low-complexity, low-overhead implementation, timeouts of less</span>
</span><span class='line'><span class="c1"># than 3.0 seconds can be considered inaccurate and unsafe.</span>
</span><span class='line'><span class="n">timeout</span> <span class="mi">180</span>
</span></code></pre></td></tr></table></div></figure>


<p>The server didn&#8217;t seem to be following this configuration.</p>

<p>After a fair bit of googling and help from the <code>#engineyard</code> IRC channel, this is what we did to fix it.
Add the following lines to <code>/data/nginx/nginx.conf</code> inside the <code>http{}</code> block (replacing 300 with the timeout you need).</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
</pre></td><td class='code'><pre><code class='nginx'><span class='line'><span class="k">client_header_timeout</span> <span class="mi">300</span><span class="p">;</span>
</span><span class='line'><span class="k">client_body_timeout</span> <span class="mi">300</span><span class="p">;</span>
</span><span class='line'><span class="k">send_timeout</span> <span class="mi">300</span><span class="p">;</span>
</span></code></pre></td></tr></table></div></figure>


<p>And restart nginx/unicorn with</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
</pre></td><td class='code'><pre><code class='bash'><span class='line'><span class="nv">$ </span>sudo /etc/init.d/nginx reload
</span><span class='line'><span class="nv">$ </span>/engineyard/bin/app_&lt;app_name&gt; reload
</span></code></pre></td></tr></table></div></figure>
<div class="author">
  <img src="https://nilenso.com/images/alumni/tim.webp" style="width: 96px; height: 96;">
  <span style=" padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/timothyandrew">Timothy Andrew</a> - check out <a href="https://blog.timothyandrew.net/">Timothy&#39;s Blog</a></i>
  </span>
</div>

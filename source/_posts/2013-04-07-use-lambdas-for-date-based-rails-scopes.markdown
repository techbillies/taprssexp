---
title: "Use Lambdas for Date-based Rails Scopes"
kind: article
created_at: 2013-04-07 18:56:00 UTC
author: Timothy Andrew
layout: post
---
<p>A scope allows you to specify an ARel query that can be used as a method call to the model (or association objects).</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
<span class='line-number'>6</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="k">class</span> <span class="nc">Item</span>
</span><span class='line'>  <span class="n">scope</span> <span class="ss">:delivered</span><span class="p">,</span> <span class="n">where</span><span class="p">(</span><span class="ss">delivered</span><span class="p">:</span> <span class="kp">true</span><span class="p">)</span>
</span><span class='line'><span class="k">end</span>
</span><span class='line'>
</span><span class='line'><span class="no">Item</span><span class="o">.</span><span class="n">delivered</span><span class="o">.</span><span class="n">to_sql</span>                     <span class="c1"># SELECT &quot;items&quot;.* FROM &quot;items&quot;  WHERE &quot;items&quot;.&quot;delivered&quot; = &#39;t&#39;</span>
</span><span class='line'><span class="no">Item</span><span class="o">.</span><span class="n">where</span><span class="p">(</span><span class="ss">price</span><span class="p">:</span> <span class="mi">2000</span><span class="p">)</span><span class="o">.</span><span class="n">delivered</span><span class="o">.</span><span class="n">to_sql</span>  <span class="c1"># SELECT &quot;items&quot;.* FROM &quot;items&quot;  WHERE &quot;items&quot;.&quot;price&quot; = 2000 AND &quot;items&quot;.&quot;delivered&quot; = &#39;t&#39;</span>
</span></code></pre></td></tr></table></div></figure>


<p>There&#8217;s a problem if we try using a scope for a relative date, though.</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="k">class</span> <span class="nc">Item</span>
</span><span class='line'>  <span class="n">scope</span> <span class="ss">:expired</span><span class="p">,</span> <span class="n">where</span><span class="p">(</span><span class="s2">&quot;expiry_date &lt; ?&quot;</span><span class="p">,</span> <span class="no">Date</span><span class="o">.</span><span class="n">today</span><span class="p">)</span>
</span><span class='line'><span class="k">end</span>
</span></code></pre></td></tr></table></div></figure>


<p>This code gets evaluated when the server is started, and the <em>output</em> of <code>Date.today</code> is stored in the scope.</p>

<p>That scope is equivalent to the following:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="k">class</span> <span class="nc">Item</span>
</span><span class='line'>  <span class="k">def</span> <span class="nc">self</span><span class="o">.</span><span class="nf">expired</span>
</span><span class='line'>    <span class="n">where</span><span class="p">(</span><span class="s2">&quot;expiry_date &lt; ?&quot;</span><span class="p">,</span> <span class="s2">&quot;2013-04-01&quot;</span><span class="p">)</span>
</span><span class='line'>  <span class="k">end</span>
</span><span class='line'><span class="k">end</span>
</span></code></pre></td></tr></table></div></figure>


<p>The date is hardcoded in there, and will not be changed until the scope is re-evaluated.
This typically happens only when the server is restarted.</p>

<p>To get around this problem, use a lambda when defining date (or time) based scopes. This will force the evaluation of the scope each time it is <em>called</em>.</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="k">class</span> <span class="nc">Item</span>
</span><span class='line'>  <span class="n">scope</span> <span class="ss">:expired</span><span class="p">,</span> <span class="nb">lambda</span> <span class="p">{</span> <span class="n">where</span><span class="p">(</span><span class="s2">&quot;expiry_date &lt; ?&quot;</span><span class="p">,</span> <span class="no">Date</span><span class="o">.</span><span class="n">today</span><span class="p">)</span> <span class="p">}</span>
</span><span class='line'><span class="k">end</span>
</span></code></pre></td></tr></table></div></figure><div class="author">
  <img src="http://nilenso.com/images/people/timothy-200.jpg" style="width: 96px; height: 96;">
  <span style="position: absolute; padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/timothyandrew">Timothy Andrew</a> - check out <a href="http://blog.timothyandrew.net/">Timothy&#39;s Blog</a></i>
  </span>
</div>

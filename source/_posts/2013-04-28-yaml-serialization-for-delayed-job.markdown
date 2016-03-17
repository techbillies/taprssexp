---
title: "YAML Serialization for Delayed Job"
kind: article
created_at: 2013-04-28 02:38:00 UTC
author: "Timothy Andrew"
categories: 
tags: 
layout: post
---
<p>When we first moved excel generation off to a delayed job on <a href="http://github.com/c42/survey-web">survey-web</a>, we had code that looked like this:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="n">responses</span> <span class="o">=</span> <span class="no">Response</span><span class="o">.</span><span class="n">where</span><span class="p">(</span><span class="ss">:foo</span> <span class="o">=&gt;</span> <span class="n">bar</span><span class="p">)</span>
</span><span class='line'><span class="ss">Delayed</span><span class="p">:</span><span class="ss">:Job</span><span class="o">.</span><span class="n">enqueue</span><span class="p">(</span><span class="no">MyCustomJob</span><span class="o">.</span><span class="n">new</span><span class="p">(</span><span class="n">responses</span><span class="p">))</span>
</span></code></pre></td></tr></table></div></figure>


<p>And this would bomb with an error like <code>Can't dump anonymous Module</code>.
After some time getting nowhere, we solved it like this:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="n">response_ids</span> <span class="o">=</span> <span class="no">Response</span><span class="o">.</span><span class="n">where</span><span class="p">(</span><span class="ss">:foo</span> <span class="o">=&gt;</span> <span class="n">bar</span><span class="p">)</span><span class="o">.</span><span class="n">map</span><span class="p">(</span><span class="o">&amp;</span><span class="ss">:id</span><span class="p">)</span>
</span><span class='line'><span class="ss">Delayed</span><span class="p">:</span><span class="ss">:Job</span><span class="o">.</span><span class="n">enqueue</span><span class="p">(</span><span class="no">MyCustomJob</span><span class="o">.</span><span class="n">new</span><span class="p">(</span><span class="n">response_ids</span><span class="p">))</span>
</span></code></pre></td></tr></table></div></figure>


<p>And in the job:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="n">responses</span> <span class="o">=</span> <span class="no">Response</span><span class="o">.</span><span class="n">where</span><span class="p">(</span><span class="s1">&#39;id in (?)&#39;</span><span class="p">,</span> <span class="n">response_ids</span><span class="p">)</span>
</span></code></pre></td></tr></table></div></figure>


<p>While refactoring a lot of that code over the last few days, we ran into the same issue. But with one difference. A controller spec was failing, but a test for the job which also passed a bunch of responses into it passed.</p>

<p>We wondered if maybe it was because we were passing a relation into the job instead of an array.</p>

<p>So we tried:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="n">responses</span> <span class="o">=</span> <span class="no">Response</span><span class="o">.</span><span class="n">where</span><span class="p">(</span><span class="ss">:foo</span> <span class="o">=&gt;</span> <span class="n">bar</span><span class="p">)</span><span class="o">.</span><span class="n">all</span>
</span><span class='line'><span class="ss">Delayed</span><span class="p">:</span><span class="ss">:Job</span><span class="o">.</span><span class="n">enqueue</span><span class="p">(</span><span class="no">MyCustomJob</span><span class="o">.</span><span class="n">new</span><span class="p">(</span><span class="n">responses</span><span class="p">))</span>
</span></code></pre></td></tr></table></div></figure>


<p>And that worked great.</p>

<p>(The files in question are <a href="https://github.com/c42/survey-web/blob/master/app/controllers/responses_controller.rb#L16">here</a> and <a href="https://github.com/c42/survey-web/blob/master/app/models/reports/excel/job.rb%22">here</a>).</p><div class="author">
  <img src="http://nilenso.com/images/people/timothy-200.jpg" style="width: 96px; height: 96;">
  <span style="position: absolute; padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/timothyandrew">Timothy Andrew</a> - check out <a href="http://blog.timothyandrew.net/">Timothy&#39;s Blog</a></i>
  </span>
</div>

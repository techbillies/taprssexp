---
title: "Writing Custom RSpec Matchers"
kind: article
created_at: 2013-05-01 06:26:00 UTC
author: Timothy Andrew
post_url: "http://blog.timothyandrew.net/blog/2013/05/01/writing-custom-rspec-matchers/"
layout: post
---
<p>RSpec matchers let you abstract away common assertions in your test code.</p>

<p>For example, we recently had a spec file with a bunch of lines that looked like this:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="n">worksheet</span><span class="o">.</span><span class="n">rows</span><span class="o">[</span><span class="mi">0</span><span class="o">].</span><span class="n">cells</span><span class="o">.</span><span class="n">map</span><span class="p">(</span><span class="o">&amp;</span><span class="ss">:value</span><span class="p">)</span><span class="o">.</span><span class="n">should</span> <span class="kp">include</span> <span class="s2">&quot;Foo&quot;</span>
</span></code></pre></td></tr></table></div></figure>


<p>Which tests if the excel file we&#8217;re generating (using <a href="https://github.com/randym/axlsx">axlsx</a>) includes <code>Foo</code> in the header row.</p>

<p>That isn&#8217;t very neat. What if we replace it with this?</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="n">worksheet</span><span class="o">.</span><span class="n">should</span> <span class="n">have_header_cell</span> <span class="s2">&quot;Foo&quot;</span>
</span></code></pre></td></tr></table></div></figure>


<p>That looks a lot better. We can implement this kind of abstraction using custom RSpec matchers.</p>

<p>The matcher for this is as simple as:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="ss">RSpec</span><span class="p">:</span><span class="ss">:Matchers</span><span class="o">.</span><span class="n">define</span> <span class="ss">:have_header_cell</span> <span class="k">do</span> <span class="o">|</span><span class="n">cell_value</span><span class="o">|</span>
</span><span class='line'>  <span class="n">match</span> <span class="k">do</span> <span class="o">|</span><span class="n">worksheet</span><span class="o">|</span>
</span><span class='line'>    <span class="n">worksheet</span><span class="o">.</span><span class="n">rows</span><span class="o">[</span><span class="mi">0</span><span class="o">].</span><span class="n">cells</span><span class="o">.</span><span class="n">map</span><span class="p">(</span><span class="o">&amp;</span><span class="ss">:value</span><span class="p">)</span><span class="o">.</span><span class="n">include?</span> <span class="n">cell_value</span>
</span><span class='line'>  <span class="k">end</span>
</span><span class='line'><span class="k">end</span>
</span></code></pre></td></tr></table></div></figure>


<p>RSpec passes in the expected and actual values to these blocks, and our code has to return a boolean representing the result of the assertion.</p>

<p>Now what about assertions that look like this?</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="n">worksheet</span><span class="o">.</span><span class="n">rows</span><span class="o">[</span><span class="mi">1</span><span class="o">].</span><span class="n">cells</span><span class="o">.</span><span class="n">map</span><span class="p">(</span><span class="o">&amp;</span><span class="ss">:value</span><span class="p">)</span><span class="o">.</span><span class="n">should</span> <span class="kp">include</span> <span class="s2">&quot;Foo&quot;</span>
</span><span class='line'><span class="n">worksheet</span><span class="o">.</span><span class="n">rows</span><span class="o">[</span><span class="mi">2</span><span class="o">].</span><span class="n">cells</span><span class="o">.</span><span class="n">map</span><span class="p">(</span><span class="o">&amp;</span><span class="ss">:value</span><span class="p">)</span><span class="o">.</span><span class="n">should</span> <span class="kp">include</span> <span class="s2">&quot;Bar&quot;</span>
</span><span class='line'><span class="n">worksheet</span><span class="o">.</span><span class="n">rows</span><span class="o">[</span><span class="mi">3</span><span class="o">].</span><span class="n">cells</span><span class="o">.</span><span class="n">map</span><span class="p">(</span><span class="o">&amp;</span><span class="ss">:value</span><span class="p">)</span><span class="o">.</span><span class="n">should</span> <span class="kp">include</span> <span class="s2">&quot;Baz&quot;</span>
</span></code></pre></td></tr></table></div></figure>


<p>The row that we&#8217;re checking changes for each assertion. Of course, we <em>could</em> create a different matcher for each of these cases, but there&#8217;s a better way.</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="n">worksheet</span><span class="o">.</span><span class="n">should</span> <span class="n">have_cell</span><span class="p">(</span><span class="s2">&quot;Foo&quot;</span><span class="p">)</span><span class="o">.</span><span class="n">in_row</span> <span class="mi">1</span>
</span><span class='line'><span class="n">worksheet</span><span class="o">.</span><span class="n">should</span> <span class="n">have_cell</span><span class="p">(</span><span class="s2">&quot;Bar&quot;</span><span class="p">)</span><span class="o">.</span><span class="n">in_row</span> <span class="mi">2</span>
</span><span class='line'><span class="n">worksheet</span><span class="o">.</span><span class="n">should</span> <span class="n">have_cell</span><span class="p">(</span><span class="s2">&quot;Baz&quot;</span><span class="p">)</span><span class="o">.</span><span class="n">in_row</span> <span class="mi">3</span>
</span></code></pre></td></tr></table></div></figure>


<p>RSpec lets you <em>chain</em> custom matchers.</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
<span class='line-number'>6</span>
<span class='line-number'>7</span>
<span class='line-number'>8</span>
<span class='line-number'>9</span>
<span class='line-number'>10</span>
<span class='line-number'>11</span>
<span class='line-number'>12</span>
<span class='line-number'>13</span>
</pre></td><td class='code'><pre><code class='ruby'><span class='line'><span class="ss">RSpec</span><span class="p">:</span><span class="ss">:Matchers</span><span class="o">.</span><span class="n">define</span> <span class="ss">:have_cell</span> <span class="k">do</span> <span class="o">|</span><span class="n">expected</span><span class="o">|</span>
</span><span class='line'>  <span class="n">match</span> <span class="k">do</span> <span class="o">|</span><span class="n">worksheet</span><span class="o">|</span>
</span><span class='line'>    <span class="n">worksheet</span><span class="o">.</span><span class="n">rows</span><span class="o">[</span><span class="vi">@index</span><span class="o">].</span><span class="n">cells</span><span class="o">.</span><span class="n">map</span><span class="p">(</span><span class="o">&amp;</span><span class="ss">:value</span><span class="p">)</span><span class="o">.</span><span class="n">include?</span> <span class="n">expected</span>
</span><span class='line'>  <span class="k">end</span>
</span><span class='line'>
</span><span class='line'>  <span class="n">chain</span> <span class="ss">:in_row</span> <span class="k">do</span> <span class="o">|</span><span class="n">index</span><span class="o">|</span>
</span><span class='line'>    <span class="vi">@index</span> <span class="o">=</span> <span class="n">index</span>
</span><span class='line'>  <span class="k">end</span>
</span><span class='line'>
</span><span class='line'>  <span class="n">failure_message_for_should</span> <span class="k">do</span> <span class="o">|</span><span class="n">actual</span><span class="o">|</span>
</span><span class='line'>    <span class="s2">&quot;Expected </span><span class="si">#{</span><span class="n">actual</span><span class="si">}</span><span class="s2"> to include </span><span class="si">#{</span><span class="n">expected</span><span class="si">}</span><span class="s2"> at row </span><span class="si">#{</span><span class="vi">@index</span><span class="si">}</span><span class="s2">.&quot;</span>
</span><span class='line'>  <span class="k">end</span>
</span><span class='line'><span class="k">end</span>
</span></code></pre></td></tr></table></div></figure>


<p>We first store the argument passed in to <code>in_row</code> as an instance variable, and then access it in the main <code>have_cell</code> matcher.</p>

<p>The example also includes a custom error message handler, which properly formats an error message if the assertion fails.</p>
<div class="author">
  <img src="http://nilenso.com/images/people/tim-200.png" style="width: 96px; height: 96;">
  <span style="position: absolute; padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/timothyandrew">Timothy Andrew</a> - check out <a href="http://blog.timothyandrew.net/">Timothy&#39;s Blog</a></i>
  </span>
</div>

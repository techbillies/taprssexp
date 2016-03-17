---
title: "Using Swipe.js to swipe between pages of a web app"
kind: article
created_at: 2013-04-05 16:15:00 UTC
author: "Timothy Andrew"
categories: 
tags: 
layout: post
---
<p>I was working with <a href="http://deobald.ca/">Steven</a> on <a href="http://github.com/deobald/jok">Jok</a> today.</p>

<p>We were converting a two page (well 3, actually) page web application into a single page application that let you swipe between pages on mobile device but worked the same on a desktop browser.</p>

<p>Here&#8217;s how that&#8217;s done.</p>

<p>First, download the <a href="http://swipejs.com/">Swipe.js</a> plugin.</p>

<p>You need the markup for all your pages in a single HTML file, wrapped with two <code>divs</code> that Swipe uses.</p>

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
</pre></td><td class='code'><pre><code class='html'><span class='line'><span class="nt">&lt;div</span> <span class="na">id=</span><span class="s">&#39;slider&#39;</span> <span class="na">class=</span><span class="s">&#39;swipe&#39;</span><span class="nt">&gt;</span>
</span><span class='line'>  <span class="nt">&lt;div</span> <span class="na">class=</span><span class="s">&#39;swipe-wrap&#39;</span><span class="nt">&gt;</span>
</span><span class='line'>    <span class="nt">&lt;div</span> <span class="na">class=</span><span class="s">&quot;page&quot;</span><span class="nt">&gt;</span>
</span><span class='line'>      Page 1
</span><span class='line'>    <span class="nt">&lt;/div&gt;</span>
</span><span class='line'>    <span class="nt">&lt;div</span> <span class="na">class=</span><span class="s">&quot;page&quot;</span><span class="nt">&gt;</span>
</span><span class='line'>      Page 2
</span><span class='line'>    <span class="nt">&lt;/div&gt;</span>
</span><span class='line'>  <span class="nt">&lt;/div&gt;</span>
</span><span class='line'><span class="nt">&lt;/div&gt;</span>
</span></code></pre></td></tr></table></div></figure>


<p>Next, we need to setup Swipe.js.</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
</pre></td><td class='code'><pre><code class='html'><span class='line'><span class="nt">&lt;script </span><span class="na">type=</span><span class="s">&quot;text/javascript&quot;</span><span class="nt">&gt;</span>
</span><span class='line'>    <span class="kd">var</span> <span class="nx">mySwipe</span> <span class="o">=</span> <span class="nx">Swipe</span><span class="p">(</span><span class="nb">document</span><span class="p">.</span><span class="nx">getElementById</span><span class="p">(</span><span class="s1">&#39;slider&#39;</span><span class="p">));</span>
</span><span class='line'>    <span class="nx">mySwipe</span><span class="p">.</span><span class="nx">setup</span><span class="p">();</span>
</span><span class='line'><span class="nt">&lt;/script&gt;</span>
</span></code></pre></td></tr></table></div></figure>


<p>We need some CSS styles too.</p>

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
<span class='line-number'>14</span>
<span class='line-number'>15</span>
<span class='line-number'>16</span>
<span class='line-number'>17</span>
<span class='line-number'>18</span>
<span class='line-number'>19</span>
<span class='line-number'>20</span>
</pre></td><td class='code'><pre><code class='css'><span class='line'><span class="nc">.swipe</span> <span class="p">{</span>
</span><span class='line'>  <span class="k">overflow</span><span class="o">:</span> <span class="k">hidden</span><span class="p">;</span>
</span><span class='line'>  <span class="k">visibility</span><span class="o">:</span> <span class="k">hidden</span><span class="p">;</span>
</span><span class='line'>  <span class="k">position</span><span class="o">:</span> <span class="k">relative</span><span class="p">;</span>
</span><span class='line'><span class="p">}</span>
</span><span class='line'><span class="nc">.swipe-wrap</span> <span class="p">{</span>
</span><span class='line'>  <span class="k">overflow</span><span class="o">:</span> <span class="k">hidden</span><span class="p">;</span>
</span><span class='line'>  <span class="k">position</span><span class="o">:</span> <span class="k">relative</span><span class="p">;</span>
</span><span class='line'><span class="p">}</span>
</span><span class='line'><span class="nc">.swipe-wrap</span> <span class="o">&gt;</span> <span class="nt">div</span> <span class="p">{</span>
</span><span class='line'>  <span class="k">float</span><span class="o">:</span><span class="k">left</span><span class="p">;</span>
</span><span class='line'>  <span class="k">width</span><span class="o">:</span><span class="m">100</span><span class="o">%</span><span class="p">;</span>
</span><span class='line'>  <span class="k">min-height</span><span class="o">:</span> <span class="m">100</span><span class="o">%</span><span class="p">;</span>
</span><span class='line'>  <span class="k">position</span><span class="o">:</span> <span class="k">relative</span><span class="p">;</span>
</span><span class='line'><span class="p">}</span>
</span><span class='line'><span class="nt">html</span><span class="o">,</span><span class="nt">body</span> <span class="p">{</span>
</span><span class='line'>    <span class="k">height</span><span class="o">:</span> <span class="m">100</span><span class="o">%</span><span class="p">;</span>
</span><span class='line'>    <span class="k">margin</span><span class="o">:</span> <span class="m">0px</span><span class="p">;</span>
</span><span class='line'>    <span class="k">padding</span><span class="o">:</span> <span class="m">0px</span><span class="p">;</span>
</span><span class='line'><span class="p">}</span>
</span></code></pre></td></tr></table></div></figure>


<p>We&#8217;ve added styles to make each page have a <code>100%</code> height, so that our background-color spans the entire page.</p>

<p>This should allow navigating between the pages by swiping on a mobile device.
On a desktop, though, there&#8217;s no way to switch between pages.</p>

<p>Swipe.js doesn&#8217;t detect swipe-like events from the mouse, so we need to add buttons to the page for navigation.</p>

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
</pre></td><td class='code'><pre><code class='html'><span class='line'><span class="nt">&lt;div</span> <span class="na">id=</span><span class="s">&quot;left-arrow&quot;</span>
</span><span class='line'>     <span class="na">style=</span><span class="s">&quot;font-size: 50px; position: absolute; left: 0%; top: 50%; z-index: 1000;&quot;</span>
</span><span class='line'>     <span class="na">onclick=</span><span class="s">&quot;javascript:window.mySwipe.prev();&quot;</span><span class="nt">&gt;</span>
</span><span class='line'><span class="ni">&amp;lt;</span>
</span><span class='line'><span class="nt">&lt;/div&gt;</span>
</span><span class='line'><span class="nt">&lt;div</span> <span class="na">id=</span><span class="s">&quot;right-arrow&quot;</span>
</span><span class='line'>     <span class="na">style=</span><span class="s">&quot;font-size: 50px; position: absolute; right: 0%; top: 50%; z-index: 1000;&quot;</span>
</span><span class='line'>     <span class="na">onclick=</span><span class="s">&quot;javascript:window.mySwipe.next();&quot;</span><span class="nt">&gt;</span>
</span><span class='line'><span class="ni">&amp;gt;</span>
</span><span class='line'><span class="nt">&lt;/div&gt;</span>
</span></code></pre></td></tr></table></div></figure>


<p>This adds a button on each side of the page which allow navigating to the previous/next pages.</p>

<p>Pretty straight-forward so far. There&#8217;s two problems with this approach, though.</p>

<ul>
<li>When a page is taller than the height of the viewport, a scrollbar shows up on all pages.
<em>This is not too bad. We could probably live with this.</em></li>
<li>If we scroll way down on a page, and then switch page, the new page will preserve the scroll position of the previous page. This can be particularly annoying if you have one really tall page and another short page.</li>
</ul>


<p>We solved this problem by caching the scroll position for each page, and then scrolling to that position when the page was changed.</p>

<p>To hook into the page change event, we need to pass a function into the Swipe.js initializer.</p>

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
</pre></td><td class='code'><pre><code class='javascript'><span class='line'><span class="kd">var</span> <span class="nx">body</span> <span class="o">=</span> <span class="nb">document</span><span class="p">.</span><span class="nx">getElementsByTagName</span><span class="p">(</span><span class="s2">&quot;body&quot;</span><span class="p">)[</span><span class="mi">0</span><span class="p">];</span>
</span><span class='line'><span class="kd">var</span> <span class="nx">otherScroll</span> <span class="o">=</span> <span class="mi">0</span><span class="p">;</span>
</span><span class='line'>
</span><span class='line'><span class="kd">var</span> <span class="nx">cb</span> <span class="o">=</span> <span class="kd">function</span><span class="p">(</span><span class="nx">index</span><span class="p">,</span> <span class="nx">element</span><span class="p">)</span> <span class="p">{</span>
</span><span class='line'>  <span class="nx">oldScroll</span> <span class="o">=</span> <span class="nx">otherScroll</span><span class="p">;</span>
</span><span class='line'>  <span class="nx">otherScroll</span> <span class="o">=</span> <span class="nx">body</span><span class="p">.</span><span class="nx">scrollTop</span><span class="p">;</span>
</span><span class='line'>  <span class="nx">body</span><span class="p">.</span><span class="nx">scrollTop</span> <span class="o">=</span> <span class="nx">oldScroll</span><span class="p">;</span>
</span><span class='line'><span class="p">};</span>
</span><span class='line'>
</span><span class='line'><span class="kd">var</span> <span class="nx">mySwipe</span> <span class="o">=</span> <span class="nx">Swipe</span><span class="p">(</span><span class="nb">document</span><span class="p">.</span><span class="nx">getElementById</span><span class="p">(</span><span class="s1">&#39;slider&#39;</span><span class="p">),</span> <span class="p">{</span> <span class="nx">callback</span><span class="o">:</span> <span class="nx">cb</span> <span class="p">});</span>
</span><span class='line'><span class="nx">mySwipe</span><span class="p">.</span><span class="nx">setup</span><span class="p">();</span>
</span></code></pre></td></tr></table></div></figure>


<p>This works okay for a two page app. If you&#8217;ve got more pages, you&#8217;ll have to cache the scroll positions for each page.</p>

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
</pre></td><td class='code'><pre><code class='javascript'><span class='line'><span class="kd">var</span> <span class="nx">body</span> <span class="o">=</span> <span class="nb">document</span><span class="p">.</span><span class="nx">getElementsByTagName</span><span class="p">(</span><span class="s2">&quot;body&quot;</span><span class="p">)[</span><span class="mi">0</span><span class="p">];</span>
</span><span class='line'><span class="kd">var</span> <span class="nx">positions</span> <span class="o">=</span> <span class="p">[];</span>
</span><span class='line'><span class="kd">var</span> <span class="nx">currentPage</span> <span class="o">=</span> <span class="mi">0</span><span class="p">;</span>
</span><span class='line'>
</span><span class='line'><span class="kd">var</span> <span class="nx">cb</span> <span class="o">=</span> <span class="kd">function</span><span class="p">(</span><span class="nx">index</span><span class="p">,</span> <span class="nx">element</span><span class="p">)</span> <span class="p">{</span>
</span><span class='line'>  <span class="nx">positions</span><span class="p">[</span><span class="nx">currentPage</span><span class="p">]</span> <span class="o">=</span> <span class="nx">body</span><span class="p">.</span><span class="nx">scrollTop</span><span class="p">;</span>
</span><span class='line'>  <span class="nx">body</span><span class="p">.</span><span class="nx">scrollTop</span> <span class="o">=</span> <span class="nx">positions</span><span class="p">[</span><span class="nx">index</span><span class="p">]</span> <span class="o">||</span> <span class="mi">0</span><span class="p">;</span>
</span><span class='line'>  <span class="nx">currentPage</span> <span class="o">=</span> <span class="nx">index</span><span class="p">;</span>
</span><span class='line'><span class="p">};</span>
</span><span class='line'>
</span><span class='line'><span class="kd">var</span> <span class="nx">mySwipe</span> <span class="o">=</span> <span class="nx">Swipe</span><span class="p">(</span><span class="nb">document</span><span class="p">.</span><span class="nx">getElementById</span><span class="p">(</span><span class="s1">&#39;slider&#39;</span><span class="p">),</span> <span class="p">{</span> <span class="nx">callback</span><span class="o">:</span> <span class="nx">cb</span> <span class="p">});</span>
</span><span class='line'><span class="nx">mySwipe</span><span class="p">.</span><span class="nx">setup</span><span class="p">();</span>
</span></code></pre></td></tr></table></div></figure><div class="author">
  <img src="http://nilenso.com/images/people/timothy-200.jpg" style="width: 96px; height: 96;">
  <span style="position: absolute; padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/timothyandrew">Timothy Andrew</a> - check out <a href="http://blog.timothyandrew.net/">Timothy&#39;s Blog</a></i>
  </span>
</div>

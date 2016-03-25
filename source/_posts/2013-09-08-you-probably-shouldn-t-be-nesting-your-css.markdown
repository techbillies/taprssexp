---
title: "You probably shouldn&#39;t be nesting your CSS"
kind: article
created_at: 2013-09-08 06:46:00 UTC
author: Srihari Sriraman
layout: post
---
<p><strong>TL;DR:</strong>  Don&rsquo;t nest CSS. Nest class names instead. This is one of the most useful take-aways from <a href="http://smacss.com">SMACSS</a>.
Follow this, and it will change the way you write scss for the better.</p>

<p>With the coming of <a href="http://sass-lang.com/">sass</a>,  we have all seen how writing css has gotten easier.
We love writing css that is similar to our html. The following would seem natural to us:</p>

<figure class='code'><figcaption><span>HTML for a component</span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
<span class='line-number'>6</span>
<span class='line-number'>7</span>
<span class='line-number'>8</span>
<span class='line-number'>9</span>
</pre></td><td class='code'><pre><code class='html'><span class='line'><span class="nt">&lt;div</span> <span class="na">class=</span><span class="s">&quot;my-component&quot;</span><span class="nt">&gt;</span>
</span><span class='line'>  <span class="nt">&lt;header&gt;&lt;/header&gt;</span>
</span><span class='line'>  <span class="nt">&lt;div</span> <span class="na">class=</span><span class="s">&quot;some-section&quot;</span><span class="nt">&gt;</span>
</span><span class='line'>    <span class="nt">&lt;header&gt;&lt;/header&gt;</span>
</span><span class='line'>    <span class="nt">&lt;p</span> <span class="na">class=</span><span class="s">&quot;description&quot;</span><span class="nt">&gt;</span>
</span><span class='line'>      <span class="nt">&lt;span</span> <span class="na">class=</span><span class="s">&quot;important&quot;</span><span class="nt">&gt;&lt;/span&gt;</span>
</span><span class='line'>    <span class="nt">&lt;/p&gt;</span>
</span><span class='line'>  <span class="nt">&lt;/div&gt;</span>
</span><span class='line'><span class="nt">&lt;/div&gt;</span>
</span></code></pre></td></tr></table></div></figure>




<figure class='code'><figcaption><span>Styling the component (the wrong way)</span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
<span class='line-number'>6</span>
<span class='line-number'>7</span>
<span class='line-number'>8</span>
<span class='line-number'>9</span>
</pre></td><td class='code'><pre><code class='sass'><span class='line'><span class="nt">div</span><span class="nc">.my-component</span> <span class="err">{</span>
</span><span class='line'>  <span class="nt">header</span> <span class="err">{}</span>
</span><span class='line'>  <span class="nc">.some-section</span> <span class="err">{</span>
</span><span class='line'>    <span class="nt">header</span> <span class="err">{}</span>
</span><span class='line'>    <span class="nt">p</span> <span class="err">{</span>
</span><span class='line'>      <span class="nc">.important</span> <span class="err">{}</span>
</span><span class='line'>    <span class="err">}</span>
</span><span class='line'>  <span class="err">}</span>
</span><span class='line'><span class="err">}</span>
</span></code></pre></td></tr></table></div></figure>


<p>This gives us the comfort of nesting css the same way we nest html. It gives us context that
<code>some-section</code> rests inside <code>my-component</code>, but nothing more. And, this gets convoluted quickly. if I had to override the style for this component elsewhere, I&rsquo;d have to do something like:</p>

<figure class='code'><figcaption><span>Overriding the style for .important</span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
</pre></td><td class='code'><pre><code class='sass'><span class='line'><span class="nc">.my-component</span> <span class="nc">.some-section</span> <span class="nt">p</span> <span class="nc">.important</span> <span class="err">{}</span>
</span></code></pre></td></tr></table></div></figure>


<h2>The correct way:</h2>

<p>Add the context, name of component/module in the class attribute:</p>

<figure class='code'><figcaption><span>HTML for a component</span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
<span class='line-number'>6</span>
<span class='line-number'>7</span>
<span class='line-number'>8</span>
<span class='line-number'>9</span>
</pre></td><td class='code'><pre><code class='html'><span class='line'><span class="nt">&lt;div</span> <span class="na">class=</span><span class="s">&quot;my-component&quot;</span><span class="nt">&gt;</span>
</span><span class='line'>  <span class="nt">&lt;header</span> <span class="na">class=</span><span class="s">&quot;my-component-header&quot;</span><span class="nt">&gt;&lt;/header&gt;</span>
</span><span class='line'>  <span class="nt">&lt;div</span> <span class="na">class=</span><span class="s">&quot;my-component-section&quot;</span><span class="nt">&gt;</span>
</span><span class='line'>    <span class="nt">&lt;header</span> <span class="na">class=</span><span class="s">&quot;my-component-section-header&quot;</span><span class="nt">&gt;&lt;/header&gt;</span>
</span><span class='line'>    <span class="nt">&lt;p</span> <span class="na">class=</span><span class="s">&quot;my-component-section-description&quot;</span><span class="nt">&gt;</span>
</span><span class='line'>      <span class="nt">&lt;span</span> <span class="na">class=</span><span class="s">&quot;my-component-section-important&quot;</span><span class="nt">&gt;&lt;/span&gt;</span>
</span><span class='line'>    <span class="nt">&lt;/p&gt;</span>
</span><span class='line'>  <span class="nt">&lt;/div&gt;</span>
</span><span class='line'><span class="nt">&lt;/div&gt;</span>
</span></code></pre></td></tr></table></div></figure>




<figure class='code'><figcaption><span>Styling the component (the correct way)</span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
<span class='line-number'>6</span>
</pre></td><td class='code'><pre><code class='sass'><span class='line'><span class="nc">.my-component</span> <span class="err">{}</span>
</span><span class='line'><span class="nc">.my-component-header</span> <span class="err">{}</span>
</span><span class='line'><span class="nc">.my-component-section</span> <span class="err">{}</span>
</span><span class='line'><span class="nc">.my-component-section-header</span> <span class="err">{}</span>
</span><span class='line'><span class="nc">.my-component-section-description</span> <span class="err">{}</span>
</span><span class='line'><span class="nc">.my-component-section-important</span> <span class="err">{}</span>
</span></code></pre></td></tr></table></div></figure>


<h3>What does this give us?</h3>

<ul>
<li>All the context that we got in nesting css. Except that the nesting is in the name instead of nested braces that are hard to read.</li>
<li>CSS with minimum specificity so that it is easy to override. For the purpose of subclassing modules, it is preferable to nest the styling by exactly one level. See exceptions below.</li>
<li>Independence from structure, so we can move our components around without having to move css around. For this purpose, it is also good to stay away from element selectors.</li>
<li>Control over cascading, that you thought was only possible <a href="http://37signals.com/svn/posts/3003-css-taking-control-of-the-cascade">with nesting</a>. The nesting in class names gives a unique name to your selector that is quite hard to override accidentally with cascading.</li>
<li>The answer to &ldquo;Where is the CSS for this?&rdquo;. Since the selectors have almost a one to one mapping with the class attributes, you just have to file-search for them now.</li>
<li>Speed. See how this helped <a href="https://speakerdeck.com/jonrohan/githubs-css-performance?slide=11">github</a> speed up their diff pages.</li>
</ul>


<h3>Conclusion:</h3>

<p>Don&rsquo;t nest CSS. You could start off with the <a href="http://thesassway.com/beginner/the-inception-rule">inception rule</a>, but I strongly suggest you stick to zero nesting levels (see exceptions below).</p>

<h3>Exceptions:</h3>

<ul>
<li>When you are writing modules that you will <a href="http://smacss.com/book/type-module#subclassing">subclass</a>, it is necessary to nest (by one level) the styling under the module&rsquo;s selector so that you can keep the defaults and override only the differences.</li>
<li>When overriding <a href="http://smacss.com/book/type-base">base rules</a>, one usually has to provide enough specificity to override an element selector, say. In these cases, nesting (by one level) is ok.</li>
</ul><div class="author">
  <img src="http://nilenso.com/images/people/srihari-200.png" style="width: 96px; height: 96;">
  <span style="position: absolute; padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/sriharisriraman">Srihari Sriraman</a> - check out <a href="http://sriharisriraman.in/">Srihari&#39;s Blog</a></i>
  </span>
</div>

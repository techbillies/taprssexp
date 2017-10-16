---
title: "Using RoboGuice to Inject Views Into a POJO"
kind: article
created_at: 2013-07-10 05:20:00 UTC
author: Timothy Andrew
post_url: "http://blog.timothyandrew.net/blog/2013/07/10/using-roboguice-to-inject-views-into-a-pojo/"
layout: post
---
<p><a href="https://github.com/roboguice/roboguice">RoboGuice</a> is great. It lets you get rid of code like:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
<span class='line-number'>6</span>
<span class='line-number'>7</span>
<span class='line-number'>8</span>
</pre></td><td class='code'><pre><code class='java'><span class='line'><span class="kd">public</span> <span class="kd">class</span> <span class="nc">LoginActivity</span> <span class="kd">extends</span> <span class="n">Activity</span> <span class="o">{</span>
</span><span class='line'>    <span class="kd">private</span> <span class="n">Button</span> <span class="n">mSignInButtonView</span><span class="o">;</span>
</span><span class='line'>
</span><span class='line'>    <span class="nd">@Override</span>
</span><span class='line'>    <span class="kd">protected</span> <span class="kt">void</span> <span class="nf">onCreate</span><span class="o">(</span><span class="n">Bundle</span> <span class="n">savedInstanceState</span><span class="o">)</span> <span class="o">{</span>
</span><span class='line'>        <span class="n">mSignInButtonView</span> <span class="o">=</span> <span class="o">(</span><span class="n">Button</span><span class="o">)</span> <span class="n">findViewById</span><span class="o">(</span><span class="n">R</span><span class="o">.</span><span class="na">id</span><span class="o">.</span><span class="na">sign_in_button</span><span class="o">);</span>
</span><span class='line'>    <span class="o">}</span>
</span><span class='line'><span class="o">}</span>
</span></code></pre></td></tr></table></div></figure>


<p>Instead, with a single line, RoboGuice will take care of injecting that view into your activity:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
<span class='line-number'>6</span>
<span class='line-number'>7</span>
<span class='line-number'>8</span>
</pre></td><td class='code'><pre><code class='java'><span class='line'><span class="kd">public</span> <span class="kd">class</span> <span class="nc">LoginActivity</span> <span class="kd">extends</span> <span class="n">RoboActivity</span> <span class="o">{</span>
</span><span class='line'>    <span class="nd">@InjectView</span><span class="o">(</span><span class="n">R</span><span class="o">.</span><span class="na">id</span><span class="o">.</span><span class="na">sign_in_button</span><span class="o">)</span> <span class="n">Button</span> <span class="n">mSignInButtonView</span><span class="o">;</span>
</span><span class='line'>
</span><span class='line'>    <span class="nd">@Override</span>
</span><span class='line'>    <span class="kd">protected</span> <span class="kt">void</span> <span class="nf">onCreate</span><span class="o">(</span><span class="n">Bundle</span> <span class="n">savedInstanceState</span><span class="o">)</span> <span class="o">{</span>
</span><span class='line'>        <span class="c1">// I have a reference to mSignInButtonView here.</span>
</span><span class='line'>    <span class="o">}</span>
</span><span class='line'><span class="o">}</span>
</span></code></pre></td></tr></table></div></figure>


<p>Now we&#8217;re rewriting <a href="http://github.com/nilenso/ashoka-survey-mobile">ashoka-survey-mobile</a> as a layered <a href="(http://github.com/nilenso/ashoka-survey-mobile-native">native app</a>).
We have a LoginView (POJO) which needs references to views present on-screen. Normally, we would instantiate the POJO in the activity, and pass it all the views it needs.</p>

<p>But can we do this with RoboGuice? We can&#8217;t really use <code>@InjectView</code> in a POJO. It needs an Activity context.
The next best thing is to inject the activity into the POJO (RoboGuice is smart enough to inject the correct activity), and pick the views manually using <code>findViewById</code>.</p>

<p>So in the activity:</p>

<figure class='code'><figcaption><span></span></figcaption><div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers"><span class='line-number'>1</span>
<span class='line-number'>2</span>
<span class='line-number'>3</span>
<span class='line-number'>4</span>
<span class='line-number'>5</span>
<span class='line-number'>6</span>
<span class='line-number'>7</span>
<span class='line-number'>8</span>
</pre></td><td class='code'><pre><code class='java'><span class='line'><span class="kd">public</span> <span class="kd">class</span> <span class="nc">LoginActivity</span> <span class="kd">extends</span> <span class="n">RoboActivity</span> <span class="o">{</span>
</span><span class='line'>    <span class="nd">@Inject</span> <span class="n">LoginView</span> <span class="n">loginView</span><span class="o">;</span>
</span><span class='line'>
</span><span class='line'>    <span class="nd">@Override</span>
</span><span class='line'>    <span class="kd">protected</span> <span class="kt">void</span> <span class="nf">onCreate</span><span class="o">(</span><span class="n">Bundle</span> <span class="n">savedInstanceState</span><span class="o">)</span> <span class="o">{</span>
</span><span class='line'>        <span class="n">loginView</span><span class="o">.</span><span class="na">onCreate</span><span class="o">();</span> <span class="c1">// Need to manually build up the view references inside LoginView</span>
</span><span class='line'>    <span class="o">}</span>
</span><span class='line'><span class="o">}</span>
</span></code></pre></td></tr></table></div></figure>


<p>and in <code>LoginView</code>:</p>

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
</pre></td><td class='code'><pre><code class='java'><span class='line'><span class="kd">public</span> <span class="kd">class</span> <span class="nc">LoginView</span> <span class="o">{</span>
</span><span class='line'>    <span class="nd">@Inject</span> <span class="n">Activity</span> <span class="n">activity</span><span class="o">;</span> <span class="c1">// This gets injected with the correct instance of LoginActivity</span>
</span><span class='line'>    <span class="kd">private</span> <span class="n">Button</span> <span class="n">buttonView</span><span class="o">;</span>
</span><span class='line'>    <span class="kd">private</span> <span class="n">EditText</span> <span class="n">editText</span><span class="o">;</span>
</span><span class='line'>
</span><span class='line'>    <span class="kd">public</span> <span class="kt">void</span> <span class="nf">onCreate</span><span class="o">()</span> <span class="o">{</span>
</span><span class='line'>        <span class="n">buttonView</span> <span class="o">=</span> <span class="n">activity</span><span class="o">.</span><span class="na">findViewById</span><span class="o">(</span><span class="n">R</span><span class="o">.</span><span class="na">id</span><span class="o">.</span><span class="na">my_button</span><span class="o">);</span>
</span><span class='line'>        <span class="n">editText</span> <span class="o">=</span> <span class="n">activity</span><span class="o">.</span><span class="na">findViewById</span><span class="o">(</span><span class="n">R</span><span class="o">.</span><span class="na">id</span><span class="o">.</span><span class="na">my_edit_text</span><span class="o">);</span>
</span><span class='line'>    <span class="o">}</span>
</span><span class='line'><span class="o">}</span>
</span></code></pre></td></tr></table></div></figure>


<p>And then your POJO can manipulate the views that are on-screen as required.</p><div class="author">
  <img src="http://nilenso.com/images/people/tim-200.png" style="width: 96px; height: 96;">
  <span style="position: absolute; padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/timothyandrew">Timothy Andrew</a> - check out <a href="http://blog.timothyandrew.net/">Timothy&#39;s Blog</a></i>
  </span>
</div>

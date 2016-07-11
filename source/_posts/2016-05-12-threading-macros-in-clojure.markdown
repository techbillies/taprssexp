---
title: "Threading macros in clojure"
kind: article
created_at: 2016-05-12 18:29:38 UTC
author: Unnikrishnan Geethagovindan
layout: post
---
<p>A few days into learning clojure, I thought it would be a good idea to look at some actual clojure projects in github. I was feeling all confident and what not &#8211; you know getting used to lispy way of writing things. The purpose of going through some code, was to get a gist of what was going on in the code, if not understanding it fully. I guess you already know where this is going don&#8217;t you ? Yep, I find myself reading through code and I find these two, <code>-&gt;</code> and <code>-&gt;&gt;</code> (and a lot more <em>scary </em>stuff) staring at me, and I had no clue what to make of it. I guess there would at least be a few of you guys who felt the same.</p>
<p>Apparently, they are called threading macros. <code>-&gt;</code> is the thread first and <code>-&gt;&gt;</code> thread last macros, and they are syntactical sugar to your code. It makes reading/writing code easier. &#8220;Meh! Just that?&#8221; you ask. Let&#8217;s see.</p>
<p>The syntax goes something like this : <a href="http://clojuredocs.org/clojure.core/-%3E"><code>(-&gt; x &amp; forms)</code></a> and <a href="http://clojuredocs.org/clojure.core/-%3E%3E"><code>(-&gt;&gt; x &amp; forms)</code></a>. The following examples might help you understand it.</p>
<p>Let say you want to do this (divide 2 by 1 then subtract 3 then add 4 and multiply with 5). How would you write it in clojure?</p>
<h2><a id="user-content--" class="anchor" href="https://github.com/krish8664/til/blob/master/clojure/threading.md#-"></a>-&gt;</h2>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >user=&gt; (<span class="pl-en">*</span> (<span class="pl-en">+</span> (<span class="pl-en">-</span> (<span class="pl-en">/</span> <span class="pl-c1">2</span> <span class="pl-c1">1</span>) <span class="pl-c1">3</span>) <span class="pl-c1">4</span> )<span class="pl-c1">5</span>)
<span class="pl-c1">15</span></pre></div>
</div>
<p>Boy! It can get difficult to read when you have a bunch of these strung together.</p>
<p>Now lets see how we write it with <code>-&gt;</code></p>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >user=&gt; (<span class="pl-en">-&gt;</span> <span class="pl-c1">2</span>
       (<span class="pl-en">/</span> <span class="pl-c1">1</span>)
       (<span class="pl-en">-</span> <span class="pl-c1">3</span>)
       (<span class="pl-en">+</span> <span class="pl-c1">4</span>)
       (<span class="pl-en">*</span> <span class="pl-c1">5</span>))
<span class="pl-c1">15</span></pre></div>
</div>
<p>Woh! This is a lot simpler to read (at least for me)! So what happens here is the thread first macro just takes the 2 and then pass it as the first argument to the next function and then the result of that as the first argument to the next and so on.</p>
<h2><a id="user-content---1" class="anchor" href="https://github.com/krish8664/til/blob/master/clojure/threading.md#--1"></a>-&gt;&gt;</h2>
<p>Thread last does something similar, instead of passing it as the first argument it would pass it as the last argument. So if you where to apply the <code>-&gt;&gt;</code> to the previous example you would get</p>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >user=&gt; (<span class="pl-en">-&gt;&gt;</span> <span class="pl-c1">2</span>
        (<span class="pl-en">/</span> <span class="pl-c1">1</span>)
        (<span class="pl-en">-</span> <span class="pl-c1">3</span>)
        (<span class="pl-en">+</span> <span class="pl-c1">4</span>)
        (<span class="pl-en">*</span> <span class="pl-c1">5</span>))
<span class="pl-c1">65/2</span></pre></div>
</div>
<p>which is</p>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >user=&gt; (<span class="pl-en">*</span> <span class="pl-c1">5</span> (<span class="pl-en">+</span> <span class="pl-c1">4</span> (<span class="pl-en">-</span> <span class="pl-c1">3</span> (<span class="pl-en">/</span> <span class="pl-c1">1</span> <span class="pl-c1">2</span>))))
<span class="pl-c1">65/2</span></pre></div>
</div>
<h2><a id="user-content-objects-and-collections" class="anchor" href="https://github.com/krish8664/til/blob/master/clojure/threading.md#objects-and-collections"></a>Objects and collections</h2>
<p>My favourite use of the threading macros has been when I have used them with java/clojure data structures. It makes handling them a lot easier.</p>
<h3><a id="user-content-collections" class="anchor" href="https://github.com/krish8664/til/blob/master/clojure/threading.md#collections"></a>Collections</h3>
<p>The thread-last macro <code>-&gt;&gt;</code> is very useful in dealing with collections. Where you have to transform them or apply functions to them, which is what you might be doing in a lot of your clojure code. For example, if you have this collection:</p>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >(<span class="pl-k">def</span> x {<span class="pl-c1">:document</span>
    {<span class="pl-c1">:paragraph</span>
     {<span class="pl-c1">:text</span> [<span class="pl-s"><span class="pl-pds">"</span>This is the first line<span class="pl-pds">"</span></span>
         <span class="pl-s"><span class="pl-pds">"</span>This is the second line<span class="pl-pds">"</span></span>
         <span class="pl-s"><span class="pl-pds">"</span>This is the third line<span class="pl-pds">"</span></span>]}}})</pre></div>
</div>
<p>Say you want to add a new &#8216;\n&#8217; at the end of each line and then print them together as a single string. How would you do this? Well its easy, you just get the text and then apply map and reduce to it and then print. Let&#8217;s write it shall we?</p>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >(<span class="pl-en">println</span> (<span class="pl-en">reduce</span> str (<span class="pl-en">map</span> #(<span class="pl-en">str</span> % <span class="pl-s"><span class="pl-pds">"</span><span class="pl-cce">\n</span><span class="pl-pds">"</span></span>) (<span class="pl-c1">:text</span> (<span class="pl-c1">:paragraph</span> (<span class="pl-c1">:document</span> x))))))</pre></div>
</div>
<p>Now lets take a look at this if we decide to write it using thread last macro</p>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >(<span class="pl-en">-&gt;&gt;</span> x
     <span class="pl-c1">:document</span> <span class="pl-c1">:paragraph</span> <span class="pl-c1">:text</span>
     (<span class="pl-en">map</span> #(<span class="pl-en">str</span> % <span class="pl-s"><span class="pl-pds">"</span><span class="pl-cce">\n</span><span class="pl-pds">"</span></span>))
     (<span class="pl-en">reduce</span> str)
     println)</pre></div>
</div>
<p>It&#8217;s a lot more cleaner, and you don&#8217;t have to keep matching the parenthesis to actually figure out what is happening. This works even better when you want to do a lot more transformation on the collections.</p>
<p>While at it, we can make use of this neat function <code>get-in</code> that helps you get values from deep inside a map, which is somewhat better to use at times. The advantage of using <code>get-in</code> over the threading would be that it helps you supply a <code>not-found</code> value, the would be returned if the key you are looking for is not there in the collection. Pretty neat huh? Let&#8217;s try that.</p>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >(<span class="pl-en">-&gt;&gt;</span> (<span class="pl-en">get-in</span> x [<span class="pl-c1">:document</span> <span class="pl-c1">:paragraph</span> <span class="pl-c1">:text</span>] [<span class="pl-s"><span class="pl-pds">"</span>No text found<span class="pl-pds">"</span></span>])
     (<span class="pl-en">map</span> #(<span class="pl-en">str</span> % <span class="pl-s"><span class="pl-pds">"</span><span class="pl-cce">\n</span><span class="pl-pds">"</span></span>))
     (<span class="pl-en">reduce</span> str)
     println)</pre></div>
</div>
<h3><a id="user-content-objects" class="anchor" href="https://github.com/krish8664/til/blob/master/clojure/threading.md#objects"></a>Objects</h3>
<p>Now if you are working with java interop and you aren&#8217;t using the thread-first macro, then this might change your mind. Let&#8217;s take this example, where you have a java object and you apply a series of methods on the Java object or Java objects returned on applying these methods. This is how you would be doing it.</p>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >(<span class="pl-en">.add</span> (<span class="pl-en">.getContent</span> (<span class="pl-en">.getBody</span> (<span class="pl-en">.getJaxbelement</span> (<span class="pl-en">.getMaindocumentpart</span> (<span class="pl-en">Wordprocessingmlpackage/createPackage</span>)))) paragraph)</pre></div>
</div>
<p>Now with thread first this becomes</p>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >(<span class="pl-en">-&gt;</span> (<span class="pl-en">WordprocessingMLPackage/createPackage</span>)
    .getMainDocumentPart
    .getJaxbElement
    .getBody
    .getContent
    (<span class="pl-en">.add</span> paragraph)</pre></div>
</div>
<p>Which is way more easier to read, and write. It is aligned with the original java representation, which aids in better understanding of the code. It feels less clunky than the previous case where you could get lost in all those parenthesis.</p>
<p>Since we are at it, let&#8217;s talk about another function: <code>doto</code>. This is very helpful when you have to apply multiple functions on a single java object. We didn&#8217;t use it in the previous example because, each of the functions were returning a different object.</p>
<p>Consider you have a table-border object and you want to set border to it. This is how you would be writing with thread the <code>doto</code> function.</p>
<div class="highlight highlight-source-clojure">
<div class="code-box"><div class="code-title"><i class="fa fa-code"></i> <div class="pull-right"><a href="#" class="btn btn-default btn-xs toggle-code" data-toggle="tooltip" title="Toggle code"><i class="fa fa-toggle-up"></i></a></div></div><pre >(<span class="pl-k">defn</span> <span class="pl-e">set-table-border</span>
  [table-border border]
  (<span class="pl-en">doto</span> table-border
    (<span class="pl-en">.setBottom</span> border)
    (<span class="pl-en">.setTop</span> border)
    (<span class="pl-en">.setRight</span> border)
    (<span class="pl-en">.setLeft</span> border)
    (<span class="pl-en">.setInsideH</span> border)
    (<span class="pl-en">.setInsideV</span> border)))</pre></div>
</div>
<p>You could use the threading operator or even write it in a single line, but it would be messy.</p>
<p class="p1"><span class="s2">A </span><span class="s3">threading</span><span class="s2"> macro can be used to reverse the read order: the value is primarily for people reading your code later; if using a </span><span class="s3">threading</span><span class="s2"> macro doesn&#8217;t feel like it will make your code easier for the next person to read, it&#8217;s probably the wrong choice.</span></p><div class="author">
  <img src="http://blog.unnikrishnan.in/wp-content/uploads/2016/05/13124641_10207964967054916_8185125548463219102_n-e1464062267378.jpg" style="width: 96px; height: 96;">
  <span style="position: absolute; padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/krish8664">Unnikrishnan Geethagovindan</a> - check out <a href="http://blog.unnikrishnan.in">My blog</a></i>
  </span>
</div>

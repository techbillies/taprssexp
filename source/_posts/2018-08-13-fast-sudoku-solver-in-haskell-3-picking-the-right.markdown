---
title: "Fast Sudoku Solver in Haskell #3: Picking the Right Data Structures"
kind: article
created_at: 2018-08-13 00:00:00 UTC
author: Abhinav Sarkar
post_url: "https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-3/"
layout: post
---
<p>In the <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/">previous part</a> in this series of posts, we optimized the simple Sudoku solver by implementing a new strategy to prune cells, and were able to achieve a speedup of almost 200x. Afterwards, we profiled the solution and found that there were bottlenecks in the program, leading to a slowdown. In this post, we are going to follow the profiler and use the right <em>Data Structures</em> to improve the solution further and make it <strong>faster</strong>.</p>
<!--more-->
<p>This is the third post in a series of posts:</p>
<ol type="1">
<li><a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-1/">Fast Sudoku Solver in Haskell #1: A Simple Solution</a></li>
<li><a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/">Fast Sudoku Solver in Haskell #2: A 200x Faster Solution</a></li>
<li><a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-3/">Fast Sudoku Solver in Haskell #3: Picking the Right Data Structures</a></li>
</ol>
<p>Discuss this post on <a href="https://www.reddit.com/r/haskell/comments/96y0xa/fast_sudoku_solver_in_haskell_3_picking_the_right/" target="_blank" rel="noopener">r/haskell</a>.</p>
<nav id="toc" class="right-toc"><h3>Contents</h3><ol><li><a href="#quick-recap">Quick Recap</a></li><li><a href="#profile-twice-code-once">Profile Twice, Code Once</a></li><li><a href="#a-set-for-all-occasions">A Set for All Occasions</a></li><li><a href="#bit-by-bit-we-get-faster">Bit by Bit, We Get Faster</a></li><li><a href="#back-to-the-profiler">Back to the Profiler</a></li><li><a href="#vectors-of-speed">Vectors of Speed</a></li><li><a href="#revenge-of-the">Revenge of the <code>(==)</code></a></li><li><a href="#one-function-to-prune-them-all">One Function to Prune Them All</a></li><li><a href="#rise-of-the-mutables">Rise of the Mutables</a></li><li><a href="#comparison-of-implementations">Comparison of Implementations</a></li><li><a href="#conclusion">Conclusion</a></li></ol></nav>
<h2 id="quick-recap" data-track-content data-content-name="quick-recap" data-content-piece="fast-sudoku-solver-in-haskell-3">Quick Recap<a href="#quick-recap" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p><a href="https://en.wikipedia.org/wiki/Sudoku" target="_blank" rel="noopener">Sudoku</a> is a number placement puzzle. It consists of a 9x9 grid which is to be filled with digits from 1 to 9 such that each row, each column and each of the nine 3x3 sub-grids contain all the digits. Some of the cells of the grid come pre-filled and the player has to fill the rest.</p>
<p>In the previous post, we improved the performance of the simple Sudoku solver by implementing a new strategy to prune cells. This <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/#a-little-forward-a-little-backward">new strategy</a> found the digits which occurred uniquely, in pairs, or in triplets and fixed the cells to those digits. It led to a speedup of about 200x over our original naive solution. This is our current run<a href="#fn1" class="footnote-ref" id="fnref1" role="doc-noteref"><sup>1</sup></a> time for solving all the 49151 <a href="https://abhinavsarkar.net/files/sudoku17.txt.bz2">17-clue puzzles</a>:</p>
<pre class="plain"><code>$ cat sudoku17.txt | time stack exec sudoku &gt; /dev/null
      258.97 real       257.34 user         1.52 sys</code></pre>
<p>Let’s try to improve this time.<a href="#fn2" class="footnote-ref" id="fnref2" role="doc-noteref"><sup>2</sup></a></p>
<h2 id="profile-twice-code-once" data-track-content data-content-name="profile-twice-code-once" data-content-piece="fast-sudoku-solver-in-haskell-3">Profile Twice, Code Once<a href="#profile-twice-code-once" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>Instead of trying to guess how to improve the performance of our solution, let’s be methodical about it. We start with profiling the code to find the bottlenecks. Let’s compile and run the code with profiling flags:</p>
<pre class="plain"><code>$ stack build --profile
$ head -1000 sudoku17.txt | stack exec -- sudoku +RTS -p &gt; /dev/null</code></pre>
<p>This generates a <code>sudoku.prof</code> file with the profiling output. Here are the top seven <em>Cost Centres</em><a href="#fn3" class="footnote-ref" id="fnref3" role="doc-noteref"><sup>3</sup></a> from the file (cleaned for brevity):</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Cost Centre</th>
<th style="text-align: left;">Src</th>
<th style="text-align: right;">%time</th>
<th style="text-align: right;">%alloc</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities</code></td>
<td style="text-align: left;">Sudoku.hs:(49,1)-(62,26)</td>
<td style="text-align: right;">18.9</td>
<td style="text-align: right;">11.4</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>pruneCellsByFixed.pruneCell</code></td>
<td style="text-align: left;">Sudoku.hs:(75,5)-(76,36)</td>
<td style="text-align: right;">17.7</td>
<td style="text-align: right;">30.8</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities.\.\</code></td>
<td style="text-align: left;">Sudoku.hs:55:38-70</td>
<td style="text-align: right;">11.7</td>
<td style="text-align: right;">20.3</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>fixM.\</code></td>
<td style="text-align: left;">Sudoku.hs:13:27-65</td>
<td style="text-align: right;">10.7</td>
<td style="text-align: right;">0.0</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>==</code></td>
<td style="text-align: left;">Sudoku.hs:15:56-57</td>
<td style="text-align: right;">5.6</td>
<td style="text-align: right;">0.0</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>pruneGrid'</code></td>
<td style="text-align: left;">Sudoku.hs:(103,1)-(106,64)</td>
<td style="text-align: right;">5.0</td>
<td style="text-align: right;">6.7</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>pruneCellsByFixed</code></td>
<td style="text-align: left;">Sudoku.hs:(71,1)-(76,36)</td>
<td style="text-align: right;">4.5</td>
<td style="text-align: right;">5.0</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>exclusivePossibilities.\</code></td>
<td style="text-align: left;">Sudoku.hs:58:36-68</td>
<td style="text-align: right;">3.4</td>
<td style="text-align: right;">2.5</td>
</tr>
</tbody>
</table>
</div>
<p><em>Cost Centre</em> points to a function, either named or anonymous. <em>Src</em> gives the line and column numbers of the source code of the function. <em>%time</em> and <em>%alloc</em> are the percentages of time spent and memory allocated in the function, respectively.</p>
<p>We see that <code>exclusivePossibilities</code> and the nested functions inside it take up almost 34% time of the entire run time. Second biggest bottleneck is the <code>pruneCell</code> function inside the <code>pruneCellsByFixed</code> function.</p>
<p>We are going to look at <code>exclusivePossibilities</code> later. For now, it is easy to guess the possible reason for <code>pruneCell</code> taking so much time. Here’s the code for reference:</p>
<div class="sourceCode" id="cb3"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb3-1"><a href="#cb3-1"></a><span class="ot">pruneCellsByFixed ::</span> [<span class="dt">Cell</span>] <span class="ot">-&gt;</span> <span class="dt">Maybe</span> [<span class="dt">Cell</span>]</span>
<span id="cb3-2"><a href="#cb3-2"></a>pruneCellsByFixed cells <span class="ot">=</span> <span class="fu">traverse</span> pruneCell cells</span>
<span id="cb3-3"><a href="#cb3-3"></a>  <span class="kw">where</span></span>
<span id="cb3-4"><a href="#cb3-4"></a>    fixeds <span class="ot">=</span> [x <span class="op">|</span> <span class="dt">Fixed</span> x <span class="ot">&lt;-</span> cells]</span>
<span id="cb3-5"><a href="#cb3-5"></a></span>
<span id="cb3-6"><a href="#cb3-6"></a>    pruneCell (<span class="dt">Possible</span> xs) <span class="ot">=</span> makeCell (xs <span class="dt">Data.List</span><span class="op">.</span>\\ fixeds)</span>
<span id="cb3-7"><a href="#cb3-7"></a>    pruneCell x             <span class="ot">=</span> <span class="dt">Just</span> x</span></code></pre></div>
<p><code>pruneCell</code> uses <code>Data.List.\\</code> to find the difference of the cell’s possible digits and the fixed digits in the cell’s block. In Haskell, lists are implemented as <a href="https://en.wikipedia.org/wiki/Linked_list#Singly_linked_list" target="_blank" rel="noopener">singly linked lists</a>. So, finding the difference or intersection of two lists is O(n<sup>2</sup>), that is, quadratic <a href="https://en.wikipedia.org/wiki/Asymptotic_complexity" target="_blank" rel="noopener">asymptotic complexity</a>. Let’s tackle this bottleneck first.</p>
<h2 id="a-set-for-all-occasions" data-track-content data-content-name="a-set-for-all-occasions" data-content-piece="fast-sudoku-solver-in-haskell-3">A Set for All Occasions<a href="#a-set-for-all-occasions" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>What is a efficient data structure for finding differences and intersections? Why, a <a href="https://en.wikipedia.org/wiki/Set_(abstract_data_type)" target="_blank" rel="noopener"><em>Set</em></a> of course! A Set stores unique values and provides fast operations for testing membership of its elements. If we use a Set to represent the possible values of cells instead of a List, the program should run faster. Since the possible values are already unique (<code>1</code>–<code>9</code>), it should not break anything.</p>
<p>Haskell comes with a bunch of Set implementations:</p>
<ul>
<li><a href="https://hackage.haskell.org/package/containers-0.6.0.1/docs/Data-Set.html" target="_blank" rel="noopener"><code>Data.Set</code></a> which is a generic data structure implemented as <a href="https://en.wikipedia.org/wiki/Self-balancing_binary_search_tree" target="_blank" rel="noopener">self-balancing binary search tree</a>.</li>
<li><a href="https://hackage.haskell.org/package/unordered-containers-0.2.9.0/docs/Data-HashSet.html" target="_blank" rel="noopener"><code>Data.HashSet</code></a> which is a generic data structure implemented as <a href="https://en.wikipedia.org/wiki/Hash_array_mapped_trie" target="_blank" rel="noopener">hash array mapped trie</a>.</li>
<li><a href="https://hackage.haskell.org/package/containers-0.6.0.1/docs/Data-IntSet.html" target="_blank" rel="noopener"><code>Data.IntSet</code></a> which is a specialized data structure for integer values, implemented as <a href="https://en.wikipedia.org/wiki/Radix_tree" target="_blank" rel="noopener">radix tree</a>.</li>
</ul>
<p>However, a much faster implementation is possible for our particular use-case. We can use a <a href="https://en.wikipedia.org/wiki/Bitset" target="_blank" rel="noopener"><em>BitSet</em></a>.</p>
<p>A BitSet uses <a href="https://en.wikipedia.org/wiki/Bit" target="_blank" rel="noopener">bits</a> to represent unique members of a Set. We map values to particular bits using some function. If the bit corresponding to a particular value is set to 1 then the value is present in the Set, else it is not. So, we need as many bits in a BitSet as the number of values in our domain, which makes is difficult to use for generic problems. But, for our Sudoku solver, we need to store only the digits <code>1</code>–<code>9</code> in the Set, which make BitSet very suitable for us. Also, the Set operations on BitSet are implemented using bit-level instructions in hardware, making them much faster than those on the other data structure listed above.</p>
<p>In Haskell, we can use the <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Data-Word.html" target="_blank" rel="noopener"><code>Data.Word</code></a> module to represent a BitSet. Specifically, we can use the <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Data-Word.html#t:Word16" target="_blank" rel="noopener"><code>Data.Word.Word16</code></a> type which has sixteen bits because we need only nine bits to represent the nine digits. The bit-level operations on <code>Word16</code> are provided by the <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Data-Bits.html" target="_blank" rel="noopener"><code>Data.Bits</code></a> module.</p>
<h2 id="bit-by-bit-we-get-faster" data-track-content data-content-name="bit-by-bit-we-get-faster" data-content-piece="fast-sudoku-solver-in-haskell-3">Bit by Bit, We Get Faster<a href="#bit-by-bit-we-get-faster" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>First, we replace List with <code>Word16</code> in the <code>Cell</code> type and add a helper function:</p>
<div class="sourceCode" id="cb4"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb4-1"><a href="#cb4-1"></a><span class="kw">data</span> <span class="dt">Cell</span> <span class="ot">=</span> <span class="dt">Fixed</span> <span class="dt">Data.Word.Word16</span></span>
<span id="cb4-2"><a href="#cb4-2"></a>          <span class="op">|</span> <span class="dt">Possible</span> <span class="dt">Data.Word.Word16</span></span>
<span id="cb4-3"><a href="#cb4-3"></a>          <span class="kw">deriving</span> (<span class="dt">Show</span>, <span class="dt">Eq</span>)</span>
<span id="cb4-4"><a href="#cb4-4"></a></span>
<span id="cb4-5"><a href="#cb4-5"></a><span class="ot">setBits ::</span> <span class="dt">Data.Word.Word16</span> <span class="ot">-&gt;</span> [<span class="dt">Data.Word.Word16</span>] <span class="ot">-&gt;</span> <span class="dt">Data.Word.Word16</span></span>
<span id="cb4-6"><a href="#cb4-6"></a>setBits <span class="ot">=</span> Data.List.foldl' (<span class="op">Data.Bits..|.</span>)</span></code></pre></div>
<p>Then we replace <code>Int</code> related operations with bit related ones in the read and show functions:</p>
<div class="sourceCode" id="cb5"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb5-1"><a href="#cb5-1"></a><span class="ot">readGrid ::</span> <span class="dt">String</span> <span class="ot">-&gt;</span> <span class="dt">Maybe</span> <span class="dt">Grid</span></span>
<span id="cb5-2"><a href="#cb5-2"></a>readGrid s</span>
<span id="cb5-3"><a href="#cb5-3"></a>  <span class="op">|</span> <span class="fu">length</span> s <span class="op">==</span> <span class="dv">81</span> <span class="ot">=</span></span>
<span id="cb5-4"><a href="#cb5-4"></a>      <span class="fu">traverse</span> (<span class="fu">traverse</span> readCell) <span class="op">.</span> Data.List.Split.chunksOf <span class="dv">9</span> <span class="op">$</span> s</span>
<span id="cb5-5"><a href="#cb5-5"></a>  <span class="op">|</span> <span class="fu">otherwise</span>      <span class="ot">=</span> <span class="dt">Nothing</span></span>
<span id="cb5-6"><a href="#cb5-6"></a>  <span class="kw">where</span></span>
<span id="cb5-7"><a href="#cb5-7"></a>    allBitsSet <span class="ot">=</span> <span class="dv">1022</span></span>
<span id="cb5-8"><a href="#cb5-8"></a></span>
<span id="cb5-9"><a href="#cb5-9"></a>    readCell <span class="ch">'.'</span> <span class="ot">=</span> <span class="dt">Just</span> <span class="op">$</span> <span class="dt">Possible</span> allBitsSet</span>
<span id="cb5-10"><a href="#cb5-10"></a>    readCell c</span>
<span id="cb5-11"><a href="#cb5-11"></a>      <span class="op">|</span> Data.Char.isDigit c <span class="op">&amp;&amp;</span> c <span class="op">&gt;</span> <span class="ch">'0'</span> <span class="ot">=</span></span>
<span id="cb5-12"><a href="#cb5-12"></a>          <span class="dt">Just</span> <span class="op">.</span> <span class="dt">Fixed</span> <span class="op">.</span> Data.Bits.bit <span class="op">.</span> Data.Char.digitToInt <span class="op">$</span> c</span>
<span id="cb5-13"><a href="#cb5-13"></a>      <span class="op">|</span> <span class="fu">otherwise</span> <span class="ot">=</span> <span class="dt">Nothing</span></span>
<span id="cb5-14"><a href="#cb5-14"></a></span>
<span id="cb5-15"><a href="#cb5-15"></a><span class="ot">showGrid ::</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> <span class="dt">String</span></span>
<span id="cb5-16"><a href="#cb5-16"></a>showGrid <span class="ot">=</span> <span class="fu">unlines</span> <span class="op">.</span> <span class="fu">map</span> (<span class="fu">unwords</span> <span class="op">.</span> <span class="fu">map</span> showCell)</span>
<span id="cb5-17"><a href="#cb5-17"></a>  <span class="kw">where</span></span>
<span id="cb5-18"><a href="#cb5-18"></a>    showCell (<span class="dt">Fixed</span> x) <span class="ot">=</span> <span class="fu">show</span> <span class="op">.</span> Data.Bits.countTrailingZeros <span class="op">$</span> x</span>
<span id="cb5-19"><a href="#cb5-19"></a>    showCell _         <span class="ot">=</span> <span class="st">&quot;.&quot;</span></span>
<span id="cb5-20"><a href="#cb5-20"></a></span>
<span id="cb5-21"><a href="#cb5-21"></a><span class="ot">showGridWithPossibilities ::</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> <span class="dt">String</span></span>
<span id="cb5-22"><a href="#cb5-22"></a>showGridWithPossibilities <span class="ot">=</span> <span class="fu">unlines</span> <span class="op">.</span> <span class="fu">map</span> (<span class="fu">unwords</span> <span class="op">.</span> <span class="fu">map</span> showCell)</span>
<span id="cb5-23"><a href="#cb5-23"></a>  <span class="kw">where</span></span>
<span id="cb5-24"><a href="#cb5-24"></a>    showCell (<span class="dt">Fixed</span> x) <span class="ot">=</span> (<span class="fu">show</span> <span class="op">.</span> Data.Bits.countTrailingZeros <span class="op">$</span> x) <span class="op">++</span> <span class="st">&quot;          &quot;</span></span>
<span id="cb5-25"><a href="#cb5-25"></a>    showCell (<span class="dt">Possible</span> xs) <span class="ot">=</span></span>
<span id="cb5-26"><a href="#cb5-26"></a>      <span class="st">&quot;[&quot;</span> <span class="op">++</span></span>
<span id="cb5-27"><a href="#cb5-27"></a>      <span class="fu">map</span> (\i <span class="ot">-&gt;</span> <span class="kw">if</span> Data.Bits.testBit xs i</span>
<span id="cb5-28"><a href="#cb5-28"></a>                 <span class="kw">then</span> Data.Char.intToDigit i</span>
<span id="cb5-29"><a href="#cb5-29"></a>                 <span class="kw">else</span> <span class="ch">' '</span>)</span>
<span id="cb5-30"><a href="#cb5-30"></a>          [<span class="dv">1</span><span class="op">..</span><span class="dv">9</span>]</span>
<span id="cb5-31"><a href="#cb5-31"></a>      <span class="op">++</span> <span class="st">&quot;]&quot;</span></span></code></pre></div>
<p>We set the same bits as the digits to indicate the presence of the digits in the possibilities. For example, for digit <code>1</code>, we set the bit 1 so that the resulting <code>Word16</code> is <code>0000 0000 0000 0010</code> or 2. This also means, for fixed cells, the value is <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Data-Bits.html#v:countTrailingZeros" target="_blank" rel="noopener">count of the zeros from right</a>.</p>
<p>The change in the <code>exclusivePossibilities</code> function is pretty minimal:</p>
<div class="sourceCode" id="cb6"><pre class="sourceCode diff"><code class="sourceCode diff"><span id="cb6-1"><a href="#cb6-1"></a><span class="st">-exclusivePossibilities :: [Cell] -&gt; [[Int]]</span></span>
<span id="cb6-2"><a href="#cb6-2"></a><span class="va">+exclusivePossibilities :: [Cell] -&gt; [Data.Word.Word16]</span></span>
<span id="cb6-3"><a href="#cb6-3"></a> exclusivePossibilities row =</span>
<span id="cb6-4"><a href="#cb6-4"></a>   row</span>
<span id="cb6-5"><a href="#cb6-5"></a>   &amp; zip [1..9]</span>
<span id="cb6-6"><a href="#cb6-6"></a>   &amp; filter (isPossible . snd)</span>
<span id="cb6-7"><a href="#cb6-7"></a>   &amp; Data.List.foldl'</span>
<span id="cb6-8"><a href="#cb6-8"></a>       (\acc ~(i, Possible xs) -&gt;</span>
<span id="cb6-9"><a href="#cb6-9"></a><span class="st">-        Data.List.foldl'</span></span>
<span id="cb6-10"><a href="#cb6-10"></a><span class="st">-          (\acc' x -&gt; Map.insertWith prepend x [i] acc')</span></span>
<span id="cb6-11"><a href="#cb6-11"></a><span class="st">-          acc</span></span>
<span id="cb6-12"><a href="#cb6-12"></a><span class="st">-          xs)</span></span>
<span id="cb6-13"><a href="#cb6-13"></a><span class="va">+        Data.List.foldl'</span></span>
<span id="cb6-14"><a href="#cb6-14"></a><span class="va">+          (\acc' x -&gt; if Data.Bits.testBit xs x</span></span>
<span id="cb6-15"><a href="#cb6-15"></a><span class="va">+                      then Map.insertWith prepend x [i] acc'</span></span>
<span id="cb6-16"><a href="#cb6-16"></a><span class="va">+                      else acc')</span></span>
<span id="cb6-17"><a href="#cb6-17"></a><span class="va">+          acc</span></span>
<span id="cb6-18"><a href="#cb6-18"></a><span class="va">+          [1..9])</span></span>
<span id="cb6-19"><a href="#cb6-19"></a>       Map.empty</span>
<span id="cb6-20"><a href="#cb6-20"></a>   &amp; Map.filter ((&lt; 4) . length)</span>
<span id="cb6-21"><a href="#cb6-21"></a>   &amp; Map.foldlWithKey' (\acc x is -&gt; Map.insertWith prepend is [x] acc) Map.empty</span>
<span id="cb6-22"><a href="#cb6-22"></a>   &amp; Map.filterWithKey (\is xs -&gt; length is == length xs)</span>
<span id="cb6-23"><a href="#cb6-23"></a>   &amp; Map.elems</span>
<span id="cb6-24"><a href="#cb6-24"></a><span class="va">+  &amp; map (Data.List.foldl' Data.Bits.setBit Data.Bits.zeroBits)</span></span>
<span id="cb6-25"><a href="#cb6-25"></a>   where</span>
<span id="cb6-26"><a href="#cb6-26"></a>     prepend ~[y] ys = y:ys</span></code></pre></div>
<p>In the nested folding step, instead of folding over the possible values of the cells, now we fold over the digits from <code>1</code> to <code>9</code> and insert the entry in the map if the bit corresponding to the digit is set in the possibilities. And as the last step, we convert the exclusive possibilities to <code>Word16</code> by folding them, starting with zero. As example in the <em>REPL</em> should be instructive:</p>
<div class="sourceCode" id="cb7"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb7-1"><a href="#cb7-1"></a><span class="op">*</span><span class="dt">Main</span><span class="op">&gt;</span> poss <span class="ot">=</span> Data.List.foldl' Data.Bits.setBit Data.Bits.zeroBits</span>
<span id="cb7-2"><a href="#cb7-2"></a><span class="op">*</span><span class="dt">Main</span><span class="op">&gt;</span> row <span class="ot">=</span> [<span class="dt">Possible</span> <span class="op">$</span> poss [<span class="dv">4</span>,<span class="dv">6</span>,<span class="dv">9</span>], <span class="dt">Fixed</span> <span class="op">$</span> poss [<span class="dv">1</span>], <span class="dt">Fixed</span> <span class="op">$</span> poss [<span class="dv">5</span>], <span class="dt">Possible</span> <span class="op">$</span> poss [<span class="dv">6</span>,<span class="dv">9</span>], <span class="dt">Fixed</span> <span class="op">$</span> poss [<span class="dv">7</span>], <span class="dt">Possible</span> <span class="op">$</span> poss [<span class="dv">2</span>,<span class="dv">3</span>,<span class="dv">6</span>,<span class="dv">8</span>,<span class="dv">9</span>], <span class="dt">Possible</span> <span class="op">$</span> poss [<span class="dv">6</span>,<span class="dv">9</span>], <span class="dt">Possible</span> <span class="op">$</span> poss [<span class="dv">2</span>,<span class="dv">3</span>,<span class="dv">6</span>,<span class="dv">8</span>,<span class="dv">9</span>], <span class="dt">Possible</span> <span class="op">$</span> poss [<span class="dv">2</span>,<span class="dv">3</span>,<span class="dv">6</span>,<span class="dv">8</span>,<span class="dv">9</span>]]</span>
<span id="cb7-3"><a href="#cb7-3"></a><span class="op">*</span><span class="dt">Main</span><span class="op">&gt;</span> <span class="fu">putStr</span> <span class="op">$</span> showGridWithPossibilities [row]</span>
<span id="cb7-4"><a href="#cb7-4"></a>[   <span class="dv">4</span> <span class="dv">6</span>  <span class="dv">9</span>] <span class="dv">1</span>           <span class="dv">5</span>           [     <span class="dv">6</span>  <span class="dv">9</span>] <span class="dv">7</span>           [ <span class="dv">23</span>  <span class="dv">6</span> <span class="dv">89</span>] [     <span class="dv">6</span>  <span class="dv">9</span>] [ <span class="dv">23</span>  <span class="dv">6</span> <span class="dv">89</span>] [ <span class="dv">23</span>  <span class="dv">6</span> <span class="dv">89</span>]</span>
<span id="cb7-5"><a href="#cb7-5"></a><span class="op">*</span><span class="dt">Main</span><span class="op">&gt;</span> exclusivePossibilities row</span>
<span id="cb7-6"><a href="#cb7-6"></a>[<span class="dv">16</span>,<span class="dv">268</span>]</span>
<span id="cb7-7"><a href="#cb7-7"></a><span class="op">*</span><span class="dt">Main</span><span class="op">&gt;</span> [poss [<span class="dv">4</span>], poss [<span class="dv">8</span>,<span class="dv">3</span>,<span class="dv">2</span>]]</span>
<span id="cb7-8"><a href="#cb7-8"></a>[<span class="dv">16</span>,<span class="dv">268</span>]</span></code></pre></div>
<p>This is the same example row as the <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/#a-little-forward-a-little-backward">last time</a>. And it returns same results, excepts as a list of <code>Word16</code> now.</p>
<p>Now, we change <code>makeCell</code> to use bit operations instead of list ones:</p>
<div class="sourceCode" id="cb8"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb8-1"><a href="#cb8-1"></a><span class="ot">makeCell ::</span> <span class="dt">Data.Word.Word16</span> <span class="ot">-&gt;</span> <span class="dt">Maybe</span> <span class="dt">Cell</span></span>
<span id="cb8-2"><a href="#cb8-2"></a>makeCell ys</span>
<span id="cb8-3"><a href="#cb8-3"></a>  <span class="op">|</span> ys <span class="op">==</span> Data.Bits.zeroBits   <span class="ot">=</span> <span class="dt">Nothing</span></span>
<span id="cb8-4"><a href="#cb8-4"></a>  <span class="op">|</span> Data.Bits.popCount ys <span class="op">==</span> <span class="dv">1</span> <span class="ot">=</span> <span class="dt">Just</span> <span class="op">$</span> <span class="dt">Fixed</span> ys</span>
<span id="cb8-5"><a href="#cb8-5"></a>  <span class="op">|</span> <span class="fu">otherwise</span>                  <span class="ot">=</span> <span class="dt">Just</span> <span class="op">$</span> <span class="dt">Possible</span> ys</span></code></pre></div>
<p>And we change cell pruning functions too:</p>
<div class="sourceCode" id="cb9"><pre class="sourceCode diff"><code class="sourceCode diff"><span id="cb9-1"><a href="#cb9-1"></a> pruneCellsByFixed :: [Cell] -&gt; Maybe [Cell]</span>
<span id="cb9-2"><a href="#cb9-2"></a> pruneCellsByFixed cells = traverse pruneCell cells</span>
<span id="cb9-3"><a href="#cb9-3"></a>   where</span>
<span id="cb9-4"><a href="#cb9-4"></a><span class="st">-    fixeds = [x | Fixed x &lt;- cells]</span></span>
<span id="cb9-5"><a href="#cb9-5"></a><span class="va">+    fixeds = setBits Data.Bits.zeroBits [x | Fixed x &lt;- cells]</span></span>
<span id="cb9-6"><a href="#cb9-6"></a></span>
<span id="cb9-7"><a href="#cb9-7"></a><span class="st">-    pruneCell (Possible xs) = makeCell (xs Data.List.\\ fixeds)</span></span>
<span id="cb9-8"><a href="#cb9-8"></a><span class="va">+    pruneCell (Possible xs) =</span></span>
<span id="cb9-9"><a href="#cb9-9"></a><span class="va">+      makeCell (xs Data.Bits..&amp;. Data.Bits.complement fixeds)</span></span>
<span id="cb9-10"><a href="#cb9-10"></a>     pruneCell x             = Just x</span>
<span id="cb9-11"><a href="#cb9-11"></a></span>
<span id="cb9-12"><a href="#cb9-12"></a> pruneCellsByExclusives :: [Cell] -&gt; Maybe [Cell]</span>
<span id="cb9-13"><a href="#cb9-13"></a> pruneCellsByExclusives cells = case exclusives of</span>
<span id="cb9-14"><a href="#cb9-14"></a>   [] -&gt; Just cells</span>
<span id="cb9-15"><a href="#cb9-15"></a>   _  -&gt; traverse pruneCell cells</span>
<span id="cb9-16"><a href="#cb9-16"></a>   where</span>
<span id="cb9-17"><a href="#cb9-17"></a>     exclusives    = exclusivePossibilities cells</span>
<span id="cb9-18"><a href="#cb9-18"></a><span class="st">-    allExclusives = concat exclusives</span></span>
<span id="cb9-19"><a href="#cb9-19"></a><span class="va">+    allExclusives = setBits Data.Bits.zeroBits exclusives</span></span>
<span id="cb9-20"><a href="#cb9-20"></a></span>
<span id="cb9-21"><a href="#cb9-21"></a>     pruneCell cell@(Fixed _) = Just cell</span>
<span id="cb9-22"><a href="#cb9-22"></a>     pruneCell cell@(Possible xs)</span>
<span id="cb9-23"><a href="#cb9-23"></a>       | intersection `elem` exclusives = makeCell intersection</span>
<span id="cb9-24"><a href="#cb9-24"></a>       | otherwise                      = Just cell</span>
<span id="cb9-25"><a href="#cb9-25"></a>       where</span>
<span id="cb9-26"><a href="#cb9-26"></a><span class="st">-        intersection = xs `Data.List.intersect` allExclusives</span></span>
<span id="cb9-27"><a href="#cb9-27"></a><span class="va">+        intersection = xs Data.Bits..&amp;. allExclusives</span></span></code></pre></div>
<p>Notice how the list difference and intersection functions are replaced by <code>Data.Bits</code> functions. Specifically, list difference is replace by bitwise-and of the bitwise-complement, and list intersection is replaced by bitwise-and.</p>
<p>We make a one-line change in the <code>isGridInvalid</code> function to find empty possible cells using bit ops:</p>
<div class="sourceCode" id="cb10"><pre class="sourceCode diff"><code class="sourceCode diff"><span id="cb10-1"><a href="#cb10-1"></a> isGridInvalid :: Grid -&gt; Bool</span>
<span id="cb10-2"><a href="#cb10-2"></a> isGridInvalid grid =</span>
<span id="cb10-3"><a href="#cb10-3"></a>   any isInvalidRow grid</span>
<span id="cb10-4"><a href="#cb10-4"></a>   || any isInvalidRow (Data.List.transpose grid)</span>
<span id="cb10-5"><a href="#cb10-5"></a>   || any isInvalidRow (subGridsToRows grid)</span>
<span id="cb10-6"><a href="#cb10-6"></a>   where</span>
<span id="cb10-7"><a href="#cb10-7"></a>     isInvalidRow row =</span>
<span id="cb10-8"><a href="#cb10-8"></a>       let fixeds         = [x | Fixed x &lt;- row]</span>
<span id="cb10-9"><a href="#cb10-9"></a><span class="st">-          emptyPossibles = [x | Possible x &lt;- row, null x]</span></span>
<span id="cb10-10"><a href="#cb10-10"></a><span class="va">+          emptyPossibles = [() | Possible x &lt;- row, x == Data.Bits.zeroBits]</span></span>
<span id="cb10-11"><a href="#cb10-11"></a>       in hasDups fixeds || not (null emptyPossibles)</span>
<span id="cb10-12"><a href="#cb10-12"></a></span>
<span id="cb10-13"><a href="#cb10-13"></a>     hasDups l = hasDups' l []</span>
<span id="cb10-14"><a href="#cb10-14"></a></span>
<span id="cb10-15"><a href="#cb10-15"></a>     hasDups' [] _ = False</span>
<span id="cb10-16"><a href="#cb10-16"></a>     hasDups' (y:ys) xs</span>
<span id="cb10-17"><a href="#cb10-17"></a>       | y `elem` xs = True</span>
<span id="cb10-18"><a href="#cb10-18"></a>       | otherwise   = hasDups' ys (y:xs)</span></code></pre></div>
<p>And finally, we change the <code>nextGrids</code> functions to use bit operations:</p>
<div class="sourceCode" id="cb11"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb11-1"><a href="#cb11-1"></a><span class="ot">nextGrids ::</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> (<span class="dt">Grid</span>, <span class="dt">Grid</span>)</span>
<span id="cb11-2"><a href="#cb11-2"></a>nextGrids grid <span class="ot">=</span></span>
<span id="cb11-3"><a href="#cb11-3"></a>  <span class="kw">let</span> (i, first<span class="op">@</span>(<span class="dt">Fixed</span> _), rest) <span class="ot">=</span></span>
<span id="cb11-4"><a href="#cb11-4"></a>        fixCell</span>
<span id="cb11-5"><a href="#cb11-5"></a>        <span class="op">.</span> Data.List.minimumBy (<span class="fu">compare</span> <span class="ot">`Data.Function.on`</span> (possibilityCount <span class="op">.</span> <span class="fu">snd</span>))</span>
<span id="cb11-6"><a href="#cb11-6"></a>        <span class="op">.</span> <span class="fu">filter</span> (isPossible <span class="op">.</span> <span class="fu">snd</span>)</span>
<span id="cb11-7"><a href="#cb11-7"></a>        <span class="op">.</span> <span class="fu">zip</span> [<span class="dv">0</span><span class="op">..</span>]</span>
<span id="cb11-8"><a href="#cb11-8"></a>        <span class="op">.</span> <span class="fu">concat</span></span>
<span id="cb11-9"><a href="#cb11-9"></a>        <span class="op">$</span> grid</span>
<span id="cb11-10"><a href="#cb11-10"></a>  <span class="kw">in</span> (replace2D i first grid, replace2D i rest grid)</span>
<span id="cb11-11"><a href="#cb11-11"></a>  <span class="kw">where</span></span>
<span id="cb11-12"><a href="#cb11-12"></a>    possibilityCount (<span class="dt">Possible</span> xs) <span class="ot">=</span> Data.Bits.popCount xs</span>
<span id="cb11-13"><a href="#cb11-13"></a>    possibilityCount (<span class="dt">Fixed</span> _)     <span class="ot">=</span> <span class="dv">1</span></span>
<span id="cb11-14"><a href="#cb11-14"></a></span>
<span id="cb11-15"><a href="#cb11-15"></a>    fixCell <span class="op">~</span>(i, <span class="dt">Possible</span> xs) <span class="ot">=</span></span>
<span id="cb11-16"><a href="#cb11-16"></a>      <span class="kw">let</span> x <span class="ot">=</span> Data.Bits.countTrailingZeros xs</span>
<span id="cb11-17"><a href="#cb11-17"></a>      <span class="kw">in</span> <span class="kw">case</span> makeCell (Data.Bits.clearBit xs x) <span class="kw">of</span></span>
<span id="cb11-18"><a href="#cb11-18"></a>        <span class="dt">Nothing</span> <span class="ot">-&gt;</span> <span class="fu">error</span> <span class="st">&quot;Impossible case&quot;</span></span>
<span id="cb11-19"><a href="#cb11-19"></a>        <span class="dt">Just</span> cell <span class="ot">-&gt;</span> (i, <span class="dt">Fixed</span> (Data.Bits.bit x), cell)</span>
<span id="cb11-20"><a href="#cb11-20"></a></span>
<span id="cb11-21"><a href="#cb11-21"></a><span class="ot">    replace2D ::</span> <span class="dt">Int</span> <span class="ot">-&gt;</span> a <span class="ot">-&gt;</span> [[a]] <span class="ot">-&gt;</span> [[a]]</span>
<span id="cb11-22"><a href="#cb11-22"></a>    replace2D i v <span class="ot">=</span></span>
<span id="cb11-23"><a href="#cb11-23"></a>      <span class="kw">let</span> (x, y) <span class="ot">=</span> (i <span class="ot">`quot`</span> <span class="dv">9</span>, i <span class="ot">`mod`</span> <span class="dv">9</span>) <span class="kw">in</span> replace x (replace y (<span class="fu">const</span> v))</span>
<span id="cb11-24"><a href="#cb11-24"></a>    replace p f xs <span class="ot">=</span> [<span class="kw">if</span> i <span class="op">==</span> p <span class="kw">then</span> f x <span class="kw">else</span> x <span class="op">|</span> (x, i) <span class="ot">&lt;-</span> <span class="fu">zip</span> xs [<span class="dv">0</span><span class="op">..</span>]]</span></code></pre></div>
<p><code>possibilityCount</code> now uses <code>Data.Bits.popCount</code> to count the number of bits set to 1. <code>fixCell</code> now chooses the first set bit from right as the digit to fix. Rest of the code stays the same. Let’s build and run it:</p>
<pre class="plain"><code>$ stack build
$ cat sudoku17.txt | time stack exec sudoku &gt; /dev/null
       69.44 real        69.12 user         0.37 sys</code></pre>
<p>Wow! That is almost 3.7x faster than the previous solution. It’s a massive win! But let’s not be content yet. To the profiler again!<a href="#fn4" class="footnote-ref" id="fnref4" role="doc-noteref"><sup>4</sup></a></p>
<h2 id="back-to-the-profiler" data-track-content data-content-name="back-to-the-profiler" data-content-piece="fast-sudoku-solver-in-haskell-3">Back to the Profiler<a href="#back-to-the-profiler" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>Running the profiler again gives us these top six culprits:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Cost Centre</th>
<th style="text-align: left;">Src</th>
<th style="text-align: right;">%time</th>
<th style="text-align: right;">%alloc</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities</code></td>
<td style="text-align: left;">Sudoku.hs:(57,1)-(74,26)</td>
<td style="text-align: right;">25.2</td>
<td style="text-align: right;">16.6</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>exclusivePossibilities.\.\</code></td>
<td style="text-align: left;">Sudoku.hs:64:23-96</td>
<td style="text-align: right;">19.0</td>
<td style="text-align: right;">32.8</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>fixM.\</code></td>
<td style="text-align: left;">Sudoku.hs:15:27-65</td>
<td style="text-align: right;">12.5</td>
<td style="text-align: right;">0.1</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>pruneCellsByFixed</code></td>
<td style="text-align: left;">Sudoku.hs:(83,1)-(88,36)</td>
<td style="text-align: right;">5.9</td>
<td style="text-align: right;">7.1</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>pruneGrid'</code></td>
<td style="text-align: left;">Sudoku.hs:(115,1)-(118,64)</td>
<td style="text-align: right;">5.0</td>
<td style="text-align: right;">8.6</td>
</tr>
</tbody>
</table>
</div>
<p>Hurray! <code>pruneCellsByFixed.pruneCell</code> has disappeared from the list of top bottlenecks. Though <code>exclusivePossibilities</code> still remains here as expected.</p>
<p><code>exclusivePossibilities</code> is a big function. The profiler does not really tell us which parts of it are the slow ones. That’s because by default, the profiler only considers functions as <em>Cost Centres</em>. We need to give it hints for it to be able to find bottlenecks inside functions. For that, we need to insert <a href="https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/profiling.html#inserting-cost-centres-by-hand" target="_blank" rel="noopener"><em>Cost Centre</em> annotations</a> in the code:</p>
<div class="sourceCode" id="cb13"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb13-1"><a href="#cb13-1"></a><span class="ot">exclusivePossibilities ::</span> [<span class="dt">Cell</span>] <span class="ot">-&gt;</span> [<span class="dt">Data.Word.Word16</span>]</span>
<span id="cb13-2"><a href="#cb13-2"></a>exclusivePossibilities row <span class="ot">=</span></span>
<span id="cb13-3"><a href="#cb13-3"></a>  row</span>
<span id="cb13-4"><a href="#cb13-4"></a>  <span class="op">&amp;</span> (<span class="ot">{-# SCC &quot;EP.zip&quot; #-}</span> <span class="fu">zip</span> [<span class="dv">1</span><span class="op">..</span><span class="dv">9</span>])</span>
<span id="cb13-5"><a href="#cb13-5"></a>  <span class="op">&amp;</span> (<span class="ot">{-# SCC &quot;EP.filter&quot; #-}</span> <span class="fu">filter</span> (isPossible <span class="op">.</span> <span class="fu">snd</span>))</span>
<span id="cb13-6"><a href="#cb13-6"></a>  <span class="op">&amp;</span> (<span class="ot">{-# SCC &quot;EP.foldl&quot; #-}</span> Data.List.foldl'</span>
<span id="cb13-7"><a href="#cb13-7"></a>      (\acc <span class="op">~</span>(i, <span class="dt">Possible</span> xs) <span class="ot">-&gt;</span></span>
<span id="cb13-8"><a href="#cb13-8"></a>        Data.List.foldl'</span>
<span id="cb13-9"><a href="#cb13-9"></a>          (\acc' n <span class="ot">-&gt;</span> <span class="kw">if</span> Data.Bits.testBit xs n</span>
<span id="cb13-10"><a href="#cb13-10"></a>                      <span class="kw">then</span> Map.insertWith prepend n [i] acc'</span>
<span id="cb13-11"><a href="#cb13-11"></a>                      <span class="kw">else</span> acc')</span>
<span id="cb13-12"><a href="#cb13-12"></a>          acc</span>
<span id="cb13-13"><a href="#cb13-13"></a>          [<span class="dv">1</span><span class="op">..</span><span class="dv">9</span>])</span>
<span id="cb13-14"><a href="#cb13-14"></a>      Map.empty)</span>
<span id="cb13-15"><a href="#cb13-15"></a>  <span class="op">&amp;</span> (<span class="ot">{-# SCC &quot;EP.Map.filter1&quot; #-}</span> Map.filter ((<span class="op">&lt;</span> <span class="dv">4</span>) <span class="op">.</span> <span class="fu">length</span>))</span>
<span id="cb13-16"><a href="#cb13-16"></a>  <span class="op">&amp;</span> (<span class="ot">{-# SCC &quot;EP.Map.foldl&quot; #-}</span></span>
<span id="cb13-17"><a href="#cb13-17"></a>       Map.foldlWithKey'</span>
<span id="cb13-18"><a href="#cb13-18"></a>         (\acc x is <span class="ot">-&gt;</span> Map.insertWith prepend is [x] acc)</span>
<span id="cb13-19"><a href="#cb13-19"></a>         Map.empty)</span>
<span id="cb13-20"><a href="#cb13-20"></a>  <span class="op">&amp;</span> (<span class="ot">{-# SCC &quot;EP.Map.filter2&quot; #-}</span></span>
<span id="cb13-21"><a href="#cb13-21"></a>       Map.filterWithKey (\is xs <span class="ot">-&gt;</span> <span class="fu">length</span> is <span class="op">==</span> <span class="fu">length</span> xs))</span>
<span id="cb13-22"><a href="#cb13-22"></a>  <span class="op">&amp;</span> (<span class="ot">{-# SCC &quot;EP.Map.elems&quot; #-}</span> Map.elems)</span>
<span id="cb13-23"><a href="#cb13-23"></a>  <span class="op">&amp;</span> (<span class="ot">{-# SCC &quot;EP.map&quot; #-}</span></span>
<span id="cb13-24"><a href="#cb13-24"></a>       <span class="fu">map</span> (Data.List.foldl' Data.Bits.setBit Data.Bits.zeroBits))</span>
<span id="cb13-25"><a href="#cb13-25"></a>  <span class="kw">where</span></span>
<span id="cb13-26"><a href="#cb13-26"></a>    prepend <span class="op">~</span>[y] ys <span class="ot">=</span> y<span class="op">:</span>ys</span></code></pre></div>
<p>Here, <code>{-# SCC "EP.zip" #-}</code> is a <em>Cost Centre</em> annotation. <code>"EP.zip"</code> is the name we choose to give to this <em>Cost Centre</em>.</p>
<p>After profiling the code again, we get a different list of bottlenecks:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Cost Centre</th>
<th style="text-align: left;">Src</th>
<th style="text-align: right;">%time</th>
<th style="text-align: right;">%alloc</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities.\.\</code></td>
<td style="text-align: left;">Sudoku.hs:(64,23)-(66,31)</td>
<td style="text-align: right;">19.5</td>
<td style="text-align: right;">31.4</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>fixM.\</code></td>
<td style="text-align: left;">Sudoku.hs:15:27-65</td>
<td style="text-align: right;">13.1</td>
<td style="text-align: right;">0.1</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>pruneCellsByFixed</code></td>
<td style="text-align: left;">Sudoku.hs:(85,1)-(90,36)</td>
<td style="text-align: right;">5.4</td>
<td style="text-align: right;">6.8</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>pruneGrid'</code></td>
<td style="text-align: left;">Sudoku.hs:(117,1)-(120,64)</td>
<td style="text-align: right;">4.8</td>
<td style="text-align: right;">8.3</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>EP.zip</code></td>
<td style="text-align: left;">Sudoku.hs:59:27-36</td>
<td style="text-align: right;">4.3</td>
<td style="text-align: right;">10.7</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>EP.Map.filter1</code></td>
<td style="text-align: left;">Sudoku.hs:70:35-61</td>
<td style="text-align: right;">4.2</td>
<td style="text-align: right;">0.5</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>chunksOf</code></td>
<td style="text-align: left;">Data/List/Split/Internals.hs:(514,1)-(517,49)</td>
<td style="text-align: right;">4.1</td>
<td style="text-align: right;">7.4</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>exclusivePossibilities.\</code></td>
<td style="text-align: left;">Sudoku.hs:71:64-96</td>
<td style="text-align: right;">4.0</td>
<td style="text-align: right;">3.4</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>EP.filter</code></td>
<td style="text-align: left;">Sudoku.hs:60:30-54</td>
<td style="text-align: right;">2.9</td>
<td style="text-align: right;">3.4</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>EP.foldl</code></td>
<td style="text-align: left;">Sudoku.hs:(61,29)-(69,15)</td>
<td style="text-align: right;">2.8</td>
<td style="text-align: right;">1.8</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities</code></td>
<td style="text-align: left;">Sudoku.hs:(57,1)-(76,26)</td>
<td style="text-align: right;">2.7</td>
<td style="text-align: right;">1.9</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>chunksOf.splitter</code></td>
<td style="text-align: left;">Data/List/Split/Internals.hs:(516,3)-(517,49)</td>
<td style="text-align: right;">2.5</td>
<td style="text-align: right;">2.7</td>
</tr>
</tbody>
</table>
</div>
<p>So almost one-fifth of the time is actually going in this nested one-line anonymous function inside <code>exclusivePossibilities</code>:</p>
<div class="sourceCode" id="cb14"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb14-1"><a href="#cb14-1"></a>(\acc' n <span class="ot">-&gt;</span></span>
<span id="cb14-2"><a href="#cb14-2"></a>    <span class="kw">if</span> Data.Bits.testBit xs n <span class="kw">then</span> Map.insertWith prepend n [i] acc' <span class="kw">else</span> acc')</span></code></pre></div>
<p>But we are going to ignore it for now.</p>
<p>If we look closely, we also find that around 17% of the run time now goes into list traversal and manipulation. This is in the functions <code>pruneCellsByFixed</code>, <code>pruneGrid'</code>, <code>chunksOf</code> and <code>chunksOf.splitter</code>, where the first two are majorly list traversal and transposition, and the last two are list splitting. Maybe it is time to get rid of lists altogether?</p>
<h2 id="vectors-of-speed" data-track-content data-content-name="vectors-of-speed" data-content-piece="fast-sudoku-solver-in-haskell-3">Vectors of Speed<a href="#vectors-of-speed" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p><a href="https://hackage.haskell.org/package/vector-0.12.0.1" target="_blank" rel="noopener">Vector</a> is a Haskell library for working with arrays. It implements very performant operations for integer-indexed array data. Unlike the lists in Haskell which are implemented as <a href="https://en.wikipedia.org/wiki/Linked_list#Singly_linked_list" target="_blank" rel="noopener">singly linked lists</a>, vectors are stored in a contiguous set of memory locations. This makes random access to the elements a constant time operation. The memory overhead per additional item in vectors is also much smaller. Lists allocate memory for each item in the heap and have pointers to the memory locations in nodes, leading to a lot of wasted memory in holding pointers. On the other hand, operations on lists are lazy, whereas, operations on vectors are strict, and this may need to useless computation depending on the use-case<a href="#fn5" class="footnote-ref" id="fnref5" role="doc-noteref"><sup>5</sup></a>.</p>
<p>In our current code, we represent the grid as a list of lists of cells. All the pruning operations require us to traverse the grid list or the row lists. We also need to transform the grid back-and-forth for being able to use the same pruning operations for rows, columns and sub-grids. The pruning of cells and the choosing of pivot cells also requires us to replace cells in the grid with new ones, leading to a lot of list traversals.</p>
<p>To prevent all this linear-time list traversals, we can replace the nested list of lists with a single vector. Then all we need to do it to go over the right parts of this vector, looking up and replacing cells as needed. Since both lookups and updates on vectors are constant time, this should lead to a speedup.</p>
<p>Let’s start by changing the grid to a vector of cells.:</p>
<div class="sourceCode" id="cb15"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb15-1"><a href="#cb15-1"></a><span class="kw">data</span> <span class="dt">Cell</span> <span class="ot">=</span> <span class="dt">Fixed</span> <span class="dt">Data.Word.Word16</span></span>
<span id="cb15-2"><a href="#cb15-2"></a>          <span class="op">|</span> <span class="dt">Possible</span> <span class="dt">Data.Word.Word16</span></span>
<span id="cb15-3"><a href="#cb15-3"></a>          <span class="kw">deriving</span> (<span class="dt">Show</span>, <span class="dt">Eq</span>)</span>
<span id="cb15-4"><a href="#cb15-4"></a></span>
<span id="cb15-5"><a href="#cb15-5"></a><span class="kw">type</span> <span class="dt">Grid</span> <span class="ot">=</span> <span class="dt">Data.Vector.Vector</span> <span class="dt">Cell</span></span></code></pre></div>
<p>Since we plan to traverse different parts of the same vector, let’s define these different parts first:</p>
<div class="sourceCode" id="cb16"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb16-1"><a href="#cb16-1"></a><span class="kw">type</span> <span class="dt">CellIxs</span> <span class="ot">=</span> [<span class="dt">Int</span>]</span>
<span id="cb16-2"><a href="#cb16-2"></a></span>
<span id="cb16-3"><a href="#cb16-3"></a><span class="ot">fromXY ::</span> (<span class="dt">Int</span>, <span class="dt">Int</span>) <span class="ot">-&gt;</span> <span class="dt">Int</span></span>
<span id="cb16-4"><a href="#cb16-4"></a>fromXY (x, y) <span class="ot">=</span> x <span class="op">*</span> <span class="dv">9</span> <span class="op">+</span> y</span>
<span id="cb16-5"><a href="#cb16-5"></a></span>
<span id="cb16-6"><a href="#cb16-6"></a>allRowIxs, allColIxs,<span class="ot"> allSubGridIxs ::</span> [<span class="dt">CellIxs</span>]</span>
<span id="cb16-7"><a href="#cb16-7"></a>allRowIxs <span class="ot">=</span> [getRow i <span class="op">|</span> i <span class="ot">&lt;-</span> [<span class="dv">0</span><span class="op">..</span><span class="dv">8</span>]]</span>
<span id="cb16-8"><a href="#cb16-8"></a>  <span class="kw">where</span> getRow n <span class="ot">=</span> [ fromXY (n, i) <span class="op">|</span> i <span class="ot">&lt;-</span> [<span class="dv">0</span><span class="op">..</span><span class="dv">8</span>] ]</span>
<span id="cb16-9"><a href="#cb16-9"></a></span>
<span id="cb16-10"><a href="#cb16-10"></a>allColIxs <span class="ot">=</span> [getCol i <span class="op">|</span> i <span class="ot">&lt;-</span> [<span class="dv">0</span><span class="op">..</span><span class="dv">8</span>]]</span>
<span id="cb16-11"><a href="#cb16-11"></a>  <span class="kw">where</span> getCol n <span class="ot">=</span> [ fromXY (i, n) <span class="op">|</span> i <span class="ot">&lt;-</span> [<span class="dv">0</span><span class="op">..</span><span class="dv">8</span>] ]</span>
<span id="cb16-12"><a href="#cb16-12"></a></span>
<span id="cb16-13"><a href="#cb16-13"></a>allSubGridIxs <span class="ot">=</span> [getSubGrid i <span class="op">|</span> i <span class="ot">&lt;-</span> [<span class="dv">0</span><span class="op">..</span><span class="dv">8</span>]]</span>
<span id="cb16-14"><a href="#cb16-14"></a>  <span class="kw">where</span> getSubGrid n <span class="ot">=</span> <span class="kw">let</span> (r, c) <span class="ot">=</span> (n <span class="ot">`quot`</span> <span class="dv">3</span>, n <span class="ot">`mod`</span> <span class="dv">3</span>)</span>
<span id="cb16-15"><a href="#cb16-15"></a>          <span class="kw">in</span> [ fromXY (<span class="dv">3</span> <span class="op">*</span> r <span class="op">+</span> i, <span class="dv">3</span> <span class="op">*</span> c <span class="op">+</span> j) <span class="op">|</span> i <span class="ot">&lt;-</span> [<span class="dv">0</span><span class="op">..</span><span class="dv">2</span>], j <span class="ot">&lt;-</span> [<span class="dv">0</span><span class="op">..</span><span class="dv">2</span>] ]</span></code></pre></div>
<p>We define a type for cell indices as a list of integers. Then we create three lists of cell indices: all row indices, all column indices, and all sub-grid indices. Let’s check these out in the <em>REPL</em>:</p>
<div class="sourceCode" id="cb17"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb17-1"><a href="#cb17-1"></a><span class="op">*</span><span class="dt">Main</span><span class="op">&gt;</span> Control.Monad.mapM_ <span class="fu">print</span> allRowIxs</span>
<span id="cb17-2"><a href="#cb17-2"></a>[<span class="dv">0</span>,<span class="dv">1</span>,<span class="dv">2</span>,<span class="dv">3</span>,<span class="dv">4</span>,<span class="dv">5</span>,<span class="dv">6</span>,<span class="dv">7</span>,<span class="dv">8</span>]</span>
<span id="cb17-3"><a href="#cb17-3"></a>[<span class="dv">9</span>,<span class="dv">10</span>,<span class="dv">11</span>,<span class="dv">12</span>,<span class="dv">13</span>,<span class="dv">14</span>,<span class="dv">15</span>,<span class="dv">16</span>,<span class="dv">17</span>]</span>
<span id="cb17-4"><a href="#cb17-4"></a>[<span class="dv">18</span>,<span class="dv">19</span>,<span class="dv">20</span>,<span class="dv">21</span>,<span class="dv">22</span>,<span class="dv">23</span>,<span class="dv">24</span>,<span class="dv">25</span>,<span class="dv">26</span>]</span>
<span id="cb17-5"><a href="#cb17-5"></a>[<span class="dv">27</span>,<span class="dv">28</span>,<span class="dv">29</span>,<span class="dv">30</span>,<span class="dv">31</span>,<span class="dv">32</span>,<span class="dv">33</span>,<span class="dv">34</span>,<span class="dv">35</span>]</span>
<span id="cb17-6"><a href="#cb17-6"></a>[<span class="dv">36</span>,<span class="dv">37</span>,<span class="dv">38</span>,<span class="dv">39</span>,<span class="dv">40</span>,<span class="dv">41</span>,<span class="dv">42</span>,<span class="dv">43</span>,<span class="dv">44</span>]</span>
<span id="cb17-7"><a href="#cb17-7"></a>[<span class="dv">45</span>,<span class="dv">46</span>,<span class="dv">47</span>,<span class="dv">48</span>,<span class="dv">49</span>,<span class="dv">50</span>,<span class="dv">51</span>,<span class="dv">52</span>,<span class="dv">53</span>]</span>
<span id="cb17-8"><a href="#cb17-8"></a>[<span class="dv">54</span>,<span class="dv">55</span>,<span class="dv">56</span>,<span class="dv">57</span>,<span class="dv">58</span>,<span class="dv">59</span>,<span class="dv">60</span>,<span class="dv">61</span>,<span class="dv">62</span>]</span>
<span id="cb17-9"><a href="#cb17-9"></a>[<span class="dv">63</span>,<span class="dv">64</span>,<span class="dv">65</span>,<span class="dv">66</span>,<span class="dv">67</span>,<span class="dv">68</span>,<span class="dv">69</span>,<span class="dv">70</span>,<span class="dv">71</span>]</span>
<span id="cb17-10"><a href="#cb17-10"></a>[<span class="dv">72</span>,<span class="dv">73</span>,<span class="dv">74</span>,<span class="dv">75</span>,<span class="dv">76</span>,<span class="dv">77</span>,<span class="dv">78</span>,<span class="dv">79</span>,<span class="dv">80</span>]</span>
<span id="cb17-11"><a href="#cb17-11"></a><span class="op">*</span><span class="dt">Main</span><span class="op">&gt;</span> Control.Monad.mapM_ <span class="fu">print</span> allColIxs</span>
<span id="cb17-12"><a href="#cb17-12"></a>[<span class="dv">0</span>,<span class="dv">9</span>,<span class="dv">18</span>,<span class="dv">27</span>,<span class="dv">36</span>,<span class="dv">45</span>,<span class="dv">54</span>,<span class="dv">63</span>,<span class="dv">72</span>]</span>
<span id="cb17-13"><a href="#cb17-13"></a>[<span class="dv">1</span>,<span class="dv">10</span>,<span class="dv">19</span>,<span class="dv">28</span>,<span class="dv">37</span>,<span class="dv">46</span>,<span class="dv">55</span>,<span class="dv">64</span>,<span class="dv">73</span>]</span>
<span id="cb17-14"><a href="#cb17-14"></a>[<span class="dv">2</span>,<span class="dv">11</span>,<span class="dv">20</span>,<span class="dv">29</span>,<span class="dv">38</span>,<span class="dv">47</span>,<span class="dv">56</span>,<span class="dv">65</span>,<span class="dv">74</span>]</span>
<span id="cb17-15"><a href="#cb17-15"></a>[<span class="dv">3</span>,<span class="dv">12</span>,<span class="dv">21</span>,<span class="dv">30</span>,<span class="dv">39</span>,<span class="dv">48</span>,<span class="dv">57</span>,<span class="dv">66</span>,<span class="dv">75</span>]</span>
<span id="cb17-16"><a href="#cb17-16"></a>[<span class="dv">4</span>,<span class="dv">13</span>,<span class="dv">22</span>,<span class="dv">31</span>,<span class="dv">40</span>,<span class="dv">49</span>,<span class="dv">58</span>,<span class="dv">67</span>,<span class="dv">76</span>]</span>
<span id="cb17-17"><a href="#cb17-17"></a>[<span class="dv">5</span>,<span class="dv">14</span>,<span class="dv">23</span>,<span class="dv">32</span>,<span class="dv">41</span>,<span class="dv">50</span>,<span class="dv">59</span>,<span class="dv">68</span>,<span class="dv">77</span>]</span>
<span id="cb17-18"><a href="#cb17-18"></a>[<span class="dv">6</span>,<span class="dv">15</span>,<span class="dv">24</span>,<span class="dv">33</span>,<span class="dv">42</span>,<span class="dv">51</span>,<span class="dv">60</span>,<span class="dv">69</span>,<span class="dv">78</span>]</span>
<span id="cb17-19"><a href="#cb17-19"></a>[<span class="dv">7</span>,<span class="dv">16</span>,<span class="dv">25</span>,<span class="dv">34</span>,<span class="dv">43</span>,<span class="dv">52</span>,<span class="dv">61</span>,<span class="dv">70</span>,<span class="dv">79</span>]</span>
<span id="cb17-20"><a href="#cb17-20"></a>[<span class="dv">8</span>,<span class="dv">17</span>,<span class="dv">26</span>,<span class="dv">35</span>,<span class="dv">44</span>,<span class="dv">53</span>,<span class="dv">62</span>,<span class="dv">71</span>,<span class="dv">80</span>]</span>
<span id="cb17-21"><a href="#cb17-21"></a><span class="op">*</span><span class="dt">Main</span><span class="op">&gt;</span> Control.Monad.mapM_ <span class="fu">print</span> allSubGridIxs</span>
<span id="cb17-22"><a href="#cb17-22"></a>[<span class="dv">0</span>,<span class="dv">1</span>,<span class="dv">2</span>,<span class="dv">9</span>,<span class="dv">10</span>,<span class="dv">11</span>,<span class="dv">18</span>,<span class="dv">19</span>,<span class="dv">20</span>]</span>
<span id="cb17-23"><a href="#cb17-23"></a>[<span class="dv">3</span>,<span class="dv">4</span>,<span class="dv">5</span>,<span class="dv">12</span>,<span class="dv">13</span>,<span class="dv">14</span>,<span class="dv">21</span>,<span class="dv">22</span>,<span class="dv">23</span>]</span>
<span id="cb17-24"><a href="#cb17-24"></a>[<span class="dv">6</span>,<span class="dv">7</span>,<span class="dv">8</span>,<span class="dv">15</span>,<span class="dv">16</span>,<span class="dv">17</span>,<span class="dv">24</span>,<span class="dv">25</span>,<span class="dv">26</span>]</span>
<span id="cb17-25"><a href="#cb17-25"></a>[<span class="dv">27</span>,<span class="dv">28</span>,<span class="dv">29</span>,<span class="dv">36</span>,<span class="dv">37</span>,<span class="dv">38</span>,<span class="dv">45</span>,<span class="dv">46</span>,<span class="dv">47</span>]</span>
<span id="cb17-26"><a href="#cb17-26"></a>[<span class="dv">30</span>,<span class="dv">31</span>,<span class="dv">32</span>,<span class="dv">39</span>,<span class="dv">40</span>,<span class="dv">41</span>,<span class="dv">48</span>,<span class="dv">49</span>,<span class="dv">50</span>]</span>
<span id="cb17-27"><a href="#cb17-27"></a>[<span class="dv">33</span>,<span class="dv">34</span>,<span class="dv">35</span>,<span class="dv">42</span>,<span class="dv">43</span>,<span class="dv">44</span>,<span class="dv">51</span>,<span class="dv">52</span>,<span class="dv">53</span>]</span>
<span id="cb17-28"><a href="#cb17-28"></a>[<span class="dv">54</span>,<span class="dv">55</span>,<span class="dv">56</span>,<span class="dv">63</span>,<span class="dv">64</span>,<span class="dv">65</span>,<span class="dv">72</span>,<span class="dv">73</span>,<span class="dv">74</span>]</span>
<span id="cb17-29"><a href="#cb17-29"></a>[<span class="dv">57</span>,<span class="dv">58</span>,<span class="dv">59</span>,<span class="dv">66</span>,<span class="dv">67</span>,<span class="dv">68</span>,<span class="dv">75</span>,<span class="dv">76</span>,<span class="dv">77</span>]</span>
<span id="cb17-30"><a href="#cb17-30"></a>[<span class="dv">60</span>,<span class="dv">61</span>,<span class="dv">62</span>,<span class="dv">69</span>,<span class="dv">70</span>,<span class="dv">71</span>,<span class="dv">78</span>,<span class="dv">79</span>,<span class="dv">80</span>]</span></code></pre></div>
<p>We can verify manually that these indices are correct.</p>
<p>Read and show functions are easy to change for vector:</p>
<div class="sourceCode" id="cb18"><pre class="sourceCode diff"><code class="sourceCode diff"><span id="cb18-1"><a href="#cb18-1"></a> readGrid :: String -&gt; Maybe Grid</span>
<span id="cb18-2"><a href="#cb18-2"></a> readGrid s</span>
<span id="cb18-3"><a href="#cb18-3"></a><span class="st">-  | length s == 81 = traverse (traverse readCell) . Data.List.Split.chunksOf 9 $ s</span></span>
<span id="cb18-4"><a href="#cb18-4"></a><span class="va">+  | length s == 81 = Data.Vector.fromList &lt;$&gt; traverse readCell s</span></span>
<span id="cb18-5"><a href="#cb18-5"></a>   | otherwise      = Nothing</span>
<span id="cb18-6"><a href="#cb18-6"></a>   where</span>
<span id="cb18-7"><a href="#cb18-7"></a>     allBitsSet = 1022</span>
<span id="cb18-8"><a href="#cb18-8"></a></span>
<span id="cb18-9"><a href="#cb18-9"></a>     readCell '.' = Just $ Possible allBitsSet</span>
<span id="cb18-10"><a href="#cb18-10"></a>     readCell c</span>
<span id="cb18-11"><a href="#cb18-11"></a>       | Data.Char.isDigit c &amp;&amp; c &gt; '0' =</span>
<span id="cb18-12"><a href="#cb18-12"></a>           Just . Fixed . Data.Bits.bit . Data.Char.digitToInt $ c</span>
<span id="cb18-13"><a href="#cb18-13"></a>       | otherwise = Nothing</span>
<span id="cb18-14"><a href="#cb18-14"></a></span>
<span id="cb18-15"><a href="#cb18-15"></a> showGrid :: Grid -&gt; String</span>
<span id="cb18-16"><a href="#cb18-16"></a><span class="st">-showGrid = unlines . map (unwords . map showCell)</span></span>
<span id="cb18-17"><a href="#cb18-17"></a><span class="va">+showGrid grid =</span></span>
<span id="cb18-18"><a href="#cb18-18"></a><span class="va">+  unlines . map (unwords . map (showCell . (grid !))) $ allRowIxs</span></span>
<span id="cb18-19"><a href="#cb18-19"></a>   where</span>
<span id="cb18-20"><a href="#cb18-20"></a>     showCell (Fixed x) = show . Data.Bits.countTrailingZeros $ x</span>
<span id="cb18-21"><a href="#cb18-21"></a>     showCell _         = &quot;.&quot;</span>
<span id="cb18-22"><a href="#cb18-22"></a></span>
<span id="cb18-23"><a href="#cb18-23"></a> showGridWithPossibilities :: Grid -&gt; String</span>
<span id="cb18-24"><a href="#cb18-24"></a><span class="st">-showGridWithPossibilities = unlines . map (unwords . map showCell)</span></span>
<span id="cb18-25"><a href="#cb18-25"></a><span class="va">+showGridWithPossibilities grid =</span></span>
<span id="cb18-26"><a href="#cb18-26"></a><span class="va">+  unlines . map (unwords . map (showCell . (grid !))) $ allRowIxs</span></span>
<span id="cb18-27"><a href="#cb18-27"></a>   where</span>
<span id="cb18-28"><a href="#cb18-28"></a>     showCell (Fixed x) = (show . Data.Bits.countTrailingZeros $ x) ++ &quot;          &quot;</span>
<span id="cb18-29"><a href="#cb18-29"></a>     showCell (Possible xs) =</span>
<span id="cb18-30"><a href="#cb18-30"></a>       &quot;[&quot; ++</span>
<span id="cb18-31"><a href="#cb18-31"></a>       map (\i -&gt; if Data.Bits.testBit xs i</span>
<span id="cb18-32"><a href="#cb18-32"></a>                  then Data.Char.intToDigit i</span>
<span id="cb18-33"><a href="#cb18-33"></a>                  else ' ')</span>
<span id="cb18-34"><a href="#cb18-34"></a>           [1..9]</span>
<span id="cb18-35"><a href="#cb18-35"></a>       ++ &quot;]&quot;</span></code></pre></div>
<p><code>readGrid</code> simply changes to work on a single vector of cells instead of a list of lists. Show functions have a pretty minor change to do lookups from a vector using the row indices and the <a href="https://hackage.haskell.org/package/vector-0.12.0.1/docs/Data-Vector.html#v:-33-" target="_blank" rel="noopener"><code>(!)</code></a> function. The <code>(!)</code> function is the vector indexing function which is similar to the <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Prelude.html#v:-33--33-" target="_blank" rel="noopener"><code>(!!)</code></a> function, except it executes in constant time.</p>
<p>The pruning related functions are rewritten for working with vectors:</p>
<div class="sourceCode" id="cb19"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb19-1"><a href="#cb19-1"></a><span class="ot">replaceCell ::</span> <span class="dt">Int</span> <span class="ot">-&gt;</span> <span class="dt">Cell</span> <span class="ot">-&gt;</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> <span class="dt">Grid</span></span>
<span id="cb19-2"><a href="#cb19-2"></a>replaceCell i c g <span class="ot">=</span> g <span class="op">Data.Vector.//</span> [(i, c)]</span>
<span id="cb19-3"><a href="#cb19-3"></a></span>
<span id="cb19-4"><a href="#cb19-4"></a><span class="ot">pruneCellsByFixed ::</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> <span class="dt">CellIxs</span> <span class="ot">-&gt;</span> <span class="dt">Maybe</span> <span class="dt">Grid</span></span>
<span id="cb19-5"><a href="#cb19-5"></a>pruneCellsByFixed grid cellIxs <span class="ot">=</span></span>
<span id="cb19-6"><a href="#cb19-6"></a>  Control.Monad.foldM pruneCell grid <span class="op">.</span> <span class="fu">map</span> (\i <span class="ot">-&gt;</span> (i, grid <span class="op">!</span> i)) <span class="op">$</span> cellIxs</span>
<span id="cb19-7"><a href="#cb19-7"></a>  <span class="kw">where</span></span>
<span id="cb19-8"><a href="#cb19-8"></a>    fixeds <span class="ot">=</span> setBits Data.Bits.zeroBits [x <span class="op">|</span> <span class="dt">Fixed</span> x <span class="ot">&lt;-</span> <span class="fu">map</span> (grid <span class="op">!</span>) cellIxs]</span>
<span id="cb19-9"><a href="#cb19-9"></a></span>
<span id="cb19-10"><a href="#cb19-10"></a>    pruneCell g (_, <span class="dt">Fixed</span> _) <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb19-11"><a href="#cb19-11"></a>    pruneCell g (i, <span class="dt">Possible</span> xs)</span>
<span id="cb19-12"><a href="#cb19-12"></a>      <span class="op">|</span> xs' <span class="op">==</span> xs <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb19-13"><a href="#cb19-13"></a>      <span class="op">|</span> <span class="fu">otherwise</span> <span class="ot">=</span> <span class="fu">flip</span> (replaceCell i) g <span class="op">&lt;$&gt;</span> makeCell xs'</span>
<span id="cb19-14"><a href="#cb19-14"></a>      <span class="kw">where</span></span>
<span id="cb19-15"><a href="#cb19-15"></a>        xs' <span class="ot">=</span> xs <span class="op">Data.Bits..&amp;.</span> Data.Bits.complement fixeds</span>
<span id="cb19-16"><a href="#cb19-16"></a></span>
<span id="cb19-17"><a href="#cb19-17"></a><span class="ot">pruneCellsByExclusives ::</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> <span class="dt">CellIxs</span> <span class="ot">-&gt;</span> <span class="dt">Maybe</span> <span class="dt">Grid</span></span>
<span id="cb19-18"><a href="#cb19-18"></a>pruneCellsByExclusives grid cellIxs <span class="ot">=</span> <span class="kw">case</span> exclusives <span class="kw">of</span></span>
<span id="cb19-19"><a href="#cb19-19"></a>  [] <span class="ot">-&gt;</span> <span class="dt">Just</span> grid</span>
<span id="cb19-20"><a href="#cb19-20"></a>  _  <span class="ot">-&gt;</span> Control.Monad.foldM pruneCell grid <span class="op">.</span> <span class="fu">zip</span> cellIxs <span class="op">$</span> cells</span>
<span id="cb19-21"><a href="#cb19-21"></a>  <span class="kw">where</span></span>
<span id="cb19-22"><a href="#cb19-22"></a>    cells         <span class="ot">=</span> <span class="fu">map</span> (grid <span class="op">!</span>) cellIxs</span>
<span id="cb19-23"><a href="#cb19-23"></a>    exclusives    <span class="ot">=</span> exclusivePossibilities cells</span>
<span id="cb19-24"><a href="#cb19-24"></a>    allExclusives <span class="ot">=</span> setBits Data.Bits.zeroBits exclusives</span>
<span id="cb19-25"><a href="#cb19-25"></a></span>
<span id="cb19-26"><a href="#cb19-26"></a>    pruneCell g (_, <span class="dt">Fixed</span> _) <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb19-27"><a href="#cb19-27"></a>    pruneCell g (i, <span class="dt">Possible</span> xs)</span>
<span id="cb19-28"><a href="#cb19-28"></a>      <span class="op">|</span> intersection <span class="op">==</span> xs             <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb19-29"><a href="#cb19-29"></a>      <span class="op">|</span> intersection <span class="ot">`elem`</span> exclusives <span class="ot">=</span></span>
<span id="cb19-30"><a href="#cb19-30"></a>          <span class="fu">flip</span> (replaceCell i) g <span class="op">&lt;$&gt;</span> makeCell intersection</span>
<span id="cb19-31"><a href="#cb19-31"></a>      <span class="op">|</span> <span class="fu">otherwise</span>                      <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb19-32"><a href="#cb19-32"></a>      <span class="kw">where</span></span>
<span id="cb19-33"><a href="#cb19-33"></a>        intersection <span class="ot">=</span> xs <span class="op">Data.Bits..&amp;.</span> allExclusives</span>
<span id="cb19-34"><a href="#cb19-34"></a></span>
<span id="cb19-35"><a href="#cb19-35"></a><span class="ot">pruneCells ::</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> <span class="dt">CellIxs</span> <span class="ot">-&gt;</span> <span class="dt">Maybe</span> <span class="dt">Grid</span></span>
<span id="cb19-36"><a href="#cb19-36"></a>pruneCells grid cellIxs <span class="ot">=</span></span>
<span id="cb19-37"><a href="#cb19-37"></a>  fixM (<span class="fu">flip</span> pruneCellsByFixed cellIxs) grid</span>
<span id="cb19-38"><a href="#cb19-38"></a>  <span class="op">&gt;&gt;=</span> fixM (<span class="fu">flip</span> pruneCellsByExclusives cellIxs)</span></code></pre></div>
<p>All the three functions now take the grid and the cell indices instead of a list of cells, and use the cell indices to lookup the cells from the grid. Also, instead of using the <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Data-Traversable.html#v:traverse" target="_blank" rel="noopener"><code>traverse</code></a> function as earlier, now we use the <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Control-Monad.html#v:foldM" target="_blank" rel="noopener"><code>Control.Monad.foldM</code></a> function to fold over the cell-index-and-cell tuples in the context of the <code>Maybe</code> monad, making changes to the grid directly.</p>
<p>We use the <code>replaceCell</code> function to replace cells at an index in the grid. It is a simple wrapper over the vector update function <code>Data.Vector.//</code>. Rest of the code is same in essence, except a few changes to accommodate the changed function parameters.</p>
<p><code>pruneGrid'</code> function does not need to do transpositions and back-transpositions anymore as now we use the cell indices to go over the right parts of the grid vector directly:</p>
<div class="sourceCode" id="cb20"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb20-1"><a href="#cb20-1"></a><span class="ot">pruneGrid' ::</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> <span class="dt">Maybe</span> <span class="dt">Grid</span></span>
<span id="cb20-2"><a href="#cb20-2"></a>pruneGrid' grid <span class="ot">=</span></span>
<span id="cb20-3"><a href="#cb20-3"></a>  Control.Monad.foldM pruneCells grid allRowIxs</span>
<span id="cb20-4"><a href="#cb20-4"></a>  <span class="op">&gt;&gt;=</span> <span class="fu">flip</span> (Control.Monad.foldM pruneCells) allColIxs</span>
<span id="cb20-5"><a href="#cb20-5"></a>  <span class="op">&gt;&gt;=</span> <span class="fu">flip</span> (Control.Monad.foldM pruneCells) allSubGridIxs</span></code></pre></div>
<p>Notice that the <code>traverse</code> function here is also replaced by the <code>Control.Monad.foldM</code> function.</p>
<p>Similarly, the grid predicate functions change a little to go over a vector instead of a list of lists:</p>
<div class="sourceCode" id="cb21"><pre class="sourceCode diff"><code class="sourceCode diff"><span id="cb21-1"><a href="#cb21-1"></a> isGridFilled :: Grid -&gt; Bool</span>
<span id="cb21-2"><a href="#cb21-2"></a><span class="st">-isGridFilled grid = null [ () | Possible _ &lt;- concat grid ]</span></span>
<span id="cb21-3"><a href="#cb21-3"></a><span class="va">+isGridFilled = not . Data.Vector.any isPossible</span></span>
<span id="cb21-4"><a href="#cb21-4"></a></span>
<span id="cb21-5"><a href="#cb21-5"></a> isGridInvalid :: Grid -&gt; Bool</span>
<span id="cb21-6"><a href="#cb21-6"></a> isGridInvalid grid =</span>
<span id="cb21-7"><a href="#cb21-7"></a><span class="st">-  any isInvalidRow grid</span></span>
<span id="cb21-8"><a href="#cb21-8"></a><span class="st">-  || any isInvalidRow (Data.List.transpose grid)</span></span>
<span id="cb21-9"><a href="#cb21-9"></a><span class="st">-  || any isInvalidRow (subGridsToRows grid)</span></span>
<span id="cb21-10"><a href="#cb21-10"></a><span class="va">+  any isInvalidRow (map (map (grid !)) allRowIxs)</span></span>
<span id="cb21-11"><a href="#cb21-11"></a><span class="va">+  || any isInvalidRow (map (map (grid !)) allColIxs)</span></span>
<span id="cb21-12"><a href="#cb21-12"></a><span class="va">+  || any isInvalidRow (map (map (grid !)) allSubGridIxs)</span></span></code></pre></div>
<p>And finally, we change the <code>nextGrids</code> function to replace the list related operations with the vector related ones:</p>
<div class="sourceCode" id="cb22"><pre class="sourceCode diff"><code class="sourceCode diff"><span id="cb22-1"><a href="#cb22-1"></a> nextGrids :: Grid -&gt; (Grid, Grid)</span>
<span id="cb22-2"><a href="#cb22-2"></a> nextGrids grid =</span>
<span id="cb22-3"><a href="#cb22-3"></a>   let (i, first@(Fixed _), rest) =</span>
<span id="cb22-4"><a href="#cb22-4"></a>         fixCell</span>
<span id="cb22-5"><a href="#cb22-5"></a><span class="st">-        . Data.List.minimumBy</span></span>
<span id="cb22-6"><a href="#cb22-6"></a><span class="va">+        . Data.Vector.minimumBy</span></span>
<span id="cb22-7"><a href="#cb22-7"></a>             (compare `Data.Function.on` (possibilityCount . snd))</span>
<span id="cb22-8"><a href="#cb22-8"></a><span class="st">-        . filter (isPossible . snd)</span></span>
<span id="cb22-9"><a href="#cb22-9"></a><span class="st">-        . zip [0..]</span></span>
<span id="cb22-10"><a href="#cb22-10"></a><span class="st">-        . concat</span></span>
<span id="cb22-11"><a href="#cb22-11"></a><span class="va">+        . Data.Vector.imapMaybe</span></span>
<span id="cb22-12"><a href="#cb22-12"></a><span class="va">+            (\j cell -&gt; if isPossible cell then Just (j, cell) else Nothing)</span></span>
<span id="cb22-13"><a href="#cb22-13"></a>         $ grid</span>
<span id="cb22-14"><a href="#cb22-14"></a><span class="st">-  in (replace2D i first grid, replace2D i rest grid)</span></span>
<span id="cb22-15"><a href="#cb22-15"></a><span class="va">+  in (replaceCell i first grid, replaceCell i rest grid)</span></span></code></pre></div>
<p>We also switch the <code>replace2D</code> function which went over the entire list of lists of cells to replace a cell, with the vector-based <code>replaceCell</code> function.</p>
<p>All the required changes are done. Let’s do a run:</p>
<pre class="plain"><code>$ stack build
$ cat sudoku17.txt | time stack exec sudoku &gt; /dev/null
       88.53 real        88.16 user         0.41 sys</code></pre>
<p>Oops! Instead of getting a speedup, our vector-based code is actually 1.3x slower than the list-based code. How did this happen? Time to bust out the profiler again!</p>
<h2 id="revenge-of-the" data-track-content data-content-name="revenge-of-the" data-content-piece="fast-sudoku-solver-in-haskell-3">Revenge of the <code>(==)</code><a href="#revenge-of-the" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>Profiling the current code gives us the following hotspots:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Cost Centre</th>
<th style="text-align: left;">Src</th>
<th style="text-align: right;">%time</th>
<th style="text-align: right;">%alloc</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><code>&gt;&gt;=</code></td>
<td style="text-align: left;">Data/Vector/Fusion/Util.hs:36:3-18</td>
<td style="text-align: right;">52.2</td>
<td style="text-align: right;">51.0</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>basicUnsafeIndexM</code></td>
<td style="text-align: left;">Data/Vector.hs:278:3-62</td>
<td style="text-align: right;">22.2</td>
<td style="text-align: right;">20.4</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities</code></td>
<td style="text-align: left;">Sudoku.hs:(75,1)-(93,26)</td>
<td style="text-align: right;">6.8</td>
<td style="text-align: right;">8.3</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>exclusivePossibilities.\.\</code></td>
<td style="text-align: left;">Sudoku.hs:83:23-96</td>
<td style="text-align: right;">3.8</td>
<td style="text-align: right;">8.8</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>pruneCellsByFixed.fixeds</code></td>
<td style="text-align: left;">Sudoku.hs:105:5-77</td>
<td style="text-align: right;">2.0</td>
<td style="text-align: right;">1.7</td>
</tr>
</tbody>
</table>
</div>
<p>We see a sudden appearance of <code>(&gt;&gt;=)</code> from the <code>Data.Vector.Fusion.Util</code> module at the top of the list, taking more than half of the run time. For more clues, we dive into the detailed profiler report and find this bit:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Cost Centre</th>
<th style="text-align: left;">Src</th>
<th style="text-align: right;">%time</th>
<th style="text-align: right;">%alloc</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><code>pruneGrid</code></td>
<td style="text-align: left;">Sudoku.hs:143:1-27</td>
<td style="text-align: right;">0.0</td>
<td style="text-align: right;">0.0</td>
</tr>
<tr class="even">
<td style="text-align: left;">  <code>fixM</code></td>
<td style="text-align: left;">Sudoku.hs:16:1-65</td>
<td style="text-align: right;">0.1</td>
<td style="text-align: right;">0.0</td>
</tr>
<tr class="odd">
<td style="text-align: left;">    <code>fixM.\</code></td>
<td style="text-align: left;">Sudoku.hs:16:27-65</td>
<td style="text-align: right;">0.2</td>
<td style="text-align: right;">0.1</td>
</tr>
<tr class="even">
<td style="text-align: left;">      <code>==</code></td>
<td style="text-align: left;">Data/Vector.hs:287:3-50</td>
<td style="text-align: right;">1.0</td>
<td style="text-align: right;">1.4</td>
</tr>
<tr class="odd">
<td style="text-align: left;">        <code>&gt;&gt;=</code></td>
<td style="text-align: left;">Data/Vector/Fusion/Util.hs:36:3-18</td>
<td style="text-align: right;">51.9</td>
<td style="text-align: right;">50.7</td>
</tr>
<tr class="even">
<td style="text-align: left;">          <code>basicUnsafeIndexM</code></td>
<td style="text-align: left;">Data/Vector.hs:278:3-62</td>
<td style="text-align: right;">19.3</td>
<td style="text-align: right;">20.3</td>
</tr>
</tbody>
</table>
</div>
<p>Here, the indentation indicated nesting of operations. We see that both the <code>(&gt;&gt;=)</code> and <code>basicUnsafeIndexM</code> functions — which together take around three-quarter of the run time — are being called from the <code>(==)</code> function in the <code>fixM</code> function<a href="#fn6" class="footnote-ref" id="fnref6" role="doc-noteref"><sup>6</sup></a>. It seems like we are checking for equality too many times. Here’s the usage of the <code>fixM</code> for reference:</p>
<div class="sourceCode" id="cb24"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb24-1"><a href="#cb24-1"></a><span class="ot">pruneCells ::</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> <span class="dt">CellIxs</span> <span class="ot">-&gt;</span> <span class="dt">Maybe</span> <span class="dt">Grid</span></span>
<span id="cb24-2"><a href="#cb24-2"></a>pruneCells grid cellIxs <span class="ot">=</span></span>
<span id="cb24-3"><a href="#cb24-3"></a>  fixM (<span class="fu">flip</span> pruneCellsByFixed cellIxs) grid</span>
<span id="cb24-4"><a href="#cb24-4"></a>  <span class="op">&gt;&gt;=</span> fixM (<span class="fu">flip</span> pruneCellsByExclusives cellIxs)</span>
<span id="cb24-5"><a href="#cb24-5"></a></span>
<span id="cb24-6"><a href="#cb24-6"></a><span class="ot">pruneGrid ::</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> <span class="dt">Maybe</span> <span class="dt">Grid</span></span>
<span id="cb24-7"><a href="#cb24-7"></a>pruneGrid <span class="ot">=</span> fixM pruneGrid'</span></code></pre></div>
<p>In <code>pruneGrid</code>, we run <code>pruneGrid'</code> till the resultant grid settles, that is, the grid computed in a particular iteration is <strong>equal to</strong> the grid in the previous iteration. Interestingly, we do the same thing in <code>pruneCells</code> too. We equate <strong>the whole grid</strong> to check for settling of each block of cells. This is the reason of the slowdown.</p>
<h2 id="one-function-to-prune-them-all" data-track-content data-content-name="one-function-to-prune-them-all" data-content-piece="fast-sudoku-solver-in-haskell-3">One Function to Prune Them All<a href="#one-function-to-prune-them-all" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>Why did we add <code>fixM</code> in the <code>pruneCells</code> function at all? Quoting from the <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/#fn6">previous post</a>,</p>
<blockquote>
<p>We need to run <code>pruneCellsByFixed</code> and <code>pruneCellsByExclusives</code> repeatedly using <code>fixM</code> because an unsettled row can lead to wrong solutions.</p>
<p>Imagine a row which just got a <code>9</code> fixed because of <code>pruneCellsByFixed</code>. If we don’t run the function again, the row may be left with one non-fixed cell with a <code>9</code>. When we run this row through <code>pruneCellsByExclusives</code>, it’ll consider the <code>9</code> in the non-fixed cell as a <em>Single</em> and fix it. This will lead to two <code>9</code>s in the same row, causing the solution to fail.</p>
</blockquote>
<p>So the reason we added <code>fixM</code> is that, we run the two pruning strategies one-after-another. That way, they see the cells in the same block in different states. If we were to merge the two pruning functions into a single one such that they work in lockstep, we would not need to run <code>fixM</code> at all!</p>
<p>With this idea, we rewrite <code>pruneCells</code> as a single function:</p>
<div class="sourceCode" id="cb25"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb25-1"><a href="#cb25-1"></a><span class="ot">pruneCells ::</span> <span class="dt">Grid</span> <span class="ot">-&gt;</span> <span class="dt">CellIxs</span> <span class="ot">-&gt;</span> <span class="dt">Maybe</span> <span class="dt">Grid</span></span>
<span id="cb25-2"><a href="#cb25-2"></a>pruneCells grid cellIxs <span class="ot">=</span> Control.Monad.foldM pruneCell grid cellIxs</span>
<span id="cb25-3"><a href="#cb25-3"></a>  <span class="kw">where</span></span>
<span id="cb25-4"><a href="#cb25-4"></a>    cells         <span class="ot">=</span> <span class="fu">map</span> (grid <span class="op">!</span>) cellIxs</span>
<span id="cb25-5"><a href="#cb25-5"></a>    exclusives    <span class="ot">=</span> exclusivePossibilities cells</span>
<span id="cb25-6"><a href="#cb25-6"></a>    allExclusives <span class="ot">=</span> setBits Data.Bits.zeroBits exclusives</span>
<span id="cb25-7"><a href="#cb25-7"></a>    fixeds        <span class="ot">=</span> setBits Data.Bits.zeroBits [x <span class="op">|</span> <span class="dt">Fixed</span> x <span class="ot">&lt;-</span> cells]</span>
<span id="cb25-8"><a href="#cb25-8"></a></span>
<span id="cb25-9"><a href="#cb25-9"></a>    pruneCell g i <span class="ot">=</span></span>
<span id="cb25-10"><a href="#cb25-10"></a>      pruneCellByFixed g (i, g <span class="op">!</span> i) <span class="op">&gt;&gt;=</span> \g' <span class="ot">-&gt;</span> pruneCellByExclusives g' (i, g' <span class="op">!</span> i)</span>
<span id="cb25-11"><a href="#cb25-11"></a></span>
<span id="cb25-12"><a href="#cb25-12"></a>    pruneCellByFixed g (_, <span class="dt">Fixed</span> _) <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb25-13"><a href="#cb25-13"></a>    pruneCellByFixed g (i, <span class="dt">Possible</span> xs)</span>
<span id="cb25-14"><a href="#cb25-14"></a>      <span class="op">|</span> xs' <span class="op">==</span> xs <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb25-15"><a href="#cb25-15"></a>      <span class="op">|</span> <span class="fu">otherwise</span> <span class="ot">=</span> <span class="fu">flip</span> (replaceCell i) g <span class="op">&lt;$&gt;</span> makeCell xs'</span>
<span id="cb25-16"><a href="#cb25-16"></a>      <span class="kw">where</span></span>
<span id="cb25-17"><a href="#cb25-17"></a>        xs' <span class="ot">=</span> xs <span class="op">Data.Bits..&amp;.</span> Data.Bits.complement fixeds</span>
<span id="cb25-18"><a href="#cb25-18"></a></span>
<span id="cb25-19"><a href="#cb25-19"></a>    pruneCellByExclusives g (_, <span class="dt">Fixed</span> _) <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb25-20"><a href="#cb25-20"></a>    pruneCellByExclusives g (i, <span class="dt">Possible</span> xs)</span>
<span id="cb25-21"><a href="#cb25-21"></a>      <span class="op">|</span> <span class="fu">null</span> exclusives                <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb25-22"><a href="#cb25-22"></a>      <span class="op">|</span> intersection <span class="op">==</span> xs             <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb25-23"><a href="#cb25-23"></a>      <span class="op">|</span> intersection <span class="ot">`elem`</span> exclusives <span class="ot">=</span></span>
<span id="cb25-24"><a href="#cb25-24"></a>          <span class="fu">flip</span> (replaceCell i) g <span class="op">&lt;$&gt;</span> makeCell intersection</span>
<span id="cb25-25"><a href="#cb25-25"></a>      <span class="op">|</span> <span class="fu">otherwise</span>                      <span class="ot">=</span> <span class="dt">Just</span> g</span>
<span id="cb25-26"><a href="#cb25-26"></a>      <span class="kw">where</span></span>
<span id="cb25-27"><a href="#cb25-27"></a>        intersection <span class="ot">=</span> xs <span class="op">Data.Bits..&amp;.</span> allExclusives</span></code></pre></div>
<p>We have merged the two pruning functions almost blindly. The important part here is the nested <code>pruneCell</code> function which uses monadic bind <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Control-Monad.html#v:-62--62--61-" target="_blank" rel="noopener"><code>(&gt;&gt;=)</code></a> to ensure that cells fixed in the first step are seen by the next step. Merging the two functions ensures that both strategies will see same <em>Exclusives</em> and <em>Fixeds</em>, thereby running in lockstep.</p>
<p>Let’s try it out:</p>
<pre class="plain"><code>$ stack build
$ cat sudoku17.txt | time stack exec sudoku &gt; /dev/null
      57.67 real        57.12 user         0.46 sys</code></pre>
<p>Ah, now it’s faster than the list-based implementation by 1.2x<a href="#fn7" class="footnote-ref" id="fnref7" role="doc-noteref"><sup>7</sup></a>. Let’s see what the profiler says:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Cost Centre</th>
<th style="text-align: left;">Src</th>
<th style="text-align: right;">%time</th>
<th style="text-align: right;">%alloc</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities.\.\</code></td>
<td style="text-align: left;">Sudoku.hs:82:23-96</td>
<td style="text-align: right;">15.7</td>
<td style="text-align: right;">33.3</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>pruneCells</code></td>
<td style="text-align: left;">Sudoku.hs:(101,1)-(126,53)</td>
<td style="text-align: right;">9.6</td>
<td style="text-align: right;">6.8</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>pruneCells.pruneCell</code></td>
<td style="text-align: left;">Sudoku.hs:(108,5)-(109,83)</td>
<td style="text-align: right;">9.5</td>
<td style="text-align: right;">2.1</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>basicUnsafeIndexM</code></td>
<td style="text-align: left;">Data/Vector.hs:278:3-62</td>
<td style="text-align: right;">9.4</td>
<td style="text-align: right;">0.5</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>pruneCells.pruneCell.\</code></td>
<td style="text-align: left;">Sudoku.hs:109:48-83</td>
<td style="text-align: right;">7.6</td>
<td style="text-align: right;">2.1</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>pruneCells.cells</code></td>
<td style="text-align: left;">Sudoku.hs:103:5-40</td>
<td style="text-align: right;">7.1</td>
<td style="text-align: right;">10.9</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities.\</code></td>
<td style="text-align: left;">Sudoku.hs:87:64-96</td>
<td style="text-align: right;">3.5</td>
<td style="text-align: right;">3.8</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>EP.Map.filter1</code></td>
<td style="text-align: left;">Sudoku.hs:86:35-61</td>
<td style="text-align: right;">3.0</td>
<td style="text-align: right;">0.6</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>&gt;&gt;=</code></td>
<td style="text-align: left;">Data/Vector/Fusion/Util.hs:36:3-18</td>
<td style="text-align: right;">2.8</td>
<td style="text-align: right;">2.0</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>replaceCell</code></td>
<td style="text-align: left;">Sudoku.hs:59:1-45</td>
<td style="text-align: right;">2.5</td>
<td style="text-align: right;">1.1</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>EP.filter</code></td>
<td style="text-align: left;">Sudoku.hs:78:30-54</td>
<td style="text-align: right;">2.4</td>
<td style="text-align: right;">3.3</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>primitive</code></td>
<td style="text-align: left;">Control/Monad/Primitive.hs:195:3-16</td>
<td style="text-align: right;">2.3</td>
<td style="text-align: right;">6.5</td>
</tr>
</tbody>
</table>
</div>
<p>The double nested anonymous function mentioned before is still the biggest culprit but <code>fixM</code> has disappeared from the list. Let’s tackle <code>exclusivePossibilities</code> now.</p>
<h2 id="rise-of-the-mutables" data-track-content data-content-name="rise-of-the-mutables" data-content-piece="fast-sudoku-solver-in-haskell-3">Rise of the Mutables<a href="#rise-of-the-mutables" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>Here’s <code>exclusivePossibilities</code> again for reference:</p>
<div class="sourceCode" id="cb27"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb27-1"><a href="#cb27-1"></a><span class="ot">exclusivePossibilities ::</span> [<span class="dt">Cell</span>] <span class="ot">-&gt;</span> [<span class="dt">Data.Word.Word16</span>]</span>
<span id="cb27-2"><a href="#cb27-2"></a>exclusivePossibilities row <span class="ot">=</span></span>
<span id="cb27-3"><a href="#cb27-3"></a>  row</span>
<span id="cb27-4"><a href="#cb27-4"></a>  <span class="op">&amp;</span> <span class="fu">zip</span> [<span class="dv">1</span><span class="op">..</span><span class="dv">9</span>]</span>
<span id="cb27-5"><a href="#cb27-5"></a>  <span class="op">&amp;</span> <span class="fu">filter</span> (isPossible <span class="op">.</span> <span class="fu">snd</span>)</span>
<span id="cb27-6"><a href="#cb27-6"></a>  <span class="op">&amp;</span> Data.List.foldl'</span>
<span id="cb27-7"><a href="#cb27-7"></a>      (\acc <span class="op">~</span>(i, <span class="dt">Possible</span> xs) <span class="ot">-&gt;</span></span>
<span id="cb27-8"><a href="#cb27-8"></a>        Data.List.foldl'</span>
<span id="cb27-9"><a href="#cb27-9"></a>          (\acc' n <span class="ot">-&gt;</span> <span class="kw">if</span> Data.Bits.testBit xs n </span>
<span id="cb27-10"><a href="#cb27-10"></a>                      <span class="kw">then</span> Map.insertWith prepend n [i] acc' </span>
<span id="cb27-11"><a href="#cb27-11"></a>                      <span class="kw">else</span> acc')</span>
<span id="cb27-12"><a href="#cb27-12"></a>          acc</span>
<span id="cb27-13"><a href="#cb27-13"></a>          [<span class="dv">1</span><span class="op">..</span><span class="dv">9</span>])</span>
<span id="cb27-14"><a href="#cb27-14"></a>      Map.empty</span>
<span id="cb27-15"><a href="#cb27-15"></a>  <span class="op">&amp;</span> Map.filter ((<span class="op">&lt;</span> <span class="dv">4</span>) <span class="op">.</span> <span class="fu">length</span>)</span>
<span id="cb27-16"><a href="#cb27-16"></a>  <span class="op">&amp;</span> Map.foldlWithKey'(\acc x is <span class="ot">-&gt;</span> Map.insertWith prepend is [x] acc) Map.empty</span>
<span id="cb27-17"><a href="#cb27-17"></a>  <span class="op">&amp;</span> Map.filterWithKey (\is xs <span class="ot">-&gt;</span> <span class="fu">length</span> is <span class="op">==</span> <span class="fu">length</span> xs)</span>
<span id="cb27-18"><a href="#cb27-18"></a>  <span class="op">&amp;</span> Map.elems</span>
<span id="cb27-19"><a href="#cb27-19"></a>  <span class="op">&amp;</span> <span class="fu">map</span> (Data.List.foldl' Data.Bits.setBit Data.Bits.zeroBits)</span>
<span id="cb27-20"><a href="#cb27-20"></a>  <span class="kw">where</span></span>
<span id="cb27-21"><a href="#cb27-21"></a>    prepend <span class="op">~</span>[y] ys <span class="ot">=</span> y<span class="op">:</span>ys</span></code></pre></div>
<p>Let’s zoom into lines 6–14. Here, we do a fold with a nested fold over the non-fixed cells of the given block to accumulate the mapping from the digits to the indices of the cells they occur in. We use a <a href="https://hackage.haskell.org/package/containers-0.6.0.1/docs/Data-Map-Strict.html" target="_blank" rel="noopener"><code>Data.Map.Strict</code></a> map as the accumulator. If a digit is not present in the map as a key then we add a singleton list containing the corresponding cell index as the value. If the digit is already present in the map then we prepend the cell index to the list of indices for the digit. So we end up “mutating” the map repeatedly.</p>
<p>Of course, it’s not actual mutation because the map data structure we are using is immutable. Each change to the map instance creates a new copy with the addition, which we thread through the fold operation, and we get the final copy at the end. This may be the reason of the slowness in this section of the code.</p>
<p>What if, instead of using an immutable data structure for this, we used a mutable one? But how can we do that when we know that Haskell is a pure language? Purity means that all code must be <a href="https://en.wikipedia.org/wiki/Referential_transparency" target="_blank" rel="noopener">referentially transparent</a>, and mutability certainly isn’t. It turns out, there is an escape hatch to mutability in Haskell. Quoting the relevant section from the book <a href="https://book.realworldhaskell.org/read/advanced-library-design-building-a-bloom-filter.html#id680273" target="_blank" rel="noopener">Real World Haskell</a>:</p>
<blockquote>
<p>Haskell provides a special monad, named <code>ST</code>, which lets us work safely with mutable state. Compared to the <code>State</code> monad, it has some powerful added capabilities.</p>
<ul>
<li>We can <em>thaw</em> an immutable array to give a mutable array; modify the mutable array in place; and freeze a new immutable array when we are done.</li>
<li>We have the ability to use <em>mutable references</em>. This lets us implement data structures that we can modify after construction, as in an imperative language. This ability is vital for some imperative data structures and algorithms, for which similarly efficient purely functional alternatives have not yet been discovered.</li>
</ul>
</blockquote>
<p>So if we use a mutable map in the <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Control-Monad-ST.html" target="_blank" rel="noopener"><code>ST</code> monad</a>, we may be able to get rid of this bottleneck. But, we can actually do better! Since the keys of our map are digits <code>1</code>–<code>9</code>, we can use a <a href="https://hackage.haskell.org/package/vector-0.12.0.1/docs/Data-Vector-Mutable.html" target="_blank" rel="noopener">mutable vector</a> to store the indices. In fact, we can go one step even further and store the indices as a BitSet as <code>Word16</code> because they also range from 1 to 9, and are unique for a block. This lets us use an <a href="https://hackage.haskell.org/package/vector-0.12.0.1/docs/Data-Vector-Unboxed-Mutable.html" target="_blank" rel="noopener">unboxed mutable vector</a>. What is <em>unboxing</em> you ask? Quoting from the <a href="https://downloads.haskell.org/~ghc/8.4.3/docs/html/users_guide/glasgow_exts.html#unboxed-types" target="_blank" rel="noopener">GHC docs</a>:</p>
<blockquote>
<p>Most types in GHC are boxed, which means that values of that type are represented by a pointer to a heap object. The representation of a Haskell <code>Int</code>, for example, is a two-word heap object. An unboxed type, however, is represented by the value itself, no pointers or heap allocation are involved.</p>
</blockquote>
<p>When combined with vector, unboxing of values means the whole vector is stored as single byte array, avoiding pointer redirections completely. This is more memory efficient and allows better usage of caches<a href="#fn8" class="footnote-ref" id="fnref8" role="doc-noteref"><sup>8</sup></a>. Let’s rewrite <code>exclusivePossibilities</code> using <code>ST</code> and unboxed mutable vectors.</p>
<p>First we write the core of this operation, the function <code>cellIndicesList</code> which take a list of cells and returns the digit to cell indices mapping. The mapping is returned as a list. The zeroth value in this list is the indices of the cells which have <code>1</code> as a possible digit, and so on. The indices themselves are packed as BitSets. If the bit 1 is set then the first cell has a particular digit. Let’s say it returns <code>[0,688,54,134,0,654,652,526,670]</code>. In 10-bit binary it is:</p>
<pre class="plain"><code>[0000000000, 1010110000, 0000110110, 0010000110, 0000000000, 1010001110, 1010001100, 1000001110, 1010011110]</code></pre>
<p>We can arrange it in a table for further clarity:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: right;">Digits</th>
<th style="text-align: right;">Cell 9</th>
<th style="text-align: right;">Cell 8</th>
<th style="text-align: right;">Cell 7</th>
<th style="text-align: right;">Cell 6</th>
<th style="text-align: right;">Cell 5</th>
<th style="text-align: right;">Cell 4</th>
<th style="text-align: right;">Cell 3</th>
<th style="text-align: right;">Cell 2</th>
<th style="text-align: right;">Cell 1</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
</tr>
<tr class="even">
<td style="text-align: right;">2</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
</tr>
<tr class="odd">
<td style="text-align: right;">3</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
</tr>
<tr class="even">
<td style="text-align: right;">4</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
</tr>
<tr class="odd">
<td style="text-align: right;">5</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
</tr>
<tr class="even">
<td style="text-align: right;">6</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
</tr>
<tr class="odd">
<td style="text-align: right;">7</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
</tr>
<tr class="even">
<td style="text-align: right;">8</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
</tr>
<tr class="odd">
<td style="text-align: right;">9</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
</tr>
</tbody>
</table>
</div>
<p>If the value of the intersection of a particular digit and a particular cell index in the table is set to 1, then the digit is a possibility in the cell, else it is not. Here’s the code:</p>
<div class="sourceCode" id="cb29"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb29-1"><a href="#cb29-1"></a><span class="ot">cellIndicesList ::</span> [<span class="dt">Cell</span>] <span class="ot">-&gt;</span> [<span class="dt">Data.Word.Word16</span>]</span>
<span id="cb29-2"><a href="#cb29-2"></a>cellIndicesList cells <span class="ot">=</span></span>
<span id="cb29-3"><a href="#cb29-3"></a>  Data.Vector.Unboxed.toList <span class="op">$</span> Control.Monad.ST.runST <span class="op">$</span> <span class="kw">do</span></span>
<span id="cb29-4"><a href="#cb29-4"></a>    vec <span class="ot">&lt;-</span> Data.Vector.Unboxed.Mutable.replicate <span class="dv">9</span> Data.Bits.zeroBits</span>
<span id="cb29-5"><a href="#cb29-5"></a>    ref <span class="ot">&lt;-</span> Data.STRef.newSTRef (<span class="dv">1</span><span class="ot"> ::</span> <span class="dt">Int</span>)</span>
<span id="cb29-6"><a href="#cb29-6"></a>    Control.Monad.forM_ cells <span class="op">$</span> \cell <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb29-7"><a href="#cb29-7"></a>      i <span class="ot">&lt;-</span> Data.STRef.readSTRef ref</span>
<span id="cb29-8"><a href="#cb29-8"></a>      <span class="kw">case</span> cell <span class="kw">of</span></span>
<span id="cb29-9"><a href="#cb29-9"></a>        <span class="dt">Fixed</span> _ <span class="ot">-&gt;</span> <span class="fu">return</span> ()</span>
<span id="cb29-10"><a href="#cb29-10"></a>        <span class="dt">Possible</span> xs <span class="ot">-&gt;</span> Control.Monad.forM_ [<span class="dv">0</span><span class="op">..</span><span class="dv">8</span>] <span class="op">$</span> \d <span class="ot">-&gt;</span></span>
<span id="cb29-11"><a href="#cb29-11"></a>          Control.Monad.when (Data.Bits.testBit xs (d<span class="op">+</span><span class="dv">1</span>)) <span class="op">$</span></span>
<span id="cb29-12"><a href="#cb29-12"></a>            Data.Vector.Unboxed.Mutable.unsafeModify vec (<span class="ot">`Data.Bits.setBit`</span> i) d</span>
<span id="cb29-13"><a href="#cb29-13"></a>      Data.STRef.writeSTRef ref (i<span class="op">+</span><span class="dv">1</span>)</span>
<span id="cb29-14"><a href="#cb29-14"></a>    Data.Vector.Unboxed.unsafeFreeze vec</span></code></pre></div>
<p>The whole mutable code runs inside the <code>runST</code> function. <code>runST</code> take an operation in <code>ST</code> monad and executes it, making sure that the mutable references created inside it cannot escape the scope of <code>runST</code>. This is done using a type-system trickery called <a href="https://web.archive.org/web/20180813050307/https://prime.haskell.org/wiki/Rank2Types" target="_blank" rel="noopener">Rank-2 types</a>.</p>
<p>Inside the <code>ST</code> operation, we start with creating a mutable vector of <code>Word16</code>s of size 9 with all its values initially set to zero. We also initialize a mutable reference to keep track of the cell index we are on. Then we run two nested for loops, going over each cell and each digit <code>1</code>–<code>9</code>, setting the right bit of the right index of the mutable vector. During this, we mutate the vector directly using the <code>Data.Vector.Unboxed.Mutable.unsafeModify</code> function. At the end of the <code>ST</code> operation, we freeze the mutable vector to return an immutable version of it. Outside <code>runST</code>, we convert the immutable vector to a list. Notice how this code is quite similar to how we’d write it in <a href="https://en.wikipedia.org/wiki/Imperative_programming" target="_blank" rel="noopener">imperative programming</a> languages like C or Java<a href="#fn9" class="footnote-ref" id="fnref9" role="doc-noteref"><sup>9</sup></a>.</p>
<p>It is easy to use this function now to rewrite <code>exclusivePossibilities</code>:</p>
<div class="sourceCode" id="cb30"><pre class="sourceCode diff"><code class="sourceCode diff"><span id="cb30-1"><a href="#cb30-1"></a> exclusivePossibilities :: [Cell] -&gt; [Data.Word.Word16]</span>
<span id="cb30-2"><a href="#cb30-2"></a> exclusivePossibilities row =</span>
<span id="cb30-3"><a href="#cb30-3"></a>   row</span>
<span id="cb30-4"><a href="#cb30-4"></a><span class="st">-  &amp; zip [1..9]</span></span>
<span id="cb30-5"><a href="#cb30-5"></a><span class="st">-  &amp; filter (isPossible . snd)</span></span>
<span id="cb30-6"><a href="#cb30-6"></a><span class="st">-  &amp; Data.List.foldl'</span></span>
<span id="cb30-7"><a href="#cb30-7"></a><span class="st">-      (\acc ~(i, Possible xs) -&gt;</span></span>
<span id="cb30-8"><a href="#cb30-8"></a><span class="st">-        Data.List.foldl'</span></span>
<span id="cb30-9"><a href="#cb30-9"></a><span class="st">-          (\acc' n -&gt; if Data.Bits.testBit xs n </span></span>
<span id="cb30-10"><a href="#cb30-10"></a><span class="st">-                      then Map.insertWith prepend n [i] acc' </span></span>
<span id="cb30-11"><a href="#cb30-11"></a><span class="st">-                      else acc')</span></span>
<span id="cb30-12"><a href="#cb30-12"></a><span class="st">-          acc</span></span>
<span id="cb30-13"><a href="#cb30-13"></a><span class="st">-          [1..9])</span></span>
<span id="cb30-14"><a href="#cb30-14"></a><span class="st">-      Map.empty</span></span>
<span id="cb30-15"><a href="#cb30-15"></a><span class="va">+  &amp; cellIndicesList</span></span>
<span id="cb30-16"><a href="#cb30-16"></a><span class="va">+  &amp; zip [1..9]</span></span>
<span id="cb30-17"><a href="#cb30-17"></a><span class="st">-  &amp; Map.filter ((&lt; 4) . length)</span></span>
<span id="cb30-18"><a href="#cb30-18"></a><span class="st">-  &amp; Map.foldlWithKey' (\acc x is -&gt; Map.insertWith prepend is [x] acc) Map.empty</span></span>
<span id="cb30-19"><a href="#cb30-19"></a><span class="st">-  &amp; Map.filterWithKey (\is xs -&gt; length is == length xs)</span></span>
<span id="cb30-20"><a href="#cb30-20"></a><span class="va">+  &amp; filter (\(_, is) -&gt; let p = Data.Bits.popCount is in p &gt; 0 &amp;&amp; p &lt; 4)</span></span>
<span id="cb30-21"><a href="#cb30-21"></a><span class="va">+  &amp; Data.List.foldl' (\acc (x, is) -&gt; Map.insertWith prepend is [x] acc) Map.empty</span></span>
<span id="cb30-22"><a href="#cb30-22"></a><span class="va">+  &amp; Map.filterWithKey (\is xs -&gt; Data.Bits.popCount is == length xs)</span></span>
<span id="cb30-23"><a href="#cb30-23"></a>   &amp; Map.elems</span>
<span id="cb30-24"><a href="#cb30-24"></a>   &amp; map (Data.List.foldl' Data.Bits.setBit Data.Bits.zeroBits)</span>
<span id="cb30-25"><a href="#cb30-25"></a>   where</span>
<span id="cb30-26"><a href="#cb30-26"></a>     prepend ~[y] ys = y:ys</span></code></pre></div>
<p>We replace the nested two-fold operation with <code>cellIndicesList</code>. Then we replace some map related function with the corresponding list ones because <code>cellIndicesList</code> returns a list. We also replace the <code>length</code> function call on cell indices with <code>Data.Bits.popCount</code> function call as the indices are represented as <code>Word16</code> now.</p>
<p>That is it. Let’s build and run it now:</p>
<pre class="plain"><code>$ stack build
$ cat sudoku17.txt | time stack exec sudoku &gt; /dev/null
      35.04 real        34.84 user         0.24 sys</code></pre>
<p>That’s a 1.6x speedup over the map-and-fold based version. Let’s check what the profiler has to say:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Cost Centre</th>
<th style="text-align: left;">Src</th>
<th style="text-align: right;">%time</th>
<th style="text-align: right;">%alloc</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><code>cellIndicesList.\.\</code></td>
<td style="text-align: left;">Sudoku.hs:(88,11)-(89,81)</td>
<td style="text-align: right;">10.7</td>
<td style="text-align: right;">6.0</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>primitive</code></td>
<td style="text-align: left;">Control/Monad/Primitive.hs:195:3-16</td>
<td style="text-align: right;">7.9</td>
<td style="text-align: right;">6.9</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>pruneCells</code></td>
<td style="text-align: left;">Sudoku.hs:(113,1)-(138,53)</td>
<td style="text-align: right;">7.5</td>
<td style="text-align: right;">6.4</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>cellIndicesList</code></td>
<td style="text-align: left;">Sudoku.hs:(79,1)-(91,40)</td>
<td style="text-align: right;">7.4</td>
<td style="text-align: right;">10.1</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>basicUnsafeIndexM</code></td>
<td style="text-align: left;">Data/Vector.hs:278:3-62</td>
<td style="text-align: right;">7.3</td>
<td style="text-align: right;">0.5</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>pruneCells.pruneCell</code></td>
<td style="text-align: left;">Sudoku.hs:(120,5)-(121,83)</td>
<td style="text-align: right;">6.8</td>
<td style="text-align: right;">2.0</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities</code></td>
<td style="text-align: left;">Sudoku.hs:(94,1)-(104,26)</td>
<td style="text-align: right;">6.5</td>
<td style="text-align: right;">9.7</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>pruneCells.pruneCell.\</code></td>
<td style="text-align: left;">Sudoku.hs:121:48-83</td>
<td style="text-align: right;">6.1</td>
<td style="text-align: right;">2.0</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>cellIndicesList.\</code></td>
<td style="text-align: left;">Sudoku.hs:(83,42)-(90,37)</td>
<td style="text-align: right;">5.5</td>
<td style="text-align: right;">3.5</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>pruneCells.cells</code></td>
<td style="text-align: left;">Sudoku.hs:115:5-40</td>
<td style="text-align: right;">5.0</td>
<td style="text-align: right;">10.4</td>
</tr>
</tbody>
</table>
</div>
<p>The run time is spread quite evenly over all the functions now and there are no hotspots anymore. We stop optimizating at this point<a href="#fn10" class="footnote-ref" id="fnref10" role="doc-noteref"><sup>10</sup></a>. Let’s see how far we have come up.</p>
<h2 id="comparison-of-implementations" data-track-content data-content-name="comparison-of-implementations" data-content-piece="fast-sudoku-solver-in-haskell-3">Comparison of Implementations<a href="#comparison-of-implementations" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>Below is a table showing the speedups we got with each new implementation:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Implementation</th>
<th style="text-align: right;">Run Time (s)</th>
<th style="text-align: right;">Incremental Speedup</th>
<th style="text-align: right;">Cumulative Speedup</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Simple</td>
<td style="text-align: right;">47450</td>
<td style="text-align: right;">1x</td>
<td style="text-align: right;">1x</td>
</tr>
<tr class="even">
<td style="text-align: left;">Exclusive Pruning</td>
<td style="text-align: right;">258.97</td>
<td style="text-align: right;">183.23x</td>
<td style="text-align: right;">183x</td>
</tr>
<tr class="odd">
<td style="text-align: left;">BitSet</td>
<td style="text-align: right;">69.44</td>
<td style="text-align: right;">3.73x</td>
<td style="text-align: right;">683x</td>
</tr>
<tr class="even">
<td style="text-align: left;">Vector</td>
<td style="text-align: right;">57.67</td>
<td style="text-align: right;">1.20x</td>
<td style="text-align: right;">823x</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Mutable Vector</td>
<td style="text-align: right;">35.04</td>
<td style="text-align: right;">1.65x</td>
<td style="text-align: right;">1354x</td>
</tr>
</tbody>
</table>
</div>
<p>The first improvement over the simple solution got us the most major speedup of 183x. After that, we followed the profiler, fixing bottlenecks by using the right data structures. We got quite significant speedup over the naive list-based solution, leading to drop in the run time from 259 seconds to 35 seconds. In total, we have done more than a thousand times improvement in the run time since the first solution!</p>
<h2 id="conclusion" data-track-content data-content-name="conclusion" data-content-piece="fast-sudoku-solver-in-haskell-3">Conclusion<a href="#conclusion" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>In this post, we improved upon our list-based Sudoku solution from the <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/">last time</a>. We profiled the code at each step, found the bottlenecks and fixed them by choosing the right data structure for the case. We ended up using BitSets and Vectors — both immutable and mutable varieties — for the different parts of the code. Finally, we sped up our program by 7.4 times. Can we go even faster? How about using all those other CPU cores which have been lying idle? Come back for the next post in this series where we’ll explore the parallel programming facilities in Haskell. The code till now is available <a href="https://code.abhinavsarkar.net/abhin4v/hasdoku/src/commit/4a9a1531d5780e7abc7d5ab2a26dccbf34382031" target="_blank" rel="noopener">here</a>. Discuss this post on <a href="https://www.reddit.com/r/haskell/comments/96y0xa/fast_sudoku_solver_in_haskell_3_picking_the_right/" target="_blank" rel="noopener">r/haskell</a> or <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-3/#comment-container">leave a comment</a>.</p>
<section class="footnotes" role="doc-endnotes">
<hr />
<ol>
<li id="fn1" role="doc-endnote"><p>All the runs were done on my MacBook Pro from 2014 with 2.2 GHz Intel Core i7 CPU and 16 GB memory.<a href="#fnref1" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn2" role="doc-endnote"><p>A lot of the code in this post references the code from the previous posts, including showing diffs. So, please read the previous posts if you have not already done so.<a href="#fnref2" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn3" role="doc-endnote"><p>Notice the British English spelling of the word “Centre”. GHC was originally developed in <a href="https://en.wikipedia.org/wiki/University_of_Glasgow" target="_blank" rel="noopener">University of Glasgow</a> in Scotland.<a href="#fnref3" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn4" role="doc-endnote"><p>The code for the BitSet based implementa­tion can be found <a href="https://code.abhinavsarkar.net/abhin4v/hasdoku/src/commit/5a3044e09cd86dd6154bc50760095c4b38c48c6a" target="_blank" rel="noopener">here</a>.<a href="#fnref4" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn5" role="doc-endnote"><p><a href="https://web.archive.org/web/20171031080004/https://www.schoolofhaskell.com/user/commercial/content/vector" target="_blank" rel="noopener">This article</a> on School of Haskell goes into details about performance of vectors vs. lists. There are also <a href="https://web.archive.org/web/20180802043644/https://github.com/haskell-perf/sequences/blob/master/README.md" target="_blank" rel="noopener">these</a> benchmarks for sequence data structures in Haskell: lists, vectors, seqs, etc.<a href="#fnref5" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn6" role="doc-endnote"><p>We see Haskell’s laziness at work here. In the code for the <code>fixM</code> function, the <code>(==)</code> function is nested inside the <code>(&gt;&gt;=)</code> function, but because of laziness, they are actually evaluated in the reverse order. The evaluation of parameters for the <code>(==)</code> function causes the <code>(&gt;&gt;=)</code> function to be evaluated.<a href="#fnref6" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn7" role="doc-endnote"><p>The code for the vector based implementa­tion can be found <a href="https://code.abhinavsarkar.net/abhin4v/hasdoku/src/commit/a320a7874c6fa0c39665151cc8e073532cc750a1" target="_blank" rel="noopener">here</a>.<a href="#fnref7" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn8" role="doc-endnote"><p>Unboxed vectors have some <a href="https://hackage.haskell.org/package/vector-0.12.0.1/docs/Data-Vector-Unboxed.html#t:Unbox" target="_blank" rel="noopener">restrictions</a> on the kind of values that can be put into them but <code>Word16</code> already follows those restrictions so we are good.<a href="#fnref8" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn9" role="doc-endnote"><p>Haskell can be a pretty good imperative programming language using the <code>ST</code> monad. <a href="https://web.archive.org/web/20180628054717/https://vaibhavsagar.com/blog/2017/05/29/imperative-haskell/" target="_blank" rel="noopener">This article</a> shows how to implement some algorithms which require mutable data structures in Haskell.<a href="#fnref9" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn10" role="doc-endnote"><p>The code for the mutable vector based implementation can be found <a href="https://code.abhinavsarkar.net/abhin4v/hasdoku/src/commit/4a9a1531d5780e7abc7d5ab2a26dccbf34382031" target="_blank" rel="noopener">here</a>.<a href="#fnref10" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
</ol>
</section><p>If you liked this post, please <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-3/#comment-container">leave a comment</a>.</p><img src="https://anna.abhinavsarkar.net/piwik.php?idsite=1&amp;rec=1" style="border:0; display: none;" />


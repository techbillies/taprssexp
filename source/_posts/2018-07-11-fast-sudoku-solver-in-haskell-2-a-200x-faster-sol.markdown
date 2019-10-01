---
title: "Fast Sudoku Solver in Haskell #2: A 200x Faster Solution"
kind: article
created_at: 2018-07-11 00:00:00 UTC
author: Abhinav Sarkar
post_url: "https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/"
layout: post
---
<p>In the <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-1/">first part</a> of this series of posts, we wrote a simple <a href="https://en.wikipedia.org/wiki/Sudoku" target="_blank" rel="noopener">Sudoku</a> solver in <a href="https://www.haskell.org/" target="_blank" rel="noopener">Haskell</a>. It used a <a href="https://en.wikipedia.org/wiki/Constraint_satisfaction_problem" target="_blank" rel="noopener">constraint satisfaction</a> algorithm with <a href="https://en.wikipedia.org/wiki/Depth-first_search" target="_blank" rel="noopener">backtracking</a>. The solution worked well but was very slow. In this post, we are going to improve it and make it <strong>fast</strong>.</p>
<!--more-->
<p>This is the second post in a series of posts:</p>
<ol type="1">
<li><a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-1/">Fast Sudoku Solver in Haskell #1: A Simple Solution</a></li>
<li><a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/">Fast Sudoku Solver in Haskell #2: A 200x Faster Solution</a></li>
<li><a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-3/">Fast Sudoku Solver in Haskell #3: Picking the Right Data Structures</a></li>
</ol>
<p>Discuss this post on <a href="https://www.reddit.com/r/haskell/comments/8xyfad/fast_sudoku_solver_in_haskell_2_a_200x_faster/" target="_blank" rel="noopener">r/haskell</a>.</p>
<nav id="toc" class="right-toc"><h3>Contents</h3><ol><li><a href="#quick-recap">Quick Recap</a></li><li><a href="#constraints-and-corollaries">Constraints and Corollaries</a></li><li><a href="#singles-twins-and-triplets">Singles, Twins and Triplets</a></li><li><a href="#a-little-forward-a-little-backward">A Little Forward, a Little Backward</a></li><li><a href="#pruning-the-cells-exclusively">Pruning the Cells, Exclusively</a></li><li><a href="#faster-than-a-speeding-bullet">Faster than a Speeding Bullet!</a><ol><li><a href="#update">Update</a></li></ol></li><li><a href="#conclusion">Conclusion</a></li></ol></nav>
<h2 id="quick-recap" data-track-content data-content-name="quick-recap" data-content-piece="fast-sudoku-solver-in-haskell-2">Quick Recap<a href="#quick-recap" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p><a href="https://en.wikipedia.org/wiki/Sudoku" target="_blank" rel="noopener">Sudoku</a> is a number placement puzzle. It consists of a 9x9 grid which is to be filled with digits from 1 to 9 such that each row, each column and each of the nine 3x3 sub-grids contain all the digits. Some of the cells of the grid come pre-filled and the player has to fill the rest.</p>
<p>In the previous post, we implemented a simple Sudoku solver without paying much attention to its performance characteristics. We ran<a href="#fn1" class="footnote-ref" id="fnref1" role="doc-noteref"><sup>1</sup></a> some of <a href="https://abhinavsarkar.net/files/sudoku17.txt.bz2">17-clue puzzles</a><a href="#fn2" class="footnote-ref" id="fnref2" role="doc-noteref"><sup>2</sup></a> through our program to see how fast it was:</p>
<pre class="plain"><code>$ head -n100 sudoku17.txt | time stack exec sudoku
... output omitted ...
      116.70 real       198.09 user        94.46 sys</code></pre>
<p>So, it took about 117 seconds to solve one hundred puzzles. At this speed, it would take about 16 hours to solve all the 49151 puzzles contained in the file. This is way too slow. We need to find ways to make it faster. Let’s go back to the drawing board.</p>
<h2 id="constraints-and-corollaries" data-track-content data-content-name="constraints-and-corollaries" data-content-piece="fast-sudoku-solver-in-haskell-2">Constraints and Corollaries<a href="#constraints-and-corollaries" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>In a Sudoku puzzle, we have a partially filled 9x9 grid which we have to fill completely while following the constraints of the game.</p>
<pre class="plain low-line-height"><code>+-------+-------+-------+
| . . . | . . . | . 1 . |
| 4 . . | . . . | . . . |
| . 2 . | . . . | . . . |
+-------+-------+-------+
| . . . | . 5 . | 4 . 7 |
| . . 8 | . . . | 3 . . |
| . . 1 | . 9 . | . . . |
+-------+-------+-------+
| 3 . . | 4 . . | 2 . . |
| . 5 . | 1 . . | . . . |
| . . . | 8 . 6 | . . . |
+-------+-------+-------+
    A sample puzzle

+-------+-------+-------+
| 6 9 3 | 7 8 4 | 5 1 2 |
| 4 8 7 | 5 1 2 | 9 3 6 |
| 1 2 5 | 9 6 3 | 8 7 4 |
+-------+-------+-------+
| 9 3 2 | 6 5 1 | 4 8 7 |
| 5 6 8 | 2 4 7 | 3 9 1 |
| 7 4 1 | 3 9 8 | 6 2 5 |
+-------+-------+-------+
| 3 1 9 | 4 7 5 | 2 6 8 |
| 8 5 6 | 1 2 9 | 7 4 3 |
| 2 7 4 | 8 3 6 | 1 5 9 |
+-------+-------+-------+
    and its solution</code></pre>
<p>Earlier, we followed a simple pruning algorithm which removed all the solved (or <em>fixed</em>) digits from neighbours of the fixed cells. We repeated the pruning till the fixed and non-fixed values in the grid stopped changing (or the grid <em>settled</em>). Here’s an example of a grid before pruning:</p>
<pre class="small plain low-line-height overflow"><code>+-------------------------------------+-------------------------------------+-------------------------------------+
| [123456789] [123456789] [123456789] | [123456789] [123456789] [123456789] | [123456789] 1           [123456789] |
| 4           [123456789] [123456789] | [123456789] [123456789] [123456789] | [123456789] [123456789] [123456789] |
| [123456789] 2           [123456789] | [123456789] [123456789] [123456789] | [123456789] [123456789] [123456789] |
+-------------------------------------+-------------------------------------+-------------------------------------+
| [123456789] [123456789] [123456789] | [123456789] 5           [123456789] | 4           [123456789] 7           |
| [123456789] [123456789] 8           | [123456789] [123456789] [123456789] | 3           [123456789] [123456789] |
| [123456789] [123456789] 1           | [123456789] 9           [123456789] | [123456789] [123456789] [123456789] |
+-------------------------------------+-------------------------------------+-------------------------------------+
| 3           [123456789] [123456789] | 4           [123456789] [123456789] | 2           [123456789] [123456789] |
| [123456789] 5           [123456789] | 1           [123456789] [123456789] | [123456789] [123456789] [123456789] |
| [123456789] [123456789] [123456789] | 8           [123456789] 6           | [123456789] [123456789] [123456789] |
+-------------------------------------+-------------------------------------+-------------------------------------+</code></pre>
<p>And here’s the same grid when it settles after repeated pruning:</p>
<pre class="small plain low-line-height overflow"><code>+-------------------------------------+-------------------------------------+-------------------------------------+
| [    56789] [  3  6789] [  3 567 9] | [ 23 567 9] [ 234 6 8 ] [ 2345 789] | [    56789] 1           [ 23456 89] |
| 4           [1 3  6789] [  3 567 9] | [ 23 567 9] [123  6 8 ] [123 5 789] | [    56789] [ 23 56789] [ 23 56 89] |
| [1   56789] 2           [  3 567 9] | [  3 567 9] [1 34 6 8 ] [1 345 789] | [    56789] [  3456789] [  3456 89] |
+-------------------------------------+-------------------------------------+-------------------------------------+
| [ 2   6  9] [  3  6  9] [ 23  6  9] | [ 23  6   ] 5           [123    8 ] | 4           [ 2   6 89] 7           |
| [ 2  567 9] [   4 67 9] 8           | [ 2   67  ] [12 4 6   ] [12 4  7  ] | 3           [ 2  56  9] [12  56  9] |
| [ 2  567  ] [  34 67  ] 1           | [ 23  67  ] 9           [ 234  78 ] | [    56 8 ] [ 2  56 8 ] [ 2  56 8 ] |
+-------------------------------------+-------------------------------------+-------------------------------------+
| 3           [1    6 89] [     6  9] | 4           7           [    5   9] | 2           [    56 89] [1   56 89] |
| [ 2   6789] 5           [ 2 4 67 9] | 1           [ 23      ] [ 23     9] | [     6789] [  34 6789] [  34 6 89] |
| [12    7 9] [1  4  7 9] [ 2 4  7 9] | 8           [ 23      ] 6           | [1   5 7 9] [  345 7 9] [1 345   9] |
+-------------------------------------+-------------------------------------+-------------------------------------+</code></pre>
<p>We see how the possibilities conflicting with the fixed values are removed. We also see how some of the non-fixed cells turn into fixed ones as all their other possible values get eliminated.</p>
<p>This simple strategy follows directly from the constraints of Sudoku. But, are there more complex strategies which are implied indirectly?</p>
<h2 id="singles-twins-and-triplets" data-track-content data-content-name="singles-twins-and-triplets" data-content-piece="fast-sudoku-solver-in-haskell-2">Singles, Twins and Triplets<a href="#singles-twins-and-triplets" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>Let’s have a look at this sample row captured from a solution in progress:</p>
<pre class="small plain low-line-height overflow"><code>+-------------------------------------+-------------------------------------+-------------------------------------+
| 4           [ 2   6 89] 7           | 3           [ 2  56  9] [12  56  9] | [    56 8 ] [ 2  56 8 ] [ 2  56 8 ] |
+-------------------------------------+-------------------------------------+-------------------------------------+</code></pre>
<p>Notice how the sixth cell is the only one with <code>1</code> as a possibility in it. It is obvious that we should fix the sixth cell to <code>1</code> as we cannot place <code>1</code> in any other cell in the row. Let’s call this the <em>Singles</em><a href="#fn3" class="footnote-ref" id="fnref3" role="doc-noteref"><sup>3</sup></a> scenario.</p>
<p>But, our current solution will not fix the sixth cell to <code>1</code> till one of these cases arise:</p>
<ol type="a">
<li>all other possibilities of the cell are pruned away, or,</li>
<li>the cell is chosen as pivot in the <code>nextGrids</code> function and <code>1</code> is chosen as the value to fix.</li>
</ol>
<p>This may take very long and lead to a longer solution time. Let’s assume that we recognize the Singles scenario while pruning cells and fix the cell to <code>1</code> right then. That would cut down the search tree by a lot and make the solution much faster.</p>
<p>It turns out, we can generalize this pattern. Let’s check out this sample row from middle of a solution:</p>
<pre class="small plain low-line-height overflow"><code>+-------------------------------------+-------------------------------------+-------------------------------------+
| [1  4    9] 3           [1  4567 9] | [1  4   89] [1  4 6 89] [1  4 6 89] | [1  4   89] 2           [1  456789] |
+-------------------------------------+-------------------------------------+-------------------------------------+</code></pre>
<p>It is a bit difficult to notice with the naked eye but there’s something special here too. The digits <code>5</code> and <code>7</code> occur only in the third and the ninth cells. Though they are accompanied by other digits in those cells, they are not present in any other cells. This means, we can place <code>5</code> and <code>7</code> either in the third or the ninth cell and no other cells. This implies that we can prune the third and ninth cells to have only <code>5</code> and <code>7</code> like this:</p>
<pre class="small plain low-line-height overflow"><code>+-------------------------------------+-------------------------------------+-------------------------------------+
| [1  4    9] 3           [    5 7  ] | [1  4   89] [1  4 6 89] [1  4 6 89] | [1  4   89] 2           [    5 7  ] |
+-------------------------------------+-------------------------------------+-------------------------------------+</code></pre>
<p>This is the <em>Twins</em> scenario. As we can imagine, this pattern extends to groups of three digits and beyond. When three digits can be found only in three cells in a block, it is the <em>Triplets</em> scenario, as in the example below:</p>
<pre class="small plain low-line-height overflow"><code>+-------------------------------------+-------------------------------------+-------------------------------------+
| [   45 7  ] [   45 7  ] [    5 7  ] | 2           [  3 5  89] 6           | 1           [  34   89] [  34   89] |
+-------------------------------------+-------------------------------------+-------------------------------------+</code></pre>
<p>In this case, the triplet digits are <code>3</code>, <code>8</code> and <code>9</code>. And as before, we can prune the block by fixing these digits in their cells:</p>
<pre class="small plain low-line-height overflow"><code>+-------------------------------------+-------------------------------------+-------------------------------------+
| [   45 7  ] [   45 7  ] [    5 7  ] | 2           [  3    89] 6           | 1           [  3    89] [  3    89] |
+-------------------------------------+-------------------------------------+-------------------------------------+</code></pre>
<p>Let’s call these three scenarios <em>Exclusives</em> in general.</p>
<p>We can extend this to <em>Quadruplets</em> scenario and further. But such scenarios occur rarely in a 9x9 Sudoku puzzle. Trying to find them may end up being more computationally expensive than the benefit we may get in solution time speedup by finding them.</p>
<p>Now that we have discovered these new strategies to prune cells, let’s implement them in Haskell.</p>
<h2 id="a-little-forward-a-little-backward" data-track-content data-content-name="a-little-forward-a-little-backward" data-content-piece="fast-sudoku-solver-in-haskell-2">A Little Forward, a Little Backward<a href="#a-little-forward-a-little-backward" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>We can implement the three new strategies to prune cells as one function for each. However, we can actually implement all these strategies in a single function. But, this function is a bit more complex than the previous pruning function. So first, let’s try to understand its working using tables. Let’s take this sample row:</p>
<pre class="small plain low-line-height overflow"><code>+-------------------------------------+-------------------------------------+-------------------------------------+
| [   4 6  9] 1           5           | [     6  9] 7           [ 23  6 89] | [     6  9] [ 23  6 89] [ 23  6 89] |
+-------------------------------------+-------------------------------------+-------------------------------------+</code></pre>
<p>First, we make a table mapping the digits to the cells in which they occur, excluding the fixed cells:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Digit</th>
<th style="text-align: right;">Cells</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">2</td>
<td style="text-align: right;">6, 8, 9</td>
</tr>
<tr class="even">
<td style="text-align: left;">3</td>
<td style="text-align: right;">6, 8, 9</td>
</tr>
<tr class="odd">
<td style="text-align: left;">4</td>
<td style="text-align: right;">1</td>
</tr>
<tr class="even">
<td style="text-align: left;">6</td>
<td style="text-align: right;">1, 4, 6, 7, 8, 9</td>
</tr>
<tr class="odd">
<td style="text-align: left;">8</td>
<td style="text-align: right;">6, 8, 9</td>
</tr>
<tr class="even">
<td style="text-align: left;">9</td>
<td style="text-align: right;">1, 4, 6, 7, 8, 9</td>
</tr>
</tbody>
</table>
</div>
<p>Then, we flip this table and collect all the digits that occur in the same set of cells:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Cells</th>
<th style="text-align: right;">Digits</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">1</td>
<td style="text-align: right;">4</td>
</tr>
<tr class="even">
<td style="text-align: left;">6, 8, 9</td>
<td style="text-align: right;">2, 3, 8</td>
</tr>
<tr class="odd">
<td style="text-align: left;">1, 4, 6, 7, 8, 9</td>
<td style="text-align: right;">6, 9</td>
</tr>
</tbody>
</table>
</div>
<p>And finally, we remove the rows of the table in which the count of the cells is not the same as the count of the digits:</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Cells</th>
<th style="text-align: right;">Digits</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">1</td>
<td style="text-align: right;">4</td>
</tr>
<tr class="even">
<td style="text-align: left;">6, 8, 9</td>
<td style="text-align: right;">2, 3, 8</td>
</tr>
</tbody>
</table>
</div>
<p>Voilà! We have found a Single <code>4</code> and a set of Triplets <code>2</code>, <code>3</code> and <code>8</code>. You can go over the puzzle row and verify that this indeed is the case.</p>
<p>Translating this logic to Haskell is quite easy now:</p>
<div class="sourceCode" id="cb11"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb11-1"><a href="#cb11-1"></a><span class="ot">isPossible ::</span> <span class="dt">Cell</span> <span class="ot">-&gt;</span> <span class="dt">Bool</span></span>
<span id="cb11-2"><a href="#cb11-2"></a>isPossible (<span class="dt">Possible</span> _) <span class="ot">=</span> <span class="dt">True</span></span>
<span id="cb11-3"><a href="#cb11-3"></a>isPossible _            <span class="ot">=</span> <span class="dt">False</span></span>
<span id="cb11-4"><a href="#cb11-4"></a></span>
<span id="cb11-5"><a href="#cb11-5"></a><span class="ot">exclusivePossibilities ::</span> [<span class="dt">Cell</span>] <span class="ot">-&gt;</span> [[<span class="dt">Int</span>]]</span>
<span id="cb11-6"><a href="#cb11-6"></a>exclusivePossibilities row <span class="ot">=</span></span>
<span id="cb11-7"><a href="#cb11-7"></a>  <span class="co">-- input</span></span>
<span id="cb11-8"><a href="#cb11-8"></a>  row</span>
<span id="cb11-9"><a href="#cb11-9"></a>  <span class="co">-- [Possible [4,6,9], Fixed 1, Fixed 5, Possible [6,9], Fixed 7, Possible [2,3,6,8,9],</span></span>
<span id="cb11-10"><a href="#cb11-10"></a>  <span class="co">-- Possible [6,9], Possible [2,3,6,8,9], Possible [2,3,6,8,9]]</span></span>
<span id="cb11-11"><a href="#cb11-11"></a></span>
<span id="cb11-12"><a href="#cb11-12"></a>  <span class="co">-- step 1</span></span>
<span id="cb11-13"><a href="#cb11-13"></a>  <span class="op">&amp;</span> <span class="fu">zip</span> [<span class="dv">1</span><span class="op">..</span><span class="dv">9</span>]</span>
<span id="cb11-14"><a href="#cb11-14"></a>  <span class="co">-- [(1,Possible [4,6,9]),(2,Fixed 1),(3,Fixed 5),(4,Possible [6,9]),(5,Fixed 7),</span></span>
<span id="cb11-15"><a href="#cb11-15"></a>  <span class="co">-- (6,Possible [2,3,6,8,9]),(7,Possible [6,9]),(8,Possible [2,3,6,8,9]),</span></span>
<span id="cb11-16"><a href="#cb11-16"></a>  <span class="co">-- (9,Possible [2,3,6,8,9])]</span></span>
<span id="cb11-17"><a href="#cb11-17"></a></span>
<span id="cb11-18"><a href="#cb11-18"></a>  <span class="co">-- step 2</span></span>
<span id="cb11-19"><a href="#cb11-19"></a>  <span class="op">&amp;</span> <span class="fu">filter</span> (isPossible <span class="op">.</span> <span class="fu">snd</span>)</span>
<span id="cb11-20"><a href="#cb11-20"></a>  <span class="co">-- [(1,Possible [4,6,9]),(4,Possible [6,9]),(6,Possible [2,3,6,8,9]),</span></span>
<span id="cb11-21"><a href="#cb11-21"></a>  <span class="co">-- (7,Possible [6,9]), (8,Possible [2,3,6,8,9]),(9,Possible [2,3,6,8,9])]</span></span>
<span id="cb11-22"><a href="#cb11-22"></a></span>
<span id="cb11-23"><a href="#cb11-23"></a>  <span class="co">-- step 3</span></span>
<span id="cb11-24"><a href="#cb11-24"></a>  <span class="op">&amp;</span> Data.List.foldl'</span>
<span id="cb11-25"><a href="#cb11-25"></a>      (\acc <span class="op">~</span>(i, <span class="dt">Possible</span> xs) <span class="ot">-&gt;</span></span>
<span id="cb11-26"><a href="#cb11-26"></a>        Data.List.foldl' (\acc' x <span class="ot">-&gt;</span> Map.insertWith prepend x [i] acc') acc xs)</span>
<span id="cb11-27"><a href="#cb11-27"></a>      Map.empty</span>
<span id="cb11-28"><a href="#cb11-28"></a>  <span class="co">-- fromList [(2,[9,8,6]),(3,[9,8,6]),(4,[1]),(6,[9,8,7,6,4,1]),(8,[9,8,6]),</span></span>
<span id="cb11-29"><a href="#cb11-29"></a>  <span class="co">-- (9,[9,8,7,6,4,1])]</span></span>
<span id="cb11-30"><a href="#cb11-30"></a></span>
<span id="cb11-31"><a href="#cb11-31"></a>  <span class="co">-- step 4</span></span>
<span id="cb11-32"><a href="#cb11-32"></a>  <span class="op">&amp;</span> Map.filter ((<span class="op">&lt;</span> <span class="dv">4</span>) <span class="op">.</span> <span class="fu">length</span>)</span>
<span id="cb11-33"><a href="#cb11-33"></a>  <span class="co">-- fromList [(2,[9,8,6]),(3,[9,8,6]),(4,[1]),(8,[9,8,6])]</span></span>
<span id="cb11-34"><a href="#cb11-34"></a></span>
<span id="cb11-35"><a href="#cb11-35"></a>  <span class="co">-- step 5</span></span>
<span id="cb11-36"><a href="#cb11-36"></a>  <span class="op">&amp;</span> Map.foldlWithKey'(\acc x is <span class="ot">-&gt;</span> Map.insertWith prepend is [x] acc) Map.empty</span>
<span id="cb11-37"><a href="#cb11-37"></a>  <span class="co">-- fromList [([1],[4]),([9,8,6],[8,3,2])]</span></span>
<span id="cb11-38"><a href="#cb11-38"></a></span>
<span id="cb11-39"><a href="#cb11-39"></a>  <span class="co">-- step 6</span></span>
<span id="cb11-40"><a href="#cb11-40"></a>  <span class="op">&amp;</span> Map.filterWithKey (\is xs <span class="ot">-&gt;</span> <span class="fu">length</span> is <span class="op">==</span> <span class="fu">length</span> xs)</span>
<span id="cb11-41"><a href="#cb11-41"></a>  <span class="co">-- fromList [([1],[4]),([9,8,6],[8,3,2])]</span></span>
<span id="cb11-42"><a href="#cb11-42"></a></span>
<span id="cb11-43"><a href="#cb11-43"></a>  <span class="co">-- step 7</span></span>
<span id="cb11-44"><a href="#cb11-44"></a>  <span class="op">&amp;</span> Map.elems</span>
<span id="cb11-45"><a href="#cb11-45"></a>  <span class="co">-- [[4],[8,3,2]]</span></span>
<span id="cb11-46"><a href="#cb11-46"></a>  <span class="kw">where</span></span>
<span id="cb11-47"><a href="#cb11-47"></a>    prepend <span class="op">~</span>[y] ys <span class="ot">=</span> y<span class="op">:</span>ys</span></code></pre></div>
<p>We extract the <code>isPossible</code> function to the top level from the <code>nextGrids</code> function for reuse. Then we write the <code>exclusivePossibilities</code> function which finds the Exclusives in the input row. This function is written using the reverse application operator <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Data-Function.html#v:-38-" target="_blank" rel="noopener"><code>(&amp;)</code></a><a href="#fn4" class="footnote-ref" id="fnref4" role="doc-noteref"><sup>4</sup></a> instead of the usual <code>($)</code> operator so that we can read it from top to bottom. We also show the intermediate values for a sample input after every step in the function chain.</p>
<p>The nub of the function lies in step 3 (pun intended). We do a nested fold over all the non-fixed cells and all the possible digits in them to compute the map<a href="#fn5" class="footnote-ref" id="fnref5" role="doc-noteref"><sup>5</sup></a> which represents the first table. Thereafter, we filter the map to keep only the entries with length less than four (step 4). Then we flip it to create a new map which represents the second table (step 5). Finally, we filter the flipped map for the entries where the cell count is same as the digit count (step 6) to arrive at the final table. The step 7 just gets the values in the map which is the list of all the Exclusives in the input row.</p>
<h2 id="pruning-the-cells-exclusively" data-track-content data-content-name="pruning-the-cells-exclusively" data-content-piece="fast-sudoku-solver-in-haskell-2">Pruning the Cells, Exclusively<a href="#pruning-the-cells-exclusively" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>To start with, we extract some reusable code from the previous <code>pruneCells</code> function and rename it to <code>pruneCellsByFixed</code>:</p>
<div class="sourceCode" id="cb12"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb12-1"><a href="#cb12-1"></a><span class="ot">makeCell ::</span> [<span class="dt">Int</span>] <span class="ot">-&gt;</span> <span class="dt">Maybe</span> <span class="dt">Cell</span></span>
<span id="cb12-2"><a href="#cb12-2"></a>makeCell ys <span class="ot">=</span> <span class="kw">case</span> ys <span class="kw">of</span></span>
<span id="cb12-3"><a href="#cb12-3"></a>  []  <span class="ot">-&gt;</span> <span class="dt">Nothing</span></span>
<span id="cb12-4"><a href="#cb12-4"></a>  [y] <span class="ot">-&gt;</span> <span class="dt">Just</span> <span class="op">$</span> <span class="dt">Fixed</span> y</span>
<span id="cb12-5"><a href="#cb12-5"></a>  _   <span class="ot">-&gt;</span> <span class="dt">Just</span> <span class="op">$</span> <span class="dt">Possible</span> ys</span>
<span id="cb12-6"><a href="#cb12-6"></a></span>
<span id="cb12-7"><a href="#cb12-7"></a><span class="ot">pruneCellsByFixed ::</span> [<span class="dt">Cell</span>] <span class="ot">-&gt;</span> <span class="dt">Maybe</span> [<span class="dt">Cell</span>]</span>
<span id="cb12-8"><a href="#cb12-8"></a>pruneCellsByFixed cells <span class="ot">=</span> <span class="fu">traverse</span> pruneCell cells</span>
<span id="cb12-9"><a href="#cb12-9"></a>  <span class="kw">where</span></span>
<span id="cb12-10"><a href="#cb12-10"></a>    fixeds <span class="ot">=</span> [x <span class="op">|</span> <span class="dt">Fixed</span> x <span class="ot">&lt;-</span> cells]</span>
<span id="cb12-11"><a href="#cb12-11"></a></span>
<span id="cb12-12"><a href="#cb12-12"></a>    pruneCell (<span class="dt">Possible</span> xs) <span class="ot">=</span> makeCell (xs <span class="dt">Data.List</span><span class="op">.</span>\\ fixeds)</span>
<span id="cb12-13"><a href="#cb12-13"></a>    pruneCell x             <span class="ot">=</span> <span class="dt">Just</span> x</span></code></pre></div>
<p>Now we write the <code>pruneCellsByExclusives</code> function which uses the <code>exclusivePossibilities</code> function to prune the cells:</p>
<div class="sourceCode" id="cb13"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb13-1"><a href="#cb13-1"></a><span class="ot">pruneCellsByExclusives ::</span> [<span class="dt">Cell</span>] <span class="ot">-&gt;</span> <span class="dt">Maybe</span> [<span class="dt">Cell</span>]</span>
<span id="cb13-2"><a href="#cb13-2"></a>pruneCellsByExclusives cells <span class="ot">=</span> <span class="kw">case</span> exclusives <span class="kw">of</span></span>
<span id="cb13-3"><a href="#cb13-3"></a>  [] <span class="ot">-&gt;</span> <span class="dt">Just</span> cells</span>
<span id="cb13-4"><a href="#cb13-4"></a>  _  <span class="ot">-&gt;</span> <span class="fu">traverse</span> pruneCell cells</span>
<span id="cb13-5"><a href="#cb13-5"></a>  <span class="kw">where</span></span>
<span id="cb13-6"><a href="#cb13-6"></a>    exclusives    <span class="ot">=</span> exclusivePossibilities cells</span>
<span id="cb13-7"><a href="#cb13-7"></a>    allExclusives <span class="ot">=</span> <span class="fu">concat</span> exclusives</span>
<span id="cb13-8"><a href="#cb13-8"></a></span>
<span id="cb13-9"><a href="#cb13-9"></a>    pruneCell cell<span class="op">@</span>(<span class="dt">Fixed</span> _) <span class="ot">=</span> <span class="dt">Just</span> cell</span>
<span id="cb13-10"><a href="#cb13-10"></a>    pruneCell cell<span class="op">@</span>(<span class="dt">Possible</span> xs)</span>
<span id="cb13-11"><a href="#cb13-11"></a>      <span class="op">|</span> intersection <span class="ot">`elem`</span> exclusives <span class="ot">=</span> makeCell intersection</span>
<span id="cb13-12"><a href="#cb13-12"></a>      <span class="op">|</span> <span class="fu">otherwise</span>                      <span class="ot">=</span> <span class="dt">Just</span> cell</span>
<span id="cb13-13"><a href="#cb13-13"></a>      <span class="kw">where</span></span>
<span id="cb13-14"><a href="#cb13-14"></a>        intersection <span class="ot">=</span> xs <span class="ot">`Data.List.intersect`</span> allExclusives</span></code></pre></div>
<p><code>pruneCellsByExclusives</code> works exactly as shown in the examples above. We first find the list of Exclusives in the given cells. If there are no Exclusives, there’s nothing to do and we just return the cells. If we find any Exclusives, we <a href="https://hackage.haskell.org/package/base-4.11.1.0/docs/Data-Traversable.html#v:traverse" target="_blank" rel="noopener"><code>traverse</code></a> the cells, pruning each cell to only the intersection of the possible digits in the cell and Exclusive digits. That’s it! We reuse the <code>makeCell</code> function to create a new cell with the intersection.</p>
<p>As the final step, we rewrite the <code>pruneCells</code> function by combining both the functions.</p>
<div class="sourceCode" id="cb14"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb14-1"><a href="#cb14-1"></a><span class="ot">fixM ::</span> (<span class="dt">Eq</span> t, <span class="dt">Monad</span> m) <span class="ot">=&gt;</span> (t <span class="ot">-&gt;</span> m t) <span class="ot">-&gt;</span> t <span class="ot">-&gt;</span> m t</span>
<span id="cb14-2"><a href="#cb14-2"></a>fixM f x <span class="ot">=</span> f x <span class="op">&gt;&gt;=</span> \x' <span class="ot">-&gt;</span> <span class="kw">if</span> x' <span class="op">==</span> x <span class="kw">then</span> <span class="fu">return</span> x <span class="kw">else</span> fixM f x'</span>
<span id="cb14-3"><a href="#cb14-3"></a></span>
<span id="cb14-4"><a href="#cb14-4"></a><span class="ot">pruneCells ::</span> [<span class="dt">Cell</span>] <span class="ot">-&gt;</span> <span class="dt">Maybe</span> [<span class="dt">Cell</span>]</span>
<span id="cb14-5"><a href="#cb14-5"></a>pruneCells cells <span class="ot">=</span> fixM pruneCellsByFixed cells <span class="op">&gt;&gt;=</span> fixM pruneCellsByExclusives</span></code></pre></div>
<p>We have extracted <code>fixM</code> as a top level function from the <code>pruneGrid</code> function. Just like the <code>pruneGrid'</code> function, we need to use monadic bind (<a href="https://hackage.haskell.org/package/base-4.10.1.0/docs/Control-Monad.html#v:-62--62--61-" target="_blank" rel="noopener"><code>&gt;&gt;=</code></a>) to chain the two pruning steps. We also use <code>fixM</code> to apply each step repeatedly till the pruned cells settle<a href="#fn6" class="footnote-ref" id="fnref6" role="doc-noteref"><sup>6</sup></a>.</p>
<p>No further code changes are required. It is time to check out the improvements.</p>
<h2 id="faster-than-a-speeding-bullet" data-track-content data-content-name="faster-than-a-speeding-bullet" data-content-piece="fast-sudoku-solver-in-haskell-2">Faster than a Speeding Bullet!<a href="#faster-than-a-speeding-bullet" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>Let’s build the program and run the exact same number of puzzles as before:</p>
<pre class="plain"><code>$ head -n100 sudoku17.txt | time stack exec sudoku
... output omitted ...
      0.53 real         0.58 user         0.23 sys</code></pre>
<p>Woah! It is way faster than before. Let’s solve all the puzzles now:</p>
<pre class="plain"><code>$ cat sudoku17.txt | time stack exec sudoku &gt; /dev/null
      282.98 real       407.25 user       109.27 sys</code></pre>
<p>So it is took about 283 seconds to solve all the 49151 puzzles. The speedup is about 200x<a href="#fn7" class="footnote-ref" id="fnref7" role="doc-noteref"><sup>7</sup></a>. That’s about 5.8 milliseconds per puzzle.</p>
<p>Let’s do a quick profiling to see where the time is going:</p>
<pre class="plain"><code>$ stack build --profile
$ head -n1000 sudoku17.txt | stack exec -- sudoku +RTS -p &gt; /dev/null</code></pre>
<p>This generates a file named <code>sudoku.prof</code> with the profiling results. Here are the top five most time-taking functions (cleaned for brevity):</p>
<div class="scrollable-table">
<table>
<thead>
<tr class="header">
<th style="text-align: left;">Cost Center</th>
<th style="text-align: left;">Source</th>
<th style="text-align: right;">%time</th>
<th style="text-align: right;">%alloc</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities</code></td>
<td style="text-align: left;">(49,1)-(62,26)</td>
<td style="text-align: right;">17.6</td>
<td style="text-align: right;">11.4</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>pruneCellsByFixed.pruneCell</code></td>
<td style="text-align: left;">(75,5)-(76,36)</td>
<td style="text-align: right;">16.9</td>
<td style="text-align: right;">30.8</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>exclusivePossibilities.\.\</code></td>
<td style="text-align: left;">55:38-70</td>
<td style="text-align: right;">12.2</td>
<td style="text-align: right;">20.3</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>fixM.\</code></td>
<td style="text-align: left;">13:27-65</td>
<td style="text-align: right;">10.0</td>
<td style="text-align: right;">0.0</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>==</code></td>
<td style="text-align: left;">15:56-57</td>
<td style="text-align: right;">7.2</td>
<td style="text-align: right;">0.0</td>
</tr>
</tbody>
</table>
</div>
<p>Looking at the report, my guess is that a lot of time is going into list operations. Lists are known to be inefficient in Haskell so maybe we should switch to some other data structures?</p>
<h3 id="update">Update<a href="#update" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h3>
<p>As per the <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/#comment-97ca7640-8531-11e8-a1d5-1fd7d3dbc496">comment</a> below by Chris Casinghino, I ran both the versions of code without the <code>-threaded</code>, <code>-rtsopts</code> and <code>-with-rtsopts=-N</code> options. The time for previous post’s code:</p>
<pre class="plain"><code>$ head -n100 sudoku17.txt | time stack exec sudoku
... output omitted ...
       96.54 real        95.90 user         0.66 sys</code></pre>
<p>And the time for this post’s code:</p>
<pre class="plain"><code>$ cat sudoku17.txt | time stack exec sudoku &gt; /dev/null
      258.97 real       257.34 user         1.52 sys</code></pre>
<p>So, both the versions run about 10% faster without the threading options. I suspect this has something to do with GHC’s parallel GC as described in <a href="https://web.archive.org/web/20170612225421/https://inner-haven.net/posts/2017-05-08-speed-up-haskell-programs-weird-trick.html" target="_blank" rel="noopener">this post</a>. So for now, I’ll keep threading disabled.</p>
<h2 id="conclusion" data-track-content data-content-name="conclusion" data-content-piece="fast-sudoku-solver-in-haskell-2">Conclusion<a href="#conclusion" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>In this post, we improved upon our simple Sudoku solution from the <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-1/">last time</a>. We discovered and implemented a new strategy to prune cells, and we achieved a 200x speedup. But profiling shows that we still have many possibilities for improvements. We’ll work on that and more in the upcoming posts in this series. The code till now is available <a href="https://code.abhinavsarkar.net/abhin4v/hasdoku/src/commit/9d6eb18229f905c52cb4c98b569abb70757ba022" target="_blank" rel="noopener">here</a>. Discuss this post on <a href="https://www.reddit.com/r/haskell/comments/8xyfad/fast_sudoku_solver_in_haskell_2_a_200x_faster/" target="_blank" rel="noopener">r/haskell</a> or <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/#comment-container">leave a comment</a>.</p>
<section class="footnotes" role="doc-endnotes">
<hr />
<ol>
<li id="fn1" role="doc-endnote"><p>All the runs were done on my MacBook Pro from 2014 with 2.2 GHz Intel Core i7 CPU and 16 GB memory.<a href="#fnref1" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn2" role="doc-endnote"><p>At least 17 cells must be pre-filled in a Sudoku puzzle for it to have a unique solution. So 17-clue puzzles are the most difficult of all puzzles. <a href="https://arxiv.org/pdf/1201.0749v2.pdf" target="_blank" rel="noopener">This paper</a> by McGuire, Tugemann and Civario gives the proof of the same.<a href="#fnref2" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn3" role="doc-endnote"><p>“Single” as in <a href="https://en.wikipedia.org/wiki/Single_child" target="_blank" rel="noopener">“Single child”</a><a href="#fnref3" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn4" role="doc-endnote"><p>Reverse application operation is not used much in Haskell. But it is the preferred way of function chaining in some other functional programming languages like <a href="https://clojuredocs.org/clojure.core/-%3E" target="_blank" rel="noopener">Clojure</a>, <a href="https://msdn.microsoft.com/en-us/visualfsharpdocs/conceptual/operators.%5b-h%5d-%5d%5b't1,'u%5d-function-%5bfsharp%5d" target="_blank" rel="noopener">FSharp</a>, and <a href="https://hexdocs.pm/elixir/Kernel.html#%7C%3E/2" target="_blank" rel="noopener">Elixir</a>.<a href="#fnref4" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn5" role="doc-endnote"><p>We use <a href="https://hackage.haskell.org/package/containers-0.6.0.1/docs/Data-Map-Strict.html" target="_blank" rel="noopener">Data.Map.Strict</a> as the map imple­mentation.<a href="#fnref5" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn6" role="doc-endnote"><p>We need to run <code>pruneCellsByFixed</code> and <code>pruneCellsByExclusives</code> repeatedly using <code>fixM</code> because an unsettled row can lead to wrong solutions.</p>
<p>Imagine a row which just got a <code>9</code> fixed because of <code>pruneCellsByFixed</code>. If we don’t run the function again, the row may be left with one non-fixed cell with a <code>9</code>. When we run this row through <code>pruneCellsByExclusives</code>, it’ll consider the <code>9</code> in the non-fixed cell as a Single and fix it. This will lead to two <code>9</code>s in the same row, causing the solution to fail.<a href="#fnref6" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
<li id="fn7" role="doc-endnote"><p>Speedup calculation: 116.7 / 100 * 49151 / 282.98 = 202.7<a href="#fnref7" class="footnote-back" role="doc-backlink">↩︎</a></p></li>
</ol>
</section><p>If you liked this post, please <a href="https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-2/#comment-container">leave a comment</a>.</p><img src="https://anna.abhinavsarkar.net/piwik.php?idsite=1&amp;rec=1" style="border:0; display: none;" /><div class="author">
  <img src="https://nilenso.com/images/people/abhinav-200.png" style="width: 96px; height: 96;">
  <span style="position: absolute; padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/abhin4v">Abhinav Sarkar</a> - check out <a href="https://abhinavsarkar.net">All posts on abhinavsarkar.net</a></i>
  </span>
</div>

---
title: "Writing a Simple REST Web Service in PureScript - Part 2"
kind: article
created_at: 2017-10-01 00:00:00 UTC
author: Abhinav Sarkar
post_url: "https://abhinavsarkar.net/posts/ps-simple-rest-service-2/"
layout: post
---
<p>To recap, in the <a href="https://abhinavsarkar.net/posts/ps-simple-rest-service/">first</a> part of this two-part tutorial, we built a simple JSON <a href="https://en.wikipedia.org/wiki/REST" target="_blank" rel="noopener">REST</a> web service in <a href="http://purescript.org" target="_blank" rel="noopener">PureScript</a> to create, update, get, list and delete users, backed by a Postgres database. In this part we’ll work on the rest of the features. <!--more--> The requirements are:</p>
<ol type="1">
<li>validation of API requests.</li>
<li>reading the server and database configs from environment variables.</li>
<li>logging HTTP requests and debugging info.</li>
</ol>
<nav id="toc" class="right-toc"><h3>Contents</h3><ol><li><a href="#bugs">Bugs!</a></li><li><a href="#validation">Validation</a></li><li><a href="#configuration">Configuration</a></li><li><a href="#logging">Logging</a></li><li><a href="#conclusion">Conclusion</a></li></ol></nav>
<p>But first,</p>
<h2 id="bugs" data-track-content data-content-name="bugs" data-content-piece="ps-simple-rest-service-2">Bugs!<a href="#bugs" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>What happens if we hit a URL on our server which does not exist? Let’s fire up the server and test it:</p>
<div class="sourceCode" id="cb1"><pre class="sourceCode bash"><code class="sourceCode bash"><span id="cb1-1"><a href="#cb1-1"></a>$ <span class="ex">pulp</span> --watch run</span></code></pre></div>
<pre class="http"><code>$ http GET http://localhost:4000/v1/random
HTTP/1.1 404 Not Found
Connection: keep-alive
Content-Length: 148
Content-Security-Policy: default-src 'self'
Content-Type: text/html; charset=utf-8
Date: Sat, 30 Sep 2017 08:23:20 GMT
X-Content-Type-Options: nosniff
X-Powered-By: Express

&lt;!DOCTYPE html&gt;
&lt;html lang=&quot;en&quot;&gt;
&lt;head&gt;
&lt;meta charset=&quot;utf-8&quot;&gt;
&lt;title&gt;Error&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
&lt;pre&gt;Cannot GET /v1/random&lt;/pre&gt;
&lt;/body&gt;
&lt;/html&gt;</code></pre>
<p>We get back a default HTML response with a 404 status from <a href="https://expressjs.com" target="_blank" rel="noopener">Express</a>. Since we are writing a JSON API, we should return a JSON response in this case too. We add the following code in the <code>src/SimpleService/Server.purs</code> file to add a catch-all route and send a 404 status with a JSON error message:</p>
<div class="sourceCode" id="cb3"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb3-1"><a href="#cb3-1"></a><span class="co">-- previous code</span></span>
<span id="cb3-2"><a href="#cb3-2"></a><span class="kw">import</span> <span class="dt">Data.Either</span> (fromRight)</span>
<span id="cb3-3"><a href="#cb3-3"></a><span class="kw">import</span> <span class="dt">Data.String.Regex</span> (<span class="dt">Regex</span>, regex) <span class="kw">as</span> <span class="dt">Re</span></span>
<span id="cb3-4"><a href="#cb3-4"></a><span class="kw">import</span> <span class="dt">Data.String.Regex.Flags</span> (noFlags) <span class="kw">as</span> <span class="dt">Re</span></span>
<span id="cb3-5"><a href="#cb3-5"></a><span class="kw">import</span> <span class="dt">Node.Express.App</span> (<span class="dt">App</span>, all, delete, get, http, listenHttp, post, useExternal)</span>
<span id="cb3-6"><a href="#cb3-6"></a><span class="kw">import</span> <span class="dt">Node.Express.Response</span> (sendJson, setStatus)</span>
<span id="cb3-7"><a href="#cb3-7"></a><span class="kw">import</span> <span class="dt">Partial.Unsafe</span> (unsafePartial)</span>
<span id="cb3-8"><a href="#cb3-8"></a><span class="co">-- previous code</span></span>
<span id="cb3-9"><a href="#cb3-9"></a></span>
<span id="cb3-10"><a href="#cb3-10"></a><span class="ot">allRoutePattern ::</span> <span class="dt">Re.Regex</span></span>
<span id="cb3-11"><a href="#cb3-11"></a>allRoutePattern <span class="ot">=</span> unsafePartial <span class="op">$</span> fromRight <span class="op">$</span> Re.regex <span class="st">&quot;/.*&quot;</span> Re.noFlags</span>
<span id="cb3-12"><a href="#cb3-12"></a></span>
<span id="cb3-13"><a href="#cb3-13"></a><span class="ot">app ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">PG.Pool</span> <span class="ot">-&gt;</span> <span class="dt">App</span> (<span class="ot">postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span> <span class="op">|</span> eff)</span>
<span id="cb3-14"><a href="#cb3-14"></a>app pool <span class="ot">=</span> <span class="kw">do</span></span>
<span id="cb3-15"><a href="#cb3-15"></a>  useExternal jsonBodyParser</span>
<span id="cb3-16"><a href="#cb3-16"></a></span>
<span id="cb3-17"><a href="#cb3-17"></a>  get <span class="st">&quot;/v1/user/:id&quot;</span>    <span class="op">$</span> getUser pool</span>
<span id="cb3-18"><a href="#cb3-18"></a>  delete <span class="st">&quot;/v1/user/:id&quot;</span> <span class="op">$</span> deleteUser pool</span>
<span id="cb3-19"><a href="#cb3-19"></a>  post <span class="st">&quot;/v1/users&quot;</span>      <span class="op">$</span> createUser pool</span>
<span id="cb3-20"><a href="#cb3-20"></a>  patch <span class="st">&quot;/v1/user/:id&quot;</span>  <span class="op">$</span> updateUser pool</span>
<span id="cb3-21"><a href="#cb3-21"></a>  get <span class="st">&quot;/v1/users&quot;</span>       <span class="op">$</span> listUsers pool</span>
<span id="cb3-22"><a href="#cb3-22"></a></span>
<span id="cb3-23"><a href="#cb3-23"></a>  <span class="fu">all</span> allRoutePattern <span class="kw">do</span></span>
<span id="cb3-24"><a href="#cb3-24"></a>    setStatus <span class="dv">404</span></span>
<span id="cb3-25"><a href="#cb3-25"></a>    sendJson {<span class="fu">error</span><span class="op">:</span> <span class="st">&quot;Route not found&quot;</span>}</span>
<span id="cb3-26"><a href="#cb3-26"></a>  <span class="kw">where</span></span>
<span id="cb3-27"><a href="#cb3-27"></a>    patch <span class="ot">=</span> http (<span class="dt">CustomMethod</span> <span class="st">&quot;patch&quot;</span>)</span></code></pre></div>
<p><code>allRoutePattern</code> matches all routes because it uses a <code>"/.*"</code> <a href="https://en.wikipedia.org/wiki/Regular_expression" target="_blank" rel="noopener">regular expression</a>. We place it as the last route to match all the otherwise unrouted requests. Let’s see what is the result:</p>
<pre class="http"><code>$ http GET http://localhost:4000/v1/random
HTTP/1.1 404 Not Found
Connection: keep-alive
Content-Length: 27
Content-Type: application/json; charset=utf-8
Date: Sat, 30 Sep 2017 08:46:46 GMT
ETag: W/&quot;1b-772e0u4nrE48ogbR0KmKfSvrHUE&quot;
X-Powered-By: Express

{
    &quot;error&quot;: &quot;Route not found&quot;
}</code></pre>
<p>Now we get a nicely formatted JSON response.</p>
<p>Another scenario is when our application throws some uncaught error. To simulate this, we shut down our postgres database and hit the server for listing users:</p>
<pre class="http"><code>$ http GET http://localhost:4000/v1/users
HTTP/1.1 500 Internal Server Error
Connection: keep-alive
Content-Length: 372
Content-Security-Policy: default-src 'self'
Content-Type: text/html; charset=utf-8
Date: Sat, 30 Sep 2017 08:53:40 GMT
X-Content-Type-Options: nosniff
X-Powered-By: Express

&lt;!DOCTYPE html&gt;
&lt;html lang=&quot;en&quot;&gt;
&lt;head&gt;
&lt;meta charset=&quot;utf-8&quot;&gt;
&lt;title&gt;Error&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
&lt;pre&gt;Error: connect ECONNREFUSED 127.0.0.1:5432&lt;br&gt; &amp;nbsp; &amp;nbsp;at Object._errnoException (util.js:1026:11)&lt;br&gt; &amp;nbsp; &amp;nbsp;at _exceptionWithHostPort (util.js:1049:20)&lt;br&gt; &amp;nbsp; &amp;nbsp;at TCPConnectWrap.afterConnect [as oncomplete] (net.js:1174:14)&lt;/pre&gt;
&lt;/body&gt;
&lt;/html&gt;</code></pre>
<p>We get another default HTML response from Express with a 500 status. Again, in this case we’d like to return a JSON response. We add the following code to the <code>src/SimpleService/Server.purs</code> file:</p>
<div class="sourceCode" id="cb6"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb6-1"><a href="#cb6-1"></a><span class="co">-- previous code</span></span>
<span id="cb6-2"><a href="#cb6-2"></a><span class="kw">import</span> <span class="dt">Control.Monad.Eff.Exception</span> (message)</span>
<span id="cb6-3"><a href="#cb6-3"></a><span class="kw">import</span> <span class="dt">Node.Express.App</span> (<span class="dt">App</span>, all, delete, get, http, listenHttp, post, useExternal, useOnError)</span>
<span id="cb6-4"><a href="#cb6-4"></a><span class="co">-- previous code</span></span>
<span id="cb6-5"><a href="#cb6-5"></a></span>
<span id="cb6-6"><a href="#cb6-6"></a><span class="ot">app ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">PG.Pool</span> <span class="ot">-&gt;</span> <span class="dt">App</span> (<span class="ot">postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span> <span class="op">|</span> eff)</span>
<span id="cb6-7"><a href="#cb6-7"></a>app pool <span class="ot">=</span> <span class="kw">do</span></span>
<span id="cb6-8"><a href="#cb6-8"></a>  <span class="co">-- previous code</span></span>
<span id="cb6-9"><a href="#cb6-9"></a>  useOnError \err <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb6-10"><a href="#cb6-10"></a>    setStatus <span class="dv">500</span></span>
<span id="cb6-11"><a href="#cb6-11"></a>    sendJson {<span class="fu">error</span><span class="op">:</span> message err}</span>
<span id="cb6-12"><a href="#cb6-12"></a>  <span class="kw">where</span></span>
<span id="cb6-13"><a href="#cb6-13"></a>    patch <span class="ot">=</span> http (<span class="dt">CustomMethod</span> <span class="st">&quot;patch&quot;</span>)</span></code></pre></div>
<p>We add the <code>useOnError</code> handler which comes with <a href="https://pursuit.purescript.org/packages/purescript-express" target="_blank" rel="noopener"><code>purescript-express</code></a> to return the error message as a JSON response. Back on the command-line:</p>
<pre class="http"><code>$ http GET http://localhost:4000/v1/users
HTTP/1.1 500 Internal Server Error
Connection: keep-alive
Content-Length: 47
Content-Type: application/json; charset=utf-8
Date: Sat, 30 Sep 2017 09:01:37 GMT
ETag: W/&quot;2f-cJuIW6961YCpo9TWDSZ9VWHLGHE&quot;
X-Powered-By: Express

{
    &quot;error&quot;: &quot;connect ECONNREFUSED 127.0.0.1:5432&quot;
}</code></pre>
<p>It works! Bugs are fixed now. We proceed to add next features.</p>
<h2 id="validation" data-track-content data-content-name="validation" data-content-piece="ps-simple-rest-service-2">Validation<a href="#validation" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>Let’s recall the code to update a user from the <code>src/SimpleService/Handler.purs</code> file:</p>
<div class="sourceCode" id="cb8"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb8-1"><a href="#cb8-1"></a><span class="ot">updateUser ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">PG.Pool</span> <span class="ot">-&gt;</span> <span class="dt">Handler</span> (<span class="ot">postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span> <span class="op">|</span> eff)</span>
<span id="cb8-2"><a href="#cb8-2"></a>updateUser pool <span class="ot">=</span> getRouteParam <span class="st">&quot;id&quot;</span> <span class="op">&gt;&gt;=</span> <span class="kw">case</span> _ <span class="kw">of</span></span>
<span id="cb8-3"><a href="#cb8-3"></a>  <span class="dt">Nothing</span> <span class="ot">-&gt;</span> respond <span class="dv">422</span> { <span class="fu">error</span><span class="op">:</span> <span class="st">&quot;User ID is required&quot;</span> }</span>
<span id="cb8-4"><a href="#cb8-4"></a>  <span class="dt">Just</span> sUserId <span class="ot">-&gt;</span> <span class="kw">case</span> fromString sUserId <span class="kw">of</span></span>
<span id="cb8-5"><a href="#cb8-5"></a>    <span class="dt">Nothing</span> <span class="ot">-&gt;</span> respond <span class="dv">422</span> { <span class="fu">error</span><span class="op">:</span> <span class="st">&quot;User ID must be positive: &quot;</span> <span class="op">&lt;&gt;</span> sUserId }</span>
<span id="cb8-6"><a href="#cb8-6"></a>    <span class="dt">Just</span> userId <span class="ot">-&gt;</span> getBody <span class="op">&gt;&gt;=</span> <span class="kw">case</span> _ <span class="kw">of</span></span>
<span id="cb8-7"><a href="#cb8-7"></a>      <span class="dt">Left</span> errs <span class="ot">-&gt;</span> respond <span class="dv">422</span> { <span class="fu">error</span><span class="op">:</span> intercalate <span class="st">&quot;, &quot;</span> <span class="op">$</span> <span class="fu">map</span> renderForeignError errs}</span>
<span id="cb8-8"><a href="#cb8-8"></a>      <span class="dt">Right</span> (<span class="dt">UserPatch</span> userPatch) <span class="ot">-&gt;</span> <span class="kw">case</span> unNullOrUndefined userPatch<span class="op">.</span>name <span class="kw">of</span></span>
<span id="cb8-9"><a href="#cb8-9"></a>        <span class="dt">Nothing</span> <span class="ot">-&gt;</span> respondNoContent <span class="dv">204</span></span>
<span id="cb8-10"><a href="#cb8-10"></a>        <span class="dt">Just</span> userName <span class="ot">-&gt;</span> <span class="kw">if</span> userName <span class="op">==</span> <span class="st">&quot;&quot;</span></span>
<span id="cb8-11"><a href="#cb8-11"></a>          <span class="kw">then</span> respond <span class="dv">422</span> { <span class="fu">error</span><span class="op">:</span> <span class="st">&quot;User name must not be empty&quot;</span> }</span>
<span id="cb8-12"><a href="#cb8-12"></a>          <span class="kw">else</span> <span class="kw">do</span></span>
<span id="cb8-13"><a href="#cb8-13"></a>            savedUser <span class="ot">&lt;-</span> liftAff <span class="op">$</span> PG.withConnection pool \conn <span class="ot">-&gt;</span> PG.withTransaction conn <span class="kw">do</span></span>
<span id="cb8-14"><a href="#cb8-14"></a>              P.findUser conn userId <span class="op">&gt;&gt;=</span> <span class="kw">case</span> _ <span class="kw">of</span></span>
<span id="cb8-15"><a href="#cb8-15"></a>                <span class="dt">Nothing</span> <span class="ot">-&gt;</span> <span class="fu">pure</span> <span class="dt">Nothing</span></span>
<span id="cb8-16"><a href="#cb8-16"></a>                <span class="dt">Just</span> (<span class="dt">User</span> user) <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb8-17"><a href="#cb8-17"></a>                  <span class="kw">let</span> user' <span class="ot">=</span> <span class="dt">User</span> (user { name <span class="ot">=</span> userName })</span>
<span id="cb8-18"><a href="#cb8-18"></a>                  P.updateUser conn user'</span>
<span id="cb8-19"><a href="#cb8-19"></a>                  <span class="fu">pure</span> <span class="op">$</span> <span class="dt">Just</span> user'</span>
<span id="cb8-20"><a href="#cb8-20"></a>            <span class="kw">case</span> savedUser <span class="kw">of</span></span>
<span id="cb8-21"><a href="#cb8-21"></a>              <span class="dt">Nothing</span> <span class="ot">-&gt;</span> respond <span class="dv">404</span> { <span class="fu">error</span><span class="op">:</span> <span class="st">&quot;User not found with id: &quot;</span> <span class="op">&lt;&gt;</span> sUserId }</span>
<span id="cb8-22"><a href="#cb8-22"></a>              <span class="dt">Just</span> user <span class="ot">-&gt;</span> respond <span class="dv">200</span> (encode user)</span></code></pre></div>
<p>As we can see, the actual request handling logic is obfuscated by the request validation logic for the user id and the user name patch parameters. We also notice that we are using three constructs for validation here: <code>Maybe</code>, <code>Either</code> and <code>if-then-else</code>. However, we can use just <code>Either</code> to subsume all these cases as it can “carry” a failure as well as a success case. <code>Either</code> also comes with a nice monad transformer <a href="https://pursuit.purescript.org/packages/purescript-transformers/3.4.0/docs/Control.Monad.Except.Trans#t:ExceptT" target="_blank" rel="noopener"><code>ExceptT</code></a> which provides the <code>do</code> syntax for failure propagation. So we choose <code>ExceptT</code> as the base construct for our validation framework and write functions to upgrade <code>Maybe</code> and <code>if-then-else</code> to it. We add the following code to the <code>src/SimpleService/Validation.purs</code> file:</p>
<div class="sourceCode" id="cb9"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb9-1"><a href="#cb9-1"></a><span class="kw">module</span> <span class="dt">SimpleService.Validation</span></span>
<span id="cb9-2"><a href="#cb9-2"></a>  (<span class="kw">module</span> <span class="dt">MoreExports</span>, <span class="kw">module</span> <span class="dt">SimpleService.Validation</span>) <span class="kw">where</span></span>
<span id="cb9-3"><a href="#cb9-3"></a></span>
<span id="cb9-4"><a href="#cb9-4"></a><span class="kw">import</span> <span class="dt">Prelude</span></span>
<span id="cb9-5"><a href="#cb9-5"></a></span>
<span id="cb9-6"><a href="#cb9-6"></a><span class="kw">import</span> <span class="dt">Control.Monad.Except</span> (<span class="dt">ExceptT</span>, except, runExceptT)</span>
<span id="cb9-7"><a href="#cb9-7"></a><span class="kw">import</span> <span class="dt">Data.Either</span> (<span class="dt">Either</span>(..))</span>
<span id="cb9-8"><a href="#cb9-8"></a><span class="kw">import</span> <span class="dt">Data.Maybe</span> (<span class="dt">Maybe</span>(..))</span>
<span id="cb9-9"><a href="#cb9-9"></a><span class="kw">import</span> <span class="dt">Node.Express.Handler</span> (<span class="dt">HandlerM</span>, <span class="dt">Handler</span>)</span>
<span id="cb9-10"><a href="#cb9-10"></a><span class="kw">import</span> <span class="dt">Node.Express.Response</span> (sendJson, setStatus)</span>
<span id="cb9-11"><a href="#cb9-11"></a><span class="kw">import</span> <span class="dt">Node.Express.Types</span> (<span class="dt">EXPRESS</span>)</span>
<span id="cb9-12"><a href="#cb9-12"></a><span class="kw">import</span> <span class="dt">Control.Monad.Except</span> (except) <span class="kw">as</span> <span class="dt">MoreExports</span></span>
<span id="cb9-13"><a href="#cb9-13"></a></span>
<span id="cb9-14"><a href="#cb9-14"></a><span class="kw">type</span> <span class="dt">Validation</span> eff a <span class="ot">=</span> <span class="dt">ExceptT</span> <span class="dt">String</span> (<span class="dt">HandlerM</span> (<span class="ot">express ::</span> <span class="dt">EXPRESS</span> <span class="op">|</span> eff)) a</span>
<span id="cb9-15"><a href="#cb9-15"></a></span>
<span id="cb9-16"><a href="#cb9-16"></a><span class="ot">exceptMaybe ::</span> <span class="kw">forall</span> e m a<span class="op">.</span> <span class="dt">Applicative</span> m <span class="ot">=&gt;</span> e <span class="ot">-&gt;</span> <span class="dt">Maybe</span> a <span class="ot">-&gt;</span> <span class="dt">ExceptT</span> e m a</span>
<span id="cb9-17"><a href="#cb9-17"></a>exceptMaybe e a <span class="ot">=</span> except <span class="op">$</span> <span class="kw">case</span> a <span class="kw">of</span></span>
<span id="cb9-18"><a href="#cb9-18"></a>  <span class="dt">Just</span> x  <span class="ot">-&gt;</span> <span class="dt">Right</span> x</span>
<span id="cb9-19"><a href="#cb9-19"></a>  <span class="dt">Nothing</span> <span class="ot">-&gt;</span> <span class="dt">Left</span> e</span>
<span id="cb9-20"><a href="#cb9-20"></a></span>
<span id="cb9-21"><a href="#cb9-21"></a><span class="ot">exceptCond ::</span> <span class="kw">forall</span> e m a<span class="op">.</span> <span class="dt">Applicative</span> m <span class="ot">=&gt;</span> e <span class="ot">-&gt;</span> (a <span class="ot">-&gt;</span> <span class="dt">Boolean</span>) <span class="ot">-&gt;</span> a <span class="ot">-&gt;</span> <span class="dt">ExceptT</span> e m a</span>
<span id="cb9-22"><a href="#cb9-22"></a>exceptCond e cond a <span class="ot">=</span> except <span class="op">$</span> <span class="kw">if</span> cond a <span class="kw">then</span> <span class="dt">Right</span> a <span class="kw">else</span> <span class="dt">Left</span> e</span>
<span id="cb9-23"><a href="#cb9-23"></a></span>
<span id="cb9-24"><a href="#cb9-24"></a><span class="ot">withValidation ::</span> <span class="kw">forall</span> eff a<span class="op">.</span> <span class="dt">Validation</span> eff a <span class="ot">-&gt;</span> (a <span class="ot">-&gt;</span> <span class="dt">Handler</span> eff) <span class="ot">-&gt;</span> <span class="dt">Handler</span> eff</span>
<span id="cb9-25"><a href="#cb9-25"></a>withValidation action handler <span class="ot">=</span> runExceptT action <span class="op">&gt;&gt;=</span> <span class="kw">case</span> _ <span class="kw">of</span></span>
<span id="cb9-26"><a href="#cb9-26"></a>  <span class="dt">Left</span> err <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb9-27"><a href="#cb9-27"></a>    setStatus <span class="dv">422</span></span>
<span id="cb9-28"><a href="#cb9-28"></a>    sendJson {<span class="fu">error</span><span class="op">:</span> err}</span>
<span id="cb9-29"><a href="#cb9-29"></a>  <span class="dt">Right</span> x  <span class="ot">-&gt;</span> handler x</span></code></pre></div>
<p>We re-export <code>except</code> from the <code>Control.Monad.Except</code> module. We also add a <code>withValidation</code> function which runs an <code>ExceptT</code> based validation and either returns an error response with a 422 status in case of a failed validation or runs the given action with the valid value in case of a successful validation.</p>
<p>Using these functions, we now write <code>updateUser</code> in the <code>src/SimpleService/Handler.purs</code> file as:</p>
<div class="sourceCode" id="cb10"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb10-1"><a href="#cb10-1"></a><span class="co">-- previous code</span></span>
<span id="cb10-2"><a href="#cb10-2"></a><span class="kw">import</span> <span class="dt">Control.Monad.Trans.Class</span> (lift)</span>
<span id="cb10-3"><a href="#cb10-3"></a><span class="kw">import</span> <span class="dt">Data.Bifunctor</span> (lmap)</span>
<span id="cb10-4"><a href="#cb10-4"></a><span class="kw">import</span> <span class="dt">Data.Foreign</span> (<span class="dt">ForeignError</span>, renderForeignError)</span>
<span id="cb10-5"><a href="#cb10-5"></a><span class="kw">import</span> <span class="dt">Data.List.NonEmpty</span> (toList)</span>
<span id="cb10-6"><a href="#cb10-6"></a><span class="kw">import</span> <span class="dt">Data.List.Types</span> (<span class="dt">NonEmptyList</span>)</span>
<span id="cb10-7"><a href="#cb10-7"></a><span class="kw">import</span> <span class="dt">Data.Tuple</span> (<span class="dt">Tuple</span>(..))</span>
<span id="cb10-8"><a href="#cb10-8"></a><span class="kw">import</span> <span class="dt">SimpleService.Validation</span> <span class="kw">as</span> <span class="dt">V</span></span>
<span id="cb10-9"><a href="#cb10-9"></a><span class="co">-- previous code</span></span>
<span id="cb10-10"><a href="#cb10-10"></a></span>
<span id="cb10-11"><a href="#cb10-11"></a><span class="ot">renderForeignErrors ::</span> <span class="kw">forall</span> a<span class="op">.</span> <span class="dt">Either</span> (<span class="dt">NonEmptyList</span> <span class="dt">ForeignError</span>) a <span class="ot">-&gt;</span> <span class="dt">Either</span> <span class="dt">String</span> a</span>
<span id="cb10-12"><a href="#cb10-12"></a>renderForeignErrors <span class="ot">=</span> lmap (toList <span class="op">&gt;&gt;&gt;</span> <span class="fu">map</span> renderForeignError <span class="op">&gt;&gt;&gt;</span> intercalate <span class="st">&quot;, &quot;</span>)</span>
<span id="cb10-13"><a href="#cb10-13"></a></span>
<span id="cb10-14"><a href="#cb10-14"></a><span class="ot">updateUser ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">PG.Pool</span> <span class="ot">-&gt;</span> <span class="dt">Handler</span> (<span class="ot">postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span> <span class="op">|</span> eff)</span>
<span id="cb10-15"><a href="#cb10-15"></a>updateUser pool <span class="ot">=</span> V.withValidation (<span class="dt">Tuple</span> <span class="op">&lt;$&gt;</span> getUserId <span class="op">&lt;*&gt;</span> getUserPatch)</span>
<span id="cb10-16"><a href="#cb10-16"></a>                                   \(<span class="dt">Tuple</span> userId (<span class="dt">UserPatch</span> userPatch)) <span class="ot">-&gt;</span></span>
<span id="cb10-17"><a href="#cb10-17"></a>    <span class="kw">case</span> unNullOrUndefined userPatch<span class="op">.</span>name <span class="kw">of</span></span>
<span id="cb10-18"><a href="#cb10-18"></a>      <span class="dt">Nothing</span> <span class="ot">-&gt;</span> respondNoContent <span class="dv">204</span></span>
<span id="cb10-19"><a href="#cb10-19"></a>      <span class="dt">Just</span> uName <span class="ot">-&gt;</span> V.withValidation (getUserName uName) \userName <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb10-20"><a href="#cb10-20"></a>        savedUser <span class="ot">&lt;-</span> liftAff <span class="op">$</span> PG.withConnection pool \conn <span class="ot">-&gt;</span> PG.withTransaction conn <span class="kw">do</span></span>
<span id="cb10-21"><a href="#cb10-21"></a>          P.findUser conn userId <span class="op">&gt;&gt;=</span> <span class="kw">case</span> _ <span class="kw">of</span></span>
<span id="cb10-22"><a href="#cb10-22"></a>            <span class="dt">Nothing</span> <span class="ot">-&gt;</span> <span class="fu">pure</span> <span class="dt">Nothing</span></span>
<span id="cb10-23"><a href="#cb10-23"></a>            <span class="dt">Just</span> (<span class="dt">User</span> user) <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb10-24"><a href="#cb10-24"></a>              <span class="kw">let</span> user' <span class="ot">=</span> <span class="dt">User</span> (user { name <span class="ot">=</span> userName })</span>
<span id="cb10-25"><a href="#cb10-25"></a>              P.updateUser conn user'</span>
<span id="cb10-26"><a href="#cb10-26"></a>              <span class="fu">pure</span> <span class="op">$</span> <span class="dt">Just</span> user'</span>
<span id="cb10-27"><a href="#cb10-27"></a>        <span class="kw">case</span> savedUser <span class="kw">of</span></span>
<span id="cb10-28"><a href="#cb10-28"></a>          <span class="dt">Nothing</span> <span class="ot">-&gt;</span> respond <span class="dv">404</span> { <span class="fu">error</span><span class="op">:</span> <span class="st">&quot;User not found with id: &quot;</span> <span class="op">&lt;&gt;</span> <span class="fu">show</span> userId }</span>
<span id="cb10-29"><a href="#cb10-29"></a>          <span class="dt">Just</span> user <span class="ot">-&gt;</span> respond <span class="dv">200</span> (encode user)</span>
<span id="cb10-30"><a href="#cb10-30"></a>  <span class="kw">where</span></span>
<span id="cb10-31"><a href="#cb10-31"></a>    getUserId <span class="ot">=</span> lift (getRouteParam <span class="st">&quot;id&quot;</span>)</span>
<span id="cb10-32"><a href="#cb10-32"></a>      <span class="op">&gt;&gt;=</span> V.exceptMaybe <span class="st">&quot;User ID is required&quot;</span></span>
<span id="cb10-33"><a href="#cb10-33"></a>      <span class="op">&gt;&gt;=</span> fromString <span class="op">&gt;&gt;&gt;</span> V.exceptMaybe <span class="st">&quot;User ID must be positive&quot;</span></span>
<span id="cb10-34"><a href="#cb10-34"></a></span>
<span id="cb10-35"><a href="#cb10-35"></a>    getUserPatch <span class="ot">=</span> lift getBody <span class="op">&gt;&gt;=</span> V.except <span class="op">&lt;&lt;&lt;</span> renderForeignErrors</span>
<span id="cb10-36"><a href="#cb10-36"></a></span>
<span id="cb10-37"><a href="#cb10-37"></a>    getUserName <span class="ot">=</span> V.exceptCond <span class="st">&quot;User name must not be empty&quot;</span> (_ <span class="op">==</span> <span class="st">&quot;&quot;</span>)</span></code></pre></div>
<p>The validation logic has been extracted out in separate functions now which are composed using <a href="https://pursuit.purescript.org/packages/purescript-prelude/3.0.0/docs/Control.Applicative#t:Applicative" target="_blank" rel="noopener">Applicative</a>. The validation steps are composed using the <code>ExceptT</code> monad. We are now free to express the core logic of the function clearly. We rewrite the <code>src/SimpleService/Handler.purs</code> file using the validations:</p>
<div class="sourceCode" id="cb11"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb11-1"><a href="#cb11-1"></a><span class="kw">module</span> <span class="dt">SimpleService.Handler</span> <span class="kw">where</span></span>
<span id="cb11-2"><a href="#cb11-2"></a></span>
<span id="cb11-3"><a href="#cb11-3"></a><span class="kw">import</span> <span class="dt">Prelude</span></span>
<span id="cb11-4"><a href="#cb11-4"></a></span>
<span id="cb11-5"><a href="#cb11-5"></a><span class="kw">import</span> <span class="dt">Control.Monad.Aff.Class</span> (liftAff)</span>
<span id="cb11-6"><a href="#cb11-6"></a><span class="kw">import</span> <span class="dt">Control.Monad.Trans.Class</span> (lift)</span>
<span id="cb11-7"><a href="#cb11-7"></a><span class="kw">import</span> <span class="dt">Data.Bifunctor</span> (lmap)</span>
<span id="cb11-8"><a href="#cb11-8"></a><span class="kw">import</span> <span class="dt">Data.Either</span> (<span class="dt">Either</span>)</span>
<span id="cb11-9"><a href="#cb11-9"></a><span class="kw">import</span> <span class="dt">Data.Foldable</span> (intercalate)</span>
<span id="cb11-10"><a href="#cb11-10"></a><span class="kw">import</span> <span class="dt">Data.Foreign</span> (<span class="dt">ForeignError</span>, renderForeignError)</span>
<span id="cb11-11"><a href="#cb11-11"></a><span class="kw">import</span> <span class="dt">Data.Foreign.Class</span> (encode)</span>
<span id="cb11-12"><a href="#cb11-12"></a><span class="kw">import</span> <span class="dt">Data.Foreign.NullOrUndefined</span> (unNullOrUndefined)</span>
<span id="cb11-13"><a href="#cb11-13"></a><span class="kw">import</span> <span class="dt">Data.Int</span> (fromString)</span>
<span id="cb11-14"><a href="#cb11-14"></a><span class="kw">import</span> <span class="dt">Data.List.NonEmpty</span> (toList)</span>
<span id="cb11-15"><a href="#cb11-15"></a><span class="kw">import</span> <span class="dt">Data.List.Types</span> (<span class="dt">NonEmptyList</span>)</span>
<span id="cb11-16"><a href="#cb11-16"></a><span class="kw">import</span> <span class="dt">Data.Maybe</span> (<span class="dt">Maybe</span>(..))</span>
<span id="cb11-17"><a href="#cb11-17"></a><span class="kw">import</span> <span class="dt">Data.Tuple</span> (<span class="dt">Tuple</span>(..))</span>
<span id="cb11-18"><a href="#cb11-18"></a><span class="kw">import</span> <span class="dt">Database.PostgreSQL</span> <span class="kw">as</span> <span class="dt">PG</span></span>
<span id="cb11-19"><a href="#cb11-19"></a><span class="kw">import</span> <span class="dt">Node.Express.Handler</span> (<span class="dt">Handler</span>)</span>
<span id="cb11-20"><a href="#cb11-20"></a><span class="kw">import</span> <span class="dt">Node.Express.Request</span> (getBody, getRouteParam)</span>
<span id="cb11-21"><a href="#cb11-21"></a><span class="kw">import</span> <span class="dt">Node.Express.Response</span> (end, sendJson, setStatus)</span>
<span id="cb11-22"><a href="#cb11-22"></a><span class="kw">import</span> <span class="dt">SimpleService.Persistence</span> <span class="kw">as</span> <span class="dt">P</span></span>
<span id="cb11-23"><a href="#cb11-23"></a><span class="kw">import</span> <span class="dt">SimpleService.Validation</span> <span class="kw">as</span> <span class="dt">V</span></span>
<span id="cb11-24"><a href="#cb11-24"></a><span class="kw">import</span> <span class="dt">SimpleService.Types</span></span>
<span id="cb11-25"><a href="#cb11-25"></a></span>
<span id="cb11-26"><a href="#cb11-26"></a><span class="ot">getUser ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">PG.Pool</span> <span class="ot">-&gt;</span> <span class="dt">Handler</span> (<span class="ot">postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span> <span class="op">|</span> eff)</span>
<span id="cb11-27"><a href="#cb11-27"></a>getUser pool <span class="ot">=</span> V.withValidation getUserId \userId <span class="ot">-&gt;</span></span>
<span id="cb11-28"><a href="#cb11-28"></a>  liftAff (PG.withConnection pool <span class="op">$</span> <span class="fu">flip</span> P.findUser userId) <span class="op">&gt;&gt;=</span> <span class="kw">case</span> _ <span class="kw">of</span></span>
<span id="cb11-29"><a href="#cb11-29"></a>    <span class="dt">Nothing</span> <span class="ot">-&gt;</span> respond <span class="dv">404</span> { <span class="fu">error</span><span class="op">:</span> <span class="st">&quot;User not found with id: &quot;</span> <span class="op">&lt;&gt;</span> <span class="fu">show</span> userId }</span>
<span id="cb11-30"><a href="#cb11-30"></a>    <span class="dt">Just</span> user <span class="ot">-&gt;</span> respond <span class="dv">200</span> (encode user)</span>
<span id="cb11-31"><a href="#cb11-31"></a></span>
<span id="cb11-32"><a href="#cb11-32"></a><span class="ot">deleteUser ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">PG.Pool</span> <span class="ot">-&gt;</span> <span class="dt">Handler</span> (<span class="ot">postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span> <span class="op">|</span> eff)</span>
<span id="cb11-33"><a href="#cb11-33"></a>deleteUser pool <span class="ot">=</span> V.withValidation getUserId \userId <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb11-34"><a href="#cb11-34"></a>  found <span class="ot">&lt;-</span> liftAff <span class="op">$</span> PG.withConnection pool \conn <span class="ot">-&gt;</span> PG.withTransaction conn <span class="kw">do</span></span>
<span id="cb11-35"><a href="#cb11-35"></a>    P.findUser conn userId <span class="op">&gt;&gt;=</span> <span class="kw">case</span> _ <span class="kw">of</span></span>
<span id="cb11-36"><a href="#cb11-36"></a>      <span class="dt">Nothing</span> <span class="ot">-&gt;</span> <span class="fu">pure</span> false</span>
<span id="cb11-37"><a href="#cb11-37"></a>      <span class="dt">Just</span> _  <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb11-38"><a href="#cb11-38"></a>        P.deleteUser conn userId</span>
<span id="cb11-39"><a href="#cb11-39"></a>        <span class="fu">pure</span> true</span>
<span id="cb11-40"><a href="#cb11-40"></a>  <span class="kw">if</span> found</span>
<span id="cb11-41"><a href="#cb11-41"></a>    <span class="kw">then</span> respondNoContent <span class="dv">204</span></span>
<span id="cb11-42"><a href="#cb11-42"></a>    <span class="kw">else</span> respond <span class="dv">404</span> { <span class="fu">error</span><span class="op">:</span> <span class="st">&quot;User not found with id: &quot;</span> <span class="op">&lt;&gt;</span> <span class="fu">show</span> userId }</span>
<span id="cb11-43"><a href="#cb11-43"></a></span>
<span id="cb11-44"><a href="#cb11-44"></a><span class="ot">createUser ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">PG.Pool</span> <span class="ot">-&gt;</span> <span class="dt">Handler</span> (<span class="ot">postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span> <span class="op">|</span> eff)</span>
<span id="cb11-45"><a href="#cb11-45"></a>createUser pool <span class="ot">=</span> V.withValidation getUser \user<span class="op">@</span>(<span class="dt">User</span> _) <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb11-46"><a href="#cb11-46"></a>  liftAff (PG.withConnection pool <span class="op">$</span> <span class="fu">flip</span> P.insertUser user)</span>
<span id="cb11-47"><a href="#cb11-47"></a>  respondNoContent <span class="dv">201</span></span>
<span id="cb11-48"><a href="#cb11-48"></a>  <span class="kw">where</span></span>
<span id="cb11-49"><a href="#cb11-49"></a>    getUser <span class="ot">=</span> lift getBody</span>
<span id="cb11-50"><a href="#cb11-50"></a>      <span class="op">&gt;&gt;=</span> V.except <span class="op">&lt;&lt;&lt;</span> renderForeignErrors</span>
<span id="cb11-51"><a href="#cb11-51"></a>      <span class="op">&gt;&gt;=</span> V.exceptCond <span class="st">&quot;User ID must be positive&quot;</span> (\(<span class="dt">User</span> user) <span class="ot">-&gt;</span> user<span class="op">.</span><span class="fu">id</span> <span class="op">&gt;</span> <span class="dv">0</span>)</span>
<span id="cb11-52"><a href="#cb11-52"></a>      <span class="op">&gt;&gt;=</span> V.exceptCond <span class="st">&quot;User name must not be empty&quot;</span> (\(<span class="dt">User</span> user) <span class="ot">-&gt;</span> user<span class="op">.</span>name <span class="op">/=</span> <span class="st">&quot;&quot;</span>)</span>
<span id="cb11-53"><a href="#cb11-53"></a></span>
<span id="cb11-54"><a href="#cb11-54"></a><span class="ot">updateUser ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">PG.Pool</span> <span class="ot">-&gt;</span> <span class="dt">Handler</span> (<span class="ot">postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span> <span class="op">|</span> eff)</span>
<span id="cb11-55"><a href="#cb11-55"></a>updateUser pool <span class="ot">=</span> V.withValidation (<span class="dt">Tuple</span> <span class="op">&lt;$&gt;</span> getUserId <span class="op">&lt;*&gt;</span> getUserPatch)</span>
<span id="cb11-56"><a href="#cb11-56"></a>                                   \(<span class="dt">Tuple</span> userId (<span class="dt">UserPatch</span> userPatch)) <span class="ot">-&gt;</span></span>
<span id="cb11-57"><a href="#cb11-57"></a>    <span class="kw">case</span> unNullOrUndefined userPatch<span class="op">.</span>name <span class="kw">of</span></span>
<span id="cb11-58"><a href="#cb11-58"></a>      <span class="dt">Nothing</span> <span class="ot">-&gt;</span> respondNoContent <span class="dv">204</span></span>
<span id="cb11-59"><a href="#cb11-59"></a>      <span class="dt">Just</span> uName <span class="ot">-&gt;</span> V.withValidation (getUserName uName) \userName <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb11-60"><a href="#cb11-60"></a>        savedUser <span class="ot">&lt;-</span> liftAff <span class="op">$</span> PG.withConnection pool \conn <span class="ot">-&gt;</span> PG.withTransaction conn <span class="kw">do</span></span>
<span id="cb11-61"><a href="#cb11-61"></a>          P.findUser conn userId <span class="op">&gt;&gt;=</span> <span class="kw">case</span> _ <span class="kw">of</span></span>
<span id="cb11-62"><a href="#cb11-62"></a>            <span class="dt">Nothing</span> <span class="ot">-&gt;</span> <span class="fu">pure</span> <span class="dt">Nothing</span></span>
<span id="cb11-63"><a href="#cb11-63"></a>            <span class="dt">Just</span> (<span class="dt">User</span> user) <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb11-64"><a href="#cb11-64"></a>              <span class="kw">let</span> user' <span class="ot">=</span> <span class="dt">User</span> (user { name <span class="ot">=</span> userName })</span>
<span id="cb11-65"><a href="#cb11-65"></a>              P.updateUser conn user'</span>
<span id="cb11-66"><a href="#cb11-66"></a>              <span class="fu">pure</span> <span class="op">$</span> <span class="dt">Just</span> user'</span>
<span id="cb11-67"><a href="#cb11-67"></a>        <span class="kw">case</span> savedUser <span class="kw">of</span></span>
<span id="cb11-68"><a href="#cb11-68"></a>          <span class="dt">Nothing</span> <span class="ot">-&gt;</span> respond <span class="dv">404</span> { <span class="fu">error</span><span class="op">:</span> <span class="st">&quot;User not found with id: &quot;</span> <span class="op">&lt;&gt;</span> <span class="fu">show</span> userId }</span>
<span id="cb11-69"><a href="#cb11-69"></a>          <span class="dt">Just</span> user <span class="ot">-&gt;</span> respond <span class="dv">200</span> (encode user)</span>
<span id="cb11-70"><a href="#cb11-70"></a>  <span class="kw">where</span></span>
<span id="cb11-71"><a href="#cb11-71"></a>    getUserPatch <span class="ot">=</span> lift getBody <span class="op">&gt;&gt;=</span> V.except <span class="op">&lt;&lt;&lt;</span> renderForeignErrors</span>
<span id="cb11-72"><a href="#cb11-72"></a>    getUserName <span class="ot">=</span> V.exceptCond <span class="st">&quot;User name must not be empty&quot;</span> (_ <span class="op">/=</span> <span class="st">&quot;&quot;</span>)</span>
<span id="cb11-73"><a href="#cb11-73"></a></span>
<span id="cb11-74"><a href="#cb11-74"></a><span class="ot">listUsers ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">PG.Pool</span> <span class="ot">-&gt;</span> <span class="dt">Handler</span> (<span class="ot">postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span> <span class="op">|</span> eff)</span>
<span id="cb11-75"><a href="#cb11-75"></a>listUsers pool <span class="ot">=</span> liftAff (PG.withConnection pool P.listUsers) <span class="op">&gt;&gt;=</span> encode <span class="op">&gt;&gt;&gt;</span> respond <span class="dv">200</span></span>
<span id="cb11-76"><a href="#cb11-76"></a></span>
<span id="cb11-77"><a href="#cb11-77"></a><span class="ot">getUserId ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">V.Validation</span> eff <span class="dt">Int</span></span>
<span id="cb11-78"><a href="#cb11-78"></a>getUserId <span class="ot">=</span> lift (getRouteParam <span class="st">&quot;id&quot;</span>)</span>
<span id="cb11-79"><a href="#cb11-79"></a>  <span class="op">&gt;&gt;=</span> V.exceptMaybe <span class="st">&quot;User ID is required&quot;</span></span>
<span id="cb11-80"><a href="#cb11-80"></a>  <span class="op">&gt;&gt;=</span> fromString <span class="op">&gt;&gt;&gt;</span> V.exceptMaybe <span class="st">&quot;User ID must be an integer&quot;</span></span>
<span id="cb11-81"><a href="#cb11-81"></a>  <span class="op">&gt;&gt;=</span> V.exceptCond <span class="st">&quot;User ID must be positive&quot;</span> (_ <span class="op">&gt;</span> <span class="dv">0</span>)</span>
<span id="cb11-82"><a href="#cb11-82"></a></span>
<span id="cb11-83"><a href="#cb11-83"></a><span class="ot">renderForeignErrors ::</span> <span class="kw">forall</span> a<span class="op">.</span> <span class="dt">Either</span> (<span class="dt">NonEmptyList</span> <span class="dt">ForeignError</span>) a <span class="ot">-&gt;</span> <span class="dt">Either</span> <span class="dt">String</span> a</span>
<span id="cb11-84"><a href="#cb11-84"></a>renderForeignErrors <span class="ot">=</span> lmap (toList <span class="op">&gt;&gt;&gt;</span> <span class="fu">map</span> renderForeignError <span class="op">&gt;&gt;&gt;</span> intercalate <span class="st">&quot;, &quot;</span>)</span>
<span id="cb11-85"><a href="#cb11-85"></a></span>
<span id="cb11-86"><a href="#cb11-86"></a><span class="ot">respond ::</span> <span class="kw">forall</span> eff a<span class="op">.</span> <span class="dt">Int</span> <span class="ot">-&gt;</span> a <span class="ot">-&gt;</span> <span class="dt">Handler</span> eff</span>
<span id="cb11-87"><a href="#cb11-87"></a>respond status body <span class="ot">=</span> <span class="kw">do</span></span>
<span id="cb11-88"><a href="#cb11-88"></a>  setStatus status</span>
<span id="cb11-89"><a href="#cb11-89"></a>  sendJson body</span>
<span id="cb11-90"><a href="#cb11-90"></a></span>
<span id="cb11-91"><a href="#cb11-91"></a><span class="ot">respondNoContent ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">Int</span> <span class="ot">-&gt;</span> <span class="dt">Handler</span> eff</span>
<span id="cb11-92"><a href="#cb11-92"></a>respondNoContent status <span class="ot">=</span> <span class="kw">do</span></span>
<span id="cb11-93"><a href="#cb11-93"></a>  setStatus status</span>
<span id="cb11-94"><a href="#cb11-94"></a>  end</span></code></pre></div>
<p>The code is much cleaner now. Let’s try out a few test cases:</p>
<pre class="http"><code>$ http POST http://localhost:4000/v1/users id:=3 name=roger
HTTP/1.1 201 Created
Connection: keep-alive
Content-Length: 0
Date: Sat, 30 Sep 2017 12:13:37 GMT
X-Powered-By: Express</code></pre>
<pre class="http"><code>$ http POST http://localhost:4000/v1/users id:=3
HTTP/1.1 422 Unprocessable Entity
Connection: keep-alive
Content-Length: 102
Content-Type: application/json; charset=utf-8
Date: Sat, 30 Sep 2017 12:13:50 GMT
ETag: W/&quot;66-/c4cfoquQZGwtDBUzHjJydJAHJ0&quot;
X-Powered-By: Express

{
    &quot;error&quot;: &quot;Error at array index 0: (ErrorAtProperty \&quot;name\&quot; (TypeMismatch \&quot;String\&quot; \&quot;Undefined\&quot;))&quot;
}</code></pre>
<pre class="http"><code>$ http POST http://localhost:4000/v1/users id:=3 name=&quot;&quot;
HTTP/1.1 422 Unprocessable Entity
Connection: keep-alive
Content-Length: 39
Content-Type: application/json; charset=utf-8
Date: Sat, 30 Sep 2017 12:14:02 GMT
ETag: W/&quot;27-JQsh12xu/rEFdWy8REF4NMtBUB4&quot;
X-Powered-By: Express

{
    &quot;error&quot;: &quot;User name must not be empty&quot;
}</code></pre>
<pre class="http"><code>$ http POST http://localhost:4000/v1/users id:=0 name=roger
HTTP/1.1 422 Unprocessable Entity
Connection: keep-alive
Content-Length: 36
Content-Type: application/json; charset=utf-8
Date: Sat, 30 Sep 2017 12:14:14 GMT
ETag: W/&quot;24-Pvt1L4eGilBmVtaOGHlSReJ413E&quot;
X-Powered-By: Express

{
    &quot;error&quot;: &quot;User ID must be positive&quot;
}</code></pre>
<pre class="http"><code>$ http GET http://localhost:4000/v1/user/3
HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 23
Content-Type: application/json; charset=utf-8
Date: Sat, 30 Sep 2017 12:14:28 GMT
ETag: W/&quot;17-1scpiB1FT9DBu9s4I1gNWSjH2go&quot;
X-Powered-By: Express

{
    &quot;id&quot;: 3,
    &quot;name&quot;: &quot;roger&quot;
}</code></pre>
<pre class="http"><code>$ http GET http://localhost:4000/v1/user/asdf
HTTP/1.1 422 Unprocessable Entity
Connection: keep-alive
Content-Length: 38
Content-Type: application/json; charset=utf-8
Date: Sat, 30 Sep 2017 12:14:40 GMT
ETag: W/&quot;26-//tvORl1gGDUMwgSaqbEpJhuadI&quot;
X-Powered-By: Express

{
    &quot;error&quot;: &quot;User ID must be an integer&quot;
}</code></pre>
<pre class="http"><code>$ http GET http://localhost:4000/v1/user/-1
HTTP/1.1 422 Unprocessable Entity
Connection: keep-alive
Content-Length: 36
Content-Type: application/json; charset=utf-8
Date: Sat, 30 Sep 2017 12:14:45 GMT
ETag: W/&quot;24-Pvt1L4eGilBmVtaOGHlSReJ413E&quot;
X-Powered-By: Express

{
    &quot;error&quot;: &quot;User ID must be positive&quot;
}</code></pre>
<p>It works as expected.</p>
<h2 id="configuration" data-track-content data-content-name="configuration" data-content-piece="ps-simple-rest-service-2">Configuration<a href="#configuration" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>Right now our application configuration resides in the <code>main</code> function:</p>
<div class="sourceCode" id="cb19"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb19-1"><a href="#cb19-1"></a>main <span class="ot">=</span> runServer port databaseConfig</span>
<span id="cb19-2"><a href="#cb19-2"></a>  <span class="kw">where</span></span>
<span id="cb19-3"><a href="#cb19-3"></a>    port <span class="ot">=</span> <span class="dv">4000</span></span>
<span id="cb19-4"><a href="#cb19-4"></a>    databaseConfig <span class="ot">=</span> { user<span class="op">:</span> <span class="st">&quot;abhinav&quot;</span></span>
<span id="cb19-5"><a href="#cb19-5"></a>                     , password<span class="op">:</span> <span class="st">&quot;&quot;</span></span>
<span id="cb19-6"><a href="#cb19-6"></a>                     , host<span class="op">:</span> <span class="st">&quot;localhost&quot;</span></span>
<span id="cb19-7"><a href="#cb19-7"></a>                     , port<span class="op">:</span> <span class="dv">5432</span></span>
<span id="cb19-8"><a href="#cb19-8"></a>                     , database<span class="op">:</span> <span class="st">&quot;simple_service&quot;</span></span>
<span id="cb19-9"><a href="#cb19-9"></a>                     , <span class="fu">max</span><span class="op">:</span> <span class="dv">10</span></span>
<span id="cb19-10"><a href="#cb19-10"></a>                     , idleTimeoutMillis<span class="op">:</span> <span class="dv">1000</span></span>
<span id="cb19-11"><a href="#cb19-11"></a>                     }</span></code></pre></div>
<p>We are going to extract it out of the code and read it from the environment variables using the <a href="https://pursuit.purescript.org/packages/purescript-config" target="_blank" rel="noopener"><code>purescript-config</code></a> package. First, we install the required packages using <a href="http://bower.io" target="_blank" rel="noopener">bower</a>.</p>
<div class="sourceCode" id="cb20"><pre class="sourceCode bash"><code class="sourceCode bash"><span id="cb20-1"><a href="#cb20-1"></a>$ <span class="ex">bower</span> install --save purescript-node-process purescript-config</span></code></pre></div>
<p>Now, we write the following code in the <code>src/SimpleService/Config.purs</code> file:</p>
<div class="sourceCode" id="cb21"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb21-1"><a href="#cb21-1"></a><span class="kw">module</span> <span class="dt">SimpleService.Config</span> <span class="kw">where</span></span>
<span id="cb21-2"><a href="#cb21-2"></a></span>
<span id="cb21-3"><a href="#cb21-3"></a><span class="kw">import</span> <span class="dt">Data.Config</span></span>
<span id="cb21-4"><a href="#cb21-4"></a><span class="kw">import</span> <span class="dt">Prelude</span></span>
<span id="cb21-5"><a href="#cb21-5"></a></span>
<span id="cb21-6"><a href="#cb21-6"></a><span class="kw">import</span> <span class="dt">Control.Monad.Eff</span> (<span class="dt">Eff</span>)</span>
<span id="cb21-7"><a href="#cb21-7"></a><span class="kw">import</span> <span class="dt">Data.Config.Node</span> (fromEnv)</span>
<span id="cb21-8"><a href="#cb21-8"></a><span class="kw">import</span> <span class="dt">Data.Either</span> (<span class="dt">Either</span>)</span>
<span id="cb21-9"><a href="#cb21-9"></a><span class="kw">import</span> <span class="dt">Data.Set</span> (<span class="dt">Set</span>)</span>
<span id="cb21-10"><a href="#cb21-10"></a><span class="kw">import</span> <span class="dt">Database.PostgreSQL</span> <span class="kw">as</span> <span class="dt">PG</span></span>
<span id="cb21-11"><a href="#cb21-11"></a><span class="kw">import</span> <span class="dt">Node.Process</span> (<span class="dt">PROCESS</span>)</span>
<span id="cb21-12"><a href="#cb21-12"></a></span>
<span id="cb21-13"><a href="#cb21-13"></a><span class="kw">type</span> <span class="dt">ServerConfig</span> <span class="ot">=</span></span>
<span id="cb21-14"><a href="#cb21-14"></a>  {<span class="ot"> port           ::</span> <span class="dt">Int</span></span>
<span id="cb21-15"><a href="#cb21-15"></a>  ,<span class="ot"> databaseConfig ::</span> <span class="dt">PG.PoolConfiguration</span></span>
<span id="cb21-16"><a href="#cb21-16"></a>  }</span>
<span id="cb21-17"><a href="#cb21-17"></a></span>
<span id="cb21-18"><a href="#cb21-18"></a><span class="ot">databaseConfig ::</span> <span class="dt">Config</span> {<span class="ot">name ::</span> <span class="dt">String</span>} <span class="dt">PG.PoolConfiguration</span></span>
<span id="cb21-19"><a href="#cb21-19"></a>databaseConfig <span class="ot">=</span></span>
<span id="cb21-20"><a href="#cb21-20"></a>  { user<span class="op">:</span> _, password<span class="op">:</span> _, host<span class="op">:</span> _, port<span class="op">:</span> _, database<span class="op">:</span> _, <span class="fu">max</span><span class="op">:</span> _, idleTimeoutMillis<span class="op">:</span> _ }</span>
<span id="cb21-21"><a href="#cb21-21"></a>  <span class="op">&lt;$&gt;</span> string {name<span class="op">:</span> <span class="st">&quot;user&quot;</span>}</span>
<span id="cb21-22"><a href="#cb21-22"></a>  <span class="op">&lt;*&gt;</span> string {name<span class="op">:</span> <span class="st">&quot;password&quot;</span>}</span>
<span id="cb21-23"><a href="#cb21-23"></a>  <span class="op">&lt;*&gt;</span> string {name<span class="op">:</span> <span class="st">&quot;host&quot;</span>}</span>
<span id="cb21-24"><a href="#cb21-24"></a>  <span class="op">&lt;*&gt;</span> int    {name<span class="op">:</span> <span class="st">&quot;port&quot;</span>}</span>
<span id="cb21-25"><a href="#cb21-25"></a>  <span class="op">&lt;*&gt;</span> string {name<span class="op">:</span> <span class="st">&quot;database&quot;</span>}</span>
<span id="cb21-26"><a href="#cb21-26"></a>  <span class="op">&lt;*&gt;</span> int    {name<span class="op">:</span> <span class="st">&quot;pool_size&quot;</span>}</span>
<span id="cb21-27"><a href="#cb21-27"></a>  <span class="op">&lt;*&gt;</span> int    {name<span class="op">:</span> <span class="st">&quot;idle_conn_timeout_millis&quot;</span>}</span>
<span id="cb21-28"><a href="#cb21-28"></a></span>
<span id="cb21-29"><a href="#cb21-29"></a><span class="ot">portConfig ::</span> <span class="dt">Config</span> {<span class="ot">name ::</span> <span class="dt">String</span>} <span class="dt">Int</span></span>
<span id="cb21-30"><a href="#cb21-30"></a>portConfig <span class="ot">=</span> int {name<span class="op">:</span> <span class="st">&quot;port&quot;</span>}</span>
<span id="cb21-31"><a href="#cb21-31"></a></span>
<span id="cb21-32"><a href="#cb21-32"></a><span class="ot">serverConfig ::</span> <span class="dt">Config</span> {<span class="ot">name ::</span> <span class="dt">String</span>} <span class="dt">ServerConfig</span></span>
<span id="cb21-33"><a href="#cb21-33"></a>serverConfig <span class="ot">=</span></span>
<span id="cb21-34"><a href="#cb21-34"></a>  { port<span class="op">:</span> _, databaseConfig<span class="op">:</span> _}</span>
<span id="cb21-35"><a href="#cb21-35"></a>  <span class="op">&lt;$&gt;</span> portConfig</span>
<span id="cb21-36"><a href="#cb21-36"></a>  <span class="op">&lt;*&gt;</span> prefix {name<span class="op">:</span> <span class="st">&quot;db&quot;</span>} databaseConfig</span>
<span id="cb21-37"><a href="#cb21-37"></a></span>
<span id="cb21-38"><a href="#cb21-38"></a><span class="ot">readServerConfig ::</span> <span class="kw">forall</span> eff<span class="op">.</span></span>
<span id="cb21-39"><a href="#cb21-39"></a>                    <span class="dt">Eff</span> (<span class="ot">process ::</span> <span class="dt">PROCESS</span> <span class="op">|</span> eff) (<span class="dt">Either</span> (<span class="dt">Set</span> <span class="dt">String</span>) <span class="dt">ServerConfig</span>)</span>
<span id="cb21-40"><a href="#cb21-40"></a>readServerConfig <span class="ot">=</span> fromEnv <span class="st">&quot;SS&quot;</span> serverConfig</span></code></pre></div>
<p>We use the applicative DSL provided in <code>Data.Config</code> module to build a description of our configuration. This description contains the keys and types of the configuration, for consumption by various interpreters. Then we use the <code>fromEnv</code> interpreter to read the config from the environment variables derived from the <code>name</code> fields in the records in the description in the <code>readServerConfig</code> function. We also write a bash script to set those environment variables in the development environment in the <code>setenv.sh</code> file:</p>
<div class="sourceCode" id="cb22"><pre class="sourceCode bash"><code class="sourceCode bash"><span id="cb22-1"><a href="#cb22-1"></a><span class="bu">export</span> <span class="va">SS_PORT=</span>4000</span>
<span id="cb22-2"><a href="#cb22-2"></a><span class="bu">export</span> <span class="va">SS_DB_USER=</span><span class="st">&quot;abhinav&quot;</span></span>
<span id="cb22-3"><a href="#cb22-3"></a><span class="bu">export</span> <span class="va">SS_DB_PASSWORD=</span><span class="st">&quot;&quot;</span></span>
<span id="cb22-4"><a href="#cb22-4"></a><span class="bu">export</span> <span class="va">SS_DB_HOST=</span><span class="st">&quot;localhost&quot;</span></span>
<span id="cb22-5"><a href="#cb22-5"></a><span class="bu">export</span> <span class="va">SS_DB_PORT=</span>5432</span>
<span id="cb22-6"><a href="#cb22-6"></a><span class="bu">export</span> <span class="va">SS_DB_DATABASE=</span><span class="st">&quot;simple_service&quot;</span></span>
<span id="cb22-7"><a href="#cb22-7"></a><span class="bu">export</span> <span class="va">SS_DB_POOL_SIZE=</span>10</span>
<span id="cb22-8"><a href="#cb22-8"></a><span class="bu">export</span> <span class="va">SS_DB_IDLE_CONN_TIMEOUT_MILLIS=</span>1000</span></code></pre></div>
<p>Now we rewrite our <code>src/Main.purs</code> file to use the <code>readServerConfig</code> function:</p>
<div class="sourceCode" id="cb23"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb23-1"><a href="#cb23-1"></a><span class="kw">module</span> <span class="dt">Main</span> <span class="kw">where</span></span>
<span id="cb23-2"><a href="#cb23-2"></a></span>
<span id="cb23-3"><a href="#cb23-3"></a><span class="kw">import</span> <span class="dt">Prelude</span></span>
<span id="cb23-4"><a href="#cb23-4"></a></span>
<span id="cb23-5"><a href="#cb23-5"></a><span class="kw">import</span> <span class="dt">Control.Monad.Eff</span> (<span class="dt">Eff</span>)</span>
<span id="cb23-6"><a href="#cb23-6"></a><span class="kw">import</span> <span class="dt">Control.Monad.Eff.Console</span> (<span class="dt">CONSOLE</span>, log)</span>
<span id="cb23-7"><a href="#cb23-7"></a><span class="kw">import</span> <span class="dt">Data.Either</span> (<span class="dt">Either</span>(..))</span>
<span id="cb23-8"><a href="#cb23-8"></a><span class="kw">import</span> <span class="dt">Data.Set</span> (toUnfoldable)</span>
<span id="cb23-9"><a href="#cb23-9"></a><span class="kw">import</span> <span class="dt">Data.String</span> (joinWith)</span>
<span id="cb23-10"><a href="#cb23-10"></a><span class="kw">import</span> <span class="dt">Database.PostgreSQL</span> <span class="kw">as</span> <span class="dt">PG</span></span>
<span id="cb23-11"><a href="#cb23-11"></a><span class="kw">import</span> <span class="dt">Node.Express.Types</span> (<span class="dt">EXPRESS</span>)</span>
<span id="cb23-12"><a href="#cb23-12"></a><span class="kw">import</span> <span class="dt">Node.Process</span> (<span class="dt">PROCESS</span>)</span>
<span id="cb23-13"><a href="#cb23-13"></a><span class="kw">import</span> <span class="dt">Node.Process</span> <span class="kw">as</span> <span class="dt">Process</span></span>
<span id="cb23-14"><a href="#cb23-14"></a><span class="kw">import</span> <span class="dt">SimpleService.Config</span> (readServerConfig)</span>
<span id="cb23-15"><a href="#cb23-15"></a><span class="kw">import</span> <span class="dt">SimpleService.Server</span> (runServer)</span>
<span id="cb23-16"><a href="#cb23-16"></a></span>
<span id="cb23-17"><a href="#cb23-17"></a><span class="ot">main ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">Eff</span> (<span class="ot"> console ::</span> <span class="dt">CONSOLE</span></span>
<span id="cb23-18"><a href="#cb23-18"></a>                        ,<span class="ot"> express ::</span> <span class="dt">EXPRESS</span></span>
<span id="cb23-19"><a href="#cb23-19"></a>                        ,<span class="ot"> postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span></span>
<span id="cb23-20"><a href="#cb23-20"></a>                        ,<span class="ot"> process ::</span> <span class="dt">PROCESS</span></span>
<span id="cb23-21"><a href="#cb23-21"></a>                        <span class="op">|</span> eff ) <span class="dt">Unit</span></span>
<span id="cb23-22"><a href="#cb23-22"></a>main <span class="ot">=</span> readServerConfig <span class="op">&gt;&gt;=</span> <span class="kw">case</span> _ <span class="kw">of</span></span>
<span id="cb23-23"><a href="#cb23-23"></a>  <span class="dt">Left</span> missingKeys <span class="ot">-&gt;</span> <span class="kw">do</span></span>
<span id="cb23-24"><a href="#cb23-24"></a>    <span class="fu">log</span> <span class="op">$</span> <span class="st">&quot;Unable to start. Missing Env keys: &quot;</span> <span class="op">&lt;&gt;</span> joinWith <span class="st">&quot;, &quot;</span> (toUnfoldable missingKeys)</span>
<span id="cb23-25"><a href="#cb23-25"></a>    Process.exit <span class="dv">1</span></span>
<span id="cb23-26"><a href="#cb23-26"></a>  <span class="dt">Right</span> { port, databaseConfig } <span class="ot">-&gt;</span> runServer port databaseConfig</span></code></pre></div>
<p>If <code>readServerConfig</code> fails, we print the missing keys to the console and exit the process. Else we run the server with the read config.</p>
<p>To test this, we stop the server we ran in the beginning, source the config, and run it again:</p>
<div class="sourceCode" id="cb24"><pre class="sourceCode bash"><code class="sourceCode bash"><span id="cb24-1"><a href="#cb24-1"></a>$ <span class="ex">pulp</span> --watch run</span>
<span id="cb24-2"><a href="#cb24-2"></a><span class="ex">*</span> Building project in /Users/abhinav/ps-simple-rest-service</span>
<span id="cb24-3"><a href="#cb24-3"></a><span class="ex">*</span> Build successful.</span>
<span id="cb24-4"><a href="#cb24-4"></a><span class="ex">Server</span> listening on :4000</span>
<span id="cb24-5"><a href="#cb24-5"></a>^<span class="ex">C</span></span>
<span id="cb24-6"><a href="#cb24-6"></a>$ <span class="bu">source</span> setenv.sh</span>
<span id="cb24-7"><a href="#cb24-7"></a>$ <span class="ex">pulp</span> --watch run</span>
<span id="cb24-8"><a href="#cb24-8"></a><span class="ex">*</span> Building project in /Users/abhinav/ps-simple-rest-service</span>
<span id="cb24-9"><a href="#cb24-9"></a><span class="ex">*</span> Build successful.</span>
<span id="cb24-10"><a href="#cb24-10"></a><span class="ex">Server</span> listening on :4000</span></code></pre></div>
<p>It works! We test the failure case by opening another terminal which does not have the environment variables set:</p>
<div class="sourceCode" id="cb25"><pre class="sourceCode bash"><code class="sourceCode bash"><span id="cb25-1"><a href="#cb25-1"></a>$ <span class="ex">pulp</span> run</span>
<span id="cb25-2"><a href="#cb25-2"></a><span class="ex">*</span> Building project in /Users/abhinav/ps-simple-rest-service</span>
<span id="cb25-3"><a href="#cb25-3"></a><span class="ex">*</span> Build successful.</span>
<span id="cb25-4"><a href="#cb25-4"></a><span class="ex">Unable</span> to start. Missing Env keys: SS_DB_DATABASE, SS_DB_HOST, SS_DB_IDLE_CONN_TIMEOUT_MILLIS, SS_DB_PASSWORD, SS_DB_POOL_SIZE, SS_DB_PORT, SS_DB_USER, SS_PORT</span>
<span id="cb25-5"><a href="#cb25-5"></a><span class="ex">*</span> ERROR: Subcommand terminated with exit code 1</span></code></pre></div>
<p>Up next, we add logging to our application.</p>
<h2 id="logging" data-track-content data-content-name="logging" data-content-piece="ps-simple-rest-service-2">Logging<a href="#logging" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>For logging, we use the <a href="https://pursuit.purescript.org/packages/purescript-logging" target="_blank" rel="noopener"><code>purescript-logging</code></a> package. We write a logger which logs to <code>stdout</code>; in the <code>src/SimpleService/Logger.purs</code> file:</p>
<div class="sourceCode" id="cb26"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb26-1"><a href="#cb26-1"></a><span class="kw">module</span> <span class="dt">SimpleService.Logger</span></span>
<span id="cb26-2"><a href="#cb26-2"></a>  ( debug</span>
<span id="cb26-3"><a href="#cb26-3"></a>  , info</span>
<span id="cb26-4"><a href="#cb26-4"></a>  , warn</span>
<span id="cb26-5"><a href="#cb26-5"></a>  , <span class="fu">error</span></span>
<span id="cb26-6"><a href="#cb26-6"></a>  ) <span class="kw">where</span></span>
<span id="cb26-7"><a href="#cb26-7"></a></span>
<span id="cb26-8"><a href="#cb26-8"></a><span class="kw">import</span> <span class="dt">Prelude</span></span>
<span id="cb26-9"><a href="#cb26-9"></a></span>
<span id="cb26-10"><a href="#cb26-10"></a><span class="kw">import</span> <span class="dt">Control.Logger</span> <span class="kw">as</span> <span class="dt">L</span></span>
<span id="cb26-11"><a href="#cb26-11"></a><span class="kw">import</span> <span class="dt">Control.Monad.Eff.Class</span> (class <span class="dt">MonadEff</span>, liftEff)</span>
<span id="cb26-12"><a href="#cb26-12"></a><span class="kw">import</span> <span class="dt">Control.Monad.Eff.Console</span> <span class="kw">as</span> <span class="dt">C</span></span>
<span id="cb26-13"><a href="#cb26-13"></a><span class="kw">import</span> <span class="dt">Control.Monad.Eff.Now</span> (<span class="dt">NOW</span>, now)</span>
<span id="cb26-14"><a href="#cb26-14"></a><span class="kw">import</span> <span class="dt">Data.DateTime.Instant</span> (toDateTime)</span>
<span id="cb26-15"><a href="#cb26-15"></a><span class="kw">import</span> <span class="dt">Data.Either</span> (fromRight)</span>
<span id="cb26-16"><a href="#cb26-16"></a><span class="kw">import</span> <span class="dt">Data.Formatter.DateTime</span> (<span class="dt">Formatter</span>, format, parseFormatString)</span>
<span id="cb26-17"><a href="#cb26-17"></a><span class="kw">import</span> <span class="dt">Data.Generic.Rep</span> (class <span class="dt">Generic</span>)</span>
<span id="cb26-18"><a href="#cb26-18"></a><span class="kw">import</span> <span class="dt">Data.Generic.Rep.Show</span> (genericShow)</span>
<span id="cb26-19"><a href="#cb26-19"></a><span class="kw">import</span> <span class="dt">Data.String</span> (toUpper)</span>
<span id="cb26-20"><a href="#cb26-20"></a><span class="kw">import</span> <span class="dt">Partial.Unsafe</span> (unsafePartial)</span>
<span id="cb26-21"><a href="#cb26-21"></a></span>
<span id="cb26-22"><a href="#cb26-22"></a><span class="kw">data</span> <span class="dt">Level</span> <span class="ot">=</span> <span class="dt">Debug</span> <span class="op">|</span> <span class="dt">Info</span> <span class="op">|</span> <span class="dt">Warn</span> <span class="op">|</span> <span class="dt">Error</span></span>
<span id="cb26-23"><a href="#cb26-23"></a></span>
<span id="cb26-24"><a href="#cb26-24"></a>derive <span class="kw">instance</span><span class="ot"> eqLevel ::</span> <span class="dt">Eq</span> <span class="dt">Level</span></span>
<span id="cb26-25"><a href="#cb26-25"></a>derive <span class="kw">instance</span><span class="ot"> ordLevel ::</span> <span class="dt">Ord</span> <span class="dt">Level</span></span>
<span id="cb26-26"><a href="#cb26-26"></a>derive <span class="kw">instance</span><span class="ot"> genericLevel ::</span> <span class="dt">Generic</span> <span class="dt">Level</span> _</span>
<span id="cb26-27"><a href="#cb26-27"></a></span>
<span id="cb26-28"><a href="#cb26-28"></a><span class="kw">instance</span><span class="ot"> showLevel ::</span> <span class="dt">Show</span> <span class="dt">Level</span> <span class="kw">where</span></span>
<span id="cb26-29"><a href="#cb26-29"></a>  <span class="fu">show</span> <span class="ot">=</span> <span class="fu">toUpper</span> <span class="op">&lt;&lt;&lt;</span> genericShow</span>
<span id="cb26-30"><a href="#cb26-30"></a></span>
<span id="cb26-31"><a href="#cb26-31"></a><span class="kw">type</span> <span class="dt">Entry</span> <span class="ot">=</span></span>
<span id="cb26-32"><a href="#cb26-32"></a>  {<span class="ot"> level   ::</span> <span class="dt">Level</span></span>
<span id="cb26-33"><a href="#cb26-33"></a>  ,<span class="ot"> message ::</span> <span class="dt">String</span></span>
<span id="cb26-34"><a href="#cb26-34"></a>  }</span>
<span id="cb26-35"><a href="#cb26-35"></a></span>
<span id="cb26-36"><a href="#cb26-36"></a><span class="ot">dtFormatter ::</span> <span class="dt">Formatter</span></span>
<span id="cb26-37"><a href="#cb26-37"></a>dtFormatter <span class="ot">=</span> unsafePartial <span class="op">$</span> fromRight <span class="op">$</span> parseFormatString <span class="st">&quot;YYYY-MM-DD HH:mm:ss.SSS&quot;</span></span>
<span id="cb26-38"><a href="#cb26-38"></a></span>
<span id="cb26-39"><a href="#cb26-39"></a><span class="ot">logger ::</span> <span class="kw">forall</span> m e<span class="op">.</span> (</span>
<span id="cb26-40"><a href="#cb26-40"></a>          <span class="dt">MonadEff</span> (<span class="ot">console ::</span> <span class="dt">C.CONSOLE</span>,<span class="ot"> now ::</span> <span class="dt">NOW</span> <span class="op">|</span> e) m) <span class="ot">=&gt;</span> <span class="dt">L.Logger</span> m <span class="dt">Entry</span></span>
<span id="cb26-41"><a href="#cb26-41"></a>logger <span class="ot">=</span> <span class="dt">L.Logger</span> <span class="op">$</span> \{ level, message } <span class="ot">-&gt;</span> liftEff <span class="kw">do</span></span>
<span id="cb26-42"><a href="#cb26-42"></a>  time <span class="ot">&lt;-</span> toDateTime <span class="op">&lt;$&gt;</span> now</span>
<span id="cb26-43"><a href="#cb26-43"></a>  C.log <span class="op">$</span> <span class="st">&quot;[&quot;</span> <span class="op">&lt;&gt;</span> format dtFormatter time <span class="op">&lt;&gt;</span> <span class="st">&quot;] &quot;</span> <span class="op">&lt;&gt;</span> <span class="fu">show</span> level <span class="op">&lt;&gt;</span> <span class="st">&quot; &quot;</span> <span class="op">&lt;&gt;</span> message</span>
<span id="cb26-44"><a href="#cb26-44"></a></span>
<span id="cb26-45"><a href="#cb26-45"></a><span class="fu">log</span><span class="ot"> ::</span> <span class="kw">forall</span> m e<span class="op">.</span></span>
<span id="cb26-46"><a href="#cb26-46"></a>        <span class="dt">MonadEff</span> (<span class="ot">console ::</span> <span class="dt">C.CONSOLE</span> ,<span class="ot"> now ::</span> <span class="dt">NOW</span> <span class="op">|</span> e) m</span>
<span id="cb26-47"><a href="#cb26-47"></a>     <span class="ot">=&gt;</span> <span class="dt">Entry</span> <span class="ot">-&gt;</span> m <span class="dt">Unit</span></span>
<span id="cb26-48"><a href="#cb26-48"></a><span class="fu">log</span> entry<span class="op">@</span>{level} <span class="ot">=</span> L.log (L.cfilter (\e <span class="ot">-&gt;</span> e<span class="op">.</span>level <span class="op">==</span> level) logger) entry</span>
<span id="cb26-49"><a href="#cb26-49"></a></span>
<span id="cb26-50"><a href="#cb26-50"></a><span class="ot">debug ::</span> <span class="kw">forall</span> m e<span class="op">.</span></span>
<span id="cb26-51"><a href="#cb26-51"></a>         <span class="dt">MonadEff</span> (<span class="ot">console ::</span> <span class="dt">C.CONSOLE</span> ,<span class="ot"> now ::</span> <span class="dt">NOW</span> <span class="op">|</span> e) m <span class="ot">=&gt;</span> <span class="dt">String</span> <span class="ot">-&gt;</span> m <span class="dt">Unit</span></span>
<span id="cb26-52"><a href="#cb26-52"></a>debug message <span class="ot">=</span> <span class="fu">log</span> { level<span class="op">:</span> <span class="dt">Debug</span>, message }</span>
<span id="cb26-53"><a href="#cb26-53"></a></span>
<span id="cb26-54"><a href="#cb26-54"></a><span class="ot">info ::</span> <span class="kw">forall</span> m e<span class="op">.</span></span>
<span id="cb26-55"><a href="#cb26-55"></a>        <span class="dt">MonadEff</span> (<span class="ot">console ::</span> <span class="dt">C.CONSOLE</span> ,<span class="ot"> now ::</span> <span class="dt">NOW</span> <span class="op">|</span> e) m <span class="ot">=&gt;</span> <span class="dt">String</span> <span class="ot">-&gt;</span> m <span class="dt">Unit</span></span>
<span id="cb26-56"><a href="#cb26-56"></a>info message <span class="ot">=</span> <span class="fu">log</span> { level<span class="op">:</span> <span class="dt">Info</span>, message }</span>
<span id="cb26-57"><a href="#cb26-57"></a></span>
<span id="cb26-58"><a href="#cb26-58"></a><span class="ot">warn ::</span> <span class="kw">forall</span> m e<span class="op">.</span></span>
<span id="cb26-59"><a href="#cb26-59"></a>        <span class="dt">MonadEff</span> (<span class="ot">console ::</span> <span class="dt">C.CONSOLE</span> ,<span class="ot"> now ::</span> <span class="dt">NOW</span> <span class="op">|</span> e) m <span class="ot">=&gt;</span> <span class="dt">String</span> <span class="ot">-&gt;</span> m <span class="dt">Unit</span></span>
<span id="cb26-60"><a href="#cb26-60"></a>warn message <span class="ot">=</span> <span class="fu">log</span> { level<span class="op">:</span> <span class="dt">Warn</span>, message }</span>
<span id="cb26-61"><a href="#cb26-61"></a></span>
<span id="cb26-62"><a href="#cb26-62"></a><span class="fu">error</span><span class="ot"> ::</span> <span class="kw">forall</span> m e<span class="op">.</span></span>
<span id="cb26-63"><a href="#cb26-63"></a>         <span class="dt">MonadEff</span> (<span class="ot">console ::</span> <span class="dt">C.CONSOLE</span> ,<span class="ot"> now ::</span> <span class="dt">NOW</span> <span class="op">|</span> e) m <span class="ot">=&gt;</span> <span class="dt">String</span> <span class="ot">-&gt;</span> m <span class="dt">Unit</span></span>
<span id="cb26-64"><a href="#cb26-64"></a><span class="fu">error</span> message <span class="ot">=</span> <span class="fu">log</span> { level<span class="op">:</span> <span class="dt">Error</span>, message }</span></code></pre></div>
<p><code>purescript-logging</code> lets us define our own logging levels and loggers. We define four log levels, and a log entry type with the log level and the message. Then we write the logger which will print the log entry to <code>stdout</code> along with the current time as a well formatted string. We define convenience functions for each log level.</p>
<p>Before we proceed, let’s install the required dependencies.</p>
<div class="sourceCode" id="cb27"><pre class="sourceCode bash"><code class="sourceCode bash"><span id="cb27-1"><a href="#cb27-1"></a>$ <span class="ex">bower</span> install --save purescript-logging purescript-now purescript-formatters</span></code></pre></div>
<p>Now we add a request logger middleware to our server in the <code>src/SimpleService/Server.purs</code> file:</p>
<div class="sourceCode" id="cb28"><pre class="sourceCode haskell"><code class="sourceCode haskell"><span id="cb28-1"><a href="#cb28-1"></a><span class="co">-- previous code</span></span>
<span id="cb28-2"><a href="#cb28-2"></a><span class="kw">import</span> <span class="dt">Control.Monad.Eff.Console</span> (<span class="dt">CONSOLE</span>)</span>
<span id="cb28-3"><a href="#cb28-3"></a><span class="kw">import</span> <span class="dt">Control.Monad.Eff.Now</span> (<span class="dt">NOW</span>)</span>
<span id="cb28-4"><a href="#cb28-4"></a><span class="kw">import</span> <span class="dt">Data.Maybe</span> (maybe)</span>
<span id="cb28-5"><a href="#cb28-5"></a><span class="kw">import</span> <span class="dt">Data.String</span> (toUpper)</span>
<span id="cb28-6"><a href="#cb28-6"></a><span class="kw">import</span> <span class="dt">Node.Express.App</span> (<span class="dt">App</span>, all, delete, get, http, listenHttp, post, use, useExternal, useOnError)</span>
<span id="cb28-7"><a href="#cb28-7"></a><span class="kw">import</span> <span class="dt">Node.Express.Handler</span> (<span class="dt">Handler</span>, next)</span>
<span id="cb28-8"><a href="#cb28-8"></a><span class="kw">import</span> <span class="dt">Node.Express.Request</span> (getMethod, getPath)</span>
<span id="cb28-9"><a href="#cb28-9"></a><span class="kw">import</span> <span class="dt">SimpleService.Logger</span> <span class="kw">as</span> <span class="dt">Log</span></span>
<span id="cb28-10"><a href="#cb28-10"></a><span class="co">-- previous code</span></span>
<span id="cb28-11"><a href="#cb28-11"></a></span>
<span id="cb28-12"><a href="#cb28-12"></a><span class="ot">requestLogger ::</span> <span class="kw">forall</span> eff<span class="op">.</span> <span class="dt">Handler</span> (<span class="ot">console ::</span> <span class="dt">CONSOLE</span>,<span class="ot"> now ::</span> <span class="dt">NOW</span> <span class="op">|</span> eff)</span>
<span id="cb28-13"><a href="#cb28-13"></a>requestLogger <span class="ot">=</span> <span class="kw">do</span></span>
<span id="cb28-14"><a href="#cb28-14"></a>  method <span class="ot">&lt;-</span> getMethod</span>
<span id="cb28-15"><a href="#cb28-15"></a>  path   <span class="ot">&lt;-</span> getPath</span>
<span id="cb28-16"><a href="#cb28-16"></a>  Log.debug <span class="op">$</span> <span class="st">&quot;HTTP: &quot;</span> <span class="op">&lt;&gt;</span> <span class="fu">maybe</span> <span class="st">&quot;&quot;</span> <span class="fu">id</span> ((<span class="fu">toUpper</span> <span class="op">&lt;&lt;&lt;</span> <span class="fu">show</span>) <span class="op">&lt;$&gt;</span> method) <span class="op">&lt;&gt;</span> <span class="st">&quot; &quot;</span> <span class="op">&lt;&gt;</span> path</span>
<span id="cb28-17"><a href="#cb28-17"></a>  next</span>
<span id="cb28-18"><a href="#cb28-18"></a></span>
<span id="cb28-19"><a href="#cb28-19"></a><span class="ot">app ::</span> <span class="kw">forall</span> eff<span class="op">.</span></span>
<span id="cb28-20"><a href="#cb28-20"></a>       <span class="dt">PG.Pool</span></span>
<span id="cb28-21"><a href="#cb28-21"></a>    <span class="ot">-&gt;</span> <span class="dt">App</span> (<span class="ot">postgreSQL ::</span> <span class="dt">PG.POSTGRESQL</span>,<span class="ot"> console ::</span> <span class="dt">CONSOLE</span>,<span class="ot"> now ::</span> <span class="dt">NOW</span> <span class="op">|</span> eff)</span>
<span id="cb28-22"><a href="#cb28-22"></a>app pool <span class="ot">=</span> <span class="kw">do</span></span>
<span id="cb28-23"><a href="#cb28-23"></a>  useExternal jsonBodyParser</span>
<span id="cb28-24"><a href="#cb28-24"></a>  use requestLogger</span>
<span id="cb28-25"><a href="#cb28-25"></a>  <span class="co">-- previous code</span></span></code></pre></div>
<p>We also convert all our previous logging statements which used <code>Console.log</code> to use <code>SimpleService.Logger</code> and add logs in our handlers. We can see logging in effect by restarting the server and hitting it:</p>
<div class="sourceCode" id="cb29"><pre class="sourceCode bash"><code class="sourceCode bash"><span id="cb29-1"><a href="#cb29-1"></a>$ <span class="ex">pulp</span> --watch run</span>
<span id="cb29-2"><a href="#cb29-2"></a><span class="ex">*</span> Building project in /Users/abhinav/ps-simple-rest-service</span>
<span id="cb29-3"><a href="#cb29-3"></a><span class="ex">*</span> Build successful.</span>
<span id="cb29-4"><a href="#cb29-4"></a>[<span class="ex">2017-09-30</span> 16:02:41.634] INFO Server listening on :4000</span>
<span id="cb29-5"><a href="#cb29-5"></a>[<span class="ex">2017-09-30</span> 16:02:43.494] DEBUG HTTP: PATCH /v1/user/3</span>
<span id="cb29-6"><a href="#cb29-6"></a>[<span class="ex">2017-09-30</span> 16:02:43.517] DEBUG Updated user: 3</span>
<span id="cb29-7"><a href="#cb29-7"></a>[<span class="ex">2017-09-30</span> 16:03:46.615] DEBUG HTTP: DELETE /v1/user/3</span>
<span id="cb29-8"><a href="#cb29-8"></a>[<span class="ex">2017-09-30</span> 16:03:46.635] DEBUG Deleted user 3</span>
<span id="cb29-9"><a href="#cb29-9"></a>[<span class="ex">2017-09-30</span> 16:05:03.805] DEBUG HTTP: GET /v1/users</span></code></pre></div>
<h2 id="conclusion" data-track-content data-content-name="conclusion" data-content-piece="ps-simple-rest-service-2">Conclusion<a href="#conclusion" class="ref-link"></a><a href="#top" class="top-link" title="Back to top"></a></h2>
<p>In this tutorial we learned how to create a simple JSON REST web service written in PureScript with persistence, validation, configuration and logging. The complete code for this tutorial can be found in <a href="https://github.com/abhin4v/ps-simple-rest-service" target="_blank" rel="noopener">github</a>. Discuss this post in the <a href="https://abhinavsarkar.net/posts/ps-simple-rest-service-2/#comment-container">comments</a>.</p><p>If you liked this post, please <a href="https://abhinavsarkar.net/posts/ps-simple-rest-service-2/#comment-container">leave a comment</a>.</p><img src="https://anna.abhinavsarkar.net/piwik.php?idsite=1&amp;rec=1" style="border:0; display: none;" />
<div class="author">
  <img src="https://nilenso.com/images/alumni/abhinav.webp" style="width: 96px; height: 96;">
  <span style="position: absolute; padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/abhin4v">Abhinav Sarkar</a> - check out <a href="https://abhinavsarkar.net">All posts on abhinavsarkar.net</a></i>
  </span>
</div>

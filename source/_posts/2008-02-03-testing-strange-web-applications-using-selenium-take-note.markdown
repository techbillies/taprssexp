---
title: "Testing strange web applications using Selenium? Take note."
kind: article
created_at: 2008-02-03 11:22:00 UTC
author: Steven Deobald
layout: post
---
<span style="font-size:180%;">Update to: <a href="http://www.mail-archive.com/selenium-users@lists.public.thoughtworks.org/msg00652.html">Workaround for <span style="font-family: courier new;">alert()</span> and <span style="font-family: courier new;">confirm()</span> during <span style="font-family: courier new;">onload()</span></a></span><br /><br />A change in Selenium has caused this workaround to stop working for those inclined to simply copy and paste Alistair's original solution. These days, if you want to give Selenium access to <span style="font-family: courier new;">alert()</span> and <span style="font-family: courier new;">confirm()</span> dialogs your application pops up during the <span style="font-family: courier new;">onload </span>event, you'll need to reference <span style="font-family: courier new;">parent.selenium.browserbot</span> instead. As per the original solution, execute the following code anywhere (either statically in the page or in the <span style="font-family: courier new;">onload</span> event itself) before the JavaScript which pops up a dialog:<br /><br /><span style="font-family: courier new; font-weight: bold;">var browserbot = parent.selenium.browserbot;</span><br /><span style="font-family: courier new; font-weight: bold;"> if (browserbot) {</span><br /><span style="font-family: courier new; font-weight: bold;">    browserbot.modifyWindowToRecordPopUpDialogs(window, browserbot);</span><br /><span style="font-family: courier new; font-weight: bold;"> }</span><br /><br />Tada! You're home free and your QAs can happily automate testing through the UI once again.<br /><br />Also of note: If you're popping up alert and confirm dialogs in an <span style="font-family: courier new;">IFrame </span>(egads!), you'll need to reference <span style="font-family: courier new;">parent.parent.selenium.browserbot</span>.<br /><br />Happy testing!
<div class="author">
  <img src="http://nilenso.com/images/alumni/steven.webp" style="width: 96px; height: 96;">
  <span style="position: absolute; padding: 32px 15px;">
    <i>Original post by <a href="http://twitter.com/deobald">Steven Deobald</a> - check out <a href="http://blog.deobald.ca/">Hungry, horny, sleepy, curious.</a></i>
  </span>
</div>

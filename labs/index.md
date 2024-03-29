---
layout: default
title: Projects and code
---

<style>
ul {
	margin-left: 0;
	list-style: none;
}
aside {
	margin-left: 0;
	margin-right: 0;
	border: 1px solid black;
}
aside > div {
	margin: 1em;
}
aside img {
	float: right;
	margin: 1em;
}
aside hgroup > * {
	display: inline;
}
</style>

<h2>2023</h2>

* [wbe.rs](https://github.com/delan/wbe.rs) 🦀 — Loose implementation of the [*Web Browser Engineering*](https://browser.engineering) book in Rust.
* [worstpractice](https://github.com/delan/worstpractice) — Viewer for XML patient records exported by Best Practice (Bp Premier).

<h2>2022</h2>

* [usb3sun](https://github.com/delan/usb3sun) — USB input adapter (open hardware, open firmware) for Sun workstations.
* [reverssg](https://github.com/delan/reverssg) — <em>Super Solvers: Gizmos &amp; Gadgets!</em> decompilation and reverse engineering.

<h2>2021</h2>

<aside><div markdown="1">
<img src="/images/ssgesus.png" width="238">
<hgroup>
<h3 markdown="1">[ssgesus](https://bucket.daz.cat/ssgesus/)</h3>
<em markdown="1"> [[source](https://bitbucket.org/delan/ssgesus)]</em>
</hgroup>
<em>Super Solvers: Gizmos &amp; Gadgets!</em> route planner.

This 1990s educational puzzle platformer game has been a favourite of mine since I was six years old, but I’m now speedrunning and reverse engineering it.

The objective of the game is to find the best parts to build vehicles that win races, solving STEM puzzles along the way.
The parts are placed randomly, but the RNG is seeded with the Unix time, so we can predict where the best parts will be for any given run.
<br style="clear: both;">
</div></aside>

<aside><div markdown="1">
<img src="/images/osmpip.png" width="238">
<hgroup>
<h3 markdown="1">[osmpip](https://bitbucket.org/delan/osmpip)</h3>
<em markdown="1"> [[source](https://bitbucket.org/delan/osmpip)]</em>
</hgroup>
OpenStreetMap renderer for dashcam GPS data.

I wrote this program to make a map overlay for my road trip music videos (not yet publicly released), inspired by the map window in [Dashcam Viewer](https://dashcamviewer.com/), without hammering map services like Google Maps or the public OpenStreetMap server with requests.
It instead uses an OpenStreetMap tile server the user sets up on their own machine.

This was feasible because many dashcams embed hidden but machine-readable GPS data in each video file, in addition to optionally burning the coordinates as text into the video frames.
<br style="clear: both;">
</div></aside>

<aside><div markdown="1">
<img src="/images/mmm.png" width="238">
<hgroup>
<h3 markdown="1">[mmm](https://bucket.daz.cat/mmm/per/drawing.svg)</h3>
<em markdown="1"> [[source](https://bitbucket.org/delan/mmm)]</em>
<em markdown="1"> [[Steam page](https://steamcommunity.com/sharedfiles/filedetails/?id=2575991046)]</em>
</hgroup>
<em>Mini Metro</em> map for Perth, Australia.

Maps for this minimalist rail transit strategy game are written in JSON, and include the visible geometry of land masses and water bodies, plus invisible geometry for things like the regions that stations can spawn in.

I traced the land masses and defined the other geometry in Inkscape, but there’s no level editor available to the public, so I embedded a script in the SVG that reads *its own path data* and generates a valid <em>Mini Metro</em> map.
<br style="clear: both;">
</div></aside>

* [fuckgitmemory](https://bitbucket.org/delan/fuckgitmemory) — User script that blocks GitHub scrapers, taking you to real issue pages.

* [cursedtv](https://bitbucket.org/delan/cursedtv) 🦀 — Generates XSPF playlists with TV shows, bumpers, and ads.

<h2>2020</h2>

<aside><div markdown="1">
<img src="/images/badapple.png" width="238">
<hgroup>
<h3 markdown="1">[badapple.rs](https://bitbucket.org/delan/badapple.rs)</h3>
<span> 🦀</span>
<em markdown="1"> [[source](https://bitbucket.org/delan/badapple.rs)]</em>
<em markdown="1"> [[blog post]({% post_url 2020-06-29-bad-apple-for-taskmgr %})]</em>
</hgroup>
Video player for Task Manager’s CPU graphs.

This project generates real CPU load with thread affinity to shade the usage tiles, unlike the more common approaches of hacking the taskmgr process or using video editing.

I managed to make a passable 11x6 canvas with only six cores and twelve hardware threads, with libvirt and KVM and careful guest configuration.
<br style="clear: both;">
</div></aside>

* [xd](https://bitbucket.org/delan/xd) 🦀 — Tool that dumps binary input in a more human-readable format.

* [dis2ello](https://bitbucket.org/delan/dis2ello) 🦀 — Discord bot that posts tasks or shopping list items to Trello.

* [togpac](https://bitbucket.org/delan/togpac) — [Firefox extension](https://addons.mozilla.org/firefox/addon/togpac/) for a button that disables your proxy settings.

* [memories](https://bitbucket.org/delan/memories) — Self-hosted photo viewer for sharing with family and friends.

<h2>2019</h2>

* [pledge-rs](https://github.com/i80and/pledge-rs) 🦀 — Rust bindings for OpenBSD’s [pledge(2)](https://man.openbsd.org/OpenBSD-5.9/pledge.2) interface.

* [nonymous](https://bitbucket.org/delan/nonymous) 🦀 — DNS library (no-std and no-alloc friendly) and DNS tools.

* [ing2ynab](https://bitbucket.org/delan/ing2ynab) 🦀 — Cleans up ing.com.au transactions for YNAB.

<h2>2017</h2>

* [mazuals](https://bitbucket.org/delan/mazuals) — User script for Mazda’s service manuals.

<h2>2016</h2>

* [hardtype](https://bitbucket.org/delan/hardtype) — Aggressively overrides FreeType rendering for Fontconfig-oblivious software.

* [chempoodle](https://bitbucket.org/delan/chempoodle) — Allows you to run ChemDoodle with any Java implementation.

<h2>2015</h2>

<aside><div markdown="1">
<img src="/images/matrix86.png" width="238">
<hgroup>
<h3 markdown="1">[matrix86](https://bitbucket.org/delan/matrix86)</h3>
<em markdown="1"> [[source](https://bitbucket.org/delan/matrix86)]</em>
</hgroup>
Real mode demo inspired by [cmatrix](http://www.asty.org/cmatrix/) in 188 bytes of 80286 machine code.
<br style="clear: both;">
</div></aside>

* [floatvis](floatvis) — Online IEEE 754 playground.

<h2>2014</h2>

* [halokey](halokey) — DigitalProductId generator for the Gearbox port of Halo: Combat Evolved.

* [peereval](peereval) — Calculator for peer evaluations in group projects adding up to 100%.

* [cygmake](https://github.com/delan/cygmake) — Clean room Cygwin package builder, used to compile [Irssi’s](http://irssi.org/) Windows builds.

* [scrapexam](https://github.com/delan/scrapexam) — Scraper for the Curtin University past exam paper archive.

<h2>2013</h2>

* [lyletube](https://github.com/delan/lyletube) — YouTube jukebox for LAN parties, with suggestions and automatic playback.

* [scrapetopia](https://github.com/delan/scrapetopia) — Scraper for the Curtin University Lectopia video archive.

* [labstat](https://github.com/delan/labstat) — Tools for getting information about the Curtin University network.

* [lookout](https://github.com/delan/lookout) — Light and aesthetic server health monitor using Flask and psutil.

<h2>2012</h2>

<aside><div markdown="1">
<img src="/images/charming.png" width="238">
<hgroup>
<h3 markdown="1">[charming](https://charming.daz.cat)</h3>
<span> 🦀</span>
<em markdown="1"> [[source](https://github.com/delan/charming)]</em>
</hgroup>
Fast mobile-friendly Unicode character map.

Search for characters and named sequences by their names, aliases, Unihan definitions, code points, or paste them in directly to break down the grapheme clusters into their constituent parts.

This progressive web app can run completely offline, since the entire working data set is downloaded to the client at once.
Novel techniques for packing the Unicode data keep the page weight under 2 MB over the wire and under 9 MB in RAM, so that it can even run comfortably on my ancient iPhone SE.
<br style="clear: both;">
</div></aside>

* [cabinvis](cabinvis) — Visualise binary files using Hilbert curves, inspired by [Aldo Cortesi’s blog post](http://corte.si/posts/visualisation/binvis/index.html).

* [utf8check](https://github.com/delan/utf8check) — Extremely fast and strict UTF-8 stream validator, inspector and sanitiser.

<h2>2011</h2>

* [brief](https://github.com/delan/brief) — Configurable Brainfuck interpreter with loop caching and run length execution.

* [digilogue](digilogue) — Show this signal simulator to anyone who buys overpriced digital cables.

* [facepaste](https://github.com/delan/facepaste) — Facebook album downloader for Firefox (defunct).

<h2>University assignments</h2>

* [Artificial and Machine Intelligence 300: search assignment](https://bitbucket.org/delan/stratagem)
* [Fundamental Concepts of Cryptography 200: DEA assignment](https://bitbucket.org/delan/focaccia)
* [Fundamental Concepts of Cryptography 200: RSA assignment](https://bitbucket.org/delan/recusant)
* [Fundamental Concepts of Cryptography 200: final assignment](https://bitbucket.org/delan/funcept)
* [Computer Graphics 200: POV-Ray assignment](https://github.com/delan/phongray)
* [Computer Graphics 200: OpenGL assignment](https://github.com/delan/outback)
* [Programming Languages 200: parser assignment](https://github.com/delan/plc)
* [Software Engineering 200: Mars rover assignment](https://github.com/delan/rover)
* [Design and Analysis of Algorithms 300: Huffman assignment](https://github.com/delan/daahuff)
* [Personal Software Processes 251: PSP assignments](https://github.com/delan/psphw)
* [Project Design and Management 300: group assignment](https://github.com/delan/tothemoon)
* [Computer Communications 200: stop and wait assignment](https://github.com/delan/hammertime)
* [Operating Systems 200: scheduler assignment](https://github.com/delan/osched)
* [Data Structures and Algorithms 120: inventory assignment](https://github.com/delan/dsainventory)
* [Data Structures and Algorithms 120: mining assignment](https://github.com/delan/dsamining)
* [Unix and C Programming 120: calendar assignment](https://github.com/delan/ucpcal)

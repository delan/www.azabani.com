---
layout: default
title: "Meet the CSS highlight pseudos"
date: 2022-09-01 23:00:00 +0800
tags: home igalia
_preview_description: "Everything you wanted to know about custom highlights, spelling and grammar errors, and how ::selection is changing in CSS."
_preview_image: /images/meethp-preview.jpg
_footer_twitter: https://twitter.com/dazabani/status/1565367814591901696
---

A year and a half ago, I was asked to help upstream a Chromium patch allowing authors to recolor <span class="_spelling">spelling</span> and <span class="_grammar">grammar</span> errors in CSS.
At the time, I didn’t realise that this was part of a far more ambitious effort to reimagine spelling errors, grammar errors, text selections, and more as a coherent system that didn’t yet exist as such in any browser.
That system is known as the _highlight pseudos_, and this post will focus on the design of said system and its consequences for authors.

This is the third part of a series ([part one], [part two]) about Igalia’s work towards making the CSS highlight pseudos a reality.

[part one]: {% post_url 2021-05-17-spelling-grammar %}
[part two]: {% post_url 2021-12-16-spelling-grammar-2 %}

<aside markdown="1">
**Update (2024-04-29):**
- added [details about applicable properties](#applicable-properties)
- removed [§ _Accessing global constants_](#accessing-global-constants)
- added [§ _Custom properties_](#custom-properties)
</aside>

<style>
article { --cr-highlight: #3584E4; --cr-highlight-aC0h: #3584E4C0; }
article figure > img { max-width: 100%; }
article figure > figcaption { max-width: 30rem; margin-left: auto; margin-right: auto; }
article pre, article code { font-family: Inconsolata, monospace, monospace; }
article aside, article blockquote { font-size: 0.75em; max-width: 30rem; }
article aside { margin-left: 0; padding-left: 1rem; border-left: 3px double rebeccapurple; }
article blockquote { margin-left: 3rem; }
article blockquote:before { margin-left: -2rem; }

._spelling, ._grammar { text-decoration-thickness: /* iOS takes 0 literally */ 1px; text-decoration-skip-ink: none; }
._spelling { text-decoration: /* not a shorthand on iOS */ underline; text-decoration-style: wavy; text-decoration-color: red; }
._grammar { text-decoration: /* not a shorthand on iOS */ underline; text-decoration-style: wavy; text-decoration-color: green; }
._example { border: 2px dotted rebeccapurple; }
._example * + *, ._hpdemo * + * { margin-top: 0; }

._checker { position: relative; margin-left: auto; margin-right: auto; }
._checker:focus { outline: none; }
._checker::before { display: flex; align-items: center; justify-content: center; position: absolute; top: 0; bottom: 0; left: 0; right: 0; width: 100%; font-size: 7em; color: transparent; background: transparent; content: "▶"; }
._checker:not(:focus)::before { color: rebeccapurple; background: #66339940; }

._checker tbody th { text-align: left; }
._checker ._live::selection, ._checker ._live *::selection { color: currentColor; background: transparent; }
._checker:not(:focus) ._live > div { visibility: hidden; }
._checker:not([data-phase=done]):not(#specificity) ._live > div,
._checker:not([data-phase=done]):not(#specificity) ._live > div * { color: transparent; }
._checker:not([data-phase=done]):not(#specificity) ._live > div::selection,
._checker:not([data-phase=done]):not(#specificity) ._live > div *::selection { color: transparent; }
._checker:not([data-phase=done]):not(#specificity) ._live > div::highlight(checker),
._checker:not([data-phase=done]):not(#specificity) ._live > div *::highlight(checker),
._checker:not([data-phase=done]):not(#specificity) ._live > div::highlight(lower),
._checker:not([data-phase=done]):not(#specificity) ._live > div *::highlight(lower) { color: transparent; }
._checker ._live > div { width: 5em; }
._checker ._live > div { position: relative; line-height: 1; }
._checker ._live > div > span { position: absolute; margin: 0; padding-top: calc((1.5em - 1em) / 2); width: 5em; }

/*
    ::highlight() [end-to-end test]
    = no, if the pseudo selector is broken and/or no active highlight
    = yes, if the pseudo selector works and highlight is active
*/
._checker ._custom
    :nth-child(2) { color: transparent; background: transparent; }
._checker ._custom
    :nth-child(1)::highlight(checker) { color: transparent; }
._checker ._custom
    :nth-child(2)::highlight(checker) { color: CanvasText; background: Canvas; }

/*
    ::highlight() [selector]
    = no, if the pseudo selector is unsupported
    = yes, if the pseudo selector is supported
    • highlight not active, only for selector list validity
*/
._checker ._chps
    :nth-child(2) { color: transparent; }
._checker ._chps
    :nth-child(1), :not(*)::highlight(checker) { color: transparent; }
._checker ._chps
    :nth-child(2), :not(*)::highlight(checker) { color: CanvasText; }

/*
    ::highlight() [API]
    = no, if the API is missing or broken
    = yes, if the API is present and working
*/
._checker ._cha {}

/*
    ::spelling-error [end-to-end test]
    = no, if the pseudo selector is broken and/or no active highlight
    = yes, if the pseudo selector works and highlight is active
*/
._checker [spellcheck]
    :nth-child(2) { color: transparent; background: transparent; }
._checker [spellcheck]
    :nth-child(1)::spelling-error { color: transparent; }
._checker [spellcheck]
    :nth-child(2)::spelling-error { color: CanvasText; background: Canvas; }
._checker [spellcheck]
    *::spelling-error { text-decoration: none; }

/*
    Highlight inheritance (::highlight)
    = no, if var() inherits from originating element
    = yes, if var() ignores originating element and uses fallback
*/
._checker ._hih
    { color: transparent; background: transparent; }
._checker ._hih::highlight(checker)
    { --t: transparent; --x: CanvasText; --y: Canvas; }
._checker ._hih :nth-child(1)::highlight(checker)
    { color: var(--t, CanvasText); background: var(--t, Canvas); }
._checker ._hih :nth-child(2)::highlight(checker)
    { color: var(--x, transparent); background: var(--y, transparent); }

/*
    Highlight inheritance (::selection)
    = no, if var() inherits from originating element
    = yes, if var() ignores originating element and uses fallback
*/
._checker ._his
    { color: transparent; background: transparent; }
._checker ._his::selection
    { --t: transparent; --x: CanvasText; --y: Canvas; }
._checker ._his :nth-child(1)::selection
    { color: var(--t, CanvasText); background: var(--t, Canvas); }
._checker ._his :nth-child(2)::selection
    { color: var(--x, transparent); background: var(--y, transparent); }

/*
    Highlight overlay painting
    = no, if currentColor takes color from originating element only
    = yes, if currentColor takes color from next active highlight
    • lower highlight “yes” is hidden by ‘-webkit-text-fill-color’
*/
._checker ._hop
    { color: transparent; background: transparent; }
._checker ._hop :nth-child(1) { color: CanvasText; }
._checker ._hop :nth-child(1)::highlight(lower) { color: transparent; }
._checker ._hop :nth-child(1)::highlight(checker) { color: currentColor; }
._checker ._hop :nth-child(2) { color: transparent; }
._checker ._hop :nth-child(2)::highlight(lower) { color: CanvasText; -webkit-text-fill-color: transparent; }
._checker ._hop :nth-child(2)::highlight(checker) { color: currentColor; -webkit-text-fill-color: currentColor; }

._table { font-size: 0.75em; }
._table td, ._table th { vertical-align: top; border: 1px solid black; }
._table td:not(._tight), ._table th:not(._tight) { padding: 0.5em; }
._tight picture, ._tight img { vertical-align: top; }
._compare * + *, ._tight * + *, ._gifs * + * { margin-top: 0; }
._compare { max-width: 100%; border: 1px solid rebeccapurple; }
._compare > div { max-width: 100%; position: relative; touch-action: pinch-zoom; --cut: 50%; }
._compare > div > * { vertical-align: top; max-width: 100%; }
._compare > div > :nth-child(1) { position: absolute; clip: rect(auto, auto, auto, var(--cut)); }
._compare > div > :nth-child(2) { position: absolute; width: var(--cut); height: 100%; border-right: 1px solid rebeccapurple; }
._compare > div > :nth-child(2):before { content: var(--left-label); color: rebeccapurple; font-size: 0.75em; position: absolute; right: 0.5em; }
._compare > div > :nth-child(2):after { content: var(--right-label); color: rebeccapurple; font-size: 0.75em; position: absolute; left: calc(100% + 0.5em); }
._sum td:first-of-type { padding-right: 1em; }
._gifs { position: relative; display: flex; flex-flow: column nowrap; }
._gifs > video { transition: opacity 0.125s linear; }
._gifs > button { transition: 0.125s linear; transition-property: color, background-color; }
._gifs._paused > video { opacity: 0.5; }
._gifs._paused > button { color: rebeccapurple; background: #66339940; }
._gifs > button { position: absolute; top: 0; bottom: 0; left: 0; right: 0; width: 100%; font-size: 7em; color: transparent; background: transparent; content: "▶"; }
._gifs > button:focus-visible { outline: 0.25rem solid #663399C0; outline-offset: -0.25rem; }

._commits { position: relative; }
._commits > :first-child { position: absolute; right: -0.1em; height: 100%; border-right: 0.2em solid rgba(102,51,153,0.5); }
._commits > :last-child { position: relative; padding-right: 0.5em; }
* + ._commit, ._commit * + * { margin-top: 0; }
._commit { line-height: 2; margin-right: -1.5em; text-align: right; }
._commit > img { width: 2em; vertical-align: middle; }
._commit > a { padding-right: 0.5em; text-decoration: none; color: rebeccapurple; }
._commit > a > code { font-size: 1em; }
._commit-none > a { color: rgba(102,51,153,0.5); }
</style>

## Contents

* [What are they?](#what-are-they)
* [Can I use them?](#can-i-use-them)
* [How do I use them?](#how-do-i-use-them)
* [How do they work?](#how-do-they-work)
* [Gotchas](#gotchas)
    * [Removing decorations and shadows](#removing-decorations-and-shadows)
    * [Accessing global constants](#accessing-global-constants)
    * [Spec issues](#spec-issues)

## What are they?

CSS has four highlight pseudos and an open set of author-defined custom highlight pseudos.
They have their roots in ::selection, which was a rudimentary and non-standard, but widely supported, way of styling text and images selected by the user.

The built-in highlights are ::selection for user-selected content, ::target-text for linking to text fragments, ::spelling-error for misspelled words, and ::grammar-error for text with grammar errors, while the custom highlights are known as ::highlight(_x_) where _x_ is the author-defined highlight name.

## Can I use them?

[::selection] has long been supported by all of the major browsers, and [::target-text] shipped in Chromium 89.
But for most of that time, no browser had yet implemented the more robust highlight pseudo system in the [CSS pseudo spec].

[::selection]: https://developer.mozilla.org/en-US/docs/Web/CSS/::selection
[::target-text]: https://developer.mozilla.org/en-US/docs/Web/CSS/::target-text
[CSS pseudo spec]: https://drafts.csswg.org/css-pseudo/

::highlight() and the custom highlight API shipped in Chromium 105, thanks to the work by members[^1] of the Microsoft Edge team.
They are also available in Safari 14.1 (including iOS 14.5) as an experimental feature (Highlight API).
You can enable that feature in the Develop menu, or for iOS, under Settings > Safari > Advanced.

[^1]: Dan, Fernando, Sanket, Luis, Bo, and anyone else I missed.

<aside markdown="1">
Safari’s support currently has a couple of quirks, as of TP 152.
Range is not supported for custom highlights yet, only StaticRange, and the Highlight constructor has a bug where it requires passing exactly one range, ignoring any additional arguments.
To create a Highlight with no ranges, first create one with a dummy range, then call the `clear` or `delete` methods.
</aside>

Chromium 105 also implements the vast majority of the new highlight pseudo system.
This includes highlight overlay painting, which was enabled for all highlight pseudos, and highlight inheritance, which was enabled for ::highlight() only.

[^2]: See [this demo](https://codepen.io/dazabani13/full/KKqzOJp) for more details.

Chromium 108 includes ::spelling-error and ::grammar-error as an experimental feature, together with the new ‘text-decoration-line’ values ‘spelling-error’ and ‘grammar-error’.
Chromium 111 enables highlight inheritance for ::selection and ::target-text as an experimental feature, in addition to ::highlight() and the spelling and grammar pseudos (which always use highlight inheritance).
You can enable these features at

> chrome://flags/#enable-experimental-web-platform-features

<aside markdown="1">
Chromium’s support also currently has some bugs, as of r1041796.
Notably, highlights don’t yet work under ::first-line and ::first-letter[^2], ‘text-shadow’ is [not yet enabled](https://crbug.com/1350475) for ::highlight(), computedStyleMap [results are wrong](https://crbug.com/1099874) for ‘currentColor’, and highlights that split ligatures (e.g. for complex scripts) only render accurately in ::selection[^2].
</aside>

Click the table below to see if your browser supports these features.

<pre id="debug" hidden style="position: fixed; color: white; background: black; left: 0; top: 0; right: 0; margin: 0; white-space: pre-wrap;">act: <span id="debug_active"></span>
sel: <span id="debug_selection"></span>
cha: <span id="debug_cha"></span>
<span id="debug_count" hidden></span></pre>

<figure><div class="scroll"><div class="flex column_bag">
<table class="_table _checker" contenteditable spellcheck="false" data-phase="fresh">
    <thead><tr>
        <th></th><th>yours</th><th>Chromium</th><th>Safari</th><th>Firefox</th>
    </tr></thead>
    <!--
        Safari 14.0.3 (iOS 14.4.2): -selector (H)
        Safari 14.1.2 (macOS 11): +selector (ab)
        Safari 15.6? (iOS 15.6.1): +selector (ab)
        Safari 15.6.1 (macOS 11): +selector (ab)
        Safari TP 152 (macOS 12.5.1): +selector (ab)
            (16.0, WebKit 17615.1.2.3)
    -->
    <tr><th>Custom highlights</th>
        <td class="_live"><div class="_custom"><span>no</span><span>yes</span></div></td>
        <td>105</td><td>14.1*</td><td>?</td>
    </tr><tr><th>• ::highlight()</th>
        <td class="_live"><div class="_chps"><span>no</span><span>yes</span></div></td>
        <td>105</td><td>14.1*</td><td>?</td>
    </tr><tr><th>• CSSOM API</th>
        <td class="_live"><div class="_cha"><span>no</span><span>yes</span></div></td>
        <td>105</td><td>14.1* (ab)</td><td>?</td>
    </tr><tr><th>::spelling-error</th>
        <td class="_live"><div spellcheck="true" lang="en"><span>no</span><span>yes</span></div></td>
        <td>108*</td><td>?</td><td>?</td>
    </tr><tr><th>Highlight overlay painting</th>
        <td class="_live"><div class="_hop"><span>no</span><span>yes</span></div></td>
        <td>105</td><td>?</td><td>?</td>
    </tr><tr><th>Highlight inheritance (::selection)</th>
        <td class="_live"><div class="_his"><span>no</span><span>yes</span></div></td>
        <td>111*</td><td>?</td><td>?</td>
    </tr><tr><th>Highlight inheritance (::highlight)</th>
        <td class="_live"><div class="_hih"><span>no</span><span>yes</span></div></td>
        <td>105</td><td>?</td><td>?</td>
    </tr>
</table>
<div class="gap"></div>
<aside markdown="1">
* \* = experimental (can be enabled in UI)
* S = ::highlight() unsupported in querySelector
* C = CSS.highlights missing or setlike ([older API from 2020](https://www.w3.org/TR/2020/WD-css-highlight-api-1-20201208/))
* H = new Highlight() missing
* a = StaticRange only (no support for Range)
* b = new Highlight() requires exactly one range argument
</aside>
</div></div></figure>

<script>
    let checkerTimer = null;

    // selectionchange events can get stuck in infinite loops if they get
    // normalised in a way that fixCheckerSelectionIfNeeded doesn’t expect
    const selectionchangeTimes = [...Array(10)].map(_ => null);

    const checker = document.querySelector("._checker");
    const counts = new Map;

    function debug_active() {
        if (document.querySelector("#debug").hidden)
            return;
        const debug = document.querySelector("#debug_active");
        debug.textContent = document.activeElement;
    }

    function debug_selection() {
        if (document.querySelector("#debug").hidden)
            return;
        const debug = document.querySelector("#debug_selection");
        const sel = getSelection();
        debug.textContent =
            `${sel.anchorOffset} ${format(sel.anchorNode)}`
            + `\n     `
            + `${sel.focusOffset} ${format(sel.focusNode)}`;
        function format(node) {
            if (node == null || node.nodeValue == null)
                return "";
            if (node.nodeValue.length < 30)
                return `${node.nodeName} "${node.nodeValue}"`;
            return ` "${node.nodeName} ${node.nodeValue.slice(0,27)}"...`;
        }
    }

    function debug_count(eventType) {
        if (document.querySelector("#debug").hidden)
            return;
        console.log(eventType);
        counts.set(eventType, (counts.get(eventType) ?? 0) + 1);
        const debug = document.querySelector("#debug_count");
        debug.textContent = "";
        for (const [i, n] of counts)
            debug.textContent += (debug.textContent ? "    " : "cou:")
                + ` • ${n} x ${i}\n`;
    }

    function debug_cha(message) {
        if (document.querySelector("#debug").hidden)
            return;
        const debug = document.querySelector("#debug_cha");
        debug.textContent = message;
    }

    checker.addEventListener("focus", ({target}) => {
        debug_count("focus");
        if (target.dataset.phase == "fresh") {
            target.dataset.phase = "spell";
            checkerTimer = setTimeout(finish, 250);
            const range = new Range;
            range.selectNodeContents(target.querySelector("[spellcheck]"));
            getSelection().removeAllRanges();
            getSelection().addRange(range);
            if (this.internals)
                internals.setMarker(document, range, "spelling");
        } else if (target.dataset.phase == "spell") {
            clearTimeout(checkerTimer);
            checkerTimer = setTimeout(finish, 250);
        } else {
            finish();
        }

        function finish() {
            target.dataset.phase = "done";
            checkerTimer = null;

            const selector = (() => {
                try {
                    return !document.querySelector(":not(*)::highlight(checker)");
                } catch (e) {}
                return false;
            })();
            const collection = !!(this.CSS && CSS.highlights && CSS.highlights.set);
            const ctor = !!this.Highlight;
            const staticRangesOnly = ctor ? (() => {
                try {
                    const range = new Range;
                    range.selectNodeContents(document.body);
                    return !new Highlight(range);
                } catch (e) {}
                try {
                    const range = new StaticRange({
                        startOffset: 0, endOffset: 0,
                        startContainer: document.body,
                        endContainer: document.body,
                    });
                    return !!new Highlight(range);
                } catch (e) {}
                return null;
            })() : null;
            const ctorTakesExactlyOneRange = ctor ? (() => {
                try {
                    const foo = new StaticRange({
                        startOffset: 0, endOffset: 0,
                        startContainer: document.body,
                        endContainer: document.body,
                    });
                    const bar = new StaticRange({
                        startOffset: 1, endOffset: 1,
                        startContainer: document.body,
                        endContainer: document.body,
                    });
                    switch (new Highlight(foo, bar).size) {
                        case 1: return true;
                        case 2: return false;
                    }
                } catch (e) {}
                return null;
            })() : null;

            checker.querySelector("._cha").textContent = (() => {
                if (selector && collection && ctor && !staticRangesOnly && !ctorTakesExactlyOneRange)
                    return "yes";
                if (!selector || !collection || !ctor) {
                    let result = "no (";
                    result += !selector ? "S" : "";
                    result += !collection ? "C" : "";
                    result += !ctor ? "H" : "";
                    return result + ")";
                }
                if (staticRangesOnly || ctorTakesExactlyOneRange) {
                    let result = "buggy (";
                    result += staticRangesOnly ? "a" : "";
                    result += ctorTakesExactlyOneRange ? "b" : "";
                    return result + ")";
                }
            })();

            try {
                if (this.CSS && CSS.highlights) {
                    const hop = new StaticRange({
                        startOffset: 0, endOffset: 2,
                        startContainer: checker.querySelector("._hop"),
                        endContainer: checker.querySelector("._hop"),
                    });
                    const custom = new StaticRange({
                        startOffset: 0, endOffset: 2,
                        startContainer: checker.querySelector("._custom"),
                        endContainer: checker.querySelector("._custom"),
                    });
                    const hih = new StaticRange({
                        startOffset: 0, endOffset: 2,
                        startContainer: checker.querySelector("._hih"),
                        endContainer: checker.querySelector("._hih"),
                    });

                    CSS.highlights.set("lower", new Highlight(hop));

                    // work around Safari bug where ctor takes exactly one range
                    // (beware that having hop highlighted by lower but not by
                    // checker causes false “yes”, because Safari does not seem
                    // to support ‘-webkit-text-fill-color’ in highlights)
                    const h = new Highlight(hop, custom, hih);
                    CSS.highlights.set("checker", h);
                    if (CSS.highlights.get("checker").size == 1) {
                        h.add(custom);
                        h.add(hih);
                    }
                }
            } catch (e) {
                debug_cha("ex: " + e + "\n" + e.stack + "\n" + this.Highlight);
            }
            fixCheckerSelectionIfNeeded();
        }
    });

    checker.addEventListener("blur", ({target}) => {
        if (target.dataset.phase == "done")
            getSelection().removeAllRanges();
    });

    checker.addEventListener("click", ({target}) => {
        if (target.dataset.phase != "done")
            return;
        debug_count("click");
        fixCheckerSelectionIfNeeded();
    });

    checker.addEventListener("beforeinput", event => {
        event.preventDefault();
    });

    document.addEventListener("selectionchange", event => {
        const now = performance.now();
        const front = selectionchangeTimes.shift();
        selectionchangeTimes.push(now);
        if (now - front < 1000)
            return;
        debug_count("selectionchange");
        if (checker.dataset.phase != "done")
            return;
        debug_active();
        if (document.activeElement != checker)
            return;
        fixCheckerSelectionIfNeeded();
    });

    function fixCheckerSelectionIfNeeded() {
        debug_count("fix");
        const row = checker.querySelector("._his");
        const sel = getSelection();
        let anchorOk = false, focusOk = false;
        for (let node = row; node != null; node = node.firstChild)
            if (sel.anchorNode == node && sel.anchorOffset == 0)
                anchorOk = true;
        for (let node = row; node != null; node = node.lastChild)
            if (sel.focusNode == node && sel.focusOffset == (
                    node.nodeType == 3 ? node.nodeValue.length : node.childNodes.length))
                focusOk = true;
        if (anchorOk && focusOk)
            return;
        debug_selection();
        const his = new Range;
        his.selectNodeContents(row);
        getSelection().removeAllRanges();
        getSelection().addRange(his);
    }
</script>

## How do I use them?

While you can write rules for highlight pseudos that target all elements, as was commonly done for pre-standard ::selection, selecting specific elements can be more powerful, allowing descendants to cleanly override highlight styles.

<figure markdown="1"><div markdown="1" class="scroll"><div markdown="1" class="flex column_bag">
<div class="_example" style="width: max-content; font-size: 2em; color: white;">
    <span style="color: white; background: black;">the fox jumps over the dog</span>
    <div>
        <span style="color: white; background: darkred;">(the </span
        ><sup style="color: white; background: darkred;">quick</sup
        ><span style="color: white; background: darkred;"> fox, mind you)</span>
    </div>
</div>
<div class="gap"></div>
```html
<style>
    :root::selection {
        color: white;
        background-color: black;
    }
    aside::selection {
        background-color: darkred;
    }
</style>
<body>
    <p>the fox jumps over the dog
    <aside>
        (the <sup>quick</sup> fox, mind you)
    </aside>
</body>
```
</div></div></figure>

Previously the same code would yield…

<figure markdown="1"><div markdown="1" class="scroll">
<div class="_example" style="width: max-content; font-size: 2em; color: white;">
    <span style="color: white; background: var(--cr-highlight);">the fox jumps over the dog</span>
    <div>
        <span style="color: white; background: darkred;">(the </span
        ><sup style="color: white; background: var(--cr-highlight);">quick</sup
        ><span style="color: white; background: darkred;"> fox, mind you)</span>
    </div>
</div>
</div><figcaption markdown="1">
(in older browsers)

Notice how *none* of the text is white on black, because there are always other elements (body, p, aside, sup) between the root and the text.
</figcaption></figure>

…unless you also selected the descendants of :root and aside:

<figure markdown="1"><div markdown="1" class="scroll">
```css
:root::selection,
:root *::selection
/* (or just ::selection) */ {
    color: white;
    background-color: black;
}
aside::selection,
aside *::selection {
    background-color: green;
}
```
</div></figure>

Note that a bare ::selection rule still means *::selection, and like any universal rule, it can interfere with inheritance when mixed with non-universal highlight rules.

<figure markdown="1"><div markdown="1" class="scroll"><div markdown="1" class="flex column_bag">
<div class="_example" style="width: max-content; font-size: 2em; color: white;">
    <span style="color: white; background: black;">the fox jumps over the dog</span>
    <div>
        <span style="color: white; background: darkred;">(the </span
        ><sup style="color: white; background: black;">quick</sup
        ><span style="color: white; background: darkred;"> fox, mind you)</span>
    </div>
</div>
<div class="gap"></div>
```html
<style>
    ::selection {
        color: white;
        background-color: black;
    }
    aside::selection {
        background-color: darkred;
    }
</style>
<body>
    <p>the fox jumps over the dog
    <aside>
        (the <sup>quick</sup> fox, mind you)
    </aside>
</body>
```
</div></div><figcaption markdown="1">
sup::selection *would have* inherited ‘darkred’ from aside::selection, but the universal ::selection rule matches it directly, so it becomes black.
</figcaption></figure>

::selection is primarily controlled by user input, though pages can both read and write the active ranges via the [Selection] API with [getSelection()].

::target-text is activated by navigating to a URL ending in a [fragment directive], which has its own syntax embedded in the #fragment. For example:

* `#foo:~:text=bar` targets #foo and highlights the first occurrence of “bar”
* `#:~:text=the,dog` highlights the first range of text from “the” to “dog”

::spelling-error and ::grammar-error are controlled by the user’s spell checker, which is only used where the user can input text, such as with `textarea` or `contenteditable`,
subject to the [`spellcheck`] attribute (which also affects grammar checking).
For privacy reasons, pages can’t read the active ranges of these highlights, despite being visible to the user.

::highlight() is controlled via the [Highlight] API with [CSS.highlights].
CSS.highlights is a *maplike* object, which means the interface is the same as a [Map] of strings (highlight names) to Highlight objects.
Highlight objects, in turn, are *setlike* objects, which you can use like a [Set] of [Range] or [StaticRange] objects.

[getComputedStyle()]: https://developer.mozilla.org/en-US/docs/Web/API/Window/getComputedStyle
[Selection]: https://developer.mozilla.org/en-US/docs/Web/API/Selection
[getSelection()]: https://developer.mozilla.org/en-US/docs/Web/API/Window/getSelection
[fragment directive]: https://wicg.github.io/scroll-to-text-fragment/#the-fragment-directive
[`spellcheck`]: https://html.spec.whatwg.org/multipage/interaction.html#attr-spellcheck
[Highlight]: https://drafts.csswg.org/css-highlight-api-1/#highlight
[CSS.highlights]: https://drafts.csswg.org/css-highlight-api-1/#intro-ex
[Map]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map
[Set]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set
[Range]: https://developer.mozilla.org/en-US/docs/Web/API/Range
[StaticRange]: https://developer.mozilla.org/en-US/docs/Web/API/StaticRange

<figure><div class="scroll" markdown="1"><div class="flex column_bag" markdown="1">
<div class="_example" style="width: max-content; font-size: 3em;">
    <span style="background: yellow;">Hello</span>, world!
</div>
```html
<style>
    ::highlight(foo) { background: yellow; }
</style>
<script>
    const foo = new Highlight;
    CSS.highlights.set("foo", foo); // maplike

    const range = new Range;
    range.setStart(document.body.firstChild, 0);
    range.setEnd(document.body.firstChild, 5);
    foo.add(range); // setlike
</script>
<body>Hello, world!</body>
```
</div></div></figure>

You can use [getComputedStyle()] to query resolved highlight styles under a particular element.
Regardless of which parts (if any) are highlighted, the styles returned are as if the given highlight is active and all other highlights are inactive.

<figure><div class="scroll" markdown="1">
```html
<style>
    ::selection { background: #00FF00; }
    ::highlight(foo) { background: #FF00FF; }
</style>
<script>
    getSelection().removeAllRanges();
    getSelection().selectAllChildren(document.body);

    const style = getComputedStyle(document.body, "::highlight(foo)");
    console.log(style.backgroundColor);
</script>
<body>Hello, world!</body>
```
</div><figcaption markdown="1">
This code always prints “rgb(255, 0, 255)”, even though only ::selection is active.
</figcaption></figure>

## How do they work?

Highlight pseudos are defined as pseudo-elements, but they actually have very little in common with other pseudo-elements like ::before and ::first-line.

Unlike other pseudos, they generate _highlight overlays_, not boxes, and these overlays are like layers over the original content.
Where text is highlighted, a highlight overlay can add backgrounds and text shadows, while the text proper and any other decorations are “lifted” to the very top.

<style>@import url(/images/hpdemo.css);</style>
<script src="/images/hpdemo.js"></script>
<figure><div class="_demo _hpdemo" data-_demo="_hpdemo" style="--w: var(--inner-width); user-select: none; cursor: pointer;">
    <script type="text/x-choreography">
        q   q   q   q   q   q
        0   1   2   2   3   3
    </script>
    <div><main style="--n: 7;">
        <div class="q" style="outline: 3px dotted #00000070; background: #70700038;">
            <span>quikc brown<span style="color: initial;"> fox</span></span>
            <label>originating element</label>
        </div>
        <div class="q" style="outline: 3px dotted #00000070; background: #A8000038;">
            <span><span style="color: initial; text-decoration: underline; text-decoration-style: wavy; text-decoration-color: red;">qui</span>kc brown fox</span>
            <label>::spelling-error</label>
        </div>
        <div class="q" style="outline: 3px dotted #00000070; background: #66339938;">
            <span>quikc <span style="background: #D070D0C0;">br<span>own</span></span> fox</span>
            <label>::target-text</label>
        </div>
        <div class="q">
            <span>quikc <span>br<span style="color: initial;">own</span></span> fox</span>
        </div>
        <div class="q" style="outline: 3px dotted #00000070; background: #3838C038;">
            <span>qui<span style="background: #3838C0C0;"><span>kc</span> br</span>own fox</span>
            <label>::selection</label>
        </div>
        <div class="q">
            <span>qui<span style="color: initial;"><span style="text-decoration: underline; text-decoration-style: wavy; text-decoration-color: red;">kc</span> br</span>own fox</span>
        </div>
    </main></div>
</div></figure>
<script>
    const hpdemo = {
        update() {
            const t = this.tFunction();
            if (t == this.t) return;
            this.t = t;
            this.state = _hpdemo(this.state, this.root, this.t);
        },
        tFunction() {
            if (hpdemo.clicked) return 1 - hpdemo.t;
            const rect = this.root.getBoundingClientRect();
            const y = rect.top + (rect.bottom - rect.top) / 2;
            return Number(y < innerHeight / 2);
        },
        state: {},
        root: document.querySelector("._hpdemo"),
        t: null,
        clicked: false,
    };
    hpdemo.update();
    addEventListener("scroll", () => {
        if (hpdemo.clicked) return;
        hpdemo.update();
    });
    hpdemo.root.addEventListener("click", () => {
        hpdemo.clicked = true;
        hpdemo.update();
    });
</script>

You can think of highlight pseudos as _innermost_ pseudo-elements that always exist at the bottom of any tree of elements and other pseudos, but unlike other pseudos, they don’t inherit their styles from that element tree.

Instead each highlight pseudo forms its own inheritance tree, parallel to the element tree.
This means body::selection inherits from html::selection, not from ‘body’ itself.

<hr>

At this point, you can probably see that the highlight pseudos are quite different from the rest of CSS, but there are also several special cases and rules needed to make them a coherent system.

For the typical appearance of <span class="_spelling">spelling</span> and <span class="_grammar">grammar</span> errors, highlight pseudos need to be able to add their own decorations, and they need to be able to leave the underlying foreground color unchanged.
Highlight inheritance happens separately from the element tree, so we need some way to refer to the underlying foreground color.

That escape hatch is to set ‘color’ itself to ‘currentColor’, which is the default if nothing in the highlight tree sets ‘color’.

<figure><div class="scroll" markdown="1"><div class="flex column_bag" markdown="1">
<div class="_example" style="width: max-content; font-size: 3em;">
    quick → <span class="_spelling">quikc</span>
    <br>
    <span style="color: rebeccapurple;">quick → <span class="_spelling">quikc</span></span>
</div>
<div class="gap"></div>
```css
:root::spelling-error {
    /* color: currentColor; */
    text-decoration: red wavy underline;
}
```
</div></div></figure>

<aside markdown="1">
This is a bit of a special case within a special case.

You see, ‘currentColor’ is usually defined as “the computed value of ‘color’”, but the way I like to think of it is “don’t change the foreground color”, and most color-valued properties like ‘text-decoration-color’ default to this value.

For ‘color’ itself that wouldn’t make sense, so we instead define ‘color:currentColor’ as equivalent to ‘color:inherit’, which still fits that mental model.
But for highlights, that definition would no longer fit, so we redefine it as being the ‘color’ of the next active highlight below.
</aside>

To make highlight inheritance actually useful for <span class="_spelling">‘text-decoration’</span> and <span style="background: yellow;">‘background-color’</span>, _all properties are inherited_ in highlight styles, even those that are not usually inherited.

<figure><div class="scroll" markdown="1"><div class="flex row_bag" markdown="1">
<div class="_example" style="width: max-content; font-size: 3em;">
    <sup style="background-color: yellow;">quick</sup><span style="background-color: yellow;"> fox</span>
</div>
<div class="gap"></div>
```html
<style>
    aside::selection {
        background-color: yellow;
    }
</style>
<aside>
    <sup>quick</sup> fox
</aside>
```
</div></div></figure>

<a name="applicable-properties"></a>Only a [handful of properties](https://drafts.csswg.org/css-pseudo/#highlight-styling) are settable in highlight styles, for performance and privacy reasons.
In general, properties that you can’t set in highlight styles come from the _originating element_, which is to say from the non-highlight styles.

<figure><div class="scroll" markdown="1"><div class="flex row_bag" markdown="1">
<div class="_example" style="width: max-content; font-size: 3em; padding-right: 0.5em;">
    <span style="text-shadow: 0.25em 0.25lh lightblue;">A</span><big style="font-size: 2em; line-height: 1.5; text-shadow: 0.25em 0.25lh lightblue;"> A</big>
</div>
<div class="gap"></div>
```html
<style>
    :root::selection {
        text-shadow: 0.25em 0.25lh lightblue;
        background-color: transparent;
    }
    big {
        font-size: 2em;
        line-height: 1;
    }
</style>
<aside>
    <sup>quick</sup> fox
</aside>
```
</div></div><figcaption markdown="1">
When selected, the &lt;big> is still 2em/1, and the selection shadow takes that into account, even though you are not allowed to set ‘font-size’ or ‘line-height’ in :root::selection.
</figcaption></figure>

This would conflict with the usual rules[^3] for decorating boxes, because descendants would get two decorations, one propagated and one inherited.
We resolved this by making decorations added by highlights not propagate to any descendants.

[^3]: [CSSWG discussion](https://github.com/w3c/csswg-drafts/issues/6829#issuecomment-1098255113) also found that decorating box semantics are undesirable for decorations added by highlights anyway.

<figure><div class="scroll" markdown="1"><div class="flex row_bag" markdown="1">
<div class="_example" style="width: max-content; font-size: 3em;">
    <div style="position: relative; color: transparent;">
        <div style="position: absolute; bottom: 0; text-decoration: underline; text-decoration-color: blue; text-decoration-thickness: 0.25rem; text-decoration-skip: none; text-decoration-skip-ink: none;">
            <span style="font-size: 0.75em;">quick</span> fox
        </div>
        <div style="position: absolute; bottom: 0; color: CanvasText;">
            <sup>quick</sup> fox
        </div>
        <!-- sizer -->
        <sup>quick</sup> fox
    </div>
    <div>
        <sup class="_spelling">quikc</sup> <span class="_spelling">fxo</span>
    </div>
</div>
<div class="gap"></div>
```html
<style>
    .blue {
        text-decoration: blue underline;
    }
    :root::spelling-error {
        text-decoration: red wavy underline;
    }
</style>
<div class="blue">
    <sup>quick</sup> fox
</div>
<div contenteditable spellcheck lang="en">
    <sup>quikc</sup> fxo
</div>
```
</div></div><figcaption markdown="1">
The blue decoration *propagates* to the sup element from the decorating box, so there should be a single line at the normal baseline.
On the other hand, the spelling decoration is *inherited* by sup::spelling-error, so there should be separate lines for “quikc” and “fxo” at their respective baselines.
</figcaption></figure>

Unstyled highlight pseudos generally don’t change the appearance of the original content, so the default ‘color’ and ‘background-color’ in highlights are ‘currentColor’ and ‘transparent’ respectively, the latter being the property’s initial value.
But two highlight pseudos, ::selection and ::target-text, have UA default foreground and background colors.

For compatibility with ::selection in older browsers, the UA default ‘color’ and ‘background-color’ (e.g. white on blue) is only used if _neither_ were set by the author.
This rule is known as _paired cascade_, and for consistency it also applies to ::target-text.

<figure><div class="scroll"><div class="flex"><table class="_sum">
<tr><td></td><td><span style="color: white; background: var(--cr-highlight);">default on default</span><span style="color: rebeccapurple;"> plus more text</span></td></tr>
<tr><td>+</td><td markdown="1">
```css
p { color: rebeccapurple; }
::selection { background: yellow; }
```
</td></tr>
<tr><td>=</td><td><span style="color: rebeccapurple; background: yellow;">currentColor on yellow</span><span style="color: rebeccapurple;"> plus more text</span></td></tr>
</table></div></div></figure>

It’s common for selected text to almost invert the original text colors, turning <span style="color: black; background: white;">black on white</span> into <span style="color: white; background: var(--cr-highlight);">white on blue</span>, for example.
To guarantee that the original decorations remain as legible as the text when highlighted, which is especially important for decorations with semantic meaning (e.g. <span style="text-decoration: line-through;">line-through</span>), originating decorations are recolored to the highlight ‘color’.
This doesn’t apply to decorations added by highlights though, because that would break the typical appearance of <span class="_spelling">spelling</span> and <span class="_grammar">grammar</span> errors.

<figure><div class="scroll" markdown="1"><div class="flex column_bag" markdown="1">
<div class="_example" style="width: max-content; font-size: 3em;">
    <div>
        do
        <span style="text-decoration: line-through; text-decoration-color: darkred;">not</span>
        buy bread
    </div><div><span style="color: white; background: darkblue;">
        do
        <span style="text-decoration: line-through;">not</span>
        buy bread
    </span></div>
</div>
<div class="gap"></div>
```html
<style>
    del {
        text-decoration: darkred line-through;
    }
    ::selection {
        color: white;
        background: darkblue;
    }
</style>
<div>
    do <del>not</del> buy bread
</div>
```
</div></div><figcaption markdown="1">
This line-through decoration becomes white like the rest of the text when selected, even though it was explicitly set to ‘darkred’ in the original content.
</figcaption></figure>

The default style rules for highlight pseudos might look something like this.
Notice the new ‘spelling-error’ and ‘grammar-error’ decorations, which authors can use to imitate native spelling and grammar errors.

<figure><div class="scroll" markdown="1">
```css
:root::selection { background-color: Highlight; color: HighlightText; }
:root::target-text { background-color: Mark; color: MarkText; }
:root::spelling-error { text-decoration: spelling-error; }
:root::grammar-error { text-decoration: grammar-error; }
```
</div><figcaption markdown="1">
This doesn’t completely describe ::selection and ::target-text, due to paired cascade.
</figcaption></figure>

<hr>

The way the highlight pseudos have been designed naturally leads to some limitations.

## Gotchas

### Removing decorations and shadows

Older browsers with ::selection tend to treat it purely as a way to *change* the original content’s styles, including text shadows and other decorations.
[Some tutorial content] has even been written to that effect:

[Some tutorial content]: https://css-tricks.com/almanac/selectors/s/selection/

> One of the most helpful uses for `::selection` is turning off a `text-shadow` during selection.
> A `text-shadow` can clash with the selection’s background color and make the text difficult to read.
> Set `text-shadow: none;` to make text clear and easy to read during selection.

Under the spec, highlight pseudos can no longer remove or really change the original content’s decorations and shadows.
Setting these properties in highlight pseudos to values other than ‘none’ *adds* decorations and shadows to the overlays when they are active.

<figure><div class="scroll" markdown="1">
```css
del {
    text-decoration: line-through;
    text-shadow: 2px 2px red;
}
::highlight(undelete) {
    text-decoration: none;
    text-shadow: none;
}
```
</div><figcaption markdown="1">
This code means that ::highlight(undelete) adds no decorations or shadows, not that it removes the line-through and red shadow when `del` is highlighted.
</figcaption></figure>

While the new :has() selector might appear to offer a solution to this problem, pseudo-element selectors are not allowed in :has(), at least not yet.

<figure><div class="scroll" markdown="1">
```css
del:has(::highlight(undelete)) {
    text-decoration: none;
    text-shadow: none;
}
```
</div><figcaption markdown="1">
This code does not work.
</figcaption></figure>

Removing shadows that might clash with highlight backgrounds (as suggested in the tutorial above) will no longer be as necessary anyway, since highlight backgrounds now paint *on top of* the original text shadows.

<figure><div class="scroll" markdown="1"><div class="flex row_bag" markdown="1">
<div class="_example" style="width: max-content; font-size: 2em; font-weight: bold; padding-right: 0.25em;">
    <div style="position: relative; color: transparent;">
        <div style="position: absolute; bottom: 0; text-shadow: 0.25em 0.25em magenta;">
            <span style="color: white; background: var(--cr-highlight);">Faultlore</span>
        </div>
        <!-- sizer -->
        Faultlore
    </div>
    <div style="position: relative; color: transparent;">
        <div style="position: absolute; bottom: 0; text-shadow: 0.25em 0.25em magenta;">
            <span style="color: white; background: var(--cr-highlight-aC0h);">Faultlore</span>
        </div>
        <!-- sizer -->
        Faultlore
    </div>
</div>
<div class="gap"></div>
<a href="https://gankra.github.io">→</a>
<div class="gap"></div>
<div class="_example" style="width: max-content; font-size: 2em; font-weight: bold; padding-right: 0.25em;">
    <div style="position: relative; color: transparent;">
        <div style="position: absolute; bottom: 0; text-shadow: 0.25em 0.25em magenta;">
            Faultlore
        </div>
        <div style="position: absolute; bottom: 0;">
            <span style="color: white; background: var(--cr-highlight);">Faultlore</span>
        </div>
        <!-- sizer -->
        Faultlore
    </div>
    <div style="position: relative; color: transparent;">
        <div style="position: absolute; bottom: 0; text-shadow: 0.25em 0.25em magenta;">
            Faultlore
        </div>
        <div style="position: absolute; bottom: 0;">
            <span style="color: white; background: var(--cr-highlight-aC0h);">Faultlore</span>
        </div>
        <!-- sizer -->
        Faultlore
    </div>
</div>
</div></div></figure>

If you still want to ensure those shadows don’t clash with highlights in older browsers, you can set ‘text-shadow’ to ‘none’, which is harmless in newer browsers.

<figure><div class="scroll" markdown="1">
```css
::selection { text-shadow: none; }
```
</div><figcaption markdown="1">
This rule might be helpful for older browsers, but note that like any universal rule, it can interfere with inheritance of ‘text-shadow’ when combined with more specific rules.
</figcaption></figure>

As for line decorations, if you’re really determined, you can work around this limitation by using ‘-webkit-text-fill-color’, [a standard property] (believe it or not) that controls the foreground fill color of text[^4].

[a standard property]: https://compat.spec.whatwg.org/#the-webkit-text-fill-color
[^4]: This is actually the case everywhere the WHATWG compat spec applies, at all times. If you think about it, the only reason why setting ‘color’ to ‘red’ makes your text red is because ‘-webkit-text-fill-color’ defaults to ‘currentColor’.

<figure><div class="scroll" markdown="1">
```css
::highlight(undelete) {
    color: transparent;
    -webkit-text-fill-color: CanvasText;
}
```
</div><figcaption markdown="1">
This hack hides any original decorations (in visual media), because those decorations are recolored to the highlight ‘color’, but it might change the text color too.
</figcaption></figure>

Fun fact: because of ‘-webkit-text-fill-color’ and [its stroke-related siblings], it isn’t always possible for highlight pseudos to avoid changing the foreground colors of text, at least not without out-of-band knowledge of what those colors are.

[its stroke-related siblings]: https://compat.spec.whatwg.org/#the-webkit-text-stroke

<figure><div class="scroll" markdown="1"><div class="flex column_bag" markdown="1">
<div class="flex column_bag">
    <div class="_example" style="width: max-content; font-size: 3em; color: blue;">
        the
        <em style="-webkit-text-fill-color: yellow; -webkit-text-stroke: 1px green;">
            quick
            fox
        </em>
    </div>
    <div class="gap"></div>
    ↓
    <div class="gap"></div>
    <div class="_example" style="width: max-content; font-size: 3em; color: blue;">
        the
        <em style="-webkit-text-fill-color: yellow; -webkit-text-stroke: 1px green;">
            <span class="_spelling" style="-webkit-text-fill-color: currentColor; -webkit-text-stroke: 0 currentColor;">quikc</span>
            fox
        </em>
    </div>
</div>
<div class="gap"></div>
```css
p { color: blue; }
em {
    -webkit-text-fill-color: yellow;
    -webkit-text-stroke: 1px green;
}
:root::spelling-error {
    /* default styles */
    color: currentColor;
    -webkit-text-fill-color: currentColor;
    -webkit-text-stroke-color: 0 currentColor;
    text-decoration: spelling-error;
}
em::spelling-error {
    /* styles needed to preserve text colors */
    -webkit-text-fill-color: yellow;
    -webkit-text-stroke: 1px green;
}
```
</div></div><figcaption markdown="1">
When a word in `em` is misspelled, it will become blue like the rest of `p`, unless the fill and stroke properties are set in ::spelling-error accordingly.
</figcaption></figure>

### Accessing global constants

<details markdown="1"><summary><strong>Update (2024-04-29):</strong> this section is no longer true (see <a href="#custom-properties">§ <em>Custom properties</em></a>), but you can click here to read what I wrote originally.</summary>

<del>Highlight pseudos also don’t automatically have access to custom properties set in the element tree, which can make things tricky if you have a design system that exposes a color palette via custom properties on :root.</del>

<figure><div class="scroll" markdown="1">
```css
:root {
    --primary: #420420;
    --secondary: #C0FFEE;
    --accent: #663399;
}
::selection {
    background: var(--accent);
    color: var(--secondary);
}
```
</div><figcaption markdown="1">
This code does not work.
</figcaption></figure>

<del>You can work around this by adding selectors for the necessary highlight pseudos to the rule defining the constants, or if the necessary highlight pseudos are unknown, by rewriting each constant as a custom @property rule.</del>

<figure markdown="1"><div markdown="1" class="scroll"><div markdown="1" class="flex">
```css
:root, :root::selection {
    --primary: #420420;
    --secondary: #C0FFEE;
    --accent: #663399;
}
```
<div class="gap"></div>
```css
@property --primary {
    initial-value: #420420;
    syntax: "*"; inherits: false;
}
@property --secondary {
    initial-value: #C0FFEE;
    syntax: "*"; inherits: false;
}
@property --accent {
    initial-value: #663399;
    syntax: "*"; inherits: false;
}
```
</div></div></figure>
</details>

### Custom properties

You can _use_ custom properties in highlight styles, but you will not be able to set or override them there.
Custom property values come from the nearest originating element.

This is unfortunate, but allowing you to set custom properties in highlight styles broke a lot of existing content on the web (and existing advice on Stack Overflow).
For more details, see these posts by my colleague Stephen Chenney:

- [The CSS Highlight Inheritance Model](https://blogs.igalia.com/schenney/the-css-highlight-inheritance-model/) (January 2024)
- [CSS Custom Properties in Highlight Pseudos](https://blogs.igalia.com/schenney/css-custom-properties-in-highlight-pseudos/) (April 2024)
- (and the CSSWG issues, [#6641](https://github.com/w3c/csswg-drafts/issues/6641) and [#9909](https://github.com/w3c/csswg-drafts/issues/9909))

<figure markdown="1"><div markdown="1" class="scroll"><div markdown="1" class="flex column_bag">
<div class="_example" style="width: max-content; font-size: 2em; color: black;">
    <span style="color: black; background: lightgreen;">the fox jumps over the dog</span>
    <div>
        <span style="color: black; background: yellow;">(the </span
        ><sup style="color: black; background: yellow;">quick</sup
        ><span style="color: black; background: yellow;"> fox, mind you)</span>
    </div>
</div>
<div class="gap"></div>
```html
<style>
    ::selection /* = *::selection (universal) */ {
        /* using --selection-color in ::selection is ok... */
        background-color: var(--selection-color); /* 🙆‍♀️ */

        /* ...but you will no longer be allowed to set it! */
        --selection-color: red; /* 🙅‍♀️ */
    }
    body {
        --selection-color: lightgreen;
    }
    aside {
        --selection-color: yellow;
    }
</style>
<body>
    <p>the fox jumps over the dog
    <aside>
        (the <sup>quick</sup> fox, mind you)
    </aside>
</body>
```
</div></div></figure>

### Spec issues

While the design of the highlight pseudos has mostly settled, there are still some unresolved issues to watch out for.

* how to use spelling and grammar decorations with the UA default colors ([#7522](https://github.com/w3c/csswg-drafts/issues/7522))
* values of non-applicable properties, e.g. ‘text-shadow’ with em units ([#7591](https://github.com/w3c/csswg-drafts/issues/7591))
* the meaning of underline- and emphasis-related properties in highlights ([#7101](https://github.com/w3c/csswg-drafts/issues/7101))
* whether ‘-webkit-text-fill-color’ and friends are allowed in highlights ([#7580](https://github.com/w3c/csswg-drafts/issues/7580))
* some browsers “tweak” the colors or alphas set in highlight styles ([#6853](https://github.com/w3c/csswg-drafts/issues/6853))
* how the highlight pseudos are supposed to interact with SVG ([svgwg#894](https://github.com/w3c/svgwg/issues/894))

## What now?

The highlight pseudos are a radical departure from older browsers with ::selection, and have some significant differences with CSS as we know it.
Now that we have some experimental support, we want *your* help to play around with these features and help us make them as useful and ergonomic as possible before they’re set in stone.

Special thanks to [Rego](https://twitter.com/regocas), [Brian](https://twitter.com/briankardell), [Eric](https://twitter.com/meyerweb) (Igalia), [Florian](https://twitter.com/frivoal), [fantasai](https://twitter.com/fantasai) (CSSWG), [Emilio](https://twitter.com/ecbos_) (Mozilla), and [Dan](https://twitter.com/dandclark1) for their work in shaping the highlight pseudos (and this post).
We would also like to thank [Bloomberg](https://www.bloomberg.com/company/) for sponsoring this work.

<hr>

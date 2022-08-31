---
layout: default
title: "Meet the CSS highlight pseudos"
date: 2022-08-26 22:00:00 +0800
tags: home igalia
# _preview_description: "..."
# _preview_image: ...
_footer_twitter: https://twitter.com/dazabani
---

A year and a half ago, I was asked to help upstream a Chromium patch allowing authors to recolor <span class="_spelling">spelling</span> and <span class="_grammar">grammar</span> errors in CSS.
At the time, I didn’t realise that this was part of a far more ambitious effort to reimagine spelling errors, grammar errors, text selections, and more as a coherent system that didn’t yet exist as such in any browser.
That system is known as the _highlight pseudos_, and this post will focus on the design of said system and its consequences.

This is the third part of a series ([part one], [part two]) about Igalia’s work towards making the CSS highlight pseudos a reality.

[part one]: {% post_url 2021-05-17-spelling-grammar %}
[part two]: {% post_url 2021-12-16-spelling-grammar-2 %}

<style>
article figure > img { max-width: 100%; }
article figure > figcaption { max-width: 30rem; margin-left: auto; margin-right: auto; }
article pre, article code { font-family: Inconsolata, monospace, monospace; }
article blockquote { max-width: 27rem; margin-inline: auto; }
article blockquote > footer { text-align: right; }
._spelling, ._grammar { text-decoration-thickness: /* iOS takes 0 literally */ 1px; text-decoration-skip-ink: none; }
._spelling { text-decoration: /* not a shorthand on iOS */ underline; text-decoration-style: wavy; text-decoration-color: red; }
._grammar { text-decoration: /* not a shorthand on iOS */ underline; text-decoration-style: wavy; text-decoration-color: green; }

._checker { position: relative; margin-left: auto; margin-right: auto; }
._checker:focus { outline: none; }
._checker::before { display: flex; align-items: center; justify-content: center; position: absolute; top: 0; bottom: 0; left: 0; right: 0; width: 100%; font-size: 7em; color: transparent; background: transparent; content: "▶"; }
._checker:not(:focus)::before { color: rebeccapurple; background: #66339940; }
._checker *::selection { color: currentColor; background: transparent; }
._checker:not(:focus) td > div { visibility: hidden; }
._checker:not([data-phase=done]):not(#specificity) td > div,
._checker:not([data-phase=done]):not(#specificity) td > div * { color: transparent; }
._checker:not([data-phase=done]):not(#specificity) td > div::selection,
._checker:not([data-phase=done]):not(#specificity) td > div *::selection { color: transparent; }
._checker:not([data-phase=done]):not(#specificity) td > div::highlight(checker),
._checker:not([data-phase=done]):not(#specificity) td > div *::highlight(checker),
._checker:not([data-phase=done]):not(#specificity) td > div::highlight(upper),
._checker:not([data-phase=done]):not(#specificity) td > div *::highlight(upper) { color: transparent; }
._checker td > div { width: 5em; }
._checker td > div { position: relative; line-height: 1; }
._checker td > div > span { position: absolute; margin: 0; padding-top: calc((1.5em - 1em) / 2); width: 5em; }
._checker ._custom :nth-child(2),
._checker [spellcheck] :nth-child(2),
._checker ._hih,
._checker ._his,
._checker ._hop { color: transparent; background: transparent; }
._checker ._custom :nth-child(1)::highlight(checker) { color: transparent; }
._checker [spellcheck] :nth-child(1)::spelling-error { color: transparent; }
._checker ._custom :nth-child(2)::highlight(checker) { color: CanvasText; background: Canvas; }
._checker [spellcheck] :nth-child(2)::spelling-error { color: CanvasText; background: Canvas; }
._checker [spellcheck] *::spelling-error { text-decoration: none; }
._checker ._hih::highlight(checker) { --t: transparent; --x: CanvasText; --y: Canvas; }
._checker ._hih :nth-child(1)::highlight(checker) { color: var(--t, CanvasText); background: var(--t, Canvas); }
._checker ._hih :nth-child(2)::highlight(checker) { color: var(--x, transparent); background: var(--y, transparent); }
._checker ._his::selection { --t: transparent; --x: CanvasText; --y: Canvas; }
._checker ._his :nth-child(1)::selection { color: var(--t, CanvasText); background: var(--t, Canvas); }
._checker ._his :nth-child(2)::selection { color: var(--x, transparent); background: var(--y, transparent); }
._checker ._hop :nth-child(1) { color: CanvasText; }
._checker ._hop :nth-child(1)::highlight(checker) { color: transparent; }
._checker ._hop :nth-child(1)::highlight(upper) { color: currentColor; }
._checker ._hop :nth-child(2) { color: transparent; }
._checker ._hop :nth-child(2)::highlight(checker) { color: CanvasText; -webkit-text-fill-color: transparent; }
._checker ._hop :nth-child(2)::highlight(upper) { color: currentColor; -webkit-text-fill-color: currentColor; }
._checker._table th { text-align: left; }

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

## What are they?

CSS has four highlight pseudos and an open set of author-defined custom highlight pseudos.
They have their roots in ::selection, which was a rudimentary and non-standard, but widely supported, way of styling text and images selected by the user.

The built-in highlights are ::selection for user-selected content, ::target-text for linking to text fragments, ::spelling-error for misspelled words, and ::grammar-error for text with grammar errors, while the custom highlights are known as ::highlight(_x_) where _x_ is the author-defined highlight name.

## Can I use them?

Prior to our efforts, [::selection] was already widely supported, and [::target-text] shipped in Chromium 89.
But for most of that time, no browser had yet implemented the more robust highlight pseudo system in the [CSS pseudo spec].

[CSS pseudo spec]: https://drafts.csswg.org/css-pseudo/

::highlight() and the custom highlight API shipped in Chromium 105, thanks to the work by members of the Microsoft Edge team (Dan, Fernando, Sanket, Luis, Bo).

Chromium 105 also implements the vast majority of the new highlight pseudo system.
This includes highlight overlay painting, which was enabled for all highlight pseudos, and highlight inheritance, which was enabled for ::highlight() only.

[::selection]: https://developer.mozilla.org/en-US/docs/Web/CSS/::selection
[::target-text]: https://developer.mozilla.org/en-US/docs/Web/CSS/::target-text

Chromium 107 includes ::spelling-error and ::grammar-error as an experimental feature.
You can enable these features at

> chrome://flags/#enable-experimental-web-platform-features

^ FIXME check version

Click the table below to see if your browser supports these features.

<pre id="debug" hidden style="position: fixed; color: white; background: black; left: 0; top: 0; right: 0; margin: 0;">act: <span id="debug_active"></span><br>sel: <span id="debug_selection"></span><br><span id="debug_count"></span></pre>
<figure><table id="checker" class="_table _checker" contenteditable spellcheck="false" data-phase="fresh">
    <tr><th>Custom highlights</th><td><div class="_custom"><span>no</span><span>yes</span></div></td></tr>
    <tr><th>Spelling</th><td><div spellcheck="true" lang="en"><span>no</span><span>yes</span></div></td></tr>
    <tr><th>Highlight overlay painting</th><td><div class="_hop"><span>no</span><span>yes</span></div></td></tr>
    <tr><th>Highlight inheritance (::selection)</th><td><div class="_his"><span>no</span><span>yes</span></div></td></tr>
    <tr><th>Highlight inheritance (::highlight)</th><td><div class="_hih"><span>no</span><span>yes</span></div></td></tr>
</table></figure>
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
            `${sel.anchorOffset} ${sel.anchorNode.nodeName}${format(sel.anchorNode)}`
            + `\n     `
            + `${sel.focusOffset} ${sel.focusNode.nodeName}${format(sel.focusNode)}`;
        function format(node) {
            if (node.nodeValue == null)
                return "";
            if (node.nodeValue.length < 30)
                return ` "${node.nodeValue}"`;
            return ` "${node.nodeValue.slice(0,27)}"...`;
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
            if (this.CSS && CSS.highlights) {
                const custom = new Range;
                custom.selectNodeContents(target.children[0].children[0]);
                const hop = new Range;
                hop.selectNodeContents(target.children[0].children[2]);
                const hih = new Range;
                hih.selectNodeContents(target.children[0].children[4]);
                CSS.highlights.set("checker", new Highlight(custom, hop, hih));
                CSS.highlights.set("upper", new Highlight(hop));
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

<figure markdown="1"><div markdown="1" class="scroll"><div markdown="1" class="flex">
```css
::selection {
    color: white;
    background-color: blue;
}
aside::selection,
aside *::selection {
    background-color: green;
}
```
<div class="gap"></div>
≈
<div class="gap"></div>
```css
:root::selection {
    color: white;
    background-color: blue;
}
aside::selection {
    background-color: green;
}
```
</div></div><figcaption markdown="1">
With highlight inheritance (right), aside::selection can now override ‘background-color’ cleanly without needing to select all of its descendants (left).
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

<figure><div class="scroll" markdown="1">
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
</div><figcaption markdown="1">
<span style="background: yellow;">Hello</span>, world!
</figcaption></figure>

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

    // = rgb(255, 0, 255)
    // even though only ::selection is active
    getComputedStyle(document.body, "::highlight(foo)")
        .backgroundColor;
</script>
<body>Hello, world!</body>
```
</div></figure>

## How do they work?

Highlight pseudos are defined as pseudo-elements, but they actually have very little in common with other pseudo-elements like ::before and ::first-line.
Unlike other pseudos, they generate _highlight overlays_, not boxes, and these overlays are like layers over the original content.
Where text is highlighted, a highlight overlay can add backgrounds and text shadows, while the text proper and any other decorations are “lifted” to the very top.

<style>@import url(/images/hpdemo.css);</style>
<script src="/images/hpdemo.js"></script>
<figure><div class="_demo _hpdemo" data-_demo="_hpdemo" style="--w: var(--inner-width);">
    <script type="text/x-choreography">
        q   q   q   q   q   q
        0   1   2   2   3   3
    </script>
    <div><main style="--n: 7;">
        <div style="outline: 3px dotted #00000070; background: #70700038;">
            <span>quikc brown<span style="color: initial;"> fox</span></span>
            <label>originating element</label>
        </div>
        <div style="outline: 3px dotted #00000070; background: #A8000038;">
            <span><span style="color: initial; text-decoration: red wavy underline;">qui</span>kc brown fox</span>
            <label>::spelling-error</label>
        </div>
        <div style="outline: 3px dotted #00000070; background: #66339938;">
            <span>quikc <span style="background: #D070D0C0;">br<span>own</span></span> fox</span>
            <label>::target-text</label>
        </div>
        <div class="q">
            <span>quikc <span>br<span style="color: initial;">own</span></span> fox</span>
        </div>
        <div style="outline: 3px dotted #00000070; background: #3838C038;">
            <span>qui<span style="background: #3838C0C0;"><span>kc</span> br</span>own fox</span>
            <label>::selection</label>
        </div>
        <div class="q">
            <span>qui<span style="color: initial;"><span style="text-decoration: red wavy underline;">kc</span> br</span>own fox</span>
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
            const rect = this.root.getBoundingClientRect();
            const y = rect.top + (rect.bottom - rect.top) / 2;
            return Number(y < innerHeight / 2);
        },
        state: {},
        root: document.querySelector("._hpdemo"),
        t: null,
    };
    hpdemo.update();
    addEventListener("scroll", () => {
        hpdemo.update();
    });
</script>

You can think of them as _innermost_ pseudo-elements that always exist at the bottom of any tree of elements and other pseudos, but they don’t inherit their styles from that element tree.
Instead each highlight pseudo forms its own inheritance tree, parallel to the element tree.

<hr>

At this point, you can probably see that the highlight pseudos are quite different from the rest of CSS, but there are also several special cases and rules needed to make them a coherent system.

For the typical appearance of <span class="_spelling">spelling</span> and <span class="_grammar">grammar</span> errors, highlight pseudos need to be able to add their own decorations, and they need to be able to leave the underlying foreground color unchanged.
_Highlight inheritance_ happens separately from the element tree, so we need some way to refer to the underlying foreground color.
That escape hatch is to set ‘color’ itself to ‘currentColor’, which is a special case within a special case.

You see, ‘currentColor’ is usually defined as “the computed value of ‘color’”, but the way I like to think of it is “don’t change the foreground color”, and most color-valued properties like ‘text-decoration-color’ default to this value.
For ‘color’ itself that wouldn’t make sense, so we instead define ‘color:currentColor’ as equivalent to ‘color:inherit’, which still fits that mental model.
But for highlights, that definition would no longer fit, so we redefine it as being the ‘color’ of the next active highlight below.

To make highlight inheritance actually useful for <span class="_spelling">‘text-decoration’</span> and <span style="background: yellow;">‘background-color’</span>, _all properties are inherited_ in highlight styles, even those that are not usually inherited.
This would conflict with the usual rules for decorating box[^1] propagation, so we resolved this by making decorations added by highlights not propagate to any descendants.

[^1]: CSSWG discussion also found that decorating box semantics are undesirable for decorations added by highlights anyway.

Unstyled highlight pseudos generally don’t change the appearance of the original content, so the default ‘color’ and ‘background-color’ in highlights are ‘currentColor’ and ‘transparent’ respectively, the latter being the property’s initial value.
But two highlight pseudos, ::selection and ::target-text, have UA default foreground and background colors.
For compatibility with ::selection in old browsers, the UA default ‘color’ and ‘background-color’ (e.g. white on blue) is only used if _neither_ of them were set by the author.
This rule is known as _paired cascade_, and for consistency it also applies to ::target-text.

It’s common for selected text to almost invert the original text colors, turning <span style="color: black; background: white;">black on white</span> into <span style="color: white; background: cornflowerblue;">white on blue</span>, for example.
To guarantee that the original decorations remain as legible as the text when highlighted, which is especially important for decorations with semantic meaning (e.g. <span style="text-decoration: line-through;">line-through</span>), _originating decorations are recolored_ to the highlight ‘color’.
This doesn’t apply to decorations added by highlights though, because that would break the typical appearance of <span class="_spelling">spelling</span> and <span class="_grammar">grammar</span> errors.

The default style rules for highlight pseudos might look something like this.
Notice the new ‘spelling-error’ and ‘grammar-error’ decorations, which authors can use to imitate native spelling and grammar errors.

<figure><div class="scroll" markdown="1">
```css
::selection { background-color: Highlight; color: HighlightText; }
::target-text { background-color: Mark; color: MarkText; }
::spelling-error { text-decoration: spelling-error; }
::grammar-error { text-decoration: grammar-error; }
```
</div><figcaption markdown="1">
This doesn’t completely describe ::selection and ::target-text, due to paired cascade.
</figcaption></figure>

<hr>

The way the highlight pseudos have been designed naturally leads to some limitations.

## Removing decorations and shadows

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
del { text-decoration: line-through; text-shadow: 2px 2px red; }
::highlight(undelete) { text-decoration: none; text-shadow: none; }
```
</div><figcaption markdown="1">
This code means that ::highlight(undelete) adds no decorations or shadows, not that it removes the line-through and red shadow when `del` is highlighted.
</figcaption></figure>

Removing shadows that might clash with highlight backgrounds (as suggested in the tutorial above) will no longer be as necessary anyway, since highlight backgrounds now paint *on top of* the original text shadows.
If you still want to ensure those shadows don’t clash with highlights in older browsers, you can set ‘text-shadow’ to ‘none’, which is harmless in newer browsers.

<figure><div class="scroll" markdown="1">
```css
::selection { text-shadow: none; }
```
</div><figcaption markdown="1">
This rule might be helpful for older browsers, but note that like any universal rule, it can interfere with inheritance of ‘text-shadow’ when combined with more specific rules.
</figcaption></figure>

If you’re really determined, you can work around this limitation for line decorations by using ‘-webkit-text-fill-color’, [a standard property] (believe it or not) that controls the foreground fill color of text[^2].

[^2]: This is actually the case everywhere the WHATWG compat spec applies, at all times. If you think about it, the only reason why setting ‘color’ to ‘red’ makes your text red is because ‘-webkit-text-fill-color’ defaults to ‘currentColor’.

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

In fact, because of ‘-webkit-text-fill-color’ and [its stroke-related siblings], it isn’t always possible for highlight pseudos to avoid changing the foreground colors of text, at least not without out-of-band knowledge of what those colors are.

[its stroke-related siblings]: https://compat.spec.whatwg.org/#the-webkit-text-stroke

<figure><div class="scroll" markdown="1">
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
</div><figcaption markdown="1">
When a word in `em` is misspelled, it will become blue like the rest of `p`, unless the fill and stroke properties are set in ::spelling-error accordingly.
</figcaption></figure>

## Accessing global constants

Highlight pseudos also don’t automatically have access to custom properties set in the element tree, which can make things tricky if you have a design system that exposes a color palette via custom properties on :root.

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

You can work around this by adding selectors for the necessary highlight pseudos to the rule defining the constants, or if the necessary highlight pseudos are unknown, by rewriting each constant as a custom @property rule.

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

<hr>

[a standard property]: https://compat.spec.whatwg.org/#the-webkit-text-fill-color

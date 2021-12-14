---
layout: default
title: "Chromium spelling and grammar, part 2"
date: 2022-01-01 00:00:00 +0800
---

Modern web browsers can help users with their word processing needs by drawing squiggly lines under possible <span class="local-spelling">spelling</span> or <span class="local-grammar">grammar</span> errors in their input.
CSS will give authors more control over when and how they appear, with the new ::spelling- and ::grammar-error pseudo-elements, and spelling- and grammar-error text decorations.
[Since part 1] in May, we’ve done a fair bit of work in both Chromium and the CSSWG towards making this possible.

[Since part 1]: {% post_url 2021-05-17-spelling-grammar %}

<style>
article figure > img { max-width: 100%; }
article figure > figcaption { max-width: 30rem; margin-left: auto; margin-right: auto; }
article pre, article code { font-family: Inconsolata, monospace, monospace; }
article > :not(img):not(hr):before { width: 13em; display: block; overflow: hidden; content: ""; }
.local-demo { font-style: italic; font-weight: bold; color: rebeccapurple; }
.local-spelling, .local-grammar { text-decoration-thickness: 0; text-decoration-skip-ink: none; }
.local-spelling { text-decoration: red wavy underline; }
.local-grammar { text-decoration: green wavy underline; }
.local-table { font-size: 0.75em; }
.local-table td, .local-table th { vertical-align: top; border: 1px solid black; }
.local-table td:not(.local-tight), .local-table th:not(.local-tight) { padding: 0.5em; }
.local-tight picture, .local-tight img { vertical-align: top; }
.local-compare * + *, .local-tight * + *, ._gifs * + * { margin-top: 0; }
.local-compare { max-width: 100%; border: 1px solid rebeccapurple; }
.local-compare > div { max-width: 100%; position: relative; touch-action: pinch-zoom; --cut: 50%; }
.local-compare > div > * { vertical-align: top; max-width: 100%; }
.local-compare > div > :nth-child(1) { position: absolute; clip: rect(auto, auto, auto, var(--cut)); }
.local-compare > div > :nth-child(2) { position: absolute; width: var(--cut); height: 100%; border-right: 1px solid rebeccapurple; }
.local-compare > div > :nth-child(2):before { content: "actual"; color: rebeccapurple; font-size: 0.75em; position: absolute; right: 0.5em; }
.local-compare > div > :nth-child(2):after { content: "ref"; color: rebeccapurple; font-size: 0.75em; position: absolute; left: calc(100% + 0.5em); }
.local-sum td:first-of-type { padding-right: 1em; }
._gifs { position: relative; display: flex; flex-flow: column nowrap; }
._gifs:focus-visible { outline: 0.1em solid #663399C0; outline-offset: -0.1em; }
._gifs._paused > * { opacity: 0.5; }
._gifs::after { display: flex; position: absolute; top: 0; bottom: 0; left: 0; right: 0; align-items: center; justify-content: center; font-size: 7em; color: rebeccapurple; content: "▶"; opacity: 0; /* creating ::after only when paused makes firefox flicker */ }
._gifs._paused::after { opacity: 1; }

.local-commit-container-container { position: relative; }
.local-commit-line { position: absolute; right: -0.1em; height: 100%; border-right: 0.2em solid rgba(102,51,153,0.5); }
.local-commit-container { position: relative; padding-right: 0.5em; }
* + .local-commit, .local-commit * + * { margin-top: 0; }
.local-commit { line-height: 2; margin-right: -1.5em; text-align: right; }
.local-commit > img { width: 2em; vertical-align: middle; }
.local-commit > a { padding-right: 0.5em; text-decoration: none; color: rebeccapurple; }
.local-commit > a > code { font-size: 1em; }
.local-commit-none > a { color: rgba(102,51,153,0.5); }
</style>

At its core, the client funding this work had an internal patch that did just enough to allow you to customise squiggly line colors, and our job was to upstream it.
But turning that into something that’s suitable for adoption by the general public, that interacts well with other features, and can be specified *and tested* in a cohesive way that makes sense to other implementors?
That’s a lot more involved than merging a branch.

Check out our [project index](https://bucket.daz.cat/work/igalia/0/) for a complete list of demos, tests, patches, and issues.

## Contents

* [Current status](#current-status)
* [Charlie’s lawyerings](#charlie)
* [Wavy decorations](#wavy-decorations)
* [Highlight inheritance](#highlight-inheritance)
    * [Blink style 101](#blink-style-101)
    * [How pseudo-elements work](#blink-style-102)
    * [Status quo](#status-quo)
    * [Storing highlight styles](#storing-highlight-styles)
    * [Single-pass resolution](#single-pass-resolution)
    * [Multi-pass resolution](#multi-pass-resolution)
    * [Pathology in legacy](#pathology-in-legacy)
    * [Paired cascade](#paired-cascade)
    * [Who’s got green?](#fixing-tests)

## Current status

A rudimentary version of highlight inheritance has landed, including support for ::highlight ([Fernando Fiori](https://crrev.com/c/3237158)).
More work needs to be done to improve performance and iron out edge cases.
This implementation is currently behind a Blink feature flag:

<figure><div class="scroll" markdown="1">
    --enable-blink-features=HighlightInheritance
</div></figure>

Adding to our initial support for ::{spelling,grammar}-error, we’ve since landed the same for the new {spelling,grammar}-error decoration types.
So far, both are mostly only supported in style, not in paint; while the cascade and other style calculations will understand them, they aren’t very useful yet.

We’ve also made it possible to change the color of native squiggly lines by setting text-decoration-color on either of the new pseudo-elements.
This feature, and the features above, are also behind a flag:

<figure><div class="scroll" markdown="1">
    --enable-blink-features=CSSSpellingGrammarErrors
</div></figure>

[TODO write about [the big june meeting](https://hackmd.io/@dazabani/cr-highlight-pseudos-2021-06)]

[TODO update this with work from the last month or two]

<h2 markdown="1" id="charlie">[C](https://www.youtube.com/watch?v=qcderLXiwa8)harlie’s ~~bird~~ spec lawyerings</h2>

I’ve learned a lot of things while working on this project.
One interesting lesson was that no matter how clearly a feature is specified, and how much discussion goes into spec details, half the questions won’t become apparent until implementors start building it.

<img width="300" height="300" src="/images/spammar2-charlie.jpg" class="flight">

* What happens when both highlight and originating content define text shadows? What if multiple highlights do the same? What order do we paint these shadows in? ([#3932](https://github.com/w3c/csswg-drafts/issues/3932))
* What happens to the originating content’s decorations when highlighted? What happens when highlights define their own decorations? Which decorations get recolored to the foreground color for clarity? What’s the painting order? Does it even mean anything for a highlight to set text-decoration-color only? ([#6022](https://github.com/w3c/csswg-drafts/issues/6022))
* Some browsers invert the author’s ::selection background based on contrast with the foreground color. Should this be allowed, or does it do more harm than good? ([#6150](https://github.com/w3c/csswg-drafts/issues/6150))
    * What about other “tweaks”? What if a browser needs to force translucency to make its selection highlighting *work*? ([#6853](https://github.com/w3c/csswg-drafts/issues/6853))
    * How do we even write reftests if they *are* allowed? (no issue)
    * While we’re talking about testing, how do we even test ::{spelling,grammar}-error without a way to guarantee that some text is treated as an error? ([wpt#30863](https://github.com/web-platform-tests/wpt/issues/30863))
* How does paired cascade work? Does “use” mean used value? Which properties are “highlight colors”? Do we really mean ::selection only, and color and background-color only? What does it mean for a highlight color to have been “specified by the author”? Does the user origin stylesheet count as “specified”? Do unset and revert count as “specified”? Does unset mean inherit even when the property is not normally inherited? ([#6386](https://github.com/w3c/csswg-drafts/issues/6386))
* Should custom properties be allowed? What about variable references? Do we force non-inherited custom properties to become inherited like we do for non-custom properties? Should we provide a better way to set custom properties in a way that affects highlight pseudos? ([#6264](https://github.com/w3c/csswg-drafts/issues/6264), [#6641](https://github.com/w3c/csswg-drafts/issues/6641))
* What if existing content relies on implicitly inheriting a highlight foreground color when setting background-color explicitly, or vice versa? Do we need to accommodate this for compat? ([#6774](https://github.com/w3c/csswg-drafts/issues/6774))
* The spec effectively recommends that ::{spelling,grammar}-error (and *requires* that ::highlight) force the text color to black by default. Surely we want to *not change* the color by default? ([#6779](https://github.com/w3c/csswg-drafts/issues/6779))
* Does color:currentColor point to the next *active* highlight overlay below, or are inactive highlights included too? What happens when the author tries to getComputedStyle with ::selection? ([#6818](https://github.com/w3c/csswg-drafts/issues/6818))
* Do decorations “propagate” to descendants in highlights like they would normally? How do we reconcile that with highlight inheritance? How do we ensure that “decorating box” semantics aren’t broken? ([#6829](https://github.com/w3c/csswg-drafts/issues/6829))

## Wavy decorations

[TODO write about this]

<figure><div class="scroll"><div class="flex" style="flex-direction: column; align-items: center;">
    <!-- ( i=images/foo; ffmpeg -y -i $i.gif -vf 'setpts=50/60*PTS' -r 60 -pix_fmt yuv420p -vcodec libx264 -crf 17 $i.mp4 ) -->
    <!-- ( i=images/foo; ffmpeg -y -i $i.gif -vf 'setpts=50/60*PTS' -r 60 -pix_fmt yuv420p -vcodec libvpx -crf 10 -b:v 1M $i.webm ) -->
    <!-- <img width="384" height="216" src="/images/spammar2-w0.gif"> -->
    <!-- <img width="384" height="216" src="/images/spammar2-w1.gif"> -->
    <div class="_gifs _paused" tabindex="0">
        <video loop playsinline tabindex="-1" width="384" height="216" poster="/images/spammar2-w0.png"><source src="/images/spammar2-w0.mp4"><source src="/images/spammar2-w0.webm"></video>
        <video loop playsinline tabindex="-1" width="384" height="216" poster="/images/spammar2-w1.png"><source src="/images/spammar2-w1.mp4"><source src="/images/spammar2-w1.webm"></video>
    </div>
</div></div><figcaption>
    (<a href="https://bucket.daz.cat/work/igalia/0/0.html?color=%2300C000&style=wavy&line=underline&thickness=auto&ink=none&trySpellcheck=1&wm=horizontal-tb&marquee&overlay"><strong>demo<sub>0</sub></strong></a>)
</figcaption></figure>

## [TODO other topics]

* prioritise mvp: 90XchqYYTmKvtwG_TALVdw
* https://bucket.daz.cat/work/igalia/0/29.html
* invalidation bugs (target-text, selection in firefox)
* used-value-time tweaking of highlight colors
    * untestable issue
* spec issues: 62#note_46655, 62#note_47793
* reconsider whether text-shadow should be allowed

## [TODO highlight painting]

* split originating and ::selection decorations
    * reftest weirdness with wavy
    * bézier clipping region (freya holmer)
* rego’s work

<hr>

## Highlight inheritance

Presto (Opera), uniquely, supported inheritance for ::selection before it was cool, by mapping those styles to synthesised (internal) ‘selection-color’ and ‘selection-background’ properties that were marked as inherited.

Blink also has internal properties, most notably for [:visited links](https://developer.mozilla.org/en-US/docs/Web/CSS/:visited) and [forced colors](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/forced-colors), where we need to keep track of both “original” and “new” colors.
This works well enough, but internal properties add a great deal of complexity to the code that applies and consumes styles.
Now that there are multiple highlight pseudos, supporting a lot more than just ‘color’ and ‘background-color’, this complexity is hard to justify.

To understand the work that went into highlight inheritance, let’s take a look at how CSS works in Chromium.

### Blink style 101

CSS is managed by Blink’s *style* system, which at its highest level consists of the *engine*, the *resolver*, and the *ComputedStyle* data structure.
The engine maintains all of the style-related state for a document, including all of its stylesheet rules *and* the information needed to recalculate styles efficiently when the document changes.
The resolver’s job is to calculate styles for some element, writing the results to a new ComputedStyle object.

<figure><div class="scroll">
    <img width="407" height="167" src="/images/spammar2-x0.png" srcset="/images/spammar2-x0.png 2x">
</div></figure>

ComputedStyle itself is also interesting.
There are over 600 properties, including internal properties, shorthands (like ‘margin’), and aliases (like ‘-webkit-transform’), so most of the fields and methods are actually generated (ComputedStyleBase) with the help of some Python scripts.
These fields are “sharded” into *field groups*, so we can [efficiently reuse] style data from ancestors and previous resolver outputs. Some of these field groups are human-defined, like “surround” for all of the margin/border/padding properties, but there are also several *raredata* groups generated from property popularity stats.

[efficiently reuse]: https://en.wikipedia.org/wiki/Copy-on-write

<figure><div class="scroll">
    <img width="587" height="293" src="/images/spammar2-x1.png" srcset="/images/spammar2-x1.png 2x">
</div></figure>

When resolving styles, we usually start by cloning an [“empty”] ComputedStyle, then we copy over the inherited properties from the parent to this fresh new object.
Many of these live in the “inherited” field group, so all we need to do for those is copy a single pointer.
At this point, we have the parent’s inherited properties, and everything else as initial values, so if the element doesn’t have any rules of its own, we’re more or less done.

[“empty”]: https://developer.mozilla.org/en-US/docs/Web/CSS/initial_value

<!-- [^2]: Some properties, such as ‘color’, are inherited by default, but most properties aren’t. For example, if you add a ‘border’ to some element, it doesn’t really make sense for all of its descendants to automatically have borders too. -->

<figure><div class="scroll">
    <img width="527" height="334" src="/images/spammar2-x2.png" srcset="/images/spammar2-x2.png 2x">
</div></figure>

Otherwise, we search for matching rules, [sort all of their declarations] by things like specificity, then *apply* the winning declarations by overwriting various ComputedStyle fields.
If we’re overwriting fields in field groups, we need to clone the field groups too, to avoid clobbering someone else’s styles.

[sort all of their declarations]: https://www.w3.org/TR/css-cascade-4/#cascading

<figure><div class="scroll">
    <img width="527" height="190" src="/images/spammar2-x3.png" srcset="/images/spammar2-x3.png 2x">
</div></figure>

<h3 id="blink-style-102">Blink style 102: pseudo-elements</h3>

For ordinary elements (including pseudo-elements with a clear place in the DOM tree, like ::before or ::marker), we determine styles as part of *style*’s regular tree traversal.
We start by updating :root’s styles, then any children affected by the update, and so on.
But for other pseudos we usually use a “lazy” approach, where we don’t bother determining styles until they are needed by later phases of the rendering process, like *layout* or *paint*.

Let’s say we’re determining styles for some ordinary element.
When we’re searching for matching rules, if we find one that *actually* matches our ::selection, we make a note in our *pseudo bits* that we’ve seen rules for that pseudo, but otherwise ignore the rule.

<figure><div class="scroll">
    <img width="467" height="107" src="/images/spammar2-y0.png" srcset="/images/spammar2-y0.png 2x">
</div></figure>

Once we’re in *paint*, if the user has selected some text, then we need to know our ::selection styles.
So we check our *pseudo bits*, and if the ::selection bit was set, we call our *resolver* with a special request for pseudo styles, then cache the result into a vector inside the originating element’s ComputedStyle.

<figure><div class="scroll">
    <img width="547" height="97" src="/images/spammar2-y1.png" srcset="/images/spammar2-y1.png 2x">
</div></figure>

This is how ::selection used to work, and at first I tried to keep it that way.

<div class="local-commit-container-container"><div class="local-commit-line"></div><div markdown="1" class="local-commit-container">

### Status quo

<!-- 7 27/4 https://chromium-review.googlesource.com/c/chromium/src/+/2850068/76#message-6e35ffa1c80f3b2f5e6bbf67a57455cae4cbf62a
* status quo, but set parent_override
* had to disable early return optimisation
* had to disable pseudo style cache
* copy *all* properties to base style
* treat *all* properties as inherited when applying -->

My initial solution was to make *paint* pass in a custom inheritance parent with its style request.
Normally pseudo styles inherit from the originating element, but here they would inherit from the parent’s highlight styles, which we would obtain recursively.
Then in the resolver, if we’re dealing with a highlight, we copy non-inherited properties too.

On the surface, this worked, but to make it correct, we had to work around an optimisation where the resolver would bail out early if there were no matching rules.
Worse still, we had to bypass the pseudo cache entirely.
We already had to do so under :window-inactive, but the performance penalty was fairly contained.
Not anymore!

<div class="local-commit"><a href="https://crrev.com/c/2850068/7"><code>PS7</code></a><img src="/images/badapple-commit-dot.svg"></div>

<!-- 9..=10 3/5 https://chromium-review.googlesource.com/c/chromium/src/+/2850068/76#message-e7233cca6fd3946e65013d523c9ebdb7c2e47b63
* just clone parent (rather than copying properties)
* active-selection-018 ::selection background inversion
* still punishes :window-inactive -->

If we copy over the parent’s inherited properties as usual, and for highlights, copy the non-inherited properties too, that more or less means we’re copying *all* the fields, so why not do away with that and just clone the parent’s ComputedStyle?

<div class="local-commit"><a href="https://crrev.com/c/2850068/7..10"><code>PS10</code></a><img src="/images/badapple-commit-dot.svg"></div>

<!-- 13 7/5 https://chromium-review.googlesource.com/c/chromium/src/+/2850068/76#message-701cd86b8e72f54623e777d4a1e9a3ece9d4e24d
* attempt to cache, but no invalidation makes this d.o.a. -->

<!-- I then tried to tackle the complete lack of caching for highlight styles. -->

The pseudo cache is only designed for pseudos whose styles won’t need to change between the originating element’s style updates.
For most pseudos, this is true anyway, as long as we bypass the cache under pseudo-classes like :window-inactive.

These caches are essentially never cleared as such, but when the next update happens, the whole ComputedStyle (including the cache) gets discarded.
Caching results with custom inheritance parents is frowned upon, because changing the parent you inherit your styles from can yield different styles, but for highlights, we will always pass in the same parent throughout an update cycle, so surely we can use the cache here?

<div class="local-commit"><a href="https://crrev.com/c/2850068/10..13"><code>PS13</code></a><img src="/images/badapple-commit-dot.svg"></div>

<!-- 14..=16 28/5 https://chromium-review.googlesource.com/c/chromium/src/+/2850068/76#message-3b9153ca6ae474b6284fe59fb4b84d94bef48c48
* generated StyleHighlightData (per pseudo) with applicable properties only -->

…well, yes and no.

Given an element that inherits a bunch of highlight styles, the initial styles are correct.
But when those inherited values change in some ancestor, our highlight styles fail to update!
This is a classic *cache invalidation* bug.
Our invalidation system wasn’t even the problem — it’s just inherently unaware of lazily resolved styles in pseudo caches.
This is usually fine, because most pseudos inherit from the originating element, but not here.

### Storing highlight styles

With the pseudo cache being unsuitable for highlight styles, we need some other way of storing them.
Only a handful of properties are allowed in highlight styles, so why not make a dedicated type with only those fields?

The declarations and basic methods for CSS properties is entirely generated, so let’s write some new templates…

<figure><div class="scroll" markdown="1">
```jinja
{{ "{%" }} macro declare_highlight_class(name, fields, field_templates): -%}
class {{ "{{" }}name}} : public RefCounted<{{ "{{" }}name}}> {
 public:
  static scoped_refptr<{{ "{{" }}name}}> Create() { /* ... */ }
  scoped_refptr<{{ "{{" }}name}}> Copy() const { /* ... */ }
  bool operator==(const {{ "{{" }}name}}& other) const { /* ... */ }
  bool operator!=(const {{ "{{" }}name}}& other) const { /* ... */ }
  {{ "{%" }} for field in fields %}
  {{ "{{" }}declare_storage(field)}}
  {{ "{%" }} endfor %}
  {{ "{%" }} for field in fields %}
  {{ "{{" }}field_templates[field.field_template]
      .decl_public_methods(field.without_group())
    |indent(2)}}
  {{ "{%" }} endfor %}
 private:
  {{ "{{" }}name}}();
  CORE_EXPORT {{ "{{" }}name}}(const {{ "{{" }}name}}&);
};
{{ "{%" }}- endmacro %}
```
</div></figure>

…then use them in the ComputedStyleBase template.

<figure><div class="scroll" markdown="1">
```jinja
{{ "{{" }}declare_highlight_class(
    'StyleHighlightData',
    computed_style.all_fields
        |sort(attribute='name')
        |selectattr('valid_for_highlight')
        |list,
    field_templates)
  |indent(2)}}
```
</div></figure>

<div class="local-commit"><a href="https://crrev.com/c/2850068/13..16"><code>PS16</code></a><img src="/images/badapple-commit-dot.svg"></div>

Trouble is, all of the methods that apply and serialise property values — and there are hundreds of them — accept ComputedStyle, not some other type.

<figure><div class="scroll" markdown="1">
```c++
const blink::Color Color::ColorIncludingFallback(
    bool visited_link,
    const ComputedStyle& style) const { /* ... */ }

const CSSValue* Color::CSSValueFromComputedStyleInternal(
    const ComputedStyle& style,
    const LayoutObject*,
    bool allow_visited_style) const { /* ... */ }
```
</div></figure>

Combined with the fact that our copy-on-write field group system mitigates a lot of the wasted memory, well hopefully anyway, we quickly abandoned this dedicated type.

<div class="local-commit"><a href="https://crrev.com/c/2850068/16..25"><code>PS25</code></a><img src="/images/badapple-commit-dot.svg"></div>

<!-- <div class="local-commit local-commit-none"><a href="https://crrev.com/c/2850068/24..25"><code>PS25</code></a><img src="/images/badapple-commit-none.svg"></div> -->

We then optimised the top-level struct a bit, saving a few pointer widths by moving the four highlight style pointers into a separate type, but this was still less than ideal.
We were widening ComputedStyle by one pointer, but the vast majority of web content doesn’t use highlight pseudos at all, and ComputedStyle and ComputedStyleBase are very sensitive to size changes.
To give you an idea of how much it matters, we even throw a compile-time error if the size inadvertently changes!

<figure><div class="scroll" markdown="1">
```c++
struct SameSizeAsComputedStyleBase {
  SameSizeAsComputedStyleBase() { Alias(&pointers); Alias(&bitfields); }
 private:
  void* pointers[9];
  unsigned bitfields[5];
};

struct SameSizeAsComputedStyle : public SameSizeAsComputedStyleBase,
                                 public RefCounted<SameSizeAsComputedStyle> {
  SameSizeAsComputedStyle() { Alias(&own_pointers); }
 private:
  void* own_pointers[1];
};

ASSERT_SIZE(ComputedStyle, SameSizeAsComputedStyle);
```
</div></figure>

To move highlights out of the top-level and into a *raredata* group, we had to get rid of all the fancy generated code and Just write a plain struct, which has the added benefit of making the code easier to read.
Luckily, at this point we were only using it to loop through the four highlight pseudos, not dozens or hundreds of properties.

Then all we needed was a bit of JSON to tell the code generator to add an “extra” field, *and* find an appropriate field group for us (`"*"`).
Because this field is not for a popular CSS property, or a property at all really, it automatically goes in a *raredata* group.

<figure><div class="scroll" markdown="1">
```js
[{
  name: "HighlightData",
  inherited: true,
  field_template: "external",
  type_name: "StyleHighlightData",
  include_paths: ["third_party/blink/renderer/core/style/style_highlight_data.h"],
  default_value: "",
  wrapper_pointer_name: "DataRef",
  field_group: "*",
  computed_style_custom_functions: ["initial", "getter", "setter", "resetter"],
}]
```
</div></figure>

<div class="local-commit"><a href="https://crrev.com/c/2850068/25..35"><code>PS35</code></a><img src="/images/badapple-commit-dot.svg"></div>

### Single-pass resolution

With our new storage figured out, we now needed to actually write to it.
We want to resolve highlight styles as part of the regular style update cycle, so that they can eventually benefit from style invalidation.

Looking at the resolver, I thought wow, there does seem to be a lot of redundant work being done when resolving highlight styles in a separate request, so why not weave highlight resolution into the resolver while we’re at it?

<div class="local-commit"><a href="https://crrev.com/c/2850068/35..36"><code>PS36</code></a><img src="/images/badapple-commit-dot.svg"></div>

<figure><div class="scroll" markdown="1">
```diff
@@ third_party/blink/renderer/core/css/css_selector.h @@
   enum RelationType {
+    kHighlights,
@@ third_party/blink/renderer/core/css/css_selector.cc @@
       case kShadowSlot:
+      case kHighlights:
@@ third_party/blink/renderer/core/css/element_rule_collector.h @@
   MatchedRule(const RuleData* rule_data,
               unsigned style_sheet_index,
               const CSSStyleSheet* parent_style_sheet,
+              absl::optional<PseudoId> highlight)
@@ third_party/blink/renderer/core/css/resolver/match_result.h @@
   void AddMatchedProperties(
       const CSSPropertyValueSet* properties,
       unsigned link_match_type = CSSSelector::kMatchAll,
       ValidPropertyFilter = ValidPropertyFilter::kNoFilter,
+      absl::optional<PseudoId> highlight = absl::nullopt);
@@ ... @@
   const MatchedPropertiesVector& GetMatchedProperties(
+      absl::optional<PseudoId> highlight) const {
+    DCHECK(!highlight || highlight_matched_properties_.Contains(*highlight));
+    return highlight ? *highlight_matched_properties_.at(*highlight)
                      : matched_properties_;
@@ ... @@
   MatchedPropertiesVector matched_properties_;
+  HeapHashMap<PseudoId, Member<MatchedPropertiesVector>>
+      highlight_matched_properties_;
@@ third_party/blink/renderer/core/css/resolver/style_cascade.h @@
   void Apply(CascadeFilter = CascadeFilter());
+  void ApplyHighlight(PseudoId);
@@ third_party/blink/renderer/core/css/resolver/style_cascade.cc @@
 const CSSValue* ValueAt(const MatchResult& result,
+                        absl::optional<PseudoId> highlight,
@@ ... @@
 const TreeScope& TreeScopeAt(const MatchResult& result,
+                             absl::optional<PseudoId> highlight,
                              uint32_t position) {
```
</div></figure>

> In general we must find a less intrusive way to implement this. We can not have \|highlight\| params on everything.

You know what? Fair enough.

<div class="local-commit local-commit-none"><a href="https://crrev.com/c/2850068/36..37"><code>⭯ PS35</code></a><img src="/images/badapple-commit-none.svg"></div>

<h3 markdown="1" id="multi-pass-resolution">Tight but not *too* tight</h3>

Element::Recalc{,Own}Style are pretty big friends of *style*.
They drive the style update cycle by determining how the tree has changed, making a *resolver* request for the element, and determining which descendants also need to be updated.

This makes them the perfect place to update highlight styles.
All we need to do is make an additional resolver request for each highlight pseudo, store it in the highlight data, and bob’s your uncle.

<figure><div class="scroll" markdown="1">
```c++
StyleRecalcChange Element::RecalcOwnStyle(
    const StyleRecalcChange change,
    const StyleRecalcContext& style_recalc_context) {
  // ...
  if (new_style) {
    StyleHighlightData* highlights = new_style->MutableHighlightData();
    if (new_style->HasPseudoElementStyle(kPseudoIdSelection)) {
      ComputedStyle* parent = ParentComputedStyle()->HighlightData()->Selection();
      StyleRequest request{kPseudoIdSelection, parent};
      highlights->SetSelection(StyleForPseudoElement(style_recalc_context, parent));
    }
    // kPseudoIdTargetText
    // kPseudoIdSpellingError
    // kPseudoIdGrammarError
    // ...
  }
  // SetComputedStyle(new_style);
  // ...
}
```
</div></figure>

<div class="local-commit"><a href="https://crrev.com/c/2850068/37..43"><code>PS43</code></a><img src="/images/badapple-commit-dot.svg"></div>

### Pathology in legacy

So far, I had been writing this patch as a *replacement* for the old inheritance logic, but since we decided to defer highlight inheritance for ::highlight to a later patch, we had to undelete the old behaviour and switch between them with a Blink feature.

<!-- While this also proved prudent due to a compat risk we weren’t aware of ([csswg-drafts#6774](https://github.com/w3c/csswg-drafts/issues/6774)), the other reason why we did this was performance. --> Another reason for the feature gate was performance.
Of the pages in the wild already using highlight pseudos, most of them probably use universal ::selection rules, if only because of how useless the old model was for more complex use cases.

<!-- though some use counters might be a good idea -->

<figure><div class="scroll" markdown="1">
```css
::selection { color: lime; background: green; }
```
</div></figure>

But `::selection` isn’t magic — it literally means `*::selection`, which makes the rule match everywhere in the ::selection tree.
As a result, we end up cloning highlight styles for each descendant, only to apply the *same* property values, which wastes time and memory.
This will need to be fixed before we can enable the feature for everyone.

<figure><div class="scroll">
    <img width="448" height="378" src="/images/spammar2-z0.png" srcset="/images/spammar2-z0.png 2x">
</div><figcaption>
The reality is a bit more complicated than this, because ‘color’ and ‘background-color’ are actually in field groups that would also need to be cloned.
</figcaption></figure>

<div class="local-commit"><a href="https://crrev.com/c/2850068/43..51"><code>PS51</code></a><img src="/images/badapple-commit-dot.svg"></div>

### Paired cascade

Next we tried to reimplement *paired cascade*.
For compatibility reasons, ::selection has special logic for the browser’s default ‘color’ and ‘background-color’ (e.g. white on blue), where we only use those colors if *neither* of them were set by the author.
Otherwise, they default to initial values, usually black on transparent.

<figure><div class="scroll"><div class="flex"><table class="local-sum">
<tr><td></td><td><span style="color: white; background: #3584e4;">default on default</span></td></tr>
<tr><td>+</td><td markdown="1">
```css
::selection { background: yellow; }
```
</td></tr>
<tr><td>=</td><td><span style="color: black; background: yellow;">initial on yellow</span></td></tr>
</table></div></div></figure>

The spec says so in a mere 22 words:

> The UA must use its own highlight colors for ::selection only when neither color nor background-color has been specified by the author.

Brevity is a good thing, and this seemed clear enough to me in the past.
But once I actually had to implement it, I had questions about almost every word ([#6386](https://github.com/w3c/csswg-drafts/issues/6386)).
While they aren’t *entirely* resolved, we’ve been getting pretty close over the last few weeks.

<div class="local-commit"><a href="https://crrev.com/c/2850068/51..52"><code>PS52</code></a><img src="/images/badapple-commit-dot.svg"></div>

<h3 id="fixing-tests">Who’s got green?</h3>

Aside from cleanup and polish, the remaining work was to fix test failures and other bugs.
These included crashes under legacy layout, since we only implemented this for LayoutNG, and functional changes leaking out of the feature gate.
One of the reftest failures was also interesting to deal with.
Let’s minimise it and take a look.

<figure><div class="scroll" markdown="1">
```html
<!doctype html><meta charset="utf-8">
<title>active selection and background-color (basic)</title>
<style>
    main { color: fuchsia; background: red; }
    main::selection { background: green; }
</style>
<p>Pass if text is fuchsia on green, not fuchsia on red.
<main>Selected Text</main>
<script>/* selectNodeContents(main); */</script>
```
</div></figure>

In the past, the “Selected Text” would render as fuchsia on green, and the test passes.
But under highlight inheritance it fails, rendering as initial (black) on green, because we now inherit styles in a tree for each pseudo, not from the originating element.

<figure><div class="scroll"><div class="flex"><div>
<span style="color: fuchsia; background: green;">Selected Text</span>
→
<span style="color: black; background: green;">Selected Text</span>
</div></div></div></figure>

So if the test is wrong, then how do we fix it?
Well… it depends on the *intent* of the test, at least if we want to Do The Right Thing and preserve that.
Clearly the *primary* intent of the test is ‘background-color’, given the `<title>`, but tests can also have secondary, less explicit intents.
In this case, the flavour text[^1] even mentions fuchsia!

[^1]: This is an automated reftest, so the instructions in `<p>` have no effect on the outcome. [We require them anyway](https://web-platform-tests.org/writing-tests/reftests.html#writing-a-good-reftest), because they add a bit of redundancy that helps humans understand and verify the test’s assertions.

It might have helped if the test had a [`<meta name=assert>`](https://web-platform-tests.org/writing-tests/reftest-tutorial.html#writing-the-test-file), an optional field dedicated to conveying intent, but probably not.
Most of the assert tags I’ve seen are poorly written anyway, being a more or less verbose adaptation of the title or flavour text, and there’s a good chance that the intent for fuchsia (if any) was simply to inherit it from the originating element, so we would still need to invent a new intent.

We could change the reference to initial (black) on green, which would serve as a secondary test that we *don’t* inherit from the originating element, or remove the existing ‘color’, which would serve as a secondary test for [paired cascade](#paired-cascade).
But I didn’t think it through that far at the time, so I gave ::selection a new ‘color’, achieving neither.

<figure><div class="scroll" markdown="1">
```diff
 main::selection {
+ color: aqua;
  background: green; }
 </style>
 <p>Pass if text is
- fuchsia
+ aqua
 on green, not fuchsia on red.
```
</div></figure>

Because the selected and unselected text colors were now different, I created *another* test failure, though only under legacy layout.
The reference for this test was straightforward: aqua on green, no mention of fuchsia.
This makes sense on the surface, given that all of the text under test was selected.

In this case, the tip of the “t” was crossing the right edge of the selection as ink overflow, and were carefully painting the overflow in the unselected color.
The test would have failed under LayoutNG too, if not for an optimisation that skips this technique when everything is selected.
Let me illustrate with an exaggerated example:

<figure><div class="scroll">
    <img width="167" height="102" src="/images/spammar2-ink-overflow.png" srcset="/images/spammar2-ink-overflow.png 2x">
</div></figure>

To be clear, this behaviour is generally considered desirable, and Firefox even supports it for all markup, not just ::selection.
It’s definitely possible to make the active-selection tests account for this — and the tools to do so already exist in the Web Platform Tests — but I don’t have the time to pursue this right now.

<div class="local-commit"><a href="https://crrev.com/c/2850068/52..76"><code>PS76</code></a><img src="/images/badapple-commit-dot.svg"></div>

</div></div>

## [TODO next steps]

## [TODO thanks]

* rego, andruud, futhark, florian, fantasai, emilio

<hr>

<script>
    (() => {
        function click({ currentTarget: x }) {
            x.classList.toggle('_paused');
            x.querySelectorAll("video").forEach(v => {
                v.paused ? v.play() : v.pause();
            });
        }
        function keypress(event) {
            const { currentTarget: x, key } = event;
            if (key == "Enter")
                click(event);
        }
        document.querySelectorAll("._gifs").forEach(x => {
            x.addEventListener("click", click);
            x.addEventListener("keypress", keypress);
        });
    })();
</script>

---
layout: default
title: Choosing a software licence
date: 2015-12-21 22:00:00 +0800
---

The licence that one releases their software under is often a topic
that’s given less thought then it perhaps deserves. I’ve been
releasing my code under the MIT (Expat) licence for as long as I can
remember, but I thought it might be prudent to take a closer look at
what’s out there in the wild world of software licensing.

## Teal deer

Unless otherwise specified, neither this page, nor any of the pages
that I’m about to link to, necessarily constitute Proper Legal
Advice™. If your project matters enough that the choice of its
licence may have a significant effect, please hire an actual lawyer.
This means that you should definitely steer clear of Lionel Hutz.

If you want to choose a licence, and you want to make the most
reasonable choice you can in the least possible time, use GitHub’s
[Choose a License][cal]. For most scenarios, the choice basically
boils down to Expat, Apache 2.0, or the GPL.

[cal]: http://choosealicense.com/

If you’re looking for a comprehensive reference on the pros and cons
of the licence you’re considering, check out the Free Software
Foundation’s [Various Licenses and Comments about Them][vlcat], which
is only occasionally didactic about copyleft licensing. You may also
find [TLDRLegal][tldr] and OSS Watch’s [Licence
differentiator][ldiff] useful.

[vlcat]: https://www.gnu.org/licenses/license-list.html
[tldr]: https://tldrlegal.com/
[ldiff]: http://oss-watch.ac.uk/apps/licdiff/

## Licence compatibility

Whether or not two licences are “compatible” is important for when
programs of those licences are combined, derived, or linked together,
but the details depend on who you ask. For some, compatibility is
achieved when works of the given licences may be combined to form a
larger software project, while for others, compatibility also
requires that one of the constituent works’ licences be able to
“dominate”, licensing the entire derived work. Compatibility is
generally [*not* a symmetric relation][laurent].

[laurent]: http://www.eolevent.eu/sites/default/files/EOLE%202008%20%E2%80%94%20Philippe%20Laurent%20%E2%80%94%20The%20GPLv3%20and%20Compatibility%20Issues.pdf

## The public domain

Placing your work in the public domain is simple, in theory, as doing
so should relinquish your ownership and all of your rights over said
work. Very few jursdictions, however, provide a practical way to do
this, and in some jurisdictions, you may not be allowed to do this at
all! For people in those places, your work will effectively continue
to be “all rights reserved”, rendering it unusable for them.

Enter [CC0][cc0]. It’s essentially a licence that attempts to waive
all rights over a given work in a given jurisdiction, and failing
that, places the work under a licence with the most permissive terms
allowed in that jurisdiction.

[cc0]: https://creativecommons.org/about/cc0

CC0 is usually referred to as a “tool” instead of a “licence”,
because where a work may be placed in the public domain, CC0 no
longer bears the role of a licence. Unlike most Creative Commons
licences, CC0 is suitable for use with any kind of work, [including
software][ccsoft]. The FSF prefers CC0 for releasing works into the
public domain.

[ccsoft]: https://creativecommons.org/faq/#can-i-apply-a-creative-commons-license-to-software

## The novelty licences

Other attempts to solve the issue of placing works in the public
domain, include Banlu Kemiyatorn and Sam Hocevar’s Do What the Fuck
You Want to Public License, or WTFPL for short. While on the surface,
writing a licence to informally relinquish all rights seems like a
reasonable solution, the [Open Source Initiative][osiwtf] has noted
that without a clear and explicit grant of rights, the WTFPL is no
more universal than any other lone attempt to place a work in the
public domain.

[osiwtf]: http://opensource.org/minutes20090304

By lacking any explicit legal terms, the WTFPL also fails to disclaim
authors’ warranties and liabilities for their software, protections
that are provided by virtually all serious free and open licences. As
such, while “novelty” licences like the WTFPL are certainly amusing,
they’re not a wise choice for any significant projects.

## The copyleft licences

In an effort to ensure that free and open works remain so, even after
they’re distributed or modified to create derivative works,
“copyleft” licences like the GNU General Public License were created.
Richard Stallman described the concept succinctly in his *GNU
Manifesto*: “no distributor [of the GNU operating system] will be
allowed to restrict its further redistribution”.

When distributing software released under a copyleft licence, whether
or not any modifications have been made, the source *must* be
included or otherwise made readily available along with any binaries
or other forms of the software.

Some examples of copyleft licences include the Mozilla Public License
and the GNU GPL family of licences.

## The permissive licences

Free and open licences which are not copyleft are usually referred to
as “permissive” licences. Like all free and open licences, permissive
licences adhere to the Free Software Definition, and programs
licensed under a permissive licence grant anyone the freedom to:

1. Run the program in any manner, and for any purpose;
2. Study how the program works, and change it to suit one’s needs;
3. Redistribute copies (of the original program) to others; and
4. Distribute copies of one’s modified versions to others.

Permissive licences almost always specify a common set of additional
terms:

  * The authors disclaim all warranties and liabilities for their software;
  * Copies and derivative works must credit the original authors; and
  * Copies and derivatives must retain the original copyright notices.

There are loads of permissive licences out there, including but not
limited to:

  * The MIT licences (Expat, X11, and XFree86);
  * The BSD licences (“prior”, “original”, “revised”, “simplified”, and FreeBSD);
  * The University of Illinois/NCSA licence (UIUC or NCSA for short);
  * The ISC licences (with or without the FSF’s clarification); and
  * The Apache licences (versions 1.0, 1.1, and 2.0).

They’re all worth mentioning here, because they share a handful of
subtle differences.

## Advertising and endorsement clauses

Being permissive licences, the MIT, BSD, NCSA, ISC, and Apache
families of licences are nearly identical in their spirit and terms.

Chronologically speaking, there are five licences that have been used
in the BSD and its derivatives, although only the last three are
really relevant for modern usage:

  * The “prior” BSD licence (1988), as used by 4.3BSD-Tahoe;
  * The “original” BSD licence (1990), with four clauses;
  * The “revised” BSD licence (1999), with three clauses;
  * The “simplified” BSD licence, with two clauses; and
  * The FreeBSD licence, which also has two clauses.

The earliest two versions of the licence are roughly equivalent, and
they have clauses that are known as the “advertising clauses”, which
require that any advertising for products or services that contain
licenced code must include an acknowledgement of its authors.

You might correctly imagine that this requirement can prove very
unwieldy, very quickly, and as such, they aren’t approved by the OSI,
nor are they compatible with many popular licences like the GPL. The
“revised” version removes the advertising clause, making it far
less troublesome and incompatible with other free and open licences.

All three of these versions, however, include another clause that
requires permission prior to using the names of a work’s authors and
contributors to “endorse or promote” derivative works. Contrary to my
initial assumption, this doesn’t preclude the “revised” version from
compatibility with the GPL, nor from being considered free and open.

The “simplified” BSD licence removes this “endorsement” clause too,
leaving behind a fairly concise permissive licence, and the FreeBSD
licence is based on this version, with the addition of a paragraph
stating that the “views and conclusions” of the individual authors
don’t represent the FreeBSD Project as a whole.

As for the MIT family of licences:

  * The Expat licence is similar to the “simplified” BSD licence;
  * The X11 licence is similar to the “revised” BSD licence; and
  * The XFree86 licence is similar to the “original” BSD licence.

In other words, the X11 licence is like the Expat licence plus an
endorsement clause, and the XFree86 licence is like the X11 licence
plus an advertising clause.

The NCSA licence, put simply, is based on the “revised” BSD licence,
with some minor improvements in wording drawn from the X11 licence to
improve precision.

Version 1.0 of the Apache licence is similar to the “original” BSD
licence by virtue of having an advertising clause, while version 1.1
removes the clause, making it vaguely like the “revised” BSD licence.
These versions of the Apache licence weren’t really designed for
general use by other projects however, and their strict and specific
prohibitions on the use of Apache-related names, along with their
incompatibility with the GPL because of these, make them rather
unattractive options.

Finally and most elegantly, the ISC licences are “functionally
equivalent” to the Expat and “simplified” BSD licences, but thanks
to the Berne convention, they’re over 30% less wordy than Expat, and
over 40% less wordy than the BSD two-clause!

## Patent grants and retaliation clauses

Most of the permissive licences we’ve discussed so far were written
before software patents were widespread. With these licences, anyone
who uses a program that’s covered by one or more patents may risk
being the target of litigation from patent holders.

There are two kinds of clauses that a software licence can use to
help mitigate this risk: grant clauses *grant* users a licence to use
any necessary patents, and retaliation clauses *revoke* these patent
licences from anyone who initiates litigation.

Enter version 2.0 of the Apache licence. This licence contains both
a grant clause and a retaliation clause, making it widely recommended
as the most robust licence with respect to its protections against
patent litigation. The retaliation clause alone subsequently made its
way into the GPL 3.0 and the MPL 2.0.

## The Creative Commons licences

Mainly geared towards artistic and other creative works, the Creative
Commons family of licences give authors a variety of choices about
how their works may be used. Regardless of the choices that a given
author makes, anyone may — at the very least — distribute any work
that’s in the Creative Commons worldwide, but:

  * The work must not be modified, regardless of its distribution;
  * Attribution for the authors of the work must be preserved; and
  * The distribution must not take place for commercial purposes.

From here, authors may tweak the terms of the licence by:

  * Allowing the commercial distribution of their work; and/or
  * Allowing derivative works:
    * Provided that they use the same licence; or
    * Regardless of the resultant licence.

It’s not a good idea to use any of the Creative Commons licences,
except for CC0, for [software projects][ccsoft], because they lack
specific terms that are desirable for software licensing, and they’re
incompatible with most free and open software licences, among other
reasons.

## Colloquial ambiguities

Just as the Creative Commons, GPL, MPL, and Apache licences must be
disambiguated with a version and possibly some licensing settings,
the “MIT licence” and “BSD licence” need to be qualified with which
one of the three or five variants they encompass is being discussed
respectively.

Referring to the NCSA licence isn’t at all ambiguous, and the only
ambiguity when discussing the ISC licence is the clarifying
replacement of “and distribute” with “and/or distribute” to allow the
licence to be approved by the FSF, because some projects like OpenBSD
continue to use the old wording.

## Vanity and aesthetics

It’s also interesting to see that these free and open licences are
usually named after:

  * A software project: GNU GPL, MPL, Apache, BSD, Expat, X11, XFree86;
  * A university: MIT, UIUC/NCSA;
  * Another organisation: Creative Commons, ISC; or
  * Its contents: WTFPL.

While you could chalk it up to me being a little bit weird, I have a
slight but irrational aversion to preferring licences that fall into
the first two categories.

## Relicensing my work

At the exceedingly rare risk of these being foreshadowing words, I
don’t see myself being the target of patent litigation any time soon,
and I don’t feel like a copyleft licence provides a meaningful
benefit for my code over a permissive one.

I think I’ll relicense my projects under the ISC licence over the
next week or two — not that it matters, as virtually nobody actually
uses the code I’ve written, but because it’s cute as fuck *and* it
shares its semantics with the Expat licence that I’m currently using.

---
layout: default
_class: blogv2
title: "Generative AI in Servo"
date: 2025-04-11 20:00:00 +0800
tags: home igalia
_preview_description: "We can, and should, build Servo without generative AI tools like GitHub Copilot."
_preview_image: /images/generative-ai-in-servo.jpg
---

[Servo](https://servo.org) has shown that we can build a browser with a modern, parallel layout engine in a fraction of the cost of the big incumbents, thanks to our [powerful](https://www.rust-lang.org) [tooling](https://rust-analyzer.github.io/book/), our [strong community](https://servo.zulipchat.com/), and our [thorough documentation](https://book.servo.org/).
But we can, and should, build Servo without generative AI tools like GitHub Copilot.

<aside markdown=1>
This post is my personal opinion, not necessarily representative of Servo or my colleagues at Igalia.
I hope it makes a difference.
</aside>

I’m the lead author of our [monthly updates](https://servo.org/blog/) and the [Servo book](https://book.servo.org), a member of the [Technical Steering Committee](https://github.com/servo/project/blob/6dcfe4a26b034e0dccad2f4a31c1d797abcc8c82/governance/tsc/README.md), and a coauthor of [our current AI policy](https://book.servo.org/contributing.html#ai-contributions) ([permalink](https://github.com/servo/book/blob/d4c87ea7646ce43b354aa5c37dea674e830d5edf/src/contributing.md#ai-contributions)).
That policy was inspired by [Gentoo’s AI policy](https://wiki.gentoo.org/wiki/Project:Council/AI_policy), and has in turn inspired the AI policies of [Loupe](https://discourse.gnome.org/t/loupe-no-longer-allows-generative-ai-contributions/27327) and [Amaranth](https://mastodon.social/@whitequark/114303833444527216).

Recently the TSC voted in favour of [two proposals](https://github.com/servo/servo/discussions/36379) that relax our ban on AI contributions.
This was a mistake, and it was also a mistake to wait until *after* we had made our decision to seek community feedback (see [§ On governance](#on-governance)).
[§ Your feedback](#your-feedback) made it clear that those proposals are the wrong way forward for Servo.

<aside markdown=1>
**Correction (2025-04-12)**

A previous version of this post highlighted a logic error in the [AI-assisted patch](https://github.com/servo/servo/discussions/36379) we used as a basis for those two proposals.
This error was made in a non-AI-assisted part of the patch.
</aside>

I call on the TSC to **explicitly reaffirm that generative AI tools like Copilot are not welcome in Servo**, and make it clear that we **intend to keep it that way indefinitely**, in both our policy and the community, so we can start rebuilding trust.
It’s not enough to say oops, sorry, we will not be moving forward with these proposals.

Like any logic written by humans, this policy does have some unintended consequences.
Our intent was to ban AI tools that generate bullshit [\[a\]](https://link.springer.com/content/pdf/10.1007/s10676-024-09775-5.pdf) in inscrutable ways, including GitHub Copilot and ChatGPT.
But there are other tools that use [similar](https://en.wikipedia.org/w/index.php?title=Transformer_(deep_learning_architecture)&oldid=1284020707) [underlying](https://en.wikipedia.org/w/index.php?title=Deep_learning&oldid=1283714111) [technology](https://en.wikipedia.org/w/index.php?title=Neural_network_(machine_learning)&oldid=1282432692) in more useful and less problematic ways (see [§ Potential exceptions](#potential-exceptions)).
Reviewing these tools for use in Servo should be a **community-driven process**.

We should not punish contributors for honest mistakes, but we should **make our policy easier to follow**.
Some ways to do this include documenting the tools that are known to be allowed and not allowed, documenting how to turn off features that are not allowed, and giving contributors a way to declare that they’ve read and followed the policy.

The declaration would be a good place to provide a dated link to the policy, giving contributors the best chance to understand the policy and knowingly follow it (or violate it).
This is not perfect, and it won’t always be easy to enforce, but it should give contributors and maintainers a foundation of trust.

---

## Potential exceptions

Proposals for exceptions should start in the community, and should focus on a specific tool used for a specific purpose.
If the proposal is for a specific *kind* of tool, it must come with concrete examples of *which* tools are to be allowed.
Much of the harm being caused by generative AI in the world around us comes from people using open-ended tools that are not fit for any purpose, or even treating them like they are [AGI](https://en.wikipedia.org/w/index.php?title=Artificial_general_intelligence&oldid=1284985284).

The goal of these discussions would be to understand:

- the underlying challenges faced by contributors
- how effective the tool is for the purpose
- how well the tool and purpose mitigate the issues in the policy
- whether there are any existing or alternative solutions
- whether those solutions have problems that need to be addressed

Sometimes the purpose may need to be constrained to mitigate the issues in the policy.
Let’s look at a couple of examples.

For some tasks like **speech recognition** [\[b\]](https://arxiv.org/pdf/2212.04356) and **machine translation** [\[c\]](https://research.google/blog/recent-advances-in-google-translate/) [\[d\]](https://aclanthology.org/2020.amta-research.9.pdf), tools with large language models and transformers are the state of the art (other than humans).
This means those tools may be probabilistic tools, and strictly speaking, they may be [*generative AI*](https://en.wikipedia.org/w/index.php?title=Generative_artificial_intelligence&oldid=1284756817) tools, because the models they use are [*generative models*](https://en.wikipedia.org/w/index.php?title=Generative_model&oldid=1264858524).
Generative AI does not necessarily mean “AI that generates bullshit in inscrutable ways”.

**Speech recognition** can be used in a variety of ways.
If plumbed into ChatGPT, it will have all of the same problems as ChatGPT.
If used for automatic captions, it can make videos and calls accessible to people that can’t hear well (myself included), but it can also infantilise us by [censoring profanities](https://ericwbailey.website/published/swearing-and-automatic-captions/) and make serious errors that [cause real harm](https://www.consumerreports.org/disability-rights/auto-captions-often-fall-short-on-zoom-facebook-and-others-a9742392879/).
If deployed for that purpose by an online video platform, it can undermine the labour of human transcribers and lower the overall quality of captions.

If used as an input method, it would be a clear win for accessibility.
My understanding of speech input tools is that they have a clear (if configurable) mapping from the things you say to the text they generate or [the edits they make](https://www.cursorless.org/docs/), so they may be a good fit.

In that case, *maintainer burden* and *correctness and security* would not be an issue, because the author is in complete control of what they write.
*Copyright issues* seem less of a concern to me, since these tools operate on such a small scale (words and symbols) that they are unlikely to reproduce a copyrightable amount of text verbatim, but I am not a lawyer.
As for *ethical issues*, these tools are generally trained once then run on the author’s device.
When used as an input method, they are not being used to undermine labour or justify layoffs.
I’m not sure about the process of training their models.

**Machine translation** can also be used in a variety of ways.
If deployed by a language learning app, it can ruin the quality of your core product, but hey, then you can [lay off](https://www.washingtonpost.com/technology/2024/01/10/duolingo-ai-layoffs/) those pesky human translators.
If used to localise your product, your users will finally be able to [compress to postcode file](https://www.neowin.net/news/accept-essential-biscuits-windows-11-calls-zip-files-postcode-files-in-uk-english/).
If used to localise your docs, it can make your docs worse than useless unless you [take very careful precautions](https://www.reddit.com/r/rust/comments/1jtw560/comment/mm6e34l/).
What if we allowed contributors to use machine translation to communicate with each other, but not in code commits, documentation, or any other work products?

Deployed carelessly, they will waste the reader’s time, and undermine the labour of actual human translators who would otherwise be happy to contribute to Servo.
If constrained to collaboration, it would still be far from perfect, but it may be worthwhile.

*Maintainer burden* should be mitigated, because this won’t change the amount or kind of text that needs to be reviewed.
*Correctness and security* too, because this won’t change the text that can be committed to Servo.
I can’t comment on the *copyright issues*, because I am not a lawyer.
The *ethical issues* may be significantly reduced, because this use case wasn’t a market for human translators in the first place.

---

## Your feedback

I appreciate the feedback you gave [on the Fediverse](https://floss.social/@servo/114296977894869359), [on Bluesky](https://bsky.app/profile/servo.org/post/3lma3ru5jok2y), and [on Reddit](https://www.reddit.com/r/rust/comments/1jtw560).
I also appreciate the comments [on GitHub](https://github.com/servo/servo/discussions/36379) from several people who were more on the [favouring](https://github.com/servo/servo/discussions/36379#discussioncomment-12752620) [side](https://github.com/servo/servo/discussions/36379#discussioncomment-12752951) [of](https://github.com/servo/servo/discussions/36379#discussioncomment-12754434) [the](https://github.com/servo/servo/discussions/36379#discussioncomment-12770260) [proposal](https://github.com/servo/servo/discussions/36379#discussioncomment-12775011), even though we reached different conclusions in most cases.
One comment argued that it’s possible to use AI autocomplete safely by accepting the completions [one word at a time](https://github.com/servo/servo/discussions/36379#discussioncomment-12756971).

That said, the overall consensus in our community was overwhelmingly clear, including among many of those who were in favour of the proposals.
None of the benefits of generative AI tools are worth the cost in community goodwill [\[e\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12770260).

Much of the dissent on GitHub was already covered by our existing policy, but there were quite a few arguments worth highlighting.

**Speech-to-text input**
is ok [\[f\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12776344) [\[g\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12756111).

**Machine translation**
is generally not useful or effective for technical writing [\[h\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12751548) [\[i\]](https://www.reddit.com/r/rust/comments/1jtw560/comment/mlxty67) [\[j\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752411).
It can be, if some precautions are taken [\[k\]](https://www.reddit.com/r/rust/comments/1jtw560/comment/mm6e34l/).
It may be less ethically encumbered than generative AI tools [\[l\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752707).
Client-side machine translation is ok [\[m\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753281).
Machine translation for collaboration is ok [\[n\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12759143) [\[o\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12756111).

**The proposals.**
Proposal 1 is ill-defined [\[p\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12754818).
Proposal 2 has an ill-defined distinction between autocompletes and “full” code generation [\[q\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753114) [\[r\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752843) [\[s\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753041).

**Documentation**
is just as technical as code [\[u\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12767895).
Wrong documentation is worse than no documentation [\[v\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12751560) [\[w\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753041) [\[x\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12769041).
Good documentation requires human context [\[y\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12751548) [\[z\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752411).

**GitHub Copilot**
is not a good tool for answering questions [\[ab\]](https://github.com/servo/book/pull/27).
It isn’t even that good of a programming tool [\[ac\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752073).
Using it may be incompatible with the DCO [\[ad\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752073).
Using it could make us depend on Microsoft to protect us against legal liability [\[ae\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752938).

**Correctness.**
Generative AI code is wrong at an alarming rate [\[af\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12754116).
Generative AI tools will lie to us with complete confidence [\[ag\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753566).
Generative AI tools (and users of those tools) cannot explain their reasoning [\[ah\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752823) [\[ai\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12776304).
Humans as supervisors are ill-equipped to deal with the subtle errors that generative AI tools make [\[aj\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752707) [\[ak\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753375) [\[al\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12756059) [\[am\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12766312).
Even experts can easily be misled by these tools [\[an\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752411).
Typing is not the hard part of programming [\[ao\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752823), as even some of those in favour [have said](https://medium.com/@polyglot_factotum/ai-is-not-a-better-ide-e395db9da063):

> If I could offload that part of the work to copilot, I would be left with more energy for the challenging part.

**Project health.**
Partially lifting the ban will create uncertainty that increases maintainer burden for all contributions [\[ap\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753041) [\[aq\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12776304).
Becoming dependent on tools with non-free models is risky [\[ar\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752620).
Generative AI tools may not be fair use [\[as\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12755626) → [\[at\]](https://suchir.net/fair_use.html).
Outside of Servo, people have spent so much time cleaning up after LLM-generated mess [\[au\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752843).

**Material.**
Servo contributor refuses to spend time cleaning up after LLM-generated mess [\[av\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752707).
Others will stop donating [\[aw\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752707) [\[ax\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753442) [\[ay\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753939) [\[az\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12754804) [\[ba\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12754889) [\[bb\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12755244) [\[bc\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12758397) [\[bd\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12759143) [\[be\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12763689) [\[bf\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12755031) [\[bg\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12756035), will stop contributing [\[bh\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752707), will not start donating [\[bi\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12754139), will not start contributing [\[bj\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753271) [\[bk\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12755031), or will not start promoting [\[bl\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12753271) the project.

**Broader context.**
Allowing AI contributions is a bad signal for the project’s relationship with the broader AI movement [\[bm\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752415) [\[bn\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752707) [\[bo\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12757753).
The modern AI movement is backed by overwhelming capital interests, and must be opposed equally strongly [\[bp\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752707).
People often “need” GitHub or Firefox, but no one “needs” Servo, so we can and should be held to a higher standard [\[bq\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752707).
Rejection of AI is only credible if the project rejects AI contributions [\[br\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752707).
We can attract funding from AI-adjacent parties without getting into AI ourselves [\[bs\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12752823), though that may be easier said than done [\[bt\]](https://github.com/servo/servo/discussions/36379#discussioncomment-12775861).

---

## On governance

Several people have raised concerns about how Servo’s governance could have led to this decision, and some have even suspected foul play.
But like most discussions in the TSC, most of the discussion around AI contributions happened async on Zulip, and we didn’t save anything special for the synchronous monthly public calls.
As a result, whenever the discussion overflowed the sync meeting, we just continued it internally, so the public minutes were missing the vast majority of the discussion (and the decisions).
These decisions should probably have happened in public.

Our decisions followed the TSC’s usual process, with a strong preference for resolving disagreements by consensus rather than by voting, but we didn’t have any consistent structure for moving from one to the other.
This may have made the decision process prone to being blocked and dominated by the most persistent participants.

Contrast this with decision making within Igalia, where we also prefer consensus before voting, but the consensus process is always used to inform *proposals* that are drafted by *more than one person* and then *always voted on*.
Most polls are “yes” or “no” by majority, and only a few polls for the most critical matters allow vetoing.
This ensures that proposals have meaningful support before being considered, and if only one person is strongly against something, they are heard but they generally can’t single-handedly block the decision with debate.

<aside markdown=1>
The rules are actually more complex than just by majority.
There’s clear advice on what “yes”, “no”, and “abstain” actually mean, they take into account abstaining and undecided voters, there are set time limits and times to contact undecided voters, and they provide for a way to abort a poll if the wording of the proposal is ill-formed.

We had twenty years to figure out all those details, and one of the improvements above only landed a couple of months ago.
</aside>

We also didn’t have any consistent structure for community consultation, so it wasn’t clear how or when we should seek feedback.
A public RFC process may have helped with this, and would also help us collaborate on and document other decisions.

More personally, I did not participate in the extensive discussion in January and February that helped move consensus in the TSC towards allowing the non-code and Copilot exceptions until [fairly late](https://github.com/servo/project/blob/6dcfe4a26b034e0dccad2f4a31c1d797abcc8c82/governance/tsc/tsc-2025-02-24.md#ai-policy-review).
Some of that was because I was on leave, including for the vote on the initial Copilot “experiments”, but most of it was that I didn’t have the bandwidth.
Doing politics is hard, exhausting work, and there’s only so much of it you can do, even when you’re not wearing three other hats.

---

<a href="/images/generative-ai-in-servo.jpg"><img alt="a white and grey cat named Diffie, poking her head out through a sliding door" title="a white and grey cat named Diffie, poking her head out through a sliding door" src="/images/generative-ai-in-servo.jpg" style="width: 100%;"></a>

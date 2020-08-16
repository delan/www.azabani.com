---
layout: default
title: An open letter to Bitbucket about Mercurial
date: 2020-06-07 19:00:00 +1000
tags: home
---

In August 2019, the Bitbucket team announced that [they would “sunset” Mercurial](https://bitbucket.org/blog/sunsetting-mercurial-support-in-bitbucket) on 1 June 2020 (now 1 July 2020) by removing all Mercurial repositories and associated content.
I urge them to reconsider that approach with this open letter.

<hr>

Hi.
I’ve enjoyed using Bitbucket for a [long time](https://bitbucket.org/delan), though I’m pretty sure I joined after you [added Git support](https://bitbucket.org/blog/bitbucket-now-rocks-git), and I’m not afraid to [make other sites enjoy you too](https://github.com/rust-lang/crates.io/pull/1934).

The merits of discontinuing _active_ Mercurial support are their own can of worms.
I don’t really have a strong opinion there one way or another, and I’m sure you’ve heard more than enough about that in [your forum thread](https://community.atlassian.com/t5/x/x/ba-p/1155380), which received so many replies that I couldn’t read them all.

I have a passing interest in Mercurial (thanks to you), but that’s nothing compared to how much I care about digital preservation, that is to say, the long-term health of everything we create with our computers.

On this basis, I believe your approach is irresponsible.
I don’t have all the answers here, but there’s a lot of middle ground between “full Mercurial support forever” and “delete fucking everything”.
You can do better.

Let’s explore some of that middle ground, but first, an appeal.

## If nothing else…

[Archive Team](https://www.archiveteam.org) will start building a best-effort archive soon, [with or without your help](https://www.archiveteam.org/index.php?title=Bitbucket).
Please be nice to them, don’t block them, and have someone on your team take point on any questions or problems that come up.
You can reach them in #kickthebucket on [hackint](https://hackint.org), or [hit me up](/about/) and I can pass on some contact details.

If you’re not going to change your mind, it would be best to reach out to the people who live and breathe online digital preservation, above or at the [Internet Archive](https://archive.org/about/contact.php), and find out how you can make their work easier.
I would imagine that this could mean anything from passing on dumps of the underlying data to setting up redirects to an archive, but the opinions in this letter are my own.

## Why you should care

Leaving it up to third-party archivists to figure out how to scrape everything from a production service is far from ideal.
When this happens, it might not be easy (or even possible) for users to remove or supersede their archived content.
There are things that can’t be scraped of course, including private repos and some metadata like environment variables, but with some collaboration, there might be ways to preserve those safely too.

Placing the burden of migration on authors, while convenient and flexible, will effectively destroy the works of authors who aren’t around to defend them.
No author stays an active user forever, every author dies someday, and not all works will find a new maintainer before one of those things happen.

All of the recommended migration options destroy issues, pull requests, downloads, and Pipelines results, or at least [all of the links](https://www.w3.org/Provider/Style/URI) to them.
The raw commits are no substitute for the knowledge and history in that content.
Said archivists are working on [some](https://github.com/clach04/bitbucket_tools) [more complete tools](https://github.com/philipstarkey/bitbucket-hg-exporter), but even if they’re complete _tomorrow_, only you can prevent link rot.

## Build with heart and balance

There’s a difference between obligation and responsibility.
In the world [as we know it](https://en.wikipedia.org/wiki/Capitalism), your only strict obligations are to those who have paid you to do something.

When you build a medium for people to collaborate and share their works with the world, you have responsibilities to those works.
You can think of this as the price of inviting free users to build your platform and establish your place as a major competitor to that other service with the five-limbed feline mascot.

Our cultural output over the last century is in unprecedented danger of being lost forever, and yes, that includes code.
This isn’t a foregone conclusion though, and you have the power to shut down your service in a way that avoids destruction.

## More middle ground

You could step down to read-only access, potentially by converting the content to a static HTML format.
No one says read-only has to mean seamless integration with your evolving frontend, and if anything, everyone wins if you do it in a way that relieves you of having to think of compatibility with each change.

You could convert the repos to Git in place.
If you do nothing, authors are going to have to convert and/or relocate their repos anyway, but no matter what they choose, they lose all of their issues and other non-code content.
You are in a unique position to keep this content alive, as well as keep commit links working by, for example, redirecting Mercurial hashes to Git hashes.

[Google Code](https://code.google.com/archive/about) operated in the same space from 2006 to 2015, and even mentioned you in their [farewell post](https://opensource.googleblog.com/2015/03/farewell-to-google-code.html).
When that service shut down, every project was archived, including code, issues, wikis, and downloads.
Links were kept alive, like [this project link](https://code.google.com/p/xtideuniversalbios/).
Authors were given a way (albeit not a very convenient one) to remove archived projects, or set up redirects, after the archive date.

None of these options are easy, but I trust you to do the right thing and try.

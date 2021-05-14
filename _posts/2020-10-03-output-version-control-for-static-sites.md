---
layout: default
title: Output version control for static sites
date: 2020-10-03 23:00:00 +1000
tags: home jekyll
_preview_description: Do you use a static site generator? Here’s a way to ensure you only deploy the changes you expect!
---

I use [Jekyll], a static site generator that’s most notable for powering [GitHub Pages].
Two years ago, I noticed that the permalinks for several of my blog posts were broken by a Jekyll bug after I upgraded to Ruby 2.4.
I’ve since written a Git-based system to stop this kind of breakage from ever reappearing, which should be useful to anyone who uses a static site generator and wants to avoid corruption or inadvertent changes.

[Jekyll]: https://jekyllrb.com
[GitHub Pages]: https://pages.github.com

## The bug

You can read more about what happened in [the commit] where I first wrote the system, but in short, Jekyll used to suffer from [a bug] where the day a post gets filed under can vary depending on Ruby version… because time zones.

[the commit]: https://github.com/delan/www.azabani.com/commit/e9b43f305e16341003ec1710d09567359178fc1f
[a bug]: https://github.com/jekyll/jekyll/pull/6697

I was using an affected version, and when I upgraded to Ruby 2.4 with a new OS release, ten posts got “moved” to the next day.
It took me five months to notice this, and search engines had already adjusted to the damage.

I migrated my site from Jekyll 3.0.1 to 3.8.3, which wasn’t too hard thanks to the project’s [stability philosophy], but I also created some [static redirects] to keep the broken permalinks working, in case any backlinks were made during that time.

[stability philosophy]: https://jekyllrb.com/philosophy/#4-stability
[static redirects]: http://sebastians-pamphlets.com/google-and-yahoo-treat-undelayed-meta-refresh-as-301-redirect/

<figure markdown="1">
<figcaption><code>_layouts/legacy.html</code></figcaption>
<div class="scroll" markdown="1">
```html
<!doctype html><meta charset="utf-8">
<meta http-equiv="Refresh" content="0;
    URL={{ "{{" }} site.url }}{{ "{{" }} site.baseurl }}{{ "{{" }} content | strip_newlines }}">
```
</div>
</figure>

<figure markdown="1">
<figcaption><code>2014/01/03/forcing-single-timezone-jekyll.html</code></figcaption>
<div class="scroll" markdown="1">
```
---
layout: legacy
---
{{ "{%" }} post_url 2014-01-02-forcing-single-timezone-jekyll %}
```
</div>
</figure>

## The system

But anyway, back to the system.
The idea behind output version control is to track the actual files that get served, so when we want to generate and deploy a new version of our site, we can see how the site would actually change.

The whole system is powered by a makefile, which sets up a special Git repository at `_staging` that tracks the site generator’s output.
This repo is unrelated to any Git repo we might be using for the *source* of the site, so it will never get confused by branches or refactoring.

`_staging` lets you examine the changes that would be made by deploying your site.
If you’re happy with the changes, we clone the repo to `_production`, so to use this system, reconfigure your web server to serve your site from `_production/_site`, rather than `_site` or wherever your site generator writes to.

Let’s read it together.
I like to put `.POSIX:` [on the first line] out of habit, though strictly speaking our use of `.PHONY:` makes this [not a portable makefile] anyway.
`BUNDLE` lets us override how we run [Bundler], like `make BUNDLE=bundle24` on OpenBSD for example.

[on the first line]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html#tag_20_76_13_04
[not a portable makefile]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html#tag_20_76_03
[Bundler]: https://bundler.io

```makefile
.POSIX:

BUNDLE = bundle
```

When we `make dry` or `make` with no targets, generate the site into `_site`, copy `_site` to the output repo’s working tree, check if the index is dirty, and copy the working tree to the index.
Our use of the index is interesting here.
By checking and bailing out if the index is dirty, we’re forced to either deploy or reject any previously staged changes, which might prevent accidental data loss.

```makefile
dry: _staging
	$(BUNDLE) exec jekyll build
	rsync -a --delete _site _staging
	git -C _staging diff --cached --quiet
	git -C _staging add _site
```

When we `make examine`, display the staged changes as a diff between HEAD and the index, so we can decide whether we’re happy with them.

```makefile
examine: _staging
	git -C _staging diff --cached
```

When we `make deploy`, commit the changes as the new HEAD, then update the clone at `_production` to reflect them.

```makefile
deploy: _staging _production
	git -C _staging commit --allow-empty --allow-empty-message -m ''
	git -C _production pull
```

When we `make reject`, throw away the staged changes by resetting the index to HEAD.
In this situation, as well as when `make dry` bails out, the working tree could still be dirty.
While we could clean it with `--hard` and `git clean -dffx`, we don’t *need* to, because we only ever copy the working tree to the index after completely rewriting it with rsync(1).

```makefile
reject: _staging
	git -C _staging reset
```

To set up `_staging` for the first time, create the directory and make it a Git repo.
To set up `_production` for the first time, clone `_staging` as a Git repo.

```makefile
_staging:
	mkdir -p -- '$@'
	cd -- '$@' && git init

_production:
	git clone _staging _production
```

Never skip the commands under `dry` + `examine` + `deploy` + `reject` based on modified times, even if there happens to be a file with one of those names in the site’s sources.
`.PHONY:` isn’t yet in the [POSIX spec], but it has widespread support, including the GNU and OpenBSD implementations.

[POSIX spec]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html

```makefile
.PHONY: dry examine deploy reject
```

That’s all there is to it!
Is this the perfect system?
No, but it suffices for my needs.

### Limitations

If your site’s output has non-deterministic parts, those parts can make the output of `make examine` noisy.
The one example I’ve encountered is [jekyll-feed]’s &lt;updated> tags, when I added Atom feeds [a few months ago].
You could probably fix this with [textconv or an external diff command].

[jekyll-feed]: https://github.com/jekyll/jekyll-feed
[a few months ago]: https://github.com/delan/www.azabani.com/commit/113a37f7e712ddc626f04039474e723620f33b3f
[textconv or an external diff command]: https://git-scm.com/docs/gitattributes#_performing_text_diffs_of_binary_files

We can, of course, access older versions of our site’s output with `git -C _production`, but the system as described doesn’t store the inputs that they were generated from (or even hints as to where we can find them, like commit hashes).
Feel free to implement this, but note that your site’s sources aren’t necessarily the only relevant input!
For example, the inputs that broke my permalinks were my Ruby and Jekyll versions.

`_production` and `_staging` will store an unbounded amount of history, so if you need to reclaim space, you’ll want to use something like `git rebase -i --root` to squash old commits followed by a `git gc`.

There’s still a lot of unnecessary overhead.
The initial clone to `_production` uses hard links but subsequent pulls don’t, so we should probably use rsync(1) rather than cloning `_staging`.
When the output advances to `_staging` and then to `_production`, we can also delete the redundant copies in `_site` and then in `_staging`.

There’s no easy way for `make examine` to accept additional arguments, such as `--word-diff`, that are then passed to `git diff --cached`.
If we used a shell script instead of a makefile, this wouldn’t be a problem:

```sh
action="$1"; shift

case "$action" in
    (examine) git -C _staging diff --cached "$@" ;;
    # ...
esac
```

## B-side: incremental builds

I’ve got a thing for using secondary Git repositories in project tooling.
When I worked at Atlassian, I wrote an incremental build system for [Maven] using a similar technique.
Maven doesn’t support incremental builds out of the box, but `mvn -pl x,y,...` tells [the reactor](https://maven.apache.org/guides/mini/guide-multiple-modules.html#the-reactor) to only try to build a subset of our project’s modules. If we could figure out which modules need to be rebuilt, we can implement coarse-grained incremental builds!

[Maven]: https://maven.apache.org

In this case, the secondary Git repo, which I call a “shadow repo”, tracks the inputs rather than the outputs.
But Delan, you ask, doesn’t the primary repo already do that?
Kind of, but the user (i.e. one of my colleagues) is constantly messing around with it, and it’s difficult to implement robust incremental builds atop a repo that we don’t control, because we have no way of knowing what the inputs were *during the last successful build*.
The system I replaced tried anyway, and it got confused by everything from dirty indexes and working trees to the user switching branches.

My new system roughly worked as follows.
We create the shadow repo, which is `--bare` to avoid the redundant working tree.
To interact with it, we point `GIT_DIR` to the shadow repo and `GIT_WORK_TREE` to the real repo’s working tree.

```sh
#!/bin/sh
set -eu

top="$(git rev-parse --show-toplevel)" || exit 66
git init --bare -- "$top/.shadow/repository"

shadow() {
    GIT_DIR="$top/.shadow/repository" GIT_WORK_TREE="$top" git "$@"
}
```

Before each build attempt, we copy everything except build outputs to the index, thanks to the project’s own gitignore(5), and get a list of paths that have changed since the last successful build (HEAD).

```sh
shadow add -- "$top"
shadow status -z
```

We then convert the list of paths to a set of Maven modules, by finding their nearest ancestors containing a pom.xml, then pass that set to `mvn -am -pl`.
I no longer have any of the original source code, so I’ll leave this as an exercise for the reader.

If and only if the build succeeds, we commit the new build inputs.
We get those from the index, which also prevents false negatives in the next build attempt, were the user to have edited any files during the build process.

```sh
commit() {
    shadow commit -m '' --allow-empty --allow-empty-message "$@"
}

commit --amend || commit
```

## Closing thoughts

I hope you found that interesting!
Perhaps you’ll even see Git in a new light, finding ways to use the stupid content tracker™ other than version control for source code.

I’ve been afraid to check if anyone has done this before, because I felt like if I was *aware* of any prior art, I would lose my enthusiasm for solving this problem and writing about it.
But now that I’m done, that doesn’t matter anymore.
Let me know if great minds think alike!

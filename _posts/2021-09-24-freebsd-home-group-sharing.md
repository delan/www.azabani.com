---
layout: default
title: Group sharing on a FreeBSD home server
date: 2021-09-24 23:30:00 +0800
tags: home
_preview_description: “Or, a 2500-word journey where I figure out how to change one bit.”
_footer_twitter: https://twitter.com/dazabani
---

My partner and I share a home server for our storage needs, running on FreeBSD 12 with ZFS.
We have our own users, delan and aria, and a group (delanria) that *in theory* we can use for common areas, like our software collection.
Services like torrent clients and media libraries have their own users too, and all of these users need to write to things others have created.
This was easier said than done.

* [Unix permissions 101](#unix-permissions-101)
    * [Ownership and creation](#ownership-and-creation)
* [Shared storage](#shared-storage)
* [Login classes](#login-classes)
* [Fixing sudo(8)](#fixing-sudo)
* [Fixing services](#fixing-services)
* [Fixing samba(8)](#fixing-samba)
* [Funny execute bits](#funny-execute-bits)
* [What did we learn?](#what-did-we-learn)

## Unix permissions 101

Files are owned by a user (the owner) and a group (the group).
Users belong to groups, and each group they join grants them access to any files owned by that group.
Processes run as a user (euid) and a group (egid), more or less.

Traditional permissions for files consist of twelve bits: nine for whether the owning user (u), owning group (g), and others (o) can read (r), write (w), or execute (x); three for controlling execution behaviour.
Of the latter three, setuid (u+s) makes the file run with its owning user as euid, setgid (g+s) does that for owning group and egid, and sticky (t) was mostly [only used historically].

[only used historically]: https://en.wikipedia.org/wiki/Sticky_bit#History

Directories repurpose the execute bits for “search”, which essentially means whether you can blindly access children (subject to the children’s permissions).
This is distinct from the read bits, which control whether you can list children, and write bits, for creating and deleting children.
They also repurpose the sticky bit for “restricted deletion”, where children can only be deleted by their owners, rather than anyone who can write to the directory (useful for /tmp).

This permission model frankly sucks.
It’s clear that these twelve bits are a messy and leaky abstraction over filesystem access rights.
But I’ve never used ACL:s outside of Windows, and I don’t intend to change that any time soon.
I know that ls(1) indicates ACL:s with a plus (drwxrwxrwx+), that there are apparently “POSIX” and “NFS” flavours of ACL:s, and… that’s pretty much it.

### Ownership and creation

When you create a file, it’s owned by you (euid), but the owning group depends.
Unfortunately, sometimes it’s your “current” group (egid), which is controlled by newgrp(1) and defaults to your “login” group, which is usually something like “users” or “staff” or a group with the same name as your user.

FreeBSD makes group ownership of directories easy, because new files always inherit the owning group, so that “sometimes” is never! But on Linux, they’re only inherited when the parent is setgid, and otherwise take their owning group from you (egid).

Unix requires the nine main permission bits upfront when creating a file or directory, and convention is for programs that don’t know or care about these bits to give 666<sub>8</sub> (u+rw, g+rw, o+rw) or 777<sub>8</sub> (u+rwx, g+rwx, o+rwx) respectively.

<figure><div class="scroll" markdown="1">
```c
// create a directory (u+rwx, g+rwx, o+rwx)
mkdir("path/to/foo", 0777);
// create an executable file (u+rwx, g+rwx, o+rwx)
creat("path/to/bar", 0777);
// create a non-executable file (u+rw, g+rw, o+rw)
creat("path/to/baz", 0666);
```
</div></figure>

The bits are then filtered by the *umask*, an environmental setting that almost always defaults to 022<sub>8</sub> (g-w, o-w).
This is where the common permissions of 644<sub>8</sub> (u+rw, g+r, o+r) for files and 755<sub>8</sub> (u+rwx, g+rx, o+rx) for directories comes from.

<figure><div class="scroll" markdown="1">
```
$ ls -l path/to
drwxr-xr-x  [...]  foo
drwxr-xr-x  [...]  bar
drw-r--r--  [...]  baz
```
</div></figure>

## Shared storage

Let’s say we have some groups.

<figure><div class="scroll" markdown="1">
```
$ rg delan,aria /etc/group
wheel:*:0:root,delan,aria
delanria:*:1003:delan,aria
sonarr:*:351:delan,aria
radarr:*:352:delan,aria
_sabnzbd:*:350:delan,aria,sonarr,radarr
qbittorrent:*:850:delan,aria,sonarr,radarr
```
</div></figure>

Let’s also say I have a notes directory and a software directory, both of which are shared with my partner including write permissions (g+w).

<figure><div class="scroll" markdown="1">
```
$ ls -la /ocean/notes
drwxrwxr-x  [...]  delan  delanria  [...]  .

$ ls -la /ocean/software
drwxrwxr-x  [...]  delan  delanria  [...]  .
drwxrwxr-x  [...]  delan  delanria  [...]  accounting
drwxrwxr-x  [...]  delan  delanria  [...]  benchmarks
drwxrwxr-x  [...]  delan  delanria  [...]  drivers
                                           ...
```
</div></figure>

When adding a new note, or adding a category of software, the immediate problem we run into is that a umask of 022<sub>8</sub> (g-w, o-w) makes the new directory group-read-only (g+rx).

<figure><div class="scroll" markdown="1">
```
delan@storage$ echo bread > /ocean/notes/buy
delan@storage$ mkdir /ocean/software/fonts
aria@storage$ echo soul > /ocean/notes/sell
aria@storage$ mkdir /ocean/software/games

$ ls -ld /ocean/notes/{,buy,sell}
drwxrwxr-x  [...]  delan  delanria  [...]  .
-rw-r--r--  [...]  delan  delanria  [...]  buy
-rw-r--r--  [...]  aria   delanria  [...]  sell

$ ls -ld /ocean/software/{,fonts,games}
drwxrwxr-x  [...]  delan  delanria  [...]  .
drwxr-xr-x  [...]  delan  delanria  [...]  fonts
drwxr-xr-x  [...]  aria   delanria  [...]  games
```
</div></figure>

This prevents the other partner from changing notes or adding software, unless we periodically “fix up” the permissions in common areas.

<figure><div class="scroll" markdown="1">
```
delan@storage$ echo out >> /ocean/notes/sell
zsh: permission denied: out

aria@storage$ cd /ocean/software/games
aria@storage$ curl -sSO https://riot.example.com/valorant.exe
curl: (23) Failure writing output to destination

$ chmod -R g+w /ocean/{notes,software}
```
</div></figure>

## Login classes

We can avoid these problems by setting our umask to 002<sub>8</sub> (o-w), which is controlled by each user’s login class.
In my login.conf(5), many settings are defined only in the “default” login class, including the umask, which are directly inherited by the other classes.

<figure><div class="scroll" markdown="1">
```
$ cat /etc/login.conf
default:\
	:passwd_format=sha512:\
	:...:\
	:umask=022:
standard:\
	:tc=default:
daemon:\
	:...:\
	:tc=default:
...
```
</div></figure>

Put a pin in the line with “passwd_format”, we’ll need that later.

If we change the umask setting and rebuild, logging in yields the expected umask, fixing the scenarios above… except when switching users with sudo(8).
Switching users with su(1) *via* sudo(8) works as expected, so what gives?

<figure><div class="scroll" markdown="1">
```
# vim /etc/login.conf
# cap_mkdb /etc/login.conf
# su -l delan
delan@storage$ umask
002

delan@storage$ sudo -iu aria umask
022

delan@storage$ sudo su -l aria -c 'umask'
002
```
</div></figure>

<h2 id="fixing-samba">Fixing sudo(8)</h2>

At first, the only way we can get the expected umask when switching users with sudo(8) is to explicitly ask for a login class, such as the user’s default class:

<figure><div class="scroll" markdown="1">
```
delan@storage$ sudo -iu aria -c - umask
002
```
</div></figure>

This is because of defaults for three [sudoers(5) settings]: use_loginclass, umask_override, and umask.
These settings mean that sudo(8) forms the new umask as follows.

[sudoers(5) settings]: <https://man.freebsd.org/sudoers(5)>

use_loginclass is off, so we start by taking our umask from the environment in which sudo was invoked, in this case, 002<sub>8</sub>.
umask_override is off, so our next step will do a bitwise OR, rather than replacing our umask entirely.
The umask setting is 022<sub>8</sub>, so our final umask is 002<sub>8</sub> OR 022<sub>8</sub>, which is… well… 022<sub>8</sub>.

To fix this, we can turn use_loginclass on, which usually[^1] takes our initial umask from the user’s default login class, or turn the umask setting off, which tells sudo(8) not to modify that initial umask.

[^1]: If the umask setting is *explicitly* set (other than to turn it off), then the initial umask is always taken from the invoking environment, not login classes as you might expect from turning use_loginclass on. This includes explicitly setting it to 022<sub>8</sub>, and yes, that means your 022<sub>8</sub> and the default 022<sub>8</sub> are different. sudo(8) is complicated.

<figure><div class="scroll" markdown="1">
```
Defaults use_loginclass  # option 1: use_loginclass on
Defaults !umask          # option 2: umask off

# option 3: umask off, but in a way that makes no sense
# (seriously, sudo authors, why did you add this case?
#  this just makes it impossible to actually set 0777!)
Defaults umask=0777
```
</div></figure>

## Fixing services

According to the [rc.subr(8) manual](<https://man.freebsd.org/rc.subr(8)>), services ostensibly use the “daemon” login class by default.
But despite setting the umask in all of our login classes to 002<sub>8</sub> (o-w), services like *qbittorrent* and *sabnzbd* continue to create things group-read-only.
Once again, what gives?

As the manual says, the ${name}_login_class is used with ${name}_limits.
The former points to a login class containing our initial set of resource limits, and the latter overrides those limits, by way of limits(1).
Indeed, if we look under the hood, the login class is *only* ever used in the arguments passed to limits(1).

<figure><div class="scroll" markdown="1">
```
$ rg _login_class /etc/rc.subr
786:#   ${name}_login_class n   Login class to use, else "daemon".
969:        _prepend=\$${name}_prepend  _login_class=\${${name}_login_class:-daemon} \
1124:                   _doit="$_cd limits -C $_login_class $_limits $_doit"
```
</div></figure>

But resource limits aren’t the only settings defined by login classes, which as we saw earlier, also says things like “passwd_format is sha512”!
So this begs the question: is umask considered a resource limit for the purposes of limits(1)?

<figure><div class="scroll" markdown="1">
```
root@storage$ umask 000; ulimit 69
root@storage$ limits sh -c 'umask; ulimit'
0000
69

root@storage$ limits -C daemon sh -c 'umask; ulimit'
0000
unlimited
```
</div></figure>

No.
In fact, not only is the umask of the “daemon” login class not consulted when running a service, but rc(8) and init(8) themselves don’t even run in a login class.
You can see the former for yourself by adding a couple of lines to /etc/rc and rebooting.

<figure><div class="scroll" markdown="1">
```
$ head -2 /etc/rc
#!/bin/sh
umask=$(umask)          # add this

$ tail -2 /etc/rc
echo "umask is $umask"  # add this
exit 0
```
</div></figure>

As for the latter, you can write a script that spews out the umask, then reboot and tell loader(8) to tell init(8) to immediately exec that script.

<figure><div class="scroll" markdown="1">
```
$ sudo chmod +x /root/umask
$ cat /root/umask
#!/bin/sh
while :; do umask; done

loader> set init_exec=/root/umask
loader> boot
```
</div></figure>

In both cases, the umask is 022<sub>8</sub> (g-w, o-w).
This is because login classes aren’t magic, nor are they omnipotent!
The only processes subject to them are those spawned by login(1), or things like login(1)[^3], such as su(1), sudo(8), or sshd(8).

[^3]: More precisely, things that call [setusercontext(8)](<https://man.freebsd.org/setusercontext(8)>) or [setclasscontext(8)](<https://man.freebsd.org/setusercontext(8)>) with flags containing LOGIN_SETUMASK.

All other processes ultimately inherit their umask from the “kernel” process (pid 0), whose umask is hardcoded to, you guessed it, 022<sub>8</sub> (g-w, o-w).

<figure><div class="scroll" markdown="1">
```c
// sys/kern/init_main.c
static void
proc0_init(void *dummy __unused)
{
	struct proc *p;
	// [...]
	p->p_pd = pdinit(NULL, false);
	// [...]
}

// sys/kern/kern_descrip.c
struct pwddesc *
pdinit(struct pwddesc *pdp, bool keeplock)
{
	// [...]
	newpdp->pd_cmask = CMASK;
	// [...]
}

// sys/sys/param.h
#define	CMASK	022		/* default file mask: S_IWGRP|S_IWOTH */
```
</div></figure>

So getting back on task, how do we run our services with another umask?
One way might be to add a line setting the umask to the beginning of /etc/rc, but this is rather drastic, and the security of this… smells questionable.

[The solution I’ve settled on] is to sneak a umask command into the per-service rc.conf(5) for specific services.
This works because in rc.subr(5), load_rc_config executes /etc/rc.conf “if it has not yet been read in” (whatever that means), then executes /etc/rc.conf.d/foo if it exists.
Most of the time, these files contain variables only, but they’re just shell scripts.
It’s shell scripts all the way down.

[The solution I’ve settled on]: https://forums.freebsd.org/threads/setting-umask-on-daemon.75069/

<figure><div class="scroll" markdown="1">
```
$ ls -l /etc/rc.conf.d
-rw-r--r--  [...]  _umask
lrwxr-xr-x  [...]  qbittorrent -> _umask
lrwxr-xr-x  [...]  radarr -> _umask
lrwxr-xr-x  [...]  sabnzbd -> _umask
lrwxr-xr-x  [...]  sonarr -> _umask

$ cat /etc/rc.conf.d/_umask
umask 002
```
</div></figure>

<h2 id="fixing-samba">Fixing samba(8)</h2>

That rc.conf(5) hack doesn’t work for samba(8), where the umask that applies to things created by clients is controlled by internal configuration, just like sudo(8).
In this case, “create mode” and “directory mode” are the settings to change.

<figure><div class="scroll" markdown="1">
```
[global]
create mode = 0775     # like umask 002
directory mode = 0775  # like umask 002
```
</div></figure>

While we’re at it, if you want to set execute bits on all new files, you can use “force create mask”.
Aria likes this, but I’m not so sure.

<figure><div class="scroll" markdown="1">
```
[global]
# force create mode = 0111  # like ugo+x
```
</div></figure>

## Funny execute bits

At this point, it looked like we were done, but something caught my eye when Aria created some files for testing.
The files had owning user execute (u+x), but not the other two execute bits.
For the last bloody time, what gives?

<figure><div class="scroll" markdown="1">
```
$ ls -l
-rwxrw-r--  [...]  aria  delanria  [...]  foo.txt
```
</div></figure>

Turns out there’s an old samba(8) feature that repurposes the three execute bits for the three legacy DOS attributes respectively: archive, system, hidden.
The setting for the first execute bit (“map archive”) is on by default, and Windows had created the file with the archive bit on, hence owning user execute (u+x)!

Nowadays extended attributes are a better way to store those attributes, which is on by default as “store dos attributes”.
But I was worried that I would need to do something messy like vfs_streams_xattr(8), remembering that FreeBSD and ZFS don’t support xattrs, at least not until FreeBSD 13.
After all, ZFS says that they’re not supported!

<figure><div class="scroll" markdown="1">
```
root@storage$ zfs set xattr=on ocean
property 'xattr' not supported on FreeBSD: permission denied
```
</div></figure>

Turns out [that error](https://forums.freebsd.org/threads/state-of-zfs-xattr-support-in-freebsd.55418/) [is misleading](https://unix.stackexchange.com/q/266913), and xattrs more or less work fine.

<figure><div class="scroll" markdown="1">
```
root@storage$ lsextattr user foo.txt
foo.txt DOSATTRIB

(archive bit only)
root@storage$ getextattr -x user DOSATTRIB foo.txt
foo.txt 00 00 04 00 04 00 00 00 51 00 00 00 20
> 00 00 00 44 a8 2c de 2d b1 d7 01 44 a8 2c de
> 2d b1 d7 01

(archive + system + hidden)
root@storage$ getextattr -x user DOSATTRIB foo.txt
foo.txt 00 00 04 00 04 00 00 00 51 00 00 00 23
> 00 00 00 44 a8 2c de 2d b1 d7 01 44 a8 2c de
> 2d b1 d7 01

(none of those attributes)
root@storage$ getextattr -x user DOSATTRIB foo.txt
foo.txt 00 00 04 00 04 00 00 00 51 00 00 00 00
> 00 00 00 44 a8 2c de 2d b1 d7 01 44 a8 2c de
> 2d b1 d7 01
```
</div></figure>

To top it all off, the smb.conf(5) manual says that “store dos attributes” *should* have automatically disabled the execute-bit-based attribute mapping, but they actually don’t.
I guess the manual was wrong.

<figure><div class="scroll" markdown="1">
```
[global]
map archive = no
map system = no
map hidden = no
```
</div></figure>

## What did we learn?

FreeBSD gives us owning group inheritance for free, but inheriting the group-writable bit requires changing the umask.
This can be done for human use by way of the login classes in login.conf(5), with special tweaks needed for sudo(8), but services only use login classes for resource limits, not the umask, which has a hardcoded default of 022<sub>8</sub> (g-w, o-w).

Most services can have the desired umask set imperatively in /etc/rc.conf.d, but samba(8) needs to be configured with its own “create mask” and “directory mask” settings.

When in doubt, read the source code.

<hr>

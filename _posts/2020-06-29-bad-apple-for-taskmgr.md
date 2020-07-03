---
layout: default
title: Bad Apple!! for taskmgr
date: 2020-06-30 05:00:00 +1000
tags: home
---

[Bad Apple!!] is a Touhou song whose [music video] has been described as [“the doom of music videos”], because it’s been played on [everything] from [string lights] to [oscilloscopes].
This post is about that video, writing an improved “video player” for Task Manager’s CPU graphs, and using virtual machines to push my feeble hardware to the limit.

[Bad Apple!!]: https://en.wikipedia.org/wiki/Bad_Apple!!
[music video]: https://www.youtube.com/watch?v=FtutLA63Cp8
[“the doom of music videos”]: https://twitter.com/Clipsey5/status/1276287929447579648
[everything]: https://twitter.com/marcan42/status/1273964930618646528
[string lights]: https://twitter.com/Reif_FHI/status/1069150346289659904
[oscilloscopes]: https://twitter.com/marcan42/status/1042376140512538625

<style>
/* :root { font-size: 20px; } */
article { word-wrap: break-word; }
figure { text-align: center; }
figcaption { font-size: 0.75em; }
.local-video { max-width: 100%; }
.local-commit-container { margin-right: -1.6em; padding-right: 1.4em; border-right: 0.2em solid rgba(102,51,153,0.5); }
.local-commit { line-height: 2; margin-right: -2.5em; text-align: right; }
.local-commit > img { width: 2em; vertical-align: middle; }
.local-commit > a { padding-right: 0.5em; text-decoration: none; color: rebeccapurple; }
.local-commit > a > code { font-size: 1em; }
.local-commit-none > a { color: rgba(102,51,153,0.5); }
</style>

<figure>
    <p><iframe class="local-video" width="560" height="315" src="https://www.youtube-nocookie.com/embed/hMGM6s1Qw_Q" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe></p>
    <figcaption>I definitely cherry-picked that thumbnail, not gonna lie.</figcaption>
</figure>

## Prior art

The idea started in March, with a [video] that appeared to play it on an AMD 3990X, but that one [turned out to be “fake”], at least in the sense that it relied heavily on [video editing].
More recently, [@kbeckmann] and [@winocm] played it over 64 and 128 processors, which at first inspired me to replicate what they did, and pretty soon I wanted to bring something new to the table.

[video]: https://twitter.com/marcan42/status/1273957984243027968
[turned out to be “fake”]: https://twitter.com/marcan42/status/1273957984243027968
[video editing]: https://en.wikipedia.org/wiki/Adobe_After_Effects

[@kbeckmann]: https://twitter.com/kbeckmann/status/1275835614529806348
[@winocm]: https://twitter.com/winocm/status/1276037359503466497

The biggest obstacle for me was hardware.
The “shaded tiles” style of CPU graphs only kick in when you have 64 or more processors, but my main machine [only has eightish], and my laptop [only has twelvish].
There’s a whole spectrum of approaches I could choose from:

* Using video editing to render an imitation (already done)
* Modifying taskmgr’s memory to feed it fake activity numbers
* Using a virtual machine to Download More Cores
* Just recording it on real hardware (already done)

[only has eightish]: https://ark.intel.com/content/www/us/en/ark/products/80915/intel-xeon-processor-e3-1276-v3-8m-cache-3-60-ghz.html
[only has twelvish]: https://ark.intel.com/content/www/us/en/ark/products/191045/intel-core-i7-9750h-processor-12m-cache-up-to-4-50-ghz.html

I’m really into virtualisation, so I decided to solve this with libvirt and KVM.
While I could probably ask [Igalia] to let me run a guest on one of their 128-thread build boxes, I was interested in a challenge, driven by the same urge as when I [built a home router] out of an old Pentium III[^1].
That turned out to be challenging and interesting, and I’m surprised I was able to mitigate enough of the problems that the result was worth sharing.

[Igalia]: https://www.igalia.com
[built a home router]: {% post_url 2015-08-06-modern-openbsd-home-router %}
[^1]: [I still use that router] at home today, almost five years later, and I’m only planning to decommission it because I recently upgraded to gigabit internet, which the poor thing just can’t keep up with.
[I still use that router]: https://bitbucket.org/delan/daria.daz.cat

## Getting started

[My main Windows install] is a libvirt guest with GPU passthrough, so at first I tried the path of least resistance.
I cranked up the CPU topology, rebooted, and… it struggled, taking several minutes to reach the login screen.

I figured that such an extreme overcommitment might be fine *after* boot, and the only problem was booting that way, so I tried CPU hotplug, but nothing happened.
While Windows Server apparently got an update that fixed hotplug, and Windows 10 also received that update, that didn’t mean that Windows 10 supports hotplug.

[My main Windows install]: https://bucket.daz.cat/e768982969270172.xml

<figure>
    <a href="/images/badapple-1.png"><img src="/images/badapple-1.png" width="100%"></a>
    <figcaption>What I would have seen if there was any justice in this world.</figcaption>
</figure>

I put together a Windows Server 2019 guest, and at last I could use CPU hotplug!
But the guest also booted fine with the overcommitment in place (or at least it does now, if I’ve got my timeline wrong).
Perhaps the sheer lack of crap it had to load, by virtue of being a fresh install *and* Windows Server, did the trick.

I turned off the malware scanner for good measure.

## The black screen phase

[My video player] has its roots in @kbeckmann’s [bad_cpu.py], so let’s start there.
The latter spawns a process for each “pixel” of the CPU graph, each of which sets its [affinity] to one CPU, then spins and sleeps as a kind of [pulse-width modulation] over CPU activity, just like a microwave or (some types of) dimmer switch.

[My video player]: https://bitbucket.org/delan/badapple.rs
[bad_cpu.py]: https://gist.github.com/kbeckmann/41254cc559ee4917913e522cc529a4e5
[affinity]: https://en.wikipedia.org/wiki/Processor_affinity
[pulse-width modulation]: https://en.wikipedia.org/wiki/Pulse-width_modulation

Sadly bad_cpu.py doesn’t scale beyond 64 processors without modifications, because of how the Windows API communicates affinity.
Since the dawn of time, affinity has been represented as a [register-width bit mask].
Windows is big on backwards compatibility, so when support for more than 64 (or 32) processors was introduced, the developers introduced the concept of [processor groups].

[register-width bit mask]: https://docs.microsoft.com/en-us/windows-hardware/drivers/kernel/interrupt-affinity-and-priority#about-kaffinity
[processor groups]: https://docs.microsoft.com/en-us/windows/win32/procthread/processor-groups

[The library we were using] didn’t provide a way to change processor group affinity, [Python’s bindings for the Windows API] didn’t include [SetThreadGroupAffinity], and even if it did, what if the interpreter creates other threads than the one GetCurrentThread would give us a handle for?

[The library we were using]: https://pypi.org/project/psutil/
[Python’s bindings for the Windows API]: https://pypi.org/project/pywin32/
[SetThreadGroupAffinity]: https://docs.microsoft.com/en-us/windows/win32/api/processtopologyapi/nf-processtopologyapi-setthreadgroupaffinity

<div markdown="1" class="local-commit-container">

<!-- git log --reverse --abbrev=13 --pretty=tformat:'<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/%H"><code>%h</code></a><img src="/images/badapple-commit-dot.svg"></div>%n%ad    %s%n' -->

That’s when I decided to Rewrite It In Rust. As far as Windows was concerned, this initially involved three things:

1. [GetLogicalProcessorInformationEx] to find out what the processor groups are
2. [InitializeProcThreadAttributeList] and [UpdateProcThreadAttribute] to wrap each processor group affinity value in some fancy paper and a bow
3. [CreateRemoteThreadEx] to create each pixel thread with its affinity value

[GetLogicalProcessorInformationEx]: https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlogicalprocessorinformationex
[InitializeProcThreadAttributeList]: https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-initializeprocthreadattributelist
[UpdateProcThreadAttribute]: https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-updateprocthreadattribute
[CreateRemoteThreadEx]: https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createremotethreadex

I struggled with steps one and two for most of Friday.

GetLogicalProcessorInformationEx is named after [GetLogicalProcessorInformation], a similar function that doesn’t support processor groups.
The latter had an example, from which I learned that it writes an array of fixed-size structures, so I assumed that this was also true for the former, but when I tried calling the function, I got nonsense.
It wasn’t until I found [this usage in the wild] that I learned the newer function writes an array of *variable-size* structures!

[GetLogicalProcessorInformation]: https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlogicalprocessorinformation
[this usage in the wild]: https://github.com/GPUOpen-LibrariesAndSDKs/cpu-core-counts/blob/7c2329aa7109c4d26f83d44f9a422524a63dac82/windows/ThreadCount-Win7.cpp

While it was clear that our affinity values had to outlive the attribute lists that wrapped them, it was unclear whether the attribute lists had to outlive the threads they were used to create.
I eventually [tried to do both], but I don’t think my approach guaranteed that they wouldn’t move.
I couldn’t figure out how to [Pin] them, nor was I even sure whether that was the appropriate tool.

[tried to do both]: https://bitbucket.org/delan/badapple.rs/src/e18f7dbf69c07fe153f5536847bf69a9e03d5777/src/windows.rs?at=trunk#lines-53:59
[Pin]: https://doc.rust-lang.org/std/pin/struct.Pin.html

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/c8cba094f63d3e3746de271bb787ae1fedcad1ac"><code>c8cba094f63d3</code></a><img src="/images/badapple-commit-dot.svg"></div>

<div class="local-commit local-commit-none"><a href="https://bitbucket.org/delan/badapple.rs/commits/7d01d8501f5fbefb0e7992acc86b698dd43d98cd"><code>7d01d8501f5fb</code></a><img src="/images/badapple-commit-none.svg"></div>

By the end of Friday, I got some test patterns going, but I was disappointed to see that the percentages were distorted downwards, making pixels too light, when too many pixels needed to be dark.
Migrating the virtual machine to my laptop helped, but not enough.

<figure>
    <a href="/images/badapple-2.png"><img src="/images/badapple-2.png" width="50%"></a
    ><a href="/images/badapple-3.png"><img src="/images/badapple-3.png" width="50%"></a>
    <figcaption>12/240 versus 120/240 pixels at 50%.</figcaption>
</figure>

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/bd5e068fbba66093f232ff8f374c9df574c6caf8"><code>bd5e068fbba66</code></a><img src="/images/badapple-commit-dot.svg"></div>

<div class="local-commit local-commit-none"><a href="https://bitbucket.org/delan/badapple.rs/commits/74dbca8ca6ae387c3f467ebcda2302de546f2930"><code>74dbca8ca6ae3</code></a><img src="/images/badapple-commit-none.svg"></div>

<div class="local-commit local-commit-none"><a href="https://bitbucket.org/delan/badapple.rs/commits/78ef5a58cf994fe69228de49b038fbb9daa637bb"><code>78ef5a58cf994</code></a><img src="/images/badapple-commit-none.svg"></div>

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/1a837711be0d46188bb8cccd2faf3240bde14552"><code>1a837711be0d4</code></a><img src="/images/badapple-commit-dot.svg"></div>

<div class="local-commit local-commit-none"><a href="https://bitbucket.org/delan/badapple.rs/commits/32cddabdc67712dfb1cda0f3b87d2d0e2670312c"><code>32cddabdc6771</code></a><img src="/images/badapple-commit-none.svg"></div>

From there, implementing external video input was easy, probably the easiest part of the project.
Slurp up the file, throw in a couple of loops with Rust’s wonderful [ChunksExact], and dole out each pixel to the appropriate vector.

[ChunksExact]: https://doc.rust-lang.org/std/primitive.slice.html#method.chunks_exact

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/55dade1bcfcac5752ff669f14db45e7afe8bc789"><code>55dade1bcfcac</code></a><img src="/images/badapple-commit-dot.svg"></div>

## Performance tuning

Having seen disappointing results from both bad_cpu.py and my new player, at first I looked beyond the code for solutions.
The ideas I came up with fell into three buckets:

* **Messing around with schedulers**, be it on the guest ([α][α] [β][β] [γ][γ] [δ][δ]) or the host ([ε]). I didn’t know enough to come up with *informed* ideas, so I didn’t get very far.
* **Optimising the virtual machine**, based on the same advice that I heed from [the VFIO community] and [their resources]. libvirt’s defaults are generally top notch, but it still leaves room for tweaks like switching to 1 GiB static huge pages and removing the memory balloon. That said, nothing had an effect to write home about.
* **Pinning the guest threads**, which I’ve pulled into its own dot point because it *did* have a notable effect. *Massive* and *negative*. This is a common tweak for normal guests that aren’t oversubscribed, but here? The guest performance tanked like it did when I tried to overcommit my main install, and CPU hotplug just delayed the tanking. Even without nohz_full (which I later learned [was a silly idea] when overcommitting pins). Even without rcu_nocbs. Even without isolcpus or [cset shield].

[α]: https://www.microsoftpressstore.com/articles/article.aspx?p=2233328&seqNum=7
[β]: http://recoverymonkey.org/2007/08/17/processor-scheduling-and-quanta-in-windows-and-a-bit-about-unixlinux/
[γ]: https://docs.microsoft.com/en-us/windows/win32/procthread/multimedia-class-scheduler-service
[δ]: https://docs.microsoft.com/en-us/windows/win32/procthread/platform-work-queue-api
[ε]: https://www.kernel.org/doc/Documentation/scheduler/sched-rt-group.txt
[the VFIO community]: https://discord.gg/f63cXwH
[their resources]: https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF
[was a silly idea]: https://www.kernel.org/doc/Documentation/timers/NO_HZ.txt
[cset shield]: https://www.codeblueprint.co.uk/2019/10/08/isolcpus-is-deprecated-kinda.html

I also ran into a bunch of limits while figuring out how far I could push my hardware.

* 32 ([KAFFINITY] on i686-pc-windows-gnu, [rustup]’s reasonable default)
* 64 ([KAFFINITY] on x86_64-pc-windows-msvc, which I switched to)
* 255 (pc-q35-4.2 without iommu@eim)
* 288 (pc-q35-4.2 with iommu@eim)
* 64 sockets (Windows limitation?)

[KAFFINITY]: https://docs.microsoft.com/en-us/windows-hardware/drivers/kernel/interrupt-affinity-and-priority#about-kaffinity
[rustup]: https://rustup.rs

To go beyond 255 logical processors and reach the 288 limit, we needed iommu@eim, which also needed iommu@intremap and the qemu ioapic.

```
<domain>
  <features>
    <ioapic driver="qemu"/>
  </features>
  <devices>
    <iommu model="intel">
      <driver intremap="on" eim="on"/>
    </iommu>
  </devices>
</domain>
```

For what it’s worth, by the time I recorded the video, I ended up with [this configuration].

[this configuration]: /static/badapple.xml

## High Frame Rate™

Task Manager has a bunch of update speeds, but the fastest is only twice a second.
The good news is that we can also press F5 to update as often as we want.
Once I added a thread that calls SendInput after every frame, we could play the video at 4 fps.

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/20e17d39c0c98469a68cb3f6fd8d9bd10254c686"><code>20e17d39c0c98</code></a><img src="/images/badapple-commit-dot.svg"></div>

Well… kind of.
[SendInput] can only press F5 in the foreground window, so I had to Alt+Tab every time I ran the program.
[SendMessage] would [probably be better], but I later [worked around that] with [FindWindowW] and [SetForegroundWindow].

[SendInput]: https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput
[SendMessage]: https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendmessage
[probably be better]: https://stackoverflow.com/questions/1220820
[worked around that]: https://bitbucket.org/delan/badapple.rs/commits/096347fca5582ac28ce502f8bf8d51728ce7fdad
[FindWindowW]: https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-findwindoww
[SetForegroundWindow]: https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setforegroundwindow

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/096347fca5582ac28ce502f8bf8d51728ce7fdad"><code>096347fca5582</code></a><img src="/images/badapple-commit-up.svg"></div>

<div class="local-commit local-commit-none"><a href="https://bitbucket.org/delan/badapple.rs/commits/7c6e17d450517d02a29603235c54ea2a45958ad4"><code>7c6e17d450517</code></a><img src="/images/badapple-commit-none.svg"></div>

From here on, I turn off automatic updates, because they split our carefully timed refresh cycles into two corrupted updates.

Making the player press F5 between frames also ensures that Task Manager’s cycles are *in phase* with the frames (albeit with a small error between F5 and refresh).
This might not seem like a problem at first, much like the number of days from X January to X February is always the number of days in January, but when we’re too far out of phase, the dark pixel in a dark-to-light transition won’t be dark enough (and vice versa).

<figure>
    <a href="/images/badapple-4.png"><img src="/images/badapple-4.png" width="100%"></a>
    <figcaption>When the refresh is 20% late, the 80% pixel becomes 70%.</figcaption>
</figure>

There are limits to this technique.
The higher the frame rate, the more of our CPU time gets consumed by Task Manager, [until the tiles become wildly inaccurate].

[until the tiles become wildly inaccurate]: https://twitter.com/winocm/status/1276314798758588418

## Timing is everything

By this point, I was noticing more and more severe timing problems.
The simple approach taken by bad_cpu.py was perfect for real hardware, but on an overcommitted virtual machine, that didn’t cut it.
There was excessive visual noise, and when I started playing the original video side-by-side on another machine, I noticed that our playback finished around 30 seconds late.

My first thought was that **[Instant]**, despite being [monotonic], is “not guaranteed to be steady”, such that “some seconds may be longer than others”.
But on Windows, it’s based on [QueryPerformanceCounter], which provides [much stricter guarantees].
QPC uses the best available counter on a given machine (e.g. RDTSC, RDTSCP, HPET, ACPI PM timer) plus [its own magic][magic][^2] to create timestamps unaffected by system time, [dynamic frequency scaling], multiple processors, and hypervisor conditions (assuming a reasonable hypervisor).
These timestamps are even meaningful across threads (± 1 tick)!

[Instant]: https://doc.rust-lang.org/std/time/struct.Instant.html
[monotonic]: https://en.wikipedia.org/wiki/Monotonic_function
[QueryPerformanceCounter]: https://docs.microsoft.com/en-us/windows/win32/api/profileapi/nf-profileapi-queryperformancecounter
[much stricter guarantees]: https://docs.microsoft.com/en-us/windows/win32/sysinfo/acquiring-high-resolution-time-stamps
[magic]: /images/badapple-magic.jpg
[^2]: This includes workarounds for lying firmware, handling of unsynchronised TSC values across processors, and much more. I would seriously recommend reading Microsoft’s [documentation about this], it’s very interesting!
[documentation about this]: https://docs.microsoft.com/en-us/windows/win32/sysinfo/acquiring-high-resolution-time-stamps
[dynamic frequency scaling]: https://en.wikipedia.org/wiki/Dynamic_frequency_scaling

I then worried that our F5 thread was getting delayed by all of the busier pixel threads.
I didn’t measure this one, and I doubt it was a huge problem unless we’re on a frame that’s almost completely filled, but I used **[SetThreadPriority]** to keep the pixel threads out of the way.
I would have preferred to set the threads’ priorities at creation time with something like a [ProcThreadAttributeList], but that didn’t seem to be possible.
THREAD_MODE_BACKGROUND_BEGIN looked attractive, but upon closer inspection, that’s an orthogonal setting for “resource” (I/O) scheduling, which we never do during playback, so I chose THREAD_PRIORITY_IDLE.

[SetThreadPriority]: https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-setthreadpriority
[ProcThreadAttributeList]: https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-updateprocthreadattribute

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/9883355e6e8643a34a713df33d01e3a5efc995cd"><code>9883355e6e864</code></a><img src="/images/badapple-commit-dot.svg"></div>

<hr>

One of the biggest problems turned out to be **keeping the pixel threads in sync**.
Each pixel thread started its playback as soon as it could execute.
I used an [AtomicUsize] with `fetch_add(1, Relaxed)` to measure the time from right before the first CreateRemoteThreadEx to the start of the last pixel thread to gain execution, and it was a massive 150–250 milliseconds!
I struggled to imagine which of Windows’ [synchronisation primitives] would be an efficient solution here, but Rust came to the rescue with [Barrier], which blocks waiters until a given number of waiters are waiting.
That number is one for every pixel thread plus one for the F5 thread, and I added waits to the start of both functions’ main loops.

[AtomicUsize]: https://doc.rust-lang.org/std/sync/atomic/struct.AtomicUsize.html
[synchronisation primitives]: https://docs.microsoft.com/en-us/windows/win32/sync/synchronization-objects
[Barrier]: https://doc.rust-lang.org/std/sync/struct.Barrier.html

With all of the threads in sync, I eliminated the sleeps from the pixel threads, elevating the importance of the F5 thread to what I’ve since called the “clock” thread.
The pixel threads’ main loop was wait → spin → sleep, but the clock thread was wait → sleep → F5, so skipping directly to the wait was effectively a sleep.

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/9992c03d6068fb69f7f9af811339d966d4f37067"><code>9992c03d6068f</code></a><img src="/images/badapple-commit-dot.svg"></div>

This improved the picture quality, but playback still consistently finished too late.
Given the simple algorithm “spin for darkness / fps, sleep for (1 − darkness) / fps”, this kind of problem is always present (if negligible) even on real hardware.
Calculating how long to sleep for is very fast but not instant, and sleeping for some amount of time doesn’t guarantee that the scheduler will return us to execution in that time.

The first thing I tried was to adjust the sleep time to catch up with (or if necessary, wait for) the **nominal** time we should start the next frame, based on when playback started.
I called the difference between what a naïve sleep would give us and the nominal time **lateness**.
This helped at very low resolutions where I disabled most of the pixels on the canvas, but what I otherwise found was that our adjusted sleep was always zero.

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/7f5562e540a681e91fad96d64711b0d4b1cdadd7"><code>7f5562e540a68</code></a><img src="/images/badapple-commit-dot.svg"></div>

<div class="local-commit local-commit-none"><a href="https://bitbucket.org/delan/badapple.rs/commits/e18f7dbf69c07fe153f5536847bf69a9e03d5777"><code>e18f7dbf69c07</code></a><img src="/images/badapple-commit-none.svg"></div>

<div class="local-commit local-commit-none"><a href="https://bitbucket.org/delan/badapple.rs/commits/6e3d0ddabd45ddf803bee482f128fe3a9e4811a4"><code>6e3d0ddabd45d</code></a><img src="/images/badapple-commit-none.svg"></div>

<div class="local-commit local-commit-none"><a href="https://bitbucket.org/delan/badapple.rs/commits/30161548913f7d44dd5a019642ea25331da5b022"><code>30161548913f7</code></a><img src="/images/badapple-commit-none.svg"></div>

<figure>
    <a href="/images/badapple-5.png"><img src="/images/badapple-5.png" width="100%"></a>
    <figcaption>There was so much lateness that we couldn’t keep up.</figcaption>
</figure>

This was actually bad news and good news at the same time.
The bad news was that we would need to do more to fix our timing problems, but the good news?
**Even when we effectively removed sleeps, the picture was still recognisable,** and if anything, the change helped us with our “washed out” distortion.
I was worried that this might not be the case, because if you look at each pixel thread in isolation and ignore the Barrier, wouldn’t all spin and no sleep yield 100% activity?

I now believe — but correct me if I’m wrong — the percentages are based on how much of each wall second (or other period) a given processor is busy for, and when a guest processor is preempted against its will, that time doesn’t count, like how you don’t experience the time you’re asleep[^3].
This would explain the distortion that occurs when a guest processor *can’t* run because the host processors are contended!

[^3]: I don’t think this is actually true, but I’m sticking with the analogy.

<hr>

One thing that I was surprised to see made *zero* difference was switching from a debug build to a release build.
It ended up being so irrelevant to this workload that while I put <code>--release</code> in the README, I forgot to use it when recording the video!

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/7a9150a4e5e9c5b8aedefebb9d93207bf4ae63be"><code>7a9150a4e5e9c</code></a><img src="/images/badapple-commit-dot.svg"></div>

But the technique that made the biggest difference to our timing problems was **dropping frames**.
When we’re running more than 1 / fps late, not even a 100% empty frame gives us enough room for sleep adjustment that we’ll catch up completely by the end of the frame.
Figuring out how the clock thread could safely communicate this to the pixel threads was difficult, but I decided to publish the next frame index with a [RwLock], which I would describe as Rust’s borrowing rule plus the ability to wait.

[RwLock]: https://doc.rust-lang.org/std/sync/struct.RwLock.html

Strictly speaking that wasn’t enough, because while the Barrier syncs up all of the threads at the start of each frame, we have no way of knowing when the write acquisition (clock thread) happens relative to the read acquisitions (pixel threads).
Did it happen before all of them, after all of them, or somewhere in between?
Either of the first two would probably be fine if only we could make it *consistent*, but somewhere in between is very bad.
If that happens, some pixels will draw their part of the *old* frame and others the *new* frame, which sounds like the relatively minor problem known as horizontal tearing… until you realise that the read acquisitions don’t happen in scanline order.

To prevent that, I added a second wait on the Barrier to both functions’ main loops, dividing each frame into two phases based on the next frame index: read-only and write-only.
In the read-only phase, all threads read that variable (and do the rest of their work), then in the write-only phase, the clock thread writes the new index.
I’m sure there are better tools for the job though — it relies on me writing code that obeys my own rule, without any compile-time or runtime enforcement.

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/156c45ea6c6e3d2c2970ed8c485df0a8cc0d0dbb"><code>156c45ea6c6e3</code></a><img src="/images/badapple-commit-dot.svg"></div>

<div class="local-commit"><a href="https://bitbucket.org/delan/badapple.rs/commits/5065d9566d7b6e0ca3feea7a6719df81aa42cbc2"><code>5065d9566d7b6</code></a><img src="/images/badapple-commit-dot.svg"></div>

<div class="local-commit local-commit-none"><a href="https://bitbucket.org/delan/badapple.rs/commits/8a2d3d2288aa8ee0d1cb9d360eb33544d964e353"><code>8a2d3d2288aa8</code></a><img src="/images/badapple-commit-none.svg"></div>

</div>

## The present tense

[I wrote a video player] for taskmgr, and it now works well enough to play Bad Apple!! on an 11x6 canvas with only a laptop and the power of virtualisation.
Picture fidelity and frame rates are far better during the black-on-white shots, but at least *some* of the white-on-black shots managed to yield more than a complete blur.

[I wrote a video player]: https://bitbucket.org/delan/badapple.rs

Playback at 4 fps or even 10 fps is now possible, which is an improvement that even the Real Hardware folks can enjoy, but if I could drive 66 pixels with only 12 hardware threads, imagine what we could do with 64 or even 128!

<hr>

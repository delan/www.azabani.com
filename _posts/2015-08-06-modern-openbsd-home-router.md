---
layout: default
title: The modern OpenBSD home router
date: 2015-08-07 01:00:00 +0800
tags: home
---

It’s no secret that most consumer routers ship with software that’s
flaky at best, and prohibitively insecure at worst. While I’ve had good
experiences with OpenWrt and pfSense, I wanted to build a router from
the ground up, both to understand the stack and to have something to
tinker with. I found many solid tutorials out there, but few of them
covered the intricacies of both PPP and IPv6. Here’s what I’ve learned.

## Choosing the hardware

The hardware itself is not very modern at all. In the interest of a
challenge, I chose the oldest computer that could reasonably replace
the Billion 7800N that I was using. Meet the IBM Aptiva, model 2194,
whose tiny 95 watt power supply drives some hardware that’s nearly old
as myself:

	cpu0: Intel Pentium III ("GenuineIntel" 686-class) 602 MHz
	bios0: vendor IBM version "PTKT09AUS" date 05/15/2000
	bios0: IBM 219443A
	ral0 at pci1 dev 3 function 0 "Ralink RT2561S" rev 0x00: irq 11, address 00:21:29:e2:c6:03
	em0 at pci1 dev 4 function 0 "Intel 82541GI" rev 0x05: irq 5, address 00:1b:21:56:16:9c
	em1 at pci1 dev 5 function 0 "Intel 82541GI" rev 0x05: irq 3, address 00:1b:21:56:1b:86
	spdmem0 at iic0 addr 0x50: 128MB SDRAM non-parity PC133CL2
	spdmem1 at iic0 addr 0x51: 128MB SDRAM non-parity PC133CL2

After upgrading the memory’s speed and capacity, choosing Ethernet
cards was easy. Almost all of mine were based on a Realtek RTL81xx or
Intel 82451PI controller, both of which have excellent support with
OpenBSD. The Realtek-based cards I owned had an empty socket for a PXE
ROM, or no socket at all, so I opted for a pair of Intel PRO/1000 GT
Desktop cards instead. A quick test with nc(1) shows that I can only
push about 27 MiB/s through the router before the CPU becomes a
bottleneck.

Finding a wireless card was more difficult, even though the spare cards
I had only supported 802.11g. Of those, only one has a driver that
supports hostap mode:

  * SMC SMCWPCI-G (Qualcomm Atheros AR5005G(S) `168C:001A`): no driver
  * Netgear WPN311 V1H2 Rev. A3 (Atheros AR5005G(S) `168C:001A`): no driver
  * Netgear WG311v3 Rev. A1 (Marvell Libertas 88W8335 `11AB:1FAA`): malo(4) ✗
  * Cisco Linksys WMP54G ver. 4.1 (Ralink RT2561S `1814:0301`): ral(4) ✓

Conveniently, unlike Marvell, Ralink has also allowed OpenBSD to freely
distribute the required firmware without necessitating the use of
fw_update(1).

I’m still connected to the outside world through an ADSL service with
[Internode]. Because internal modems for anything newer than G.992.1
are hard to come by, I simply dug out an old Netgear DG834Gv2 and put
it into bridge mode.

To put the DG834Gv2 into bridge mode, head to `/setup.cgi?next_file=mode.htm`
on the device, then ensure that the ADSL parameters are correct and
wireless is disabled. The 7800N would not only have been a waste of
fancy hardware, but doing the same on that made it unreachable over
IPv4, whereas the DG834Gv2 remained reachable. On the other hand, the
7800N can lie to your DSLAM or MSAN about the SNR of an ADSL connection.

Having configured the hardware and installed OpenBSD 5.7 without any
problems, connecting to the Internet soon became my next task.

[Internode]: http://www.internode.on.net/

<img class="post_image_full"
     src="/images/router.jpg"
     alt="[Photograph of the router with an IBM KB-8923]">

## Interface layout

Behind every fancy router is a bridge, and a bridge is what I made:

	% cat /etc/hostname.bridge0
	add vether0
	add em0
	add em1
	add ral0
	up

`em0` goes to the DG834Gv2, `em1` goes to a D-Link DGS-1008D, a dumb
switch, `ral0` hosts the wireless network, and `vether0` serves two
purposes: not only does it decouple whether or not IPv4 and IPv6 will
work from whether or not a particular physical interface is up, but it
also yields a stable interface identifier that’s independent of any
physical interface.

	% cat /etc/hostname.em0
	up

	% cat /etc/hostname.em1
	up

	% cat /etc/hostname.ral0
	media autoselect mode 11g mediaopt hostap
	nwid deLAN
	wpakey hunter13
	wpaprotos wpa2
	wpaakms psk
	wpaciphers ccmp
	wpagroupcipher ccmp
	up

	% cat /etc/hostname.vether0
	inet 172.19.1.1 255.255.0.0
	inet6 eui64

	% sh /etc/netstart em0 em1 ral0 vether0 bridge0

## Reaching the outside world

As far as I know, Internode is the only residential ISP in Australia
that provides native IPv6 without the use of any transition mechanisms.
While some consumer routers like the 7800N Just Work™ in this regard,
others don’t, like the Netgear WNDR3700v2, for which the best
connectivity reachable with stock firmware is 6to4, because it
otherwise erroneously tries to establish two separate PPP sessions —
one for each protocol.

Looking downwards, the stack of protocols sent over an Internode ADSL
connection, sometimes known as PPPoEoA for short, is [rather complex]:

[rather complex]: https://www.farside.org.uk/200903/ipoeoatm

  * Transport layer or application layer payload
  * IPv4 packet header or IPv6 packet header [[RFC 791][791], [2460]]
  * PPP packet header (2 octets, type 0021<sub>16</sub> or
    0057<sub>16</sub>) [[RFC 1661][1661], [1332], [5072]]
  * PPPoE header (6 octets) [[RFC 2516][2516] § 4]
  * Ethernet II frame (18 octets, EtherType 8863<sub>16</sub> or
    8864<sub>16</sub>) [[IEEE 802.3-2012][802.3]]

From here below, the ADSL side of the DG834Gv2 continues:

  * LLC Encapsulation for Bridged Protocols (10 octets)
    [[RFC 2684][2684] § 5.2]:
    * IEEE 802 SNAP header (5 octets, OUI 00:80:C2<sub>16</sub>,
      PID 0001<sub>16</sub>) [[IEEE 802][802]]
    * IEEE 802.2 LLC header (3 octets, AA:AA:03<sub>16</sub>)
      [[IEEE 802.2][802.2]]
  * AAL5 CPCS-PDU trailer (8 octets)
    [[RFC 2684][2684] § 4, [ITU-T Rec. I.363.5][I.363.5]]
  * ATM cell header (5 octets)
  * ADSL2+ physical layer [[ITU-T Rec. G.992.5][G.992.5]]

Alternatively, the Ethernet side of the DG834Gv2 continues:

  * Ethernet packet (8 octets) [[IEEE 802.3-2012][802.3]]
  * Ethernet interpacket gap (12 octets) [[IEEE 802.3-2012][802.3]]
  * 100BASE-TX physical layer [[IEEE 802.3-2012][802.3]]

[791]: https://tools.ietf.org/html/rfc791
[2460]: https://tools.ietf.org/html/rfc2460
[1661]: https://tools.ietf.org/html/rfc1661
[1332]: https://tools.ietf.org/html/rfc1332
[5072]: https://tools.ietf.org/html/rfc5072
[2516]: https://tools.ietf.org/html/rfc2516
[802.3]: https://standards.ieee.org/about/get/802/802.3.html
[2684]: https://tools.ietf.org/html/rfc2684
[802]: https://standards.ieee.org/about/get/802/802.html
[802.2]: https://standards.ieee.org/about/get/802/802.2.html
[I.363.5]: https://www.itu.int/rec/T-REC-I.363.5/en
[G.992.5]: https://www.itu.int/rec/T-REC-G.992.5/en

IPv4 addresses are obtained with the PPP Internet Protocol Control
Protocol [[RFC 1332][1332]]. This includes dynamic and static
addresses, but does not include routed subnets. IPv6 is where the
situation becomes more confusing. The IPv6 Control Protocol
[[RFC 5072][5072]] is only used to negotiate a unique interface
identifier for the client, because PPP is only concerned with
link-local communication between a pair of peers. Even if no globally
routable prefixes are assigned, once this negotiation is complete,
IPv6 traffic to the ISP peer is technically possible, although not very
useful of course.

After some hours hacking away because the OpenBSD 5.7 manual page for
pppoe(4) was incorrect, I reached this configuration:

	% cat /etc/hostname.pppoe0
	!/sbin/ifconfig em0 up
	inet 0.0.0.0 255.255.255.255 NONE \
		pppoedev em0 \
		authproto chap \
		authname 'azabani@internode.on.net' \
		authkey hunter2
	dest 0.0.0.1
	inet6 eui64
	!/sbin/route add 0.0.0.0/0 -ifp pppoe0 0.0.0.1
	!/sbin/route add ::/0 -ifp pppoe0 fe80::

	% sh /etc/netstart pppoe0

The two errors were subtle but fatal. Placing `inet6 eui64` before the
PPPoE parameters inadvertently brings the interface up, after which the
parameters can’t be changed. Viable solutions include placing `down`
just after `inet6 eui64`, or simply moving `inet6 eui64` after the
PPPoE parameters. Because of a peculiarity with route(8),
`add default fe80::` doesn’t work either unless the `-inet6` option is
specified, because `0.0.0.0/0` is assumed, and incompatible address
families ensue. I’ve since [sent] a [patch] to `tech@openbsd.org`.

[sent]: https://www.azabani.com/patch/3/message.txt
[patch]: https://www.azabani.com/patch/3/patch.txt

From here, either or both of two paths can be taken to obtain a globally
routable IPv6 prefix: NDP Router Solicitation [[RFC 4861][4861]] for the
dynamic /64, or DHCPv6 IA_PD [[RFC 3633][3633]] for the static /56.

[3633]: https://tools.ietf.org/html/rfc3633
[4861]: https://tools.ietf.org/html/rfc4861

	% ifconfig pppoe0 inet6 autoconf

One command is required to start sending Router Solicitation messages,
and ifconfig(8) handles it now that rtsold(8) has been removed. Because
[[RFC 4861][4861]] doesn’t specify whether or not routers are allowed
to send Router Solicitation messages, OpenBSD errs on the side of caution,
and will not send them if `net.inet6.ip6.forwarding` is enabled.

The `wide-dhcpv6` package provides dhcp6c(8) for DHCPv6 IA_PD, or
prefix delegation. Note that even though the /56 prefix is static, the
prefix delegation process [must still occur][why IA_PD] so that
Internode can update its routing tables, something that I spent half a
day scratching my head at when I tried to cut corners.

[why IA_PD]: https://jeremy.visser.name/2009/06/why-dynamic-ipv6-subnet-allocations-for-home-users-are-evil/#comment-4808

	% pkg_add wide-dhcpv6

	% cat /etc/rc.d/dhcp6c
	#!/bin/sh

	daemon="/usr/local/sbin/dhcp6c"

	. /etc/rc.d/rc.subr

	rc_reload=NO

	rc_cmd $1

	% cat /etc/dhcp6c.conf
	interface pppoe0 {
		send ia-pd 0;
		send domain-name-servers;
		send rapid-commit;
	};

	id-assoc pd {
		prefix-interface vether0 {
			sla-id 0;
			sla-len 8;
		};
	};

	% echo 'dhcp6c_flags=pppoe0' | tee -a /etc/rc.conf.local
	dhcp6c_flags=pppoe0

	% echo '!/etc/rc.d/dhcp6c restart' | tee -a /etc/hostname.pppoe0
	!/etc/rc.d/dhcp6c restart

	% /etc/rc.d/dhcp6c restart
	dhcp6c(ok)

## Turning a client into a router

Most of the work involved in configuring routing involves pf(4) and
pf.conf(5), but I left that until last. Before that I set the DNS
search domain and resolvers to sane defaults, and enabled packet
forwarding for both IPv4 and IPv6.

	% cat /etc/resolv.conf
	search home.daz.cat
	nameserver 192.231.203.132
	nameserver 192.231.203.3

	% cat /etc/sysctl.conf
	net.inet.ip.forwarding=1
	net.inet6.ip6.forwarding=1

	% xargs sysctl < /etc/sysctl.conf
	net.inet.ip.forwarding: 0 -> 1
	net.inet6.ip6.forwarding: 0 -> 1

From there I moved to DHCP, something that most people are familiar with.

	% cat /etc/dhcpd.conf
	subnet 172.19.0.0 netmask 255.255.0.0 {
		range 172.19.2.1 172.19.2.254;
		default-lease-time 3600;
		max-lease-time 604800;
		option routers 172.19.1.1;
		option domain-name-servers 192.231.203.132, 192.231.203.3;
		option domain-name "home.daz.cat";
	}

	% echo 'dhcpd_flags=vether0' | tee -a /etc/rc.conf.local
	dhcpd_flags=vether0

	% /etc/rc.d/dhcpd restart
	dhcpd(ok)

As for IPv6, rtadvd(8) goes a long way by sending Router Advertisement
messages, propagating the globally routable IPv6 prefix where it’s
available. I’m leaving clients to generate their own interface
identifiers using SLAAC [[RFC 4862][4862], [4941]] instead of running
a stateful DHCPv6 [[RFC 3315][3315]] server. In its stateless form,
DHCPv6 is only necessary to advertise IPv6 DNS servers, which I’ll get
around to doing eventually.

[3315]: https://tools.ietf.org/html/rfc3315
[4862]: https://tools.ietf.org/html/rfc4862
[4941]: https://tools.ietf.org/html/rfc4941

	% echo 'rtadvd_flags=vether0' | tee -a /etc/rc.conf.local
	rtadvd_flags=vether0

	% /etc/rc.d/rtadvd restart
	rtadvd(ok)

pf.conf(5) is where I spent a few full days of my time. I paid careful
attention to RFCs when I was deciding which address blocks to drop
traffic from [[RFC 6890][6890]] and which ICMPv6 message types and
codes to allow through the router [[RFC 4890][4890]].

[4890]: https://tools.ietf.org/html/rfc4890
[6890]: https://tools.ietf.org/html/rfc6890

	### ~~~ Interface layout ~~~ ###

	# em0: 802.3ab to ADSL modem (172.19.0.1/16)
	# em1: 802.3ab to internal switch
	# ral0: 802.11g in hostap mode
	# vether0: persists addresses 172.19.1.1/16 and 2001:44b8:6116:1c00::eui64/64
	# bridge0: Ethernet bridge over all of the above
	# pflog0: target interface for blocked packets
	# pppoe0: PPPoE session over em0

	### ~~~ Constants and variables ~~~ ###

	# All addresses associated with this host
	self = "{ (egress), (vether0) }"

	# RFC 6890: Special-Purpose IP Address Registries:
	# https://www.iana.org/assignments/iana-ipv4-special-registry/
	# https://www.iana.org/assignments/iana-ipv6-special-registry/

	# Included below are all address blocks with either Forwardable = False,
	# Global = False, or both, but excluding 2001::/23 because it is often
	# superseded by more specific allocations, as of 2015-08-05.

	table <martians> const { \
		0.0.0.0/8, \
		10.0.0.0/8, \
		100.64.0.0/10, \
		127.0.0.0/8, \
		169.254.0.0/16, \
		172.16.0.0/12, \
		192.0.0.0/24, \
		192.0.2.0/24, \
		192.168.0.0/16, \
		198.18.0.0/15, \
		198.51.100.0/24, \
		203.0.113.0/24, \
		240.0.0.0/4, \
		255.255.255.255/32, \
		::1/128, \
		::/128, \
		::ffff:0:0/96, \
		100::/64, \
		2001::/32, \
		2001:2::/48, \
		2001:db8::/32, \
		fc00::/7, \
		fe80::/10 \
	}

	### ~~~ Default rules ~~~ ###

	# Never touch loopback interfaces
	set skip on lo

	# Normalise packets, especially IPv4 DF and Identification
	match in all scrub (no-df random-id)

	# Limit the MSS on PPPoE to 1440 octets
	match on pppoe0 scrub (max-mss 1440)

	# Block all packets by default, logging them to pflog0
	block log

	### ~~~ Link-scoped services ~~~ ###

	# DHCPv6 client: make IA_PD requests and receive responses to them
	pass out quick on egress inet6 proto udp from (egress) to ff02::1:2 port dhcpv6-server
	pass in quick on egress inet6 proto udp to (egress) port dhcpv6-client

	### ~~~ Bulk pass rules ~~~ ###

	# Pass all traffic on internal interfaces
	# vether0 is necessary here, but bridge0 is not
	pass quick on { vether0 em0 em1 ral0 }

	# Pass all outbound IPv6 traffic
	pass out quick on egress inet6 from { egress, (vether0:network) } modulate state

	# Pass all outbound IPv4 traffic from this host
	pass out quick on egress inet from egress modulate state

	# NAT all outbound IPv4 traffic from the rest of our network
	pass out quick on egress inet from (vether0:network) nat-to (egress) modulate state

	### ~~~ Block undesirable traffic ~~~ ###

	# These rules must not precede the DHCPv6 client or NAT rules above
	block log quick on egress from { no-route, urpf-failed, <martians> }
	block log quick on egress to { no-route, <martians> }

	### ~~~ Pass some ICMP and ICMPv6 traffic ~~~ ####

	# Pass all inbound ICMP echo requests
	pass in quick on egress inet proto icmp icmp-type echoreq

	# RFC 4890: Recommendations for Filtering ICMPv6 Messages in Firewalls
	pass quick on egress inet6 proto icmp6 icmp6-type { 1, 2, 128, 129 }
	pass quick on egress inet6 proto icmp6 icmp6-type 3 code 0
	pass quick on egress inet6 proto icmp6 icmp6-type 3 code 1
	pass quick on egress inet6 proto icmp6 icmp6-type 4 code 0
	pass quick on egress inet6 proto icmp6 icmp6-type 4 code 1
	pass quick on egress inet6 proto icmp6 icmp6-type 4 code 2

	### ~~~ Open services on this router ~~~ ###

	# OpenSSH server
	pass in on egress proto { tcp, udp } to $self port ssh

## Watch this space!

Future tasks which I’m yet to complete include:

  * Configuring ntpd(8)
  * Advertising IPv6 DNS servers with dhcp6s(8)
  * Hosting an authoritative DNS zone for `home.daz.cat` with nsd(8)
  * Caching DNS queries with unbound(8)

You can find the [root overlay] for my router on Bitbucket.

[root overlay]: https://bitbucket.org/delan/daria.daz.cat

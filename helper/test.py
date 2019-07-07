#!/usr/bin/env python3

from sys import stdin


p, *r = eval(stdin.read())
q = p


def U(scalar):
    result = hex(scalar)[2:].upper()

    if scalar < 0x1000:
        result = f"000{result}"[-4:]

    return result


def z():
    if p < q:
        return f"U+{U(p)}-{U(q)}"
    else:
        return f"U+{U(p)}"


for x in r:
    if x - q > 1:
        print(z(), end=", ")
        p = x
    q = x

print(z())

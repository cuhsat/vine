#!/usr/bin/env python
import sys

def main(script, text="", *args):
    result = 0

    for char in text:
        result = 0xFFFFFFFF & (result << 3 | result >> 29)
        result = 0xFFFFFFFF & (result ^ ord(char))

    print("0x%08X" % result)

if __name__ == "__main__":
    sys.exit(main(*sys.argv))

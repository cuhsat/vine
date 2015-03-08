import sys

if len(sys.argv) > 1:
    text = sys.argv[1]
    hash = 0

    for i in range(len(text)):
        hash = 0xFFFFFFFF & (hash << 3 | hash >> 29)
        hash = 0xFFFFFFFF & (hash ^ ord(text[i]))

    print "0x%08X" % hash

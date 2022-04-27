#!/bin/sh
# Simply Run this and you can get a pretty quick little file write speed test for the storage device you want.
# Source: https://kenichishibata.medium.com/test-i-o-performance-of-linux-using-dd-a5074f1de9ce
dd if=/dev/zero of=/tmp/test1.img bs=1G count=1 oflag=dsync

#!/bin/bash

rm -r /tmp/batchomatic
mkdir /tmp/batchomatic

dpkg -l | awk '/^[hi]i/{print $2}' > /tmp/batchomatic/alltweaks.txt
awk 'NR==FNR{a[$0];next} !($0 in a)' /Library/batchomatic/ignoredtweaks.txt /tmp/batchomatic/alltweaks.txt > /tmp/batchomatic/thinnedtweaks.txt
sed '/^gsc./ d' /tmp/batchomatic/thinnedtweaks.txt > /tmp/batchomatic/tweaksWithNewline.txt
printf %s "$(< /tmp/batchomatic/tweaksWithNewline.txt)" > /tmp/batchomatic/removeall.txt

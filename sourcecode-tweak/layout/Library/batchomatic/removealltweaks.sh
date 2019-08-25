#!/bin/bash

rm -r /tmp/batchomatic
mkdir /tmp/batchomatic

dpkg -l | awk '/^[hi]i/{print $2}' > /tmp/batchomatic/alltweaks.txt
sed '/^gsc./ d' /tmp/batchomatic/alltweaks.txt > /tmp/batchomatic/tweaksNoGsc.txt
awk 'NR==FNR{a[$0];next} !($0 in a)' /Library/batchomatic/ignoredtweaks.txt /tmp/batchomatic/tweaksNoGsc.txt > /tmp/batchomatic/tweaksWithoutIgnores.txt

if [ "$1" = 1 ]; then
    mv /tmp/batchomatic/tweaksWithoutIgnores.txt /tmp/batchomatic/tweaksOptionsHandled.txt
else
    awk 'NR==FNR{a[$0];next} !($0 in a)' /Library/batchomatic/dontremoveeverything.txt /tmp/batchomatic/tweaksWithoutIgnores.txt > /tmp/batchomatic/tweaksOptionsHandled.txt
fi

printf %s "$(< /tmp/batchomatic/tweaksOptionsHandled.txt)" > /tmp/batchomatic/removeall.txt

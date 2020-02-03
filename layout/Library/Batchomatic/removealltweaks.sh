#!/bin/bash

rm -r /tmp/batchomatic
mkdir /tmp/batchomatic
dpkg --get-selections > /tmp/batchomatic/rawtweaks.txt
grep -v deinstall /tmp/batchomatic/rawtweaks.txt > /tmp/batchomatic/noDeinstalls.txt
grep -v gsc. /tmp/batchomatic/noDeinstalls.txt > /tmp/batchomatic/noGsc.txt
grep -o '^\S*' /tmp/batchomatic/noGsc.txt > /tmp/batchomatic/alltweaks.txt
sort -u /tmp/batchomatic/alltweaks.txt > /tmp/batchomatic/tweaksSorted.txt
sed -e :a -e '/./,$!d;/^\n*$/{$d;N;};/\n$/ba' /tmp/batchomatic/tweaksSorted.txt > /tmp/batchomatic/tweaksTrimmed.txt

diff --changed-group-format="%>" --unchanged-group-format="" /Library/Batchomatic/ignoredtweaks.txt /tmp/batchomatic/tweaksTrimmed.txt > /tmp/batchomatic/tweaksWithoutIgnores.txt
if [ "$1" = 1 ]; then
    mv /tmp/batchomatic/tweaksWithoutIgnores.txt /tmp/batchomatic/tweaksOptionsHandled.txt
else
    diff --changed-group-format="%>" --unchanged-group-format="" /Library/Batchomatic/dontremoveeverything.txt /tmp/batchomatic/tweaksWithoutIgnores.txt > /tmp/batchomatic/tweaksOptionsHandled.txt
fi

sort -u /tmp/batchomatic/tweaksOptionsHandled.txt > /tmp/batchomatic/tweaksReSorted.txt
echo -n "`cat /tmp/batchomatic/tweaksReSorted.txt`" > /tmp/batchomatic/removealltweaks.txt

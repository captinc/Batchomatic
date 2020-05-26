#!/bin/bash

addUtilityRepos () {
    echo "" >> /tmp/batchomatic/wantedReposRaw.txt
    if [ `ls -a /etc/ | grep .installed-chimera` ]; then
        echo "https://repo.chimera.sh/" >> /tmp/batchomatic/wantedReposRaw.txt
    elif [ `ls -a / | grep .installed_unc0ver` ]; then
        FILE1=/etc/apt/cydiasources.d/cydia.list
        FILE2=/etc/apt/sources.list.d/sileo.sources
        FILE3=/etc/apt/sources.list.d/cydia.list
        if [ -e "$FILE1" -o -e "$FILE2" ]; then
            echo "https://diatr.us/apt/" >> /tmp/batchomatic/wantedReposRaw.txt
        elif [ -f "$FILE3" ]; then
            echo "https://apt.bingner.com/" >> /tmp/batchomatic/wantedReposRaw.txt
        fi
    elif [ `ls -a /etc/apt/preferences.d/ | grep checkra1n` ]; then
        echo "https://apt.bingner.com/" >> /tmp/batchomatic/wantedReposRaw.txt
    fi
}

rm -r /tmp/batchomatic
mkdir /tmp/batchomatic
cp /var/mobile/BatchInstall/repos.txt /tmp/batchomatic/wantedReposRaw.txt

if [ "$1" = 1 ]; then
    cat /etc/apt/sources.list.d/*.list >> /tmp/batchomatic/reposRaw.txt || true
    cat /etc/apt/cydiasources.d/*.list >> /tmp/batchomatic/reposRaw.txt || true
elif [ "$1" = 2 ]; then
    cat "/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list" >> /tmp/batchomatic/reposRaw.txt || true
    addUtilityRepos
elif [ "$1" = 3 ]; then
    cat /etc/apt/sources.list.d/*.sources >> /tmp/batchomatic/reposRaw.txt || true
    addUtilityRepos
elif [ "$1" = 4 ]; then
    ls "/var/mobile/Library/Application Support/Installer/SourcesFiles" | sed 's:_:/:g' | sed 's:\(.*\)-Packages:\1:' >> /tmp/batchomatic/reposWithSlash.txt || true
    addUtilityRepos
fi

egrep -o 'https?://[^ ]+' /tmp/batchomatic/reposRaw.txt >> /tmp/batchomatic/reposExtracted.txt
sed 's:/\?$:/:g' /tmp/batchomatic/reposExtracted.txt >> /tmp/batchomatic/reposWithSlash.txt
sed 's#https://repounclutter.coolstar.org/#http://apt.thebigboss.org/repofiles/cydia/#g' /tmp/batchomatic/reposWithSlash.txt > /tmp/batchomatic/reposRepoUnclutterConverted.txt
sed 's#http://apt.bingner.com/#https://apt.bingner.com/#g' /tmp/batchomatic/reposRepoUnclutterConverted.txt > /tmp/batchomatic/reposBingnerConverted.txt
sort -u /tmp/batchomatic/reposBingnerConverted.txt > /tmp/batchomatic/currentlyaddedrepos.txt

diff --changed-group-format="%>" --unchanged-group-format="" /tmp/batchomatic/currentlyaddedrepos.txt /tmp/batchomatic/wantedReposRaw.txt > /tmp/batchomatic/reposToAddWithoutIgnores.txt
if [ "$1" = 3 ]; then
    sed 's#http://apt.thebigboss.org/repofiles/cydia/#https://repounclutter.coolstar.org/#g' /tmp/batchomatic/reposToAddWithoutIgnores.txt > /tmp/batchomatic/reposRepoUnclutterConverted.txt
    grep -v "http://apt.modmyi.com/" /tmp/batchomatic/reposRepoUnclutterConverted.txt > /tmp/batchomatic/reposNoModyMyI.txt
    grep -v "http://cydia.zodttd.com/repo/cydia/" /tmp/batchomatic/reposNoModyMyI.txt > /tmp/batchomatic/reposDefaultSourcesHandled.txt
else
    mv /tmp/batchomatic/reposToAddWithoutIgnores.txt /tmp/batchomatic/reposDefaultSourcesHandled.txt
fi
sort -u /tmp/batchomatic/reposDefaultSourcesHandled.txt > /tmp/batchomatic/reposToAddSorted.txt
echo -n "`cat /tmp/batchomatic/reposToAddSorted.txt`" > /tmp/batchomatic/reposToAdd.txt

if [ ! -s /tmp/batchomatic/reposToAdd.txt ]; then
    rm /tmp/batchomatic/reposToAdd.txt
fi

#!/bin/bash

addUtilityRepos () {
    if [ `ls -a /etc/ | grep .installed-chimera` ]; then
        echo "https://repo.chimera.sh/" >> /tmp/batchomatic/wantedReposRaw.txt
    elif [ `ls -a / | grep .installed_unc0ver` ]; then
        FILE1=/etc/apt/cydiasources.d/cydia.list
        FILE2=/etc/apt/sources.list.d/sileo.sources
        FILE3=/etc/apt/sources.list.d/cydia.list

        if test -f "$FILE1" || test -f "$FILE2"; then
            echo "https://diatr.us/apt/" >> /tmp/batchomatic/wantedReposRaw.txt
        elif test -f "$FILE3"; then
            echo "https://apt.bingner.com/" >> /tmp/batchomatic/wantedReposRaw.txt
        fi
    fi
}

rm -r /tmp/batchomatic
mkdir /tmp/batchomatic

sort -u /var/mobile/BatchInstall/repos.txt > /tmp/batchomatic/wantedReposRaw.txt

if [ "$1" = 1 ]; then
    cat /etc/apt/sources.list.d/cydia.list >> /tmp/batchomatic/reposRaw.txt || true
    cat /etc/apt/cydiasources.d/cydia.list >> /tmp/batchomatic/reposRaw.txt || true
elif [ "$1" = 2 ]; then
    cat "/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list" >> /tmp/batchomatic/reposRaw.txt || true
    addUtilityRepos
elif [ "$1" = 3 ]; then
    cat /etc/apt/sources.list.d/*.sources >> /tmp/batchomatic/reposRaw.txt || true
    addUtilityRepos
elif [ "$1" = 4 ]; then
    ls "/var/mobile/Library/Application Support/Installer/SourcesFiles" | sed 's:_:/:g' | sed 's:\(.*\)-Packages:\1:' >> /tmp/batchomatic/reposFormatted.txt || true
    addUtilityRepos
fi

egrep -o 'https?://[^ ]+' /tmp/batchomatic/reposRaw.txt >> /tmp/batchomatic/reposExtracted.txt
while read aLine; do
    case "$aLine" in
        */)
        echo $aLine >> /tmp/batchomatic/reposFormatted.txt
        ;;
        *)
        echo "$aLine/" >> /tmp/batchomatic/reposFormatted.txt
        ;;
    esac
done < /tmp/batchomatic/reposExtracted.txt
sed 's#https://repounclutter.coolstar.org/#http://apt.thebigboss.org/repofiles/cydia/#g' /tmp/batchomatic/reposFormatted.txt > /tmp/batchomatic/reposRepoUnclutterConverted.txt
sort -u /tmp/batchomatic/reposRepoUnclutterConverted.txt >> /tmp/batchomatic/reposSorted.txt
printf %s "$(< /tmp/batchomatic/reposSorted.txt)" > /tmp/batchomatic/currentlyaddedrepos.txt

if [ ! -s /tmp/batchomatic/currentlyaddedrepos.txt ]; then
    cp /tmp/batchomatic/wantedReposRaw.txt /tmp/batchomatic/reposToAddUnsorted.txt
else
    awk 'NR==FNR{a[$0];next} !($0 in a)' /tmp/batchomatic/currentlyaddedrepos.txt /tmp/batchomatic/wantedReposRaw.txt > /tmp/batchomatic/reposToAddUnsorted.txt
fi
sort -u /tmp/batchomatic/reposToAddUnsorted.txt >> /tmp/batchomatic/reposToAddSorted.txt

if [ "$1" = 2 ]; then
    result=$( grep "http://apt.thebigboss.org/repofiles/cydia/" /tmp/batchomatic/reposToAddSorted.txt )
    if [ -n "$result" ]; then
        echo "http://apt.thebigboss.org/repofiles/cydia/" >> /tmp/batchomatic/wantedDefaultRepos.txt
        grep -v "http://apt.thebigboss.org/repofiles/cydia/" /tmp/batchomatic/reposToAddSorted.txt > /tmp/batchomatic/reposTemporary.txt
        mv /tmp/batchomatic/reposTemporary.txt /tmp/batchomatic/reposToAddSorted.txt
    fi

    result=$( grep "http://apt.modmyi.com/" /tmp/batchomatic/reposToAddSorted.txt )
    if [ -n "$result" ]; then
        echo "http://apt.modmyi.com/" >> /tmp/batchomatic/wantedDefaultRepos.txt
        grep -v "http://apt.modmyi.com/" /tmp/batchomatic/reposToAddSorted.txt > /tmp/batchomatic/reposTemporary.txt
        mv /tmp/batchomatic/reposTemporary.txt /tmp/batchomatic/reposToAddSorted.txt
    fi

    result=$( grep "http://cydia.zodttd.com/repo/cydia/" /tmp/batchomatic/reposToAddSorted.txt )
    if [ -n "$result" ]; then
        echo "http://cydia.zodttd.com/repo/cydia/" >> /tmp/batchomatic/wantedDefaultRepos.txt
        grep -v "http://cydia.zodttd.com/repo/cydia/" /tmp/batchomatic/reposToAddSorted.txt > /tmp/batchomatic/reposTemporary.txt
        mv /tmp/batchomatic/reposTemporary.txt /tmp/batchomatic/reposToAddSorted.txt
    fi
    mv /tmp/batchomatic/reposToAddSorted.txt /tmp/batchomatic/reposDefaultSourcesHandled.txt
elif [ "$1" = 3 ]; then
    sed 's#http://apt.thebigboss.org/repofiles/cydia/#https://repounclutter.coolstar.org/#g' /tmp/batchomatic/reposToAddSorted.txt > /tmp/batchomatic/reposRepoUnclutterConverted.txt
    grep -v "http://apt.modmyi.com/" /tmp/batchomatic/reposRepoUnclutterConverted.txt > /tmp/batchomatic/reposNoModyMyI.txt
    grep -v "http://cydia.zodttd.com/repo/cydia/" /tmp/batchomatic/reposNoModyMyI.txt > /tmp/batchomatic/reposNoZodTTD.txt
    sort -u /tmp/batchomatic/reposNoZodTTD.txt > /tmp/batchomatic/reposDefaultSourcesHandled.txt
else
    mv /tmp/batchomatic/reposToAddSorted.txt /tmp/batchomatic/reposDefaultSourcesHandled.txt
fi

printf %s "$(< /tmp/batchomatic/wantedDefaultRepos.txt)" > /tmp/batchomatic/defaultReposToAdd.txt
printf %s "$(< /tmp/batchomatic/reposDefaultSourcesHandled.txt)" > /tmp/batchomatic/reposToAdd.txt

if [ ! -s /tmp/batchomatic/defaultReposToAdd.txt ]; then
    rm /tmp/batchomatic/defaultReposToAdd.txt
fi
if [ ! -s /tmp/batchomatic/reposToAdd.txt ]; then
    rm /tmp/batchomatic/reposToAdd.txt
fi

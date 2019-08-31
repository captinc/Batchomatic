#!/bin/bash

step1 () {
    rm -r /tmp/batchomatic 2>/dev/null
    mkdir /tmp/batchomatic
    timestamp="`date +"%Y.%m.%d-%H.%M.%S"`"
    echo $timestamp >> /tmp/batchomatic/timestampWithNewline.txt
    printf %s "$(< /tmp/batchomatic/timestampWithNewline.txt)" > /tmp/batchomatic/timestamp.txt
    echo "LOG: completed initial setup"
}
step2 () {
    mkdir /tmp/batchomatic/create
    mkdir /tmp/batchomatic/create/DEBIAN
    cp /Library/batchomatic/directions /tmp/batchomatic/create/DEBIAN/postinst
    mkdir /tmp/batchomatic/create/var
    mkdir /tmp/batchomatic/create/var/mobile
    mkdir /tmp/batchomatic/create/var/mobile/BatchInstall
    mkdir /tmp/batchomatic/create/var/mobile/BatchInstall/SavedDebs
    echo "LOG: completed filesystem setup"
}
step3 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    versionNumber=`dpkg-query --showformat='${Version}\n' --show com.captinc.batchomatic`
    echo "Package: com.you.batchinstall" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Name: BatchInstall - Online" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Version: $timestamp" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Author: You" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Maintainer: You" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Architecture: iphoneos-arm" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Section: Tweaks" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Description: Batch-install all of your tweaks for your setup! Created using Batchomatic v$versionNumber" >> /tmp/batchomatic/create/DEBIAN/control
    echo "LOG: created control file"
}
step4 () {
    apt-cache depends com.you.batchinstall | awk -F "Depends: " '/Depends: /{print $2}' > /tmp/batchomatic/alltweaks.txt
    awk 'NR==FNR{a[$0];next} !($0 in a)' /Library/batchomatic/ignoredtweaks.txt /tmp/batchomatic/alltweaks.txt > /tmp/batchomatic/tweaksWithoutIgnores.txt
    sed -i 's|[<>,]||g' /tmp/batchomatic/tweaksWithoutIgnores.txt
    printf %s "$(< /tmp/batchomatic/tweaksWithoutIgnores.txt)" > /tmp/batchomatic/create/var/mobile/BatchInstall/tweaks.txt
    echo "LOG: gathered tweaks"
}
step5 () {
    cat /etc/apt/sources.list.d/*.list /etc/apt/cydiasources.d/*.list /var/mobile/Library/Application\ Support/xyz.willy.Zebra/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null >> /tmp/batchomatic/reposRaw.txt
    ls "/var/mobile/Library/Application Support/Installer/SourcesFiles" 2>/dev/null | sed 's:_:/:g' | sed 's:\(.*\)-Packages:\1:' >> /tmp/batchomatic/reposWithSlash.txt
    egrep -o 'https?://[^ ]+' /tmp/batchomatic/reposRaw.txt >> /tmp/batchomatic/reposExtracted.txt
    sed 's:/\?$:/:g' /tmp/batchomatic/reposExtracted.txt >> /tmp/batchomatic/reposWithSlash.txt
    sed 's#https://repounclutter.coolstar.org/#http://apt.thebigboss.org/repofiles/cydia/#g' /tmp/batchomatic/reposWithSlash.txt > /tmp/batchomatic/reposRepoUnclutterConverted.txt
    sort -u /tmp/batchomatic/reposRepoUnclutterConverted.txt >> /tmp/batchomatic/reposSorted.txt
    awk 'NR==FNR{a[$0];next} !($0 in a)' /Library/batchomatic/ignoredrepos.txt /tmp/batchomatic/reposSorted.txt > /tmp/batchomatic/reposWithoutIgnores.txt
    sort -u /tmp/batchomatic/reposWithoutIgnores.txt >> /tmp/batchomatic/reposReSorted.txt
    printf %s "$(< /tmp/batchomatic/reposReSorted.txt)" > /tmp/batchomatic/create/var/mobile/BatchInstall/repos.txt
    echo "LOG: gathered repos"
}
step6 () {
    batchomaticd 9
    hostsFile=/var/mobile/BatchInstall/hosts
    if test -f "$hostsFile"; then
    cp -r /var/mobile/BatchInstall/TweakPreferences /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences
    cp /var/mobile/BatchInstall/hosts /tmp/batchomatic/create/var/mobile/BatchInstall
    else
    cp -r /var/mobile/BatchInstall /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences
    batchomaticd 1
    fi

    batchomaticd 8
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/com.apple* 2>/dev/null
    cp /var/mobile/Library/Caches/libactivator.plist /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/libactivator.exported.plist 2>/dev/null
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/.Global* 2>/dev/null
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/com.google* 2>/dev/null
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/group.com.apple* 2>/dev/null
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/com.saurik.Cydia.plist 2>/dev/null
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/nfcd.plist 2>/dev/null
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/TVRemoteConnectionService.plist 2>/dev/null
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/UITextInputContextIdentifiers.plist 2>/dev/null
    find /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences -maxdepth 1 -name "*groups.com.apple*" -delete 2>/dev/null
    echo "LOG: gathered tweak preferences"
}
step7 () {
    batchomaticd 2
    echo "LOG: gathered hosts file"
}
step8 () {
    cp /var/mobile/BatchomaticDebs/UserSavedDebs/* /tmp/batchomatic/create/var/mobile/BatchInstall/SavedDebs 2>/dev/null
    echo "LOG: gathered saved debs"
}
step9 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    find /tmp/batchomatic/create -name ".DS_Store" -type f -delete 2>/dev/null
    echo "LOG: building final deb"
    dpkg -b /tmp/batchomatic/create /var/mobile/BatchomaticDebs/batchinstall-online-$timestamp.deb
}
step10 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    echo "batchinstall-online-$timestamp.deb" > /tmp/batchomatic/nameOfDeb.txt
    echo "LOG: complete"
}

if [ "$1" = 1 ]; then
    step1
elif [ "$1" = 2 ]; then
    step2
elif [ "$1" = 3 ]; then
    step3
elif [ "$1" = 4 ]; then
    step4
elif [ "$1" = 5 ]; then
    step5
elif [ "$1" = 6 ]; then
    step6
elif [ "$1" = 7 ]; then
    step7
elif [ "$1" = 8 ]; then
    step8
elif [ "$1" = 9 ]; then
    step9
elif [ "$1" = 10 ]; then
    step10
elif [ "$1" = 0 ]; then
    step1
    step2
    step3
    step4
    step5
    step6
    step7
    step8
    step9
    step10
fi

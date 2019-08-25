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
    mkdir /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences
    mkdir /tmp/batchomatic/create/var/mobile/BatchInstall/SavedDebs
    mkdir /tmp/batchomatic/create/var/mobile/BatchInstall/OfflineDebs
    echo "LOG: completed filesystem setup"
}

step3 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    versionNumber=`dpkg-query --showformat='${Version}\n' --show com.captinc.batchomatic`
    echo "Package: com.you.batchinstall" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Name: BatchInstall - Offline" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Version: $timestamp" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Author: You" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Maintainer: You" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Architecture: iphoneos-arm" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Section: Tweaks" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Description: Batch-install the .debs of your tweaks, offline! Created using Batchomatic v$versionNumber" >> /tmp/batchomatic/create/DEBIAN/control
    echo "LOG: created control file"
}

step4 () {
    cp -R `ls -d /var/mobile/Library/Preferences/* | grep -v 'com.apple'` /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences
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

step5 () {
    batchomaticd 1
    batchomaticd 2
    echo "LOG: gathered hosts file"
}

step6 () {
    cp /var/mobile/BatchomaticDebs/UserSavedDebs/* /tmp/batchomatic/create/var/mobile/BatchInstall/SavedDebs 2>/dev/null
    echo "LOG: gathered saved debs"
}

step7 () {
    dpkg -l | awk '/^[hi]i/{print $2}' > /tmp/batchomatic/alltweaks.txt
    awk 'NR==FNR{a[$0];next} !($0 in a)' /Library/batchomatic/ignoredtweaks.txt /tmp/batchomatic/alltweaks.txt > /tmp/batchomatic/tweaksWithoutIgnores.txt
    sed '/^gsc./ d' /tmp/batchomatic/tweaksWithoutIgnores.txt > /tmp/batchomatic/tweaksWithNewline.txt
    printf %s "$(< /tmp/batchomatic/tweaksWithNewline.txt)" > /tmp/batchomatic/tweaks.txt
    mkdir /tmp/batchomatic/builddeb
}

step8() {
    eachTweak=$1
    mkdir /tmp/batchomatic/builddeb/DEBIAN

    dpkg-query -s $eachTweak | grep -v Status >> /tmp/batchomatic/builddeb/DEBIAN/control

    debianScripts=`ls /Library/dpkg/info | grep $eachTweak | grep -v ".list" | grep -v ".md5sums"`
    for eachScript in $debianScripts
    do
        cp -p /Library/dpkg/info/$eachScript /tmp/batchomatic/builddeb/DEBIAN
        normalNameOfScript=`ls /tmp/batchomatic/builddeb/DEBIAN | grep $eachScript | awk '{print $NF}' FS=.`
        mv /tmp/batchomatic/builddeb/DEBIAN/$eachScript /tmp/batchomatic/builddeb/DEBIAN/$normalNameOfScript
    done

    firstLineOfOutput=`dpkg-query -L $eachTweak | head -n 1`
    if [ $firstLineOfOutput == "/." ]; then
        filesToCopy=`dpkg-query -L $eachTweak | tail -n +2`
    else
        filesToCopy=`dpkg-query -L $eachTweak`
    fi

    for aFile in $filesToCopy
    do
        if [ -d "$aFile" ]; then
            mkdir -p "/tmp/batchomatic/builddeb$aFile"
        elif [ -f "$aFile" ]; then
            cp -p $aFile "/tmp/batchomatic/builddeb$aFile"
        fi
    done

    find /tmp/batchomatic/builddeb -name ".DS_Store" -type f -delete 2>/dev/null
    dpkg -b /tmp/batchomatic/builddeb /tmp/batchomatic/create/var/mobile/BatchInstall/OfflineDebs
    rm -r /tmp/batchomatic/builddeb/*
    echo "LOG: created deb of one tweak"
}

step9 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    find /tmp/batchomatic/create -name ".DS_Store" -type f -delete 2>/dev/null
    echo "LOG: building final deb"
    dpkg -b /tmp/batchomatic/create /var/mobile/BatchomaticDebs/batchinstall-offline-$timestamp.deb
}

step10 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    echo "batchinstall-offline-$timestamp.deb" > /tmp/batchomatic/nameOfDeb.txt
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
    step8 $2
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

    while read aLine; do
        step8 $aLine
    done < /tmp/batchomatic/tweaks.txt

    step9
    step10
fi

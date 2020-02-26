#!/bin/bash

step1 () {
    rm -r /tmp/batchomatic
    mkdir /tmp/batchomatic
    echo "`date +"%Y.%m.%d-%H.%M.%S"`" >> /tmp/batchomatic/timestampWithNewline.txt
    echo -n "`cat /tmp/batchomatic/timestampWithNewline.txt`" > /tmp/batchomatic/timestamp.txt
    echo "LOG: Completed initial setup"
}

step2 () {
    mkdir -p /tmp/batchomatic/create/DEBIAN
    mkdir -p /tmp/batchomatic/create/var/mobile/BatchInstall/SavedDebs
    cp /Library/Batchomatic/directions /tmp/batchomatic/create/DEBIAN/postinst
    echo "LOG: Completed filesystem setup"
}

step3 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    batchomaticVersion=`dpkg-query --showformat='${Version}\n' --show com.captinc.batchomatic`
    iOSVersion=`sw_vers | grep ProductVersion | sed 's/ProductVersion: //'`
    echo "Package: com.you.batchinstall" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Name: BatchInstall - Online" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Version: "$timestamp"" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Author: You" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Maintainer: You" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Architecture: iphoneos-arm" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Section: Tweaks" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Description: Batch install all of your tweaks for your setup! Created using Batchomatic v"$batchomaticVersion" and iOS "$iOSVersion"" >> /tmp/batchomatic/create/DEBIAN/control
    echo "LOG: Created control file"
}

step4 () {
    if [ -z "$1" ]; then
        motherPath="/tmp/batchomatic"
    else
        motherPath="$1"
    fi
    
    dpkg --get-selections > $motherPath/rawtweaks.txt
    grep -v deinstall $motherPath/rawtweaks.txt > $motherPath/noDeinstalls.txt
    grep -v gsc. $motherPath/noDeinstalls.txt > $motherPath/noGsc.txt
    grep -o '^\S*' $motherPath/noGsc.txt > $motherPath/alltweaks.txt
    sort -u $motherPath/alltweaks.txt > $motherPath/tweaksSorted.txt
    sed -e :a -e '/./,$!d;/^\n*$/{$d;N;};/\n$/ba' $motherPath/tweaksSorted.txt > $motherPath/tweaksTrimmed.txt
    diff --changed-group-format="%>" --unchanged-group-format="" /Library/Batchomatic/ignoredtweaks.txt $motherPath/tweaksTrimmed.txt > $motherPath/tweaksWithoutIgnores.txt
    sort -u $motherPath/tweaksWithoutIgnores.txt > $motherPath/tweaksReSorted.txt
    theCommand="cat ${motherPath}/tweaksReSorted.txt"
    echo -n "`eval ${theCommand}`" > $motherPath/create/var/mobile/BatchInstall/tweaks.txt
    echo "LOG: Gathered tweaks"
}

step5 () {
    cat /etc/apt/sources.list.d/*.list /etc/apt/cydiasources.d/*.list /var/mobile/Library/Application\ Support/xyz.willy.Zebra/*.list /etc/apt/sources.list.d/*.sources >> /tmp/batchomatic/reposRaw.txt
    ls "/var/mobile/Library/Application Support/Installer/SourcesFiles" | sed 's:_:/:g' | sed 's:\(.*\)-Packages:\1:' >> /tmp/batchomatic/reposWithSlash.txt
    egrep -o 'https?://[^ ]+' /tmp/batchomatic/reposRaw.txt >> /tmp/batchomatic/reposExtracted.txt
    sed 's:/\?$:/:g' /tmp/batchomatic/reposExtracted.txt >> /tmp/batchomatic/reposWithSlash.txt
    sed 's#https://repounclutter.coolstar.org/#http://apt.thebigboss.org/repofiles/cydia/#g' /tmp/batchomatic/reposWithSlash.txt > /tmp/batchomatic/reposRepoUnclutterConverted.txt
    sort -u /tmp/batchomatic/reposRepoUnclutterConverted.txt > /tmp/batchomatic/reposSorted.txt
    diff --changed-group-format="%>" --unchanged-group-format="" /Library/Batchomatic/ignoredrepos.txt /tmp/batchomatic/reposSorted.txt > /tmp/batchomatic/reposWithoutIgnores.txt
    sort -u /tmp/batchomatic/reposWithoutIgnores.txt > /tmp/batchomatic/reposReSorted.txt
    echo -n "`cat /tmp/batchomatic/reposReSorted.txt`" > /tmp/batchomatic/create/var/mobile/BatchInstall/repos.txt
    echo "LOG: Gathered repos"
}

step6 () {
    cp -r /var/mobile/Library/Preferences /tmp/batchomatic/create/var/mobile/BatchInstall
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/com.rpetrich.*.license
    rm -r /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/com.apple.*
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/systemgroup.com.apple.*
    cp /var/mobile/Library/Caches/libactivator.plist /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/libactivator.exported.plist
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/.Global*
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/com.google*
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/group.com.apple*
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/com.saurik.Cydia.plist
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/kNPProgressTrackerDomain.plist
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/nfcd.plist
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/TVRemoteConnectionService.plist
    rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/UITextInputContextIdentifiers.plist
    find /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences -maxdepth 1 -name "*groups.com.apple*" -delete
    echo "LOG: Gathered tweak preferences"
}

step7 () {
    cp /etc/hosts /tmp/batchomatic/create/var/mobile/BatchInstall
    echo "LOG: Gathered hosts file"
}

step8 () {
    cp /var/mobile/BatchomaticDebs/UserSavedDebs/* /tmp/batchomatic/create/var/mobile/BatchInstall/SavedDebs
    echo "LOG: Gathered saved debs"
}

step9 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    find /tmp/batchomatic/create -name ".DS_Store" -type f -delete
    echo "LOG: Building final deb"
    dpkg -b /tmp/batchomatic/create /tmp/batchomatic/batchinstall-online-"$timestamp".deb
}

step10 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    if ! dpkg -x /tmp/batchomatic/batchinstall-online-"$timestamp".deb /tmp/batchomatic/verify; then
        echo "everythingbroke" > /tmp/batchomatic/nameOfDeb.txt
        echo "Error: Online deb creation failed"
    else
        mv /tmp/batchomatic/batchinstall-online-"$timestamp".deb /var/mobile/BatchomaticDebs
        echo "batchinstall-online-"$timestamp".deb" > /tmp/batchomatic/nameOfDeb.txt
        echo "LOG: Done! The .deb is at /var/mobile/BatchomaticDebs"
    fi
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
elif [ "$1" = all ]; then
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
elif [ "$1" = getlist ]; then
    motherPath="/tmp/batchomaticGetList"
    mkdir -p $motherPath/create/var/mobile/BatchInstall
    step4 "$motherPath"
    mv $motherPath/create/var/mobile/BatchInstall/tweaks.txt $motherPath
fi

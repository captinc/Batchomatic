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
    mkdir -p /tmp/batchomatic/create/var/mobile/BatchInstall/OfflineDebs
    cp /Library/Batchomatic/directions /tmp/batchomatic/create/DEBIAN/postinst
    echo "LOG: Completed filesystem setup"
}

step3 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    batchomaticVersion=`dpkg-query --showformat='${Version}\n' --show com.captinc.batchomatic`
    iOSVersion=`sw_vers | grep ProductVersion | sed 's/ProductVersion: //'`
    echo "Package: com.you.batchinstall" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Name: BatchInstall - Offline" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Version: "$timestamp"" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Author: You" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Maintainer: You" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Architecture: iphoneos-arm" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Section: Tweaks" >> /tmp/batchomatic/create/DEBIAN/control
    echo "Description: Batch install .debs of your tweaks, offline! Created using Batchomatic v"$batchomaticVersion" and iOS "$iOSVersion"" >> /tmp/batchomatic/create/DEBIAN/control
    echo "LOG: Created control file"
}

step4 () {
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

step5 () {
    cp /etc/hosts /tmp/batchomatic/create/var/mobile/BatchInstall
    echo "LOG: Gathered hosts file"
}

step6 () {
    cp /var/mobile/BatchomaticDebs/UserSavedDebs/* /tmp/batchomatic/create/var/mobile/BatchInstall/SavedDebs
    echo "LOG: Gathered saved debs"
}

step7 () {
    dpkg --get-selections > /tmp/batchomatic/rawtweaks.txt
    grep -v deinstall /tmp/batchomatic/rawtweaks.txt > /tmp/batchomatic/noDeinstalls.txt
    grep -v gsc. /tmp/batchomatic/noDeinstalls.txt > /tmp/batchomatic/noGsc.txt
    grep -o '^\S*' /tmp/batchomatic/noGsc.txt > /tmp/batchomatic/alltweaks.txt
    sort -u /tmp/batchomatic/alltweaks.txt > /tmp/batchomatic/tweaksSorted.txt
    sed -e :a -e '/./,$!d;/^\n*$/{$d;N;};/\n$/ba' /tmp/batchomatic/tweaksSorted.txt > /tmp/batchomatic/tweaksTrimmed.txt
    diff --changed-group-format="%>" --unchanged-group-format="" /Library/Batchomatic/ignoredtweaks.txt /tmp/batchomatic/tweaksTrimmed.txt > /tmp/batchomatic/tweaksWithoutIgnores.txt
    sort -u /tmp/batchomatic/tweaksWithoutIgnores.txt > /tmp/batchomatic/tweaksReSorted.txt
    echo -n "`cat /tmp/batchomatic/tweaksReSorted.txt`" > /tmp/batchomatic/tweaks.txt
    echo "LOG: Gathered tweaks"
}

step8() {
    eachTweak="$1"
    rm -r /tmp/batchomatic/builddeb
    mkdir -p /tmp/batchomatic/builddeb/DEBIAN

    dpkg-query -s "$eachTweak" | grep -v Status >> /tmp/batchomatic/builddeb/DEBIAN/control
    
    debianScripts=`ls /Library/dpkg/info | grep "$eachTweak" | grep -v ".list" | grep -v ".md5sums"`
    if ! [ -z "$debianScripts" ]; then
          for eachScript in $debianScripts
          do
              scriptName=`echo "${eachScript/$'\n'}"`
              cp -p -P /Library/dpkg/info/"$scriptName" /tmp/batchomatic/builddeb/DEBIAN
              normalNameOfScript=`echo "${scriptName##*.}" | sed 's/*.*//'`
              mv /tmp/batchomatic/builddeb/DEBIAN/"$scriptName" /tmp/batchomatic/builddeb/DEBIAN/"$normalNameOfScript"
          done
    fi
    
    allFiles=`dpkg-query -L "$eachTweak"`
    firstLineOfOutput=(${allFiles[@]})
    if [ "${firstLineOfOutput[0]}" == "/." ]; then
        filesToCopy=`dpkg-query -L "$eachTweak" | sed "1 d"`
    else
        filesToCopy="$allFiles"
    fi
    OLDIFS=$IFS
    IFS=$'\n'
    for eachFile in $filesToCopy
    do
        thePath=`echo "${eachFile/$'\n'}"`
        if [ -d "$thePath" ]; then
            mkdir -p "/tmp/batchomatic/builddeb"$thePath""
        else
            if [[ $thePath =~ ^/Library/MobileSubstrate/DynamicLibraries/.*.disabled$ ]]; then
                endPath=`echo "$thePath" | sed 's/\(.*\)disabled/\1dylib/'`
                cp -p -P "$thePath" "/tmp/batchomatic/builddeb"$endPath""
            else
                cp -p -P "$thePath" "/tmp/batchomatic/builddeb"$thePath""
            fi
        fi
    done
    IFS=$OLDIFS

    find /tmp/batchomatic/builddeb -name ".DS_Store" -type f -delete
    dpkg -b /tmp/batchomatic/builddeb /tmp/batchomatic/create/var/mobile/BatchInstall/OfflineDebs
    if [ $? -eq 0 ]; then
        echo "LOG: Created deb of this tweak"
        return 0;
    else
        echo "Error: Deb creation for this tweak failed"
        return 1;
    fi
}

step9 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    find /tmp/batchomatic/create -name ".DS_Store" -type f -delete
    echo "LOG: Building final deb"
    dpkg -b /tmp/batchomatic/create /tmp/batchomatic/batchinstall-offline-"$timestamp".deb
}

step10 () {
    timestamp="`cat /tmp/batchomatic/timestamp.txt`"
    if ! dpkg -x /tmp/batchomatic/batchinstall-offline-"$timestamp".deb /tmp/batchomatic/verify; then
        echo "everythingbroke" > /tmp/batchomatic/nameOfDeb.txt
        echo "Error: Offline deb creation failed"
    else
        mv /tmp/batchomatic/batchinstall-offline-"$timestamp".deb /var/mobile/BatchomaticDebs
        echo "batchinstall-offline-"$timestamp".deb" > /tmp/batchomatic/nameOfDeb.txt
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
    step8 "$2"
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
    while read aLine; do
        step8 "$aLine"
    done < /tmp/batchomatic/tweaks.txt
    step9
    step10
elif [ "$1" = deb ]; then
    step1
    step2
    step3
    step4
    step5
    step6
    step7
    step8 "$2"
    if [ $? -eq 0 ]; then
        filename="`ls /tmp/batchomatic/create/var/mobile/BatchInstall/OfflineDebs`"
        mv /tmp/batchomatic/create/var/mobile/BatchInstall/OfflineDebs/$filename /var/mobile/BatchomaticDebs
        echo "$filename" > /tmp/batchomatic/nameOfDeb.txt
        echo "LOG: Done! The .deb is at /var/mobile/BatchomaticDebs"
    else
        echo "debcreationfailed" > /tmp/batchomatic/nameOfDeb.txt
        echo "Error: Deb creation of a specific tweak failed"
    fi
fi

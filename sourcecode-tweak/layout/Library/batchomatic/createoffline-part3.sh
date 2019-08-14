#!/bin/bash

timestamp=$1

nameOfBatchomaticDeb=`ls /tmp/batchomatic/create/var/mobile/BatchInstall/OfflineDebs | grep com.captinc.batchomatic_`
mv /tmp/batchomatic/create/var/mobile/BatchInstall/OfflineDebs/$nameOfBatchomaticDeb /tmp/batchomatic/create/var/mobile/BatchInstall/com.captinc.batchomatic.deb

cp /var/mobile/BatchomaticDebs/UserSavedDebs/* /tmp/batchomatic/create/var/mobile/BatchInstall/SavedDebs

dpkg-deb -b /tmp/batchomatic/create /var/mobile/BatchomaticDebs/batchinstall-$timestamp.deb
rm -r /tmp/batchomatic

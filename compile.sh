#!/bin/bash

find . -name ".DS_Store" -type f -delete
cd ./sourcecode-daemon
make package FINALPACKAGE=1
dpkg -x ./packages/*.deb ./packages
mv ./packages/usr/bin/batchomaticd ../sourcecode-tweak/layout/usr/bin
cd ..
cd ./sourcecode-tweak
make package FINALPACKAGE=1
cp ./packages/*.deb ../
cd ..
rm -r ./sourcecode-daemon/packages/usr
echo "Done!"

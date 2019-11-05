# Batchomatic v4.0
TL;DR - a tweak to batch install all of your other tweaks, repos, saved .debs, tweak preferences, and hosts file. Online or offline. Can also remove all of your tweaks, respring, and run uicache. A real time saver!

Compatible with all devices on iOS 11.0+ only. Works with Cydia, Zebra, Sileo, and Installer on unc0ver, unc0ver dark, and Chimera

Repo: **BigBoss**

Price: **Free!**

[Direct .deb download](https://github.com/captinc/batchomatic/releases/download/v4.0/com.captinc.batchomatic.deb)

[Additional information available in the reddit post](https://www.reddit.com/r/jailbreak/comments/cqarr6/release_batchomatic_v30_on_bigboss_batch_install/)

[Screenshots](https://imgur.com/a/lmu8jtY)

# How to compile
1. [Install theos](https://github.com/theos/theos/wiki/Installation-macOS) on your Mac
2. `git clone https://github.com/captinc/batchomatic.git ./Batchomatic-master`
3. `cd ./Batchomatic-master`
4. `make package`

A .deb will now be in the "Batchomatic-master" folder

# License
Please do not repackage my tweak, call it your own, and then redistribute it. You can use **individual** parts of my code for your own **non-commercial** projects. There is **no** warranty for this project. If you have any questions, [PM me on reddit](https://reddit.com/u/captinc37)

# Changelog
**v4.0**
    - New UI
    - Fixed “Unexpected end of file in archive member header”
    - Added checking to ensure .debs are created properly and notifies the user if it still fails for some reason
    - Fixed issues with .debs not being created/installed properly
    - Removed Gawk dependency
    - Added compatibility with the latest version of Sileo
    - Fixed adding repos freezing in Sileo
    - Fixed not queuing tweaks in Sileo because of a problem with BigBoss/Packix/Dynastic
    - Fixed Zebra freezing while adding repos and/or not adding repos at all
    - Faster repo adding in Zebra
    - Faster time for “Install .deb”
    - sbreload for all supported iOS versions
    - Fixed not showing the unfindable tweaks screen
    - On the install screen, grey out the non-applicable switches instead of hiding them
    - Fixed random/ugly whitespace in the popups
    - Fixed lag when tapping “Install .deb” and “Help”
    - Added what iOS version a .deb is created on to the package description of BatchInstall
    - Updated what system tweaks to ignore
    - “batchdeb” is now “bmd deb com.package.name”
    - No more specifying an output path for “bmd deb”. They are automatically saved at /var/mobile/BatchomaticDebs
    - Removed “Convert old .deb” because that was meant to be a temporary transitional measure
    - Removed 32-bit/iOS 10 support (sorry. it didn’t work properly anyway)
    - MAJOR under-the-hood code improvements
    - Updated the v3.0-v.3.2 reddit posts and GitHub with the latest information

**v3.2**
    - Added description to “Remove all tweaks”
    - Added Help button that links to the release post
    - Added ability to create a deb of a single tweak via a terminal command
    - Reorganized buttons
    - Now uses sbreload only on iOS 12.0+
    - Fixed “Create .deb” taking forever
    - Fixed not including files/folders that have spaces in their name when creating an offline deb
    - Fixed not installing all tweaks when installing an offline deb
    - Fixed half-installed packages when installing an offline deb
    - Fixed Sileo not showing the Batchomatic button when the system language is not English

**v3.1**
    - Added ability to immediately share created .debs
    - Added progress messages to Create .deb/Convert .deb/Create offline .deb
    - Added ability to keep Filza, package managers, and Batchomatic itself when using "Remove all tweaks" option
    - Now backs up all .list/.sources files
    - Changed naming scheme to specify online vs offline in the filename of batchinstall
    - Fixed trying to install Zebra's/Installer's .deb when using Zebra/Installer, which resulted in a crash
    - Fixed falsely saying "your .deb is in online mode" when in fact its not installed at all
    - Stomped on the bug that backed up com.you.batchinstall inside com.you.batchinstall
    - Blew up .DS_Store issues
    - Squashed the bug about not installing saved/offline debs
    - Taught Activator how to back up/restore its settings properly
    - Slaps Cydia when it displays "Half-installed packages" while using Batchomatic
    - Slaps Sileo when it doesn't show the Batchomatic button
    - Improved code

**v3.0.1**
    - Fixed a UI bug

**v3.0**
    - Complete, total revamp
    - Added support for A12, Chimera, Zebra, Sileo, and Installer
    - Added backing up repos
    - Added backing up saved .debs
    - Added offline mode
    - Added "Remove all tweaks" feature
    - Added "Respring/uicache" feature
    - Added a proper UI
    - Fixed not backing up hosts file
    - Fixed iCleaner removing all tweaks when "Remove unused dependencies" was turned on
    - Made an actual tweak instead of just a terminal script
    - Moved to BigBoss

**v2.1**
    - Added official compatibilty for unc0ver dark in Cydia only
    - Added prelimnary compatibilty for Chimera and Sileo
    - Now includes dependencies of your tweaks (for upcoming Sileo support)
    - Updated what system tweaks to exclude
    - Now excludes all system tweaks that are present immediately after the first run of all 3 jailbreaks
    - Fixed the script not running due to its support files already being on your device
    - Improved code
    - Improved this depiction

**v2.0.1**
    - Removed unnecessary code

**v2.0**
    - Changed tweak name
    - Removed purposefully ignoring itself when creating a custom .deb
    - Added more system tweaks to ignore
    - Now, the normal version ("Batchomatic") does NOT save your hosts file
    - The version named "Batchomatic - hosts" DOES save your hosts file
    - Added depictions
    - Simplified code

**v1.0.1, 1.0.2, and 1.0.3**
    - Added more system tweaks to ignore

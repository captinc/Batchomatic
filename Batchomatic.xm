#import "Headers/Batchomatic.h"
#import "Headers/BMHomeTableViewController.h"
#import "Headers/NSTask.h"
extern int refreshesCompleted; //This variable tells my tweak if we are currently adding repos so it can detect when adding repos is finished. Because it needs to survive Batchomatic being dismissed & reopened, it must be a global extern C variable instead of an @property
int refreshesCompleted = 0;

@implementation Batchomatic
+ (instancetype)sharedInstance { //Returns the instance of the Batchomatic class so you can access this code from anywhere
    static Batchomatic *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

+ (void)placeButton:(UIViewController *)sender { //Creates the Batchomatic button from my icon and places it in the navigation bar
    NSBundle *bundle = [NSBundle bundleWithPath:@"/Library/Batchomatic/Icon.bundle"]; //you should use a bundle to get the icon and provide @3x and @2x versions. that way, iOS can choose the best resolution for your device
    UIImage *icon = [[UIImage imageNamed:@"Icon" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:icon forState:UIControlStateNormal];
    [btn addTarget:sender action:@selector(startBatchomatic) forControlEvents:UIControlEventTouchUpInside];
    sender.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
}

+ (void)openMainScreen:(UIViewController *)sender { //Opens the main Batchomatic UI
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[BMHomeTableViewController alloc] init]];
    [sender presentViewController:nav animated:YES completion:nil];
}

//--------------------------------------------------------------------------------------------------------------------------
//methods for the UI of creating/installing a .deb
- (void)createDeb:(int)type withMotherMessage:(NSString *)motherMessage { //Creates a .deb with all of the necessary information. A few other methods need to be called before calling this one. See BMHomeTableViewController.xm for more info
    NSArray *onlineSteps = @[@"Running initial setup", @"Setting up filesystem", @"Creating control file", @"Gathering tweaks", @"Gathering repos", @"Gathering tweak preferences", @"Gathering hosts file", @"Gathering saved debs", @"Building final deb", @"Verifying deb"];
    NSArray *offlineSteps = @[@"Running initial setup", @"Setting up filesystem", @"Creating control file", @"Gathering tweak preferences", @"Gathering hosts file", @"Gathering saved debs", @"Preparing", @"Building final deb", @"Verifying deb"];
    
    if (type == 1) { //type 1 means an online .deb with tweaks, repos, saved .debs, tweak preferences, and hosts file
        for (int x = 0; x < 10; x++) {
            [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, [onlineSteps objectAtIndex:x]]];
            [self runCommand:[NSString stringWithFormat:@"bmd online %d", (x+1)]];
        }
    }
    else { //type 2 means an offline .deb with .debs of your tweaks, saved .debs, tweak preferences, and hosts file. A plain list of repos/tweaks is not included
        for (int x = 0; x < 7; x++) {
            [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, [offlineSteps objectAtIndex:x]]];
            [self runCommand:[NSString stringWithFormat:@"bmd offline %d", (x+1)]];
        }
        
        motherMessage = [self updateProgressMessage:@"Creating .debs of your tweaks. This could take several minutes...."];
        FILE *tweaksToCreateDebsForFile = fopen("/tmp/batchomatic/tweaks.txt", "r");
        while (!feof(tweaksToCreateDebsForFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:tweaksToCreateDebsForFile];
            [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@%@", motherMessage, @"\n", thePackageIdentifer]];
            [self runCommand:[NSString stringWithFormat:@"bmd offline 8 %@", thePackageIdentifer]];
        }
        fclose(tweaksToCreateDebsForFile);
        
        motherMessage = [self updateProgressMessage:@"Creating your offline .deb....\n"];
        for (int x = 7; x < 9; x++) {
            [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, [offlineSteps objectAtIndex:x]]];
            [self runCommand:[NSString stringWithFormat:@"bmd offline %d", (x+2)]];
        }
    }
    
    FILE *file = fopen("/tmp/batchomatic/nameOfDeb.txt", "r"); //ensures the created deb is valid and usable
    NSString *debFileName = [self readEachLineOfFile:file];
    fclose(file);
    if ([debFileName isEqualToString:@"everythingbroke"]) {
        [self transitionProgressMessage:@"Error: creation of your .deb failed\nTry deleting /var/mobile/Library/Preferences/com.rpetrich.pictureinpicture.license, /var/mobile/Library/Preferences/BackupAZ3, and /var/mobile/Library/Preferences/Slices. Then try again\n\nIf that does not fix it, please contact me: https://reddit.com/u/captinc37"];
        [self.spinner stopAnimating];
        UIAlertAction *contactAction = [UIAlertAction actionWithTitle:@"Contact developer" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSDictionary *options = @{UIApplicationOpenURLOptionUniversalLinksOnly:@NO};
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/message/compose/?to=captinc37&subject=Batchomatic%20creation%20error"] options:options completionHandler:nil];
        }];
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
        [self.processingDialog addAction:contactAction];
        [self.processingDialog addAction:dismissAction];
    }
    else {
        [self showFinishedCreatingDialog:debFileName];
    }
}

- (void)calculateMaxStepsForInstalling { //Calculates how many stages there will be based on what toggles the user turned on. This method is only called when installing a .deb
    self.maxSteps = 0;
    if (self.prefsSwitchStatus == true) {
        self.maxSteps++;
    }
    if (self.savedDebsSwitchStatus == true) {
        self.maxSteps++;
    }
    if (self.hostsSwitchStatus == true) {
        self.maxSteps++;
    }
    if (self.debIsOnline) {
        if (self.reposSwitchStatus == true) {
            self.maxSteps++;
        }
        if (self.tweaksSwitchStatus == true) {
            self.maxSteps++;
        }
    }
    else {
        if (self.offlineTweaksSwitchStatus == true) {
            self.maxSteps++;
        }
    }
}

- (void)installDeb { //Actually performs the actions that the user wants. A few other methods need to be called before calling this one. See BMInstallTableViewController.xm for more info
    if (self.prefsSwitchStatus == true) {
        [self updateProgressMessage:@"Installing preferences...."];
        [self runCommand:@"bmd installprefs"];
        [self runCommand:@"bmd installactivatorprefs"];
    }
    if (self.hostsSwitchStatus == true) {
        [self updateProgressMessage:@"Installing hosts...."];
        [self runCommand:@"bmd installhosts"];
    }
    if (self.savedDebsSwitchStatus == true) {
        NSString *motherMessage = [self updateProgressMessage:@"Installing saved .debs...."];
        [self runCommand:@"bmd chperms1"];
        [self installAllDebsInFolder:@"/var/mobile/BatchInstall/SavedDebs" withMotherMessage:motherMessage];
    }
    if (self.offlineTweaksSwitchStatus == true) {
        NSString *motherMessage = [self updateProgressMessage:@"Installing offline .debs...."];
        [self runCommand:@"bmd chperms2"];
        [self installAllDebsInFolder:@"/var/mobile/BatchInstall/OfflineDebs" withMotherMessage:motherMessage];
    }
    if (self.reposSwitchStatus == true) {
        [self updateProgressMessage:@"Adding repos...."];
        [self addRepos];
        return;
    }
    if (self.tweaksSwitchStatus == true) {
        [self processingReposDidFinish:true];
        return;
    }
    [self endProcessingDialog:@"Done! Succesfully installed your .deb!" transition:true shouldOpenBMHomeViewControllerFirst:false];
}

//--------------------------------------------------------------------------------------------------------------------------
//methods for the back-end of installing a .deb
- (void)installAllDebsInFolder:(NSString *)pathToDebsFolder withMotherMessage:(NSString *)motherMessage { //Installs all .debs at the given folder and updates the UIAlertController about what .deb is being installed right now. This interfaces with the binary I made to run a command as root (see the 'bmd' folder)
    [self runCommand:@"bmd rmtemp"];
    [self runCommand:@"mkdir -p /tmp/batchomatic/tempdebs"];
    [self runCommand:[NSString stringWithFormat:@"mv %@%@", pathToDebsFolder, @"/com.captinc.batchomatic*.deb /tmp/batchomatic/tempdebs"]]; //if we install the .deb for the currently-in-use package manager, it will crash
    if (self.packageManager == 2) {
        [self runCommand:[NSString stringWithFormat:@"mv %@%@", pathToDebsFolder, @"/xyz.willy.zebra*.deb /tmp/batchomatic/tempdebs"]];
    }
    if (self.packageManager == 4) {
        [self runCommand:[NSString stringWithFormat:@"mv %@%@", pathToDebsFolder, @"/me.apptapp.installer*.deb /tmp/batchomatic/tempdebs"]];
    }
    
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:pathToDebsFolder];
    for (NSString *debFileName in directoryEnumerator) {
        if ([[debFileName pathExtension] isEqualToString:@"deb"]) {
            NSString *thePackageIdentifer = [self runCommand:[NSString stringWithFormat:@"prefix=\" Package: \" && dpkg --info %@%@%@%@", pathToDebsFolder, @"/", debFileName, @" | grep \"Package: \" | sed -e \"s/^$prefix//\""]];
            [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@%@", motherMessage, @"\n", thePackageIdentifer]];
            [self runCommand:[NSString stringWithFormat:@"bmd installdeb %@%@%@", pathToDebsFolder, @"/", debFileName]]; //FYI, "bmd" means "batchomatic daemon" or "batchomaticd"
        }
    }
    
    [self runCommand:@"bmd dpkgconfig"];
    [self runCommand:[NSString stringWithFormat:@"mv /tmp/batchomatic/tempdebs/*.deb %@", pathToDebsFolder]];
    [self runCommand:@"rm -r /tmp/batchomatic"];
}

- (void)addRepos { //Adds all of the user's repos to the current package manager if they are not already added. Code for this feature is continued in my %hooks and then comes back to "- (void)processingReposDidFinish:" in this file. This is because we need to wait for repos to finish adding before we can proceed
    refreshesCompleted = 1; //global extern C variable
    [self runCommand:[NSString stringWithFormat:@"bmd addrepos %d", self.packageManager]];
    FILE *listOfReposFile = fopen("/tmp/batchomatic/reposToAdd.txt", "r");
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/batchomatic/reposToAdd.txt" isDirectory:NULL]) { //this bash script determines what repos we want versus what repos are already added
        if (self.packageManager == 1) { //if we are using Cydia
            Cydia *cydiaDelegate = (Cydia *)[[UIApplication sharedApplication] delegate];
            while (!feof(listOfReposFile)) {
                NSString *eachRepo = [self readEachLineOfFile:listOfReposFile];
                if ([eachRepo isEqualToString:@"http://apt.thebigboss.org/repofiles/cydia/"] || [eachRepo isEqualToString:@"http://apt.modmyi.com/"] || [eachRepo isEqualToString:@"http://cydia.zodttd.com/repo/cydia/"]) {
                    NSDictionary *dictionary = @{@"Distribution":@"stable", @"Sections":[NSArray arrayWithObject:@"main"], @"Type":@"deb", @"URI":eachRepo};
                    [cydiaDelegate addSource:dictionary];
                }
                else {
                    [cydiaDelegate addTrivialSource:eachRepo];
                }
            }
            [cydiaDelegate requestUpdate]; //must refresh Cydia sources twice for changes to take effect. see Tweak.xm for more info
        }
        
        else if (self.packageManager == 2) { //if we are using Zebra
            NSURL *url = [NSURL fileURLWithPath:@"/tmp/batchomatic/reposToAdd.txt"]; 
            [self.processingDialog dismissViewControllerAnimated:YES completion:^{
                [self.bm_BMInstallTableViewController dismissViewControllerAnimated:YES completion:^{
                    [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                        [self.zebra_ZBSourceListTableViewController handleImportOf:url];
                    }];
                }];
            }];
        }
        
        else if (self.packageManager == 3) { //if we are using Sileo
            NSMutableArray *reposToAdd = [[NSMutableArray alloc] init];
            while (!feof(listOfReposFile)) {
                NSString *eachRepo = [self readEachLineOfFile:listOfReposFile];
                NSURL *eachRepoAsURL = [NSURL URLWithString:eachRepo];
                [reposToAdd addObject:eachRepoAsURL];
            }
            [[%c(_TtC5Sileo11RepoManager) shared] addReposWith:reposToAdd];
            
            UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
            [self.sileo_SourcesViewController refreshSources:refreshControl];
        }
        
        else if (self.packageManager == 4) { //if we are using Installer
            while (!feof(listOfReposFile)) {
                NSString *eachRepo = [self readEachLineOfFile:listOfReposFile];
                [self.installer_ManageViewController addSourceWithString:eachRepo withHttpApproval:true];
            }
            
            [self.processingDialog dismissViewControllerAnimated:YES completion:^{
                [self.bm_BMInstallTableViewController dismissViewControllerAnimated:YES completion:^{
                    [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                        [self.installer_ATTabBarController presentTasks];
                    }];
                }];
            }];
        }
    }
    else {
        [self processingReposDidFinish:true];
    }
    fclose(listOfReposFile);
    [self runCommand:@"bmd rmtemp"];
}

- (void)processingReposDidFinish:(bool)shouldTransition { //After each package manager finishes adding repos, this method is called to continue running Batchomatic
    refreshesCompleted = 0;
    if (self.isRemovingRepos) { //this means the package manager finished removing repos
        self.isRemovingRepos = false;
        [self endProcessingDialog:@"Done! Succesfully removed all repos!" transition:shouldTransition shouldOpenBMHomeViewControllerFirst:false];
    }
    else { //this means the package manager finished adding repos
        if (self.tweaksSwitchStatus == true) {
            if (shouldTransition) {
                [self updateProgressMessage:@"Queuing tweaks...."];
                [self queueTweaks:shouldTransition];
            }
            else {
                [self showProcessingDialog:@"Queuing tweaks...." includeStage:true startingStep:(self.currentStep + 1) autoPresent:false];
                [self.motherClass presentViewController:self.processingDialog animated:YES completion:^{
                    [self queueTweaks:shouldTransition];
                }];
            }
        }
        else {
            [self endProcessingDialog:@"Done! Succesfully installed your .deb!" transition:shouldTransition shouldOpenBMHomeViewControllerFirst:!shouldTransition];
        }
    }
}

- (void)showUnfindableTweaks:(NSMutableString *)unfindableTweaks transition:(bool)shouldTransition { //Displays an alert if we cannot find some of the user's tweaks. This is caused when the repo for said tweak is not added, or said tweak was previously installed from a .deb. We obviously can't queue a tweak if we can't find it
    if ([unfindableTweaks isEqualToString:@""]) {
        [self.processingDialog dismissViewControllerAnimated:YES completion:^{
            [self openQueueForCurrentPackageManager:shouldTransition];
        }];
    }
    else {
        NSString *message = [NSString stringWithFormat:@"The following tweaks could not be found:\n\n%@", unfindableTweaks];
        [self transitionProgressMessage:message];
        [self.spinner stopAnimating];
        UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy to clipboard and proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = unfindableTweaks;
            [self openQueueForCurrentPackageManager:shouldTransition];
        }];
        UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self openQueueForCurrentPackageManager:shouldTransition];
        }];
        [self.processingDialog addAction:copyAction];
        [self.processingDialog addAction:proceedAction];
    }
}

- (void)queueTweaks:(bool)shouldTransition { //Adds all of the user's tweaks to the queue if they are not already installed
    NSMutableString *unfindableTweaks = [[NSMutableString alloc] init];
    FILE *listOfTweaksFile = fopen("/var/mobile/BatchInstall/tweaks.txt", "r");
    
    if (self.packageManager == 1) { //Cydia
        while (!feof(listOfTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:listOfTweaksFile];
            Package *thePackage = (Package *)[[%c(Database) sharedInstance] packageWithName:thePackageIdentifer];
            if (thePackage != nil) {
                if ([thePackage uninstalled]) {
                    [thePackage install];
                }
            }
            else {
                [unfindableTweaks appendString:thePackageIdentifer];
                [unfindableTweaks appendString:@"\n"];
            }
        }
        
        Cydia *cydiaDelegate = (Cydia *)[[UIApplication sharedApplication] delegate];
        [cydiaDelegate resolve];
        [self showUnfindableTweaks:unfindableTweaks transition:shouldTransition];
    }
    
    else if (self.packageManager == 2) { //Zebra
        ZBDatabaseManager *zebraDatabase = [%c(ZBDatabaseManager) sharedInstance];
        ZBQueue *zebraQueue = [%c(ZBQueue) sharedQueue];
        ZBQueueType zebraInstall = ZBQueueTypeInstall;
        
        while (!feof(listOfTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:listOfTweaksFile];
            ZBPackage *thePackage = [zebraDatabase topVersionForPackageID:thePackageIdentifer];
            if (thePackage != nil) {
                if (![zebraDatabase packageIDIsInstalled:thePackageIdentifer version:nil]) {
                    [zebraQueue addPackage:thePackage toQueue:zebraInstall];
                }
            }
            else {
                [unfindableTweaks appendString:thePackageIdentifer];
                [unfindableTweaks appendString:@"\n"];
            }
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ //dispatch_after is necessary because Zebra lags when you open a queue with a ton of packages. this way, the user experiences less lag
            [self showUnfindableTweaks:unfindableTweaks transition:shouldTransition];
        });
    }
    
    else if (self.packageManager == 3) { //Sileo
        while (!feof(listOfTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:listOfTweaksFile];
            _TtC5Sileo7Package *thePackage = [[%c(_TtC5Sileo18PackageListManager) shared] newestPackageWithIdentifier:thePackageIdentifer];
            if (thePackage != nil) {
                if ([[%c(_TtC5Sileo18PackageListManager) shared] installedPackageWithIdentifier:thePackageIdentifer] == nil) {
                    [[%c(_TtC5Sileo15DownloadManager) shared] addWithPackage:thePackage queue:1];
                }
            }
            else {
                [unfindableTweaks appendString:thePackageIdentifer];
                [unfindableTweaks appendString:@"\n"];
            }
        }
        
        [[%c(_TtC5Sileo15DownloadManager) shared] reloadDataWithRecheckPackages:true];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ //dispatch_after is necessary because Sileo takes a few seconds to update the amount of dependency errors
            if ([[[%c(_TtC5Sileo15DownloadManager) shared] errors] count] != 0) { //see "- (void)sileoFixDependencies" for an explanation about this
                [self sileoFixDependencies:unfindableTweaks transition:shouldTransition];
            }
            else {
                [self showUnfindableTweaks:unfindableTweaks transition:shouldTransition];
            }
        });
    }
    
    else if (self.packageManager == 4) { //Installer
        while (!feof(listOfTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:listOfTweaksFile];
            ATRPackages *pkgs = [[%c(ATRPackageManager) sharedPackageManager] packages];
            if ([pkgs packageWithIdentifier:thePackageIdentifer] != nil) {
                if (![pkgs packageIsInstalled:thePackageIdentifer]) {
                    [pkgs setPackage:thePackageIdentifer inTheQueue:YES versionToQueue:nil operation:1];
                }
            }
            else {
                [unfindableTweaks appendString:thePackageIdentifer];
                [unfindableTweaks appendString:@"\n"];
            }
        }
        [self showUnfindableTweaks:unfindableTweaks transition:shouldTransition];
    }
    fclose(listOfTweaksFile);
}

- (void)openQueueForCurrentPackageManager:(bool)shouldTransition { //Opens the install queue for the current package manager
    if (shouldTransition) {
        [self.bm_BMInstallTableViewController dismissViewControllerAnimated:YES completion:^{
            [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                [self openQueueForCurrentPackageManager:false]; //do method recursion because I like code-reuse
            }];
        }];
    }
    else {
        if (self.packageManager == 1) {
            [(Cydia *)[[UIApplication sharedApplication] delegate] queue];
        }
        else if (self.packageManager == 2) {
            [self.zebra_ZBTabBarController openQueue:YES];
        }
        else if (self.packageManager == 3) {
            [[%c(TabBarController) singleton] presentPopupController];
        }
        else if (self.packageManager == 4) {
            [self.installer_ATTabBarController presentQueue];
        }
    }
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to make Sileo add the dependencies of your tweaks to the queue since Sileo doesn't do that by default
- (void)sileoFixDependencies:(NSMutableString *)unfindableTweaks transition:(bool)shouldTransition { //In Sileo, check for any current dependency errors, add those dependencies to the queue, and then re-check via method recursion
    [self sileoAddDependenciesToQueue];
    [[%c(_TtC5Sileo15DownloadManager) shared] reloadDataWithRecheckPackages:true];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[[%c(_TtC5Sileo15DownloadManager) shared] errors] count] != 0) {
            [self sileoFixDependencies:unfindableTweaks transition:shouldTransition]; //method recursion
        }
        else {
            [self showUnfindableTweaks:unfindableTweaks transition:shouldTransition];
        }
    });
}

- (void)sileoAddDependenciesToQueue { //Resolves any current dependency problems when queuing tweaks in Sileo. After running this method, you need to check for dependency problems again
    NSArray *sileoErrors = [[%c(_TtC5Sileo15DownloadManager) shared] errors];
    NSMutableArray *unfoundDependenciesAsArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < [sileoErrors count]; i++) {
        NSDictionary *dict = [sileoErrors objectAtIndex:i];
        [unfoundDependenciesAsArray addObject:[dict objectForKey:@"otherPkg"]];
    }
    
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:unfoundDependenciesAsArray];
    NSArray *middleMan = [orderedSet array];
    NSMutableArray *arrayWithoutDuplicates = [middleMan mutableCopy];
    if ([arrayWithoutDuplicates containsObject:@"org.thebigboss.libcolorpicker"] && [arrayWithoutDuplicates containsObject:@"me.nepeta.libcolorpicker"]) {
        [arrayWithoutDuplicates removeObject:@"org.thebigboss.libcolorpicker"];
    }
    
    for (int i = 0; i < [arrayWithoutDuplicates count]; i++) {
        NSString *thePackageIdentifer = [arrayWithoutDuplicates objectAtIndex:i];
        _TtC5Sileo7Package *thePackage = [[%c(_TtC5Sileo18PackageListManager) shared] newestPackageWithIdentifier:thePackageIdentifer];
        if (thePackage != nil) {
            if ([[%c(_TtC5Sileo18PackageListManager) shared] installedPackageWithIdentifier:thePackageIdentifer] == nil && ![[[%c(_TtC5Sileo15DownloadManager) shared] installations] containsObject:thePackage]) {
                [[%c(_TtC5Sileo15DownloadManager) shared] addWithPackage:thePackage queue:1];
            }
        }
    }
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to repack an installed tweak to a .deb and remove all tweaks and repos
- (void)repackTweakWithIdentifier:(NSString *)packageID { //Repacks the specified package identifier to a .deb
    [self runCommand:[NSString stringWithFormat:@"bmd deb %@", packageID]];
    
    FILE *file = fopen("/tmp/batchomatic/nameOfDeb.txt", "r");
    NSString *debFileName = [self readEachLineOfFile:file];
    fclose(file);
    
    if ([debFileName isEqualToString:@"debcreationfailed"]) {
        NSString *msg = [NSString stringWithFormat:@"Error: creation of the .deb for this tweak failed. This is most likely a problem with that particular tweak\n\nTry running \"bmd deb %@%@", packageID, @"\" in Terminal for more information"];
        [self transitionProgressMessage:msg];
        [self.spinner stopAnimating];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
        [self.processingDialog addAction:okAction];
    }
    else {
        [self showFinishedCreatingDialog:debFileName];
    }
}

- (void)removeAllRepos { //Removes all currently-added repos from the current package manager
    self.isRemovingRepos = true;
    NSMutableArray *ignoredRepos = [[NSMutableArray alloc] init];
    FILE *ignoredReposFile = fopen("/Library/Batchomatic/ignoredrepos.txt", "r");
    while (!feof(ignoredReposFile)) {
        NSString *aRepo = [self readEachLineOfFile:ignoredReposFile];
        
        [ignoredRepos addObject:aRepo];
    }
    fclose(ignoredReposFile);
    [ignoredRepos addObject:@"http://apt.thebigboss.org/repofiles/cydia/"];
    [ignoredRepos addObject:@"https://repounclutter.coolstar.org/"];
    
    if (self.packageManager == 1) { //Cydia
        refreshesCompleted = 1;
        NSArray *allRepos = [[[%c(Database) sharedInstance] sources] copy];
        NSArray *cannotBeRemoved = @[@"http://apt.bingner.com/", @"https://apt.bingner.com/", @"https://diatr.us/apt/"];
        for (int x = 0; x < [allRepos count]; x++) {
            NSString *url = [(Source *)[allRepos objectAtIndex:x] rooturi];
            if ([cannotBeRemoved containsObject:url]) {
                continue;
            }
            if (!self.removeAllReposSwitchStatus && [ignoredRepos containsObject:url]) {
                continue;
            }
            [(Source *)[allRepos objectAtIndex:x] remove];
        }
        [(Cydia *)[[UIApplication sharedApplication] delegate] requestUpdate];
    }
    
    else if (self.packageManager == 2) { //Zebra
        NSArray *allRepos = [[[%c(ZBDatabaseManager) sharedInstance] sources] copy];
        for (ZBBaseSource *source in allRepos) {
            if ([source.repositoryURI isEqualToString:@"https://getzbra.com/repo/"]) {
                continue;
            }
            if (!self.removeAllReposSwitchStatus && [ignoredRepos containsObject:source.repositoryURI]) {
                continue;
            }
            [[%c(ZBSourceManager) sharedInstance] deleteSource:(ZBSource *)source];
        }
        [self.zebra_ZBSourceListTableViewController refreshTable];
        [self processingReposDidFinish:true];
    }
    
    else if (self.packageManager == 3) { //Sileo
        refreshesCompleted = 1;
        NSArray *allRepos = [[%c(_TtC5Sileo11RepoManager) shared] repoList];
        NSArray *cannotBeRemoved = @[@"https://repo.chimera.sh/", @"https://diatr.us/dark/", @"https://diatr.us/sileodark/", @"https://diatr.us/apt/"];
        for (int x = 0; x < [allRepos count]; x++) {
            NSString *url = [(_TtC5Sileo4Repo *)[allRepos objectAtIndex:x] repoURL];
            if ([cannotBeRemoved containsObject:url]) {
                continue;
            }
            if (!self.removeAllReposSwitchStatus && [ignoredRepos containsObject:url]) {
                continue;
            }
            [[%c(_TtC5Sileo11RepoManager) shared] remove:(_TtC5Sileo4Repo *)[allRepos objectAtIndex:x]];
        }
        
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [self.sileo_SourcesViewController refreshSources:refreshControl];
    }
    
    else if (self.packageManager == 4) { //Installer
        NSArray *allRepos = [[(ATRSources *)[[%c(ATRPackageManager) sharedPackageManager] sources] arrayOfConfiguredSources] copy];
        for (int x = 0; x < [allRepos count]; x++) {
            NSString *url = [allRepos objectAtIndex:x];
            if ([url isEqualToString:@"https://apptapp.me/repo/"]) {
                continue;
            }
            if (!self.removeAllReposSwitchStatus && [ignoredRepos containsObject:url]) {
                continue;
            }
            [(ATRSources *)[[%c(ATRPackageManager) sharedPackageManager] sources] removeSourceWithLocation:url];
        }
        [self processingReposDidFinish:true];
    }
}

- (void)removeAllTweaks { //Queues all currently-installed tweaks for removal in the current package manager
    if (self.removeAllTweaksSwitchStatus == true) {
        [self runCommand:@"bmd removealltweaks 1"];
    }
    else {
        [self runCommand:@"bmd removealltweaks 0"];
    }
    FILE *removeAllTweaksFile = fopen("/tmp/batchomatic/removealltweaks.txt", "r");
    
    if (self.packageManager == 1) { //Cydia
        while (!feof(removeAllTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:removeAllTweaksFile];
            Package *thePackage = (Package *)[[%c(Database) sharedInstance] packageWithName:thePackageIdentifer];
            if ([thePackage installed]) {
                [thePackage remove];
            }
        }
        
        Cydia *cydiaDelegate = (Cydia *)[[UIApplication sharedApplication] delegate];
        [cydiaDelegate resolve];
        [self.processingDialog dismissViewControllerAnimated:YES completion:^{
            [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                [cydiaDelegate queue];
            }];
        }];
    }
    
    else if (self.packageManager == 2) { //Zebra
        ZBDatabaseManager *zebraDatabase = [%c(ZBDatabaseManager) sharedInstance];
        ZBQueue *zebraQueue = [%c(ZBQueue) sharedQueue];
        ZBQueueType zebraRemove = ZBQueueTypeRemove;
        
        while (!feof(removeAllTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:removeAllTweaksFile];
            ZBPackage *thePackage = [zebraDatabase topVersionForPackageID:thePackageIdentifer];
            if ([zebraDatabase packageIDIsInstalled:thePackageIdentifer version:nil]) {
                [zebraQueue addPackage:thePackage toQueue:zebraRemove];
            }
        }
        
        [self.processingDialog dismissViewControllerAnimated:YES completion:^{
            [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                [self.zebra_ZBTabBarController openQueue:YES];
            }];
        }];
    }
    
    else if (self.packageManager == 3) { //Sileo
        while (!feof(removeAllTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:removeAllTweaksFile];
            if ([[%c(_TtC5Sileo18PackageListManager) shared] installedPackageWithIdentifier:thePackageIdentifer] != nil) {
                _TtC5Sileo7Package *thePackage = [[%c(_TtC5Sileo18PackageListManager) shared] newestPackageWithIdentifier:thePackageIdentifer];
                [[%c(_TtC5Sileo15DownloadManager) shared] addWithPackage:thePackage queue:2];
            }
        }
        
        [[%c(_TtC5Sileo15DownloadManager) shared] reloadDataWithRecheckPackages:true];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.processingDialog dismissViewControllerAnimated:YES completion:^{
                [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                    [[%c(TabBarController) singleton] presentPopupController];
                }];
            }];
        });
    }
    
    else if (self.packageManager == 4) { //Installer
        while (!feof(removeAllTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:removeAllTweaksFile];
            ATRPackages *pkgs = [[%c(ATRPackageManager) sharedPackageManager] packages];
            if ([pkgs packageIsInstalled:thePackageIdentifer]) {
                [pkgs setPackage:thePackageIdentifer inTheQueue:YES versionToQueue:nil operation:2];
            }
        }
        
        [self.processingDialog dismissViewControllerAnimated:YES completion:^{
            [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                [self.installer_ATTabBarController presentQueue];
            }];
        }];
    }
    fclose(removeAllTweaksFile);
    [self runCommand:@"bmd rmtemp"];
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to handle presenting/dismissing the processing dialog
- (NSString *)showProcessingDialog:(NSString *)wordMessage includeStage:(bool)includeStage startingStep:(int)startingStep autoPresent:(bool)shouldAutoPresentDialog { //Displays a UIAlertController with stages (for example: "Stage 1/4"), what we are doing, and a UIActivityIndicator/spinning wheel
    NSString *totalMessage;
    if (includeStage) {
        self.currentStep = startingStep;
        NSString *currentStepAsString = [NSString stringWithFormat:@"%d", self.currentStep];
        NSString *maxStepsAsString = [NSString stringWithFormat:@"%d", self.maxSteps];
        totalMessage = [NSString stringWithFormat:@"Stage %@%@%@%@%@", currentStepAsString, @"/", maxStepsAsString, @"\n", wordMessage];
    }
    else {
        totalMessage = wordMessage;
    }
    self.processingDialog = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:totalMessage preferredStyle:UIAlertControllerStyleAlert];
    
    UIActivityIndicatorView *spinner; //create a UIActivityIndicator inside a UIAlertController
    if (@available(iOS 13, *)) {
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    }
    else {
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    UIViewController *spinnerVC = [[UIViewController alloc] init];
    [spinnerVC.view addSubview:spinner];
    
    UILayoutGuide *margin = spinnerVC.view.layoutMarginsGuide; //center the UIActivityIndicator
    [spinner.centerXAnchor constraintEqualToAnchor:margin.centerXAnchor].active = YES;
    [spinner.centerYAnchor constraintEqualToAnchor:margin.centerYAnchor].active = YES;
    
    [self.processingDialog setValue:spinnerVC forKey:@"contentViewController"];
    spinner.hidesWhenStopped = YES;
    [spinner startAnimating];
    self.spinner = spinner;
    if (shouldAutoPresentDialog) {
        [self.bm_currentBMController presentViewController:self.processingDialog animated:YES completion:nil];
    }
    return totalMessage;
}

- (void)transitionProgressMessage:(NSString *)theMessage { //Only transitions the text of the processing dialog
    [UIView transitionWithView:self.processingDialog.view duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void) {
        self.processingDialog.message = theMessage;
    } completion:nil];
}

- (NSString *)updateProgressMessage:(NSString *)wordMessage { //Increments what stage we are on and transitions the text
    self.currentStep++;
    NSString *currentStepAsString = [NSString stringWithFormat:@"%d", self.currentStep];
    NSString *maxStepsAsString = [NSString stringWithFormat:@"%d", self.maxSteps];
    NSString *totalMessage = [NSString stringWithFormat:@"Stage %@%@%@%@%@", currentStepAsString, @"/", maxStepsAsString, @"\n", wordMessage];
    [self transitionProgressMessage:totalMessage];
    return totalMessage;
}

- (void)endProcessingDialog:(NSString *)theMessage transition:(bool)shouldTransition shouldOpenBMHomeViewControllerFirst:(bool)shouldOpenBMHomeViewControllerFirst { //Removes the UIActivityIndicator, transitions the text, and asks the user if they want to uicache/respring. This method can either present a whole new UIAlertController or transition an existing one
    UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (self.uicacheSwitchStatus == true && self.respringSwitchStatus == false) {
            [self showProcessingDialog:@"Running uicache...." includeStage:false startingStep:1 autoPresent:true];
            [self runCommand:@"uicache --all"];
            
            [self transitionProgressMessage:@"Done!"];
            [self.spinner stopAnimating];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                if ([self.bm_currentBMController isKindOfClass:%c(BMInstallTableViewController)]) {
                    [self.bm_BMInstallTableViewController dismissViewControllerAnimated:YES completion:nil];
                }
            }];
            [self.processingDialog addAction:okAction];
        }
        
        else if (self.uicacheSwitchStatus == false && self.respringSwitchStatus == true) {
            [self runCommand:@"sbreload"];
        }
        
        else if (self.uicacheSwitchStatus == true && self.respringSwitchStatus == true) {
            [self showProcessingDialog:@"Running uicache and respringing...." includeStage:false startingStep:1 autoPresent:true];
            [self runCommand:@"uicache --all --respring"];
        }
        
        else {
            if ([self.bm_currentBMController isKindOfClass:%c(BMInstallTableViewController)]) {
                [self.bm_BMInstallTableViewController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }];
    UIAlertAction *doNothingAction = [UIAlertAction actionWithTitle:@"Do nothing" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if ([self.bm_currentBMController isKindOfClass:%c(BMInstallTableViewController)]) {
            [self.bm_BMInstallTableViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    
    if (shouldTransition) {
        [self placeUISwitchInsideUIAlertController:self.processingDialog whichScreen:3];
        [self transitionProgressMessage:theMessage];
        [self.spinner stopAnimating];
        [self.processingDialog addAction:proceedAction];
        [self.processingDialog addAction:doNothingAction];
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:theMessage preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:proceedAction];
        [alert addAction:doNothingAction];
        if (theMessage == nil) {
            [self placeUISwitchInsideUIAlertController:alert whichScreen:4];
        }
        else {
            [self placeUISwitchInsideUIAlertController:alert whichScreen:3];
        }
        
        if (shouldOpenBMHomeViewControllerFirst) {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[BMHomeTableViewController alloc] init]];
            [self.motherClass presentViewController:nav animated:YES completion:^{
                [self.bm_BMHomeTableViewController presentViewController:alert animated:YES completion:nil];
            }];
        }
        else {
            [self.bm_BMHomeTableViewController presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)showFinishedCreatingDialog:(NSString *)debFileName { //UI for when creating a .deb finishes. This removes the UIActivityIndicator, transitions the text, and asks the user if they want to immediately share the created .deb
    [self transitionProgressMessage:@"Done!\nSuccesfully created your .deb!\nIt's at /var/mobile/BatchomaticDebs"];
    [self.spinner stopAnimating];
    UIAlertAction *exportAction = [UIAlertAction actionWithTitle:@"Export" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self runCommand:@"bmd rmtemp"];
        NSArray *items = @[[NSURL fileURLWithPath:[NSString stringWithFormat:@"/var/mobile/BatchomaticDebs/%@", debFileName]]];
        UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
        [shareSheet setValue:debFileName forKey:@"subject"];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { //iPads require special positioning for the share sheet
            shareSheet.modalPresentationStyle = UIModalPresentationPopover;
            UIPopoverPresentationController *popPC = shareSheet.popoverPresentationController;
            popPC.sourceView = [self.bm_currentBMController view];
            CGRect sourceRext = CGRectZero;
            sourceRext.origin = CGPointMake(75, 0);
            popPC.sourceRect = sourceRext;
            popPC.permittedArrowDirections = UIPopoverArrowDirectionUp;
        }
        [self.bm_currentBMController presentViewController:shareSheet animated:YES completion:nil];
    }];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self runCommand:@"bmd rmtemp"];
    }];
    [self.processingDialog addAction:exportAction];
    [self.processingDialog addAction:dismissAction];
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to handle my special tweak preferences (asking the user what they want to do for installing a .deb, removing all tweaks/repos, and uicache/respringing)
- (UIStackView *)createASwitchWithLabel:(NSString *)message tag:(int)theTag defaultState:(BOOL)onOrOff { //Creates a UIStackView with a UISwitch and a UILabel. The status of the switch is stored in the boolean variables prefsSwitchStatus, tweaksSwitchStatus, etc.
    UILabel *theLabel = [[UILabel alloc] init];
    theLabel.text = message;
    [theLabel sizeToFit];

    UISwitch *theSwitch = [[UISwitch alloc] init];
    theSwitch.on = onOrOff;
    [theSwitch setOn:onOrOff animated:YES];
    [theSwitch addTarget:self action:@selector(toggleTapped:) forControlEvents:UIControlEventValueChanged];
    [theSwitch.layer setValue:theLabel forKey:@"label"];
    theSwitch.tag = theTag;

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = 10;
    [stackView addArrangedSubview:theLabel];
    [stackView addArrangedSubview:theSwitch];
    return stackView;
}

- (UIStackView *)createOptionsSwitches:(int)type { //Combines multiple UIStackViews from the above method to create a larger stack view that has multiple toggles/labels
    UIStackView *combinedStackView = [[UIStackView alloc] init];
    combinedStackView.translatesAutoresizingMaskIntoConstraints = NO;
    combinedStackView.axis = UILayoutConstraintAxisVertical;
    combinedStackView.spacing = 10;
    
    if (type == 1) { //type 1 means the remove all repos screen
        [combinedStackView addArrangedSubview:[self createASwitchWithLabel:@"Remove everything?" tag:101 defaultState:NO]];
        self.removeAllReposSwitchStatus = false;
    }
    else if (type == 2) { //type 2 is the remove all tweaks screen
        [combinedStackView addArrangedSubview:[self createASwitchWithLabel:@"Remove everything?" tag:102 defaultState:NO]];
        self.removeAllTweaksSwitchStatus = false;
    }
    else { //type 3 is the respring/uicache screen
        [combinedStackView addArrangedSubview:[self createASwitchWithLabel:@"Run uicache" tag:103 defaultState:NO]];
        [combinedStackView addArrangedSubview:[self createASwitchWithLabel:@"Respring" tag:104 defaultState:YES]];
        self.uicacheSwitchStatus = false;
        self.respringSwitchStatus = true;
    }
    return combinedStackView;
}

- (UIAlertController *)placeUISwitchInsideUIAlertController:(UIAlertController *)alert whichScreen:(int)screen { //Places the large stack view from the above method inside the given UIAlertController & applies some UI adjustments to make everything look good. The result is a UIAlertController with UISwitches inside
    int whichOptions = screen;
    if (screen == 4) {
        whichOptions = 3;
    }
    UIStackView *combinedStackView = [self createOptionsSwitches:whichOptions];
    [alert.view addSubview:combinedStackView];
    [combinedStackView.centerXAnchor constraintEqualToAnchor:alert.view.centerXAnchor].active = YES;
    
    CGFloat switchesTopAnchor = 20 + 20.5 + 20;
    if (screen == 1 || screen == 2) { //remove all repos/tweaks screen with a 2-line message
        switchesTopAnchor += (2 + 16 + 16); //add the height of a 2-line message plus the space between the title and the message
    }
    else if (screen == 3) { //uicache/respring screen with a 1-line message
        switchesTopAnchor += (2 + 16); //add the height of a 1-line message
    }
    
    [combinedStackView.topAnchor constraintEqualToAnchor:alert.view.topAnchor constant:switchesTopAnchor].active = YES;
    [alert.view layoutIfNeeded];
    CGFloat totalHeight = switchesTopAnchor + combinedStackView.bounds.size.height + 20 + 44;
    [alert.view.heightAnchor constraintEqualToConstant:totalHeight].active = YES;
    return alert;
}

- (void)toggleTapped:(UISwitch *)sender { //Updates the corresponding xyzSwitchStatus variable whenever one of my UISwitches is tapped
    if (sender.tag == 0) { //sorry about this terrible formatting. I figured that with such repetitive code, less lines would make it easier to read. idk
        if ([sender isOn]) { self.prefsSwitchStatus = true; }
        else {               self.prefsSwitchStatus = false; }
    }
    else if (sender.tag == 1) {
        if ([sender isOn]) { self.hostsSwitchStatus = true; }
        else {               self.hostsSwitchStatus = false; }
    }
    else if (sender.tag == 2) {
        if ([sender isOn]) { self.savedDebsSwitchStatus = true; }
        else {               self.savedDebsSwitchStatus = false; }
    }
    else if (sender.tag == 3) {
        if ([sender isOn]) { self.reposSwitchStatus = true; }
        else {               self.reposSwitchStatus = false; }
    }
    else if (sender.tag == 4) {
        if ([sender isOn]) { self.tweaksSwitchStatus = true; }
        else {               self.tweaksSwitchStatus = false; }
    }
    else if (sender.tag == 5) {
        if ([sender isOn]) { self.offlineTweaksSwitchStatus = true; }
        else {               self.offlineTweaksSwitchStatus = false; }
    }
    else if (sender.tag == 101) {
        if ([sender isOn]) { self.removeAllReposSwitchStatus = true; }
        else {               self.removeAllReposSwitchStatus = false; }
    }
    else if (sender.tag == 102) {
        if ([sender isOn]) { self.removeAllTweaksSwitchStatus = true; }
        else {               self.removeAllTweaksSwitchStatus = false; }
    }
    else if (sender.tag == 103) {
        if ([sender isOn]) { self.uicacheSwitchStatus = true; }
        else {               self.uicacheSwitchStatus = false; }
    }
    else if (sender.tag == 104) {
        if ([sender isOn]) { self.respringSwitchStatus = true; }
        else {               self.respringSwitchStatus = false; }
    }
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to determine info about the user's .deb and load a list of currently installed tweaks into an NSArray
- (void)determineInfoAboutDeb {
    if ([[self runCommand:@"dpkg -l | grep \"com.you.batchinstall\""] isEqualToString:@""]) { //determine if the user's .deb is currently installed
        self.debIsInstalled = false;
    }
    else {
        self.debIsInstalled = true;
    }
    
    BOOL isFolder;
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/BatchInstall/OfflineDebs" isDirectory:&isFolder]) { //determine if the currently installed .deb is meant for online mode or offline mode
        self.debIsOnline = false;
    }
    else {
        self.debIsOnline = true;
    }
}

- (void)loadListOfCurrentlyInstalledTweaks { //Used only for "Repack tweak to .deb" (not used anywhere else)
    [self runCommand:@"bmd rmgetlist"];
    [self runCommand:@"bmd getlist"];
    
    NSMutableArray *tweaks = [[NSMutableArray alloc] init];
    FILE *file = fopen("/tmp/batchomaticGetList/tweaks.txt", "r");
    while (!feof(file)) {
        NSString *packageID = [self readEachLineOfFile:file];
        NSString *cmd = [NSString stringWithFormat:@"dpkg-query -s %@%@", packageID, @" | grep \"Name: \" | sed 's/Name: //'"];
        NSString *name = [self runCommand:cmd];
        if ([name isEqualToString:@""]) {
            name = packageID;
        }
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:name forKey:@"name"];
        [dict setObject:packageID forKey:@"packageID"];
        [tweaks addObject:dict];
    }
    fclose(file);
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    self.currentlyInstalledTweaks = [[tweaks sortedArrayUsingDescriptors:@[descriptor]] copy];
    
    if ([self.bm_currentBMController isKindOfClass:%c(BMRepackTableViewController)]) { //when loading the list is finished, reload the tableview
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.bm_BMRepackTableViewController createTableView];
        });
    }
    
    [self runCommand:@"bmd rmgetlist"];
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to perform utility tasks
- (NSString *)runCommand:(NSString *)theCommand { //Runs the specified shell command as "mobile" and returns the output. Running a command as root can be seen in the "bmd" folder
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-c", theCommand];
    task.standardOutput = pipe;
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

- (NSString *)readEachLineOfFile:(FILE *)file { //Returns each line of the given file. Use this inside of a while loop
    NSMutableString *result = [[NSMutableString alloc] init];
    char buffer[4096];
    int charsRead;
    do {
        if (fscanf(file, "%4095[^\n]%n%*c", buffer, &charsRead) == 1) {
            [result appendFormat:@"%s", buffer];
        }
        else {
            break;
        }
    }
    while (charsRead == 4095);
    return result;
}
@end

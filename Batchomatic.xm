//Batchomatic v4.1.1 - Created by /u/CaptInc37
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#import <headers/Batchomatic.h>
#import <headers/NSTask.h>
extern int refreshesCompleted; //this variable is used for telling my tweak what we should do next during add repos. It also ensures that my extra code in the hooks only executes if we are currently using Batchomatic
//Note: when I set that variable as an @property, I ran into some weird bug where it wasn't keeping track of its value. Setting it as a normal C global variable fixed that
int refreshesCompleted = 0;

@implementation Batchomatic
+ (id)sharedInstance { //returns the instance of the Batchomatic class (so you can access the Batchomatic code from anywhere)
    static Batchomatic *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

//methods for the front-end features (creating .deb and determining what to install)
- (void)createDeb:(NSString *)motherMessage { //creates a .deb with all of the necessary information
    if (self.maxSteps == 1) { //having only 1 step means an online .deb with tweaks, repos, saved .debs, tweak preferences, and hosts file. this weird logic is necessary because of that UIAlertController bug (detailed in (void)installDeb below)
        motherMessage = [self updateProgressMessage:@"Creating your online .deb....\n"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Running initial setup"]];
        [self runCommand:@"bmd online 1"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Setting up filesystem"]];
        [self runCommand:@"bmd online 2"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Creating control file"]];
        [self runCommand:@"bmd online 3"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Gathering tweaks"]];
        [self runCommand:@"bmd online 4"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Gathering repos"]];
        [self runCommand:@"bmd online 5"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Gathering tweak preferences"]];
        [self runCommand:@"bmd online 6"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Gathering hosts file"]];
        [self runCommand:@"bmd online 7"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Gathering saved debs"]];
        [self runCommand:@"bmd online 8"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Building final deb"]];
        [self runCommand:@"bmd online 9"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Verifying deb"]];
        [self runCommand:@"bmd online 10"];
    }
    else { //the other kind has 3 steps, meaning an offline .deb with .debs OF YOUR TWEAKS, saved .debs, tweak preferences, and hosts file. A plain list of repos/tweaks is NOT included
        motherMessage = [self updateProgressMessage:@"Creating your offline .deb....\n"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Running initial setup"]];
        [self runCommand:@"bmd offline 1"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Setting up filesystem"]];
        [self runCommand:@"bmd offline 2"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Creating control file"]];
        [self runCommand:@"bmd offline 3"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Gathering tweak preferences"]];
        [self runCommand:@"bmd offline 4"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Gathering hosts file"]];
        [self runCommand:@"bmd offline 5"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Gathering saved debs"]];
        [self runCommand:@"bmd offline 6"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Preparing"]];
        [self runCommand:@"bmd offline 7"];
        
        motherMessage = [self updateProgressMessage:@"Creating .debs of your tweaks. This could take several minutes...."];
        FILE *tweaksToCreateDebsForFile = fopen("/tmp/batchomatic/tweaks.txt", "r");
        while (!feof(tweaksToCreateDebsForFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:tweaksToCreateDebsForFile];
            [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@%@", motherMessage, @"\n", thePackageIdentifer]];
            [self runCommand:[NSString stringWithFormat:@"bmd offline 8 %@", thePackageIdentifer]];
        }
        fclose(tweaksToCreateDebsForFile);
        
        motherMessage = [self updateProgressMessage:@"Creating your offline .deb....\n"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Building final deb"]];
        [self runCommand:@"bmd offline 9"];
        [self transitionProgressMessage:[NSString stringWithFormat:@"%@%@", motherMessage, @"Verifying deb"]];
        [self runCommand:@"bmd offline 10"];
    }
    
    FILE *file = fopen("/tmp/batchomatic/nameOfDeb.txt", "r"); //ensures the created deb is valid and usable
    NSString *debFileName = [self readEachLineOfFile:file];
    fclose(file);
    if ([debFileName isEqualToString:@"everythingbroke"]) {
        [self transitionProgressMessage:@"FATAL ERROR:\nCreation of your .deb failed - it is totally unusable. This should never happen\nTry deleting /var/mobile/Library/Preferences/com.rpetrich.pictureinpicture.license and then try again\n\nIf that doesn't fix it, please contact me: https://reddit.com/u/captinc37/"];
        [self.spinner stopAnimating];
        UIAlertAction *contactAction = [UIAlertAction actionWithTitle:@"Contact developer" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSDictionary *options = @{UIApplicationOpenURLOptionUniversalLinksOnly : @NO};
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/message/compose/?to=captinc37&subject=Batchomatic%20creation%20fatal%20error"] options:options completionHandler:nil];
        }];
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
        [self.processingDialog addAction:contactAction];
        [self.processingDialog addAction:dismissAction];
    }
    else {
        [self showFinishedCreatingDialog:@"Done!\nSuccesfully created your .deb!\nIt's at /var/mobile/BatchomaticDebs" pathToDeb:debFileName];
    }
}

- (void)installDeb { //actually does the actions that the user wants. we need to have 2 methods to install the .deb because there was a bug where the UIAlertController wouldn't show up
    //the 2 methods are this one and (void)prepareToInstall in BMInstallTableViewController
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
        [self addingReposDidFinish:true];
        return;
    }
    [self endProcessingDialog:@"Done! Succesfully installed your .deb!" transition:true presentImmediately:false];
}

//--------------------------------------------------------------------------------------------------------------------------
//methods for the back-end: actually doing the main functions of this tweak. (install the user's data)
- (void)installAllDebsInFolder:(NSString *)pathToDebsFolder withMotherMessage:(NSString *)motherMessage { //installs all .debs at the given folder and updates the UIAlertController about what .deb is being installed right now. This interfaces with the binary I made to run a command as root (see the 'bmd' folder)
    [self runCommand:@"bmd rmtemp"];
    [self runCommand:@"mkdir -p /tmp/batchomatic/tempdebs"];
    [self runCommand:[NSString stringWithFormat:@"mv %@%@", pathToDebsFolder, @"/com.captinc.batchomatic*.deb /tmp/batchomatic/tempdebs"]]; //if we install a deb for a feature that's currently in use, the process will crash
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
            [self runCommand:[NSString stringWithFormat:@"bmd installdeb %@%@%@", pathToDebsFolder, @"/", debFileName]]; //fyi, "bmd" means "batchomatic daemon" or "batchomaticd"
        }
    }
    [self runCommand:@"bmd dpkgconfig"];
    [self runCommand:[NSString stringWithFormat:@"mv /tmp/batchomatic/tempdebs/*.deb %@", pathToDebsFolder]];
    [self runCommand:@"rm -r /tmp/batchomatic"];
}

- (void)addRepos { //adds all of the user's repos to the currently-in-use package manager if they are not already added
    //Note: code for this feature is continued in the hooks in Tweak.xm. After it goes through Tweak.xm, the code comes back to (void)addingReposDidFinish in this file. This is because we need to wait for the repos to finish adding before we can proceed
    refreshesCompleted = 1;
    [self runCommand:[NSString stringWithFormat:@"bmd addrepos %d", self.packageManager]];
    FILE *listOfReposFile = fopen("/tmp/batchomatic/reposToAdd.txt", "r");
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/batchomatic/reposToAdd.txt" isDirectory:NULL]) { //this bash script determines what repos we want versus what repos are already added
        if (self.packageManager == 1) { //if we are using Cydia
            Cydia *cydiaDelegate = (Cydia *)[[UIApplication sharedApplication] delegate];
            while (!feof(listOfReposFile)) {
                NSString *eachRepo = [self readEachLineOfFile:listOfReposFile];
                if ([eachRepo isEqualToString:@"http://apt.thebigboss.org/repofiles/cydia/"] || [eachRepo isEqualToString:@"http://apt.modmyi.com/"] || [eachRepo isEqualToString:@"http://cydia.zodttd.com/repo/cydia/"]) {
                    NSDictionary *dictionary = @{@"Distribution" : @"stable", @"Sections" : [NSArray arrayWithObject:@"main"], @"Type" : @"deb", @"URI" : eachRepo};
                    [cydiaDelegate addSource:dictionary];
                }
                else {
                    [cydiaDelegate addTrivialSource:eachRepo];
                }
            }
            [cydiaDelegate requestUpdate];
        }
        
        else if (self.packageManager == 2) { //if we are using Zebra
            NSString *reposToAdd = [NSString stringWithContentsOfFile:@"/tmp/batchomatic/reposToAdd.txt" encoding:NSUTF8StringEncoding error:nil];
            [self.processingDialog dismissViewControllerAnimated:YES completion:^{
                [self.bm_currentBMController dismissViewControllerAnimated:YES completion:^{
                    [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                        [self.zebra_ZBRepoListTableViewController didAddReposWithText:reposToAdd];
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
        
        else if (self.packageManager == 4) { //if we are using Installer 5
            while (!feof(listOfReposFile)) {
                NSString *eachRepo = [self readEachLineOfFile:listOfReposFile];
                [self.installer_ManageViewController addSourceWithString:eachRepo withHttpApproval:true];
            }
            [self.processingDialog dismissViewControllerAnimated:YES completion:^{
                [self.bm_currentBMController dismissViewControllerAnimated:YES completion:^{
                    [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                        [self.installer_SearchViewController showTaskView];
                    }];
                }];
            }];
        }
    }
    else {
        [self addingReposDidFinish:true];
    }
    fclose(listOfReposFile);
    [self runCommand:@"bmd rmtemp"];
}

- (void)addingReposDidFinish:(bool)shouldTransition { //after each package manager finishes adding repos, this method is called to continue running Batchomatic
    refreshesCompleted = 0;
    if (self.tweaksSwitchStatus == true) {
        if (shouldTransition) {
            [self updateProgressMessage:@"Queuing tweaks...."];
            [self queueTweaks:shouldTransition];
        }
        else {
            [self showProcessingDialog:@"Queuing tweaks...." includeStage:true startingStep:(self.currentStep + 1) autoPresent:false];
            [self.motherClass presentViewController:self.processingDialog animated:YES completion:^{ [self queueTweaks:shouldTransition]; }];
        }
    }
    else {
        [self endProcessingDialog:@"Done! Succesfully installed your .deb!" transition:shouldTransition presentImmediately:false];
    }
}

- (void)showUnfindableTweaks:(NSMutableString *)unfindableTweaks transition:(bool)shouldTransition thenInClass:(id)theClass runMethod:(SEL)theMethod { //displays an alert if we cannot find some of the user's tweaks. This is caused when the repo for said tweak is not added, or said tweak was previously installed from a .deb. We obviously can't queue a tweak if we can't find it
    if ([unfindableTweaks isEqualToString:@""]) {
        [self.processingDialog dismissViewControllerAnimated:YES completion:^{
            if (shouldTransition) {
                [self.bm_currentBMController dismissViewControllerAnimated:YES completion:^{
                    [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                        [theClass performSelector:theMethod];
                    }];
                }];
            }
            else {
                [theClass performSelector:theMethod];
            }
        }];
    }
    else {
        NSString *message = [NSString stringWithFormat:@"The following tweaks could not be found:\n\n%@", unfindableTweaks];
        [self transitionProgressMessage:message];
        [self.spinner stopAnimating];
        UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy to clipboard and proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = unfindableTweaks;
            if (shouldTransition) {
                [self.bm_currentBMController dismissViewControllerAnimated:YES completion:^{
                    [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                        [theClass performSelector:theMethod];
                    }];
                }];
            }
            else {
                [theClass performSelector:theMethod];
            }
        }];
        UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (shouldTransition) {
                [self.bm_currentBMController dismissViewControllerAnimated:YES completion:^{
                    [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                        [theClass performSelector:theMethod];
                    }];
                }];
            }
            else {
                [theClass performSelector:theMethod];
            }
        }];
        [self.processingDialog addAction:copyAction];
        [self.processingDialog addAction:proceedAction];
    }
}

- (void)queueTweaks:(bool)shouldTransition { //adds all of the user's tweaks to the queue if they are not already installed
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
        [self showUnfindableTweaks:unfindableTweaks transition:shouldTransition thenInClass:cydiaDelegate runMethod:@selector(queue)];
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ //dispatching code after 1 second is necessary because Zebra lags when you open a queue with a ton of packages. This way, the user experiences less lag
            [self showUnfindableTweaks:unfindableTweaks transition:shouldTransition thenInClass:self.zebra_ZBTabBarController runMethod:@selector(openQueue:)];
        });
    }
    
    else if (self.packageManager == 3) { //Sileo
        while (!feof(listOfTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:listOfTweaksFile];
            Package *thePackage = [[%c(_TtC5Sileo18PackageListManager) shared] newestPackageWithIdentifier:thePackageIdentifer];
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ //dispatching code after 2.5 seconds is necessary because Sileo takes a few seconds to update the amount of dependency errors
            if ([[[%c(_TtC5Sileo15DownloadManager) shared] errors] count] != 0) { //see (void)sileoFixDependencies for an explanation about this
                [self sileoFixDependencies:unfindableTweaks transition:shouldTransition];
            }
            else {
                [self showUnfindableTweaks:unfindableTweaks transition:shouldTransition thenInClass:[%c(TabBarController) singleton] runMethod:@selector(presentPopupController)];
            }
        });
    }
    
    else if (self.packageManager == 4) { //Installer
        while (!feof(listOfTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:listOfTweaksFile];
            if ([self.installer_ATRPackages packageWithIdentifier:thePackageIdentifer] != nil) {
                if (![self.installer_ATRPackages packageIsInstalled:thePackageIdentifer]) {
                    [self.installer_ATRPackages setPackage:thePackageIdentifer inTheQueue:true];
                }
            }
            else {
                [unfindableTweaks appendString:thePackageIdentifer];
                [unfindableTweaks appendString:@"\n"];
            }
        }
        UIBarButtonItem *installerPresentQueueButton = [[UIBarButtonItem alloc] initWithTitle:@"Queued Packages" style:UIBarButtonItemStylePlain target:self.installer_SearchViewController action:@selector(proceedQueuedPackages)]; //Installer does not automatically show this button when a tweak is added to the queue, so I have to do it myself
        [[self.installer_SearchViewController navigationItem] setRightBarButtonItem:installerPresentQueueButton];
        [self showUnfindableTweaks:unfindableTweaks transition:shouldTransition thenInClass:self.installer_SearchViewController runMethod:@selector(proceedQueuedPackages)];
    }
    fclose(listOfTweaksFile);
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to make Sileo add the dependencies of your tweaks to the queue since Sileo does not do this by default
//I do this by detecting any current dependency errors, adding those dependencies to the queue, and re-checking. Re-check is achieved via method recursion (when you call a method inside of itself)
- (void)sileoFixDependencies:(NSMutableString *)unfindableTweaks transition:(bool)shouldTransition {
    [self sileoAddDependenciesToQueue];
    [[%c(_TtC5Sileo15DownloadManager) shared] reloadDataWithRecheckPackages:true];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[[%c(_TtC5Sileo15DownloadManager) shared] errors] count] != 0) {
            [self sileoFixDependencies:unfindableTweaks transition:shouldTransition]; //here's that method recursion thing
        }
        else {
            [self showUnfindableTweaks:unfindableTweaks transition:shouldTransition thenInClass:[%c(TabBarController) singleton] runMethod:@selector(presentPopupController)];
        }
    });
}

- (void)sileoAddDependenciesToQueue {
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
        Package *thePackage = [[%c(_TtC5Sileo18PackageListManager) shared] newestPackageWithIdentifier:thePackageIdentifer];
        if (thePackage != nil) {
            if ([[%c(_TtC5Sileo18PackageListManager) shared] installedPackageWithIdentifier:thePackageIdentifer] == nil && ![[[%c(_TtC5Sileo15DownloadManager) shared] installations] containsObject:thePackage]) {
                [[%c(_TtC5Sileo15DownloadManager) shared] addWithPackage:thePackage queue:1];
            }
        }
    }
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to remove all tweaks
- (void)removeAllClient { //shows the screen where you choose if you want to keep package managers, Filza, and Batchomatic itself when removing all tweaks
    UIAlertController *optionsAlert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:@"When this switch is OFF, Zebra/Installer/Filza/Batchomatic/BatchInstall will stay" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [self removeAll]; }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    [optionsAlert addAction:proceedAction];
    [optionsAlert addAction:cancelAction];
    
    UIStackView *combinedStackView = [self createOptionsSwitches:1];
    [optionsAlert.view addSubview:combinedStackView];
    [combinedStackView.centerXAnchor constraintEqualToAnchor:optionsAlert.view.centerXAnchor].active = YES;
    combinedStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [combinedStackView.topAnchor constraintEqualToAnchor:optionsAlert.view.topAnchor constant:64].active = YES;
    [optionsAlert.view layoutIfNeeded];
    CGFloat height;
    if (@available(iOS 13, *)) {
        height = optionsAlert.view.bounds.size.height + optionsAlert.actions.count;
    }
    else {
        height = optionsAlert.view.bounds.size.height + optionsAlert.actions.count*52 + combinedStackView.bounds.size.height;
    }
    [optionsAlert.view.heightAnchor constraintEqualToConstant:height].active = YES;
    
    [self.bm_currentBMController presentViewController:optionsAlert animated:YES completion:nil];
}

- (void)removeAll { //actually removes ALL of the user's tweaks. All of them. This is like my own version of Restore RootFS
    self.maxSteps = 1;
    [self showProcessingDialog:@"Removing tweaks...." includeStage:true startingStep:1 autoPresent:true];
    if (self.removeEverythingSwitchStatus == true) { [self runCommand:@"bmd removeall 1"]; }
    else { [self runCommand:@"bmd removeall 0"]; }
    FILE *removeAllTweaksFile = fopen("/tmp/batchomatic/removeall.txt", "r");
    
    if (self.packageManager == 1) {
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
    
    else if (self.packageManager == 2) {
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
    
    else if (self.packageManager == 3) {
        while (!feof(removeAllTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:removeAllTweaksFile];
            if ([[%c(_TtC5Sileo18PackageListManager) shared] installedPackageWithIdentifier:thePackageIdentifer] != nil) {
                Package *thePackage = [[%c(_TtC5Sileo18PackageListManager) shared] newestPackageWithIdentifier:thePackageIdentifer];
                [[%c(_TtC5Sileo15DownloadManager) shared] addWithPackage:thePackage queue:2];
            }
        }
        [[%c(_TtC5Sileo15DownloadManager) shared] reloadDataWithRecheckPackages:true];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.processingDialog dismissViewControllerAnimated:YES completion:^{
                [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                    [[%c(TabBarController) singleton] presentPopupController];
                }];
            }];
        });
    }
    
    else if (self.packageManager == 4) {
        while (!feof(removeAllTweaksFile)) {
            NSString *thePackageIdentifer = [self readEachLineOfFile:removeAllTweaksFile];
            if ([self.installer_ATRPackages packageIsInstalled:thePackageIdentifer]) {
                [self.installer_ATRPackages setPackage:thePackageIdentifer inTheQueue:true];
            }
        }
        UIBarButtonItem *installerPresentQueueButton = [[UIBarButtonItem alloc] initWithTitle:@"Queued Packages" style:UIBarButtonItemStylePlain target:self.installer_SearchViewController action:@selector(proceedQueuedPackages)];
        [[self.installer_SearchViewController navigationItem] setRightBarButtonItem:installerPresentQueueButton];
        [self.processingDialog dismissViewControllerAnimated:YES completion:^{
            [self.bm_BMHomeTableViewController dismissViewControllerAnimated:YES completion:^{
                [self.installer_SearchViewController proceedQueuedPackages];
            }];
        }];
    }
    fclose(removeAllTweaksFile);
    [self runCommand:@"bmd rmtemp"];
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to handle the popup UI when my tweak is processing. This also handles the UI after it finishes (processing dialog and completion dialog)
- (void)showFinishedCreatingDialog:(NSString *)theMessage pathToDeb:(NSString *)debFileName { //the UI shown when creating a .deb finishes. This gets rid of the spinning wheel, transitions the text, and asks the user if they want to immediately share the created .deb
    [self transitionProgressMessage:theMessage];
    [self.spinner stopAnimating];
    UIAlertAction *exportAction = [UIAlertAction actionWithTitle:@"Export" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self runCommand:@"bmd rmtemp"];
        NSArray *items = @[[NSURL fileURLWithPath:[NSString stringWithFormat:@"/var/mobile/BatchomaticDebs/%@", debFileName]]];
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
        [activityViewController setValue:debFileName forKey:@"subject"];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { //ipads require special positioning for the share sheet
            activityViewController.modalPresentationStyle = UIModalPresentationPopover;
            UIPopoverPresentationController *popPC = activityViewController.popoverPresentationController;
            popPC.sourceView = [self.bm_currentBMController view];
            CGRect sourceRext = CGRectZero;
            sourceRext.origin = CGPointMake(75, 0);
            popPC.sourceRect = sourceRext;
            popPC.permittedArrowDirections = UIPopoverArrowDirectionUp;
        }
        [self.bm_currentBMController presentViewController:activityViewController animated:YES completion:nil];
    }];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { [self runCommand:@"bmd rmtemp"]; }];
    [self.processingDialog addAction:exportAction];
    [self.processingDialog addAction:dismissAction];
}

- (NSString *)showProcessingDialog:(NSString *)wordMessage includeStage:(bool)includeStage startingStep:(int)startingStep autoPresent:(bool)shouldAutoPresentDialog { //displays a UIAlertController with stages (for example: Stage 1/4), what we are doing, and a UIActivityIndicator/spinning wheel
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
    
    UIViewController *progressStatus = [[UIViewController alloc] init]; //these next few lines create a UIActivityIndicator inside of a UIAlertController (the spinning wheel)
    if (@available(iOS 13, *)) {
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    }
    else {
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    self.spinner.hidesWhenStopped = YES;
    [self.spinner startAnimating];
    [progressStatus.view addSubview:self.spinner];
    [progressStatus.view addConstraint:[NSLayoutConstraint constraintWithItem:self.spinner attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:progressStatus.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [progressStatus.view addConstraint:[NSLayoutConstraint constraintWithItem:self.spinner attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:progressStatus.view attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    [self.processingDialog setValue:progressStatus forKey:@"contentViewController"];
    
    if (shouldAutoPresentDialog) {
        [self.bm_currentBMController presentViewController:self.processingDialog animated:YES completion:nil];
    }
    return totalMessage;
}

- (void)transitionProgressMessage:(NSString *)theMessage { //only transitions the text of the processing dialog
    [UIView transitionWithView:self.processingDialog.view duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void) { self.processingDialog.message = theMessage; } completion:nil];
}

- (NSString *)updateProgressMessage:(NSString *)wordMessage { //increments what stage we are on and transitions the text
    self.currentStep += 1;
    NSString *currentStepAsString = [NSString stringWithFormat:@"%d", self.currentStep];
    NSString *maxStepsAsString = [NSString stringWithFormat:@"%d", self.maxSteps];
    NSString *totalMessage = [NSString stringWithFormat:@"Stage %@%@%@%@%@", currentStepAsString, @"/", maxStepsAsString, @"\n", wordMessage];
    [self transitionProgressMessage:totalMessage];
    return totalMessage;
}

- (void)endProcessingDialog:(NSString *)theMessage transition:(bool)shouldTransition presentImmediately:(bool)shouldPresentImmediately { //gets rid of the spinning wheel, transitions the text, and asks the user if they want to uicache/respring or not. This method can either present a whole new UIAlertController or transition an existing processing dialog
    UIStackView *combinedStackView = [self createOptionsSwitches:2];
    combinedStackView.translatesAutoresizingMaskIntoConstraints = NO;
    UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (self.uicacheSwitchStatus == true && self.respringSwitchStatus == false) {
            [self showProcessingDialog:@"Running uicache...." includeStage:false startingStep:1 autoPresent:true];
            [self runCommand:@"uicache --all"];
            [self transitionProgressMessage:@"Done!"];
            [self.spinner stopAnimating];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                if ([self.bm_currentBMController isKindOfClass:%c(BMInstallTableViewController)]) {
                    [self.bm_currentBMController dismiss];
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
                [self.bm_currentBMController dismiss];
            }
        }
    }];
    UIAlertAction *doNothingAction = [UIAlertAction actionWithTitle:@"Do nothing" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if ([self.bm_currentBMController isKindOfClass:%c(BMInstallTableViewController)]) {
            [self.bm_currentBMController dismiss];
        }
    }];
    
    if (shouldTransition) {
        [self.processingDialog.view addSubview:combinedStackView]; //these next few lines finalize the positioning of the UISWitches inside of the UIAlertController
        [combinedStackView.centerXAnchor constraintEqualToAnchor:self.processingDialog.view.centerXAnchor].active = YES;
        [combinedStackView.topAnchor constraintEqualToAnchor:self.processingDialog.view.topAnchor constant:64].active = YES;
        [self.processingDialog.view layoutIfNeeded];
        CGFloat height;
        if (@available(iOS 13, *)) {
            height = self.processingDialog.view.bounds.size.height + self.processingDialog.actions.count + combinedStackView.bounds.size.height;
        }
        else {
            height = self.processingDialog.view.bounds.size.height + self.processingDialog.actions.count*52 + combinedStackView.bounds.size.height;
        }
        [self.processingDialog.view.heightAnchor constraintEqualToConstant:height].active = YES;
        
        [self transitionProgressMessage:theMessage];
        [self.spinner stopAnimating];
        [self.processingDialog addAction:proceedAction];
        [self.processingDialog addAction:doNothingAction];
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:theMessage preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:proceedAction];
        [alert addAction:doNothingAction];
        
        [alert.view addSubview:combinedStackView];
        [combinedStackView.centerXAnchor constraintEqualToAnchor:alert.view.centerXAnchor].active = YES;
        [combinedStackView.topAnchor constraintEqualToAnchor:alert.view.topAnchor constant:64].active = YES;
        [alert.view layoutIfNeeded];
        CGFloat height;
        if (@available(iOS 13, *)) {
            height = alert.view.bounds.size.height + alert.actions.count + combinedStackView.bounds.size.height;
        }
        else {
            height = alert.view.bounds.size.height + alert.actions.count*52 + combinedStackView.bounds.size.height;
        }
        [alert.view.heightAnchor constraintEqualToConstant:height].active = YES;
        
        if (shouldPresentImmediately) {
            [self.bm_BMHomeTableViewController presentViewController:alert animated:YES completion:nil];
        }
        else {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[BMHomeTableViewController alloc] init]];
            [self.motherClass presentViewController:nav animated:YES completion:^{
                [self.bm_BMHomeTableViewController presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to handle tweak preferences (the creation and status of the UISwitches)
- (UIStackView *)createASwitchWithLabel:(NSString *)message tag:(int)theTag defaultState:(BOOL)onOrOff { //creates a UIStackView with a UISwitch and a label. The status of the UISwitch is stored in the variables: prefsSwitchStatus, tweaksSwitchStatus, etc.
    UILabel *theLabel = [[UILabel alloc] init];
    theLabel.text = message;
    [theLabel sizeToFit];

    UISwitch *theSwitch = [[UISwitch alloc] init];
    theSwitch.on = onOrOff;
    [theSwitch setOn:onOrOff animated:YES];
    [theSwitch addTarget:self action:@selector(toggleTapped:) forControlEvents:UIControlEventValueChanged];
    [theSwitch.layer setValue:theLabel forKey:@"label"];
    theSwitch.tag = theTag;

    UIStackView *stackview = [[UIStackView alloc] init];
    stackview.axis = UILayoutConstraintAxisHorizontal;
    stackview.spacing = 10;
    [stackview addArrangedSubview:theLabel];
    [stackview addArrangedSubview:theSwitch];
    return stackview;
}

- (UIStackView *)createOptionsSwitches:(int)type { //creates the screen where you are asked if you want to remove EVERYTHING or where you are asked to uicache/respring. It does this by combining 2 UIStackViews from the above method to create a UIAlertController with 1 or 2 toggles inside
    UIStackView *combinedStackView = [[UIStackView alloc] init];
    combinedStackView.axis = UILayoutConstraintAxisVertical;
    combinedStackView.spacing = 10;
    if (type == 1) { //type 1 means the remove all screen
        UILabel *emptySpaceLabel = [[UILabel alloc] init]; //this emptySpace stuff is needed because the UISwitches would prevent you from seeing the UIAlertController's message
        emptySpaceLabel.text = @" ";
        [emptySpaceLabel sizeToFit];
        UIStackView *emptySpaceStackView = [[UIStackView alloc] init];
        [emptySpaceStackView addArrangedSubview:emptySpaceLabel];

        [combinedStackView addArrangedSubview:emptySpaceStackView];
        [combinedStackView addArrangedSubview:[self createASwitchWithLabel:@"Remove everything?" tag:102 defaultState:NO]];
        self.removeEverythingSwitchStatus = false;
    }
    else if (type == 2) { //type 2 means the respring/uicache screen
        [combinedStackView addArrangedSubview:[self createASwitchWithLabel:@"Run uicache" tag:100 defaultState:NO]];
        [combinedStackView addArrangedSubview:[self createASwitchWithLabel:@"Respring" tag:101 defaultState:YES]];
        self.uicacheSwitchStatus = false;
        self.respringSwitchStatus = true;
    }
    return combinedStackView;
}

- (void)toggleTapped:(UISwitch *)sender { //updates the corrseponding SwitchStatus variable whenever a UISwitch is tapped
    if (sender.tag == 0) {
        if ([sender isOn]) { self.prefsSwitchStatus = true; } //sorry about this terrible formatting. I figured that with such repetitive code, less lines would make it easier to read. idk
        else { self.prefsSwitchStatus = false; }
    }
    else if (sender.tag == 1) {
        if ([sender isOn]) { self.hostsSwitchStatus = true; }
        else { self.hostsSwitchStatus = false; }
    }
    else if (sender.tag == 2) {
        if ([sender isOn]) { self.savedDebsSwitchStatus = true; }
        else { self.savedDebsSwitchStatus = false; }
    }
    else if (sender.tag == 3) {
        if ([sender isOn]) { self.reposSwitchStatus = true; }
        else { self.reposSwitchStatus = false; }
    }
    else if (sender.tag == 4) {
        if ([sender isOn]) { self.tweaksSwitchStatus = true; }
        else { self.tweaksSwitchStatus = false; }
    }
    else if (sender.tag == 5) {
        if ([sender isOn]) { self.offlineTweaksSwitchStatus = true; }
        else { self.offlineTweaksSwitchStatus = false; }
    }
    else if (sender.tag == 100) {
        if ([sender isOn]) { self.uicacheSwitchStatus = true; }
        else { self.uicacheSwitchStatus = false; }
    }
    else if (sender.tag == 101) {
        if ([sender isOn]) { self.respringSwitchStatus = true; }
        else { self.respringSwitchStatus = false; }
    }
    else if (sender.tag == 102) {
        if ([sender isOn]) { self.removeEverythingSwitchStatus = true; }
        else { self.removeEverythingSwitchStatus = false; }
    }
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to determine information about the user's .deb
- (bool)isDebInstalled { //this is self explanatory: determines if the user's deb is currently installed or not
    if ([[self runCommand:@"dpkg -l | grep \"com.you.batchinstall\""] isEqualToString:@""]) { return false; }
    else { return true; }
}

- (bool)isDebOnline { //determines if the currently installed .deb is meant for downloading tweaks from official repos, or if its meant for installing .debs of tweaks (online vs offline mode)
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/BatchInstall/OfflineDebs" isDirectory:&isDir]) { return false; }
    else { return true; }
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to perform utility tasks
- (NSString *)runCommand:(NSString *)theCommand { //runs the specified shell command as user "mobile" and returns the output. running a command as root can be seen in the "bmd" folder
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

- (NSString *)readEachLineOfFile:(FILE *)file { //returns each line of the given file. use this inside of a while loop
    char buffer[4096];
    NSMutableString *result = [NSMutableString stringWithCapacity:256];
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

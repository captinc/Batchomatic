//Batchomatic v3.0. Created by /u/CaptInc37
//My code sucks, I know. I'm a noob
//I also coded some shell scripts and a command-line-tool to support this tweak. They are in the "layout" folder

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <NSTask.h>
#import <headers.h>

//--------------------------------------------------------------------------------------------------------------------------
//global variables
NSString *batchomaticVersion = @"v3.0-rc2-1";
int packageManager;

bool prefsSwitchStatus;
bool savedDebsSwitchStatus;
bool hostsSwitchStatus;
bool reposSwitchStatus;
bool tweaksSwitchStatus;
bool offlineDebsSwitchStatus;
bool uicacheSwitchStatus;
bool respringSwitchStatus;

UIAlertController *progressAlert;
UIActivityIndicatorView *spinner;
int maxSteps;
int currentStep;

NSMutableString *unfindableTweaks;
bool shouldShowUnfindableTweaks = false;
int refreshesCompleted = 0;

id cydiaSearchControllerID;
id zebraZBSearchViewControllerID;
id zebraZBRepoListTableViewControllerID;
id sileoSourcesViewControllerID;
id sileoPackageListViewControllerID;
id sileoTabBarControllerID;
id installerSearchViewControllerID;
id installerManageViewControllerID;
id installerATRPackagesID;

//--------------------------------------------------------------------------------------------------------------------------
//methods to perform utility tasks
NSString *runCommand(NSString *theCommand) { //run shell command as mobile and return the output. running a command as root can be seen in the "sourcecode-daemon" folder
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

NSString *readEachLineOfFile(FILE *file) { //returns each line of the given file. Use this inside a while loop
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

//--------------------------------------------------------------------------------------------------------------------------
//methods to determine info about the user's .deb, and what the user wants to do
bool isDebInstalled() {
    if ([runCommand(@"dpkg -l | grep \"com.you.batchinstall\"") isEqualToString:@""]) {
        return false;
    }
    else {
        return true;
    }
}

bool isDebModern() { //was the currently installed .deb made with Batchomatic v3.0 or higher
    if ([runCommand(@"apt-cache depends com.you.batchinstall | grep -v \"com.you.batchinstall\"") isEqualToString:@""]) {
        return true;
    }
    else {
        return false;
    }
}

bool debIsOnlineMode() { //is the currently installed .deb meant for downloading tweaks from their official repos, or installing .debs of tweaks for offline mode
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/BatchInstall/OfflineDebs" isDirectory:&isDir]) {
        return false;
    }
    else {
        return true;
    }
}

bool allSwitchesAreOff() { //if all 5 preference switches are off for the 'Install .deb' feature
    if (prefsSwitchStatus == false && savedDebsSwitchStatus == false && hostsSwitchStatus == false && reposSwitchStatus == false && tweaksSwitchStatus == false && offlineDebsSwitchStatus == false) {
        return true;
    }
    else {
        return false;
    }
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to manipulate the processing screen/dialog
UIStackView *createASwitchWithLabel(id self, NSString *message, BOOL onOrOff, SEL methodToRun) { //creates a UIStackView with a UISwitch and a label. The status of the UISwitch is stored in the variables: prefsSwitchStatus, tweaksSwitchStatus, etc.
    UILabel *theLabel = [[UILabel alloc] init];
    theLabel.text = message;
    [theLabel sizeToFit];
    
    UISwitch *theSwitch = [[UISwitch alloc] init];
    theSwitch.on = onOrOff;
    [theSwitch setOn:onOrOff animated:YES];
    [theSwitch addTarget:self action:methodToRun forControlEvents:UIControlEventValueChanged];
    [theSwitch.layer setValue:theLabel forKey:@"label"];
    
    UIStackView *stackview = [[UIStackView alloc] init];
    stackview.axis = UILayoutConstraintAxisHorizontal;
    stackview.spacing = 10;
    [stackview addArrangedSubview:theLabel];
    [stackview addArrangedSubview:theSwitch];
    
    return stackview;
}

UIStackView *create5Switches(id self) { //combines 5 UIStackViews from above to create a UIAlertController with 5 toggles inside of it
    UILabel *modeLabel = [[UILabel alloc] init];
    if (debIsOnlineMode() == true) {
        modeLabel.text = @"Your .deb is in online mode";
    }
    else {
        modeLabel.text = @"Your .deb is in offline mode";
    }
    [modeLabel sizeToFit];
    UIStackView *modeStackView = [[UIStackView alloc] init];
    modeStackView.axis = UILayoutConstraintAxisHorizontal;
    [modeStackView addArrangedSubview:modeLabel];
    
    UIStackView *combinedStackView = [[UIStackView alloc] init];
    combinedStackView.axis = UILayoutConstraintAxisVertical;
    combinedStackView.spacing = 10;
    [combinedStackView addArrangedSubview:modeStackView];
    [combinedStackView addArrangedSubview:createASwitchWithLabel(self, @"Auto install preferences?", YES, @selector(prefsSwitchTapped:))];
    [combinedStackView addArrangedSubview:createASwitchWithLabel(self, @"Auto install saved .debs?", YES, @selector(savedDebsSwitchTapped:))];
    [combinedStackView addArrangedSubview:createASwitchWithLabel(self, @"Auto install hosts file?", YES, @selector(hostsSwitchTapped:))];
    prefsSwitchStatus = true;
    savedDebsSwitchStatus = true;
    hostsSwitchStatus = true;
    
    if (debIsOnlineMode() == true) {
        [combinedStackView addArrangedSubview:createASwitchWithLabel(self, @"Auto add repos?", YES, @selector(reposSwitchTapped:))];
        [combinedStackView addArrangedSubview:createASwitchWithLabel(self, @"Auto queue tweaks?", YES, @selector(tweaksSwitchTapped:))];
        reposSwitchStatus = true;
        tweaksSwitchStatus = true;
        offlineDebsSwitchStatus = false;
    }
    else {
        [combinedStackView addArrangedSubview:createASwitchWithLabel(self, @"Auto install offline .debs?", YES, @selector(offlineDebsSwitchTapped:))];
        reposSwitchStatus = false;
        tweaksSwitchStatus = false;
        offlineDebsSwitchStatus = true;
    }
    
    return combinedStackView;
}

UIStackView *create2Switches(id self) { //combines 5 UIStackViews from above to create a UIAlertController with 5 toggles inside of it
    UILabel *emptySpaceLabel = [[UILabel alloc] init];
    emptySpaceLabel.text = @"";
    [emptySpaceLabel sizeToFit];
    UIStackView *emptySpaceStackView1 = [[UIStackView alloc] init];
    [emptySpaceStackView1 addArrangedSubview:emptySpaceLabel];
    UIStackView *emptySpaceStackView2 = [[UIStackView alloc] init];
    [emptySpaceStackView2 addArrangedSubview:emptySpaceLabel];
    
    UIStackView *combinedStackView = [[UIStackView alloc] init];
    combinedStackView.axis = UILayoutConstraintAxisVertical;
    combinedStackView.spacing = 10;
    [combinedStackView addArrangedSubview:emptySpaceStackView1];
    [combinedStackView addArrangedSubview:emptySpaceStackView2];
    [combinedStackView addArrangedSubview:createASwitchWithLabel(self, @"Run uicache?", NO, @selector(uicacheSwitchTapped:))];
    [combinedStackView addArrangedSubview:createASwitchWithLabel(self, @"Respring?", YES, @selector(respringSwitchTapped:))];
    uicacheSwitchStatus = false;
    respringSwitchStatus = true;
    
    return combinedStackView;
}

void showProcessingDialog(id self, NSString *wordMessage, bool includeStage, int startingStep, bool shouldAutoPresentDialog) { //displays a UIAlertController with stages (for example: Stage 1/4), what we are doing, and a UIActivityIndicator
    NSString *totalMessage;
    if (includeStage == true) {
        currentStep = startingStep;
        NSString *currentStepAsString = [NSString stringWithFormat:@"%d", currentStep];
        NSString *maxStepsAsString = [NSString stringWithFormat:@"%d", maxSteps];
        totalMessage = [NSString stringWithFormat:@"Stage %@%@%@%@%@", currentStepAsString, @"/", maxStepsAsString, @"\n", wordMessage];
    }
    else {
        totalMessage = wordMessage;
    }
    
    progressAlert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:totalMessage preferredStyle:UIAlertControllerStyleAlert];
    
    UIViewController *progressStatus = [[UIViewController alloc] init];
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.hidesWhenStopped = YES;
    [spinner startAnimating];
    [progressStatus.view addSubview:spinner];
    
    [progressStatus.view addConstraint:[NSLayoutConstraint
                                        constraintWithItem: spinner
                                        attribute:NSLayoutAttributeCenterX
                                        relatedBy:NSLayoutRelationEqual
                                        toItem:progressStatus.view
                                        attribute:NSLayoutAttributeCenterX
                                        multiplier:1.0f
                                        constant:0.0f]];
    [progressStatus.view addConstraint:[NSLayoutConstraint
                                        constraintWithItem: spinner
                                        attribute:NSLayoutAttributeCenterY
                                        relatedBy:NSLayoutRelationEqual
                                        toItem:progressStatus.view
                                        attribute:NSLayoutAttributeCenterY
                                        multiplier:1.0f
                                        constant:0.0f]];
    [progressAlert setValue:progressStatus forKey:@"contentViewController"];
    
    if (shouldAutoPresentDialog == true) {
        [self presentViewController:progressAlert animated:true completion:nil];
    }
}

void transitionProgressMessage(NSString *theMessage) { //only transitions the text of my processing dialog
    [UIView transitionWithView: progressAlert.view
                      duration: 0.3
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^(void) {
                        progressAlert.message = theMessage;
                    }
                    completion: nil];
}

NSString *updateProgressMessage(NSString *wordMessage) { //increments what stage we are on and transitions the text of my processing dialog
    currentStep = currentStep + 1;
    NSString *currentStepAsString = [NSString stringWithFormat:@"%d", currentStep];
    NSString *maxStepsAsString = [NSString stringWithFormat:@"%d", maxSteps];
    NSString *totalMessage = [NSString stringWithFormat:@"Stage %@%@%@%@%@", currentStepAsString, @"/", maxStepsAsString, @"\n", wordMessage];
    transitionProgressMessage(totalMessage);
    return totalMessage;
}

void endProcessingDialog(NSString *theMessage, id self, bool promptToRespring, bool transition) { //gets rid of the UIActivityIndicator, transitions the text, and asks the user if they want to uicache and respring or not
    if (promptToRespring == true) {
        NSString *uicacheCommand;
        NSString *respringCommand;
        NSString *uicacheAndRespringCommand;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
            uicacheCommand = @"uicache --all";
            respringCommand = @"sbreload";
            uicacheAndRespringCommand = @"uicache --all --respring";
        }
        else {
            uicacheCommand = @"uicache";
            respringCommand = @"killall SpringBoard";
            uicacheAndRespringCommand = @"uicache && killall SpringBoard";
        }
        UIStackView *combinedStackView = create2Switches(self);
        combinedStackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            if (uicacheSwitchStatus == true && respringSwitchStatus == false) {
                showProcessingDialog(self, @"Running uicache....", false, 1, true);
                runCommand(uicacheCommand);
                endProcessingDialog(@"Done!", self, false, false);
            }
            else if (uicacheSwitchStatus == false && respringSwitchStatus == true) {
                runCommand(respringCommand);
            }
            else if (uicacheSwitchStatus == true && respringSwitchStatus == true) {
                showProcessingDialog(self, @"Running uicache and respringing....", false, 1, true);
                runCommand(uicacheAndRespringCommand);
            }
        }];
        UIAlertAction *doNothingAction = [UIAlertAction actionWithTitle:@"Do nothing" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
        
        if (transition == true) {
            [progressAlert.view addSubview:combinedStackView];
            [combinedStackView.centerXAnchor constraintEqualToAnchor:progressAlert.view.centerXAnchor].active = YES;
            [combinedStackView.topAnchor constraintEqualToAnchor:progressAlert.view.topAnchor constant:64].active = YES;
            [progressAlert.view layoutIfNeeded];
            CGFloat height = progressAlert.view.bounds.size.height + progressAlert.actions.count * 52 + combinedStackView.bounds.size.height;
            [progressAlert.view.heightAnchor constraintEqualToConstant:height].active = YES;
            
            transitionProgressMessage(theMessage);
            [spinner stopAnimating];
            [progressAlert addAction:proceedAction];
            [progressAlert addAction:doNothingAction];
        }
        else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:theMessage preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:proceedAction];
            [alert addAction:doNothingAction];
            
            [alert.view addSubview:combinedStackView];
            [combinedStackView.centerXAnchor constraintEqualToAnchor:alert.view.centerXAnchor].active = YES;
            [combinedStackView.topAnchor constraintEqualToAnchor:alert.view.topAnchor constant:64].active = YES;
            [alert.view layoutIfNeeded];
            CGFloat height = alert.view.bounds.size.height + alert.actions.count * 52 + combinedStackView.bounds.size.height;
            [alert.view.heightAnchor constraintEqualToConstant:height].active = YES;
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else {
        transitionProgressMessage(theMessage);
        [spinner stopAnimating];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
        [progressAlert addAction:okAction];
    }
}

void showUnfindableTweaks(id self) { //shows the "These tweaks cannot be found" screen. This method is only used when queuing tweaks from Zebra because Zebra lags when doing so. This special implementation fixes that
    NSString *message = [NSString stringWithFormat:@"The following tweaks could not be found:\n\n%@", unfindableTweaks];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy to clipboard and proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = unfindableTweaks;
    }];
    UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    
    [alert addAction:copyAction];
    [alert addAction:proceedAction];
    [self presentViewController:alert animated:YES completion:nil];
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to make Sileo queue all of your tweaks and their dependencies since Sileo does not do this by default
void sileoEndQueueingTweaks(NSMutableString *unfindableTweaks) {
    if ([unfindableTweaks isEqualToString:@""]) {
        [progressAlert dismissViewControllerAnimated:YES completion:^{ [sileoTabBarControllerID presentPopupController]; }];
    }
    else {
        NSString *message = [NSString stringWithFormat:@"The following tweaks could not be found:\n\n%@", unfindableTweaks];
        transitionProgressMessage(message);
        [spinner stopAnimating];
        UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy to clipboard and proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [sileoTabBarControllerID presentPopupController];
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = unfindableTweaks;
        }];
        UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { [sileoTabBarControllerID presentPopupController]; }];
        [progressAlert addAction:copyAction];
        [progressAlert addAction:proceedAction];
    }
}

void sileoAddDependenciesToQueue() {
    NSArray *sileoErrors = [[objc_getClass("_TtC5Sileo15DownloadManager") shared] errors];
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
        Package *thePackage = [[objc_getClass("_TtC5Sileo18PackageListManager") shared] newestPackageWithIdentifier:thePackageIdentifer];
        
        if (thePackage != nil) {
            if ([[objc_getClass("_TtC5Sileo18PackageListManager") shared] installedPackageWithIdentifier:thePackageIdentifer] == nil && ![[[objc_getClass("_TtC5Sileo15DownloadManager") shared] installations] containsObject:thePackage]) {
                [[objc_getClass("_TtC5Sileo15DownloadManager") shared] addWithPackage:thePackage queue:1];
            }
        }
    }
}

void sileoFixDependencies(NSMutableString *unfindableTweaks) {
    sileoAddDependenciesToQueue();
    [[objc_getClass("_TtC5Sileo15DownloadManager") shared] reloadDataWithRecheckPackages:true];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[[objc_getClass("_TtC5Sileo15DownloadManager") shared] errors] count] != 0) {
            sileoFixDependencies(unfindableTweaks);
        }
        else {
            sileoEndQueueingTweaks(unfindableTweaks);
        }
    });
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to actually install any available .debs, add your repos, and queue your tweaks
void installSavedDebs(NSString *motherMessage, NSString *pathToDebsFolder, id self) { //installs all .debs at the given path and updates the UIAlertController about what .deb is being installed right now
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:pathToDebsFolder];
    
    for (NSString *debFileName in directoryEnumerator) {
        if ([[debFileName pathExtension] isEqualToString:@"deb"]) {
            NSString *thePackageIdentifer = runCommand([NSString stringWithFormat:@"prefix=\" Package: \" && dpkg --info %@%@%@%@", pathToDebsFolder, @"/", debFileName, @" | grep \"Package: \" | sed -e \"s/^$prefix//\""]);
            transitionProgressMessage([NSString stringWithFormat:@"%@%@%@", motherMessage, @"\n", thePackageIdentifer]);
            
            runCommand([NSString stringWithFormat:@"batchomaticd 6 %@%@%@", pathToDebsFolder, @"/", debFileName]);
        }
    }
}

void queueTweaks(id self) { //adds all of the user's tweaks to the queue if they are not already installed. Also tells the user if we cannot find some of their tweaks. This is caused when the repo for said tweak is not added, or said tweak was installed from a .deb, so therefore it has no repo
    unfindableTweaks = [[NSMutableString alloc] init];
    FILE *listOfTweaksFile = fopen("/var/mobile/BatchInstall/tweaks.txt", "r");
    
    if (packageManager == 1) { //if we are using Cydia
        while (!feof(listOfTweaksFile)) {
            NSString *thePackageIdentifer = readEachLineOfFile(listOfTweaksFile);
            Package *thePackage = (Package *)[[objc_getClass("Database") sharedInstance] packageWithName:thePackageIdentifer];
            
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
        
        if ([unfindableTweaks isEqualToString:@""]) {
            [progressAlert dismissViewControllerAnimated:YES completion:^{ [cydiaDelegate queue]; }];
        }
        else {
            NSString *message = [NSString stringWithFormat:@"The following tweaks could not be found:\n\n%@", unfindableTweaks];
            transitionProgressMessage(message);
            [spinner stopAnimating];
            UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy to clipboard and proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [cydiaDelegate queue];
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = unfindableTweaks;
            }];
            UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { [cydiaDelegate queue]; }];
            [progressAlert addAction:copyAction];
            [progressAlert addAction:proceedAction];
        }
    }
    
    else if (packageManager == 2) { //if we are using Zebra
        ZBDatabaseManager *zebraDatabase = [objc_getClass("ZBDatabaseManager") sharedInstance];
        ZBQueue *zebraQueue = [objc_getClass("ZBQueue") sharedInstance];
        ZBQueueType zebraInstall = ZBQueueTypeInstall;
        
        while (!feof(listOfTweaksFile)) {
            NSString *thePackageIdentifer = readEachLineOfFile(listOfTweaksFile);
            ZBPackage *thePackage = [zebraDatabase topVersionForPackageID:thePackageIdentifer];
            
            if (thePackage != nil) {
                if ([zebraDatabase packageIDIsInstalled:thePackageIdentifer version:nil] == NO) {
                    [zebraQueue addPackage:thePackage toQueue:zebraInstall];
                }
            }
            else {
                [unfindableTweaks appendString:thePackageIdentifer];
                [unfindableTweaks appendString:@"\n"];
            }
        }
        
        if (![unfindableTweaks isEqualToString:@""]) {
            shouldShowUnfindableTweaks = true;
        }
        [progressAlert dismissViewControllerAnimated:YES completion:^{ [objc_getClass("ZBPackageActionsManager") presentQueue:self parent:nil]; }];
    }
    
    else if (packageManager == 3) { //if we are using Sileo
        while (!feof(listOfTweaksFile)) {
            NSString *thePackageIdentifer = readEachLineOfFile(listOfTweaksFile);
            Package *thePackage = [[objc_getClass("_TtC5Sileo18PackageListManager") shared] newestPackageWithIdentifier:thePackageIdentifer];
            
            if (thePackage != nil) {
                if ([[objc_getClass("_TtC5Sileo18PackageListManager") shared] installedPackageWithIdentifier:thePackageIdentifer] == nil) {
                    [[objc_getClass("_TtC5Sileo15DownloadManager") shared] addWithPackage:thePackage queue:1];
                }
            }
            else {
                [unfindableTweaks appendString:thePackageIdentifer];
                [unfindableTweaks appendString:@"\n"];
            }
        }
        
        [[objc_getClass("_TtC5Sileo15DownloadManager") shared] reloadDataWithRecheckPackages:true];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([[[objc_getClass("_TtC5Sileo15DownloadManager") shared] errors] count] != 0) {
                sileoFixDependencies(unfindableTweaks);
            }
            else {
                sileoEndQueueingTweaks(unfindableTweaks);
            }
        });
    }
    
    else if (packageManager == 4) { //if we are using Installer
        while (!feof(listOfTweaksFile)) {
            NSString *thePackageIdentifer = readEachLineOfFile(listOfTweaksFile);
            
            if ([installerATRPackagesID packageWithIdentifier:thePackageIdentifer] != nil) {
                if (![installerATRPackagesID packageIsInstalled:thePackageIdentifer]) {
                    [installerATRPackagesID setPackage:thePackageIdentifer inTheQueue:true];
                }
            }
            else {
                [unfindableTweaks appendString:thePackageIdentifer];
                [unfindableTweaks appendString:@"\n"];
            }
        }
        
        UIBarButtonItem *installerPresentQueueButton = [[UIBarButtonItem alloc] initWithTitle:@"Queued Packages" style:UIBarButtonItemStylePlain target:installerSearchViewControllerID action:@selector(proceedQueuedPackages)];
        [[installerSearchViewControllerID navigationItem] setRightBarButtonItem:installerPresentQueueButton];
        
        if ([unfindableTweaks isEqualToString:@""]) {
            [progressAlert dismissViewControllerAnimated:YES completion:^{ [installerSearchViewControllerID proceedQueuedPackages]; }];
        }
        else {
            NSString *message = [NSString stringWithFormat:@"The following tweaks could not be found:\n\n%@", unfindableTweaks];
            transitionProgressMessage(message);
            [spinner stopAnimating];
            UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy to clipboard and proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [installerSearchViewControllerID proceedQueuedPackages];
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = unfindableTweaks;
            }];
            UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { [installerSearchViewControllerID proceedQueuedPackages]; }];
            [progressAlert addAction:copyAction];
            [progressAlert addAction:proceedAction];
        }
    }
    fclose(listOfTweaksFile);
}

void addRepos(id self) { //adds all of the user's repos to the currently-in-use package manager
    //Note: code for this feature is continued in the hooks section at the bottom. This is because we need to wait for the repos to finish adding before we can proceed
    refreshesCompleted = 1; //this variable is used for telling my tweak what we should do next. It also ensures that my extra code in the hooks below only execute if the user is currently using Batchomatic
    if (packageManager == 1) {
        Cydia *cydiaDelegate = (Cydia *)[[UIApplication sharedApplication] delegate];
        runCommand(@"/Library/batchomatic/determinerepostoadd.sh 1");
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/batchomatic/reposToAdd.txt" isDirectory:NULL]) {
            FILE *listOfReposFile = fopen("/tmp/batchomatic/reposToAdd.txt", "r");
            while (!feof(listOfReposFile)) {
                NSString *eachRepo = readEachLineOfFile(listOfReposFile);
                if ([eachRepo isEqualToString:@"http://apt.thebigboss.org/repofiles/cydia/"] || [eachRepo isEqualToString:@"http://apt.modmyi.com/"] || [eachRepo isEqualToString:@"http://cydia.zodttd.com/repo/cydia/"]) {
                    NSDictionary *dictionary = @{
                                                 @"Distribution" : @"stable",
                                                 @"Sections" : [NSArray arrayWithObject:@"main"],
                                                 @"Type" : @"deb",
                                                 @"URI" : eachRepo
                                                 };
                    [cydiaDelegate addSource:dictionary];
                }
                else {
                    [cydiaDelegate addTrivialSource:eachRepo];
                }
            }
            fclose(listOfReposFile);
            [cydiaDelegate requestUpdate];
        }
        else {
            refreshesCompleted = 0;
            if (tweaksSwitchStatus == true) {
                updateProgressMessage(@"Queuing tweaks....");
                queueTweaks(self);
            }
            else {
                endProcessingDialog(@"Done! Succesfully installed your .deb!", self, true, true);
            }
        }
        runCommand(@"rm -r /tmp/batchomatic");
        //Remember: code is continued in the hooks below
    }
    
    else if (packageManager == 2) { //Zebra 1.0-beta20-2 and below have a bug where adding a default repo and a third-party repo will prevent some of our repos from being added. So until this is fixed by Wstyres, we have to first add only BigBoss/ZodTTD/ModMyI. When that's finished, we can add the rest of our repos. Now everything will work properly
        runCommand(@"/Library/batchomatic/determinerepostoadd.sh 2");
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/batchomatic/defaultReposToAdd.txt" isDirectory:NULL]) {
            NSString *reposToAdd = [NSString stringWithContentsOfFile:@"/tmp/batchomatic/defaultReposToAdd.txt" encoding:NSUTF8StringEncoding error:nil];
            [progressAlert dismissViewControllerAnimated:YES completion:^{ [zebraZBRepoListTableViewControllerID didAddReposWithText:reposToAdd]; }];
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/batchomatic/reposToAdd.txt" isDirectory:NULL]) {
            refreshesCompleted = 2;
            NSString *reposToAdd = [NSString stringWithContentsOfFile:@"/tmp/batchomatic/reposToAdd.txt" encoding:NSUTF8StringEncoding error:nil];
            [progressAlert dismissViewControllerAnimated:YES completion:^{ [zebraZBRepoListTableViewControllerID didAddReposWithText:reposToAdd]; }];
        }
        else {
            refreshesCompleted = 0;
            runCommand(@"rm -r /tmp/batchomatic");
            if (tweaksSwitchStatus == true) {
                updateProgressMessage(@"Queuing tweaks....");
                queueTweaks(self);
            }
            else {
                endProcessingDialog(@"Done! Succesfully installed your .deb!", self, true, true);
            }
        }
    }
    
    else if (packageManager == 3) { //Remember: Sileo does not support ZodTTD or ModMyI, so these 2 repos will not be added to Sileo. This can cause the "These tweaks cannot be found" screen. Fix this by downloading another package manager and trying to install your .deb again
        runCommand(@"/Library/batchomatic/determinerepostoadd.sh 3");
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/batchomatic/reposToAdd.txt" isDirectory:NULL]) {
            FILE *listOfReposFile = fopen("/tmp/batchomatic/reposToAdd.txt", "r");
            NSMutableArray *reposToAdd = [[NSMutableArray alloc] init];
            
            while (!feof(listOfReposFile)) {
                NSString *eachRepo = readEachLineOfFile(listOfReposFile);
                NSURL *eachRepoAsURL = [NSURL URLWithString:eachRepo];
                [reposToAdd addObject:eachRepoAsURL];
            }
            fclose(listOfReposFile);
            [sileoSourcesViewControllerID handleSourceAddWithURLs:reposToAdd];
        }
        else {
            refreshesCompleted = 0;
            if (tweaksSwitchStatus == true) {
                updateProgressMessage(@"Queuing tweaks....");
                queueTweaks(self);
            }
            else {
                endProcessingDialog(@"Done! Succesfully installed your .deb!", self, true, true);
            }
        }
        runCommand(@"rm -r /tmp/batchomatic");
    }
    
    else if (packageManager == 4) {
        runCommand(@"/Library/batchomatic/determinerepostoadd.sh 4");
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/batchomatic/reposToAdd.txt" isDirectory:NULL]) {
            FILE *listOfReposFile = fopen("/tmp/batchomatic/reposToAdd.txt", "r");
            while (!feof(listOfReposFile)) {
                NSString *eachRepo = readEachLineOfFile(listOfReposFile);
                [installerManageViewControllerID addSourceWithString:eachRepo withHttpApproval:true];
            }
            fclose(listOfReposFile);
            [progressAlert dismissViewControllerAnimated:YES completion:^{ [self showTaskView]; }];
        }
        else {
            refreshesCompleted = 0;
            if (tweaksSwitchStatus == true) {
                updateProgressMessage(@"Queuing tweaks....");
                queueTweaks(self);
            }
            else {
                endProcessingDialog(@"Done! Succesfully installed your .deb!", self, true, true);
            }
        }
        runCommand(@"rm -r /tmp/batchomatic");
    }
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to perform the main features of this tweak
void createDeb(id self) { //creates a .deb with the user's tweaks, repos, tweak preferences, saved .debs, and hosts file
    maxSteps = 1;
    
    showProcessingDialog(self, @"Creating your custom .deb....", true, 1, true);
    runCommand(@"/Library/batchomatic/create.sh");
    
    endProcessingDialog(@"Done!\nSuccesfully created your .deb!\nIt's at /var/mobile/BatchomaticDebs", self, false, false);
}

void installDeb(id self) { //determines what the user wants to be installed and does it
    maxSteps = 1;
    if (prefsSwitchStatus == true) {
        maxSteps = maxSteps + 1;
    }
    if (savedDebsSwitchStatus == true) {
        maxSteps = maxSteps + 1;
    }
    if (hostsSwitchStatus == true) {
        maxSteps = maxSteps + 1;
    }
    if (debIsOnlineMode() == true) {
        if (reposSwitchStatus == true) {
            maxSteps = maxSteps + 1;
        }
        if (tweaksSwitchStatus == true) {
            maxSteps = maxSteps + 1;
        }
    }
    else {
        if (offlineDebsSwitchStatus == true) {
            maxSteps = maxSteps + 1;
        }
    }
    
    showProcessingDialog(self, @"Verifying your .deb....", true, 1, true);
    if (isDebInstalled() == false) {
        endProcessingDialog(@"Error:\nYour .deb is not currently installed. Go install it with Filza and try again", self, false, false);
        return;
    }
    if (isDebModern() == false) {
        endProcessingDialog(@"Error:\nYou need to convert your .deb to be made with v3.0 or newer. Go back and tap 'Convert old .deb'", self, false, false);
        return;
    }
    
    if (allSwitchesAreOff() == true) {
        endProcessingDialog(@"Done! No toggles were on, so no action was taken", self, true, true);
        return;
    }
    
    if (prefsSwitchStatus == true) {
        updateProgressMessage(@"Installing preferences....");
        runCommand(@"find /var/mobile/BatchInstall -type f -exec chmod 777 {} \\;");
        runCommand(@"find /var/mobile/BatchInstall -type d -exec chmod 777 {} \\;");
        runCommand(@"cp -r /var/mobile/BatchInstall/Preferences/* /var/mobile/Library/Preferences");
    }
    
    if (savedDebsSwitchStatus == true) {
        NSString *motherMessage = updateProgressMessage(@"Installing saved .debs....");
        installSavedDebs(motherMessage, @"/var/mobile/BatchInstall/SavedDebs", self);
    }
    
    if (hostsSwitchStatus == true) {
        updateProgressMessage(@"Installing hosts....");
        runCommand(@"batchomaticd 3");
        runCommand(@"batchomaticd 4");
        runCommand(@"batchomaticd 5");
    }
    
    if (offlineDebsSwitchStatus == true) {
        NSString *motherMessage = updateProgressMessage(@"Installing offline .debs....");
        installSavedDebs(motherMessage, @"/var/mobile/BatchInstall/OfflineDebs", self);
    }
    
    if (reposSwitchStatus == true) {
        updateProgressMessage(@"Adding repos....");
        addRepos(self);
        return;
    }
    
    if (tweaksSwitchStatus == true) {
        updateProgressMessage(@"Queuing tweaks....");
        queueTweaks(self);
        return;
    }
    
    endProcessingDialog(@"Done! Succesfully installed your .deb!", self, true, true);
}

void convertDeb(id self) { //converts a .deb that was made with prior Batchomatic versions into a .deb that can be used with v3.0
    maxSteps = 2;
    
    showProcessingDialog(self, @"Verifying your .deb....", true, 1, true);
    if (isDebInstalled() == false) {
        endProcessingDialog(@"Error:\nYour .deb is not currently installed. Go install it with Filza and try again", self, false, false);
        return;
    }
    if (isDebModern() == true) {
        endProcessingDialog(@"Error:\nYour currently installed .deb was already made with v3.0 or newer", self, false, false);
        return;
    }
    
    updateProgressMessage(@"Converting your .deb....");
    runCommand(@"/Library/batchomatic/convert.sh");
    
    endProcessingDialog(@"Done!\nSuccesfully converted your old .deb into a new one!\nIt's now at /var/mobile/BatchomaticDebs\n\nBefore you can install this new .deb, you need to remove the current BatchInstall tweak and then install the converted .deb", self, false, false);
}

void createOfflineDeb(id self) { //creates a .deb with .debs of the user's tweaks, their saved .debs, tweak preferences, and hosts file. Repos and the list of tweaks to queue are NOT included
    maxSteps = 3;
    
    showProcessingDialog(self, @"Creating your custom offline .deb....", true, 1, true);
    runCommand(@"/Library/batchomatic/createoffline-part1.sh");
    
    NSString *motherMessage = updateProgressMessage(@"Creating .debs of your tweaks. This could take several minutes....");
    FILE *tweaksToCreateDebsForFile = fopen("/tmp/batchomatic/tweaks.txt", "r");
    
    while (!feof(tweaksToCreateDebsForFile)) {
        NSString *thePackageIdentifer = readEachLineOfFile(tweaksToCreateDebsForFile);
        transitionProgressMessage([NSString stringWithFormat:@"%@%@%@", motherMessage, @"\n", thePackageIdentifer]);
        
        NSString *theCommand = [NSString stringWithFormat:@"/Library/batchomatic/createoffline-part2.sh %@", thePackageIdentifer];
        runCommand(theCommand);
    }
    fclose(tweaksToCreateDebsForFile);
    
    updateProgressMessage(@"Building your custom offline .deb....");
    FILE *timestampFile = fopen("/tmp/batchomatic/timestamp.txt", "r");
    NSString *scriptTimestamp = readEachLineOfFile(timestampFile);
    NSString *theCommand = [NSString stringWithFormat:@"/Library/batchomatic/createoffline-part3.sh %@", scriptTimestamp];
    runCommand(theCommand);
    
    endProcessingDialog(@"Done!\nSuccesfully created your offline .deb!\nIt's at /var/mobile/BatchomaticDebs", self, false, false);
}

void removeAll(id self) { //Removes ALL of the user's tweaks. All of them. This is like a wannabe Restore RootFS
    maxSteps = 1;
    showProcessingDialog(self, @"Removing all tweaks....", true, 1, true);
    runCommand(@"/Library/batchomatic/removealltweaks.sh");
    FILE *removeAllTweaksFile = fopen("/tmp/batchomatic/removeall.txt", "r");
    
    if (packageManager == 1) {
        while (!feof(removeAllTweaksFile)) {
            NSString *thePackageIdentifer = readEachLineOfFile(removeAllTweaksFile);
            Package *thePackage = (Package *)[[objc_getClass("Database") sharedInstance] packageWithName:thePackageIdentifer];
            
            if ([thePackage installed]) {
                [thePackage remove];
            }
        }
        
        Cydia *cydiaDelegate = (Cydia *)[[UIApplication sharedApplication] delegate];
        [cydiaDelegate resolve];
        
        [progressAlert dismissViewControllerAnimated:YES completion:^{ [cydiaDelegate queue]; }];
    }
    
    else if (packageManager == 2) {
        ZBDatabaseManager *zebraDatabase = [objc_getClass("ZBDatabaseManager") sharedInstance];
        ZBQueue *zebraQueue = [objc_getClass("ZBQueue") sharedInstance];
        ZBQueueType zebraRemove = ZBQueueTypeRemove;
        
        while (!feof(removeAllTweaksFile)) {
            NSString *thePackageIdentifer = readEachLineOfFile(removeAllTweaksFile);
            ZBPackage *thePackage = [zebraDatabase topVersionForPackageID:thePackageIdentifer];
            
            if ([zebraDatabase packageIDIsInstalled:thePackageIdentifer version:nil] == YES) {
                [zebraQueue addPackage:thePackage toQueue:zebraRemove];
            }
        }
        
        [progressAlert dismissViewControllerAnimated:YES completion:^{ [objc_getClass("ZBPackageActionsManager") presentQueue:self parent:nil]; }];
    }
    
    else if (packageManager == 3) {
        while (!feof(removeAllTweaksFile)) {
            NSString *thePackageIdentifer = readEachLineOfFile(removeAllTweaksFile);
            
            if ([[objc_getClass("_TtC5Sileo18PackageListManager") shared] installedPackageWithIdentifier:thePackageIdentifer] != nil) {
                Package *thePackage = [[objc_getClass("_TtC5Sileo18PackageListManager") shared] newestPackageWithIdentifier:thePackageIdentifer];
                [[objc_getClass("_TtC5Sileo15DownloadManager") shared] addWithPackage:thePackage queue:2];
            }
        }
        
        [[objc_getClass("_TtC5Sileo15DownloadManager") shared] reloadDataWithRecheckPackages:true];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [progressAlert dismissViewControllerAnimated:YES completion:^{ [sileoTabBarControllerID presentPopupController]; }];
        });
    }
    
    else if (packageManager == 4) {
        while (!feof(removeAllTweaksFile)) {
            NSString *thePackageIdentifer = readEachLineOfFile(removeAllTweaksFile);
            
            if ([installerATRPackagesID packageIsInstalled:thePackageIdentifer]) {
                [installerATRPackagesID setPackage:thePackageIdentifer inTheQueue:true];
            }
        }
        
        UIBarButtonItem *installerPresentQueueButton = [[UIBarButtonItem alloc] initWithTitle:@"Queued Packages" style:UIBarButtonItemStylePlain target:installerSearchViewControllerID action:@selector(proceedQueuedPackages)];
        [[installerSearchViewControllerID navigationItem] setRightBarButtonItem:installerPresentQueueButton];
        
        [progressAlert dismissViewControllerAnimated:YES completion:^{ [installerSearchViewControllerID proceedQueuedPackages]; }];
    }
    fclose(removeAllTweaksFile);
    runCommand(@"rm -r /tmp/batchomatic");
}

//--------------------------------------------------------------------------------------------------------------------------
//methods to show the main screen UI
void installDebClient(id self) { //finalizes the 'Install .deb' screen
    UIAlertController *optionsAlert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {installDeb(self);}];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    
    [optionsAlert addAction:proceedAction];
    [optionsAlert addAction:cancelAction];
    
    UIStackView *combinedStackView = create5Switches(self);
    [optionsAlert.view addSubview:combinedStackView];
    [combinedStackView.centerXAnchor constraintEqualToAnchor:optionsAlert.view.centerXAnchor].active = YES;
    combinedStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [combinedStackView.topAnchor constraintEqualToAnchor:optionsAlert.view.topAnchor constant:64].active = YES;
    [optionsAlert.view layoutIfNeeded];
    CGFloat height = optionsAlert.view.bounds.size.height + optionsAlert.actions.count * 52 + combinedStackView.bounds.size.height;
    [optionsAlert.view.heightAnchor constraintEqualToConstant:height].active = YES;
    
    [self presentViewController:optionsAlert animated:YES completion:nil];
}

void convertDebClient(id self) { //asks the user if they installed all of the necessary repos for their tweaks. This is required to sucecesfully convert an old .deb
    UIAlertController *noticeAlert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:@"Converting requires you to add all of the necessary repos before converting. Tap 'Cancel' if you have not done that" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {convertDeb(self);}];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];

    [noticeAlert addAction:proceedAction];
    [noticeAlert addAction:cancelAction];
    [self presentViewController:noticeAlert animated:YES completion:nil];
}

void buttonTapped(id self) { //shows the mother UIAlertController
    NSString *alertTitle = [@"Batchomatic " stringByAppendingString:batchomaticVersion];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *createDebAction = [UIAlertAction actionWithTitle:@"Create .deb" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { createDeb(self); }];
    UIAlertAction *installDebAction = [UIAlertAction actionWithTitle:@"Install .deb" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { installDebClient(self); }];
    UIAlertAction *convertDebAction = [UIAlertAction actionWithTitle:@"Convert old .deb" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { convertDebClient(self); }];
    UIAlertAction *createOfflineDebAction = [UIAlertAction actionWithTitle:@"Create offline .deb" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { createOfflineDeb(self); }];
    UIAlertAction *removeAllAction = [UIAlertAction actionWithTitle:@"Remove all tweaks" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { removeAll(self); }];
    UIAlertAction *respringAction = [UIAlertAction actionWithTitle:@"Respring/uicache" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { endProcessingDialog(nil, self, true, false); }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    
    [alert addAction:createDebAction];
    [alert addAction:installDebAction];
    [alert addAction:convertDebAction];
    [alert addAction:createOfflineDebAction];
    [alert addAction:removeAllAction];
    [alert addAction:respringAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

//--------------------------------------------------------------------------------------------------------------------------
//hooks for compatibility with Cydia
%hook SearchController
- (void) viewDidLoad {
    %orig;
    cydiaSearchControllerID = self;
    UIBarButtonItem *batchomaticButton = [[UIBarButtonItem alloc] initWithTitle:@"Batchomatic" style:UIBarButtonItemStylePlain target:self action:@selector(startBatchomatic)];
    [[self navigationItem] setLeftBarButtonItem:batchomaticButton];
}

%new
- (void) startBatchomatic {
    packageManager = 1;
    buttonTapped(self);
}

//all of these switchTapped methods are needed to tell my tweak what the user wants to do. I don't know how to condense this into less-confusing code. Sorry
%new
- (void) prefsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        prefsSwitchStatus = true;
    }
    else {
        prefsSwitchStatus = false;
    }
}
%new
- (void) savedDebsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        savedDebsSwitchStatus = true;
    }
    else {
        savedDebsSwitchStatus = false;
    }
}
%new
- (void) hostsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        hostsSwitchStatus = true;
    }
    else {
        hostsSwitchStatus = false;
    }
}
%new
- (void) reposSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        reposSwitchStatus = true;
    }
    else {
        reposSwitchStatus = false;
    }
}
%new
- (void) tweaksSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        tweaksSwitchStatus = true;
    }
    else {
        tweaksSwitchStatus = false;
    }
}
%new
- (void) offlineDebsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        offlineDebsSwitchStatus = true;
    }
    else {
        offlineDebsSwitchStatus = false;
    }
}
%new
- (void) uicacheSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        uicacheSwitchStatus = true;
    }
    else {
        uicacheSwitchStatus = false;
    }
}
%new
- (void) respringSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        respringSwitchStatus = true;
    }
    else {
        respringSwitchStatus = false;
    }
}
%end

%hook Cydia
- (void) reloadData { //this method is called when adding repos is finished. Remember, code to continue that feature is here
    %orig;
    if (refreshesCompleted == 1) {
        Cydia *cydiaDelegate = (Cydia *)[[UIApplication sharedApplication] delegate];
        [cydiaDelegate requestUpdate];
        refreshesCompleted = 2;
    }
    else if (refreshesCompleted == 2) {
        refreshesCompleted = 0;
        if (tweaksSwitchStatus == true) {
            updateProgressMessage(@"Queuing tweaks....");
            queueTweaks(cydiaSearchControllerID);
        }
        else {
            endProcessingDialog(@"Done! Succesfully installed your .deb!", cydiaSearchControllerID, true, true);
        }
    }
}
%end

//--------------------------------------------------------------------------------------------------------------------------
//hooks for compatibility with Zebra
%hook ZBSearchViewController
- (void) viewDidLoad {
    %orig;
    zebraZBSearchViewControllerID = self;
    UIBarButtonItem *batchomaticButton = [[UIBarButtonItem alloc] initWithTitle:@"Batchomatic" style:UIBarButtonItemStylePlain target:self action:@selector(startBatchomatic)];
    [[self navigationItem] setLeftBarButtonItem:batchomaticButton];
}

%new
- (void) startBatchomatic {
    packageManager = 2;
    buttonTapped(self);
}

%new
- (void) prefsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        prefsSwitchStatus = true;
    }
    else {
        prefsSwitchStatus = false;
    }
}
%new
- (void) savedDebsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        savedDebsSwitchStatus = true;
    }
    else {
        savedDebsSwitchStatus = false;
    }
}
%new
- (void) hostsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        hostsSwitchStatus = true;
    }
    else {
        hostsSwitchStatus = false;
    }
}
%new
- (void) reposSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        reposSwitchStatus = true;
    }
    else {
        reposSwitchStatus = false;
    }
}
%new
- (void) tweaksSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        tweaksSwitchStatus = true;
    }
    else {
        tweaksSwitchStatus = false;
    }
}
%new
- (void) offlineDebsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        offlineDebsSwitchStatus = true;
    }
    else {
        offlineDebsSwitchStatus = false;
    }
}
%new
- (void) uicacheSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        uicacheSwitchStatus = true;
    }
    else {
        uicacheSwitchStatus = false;
    }
}
%new
- (void) respringSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        respringSwitchStatus = true;
    }
    else {
        respringSwitchStatus = false;
    }
}
%end

%hook ZBTabBarController
- (void) viewDidAppear:(BOOL)animated { //again, this method is called when adding repos is finished. so we continue here
    %orig;
    if (refreshesCompleted == 1) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/batchomatic/reposToAdd.txt" isDirectory:NULL]) {
            refreshesCompleted = 2;
            NSString *reposToAdd = [NSString stringWithContentsOfFile:@"/tmp/batchomatic/reposToAdd.txt" encoding:NSUTF8StringEncoding error:nil];
            [zebraZBRepoListTableViewControllerID didAddReposWithText:reposToAdd];
        }
        else {
            refreshesCompleted = 0;
            runCommand(@"rm -r /tmp/batchomatic");
            if (tweaksSwitchStatus == true) {
                showProcessingDialog(zebraZBSearchViewControllerID, @"Queuing tweaks....", true, currentStep + 1, false);
                [zebraZBSearchViewControllerID presentViewController:progressAlert animated:true completion:^{ queueTweaks(zebraZBSearchViewControllerID); }];
            }
            else {
                endProcessingDialog(@"Done! Succesfully installed your .deb!", zebraZBSearchViewControllerID, true, false);
            }
        }
    }
    else if (refreshesCompleted == 2) {
        refreshesCompleted = 0;
        runCommand(@"rm -r /tmp/batchomatic");
        if (tweaksSwitchStatus == true) {
            showProcessingDialog(zebraZBSearchViewControllerID, @"Queuing tweaks....", true, currentStep + 1, false);
            [zebraZBSearchViewControllerID presentViewController:progressAlert animated:true completion:^{ queueTweaks(zebraZBSearchViewControllerID); }];
        }
        else {
            endProcessingDialog(@"Done! Succesfully installed your .deb!", zebraZBSearchViewControllerID, true, false);
        }
    }
}
%end

%hook ZBQueueViewController
- (void) loadView {
    %orig;
    if (shouldShowUnfindableTweaks == true) {
        shouldShowUnfindableTweaks = false;
        showUnfindableTweaks(self);
    }
}
%end

%hook ZBRepoListTableViewController
- (void) viewDidLoad {
    %orig;
    zebraZBRepoListTableViewControllerID = self;
}
%end

//--------------------------------------------------------------------------------------------------------------------------
//hooks for compatibility with Sileo
%hook PackageListViewController
- (void) viewDidLoad {
    %orig;
    sileoPackageListViewControllerID = self;
    if ([self.title isEqualToString:@"Search"]) {
        UIBarButtonItem *batchomaticButton = [[UIBarButtonItem alloc] initWithTitle:@"Batchomatic" style:UIBarButtonItemStylePlain target:self action:@selector(startBatchomatic)];
        [[self navigationItem] setLeftBarButtonItem:batchomaticButton];
    }
}

%new
- (void) startBatchomatic {
    packageManager = 3;
    buttonTapped(self);
}

%new
- (void) prefsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        prefsSwitchStatus = true;
    }
    else {
        prefsSwitchStatus = false;
    }
}
%new
- (void) savedDebsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        savedDebsSwitchStatus = true;
    }
    else {
        savedDebsSwitchStatus = false;
    }
}
%new
- (void) hostsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        hostsSwitchStatus = true;
    }
    else {
        hostsSwitchStatus = false;
    }
}
%new
- (void) reposSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        reposSwitchStatus = true;
    }
    else {
        reposSwitchStatus = false;
    }
}
%new
- (void) tweaksSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        tweaksSwitchStatus = true;
    }
    else {
        tweaksSwitchStatus = false;
    }
}
%new
- (void) offlineDebsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        offlineDebsSwitchStatus = true;
    }
    else {
        offlineDebsSwitchStatus = false;
    }
}
%new
- (void) uicacheSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        uicacheSwitchStatus = true;
    }
    else {
        uicacheSwitchStatus = false;
    }
}
%new
- (void) respringSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        respringSwitchStatus = true;
    }
    else {
        respringSwitchStatus = false;
    }
}
%end

%hook SourcesViewController
- (void) viewDidLoad {
    %orig;
    sileoSourcesViewControllerID = self;
}
%end

%hook TabBarController
- (void) viewDidLoad {
    %orig;
    sileoTabBarControllerID = self;
}
%end

%hook UIActivityIndicatorView
- (void) stopAnimating {
    %orig;
    if (refreshesCompleted == 1 && packageManager == 3 && [NSStringFromClass(self.superview.class) length] == 0) {
        refreshesCompleted = 0;
        if (tweaksSwitchStatus == true) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                updateProgressMessage(@"Queuing tweaks....");
                queueTweaks(sileoPackageListViewControllerID);
            });
        }
        else {
            endProcessingDialog(@"Done! Succesfully installed your .deb!", sileoPackageListViewControllerID, true, true);
        }
    }
}
%end

//--------------------------------------------------------------------------------------------------------------------------
//hooks for compatibility with Installer
%hook SearchViewController
- (void) viewDidLoad {
    %orig;
    installerSearchViewControllerID = self;
    UIBarButtonItem *batchomaticButton = [[UIBarButtonItem alloc] initWithTitle:@"Batchomatic" style:UIBarButtonItemStylePlain target:self action:@selector(startBatchomatic)];
    [[self navigationItem] setLeftBarButtonItem:batchomaticButton];
}

%new
- (void) startBatchomatic {
    packageManager = 4;
    buttonTapped(self);
}

%new
- (void) prefsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        prefsSwitchStatus = true;
    }
    else {
        prefsSwitchStatus = false;
    }
}
%new
- (void) savedDebsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        savedDebsSwitchStatus = true;
    }
    else {
        savedDebsSwitchStatus = false;
    }
}
%new
- (void) hostsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        hostsSwitchStatus = true;
    }
    else {
        hostsSwitchStatus = false;
    }
}
%new
- (void) reposSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        reposSwitchStatus = true;
    }
    else {
        reposSwitchStatus = false;
    }
}
%new
- (void) tweaksSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        tweaksSwitchStatus = true;
    }
    else {
        tweaksSwitchStatus = false;
    }
}
%new
- (void) offlineDebsSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        offlineDebsSwitchStatus = true;
    }
    else {
        offlineDebsSwitchStatus = false;
    }
}
%new
- (void) uicacheSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        uicacheSwitchStatus = true;
    }
    else {
        uicacheSwitchStatus = false;
    }
}
%new
- (void) respringSwitchTapped:(UISwitch *)theSwitch {
    if ([theSwitch isOn]) {
        respringSwitchStatus = true;
    }
    else {
        respringSwitchStatus = false;
    }
}
%end

%hook ManageViewController
- (void) viewDidLoad {
    %orig;
    installerManageViewControllerID = self;
}
%end

%hook ATRPackages
- (id) init {
    %orig;
    installerATRPackagesID = self;
    return self;
}
%end

%hook TasksViewController
- (void) viewWillDisappear:(bool)animated {
    %orig;
    if (refreshesCompleted == 1) {
        refreshesCompleted = 0;
        if (tweaksSwitchStatus == true) {
            showProcessingDialog(installerSearchViewControllerID, @"Queuing tweaks....", true, currentStep + 1, false);
            [installerSearchViewControllerID presentViewController:progressAlert animated:true completion:^{ queueTweaks(installerSearchViewControllerID); }];
        }
        else {
            endProcessingDialog(@"Done! Succesfully installed your .deb!", installerSearchViewControllerID, true, false);
        }
    }
}
%end

//and there you have it!

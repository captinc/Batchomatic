//
//  Tweak.xm
//  Batchomatic
//  
//  Created by Capt Inc on 2020-06-01
//  Copyright © 2020 Capt Inc. All rights reserved.
//

#import "Headers/Batchomatic.h"
#import "Headers/Tweak.h"
extern int refreshesCompleted;

// Cydia
%hook SearchController
- (void)viewDidLoad {
    %orig;
    [Batchomatic placeButton:self];
}
%new
- (void)startBatchomatic {
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.packageManager = 1;
    // motherClass is whatever view controller we are coming from in the
    // package manager (for example: Cydia's Search view controller)
    bm.motherClass = self;
    [Batchomatic openMainScreen:self];
}
%end

%hook Cydia
// Cydia calls this method when it finishes adding repos. Remember, this
// code continues the "Add repos" feature. After this hook, code is
// continued further in "- (void)processingReposDidFinish:" in Batchomatic.xm
- (void)reloadData {
    %orig;
    if (refreshesCompleted == 1) {
        // there's a weird bug in Cydia where you have to refresh
        // sources twice in order for changes to take effect
        Cydia *cydiaDelegate = (Cydia *)[[UIApplication sharedApplication] delegate];
        [cydiaDelegate requestUpdate];
        refreshesCompleted = 2;
    }
    else if (refreshesCompleted == 2) {
        // Pass YES/NO for whether or not we should transition
        // the existing processing dialog or make a new one
        [[Batchomatic sharedInstance] processingReposDidFinish:YES];
    }
}

 // Surpresses the "Half-installed packages" screen only when Batchomatic is currently adding repos
- (void)_loaded {
    if (refreshesCompleted != 0) {
        return;
    }
    else {
        %orig;
    }
}
%end

//--------------------------------------------------------------------------------------------------------------------------
// Zebra
%hook ZBSearchTableViewController
- (void)viewDidLoad {
    %orig;
    [Batchomatic placeButton:self];
}
%new
- (void)startBatchomatic {
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.packageManager = 2;
    bm.motherClass = self;
    // This saves the instance of ZBTabBarController for later use
    bm.zebra_ZBTabBarController = (ZBTabBarController *)self.tabBarController;
    UINavigationController *ctrl = self.tabBarController.viewControllers[1];
    // And this saves the instance of ZBRepoListTableViewController
    bm.zebra_ZBSourceListTableViewController = (ZBSourceListTableViewController *)ctrl.viewControllers[0];
    [bm.zebra_ZBSourceListTableViewController viewDidLoad];
    [Batchomatic openMainScreen:self];
}
%end

%hook ZBRefreshViewController
// Zebra calls this method when it finishes adding repos
- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    if (refreshesCompleted != 0) {
        // Zebra displays a pop-up when adding repos, which dismisses my UIAlertController.
        // So, we need to create a new UIAlertController by passing 'NO'
        [[Batchomatic sharedInstance] processingReposDidFinish:NO];
    }
}
%end

//--------------------------------------------------------------------------------------------------------------------------
// Sileo
%hook _TtC5Sileo25PackageListViewController
- (void)viewDidLoad {
    %orig;
    if (!self.navigationItem.rightBarButtonItem) {
         // Sileo does not have a dedicated Search view controller, so dispatch_once
         // ensures the button is only placed on top of the Search bar and nowhere else
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [Batchomatic placeButton:self];
        });
    }
}
%new
- (void)startBatchomatic {
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.packageManager = 3;
    bm.motherClass = self;
    UINavigationController *ctrl = self.tabBarController.viewControllers[2];
    bm.sileo_SourcesViewController = (_TtC5Sileo21SourcesViewController *)ctrl.viewControllers[0];
    [Batchomatic openMainScreen:self];
}
%end

// I couldn't find a method in Sileo's classes that is called
// when adding repos is finished, so this will have to suffice
%hook UIActivityIndicatorView
- (void)stopAnimating {
    %orig;
    Batchomatic *bm = [Batchomatic sharedInstance];
    // Make sure to execute my code ONLY if we are using Sileo
    // AND if adding repos with Batchomatic just finished
    if (refreshesCompleted != 0 && bm.packageManager == 3 && [NSStringFromClass(self.superview.class) length] == 0) {
        // Dispatch_after is necessary because Sileo takes a few seconds to update what tweaks are in the queue
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [bm processingReposDidFinish:YES];
        });
    }
}
%end

//--------------------------------------------------------------------------------------------------------------------------
// Installer
%hook SearchViewController
- (void)viewDidLoad {
    %orig;
    [Batchomatic placeButton:self];
}
%new
- (void)startBatchomatic {
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.packageManager = 4;
    bm.motherClass = self;
    bm.installer_ATTabBarController = (ATTabBarController *)self.tabBarController;
    UINavigationController *ctrl = self.tabBarController.viewControllers[3];
    bm.installer_ManageViewController = (ManageViewController *)ctrl.viewControllers[0];
    [Batchomatic openMainScreen:self];
}
%end

%hook TasksViewController
 // Installer calls this method when it finishes adding repos
- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    if (refreshesCompleted != 0) {
        [[Batchomatic sharedInstance] processingReposDidFinish:NO];
    }
}
%end

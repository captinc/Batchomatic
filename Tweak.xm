#import <headers/Tweak.h>
#import <headers/BMHomeTableViewController.h>
#import <headers/batchomatic.h>
extern int refreshesCompleted;

//hooks for compatibility with Cydia
%hook SearchController
- (void)viewDidLoad {
    %orig;
    UIBarButtonItem *batchomaticButton = [[UIBarButtonItem alloc] initWithTitle:@"Batchomatic" style:UIBarButtonItemStylePlain target:self action:@selector(startBatchomatic)];
    [[self navigationItem] setLeftBarButtonItem:batchomaticButton];
}
%new
- (void)startBatchomatic {
    batchomatic *bm = [batchomatic sharedInstance];
    bm.packageManager = 1;
    bm.motherClass = self; //this variable is whatever view controller we are coming from in the package manager
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[BMHomeTableViewController alloc] init]];
    [self presentViewController:nav animated:YES completion:nil];
}
%end

%hook Cydia
- (void)reloadData { //this method is called when adding repos is finished. Remember, this code continues the "Add repos" feature. After this method, code is continued in the (void)addingReposDidFinish method in batchomatic.xm
    %orig;
    if (refreshesCompleted == 1) {
        Cydia *cydiaDelegate = (Cydia *)[[UIApplication sharedApplication] delegate];
        [cydiaDelegate requestUpdate];
        refreshesCompleted = 2;
    }
    else if (refreshesCompleted == 2) {
        [[%c(batchomatic) sharedInstance] addingReposDidFinish:true]; //we are passing true/false for whether or not we should transition the existing processing dialog or make a whole new one
    }
}

- (void)_loaded { //surpresses the "Half-installed packages" screen ONLY when Batchomatic is currently adding repos
    if (refreshesCompleted != 0) {
        return;
    }
    else {
        %orig;
    }
}
%end

//--------------------------------------------------------------------------------------------------------------------------
//hooks for compatibility with Zebra
%hook ZBSearchViewController
- (void)viewDidLoad {
    %orig;
    UIBarButtonItem *batchomaticButton = [[UIBarButtonItem alloc] initWithTitle:@"Batchomatic" style:UIBarButtonItemStylePlain target:self action:@selector(startBatchomatic)];
    [[self navigationItem] setLeftBarButtonItem:batchomaticButton];
}
%new
- (void)startBatchomatic {
    batchomatic *bm = [batchomatic sharedInstance];
    bm.packageManager = 2;
    bm.motherClass = self;
    bm.zebra_ZBTabBarController = (ZBTabBarController *)self.tabBarController; //this saves the instance of ZBTabBarController for later use
    UINavigationController *ctrl = self.tabBarController.viewControllers[1];
    [(ZBRepoListTableViewController *)ctrl.viewControllers[0] viewDidLoad];
    bm.zebra_ZBRepoListTableViewController = (ZBRepoListTableViewController *)ctrl.viewControllers[0]; //and this saves the instance of ZBRepoListTableViewController
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[BMHomeTableViewController alloc] init]];
    [self presentViewController:nav animated:YES completion:nil];
}
%end

%hook ZBTabBarController
- (void)viewDidAppear:(BOOL)animated { //Zebra calls this method when it finishes adding repos
    %orig;
    if (refreshesCompleted != 0) {
        if (refreshesCompleted == 1) { //but because this method is also called when we dismiss BMHomeTableViewController, we have to wait until the second time its called
            refreshesCompleted++;
        }
        else if (refreshesCompleted == 2) {
            [[%c(batchomatic) sharedInstance] addingReposDidFinish:false]; //Zebra displays a pop-up when adding repos, which dismisses my UIAlertController. so, we need to create a new UIAlertController after adding repos is finished by passing 'false' to this method
        }
    }
}
%end

//--------------------------------------------------------------------------------------------------------------------------
//hooks for compatibility with Sileo
%hook _TtC5Sileo25PackageListViewController
- (void)viewDidLoad {
    %orig;
    if (!self.navigationItem.rightBarButtonItem) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ //Sileo does not have a dedicated Search UIViewController, so dispatch_once ensures the button is only placed once (on top of the search bar)
            UIBarButtonItem *batchomaticButton = [[UIBarButtonItem alloc] initWithTitle:@"Batchomatic" style:UIBarButtonItemStylePlain target:self action:@selector(startBatchomatic)];
            [[self navigationItem] setLeftBarButtonItem:batchomaticButton];
        });
    }
}
%new
- (void)startBatchomatic {
    batchomatic *bm = [batchomatic sharedInstance];
    bm.packageManager = 3;
    bm.motherClass = self;
    UINavigationController *ctrl = self.tabBarController.viewControllers[2];
    bm.sileo_SourcesViewController = (_TtC5Sileo21SourcesViewController *)ctrl.viewControllers[0];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[BMHomeTableViewController alloc] init]];
    [self presentViewController:nav animated:YES completion:nil];
}
%end

%hook UIActivityIndicatorView //Sileo calls this method when it finishes adding repos (Sileo is slightly different than other package managers)
- (void)stopAnimating {
    %orig;
    batchomatic *bm = [%c(batchomatic) sharedInstance];
    if (refreshesCompleted != 0 && bm.packageManager == 3 && [NSStringFromClass(self.superview.class) length] == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ //dispatch_after is necessary because Sileo takes a few seconds to update what tweaks are in the queue
            [bm addingReposDidFinish:true];
        });
    }
}
%end

//--------------------------------------------------------------------------------------------------------------------------
//hooks for compatibility with Installer
%hook SearchViewController
- (void)viewDidLoad {
    %orig;
    UIBarButtonItem *batchomaticButton = [[UIBarButtonItem alloc] initWithTitle:@"Batchomatic" style:UIBarButtonItemStylePlain target:self action:@selector(startBatchomatic)];
    [[self navigationItem] setLeftBarButtonItem:batchomaticButton];
}
%new
- (void)startBatchomatic {
    batchomatic *bm = [batchomatic sharedInstance];
    bm.packageManager = 4;
    bm.motherClass = self;
    bm.installer_SearchViewController = self;
    UINavigationController *ctrl = self.tabBarController.viewControllers[3];
    bm.installer_ManageViewController = (ManageViewController *)ctrl.viewControllers[0];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[BMHomeTableViewController alloc] init]];
    [self presentViewController:nav animated:YES completion:nil];
}
%end

%hook TasksViewController
- (void)viewWillDisappear:(bool)animated { //Installer calls this method when it finishes adding repos
    %orig;
    if (refreshesCompleted != 0) {
        [[%c(batchomatic) sharedInstance] addingReposDidFinish:false];
    }
}
%end

%hook ATRPackages
- (id)init {
    %orig;
    batchomatic *bm = [%c(batchomatic) sharedInstance];
    bm.installer_ATRPackages = self;
    return self;
}
%end

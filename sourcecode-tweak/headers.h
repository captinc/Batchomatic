//headers for compatibility with Cydia
@interface SearchController : UIViewController
- (void) viewDidLoad;
@end

@interface Cydia : UIApplication
- (void) reloadData;
- (void) _loaded;
- (void) resolve;
- (void) queue;
- (void) addSource:(NSDictionary *)dictionary;
- (BOOL) addTrivialSource:(NSString *)href;
- (bool) requestUpdate;
@end

@interface PackageListController : UIViewController
- (id) packageWithName:(NSString *)packageIdentifier;
@end

@interface Database : NSObject
+ (Database *) sharedInstance;
@end

@interface Package : NSObject
- (void) install;
- (void) remove;
- (NSString *) installed;
- (BOOL) uninstalled;
@end

//-----------------------------------------------------------------
//headers for compatibility with Zebra
@interface ZBSearchViewController : UITableViewController
- (void) viewDidLoad;
@end

@interface ZBRepoListTableViewController : UITableViewController
- (void) viewDidLoad;
- (void) didAddReposWithText:(NSString *)text;
@end

@interface ZBTabBarController : UITabBarController
- (void) viewDidAppear:(BOOL)animated;
@end

@interface ZBDatabaseManager : NSObject
+ (id) sharedInstance;
- (id) topVersionForPackageID:(NSString *)packageIdentifier;
- (BOOL) packageIDIsInstalled:(NSString *)packageIdentifier version:(NSString *)version;
@end

@interface ZBPackage : NSObject
@end

typedef enum {
    ZBQueueTypeInstall      = 1 << 0,
    ZBQueueTypeRemove       = 1 << 1,
} ZBQueueType;

@interface ZBQueue : NSObject
+ (id) sharedInstance;
- (void) addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue;
@end

@interface ZBPackageActionsManager : NSObject
+ (void) presentQueue:(UIViewController *)vc parent:(UIViewController *)parent;
@end

@interface ZBQueueViewController : UIViewController
- (void) loadView;
@end

//-----------------------------------------------------------------
//headers for compatibility with Sileo
@interface _TtC5Sileo25PackageListViewController : UIViewController
- (void) viewDidLoad;
@end

@interface SourcesViewController : UITableViewController
- (void) viewDidLoad;
- (void) handleSourceAddWithURLs:(NSArray *)arrayOfNSURL;
@end

@interface _TtC5Sileo18PackageListManager : NSObject
+ (id) shared;
- (Package *) installedPackageWithIdentifier:(NSString *)packageIdentifier;
- (Package *) newestPackageWithIdentifier:(NSString *)arg1;
@end

@interface _TtC5Sileo15DownloadManager : NSObject
+ (id) shared;
- (void) addWithPackage:(Package *)thePackage queue:(int)typeOfQueue;
- (void) reloadDataWithRecheckPackages:(bool)recheck;
@property(nonatomic, copy) NSArray *errors;
@property(nonatomic, copy) NSArray *installations;
@end

@interface TabBarController : UITabBarController
- (void) viewDidLoad;
- (void) presentPopupController;
@end

//-----------------------------------------------------------------
//headers for compatibility with Installer
@interface SearchViewController : UIViewController
- (void) viewDidLoad;
- (void) showTaskView;
- (void) proceedQueuedPackages;
@end

@interface ManageViewController : UIViewController
- (void) viewDidLoad;
- (void) addSourceWithString:(NSString *)repoURL withHttpApproval:(bool)approval;
@end

@interface TasksViewController : UIViewController
- (void) viewWillDisappear:(bool)animated;
@end

@interface ATRPackages : NSObject
- (id) init;
- (void) setPackage:(NSString *)packageIdentifier inTheQueue:(bool)queue;
- (bool) packageIsInstalled:(NSString *)packageIdentifier;
- (id) packageWithIdentifier:(NSString *)packageIdentifier;
@end

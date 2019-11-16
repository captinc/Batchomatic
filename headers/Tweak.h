//headers for compatibility with Cydia
@interface SearchController : UIViewController
- (void)viewDidLoad;
@end

@interface Cydia : UIApplication
- (void)reloadData;
- (void)_loaded;
- (void)addSource:(NSDictionary *)dictionary;
- (BOOL)addTrivialSource:(NSString *)href;
- (bool)requestUpdate;
- (void)resolve;
- (void)queue;
@end

@interface Package : NSObject
- (NSString *)installed;
- (BOOL)uninstalled;
- (void)install;
- (void)remove;
@end

@interface PackageListController : UIViewController
- (Package *)packageWithName:(NSString *)packageIdentifier;
@end

@interface Database : NSObject
+ (Database *)sharedInstance;
@end

//-----------------------------------------------------------------
//headers for compatibility with Zebra
@interface ZBSearchViewController : UITableViewController
- (void)viewDidLoad;
@end

@interface ZBRepoListTableViewController : UITableViewController
- (void)didAddReposWithText:(NSString *)text;
@end

@interface ZBRefreshViewController : UIViewController
- (void)viewWillDisappear:(BOOL)animated;
@end

typedef enum {
    ZBQueueTypeInstall      = 1 << 0,
    ZBQueueTypeRemove       = 1 << 1,
} ZBQueueType;

@interface ZBPackage : NSObject
@end

@interface ZBQueue : NSObject
+ (id)sharedQueue;
- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue;
@end

@interface ZBTabBarController : UITabBarController
- (void)openQueue:(BOOL)openPopup;
@end

@interface ZBDatabaseManager : NSObject
+ (id)sharedInstance;
- (ZBPackage *)topVersionForPackageID:(NSString *)packageIdentifier;
- (BOOL)packageIDIsInstalled:(NSString *)packageIdentifier version:(NSString *)version;
@end

//-----------------------------------------------------------------
//headers for compatibility with Sileo
@interface _TtC5Sileo25PackageListViewController : UIViewController
- (void)viewDidLoad;
@end

@interface _TtC5Sileo11RepoManager : NSObject
+ (id)shared;
- (void)addReposWith:(NSArray *)arrayOfNSURL;
@end

@interface _TtC5Sileo21SourcesViewController : UITableViewController
- (void)refreshSources:(UIRefreshControl *)refreshController;
@end

@interface _TtC5Sileo15DownloadManager : NSObject
@property (nonatomic, copy) NSArray *errors;
@property (nonatomic, copy) NSArray *installations;
+ (id)shared;
- (void)addWithPackage:(Package *)thePackage queue:(int)typeOfQueue;
- (void)reloadDataWithRecheckPackages:(bool)recheck;
@end

@interface TabBarController : UITabBarController
+ (id)singleton;
- (void)presentPopupController;
@end

@interface _TtC5Sileo18PackageListManager : NSObject
+ (id)shared;
- (Package *)newestPackageWithIdentifier:(NSString *)packageIdentifier;
- (Package *)installedPackageWithIdentifier:(NSString *)packageIdentifier;
@end

//-----------------------------------------------------------------
//headers for compatibility with Installer
@interface SearchViewController : UIViewController
- (void)viewDidLoad;
- (void)showTaskView;
- (void)proceedQueuedPackages;
@end

@interface ManageViewController : UIViewController
- (void)addSourceWithString:(NSString *)repoURL withHttpApproval:(bool)approval;
@end

@interface TasksViewController : UIViewController
- (void)viewWillDisappear:(BOOL)animated;
@end

@interface ATRPackage : NSObject
@end

@interface ATRPackages : NSObject
- (id)init;
- (ATRPackage *)packageWithIdentifier:(NSString *)packageIdentifier;
- (bool)packageIsInstalled:(NSString *)packageIdentifier;
- (void)setPackage:(NSString *)packageIdentifier inTheQueue:(bool)queue;
@end

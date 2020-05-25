//Cydia
@interface SearchController : UIViewController
- (void)viewDidLoad;
- (void)startBatchomatic;
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
+ (instancetype)sharedInstance;
- (NSMutableArray *)sources;
@end

@interface Source : NSObject
- (NSMutableString *)rooturi;
- (BOOL)remove;
@end

//--------------------------------------------------------------------------------------------------------------------------
//Zebra
@interface ZBSearchTableViewController : UITableViewController
- (void)viewDidLoad;
- (void)startBatchomatic;
@end

@interface ZBSourceListTableViewController : UITableViewController
- (void)handleImportOf:(NSURL *)url;
- (void)refreshTable;
@end

@interface ZBRefreshViewController : UIViewController
- (void)viewDidDisappear:(BOOL)animated;
@end

@interface ZBPackage : NSObject
@end

typedef enum {
    ZBQueueTypeInstall      = 1 << 0,
    ZBQueueTypeRemove       = 1 << 1,
} ZBQueueType;

@interface ZBQueue : NSObject
+ (instancetype)sharedQueue;
- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue;
@end

@interface ZBTabBarController : UITabBarController
- (void)openQueue:(BOOL)openPopup;
@end

@interface ZBSource : NSObject
@end

@interface ZBBaseSource : NSObject
@property (nonatomic) NSString *repositoryURI;
@end

@interface ZBSourceManager : NSObject
+ (instancetype)sharedInstance;
- (NSMutableDictionary *)sources;
- (void)deleteSource:(ZBSource *)source;
@end

@interface ZBDatabaseManager : NSObject
+ (instancetype)sharedInstance;
- (ZBPackage *)topVersionForPackageID:(NSString *)packageIdentifier;
- (BOOL)packageIDIsInstalled:(NSString *)packageIdentifier version:(NSString *)version;
- (NSSet *)sources;
@end

//--------------------------------------------------------------------------------------------------------------------------
//Sileo
@interface _TtC5Sileo25PackageListViewController : UIViewController
- (void)viewDidLoad;
- (void)startBatchomatic;
@end

@interface _TtC5Sileo4Repo : NSObject
- (NSString *)repoURL;
@end

@interface _TtC5Sileo11RepoManager : NSObject
+ (instancetype)shared;
- (NSArray *)repoList;
- (void)addReposWith:(NSArray *)arrayOfNSURL;
- (void)remove:(_TtC5Sileo4Repo *)repo;
@end

@interface _TtC5Sileo21SourcesViewController : UITableViewController
- (void)refreshSources:(UIRefreshControl *)refreshController;
@end

@interface _TtC5Sileo7Package : NSObject
@end

@interface _TtC5Sileo18PackageListManager : NSObject
+ (instancetype)shared;
- (_TtC5Sileo7Package *)newestPackageWithIdentifier:(NSString *)packageIdentifier;
- (_TtC5Sileo7Package *)installedPackageWithIdentifier:(NSString *)packageIdentifier;
@end

@interface _TtC5Sileo15DownloadManager : NSObject
@property (nonatomic, copy) NSArray *errors;
@property (nonatomic, copy) NSArray *installations;
+ (instancetype)shared;
- (void)addWithPackage:(_TtC5Sileo7Package *)thePackage queue:(int)typeOfQueue;
- (void)reloadDataWithRecheckPackages:(bool)recheck;
@end

@interface TabBarController : UITabBarController
+ (instancetype)singleton;
- (void)presentPopupController;
@end

//--------------------------------------------------------------------------------------------------------------------------
//Installer
@interface SearchViewController : UIViewController
- (void)viewDidLoad;
- (void)startBatchomatic;
@end

@interface ManageViewController : UIViewController
- (void)addSourceWithString:(NSString *)repoURL withHttpApproval:(bool)approval;
@end

@interface ATTabBarController : UITabBarController
- (void)presentTasks;
- (void)presentQueue;
@end

@interface TasksViewController : UIViewController
- (void)viewWillDisappear:(BOOL)animated;
@end

@interface ATRPackage : NSObject
@end

@interface ATRPackages : NSObject
- (ATRPackage *)packageWithIdentifier:(NSString *)packageIdentifier;
- (bool)packageIsInstalled:(NSString *)packageIdentifier;
- (void)setPackage:(NSString *)packageIdentifier inTheQueue:(BOOL)queue versionToQueue:(NSString *)version operation:(NSUInteger)operation;
@end

@interface ATRSources : NSObject
- (NSMutableArray *)arrayOfConfiguredSources;
- (BOOL)removeSourceWithLocation:(NSString *)url;
@end

@interface ATRPackageManager
+ (instancetype)sharedPackageManager;
- (ATRSources *)sources;
- (ATRPackages *)packages;
@end

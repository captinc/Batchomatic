#import "Tweak.h"
#import "BMHomeTableViewController.h"

//headers for my tweak's own functions
@interface batchomatic : NSObject
@property id motherClass;
@property id bm_currentBMController;
@property BMHomeTableViewController *bm_BMHomeTableViewController;
@property ZBTabBarController *zebra_ZBTabBarController;
@property ZBRepoListTableViewController *zebra_ZBRepoListTableViewController;
@property _TtC5Sileo21SourcesViewController *sileo_SourcesViewController;
@property SearchViewController *installer_SearchViewController;
@property ManageViewController *installer_ManageViewController;
@property ATRPackages *installer_ATRPackages;

@property bool debIsInstalled;
@property bool debIsOnline;
@property bool prefsSwitchStatus;
@property bool savedDebsSwitchStatus;
@property bool hostsSwitchStatus;
@property bool reposSwitchStatus;
@property bool tweaksSwitchStatus;
@property bool offlineTweaksSwitchStatus;
@property bool uicacheSwitchStatus;
@property bool respringSwitchStatus;
@property bool removeEverythingSwitchStatus;

@property int packageManager;
@property UIAlertController *processingDialog;
@property UIActivityIndicatorView *spinner;
@property int maxSteps;
@property int currentStep;

+ (id)sharedInstance;

- (void)createDeb:(NSString *)motherMessage;
- (void)installDeb;

- (void)installAllDebsInFolder:(NSString *)pathToDebsFolder withMotherMessage:(NSString *)motherMessage;
- (void)addRepos;
- (void)addingReposDidFinish:(bool)shouldTransition;
- (void)showUnfindableTweaks:(NSMutableString *)unfindableTweaks transition:(bool)shouldTransition thenInClass:(id)theClass runMethod:(SEL)theMethod;
- (void)queueTweaks:(bool)shouldTransition;

- (void)sileoFixDependencies:(NSMutableString *)unfindableTweaks transition:(bool)shouldTransition;
- (void)sileoAddDependenciesToQueue;

- (void)removeAllClient;
- (void)removeAll;

- (void)showFinishedCreatingDialog:(NSString *)theMessage pathToDeb:(NSString *)debFileName;
- (NSString *)showProcessingDialog:(NSString *)wordMessage includeStage:(bool)includeStage startingStep:(int)startingStep autoPresent:(bool)shouldAutoPresentDialog;
- (void)transitionProgressMessage:(NSString *)theMessage;
- (NSString *)updateProgressMessage:(NSString *)wordMessage;
- (void)endProcessingDialog:(NSString *)theMessage transition:(bool)shouldTransition presentImmediately:(bool)shouldPresentImmediately;

- (UIStackView *)createASwitchWithLabel:(NSString *)message tag:(int)theTag defaultState:(BOOL)onOrOff;
- (UIStackView *)createOptionsSwitches:(int)type;
- (void)toggleTapped:(UISwitch *)sender;

- (bool)isDebInstalled;
- (bool)isDebOnline;

- (NSString *)runCommand:(NSString *)theCommand;
- (NSString *)readEachLineOfFile:(FILE *)file;
@end

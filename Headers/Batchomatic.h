#import "BMHomeTableViewController.h"
#import "BMInstallTableViewController.h"
#import "BMRepackTableViewController.h"
#import "Tweak.h"

@interface Batchomatic : NSObject
@property (nonatomic) BMHomeTableViewController *bm_BMHomeTableViewController;
@property (nonatomic) BMInstallTableViewController *bm_BMInstallTableViewController;
@property (nonatomic) BMRepackTableViewController *bm_BMRepackTableViewController;
@property (nonatomic) id bm_currentBMController;

@property (nonatomic) id motherClass;
@property (nonatomic) ZBTabBarController *zebra_ZBTabBarController;
@property (nonatomic) ZBSourceListTableViewController *zebra_ZBSourceListTableViewController;
@property (nonatomic) _TtC5Sileo21SourcesViewController *sileo_SourcesViewController;
@property (nonatomic) ATTabBarController *installer_ATTabBarController;
@property (nonatomic) ManageViewController *installer_ManageViewController;

@property (nonatomic) BOOL prefsSwitchStatus;
@property (nonatomic) BOOL savedDebsSwitchStatus;
@property (nonatomic) BOOL hostsSwitchStatus;
@property (nonatomic) BOOL reposSwitchStatus;
@property (nonatomic) BOOL tweaksSwitchStatus;
@property (nonatomic) BOOL offlineTweaksSwitchStatus;
@property (nonatomic) BOOL uicacheSwitchStatus;
@property (nonatomic) BOOL respringSwitchStatus;
@property (nonatomic) BOOL removeAllReposSwitchStatus;
@property (nonatomic) BOOL removeAllTweaksSwitchStatus;

@property (nonatomic) int packageManager;
@property (nonatomic) BOOL isRemovingRepos;
@property (nonatomic) BOOL debIsInstalled;
@property (nonatomic) BOOL debIsOnline;
@property (nonatomic) NSArray *currentlyInstalledTweaks;

@property (nonatomic) UIAlertController *processingDialog;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) int maxSteps;
@property (nonatomic) int currentStep;

+ (instancetype)sharedInstance;
+ (void)placeButton:(UIViewController *)sender;
+ (void)openMainScreen:(UIViewController *)sender;

- (void)createDeb:(int)type withMotherMessage:(NSString *)motherMessage;
- (void)calculateMaxStepsForInstalling;
- (void)installDeb;

- (void)installAllDebsInFolder:(NSString *)pathToDebsFolder withMotherMessage:(NSString *)motherMessage;
- (void)addRepos;
- (void)processingReposDidFinish:(BOOL)shouldTransition;
- (void)showUnfindableTweaks:(NSMutableString *)unfindableTweaks transition:(BOOL)shouldTransition;
- (void)queueTweaks:(BOOL)shouldTransition;
- (void)openQueueForCurrentPackageManager:(BOOL)shouldTransition;

- (void)sileoFixDependencies:(NSMutableString *)unfindableTweaks transition:(BOOL)shouldTransition;
- (void)sileoAddDependenciesToQueue;

- (void)repackTweakWithIdentifier:(NSString *)packageID;

- (void)removeAllRepos;
- (void)removeAllTweaks;

- (NSString *)showProcessingDialog:(NSString *)wordMessage includeStage:(BOOL)includeStage startingStep:(int)startingStep autoPresent:(BOOL)shouldAutoPresentDialog;
- (void)transitionProgressMessage:(NSString *)theMessage;
- (NSString *)updateProgressMessage:(NSString *)wordMessage;
- (void)endProcessingDialog:(NSString *)theMessage transition:(BOOL)shouldTransition shouldOpenBMHomeViewControllerFirst:(BOOL)shouldOpenBMHomeViewControllerFirst;
- (void)showFinishedCreatingDialog:(NSString *)debFileName;

- (UIStackView *)createASwitchWithLabel:(NSString *)message tag:(int)theTag defaultState:(BOOL)onOrOff;
- (UIStackView *)createOptionsSwitches:(int)type;
- (UIAlertController *)placeUISwitchInsideUIAlertController:(UIAlertController *)optionsAlert whichScreen:(int)screen;
- (void)toggleTapped:(UISwitch *)sender;

- (void)determineInfoAboutDeb;
- (void)loadListOfCurrentlyInstalledTweaks;

- (NSString *)runCommand:(NSString *)theCommand;
- (NSString *)readEachLineOfFile:(FILE *)file;
@end

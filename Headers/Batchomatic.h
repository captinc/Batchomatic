#import "BMHomeTableViewController.h"
#import "BMInstallTableViewController.h"
#import "BMRepackTableViewController.h"
#import "Tweak.h"

@interface Batchomatic : NSObject
@property BMHomeTableViewController *bm_BMHomeTableViewController;
@property BMInstallTableViewController *bm_BMInstallTableViewController;
@property BMRepackTableViewController *bm_BMRepackTableViewController;
@property id bm_currentBMController;

@property id motherClass;
@property ZBTabBarController *zebra_ZBTabBarController;
@property ZBSourceListTableViewController *zebra_ZBSourceListTableViewController;
@property _TtC5Sileo21SourcesViewController *sileo_SourcesViewController;
@property ATTabBarController *installer_ATTabBarController;
@property ManageViewController *installer_ManageViewController;

@property bool prefsSwitchStatus;
@property bool savedDebsSwitchStatus;
@property bool hostsSwitchStatus;
@property bool reposSwitchStatus;
@property bool tweaksSwitchStatus;
@property bool offlineTweaksSwitchStatus;
@property bool uicacheSwitchStatus;
@property bool respringSwitchStatus;
@property bool removeAllReposSwitchStatus;
@property bool removeAllTweaksSwitchStatus;

@property int packageManager;
@property bool isRemovingRepos;
@property bool debIsInstalled;
@property bool debIsOnline;
@property NSArray *currentlyInstalledTweaks;

@property UIAlertController *processingDialog;
@property UIActivityIndicatorView *spinner;
@property int maxSteps;
@property int currentStep;

+ (instancetype)sharedInstance;
+ (void)placeButton:(UIViewController *)sender;
+ (void)openMainScreen:(UIViewController *)sender;

- (void)createDeb:(int)type withMotherMessage:(NSString *)motherMessage;
- (void)calculateMaxStepsForInstalling;
- (void)installDeb;

- (void)installAllDebsInFolder:(NSString *)pathToDebsFolder withMotherMessage:(NSString *)motherMessage;
- (void)addRepos;
- (void)processingReposDidFinish:(bool)shouldTransition;
- (void)showUnfindableTweaks:(NSMutableString *)unfindableTweaks transition:(bool)shouldTransition;
- (void)queueTweaks:(bool)shouldTransition;
- (void)openQueueForCurrentPackageManager:(bool)shouldTransition;

- (void)sileoFixDependencies:(NSMutableString *)unfindableTweaks transition:(bool)shouldTransition;
- (void)sileoAddDependenciesToQueue;

- (void)repackTweakWithIdentifier:(NSString *)packageID;

- (void)removeAllRepos;
- (void)removeAllTweaks;

- (NSString *)showProcessingDialog:(NSString *)wordMessage includeStage:(bool)includeStage startingStep:(int)startingStep autoPresent:(bool)shouldAutoPresentDialog;
- (void)transitionProgressMessage:(NSString *)theMessage;
- (NSString *)updateProgressMessage:(NSString *)wordMessage;
- (void)endProcessingDialog:(NSString *)theMessage transition:(bool)shouldTransition shouldOpenBMHomeViewControllerFirst:(bool)shouldOpenBMHomeViewControllerFirst;
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

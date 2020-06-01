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
@property (nonatomic) ZBRepoListTableViewController *zebra_ZBRepoListTableViewController;
@property (nonatomic) _TtC5Sileo21SourcesViewController *sileo_SourcesViewController;
@property (nonatomic) ATTabBarController *installer_ATTabBarController;
@property (nonatomic) ManageViewController *installer_ManageViewController;

@property (nonatomic) bool prefsSwitchStatus;
@property (nonatomic) bool savedDebsSwitchStatus;
@property (nonatomic) bool hostsSwitchStatus;
@property (nonatomic) bool reposSwitchStatus;
@property (nonatomic) bool tweaksSwitchStatus;
@property (nonatomic) bool offlineTweaksSwitchStatus;
@property (nonatomic) bool uicacheSwitchStatus;
@property (nonatomic) bool respringSwitchStatus;
@property (nonatomic) bool removeAllReposSwitchStatus;
@property (nonatomic) bool removeAllTweaksSwitchStatus;

@property (nonatomic) int packageManager;
@property (nonatomic) bool isRemovingRepos;
@property (nonatomic) bool debIsInstalled;
@property (nonatomic) bool debIsOnline;
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

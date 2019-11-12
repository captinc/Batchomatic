#import "headers/BMHomeTableViewController.h"
#import "headers/BMInstallTableViewController.h"
#import "headers/Batchomatic.h"

//the main "Batchomatic" screen where you choose what feature to use
@implementation BMHomeTableViewController
- (id)init {
    self = [super init];
    if (!self)
        return nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkDeb) name:UIApplicationWillEnterForegroundNotification object:nil]; //see (void)checkDeb for an explanation about this
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self checkDeb];
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.bm_BMHomeTableViewController = self;
    self.tableView = [self createTableView];
    
    self.navigationItem.title = @"Batchomatic";
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(openHelpPage)];
    [[self navigationItem] setLeftBarButtonItem:backButton];
    [[self navigationItem] setRightBarButtonItem:helpButton];
}

- (UITableView *)createTableView {
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, 1/[UIScreen mainScreen].scale);
    UITableView *tableView = [[UITableView alloc]initWithFrame:frame style:UITableViewStylePlain];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [tableView registerClass:[UITableViewCell self] forCellReuseIdentifier:@"Cell"];
    tableView.dataSource = self;
    tableView.delegate = self;
    return tableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 100;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section { //hides the separators of extraneous/unused cells
    return [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.font=[UIFont boldSystemFontOfSize:22.0];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor colorWithRed:0.204 green:0.459 blue:1.000 alpha:1.0]; //Apple's default light blue color for buttons
    if (indexPath.row == 3) { //creates an empty row for organizational purposes
        cell.selectionStyle = UITableViewCellSelectionStyleNone; //makes the empty row not selectable
    }
    else {
        NSArray *cellTitles = @[@"Create online .deb", @"Create offline .deb", @"Install .deb", @"", @"Remove all", @"Respring"];
        cell.textLabel.text=[cellTitles objectAtIndex:indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault; //adds the select-then-immediately-deselect animation when tapping on a row
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; //this is also needed for that select-then-immediately-deselect animation
    Batchomatic *bm = [Batchomatic sharedInstance];
    if (indexPath.row == 0) { [self prepareToCreate:1]; }
    else if (indexPath.row == 1) { [self prepareToCreate:2]; }
    else if (indexPath.row == 2) { [self presentInstallVC]; }
    else if (indexPath.row == 3) { return; }
    else if (indexPath.row == 4) { [bm removeAllClient]; }
    else if (indexPath.row == 5) { [bm endProcessingDialog:nil transition:false presentImmediately:true]; }
}

- (void)prepareToCreate:(int)type { //we need to have 2 methods to create the .deb because there was a bug where the UIAlertController wouldn't show up
    //the 2 methods are this one and (void)createDeb:(int)type in Batchomatic.xm
    Batchomatic *bm = [Batchomatic sharedInstance];
    if (type == 1) { bm.maxSteps = 1; }
    else { bm.maxSteps = 3; }
    NSString *motherMessage = [bm showProcessingDialog:@"Preparing...." includeStage:true startingStep:0 autoPresent:true];
    [bm performSelector:@selector(createDeb:) withObject:motherMessage afterDelay:0.1];
}

- (void)presentInstallVC { //shows the Install options screen if your .deb is currently installed (BMInstallTableViewController)
    Batchomatic *bm = [Batchomatic sharedInstance];
    if (bm.debIsInstalled) {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[BMInstallTableViewController alloc] init]];
        [self presentViewController:nav animated:YES completion:nil];
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:@"Error:\nYour .deb is not currently installed. Go install it with Filza and try again" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)checkDeb { //everytime the main "Batchomatic" screen enters the foreground, it checks if your .deb is installed and whether its online or offfline. determining this info takes about 1 second, therefore causing 1 second of lag whenever you press the "Install .deb" or "Proceed" buttons. this implementation with NSNotificationCenter & UIApplicationWillEnterForegroundNotification fixes that
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.bm_currentBMController = self; //this variable is whatever Batchomatic view controller is currently on-screen
    if ([bm isDebInstalled]) { bm.debIsInstalled = true; }
    else { bm.debIsInstalled = false; }
    if ([bm isDebOnline]) { bm.debIsOnline = true; }
    else { bm.debIsOnline = false; }
}

- (void)openHelpPage {
    NSDictionary *options = @{UIApplicationOpenURLOptionUniversalLinksOnly : @NO};
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/jailbreak/comments/cqarr6/release_batchomatic_v30_on_bigboss_batch_install/"] options:options completionHandler:nil];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

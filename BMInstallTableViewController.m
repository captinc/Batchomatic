#import "headers/BMHomeTableViewController.h"
#import "headers/BMInstallTableViewController.h"
#import "headers/Batchomatic.h"

//the "Install" screen where you choose what to install
@implementation BMInstallTableViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.bm_currentBMController = self;
    self.tableView = [self createTableView];
    
    self.navigationItem.title = @"Batchomatic";
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    [[self navigationItem] setLeftBarButtonItem:backButton];
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
    return 8;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 100;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    NSArray *cellTitles = @[@"Install preferences", @"Install hosts file", @"Install saved .debs", @"Add repos", @"Queue tweaks", @"Install offline tweaks", @"", @"Proceed"];
    cell.textLabel.text=[cellTitles objectAtIndex:indexPath.row];
    cell.textLabel.font=[UIFont boldSystemFontOfSize:22.0];
    if (indexPath.row == 6) { //empty row
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (indexPath.row == 7) { //customizes the "Proceed" row
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor colorWithRed:0.204 green:0.459 blue:1.000 alpha:1.0];
    }
    else { //adds a UISWitch to all other rows
        Batchomatic *bm = [Batchomatic sharedInstance];
        UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
        toggle.tag = indexPath.row;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [toggle setOn:YES animated:YES];
        bm.prefsSwitchStatus = true;
        bm.hostsSwitchStatus = true;
        bm.savedDebsSwitchStatus = true;
        if (bm.debIsOnline) { //if the .deb is online mode, the offline switch gets disabled
            if (indexPath.row == 3 || indexPath.row == 4) {
                [toggle setOn:YES animated:YES];
                bm.reposSwitchStatus = true;
                bm.tweaksSwitchStatus = true;
            }
            if (indexPath.row == 5) {
                [toggle setOn:NO animated:YES];
                bm.offlineTweaksSwitchStatus = false;
                cell.userInteractionEnabled = NO;
                cell.textLabel.textColor = [UIColor grayColor];
            }
        }
        else { //and vice versa if the .deb is offline mode
            if (indexPath.row == 3 || indexPath.row == 4) {
                [toggle setOn:NO animated:YES];
                bm.reposSwitchStatus = false;
                bm.tweaksSwitchStatus = false;
                cell.userInteractionEnabled = NO;
                cell.textLabel.textColor = [UIColor grayColor];
            }
            if (indexPath.row == 5) {
                [toggle setOn:YES animated:YES];
                bm.offlineTweaksSwitchStatus = true;
            }
        }
        [toggle addTarget:bm action:@selector(toggleTapped:) forControlEvents:UIControlEventValueChanged]; //(void)toggleTapped: will update the corresponding boolean variable whenever the switch is tapped
        cell.accessoryView = toggle;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 7) { [self prepareToInstall]; }
}

- (void)prepareToInstall { //determines what needs to be done based on what the user chose in the switches. //we need to have 2 methods to install the .deb because there was a bug where the UIAlertController wouldn't show up
    //the 2 methods are this one and (void)installDeb in Batchomatic.xm
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.maxSteps = 0;
    if (bm.prefsSwitchStatus == true) { bm.maxSteps += 1; }
    if (bm.savedDebsSwitchStatus == true) { bm.maxSteps += 1; }
    if (bm.hostsSwitchStatus == true) { bm.maxSteps += 1; }
    if (bm.debIsOnline) {
        if (bm.reposSwitchStatus == true) { bm.maxSteps += 1; }
        if (bm.tweaksSwitchStatus == true) { bm.maxSteps += 1; }
    }
    else {
        if (bm.offlineTweaksSwitchStatus == true) { bm.maxSteps += 1; }
    }
    [bm showProcessingDialog:@"Preparing...." includeStage:true startingStep:0 autoPresent:true];
    [bm performSelector:@selector(installDeb) withObject:nil afterDelay:0.1];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
    Batchomatic *bm = [Batchomatic sharedInstance];
    [bm.bm_BMHomeTableViewController checkDeb];
}
@end

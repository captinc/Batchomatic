#import "Headers/Batchomatic.h"
#import "Headers/BMInstallTableViewController.h"

@implementation BMInstallTableViewController //The installation options screen
- (void)viewDidLoad {
    [super viewDidLoad];
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.bm_BMInstallTableViewController = self;
    
    self.navigationItem.title = @"Batchomatic";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(didTapBackButton)];
    [self createTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [Batchomatic sharedInstance].bm_currentBMController = self;
}

- (void)createTableView {
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height);
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    [tableView registerClass:[UITableViewCell self] forCellReuseIdentifier:@"Cell"];
    tableView.dataSource = self;
    tableView.delegate = self;
    self.tableView = tableView;
}

//--------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 6;
    }
    else {
        return 1;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section { //Hide the cell separator lines of extraneous/unused cells
    return [[UIView alloc] init];
}

//--------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    Batchomatic *bm = [Batchomatic sharedInstance];
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:22];
    
    if (indexPath.section == 0) { //put a UISwitch in each row of the top section
        NSArray *cellTitles = @[@"Install preferences", @"Install hosts file", @"Install saved .debs", @"Add repos", @"Queue tweaks", @"Install offline tweaks"];
        cell.textLabel.text = [cellTitles objectAtIndex:indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
        toggle.tag = indexPath.row;
        [toggle setOn:YES animated:YES];
        bm.prefsSwitchStatus = true;
        bm.hostsSwitchStatus = true;
        bm.savedDebsSwitchStatus = true;
        
        if (bm.debIsOnline) { //if the .deb is online mode, the offline switch gets greyed out
            if (indexPath.row == 3 || indexPath.row == 4) {
                [toggle setOn:YES animated:YES];
                bm.reposSwitchStatus = true;
                bm.tweaksSwitchStatus = true;
            }
            if (indexPath.row == 5) {
                [toggle setOn:NO animated:YES]; //turn the switch off
                bm.offlineTweaksSwitchStatus = false;
                toggle.enabled = NO; //grey out the switch
                cell.textLabel.alpha = 0.439216f; //grey out the label
                cell.userInteractionEnabled = NO;
            }
        }
        else { //and vice versa if the .deb is offline mode
            if (indexPath.row == 3 || indexPath.row == 4) {
                [toggle setOn:NO animated:YES];
                bm.reposSwitchStatus = false;
                bm.tweaksSwitchStatus = false;
                toggle.enabled = NO;
                cell.textLabel.alpha = 0.439216f;
                cell.userInteractionEnabled = NO;
            }
            if (indexPath.row == 5) {
                [toggle setOn:YES animated:YES];
                bm.offlineTweaksSwitchStatus = true;
            }
        }
        
        [toggle addTarget:bm action:@selector(toggleTapped:) forControlEvents:UIControlEventValueChanged]; //"- (void)toggleTapped:" will update the corresponding boolean variable whenever the switch is tapped
        cell.accessoryView = toggle;
    }
    else { //customizes the "Proceed" button/row
        NSArray *cellTitles = @[@"Proceed"];
        cell.textLabel.text = [cellTitles objectAtIndex:indexPath.row];
        if (indexPath.row == 0) {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self didTapProceedButton];
        }
    }
}

//--------------------------------------------------------------------------------------------------------------------------
- (void)didTapProceedButton {
    Batchomatic *bm = [Batchomatic sharedInstance];
    [bm calculateMaxStepsForInstalling]; //must do some prep work before actually installing the .deb
    [bm showProcessingDialog:@"Preparing...." includeStage:true startingStep:0 autoPresent:false];
    [self presentViewController:bm.processingDialog animated:YES completion:^{
        [bm installDeb];
    }];
}

- (void)didTapBackButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

//
//  BMInstallTableViewController.m
//  Batchomatic
//  
//  Created by Capt Inc on 2020-06-01
//  Copyright © 2020 Capt Inc. All rights reserved.
//

#import "Headers/Batchomatic.h"
#import "Headers/BMInstallTableViewController.h"

@implementation BMInstallTableViewController // The installation options screen
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

// Hide the cell separator lines of extraneous/unused cells
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
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
    
    // put a UISwitch in each row of the top section
    if (indexPath.section == 0) {
        NSArray *cellTitles = @[@"Install preferences", @"Install hosts file", @"Install saved .debs", @"Add repos", @"Queue tweaks", @"Install offline tweaks"];
        cell.textLabel.text = [cellTitles objectAtIndex:indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
        toggle.tag = indexPath.row;
        [toggle setOn:YES animated:YES];
        bm.prefsSwitchStatus = YES;
        bm.hostsSwitchStatus = YES;
        bm.savedDebsSwitchStatus = YES;
        
        // if the .deb is online mode, the offline switch gets greyed out
        if (bm.debIsOnline) {
            if (indexPath.row == 3 || indexPath.row == 4) {
                [toggle setOn:YES animated:YES];
                bm.reposSwitchStatus = YES;
                bm.tweaksSwitchStatus = YES;
            }
            if (indexPath.row == 5) {
                // turn the switch off
                [toggle setOn:NO animated:YES];
                bm.offlineTweaksSwitchStatus = NO;
                // grey out the switch
                toggle.enabled = NO;
                // grey out the label
                cell.textLabel.alpha = 0.439216f;
                cell.userInteractionEnabled = NO;
            }
        }
        // and vice versa if the .deb is offline mode
        else {
            if (indexPath.row == 3 || indexPath.row == 4) {
                [toggle setOn:NO animated:YES];
                bm.reposSwitchStatus = NO;
                bm.tweaksSwitchStatus = NO;
                toggle.enabled = NO;
                cell.textLabel.alpha = 0.439216f;
                cell.userInteractionEnabled = NO;
            }
            if (indexPath.row == 5) {
                [toggle setOn:YES animated:YES];
                bm.offlineTweaksSwitchStatus = YES;
            }
        }
        
        [toggle addTarget:bm action:@selector(toggleTapped:) forControlEvents:UIControlEventValueChanged]; //"- (void)toggleTapped:" will update the corresponding BOOLean variable whenever the switch is tapped
        cell.accessoryView = toggle;
    }
    // customizes the "Proceed" button/row
    else {
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
    // must do some prep work before actually installing the .deb
    [bm calculateMaxStepsForInstalling];
    [bm showProcessingDialog:@"Preparing...." includeStage:YES startingStep:0 autoPresent:NO];
    [self presentViewController:bm.processingDialog animated:YES completion:^{
        [bm installDeb];
    }];
}

- (void)didTapBackButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

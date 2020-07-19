//
//  BMHomeTableViewController.m
//  Batchomatic
//  
//  Created by Capt Inc on 2020-06-01
//  Copyright © 2020 Capt Inc. All rights reserved.
//

#import "Headers/Batchomatic.h"
#import "Headers/BMHomeTableViewController.h"
#import "Headers/BMInstallTableViewController.h"
#import "Headers/BMRepackTableViewController.h"

@implementation BMHomeTableViewController // The main Batchomatic screen where you choose what feature to use
- (NSString *)versionNumber {
    return @"v4.3.1";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.bm_BMHomeTableViewController = self;
    
    // must use dispatch_async to prevent the UI from freezing
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [bm determineInfoAboutDeb];
        [bm loadListOfCurrentlyInstalledTweaks];
    });
    
    [self createNavBar];
    [self createTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // this variable is whatever Batchomatic view controller is currently on-screen
    [Batchomatic sharedInstance].bm_currentBMController = self;
    // when this was in viewDidLoad, the version number wasn't being centered on iPads, but putting this in viewWillAppear fixed it
    [self addVersionNumberFooter];
}

//--------------------------------------------------------------------------------------------------------------------------
// Creates the main navigation bar with a custom icon next to the large title
- (void)createNavBar {
    self.navigationItem.title = @"Batchomatic";
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.prefersLargeTitles = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(didTapBackButton)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(didTapHelpButton)];
    
    // custom view in UINavigationBarLargeTitleView for the icon
    NSBundle *bundle = [NSBundle bundleWithPath:@"/Library/Batchomatic/Icon.bundle"];
    UIImage *icon = [[UIImage imageNamed:@"Icon" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:icon];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSArray *array = navBar.subviews;
        UIView *largeTitleView = [array objectAtIndex:1];
        [largeTitleView addSubview:imgView];

        CGFloat imageSizeForLargeState = 40;
        imgView.layer.cornerRadius = imageSizeForLargeState / 2;
        imgView.clipsToBounds = YES;
        imgView.translatesAutoresizingMaskIntoConstraints = NO;

        [imgView.rightAnchor constraintEqualToAnchor:navBar.rightAnchor constant:-16].active = YES;
        [imgView.bottomAnchor constraintEqualToAnchor:navBar.bottomAnchor constant:-12].active = YES;
        [imgView.heightAnchor constraintEqualToConstant:imageSizeForLargeState].active = YES;
        [imgView.widthAnchor constraintEqualToAnchor:imgView.heightAnchor].active = YES;
    });
}

- (void)createTableView {
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height);
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    [tableView registerClass:[UITableViewCell self] forCellReuseIdentifier:@"Cell"];
    tableView.dataSource = self;
    tableView.delegate = self;
    self.tableView = tableView;
}

// Add the version number as footer of the UITableView
- (void)addVersionNumberFooter {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 28)];
    UILabel *label = [[UILabel alloc] initWithFrame:footer.frame];
    label.text = [self versionNumber];
    label.textAlignment = NSTextAlignmentCenter;
    [footer addSubview:label];
    self.tableView.tableFooterView = footer;
}

//--------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    }
    else if (section == 1) {
        return 3;
    }
    else {
        return 1;
    }
}

// Add section separators and hide the cell separator lines of extraneous/unused cells
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

// Make the version number at the bottom appear close to my UITableView
// instead of floating in the middle of nowhere
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 2) {
        return 7;
    }
    else {
        return 28;
    }
}

//--------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:22];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    // top section
    if (indexPath.section == 0) {
        NSArray *cellTitles = @[@"Create online .deb", @"Create offline .deb", @"Install .deb"];
        cell.textLabel.text = [cellTitles objectAtIndex:indexPath.row];
    }
    // middle section
    else if (indexPath.section == 1) {
        NSArray *cellTitles = @[@"Repack tweak to .deb", @"Remove all repos", @"Remove all tweaks"];
        cell.textLabel.text = [cellTitles objectAtIndex:indexPath.row];
    }
    // bottom section
    else {
        cell.textLabel.text = @"Respring";
    }
    
    // adds the select-then-immediately-deselect animation when tapping on a row
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // this is also needed for that select-then-immediately-deselect animation
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self didTapEitherCreateDebButton:1];
        }
        else if (indexPath.row == 1) {
            [self didTapEitherCreateDebButton:2];
        }
        else if (indexPath.row == 2) {
            [self didTapInstallDebButton];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self didTapRepackTweakButton];
        }
        else if (indexPath.row == 1) {
            [self didTapEitherRemoveAllButton:1];
        }
        else if (indexPath.row == 2) {
            [self didTapEitherRemoveAllButton:2];
        }
    }
    else {
        if (indexPath.row == 0) {
            [self didTapRespringButton];
        }
    }
}

//--------------------------------------------------------------------------------------------------------------------------
// Does some prep work before actually creating the .deb
- (void)didTapEitherCreateDebButton:(int)type {
    Batchomatic *bm = [Batchomatic sharedInstance];
    NSString *typeOfDebMsg;
    // type 1 means an online .deb
    if (type == 1) {
        bm.maxSteps = 1;
        typeOfDebMsg = @"Creating your online .deb....\n";
    }
    // type 2 means an offline .deb
    else {
        bm.maxSteps = 3;
        typeOfDebMsg = @"Creating your offline .deb....\n";
    }
    
    NSString *motherMessage = [bm showProcessingDialog:typeOfDebMsg includeStage:YES startingStep:1 autoPresent:NO];
    [self presentViewController:bm.processingDialog animated:YES completion:^{
        [bm createDeb:type withMotherMessage:motherMessage];
    }];
}

// Shows the Install options screen (BMInstallTableViewController)
// if your .deb is currently installed
- (void)didTapInstallDebButton {
    Batchomatic *bm = [Batchomatic sharedInstance];
    if (bm.debIsInstalled) {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[BMInstallTableViewController alloc] init]];
        [self presentViewController:nav animated:YES completion:nil];
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:@"Error:\nYour .deb is not currently installed. Go install it with Filza and try again" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)didTapRepackTweakButton {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[BMRepackTableViewController alloc] init]];
    [self presentViewController:nav animated:YES completion:nil];
}

// Asks the user if they want to keep utiity repos and
// BigBoss when removing all repos. Also handles asking to keep package managers, Filza, and Batchomatic itself when removing all tweaks
- (void)didTapEitherRemoveAllButton:(int)type {
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.maxSteps = 1;
    
    NSString *infoMsg;
    NSString *processingMsg;
    // type 1 means remove all repos
    if (type == 1) {
        infoMsg = @"When OFF, utility repos and BigBoss will stay";
        processingMsg = @"Removing repos....";
    }
    // type 2 means remove all tweaks
    else {
        infoMsg = @"When OFF, Zebra/Installer/Filza/Batchomatic will stay";
        processingMsg = @"Removing tweaks....";
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Batchomatic" message:infoMsg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [bm showProcessingDialog:processingMsg includeStage:YES startingStep:1 autoPresent:NO];
        [bm.bm_BMHomeTableViewController presentViewController:bm.processingDialog animated:YES completion:^{
            if (type == 1) {
                [bm removeAllRepos];
            }
            else {
                [bm removeAllTweaks];
            }
        }];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:proceedAction];
    [alert addAction:cancelAction];
    alert = [bm placeUISwitchInsideUIAlertController:alert whichScreen:type];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didTapRespringButton {
    [[Batchomatic sharedInstance] endProcessingDialog:nil transition:NO shouldOpenBMHomeViewControllerFirst:NO];
}

- (void)didTapBackButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didTapHelpButton {
    NSDictionary *options = @{UIApplicationOpenURLOptionUniversalLinksOnly:@NO};
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/jailbreak/comments/cqarr6/release_batchomatic_v30_on_bigboss_batch_install"] options:options completionHandler:nil];
}

- (void)dealloc {
    [Batchomatic sharedInstance].currentlyInstalledTweaks = nil;
}
@end

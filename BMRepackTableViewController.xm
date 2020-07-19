//
//  BMRepackTableViewController.m
//  Batchomatic
//  
//  Created by Capt Inc on 2020-06-01
//  Copyright © 2020 Capt Inc. All rights reserved.
//

#import "Headers/Batchomatic.h"
#import "Headers/BMRepackTableViewController.h"

@implementation BMRepackTableViewController // The Repack deb screen
- (void)viewDidLoad {
    [super viewDidLoad];
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.bm_BMRepackTableViewController = self;
    
    self.navigationItem.title = @"Batchomatic";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(didTapBackButton)];
    if (bm.currentlyInstalledTweaks) {
        [self createTableView];
    }
    else {
        [self placeActivityIndicator];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [Batchomatic sharedInstance].bm_currentBMController = self;
}

- (void)placeActivityIndicator {
    UIActivityIndicatorView *spinner;
    if (@available(iOS 13, *)) {
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    }
    else {
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    // center the UIActivityIndicator
    spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    CGFloat height = (CGRectGetHeight(self.view.bounds) / 2) - self.navigationController.navigationBar.frame.size.height;
    spinner.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2, height);
    
    spinner.hidesWhenStopped = YES;
    [self.view addSubview:spinner];
    [spinner startAnimating];
    self.spinner = spinner;
}

- (void)createTableView {
    [self.spinner stopAnimating];
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height);
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    [tableView registerClass:[UITableViewCell self] forCellReuseIdentifier:@"Cell"];
    tableView.dataSource = self;
    tableView.delegate = self;
    self.tableView = tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[Batchomatic sharedInstance].currentlyInstalledTweaks count];
}

// Hide the cell separator lines of extraneous/unused cells
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

//--------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    // in order to make detailTextLabel work, you must check if cell is nil or
    // if cell.detailTextLabel is nil
    if (!cell || !cell.detailTextLabel) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    Batchomatic *bm = [Batchomatic sharedInstance];
    NSDictionary *tweakInfo = [bm.currentlyInstalledTweaks objectAtIndex:indexPath.row];
    
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    // make the package ID text a light gray
    cell.detailTextLabel.textColor = [UIColor systemGrayColor];
    cell.textLabel.text = [tweakInfo objectForKey:@"name"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"\t%@", [tweakInfo objectForKey:@"packageID"]];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Batchomatic *bm = [Batchomatic sharedInstance];
    NSDictionary *tweakInfo = [bm.currentlyInstalledTweaks objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self didTapRepackTweakWithIdentifier:[tweakInfo objectForKey:@"packageID"]];
}

//--------------------------------------------------------------------------------------------------------------------------
- (void)didTapRepackTweakWithIdentifier:(NSString *)packageID {
    Batchomatic *bm = [Batchomatic sharedInstance];
    bm.maxSteps = 1;
    NSString *msg = [NSString stringWithFormat:@"Repacking tweak to .deb....\n%@", packageID];
    [bm showProcessingDialog:msg includeStage:YES startingStep:1 autoPresent:NO];
    [self presentViewController:bm.processingDialog animated:YES completion:^{
        [bm repackTweakWithIdentifier:packageID];
    }];
}

- (void)didTapBackButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

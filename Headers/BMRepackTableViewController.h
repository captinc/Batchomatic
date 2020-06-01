//
//  BMRepackTableViewController.h
//  Headers
//  
//  Created by Capt Inc on 2020-05-31
//  Copyright © 2020 Capt Inc. All rights reserved.
//

@interface BMRepackTableViewController : UITableViewController
@property UIActivityIndicatorView *spinner;

- (void)placeActivityIndicator;
- (void)createTableView;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)didTapRepackTweakWithIdentifier:(NSString *)packageID;
- (void)didTapBackButton;
@end

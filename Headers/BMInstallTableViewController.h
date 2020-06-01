//
//  BMInstallTableViewController.h
//  Headers
//  
//  Created by Capt Inc on 2020-05-31
//  Copyright © 2020 Capt Inc. All rights reserved.
//

@interface BMInstallTableViewController : UITableViewController

- (void)createTableView;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)didTapProceedButton;
- (void)didTapBackButton;
@end

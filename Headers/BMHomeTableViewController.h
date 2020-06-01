//
//  BMHomeTableViewController.h
//  Headers
//  
//  Created by Capt Inc on 2020-05-31
//  Copyright © 2020 Capt Inc. All rights reserved.
//

@interface BMHomeTableViewController : UITableViewController
- (NSString *)versionNumber;

- (void)createNavBar;
- (void)createTableView;
- (void)addVersionNumberFooter;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)didTapEitherCreateDebButton:(int)type;
- (void)didTapInstallDebButton;
- (void)didTapEitherRemoveAllButton:(int)type;
- (void)didTapRespringButton;
- (void)didTapBackButton;
- (void)didTapHelpButton;
@end

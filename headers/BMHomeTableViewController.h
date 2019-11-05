//headers for my tweak's main screen UI
@interface BMHomeTableViewController : UITableViewController
- (id)init;
- (void)viewDidLoad;

- (UITableView *)createTableView;
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)prepareToCreate:(int)type;
- (void)presentInstallVC;
- (void)checkDeb;
- (void)openHelpPage;

- (void)dismiss;
- (void)dealloc;
@end

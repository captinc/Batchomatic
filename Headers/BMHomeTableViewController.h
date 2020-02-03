@interface BMHomeTableViewController : UITableViewController
- (instancetype)init;
- (void)viewDidLoad;
- (void)viewWillAppear:(BOOL)animated;

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
- (void)didTapDismissButton;
- (void)didTapHelpButton;

- (void)checkDeb;
- (void)dealloc;
@end

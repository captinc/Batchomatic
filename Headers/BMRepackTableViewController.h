@interface BMRepackTableViewController : UITableViewController
@property UIActivityIndicatorView *spinner;
- (void)viewDidLoad;
- (void)viewWillAppear:(BOOL)animated;

- (void)placeActivityIndicator;
- (void)createTableView;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)didTapRepackTweakWithIdentifier:(NSString *)packageID;
- (void)didTapBackButton;
@end

#import "Headers/Batchomatic.h"
#import "Headers/BMRepackTableViewController.h"

@implementation BMRepackTableViewController //The Repack deb screen
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
    
    spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin); //center the UIActivityIndicator
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section { //Hide the cell separator lines of extraneous/unused cells
    return [[UIView alloc] init];
}

//--------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell || !cell.detailTextLabel) { //in order to make detailTextLabel work, you must check if cell is nil or if cell.detailTextLabel is nil
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    Batchomatic *bm = [Batchomatic sharedInstance];
    NSDictionary *tweakInfo = [bm.currentlyInstalledTweaks objectAtIndex:indexPath.row];
    
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    cell.detailTextLabel.textColor = [UIColor systemGrayColor]; //make the package ID text a light gray
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
    [bm showProcessingDialog:msg includeStage:true startingStep:1 autoPresent:false];
    [self presentViewController:bm.processingDialog animated:YES completion:^{
        [bm repackTweakWithIdentifier:packageID];
    }];
}

- (void)didTapBackButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

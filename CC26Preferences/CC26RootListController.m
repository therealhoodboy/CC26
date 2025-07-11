#import <Foundation/Foundation.h>
#import "CC26RootListController.h"

@implementation CC26RootListController
- (instancetype)init {
	self = [super init];
	if (self) {
		self.enableSwitch = [[UISwitch alloc] init];
		self.enableSwitch.onTintColor = TINT_COLOR;
		[self.enableSwitch addTarget:self action:@selector(switchStateChanged:) forControlEvents:UIControlEventValueChanged];

		[self setupButtonMenu];

		self.navigationController.navigationBar.prefersLargeTitles = YES;
		self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
	}
	return self;
}
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self setEnableSwitchState];

	self.view.tintColor = TINT_COLOR;
	[[UIApplication sharedApplication] keyWindow].tintColor = TINT_COLOR;
	[self.navigationController.navigationItem.navigationBar sizeToFit];
	_table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
}
- (void)viewWillDisappear:(BOOL)animated {
	[[UIApplication sharedApplication] keyWindow].tintColor = nil;
	[super viewWillDisappear:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];

	NSBundle *resourceBundle = [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/PreferenceBundles/CC26Preferences.bundle")];

	self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
	
	self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 180)];
	self.enableSwitch.translatesAutoresizingMaskIntoConstraints = NO;

	self.headerImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	self.headerImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.headerImageView.image = [UIImage imageWithContentsOfFile:[resourceBundle pathForResource:@"header" ofType:@"png"]];

	[self.headerView addSubview:self.headerImageView];
	[self.headerView addSubview:self.enableSwitch];

	[NSLayoutConstraint activateConstraints:@[
		[self.headerImageView.centerXAnchor constraintEqualToAnchor:self.headerView.centerXAnchor],
		[self.headerImageView.topAnchor constraintEqualToAnchor:self.headerView.topAnchor],
		[self.headerImageView.widthAnchor constraintEqualToConstant:100],
		[self.headerImageView.heightAnchor constraintEqualToConstant:100],
		[self.enableSwitch.centerXAnchor constraintEqualToAnchor:self.headerView.centerXAnchor],
		[self.enableSwitch.topAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor constant:16],
	]];
	_table.tableHeaderView = self.headerView;
}
- (void)setEnableSwitchState {
	if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:domain] boolValue]) {
		[[self enableSwitch] setOn:NO animated:NO];
	} else {
		[[self enableSwitch] setOn:YES animated:NO];
	}
}
- (void)switchStateChanged:(UISwitch *)sender {
	if (self.enableSwitch.isOn) {
		[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"enabled" inDomain:domain];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"enabled" inDomain:domain];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)setupButtonMenu {
	UIAction *respring = [UIAction actionWithTitle:@"Respring" image:[UIImage systemImageNamed:@"arrow.clockwise.circle.fill"] identifier:nil handler:^(__kindof UIAction *_Nonnull action) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
			SBSRelaunchAction *respringAction = [NSClassFromString(@"SBSRelaunchAction") actionWithReason:@"RestartRenderServer" options:4 targetURL:[NSURL URLWithString:@"prefs:root=Ampere"]];
			FBSSystemService *frontBoardService = [NSClassFromString(@"FBSSystemService") sharedService];
			NSSet *actions = [NSSet setWithObject:respringAction];
			[frontBoardService sendActions:actions withResult:nil];
		});
	}];

	UIMenu *menuActions = [UIMenu menuWithTitle:@"" children:@[respring]];
	UIBarButtonItem *optionsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"gearshape.fill"] menu:menuActions];
	
	self.navigationItem.rightBarButtonItems = @[optionsItem];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	tableView.tableHeaderView = self.headerView;
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}
@end

@implementation CC26ButtonsListController
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Buttons" target:self];
	}
	return _specifiers;
}
- (instancetype)init {
	self = [super init];
	if (self) {
		self.navigationController.navigationBar.prefersLargeTitles = YES;
		self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
	}
	return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	self.view.tintColor = TINT_COLOR;
	[[UIApplication sharedApplication] keyWindow].tintColor = TINT_COLOR;
	[self.navigationController.navigationItem.navigationBar sizeToFit];
	_table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
}
@end

@implementation CC26ColorCell
@dynamic control;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];
	if (self) {
		self.accessoryView = self.control;
	}
	return self;
}
- (void)setCellEnabled:(BOOL)cellEnabled {
	[super setCellEnabled:cellEnabled];
	self.control.backgroundColor = cellEnabled ? [self selectedColor] : [UIColor secondaryLabelColor];
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	self.control.backgroundColor = [self cellEnabled] ? [self selectedColor] : [UIColor secondaryLabelColor];
}
- (UIButton *)newControl {
	UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
	colorButton.frame = CGRectMake(0, 0, 30, 30);
	colorButton.backgroundColor = [self selectedColor];
	colorButton.layer.masksToBounds = NO;
	colorButton.layer.cornerRadius = colorButton.frame.size.width / 2;
	[colorButton addTarget:self action:@selector(selectColor) forControlEvents:UIControlEventTouchUpInside];
	return colorButton;
}
- (void)selectColor {
	UIColorPickerViewController *colorPickerController = [[UIColorPickerViewController alloc] init];
	colorPickerController.delegate = self;
	colorPickerController.supportsAlpha = NO;
	colorPickerController.modalPresentationStyle = UIModalPresentationPageSheet;
	colorPickerController.modalInPresentation = YES;
	colorPickerController.selectedColor = [self selectedColor];
	[[self _viewControllerForAncestor] presentViewController:colorPickerController animated:YES completion:nil]; 
}
- (UIColor *)selectedColor {
	NSDictionary *colorDict = [[NSUserDefaults standardUserDefaults] objectForKey:[self.specifier.properties[@"key"] stringByAppendingString:@"Dict"] inDomain:domain];
	return colorDict ? [UIColor colorWithRed:[colorDict[@"red"] floatValue] green:[colorDict[@"green"] floatValue] blue:[colorDict[@"blue"] floatValue] alpha:1.0] : [UIColor secondaryLabelColor];
}
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
	[[NSUserDefaults standardUserDefaults] setObject:[self dictionaryForColor:viewController.selectedColor] forKey:[self.specifier.properties[@"key"] stringByAppendingString:@"Dict"] inDomain:domain];
	[[NSUserDefaults standardUserDefaults] synchronize];
	self.control.backgroundColor = [self selectedColor];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.mtac.amp/statusbar.changed", nil, nil, true);
}
- (NSDictionary *)dictionaryForColor:(UIColor *)color {
	const CGFloat *components = CGColorGetComponents(color.CGColor);
	NSMutableDictionary *colorDict = [NSMutableDictionary new];
	[colorDict setObject:[NSNumber numberWithFloat:components[0]] forKey:@"red"];
	[colorDict setObject:[NSNumber numberWithFloat:components[1]] forKey:@"green"];
	[colorDict setObject:[NSNumber numberWithFloat:components[2]] forKey:@"blue"];
	return colorDict;
}
@end

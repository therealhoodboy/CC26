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

@implementation CC26Controller
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
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
	NSString *title = [self tableView:tableView titleForHeaderInSection:section];
	if (title != nil) {
		titleLabel.textColor = [UIColor secondaryLabelColor];
		titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
		titleLabel.text = [NSString stringWithFormat:@" %@", title];
	}
	return titleLabel;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = [super tableView:tableView titleForHeaderInSection:section];
	return title;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	CGFloat height = 10;
	if ([self tableView:tableView titleForHeaderInSection:section] != nil) {
		height = 40;
	}
	return height;
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

@end

@implementation CC26ModulesListController
- (id)init {
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateModuleViews) name:@"CC26BorderColorChanged" object:nil];
	}
	return self;
}
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Modules" target:self];
	}
	return _specifiers;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	tableView.tableHeaderView = self.headerView;
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self updateModuleViews];
}
- (void)viewDidLoad {
    [super viewDidLoad];

	NSBundle *resourceBundle = [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/PreferenceBundles/CC26Preferences.bundle")];
	NSString *wallpaperImageName = ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) ? @"headerWallpaperDark" : @"headerWallpaperLight";

	self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 180)];

	self.headerImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	self.headerImageView.contentMode = UIViewContentModeScaleAspectFill;
	self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.headerImageView.image = [UIImage imageWithContentsOfFile:[resourceBundle pathForResource:wallpaperImageName ofType:@"png"]];
	self.headerImageView.layer.continuousCorners = YES;
	self.headerImageView.layer.cornerRadius = 22;
	self.headerImageView.layer.masksToBounds = YES;
	self.headerImageView.clipsToBounds = YES;

	self.overlayMaterialView = [objc_getClass("MTMaterialView") materialViewWithRecipeNamed:@"modulesBackground" inBundle:[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SpringBoardFoundation.framework"] options:0 initialWeighting:0.5 scaleAdjustment:nil];
	self.overlayMaterialView.translatesAutoresizingMaskIntoConstraints = NO;
	self.overlayMaterialView.layer.masksToBounds = YES;
    self.overlayMaterialView.layer.continuousCorners = YES;
	self.overlayMaterialView.layer.cornerRadius = 22;

	UIStackView *moduleStack = [UIStackView new];
	moduleStack.spacing = 10;
	moduleStack.distribution = UIStackViewDistributionEqualSpacing;
	moduleStack.alignment = UIStackViewAlignmentCenter;
	moduleStack.translatesAutoresizingMaskIntoConstraints = NO;

	self.primaryModuleView = [objc_getClass("MTMaterialView") materialViewWithRecipeNamed:@"modules" inBundle:[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SpringBoardFoundation.framework"] options:0 initialWeighting:0.5 scaleAdjustment:nil];
	self.primaryModuleView.translatesAutoresizingMaskIntoConstraints = NO;
	self.primaryModuleView.layer.masksToBounds = YES;
    self.primaryModuleView.layer.continuousCorners = YES;
	self.primaryModuleView.layer.cornerRadius = 36;
	self.primaryModuleView.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
	[moduleStack addArrangedSubview:self.primaryModuleView];

	self.secondaryModuleView = [objc_getClass("MTMaterialView") materialViewWithRecipeNamed:@"modules" inBundle:[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SpringBoardFoundation.framework"] options:0 initialWeighting:0.5 scaleAdjustment:nil];
	self.secondaryModuleView.translatesAutoresizingMaskIntoConstraints = NO;
	self.secondaryModuleView.layer.masksToBounds = YES;
    self.secondaryModuleView.layer.continuousCorners = YES;
	self.secondaryModuleView.layer.cornerRadius = 36;
	[moduleStack addArrangedSubview:self.secondaryModuleView];

	[self.headerView addSubview:self.headerImageView];
	[self.headerView insertSubview:self.overlayMaterialView aboveSubview:self.headerImageView];
	[self.headerView insertSubview:moduleStack aboveSubview:self.overlayMaterialView];

	[NSLayoutConstraint activateConstraints:@[
		[self.headerImageView.topAnchor constraintEqualToAnchor:self.headerView.topAnchor],
		[self.headerImageView.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
		[self.headerImageView.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor constant:30],
		[self.headerImageView.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor constant:-30],

		[self.overlayMaterialView.topAnchor constraintEqualToAnchor:self.headerImageView.topAnchor],
		[self.overlayMaterialView.bottomAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor],
		[self.overlayMaterialView.leadingAnchor constraintEqualToAnchor:self.headerImageView.leadingAnchor],
		[self.overlayMaterialView.trailingAnchor constraintEqualToAnchor:self.headerImageView.trailingAnchor],

		[moduleStack.centerXAnchor constraintEqualToAnchor:self.headerView.centerXAnchor],
		[moduleStack.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
		[moduleStack.widthAnchor constraintEqualToConstant:250],
		[moduleStack.heightAnchor constraintEqualToConstant:76],

		[self.primaryModuleView.widthAnchor constraintEqualToConstant:72],
		[self.primaryModuleView.heightAnchor constraintEqualToConstant:72],
		[self.secondaryModuleView.widthAnchor constraintEqualToConstant:160],
		[self.secondaryModuleView.heightAnchor constraintEqualToConstant:72],
	]];

	[self updateModuleViews];
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	[super setPreferenceValue:value specifier:specifier];
	if ([specifier.properties[@"id"] isEqualToString:@"borderWidth"] || [specifier.properties[@"id"] isEqualToString:@"borderColor"]) {
		[self updateModuleViews];
	}
}
- (void)updateModuleViews {
	CGFloat borderWidth = [[[NSUserDefaults standardUserDefaults] objectForKey:@"borderWidth" inDomain:domain] floatValue] ?: 2.0;
	
	NSDictionary *borderColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"borderColorDict" inDomain:domain];
	UIColor *borderColor = (borderColorDict != nil) ? [UIColor colorWithRed:[borderColorDict[@"red"] floatValue] green:[borderColorDict[@"green"] floatValue] blue:[borderColorDict[@"blue"] floatValue] alpha:[borderColorDict[@"alpha"] floatValue]] : [UIColor colorWithWhite:0.5 alpha:0.3];
	
	self.primaryModuleView.layer.borderWidth = borderWidth;
	self.primaryModuleView.layer.borderColor = borderColor.CGColor;

   	self.secondaryModuleView.layer.borderWidth = borderWidth;
	self.secondaryModuleView.layer.borderColor = borderColor.CGColor;
}
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	NSBundle *resourceBundle = [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/PreferenceBundles/CC26Preferences.bundle")];
	NSString *wallpaperImageName = ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) ? @"headerWallpaperDark" : @"headerWallpaperLight";
	
	self.headerImageView.image = [UIImage imageWithContentsOfFile:[resourceBundle pathForResource:wallpaperImageName ofType:@"png"]];
}
@end

@implementation CC26SlidersListController
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Sliders" target:self];
	}
	return _specifiers;
}
@end

@implementation CC26BlurListController
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Blur" target:self];
	}
	return _specifiers;
}
@end

@implementation CC26SwitchCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];
    if (self) {
		[((UISwitch *)[self control]) setOnTintColor:TINT_COLOR];
        self.detailTextLabel.text = specifier.properties[@"subtitle"] ?: @"";
		self.detailTextLabel.numberOfLines = [specifier.properties[@"subtitleLines"] intValue] ?: 2;
    }
    return self;
}
- (void)tintColorDidChange {
	[super tintColorDidChange];
	self.detailTextLabel.textColor = [UIColor secondaryLabelColor];
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];

	if ([self respondsToSelector:@selector(tintColor)]) {
		self.detailTextLabel.textColor = [UIColor secondaryLabelColor];
	}
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
	colorPickerController.supportsAlpha = YES;
	colorPickerController.modalPresentationStyle = UIModalPresentationPageSheet;
	colorPickerController.modalInPresentation = YES;
	colorPickerController.selectedColor = [self selectedColor];
	[[self _viewControllerForAncestor] presentViewController:colorPickerController animated:YES completion:nil]; 
}
- (UIColor *)selectedColor {
	NSDictionary *colorDict = [[NSUserDefaults standardUserDefaults] objectForKey:[self.specifier.properties[@"key"] stringByAppendingString:@"Dict"] inDomain:domain];
	return colorDict ? [UIColor colorWithRed:[colorDict[@"red"] floatValue] green:[colorDict[@"green"] floatValue] blue:[colorDict[@"blue"] floatValue] alpha:[colorDict[@"alpha"] floatValue]] : colorFromHexString(self.specifier.properties[@"fallbackColor"]);
}
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
	[[NSUserDefaults standardUserDefaults] setObject:[self dictionaryForColor:viewController.selectedColor] forKey:[self.specifier.properties[@"key"] stringByAppendingString:@"Dict"] inDomain:domain];
	[[NSUserDefaults standardUserDefaults] synchronize];
	self.control.backgroundColor = [self selectedColor];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CC26BorderColorChanged" object:nil];
}
- (NSDictionary *)dictionaryForColor:(UIColor *)color {
	const CGFloat *components = CGColorGetComponents(color.CGColor);
	NSMutableDictionary *colorDict = [NSMutableDictionary new];
	[colorDict setObject:[NSNumber numberWithFloat:components[0]] forKey:@"red"];
	[colorDict setObject:[NSNumber numberWithFloat:components[1]] forKey:@"green"];
	[colorDict setObject:[NSNumber numberWithFloat:components[2]] forKey:@"blue"];
	[colorDict setObject:[NSNumber numberWithFloat:components[3]] forKey:@"alpha"];
	return colorDict;
}
@end


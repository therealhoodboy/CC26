#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSControlTableCell.h>
#include <rootless.h>

static NSString *domain = @"com.cureux.cc26";

#define TINT_COLOR [UIColor colorWithRed: 0.30 green: 0.35 blue: 0.53 alpha: 1.00]

@interface UINavigationItem (CC26Preferences)
@property (assign, nonatomic) UINavigationBar *navigationBar; 
@end

@interface FBSSystemService : NSObject
+ (id)sharedService;
- (void)sendActions:(id)arg1 withResult:(id)arg2;
@end

@interface BSAction : NSObject
@end

@interface SBSRelaunchAction : BSAction
+ (id)actionWithReason:(id)arg1 options:(unsigned long long)arg2 targetURL:(id)arg3;
@end

@interface NSUserDefaults (CC26)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface UIView (CC26Preferences)
- (UIViewController *)_viewControllerForAncestor;
@end

@interface CC26RootListController : PSListController {
    UITableView *_table;
}
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *headerImageView;;
@property (nonatomic, strong) UISwitch *enableSwitch;
- (void)setEnableSwitchState;
@end

@interface CC26ButtonsListController : PSListController {
    UITableView *_table;
}
@end

@interface CC26ColorCell : PSControlTableCell <UIColorPickerViewControllerDelegate>
@property (nonatomic, retain) UIButton *control;
- (NSDictionary *)dictionaryForColor:(UIColor *)color;
- (void)selectColor;
@end
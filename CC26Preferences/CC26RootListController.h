#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSControlTableCell.h>
#import <Preferences/PSSwitchTableCell.h>
#include <rootless.h>

static NSString *domain = @"com.cureux.cc26";

static inline unsigned int intFromHexString(NSString *hexString) {
    unsigned int hexInt = 0;

    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt:&hexInt];
    return hexInt;
}

static inline UIColor *colorFromHexString(NSString *hexString) {
    unsigned int hexint = intFromHexString(hexString);

    UIColor *color = [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255 green:((CGFloat) ((hexint & 0xFF00) >> 8))/255 blue:((CGFloat) (hexint & 0xFF))/255 alpha:1.0];

    return color;
}

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

@interface CC26Controller : PSListController {
    UITableView *_table;
}
@end

@interface CC26ButtonsListController : CC26Controller
@end

@interface CC26ModulesListController : CC26Controller
@end

@interface CC26SlidersListController : CC26Controller
@end

@interface CC26BlurListController : CC26Controller
@end

@interface CC26MediaListController : CC26Controller
@end

@interface CC26SwitchCell : PSSwitchTableCell
@end

@interface CC26ColorCell : PSControlTableCell <UIColorPickerViewControllerDelegate>
@property (nonatomic, retain) UIButton *control;
- (NSDictionary *)dictionaryForColor:(UIColor *)color;
- (void)selectColor;
@end
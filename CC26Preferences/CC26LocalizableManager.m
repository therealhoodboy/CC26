#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <rootless.h>
#import "CC26LocalizableManager.h"

@implementation CC26LocalizableManager
+ (NSString *)localizedString:(NSString *)key {
    return [[NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/PreferenceBundles/CC26Preferences.bundle")] localizedStringForKey:key value:key table:nil];
}
@end
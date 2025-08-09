#import <UIKit/UIKit.h>
#import "Headers/NSTask.h"
#import <objc/runtime.h>
#import <objc/message.h>
#include <spawn.h>
#include <rootless.h>

static NSString *domain = @"com.cureux.cc26";
static NSString *preferencesNotification = @"com.cureux.cc26/preferences.changed";

// preferences variables
static BOOL enabled;
static BOOL enableTopButtons;
static BOOL colorSliderGlyphs;

typedef struct CCUILayoutSize {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

@interface NSUserDefaults (CC26)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface MTMaterialLayer : CALayer
@property (nonatomic, copy, readwrite) NSString *recipeName;
@property (atomic, assign, readonly) CGRect visibleRect;
@end

@interface MTMaterialView : UIView @end
@interface CCUISteppedSliderView : UIControl @end
@interface MRUControlCenterView : UIView @end
@interface MRUTransportButton : UIButton @end
@interface MRUControlCenterViewController : UIViewController @end
@interface MRUNowPlayingView : UIView @end
@interface MRUNowPlayingTransportControlsView : UIView @end
@interface CCUIModularControlCenterViewController : UIViewController @end
@interface CCUIContentModuleContentContainerView : UIView @end
@interface CCUIOverlayViewController : UIViewController @end
@interface CCUIDisplayModuleViewController : UIViewController @end
@interface CCUIModularControlCenterOverlayViewController : CCUIOverlayViewController @end

@interface CCUIBaseSliderView : UIControl
@property (nonatomic, getter=isGlyphVisible) BOOL glyphVisible; 
@property (nonatomic) float value;
@property (readonly, nonatomic) CGPoint glyphCenter;
@property (nonatomic, retain) UIImageView *cc26GlyphImageView;
- (void)cc26_setGlyphValue:(float)value;
@end

@interface CCUIModuleInstanceManager : NSObject {
    NSMutableDictionary *_moduleInstanceByIdentifier;
}
+ (instancetype)sharedInstance;
@end

@interface CCUIContentModuleContainerViewController : UIViewController 
@property (copy, nonatomic) NSString *moduleIdentifier; 
@end

@interface CCUIModuleCollectionViewController : UIViewController 
- (NSArray<NSValue *> *)_sizesForModuleIdentifiers:(NSArray<NSString *> *)moduleIdentifiers moduleInstanceByIdentifier:(NSDictionary *)moduleInstanceByIdentifier interfaceOrientation:(long long)interfaceOrientation; // Added by CCSupport, added as requirement in control file
@end

@interface UIView (PrivateHierarchy)
- (UIViewController *)_viewControllerForAncestor;
@end

@interface NSValue (ControlCenterUI)
+ (NSValue *)ccui_valueWithLayoutSize:(CCUILayoutSize)layoutSize;
- (CCUILayoutSize)ccui_sizeValue;
@end

@interface CALayer (Private)
@property (assign) BOOL continuousCorners;
@property (atomic, assign, readwrite) id unsafeUnretainedDelegate;
@end

@class MTMaterialSettingsInterpolator;

@protocol MTRecipeMaterialSettingsProviding
- (id)baseMaterialSettings;
@end

@interface MTMaterialSettingsInterpolator : NSObject
@property (nonatomic, retain) id<MTRecipeMaterialSettingsProviding> finalSettings;
@end

@interface SpringBoard: NSObject
+ (id)sharedApplication;
- (void)applicationOpenURL:(id)arg0;
@end
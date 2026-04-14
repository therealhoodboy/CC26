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

// media player position override preferences (-1 = use default)
static CGFloat mediaArtworkX = -1;
static CGFloat mediaArtworkY = -1;
static CGFloat mediaArtworkSize = -1;
static CGFloat mediaRoutingBtnX = -1;
static CGFloat mediaRoutingBtnY = -1;
static CGFloat mediaRoutingBtnSize = -1;
static CGFloat mediaLabelX = -1;
static CGFloat mediaLabelY = -1;
static CGFloat mediaLabelW = -1;
static CGFloat mediaLabelH = -1;
static CGFloat mediaLabelLineSpacing = 1.0;

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
@interface MRUNowPlayingControlsView : UIView @end
@interface MRUNowPlayingLabelView : UIView @end
@interface MPUMarqueeView : UIView @end
@interface MRUNowPlayingHeaderView : UIControl @end
@interface MRUNowPlayingRoutingButton : UIButton @end
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
@end

@interface CCUICAPackageDescription : NSObject
@property (nonatomic, copy) NSURL *packageURL;
@end

@interface UIView (PrivateHierarchy)
- (UIViewController *)_viewControllerForAncestor;
@end

@interface CALayer (Private)
@property (assign) BOOL continuousCorners;
@property (atomic, assign, readwrite) id unsafeUnretainedDelegate;
@property (assign) BOOL invertsShadow;
@property (retain) id compositingFilter;
@property (assign) CGColorRef contentsMultiplyColor;
@end

@interface CCUICAPackageView : UIView
@end

@interface CCUIContinuousSliderView : UIControl {
    UIView *_backgroundView;
}
@property (assign, getter=isGlyphVisible, nonatomic) BOOL glyphVisible;
@property (readonly, nonatomic, getter=isGroupRenderingRequired) BOOL groupRenderingRequired;
- (void)cc26_applyGlyphColor;
@end

@interface SBElasticVolumeViewController : UIViewController
@end

@interface MRUVolumeViewController : UIViewController
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
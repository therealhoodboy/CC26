#import "Tweak.h"

#pragma mark - Calculation of border radius for different modules

CGFloat calculateArea(CGRect visibleRect) {
    return visibleRect.size.width * visibleRect.size.height;
}

CGFloat calculateAspect(CGRect visibleRect) {
    CGFloat width = visibleRect.size.width;
    CGFloat height = visibleRect.size.height;
    return (width > 0 && height > 0) ? (width / height) : 1.0;
}

CGFloat roundedToTwoDecimals(CGFloat value) {
    return round(value * 100.0) / 100.0;
}

CGFloat calculatedRadius(CGRect visibleRect, CGFloat fallbackRadius) {
    CGFloat width = visibleRect.size.width;
    CGFloat height = visibleRect.size.height;
    CGFloat aspect = roundedToTwoDecimals(calculateAspect(visibleRect));
    CGFloat area = calculateArea(visibleRect);

    // 💡 Logging (optional)
    // NSLog(@"[Radius] w:%.1f h:%.1f aspect:%.2f area:%.0f", width, height, aspect, area);

    if (CGSizeEqualToSize(visibleRect.size, [UIScreen mainScreen].bounds.size) || width <= 60 || height <= 60)
        return fallbackRadius;

    if (aspect == 1.00 && height <= 73)
        return fminf(width, height) / 2.0;

    if (aspect == 1.00 && width == height)
        return fminf(width, height) / 4.0;   

    //Slider vertical
   if (aspect >= 0.44 && aspect <= 0.54)
       return fminf(width, height) / 2.0;

    //Slider horizontal
    if (aspect >= 0.28 && aspect <= 0.32)
        return fminf(width, height) / 2.0;    

    if (aspect >= 2.18 && aspect <= 2.22)
        return fminf(width, height) / 2.0;    

    if (aspect >= 2.15 && aspect <= 2.17 )
        return fminf(width, height) / 2.0;      

    if (area == 48600 || area == 38745)
        return fminf(width, height) / 2.0;

    if (aspect >= 3.50 && aspect <= 4.00)    
        return fminf(width, height) / 4.0;

    if (width == height && height <= 85)
        return fminf(width, height) / 4.0;

    return 65.0;
}

CGFloat getModuleRadius(UIView *moduleView) {
    CGFloat width = moduleView.frame.size.width;
    CGFloat height = moduleView.frame.size.height;
    if ((width < 100 && height < 100) && width == height) { // 1x1 module
        return width / 2;
    } else if ((width > height) || (height > width)) {
        return fminf(width, height) / 2; // Rectangular module
    } else if ((width > 100 && height > 100) && width == height) { // large square module
        return width / 4;
    } else  if (width > 100 && height > 100) { // 1x1 module
        return width / 4;
    }
    return 0; // may need more cases for odd shaped modules such as CCSupport's 2x4 module
}

CGFloat calculatedRadiusForLayer(CALayer *layer, CGFloat fallbackRadius) {
    CGRect rect = layer.bounds;
    if (CGRectIsEmpty(rect)) {
        rect = layer.frame;
    }
    return calculatedRadius(rect, fallbackRadius);
}

NSArray *findAllSubviewsOfClass(UIView *view, Class cls) {
    NSMutableArray *result = [NSMutableArray array];
    for (UIView *sub in view.subviews) {
        if ([sub isKindOfClass:cls]) [result addObject:sub];
        [result addObjectsFromArray:findAllSubviewsOfClass(sub, cls)];
    }
    return result;
}

UIView *findSubviewOfClass(UIView *view, Class cls) {
    if ([view isKindOfClass:cls]) return view;
    for (UIView *subview in view.subviews) {
        UIView *match = findSubviewOfClass(subview, cls);
        if (match) return match;
    }
    return nil;
}

#pragma mark - Media module helpers

void adjustLabelFontsInView(UIView *view, BOOL isTitle) {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            label.font = [UIFont systemFontOfSize:13.0 weight:isTitle ? UIFontWeightSemibold : UIFontWeightRegular];
            label.adjustsFontSizeToFitWidth = YES;
            label.minimumScaleFactor = 0.7;
            label.textAlignment = NSTextAlignmentLeft;
        } else {
            adjustLabelFontsInView(subview, isTitle);
        }
    }
}

#pragma mark - Slider glyph coloring helpers

void colorLayers(NSArray *layers, CGColorRef color) {
    for (CALayer *sublayer in layers) {
        if ([sublayer isMemberOfClass:%c(CAShapeLayer)]) {
            CAShapeLayer *shapelayer = (CAShapeLayer *)sublayer;
            shapelayer.fillColor = color;
            shapelayer.strokeColor = color;
            shapelayer.shadowColor = [UIColor clearColor].CGColor;
        } else if (sublayer.sublayers.count == 0) {
            sublayer.backgroundColor = color;
            sublayer.borderColor = color;
            sublayer.contentsMultiplyColor = color;
            sublayer.shadowColor = [UIColor clearColor].CGColor;
        }
        colorLayers(sublayer.sublayers, color);
    }
}


%group CC26

static BOOL cc26_isInsideCCCompact(UIView *view) {
    BOOL isInsideCC = NO;
    UIView *v = view;
    while (v.superview) {
        if ([v isKindOfClass:%c(CCUIContentModuleContentContainerView)]) {
            isInsideCC = YES;
            break;
        }
        v = v.superview;
    }
    if (!isInsideCC) return NO;
    UIView *ancestor = view;
    while (ancestor) {
        if ([ancestor isKindOfClass:%c(MRUNowPlayingView)]) {
            @try {
                NSInteger layout = [[ancestor valueForKey:@"_layout"] integerValue];
                if (layout == 2 || layout == 1) return NO;
            } @catch (NSException *e) {}
            break;
        }
        ancestor = ancestor.superview;
    }
    return YES;
}

static void cc26_forceSubviewAlphas(UIView *view) {
    for (UIView *sub in view.subviews) {
        if (!sub.hidden) {
            sub.layer.opacity = 1.0;
        }
    }
}

%hook MRUControlCenterView
- (void)layoutSubviews {
    %orig;

    CGFloat moduleWidth = self.bounds.size.width;
    CGFloat moduleHeight = self.bounds.size.height;

    NSArray *buttons = findAllSubviewsOfClass(self, %c(MRUTransportButton));
    for (MRUTransportButton *btn in buttons) {
        // 🎯 Nur den Button nehmen, der *direkt* unter dieser View hängt
        if ([btn.superview isKindOfClass:[UIView class]] &&
            btn.superview.superview == self) {

            NSLog(@"[CC26] Found transport button: %@", btn);

            CGFloat buttonWidth = btn.frame.size.width;
            CGFloat buttonHeight = btn.frame.size.height;

            // 📐 Dynamisch berechnete Position (5% nach links, 89% nach oben)
            CGFloat buttonX = moduleWidth * 0.63;
            CGFloat buttonY = moduleHeight * 0.08;

            btn.translatesAutoresizingMaskIntoConstraints = YES;
            btn.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);

            btn.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.4];
            btn.layer.cornerRadius = 18;
            btn.layer.masksToBounds = YES;

            break; // Nur den ersten passenden Button anpassen
        }
    }
}
%end

%hook MRUNowPlayingHeaderView
- (void)layoutSubviews {
    %orig;

    // Only apply inside Control Center
    BOOL isInsideCC = NO;
    UIView *v = self;
    while (v.superview) {
        if ([v isKindOfClass:%c(CCUIContentModuleContentContainerView)]) {
            isInsideCC = YES;
            break;
        }
        v = v.superview;
    }
    if (!isInsideCC) return;

    // Skip if ancestor MRUNowPlayingView is in expanded layout
    UIView *parent = self.superview;
    while (parent) {
        if ([parent isKindOfClass:%c(MRUNowPlayingView)]) {
            @try {
                NSInteger layout = [[parent valueForKey:@"_layout"] integerValue];
                if (layout == 2 || layout == 1) return;
            } @catch (NSException *e) {}
            break;
        }
        parent = parent.superview;
    }

    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;

    // --- Read preference overrides (negative = use default) ---
    CGFloat prefArtX   = mediaArtworkX;
    CGFloat prefArtY   = mediaArtworkY;
    CGFloat prefArtSz  = mediaArtworkSize;
    CGFloat prefBtnX   = mediaRoutingBtnX;
    CGFloat prefBtnY   = mediaRoutingBtnY;
    CGFloat prefBtnSz  = mediaRoutingBtnSize;
    CGFloat prefLblX   = mediaLabelX;
    CGFloat prefLblY   = mediaLabelY;
    CGFloat prefLblW   = mediaLabelW;
    CGFloat prefLblH   = mediaLabelH;

    // === ROW 1: Artwork LEFT + Routing button RIGHT, same vertical center ===

    // Artwork
    UIView *artworkView = nil;
    Ivar artworkIvar = class_getInstanceVariable(object_getClass(self), "_artworkView");
    if (artworkIvar) artworkView = object_getIvar(self, artworkIvar);

    CGFloat artSize = (prefArtSz >= 0) ? prefArtSz : 50.0;
    CGFloat btnSize = (prefBtnSz >= 0) ? prefBtnSz : 42.0;
    CGFloat topRowHeight = MAX(artSize, btnSize);

    CGFloat artX = (prefArtX >= 0) ? prefArtX : 11.0;
    CGFloat artY = (prefArtY >= 0) ? prefArtY : 8.0;

    if (artworkView) {
        artworkView.translatesAutoresizingMaskIntoConstraints = YES;
        artworkView.frame = CGRectMake(artX, artY, artSize, artSize);
        artworkView.alpha = 1.0;
        artworkView.layer.cornerRadius = artSize * 0.22;
        artworkView.layer.masksToBounds = YES;
        artworkView.clipsToBounds = YES;
    }

    // Routing button (AirPlay) — same row, right-aligned, vertically centered with artwork
    UIView *routingButton = nil;
    Ivar routingIvar = class_getInstanceVariable(object_getClass(self), "_routingButton");
    if (routingIvar) routingButton = object_getIvar(self, routingIvar);

    CGFloat btnX = (prefBtnX >= 0) ? prefBtnX : 85.0;
    CGFloat btnY = (prefBtnY >= 0) ? prefBtnY : (topRowHeight - btnSize) / 2.0;

    if (routingButton) {
        routingButton.alpha = 1.0;
        routingButton.translatesAutoresizingMaskIntoConstraints = YES;
        routingButton.frame = CGRectMake(btnX, btnY, btnSize, btnSize);
        routingButton.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.25];
        routingButton.layer.cornerRadius = btnSize / 2.0;
        routingButton.layer.masksToBounds = YES;
    }

    // === ROW 2: Label view BELOW artwork+routing row, full width ===
    UIView *labelView = nil;
    Ivar labelIvar = class_getInstanceVariable(object_getClass(self), "_labelView");
    if (labelIvar) labelView = object_getIvar(self, labelIvar);

    if (labelView) {
        CGFloat labelX = (prefLblX >= 0) ? prefLblX : 0.0;
        CGFloat labelY = (prefLblY >= 0) ? prefLblY : 63.0;
        CGFloat labelW = (prefLblW >= 0) ? prefLblW : W;
        CGFloat labelH = (prefLblH >= 0) ? prefLblH : MAX(H - labelY, 35.0);
        labelView.translatesAutoresizingMaskIntoConstraints = YES;
        labelView.frame = CGRectMake(labelX, labelY, labelW, labelH);
        labelView.alpha = 1.0;
        labelView.layer.opacity = 1.0;
        labelView.clipsToBounds = YES;
        cc26_forceSubviewAlphas(labelView);
    }

    self.clipsToBounds = NO;
    adjustLabelFontsInView(self, NO);
}
%end

%hook MPUMarqueeView
- (void)setAlpha:(CGFloat)alpha {
    if ([self.superview isKindOfClass:%c(MRUNowPlayingLabelView)] && cc26_isInsideCCCompact(self)) {
        %orig(1.0);
        self.layer.opacity = 1.0;
        cc26_forceSubviewAlphas(self);
        return;
    }
    %orig;
}
%end

%hook MRUNowPlayingLabelView
- (void)setAlpha:(CGFloat)alpha {
    if (cc26_isInsideCCCompact(self)) {
        %orig(1.0);
        self.layer.opacity = 1.0;
        cc26_forceSubviewAlphas(self);
        return;
    }
    %orig;
}
- (void)layoutSubviews {
    %orig;

    // Only apply inside Control Center
    BOOL isInsideCC = NO;
    UIView *v = self;
    while (v.superview) {
        if ([v isKindOfClass:%c(CCUIContentModuleContentContainerView)]) {
            isInsideCC = YES;
            break;
        }
        v = v.superview;
    }
    if (!isInsideCC) return;

    // Skip if expanded
    UIView *ancestor = self.superview;
    while (ancestor) {
        if ([ancestor isKindOfClass:%c(MRUNowPlayingView)]) {
            @try {
                NSInteger layout = [[ancestor valueForKey:@"_layout"] integerValue];
                if (layout == 2 || layout == 1) return;
            } @catch (NSException *e) {}
            break;
        }
        ancestor = ancestor.superview;
    }

    // Get marquee views and standalone label views
    UIView *titleMarquee = nil;
    UIView *subtitleMarquee = nil;
    UIView *titleLabel = nil;
    UIView *subtitleLabel = nil;

    Ivar iv;
    iv = class_getInstanceVariable(object_getClass(self), "_titleMarqueeView");
    if (iv) titleMarquee = object_getIvar(self, iv);
    iv = class_getInstanceVariable(object_getClass(self), "_subtitleMarqueeView");
    if (iv) subtitleMarquee = object_getIvar(self, iv);
    iv = class_getInstanceVariable(object_getClass(self), "_titleLabel");
    if (iv) titleLabel = object_getIvar(self, iv);
    iv = class_getInstanceVariable(object_getClass(self), "_subtitleLabel");
    if (iv) subtitleLabel = object_getIvar(self, iv);

    // Use marquee views for positioning
    UIView *titleView = titleMarquee ?: titleLabel;
    UIView *subtitleView = subtitleMarquee ?: subtitleLabel;

    // _titleLabel/_subtitleLabel are INSIDE the marquee views.
    // Do NOT touch their hidden state — the system manages it
    // to avoid duplication with the marquee's own scrolling content.

    // Hide _routeLabel in compact mode (not needed)
    UIView *routeLabel = nil;
    iv = class_getInstanceVariable(object_getClass(self), "_routeLabel");
    if (iv) routeLabel = object_getIvar(self, iv);
    if (routeLabel) routeLabel.hidden = YES;

    CGFloat lineSpacing = mediaLabelLineSpacing;

    if (titleView && subtitleView) {
        CGFloat W = self.bounds.size.width;
        CGFloat titleH = 16.0;
        CGFloat subtitleH = 14.0;

        titleView.translatesAutoresizingMaskIntoConstraints = YES;
        subtitleView.translatesAutoresizingMaskIntoConstraints = YES;
        titleView.clipsToBounds = YES;
        subtitleView.clipsToBounds = YES;
        // Force visibility on self and children
        self.layer.opacity = 1.0;
        titleView.layer.opacity = 1.0;
        subtitleView.layer.opacity = 1.0;
        cc26_forceSubviewAlphas(titleView);
        cc26_forceSubviewAlphas(subtitleView);

        CGFloat totalH = titleH + lineSpacing + subtitleH;
        CGFloat startY = (self.bounds.size.height - totalH) / 2.0;
        if (startY < 0) startY = 0;

        titleView.frame = CGRectMake(0, startY, W, titleH);
        subtitleView.frame = CGRectMake(0, startY + titleH + lineSpacing, W, subtitleH);

        // Bold title, regular subtitle
        adjustLabelFontsInView(titleView, YES);
        adjustLabelFontsInView(subtitleView, NO);

        // Delayed re-force in case system overrides alpha after layout
        dispatch_async(dispatch_get_main_queue(), ^{
            self.layer.opacity = 1.0;
            for (UIView *sub in self.subviews) {
                if (!sub.hidden) {
                    sub.layer.opacity = 1.0;
                    for (UIView *inner in sub.subviews) {
                        inner.layer.opacity = 1.0;
                    }
                }
            }
        });
    }
}
%end

%hook CCUICAPackageDescription
- (NSURL *)packageURL {
    NSURL *packageURL = %orig;
    if (!colorSliderGlyphs) return packageURL;
    if ([packageURL.absoluteString isEqualToString:@"file:///System/Library/ControlCenter/Bundles/DisplayModule.bundle/Brightness.ca/"]) {
        return [NSURL fileURLWithPath:ROOT_PATH_NS(@"/Library/PreferenceBundles/CC26Preferences.bundle/Brightness.ca")];
    }
    if ([packageURL.absoluteString isEqualToString:@"file:///System/Library/PrivateFrameworks/MediaControls.framework/Volume.ca/"]) {
        return [NSURL fileURLWithPath:ROOT_PATH_NS(@"/Library/PreferenceBundles/CC26Preferences.bundle/VolumeBold.ca")];
    }
    return packageURL;
}
%end

%hook CALayer
- (void)setOpacity:(float)opacity {
    if ([self.delegate isKindOfClass:%c(CCUICAPackageView)] || [self.delegate isKindOfClass:%c(UIImageView)]) {
        id controller = [(UIView *)self.delegate _viewControllerForAncestor];
        if ([controller isKindOfClass:%c(CCUIDisplayModuleViewController)] || [controller isKindOfClass:%c(MRUVolumeViewController)]) {
            opacity = opacity > 0 ? 1.0 : opacity;
        }
    }
    %orig(opacity);
}
%end

%hook CCUIContinuousSliderView
%new
- (void)cc26_applyGlyphColor {
    if (!colorSliderGlyphs) return;
    if (!self.window) return;

    static BOOL cc26_isApplyingGlyph = NO;
    if (cc26_isApplyingGlyph) return;
    cc26_isApplyingGlyph = YES;

    UIColor *glyphColor = nil;
    id controller = [self _viewControllerForAncestor];
    if (!controller) { cc26_isApplyingGlyph = NO; return; }

    if ([controller isKindOfClass:%c(CCUIDisplayModuleViewController)]) {
        NSDictionary *brightnessColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"brightnessColorDict" inDomain:domain];
        glyphColor = (brightnessColorDict != nil) ? [UIColor colorWithRed:[brightnessColorDict[@"red"] floatValue] green:[brightnessColorDict[@"green"] floatValue] blue:[brightnessColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor colorWithRed:0.96 green:0.81 blue:0.27 alpha:1.00];
    } else if ([controller isKindOfClass:%c(MRUVolumeViewController)] || [controller isKindOfClass:%c(SBElasticVolumeViewController)]) {
        NSDictionary *volumeColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"volumeColorDict" inDomain:domain];
        glyphColor = (volumeColorDict != nil) ? [UIColor colorWithRed:[volumeColorDict[@"red"] floatValue] green:[volumeColorDict[@"green"] floatValue] blue:[volumeColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor colorWithRed:0.35 green:0.67 blue:0.88 alpha:1.00];
    }
    if (!glyphColor) { cc26_isApplyingGlyph = NO; return; }

    UIView *packageView = nil;
    const char *ivarName = "_compensatingGlyphView";

    Ivar ivar = class_getInstanceVariable(object_getClass(self), ivarName);
    if (ivar) {
        packageView = object_getIvar(self, ivar);
    }

    if (packageView && glyphColor) {
        if ([packageView isKindOfClass:%c(CCUICAPackageView)]) {
            colorLayers(@[packageView.layer], glyphColor.CGColor);
        } else if ([packageView isKindOfClass:%c(UIImageView)]) {
            [(UIImageView *)packageView setTintColor:glyphColor];
        }
    }
    cc26_isApplyingGlyph = NO;
}
- (void)didMoveToWindow {
    %orig;
    [self cc26_applyGlyphColor];
}
- (void)_applyGlyphState:(id)arg1 performConfiguration:(BOOL)arg2 {
    %orig;
    [self cc26_applyGlyphColor];
}
- (void)_setActiveGlyphView:(id)arg1 {
    %orig;
    [self cc26_applyGlyphColor];
}
- (BOOL)isGroupRenderingRequired {
    return NO;
}
- (NSArray *)punchOutRootLayers {
    return nil;
}
- (NSArray *)punchOutRenderingViews {
    return nil;
}
%end

%hook MRUNowPlayingControlsView
static BOOL cc26ControlsLayoutInProgress = NO;
- (void)layoutSubviews {
    %orig;

    if (cc26ControlsLayoutInProgress) return;
    cc26ControlsLayoutInProgress = YES;

    BOOL isInsideCC = NO;
    UIView *v = self;
    while (v.superview) {
        if ([v isKindOfClass:%c(CCUIContentModuleContentContainerView)]) {
            isInsideCC = YES;
            break;
        }
        v = v.superview;
    }
    if (!isInsideCC) {
        cc26ControlsLayoutInProgress = NO;
        return;
    }

    // Check parent MRUNowPlayingView layout
    UIView *npView = self.superview;
    if ([npView isKindOfClass:%c(MRUNowPlayingView)]) {
        @try {
            NSInteger layout = [[npView valueForKey:@"_layout"] integerValue];
            if (layout == 2 || layout == 1) {
                cc26ControlsLayoutInProgress = NO;
                return;
            }
        } @catch (NSException *e) {
            cc26ControlsLayoutInProgress = NO;
            return;
        }
    }

    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;
    CGFloat pad = 8.0;

    // Position headerView: top portion with padding
    UIView *headerView = nil;
    Ivar headerIvar = class_getInstanceVariable(object_getClass(self), "_headerView");
    if (headerIvar) headerView = object_getIvar(self, headerIvar);

    if (headerView) {
        CGFloat headerHeight = H * 0.65;
        headerView.translatesAutoresizingMaskIntoConstraints = YES;
        headerView.frame = CGRectMake(pad, pad, W - 2 * pad, headerHeight);
        headerView.clipsToBounds = NO;
        [headerView setNeedsLayout];
        [headerView layoutIfNeeded];
    }

    // Position transportControlsView: centered at bottom
    UIView *transportView = nil;
    Ivar transportIvar = class_getInstanceVariable(object_getClass(self), "_transportControlsView");
    if (transportIvar) transportView = object_getIvar(self, transportIvar);

    if (transportView) {
        CGFloat controlsHeight = transportView.frame.size.height;
        if (controlsHeight < 20) controlsHeight = 44.0;
        CGFloat controlsWidth = W * 0.75;
        CGFloat x = (W - controlsWidth) / 2.0;
        CGFloat y = H - controlsHeight - pad;
        transportView.translatesAutoresizingMaskIntoConstraints = YES;
        transportView.frame = CGRectMake(x, y, controlsWidth, controlsHeight);
    }

    cc26ControlsLayoutInProgress = NO;
}
%end

%hook MRUNowPlayingTransportControlsView
- (void)layoutSubviews {
    %orig;

    BOOL isInsideCC = NO;
    UIView *v = self;
    while (v.superview) {
        if ([v isKindOfClass:%c(CCUIContentModuleContentContainerView)]) {
            isInsideCC = YES;
            break;
        }
        v = v.superview;
    }
    if (!isInsideCC) return;

    @try {
        // Walk up to find parent MRUNowPlayingView
        UIView *ancestor = self.superview;
        while (ancestor && ![ancestor isKindOfClass:%c(MRUNowPlayingView)]) {
            ancestor = ancestor.superview;
        }
        if (!ancestor) return;

        NSInteger layout = [[ancestor valueForKey:@"_layout"] integerValue];
        if (layout == 2) return;

        UIButton *leftButton = [self valueForKey:@"leftButton"];
        UIButton *rightButton = [self valueForKey:@"rightButton"];
        UIButton *middleButton = [self valueForKey:@"middleButton"];

        if (leftButton && rightButton && middleButton) {
            CGFloat viewWidth = self.bounds.size.width;
            CGFloat centerY = self.bounds.size.height / 2.0;
            CGFloat spacing = viewWidth * 0.28;

            middleButton.center = CGPointMake(viewWidth / 2.0, centerY);
            leftButton.center = CGPointMake(viewWidth / 2.0 - spacing, centerY);
            rightButton.center = CGPointMake(viewWidth / 2.0 + spacing, centerY);
        }

    } @catch (NSException *e) {
        NSLog(@"[CC26] MRUNowPlayingTransportControlsView crash prevented: %@", e);
    }
}
%end

BOOL isSubviewOfType(UIView *view, NSArray<Class> *targetClasses) {
    if (!view) return NO;

    // Check if this view is one of the target classes
    for (Class targetClass in targetClasses) {
        if ([view isKindOfClass:targetClass]) {
            return YES;
        }
    }

    // Recursively check all subviews
    for (UIView *subview in view.subviews) {
        if (isSubviewOfType(subview, targetClasses)) {
            return YES;
        }
    }
    return NO;
}

%hook CCUIContentModuleContentContainerView
void applyBorderToSpecialViews(UIView *view, BOOL expanded) {
    if (!view) return;

    CGFloat radius = 65.0;
    BOOL shouldApply = NO;

    if ([view isKindOfClass:%c(FCUIActivityControl)]) {
        radius = 35;
        shouldApply = YES; // immer Rahmen
    } else if ([view isKindOfClass:%c(MRUNowPlayingView)]) {
        radius = 65;
        shouldApply = expanded; // nur bei expanded!
    }

    if (shouldApply) {
        view.layer.cornerRadius = radius;
        view.layer.borderWidth = 2.0;
        view.layer.continuousCorners = YES;
        view.layer.masksToBounds = YES;
        view.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
        NSLog(@"[CC26] Rahmen auf %@ gesetzt (Radius %.1f, expanded: %d): %@", NSStringFromClass([view class]), radius, expanded, view);
    }

    for (UIView *subview in view.subviews) {
        applyBorderToSpecialViews(subview, expanded);
    }
}


- (void)layoutSubviews { // Hate to use this method, but only one that doesn't cause visual glitches
    BOOL opened = MSHookIvar<BOOL>(self, "_expanded");
    int radius = opened ? 65 : getModuleRadius(self); 
    dispatch_async(dispatch_get_main_queue(), ^{
        applyBorderToSpecialViews(self, opened);
    });

    NSArray<Class> *suppressedClasses = @[
        %c(CCUIContinuousSliderView),
        %c(MRUNowPlayingView),
        %c(FCUIActivityListContentView)
    ];
    if (opened) {
    UIView *npv = findSubviewOfClass(self, %c(MRUNowPlayingView));
    if (npv) {
        npv.layer.cornerRadius = 65;
        npv.layer.borderWidth = 2.0;
        npv.layer.continuousCorners = YES;
        npv.layer.masksToBounds = YES;
        npv.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
        NSLog(@"[CC26] Manuell: Rahmen auf NowPlayingView gesetzt: %@", npv);
    } else {
        NSLog(@"[CC26] ⚠️ NowPlayingView nicht gefunden (zu früh?)");
    }
}


    // Überprüfe, ob eine der Subviews (auch tief verschachtelt) eine der Zielklassen ist
    BOOL isSuppressedType = isSubviewOfType(self, suppressedClasses);
       
    CGFloat borderWidth = (opened && isSuppressedType) ? 0.0 : 2.0;
    self.clipsToBounds = YES;
    if (opened && isSubviewOfType(self, @[ %c(MRUNowPlayingView) ])) {
    radius = 65;
}
    self.layer.cornerRadius = radius;
    self.layer.continuousCorners = YES; // Smooth corner into straight edges!!
    self.layer.borderWidth = borderWidth;
    self.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
    self.layer.masksToBounds = YES;
    if (self.subviews.count == 1) {
        UIView *subview1 = [self subviews][0];
       // subview1.layer.borderWidth = 2.0;
       // subview1.layer.continuousCorners = YES;
        if ([[subview1 subviews] count] >= 1) {
            UIView *subview2 = [subview1 subviews][0];
            if ([subview2 isKindOfClass:%c(CCUIContinuousSliderView)]) { // Volume Slider
                [subview2 setClipsToBounds:YES];
                [[subview2 layer] setCornerRadius:radius];
                subview2.layer.continuousCorners = YES; 
                subview2.layer.borderWidth = 1.0; 
                subview2.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;       
            } else {
                if ([[subview2 subviews] count] > 0) {
                    UIView *subview3 = [subview2 subviews][0];
                     subview3.layer.continuousCorners = YES; 
                     subview3.layer.borderWidth = 1.0; 
                     subview3.layer.cornerRadius = radius; 
                     subview3.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;   
                    if ([[subview3 subviews] count] > 0) {
                        UIView *subview4 = [subview3 subviews][0];
                         subview4.layer.continuousCorners = YES; 
                         subview4.layer.borderWidth = 1.0; 
                         subview4.layer.cornerRadius = radius;  
                         subview4.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
                        if ([[subview4 subviews] count] > 0) {
                            UIView *subview5 = [subview4 subviews][0];
                            
                            if ([subview5 isKindOfClass: %c(MTMaterialView)]) {
                                [[subview5 layer] setCornerRadius:radius];
                                subview5.layer.continuousCorners = YES;
                                subview5.layer.borderWidth = 1.0; 
                                subview5.layer.cornerRadius = radius;
                                subview5.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
                            }
                        }
                    }
                }
            }
        }
    } else if (self.subviews.count > 1) {
        UIView *subview = [self subviews][1];
        if ([subview isKindOfClass: %c(CCUIContinuousSliderView)]) {
            [[subview layer] setCornerRadius:radius];
            subview.layer.continuousCorners = YES;
            subview.layer.borderWidth = 1.0;
            subview.layer.cornerRadius = radius;
            subview.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
           // subview.clipsToBounds = YES;
        }
    }
    NSLog(@"[CC26] Module View: %@ – cornerRadius gesetzt auf %d", self, radius);

}
%end

%hook CCUIModularControlCenterOverlayViewController
- (void)setPresentationState:(NSInteger)state {
    %orig;

    UIView *view = self.view;
    CGFloat iconSize = 14; // Kleinere Icons
    CGFloat buttonPadding = 6; // Button etwas größer für Touchfläche
    CGFloat buttonSize = iconSize + buttonPadding;
    CGFloat yOffset = 23;
    CGFloat safeLeft = view.window.safeAreaInsets.left ?: 36;
    CGFloat safeRight = view.window.safeAreaInsets.right ?: 36;

    if (enableTopButtons) {
        // Plus-Button
        UIButton *plus = [view viewWithTag:999];
        if (!plus) {
            NSDictionary *addColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"addButtonColorDict" inDomain:domain];
            UIColor *addColor = (addColorDict != nil) ? [UIColor colorWithRed:[addColorDict[@"red"] floatValue] green:[addColorDict[@"green"] floatValue] blue:[addColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor whiteColor];

            plus = [UIButton buttonWithType:UIButtonTypeSystem];
            plus.tag = 999;

            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:iconSize weight:UIImageSymbolWeightRegular];
            UIImage *plusImage = [[UIImage systemImageNamed:@"plus"] imageByApplyingSymbolConfiguration:config];

            [plus setImage:plusImage forState:UIControlStateNormal];
            plus.tintColor = addColor;
            plus.alpha = 0.0;
            plus.transform = CGAffineTransformMakeScale(0.6, 0.6);
            plus.frame = CGRectMake(safeLeft, yOffset - 10, buttonSize, buttonSize);

            [plus addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
                UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
                [gen impactOccurred];
                [((SpringBoard *)[%c(SpringBoard) sharedApplication]) applicationOpenURL:[NSURL URLWithString:@"prefs:root=ControlCenter&path=CUSTOMIZE_CONTROLS"]];
                NSLog(@"[+] Plus tapped");
            }] forControlEvents:UIControlEventTouchUpInside];

            [view addSubview:plus];
        }

        // Power-Button
        UIButton *power = [view viewWithTag:998];
        if (!power) {
            NSDictionary *powerColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"powerButtonColorDict" inDomain:domain];
            UIColor *powerColor = (powerColorDict != nil) ? [UIColor colorWithRed:[powerColorDict[@"red"] floatValue] green:[powerColorDict[@"green"] floatValue] blue:[powerColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor systemRedColor];

            power = [UIButton buttonWithType:UIButtonTypeSystem];
            power.tag = 998;

            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:iconSize weight:UIImageSymbolWeightRegular];
            UIImage *powerImage = [[UIImage systemImageNamed:@"power"] imageByApplyingSymbolConfiguration:config];

            [power setImage:powerImage forState:UIControlStateNormal];
            power.tintColor = powerColor;
            power.alpha = 0.0;
            power.transform = CGAffineTransformMakeScale(0.6, 0.6);
            power.frame = CGRectMake(view.bounds.size.width - safeRight - buttonSize, yOffset - 10, buttonSize, buttonSize);

            if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){14,0,0}]) {
                UIAction *respringAction = [UIAction actionWithTitle:@"Respring"
                                                            image:[UIImage systemImageNamed:@"arrow.clockwise.circle"]
                                                        identifier:nil
                                                            handler:^(__kindof UIAction *action) {
                    pid_t pid;
                    const char *args[] = {"sbreload", NULL};
                    posix_spawn(&pid, ROOT_PATH("/usr/bin/sbreload"), NULL, NULL, (char *const *)args, NULL);
                }];

                UIAction *uicacheAction = [UIAction actionWithTitle:@"UICache"
                                                            image:[UIImage systemImageNamed:@"paintbrush.fill"]
                                                        identifier:nil
                                                            handler:^(__kindof UIAction *action) {
                    pid_t pid;
                    const char *args[] = {"uicache", "-a", NULL};
                    posix_spawn(&pid, ROOT_PATH("/usr/bin/uicache"), NULL, NULL, (char *const *)args, NULL);
                }];

                UIAction *userspaceAction = [UIAction actionWithTitle:@"Userspace Reboot"
                                                                image:[UIImage systemImageNamed:@"bolt.fill"]
                                                        identifier:nil
                                                            handler:^(__kindof UIAction *action) {
                    pid_t pid;
                    const char *args[] = {"launchctl", "reboot", "userspace", NULL};
                    posix_spawn(&pid, ROOT_PATH("/bin/launchctl"), NULL, NULL, (char *const *)args, NULL);
                }];

                UIMenu *menu = [UIMenu menuWithTitle:@"Choose Action"
                                            children:@[respringAction, uicacheAction, userspaceAction]];
                [power setMenu:menu];
                [power setShowsMenuAsPrimaryAction:YES];

                [power addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
                    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
                    [gen impactOccurred];
                }] forControlEvents:UIControlEventPrimaryActionTriggered];
            }

            [view addSubview:power];
        }

        // Update Frames (z. B. bei Rotation)
        plus.frame = CGRectMake(safeLeft - 10, yOffset - 10, buttonSize + 15, buttonSize + 15);
        power.frame = CGRectMake(view.bounds.size.width - safeRight - buttonSize - 10, yOffset - 10, buttonSize + 15, buttonSize + 15);

        // Animation je nach Zustand
        switch (state) {
            case 1: {
                plus.transform = CGAffineTransformMakeScale(0.6, 0.6);
                power.transform = CGAffineTransformMakeScale(0.6, 0.6);
                [UIView animateWithDuration:0.45
                                    delay:0.0
                    usingSpringWithDamping:0.7
                    initialSpringVelocity:0.5
                                    options:UIViewAnimationOptionCurveEaseOut
                                animations:^{
                    plus.alpha = 1.0;
                    plus.transform = CGAffineTransformIdentity;
                    power.alpha = 1.0;
                    power.transform = CGAffineTransformIdentity;
                } completion:nil];
                break;
            }
            case 3: {
                [UIView animateWithDuration:0.2 animations:^{
                    plus.alpha = 0.0;
                    plus.transform = CGAffineTransformMakeScale(0.6, 0.6);
                    power.alpha = 0.0;
                    power.transform = CGAffineTransformMakeScale(0.6, 0.6);
                }];
                break;
            }
            default:
                break;
        }
    }
}
%end
%end

static void loadPreferences(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSNumber *enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:domain];
    enabled = (enabledValue) ? [enabledValue boolValue] : NO;
    NSNumber *enableTopButtonsValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enableTopButtons" inDomain:domain];
    enableTopButtons = (enableTopButtonsValue) ? [enableTopButtonsValue boolValue] : YES;
    NSNumber *colorSliderGlyphsValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"colorSliderGlyphs" inDomain:domain];
    colorSliderGlyphs = (colorSliderGlyphsValue) ? [colorSliderGlyphsValue boolValue] : YES;

    // Media player position overrides (-1 = default)
    NSNumber *val;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaArtworkX" inDomain:domain];
    mediaArtworkX = val ? [val floatValue] : -1;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaArtworkY" inDomain:domain];
    mediaArtworkY = val ? [val floatValue] : -1;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaArtworkSize" inDomain:domain];
    mediaArtworkSize = val ? [val floatValue] : -1;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaRoutingBtnX" inDomain:domain];
    mediaRoutingBtnX = val ? [val floatValue] : -1;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaRoutingBtnY" inDomain:domain];
    mediaRoutingBtnY = val ? [val floatValue] : -1;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaRoutingBtnSize" inDomain:domain];
    mediaRoutingBtnSize = val ? [val floatValue] : -1;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaLabelX" inDomain:domain];
    mediaLabelX = val ? [val floatValue] : -1;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaLabelY" inDomain:domain];
    mediaLabelY = val ? [val floatValue] : -1;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaLabelW" inDomain:domain];
    mediaLabelW = val ? [val floatValue] : -1;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaLabelH" inDomain:domain];
    mediaLabelH = val ? [val floatValue] : -1;
    val = [[NSUserDefaults standardUserDefaults] objectForKey:@"mediaLabelLineSpacing" inDomain:domain];
    mediaLabelLineSpacing = val ? [val floatValue] : 1.0;
}

%ctor {
    loadPreferences(NULL, NULL, NULL, NULL, NULL); // Load prefs
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, loadPreferences, (CFStringRef)preferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    if (enabled) {
        %init(CC26)
    }
}
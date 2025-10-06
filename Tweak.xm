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

#pragma mark - iOS 26 border

/*
void applyPrismToLayer(CALayer *layer) {
    CAGradientLayer *gradient = nil;

    for (CALayer *sublayer in layer.sublayers) {
        if ([sublayer.name isEqualToString:@"iOS26PrismBorder"] && [sublayer isKindOfClass:[CAGradientLayer class]]) {
            gradient = (CAGradientLayer *)sublayer;
            break;
        }
    }

    if (!gradient) {
        gradient = [CAGradientLayer layer];
        gradient.name = @"iOS26PrismBorder";
        gradient.colors = @[
            (id)[[UIColor colorWithRed:0.8 green:0.75 blue:0.95 alpha:0.30] CGColor],
            (id)[[UIColor colorWithWhite:1.0 alpha:0.08] CGColor],
            (id)[[UIColor colorWithRed:0.9 green:0.85 blue:1.0 alpha:0.20] CGColor]
        ];
        gradient.locations = @[@0.0, @0.5, @1.0];
        gradient.startPoint = CGPointMake(0.0, 0.0);
        gradient.endPoint = CGPointMake(1.0, 1.0);
        gradient.contentsScale = [UIScreen mainScreen].scale;

        [layer insertSublayer:gradient atIndex:0];
    }

    gradient.frame = layer.bounds;
    gradient.masksToBounds = YES;
    gradient.cornerRadius = layer.cornerRadius;
}
*/

// new tahoe shader
#define MTL_TAHOE_FORMAT  MTLPixelFormatBGRA8Unorm;

static id<MTLDevice> pMetalDevice = nil;
static id<MTLCommandQueue> pMetalCommandQueue = nil;

static id<MTLRenderPipelineState> uiGlassShader = nil;
static id<MTLTexture> uiGlassBackdropTexture = nil;
static id<MTLBuffer> uiGlassInstanceData = nil;


struct TAHOE_instance_data_t {
    float position_x;
    float position_y;
    float rtSize_x;
    float rtSize_y;
    float aspectRatio;
    float _padd[3];
} uiGlassInstanceDataCPU;
        
void initMetalDevice() {
    
NSLog(@"TAHOE: initMetalDevice:BEGIN");

    pMetalDevice = MTLCreateSystemDefaultDevice();
    pMetalCommandQueue = [ pMetalDevice newCommandQueue ];

    NSString *shaderCode = 
        @"#include <metal_stdlib>\n"
        @"using namespace metal;\n"
        @"\n"
        @"struct v2f\n"
        @"{\n"
        @"    float4 position [[position]];\n"
        @"    float2 texcoord;\n"
        @"    half3 color;\n"
        @"};\n"
        @"\n"
        @"struct instance_data_t {\n"
        @"    float position[2];   // float2\n"
        @"    float rtSize[2];     // float2\n"
        @"    float aspectRatio;   // float\n"
        @"    float _padding[3];   // pad to 32 bytes\n"
        @"};\n"
        @"\n"
        @"v2f vertex vertexMain(uint vertexId [[vertex_id]])\n"
        @"{\n"
        @"    const float4 cvPositions[3] = {\n"
        @"        { -1.0, -1.0,  1.0,  1.0 },\n"
        @"        {  3.0, -1.0,  1.0,  1.0 },\n"
        @"        { -1.0,  3.0,  1.0,  1.0 },\n"
        @"    };\n"
        @"    v2f o;\n"
        @"    o.position = cvPositions[vertexId];\n"
        @"    o.texcoord = cvPositions[vertexId].xy;\n"
        @"    o.color = half3(1.f, 0.f, 0.f);\n"
        @"    return o;\n"
        @"}\n"
        @"\n"
        @"half3 gblur(float2 uv, texture2d<half, access::sample> tex, float blur = 1.0)\n"
        @"{\n"
        @"    constexpr sampler s(address::repeat, filter::linear);\n"
        @"    float Pi = 6.28318530718;\n"
        @"    float Directions = 16.0;\n"
        @"    float Quality = 3.0;\n"
        @"    float Size = blur;\n"
        @"    float2 Radius = Size/float2(2880.f,1800.f);\n"
        @"    half3 Color = tex.sample(s, uv).abg;\n"
        @"    for (float d=0.0; d<Pi; d+=Pi/Directions) {\n"
        @"        for(float i=1.0/Quality; i<=1.0001; i+=1.0/Quality) {\n"
        @"            Color += tex.sample(s, uv + float2(cos(d), sin(d)) * Radius * i).abg;\n"
        @"        }\n"
        @"    }\n"
        @"    Color /= Quality * Directions + 1.0;\n"
        @"    return Color;\n"
        @"}\n"
        @"\n"
        @"float2 rescale(float2 size, float2 texcoord) {\n"
        @"    float2 mask;\n"
        @"    mask.y = step(-size.y, texcoord.y) * step(texcoord.y, 0.0);\n"
        @"    mask.x = step(0.0, texcoord.x) * step(texcoord.x, size.x);\n"
        @"    return (1.0 - mask);\n"
        @"}\n"
        @"\n"
        @"half4 draw_circle(float2 texcoord_r, float2 texcoord, float2 position, float4 color, texture2d<half, access::sample> tex, float scales = 0.1f, float blur = 1.f, float radius = 1.f, float2 size = float2(1.f, 1.f), float aspx = 1.6f) {\n"
        @"    float2 sub = (texcoord - position);\n"
        @"    float2 res = rescale(size, sub) * float2(aspx, 1.f);\n"
        @"    sub -= float2(step(0.0, sub.x) * size.x, -step(sub.y, 0.0) * size.y);\n"
        @"    float2 diff = sub * res;\n"
        @"    float f = sqrt(dot(diff, diff) / radius);\n"
        @"    if (f > 0.65f) return half4(0,0,0, saturate((1.0 - f - 0.2)));\n"
        @"    float2 scale = float2(-scales, scales) * res;\n"
        @"    sub = mix(0.f, sub, abs(f));\n"
        @"    half3 texel1 = gblur(texcoord_r + sub * (fmod(0.56f-f, 0.6f)), tex, blur);\n"
        @"    half3 texel2 = gblur(texcoord_r + sub * (2.44f-(f+f)) * (scale*0.5f)*0.098f, tex, blur);\n"
        @"    half3 texel3 = gblur(texcoord_r + sub * (0.55f - f) * 0.18f * scale, tex, blur);\n"
        @"    half3 texel4 = gblur(texcoord_r + sub * (0.5f - f) * 0.8f * scale, tex, blur);\n"
        @"    half3 texel = (f > 0.58f) ? texel2 : texel3;\n"
        @"    texel += texel1 * saturate((f - 0.47) / 0.23) * max(texel1, texel);\n"
        @"    texel = mix(texel3, texel, saturate((f - 0.39) / 0.35)) * max(texel4, half3(0.9));\n"
        @"    texel *= mix(half3(1.f), half3(color.xyz), 1.f-color.w);\n"
        @"    texel += half3(color.xyz) * max(min(0.7f, (0.26f - f)), 0.4f) * 0.66f * color.w;\n"
        @"    return half4(texel, 1.f);\n"
        @"}\n"
        @"\n"
        @"half4 fragment fragmentMain(v2f in [[stage_in]],\n"
        @"    device const instance_data_t& instanceData [[buffer(0)]],\n"
        @"    texture2d<half, access::sample> tex [[texture(0)]])\n"
        @"{\n"
        @"    constexpr sampler s(address::repeat, filter::linear);\n"
        @"    float2 uv = in.position.xy * float2(instanceData.rtSize[0], instanceData.rtSize[1]) + float2(instanceData.position[0], instanceData.position[1]);\n"
        @"    half3 texel1 = tex.sample(s, uv).abg;\n"
        @"    half4 circles = draw_circle(uv, in.texcoord * 0.068f, float2(0,0), float4(1.f,1.f,1.f,0.8f), tex, -48.f, 2.f, 0.0125f, float2(0.f,0.f), 1.f);\n"
        @"    in.color = half3(mix(texel1, circles.rgb, circles.a));\n"
        @"    return half4(in.color, 1.0);\n"
        @"    return half4(texel1, 1.0);\n"
        @"}\n";



    NSError *error;
    MTLCompileOptions *opts = [[MTLCompileOptions alloc] init];
    

    id<MTLLibrary> shaderLib = [pMetalDevice newLibraryWithSource:shaderCode  options:opts  error:&error];
        
    id<MTLFunction> vertexFunction = [shaderLib newFunctionWithName:@"vertexMain"];
    id<MTLFunction> fragmentFunction = [shaderLib newFunctionWithName:@"fragmentMain"];

    MTLRenderPipelineDescriptor* renderPipelineDescriptor = [ [MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.label = @"liquidarse";
    renderPipelineDescriptor.vertexFunction = vertexFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTL_TAHOE_FORMAT;



    NSError *error2;

    uiGlassShader = [pMetalDevice newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error2];
    uiGlassInstanceData = [pMetalDevice newBufferWithLength:sizeof(TAHOE_instance_data_t) options:MTLResourceStorageModeShared ];

}


void updatePrismData(CALayer *layer) {
    //uiGlassInstanceDataCPU.position_x = layer.position.x;
    //uiGlassInstanceDataCPU.position_y = layer.position.y;

    uiGlassInstanceDataCPU.position_y = 0.65f;
    uiGlassInstanceDataCPU.position_x = 0.45f;

    uiGlassInstanceDataCPU.rtSize_x = 1.f/768.f; //(1.f/layer.bounds.size.width);
    uiGlassInstanceDataCPU.rtSize_y = 1.f/768.f; //(1.f/layer.bounds.size.height);


    memcpy( uiGlassInstanceData.contents, &uiGlassInstanceDataCPU, sizeof(TAHOE_instance_data_t) );
}
// Instead of using renderInContext (which cannot capture live blur/vibrancy/compositing effects),
// use iOS's snapshotting APIs to get the real screen content as seen by the user (including all blur, vibrancy, overlays, etc).
// This grabs the full screen as the user sees it and uploads it to the Metal texture.

void renderPrismBackdrop(CALayer *layer) {
    CGSize size = CGSizeMake(layer.bounds.size.width, layer.bounds.size.height);
    if (size.width < 1 || size.height < 1) return;

    
    @autoreleasepool {
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor new];
        // Set dimensions
        textureDescriptor.width = (NSUInteger)size.width;
        textureDescriptor.height = (NSUInteger)size.height;
        textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
        textureDescriptor.textureType = MTLTextureType2D;
        textureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        textureDescriptor.storageMode = MTLStorageModeShared;
        
        // 2. Create the MTLTexture
        uiGlassBackdropTexture = [pMetalDevice newTextureWithDescriptor:textureDescriptor];

    }

    NSUInteger width = (NSUInteger)size.width;
    NSUInteger height = (NSUInteger)size.height;
    NSUInteger bytesPerRow = width * 4;

    // 1. Get the main SpringBoard window (root window) for a true screen snapshot
    UIWindow *mainWindow = nil;
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if ([NSStringFromClass([window class]) isEqualToString:@"SBMainDisplayWindow"]) {
            mainWindow = window;
            break;
        }
    }
    if (!mainWindow) {
        mainWindow = [UIApplication sharedApplication].keyWindow ?: [UIApplication sharedApplication].windows.firstObject;
    }
    if (!mainWindow) return;

    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [mainWindow drawViewHierarchyInRect:CGRectMake(0, 0, size.width, size.height) afterScreenUpdates:NO];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (!snapshot) return;

    // 2. Get raw pixel data from the snapshot
    CGImageRef cgImage = snapshot.CGImage;
    if (!cgImage) return;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *pTextureData = calloc(height, bytesPerRow);
    CGContextRef context = CGBitmapContextCreate(pTextureData, width, height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host);

    if (context) {
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        [uiGlassBackdropTexture replaceRegion:region mipmapLevel:0 withBytes:pTextureData bytesPerRow:bytesPerRow];

        CGContextRelease(context);
    }
    CGColorSpaceRelease(colorSpace);
    free(pTextureData);

}

void renderPrism(CAMetalLayer *metalLayer) {

    id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
    if (!drawable) return;

    updatePrismData(metalLayer);

    MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = drawable.texture;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0,0,0,0);

    id<MTLCommandBuffer> cmd = [pMetalCommandQueue commandBuffer];
    id<MTLRenderCommandEncoder> enc = [cmd renderCommandEncoderWithDescriptor:pass];


    [enc setRenderPipelineState:uiGlassShader];

    [enc setFragmentTexture:uiGlassBackdropTexture atIndex:0];
    [enc setFragmentBuffer:uiGlassInstanceData offset:0 atIndex:0 ];


    [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [enc endEncoding];

    [cmd presentDrawable:drawable];
    [cmd commit];
}

NSMutableArray<CALayer *> *prismLayers = nil;
void startPrismUpdates(CALayer *layer) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        prismLayers = [NSMutableArray array];
        // Timer to render all layers sequentially
        [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer * _Nonnull timer) {
            for (CAMetalLayer *l in prismLayers) {
                renderPrism(l);
            }
        }];
    });

    // Prevent duplicate entries
    BOOL alreadyExists = NO;
    for (CALayer *existingLayer in prismLayers) {
        if (existingLayer == layer) {
            alreadyExists = YES;
            break;
        }
    }
    if (!alreadyExists) {
        [prismLayers addObject:layer];
    }
}


void applyPrismToLayer(CALayer *layer) {
    CAMetalLayer *metalLayer = nil;

    for (CALayer *sublayer in layer.sublayers) {
        if ([sublayer.name isEqualToString:@"iOS26PrismBorder"] && [sublayer isKindOfClass:[CAMetalLayer class]]) {
            metalLayer = (CAMetalLayer *)sublayer;
            break;
        }
    }

    if (!pMetalDevice) {
        initMetalDevice();
        
        [NSTimer scheduledTimerWithTimeInterval:0.02 repeats:YES block:^(NSTimer * _Nonnull timer) {
            renderPrismBackdrop(layer);
        }];
    }

    if (!metalLayer) {
        metalLayer = [CAMetalLayer layer];
        metalLayer.name = @"iOS26PrismBorder";
        metalLayer.contentsScale = [UIScreen mainScreen].scale;

        metalLayer.device = pMetalDevice;
        metalLayer.pixelFormat = MTL_TAHOE_FORMAT;
        metalLayer.framebufferOnly = YES;
        
        [layer insertSublayer:metalLayer atIndex:0];

        
        startPrismUpdates(metalLayer);
    }
    else {
        
        //        renderPrismBackdrop(layer);
         //       renderPrism(metalLayer);
        // this will be our main update logic

      //  metalLayer.hidden = YES;
        renderPrismBackdrop(metalLayer);
     //   metalLayer.hidden = NO;

      //  renderPrism(metalLayer);
      
    }

    metalLayer.frame = layer.bounds;
    metalLayer.masksToBounds = YES;
    metalLayer.cornerRadius = layer.cornerRadius;
}


%group CC26
%hook MTMaterialLayer
- (void)_configureIfNecessaryWithSettingsInterpolator:(MTMaterialSettingsInterpolator *)interpolator {
    %orig;
    NSArray *allowedAncestors = @[@"CCUIModularControlCenterOverlayViewController", @"MRUControlCenterViewController", @"CCUIContentModuleContainerViewController", @"FCCCControlCenterModule"];
    UIView *parentView = (UIView *)self.delegate;
    if ([allowedAncestors containsObject:NSStringFromClass([[parentView _viewControllerForAncestor] class])]) { // Hopefully fix crashes in other parts of SpringBoard or apps that load MaterialKit bundle via SpringBoard
        id<MTRecipeMaterialSettingsProviding> settings = interpolator.finalSettings;
        id base = [settings baseMaterialSettings];
        if (![base respondsToSelector:@selector(setValue:forKey:)]) return;

        if ([self.recipeName isEqualToString:@"modules"]) {
            [base setValue:@(-0.54) forKey:@"brightness"];
            [base setValue:@(2.6) forKey:@"blurRadius"];
            [base setValue:@(-0.045) forKey:@"zoom"];
            [base setValue:@(1.8) forKey:@"saturation"];
            [base setValue:@(1.0) forKey:@"luminanceAmount"];
        } else if ([self.recipeName isEqualToString:@"modulesBackground"]) {
         //   [base setValue:@(0.0) forKey:@"zoom"];
        //    [base setValue:@(4.3) forKey:@"blurRadius"];
            [base setValue:@(-0.14) forKey:@"brightness"];
            [base setValue:@(1.1) forKey:@"saturation"];
        } else if ([self.recipeName isEqualToString:@"auxiliary"]) {
            [base setValue:@(2.3) forKey:@"blurRadius"];
        }

    }
}
- (void)layoutSublayers {
    %orig;
    NSArray<NSString *> *titles = @[@"modules", @"moduleFill.highlight.generatedRecipe"];
    NSArray *allowedAncestors = @[@"CCUIModularControlCenterOverlayViewController", @"MRUControlCenterViewController", @"CCUIContentModuleContainerViewController", @"FCCCControlCenterModule"];
    UIView *parentView = (UIView *)self.delegate;
    if ([titles containsObject:self.recipeName]) {
        if ([allowedAncestors containsObject:NSStringFromClass([[parentView _viewControllerForAncestor] class])]) {
            // !!!!! IMPORTANT !!!!!!!
            applyPrismToLayer(self);
        }
    }
}
%end

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

%hook CCUIBaseSliderView
%property (nonatomic, retain) UIImageView *cc26GlyphImageView;
- (void)setGlyphVisible:(BOOL)visible {
    %orig(colorSliderGlyphs ? NO : visible);
}
- (void)didMoveToWindow {
    %orig;
    if (colorSliderGlyphs) {
        [self setGlyphVisible:NO];

        UIColor *tintColor;
        if ([[self _viewControllerForAncestor] isKindOfClass:%c(MRUVolumeViewController)]) {
            NSDictionary *volumeColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"volumeColorDict" inDomain:domain];
            tintColor = (volumeColorDict != nil) ? [UIColor colorWithRed:[volumeColorDict[@"red"] floatValue] green:[volumeColorDict[@"green"] floatValue] blue:[volumeColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor colorWithRed:0.35 green:0.67 blue:0.88 alpha:1.00];
        } else if ([[self _viewControllerForAncestor] isKindOfClass:%c(CCUIDisplayModuleViewController)]) {
            NSDictionary *brightnessColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"brightnessColorDict" inDomain:domain];
            tintColor = (brightnessColorDict != nil) ? [UIColor colorWithRed:[brightnessColorDict[@"red"] floatValue] green:[brightnessColorDict[@"green"] floatValue] blue:[brightnessColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor colorWithRed:0.96 green:0.81 blue:0.27 alpha:1.00];
        }

        if (!self.cc26GlyphImageView) self.cc26GlyphImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.cc26GlyphImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.cc26GlyphImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.cc26GlyphImageView.tintColor = tintColor;
        self.cc26GlyphImageView.center = self.glyphCenter;
        [self addSubview:self.cc26GlyphImageView];

        [self cc26_setGlyphValue:self.value];

        [NSLayoutConstraint activateConstraints:@[
            [self.cc26GlyphImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.cc26GlyphImageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-24],
            [self.cc26GlyphImageView.widthAnchor constraintEqualToConstant:40],
            [self.cc26GlyphImageView.heightAnchor constraintEqualToConstant:40]
        ]];
    }
}
- (void)setValue:(float)value {
    %orig;
    if (colorSliderGlyphs) {
        [self cc26_setGlyphValue:value];
    }
}
%new
- (void)cc26_setGlyphValue:(float)value {
    CGFloat sliderValue = value * 100;
    if ([[self _viewControllerForAncestor] isKindOfClass:%c(MRUVolumeViewController)]) {
        UIImage *icon;
        if (sliderValue == 0) {
            icon = [UIImage systemImageNamed:@"speaker.slash.fill"];
        } else if (sliderValue >= 0 && sliderValue <= 39) {
            icon = [UIImage systemImageNamed:@"speaker.wave.1.fill"];
        } else if (sliderValue >= 40 && sliderValue <= 69) {
            icon = [UIImage systemImageNamed:@"speaker.wave.2.fill"];
        } else {
            icon = [UIImage systemImageNamed:@"speaker.wave.3.fill"];
        }
        [self.cc26GlyphImageView setImage:icon];
    } else if ([[self _viewControllerForAncestor] isKindOfClass:%c(CCUIDisplayModuleViewController)]) {
        UIImage *icon;
        if (sliderValue >= 0 && sliderValue <= 39) {
            icon = [UIImage systemImageNamed:@"sun.min.fill"];
        } else if (sliderValue >= 40 && sliderValue <= 69) {
            icon = [UIImage systemImageNamed:@"sun.max.fill"];
        } else {
            icon = [UIImage systemImageNamed:@"sun.max.fill"];
        }
        [self.cc26GlyphImageView setImage:icon];
    }
}
%end

%hook MRUNowPlayingView
void adjustLabelFontsInView(UIView *view) {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
            label.adjustsFontSizeToFitWidth = YES;
            label.minimumScaleFactor = 0.8;
        } else {
            adjustLabelFontsInView(subview);
        }
    }
}
static BOOL cc26LayoutInProgress = NO;
- (void)layoutSubviews {
    %orig;

    // 🔁 Schutz vor rekursivem Layout
    if (cc26LayoutInProgress) return;
    cc26LayoutInProgress = YES;

    // Verhindere Änderungen außerhalb des Control Centers
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
        cc26LayoutInProgress = NO;
        return;
    }

    id layoutValue = nil;
    @try {
        layoutValue = [self valueForKey:@"_layout"];
    } @catch (NSException *e) {
        NSLog(@"[CC26] Exception beim Zugriff auf _layout: %@", e);
    }

    if ([layoutValue isKindOfClass:[NSNumber class]]) {
        NSInteger layout = [(NSNumber *)layoutValue integerValue];
        if (layout == 2 || layout == 1) {
            cc26LayoutInProgress = NO;
            return;
        }
    } else if (layoutValue != nil) {
        NSLog(@"[CC26] Unexpected type for _layout: %@", NSStringFromClass([layoutValue class]));
    }

    @try {
        UIView *artworkView = findSubviewOfClass(self, %c(MRUArtworkView));
        if (!artworkView || ![artworkView isKindOfClass:[UIView class]]) {
            cc26LayoutInProgress = NO;
            return;
        }

        CGFloat moduleWidth = self.bounds.size.width;
        CGFloat moduleHeight = self.bounds.size.height;

        CGFloat artworkSize = MIN(moduleWidth, moduleHeight) * 0.32;
        CGFloat artworkX = moduleWidth * 0.12;
        CGFloat artworkY = moduleHeight * 0.08;

        if ([artworkView respondsToSelector:@selector(setFrame:)]) {
            artworkView.translatesAutoresizingMaskIntoConstraints = YES;
            artworkView.frame = CGRectMake(artworkX, artworkY, artworkSize, artworkSize);
            artworkView.bounds = CGRectMake(artworkX, artworkY, artworkSize, artworkSize);
            artworkView.alpha = 1.0;
            artworkView.layer.cornerRadius = artworkSize * 0.3;
            artworkView.layer.masksToBounds = YES;
        }

        UIView *headerView = findSubviewOfClass(self, %c(MRUNowPlayingHeaderView));
        if (!headerView || ![headerView isKindOfClass:[UIView class]]) {
            cc26LayoutInProgress = NO;
            return;
        }

        CGFloat headerX = moduleWidth * 0.04;
        CGFloat headerY = CGRectGetMaxY(artworkView.frame) + moduleHeight * 0.04;
        CGFloat headerWidth = moduleWidth * 0.92;
        CGFloat headerHeight = moduleHeight * 0.3;

        headerView.frame = CGRectMake(headerX, headerY, headerWidth, headerHeight);

        // 🎯 TextAlignment setzen – differenziert nach iOS-Version
        if (@available(iOS 16.0, *)) {
            @try {
                [headerView setValue:@(NSTextAlignmentLeft) forKey:@"textAlignment"];
            } @catch (NSException *e) {
                NSLog(@"[CC26] KVC set textAlignment failed: %@", e);
            }
        } else {
            UIView *labelView = findSubviewOfClass(headerView, %c(MRUNowPlayingLabelView));
            if (labelView && [labelView respondsToSelector:@selector(setLayout:)]) {
                @try {
                    [labelView setValue:@(2) forKey:@"layout"];
                } @catch (NSException *e) {
                    NSLog(@"[CC26] KVC set layout failed: %@", e);
                }
            }
        }

        if (headerView) {
            @try {
                adjustLabelFontsInView(headerView);
            } @catch (NSException *e) {
                NSLog(@"[CC26] adjustLabelFontsInView failed: %@", e);
            }
        }

        UIView *transportControlsView = findSubviewOfClass(self, %c(MRUNowPlayingTransportControlsView));
        if (transportControlsView && [transportControlsView isKindOfClass:[UIView class]]) {
            CGFloat controlsWidth = transportControlsView.frame.size.width;
            CGFloat controlsHeight = transportControlsView.frame.size.height;

            CGFloat x = (moduleWidth - controlsWidth) / 2.0;
            CGFloat y = moduleHeight - controlsHeight - moduleHeight * 0.05;

            transportControlsView.frame = CGRectMake(x, y, controlsWidth, controlsHeight);
        }
    } @catch (NSException *e) {
        NSLog(@"[CC26] MRUNowPlayingView safe fallback: %@", e);
    }

    cc26LayoutInProgress = NO;
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
        MRUNowPlayingView *npView = (MRUNowPlayingView *)self.superview;
        if (![npView isKindOfClass:%c(MRUNowPlayingView)]) return;

        NSInteger layout = [[npView valueForKey:@"_layout"] integerValue];
        if (layout == 2) return;

        UIButton *leftButton = [self valueForKey:@"leftButton"];
        UIButton *rightButton = [self valueForKey:@"rightButton"];
        UIButton *centerButton = [self valueForKey:@"centerButton"];

        if (leftButton && rightButton && centerButton) {
            CGPoint center = centerButton.center;
            CGFloat spacing = 40.0;

            leftButton.center = CGPointMake(center.x - spacing, center.y);
            rightButton.center = CGPointMake(center.x + spacing, center.y);
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

            if (@available(iOS 14.0, *)) {
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
}

%ctor {
    loadPreferences(NULL, NULL, NULL, NULL, NULL); // Load prefs
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, loadPreferences, (CFStringRef)preferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    if (enabled) {
        %init(CC26)
    }
}

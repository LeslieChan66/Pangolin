#import "PangolinPlugin.h"
#import <BUAdSDK/BUAdSDK.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>
@interface PangolinPlugin ()<BUNativeExpressRewardedVideoAdDelegate,BUSplashAdDelegate,
BUNativeAdsManagerDelegate,BUVideoAdViewDelegate,BUNativeAdDelegate,
BUNativeExpressAdViewDelegate,
BUNativeExpressFullscreenVideoAdDelegate,
BUNativeExpresInterstitialAdDelegate,
BUBannerAdViewDelegate>
@property (nonatomic, strong) UITextField *playableUrlTextView;
@property (nonatomic, strong) UITextField *downloadUrlTextView;
@property (nonatomic, strong) UITextField *deeplinkUrlTextView;
@property (nonatomic, strong) UILabel *isLandscapeLabel;
@property (nonatomic, strong) UISwitch *isLandscapeSwitch;
@property (nonatomic, assign) BOOL isPlayableUrlValid;
@property (nonatomic, assign) BOOL isDownloadUrlValid;
@property (nonatomic, assign) BOOL isDeeplinkUrlValid;

@property(nonatomic, copy) NSDictionary *sizeDcit;

@property (nonatomic, strong) BURewardedVideoAd *rewardedVideoAd;
@property (nonatomic, strong) BUNativeExpressRewardedVideoAd *rewardedAd;
@property(nonatomic, strong) BUNativeExpressBannerView *bannerView;
@property (nonatomic, strong) BUNativeExpressInterstitialAd *interstitialAd;

@end

@implementation PangolinPlugin

FlutterMethodChannel* globalMethodChannel;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"com.tongyangsheng.pangolin"
                                     binaryMessenger:[registrar messenger]];
    PangolinPlugin* instance = [[PangolinPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    globalMethodChannel = channel;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"register" isEqualToString:call.method]) {
        NSString* appId = call.arguments[@"appId"];
        if ([@"" isEqualToString:appId]) {
            result([FlutterError errorWithCode:@"500" message:@"appId can't be null" details:nil]);
        }
        [BUAdSDKManager setAppID:appId];
        result(@YES);
    }
    else if([@"loadSplashAd" isEqualToString:call.method])
    {
        if (@available(iOS 14, *)) {
            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            }];
        } else {
            // Fallback on earlier versions
        }
        NSString* mCodeId = call.arguments[@"mCodeId"];
        [BUAdSDKManager setIsPaidApp:NO];
        [BUAdSDKManager setLoglevel:BUAdSDKLogLevelDebug];
        CGRect mainframe = [UIScreen mainScreen].bounds;
        CGRect splashFrame = CGRectMake(0, 0, mainframe.size.width, mainframe.size.height - 120);
        
        // footer Container Height 120
        UIView *view = [[UIView alloc] init];
        view.frame = CGRectMake(0, mainframe.size.height - 120, mainframe.size.width, 120);
        view.backgroundColor = [UIColor whiteColor];
        UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
        [keyWindow.rootViewController.view addSubview:view];

        // Footer
        UIImageView *logoView = [[UIImageView alloc] init];
        logoView.frame = CGRectMake(mainframe.size.width * 1 / 4, mainframe.size.height - 97.5, 65, 65);
        logoView.image = [UIImage imageNamed:@"logo"];

        UIImageView *textView = [[UIImageView alloc] init];
        textView.frame = CGRectMake(mainframe.size.width * 3 / 4 - 110, mainframe.size.height - 80, 110, 40);
        textView.image = [UIImage imageNamed:@"newbie_text"];
        
        BUSplashAdView *splashView = [[BUSplashAdView alloc] initWithSlotID:mCodeId frame:splashFrame];
        splashView.delegate = self;
        splashView.tolerateTimeout = 5;

    

        [keyWindow.rootViewController.view addSubview:textView];
        [keyWindow.rootViewController.view addSubview:logoView];

        [splashView loadAdData];
        [keyWindow.rootViewController.view addSubview:splashView];
        splashView.rootViewController = keyWindow.rootViewController;
    }
    else if([@"loadRewardAd" isEqualToString:call.method])
    {
        NSLog(@"激励视频加载");
        NSString* slotId = call.arguments[@"mCodeId"];
        NSString* userId = call.arguments[@"userID"];
        NSString* rewardName = call.arguments[@"rewardName"];
        NSString* mediaExtra = call.arguments[@"mediaExtra"];
        
        BURewardedVideoModel *model = [[BURewardedVideoModel alloc] init];
        model.userId = userId;
        model.rewardName = rewardName;
        model.extra=mediaExtra;
        
        self.rewardedAd = [[BUNativeExpressRewardedVideoAd alloc] initWithSlotID:slotId rewardedVideoModel:model];
        self.rewardedAd.delegate = self;
        [self.rewardedAd loadAdData];
        result(@YES);
    }
    else if([@"loadBannerAd" isEqualToString:call.method]){
        
        NSString* mCodeId = call.arguments[@"mCodeId"];
        NSNumber* expressViewWidth = call.arguments[@"expressViewWidth"];
        NSNumber* expressViewHeight = call.arguments[@"expressViewHeight"];
        NSNumber* isCarousel = call.arguments[@"isCarousel"];
        NSNumber* interval = call.arguments[@"interval"];
        
        UIViewController* rootVC = [self getRootViewController];
        
        
        NSValue *sizeValue = [NSValue valueWithCGSize:CGSizeMake(expressViewWidth.floatValue, expressViewHeight.floatValue)];
        CGSize size = [sizeValue CGSizeValue];
        CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat bannerHeigh = screenWidth/size.width*size.height;
        
        if (isCarousel == 0) {
            self.bannerView = [[BUNativeExpressBannerView alloc] initWithSlotID:mCodeId rootViewController:rootVC adSize:CGSizeMake(screenWidth, bannerHeigh) IsSupportDeepLink:YES];
        }
        else
        {
            self.bannerView = [[BUNativeExpressBannerView alloc] initWithSlotID:mCodeId rootViewController:rootVC adSize:CGSizeMake(screenWidth, bannerHeigh) IsSupportDeepLink:YES interval:interval.intValue];
        }
        
        self.bannerView.delegate = self;
        
        self.bannerView.frame = CGRectMake(0, rootVC.view.bounds.size.height-bannerHeigh, screenWidth, bannerHeigh);
        [self.bannerView loadAdData];
        [rootVC.view addSubview:self.bannerView];
    }
    else if([@"loadInterstitialAd" isEqualToString:call.method])
    {
        NSLog(@"111");
        NSString* mCodeId = call.arguments[@"mCodeId"];
        NSNumber* expressViewWidth = call.arguments[@"expressViewWidth"];
        NSNumber* expressViewHeight = call.arguments[@"expressViewHeight"];
        
        NSLog(@"渲染高度%@",expressViewHeight);
        
        NSValue *sizeValue = [NSValue valueWithCGSize:CGSizeMake(expressViewWidth.floatValue, expressViewHeight.floatValue)];
        CGSize size = [sizeValue CGSizeValue];
        CGFloat width = CGRectGetWidth([UIScreen mainScreen].bounds)-40;
        CGFloat height = width/size.width*size.height;
        
        self.interstitialAd = [[BUNativeExpressInterstitialAd alloc] initWithSlotID:mCodeId adSize:CGSizeMake(width, height)];
        self.interstitialAd.delegate = self;
        [self.interstitialAd loadAdData];
    }
    else
    {
        result(FlutterMethodNotImplemented);
    }
}

//展示视频用
- (UIViewController *)rootViewController{
    UIViewController *rootVC = [[UIApplication sharedApplication].delegate window].rootViewController;
    
    UIViewController *parent = rootVC;
    while((parent = rootVC.presentingViewController) != nil){
        rootVC = parent;
    }
    
    while ([rootVC isKindOfClass:[UINavigationController class]]) {
        rootVC = [(UINavigationController *)rootVC topViewController];
    }
    
    return rootVC;
}

// 激励视频加载完成
- (void)nativeExpressRewardedVideoAdDidLoad:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    NSLog(@"激励视频加载完成");
    [self.rewardedAd showAdFromRootViewController: [self rootViewController]];
}

//激励视频渲染完成并展示
- (void)nativeExpressRewardedVideoAdViewRenderSuccess:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    NSLog(@"激励视频渲染完成展示");
    [self.rewardedAd showAdFromRootViewController: [self rootViewController]];
    
}

//激励视频播放完成
- (void)nativeExpressRewardedVideoAdDidPlayFinish:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *_Nullable)error {
    NSLog(@"激励视频播放完成");
    NSMutableDictionary *mutableDictionary=[NSMutableDictionary dictionaryWithCapacity:3];
    [mutableDictionary setValue:@YES forKey:@"rewardVerify"];
    [mutableDictionary setValue:NULL forKey:@"rewardAmount"];
    [mutableDictionary setValue:NULL forKey:@"rewardName"];
    
    [globalMethodChannel invokeMethod:@"onRewardResponse" arguments:mutableDictionary];
}

- (void)nativeExpressRewardedVideoAdServerRewardDidSucceed:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd verify:(BOOL)verify {
    
}

//激励视频关闭
- (void)nativeExpressRewardedVideoAdDidClose:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    
}

//开屏视频关闭
- (void)splashAdDidClose:(BUSplashAdView *)splashAd {
    [splashAd removeFromSuperview];
    for(UIView *view in [self.getRootViewController.view subviews])
    {
        [view removeFromSuperview];
    }
}

//开屏广告加载失败
- (void)splashAd:(BUSplashAdView *)splashAd didFailWithError:(NSError * _Nullable)error {
    [splashAd removeFromSuperview];
    for(UIView *view in [self.getRootViewController.view subviews])
    {
        [view removeFromSuperview];
    }
}

#pragma BUNativeExpressBannerViewDelegate
- (void)nativeExpressBannerAdViewDidLoad:(BUNativeExpressBannerView *)bannerAdView {
}

- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView didLoadFailWithError:(NSError *)error {
    NSLog(@"error code : %ld , error message : %@",(long)error.code,error.description);
}

- (void)nativeExpressBannerAdViewRenderSuccess:(BUNativeExpressBannerView *)bannerAdView {
    NSLog(@"%s",__func__);
}

- (void)nativeExpressBannerAdViewRenderFail:(BUNativeExpressBannerView *)bannerAdView error:(NSError *)error {
    NSLog(@"%s",__func__);
}

- (void)nativeExpressBannerAdViewWillBecomVisible:(BUNativeExpressBannerView *)bannerAdView {
    NSLog(@"%s",__func__);
}

- (void)nativeExpressBannerAdViewDidClick:(BUNativeExpressBannerView *)bannerAdView {
    NSLog(@"%s",__func__);
}

- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView dislikeWithReason:(NSArray<BUDislikeWords *> *)filterwords {
    [UIView animateWithDuration:0.25 animations:^{
        bannerAdView.alpha = 0;
    } completion:^(BOOL finished) {
        [bannerAdView removeFromSuperview];
        self.bannerView = nil;
    }];
}

- (void)nativeExpressBannerAdViewDidCloseOtherController:(BUNativeExpressBannerView *)bannerAdView interactionType:(BUInteractionType)interactionType {
    NSString *str = nil;
    if (interactionType == BUInteractionTypePage) {
        str = @"ladingpage";
    } else if (interactionType == BUInteractionTypeVideoAdDetail) {
        str = @"videoDetail";
    } else {
        str = @"appstoreInApp";
    }
}

#pragma ---BUNativeExpresInterstitialAdDelegate
- (void)nativeExpresInterstitialAdDidLoad:(BUNativeExpressInterstitialAd *)interstitialAd {
    NSLog(@"%s",__func__);
}

- (void)nativeExpresInterstitialAd:(BUNativeExpressInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    NSLog(@"加载失败");
    NSLog(@"%s",__func__);
}

- (void)nativeExpresInterstitialAdRenderSuccess:(BUNativeExpressInterstitialAd *)interstitialAd {
    UIViewController* rootVC = [self getRootViewController];
    [self.interstitialAd showAdFromRootViewController:rootVC];
    NSLog(@"%s",__func__);
}

- (void)nativeExpresInterstitialAdRenderFail:(BUNativeExpressInterstitialAd *)interstitialAd error:(NSError *)error {
    NSLog(@"%s",__func__);
    NSLog(@"error code : %ld , error message : %@",(long)error.code,error.description);
}

- (void)nativeExpresInterstitialAdWillVisible:(BUNativeExpressInterstitialAd *)interstitialAd {
    NSLog(@"%s",__func__);
}

- (void)nativeExpresInterstitialAdDidClick:(BUNativeExpressInterstitialAd *)interstitialAd {
    NSLog(@"%s",__func__);
}

- (void)nativeExpresInterstitialAdWillClose:(BUNativeExpressInterstitialAd *)interstitialAd {
    NSLog(@"%s",__func__);
}

- (void)nativeExpresInterstitialAdDidClose:(BUNativeExpressInterstitialAd *)interstitialAd {
    NSLog(@"%s",__func__);
}

- (void)nativeExpresInterstitialAdDidCloseOtherController:(BUNativeExpressInterstitialAd *)interstitialAd interactionType:(BUInteractionType)interactionType {
    NSString *str = nil;
    if (interactionType == BUInteractionTypePage) {
        str = @"ladingpage";
    } else if (interactionType == BUInteractionTypeVideoAdDetail) {
        str = @"videoDetail";
    } else {
        str = @"appstoreInApp";
    }
    NSLog(@"%s __ %@",__func__,str);
}




//获取根控制器

- (UIViewController *)getRootViewController{
    
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    NSAssert(window, @"The window is empty");
    return window.rootViewController;
}


- (UIViewController *)currentViewController
{
    UIWindow *keyWindow  = [UIApplication sharedApplication].keyWindow;
    UIViewController *vc = keyWindow.rootViewController;
    while (vc.presentedViewController)
    {
        vc = vc.presentedViewController;
        
        if ([vc isKindOfClass:[UINavigationController class]])
        {
            vc = [(UINavigationController *)vc visibleViewController];
        }
        else if ([vc isKindOfClass:[UITabBarController class]])
        {
            vc = [(UITabBarController *)vc selectedViewController];
        }
    }
    return vc;
}

@end






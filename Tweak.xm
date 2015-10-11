#import <UIKit/UIKit.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <substrate.h>
#import "UIImage+ImageEffects.m"

@interface SBBannerContextView : UIView
-(UIView*)pullDownView;
@end

@interface SBBannerContainerView : UIView
@end

@interface SBBannerContainerViewController
@end

@interface SBFAnimationFactory
@end

@interface SBReachabilitySettings
-(CGFloat)yOffsetFactor;
@end

static BOOL enabled = NO;
static BOOL stayPut = YES;
static SBReachabilitySettings * sett = nil;

// for iOS9
%hook SBMainWorkspace

-(void)handleReachabilityModeActivated {
	%orig;
	NSLog(@"[BannerBuddy]Activating reachability, shifting banners down.");
	[self shiftBannersDown];
}

-(void)handleReachabilityModeDeactivated {
	%orig;
	NSLog(@"[BannerBuddy]Deactivating reachability, shifting banners up.");
	[self shiftBannersUp];
}

-(void)handleCancelReachabilityRecognizer:(id)arg{
	%orig;
	NSLog(@"[BannerBuddy]Deactivating reachability via tap, shifting banners up.");
	[self shiftBannersUp];
}

%new - (void)shiftBannersUp{

	SBBannerController * controller = [%c(SBBannerController) sharedInstance];

	if([controller isShowingBanner] && enabled && !stayPut)
	{
		NSLog(@"[BannerBuddy]Reachability is deactivating, banner is showing, tweak enabled, and user wants dynamic banners.");
		SBBannerContainerViewController * vc = MSHookIvar<SBBannerContainerViewController*>(controller,"_bannerViewController");
		SBBannerContainerView * cv = MSHookIvar<SBBannerContainerView*>(vc,"_containerView");

		CGRect dynamicRect = CGRectMake(cv.frame.origin.x,0,cv.frame.size.width,cv.frame.size.height);

		[%c(BSUIAnimationFactory) animateWithFactory:[sett animationFactory] actions:^{
			cv.frame = dynamicRect;
		} completion:^(BOOL finished){
		}];
	}
	else
	{
		NSLog(@"[BannerBuddy]Not raising->enabled: %ld, stayPut: %ld, isShowing: %ld",(long)enabled, (long)stayPut, (long)[controller isShowingBanner]);
	}
}

%new - (void)shiftBannersDown{

    SBBannerController * controller = [%c(SBBannerController) sharedInstance];

	if([controller isShowingBanner] && enabled)
	{
		NSLog(@"[BannerBuddy]Reachability is active, tweak is enabled, and banner is showing.");
		SBBannerContainerViewController * vc = MSHookIvar<SBBannerContainerViewController*>(controller,"_bannerViewController");
		SBBannerContainerView * cv = MSHookIvar<SBBannerContainerView*>(vc,"_containerView");

		CGFloat newY = [[UIScreen mainScreen] bounds].size.height * [sett yOffsetFactor];
		CGRect dynamicRect = CGRectMake(cv.frame.origin.x,newY,cv.frame.size.width,cv.frame.size.height);

		NSLog(@"STUFF: %@ %@ %@", NSStringFromCGRect(dynamicRect), vc, cv);

		[%c(BSUIAnimationFactory) animateWithFactory:[sett animationFactory] actions:^{
			cv.frame = dynamicRect;
		} completion:^(BOOL finished){
		}];
	}
	else
	{
		NSLog(@"[BannerBuddy]Not lowering ->enabled: %ld, stayPut: %ld, isShowing: %ld",(long)enabled, (long)stayPut, (long)[controller isShowingBanner]);
	}
}

%end

%hook SBWorkspace

-(void)handleReachabilityModeActivated {
	%orig;
	NSLog(@"[BannerBuddy]Activating reachability, shifting banners down.");
	[self shiftBannersDown];
}

-(void)handleReachabilityModeDeactivated {
	%orig;
	NSLog(@"[BannerBuddy]Deactivating reachability, shifting banners up.");
	[self shiftBannersUp];
}

-(void)handleCancelReachabilityRecognizer:(id)arg{
	%orig;
	NSLog(@"[BannerBuddy]Deactivating reachability via tap, shifting banners up.");
	[self shiftBannersUp];
}

%new - (void)shiftBannersUp{

	SBBannerController * controller = [%c(SBBannerController) sharedInstance];

	if([controller isShowingBanner] && enabled && !stayPut)
	{
		NSLog(@"[BannerBuddy]Reachability is deactivating, banner is showing, tweak enabled, and user wants dynamic banners.");
		SBBannerContainerViewController * vc = MSHookIvar<SBBannerContainerViewController*>(controller,"_bannerViewController");
		SBBannerContainerView * cv = MSHookIvar<SBBannerContainerView*>(vc,"_containerView");

		CGRect dynamicRect = CGRectMake(cv.frame.origin.x,0,cv.frame.size.width,cv.frame.size.height);

		[%c(SBFAnimationFactory) animateWithFactory:[sett animationFactory] actions:^{
			cv.frame = dynamicRect;
		} completion:^(BOOL finished){
		}];
	}
	else
	{
		NSLog(@"[BannerBuddy]Not raising->enabled: %ld, stayPut: %ld, isShowing: %ld",(long)enabled, (long)stayPut, (long)[controller isShowingBanner]);
	}
}

%new - (void)shiftBannersDown{

    SBBannerController * controller = [%c(SBBannerController) sharedInstance];

	if([controller isShowingBanner] && enabled)
	{
		NSLog(@"[BannerBuddy]Reachability is active, tweak is enabled, and banner is showing.");
		SBBannerContainerViewController * vc = MSHookIvar<SBBannerContainerViewController*>(controller,"_bannerViewController");
		SBBannerContainerView * cv = MSHookIvar<SBBannerContainerView*>(vc,"_containerView");

		CGFloat newY = [[UIScreen mainScreen] bounds].size.height * [sett yOffsetFactor];
		CGRect dynamicRect = CGRectMake(cv.frame.origin.x,newY,cv.frame.size.width,cv.frame.size.height);

		[%c(SBFAnimationFactory) animateWithFactory:[sett animationFactory] actions:^{
			cv.frame = dynamicRect;
		} completion:^(BOOL finished){
		}];
	}
	else
	{
		NSLog(@"[BannerBuddy]Not lowering ->enabled: %ld, stayPut: %ld, isShowing: %ld",(long)enabled, (long)stayPut, (long)[controller isShowingBanner]);
	}
}

%end

%hook SBBannerContainerView

-(void)layoutSubviews{
	%orig;

	if([[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive] && enabled)
	{
		NSLog(@"[BannerBuddy]Received a new banner while reachability was active.");
		CGFloat newY = [[UIScreen mainScreen] bounds].size.height * [sett yOffsetFactor];
		CGRect newRect = CGRectMake(self.frame.origin.x,newY,self.frame.size.width,self.frame.size.height);
		[self setFrame:newRect];
	}
}

%end

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)application {

	%orig;

	if(!sett)
	{
		sett = [%c(SBReachabilitySettings) new];
		NSLog(@"[BannerBuddy]Initialized the default reachability settings: %@", sett);
	}
}

%end

static void loadPrefs() 
{
	NSLog(@"Loading BannerBuddy prefs");
    CFPreferencesAppSynchronize(CFSTR("com.joshdoctors.bannerbuddy"));

    enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.joshdoctors.bannerbuddy")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.joshdoctors.bannerbuddy")) boolValue];
    if (enabled) {
        NSLog(@"[BannerBuddy] We are enabled");
    } else {
        NSLog(@"[BannerBuddy] We are NOT enabled");
    }

    stayPut = !CFPreferencesCopyAppValue(CFSTR("stayPut"), CFSTR("com.joshdoctors.bannerbuddy")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("stayPut"), CFSTR("com.joshdoctors.bannerbuddy")) boolValue];
}

static void showTestBanner()
{
	[[%c(SBBulletinBannerController) sharedInstance] _showTestBanner:YES];
}

%ctor
{
	NSLog(@"Loading BannerBuddy");
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                NULL,
                                (CFNotificationCallback)loadPrefs,
                                CFSTR("com.joshdoctors.bannerbuddy/settingschanged"),
                                NULL,
                                CFNotificationSuspensionBehaviorDeliverImmediately);

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                NULL,
                                (CFNotificationCallback)showTestBanner,
                                CFSTR("com.joshdoctors.bannerbuddy/showtestbanner"),
                                NULL,
                                CFNotificationSuspensionBehaviorDeliverImmediately);
	loadPrefs();
}
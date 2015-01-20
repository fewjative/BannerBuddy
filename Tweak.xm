#import <UIKit/UIKit.h>
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

static BOOL enabled = NO;
static BOOL reachabilityActive = NO;
static SBBannerContextView * bannerView = nil;
static SBBannerContainerViewController * bannerVC = nil;
static NSInteger orientation = 0;
static CGFloat yOffset = 0.0;
static BOOL justPulled = NO;
static BOOL blurView = NO;
static BOOL stayPut = YES;
static SBFAnimationFactory * factory = nil;

%hook SBWorkspace

-(void)handleReachabilityModeActivated {
	%orig;
	NSLog(@"[BannerBuddy]Activating reachability.");
}

-(void)handleReachabilityModeDeactivated {
	%orig;
	NSLog(@"[BannerBuddy]Deactivating reachability.");

	SBBannerController * controller = [%c(SBBannerController) sharedInstance];

	if([controller isShowingBanner] && enabled && !stayPut)
	{
		NSLog(@"[BannerBuddy]Reachability is deactivating, banner is showing, tweak enabled, and user wants dynamic banners.");
		SBBannerContainerViewController * vc = MSHookIvar<SBBannerContainerViewController*>(controller,"_bannerViewController");
		SBBannerContainerView * cv = MSHookIvar<SBBannerContainerView*>(vc,"_containerView");

		CGRect dynamicRect = CGRectMake(cv.frame.origin.x,0,cv.frame.size.width,cv.frame.size.height);
		
		[%c(SBFAnimationFactory) animateWithFactory:factory actions:^{
			cv.frame = dynamicRect;
		} completion:^(BOOL finished){
		}];

		factory = nil;
		NSLog(@"[BannerBuddy]CV after changes: %@", cv);
	}
	else
	{
		NSLog(@"[BannerBuddy]Not lowering the banner when reach is deactived.");
		NSLog(@"[BannerBuddy]enabled: %ld, stayPut: %ld, isShowing: %ld",(long)enabled, (long)stayPut, (long)[controller isShowingBanner]);
	}
}

%end

%hook SBBannerContainerView

-(void)layoutSubviews{
	%orig;

	if([[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive] && enabled)
	{
		NSLog(@"[BannerBuddy]Shifting from layoutSubview.");
		CGFloat newY = [[UIScreen mainScreen] bounds].size.height * yOffset;
		CGRect newRect = CGRectMake(self.frame.origin.x,newY,self.frame.size.width,self.frame.size.height);
		[self setFrame:newRect];
	}
}

%end

%hook SBReachabilitySettings

-(CGFloat)yOffsetFactor{
	CGFloat orig = %orig;
	yOffset = orig;
	
	SBBannerController * controller = [%c(SBBannerController) sharedInstance];

	if([controller isShowingBanner] && enabled)
	{
		NSLog(@"[BannerBuddy]Reachability is active, tweak is enabled, and banner is showing.");
		SBBannerContainerViewController * vc = MSHookIvar<SBBannerContainerViewController*>(controller,"_bannerViewController");
		SBBannerContainerView * cv = MSHookIvar<SBBannerContainerView*>(vc,"_containerView");

		CGFloat newY = [[UIScreen mainScreen] bounds].size.height * yOffset;
		CGRect dynamicRect = CGRectMake(cv.frame.origin.x,newY,cv.frame.size.width,cv.frame.size.height);

		[%c(SBFAnimationFactory) animateWithFactory:[self animationFactory] actions:^{
			cv.frame = dynamicRect;
		} completion:^(BOOL finished){

		/*if(1==1)//blurView
		{
			NSLog(@"[RTB]Attempting to Blur the view.");
			CGRect blurRect = CGRectMake(cv.frame.origin.x,0,cv.frame.size.width,newY);
			UIGraphicsBeginImageContext(blurRect.size);
			[[[UIApplication sharedApplication] keyWindow] drawViewHierarchyInRect:blurRect afterScreenUpdates:YES];
			UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			UIImage * blurred = [image applyBlurWithRadius:30 tintColor:[UIColor colorWithWhite:1 alpha:0.2] saturationDeltaFactor:1.5 maskImage:nil];

			UIImageView * blurredImageView = [[UIImageView alloc] initWithFrame:blurRect];
			blurredImageView.image = blurred;
			//[blurredImageView setContentMode:UIViewContentModeScaleToFill];
			blurredImageView.alpha = 0;
			NSLog(@"[RTB]Blur rect: %@", NSStringFromCGRect(blurRect));
			NSLog(@"[RTB]ImageView: %@",blurredImageView);

			//UIView * testView = [[UIView alloc] initWithFrame:testRect2];
			//testView.backgroundColor = [UIColor redColor];
			//testView.alpha=0;
			[[[UIApplication sharedApplication] keyWindow] addSubview:blurredImageView];

			[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
				blurredImageView.alpha = 1;
			}
			completion:^(BOOL finished){

			}];
			[blurredImageView release];
		}*/

		}];

		NSLog(@"[BannerBuddy]CV after changes: %@", cv);
	}
	else
	{
		NSLog(@"[BannerBuddy]Not lowering the banner when reach is deactived.");
		NSLog(@"[BannerBuddy]enabled: %ld, stayPut: %ld, isShowing: %ld",(long)enabled, (long)stayPut, (long)[controller isShowingBanner]);
	}

	return orig;
}

-(id)animationFactory{
	id orig = %orig;
	factory = [orig copyWithZone:NULL];

	//NSLog(@"Reachability mode active: %ld", [[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive]);

	SBBannerController * controller = [%c(SBBannerController) sharedInstance];

	if([controller isShowingBanner] && enabled && ![[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive] && !stayPut)
	{
		NSLog(@"[BannerBuddy]Reachability is deactivating via tap, banner is showing, tweak enabled, and user wants dynamic banners.");
		SBBannerContainerViewController * vc = MSHookIvar<SBBannerContainerViewController*>(controller,"_bannerViewController");
		SBBannerContainerView * cv = MSHookIvar<SBBannerContainerView*>(vc,"_containerView");

		CGRect dynamicRect = CGRectMake(cv.frame.origin.x,0,cv.frame.size.width,cv.frame.size.height);
		
		[%c(SBFAnimationFactory) animateWithFactory:factory actions:^{
			cv.frame = dynamicRect;
		} completion:^(BOOL finished){
		}];

		NSLog(@"[BannerBuddy]CV after changes: %@", cv);
	}

	return orig;
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
    //blurView = !CFPreferencesCopyAppValue(CFSTR("blurView"), CFSTR("com.joshdoctors.reachthebanners")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("blurView"), CFSTR("com.joshdoctors.reachthebanners")) boolValue];
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
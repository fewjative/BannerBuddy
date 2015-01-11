#import <UIKit/UIKit.h>
#import <substrate.h>

@interface SBBannerContextView : UIView
-(UIView*)pullDownView;
@end

@interface SBBannerContainerView : UIView
@end

@interface SBBannerContainerViewController
@end

static BOOL enabled = NO;
static BOOL reachabilityActive = NO;
static SBBannerContextView * bannerView = nil;
static SBBannerContainerViewController * bannerVC = nil;
static NSInteger orientation = 0;
static CGFloat yOffset = 0.0;
static BOOL justPulled = NO;

%hook SBWorkspace

-(void)handleReachabilityModeActivated {
	%orig;
	NSLog(@"[RTB]Activating reachability.");
}

-(void)handleReachabilityModeDeactivated {
	%orig;
	NSLog(@"[RTB]Deactivating reachability.");
}

%end

%hook SBBannerContainerViewController

//alternative possibility: SBBannerController, check isShowingBanner using sharedInstance, then grab appropriate views.
//Don't need to keep track of ViewController variable.
-(CGRect)_bannerFrameForOrientation:(NSInteger)arg1{

	CGRect orig = %orig(arg1);
	bannerVC = self;
	orientation = arg1;

	if([[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive] && enabled)
	{
		NSLog(@"[RTB]bannerFrameForOrientaton - reachability is active and tweak enabled.");
		CGFloat newY = [[UIScreen mainScreen] bounds].size.height * yOffset;
		CGRect newRect = CGRectMake(orig.origin.x,orig.origin.y+newY,orig.size.width,orig.size.height);
		return newRect;
	}
	else
	{
		NSLog(@"[RTB]bannerFrameForOrientaton - reachability is not active or tweak is not enabled.");
		return orig;
	}
}

-(void)dealloc{
	NSLog(@"[RTB]SBBannerContainerViewController deallocated.");
	bannerVC = nil;
	%orig;
}

%end

%hook SBReachabilitySettings

-(CGFloat)yOffsetFactor{
	CGFloat orig = %orig;
	yOffset = orig;
		
	if(bannerVC && enabled)
	{
		NSLog(@"[RTB]Shifting the banner view.");
		[bannerVC _bannerFrameForOrientation:orientation];
		NSLog(@"Shifted self: %@",self);
		SBBannerContainerView * cv = MSHookIvar<SBBannerContainerView*>(bannerVC,"_containerView");
		NSLog(@"Container: %@",cv);
		[cv shiftFrame];
	}
	else
	{
		NSLog(@"[RTB]Getting offset without shift.");
	}

	return orig;
}

%end

%hook SBBannerContainerView

%new -(void)shiftFrame{
	CGFloat newY = [[UIScreen mainScreen] bounds].size.height * yOffset;
	CGRect newRect = CGRectMake(self.frame.origin.x,newY,self.frame.size.width,self.frame.size.height);
	[self setFrame:newRect];
}

-(CGRect)_inlineContainerFrame{
	CGRect orig = %orig;

	if([[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive] && enabled)
	{
		NSLog(@"[RTB]inlineContainerFrame - reachability is active and tweak enabled.");
		CGFloat newY = [[UIScreen mainScreen] bounds].size.height * yOffset;
		//this is to reset the positioning once a user has pulled down on the notification that has been moved down.
		//thus we check to make sure the origin isn't 0(which would indicate it hasn't moved down)
		//and we check to see if our origin isn't the Y offset(which would indicate it has already been set)
		if(orig.origin.y != 0.0 && orig.origin.y != newY){

			NSLog(@"[RTB]Shifting the container frame.");
			CGRect newRect = CGRectMake(self.frame.origin.x,newY,self.frame.size.width,self.frame.size.height);
			[self setFrame:newRect];
		}
	}

	return orig;
}

-(BOOL)pointInside:(CGPoint)pt withEvent:(id)event{

	BOOL b = %orig(pt,event);
	SBBannerContextView * contextView = [self bannerView];

	//if the origin is 0, we have a regular banner that is unshifted
	if(contextView.frame.origin.y==0 || !enabled)
		return b;

	if([contextView isPulledDown])
	{
		if(CGRectContainsPoint(self.frame,pt))
		{
			NSLog(@"[RTB]Banner pulled down - point in view.");
			return YES;
		}
		else
		{
			NSLog(@"[RTB]Banner pulled down  - point out of view.");
			return NO;
		}
	}
	else
	{
		//banner is not pulled down
		if(CGRectContainsPoint(contextView.frame,pt))
		{
			NSLog(@"[RTB]Banner not pulled down - point in view.");
			return YES;
		}
		else
		{
			NSLog(@"[RTB]Banner not pulled down - point out of view.");
			return NO;
		}
	}
}

%end

%hook SBBannerContextView

-(void)setFrame:(CGRect)rect{
	if([[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive] && enabled)
	{
		CGFloat newY = [[UIScreen mainScreen] bounds].size.height * yOffset;
		if(rect.origin.y==0 && [self superview].frame.origin.y==0)
		{
			NSLog(@"[RTB]Reshifting Context.");
			CGRect newRect = CGRectMake(rect.origin.x,newY,rect.size.width,rect.size.height);
			%orig(newRect);
		}
		else
			%orig;
	}
	else
		%orig;
}

%end

static void loadPrefs() 
{
	NSLog(@"Loading ReachTheBanners prefs");
    CFPreferencesAppSynchronize(CFSTR("com.joshdoctors.reachthebanners"));

    enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.joshdoctors.reachthebanners")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.joshdoctors.reachthebanners")) boolValue];
    if (enabled) {
        NSLog(@"[ReachTheBanners] We are enabled");
    } else {
        NSLog(@"[ReachTheBanners] We are NOT enabled");
    }
}

%ctor
{
	NSLog(@"Loading ReachTheBanners");
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                NULL,
                                (CFNotificationCallback)loadPrefs,
                                CFSTR("com.joshdoctors.reachthebanners/settingschanged"),
                                NULL,
                                CFNotificationSuspensionBehaviorDeliverImmediately);
	loadPrefs();
}
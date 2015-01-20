#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>

@interface BannerBuddySettingsListController: PSListController {
}
@end

@interface ViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@end

@implementation BannerBuddySettingsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"BannerBuddySettings" target:self] retain];
	}
	return _specifiers;

}

-(void)twitter {

	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/Fewjative"]];

}

-(void)showTestBanner{
	    		CFPreferencesAppSynchronize(CFSTR("com.joshdoctors.bannerbuddy"));
    			CFNotificationCenterPostNotification(
    			CFNotificationCenterGetDarwinNotifyCenter(),
    			CFSTR("com.joshdoctors.bannerbuddy/showtestbanner"),
    			NULL,
    			NULL,
    			YES
    			);
}

-(void)save
{
    [self.view endEditing:YES];
}

@end

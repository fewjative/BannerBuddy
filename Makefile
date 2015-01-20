ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = BannerBuddy
BannerBuddy_FILES = Tweak.xm
BannerBuddy_FRAMEWORKS = UIKit CoreGraphics Foundation QuartzCore Accelerate
BannerBuddy_PRIVATE_FRAMEWORKS = SpringBoardFoundation
BannerBuddy_CFLAGS = -Wno-error
export GO_EASY_ON_ME := 1
include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += BannerBuddySettings
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_STORE" -delete
after-install::
	install.exec "killall -9 backboardd"

ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = ReachTheBanners
ReachTheBanners_FILES = Tweak.xm
ReachTheBanners_FRAMEWORKS = UIKit CoreGraphics
ReachTheBanners_CFLAGS = -Wno-error
export GO_EASY_ON_ME := 1
include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += ReachTheBannersSettings
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_STORE" -delete
after-install::
	install.exec "killall -9 backboardd"

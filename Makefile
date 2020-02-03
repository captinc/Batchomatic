ARCHS = arm64 arm64e
TARGET = iphone:clang::11.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Batchomatic
Batchomatic_FILES = $(wildcard *.xm)
Batchomatic_CFLAGS = -fobjc-arc
Batchomatic_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = Icon
Icon_INSTALL_PATH = /Library/Batchomatic
include $(THEOS_MAKE_PATH)/bundle.mk

SUBPROJECTS += bmd
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_Store" -type f -delete

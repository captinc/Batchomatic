ARCHS = arm64 arm64e
TARGET = iphone:clang::11.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Batchomatic
Batchomatic_FILES = $(wildcard *.xm *.m)
Batchomatic_CFLAGS = -fobjc-arc
Batchomatic_FRAMEWORKS = UIKit
include $(THEOS_MAKE_PATH)/tweak.mk

before-stage::
	find . -name ".DS_Store" -type f -delete

after-stage::
	$(MAKE) -C bmd
	mkdir -p $(THEOS_STAGING_DIR)/usr/bin
	mv $(THEOS_OBJ_DIR)/bmd $(THEOS_STAGING_DIR)/usr/bin

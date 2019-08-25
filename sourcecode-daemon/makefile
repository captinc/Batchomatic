ARCHS = armv7 arm64 arm64e

include $(THEOS)/makefiles/common.mk

TOOL_NAME = batchomaticd

batchomaticd_FILES = main.m
batchomaticd_CFLAGS = -fobjc-arc
batchomaticd_CODESIGN_FLAGS = -Splatform.xml

include $(THEOS_MAKE_PATH)/tool.mk

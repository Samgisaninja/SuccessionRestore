ARCHES = armv7 arm64 arm64e
include $(THEOS)/makefiles/common.mk

TOOL_NAME = SuccessionCLIhelper

SuccessionCLIhelper_FILES = main.m
SuccessionCLIhelper_CFLAGS = -fobjc-arc
SuccessionCLIhelper_CODESIGN_FLAGS = -Sent.plist

include $(THEOS_MAKE_PATH)/tool.mk

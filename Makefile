ARCHS = armv7 arm64 arm64e
TARGET = iphone:13.5:8.0
FINALPACKAGE = 1
include $(THEOS)/makefiles/common.mk

TOOL_NAME = SuccessionCLIhelper

SuccessionCLIhelper_PRIVATE_FRAMEWORKS = SpringBoardServices
SuccessionCLIhelper_FILES = main.m
SuccessionCLIhelper_CFLAGS = -fobjc-arc
SuccessionCLIhelper_CODESIGN_FLAGS = -Sent.plist


include $(THEOS_MAKE_PATH)/tool.mk

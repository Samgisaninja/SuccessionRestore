ARCHS = armv7 arm64 arm64e
TARGET = iphone:13.5:8.0
FINALPACKAGE = 1
include $(THEOS)/makefiles/common.mk

TOOL_NAME = SuccessionCLITools

SuccessionCLITools_FILES = main.m
SuccessionCLITools_CFLAGS = -fobjc-arc
SuccessionCLITools_CODESIGN_FLAGS = -Sentitlements.plist
SuccessionCLITools_INSTALL_PATH = /usr/bin

include $(THEOS_MAKE_PATH)/tool.mk

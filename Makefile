include $(THEOS)/makefiles/common.mk

TOOL_NAME = SuccessionCLIhelper

SuccessionCLIhelper_FILES = main.m
SuccessionCLIhelper_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tool.mk

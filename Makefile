include $(THEOS)/makefiles/common.mk

TOOL_NAME = SuccessionCLI

SuccessionCLI_FILES = main.m
SuccessionCLI_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tool.mk

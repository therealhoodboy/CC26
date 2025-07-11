# Set default values (can be overridden by environment)
DEBUG = 0
FINALPACKAGE = 1
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard Preferences

# Device targeting based on build mode
ifeq ($(ROOTLESS),1)
	THEOS_DEVICE_IP = 192.168.1.8
	THEOS_DEVICE_PORT = 22
	THEOS_PACKAGE_SCHEME = rootless
	EXPORT_PACKAGE = $(THEOS_PACKAGE_DIR)/$(TWEAK_NAME)_rootless.deb
else ifeq ($(ROOTHIDE),1)
	THEOS_PACKAGE_SCHEME = roothide
	EXPORT_PACKAGE = $(THEOS_PACKAGE_DIR)/$(TWEAK_NAME)_roothide.deb
else
	THEOS_DEVICE_IP = 192.168.178.34
	THEOS_DEVICE_PORT = 22
	THEOS_DEVICE_USER = root
	EXPORT_PACKAGE = $(THEOS_PACKAGE_DIR)/$(TWEAK_NAME)_rootful.deb
endif

# Include common settings
include $(THEOS)/makefiles/common.mk

# Tweak configuration
TWEAK_NAME = CC26
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += CC26Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

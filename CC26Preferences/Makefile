ARCHS = arm64 arm64e
TARGET := iphone:clang:14.5:14.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CC26Preferences

CC26Preferences_FILES = CC26RootListController.m CC26LocalizableManager.m
CC26Preferences_FRAMEWORKS = UIKit
CC26Preferences_PRIVATE_FRAMEWORKS = Preferences
CC26Preferences_INSTALL_PATH = /Library/PreferenceBundles
CC26Preferences_CFLAGS = -fobjc-arc -Wdeprecated-declarations -Wno-deprecated-declarations -fno-modules

include $(THEOS_MAKE_PATH)/bundle.mk

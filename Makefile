# Legacy Surf: the Surf iOS client by seg6, legacified by the LegacyReborn
# Project with a skeuomorphic iOS 6 skin. Built with Theos.
#
#   make package    packages/com.legacyreborn.legacysurf_<version>_iphoneos-arm.deb
#   make do         build and install on THEOS_DEVICE_IP over SSH
#   make clean
#
# Needs $THEOS/sdks/iPhoneOS8.0.sdk: it carries both the armv7 (iOS 6) and the
# arm64 (iOS 7+) stubs. Builds are release builds unless FINALPACKAGE=0.

ifneq ($(words $(CURDIR)),1)
# Theos refuses project paths that contain spaces, and this folder may well
# live under one. Hand every goal to build.sh, which builds a mirror of the
# sources under a space-free path and copies the packages back here.
_LS_GOALS := $(or $(MAKECMDGOALS),all)
.PHONY: $(_LS_GOALS) _legacysurf_mirror
$(_LS_GOALS): _legacysurf_mirror
	@:
_legacysurf_mirror:
	@./build.sh $(MAKECMDGOALS)
else

THEOS ?= $(HOME)/theos
FINALPACKAGE ?= 1

VERSION := $(shell tr -d '[:space:]' < VERSION)
SURF_BASE_VERSION := $(shell tr -d '[:space:]' < SURF_BASE_VERSION)
COMPATIBILITY_VERSION := $(shell tr -d '[:space:]' < COMPATIBILITY_VERSION)
_LS_RENDER := $(shell VERSION='$(VERSION)' SURF_BASE_VERSION='$(SURF_BASE_VERSION)' \
	COMPATIBILITY_VERSION='$(COMPATIBILITY_VERSION)' ./render-versioned-files.sh 2>&1)
ifneq ($(_LS_RENDER),)
$(error $(_LS_RENDER))
endif

ifeq ($(wildcard $(THEOS)/sdks/iPhoneOS8.0.sdk),)
$(error Missing $(THEOS)/sdks/iPhoneOS8.0.sdk; see "Building" in README.md)
endif

TARGET := iphone:clang:8.0
TARGET_OS_DEPLOYMENT_VERSION_armv7 := 6.0
TARGET_OS_DEPLOYMENT_VERSION_arm64 := 7.0
ARCHS := armv7 arm64
# The dpkg of iOS 6 era jailbreaks cannot unpack xz or zstd members.
THEOS_PLATFORM_DEB_COMPRESSION_TYPE := gzip

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := LegacySurf
LegacySurf_FILES := $(sort $(wildcard Classes/*.m)) $(sort $(wildcard Classes/quirc/*.c)) \
	$(sort $(wildcard core/src/*.c))
# VideoToolbox is intentionally absent: private on iOS 6, resolved via dlopen.
LegacySurf_FRAMEWORKS := UIKit CoreGraphics QuartzCore ImageIO Security CFNetwork AudioToolbox \
	CoreMedia CoreVideo OpenGLES MessageUI AVFoundation
# RBAppVersion is the upstream Surf release this fork tracks: the Surf server
# compares it with its own client. RBLegacyVersion is the Legacy Surf release.
LegacySurf_CFLAGS := -fobjc-arc -Wall -Werror=return-type -Wno-deprecated-declarations \
	-I$(CURDIR)/core/include \
	-DRBAppVersion='@"$(SURF_BASE_VERSION)"' \
	-DRBLegacyVersion='@"$(VERSION)"' \
	-DRBCompatibilityVersion='@"$(COMPATIBILITY_VERSION)"'
LegacySurf_CODESIGN_FLAGS := -SLegacySurf.entitlements

include $(THEOS_MAKE_PATH)/application.mk

LS_APP = $(THEOS_STAGING_DIR)/Applications/LegacySurf.app

# Surf's original icon, unchanged: iOS 6 uses the transparent 57/72 point
# artwork, iOS 7+ the opaque one. legacysurf-select-icons picks the 60/76/83.5
# point set for the running OS from postinst.
after-stage::
	@mkdir -p $(LS_APP)/IconSets/Classic $(LS_APP)/IconSets/Modern \
		$(LS_APP)/ThirdPartyNotices $(THEOS_STAGING_DIR)/usr/libexec
	@cp Icons/icon-57.png $(LS_APP)/Icon.png
	@cp Icons/icon-57@2x.png $(LS_APP)/Icon@2x.png
	@cp Icons/icon-72.png $(LS_APP)/Icon-72.png
	@cp Icons/icon-72@2x.png $(LS_APP)/Icon-72@2x.png
	@cp Icons/icon-classic-60.png $(LS_APP)/IconSets/Classic/Icon-60.png
	@cp Icons/icon-classic-60@2x.png $(LS_APP)/IconSets/Classic/Icon-60@2x.png
	@cp Icons/icon-classic-60@3x.png $(LS_APP)/IconSets/Classic/Icon-60@3x.png
	@cp Icons/icon-classic-76.png $(LS_APP)/IconSets/Classic/Icon-76~ipad.png
	@cp Icons/icon-classic-76@2x.png $(LS_APP)/IconSets/Classic/Icon-76@2x~ipad.png
	@cp Icons/icon-classic-167.png $(LS_APP)/IconSets/Classic/Icon-83.5@2x.png
	@cp Icons/icon-60.png $(LS_APP)/IconSets/Modern/Icon-60.png
	@cp Icons/icon-60@2x.png $(LS_APP)/IconSets/Modern/Icon-60@2x.png
	@cp Icons/icon-60@3x.png $(LS_APP)/IconSets/Modern/Icon-60@3x.png
	@cp Icons/icon-76.png $(LS_APP)/IconSets/Modern/Icon-76~ipad.png
	@cp Icons/icon-76@2x.png $(LS_APP)/IconSets/Modern/Icon-76@2x~ipad.png
	@cp Icons/icon-167.png $(LS_APP)/IconSets/Modern/Icon-83.5@2x.png
	@cp $(LS_APP)/IconSets/Modern/* $(LS_APP)/
	@cp LICENSE $(LS_APP)/ThirdPartyNotices/LICENSE.txt
	@cp THIRD_PARTY_NOTICES.md $(LS_APP)/ThirdPartyNotices/README.md
	@cp Artwork/DETA-SURF-LICENSE.txt $(LS_APP)/ThirdPartyNotices/DETA-SURF-LICENSE.txt
	@cp Artwork/LUCIDE-LICENSE.txt $(LS_APP)/ThirdPartyNotices/LUCIDE-LICENSE.txt
	@cp Classes/quirc/LICENSE $(LS_APP)/ThirdPartyNotices/QUIRC-LICENSE.txt
	@cp Scripts/legacysurf-select-icons $(THEOS_STAGING_DIR)/usr/libexec/legacysurf-select-icons
	@find $(THEOS_STAGING_DIR) -path $(THEOS_STAGING_DIR)/DEBIAN -prune -o -type d -exec chmod 0755 {} +
	@find $(LS_APP) -type f -exec chmod 0644 {} +
	@chmod 0755 $(LS_APP)/LegacySurf $(THEOS_STAGING_DIR)/usr/libexec/legacysurf-select-icons

endif

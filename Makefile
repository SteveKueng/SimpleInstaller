# Makefile for Imagr related tasks
# User configurable variables below
#################################################

URL="http://172.16.39.1:8080/install/config.plist"
REPORTURL=none
APP="/Applications/Install macOS High Sierra.app"
OUTPUT=~/Desktop
NBI="SimpleInstaller"
DMGPATH=none
ARGS= --enable-nbi --add-python
BUILD=Release
AUTONBIURL=https://raw.githubusercontent.com/bruienne/autonbi/master/AutoNBI.py
AUTONBIRCNBURL=https://raw.githubusercontent.com/bruienne/autonbi/feature/ramdisk/rc.netboot
FOUNDATIONPLISTURL=https://raw.githubusercontent.com/munki/munki/master/code/client/munkilib/FoundationPlist.py
INDEX="5001"
SYSLOG=none
TMPMOUNT="/private/tmp/mount"
STARTTERMINAL=False
ADDITIONALHEADERKEY="Authorization"
ADDITIONALHEADERVALUE="Basic TUVESUFcc3ZjLWdkLW1haW5yZXBvOmE2NFQ9OHFobmZ5djVZUGtuUg=="


-include config.mk

#################################################

build: clean
	xcodebuild -configuration Release

autonbi:
	if [ ! -f ./AutoNBI.py ]; then \
		curl -fsSL $(AUTONBIURL) -o ./AutoNBI.py; \
		chmod 755 ./AutoNBI.py; \
	fi

autonbi-rcnetboot:
	if [ ! -f ./rc.netboot ]; then \
		curl -fsSL $(AUTONBIRCNBURL) -o ./rc.netboot; \
		chmod 755 ./rc.netboot; \
	fi

clean:
	rm -rf build

clean-pkgs:
	sudo rm -rf Packages

clean-all: clean clean-pkgs
	rm -rf AutoNBI.py
	rm -rf rc.netboot
	rm -rf com.github.stevekueng.simpleinstaller.plist
	rm -rf FoundationPlist.py
	rm -rf FoundationPlist.pyc
	rm -rf SimpleInstaller.app

run: build
	sudo build/Release/SimpleInstaller.app/Contents/MacOS/SimpleInstaller

config:
	rm -f com.github.stevekueng.simpleinstaller.plist
	/usr/libexec/PlistBuddy -c 'Add :serverurl string "$(URL)"' com.github.stevekueng.simpleinstaller.plist
ifneq ($(REPORTURL),none)
	/usr/libexec/PlistBuddy -c 'Add :reporturl string "$(REPORTURL)"' com.github.stevekueng.simpleinstaller.plist
endif
ifneq ($(SYSLOG),none)
	/usr/libexec/PlistBuddy -c 'Add :syslog string "$(SYSLOG)"' com.github.stevekueng.simpleinstaller.plist
endif
ifneq ($(ADDITIONALHEADERKEY),none)
	/usr/libexec/PlistBuddy -c 'Add :additional_headers dict' com.github.stevekueng.simpleinstaller.plist
	/usr/libexec/PlistBuddy -c 'Add :additional_headers:"$(ADDITIONALHEADERKEY)" string "$(ADDITIONALHEADERVALUE)"' com.github.stevekueng.simpleinstaller.plist
endif

deps: autonbi foundation

dmg: build
	rm -f ./SimpleInstaller*.dmg
	rm -rf /tmp/SimpleInstaller-build
	mkdir -p /tmp/SimpleInstaller-build/Tools
	cp ./Readme.md /tmp/SimpleInstaller-build
	cp ./Makefile /tmp/SimpleInstaller-build/Tools
	cp -R ./build/Release/SimpleInstaller.app /tmp/SimpleInstaller-build
	hdiutil create -srcfolder /tmp/SimpleInstaller-build -volname "SimpleInstaller" -format UDZO -o SimpleInstaller.dmg
	mv SimpleInstaller.dmg \
		"SimpleInstaller-$(shell /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "./build/Release/SimpleInstaller.app/Contents/Info.plist").dmg"
	rm -rf /tmp/SimpleInstaller-build

foundation:
	if [ ! -f ./FoundationPlist.py ]; then \
		curl -fsSL $(FOUNDATIONPLISTURL) -o ./FoundationPlist.py; \
		chmod 755 ./FoundationPlist.py; \
	fi

dl:
ifeq ($(DMGPATH),none)
	rm -f ./SimpleInstaller*.dmg
	rm -rf SimpleInstaller.app
	curl -sL -o ./SimpleInstaller.dmg --connect-timeout 30 $$(curl -s \
		https://api.github.com/repos/SteveKueng/SimpleInstaller/releases | \
		python -c 'import json,sys;obj=json.load(sys.stdin); \
		print obj[0]["assets"][0]["browser_download_url"]')
	hdiutil attach "SimpleInstaller.dmg" -mountpoint "$(TMPMOUNT)"
else
	hdiutil attach "$(DMGPATH)" -mountpoint "$(TMPMOUNT)"
endif


	cp -r "$(TMPMOUNT)"/SimpleInstaller.app .
	hdiutil detach "$(TMPMOUNT)"
ifeq ($(DMGPATH),none)
	rm ./SimpleInstaller.dmg
endif

pkg-dir:
	mkdir -p Packages/Extras
ifeq ($(STARTTERMINAL),True)
	printf '%s\n%s' '#!/bin/bash' '/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal' > Packages/Extras/rc.imaging
	cp -r /Applications/Utilities/Console.app ./Packages
else
	printf '%s\n%s' '#!/bin/bash' '/System/Installation/Packages/SimpleInstaller.app/Contents/MacOS/SimpleInstaller' > Packages/Extras/rc.imaging
endif
	cp ./com.github.stevekueng.simpleinstaller.plist Packages/
ifeq ($(BUILD),Release)
	$(MAKE) dl
	cp -r ./SimpleInstaller.app ./Packages
else ifeq ($(BUILD),Testing)
	$(MAKE) build
	cp -r ./build/Release/SimpleInstaller.app ./Packages
else
	@echo "BUILD variable not set properly."
	exit 1
endif
	sudo chown -R root:wheel Packages/*
	sudo chmod -R 755 Packages/*

nbi: clean-pkgs autonbi foundation config pkg-dir
	sudo ./AutoNBI.py $(ARGS) --source $(APP) --folder Packages --destination $(OUTPUT) --name $(NBI) --index $(INDEX)
	$(MAKE) clean-all

nbi-ramdisk: clean-pkgs autonbi autonbi-rcnetboot foundation config pkg-dir
	sudo ./AutoNBI.py $(ARGS) --ramdisk --source $(APP) --folder Packages --destination $(OUTPUT) --name $(NBI) --index $(INDEX)
	$(MAKE) clean-all

update: clean-pkgs autonbi foundation config pkg-dir
	sudo ./AutoNBI.py --source $(OUTPUT)/$(NBI).nbi/NetInstall.dmg --folder Packages --name $(NBI) --index $(INDEX)
	$(MAKE) clean-all

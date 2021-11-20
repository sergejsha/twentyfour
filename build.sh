#!/bin/bash

if [ $GARMIN_DEVELOPER_KEY ]; then

	for device in \
		fenix5 \
		fenix5plus \
		fenix5s \
		fenix5splus \
		fenix5x \
		fenix5xplus \
		fenix6 \
		fenix6pro \
		fenix6s \
		fenix6spro \
		fenix6xpro
		
	do
		echo "Building binaries/$device/twentyfour-release.prg"
	
		monkeyc \
			-r \
			-f monkey.jungle \
			-y $GARMIN_DEVELOPER_KEY \
			-d $device \
			-o binaries/$device/twentyfour-release.prg
	
		rm binaries/$device/twentyfour-release.prg.debug.xml
		rm binaries/$device/twentyfour-release-settings.json
	
	
		echo "Building binaries/$device/twentyfour-debug.prg"
	
		monkeyc \
			-f monkey.jungle \
			-y $GARMIN_DEVELOPER_KEY \
			-d $device \
			-o binaries/$device/twentyfour-debug.prg
	
		rm binaries/$device/twentyfour-debug.prg.debug.xml
		rm binaries/$device/twentyfour-debug-settings.json
	
	done
	
else
	echo "Environment variable GARMIN_DEVELOPER_KEY must be set."
fi

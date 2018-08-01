#!/bin/bash

OVERLAY_PATH="/boot/overlays"
OVERLAY_NAME="picade.dtbo"

CONFIG="/boot/config.txt"
CONFIG_BACKUP="$CONFIG.picade-preinstall"

CONFIG_LINES=(
	"dtoverlay=picade"
)

printf "Picade HAT: Installer\n\n"

if [ $(id -u) -ne 0 ]; then
	printf "Script must be run as root. Try 'sudo ./install.sh'\n"
	exit 1
fi

if [ ! -f "$OVERLAY_NAME" ]; then
	if [ ! -f "/usr/bin/dtc" ]; then
		printf "This script requires device-tree-compiler, please \"sudo apt install device-tree-compiler\"\n";
		exit 1
	fi
	make
fi

if [ ! -f "$CONFIG_BACKUP" ]; then
	cp $CONFIG $CONFIG_BACKUP
	printf "Notice: copying $CONFIG to $CONFIG_BACKUP\n"
fi

if [ -d "$OVERLAY_PATH" ]; then
	cp $OVERLAY_NAME $OVERLAY_PATH/$OVERLAY_NAME
	printf "Installed: $OVERLAY_PATH/$OVERLAY_NAME\n"
else
	printf "Warning: unable to copy $OVERLAY_NAME to $OVERLAY_PATH\n"
fi

if [ -f "$CONFIG" ]; then
	for ((i = 0; i < ${#CONFIG_LINES[@]}; i++)); do
		CONFIG_LINE="${CONFIG_LINES[$i]}"
		grep -e "^#$CONFIG_LINE" $CONFIG > /dev/null
		STATUS=$?
		if [ $STATUS -eq 1 ]; then
			grep -r "^$CONFIG_LINE" $CONFIG > /dev/null
			STATUS=$?
			if [ $STATUS -eq 1 ]; then
				# Line is missing from config file
				echo "$CONFIG_LINE" >> $CONFIG
				printf "Config: Added \"$CONFIG_LINE\" to $CONFIG\n"
			else
				printf "Config: Skipped \"$CONFIG_LINE\", already exists in $CONFIG\n"
			fi
		else
			sed $CONFIG -i -e "s/^#$CONFIG_LINE/$CONFIG_LINE/"
			printf "Config: Uncommented \"$CONFIG_LINE\" in $CONFIG\n"
		fi
	done
else
	printf "Warning: unable to find $CONFIG, is /boot mounted?\n"
fi

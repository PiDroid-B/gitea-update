#!/bin/bash

# gitea-update.sh
# https://github.com/PiDroid-B/gitea-update
# Version : 1.1.0
# Copyright 2019 PiDroid-B All rights reserved.
# Use of this source code is governed by a GPL v3

###############################################################################

### Usage ###
INFO=$(cat <<EOF

Usage : ${0##*/} <Option>

Option :
-c : Check (Dry-Run notification)
-n : Notify when update are available
-u : Do the update
-s </path/of/your/setting> : load settings from dedicated file (it will be create if not exist)

.
EOF
)

### Doc ###
# requirements :
#   Gitea, Bash
#
# Install this script where you want (i.e. : /usr/local/bin/gitea-update.sh )
# Set all variables (in place or in dedicated settings file : please see README.md for more information)
# Change rights for the script (and for settings file if exist) : chmod 700 /usr/local/bin/gitea-update.sh
# Add cron for periodic check (i.e. every day at 5am : echo "0 5 * * * root /usr/local/bin/gitea-update.sh -n >/dev/null" > /etc/cron.d/gitea )
# Check if it works with a Dry-Run : /usr/local/bin/gitea-update.sh -c
#
# When new version available, use the option -u as like as the noficitaion suggest
#
SETTINGS_CONTENT=$(cat <<-EOF
	###############################################################################
	# VARIABLES
	# They are loaded with the following order (keep last found variables)
	# - variables defined in the script
	# - /etc/gitea-update.conf (if exist)
	# - /usr/local/etc/gitea-update.conf (if exist)
	# - given file from option -s
	
	# the option -s generate a new settings file if not exist, you can use it 
	# in /etc/gitea-update.conf or /usr/local/etc/gitea-update.conf or where you want
	
	# sender of the notification
	MAIL_FROM='Your Mail<your-mail@example.net>'
	# destination
	MAIL_TO='<mail@example.net>'
	
	# where the file 'gitea' is installed
	GITEA_PATH="/usr/local/bin/"
	# user for gitea
	GITEA_USER="gitea"
	
	# max lines of change log returned by email if new version is available
	CHANGE_LOG_MAX_LINES=100
	
EOF
)
# -----------------------------------------------------------------------------
# /!\ don't modify below /!\
# -----------------------------------------------------------------------------
eval "$SETTINGS_CONTENT"
[[ -f "/etc/gitea-update.conf" ]] && . /etc/gitea-update.conf
[[ -f "/usr/local/etc/gitea-update.conf" ]] && . /usr/local/etc/gitea-update.conf

URL_RELEASE="https://github.com/go-gitea/gitea/releases/"
URL_CHANGE_LOG="https://raw.githubusercontent.com/go-gitea/gitea/master/CHANGELOG.md"

###############################################################################
# SCRIPT
NOTIF=0
UPDATE=0
CHECK=0

while getopts ":cnus:" option
do
	case "${option}" in
		c)
			CHECK=1
		;;
		n)
			NOTIF=1
		;;
		u)
			UPDATE=1
		;;
		s)
			FILEARG="$OPTARG"
			# load file if exist else create it
			if [[ -f "$FILEARG" ]] ; then
				. "$FILEARG"
			else
				echo "$SETTINGS_CONTENT" > "$FILEARG"
				echo -e "\n\033[0;32m$SETTINGS_CONTENT\n\033[0mPlease edit it with your own values\n\tvi $FILEARG\n"
				exit 0
			fi
		;;
		\?)
			echo "$OPTARG : invalid argument"
			echo
			echo -e "${INFO}"
			exit 1
		;;
	esac
done

[[ -z $MAIL_FROM ]] || [[ $MAIL_FROM = *"example.net"* ]] &&  \
	echo -e "\n\033[0;31mError : \033[0mYou must edit this script with your settings (MAIL_FROM)" && \
	echo -e "${INFO}" && exit 1

[[ -z $MAIL_TO ]] || [[ $MAIL_TO = *"example.net"* ]] &&  \
	echo -e "\n\033[0;31mError : \033[0mYou must edit this script with your settings (MAIL_TO)" && \
	echo -e "${INFO}" && exit 1

[[ "${GITEA_PATH}" != */ ]] && GITEA_PATH="${GITEA_PATH}/"
[[ ! -f "${GITEA_PATH}gitea" ]] &&  \
        echo -e "\n\033[0;31mError : \033[0mYou must edit this script with your settings (GITEA_PATH)" && \
        echo "GITEA_PATH=${GITEA_PATH}" && \
        echo "file ${GITEA_PATH}gitea not found" && \
        echo -e "${INFO}" && exit 1

[[ ${CHECK} -eq 0 ]] && [[ ${NOTIF} -eq 0 ]] && [[ ${UPDATE} -eq 0 ]] && echo -e "${INFO}" && exit 1

last=$(curl --write-out %{redirect_url} --silent --output /dev/null  "${URL_RELEASE}latest" | awk -F '/' '{ print $8}')
current=v$(${GITEA_PATH}gitea --version | awk -F ' ' '{print $3}')

[[ ${CHECK} -eq 1 ]] && current="Dry-Run" && NOTIF=1 && UPDATE=0

MSG="Current version : ${current}\nLast version : ${last}"
echo -e "${MSG}"

if [ "$current" == "$last" ]; then
	echo
	echo "Already up to date"
	echo
else
	if [ ${NOTIF} -eq 1 ]; then
		echo "### NOTIFY ###"

                changelog=$(wget -O- "${URL_CHANGE_LOG}" )
                changelog=$(echo "$changelog" | head -n $CHANGE_LOG_MAX_LINES)

		MSG="${MSG}\n\nRun ${0} -u to update Gitea\n\nChangelog (first ${CHANGE_LOG_MAX_LINES} lines)\n\n$changelog\n\nRun ${0} -u to update Gitea\n"
		echo -e "${MSG}"
		echo -e "${MSG}" | mail -aFrom:"${MAIL_FROM}" -s "Gitea : new version available : $last" "${MAIL_TO}"

		echo "### NOTIFY DONE ###"
	fi
	if [ ${UPDATE} -eq 1 ]; then
		echo "### UPDATE ###"
		echo -e "Current version : ${current}\nLast version : ${last}"
		echo "###"
		lastversion=${last:1}
		rm ${GITEA_PATH}gitea
	        wget "${URL_RELEASE}download/$last/gitea-$lastversion-linux-amd64" -O ${GITEA_PATH}gitea
		chown $GITEA_USER:$GITEA_USER ${GITEA_PATH}gitea
	        chmod 755 ${GITEA_PATH}gitea
        	service gitea stop
	        service gitea start
		echo "### UPDATE DONE ###"
	fi
fi

exit 0



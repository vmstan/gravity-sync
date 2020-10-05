#!/bin/bash
SCRIPT_START=$SECONDS

# GRAVITY SYNC BY VMSTAN #####################
PROGRAM='Gravity Sync'
VERSION='3.0.0'

# Execute from the home folder of the user who owns it (ex: 'cd ~/gravity-sync')
# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync

# REQUIRED SETTINGS ##########################

# Run './gravity-sync.sh config' to get started

# STANDARD VARIABLES #########################

# GS Folder/File Locations
LOCAL_FOLDR='gravity-sync' 			# must exist in running user home folder
CONFIG_FILE='gravity-sync.conf' 	# must exist with primary host/user configured
GS_FILENAME='gravity-sync.sh'		# must exist because it's this script
BACKUP_FOLD='backup' 				# must exist as subdirectory in LOCAL_FOLDR

# Logging Folder/File Locations
LOG_PATH="$HOME/${LOCAL_FOLDR}"		# replace in gravity-sync.conf to overwrite
SYNCING_LOG='gravity-sync.log' 		# replace in gravity-sync.conf to overwrite
CRONJOB_LOG='gravity-sync.cron' 	# replace in gravity-sync.conf to overwrite
HISTORY_MD5='gravity-sync.md5'		# replace in gravity-sync.conf to overwrite

# Interaction Customization
VERIFY_PASS='0'						# replace in gravity-sync.conf to overwrite
SKIP_CUSTOM='0'						# replace in gravity-sync.conf to overwrite
DATE_OUTPUT='0'						# replace in gravity-sync.conf to overwrite
PING_AVOID='0'						# replace in gravity-sync.conf to overwrite
ROOT_CHECK_AVOID='0'				# replace in gravity-sync.conf to overwrite

# Backup Customization
BACKUP_RETAIN='7'					# replace in gravity-sync.conf to overwrite

# Pi-hole Folder/File Locations
PIHOLE_DIR='/etc/pihole' 			# default Pi-hole data directory
GRAVITY_FI='gravity.db' 			# default Pi-hole database file
CUSTOM_DNS='custom.list'			# default Pi-hole local DNS lookups
PIHOLE_BIN='/usr/local/bin/pihole' 	# default Pi-hole binary directory (local)
RIHOLE_BIN='/usr/local/bin/pihole' 	# default Pi-hole binary directory (remote)
FILE_OWNER='pihole:pihole'			# default Pi-hole file owner and group (local)
REMOTE_FILE_OWNER='pihole:pihole'	# default Pi-hole file owner and group (remote)

# OS Settings
BASH_PATH='/bin/bash'				# default OS bash path

# SSH CONFIGURATION ##########################

# Suggested not to replace these values here
# Add replacement variables to gravity-sync.conf

SSH_PORT='22' 						# default SSH port
SSH_PKIF='.ssh/id_rsa'				# default local SSH key

##############################################
### DO NOT CHANGE ANYTHING BELOW THIS LINE ###
##############################################

# Import Color/Message Includes
source includes/gs-colors.sh

# FUNCTION DEFINITIONS #######################

# Import Settings
function import_gs {
	MESSAGE="Importing ${CONFIG_FILE} Settings"
	echo -en "${STAT} $MESSAGE"
	if [ -f $HOME/${LOCAL_FOLDR}/${CONFIG_FILE} ]
	then
	    source $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
			error_validate
			
		# MESSAGE="Targeting ${REMOTE_USER}@${REMOTE_HOST}"
		# echo_info

		# detect_ssh
	else
		echo_fail
		
		MESSAGE="${CONFIG_FILE} Missing"
		echo_info

		TASKTYPE='CONFIG'
		config_generate
	fi
}

function show_target {
	MESSAGE="Targeting ${REMOTE_USER}@${REMOTE_HOST}"
	echo_info

	detect_ssh
}

# Check Intent
source includes/gs-intent.sh

# GS Update Functions
source includes/gs-update.sh

# GS Hashing Functions
source includes/gs-hashing.sh

# Gravity Core Functions
source includes/gs-pull.sh
source includes/gs-push.sh
source includes/gs-smart.sh
source includes/gs-restore.sh

# Logging Functions
source includes/gs-logging.sh

# Validate Functions
source includes/gs-validate.sh

# SSH Functions
source includes/gs-ssh.sh

## Error Validation
function error_validate {
	if [ "$?" != "0" ]
	then
	    echo_fail
	    exit 1
	else
		echo_good
	fi
}

# Configuration Management
source includes/gs-config.sh

# Exit Codes
source includes/gs-exit.sh

# Version Control
## Show Version
function show_version {
	echo -e "========================================================"
	MESSAGE="${BOLD}${PROGRAM}${NC} by ${CYAN}@vmstan${NC}"
	echo_info

	MESSAGE="${BLUE}https://github.com/vmstan/gravity-sync${NC}"
	echo_info

	if [ -f $HOME/${LOCAL_FOLDR}/dev ]
	then
		DEVVERSION="dev"
	elif [ -f $HOME/${LOCAL_FOLDR}/beta ]
	then 
		DEVVERSION="beta"
	else
		DEVVERSION=""
	fi
	
	MESSAGE="Running Version: ${GREEN}${VERSION}${NC} ${DEVVERSION}"
	echo_info

	GITVERSION=$(curl -sf https://raw.githubusercontent.com/vmstan/gravity-sync/master/VERSION)
	if [ -z "$GITVERSION" ]
	then
		MESSAGE="Latest Version: ${RED}Unknown${NC}"
	else
		if [ "$GITVERSION" != "$VERSION" ]
		then
		MESSAGE="Update Available: ${PURPLE}${GITVERSION}${NC}"
		else
		MESSAGE="Latest Version: ${GREEN}${GITVERSION}${NC}"
		fi
	fi
	echo_info
	echo -e "========================================================"
}

function dbclient_warning {
	if hash dbclient 2>/dev/null
	then
		if hash ssh 2>/dev/null
		then
			NOEMPTYBASHIF="1"
		else
			MESSAGE="Dropbear support has been deprecated - please convert to OpenSSH"
			echo_warn
		fi
	fi
}

# Task Stack
## Automate Task
function task_automate {
	TASKTYPE='AUTOMATE'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	# import_gs

	CRON_EXIST='0'
	CRON_CHECK=$(crontab -l | grep -q "${GS_FILENAME}"  && echo '1' || echo '0')
	if [ ${CRON_CHECK} == 1 ]
	then
		MESSAGE="Automation Task Already Exists"
		echo_info
		CRON_EXIST='1'
	fi
	
	MESSAGE="Configuring Hourly Smart Sync"
	echo_info

	if [[ $1 =~ ^[0-9][0-9]?$ ]]
	then
		INPUT_AUTO_FREQ=$1
	else
		MESSAGE="Sync Frequency in Minutes (1-30) or 0 to Disable"
		echo_need
		read INPUT_AUTO_FREQ
	fi

	if [ $INPUT_AUTO_FREQ -gt 30 ]
	then
		MESSAGE="Invalid Frequency Range"
		echo_fail
		exit_nochange
	elif [ $INPUT_AUTO_FREQ -lt 1 ]
	then
		if [ $CRON_EXIST == 1 ]
		then
			clear_cron

			MESSAGE="Sync Automation Disabled"
			echo_warn
		else
			MESSAGE="No Sync Automation Scheduled"
			echo_warn
		fi
	else
		if [ $CRON_EXIST == 1 ]
		then
			clear_cron
		fi

		MESSAGE="Saving New Sync Automation"
		echo_stat
		(crontab -l 2>/dev/null; echo "*/${INPUT_AUTO_FREQ} * * * * ${BASH_PATH} $HOME/${LOCAL_FOLDR}/${GS_FILENAME} smart > ${LOG_PATH}/${CRONJOB_LOG}") | crontab -
			error_validate
	fi

	MESSAGE="Configuring Daily Backup Frequency"
	echo_info

	if [[ $2 =~ ^[0-9][0-9]?$ ]]
	then
		INPUT_AUTO_BACKUP=$2
	else
		MESSAGE="Hour of Day to Backup (1-24) or 0 to Disable"
		echo_need
		read INPUT_AUTO_BACKUP
	fi

	if [ $INPUT_AUTO_BACKUP -gt 24 ]
	then
		MESSAGE="Invalid Frequency Range"
		echo_fail
		exit_nochange
	elif [ $INPUT_AUTO_BACKUP -lt 1 ]
	then
		MESSAGE="No Backup Automation Scheduled"
		echo_warn
	else
		MESSAGE="Saving New Backup Automation"
		echo_stat
		(crontab -l 2>/dev/null; echo "0 ${INPUT_AUTO_BACKUP} * * * ${BASH_PATH} $HOME/${LOCAL_FOLDR}/${GS_FILENAME} backup >/dev/null 2>&1") | crontab -
			error_validate
	fi

	exit_withchange
}	

## Clear Existing Automation Settings
function clear_cron {
	MESSAGE="Removing Existing Automation"
	echo_stat

	crontab -l > cronjob-old.tmp
	sed "/${GS_FILENAME}/d" cronjob-old.tmp > cronjob-new.tmp
	crontab cronjob-new.tmp 2>/dev/null
		error_validate
	rm cronjob-old.tmp
	rm cronjob-new.tmp
}

## Configure Task
function task_configure {				
	TASKTYPE='CONFIGURE'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good
	
	if [ -f $HOME/${LOCAL_FOLDR}/${CONFIG_FILE} ]
	then		
		config_delete
	else
		MESSAGE="No Active ${CONFIG_FILE}"
		echo_warn
		
		config_generate
	fi

	backup_settime
	backup_local_gravity
	backup_local_custom
	backup_cleanup
	
	exit_withchange
}

## Devmode Task
function task_devmode {
	TASKTYPE='DEV'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good
	
	if [ -f $HOME/${LOCAL_FOLDR}/dev ]
	then
		MESSAGE="Disabling ${TASKTYPE}"
		echo_stat
		rm -f $HOME/${LOCAL_FOLDR}/dev
			error_validate
	elif [ -f $HOME/${LOCAL_FOLDR}/beta ]
	then
		MESSAGE="Disabling BETA"
		echo_stat
		rm -f $HOME/${LOCAL_FOLDR}/beta
			error_validate
		
		MESSAGE="Enabling ${TASKTYPE}"
		echo_stat
		touch $HOME/${LOCAL_FOLDR}/dev
			error_validate
	else
		MESSAGE="Enabling ${TASKTYPE}"
		echo_stat
		touch $HOME/${LOCAL_FOLDR}/dev
			error_validate
		
		git branch -r

		MESSAGE="Select Branch to Update Against"
		echo_need
		read INPUT_BRANCH

		echo -e "BRANCH='${INPUT_BRANCH}'" >> $HOME/${LOCAL_FOLDR}/dev
	fi
	
	MESSAGE="Run UPDATE to apply changes"
	echo_info
	
	exit_withchange
}

## Devmode Task
function task_betamode {
	TASKTYPE='BETA'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good
	
	if [ -f $HOME/${LOCAL_FOLDR}/beta ]
	then
		MESSAGE="Disabling ${TASKTYPE}"
		echo_stat
		rm -f $HOME/${LOCAL_FOLDR}/beta
			error_validate
	elif [ -f $HOME/${LOCAL_FOLDR}/dev ]
	then
		MESSAGE="Disabling DEV"
		echo_stat
		rm -f $HOME/${LOCAL_FOLDR}/dev
			error_validate
		
		MESSAGE="Enabling ${TASKTYPE}"
		echo_stat
		touch $HOME/${LOCAL_FOLDR}/beta
			error_validate
	else
		MESSAGE="Enabling ${TASKTYPE}"
		echo_stat
		touch $HOME/${LOCAL_FOLDR}/beta
			error_validate
	fi
	
	MESSAGE="Run UPDATE to apply changes"
	echo_info
	
	exit_withchange
}

## Update Task
function task_update {
	TASKTYPE='UPDATE'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	dbclient_warning
	
	update_gs

	exit_withchange
}

## Version Task
function task_version {
	TASKTYPE='VERSION'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	show_version
	exit_nochange
}

## Logs Task
function task_logs {
	TASKTYPE='LOGS'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	logs_gs
}

## Compare Task
function task_compare {
	TASKTYPE='COMPARE'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	# import_gs
	show_target
	validate_gs_folders
	validate_ph_folders
	validate_os_sshpass
	
	previous_md5
	md5_compare
}

## Cron Task
function task_cron {
	TASKTYPE='CRON'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good
	
	show_crontab
}

function task_invalid {
	echo_fail
	list_gs_arguments
}

## Purge Task
function task_purge {
	TASKTYPE="THE-PURGE"
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	MESSAGE="THIS WILL RESET YOUR ENTIRE GRAVITY SYNC INSTALLATION"
	echo_warn
	MESSAGE="This will remove:"
	echo_warn
	MESSAGE="- All backups files."
	echo_warn
	MESSAGE="- Your ${CONFIG_FILE} file."
	echo_warn

	if [ -f "$HOME/${LOCAL_FOLDR}/dev" ]
	then
		MESSAGE="- Your development branch updater."
	elif [ -f "$HOME/${LOCAL_FOLDR}/beta" ]
	then
		MESSAGE="- Your beta branch updater."
	fi
	echo_warn

	MESSAGE="- All cronjob/automation tasks."
	echo_warn
	MESSAGE="- All job history/logs."
	echo_warn
	MESSAGE="- Associated SSH id_rsa keys."
	echo_warn
	MESSAGE="This function cannot be undone!"
	echo_warn

	MESSAGE="YOU WILL NEED TO REBUILD GRAVITY SYNC AFTER EXECUTION"
	echo_warn

	MESSAGE="Pi-hole binaries, configuration and services ARE NOT impacted!"
	echo_info
	MESSAGE="Your device will continue to resolve and block DNS requests,"
	echo_info
	MESSAGE="but your ${GRAVITY_FI} and ${CUSTOM_DNS} WILL NOT sync anymore,"
	echo_info
	MESSAGE="until you reconfigure Gravity Sync on this device."
	echo_info

	intent_validate

	MESSAGE="Cleaning Gravity Sync Directory"
	echo_stat

	git clean -f -X -d >/dev/null 2>&1
		error_validate

	clear_cron

	MESSAGE="Deleting SSH Key-files"
		echo_stat

	rm -f $HOME/${SSH_PKIF} >/dev/null 2>&1
	rm -f $HOME/${SSH_PKIF}.pub >/dev/null 2>&1
		error_validate

	MESSAGE="Realigning Dilithium Matrix"
		echo_fail

	sleep 1

	update_gs
}

## Sudo Creation Task
function task_sudo {
	TASKTYPE='SUDO'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	MESSAGE="Creating Sudoer.d Template"
	echo_stat

	NEW_SUDO_USER=$(whoami)
	echo -e "${NEW_SUDO_USER} ALL=(ALL) NOPASSWD: ${PIHOLE_DIR}" > $HOME/${LOCAL_FOLDR}/templates/gs-nopasswd.sudo
		error_validate

	MESSAGE="Installing Sudoer.d File"
	echo_stat

	sudo install -m 0440 $HOME/${LOCAL_FOLDR}/templates/gs-nopasswd.sudo /etc/sudoers.d/gs-nopasswd
		error_validate
}

## Backup Task
function task_backup {
	TASKTYPE='BACKUP'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	backup_settime
	backup_local_gravity
	backup_local_custom
	backup_cleanup
	
	logs_export
	exit_withchange
}

function backup_settime {
	BACKUPTIMESTAMP=$(date +%F-%H%M%S)
}

function backup_local_gravity {
	MESSAGE="Performing Backup of Local ${GRAVITY_FI}"
	echo_stat
	
	sqlite3 ${PIHOLE_DIR}/${GRAVITY_FI} ".backup '$HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${GRAVITY_FI}.backup'"
		error_validate
}

function backup_local_custom {
	if [ "$SKIP_CUSTOM" != '1' ]
	then	
		if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
		then
			MESSAGE="Performing Backup Up Local ${CUSTOM_DNS}"
			echo_stat

			cp ${PIHOLE_DIR}/${CUSTOM_DNS} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${CUSTOM_DNS}.backup
			error_validate
		fi
	fi
}

function backup_remote_gravity {
	MESSAGE="Performing Backup of Remote ${GRAVITY_FI}"
	echo_stat
	
	CMD_TIMEOUT='60'
	CMD_REQUESTED="sudo sqlite3 ${PIHOLE_DIR}/${GRAVITY_FI} \".backup '${PIHOLE_DIR}/${GRAVITY_FI}.backup'\""
		create_sshcmd
}

function backup_remote_custom {
	if [ "$SKIP_CUSTOM" != '1' ]
	then	
			MESSAGE="Performing Backup of Remote ${CUSTOM_DNS}"
			echo_stat
	
			CMD_TIMEOUT='15'
			CMD_REQUESTED="sudo cp ${PIHOLE_DIR}/${CUSTOM_DNS} ${PIHOLE_DIR}/${CUSTOM_DNS}.backup"
				create_sshcmd
	fi
}

function backup_cleanup {
	MESSAGE="Cleaning Up Old Backups"
	echo_stat

	find $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/$(date +%Y)*.backup -mtime +${BACKUP_RETAIN} -type f -delete 
		error_validate
}

# Echo Stack
## Informative
function echo_info {
	echo -e "${INFO} ${YELLOW}${MESSAGE}${NC}"
}

## Warning
function echo_warn {
	echo -e "${WARN} ${PURPLE}${MESSAGE}${NC}"
}

## Executing
function echo_stat {
	echo -en "${STAT} ${MESSAGE}"
} 

## Success
function echo_good {
	echo -e "\r${GOOD} ${MESSAGE}"
}

## Failure
function echo_fail {
	echo -e "\r${FAIL} ${MESSAGE}"
}

## Request
function echo_need {
	echo -en "${NEED} ${MESSAGE}: "
}

# Root Check
function root_check {
	if [ ! "$EUID" -ne 0 ]
  	then 
		TASKTYPE='ROOT'
		MESSAGE="${MESSAGE} ${TASKTYPE}"
		echo_fail
	  	
		MESSAGE="${PROGRAM} Must Not Run as Root"
		echo_warn
		
		exit_nochange
	fi
}

# SCRIPT EXECUTION ###########################

	MESSAGE="${PROGRAM} ${VERSION} Executing"
	echo_info
	
	import_gs

	MESSAGE="Evaluating Arguments"
	echo_stat

	if [ "${ROOT_CHECK_AVOID}" != "1" ]
	then
		root_check
	fi

case $# in
	
	0)
		TASKTYPE='SMART'
		MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
		echo_good

		# import_gs
		show_target
		validate_gs_folders
		validate_ph_folders
		validate_sqlite3
		validate_os_sshpass

		smart_gs
		exit
	;;
	
	1)
   		case $1 in
		   sync)
				TASKTYPE='SMART'
				MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
				echo_good

				# import_gs
				show_target
				validate_gs_folders
				validate_ph_folders
				validate_sqlite3
				validate_os_sshpass

				smart_gs
				exit
 			;;

			smart)
				TASKTYPE='SMART'
				MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
				echo_good

				# import_gs
				show_target
				validate_gs_folders
				validate_ph_folders
				validate_sqlite3
				validate_os_sshpass

				smart_gs
				exit
 			;;

   	 		pull)
				TASKTYPE='PULL'
				MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
				echo_good

				# import_gs
				show_target
				validate_gs_folders
				validate_ph_folders
				validate_sqlite3
				validate_os_sshpass
					
				pull_gs
				exit
 			;;

			push)	
				TASKTYPE='PUSH'
				MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
				echo_good

				# import_gs
				show_target
				validate_gs_folders
				validate_ph_folders
				validate_sqlite3
				validate_os_sshpass
					
				push_gs
				exit
			;;

			restore)	
				TASKTYPE='RESTORE'
				MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
				echo_good

				# import_gs
				show_target
				validate_gs_folders
				validate_ph_folders
				validate_sqlite3

				restore_gs
				exit
			;;
	
			version)
				task_version
			;;
	
			update)
				task_update
			;;

			upgrade)
				task_update
			;;
			
			dev)
				task_devmode
			;;

			# beta)
			# 	task_betamode
			# ;;

			devmode)
				task_devmode
			;;

			development)
				task_devmode
			;;
	
			logs)
				task_logs
			;;
			
			compare)
				task_compare
			;;
			
			cron)
				task_cron
			;;
			
			config)
				task_configure
			;;

			configure)
				task_configure
			;;

			auto)
				task_automate
			;;	

			automate)
				task_automate
			;;	

			backup)
				task_backup
			;;

			purge)
				task_purge
			;;

			sudo)
				task_sudo
				exit_withchange
			;;

			*)
				task_invalid
			;;
		esac
	;;

	2)
   		case $1 in
			automate)
				task_automate
			;;	

		esac
	;;

	3)
   		case $1 in
			automate)
				task_automate $2 $3
			;;	

		esac
	;;
	
	*)
		task_invalid
	;;
esac

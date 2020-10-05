#!/bin/bash
SCRIPT_START=$SECONDS

# GRAVITY SYNC BY VMSTAN #####################
PROGRAM='Gravity Sync'
VERSION='3.0.0'

# Execute from the home folder of the user who owns it (ex: 'cd ~/gravity-sync')
# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# Requires Pi-Hole 5.x or higher already be installed, for help visit https://pi-hole.net

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

# Check Intent
source includes/gs-intent.sh

# GS Update Functions
source includes/gs-update.sh

# GS Hashing Functions
source includes/gs-hashing.sh

# Gravity Core Functions
source includes/gs-compare.sh
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

# Configuration Management
source includes/gs-config.sh

# Exit Codes
source includes/gs-exit.sh

# Automation Functions
source includes/gs-automate.sh

# Purge Functions
source include/gs-purge.sh

# Backup Functions
source include/gs-backup.sh

# Root Check
source include/gs-root.sh

# Invalid Tasks
function task_invalid {
	echo_fail
	list_gs_arguments
}

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
		task_smart ;;
	1)
   		case $1 in
			smart|sync)
				task_smart ;;
   	 		pull)
				task_pull ;;
			push)	
				task_push ;;
			restore)	
				task_restore ;;
			version)
				task_version ;;
			update|upgrade)
				task_update ;;
			dev|devmode|development)
				task_devmode ;;
			logs)
				task_logs ;;
			compare)
				task_compare ;;
			cron)
				task_cron ;;
			config|configure)
				task_configure ;;
			# auto|automate)
			#	task_automate ;;
			backup)
				task_backup ;;
			purge)
				task_purge ;;
			sudo)
				task_sudo
				exit_withchange
			;;

			*)
				task_invalid ;;
		esac
	;;

	2)
   		case $1 in
			auto|automate)
				task_automate ;;
		esac
	;;

	3)
   		case $1 in
			auto|automate)
				task_automate $2 $3 ;;	
		esac
	;;
	
	*)
		task_invalid ;;
esac

# END OF SCRIPT ##############################
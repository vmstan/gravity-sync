#!/bin/bash
SCRIPT_START=$SECONDS

# GRAVITY SYNC BY VMSTAN #####################
PROGRAM='Gravity Sync'
VERSION='3.1.0'

# Execute from the home folder of the user who owns it (ex: 'cd ~/gravity-sync')
# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# Requires Pi-Hole 5.x or higher already be installed, for help visit https://pi-hole.net

# REQUIRED SETTINGS ##########################

# Run './gravity-sync.sh config' to get started

# STANDARD VARIABLES #########################

# GS Folder/File Locations
GS_FILEPATH=$(realpath $0)
LOCAL_FOLDR=$(dirname $GS_FILEPATH)
CONFIG_FILE='gravity-sync.conf' 	# must exist with primary host/user configured
GS_FILENAME='gravity-sync.sh'		# must exist because it's this script
BACKUP_FOLD='backup' 				# must exist as subdirectory in LOCAL_FOLDR

# Logging Folder/File Locations
LOG_PATH="${LOCAL_FOLDR}"		# replace in gravity-sync.conf to overwrite
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
PIHOLE_DIR='/etc/pihole' 			# default Pi-hole data directory (local)
RIHOLE_DIR='/etc/pihole'			# default Pi-hole data directory (remote)
GRAVITY_FI='gravity.db' 			# default Pi-hole database file
CUSTOM_DNS='custom.list'			# default Pi-hole local DNS lookups
PIHOLE_BIN='/usr/local/bin/pihole' 	# default Pi-hole binary directory (local)
RIHOLE_BIN='/usr/local/bin/pihole' 	# default Pi-hole binary directory (remote)
FILE_OWNER='pihole:pihole'			# default Pi-hole file owner and group (local)
RILE_OWNER='pihole:pihole'				# default Pi-hole file owner and group (remote)
DOCKER_CON='pihole/pihole'			# default Pi-hole Docker container name (local)
ROCKER_CON='pihole/pihole'			# default Pi-hole Docker container name (remote)

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
source ${LOCAL_FOLDR}/includes/gs-colors.sh

# FUNCTION DEFINITIONS #######################

# Core Functions
source ${LOCAL_FOLDR}/includes/gs-core.sh

# Gravity Replication Functions
source ${LOCAL_FOLDR}/includes/gs-compare.sh
source ${LOCAL_FOLDR}/includes/gs-pull.sh
source ${LOCAL_FOLDR}/includes/gs-push.sh
source ${LOCAL_FOLDR}/includes/gs-smart.sh
source ${LOCAL_FOLDR}/includes/gs-restore.sh
source ${LOCAL_FOLDR}/includes/gs-backup.sh

# Hashing & SSH Functions
source ${LOCAL_FOLDR}/includes/gs-hashing.sh
source ${LOCAL_FOLDR}/includes/gs-ssh.sh

# Logging Functions
source ${LOCAL_FOLDR}/includes/gs-logging.sh

# Validation Functions
source ${LOCAL_FOLDR}/includes/gs-validate.sh
source ${LOCAL_FOLDR}/includes/gs-intent.sh
source ${LOCAL_FOLDR}/includes/gs-root.sh

# Configuration Management
source ${LOCAL_FOLDR}/includes/gs-config.sh
source ${LOCAL_FOLDR}/includes/gs-update.sh
source ${LOCAL_FOLDR}/includes/gs-automate.sh
source ${LOCAL_FOLDR}/includes/gs-purge.sh

# Exit Codes
source ${LOCAL_FOLDR}/includes/gs-exit.sh

# SCRIPT EXECUTION ###########################

case $# in
	0)
		start_gs
		task_smart ;;
	1)
		case $1 in
			smart|sync)
				start_gs
				task_smart ;;
			pull)
				start_gs
				task_pull ;;
			push)
				start_gs
				task_push ;;
			restore)
				start_gs
				task_restore ;;
			version)
				start_gs_noconfig
				task_version ;;
			update|upgrade)
				start_gs
				task_update ;;
			dev|devmode|development|develop)
				start_gs_noconfig
				task_devmode ;;
			logs|log)
				start_gs
				task_logs ;;
			compare)
				start_gs
				task_compare ;;
			cron)
				start_gs
				task_cron ;;
			config|configure)
				start_gs_noconfig
				task_configure ;;
			auto|automate)
				start_gs
				task_automate ;;
			backup)
				start_gs
				task_backup ;;
			purge)
				start_gs
				task_purge ;;
			sudo)
				start_gs
				task_sudo ;;
			*)
				start_gs
				task_invalid ;;
		esac
	;;

	2)
		case $1 in
			auto|automate)
				start_gs
				task_automate ;;
		esac
	;;

	3)
		case $1 in
			auto|automate)
				start_gs
				task_automate $2 $3 ;;	
		esac
	;;
	
	*)
		start_gs
		task_invalid ;;
esac

# END OF SCRIPT ##############################
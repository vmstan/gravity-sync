#!/bin/bash

# GRAVITY SYNC BY VMSTAN #####################
VERSION='1.2.3'

# Must execute from a location in the home folder of the user who own's it (ex: /home/pi/gravity-sync)
# Configure certificate based SSH authentication between the Pi-hole HA nodes - it does not use passwords
# Tested against Pihole 5.0 GA on Raspbian Buster and Ubuntu 20.04, but it should work on most configs
# More installation instructions available at https://vmstan.com/gravity-sync
# For the latest version please visit https://github.com/vmstan/gravity-sync under Releases

# REQUIRED SETTINGS ##########################

# You MUST define REMOTE_HOST and REMOTE_USER in a file called 'gravity-sync.conf' 
# You can copy the 'gravity-sync.conf.example' file in the script directory to get started 

# STANDARD VARIABLES #########################

# GS Folder/File Locations
LOCAL_FOLDR='gravity-sync' # must exist in running user home folder
CONFIG_FILE='gravity-sync.conf' # must exist as explained above
SYNCING_LOG='gravity-sync.log' # will be created in above folder
BACKUP_FOLD='backup'

# PH Folder/File Locations
PIHOLE_DIR='/etc/pihole'  # default install directory
GRAVITY_FI='gravity.db' # this should not change

# Script Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
NC='\033[0m'

##############################################
### DO NOT CHANGE ANYTHING BELOW THIS LINE ###
##############################################

# FUNCTION DEFINITIONS #######################

# Import Settings
function import_gs {
	echo -e "[${CYAN}STAT${NC}] Importing ${CONFIG_FILE} Settings"
	if [ -f ~/${LOCAL_FOLDR}/${CONFIG_FILE} ]
	then
	    source ${CONFIG_FILE}
		echo -e "[${GREEN}GOOD${NC}] Using ${REMOTE_USER}@${REMOTE_HOST}"
	else
		echo -e "[${RED}FAIL${NC}] Required ${CONFIG_FILE} Missing"
		echo -e "Please review installation documentation for more information"
		exit_nochange
	fi
}

# Update Function
function update_gs {
	TASKTYPE='UPDATE'
	logs_export 	# dumps log prior to execution because script stops after successful pull
	echo -e "[${PURPLE}WARN${NC}] Requires GitHub Installation"
		git reset --hard
		git pull
	exit
}

# Pull Function
function pull_gs {
	TASKTYPE='PULL'
	echo -e "[${CYAN}STAT${NC}] Copying ${GRAVITY_FI} from ${REMOTE_HOST}"
		rsync -v --progress -e 'ssh -p 22' ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} ~/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.last
	echo -e "[${CYAN}STAT${NC}] Backing Up Current ${GRAVITY_FI} on $HOSTNAME"
		sudo mv -v ${PIHOLE_DIR}/${GRAVITY_FI} ~/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.backup
	echo -e "[${CYAN}STAT${NC}] Replacing ${GRAVITY_FI} on $HOSTNAME"
		sudo cp -v ~/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.last ${PIHOLE_DIR}/${GRAVITY_FI}
		sudo chmod 644 ${PIHOLE_DIR}/${GRAVITY_FI}
		sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}
	echo -e "${GRAVITY_FI} ownership and file permissions reset"
	echo -e "[${CYAN}STAT${NC}] Reloading FTLDNS Configuration"
		pihole restartdns reloadlists
		pihole restartdns
	# echo -e "[${CYAN}STAT${NC}] Archiving Latest ${GRAVITY_FI}"
	#	mv -v ~/${LOCAL_FOLDR}/${GRAVITY_FI} ~/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.last
		logs_export
	exit_withchange
}

# Push Function
function push_gs {
	TASKTYPE='PUSH'
	echo -e "[${PURPLE}WARN${NC}] DATA LOSS IS POSSIBLE"
	echo -e "The standard use of this script is to ${YELLOW}PULL${NC} data from the primary PH server to the secondary."
	echo -e "By issuing a ${YELLOW}PUSH${NC} we will overwrite ${GRAVITY_FI} on ${YELLOW}${REMOTE_HOST}${NC} with ${YELLOW}$HOSTNAME${NC} server data."
	echo -e "No backup copies are made on the primary Pihole before or after executing this command!"
	echo -e ""
	echo -e "Are you sure you want to overwrite the primary node configuration on ${REMOTE_HOST}?"
	select yn in "Yes" "No"; do
		case $yn in
		Yes )
			# echo "Replacing gravity.db on primary"
			echo -e "[${CYAN}STAT${NC}] Copying ${GRAVITY_FI} to ${REMOTE_HOST}"
				rsync --rsync-path="sudo rsync" -v --progress -e 'ssh -p 22' ${PIHOLE_DIR}/${GRAVITY_FI} ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI}
			echo -e "[${CYAN}STAT${NC}] Applying Rermissions to Remote ${GRAVITY_FI}"
				ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo chmod 644 ${PIHOLE_DIR}/${GRAVITY_FI}"
				ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}"
			echo -e "[${CYAN}STAT${NC}] Reloading FTLDNS Configuration"
				ssh ${REMOTE_USER}@${REMOTE_HOST} 'pihole restartdns reloadlists'
				ssh ${REMOTE_USER}@${REMOTE_HOST} 'pihole restartdns'
				logs_export
			exit_withchange
		;;
		
		No )
			exit_nochange
		;;
		esac
	done
}

# Logging Functions
## Check Log Function
function logs_gs {
	echo -e "Recent ${YELLOW}PULL${NC} attempts"
		tail -n 10 ${SYNCING_LOG} | grep PULL
	echo -e "Recent ${YELLOW}UPDATE${NC} attempts"
		tail -n 10 ${SYNCING_LOG} | grep UPDATE
	echo -e "Recent ${YELLOW}PUSH${NC} attempts"
			tail -n 10 ${SYNCING_LOG} | grep PUSH
	exit_nochange
}

## Log Out
function logs_export {
	echo -e "[${CYAN}STAT${NC}] Logging Timestamps to ${SYNCING_LOG}"
	# date >> ~/${LOCAL_FOLDR}/${SYNCING_LOG}
	echo -e $(date) "[${TASKTYPE}]" >> ~/${LOCAL_FOLDR}/${SYNCING_LOG}
}

# Validate Functions
## Validate GS Folders
function validate_gs_folders {
	if [ -d ~/${LOCAL_FOLDR} ]
	then
	    echo -e "[${GREEN}GOOD${NC}] Required ~/${LOCAL_FOLDR} Located"
	else
		echo -e "[${RED}FAIL${NC}] Required ~/${LOCAL_FOLDR} Missing"
		exit_nochange
	fi
}

## Validate PH Folders
function validate_ph_folders {
	if [ -d ${PIHOLE_DIR} ]
	then
	    echo -e "[${GREEN}GOOD${NC}] Required ${PIHOLE_DIR} Located"
	else
		echo -e "[${RED}FAIL${NC}] Required ${PIHOLE_DIR} Missing"
		exit_nochange
	fi
}

# List GS Arguments
function list_gs_arguments {
	echo -e "Usage: $0 [options]"
	echo -e "Example: '$0 pull'"
	echo -e ""
	echo -e "Replication Options:"
	echo -e " ${YELLOW}pull${NC}		Sync the ${GRAVITY_FI} configuration on primary PH to this server"
	echo -e " ${YELLOW}push${NC}		Force any changes made on this server back to the primary PH"
	echo -e ""
	echo -e "Debugging Options:"
	echo -e " ${YELLOW}update${NC}		Use GitHub to update this script to the latest version available"
	echo -e " ${YELLOW}version${NC}	Display the version of the current installed script"
	echo -e " ${YELLOW}logs${NC}		Show recent successful jobs"
	echo -e ""
	exit_nochange
}

# Exit Codes
## No Changes Made
function exit_nochange {
	echo -e "[${CYAN}STAT${NC}] Exiting Without Making Changes"
	exit
}

## Changes Made
function exit_withchange {
	echo -e "[${CYAN}STAT${NC}] ${GRAVITY_FI} ${TASKTYPE} Completed"
	exit
}

# SCRIPT EXECUTION ###########################

echo -e "[${CYAN}STAT${NC}] Evaluating Script Arguments"

case $# in
	
	0)
		echo -e "[${RED}FAIL${NC}] Missing Required Arguments"
			list_gs_arguments
	;;
	
	1)
   		case $1 in
   	 		pull)
				echo -e "[${GREEN}GOOD${NC}] Pull Requested"
					import_gs

				echo -e "[${CYAN}STAT${NC}] Validating Folder Configuration"
					validate_gs_folders
					validate_ph_folders
					
				pull_gs
				exit
 			;;

			push)	
				echo -e "[${GREEN}GOOD${NC}] Push Requested"
					import_gs

				echo -e "[${CYAN}STAT${NC}] Validating Folder Configuration"
					validate_gs_folders
					validate_ph_folders
					
				push_gs
				exit
			;;
	
			version)
				echo -e "[ ${PURPLE}INFO${NC} ] Gravity Sync ${VERSION}"
				exit_nochange
			;;
	
			update)
				echo -e "[${GREEN}GOOD${NC}] Update Requested"
					update_gs
				exit_nochange
			;;
	
			logs)
				echo -e "[${GREEN}GOOD${NC}] Logs Requested"
					logs_gs
			;;

			*)
				echo -e "[${RED}FAIL${NC}] '${YELLOW}$1${NC}' is Invalid Argument"
        			list_gs_arguments
			;;
		esac
	;;
	
	*)
      echo -e "[${RED}FAIL${NC}] Too Many Arguments"
      	list_gs_arguments
      exit_nochange
	;;
esac
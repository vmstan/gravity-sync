#!/bin/bash

# Gravity Sync by vmstan
VERSION='1.2.1'

# Must execute from a location in the home folder of the user who own's it (ex: /home/pi/gravity-sync)
# Configure certificate based SSH authentication between the Pihole HA nodes - it does not use passwords
# Tested against Pihole 5.0 GA on Raspbian Buster and Ubuntu 20.04, but it should work on most configs
# More installation instructions available at https://vmstan.com/gravity-sync
# For the latest version please visit https://github.com/vmstan/gravity-sync under Releases

# You must define REMOTE_HOST and REMOTE_USER in a file called 'gravity-sync.conf' -- see above documentation 

# CUSTOMIZATION ##############################

# GS Folder/File Locations
LOCAL_FOLDR='gravity-sync' # must exist in running user home folder
SYNCING_LOG='gravity-sync.log' # will be created in above folder

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

# FUNCTION DEFINITIONS #######################

# Import Settings
function import_gs {
	echo -e "${CYAN}Importing gravity-sync.conf settings${NC}"
	if [ -f ~/${LOCAL_FOLDR}/gravity-sync.conf ]
	then
	    source gravity-sync.conf
		echo -e "${GREEN}Success${NC}: Configured for ${REMOTE_USER}@${REMOTE_HOST}"
	else
		echo -e "${RED}Failure${NC}: Required file gravity-sync.conf is missing!"
		echo -e "Please review installation documentation for more information"
		exit
	fi
}

# Update Function
function update_gs {
	TASKTYPE='UPDATE'
	logs_export 	# dumps log prior to execution because script stops after successful pull
	echo -e "${YELLOW}This update will fail if Gravity Sync was not installed via GitHub${NC}"
		git reset --hard
		git pull
	exit
}

# Pull Function
function pull_gs {
	TASKTYPE='PULL'
	echo -e "${CYAN}Copying ${GRAVITY_FI} from remote server ${REMOTE_HOST}${NC}"
		rsync -v --progress -e 'ssh -p 22' ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} ~/${LOCAL_FOLDR}/${GRAVITY_FI}
	echo -e "${CYAN}Backing up the running ${GRAVITY_FI} on this server${NC}"
		sudo mv -v ${PIHOLE_DIR}/${GRAVITY_FI} ${PIHOLE_DIR}/${GRAVITY_FI}.backup
	echo -e "${CYAN}Replacing the ${GRAVITY_FI} configuration on this server${NC}"
		sudo cp -v ~/${LOCAL_FOLDR}/${GRAVITY_FI} ${PIHOLE_DIR}
		sudo chmod 644 ${PIHOLE_DIR}/${GRAVITY_FI}
		sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}
	echo -e "${GRAVITY_FI} ownership and file permissions reset"
	echo -e "${CYAN}Reloading FTLDNS with configuration from new ${GRAVITY_FI}${NC}"
		pihole restartdns reloadlists
		pihole restartdns
	echo -e "${CYAN}Retaining additional copy of remote ${GRAVITY_FI}${NC}"
		mv -v ~/${LOCAL_FOLDR}/${GRAVITY_FI} ~/${LOCAL_FOLDR}/${GRAVITY_FI}.last
	echo -e "${GREEN}gravity.db pull completed${NC}"
	logs_export
	exit
}

# Push Function
function push_gs {
	TASKTYPE='PUSH'
	echo -e "${YELLOW}WARNING: DATA LOSS IS POSSIBLE${NC}"
	echo -e "This will send the running ${GRAVITY_FI} from this server to your primary Pihole"
	echo -e "No backup copies are made on the primary Pihole before or after executing this command!"
	echo -e "Are you sure you want to overwrite the primary node configuration on ${REMOTE_HOST}?"
	select yn in "Yes" "No"; do
		case $yn in
		Yes )
			echo "Replacing gravity.db on primary"
			echo -e "${CYAN}Copying local ${GRAVITY_FI} to ${REMOTE_HOST}${NC}"
				rsync --rsync-path="sudo rsync" -v --progress -e 'ssh -p 22' ${PIHOLE_DIR}/${GRAVITY_FI} ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI}
			echo -e "${CYAN}Applying permissions to remote gravity.db${NC}"
				ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo chmod 644 ${PIHOLE_DIR}/${GRAVITY_FI}"
				ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}"
			echo -e "${CYAN}Reloading configuration on remote FTLDNS${NC}"
				ssh ${REMOTE_USER}@${REMOTE_HOST} 'pihole restartdns reloadlists'
				ssh ${REMOTE_USER}@${REMOTE_HOST} 'pihole restartdns'
			echo -e "${GREEN}gravity.db push completed${NC}"
				logs_export
			exit
		;;
		
		No )
			echo "No changes have been made to the system"
			exit
		;;
		esac
	done
}

# Logging Functions
## Check Log Function
function logs_gs {
	echo -e "Recent ${PURPLE}PULL${NC} attempts"
		tail -n 10 ${SYNCING_LOG} | grep PULL
	echo -e "Recent ${PURPLE}UPDATE${NC} attempts"
		tail -n 10 ${SYNCING_LOG} | grep UPDATE
	echo -e "Recent ${PURPLE}PUSH${NC} attempts"
			tail -n 10 ${SYNCING_LOG} | grep PUSH
}

## Log Out
function logs_export {
	echo -e "Logging timestamps to ${SYNCING_LOG}"
	# date >> ~/${LOCAL_FOLDR}/${SYNCING_LOG}
	echo -e $(date) "[${TASKTYPE}]" >> ~/${LOCAL_FOLDR}/${SYNCING_LOG}
}

# Validate Functions
## Validate GS Folders
function validate_gs_folders {
	if [ -d ~/${LOCAL_FOLDR} ]
	then
	    echo -e "${GREEN}Success${NC}: Required directory ~/${LOCAL_FOLDR} is present"
	else
		echo -e "${RED}Failure${NC}: Required directory ~/${LOCAL_FOLDR} is missing"
		exit
	fi
}

## Validate PH Folders
function validate_ph_folders {
	if [ -d ${PIHOLE_DIR} ]
	then
	    echo -e "${GREEN}Success${NC}: Required directory ${PIHOLE_DIR} is present"
	else
		echo -e "${RED}Failure${NC}: Required directory ${PIHOLE_DIR} is missing"
		exit
	fi
}

## Validate GS Argument Used
function validate_gs_arguments {
	echo "Usage: $0 {pull|push}"
	echo -e "> ${YELLOW}Pull${NC} will copy the ${GRAVITY_FI} configuration on a remote host to this server"
	echo -e "> ${YELLOW}Push${NC} will force any changes made on this server to the primary"
	echo -e "No changes have been made to the system"
  	exit 1
}

# SCRIPT EXECUTION ###########################

echo -e "${CYAN}Evaluating $0 script arguments${NC}"

case $# in
	
	0)
		echo -e "${RED}Failure${NC}: ${GRAVITY_FI} replication direction required"
		validate_gs_arguments
	;;
	
	1)
   		case $1 in
   	 		pull)
				echo -e "${GREEN}Success${NC}: Pull Requested"
					import_gs

				echo -e "${CYAN}Validating sync folder configuration${NC}"
					validate_gs_folders
					validate_ph_folders
					
				pull_gs
				exit
 			;;

			push)	
				echo -e "${GREEN}Success${NC}: Push Requested"
					import_gs

				echo -e "${CYAN}Validating sync folder configuration${NC}"
					validate_gs_folders
					validate_ph_folders
					
				push_gs
				exit
			;;
	
			version)
				echo -e "${PURPLE}Info:${NC} Gravity Sync ${VERSION}"
				echo -e "No changes have been made to the system"
				exit
			;;
	
			update)
				echo -e "${GREEN}Success:${NC} Update Requested"
					update_gs
				exit
			;;
	
			logs)
				echo -e "${GREEN}Success:${NC} Logs Requested"
					logs_gs
			;;

			*)
				echo -e "${RED}'$1' is not a valid argument${NC}"
        		echo "Usage: $0 {pull|push}"
        		exit 2
			;;
		esac
	;;
	
	*)
      echo -e "${RED}Too many arguments provided ($#)${NC}"
      echo "Usage: $0 {pull|push}"
      exit 3
	;;
esac
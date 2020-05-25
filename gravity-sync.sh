#!/bin/bash

# GRAVITY SYNC BY VMSTAN #####################
PROGRAM='Gravity Sync'
VERSION='1.3.1'

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
CRONJOB_LOG='gravity-sync.cron' # only used if cron is configured to output to this file
BACKUP_FOLD='backup' # must exist as subdirectory in LOCAL_FOLD

# PH Folder/File Locations
PIHOLE_DIR='/etc/pihole'  # default install directory
GRAVITY_FI='gravity.db' # this should not change

##############################################
### DO NOT CHANGE ANYTHING BELOW THIS LINE ###
##############################################

# Script Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
NC='\033[0m'

# Message Codes
FAIL="[${RED}FAIL${NC}]"
WARN="[${PURPLE}WARN${NC}]"
GOOD="[${GREEN}DONE${NC}]"
STAT="[${CYAN}EXEC${NC}]"
INFO="[${YELLOW}INFO${NC}]"

# FUNCTION DEFINITIONS #######################

# Import Settings
function import_gs {
	MESSAGE="Importing ${CONFIG_FILE} Settings"
	echo -e "${STAT} $MESSAGE"
	if [ -f $HOME/${LOCAL_FOLDR}/${CONFIG_FILE} ]
	then
	    source $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
			error_validate
			
		MESSAGE="Using ${REMOTE_USER}@${REMOTE_HOST}"
		echo -e "${INFO} ${MESSAGE}"
	else
		
		echo -e "${FAIL} ${MESSAGE}"
		
		MESSAGE="${CONFIG_FILE} Missing"
		echo -e "${INFO} ${MESSAGE}"
		
		exit_nochange
	fi
}

# Update Function
function update_gs {
	TASKTYPE='UPDATE'
	logs_export 	# dumps log prior to execution because script stops after successful pull
	
	MESSAGE="Requires GitHub Installation" 
	echo -e "${INFO} ${MESSAGE}"
		git reset --hard
		git pull
		
	exit
}

# Developer Build Update
function beta_gs {
	TASKTYPE='BETA'
	logs_export 	# dumps log prior to execution because script stops after successful pull
	
	MESSAGE="Requires GitHub Installation" 
	echo -e "${INFO} ${MESSAGE}"
		git reset --hard
		git pull
		git checkout origin/development
		
	exit
}

# Pull Function
function pull_gs {
	TASKTYPE='PULL'
	
	echo -e "${INFO} ${TASKTYPE} Requested"
	md5_compare
	
	MESSAGE="Pulling ${GRAVITY_FI} from ${REMOTE_HOST}"
	echo -e "${STAT} ${MESSAGE}"
		rsync -v -e 'ssh -p 22' ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull
		error_validate
	
	MESSAGE="Backing Up ${GRAVITY_FI} on $HOSTNAME"
	echo -e "${STAT} ${MESSAGE}"
		cp -v ${PIHOLE_DIR}/${GRAVITY_FI} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.backup
		error_validate
	
	MESSAGE="Replacing ${GRAVITY_FI} on $HOSTNAME"
	echo -e "${STAT} ${MESSAGE}"	
		sudo cp -v $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull ${PIHOLE_DIR}/${GRAVITY_FI}
		error_validate
	
	MESSAGE="Setting Permissions on ${GRAVITY_FI}"
	echo -e "${STAT} ${MESSAGE}"	
		sudo chmod 644 ${PIHOLE_DIR}/${GRAVITY_FI}
		error_validate
		
	MESSAGE="Setting Ownership on ${GRAVITY_FI}"
	echo -e "${STAT} ${MESSAGE}"	
		sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}
		error_validate
		
	sleep 3	
	
	MESSAGE="Updating FTLDNS Configuration"
	echo -e "${STAT} ${MESSAGE}"
		pihole restartdns reloadlists
		error_validate
	
	MESSAGE="Reloading FTLDNS Services"
	echo -e "${STAT} ${MESSAGE}"
		pihole restartdns
		error_validate
	
	logs_export
	exit_withchange
}

# Push Function
function push_gs {
	TASKTYPE='PUSH'
	
	echo -e "${INFO} ${TASKTYPE} Requested"
	md5_compare
	
	echo -e "${WARN} Are you sure you want to overwrite the primary node configuration on ${REMOTE_HOST}?"
	select yn in "Yes" "No"; do
		case $yn in
		Yes )
			
			MESSAGE="Backing Up ${GRAVITY_FI} from ${REMOTE_HOST}"
			echo -e "${STAT} ${MESSAGE}"
				rsync -v -e 'ssh -p 22' ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.push
				error_validate
	
			MESSAGE="Pushing ${GRAVITY_FI} to ${REMOTE_HOST}"
			echo -e "${STAT} ${MESSAGE}"
				rsync --rsync-path="sudo rsync" -v -e 'ssh -p 22' ${PIHOLE_DIR}/${GRAVITY_FI} ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI}
				error_validate
	
			MESSAGE="Setting Permissions on ${GRAVITY_FI}"
			echo -e "${STAT} ${MESSAGE}"	
				ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo chmod 644 ${PIHOLE_DIR}/${GRAVITY_FI}"
				error_validate
		
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo -e "${STAT} ${MESSAGE}"	
				ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}"
				error_validate	
	
			sleep 3
	
			MESSAGE="Updating FTLDNS Configuration"
			echo -e "${STAT} ${MESSAGE}"
				ssh ${REMOTE_USER}@${REMOTE_HOST} 'pihole restartdns reloadlists'
				error_validate
			
			MESSAGE="Reloading FTLDNS Services"
			echo -e "${STAT} ${MESSAGE}"	
			
				ssh ${REMOTE_USER}@${REMOTE_HOST} 'pihole restartdns'
				error_validate
			
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
	echo -e "========================================================"
	echo -e "Recent Complete ${YELLOW}PULL${NC} Executions"
		tail -n 10 ${SYNCING_LOG} | grep PULL
	echo -e "Recent Complete ${YELLOW}UPDATE${NC} Executions"
		tail -n 10 ${SYNCING_LOG} | grep UPDATE
	echo -e "Recent Complete ${YELLOW}PUSH${NC} Executions"
			tail -n 10 ${SYNCING_LOG} | grep PUSH
	echo -e "========================================================"
	exit_nochange
}

## Check Last Crontab
function logs_crontab {
	echo -e "========================================================"
	echo -e "========================================================"
	echo -e ""
	cat ${CRONJOB_LOG}
	echo -e ""
	echo -e "========================================================"
	echo -e "========================================================"
}

## Log Out
function logs_export {
	echo -e "${INFO} Logging Timestamps to ${SYNCING_LOG}"
	# date >> $HOME/${LOCAL_FOLDR}/${SYNCING_LOG}
	echo -e $(date) "[${TASKTYPE}]" >> $HOME/${LOCAL_FOLDR}/${SYNCING_LOG}
}

# Validate Functions
## Validate GS Folders
function validate_gs_folders {
	MESSAGE="Locating $HOME/${LOCAL_FOLDR}"
	echo -e "${STAT} ${MESSAGE}"
		if [ -d $HOME/${LOCAL_FOLDR} ]
		then
	    	echo -e "${GOOD} ${MESSAGE}"
		else
			echo -e "${FAIL} ${MESSAGE}"
			exit_nochange
		fi
	
	MESSAGE="Locating $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}"
	echo -e "${STAT} ${MESSAGE}"
		if [ -d $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD} ]
		then
	    	echo -e "${GOOD} ${MESSAGE}"
		else
			echo -e "${FAIL} ${MESSAGE}"
			exit_nochange
		fi
}

## Validate PH Folders
function validate_ph_folders {
	MESSAGE="Locating ${PIHOLE_DIR}"
	echo -e "${STAT} ${MESSAGE}"
		if [ -d ${PIHOLE_DIR} ]
		then
	    	echo -e "${GOOD} ${MESSAGE}"
		else
			echo -e "${FAIL} ${MESSAGE}"
			exit_nochange
		fi
}

## Validate SSHPASS
function validate_os_sshpass {
    if hash sshpass 2>/dev/null
    then
		if test -z "$REMOTE_PASS"
		then
			sshpassword=''
			MESSAGE="Using SSH Key-Pair Authentication"
		else
			sshpassword="sshpass -p ${REMOTE_PASS} "
			MESSAGE="Using SSH Password Authentication"
		fi
    else
        sshpassword=''
		MESSAGE="Using SSH Key-Pair Authentication"
    fi
	
	echo -e "$INFO $MESSAGE"
}

# List GS Arguments
function list_gs_arguments {
	echo -e "Usage: $0 [options]"
	echo -e "Example: '$0 pull'"
	echo -e ""
	echo -e "Replication Options:"
	echo -e " ${YELLOW}pull${NC}		Sync the ${GRAVITY_FI} configuration on primary PH to this server"
	echo -e " ${YELLOW}push${NC}		Force any changes made on this server back to the primary PH"
	echo -e " ${YELLOW}compare${NC}	Check to see if there is any variance between primary and secondary"
	echo -e ""
	echo -e "Update Options:"
	echo -e " ${YELLOW}update${NC}		Use GitHub to update this script to the latest version available"
	echo -e " ${YELLOW}beta${NC}		Use GitHub to update this script to the latest beta version available"
	echo -e ""
	echo -e "Debug Options:"
	echo -e " ${YELLOW}version${NC}	Display the version of the current installed script"
	echo -e " ${YELLOW}logs${NC}		Show recent successful jobs"
	echo -e " ${YELLOW}cron${NC}		Display output of last crontab execution"
	echo -e ""
	exit_nochange
}

# Exit Codes
## No Changes Made
function exit_nochange {
	echo -e "${INFO} ${PROGRAM} ${TASKTYPE} Aborting"
	exit 0
}

## Changes Made
function exit_withchange {
	echo -e "${INFO} ${PROGRAM} ${TASKTYPE} Completed"
	exit 0
}

# Error Validation
function error_validate {
	if [ "$?" != "0" ]; then
	    echo -e "${FAIL} ${MESSAGE}"
	    exit 1
	else
		echo -e "${GOOD} ${MESSAGE}"
	fi
}

# Output Version
function show_version {
	echo -e "${INFO} ${PROGRAM} ${VERSION}"
}

# Look for Changes
function md5_compare {
	echo -e "${INFO} Comparing ${GRAVITY_FI} Changes"
	
	MESSAGE="Analyzing Remote ${GRAVITY_FI}"
	echo -e "${STAT} ${MESSAGE}"
	primaryMD5=$(${sshpassword}ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'md5sum /etc/pihole/gravity.db')
		error_validate
	
	MESSAGE="Analyzing Local ${GRAVITY_FI}"
	echo -e "${STAT} ${MESSAGE}"
	secondMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI})
		error_validate
	
	if [ "$primaryMD5" == "$secondMD5" ]
	then
		echo -e "${INFO} No Changes in ${GRAVITY_FI}"
		exit_nochange
	else
		echo -e "${INFO} Changes Detected in ${GRAVITY_FI}"
	fi
	
}

# SCRIPT EXECUTION ###########################
	
	MESSAGE="Evaluating Script Arguments"
	echo -e "${STAT} ${MESSAGE}"

case $# in
	
	0)
		echo -e "${FAIL} ${MESSAGE}"
			list_gs_arguments
	;;
	
	1)
   		case $1 in
   	 		pull)
				echo -e "${GOOD} ${MESSAGE}"
				
				import_gs
				
				MESSAGE="Validating Folder Configuration"
				echo -e "${INFO} ${MESSAGE}"
					validate_gs_folders
					validate_ph_folders
					validate_os_sshpass
					
				pull_gs
				exit
 			;;

			push)	
				echo -e "${GOOD} ${MESSAGE}"
				
				import_gs

				echo -e "${INFO} Validating Folder Configuration"
					validate_gs_folders
					validate_ph_folders
					validate_os_sshpass
					
				push_gs
				exit
			;;
	
			version)
				TASKTYPE='VERSION'
				show_version
				exit_nochange
			;;
	
			update)
				# TASKTYPE='UPDATE'
				echo -e "${GOOD} ${MESSAGE}"
				
				echo -e "${INFO} Update Requested"
					update_gs
				exit_nochange
			;;
			
			beta)
				# TASKTYPE='BETA'
				echo -e "${GOOD} ${MESSAGE}"
				
				echo -e "${INFO} Beta Update Requested"
					beta_gs
				exit_nochange
			;;
	
			logs)
				TASKTYPE='LOGS'
				MESSAGE="Logs Requested"
				echo -e "${GOOD} ${MESSAGE}"
					logs_gs
			;;
			
			compare)
				TASKTYPE='COMPARE'
				
				echo -e "${GOOD} ${MESSAGE}"
					import_gs
				
				echo -e "${INFO} Validating Folder Configuration"
					validate_gs_folders
					validate_ph_folders
					validate_os_sshpass
					
				md5_compare
			;;
			
			cron)
				TASKTYPE='CRON'
				echo -e "${GOOD} ${MESSAGE}"
				
				CRONPATH="$HOME/${LOCAL_FOLDR}/${CRONJOB_LOG}"
				
				MESSAGE="Replaying Last Cronjob"
				echo -e "${STAT} ${MESSAGE}"
				
				if [ -f ${CRONPATH} ]
				then
					if [ -s ${CRONPATH} ]
						echo -e "${GOOD} ${MESSAGE}"
							logs_crontab
							exit_nochange
					then
						echo -e "${FAIL} ${MESSAGE}"
						echo -e "${INFO} ${CRONPATH} appears empty"
							exit_nochange
					fi
				else
					echo -e "${FAIL} ${MESSAGE}"
					echo -e "${YELLOW}${CRONPATH}${NC} cannot be located"
						exit_nochange
				fi
				
			;;

			*)
				MESSAGE="'${YELLOW}$1${NC}' is an Invalid Argument"
				echo -e "${FAIL} ${MESSAGE}"
        			list_gs_arguments
					exit_nochange
			;;
		esac
	;;
	
	*)
		MESSAGE="Too Many Arguments"
		echo -e "${FAIL} ${MESSAGE}"
			list_gs_arguments
			exit_nochange
	;;
esac
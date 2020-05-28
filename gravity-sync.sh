#!/bin/bash

# GRAVITY SYNC BY VMSTAN #####################
PROGRAM='Gravity Sync'
VERSION='1.5.0'

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

# PH Folder/File Locations
PIHOLE_DIR='/etc/pihole' 			# default PH data directory
GRAVITY_FI='gravity.db' 			# default PH database file
PIHOLE_BIN='/usr/local/bin/pihole' 	# default PH binary directory

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

# Script Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
NC='\033[0m'

# Message Codes
FAIL="[${RED}FAIL${NC}]"
WARN="[${PURPLE}WARN${NC}]"
GOOD="[${GREEN}DONE${NC}]"
STAT="[${CYAN}EXEC${NC}]"
INFO="[${YELLOW}INFO${NC}]"
NEED="[${BLUE}NEED${NC}]"

# FUNCTION DEFINITIONS #######################

# Import Settings
function import_gs {
	MESSAGE="Importing ${CONFIG_FILE} Settings"
	echo -en "${STAT} $MESSAGE"
	if [ -f $HOME/${LOCAL_FOLDR}/${CONFIG_FILE} ]
	then
	    source $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
			error_validate
			
		MESSAGE="Using ${REMOTE_USER}@${REMOTE_HOST}"
		echo_info
	else
		echo_fail
		
		MESSAGE="${CONFIG_FILE} Missing"
		echo_info

		TASKTYPE='CONFIG'
		config_generate
		# echo -e "Please run ${YELLOW}$#${NC} again."
	fi
}

# GS Update Functions
## Master Branch
function update_gs {
	TASKTYPE='UPDATE'
	# logs_export 	# dumps log prior to execution because script stops after successful pull
	
	MESSAGE="Requires GitHub Installation" 
	echo_info
		git reset --hard
		git pull
	exit
}

## Developer Branch
function beta_gs {
	TASKTYPE='BETA'
	# logs_export 	# dumps log prior to execution because script stops after successful pull
	
	MESSAGE="Requires GitHub Installation" 
	echo_info
		git reset --hard
		git fetch origin
		git pull origin development
	exit
}

# Gravity Core Functions
## Pull Function
function pull_gs {
	md5_compare
	
	MESSAGE="Backing Up ${GRAVITY_FI} on $HOSTNAME"
	echo_stat
		cp ${PIHOLE_DIR}/${GRAVITY_FI} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.backup >/dev/null 2>&1
		error_validate
	
	MESSAGE="Pulling ${GRAVITY_FI} from ${REMOTE_HOST}"
	echo_stat
		${SSHPASSWORD} rsync -e "ssh -p ${SSH_PORT} -i $HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull >/dev/null 2>&1
		error_validate
		
	MESSAGE="Replacing ${GRAVITY_FI} on $HOSTNAME"
	echo_stat	
		sudo cp $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
		error_validate
	
	MESSAGE="Validating Ownership on ${GRAVITY_FI}"
	echo_stat
		
		GRAVDB_OWN=$(ls -ld ${PIHOLE_DIR}/${GRAVITY_FI} | awk '{print $3 $4}')
		if [ $GRAVDB_OWN == "piholepihole" ]
		then
			echo_good
		else
			echo_fail
			
			MESSAGE="Attempting to Compensate"
			echo_info
			
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo_stat	
				sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate
		fi
		
	MESSAGE="Validating Permissions on ${GRAVITY_FI}"
	echo_stat
	
		GRAVDB_RWE=$(namei -m ${PIHOLE_DIR}/${GRAVITY_FI} | grep -v f: | grep ${GRAVITY_FI} | awk '{print $1}')
		if [ $GRAVDB_RWE = "-rw-rw-r--" ]
		then
			echo_good
		else
			echo_fail
				
			MESSAGE="Attempting to Compensate"
			echo_info
		
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo_stat
				sudo chmod 664 ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate
		fi
		
	MESSAGE="Inverting Tachyon Pulse"
	echo_info
		sleep 1	
	
	MESSAGE="Updating FTLDNS Configuration"
	echo_stat
		${PIHOLE_BIN} restartdns reloadlists >/dev/null 2>&1
		error_validate
	
	MESSAGE="Reloading FTLDNS Services"
	echo_stat
		${PIHOLE_BIN} restartdns >/dev/null 2>&1
		error_validate
	
	logs_export
	exit_withchange
}

## Push Function
function push_gs {
	md5_compare
	
	MESSAGE="Enter FIRE PHOTON TORPEDOS at this prompt to confirm"
	echo_need

	read INPUT_TORPEDOS

	if [ "${INPUT_TORPEDOS}" != "FIRE PHOTON TORPEDOS" ]
	then
		MESSAGE="${TASKTYPE} Aborted"
		echo_info
		exit_nochange
	fi

	MESSAGE="Backing Up ${GRAVITY_FI} from ${REMOTE_HOST}"
	echo_stat
		${SSHPASSWORD} rsync -e "ssh -p ${SSH_PORT} -i $HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.push >/dev/null 2>&1
		error_validate

	MESSAGE="Pushing ${GRAVITY_FI} to ${REMOTE_HOST}"
	echo_stat
		${SSHPASSWORD} rsync --rsync-path="sudo rsync" -e "ssh -p ${SSH_PORT} -i $HOME/${SSH_PKIF}" ${PIHOLE_DIR}/${GRAVITY_FI} ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
		error_validate

	MESSAGE="Setting Permissions on ${GRAVITY_FI}"
	echo_stat	
		${SSHPASSWORD} ssh -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "sudo chmod 664 ${PIHOLE_DIR}/${GRAVITY_FI}" >/dev/null 2>&1
		error_validate

	MESSAGE="Setting Ownership on ${GRAVITY_FI}"
	echo_stat	
		${SSHPASSWORD} ssh -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}" >/dev/null 2>&1
		error_validate	

	MESSAGE="Contacting Borg Collective"
	echo_info
		sleep 1	

	MESSAGE="Updating FTLDNS Configuration"
	echo_stat
		${SSHPASSWORD} ssh -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "${PIHOLE_BIN} restartdns reloadlists" >/dev/null 2>&1
		error_validate
	
	MESSAGE="Reloading FTLDNS Services"
	echo_stat	
		${SSHPASSWORD} ssh -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "${PIHOLE_BIN} restartdns" >/dev/null 2>&1
		error_validate
	
	logs_export
	exit_withchange
}

function restore_gs {
	MESSAGE="This will restore ${GRAVITY_FI} on $HOSTNAME with the previous version!"
	echo_warn

	MESSAGE="Enter FIRE ALL PHASERS at this prompt to confirm"
	echo_need

	read INPUT_PHASER

	if [ "${INPUT_PHASER}" != "FIRE ALL PHASERS" ]
	then
		MESSAGE="${TASKTYPE} Aborted"
		echo_info
		exit_nochange
	fi

	MESSAGE="Restoring ${GRAVITY_FI} on $HOSTNAME"
	echo_stat	
		sudo cp $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.backup ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
		error_validate
	
	MESSAGE="Validating Ownership on ${GRAVITY_FI}"
	echo_stat
		
		GRAVDB_OWN=$(ls -ld ${PIHOLE_DIR}/${GRAVITY_FI} | awk '{print $3 $4}')
		if [ $GRAVDB_OWN == "piholepihole" ]
		then
			echo_good
		else
			echo_fail
			
			MESSAGE="Attempting to Compensate"
			echo_info
			
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo_stat	
				sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate
		fi
		
	MESSAGE="Validating Permissions on ${GRAVITY_FI}"
	echo_stat
	
		GRAVDB_RWE=$(namei -m ${PIHOLE_DIR}/${GRAVITY_FI} | grep -v f: | grep ${GRAVITY_FI} | awk '{print $1}')
		if [ $GRAVDB_RWE = "-rw-rw-r--" ]
		then
			echo_good
		else
			echo_fail
				
			MESSAGE="Attempting to Compensate"
			echo_info
		
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo_stat
				sudo chmod 664 ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate
		fi
		
	MESSAGE="Evacuating Turbolifts"
	echo_info
		sleep 1	
	
	MESSAGE="Updating FTLDNS Configuration"
	echo_stat
		${PIHOLE_BIN} restartdns reloadlists >/dev/null 2>&1
		error_validate
	
	MESSAGE="Reloading FTLDNS Services"
	echo_stat
		${PIHOLE_BIN} restartdns >/dev/null 2>&1
		error_validate
	
	logs_export
	exit_withchange
}

# Logging Functions
## Core Logging
### Write Logs Out
function logs_export {
	MESSAGE="Logging Timestamps to ${SYNCING_LOG}"
	echo_info

	echo -e $(date) "[${TASKTYPE}]" >> ${LOG_PATH}/${SYNCING_LOG}
}

### Output Sync Logs
function logs_gs {
	import_gs

	MESSAGE="Tailing ${LOG_PATH}/${SYNCING_LOG}"
	echo_info

	echo -e "========================================================"
	echo -e "Recent Complete ${YELLOW}PULL${NC} Executions"
		tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep PULL
	echo -e "Recent Complete ${YELLOW}PUSH${NC} Executions"
		tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep PUSH
	echo -e "========================================================"

	exit_nochange
}

## Crontab Logs
### Core Crontab Logs
function show_crontab {
	import_gs
	
	MESSAGE="Replaying Last Cronjob"
	echo_stat
	
	if [ -f ${LOG_PATH}/${CRONJOB_LOG} ]
	then
		if [ -s ${LOG_PATH}/${CRONJOB_LOG} ]
			echo_good
			
			MESSAGE="Tailing ${LOG_PATH}/${CRONJOB_LOG}"
			echo_info

			echo -e "========================================================"
			date -r ${LOG_PATH}/${CRONJOB_LOG}
			cat ${LOG_PATH}/${CRONJOB_LOG}
			echo -e "========================================================"

			exit_nochange
		then
			echo_fail

			MESSAGE="${LOG_PATH}/${CRONJOB_LOG} is Empty"
			echo_info

			exit_nochange
		fi
	else
		echo_fail

		MESSAGE="${LOG_PATH}/${CRONJOB_LOG} is Missing"
		echo_info

		exit_nochange
	fi
}

# Validate Functions
## Validate GS Folders
function validate_gs_folders {
	MESSAGE="Locating $HOME/${LOCAL_FOLDR}"
	echo_stat
		if [ -d $HOME/${LOCAL_FOLDR} ]
		then
	    	echo_good
		else
			echo_fail
			exit_nochange
		fi
	
	MESSAGE="Locating $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}"
	echo_stat
		if [ -d $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD} ]
		then
	    	echo_good
		else
			echo_fail
			exit_nochange
		fi
}

## Validate PH Folders
function validate_ph_folders {
	MESSAGE="Locating ${PIHOLE_DIR}"
	echo_stat
		if [ -d ${PIHOLE_DIR} ]
		then
	    	echo_good
		else
			echo_fail
			exit_nochange
		fi
}

## Validate SSHPASS
function validate_os_sshpass {
	MESSAGE="Checking SSH Configuration"
    echo_info
	
	if hash sshpass 2>/dev/null
    then
		if test -z "$REMOTE_PASS"
		then
			SSHPASSWORD=''
			MESSAGE="Using SSH Key-Pair Authentication"
		else
			timeout 5 ssh -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'exit' >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				SSHPASSWORD="sshpass -p ${REMOTE_PASS}"
				MESSAGE="Using SSH Password Authentication"
			else
		        SSHPASSWORD=''
				MESSAGE="Using SSH Key-Pair Authentication"
			fi
			
		fi
    else
        SSHPASSWORD=''
		MESSAGE="Using SSH Key-Pair Authentication"
    fi
	
	echo_info
	
	MESSAGE="Testing SSH Connection"
	echo_stat
		timeout 5 ${SSHPASSWORD} ssh -p ${SSH_PORT} -i '$HOME/${SSH_PKIF}' -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'exit' >/dev/null 2>&1
			error_validate
}

## Error Validation
function error_validate {
	if [ "$?" != "0" ]; then
	    echo_fail
	    exit 1
	else
		echo_good
	fi
}

## Validate Sync Required
function md5_compare {
	MESSAGE="Comparing ${GRAVITY_FI} Changes"
	echo_info
	
	MESSAGE="Analyzing Remote ${GRAVITY_FI}"
	echo_stat
	primaryMD5=$(${SSHPASSWORD} ssh -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${PIHOLE_DIR}/${GRAVITY_FI}")
		error_validate
	
	MESSAGE="Analyzing Local ${GRAVITY_FI}"
	echo_stat
	secondMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI})
		error_validate
	
	if [ "$primaryMD5" == "$secondMD5" ]
	then
		MESSAGE="No Differences in ${GRAVITY_FI}"
		echo_info
		exit_nochange
	else
		MESSAGE="Changes Detected in ${GRAVITY_FI}"
		echo_info
	fi
}

# Configuration Management
## Generate New Configuration
function config_generate {
	MESSAGE="Creating ${CONFIG_FILE} from Template"
	echo_stat
	cp $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}.example $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
	error_validate
	
	MESSAGE="Enter IP or DNS of primary Pi-hole server"
	echo_need
	read INPUT_REMOTE_HOST
	
	MESSAGE="Enter SSH user with SUDO rights on primary Pi-hole server"
	echo_need
	read INPUT_REMOTE_USER
	
	MESSAGE="Saving Host to ${CONFIG_FILE}"
	echo_stat
	sed -i "/REMOTE_HOST='192.168.1.10'/c\REMOTE_HOST='${INPUT_REMOTE_HOST}'" $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
	error_validate
	
	MESSAGE="Saving User to ${CONFIG_FILE}"
	echo_stat
	sed -i "/REMOTE_USER='pi'/c\REMOTE_USER='${INPUT_REMOTE_USER}'" $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
	error_validate

	if hash sshpass 2>/dev/null
	then
		MESSAGE="SSHPASS Utility Detected"
		echo_info
		
		MESSAGE="Do you want to configure password based SSH authentication?"
		echo_warn
		MESSAGE="Your password will be stored clear-text in the ${CONFIG_FILE}!"
		echo_warn

		MESSAGE="Leave blank to use (preferred) SSH Key-Pair Authentication"
		echo_need
		read INPUT_REMOTE_PASS
				
		MESSAGE="Saving Password to ${CONFIG_FILE}"
		echo_stat
		sed -i "/REMOTE_PASS=''/c\REMOTE_PASS='${INPUT_REMOTE_PASS}'" $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
		error_validate
		
	else
		MESSAGE="SSHPASS Not Installed"
		echo_info
		
		MESSAGE="Defaulting to SSH Key-Pair Authentication"
		echo_info
	fi
	
	if [ -z $INPUT_REMOTE_PASS ]
	then
		if [ -f $HOME/${SSH_PKIF} ]
		then
			MESSAGE="Using Existing ~/${SSH_PKIF}"
			echo_info
		else
			MESSAGE="Generating ~/${SSH_PKIF}"
			echo_info
			
			MESSAGE="Accept All Defaults"
			echo_warn
			
			MESSAGE="Complete Key-Pair Creation"
			echo -e "${NEED} ${MESSAGE}"
			
			echo -e "========================================================"
			echo -e "========================================================"
			ssh-keygen -t rsa
			echo -e "========================================================"
			echo -e "========================================================"
		fi
	fi
	
	MESSAGE="Importing New ${CONFIG_FILE}"
	echo_stat
	source $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
	error_validate
	
	if [ -z $REMOTE_PASS ]
	then
		if [ -f $HOME/${SSH_PKIF} ]
		then
			MESSAGE="Registering Key-Pair on ${REMOTE_HOST}"
			echo_info
			
			MESSAGE="Enter ${REMOTE_USER}@${REMOTE_HOST} Password Below"
			echo -e "${NEED} ${MESSAGE}"
			
			echo -e "========================================================"
			echo -e "========================================================"
			ssh-copy-id -f -i $HOME/${SSH_PKIF}.pub ${REMOTE_USER}@${REMOTE_HOST}
			echo -e "========================================================"
			echo -e "========================================================"
		else
		MESSAGE="Error Creating Key-Pair"
		echo -e "${FAIL} ${MESSAGE}"
		fi
	fi
	
	validate_os_sshpass
	
	exit_withchange
}

## Delete Existing Configuration
function config_delete {
	source $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
	MESSAGE="Configuration File Exists"
	echo_warn
	
	echo -e "========================================================"
	cat $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
	echo -e "========================================================"
	
	MESSAGE="Are you sure you want to erase this configuration?"
	echo_warn

	MESSAGE="Enter EJECT THE WARPCORE at this prompt to confirm"
	echo_need

	read INPUT_WARPCORE

	if [ "${INPUT_WARPCORE}" != "EJECT THE WARPCORE" ]
	then
		MESSAGE="${TASKTYPE} Aborted"
		echo_info
		exit_nochange
	else
		MESSAGE="Erasing Existing Configuration"
		echo_stat
		rm -f $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
			error_validate
		config_generate
	fi
}

# Exit Codes
## No Changes Made
function exit_nochange {
	MESSAGE="${PROGRAM} ${TASKTYPE} Aborting"
	echo_info
	exit 0
}

## Changes Made
function exit_withchange {
	SCRIPT_END=$SECONDS
	MESSAGE="${PROGRAM} ${TASKTYPE} Completed in $((SCRIPT_END-SCRIPT_START)) seconds"
	echo_info
	exit 0
}

## List GS Arguments
function list_gs_arguments {
	echo -e "Usage: $0 [options]"
	echo -e "Example: '$0 pull'"
	echo -e ""
	echo -e "Setup Options:"
	echo -e " ${YELLOW}config${NC}		Create a new ${CONFIG_FILE} file"
	echo -e " ${YELLOW}automate${NC}	Add scheduled task to run sync"
	echo -e ""
	echo -e "Replication Options:"
	echo -e " ${YELLOW}pull${NC}		Sync the ${GRAVITY_FI} database on primary PH to this server"
	echo -e " ${YELLOW}push${NC}		Force any changes made on this server back to the primary PH"
	echo -e " ${YELLOW}restore${NC}	Restore ${GRAVITY_FI} on this server from previous copy"
	echo -e " ${YELLOW}compare${NC}	Just check for differences between primary and secondary"
	echo -e ""
	echo -e "Update Options:"
	echo -e " ${YELLOW}update${NC}		Use GitHub to update this script to the latest version"
	echo -e " ${YELLOW}beta${NC}		Use GitHub to update this script to the latest beta version"
	echo -e ""
	echo -e "Debug Options:"
	echo -e " ${YELLOW}version${NC}	Display your version of ${PROGRAM}"
	echo -e " ${YELLOW}logs${NC}		Show recent successful replication jobs"
	echo -e " ${YELLOW}cron${NC}		Display output of last crontab execution"
	echo -e ""
	exit_nochange
}

# Output Version
function show_version {
	MESSAGE="${PROGRAM} ${VERSION}"
	echo_info
}

# Task Stack
## Automate Task
function task_automate {
	TASKTYPE='AUTOMATE'
	echo_good

	import_gs

	CRON_CHECK=$(crontab -l | grep -q "${GS_FILENAME}"  && echo '1' || echo '0')
	if [ ${CRON_CHECK} == 1 ]
	then
		MESSAGE="Automation Task Already Exists"
		echo_info
		MESSAGE="Use 'crontab -e' to manually remove/edit"
		echo_info
		exit_nochange
	fi

	MESSAGE="Set Automation Frequency Per Hour"
	echo_info

	MESSAGE="1  = Every 60 Minutes"
	echo -e "++++++ ${MESSAGE}"
	MESSAGE="2  = Every 30 Minutes"
	echo -e "++++++ ${MESSAGE}"
	MESSAGE="4  = Every 15 Minutes"
	echo -e "++++++ ${MESSAGE}"
	MESSAGE="6  = Every 10 Minutes"
	echo -e "++++++ ${MESSAGE}"
	MESSAGE="12 = Every 05 Minutes"
	echo -e "++++++ ${MESSAGE}"
	
	MESSAGE="Input Automation Frequency"
	echo_need
	read INPUT_AUTO_FREQ

	if [ $INPUT_AUTO_FREQ == 1 ]
	then
		AUTO_FREQ='60'
	elif [ $INPUT_AUTO_FREQ == 2 ]
	then
		AUTO_FREQ='30'
	elif [ $INPUT_AUTO_FREQ == 4 ]
	then
		AUTO_FREQ='15'
	elif [ $INPUT_AUTO_FREQ == 6 ]
	then
		AUTO_FREQ='10'
	elif [ $INPUT_AUTO_FREQ == 12 ]
	then
		AUTO_FREQ='5'
	else
		MESSAGE="Invalid Input"
		echo -e "${FAIL} ${MESSAGE}"
		exit_nochange
	fi

	MESSAGE="Saving to Crontab"
	echo_stat
		(crontab -l 2>/dev/null; echo "*/${AUTO_FREQ} * * * * ${BASH_PATH} $HOME/${LOCAL_FOLDR}/${GS_FILENAME} pull > ${LOG_PATH}/${CRONJOB_LOG}") | crontab -
			error_validate

	exit_withchange
}	

# Echo Stack
## Informative
function echo_info {
	echo -e "${INFO} ${MESSAGE}"
}

## Warning
function echo_warn {
	echo -e "${WARN} ${MESSAGE}"
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



# SCRIPT EXECUTION ###########################
SCRIPT_START=$SECONDS
	
	MESSAGE="Evaluating Script Arguments"
	echo_stat

case $# in
	
	0)
		echo_fail
			list_gs_arguments
	;;
	
	1)
   		case $1 in
   	 		pull)
				TASKTYPE='PULL'
				echo_good

				MESSAGE="${TASKTYPE} Requested"
				echo_info
				
				import_gs
				
				MESSAGE="Validating Folder Configuration"
				echo_info
					validate_gs_folders
					validate_ph_folders
					validate_os_sshpass
					
				pull_gs
				exit
 			;;

			push)	
				TASKTYPE='PUSH'
				echo_good

				MESSAGE="${TASKTYPE} Requested"
				echo_info
				
				import_gs

				MESSAGE="Validating Folder Configuration"
				echo_info
					validate_gs_folders
					validate_ph_folders
					validate_os_sshpass
					
				push_gs
				exit
			;;

			restore)	
				TASKTYPE='RESTORE'
				echo_good

				MESSAGE="${TASKTYPE} Requested"
				echo_info
				
				import_gs

				MESSAGE="Validating Folder Configuration"
				echo_info
					validate_gs_folders
					validate_ph_folders
					# validate_os_sshpass
					
				restore_gs
				exit
			;;
	
			version)
				TASKTYPE='VERSION'
				echo_good

				MESSAGE="${TASKTYPE} Requested"
				echo_info

				show_version
				exit_nochange
			;;
	
			update)
				TASKTYPE='UPDATE'
				echo_good
				
				MESSAGE="${TASKTYPE} Requested"
				echo_info
				
				update_gs
				exit_nochange
			;;
			
			beta)
				TASKTYPE='BETA'
				echo_good

				MESSAGE="${TASKTYPE} Requested"
				echo_info
				
				beta_gs
				exit_nochange
			;;
	
			logs)
				TASKTYPE='LOGS'
				echo_good
				
				MESSAGE="${TASKTYPE} Requested"
				echo_info

				logs_gs
			;;
			
			compare)
				TASKTYPE='COMPARE'
				echo_good

				MESSAGE="${TASKTYPE} Requested"
				echo_info
				
				import_gs
				
				MESSAGE="Validating OS Configuration"
				echo_info

					validate_gs_folders
					validate_ph_folders
					validate_os_sshpass
					
				md5_compare
			;;
			
			cron)
				TASKTYPE='CRON'
				echo_good

				MESSAGE="${TASKTYPE} Requested"
				echo_info
				
				show_crontab
			;;
			
			config)
				TASKTYPE='CONFIGURE'
				echo_good

				MESSAGE="${TASKTYPE} Requested"
				echo_info
				
				if [ -f $HOME/${LOCAL_FOLDR}/${CONFIG_FILE} ]
				then		
					config_delete

				else
					MESSAGE="${CONFIG_FILE} Missing"
					echo_info
					
					config_generate
				fi
			;;

			auto)
				task_automate
			;;	

			automate)
				task_automate
			;;	

			*)
				echo_fail
        			list_gs_arguments
			;;
		esac
	;;
	
	*)
		echo_fail
			list_gs_arguments
	;;
esac
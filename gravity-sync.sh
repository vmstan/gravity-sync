#!/bin/bash

# GRAVITY SYNC BY VMSTAN #####################
PROGRAM='Gravity Sync'
VERSION='1.4.0'

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
PIHOLE_DIR='/etc/pihole'  # default PH data directory
GRAVITY_FI='gravity.db' # default 
PIHOLE_BIN='/usr/local/bin/pihole' # default PH binary directory

# SSH Configuration
SSH_PORT='22' # default SSH port
SSH_PKIF='.ssh/id_rsa.pub' # default local SSH key

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
		echo -e "${INFO} ${MESSAGE}"
	else
		
		echo -e "\r${FAIL} ${MESSAGE}"
		
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
	
	echo -e "${INFO} ${TASKTYPE} Commencing"
	
	MESSAGE="Backing Up ${GRAVITY_FI} on $HOSTNAME"
	echo -en "${STAT} ${MESSAGE}"
		cp ${PIHOLE_DIR}/${GRAVITY_FI} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.backup >/dev/null 2>&1
		error_validate
	
	MESSAGE="Pulling ${GRAVITY_FI} from ${REMOTE_HOST}"
	echo -en "${STAT} ${MESSAGE}"
		${SSHPASSWORD} rsync -e 'ssh -p ${SSH_PORT}' ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull >/dev/null 2>&1
		error_validate
		
	MESSAGE="Replacing ${GRAVITY_FI} on $HOSTNAME"
	echo -en "${STAT} ${MESSAGE}"	
		sudo cp $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
		error_validate
	
	MESSAGE="Validating Ownership on ${GRAVITY_FI}"
	echo -en "${STAT} ${MESSAGE}"
		
		GRAVDB_OWN=$(ls -ld ${PIHOLE_DIR}/${GRAVITY_FI} | awk '{print $3 $4}')
		if [ $GRAVDB_OWN == "piholepihole" ]
		then
			echo -e "\r${GOOD} ${MESSAGE}"
		else
			echo -e "\r${FAIL} $MESSAGE"
			
			MESSAGE2="Attempting to Compensate"
			echo -e "${INFO} ${MESSAGE2}"
			
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo -en "${STAT} ${MESSAGE}"	
				sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate
		fi
		
	MESSAGE="Validating Permissions on ${GRAVITY_FI}"
	echo -en "${STAT} ${MESSAGE}"
	
		GRAVDB_RWE=$(namei -m ${PIHOLE_DIR}/${GRAVITY_FI} | grep -v f: | grep ${GRAVITY_FI} | awk '{print $1}')
		if [ $GRAVDB_RWE = "-rw-r--r--" ]
		then
			echo -e "\r${GOOD} ${MESSAGE}"
		else
			echo -e "\r${FAIL} ${MESSAGE}"
				
			MESSAGE2="Attempting to Compensate"
			echo -e "${INFO} ${MESSAGE2}"
		
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo -en "${STAT} ${MESSAGE}"
				sudo chmod 644 ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate
		fi
		
	MESSAGE="Inverting Tachyon Pulse"
	echo -e "${INFO} ${MESSAGE}"
		sleep 1	
	
	MESSAGE="Updating FTLDNS Configuration"
	echo -en "${STAT} ${MESSAGE}"
		${PIHOLE_BIN} restartdns reloadlists >/dev/null 2>&1
		error_validate
	
	MESSAGE="Reloading FTLDNS Services"
	echo -en "${STAT} ${MESSAGE}"
		${PIHOLE_BIN} restartdns >/dev/null 2>&1
		error_validate
	
	logs_export
	exit_withchange
}

# Push Function
function push_gs {
	TASKTYPE='PUSH'
	
	echo -e "${INFO} ${TASKTYPE} Requested"
	md5_compare
	
	echo -e "${WARN} Are you sure you want to overwrite the primary PH configuration on ${REMOTE_HOST}?"
	select yn in "Yes" "No"; do
		case $yn in
		Yes )
			
			MESSAGE="Backing Up ${GRAVITY_FI} from ${REMOTE_HOST}"
			echo -en "${STAT} ${MESSAGE}"
				${SSHPASSWORD} rsync -e 'ssh -p ${SSH_PORT}' ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.push >/dev/null 2>&1
				error_validate
	
			MESSAGE="Pushing ${GRAVITY_FI} to ${REMOTE_HOST}"
			echo -en "${STAT} ${MESSAGE}"
				${SSHPASSWORD} rsync --rsync-path="sudo rsync" -e 'ssh -p ${SSH_PORT}' ${PIHOLE_DIR}/${GRAVITY_FI} ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate
	
			MESSAGE="Setting Permissions on ${GRAVITY_FI}"
			echo -en "${STAT} ${MESSAGE}"	
				${SSHPASSWORD} ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo chmod 644 ${PIHOLE_DIR}/${GRAVITY_FI}" >/dev/null 2>&1
				error_validate
		
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo -en "${STAT} ${MESSAGE}"	
				${SSHPASSWORD} ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}" >/dev/null 2>&1
				error_validate	
	
			MESSAGE="Contacting Borg Collective"
			echo -e "${INFO} ${MESSAGE}"
				sleep 1	
	
			MESSAGE="Updating FTLDNS Configuration"
			echo -en "${STAT} ${MESSAGE}"
				${SSHPASSWORD} ssh ${REMOTE_USER}@${REMOTE_HOST} '${PIHOLE_BIN} restartdns reloadlists' >/dev/null 2>&1
				error_validate
			
			MESSAGE="Reloading FTLDNS Services"
			echo -en "${STAT} ${MESSAGE}"	
				${SSHPASSWORD} ssh ${REMOTE_USER}@${REMOTE_HOST} '${PIHOLE_BIN} restartdns' >/dev/null 2>&1
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

## Crontab Logic
function show_crontab {
	CRONPATH="$HOME/${LOCAL_FOLDR}/${CRONJOB_LOG}"
	
	MESSAGE="Replaying Last Cronjob"
	echo -en "${STAT} ${MESSAGE}"
	
	if [ -f ${CRONPATH} ]
	then
		if [ -s ${CRONPATH} ]
			echo -e "\r${GOOD} ${MESSAGE}"
				logs_crontab
				exit_nochange
		then
			echo -e "\r${FAIL} ${MESSAGE}"
			echo -e "${INFO} ${CRONPATH} appears empty"
				exit_nochange
		fi
	else
		echo -e "\r${FAIL} ${MESSAGE}"
		echo -e "${INFO} ${CRONPATH} cannot be located"
			exit_nochange
	fi
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
	echo -en "${STAT} ${MESSAGE}"
		if [ -d $HOME/${LOCAL_FOLDR} ]
		then
	    	echo -e "\r${GOOD} ${MESSAGE}"
		else
			echo -e "\r${FAIL} ${MESSAGE}"
			exit_nochange
		fi
	
	MESSAGE="Locating $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}"
	echo -en "${STAT} ${MESSAGE}"
		if [ -d $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD} ]
		then
	    	echo -e "\r${GOOD} ${MESSAGE}"
		else
			echo -e "\r${FAIL} ${MESSAGE}"
			exit_nochange
		fi
}

## Validate PH Folders
function validate_ph_folders {
	MESSAGE="Locating ${PIHOLE_DIR}"
	echo -en "${STAT} ${MESSAGE}"
		if [ -d ${PIHOLE_DIR} ]
		then
	    	echo -e "\r${GOOD} ${MESSAGE}"
		else
			echo -e "\r${FAIL} ${MESSAGE}"
			exit_nochange
		fi
}

## Validate SSHPASS
function validate_os_sshpass {
    echo -e "${INFO} Checking SSH Configuration"
	
	if hash sshpass 2>/dev/null
    then
		if test -z "$REMOTE_PASS"
		then
			SSHPASSWORD=''
			MESSAGE="Using SSH Key-Pair Authentication"
		else
			timeout 5 ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'exit' >/dev/null 2>&1
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
	
	echo -e "${INFO} ${MESSAGE}"
	
	MESSAGE="Testing SSH Connection"
	echo -en "${STAT} ${MESSAGE}"
		timeout 5 ${SSHPASSWORD} ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'exit' >/dev/null 2>&1
			error_validate
	
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
	SCRIPT_END=$SECONDS
	echo -e "${INFO} ${PROGRAM} ${TASKTYPE} Completed in $((SCRIPT_END-SCRIPT_START)) seconds"
	exit 0
}

# Error Validation
function error_validate {
	if [ "$?" != "0" ]; then
	    echo -e "\r${FAIL} ${MESSAGE}"
	    exit 1
	else
		echo -e "\r${GOOD} ${MESSAGE}"
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
	echo -en "${STAT} ${MESSAGE}"
	primaryMD5=$(${SSHPASSWORD} ssh ${REMOTE_USER}@${REMOTE_HOST} 'md5sum /etc/pihole/gravity.db')
		error_validate
	
	MESSAGE="Analyzing Local ${GRAVITY_FI}"
	echo -en "${STAT} ${MESSAGE}"
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
SCRIPT_START=$SECONDS
	
	MESSAGE="Evaluating Script Arguments"
	echo -en "${STAT} ${MESSAGE}"

case $# in
	
	0)
		echo -e "\r${FAIL} ${MESSAGE}"
			list_gs_arguments
	;;
	
	1)
   		case $1 in
   	 		pull)
				echo -e "\r${GOOD} ${MESSAGE}"
				
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
				echo -e "\r${GOOD} ${MESSAGE}"
				
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
				echo -e "\r${GOOD} ${MESSAGE}"
				
				echo -e "${INFO} Update Requested"
					update_gs
				exit_nochange
			;;
			
			beta)
				# TASKTYPE='BETA'
				echo -e "\r${GOOD} ${MESSAGE}"
				
				echo -e "${INFO} Beta Update Requested"
					beta_gs
				exit_nochange
			;;
	
			logs)
				TASKTYPE='LOGS'
				
				echo -e "\r${GOOD} ${MESSAGE}"
				
				MESSAGE="Logs Requested"
				echo -e "${INFO} ${MESSAGE}"
					logs_gs
			;;
			
			compare)
				TASKTYPE='COMPARE'
				
				echo -e "\r${GOOD} ${MESSAGE}"
					import_gs
				
				echo -e "${INFO} Validating Folder Configuration"
					validate_gs_folders
					validate_ph_folders
					validate_os_sshpass
					
				md5_compare
			;;
			
			cron)
				TASKTYPE='CRON'
				echo -e "\r${GOOD} ${MESSAGE}"
				
				show_crontab
				
			;;
			
			config)
				TASKTYPE='CONFIG'
				echo -e "\r${GOOD} ${MESSAGE}"
				echo -e "${INFO} Entering ${TASKTYPE} Mode"
				
				if [ -f $HOME/${LOCAL_FOLDR}/${CONFIG_FILE} ]
				then		
					source $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
					MESSAGE="Configuration File Exists"
					echo -e "${WARN} ${MESSAGE}"
					
					echo -e "========================================================"
					echo -e "========================================================"
					echo -e ""
					cat $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
					echo -e ""
					echo -e "========================================================"
					echo -e "========================================================"
					
					MESSAGE="Are you sure you want to erase this configuration?"
					echo -e "${WARN} ${MESSAGE}"
					
					select yn in "Yes" "No"; do
						case $yn in
						Yes )
							MESSAGE="Erasing Existing Configuration"
							echo -en "${STAT} ${MESSAGE}"
							rm -f $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
								error_validate
							
							exit_withchange
						;;
		
						No )
							exit_nochange
						;;
						esac
					done

				else
					MESSAGE="${CONFIG_FILE} Missing"
					echo -e "${INFO} ${MESSAGE}"
					
					MESSAGE="Creating ${CONFIG_FILE} from Template"
					echo -en "${STAT} ${MESSAGE}"
					cp $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}.example $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
						error_validate
						
						MESSAGE="Enter IP or DNS of primary Pi-hole server"
						echo -e "${NEED} ${MESSAGE}"
						read INPUT_REMOTE_HOST
						
						MESSAGE="Enter SSH user with SUDO rights on primary Pi-hole server"
						echo -e "${NEED} ${MESSAGE}"
						read INPUT_REMOTE_USER
						
						MESSAGE="Saving Host to ${CONFIG_FILE}"
						echo -en "${STAT} ${MESSAGE}"
						sed -i "/REMOTE_HOST='192.168.1.10'/c\REMOTE_HOST='${INPUT_REMOTE_HOST}'" $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
							error_validate
						
						MESSAGE="Saving User to ${CONFIG_FILE}"
						echo -en "${STAT} ${MESSAGE}"
						sed -i "/REMOTE_USER='pi'/c\REMOTE_USER='${INPUT_REMOTE_USER}'" $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
							error_validate
	
						if hash sshpass 2>/dev/null
						then
							MESSAGE="SSHPASS Utility Detected"
							echo -e "${INFO} ${MESSAGE}"
							
							MESSAGE="Do you want to configure password based SSH authentication (not reccomended)?"
							echo -e "${WARN} ${MESSAGE}"
							MESSAGE="Your password will be saved in clear-text in the ${CONFIG_FILE} file!"
							echo -e "${WARN} ${MESSAGE}"
							MESSAGE="Leave blank to use (preferred) SSH Key-Pair Authentication."
							echo -e "${WARN} ${MESSAGE}"
							MESSAGE="Enter SSH password for primary Pi-hole server (optional)"
							
							echo -e "${NEED} ${MESSAGE}"
							read INPUT_REMOTE_PASS
									
							MESSAGE="Saving Password to ${CONFIG_FILE}"
							echo -en "${STAT} ${MESSAGE}"
							sed -i "/REMOTE_PASS=''/c\REMOTE_PASS='${INPUT_REMOTE_PASS}'" $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
								error_validate
							
						else
							MESSAGE="SSHPASS Not Installed"
							echo -e "${INFO} ${MESSAGE}"
							
							MESSAGE="Defaulting to SSH Key-Pair Authentication"
							echo -e "${INFO} ${MESSAGE}"
						fi
						
						if [ $INPUT_REMOTE_PASS == '' ]
						then
							if [ -f $HOME/${SSH_PKIF} ]
							then
								MESSAGE="Using Existing ~/${SSH_PKIF}"
								echo -e "${INFO} ${MESSAGE}"
							else
								MESSAGE="Generating ~/${SSH_PKIF}"
								echo -e "${INFO} ${MESSAGE}"
								
								MESSAGE="Leave Key Passphrase Blank"
								echo -e "${WARN} ${MESSAGE}"
								
								MESSAGE="Complete Key-Pair Creation"
								echo -e "${NEED} ${MESSAGE}"
								
								echo -e "========================================================"
								echo -e "========================================================"
								echo -e ""
								ssh-keygen -t rsa
								echo -e ""
								echo -e "========================================================"
								echo -e "========================================================"
							fi
						fi
						
						MESSAGE="Importing New ${CONFIG_FILE}"
						echo -en "${STAT} ${MESSAGE}"
						source $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
							error_validate
						
						if [ REMOTE_PASS == '' ]
						then
							if [ -f $HOME/${SSH_PKIF} ]
							then
								MESSAGE="Registering Key-Pair on ${REMOTE_HOST}"
								echo -e "${INFO} ${MESSAGE}"
								
								MESSAGE="Enter ${REMOTE_USER}@${REMOTE_HOST}"
								echo -e "${NEED} ${MESSAGE}"
								
								echo -e "========================================================"
								echo -e "========================================================"
								echo -e ""
								ssh-copy-id -i $HOME/${SSH_PKIF} ${REMOTE_USER}@${REMOTE_HOST}
								echo -e ""
								echo -e "========================================================"
								echo -e "========================================================"
							fi
							MESSAGE="Error Creating Key-Pair"
							echo -e "${FAIL} ${MESSAGE}"
							
							exit_withchange
						fi
						
						validate_os_sshpass
						
					exit_withchange
				fi
				
			;;
				

			*)
				echo -e "\r${FAIL} ${MESSAGE}"
        			list_gs_arguments
					exit_nochange
			;;
		esac
	;;
	
	*)
		echo -e "\r${FAIL} ${MESSAGE}"
			list_gs_arguments
			exit_nochange
	;;
esac
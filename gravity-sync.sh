#!/bin/bash
SCRIPT_START=$SECONDS

# GRAVITY SYNC BY VMSTAN #####################
PROGRAM='Gravity Sync'
VERSION='2.2.3'

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

# Script Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
BOLD='\033[1m'
NC='\033[0m'

# Message Codes
FAIL="[ ${RED}FAIL${NC} ]"
WARN="[ ${PURPLE}WARN${NC} ]"
GOOD="[ ${GREEN} OK ${NC} ]"
STAT="[ ${CYAN}EXEC${NC} ]"
INFO="[ ${YELLOW}INFO${NC} ]"
NEED="[ ${BLUE}NEED${NC} ]"

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

# GS Update Functions
## Master Branch
function update_gs {
	if [ -f "$HOME/${LOCAL_FOLDR}/dev" ]
	then
		source $HOME/${LOCAL_FOLDR}/dev
	else
		BRANCH='origin/master'
	fi

	if [ "$BRANCH" != "origin/master" ]
	then
		MESSAGE="Pulling from ${BRANCH}"
		echo_info
	fi

	GIT_CHECK=$(git status | awk '{print $1}')
	if [ "$GIT_CHECK" == "fatal:" ]
	then
		MESSAGE="Requires GitHub Installation" 
		echo_warn
		exit_nochange
	else
		MESSAGE="Updating Cache"
		echo_stat
		git fetch --all >/dev/null 2>&1
			error_validate
		MESSAGE="Applying Update"
		echo_stat
		git reset --hard ${BRANCH} >/dev/null 2>&1
			error_validate
	fi
}

# Gravity Core Functions
## Pull Gravity
function pull_gs_grav {

	backup_local_gravity
	backup_remote_gravity
	
	MESSAGE="Pulling ${GRAVITY_FI} from ${REMOTE_HOST}"
	echo_stat
		RSYNC_REPATH="rsync"
		RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI}.backup"
		RSYNC_TARGET="$HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull"
			create_rsynccmd
		
	MESSAGE="Replacing ${GRAVITY_FI} on $HOSTNAME"
	echo_stat	
		sudo cp $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
		error_validate
	
	MESSAGE="Validating Settings of ${GRAVITY_FI}"
	echo_stat

		GRAVDB_OWN=$(ls -ld ${PIHOLE_DIR}/${GRAVITY_FI} | awk 'OFS=":" {print $3,$4}')
		if [ "$GRAVDB_OWN" != "$FILE_OWNER" ]
		then
			MESSAGE="Validating Ownership on ${GRAVITY_FI}"
			echo_fail
			
			MESSAGE="Attempting to Compensate"
			echo_warn
			
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo_stat	
				sudo chown ${FILE_OWNER} ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate

			MESSAGE="Continuing Validation of ${GRAVITY_FI}"
			echo_stat
		fi
		
		GRAVDB_RWE=$(namei -m ${PIHOLE_DIR}/${GRAVITY_FI} | grep -v f: | grep ${GRAVITY_FI} | awk '{print $1}')
		if [ "$GRAVDB_RWE" != "-rw-rw-r--" ]
		then
			MESSAGE="Validating Permissions on ${GRAVITY_FI}"
			echo_fail
				
			MESSAGE="Attempting to Compensate"
			echo_warn
		
			MESSAGE="Setting Permissions on ${GRAVITY_FI}"
			echo_stat
				sudo chmod 664 ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate

			MESSAGE="Continuing Validation of ${GRAVITY_FI}"
			echo_stat
		fi

	echo_good
}

## Pull Custom
function pull_gs_cust {
	if [ "$SKIP_CUSTOM" != '1' ]
	then	
		if [ "$REMOTE_CUSTOM_DNS" == "1" ]
		then
			backup_local_custom
			backup_remote_custom

			MESSAGE="Pulling ${CUSTOM_DNS} from ${REMOTE_HOST}"
			echo_stat
				RSYNC_REPATH="rsync"
				RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${CUSTOM_DNS}.backup"
				RSYNC_TARGET="$HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${CUSTOM_DNS}.pull"
					create_rsynccmd
				
			MESSAGE="Replacing ${CUSTOM_DNS} on $HOSTNAME"
			echo_stat	
				sudo cp $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${CUSTOM_DNS}.pull ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
				error_validate
			
			MESSAGE="Validating Settings on ${CUSTOM_DNS}"
			echo_stat
				
				CUSTOMLS_OWN=$(ls -ld ${PIHOLE_DIR}/${CUSTOM_DNS} | awk '{print $3 $4}')
				if [ "$CUSTOMLS_OWN" != "rootroot" ]
				then
					MESSAGE="Validating Ownership on ${CUSTOM_DNS}"
					echo_fail
					
					MESSAGE="Attempting to Compensate"
					echo_warn
					
					MESSAGE="Setting Ownership on ${CUSTOM_DNS}"
					echo_stat	
						sudo chown root:root ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
						error_validate

					MESSAGE="Continuing Validation of ${GRAVITY_FI}"
					echo_stat
				fi
			
				CUSTOMLS_RWE=$(namei -m ${PIHOLE_DIR}/${CUSTOM_DNS} | grep -v f: | grep ${CUSTOM_DNS} | awk '{print $1}')
				if [ "$CUSTOMLS_RWE" != "-rw-r--r--" ]
				then
					MESSAGE="Validating Permissions on ${CUSTOM_DNS}"
					echo_fail
						
					MESSAGE="Attempting to Compensate"
					echo_warn
				
					MESSAGE="Setting Ownership on ${CUSTOM_DNS}"
					echo_stat
						sudo chmod 644 ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
						error_validate
					
					MESSAGE="Continuing Validation of ${GRAVITY_FI}"
					echo_stat
				fi

			echo_good
		fi
	fi
}

## Pull Reload
function pull_gs_reload {
	MESSAGE="Isolating Regeneration Pathways"
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
}

## Pull Function
function pull_gs {
	previous_md5
	md5_compare
	
	backup_settime
	pull_gs_grav
	pull_gs_cust
	pull_gs_reload
	md5_recheck
	
	logs_export
	exit_withchange
}

## Push Gravity
function push_gs_grav {
	backup_remote_gravity
	backup_local_gravity
	
	MESSAGE="Copying ${GRAVITY_FI} from ${REMOTE_HOST}"
	echo_stat
		RSYNC_REPATH="rsync"
		RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI}.backup"
		RSYNC_TARGET="$HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.push"
			create_rsynccmd

	MESSAGE="Pushing ${GRAVITY_FI} to ${REMOTE_HOST}"
	echo_stat
		RSYNC_REPATH="sudo rsync"
		RSYNC_SOURCE="$HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${GRAVITY_FI}.backup"
		RSYNC_TARGET="${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI}"
			create_rsynccmd

	MESSAGE="Setting Permissions on ${GRAVITY_FI}"
	echo_stat
		CMD_TIMEOUT='15'
		CMD_REQUESTED="sudo chmod 664 ${PIHOLE_DIR}/${GRAVITY_FI}"
			create_sshcmd	

	MESSAGE="Setting Ownership on ${GRAVITY_FI}"
	echo_stat
		CMD_TIMEOUT='15'
		CMD_REQUESTED="sudo chown ${RFILE_OWNER} ${PIHOLE_DIR}/${GRAVITY_FI}"
			create_sshcmd
}

## Push Custom
function push_gs_cust {
	if [ "$SKIP_CUSTOM" != '1' ]
	then	
		if [ "$REMOTE_CUSTOM_DNS" == "1" ]
		then
			backup_remote_custom
			backup_local_custom

			MESSAGE="Copying ${CUSTOM_DNS} from ${REMOTE_HOST}"
			echo_stat
				RSYNC_REPATH="rsync"
				RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${CUSTOM_DNS}.backup"
				RSYNC_TARGET="$HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${CUSTOM_DNS}.push"
					create_rsynccmd

			MESSAGE="Pushing ${CUSTOM_DNS} to ${REMOTE_HOST}"
			echo_stat
				RSYNC_REPATH="sudo rsync"
				RSYNC_SOURCE="$HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${CUSTOM_DNS}.backup"
				RSYNC_TARGET="${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${CUSTOM_DNS}"
					create_rsynccmd

			MESSAGE="Setting Permissions on ${CUSTOM_DNS}"
			echo_stat
				CMD_TIMEOUT='15'
				CMD_REQUESTED="sudo chmod 644 ${PIHOLE_DIR}/${CUSTOM_DNS}"
					create_sshcmd

			MESSAGE="Setting Ownership on ${CUSTOM_DNS}"
			echo_stat
				CMD_TIMEOUT='15'
				CMD_REQUESTED="sudo chown root:root ${PIHOLE_DIR}/${CUSTOM_DNS}"
					create_sshcmd	
		fi	
	fi
}

## Push Reload
function push_gs_reload {
	MESSAGE="Inverting Tachyon Pulses"
	echo_info
		sleep 1	

	MESSAGE="Updating Remote FTLDNS Configuration"
	echo_stat
		CMD_TIMEOUT='15'
		CMD_REQUESTED="${RIHOLE_BIN} restartdns reloadlists"
			create_sshcmd
	
	MESSAGE="Reloading Remote FTLDNS Services"
	echo_stat
		CMD_TIMEOUT='15'
		CMD_REQUESTED="${RIHOLE_BIN} restartdns"
			create_sshcmd
}

## Push Function
function push_gs {
	previous_md5
	md5_compare
	backup_settime
	
	intent_validate

	push_gs_grav
	push_gs_cust
	push_gs_reload

	md5_recheck
	logs_export
	exit_withchange
}

function previous_md5 {
	if [ -f "${LOG_PATH}/${HISTORY_MD5}" ]
	then
		last_primaryDBMD5=$(sed "1q;d" ${LOG_PATH}/${HISTORY_MD5})
		last_secondDBMD5=$(sed "2q;d" ${LOG_PATH}/${HISTORY_MD5})
		last_primaryCLMD5=$(sed "3q;d" ${LOG_PATH}/${HISTORY_MD5})
		last_secondCLMD5=$(sed "4q;d" ${LOG_PATH}/${HISTORY_MD5})
	else
		last_primaryDBMD5="0"
		last_secondDBMD5="0"
		last_primaryCLMD5="0"
		last_secondCLMD5="0"
	fi
}

## Smart Sync Function
function smart_gs {
	previous_md5
	md5_compare
	backup_settime

	PRIDBCHANGE="0"
	SECDBCHANGE="0"
	PRICLCHANGE="0"
	SECCLCHANGE="0"
	
	if [ "${primaryDBMD5}" != "${last_primaryDBMD5}" ]
	then
		PRIDBCHANGE="1"
	fi
	
	if [ "${secondDBMD5}" != "${last_secondDBMD5}" ]
	then
		SECDBCHANGE="1"
	fi

	if [ "${PRIDBCHANGE}" == "${SECDBCHANGE}" ]
	then
		if [ "${PRIDBCHANGE}" != "0" ]
		then
			MESSAGE="Both ${GRAVITY_FI} Changed"
			echo_warn

			PRIDBDATE=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "stat -c %Y ${PIHOLE_DIR}/${GRAVITY_FI}")
			SECDBDATE=$(stat -c %Y ${PIHOLE_DIR}/${GRAVITY_FI})

				if [ "${PRIDBDATE}" -gt "$SECDBDATE" ]
				then
					MESSAGE="Primary ${GRAVITY_FI} Last Changed"
					echo_info

					pull_gs_grav
					PULLRESTART="1"
				else
					MESSAGE="Secondary ${GRAVITY_FI} Last Changed"
					echo_info

					push_gs_grav
					PUSHRESTART="1"
				fi
		fi
	else
		if [ "${PRIDBCHANGE}" != "0" ]
		then
			pull_gs_grav
			PULLRESTART="1"
		elif [ "${SECDBCHANGE}" != "0" ]
		then
			push_gs_grav
			PUSHRESTART="1"
		fi
	fi

	if [ "${primaryCLMD5}" != "${last_primaryCLMD5}" ]
	then
		PRICLCHANGE="1"
	fi
	
	if [ "${secondCLMD5}" != "${last_secondCLMD5}" ]
	then
		SECCLCHANGE="1"
	fi

	if [ "$SKIP_CUSTOM" != '1' ]
	then

		if [ -f "${PIHOLE_DIR}/${CUSTOM_DNS}" ]
		then

			if [ "${PRICLCHANGE}" == "${SECCLCHANGE}" ]
			then
				if [ "${PRICLCHANGE}" != "0" ]
				then
					MESSAGE="Both ${CUSTOM_DNS} Changed"
					echo_warn

					PRICLDATE=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "stat -c %Y ${PIHOLE_DIR}/${CUSTOM_DNS}")
					SECCLDATE=$(stat -c %Y ${PIHOLE_DIR}/${CUSTOM_DNS})

						if [ "${PRICLDATE}" -gt "${SECCLDATE}" ]
						then
							MESSAGE="Primary ${CUSTOM_DNS} Last Changed"
							echo_info

							pull_gs_cust
							PULLRESTART="1"
						else
							MESSAGE="Secondary ${CUSTOM_DNS} Last Changed"
							echo_info

							push_gs_cust
							PUSHRESTART="1"
						fi
				fi
			else
				if [ "${PRICLCHANGE}" != "0" ]
				then
					pull_gs_cust
					PULLRESTART="1"
				elif [ "${SECCLCHANGE}" != "0" ]
				then
					push_gs_cust
					PUSHRESTART="1"
				fi
			fi
		else
			pull_gs_cust
			PULLRESTART="1"
		fi
	fi

	if [ "$PULLRESTART" == "1" ]
	then
		pull_gs_reload
	fi

	if [ "$PUSHRESTART" == "1" ]
	then
		push_gs_reload
	fi

	md5_recheck

	logs_export
	exit_withchange
}

function restore_gs {
	MESSAGE="This will restore your settings on $HOSTNAME with a previous version!"
	echo_warn

	MESSAGE="PREVIOUS BACKUPS AVAILABLE FOR RESTORATION"
	echo_info
	ls $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD} | grep $(date +%Y) | grep ${GRAVITY_FI} | colrm 18

	MESSAGE="Select backup date to restore ${GRAVITY_FI} from"
	echo_need
	read INPUT_BACKUP_DATE

	if [ -f $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_BACKUP_DATE}-${GRAVITY_FI}.backup ]
	then
		MESSAGE="Backup File Selected"
	else
		MESSAGE="Invalid Request"
		echo_info

		exit_nochange
	fi

	if [ "$SKIP_CUSTOM" != '1' ]
	then

		if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
		then
			ls $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD} | grep $(date +%Y) | grep ${CUSTOM_DNS} | colrm 18

			MESSAGE="Select backup date to restore ${CUSTOM_DNS} from"
			echo_need
			read INPUT_DNSBACKUP_DATE

			if [ -f $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_DNSBACKUP_DATE}-${CUSTOM_DNS}.backup ]
			then
				MESSAGE="Backup File Selected"
			else
				MESSAGE="Invalid Request"
				echo_info

				exit_nochange
			fi
		fi
	fi

	MESSAGE="${GRAVITY_FI} from ${INPUT_BACKUP_DATE} Selected"
		echo_info
	MESSAGE="${CUSTOM_DNS} from ${INPUT_DNSBACKUP_DATE} Selected"
		echo_info
	
	intent_validate

	MESSAGE="Making Time Warp Calculations"
	echo_info

	MESSAGE="Stopping Pi-hole Services"
	echo_stat

	sudo service pihole-FTL stop >/dev/null 2>&1
		error_validate

	MESSAGE="Restoring ${GRAVITY_FI} on $HOSTNAME"
	echo_stat	
		sudo cp $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_BACKUP_DATE}-${GRAVITY_FI}.backup ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
		error_validate
	
	MESSAGE="Validating Ownership on ${GRAVITY_FI}"
	echo_stat
		
		GRAVDB_OWN=$(ls -ld ${PIHOLE_DIR}/${GRAVITY_FI} | awk 'OFS=":" {print $3,$4}')
		if [ "$GRAVDB_OWN" == "$FILE_OWNER" ]
		then
			echo_good
		else
			echo_fail
			
			MESSAGE="Attempting to Compensate"
			echo_warn
			
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo_stat	
				sudo chown ${FILE_OWNER} ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate
		fi
		
	MESSAGE="Validating Permissions on ${GRAVITY_FI}"
	echo_stat
	
		GRAVDB_RWE=$(namei -m ${PIHOLE_DIR}/${GRAVITY_FI} | grep -v f: | grep ${GRAVITY_FI} | awk '{print $1}')
		if [ "$GRAVDB_RWE" = "-rw-rw-r--" ]
		then
			echo_good
		else
			echo_fail
				
			MESSAGE="Attempting to Compensate"
			echo_warn
		
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo_stat
				sudo chmod 664 ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
				error_validate
		fi

	if [ "$SKIP_CUSTOM" != '1' ]
	then	
		if [ -f $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_DNSBACKUP_DATE}-${CUSTOM_DNS}.backup ]
		then
			MESSAGE="Restoring ${CUSTOM_DNS} on $HOSTNAME"
			echo_stat
				sudo cp $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_DNSBACKUP_DATE}-${CUSTOM_DNS}.backup ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
				error_validate
				
			MESSAGE="Validating Ownership on ${CUSTOM_DNS}"
			echo_stat
				
				CUSTOMLS_OWN=$(ls -ld ${PIHOLE_DIR}/${CUSTOM_DNS} | awk '{print $3 $4}')
				if [ "$CUSTOMLS_OWN" == "rootroot" ]
				then
					echo_good
				else
					echo_fail
					
					MESSAGE="Attempting to Compensate"
					echo_warn
					
					MESSAGE="Setting Ownership on ${CUSTOM_DNS}"
					echo_stat	
						sudo chown root:root ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
						error_validate
				fi
				
			MESSAGE="Validating Permissions on ${CUSTOM_DNS}"
			echo_stat
			
				CUSTOMLS_RWE=$(namei -m ${PIHOLE_DIR}/${CUSTOM_DNS} | grep -v f: | grep ${CUSTOM_DNS} | awk '{print $1}')
				if [ "$CUSTOMLS_RWE" == "-rw-r--r--" ]
				then
					echo_good
				else
					echo_fail
						
					MESSAGE="Attempting to Compensate"
					echo_warn
				
					MESSAGE="Setting Ownership on ${CUSTOM_DNS}"
					echo_stat
						sudo chmod 644 ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
						error_validate
				fi
		fi
	fi

	MESSAGE="Evacuating Saucer Section"
	echo_info
		sleep 1	

	MESSAGE="Restarting FTLDNS Services"
	echo_stat
		sudo service pihole-FTL start >/dev/null 2>&1
		error_validate
	
	MESSAGE="Updating FTLDNS Configuration"
	echo_stat
		${PIHOLE_BIN} restartdns reloadlists >/dev/null 2>&1
		error_validate
	

	MESSAGE="Do you want to push the restored configuration to the primary Pi-hole? (yes/no)"
	echo_need
	read PUSH_TO_PRIMARY

	if [ "${PUSH_TO_PRIMARY}" == "Yes" ] || [ "${PUSH_TO_PRIMARY}" == "yes" ] || [ "${PUSH_TO_PRIMARY}" == "Y" ] || [ "${PUSH_TO_PRIMARY}" == "y" ]
	then
		push_gs
	elif [ "${PUSH_TO_PRIMARY}" == "No" ] || [ "${PUSH_TO_PRIMARY}" == "no" ] || [ "${PUSH_TO_PRIMARY}" == "N" ] || [ "${PUSH_TO_PRIMARY}" == "n" ]
	then
		logs_export
		exit_withchange
	else
		MESSAGE="Invalid Selection - Defaulting No"
		echo_warn

		logs_export
		exit_withchange
	fi
}

# Logging Functions
## Core Logging
### Write Logs Out
function logs_export {
	
	if [ "${TASKTYPE}" != "BACKUP" ]
	then
	MESSAGE="Saving File Hashes"
	echo_stat
		rm -f ${LOG_PATH}/${HISTORY_MD5}
		echo -e ${primaryDBMD5} >> ${LOG_PATH}/${HISTORY_MD5}
		echo -e ${secondDBMD5} >> ${LOG_PATH}/${HISTORY_MD5}
		echo -e ${primaryCLMD5} >> ${LOG_PATH}/${HISTORY_MD5}
		echo -e ${secondCLMD5} >> ${LOG_PATH}/${HISTORY_MD5}
			error_validate
	fi

	MESSAGE="Logging Successful ${TASKTYPE}"
	echo_stat
		echo -e $(date) "[${TASKTYPE}]" >> ${LOG_PATH}/${SYNCING_LOG}
		error_validate
}

### Output Sync Logs
function logs_gs {
	# import_gs

	MESSAGE="Tailing ${LOG_PATH}/${SYNCING_LOG}"
	echo_info

	echo -e "========================================================"
	echo -e "Recent Complete ${YELLOW}SMART${NC} Executions"
		tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep SMART
	echo -e "Recent Complete ${YELLOW}PULL${NC} Executions"
		tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep PULL
	echo -e "Recent Complete ${YELLOW}PUSH${NC} Executions"
		tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep PUSH
	echo -e "Recent Complete ${YELLOW}BACKUP${NC} Executions"
		tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep BACKUP
	echo -e "Recent Complete ${YELLOW}RESTORE${NC} Executions"
		tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep RESTORE
	echo -e "========================================================"

	exit_nochange
}

## Crontab Logs
### Core Crontab Logs
function show_crontab {
	# import_gs
	
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
	MESSAGE="Validating ${PROGRAM} Folders on $HOSTNAME"
	echo_stat
		if [ ! -d $HOME/${LOCAL_FOLDR} ]
		then
			MESSAGE="Unable to Find $HOME/${LOCAL_FOLDR}"
			echo_fail
			exit_nochange
		fi
	
		if [ ! -d $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD} ]
		then
			MESSAGE="Unable to Find $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}"
			echo_fail
			exit_nochange
		fi
	echo_good
}

## Validate Pi-hole Folders
function validate_ph_folders {
	MESSAGE="Validating Pi-hole Configuration on $HOSTNAME"
	echo_stat
		if [ ! -f ${PIHOLE_BIN} ]
		then
			MESSAGE="Unable to Validate Pi-Hole is Installed"
			echo_fail
			exit_nochange
		fi

		if [ ! -d ${PIHOLE_DIR} ]
		then
			MESSAGE="Unable to Validate Pi-Hole Configuration Directory"
			echo_fail
			exit_nochange
		fi
	echo_good
}

## Validate SQLite3
function validate_sqlite3 {
	MESSAGE="Validating SQLITE Installed on $HOSTNAME"
	echo_stat
		if hash sqlite3 2>/dev/null
		then
			MESSAGE="SQLITE3 Utility Detected"
			echo_good
		else
			MESSAGE="SQLITE3 Utility Missing"
			echo_warn

			MESSAGE="Installing SQLLITE3 with ${PKG_MANAGER}"
			echo_stat
			
			${PKG_INSTALL} sqllite3 >/dev/null 2>&1
				error_validate
		fi
}

## Validate SSHPASS
function validate_os_sshpass {
	SSHPASSWORD=''

	if hash sshpass 2>/dev/null
    then
		MESSAGE="SSHPASS Utility Detected"
		echo_warn
			if [ -z "$REMOTE_PASS" ]
			then
				MESSAGE="Using SSH Key-Pair Authentication"
				echo_info
			else
				MESSAGE="Testing Authentication Options"
				echo_stat

				timeout 5 ssh -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'exit' >/dev/null 2>&1
				if [ "$?" != "0" ]
				then
					SSHPASSWORD="sshpass -p ${REMOTE_PASS}"
					MESSAGE="Using SSH Password Authentication"
					echo_warn
				else
					MESSAGE="Valid Key-Pair Detected ${NC}(${RED}Password Ignored${NC})"
					echo_info
				fi
			fi
    else
        SSHPASSWORD=''
		MESSAGE="Using SSH Key-Pair Authentication"
		echo_info
    fi
	
	MESSAGE="Validating Connection to ${REMOTE_HOST}"
	echo_stat

	CMD_TIMEOUT='5'
	CMD_REQUESTED="exit"
		create_sshcmd
	
}

## Determine SSH Pathways
function create_sshcmd {
	if hash ssh 2>/dev/null
	then
		if [ -z "$SSHPASSWORD" ]
		then
			timeout --preserve-status ${CMD_TIMEOUT} ${SSH_CMD} -p ${SSH_PORT} -i $HOME/${SSH_PKIF} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "${CMD_REQUESTED}"
				error_validate
		else
			timeout --preserve-status ${CMD_TIMEOUT} ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "${CMD_REQUESTED}"
				error_validate
		fi
	# elif hash dbclient 2>/dev/null
	# then
	#	timeout --preserve-status ${CMD_TIMEOUT} ${SSH_CMD} -p ${SSH_PORT} -i $HOME/${SSH_PKIF} ${REMOTE_USER}@${REMOTE_HOST} "${CMD_REQUESTED}"
	#		error_validate
	fi
}

## Determine SSH Pathways
function create_rsynccmd {
	if hash ssh 2>/dev/null
	then
		if [ -z "$SSHPASSWORD" ]
		then
			rsync --rsync-path="${RSYNC_REPATH}" -e "${SSH_CMD} -p ${SSH_PORT} -i $HOME/${SSH_PKIF}" ${RSYNC_SOURCE} ${RSYNC_TARGET} >/dev/null 2>&1
				error_validate		
		else
			rsync --rsync-path="${RSYNC_REPATH}" -e "${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i $HOME/${SSH_PKIF}" ${RSYNC_SOURCE} ${RSYNC_TARGET} >/dev/null 2>&1
				error_validate
		fi
	# elif hash dbclient 2>/dev/null
	# then
	#	rsync --rsync-path="${RSYNC_REPATH}" -e "${SSH_CMD} -p ${SSH_PORT} -i $HOME/${SSH_PKIF}" ${RSYNC_SOURCE} ${RSYNC_TARGET} >/dev/null 2>&1
	#		error_validate
	fi
}

## Detect SSH-KEYGEN
function detect_sshkeygen {
	MESSAGE="Validating SSH-KEYGEN install on $HOSTNAME"
		echo_stat
	
	if hash ssh-keygen >/dev/null 2>&1
	then
		echo_good
	else
		echo_fail
		MESSAGE="SSH-KEYGEN is Required"
		echo_info
		
		exit_nochange
		# MESSAGE="Attempting to Compensate"
		# echo_warn

		# if hash dropbearkey >/dev/null 2>&1
		# then
		#	MESSAGE="Using DROPBEARKEY Instead"
		#	echo_info
		#		if [ ! -d $HOME/.ssh ]
		#		then
		#			mkdir $HOME/.ssh >/dev/null 2>&1
		#		fi
		#	KEYGEN_COMMAND="dropbearkey -t rsa -f"
		# else
		#	MESSAGE="No Alternatives Located"
		#	echo_info
		#		exit_nochange
		# fi	
	fi
}

function generate_sshkey {
	if [ -z $INPUT_REMOTE_PASS ]
	then
		if [ -f $HOME/${SSH_PKIF} ]
		then
			MESSAGE="Using Existing ~/${SSH_PKIF}"
			echo_info
		else
			if hash ssh-keygen >/dev/null 2>&1
			then
				MESSAGE="Generating ~/${SSH_PKIF} (SSH-KEYGEN)"
				echo_stat
				
				ssh-keygen -q -P "" -t rsa -f $HOME/${SSH_PKIF} >/dev/null 2>&1
					error_validate

			# elif hash dropbearkey >/dev/null 2>&1
			# then
			#	MESSAGE="Generating ~/${SSH_PKIF} (DROPBEARKEY)"
			#	echo_stat
			#		if [ ! -d $HOME/.ssh ]
			#		then
			#			mkdir $HOME/.ssh >/dev/null 2>&1
			#		fi
			#
			#		dropbearkey -t rsa -f $HOME/${SSH_PKIF} >/dev/null 2>&1
			#			error_validate
			else
				MESSAGE="No SSH Key Generator Located"
				echo_warn
					exit_nochange
			fi	
		fi
	fi
}

function export_sshkey {
	if [ -z $REMOTE_PASS ]
	then
		if [ -f $HOME/${SSH_PKIF} ]
		then
			MESSAGE="Registering Key-Pair on ${REMOTE_HOST}"
			echo_info
			
			#MESSAGE="Enter ${REMOTE_USER}@${REMOTE_HOST} Password Below"
			#echo -e "${NEED} ${MESSAGE}"

			# if hash ssh-copy-id 2>/dev/null
			# then
				ssh-copy-id -f -p ${SSH_PORT} -i $HOME/${SSH_PKIF}.pub ${REMOTE_USER}@${REMOTE_HOST}
			# elif hash dbclient 2>/dev/null
			# then
			# 	dropbearkey -y -f $HOME/${SSH_PKIF} | grep "^ssh-rsa " > $HOME/${SSH_PKIF}.pub
			#	cat $HOME/${SSH_PKIF}.pub | dbclient -p ${SSH_PORT} ${REMOTE_USER}@${REMOTE_HOST} 'cat - >> .ssh/authorized_keys'
			# fi
		else
		MESSAGE="Error Registering Key-Pair"
		echo_warn
		fi
	fi
}

## Detect Package Manager
function distro_check { 
	if hash apt-get 2>/dev/null
	then
		PKG_MANAGER="apt-get"
		PKG_INSTALL="sudo apt-get --yes --no-install-recommends --quiet install"
	elif hash rpm 2>/dev/null
	then
		if hash dnf 2>/dev/null
		then
			PKG_MANAGER="dnf"
		elif hash yum 2>/dev/null
		then
			PKG_MANAGER="yum"
		else
			MESSAGE="Unable to find OS Package Manager"
			echo_info
			exit_nochange
		fi
		PKG_INSTALL="sudo ${PKG_MANAGER} install -y"
	else
		MESSAGE="Unable to find OS Package Manager"
		echo_info
		exit_nochange
	fi
}

## Detect SSH & RSYNC
function detect_ssh {
	MESSAGE="Validating SSH Client on $HOSTNAME"
	echo_stat

	if hash ssh 2>/dev/null
	then
		MESSAGE="${MESSAGE} (OpenSSH)"
		echo_good
		SSH_CMD='ssh'
	elif hash dbclient 2>/dev/null
	then
		MESSAGE="${MESSAGE} (Dropbear)"
		echo_fail

		MESSAGE="Dropbear not supported in GS ${VERSION}"
		echo_info
			exit_nochange
	else
		echo_fail
		
		MESSAGE="Attempting to Compensate"
		echo_warn
		MESSAGE="Installing SSH Client with ${PKG_MANAGER}"
		echo_stat
		
		${PKG_INSTALL} ssh-client >/dev/null 2>&1
			error_validate
	fi

	MESSAGE="Validating RSYNC Installed on $HOSTNAME"
	echo_stat

	if hash rsync 2>/dev/null
	then
		echo_good
	else
		echo_fail
		MESSAGE="RSYNC is Required"
		echo_warn

		distro_check

		MESSAGE="Attempting to Compensate"
		echo_warn

		MESSAGE="Installing RSYNC with ${PKG_MANAGER}"
		echo_stat
		${PKG_INSTALL} rsync >/dev/null 2>&1
			error_validate
	fi
}

function detect_remotersync {
	MESSAGE="Creating Test File on ${REMOTE_HOST}"
	echo_stat

		CMD_TIMEOUT='15'
		CMD_REQUESTED="touch ~/gs.test"
			create_sshcmd

	MESSAGE="If pull test fails ensure RSYNC is installed on ${REMOTE_HOST}"
	echo_warn

	MESSAGE="Pulling Test File to $HOSTNAME"
	echo_stat

		RSYNC_REPATH="rsync"
		RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:~/gs.test"
		RSYNC_TARGET="$HOME/${LOCAL_FOLDR}/gs.test"
			create_rsynccmd

	MESSAGE="Cleaning Up Local Test File"
	echo_stat

	rm $HOME/${LOCAL_FOLDR}/gs.test
		error_validate

	MESSAGE="Cleaning Up Remote Test File"
	echo_stat

	CMD_TIMEOUT='15'
	CMD_REQUESTED="rm ~/gs.test"
		create_sshcmd
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

## Validate Sync Required
function md5_compare {
	# last_primaryDBMD5="0"
	# last_secondDBMD5="0"
	# last_primaryCLMD5="0"
	# last_secondCLMD5="0"
	
	HASHMARK='0'

	MESSAGE="Analyzing ${GRAVITY_FI} on ${REMOTE_HOST}"
	echo_stat
	primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${PIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//') 
		error_validate
	
	MESSAGE="Analyzing ${GRAVITY_FI} on $HOSTNAME"
	echo_stat
	secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
		error_validate
	
	if [ "$primaryDBMD5" == "$last_primaryDBMD5" ] && [ "$secondDBMD5" == "$last_secondDBMD5" ]
	then
		HASHMARK=$((HASHMARK+0))
	else
		MESSAGE="Differenced ${GRAVITY_FI} Detected"
		echo_warn
		HASHMARK=$((HASHMARK+1))
	fi

	if [ "$SKIP_CUSTOM" != '1' ]
	then
		if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
		then
			if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${PIHOLE_DIR}/${CUSTOM_DNS}
			then
				REMOTE_CUSTOM_DNS="1"
				MESSAGE="Analyzing ${CUSTOM_DNS} on ${REMOTE_HOST}"
				echo_stat

				primaryCLMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//'") 
					error_validate
				
				MESSAGE="Analyzing ${CUSTOM_DNS} on $HOSTNAME"
				echo_stat
				secondCLMD5=$(md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//')
					error_validate
				
				if [ "$primaryCLMD5" == "$last_primaryCLMD5" ] && [ "$secondCLMD5" == "$last_secondCLMD5" ]
				then
					# MESSAGE="${CUSTOM_DNS} Identical"
					# echo_info
					HASHMARK=$((HASHMARK+0))
				else
					MESSAGE="Differenced ${CUSTOM_DNS} Detected"
					echo_warn
					HASHMARK=$((HASHMARK+1))
				fi
			else
				MESSAGE="No ${CUSTOM_DNS} Detected on ${REMOTE_HOST}"
				echo_info
			fi
		else
			if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${PIHOLE_DIR}/${CUSTOM_DNS}
			then
				REMOTE_CUSTOM_DNS="1"
				MESSAGE="${REMOTE_HOST} has ${CUSTOM_DNS}"
				HASHMARK=$((HASHMARK+1))
				echo_info
			fi	
			MESSAGE="No ${CUSTOM_DNS} Detected on $HOSTNAME"
			echo_info
		fi
	fi

	if [ "$HASHMARK" != "0" ]
	then
		MESSAGE="Replication Required"
		echo_warn
		HASHMARK=$((HASHMARK+0))
	else
		MESSAGE="No Replication Required"
		echo_info
			exit_nochange
	fi
}

function md5_recheck {
	MESSAGE="Performing Replicator Diagnostics"
	echo_info
	
	HASHMARK='0'

	MESSAGE="Reanalyzing ${GRAVITY_FI} on ${REMOTE_HOST}"
	echo_stat
	primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${PIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//') 
		error_validate
	
	MESSAGE="Reanalyzing ${GRAVITY_FI} on $HOSTNAME"
	echo_stat
	secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
		error_validate
	
	# if [ "$primaryDBMD5" == "$secondDBMD5" ]
	# then
	#	HASHMARK=$((HASHMARK+0))
	# else
	#	MESSAGE="Differenced ${GRAVITY_FI} Detected"
	#	echo_warn
	#	HASHMARK=$((HASHMARK+1))
	# fi

	if [ "$SKIP_CUSTOM" != '1' ]
	then
		if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
		then
			if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${PIHOLE_DIR}/${CUSTOM_DNS}
			then
				REMOTE_CUSTOM_DNS="1"
				MESSAGE="Reanalyzing ${CUSTOM_DNS} on ${REMOTE_HOST}"
				echo_stat

				primaryCLMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//'") 
					error_validate
				
				MESSAGE="Reanalyzing ${CUSTOM_DNS} on $HOSTNAME"
				echo_stat
				secondCLMD5=$(md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//')
					error_validate
				
				# if [ "$primaryCLMD5" == "$secondCLMD5" ]
				# then
					# MESSAGE="${CUSTOM_DNS} Identical"
					# echo_info
				#	HASHMARK=$((HASHMARK+0))
				# else
				#	MESSAGE="Differenced ${CUSTOM_DNS} Detected"
				#	echo_warn
				#	HASHMARK=$((HASHMARK+1))
				# fi
			else
				MESSAGE="No ${CUSTOM_DNS} Detected on ${REMOTE_HOST}"
				echo_info
			fi
		else
			if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${PIHOLE_DIR}/${CUSTOM_DNS}
			then
				REMOTE_CUSTOM_DNS="1"
				MESSAGE="${REMOTE_HOST} has ${CUSTOM_DNS}"
			#	HASHMARK=$((HASHMARK+1))
				echo_info
			fi	
			MESSAGE="No ${CUSTOM_DNS} Detected on $HOSTNAME"
			echo_info
		fi
	fi

	# if [ "$HASHMARK" != "0" ]
	# then
	#	MESSAGE="Replication Checks Failed"
	#	echo_warn
	# else
	#	MESSAGE="Replication Was Successful"
	#	echo_info
	# fi
}

## Validate Intent
function intent_validate {
	if [ "$VERIFY_PASS" == "0" ]
	then
		PHASER=$((( RANDOM % 4 ) + 1 ))
		if [ "$PHASER" = "1" ]
		then
			INTENT="FIRE PHOTON TORPEDOS"
		elif [ "$PHASER" = "2" ]
		then
			INTENT="FIRE ALL PHASERS"
		elif [ "$PHASER" = "3" ]
		then
			INTENT="EJECT THE WARPCORE"
		elif [ "$PHASER" = "4" ]
		then
			INTENT="ENGAGE TRACTOR BEAM"
		fi
		
		MESSAGE="Type ${INTENT} to Confirm"
		echo_need

		read INPUT_INTENT

		if [ "${INPUT_INTENT}" != "${INTENT}" ]
		then
			MESSAGE="${TASKTYPE} Aborted"
			echo_info
			exit_nochange
		fi
	else
		MESSAGE="Verification Bypassed"
		echo_warn
	fi
}

# Configuration Management
## Generate New Configuration
function config_generate {
	detect_ssh
	
	MESSAGE="Creating ${CONFIG_FILE} from Template"
	echo_stat
	cp $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}.example $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
	error_validate

	MESSAGE="Environment Customization"
	echo_info

	MESSAGE="Enter a custom SSH port if required (Leave blank for default '22')"
	echo_need
	read INPUT_SSH_PORT
	INPUT_SSH_PORT="${INPUT_SSH_PORT:-22}"

	if [ "${INPUT_SSH_PORT}" != "22" ]
	then
		MESSAGE="Saving Custom SSH Port to ${CONFIG_FILE}"
		echo_stat
		sed -i "/# SSH_PORT=''/c\SSH_PORT='${INPUT_SSH_PORT}'" $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
		error_validate
	fi

	MESSAGE="Perform PING tests between Pi-holes? (Leave blank for default 'Yes')"
	echo_need
	read INPUT_PING_AVOID
	INPUT_PING_AVOID="${INPUT_PING_AVOID:-Y}"

	if [ "${INPUT_PING_AVOID}" != "Y" ]
	then
		MESSAGE="Saving Ping Avoidance to ${CONFIG_FILE}"
		echo_stat
		sed -i "/# PING_AVOID=''/c\PING_AVOID='1'" $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
		error_validate
		PING_AVOID=1
	fi
	
	MESSAGE="Standard Settings"
	echo_info

	MESSAGE="IP or DNS of Primary Pi-hole"
	echo_need
	read INPUT_REMOTE_HOST

	if [ "${PING_AVOID}" != "1" ]
	then
		
		
		MESSAGE="Testing Network Connection (PING)"
		echo_stat
		ping -c 3 ${INPUT_REMOTE_HOST} >/dev/null 2>&1
			error_validate
	else
		MESSAGE="Bypassing Network Testing (PING)"
		echo_warn
	fi
	
	MESSAGE="SSH User with SUDO rights"
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
		echo_warn
			if hash ssh 2>/dev/null
			then
				MESSAGE="Please Reference Documentation"
				echo_info

				MESSAGE="${BLUE}https://github.com/vmstan/gravity-sync/blob/master/ADVANCED.md#ssh-configuration${NC}"
				echo_info

				MESSAGE="Leave password blank to use key-pair! (reccomended)"
				echo_warn
				
				MESSAGE="SSH User Password"
				echo_need
				read INPUT_REMOTE_PASS
				
				MESSAGE="Saving Password to ${CONFIG_FILE}"
				echo_stat
				sed -i "/REMOTE_PASS=''/c\REMOTE_PASS='${INPUT_REMOTE_PASS}'" $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
					error_validate
			elif hash dbclient 2>/dev/null
			then
				MESSAGE="Dropbear SSH Detected"
				echo_warn
				MESSAGE="Skipping Password Setup"
				echo_info
			fi	
	fi

	generate_sshkey
	
	MESSAGE="Importing New ${CONFIG_FILE}"
	echo_stat
	source $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
	error_validate

	export_sshkey	
	
	MESSAGE="Testing Configuration"
	echo_info

	validate_os_sshpass
	validate_sqlite3

	detect_remotersync
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

	intent_validate

	MESSAGE="Erasing Existing Configuration"
	echo_stat
	rm -f $HOME/${LOCAL_FOLDR}/${CONFIG_FILE}
		error_validate

	config_generate
}

# Exit Codes
## No Changes Made
function exit_nochange {
	SCRIPT_END=$SECONDS
	MESSAGE="${PROGRAM} ${TASKTYPE} Aborting ($((SCRIPT_END-SCRIPT_START)) seconds)"
	echo_info
	exit 0
}

## Changes Made
function exit_withchange {
	SCRIPT_END=$SECONDS
	MESSAGE="${PROGRAM} ${TASKTYPE} Completed ($((SCRIPT_END-SCRIPT_START)) seconds)"
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
	echo -e " ${YELLOW}automate${NC}	Add a scheduled pull task to crontab"
	echo -e " ${YELLOW}update${NC}		Update ${PROGRAM} to the latest version"
	echo -e " ${YELLOW}version${NC}	Display installed version of ${PROGRAM}"
	echo -e ""
	echo -e "Replication Options:"
	echo -e " ${YELLOW}smart${NC}		Detect changes on each side and bring them together"
	echo -e " ${YELLOW}pull${NC}		Force remote configuration changes to this server"
	echo -e " ${YELLOW}push${NC}		Force local configuration made on this server back"
	echo -e " ${YELLOW}restore${NC}	Restore the ${GRAVITY_FI} on this server"
	echo -e " ${YELLOW}compare${NC}	Just check for differences"
	echo -e ""
	echo -e "Debug Options:"
	echo -e " ${YELLOW}logs${NC}		Show recent successful replication jobs"
	echo -e " ${YELLOW}cron${NC}		Display output of last crontab execution"
	echo -e ""
	exit_nochange
}

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

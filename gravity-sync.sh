#!/bin/bash
SCRIPT_START=$SECONDS

# GRAVITY SYNC BY VMSTAN #####################
PROGRAM='Gravity Sync'
VERSION='1.8.1'

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

# Interaction Customization
VERIFY_PASS='0'						# replace in gravity-sync.conf to overwrite
SKIP_CUSTOM='0'						# replace in gravity-sync.conf to overwrite
DATE_OUTPUT='0'						# replace in gravity-sync.conf to overwrite
PING_AVOID='0'						# replace in gravity-sync.conf to overwrite

# Pi-hole Folder/File Locations
PIHOLE_DIR='/etc/pihole' 			# default Pi-hole data directory
GRAVITY_FI='gravity.db' 			# default Pi-hole database file
CUSTOM_DNS='custom.list'			# default Pi-hole local DNS lookups
PIHOLE_BIN='/usr/local/bin/pihole' 	# default Pi-hole binary directory

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
			
		MESSAGE="Targeting ${REMOTE_USER}@${REMOTE_HOST}"
		echo_info

		detect_ssh
	else
		echo_fail
		
		MESSAGE="${CONFIG_FILE} Missing"
		echo_info

		TASKTYPE='CONFIG'
		config_generate
	fi
}

# GS Update Functions
## Master Branch
function update_gs {
	TASKTYPE='UPDATE'

	if [ -f "$HOME/${LOCAL_FOLDR}/dev" ]
	then
		BRANCH='development'
	else
		BRANCH='master'
	fi

	if [ "$BRANCH" = "development" ]
	then
		MESSAGE="Pulling from origin/${BRANCH}"
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
		git reset --hard origin/${BRANCH} >/dev/null 2>&1
			error_validate
	fi 
		
	exit_withchange
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
		RSYNC_REPATH="rsync"
		RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI}"
		RSYNC_TARGET="$HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull"
			create_rsynccmd
		
	MESSAGE="Replacing ${GRAVITY_FI} on $HOSTNAME"
	echo_stat	
		sudo cp $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
		error_validate
	
	MESSAGE="Validating Settings of ${GRAVITY_FI}"
	echo_stat
		
		GRAVDB_OWN=$(ls -ld ${PIHOLE_DIR}/${GRAVITY_FI} | awk '{print $3 $4}')
		if [ "$GRAVDB_OWN" != "piholepihole" ]
		then
			MESSAGE="Validating Ownership on ${GRAVITY_FI}"
			echo_fail
			
			MESSAGE="Attempting to Compensate"
			echo_warn
			
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo_stat	
				sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
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

	if [ "$SKIP_CUSTOM" != '1' ]
	then	
		if [ "$REMOTE_CUSTOM_DNS" == "1" ]
		then
			if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
			then
			MESSAGE="Backing Up ${CUSTOM_DNS} on $HOSTNAME"
			echo_stat
				cp ${PIHOLE_DIR}/${CUSTOM_DNS} $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${CUSTOM_DNS}.backup >/dev/null 2>&1
				error_validate
			fi
			
			MESSAGE="Pulling ${CUSTOM_DNS} from ${REMOTE_HOST}"
			echo_stat
				RSYNC_REPATH="rsync"
				RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${CUSTOM_DNS}"
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
	
	logs_export
	exit_withchange
}

## Push Function
function push_gs {
	md5_compare
	
	intent_validate

	MESSAGE="Backing Up ${GRAVITY_FI} from ${REMOTE_HOST}"
	echo_stat
		RSYNC_REPATH="rsync"
		RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI}"
		RSYNC_TARGET="$HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.push"
			create_rsynccmd

	MESSAGE="Pushing ${GRAVITY_FI} to ${REMOTE_HOST}"
	echo_stat
		RSYNC_REPATH="sudo rsync"
		RSYNC_SOURCE="${PIHOLE_DIR}/${GRAVITY_FI}"
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
		CMD_REQUESTED="sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}"
			create_sshcmd

	if [ "$SKIP_CUSTOM" != '1' ]
	then	
		if [ "$REMOTE_CUSTOM_DNS" == "1" ]
		then
			MESSAGE="Backing Up ${CUSTOM_DNS} from ${REMOTE_HOST}"
			echo_stat
				RSYNC_REPATH="rsync"
				RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${CUSTOM_DNS}"
				RSYNC_TARGET="$HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${CUSTOM_DNS}.push"
					create_rsynccmd

			MESSAGE="Pushing ${CUSTOM_DNS} to ${REMOTE_HOST}"
			echo_stat
				RSYNC_REPATH="sudo rsync"
				RSYNC_SOURCE="${PIHOLE_DIR}/${CUSTOM_DNS}"
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

	MESSAGE="Inverting Tachyon Pulses"
	echo_info
		sleep 1	

	MESSAGE="Updating FTLDNS Configuration"
	echo_stat
		CMD_TIMEOUT='15'
		CMD_REQUESTED="${PIHOLE_BIN} restartdns reloadlists"
			create_sshcmd
	
	MESSAGE="Reloading FTLDNS Services"
	echo_stat
		CMD_TIMEOUT='15'
		CMD_REQUESTED="${PIHOLE_BIN} restartdns"
			create_sshcmd

	logs_export
	exit_withchange

}

function restore_gs {
	MESSAGE="This will restore ${GRAVITY_FI} on $HOSTNAME with the previous version!"
	echo_warn

	intent_validate

	MESSAGE="Restoring ${GRAVITY_FI} on $HOSTNAME"
	echo_stat	
		sudo cp $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.backup ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
		error_validate
	
	MESSAGE="Validating Ownership on ${GRAVITY_FI}"
	echo_stat
		
		GRAVDB_OWN=$(ls -ld ${PIHOLE_DIR}/${GRAVITY_FI} | awk '{print $3 $4}')
		if [ "$GRAVDB_OWN" == "piholepihole" ]
		then
			echo_good
		else
			echo_fail
			
			MESSAGE="Attempting to Compensate"
			echo_warn
			
			MESSAGE="Setting Ownership on ${GRAVITY_FI}"
			echo_stat	
				sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
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
		if [ -f $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${CUSTOM_DNS}.backup ]
		then
			MESSAGE="Restoring ${CUSTOM_DNS} on $HOSTNAME"
			echo_stat
				sudo cp $HOME/${LOCAL_FOLDR}/${BACKUP_FOLD}/${CUSTOM_DNS}.backup ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
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
	MESSAGE="Logging Successful ${TASKTYPE}"
	echo_stat
		echo -e $(date) "[${TASKTYPE}]" >> ${LOG_PATH}/${SYNCING_LOG}
		error_validate
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
	echo -e "Recent Complete ${YELLOW}RESTORE${NC} Executions"
		tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep RESTORE
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
	elif hash dbclient 2>/dev/null
	then
		timeout --preserve-status ${CMD_TIMEOUT} ${SSH_CMD} -p ${SSH_PORT} -i $HOME/${SSH_PKIF} ${REMOTE_USER}@${REMOTE_HOST} "${CMD_REQUESTED}"
			error_validate
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
	elif hash dbclient 2>/dev/null
	then
		rsync --rsync-path="${RSYNC_REPATH}" -e "${SSH_CMD} -p ${SSH_PORT} -i $HOME/${SSH_PKIF}" ${RSYNC_SOURCE} ${RSYNC_TARGET} >/dev/null 2>&1
			error_validate
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
		MESSAGE="Attempting to Compensate"
		echo_warn

		if hash dropbearkey >/dev/null 2>&1
		then
			MESSAGE="Using DROPBEARKEY Instead"
			echo_info
				if [ ! -d $HOME/.ssh ]
				then
					mkdir $HOME/.ssh >/dev/null 2>&1
				fi
			KEYGEN_COMMAND="dropbearkey -t rsa -f"
		else
			MESSAGE="No Alternatives Located"
			echo_info
				exit_nochange
		fi	
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

			elif hash dropbearkey >/dev/null 2>&1
			then
				MESSAGE="Generating ~/${SSH_PKIF} (DROPBEARKEY)"
				echo_stat
					if [ ! -d $HOME/.ssh ]
					then
						mkdir $HOME/.ssh >/dev/null 2>&1
					fi

					dropbearkey -t rsa -f $HOME/${SSH_PKIF} >/dev/null 2>&1
						error_validate
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

			if hash ssh-copy-id 2>/dev/null
			then
				ssh-copy-id -f -p ${SSH_PORT} -i $HOME/${SSH_PKIF}.pub ${REMOTE_USER}@${REMOTE_HOST}
			elif hash dbclient 2>/dev/null
			then
				dropbearkey -y -f $HOME/${SSH_PKIF} | grep "^ssh-rsa " > $HOME/${SSH_PKIF}.pub
				cat $HOME/${SSH_PKIF}.pub | dbclient -p ${SSH_PORT} ${REMOTE_USER}@${REMOTE_HOST} 'cat - >> .ssh/authorized_keys'
			fi
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
		echo_good
		SSH_CMD='dbclient'
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
	HASHMARK='0'

	MESSAGE="Analyzing ${GRAVITY_FI} on ${REMOTE_HOST}"
	echo_stat
	primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${PIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//') 
		error_validate
	
	MESSAGE="Analyzing ${GRAVITY_FI} on $HOSTNAME"
	echo_stat
	secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
		error_validate
	
	if [ "$primaryDBMD5" == "$secondDBMD5" ]
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
				
				if [ "$primaryCLMD5" == "$secondCLMD5" ]
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
	echo -e " ${YELLOW}pull${NC}		Sync remote ${GRAVITY_FI} to this server"
	echo -e " ${YELLOW}push${NC}		Force changes made on this server back"
	echo -e " ${YELLOW}restore${NC}	Restore ${GRAVITY_FI} on this server"
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
	
	MESSAGE="Running Version: ${GREEN}${VERSION}${NC}"
	echo_info

	GITVERSION=$(curl -sf https://raw.githubusercontent.com/vmstan/gravity-sync/master/VERSION)
	if [ -z "$GITVERSION" ]
	then
		MESSAGE="Latest Version: ${RED}Unknown${NC}"
	else
		if [ "$GITVERSION" != "$VERSION" ]
		then
		MESSAGE="Upgrade Available: ${PURPLE}${GITVERSION}${NC}"
		else
		MESSAGE="Latest Version: ${GREEN}${GITVERSION}${NC}"
		fi
	fi
	echo_info
	echo -e "========================================================"
}

# Task Stack
## Automate Task
function task_automate {
	TASKTYPE='AUTOMATE'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
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
	else
		MESSAGE="Enabling ${TASKTYPE}"
		echo_stat
		touch $HOME/${LOCAL_FOLDR}/dev
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
	
	update_gs
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
	
	import_gs
	validate_gs_folders
	validate_ph_folders
	validate_os_sshpass
		
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
	
	MESSAGE="Evaluating Arguments"
	echo_stat

	root_check

case $# in
	
	0)
		task_invalid
	;;
	
	1)
   		case $1 in
   	 		pull)
				TASKTYPE='PULL'
				MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
				echo_good
				
				import_gs
				validate_gs_folders
				validate_ph_folders
				validate_os_sshpass
					
				pull_gs
				exit
 			;;

			push)	
				TASKTYPE='PUSH'
				MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
				echo_good
				
				import_gs
				validate_gs_folders
				validate_ph_folders
				validate_os_sshpass
					
				push_gs
				exit
			;;

			restore)	
				TASKTYPE='RESTORE'
				MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
				echo_good

				import_gs
				validate_gs_folders
				validate_ph_folders

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

			*)
				task_invalid
			;;
		esac
	;;
	
	*)
		task_invalid
	;;
esac

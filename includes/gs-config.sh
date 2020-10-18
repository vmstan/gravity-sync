# GRAVITY SYNC BY VMSTAN #####################
# gs-config.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Configure Task
function task_configure {				
	TASKTYPE='CONFIGURE'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good
	
	if [ -f ${LOCAL_FOLDR}/${CONFIG_FILE} ]
	then		
		config_delete
	else
		# MESSAGE="${CONFIG_FILE}"
		# echo_warn
		config_generate
	fi

	backup_settime
	backup_local_gravity
	backup_local_custom
	backup_cleanup
	
	exit_withchange
}

## Generate New Configuration
function config_generate {
	# detect_ssh
	
	MESSAGE="Creating New ${CONFIG_FILE} from Template"
	echo_stat
	cp ${LOCAL_FOLDR}/${CONFIG_FILE}.example ${LOCAL_FOLDR}/${CONFIG_FILE}
	error_validate

	MESSAGE="Use Advanced Installation Options? (Leave blank for default 'No')"
	echo_need
	read INPUT_ADVANCED_INSTALL
	INPUT_ADVANCED_INSTALL="${INPUT_ADVANCED_INSTALL:-N}"
	
	if [ "${INPUT_ADVANCED_INSTALL}" != "N" ]
	then
		MESSAGE="Advanced Configuration"
		echo_info
		
		advanced_config_generate
	fi
	
	MESSAGE="Standard Settings"
	echo_info

	MESSAGE="Primary Pi-hole Address (IP or DNS)"
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
	sed -i "/REMOTE_HOST='192.168.1.10'/c\REMOTE_HOST='${INPUT_REMOTE_HOST}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
	error_validate
	
	MESSAGE="Saving User to ${CONFIG_FILE}"
	echo_stat
	sed -i "/REMOTE_USER='pi'/c\REMOTE_USER='${INPUT_REMOTE_USER}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
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
				sed -i "/REMOTE_PASS=''/c\REMOTE_PASS='${INPUT_REMOTE_PASS}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
					error_validate
			fi	
	fi

	generate_sshkey
	
	MESSAGE="Importing New ${CONFIG_FILE}"
	echo_stat
	source ${LOCAL_FOLDR}/${CONFIG_FILE}
	error_validate

	export_sshkey	
	
	MESSAGE="Testing Configuration"
	echo_info

	validate_os_sshpass
	validate_sqlite3

	detect_remotersync
}

## Advanced Configuration Options
function advanced_config_generate {
	MESSAGE="Primary Pi-hole SSH Port (Leave blank for default '22')"
		echo_need
		read INPUT_SSH_PORT
		INPUT_SSH_PORT="${INPUT_SSH_PORT:-22}"
	
		if [ "${INPUT_SSH_PORT}" != "22" ]
		then
			MESSAGE="Saving Custom SSH Port to ${CONFIG_FILE}"
			echo_stat
			sed -i "/# SSH_PORT=''/c\SSH_PORT='${INPUT_SSH_PORT}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
			error_validate
		fi
	
		MESSAGE="Enable Connectivity Checking (Leave blank for default 'Yes')"
		echo_need
		read INPUT_PING_AVOID
		INPUT_PING_AVOID="${INPUT_PING_AVOID:-Y}"
	
		if [ "${INPUT_PING_AVOID}" != "Y" ]
		then
			MESSAGE="Saving Ping Avoidance to ${CONFIG_FILE}"
			echo_stat
			sed -i "/# PING_AVOID=''/c\PING_AVOID='1'" ${LOCAL_FOLDR}/${CONFIG_FILE}
			error_validate
			PING_AVOID=1
		fi
		
		MESSAGE="Custom SSH PKIF Location (Leave blank for default '.ssh/id_rsa')"
		echo_need
		read INPUT_CUSTOM_PKIF
		INPUT_CUSTOM_PKIF="${INPUT_CUSTOM_PKIF:-.ssh/id_rsa}"
		
		if [ "${INPUT_CUSTOM_PKIF}" != ".ssh/id_rsa" ]
		then
			MESSAGE="Saving Custom PKIF to ${CONFIG_FILE}"
			echo_stat
			sed -i "/# SSH_PKIF=''/c\SSH_PKIF='${INPUT_CUSTOM_PKIF}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
			error_validate
		fi
}

## Delete Existing Configuration
function config_delete {
	source ${LOCAL_FOLDR}/${CONFIG_FILE}
	MESSAGE="Configuration File Exists"
	echo_warn
	
	echo -e "========================================================"
	cat ${LOCAL_FOLDR}/${CONFIG_FILE}
	echo -e "========================================================"
	
	MESSAGE="Are you sure you want to erase this configuration?"
	echo_warn

	intent_validate

	MESSAGE="Erasing Existing Configuration"
	echo_stat
	rm -f ${LOCAL_FOLDR}/${CONFIG_FILE}
		error_validate

	config_generate
}
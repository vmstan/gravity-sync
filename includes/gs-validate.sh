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
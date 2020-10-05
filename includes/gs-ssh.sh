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
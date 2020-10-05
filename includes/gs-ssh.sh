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
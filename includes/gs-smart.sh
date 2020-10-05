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
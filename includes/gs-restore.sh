# GRAVITY SYNC BY VMSTAN #####################
# gs-restore.sh ##############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Restore Task
function task_restore {
    TASKTYPE='RESTORE'
    MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
    echo_good

    show_target
    validate_gs_folders
    validate_ph_folders
    validate_sqlite3

    restore_gs
    exit
}

## Restore Gravity
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
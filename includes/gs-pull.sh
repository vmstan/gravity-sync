# GRAVITY SYNC BY VMSTAN #####################
# gs-pull.sh #################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

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
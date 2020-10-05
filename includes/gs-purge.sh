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
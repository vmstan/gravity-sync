# GRAVITY SYNC BY VMSTAN #####################
# gs-core.sh #################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Import Settings
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

## Invalid Tasks
function task_invalid {
	echo_fail
	list_gs_arguments
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

# Standard Output
function start_gs {
	MESSAGE="${PROGRAM} ${VERSION} Executing"
	echo_info
	
	import_gs

	MESSAGE="Evaluating Arguments"
	echo_stat

	if [ "${ROOT_CHECK_AVOID}" != "1" ]
	then
		root_check
	fi
}

# Standard Output No Config
function start_gs_noconfig {
	MESSAGE="${PROGRAM} ${VERSION} Executing"
	echo_info

	MESSAGE="Evaluating Arguments"
	echo_stat
}
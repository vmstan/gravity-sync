# GRAVITY SYNC BY VMSTAN #####################
# gs-update.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Master Branch
function update_gs {
	if [ -f "$HOME/${LOCAL_FOLDR}/dev" ]
	then
		source $HOME/${LOCAL_FOLDR}/dev
	else
		BRANCH='origin/master'
	fi

	if [ "$BRANCH" != "origin/master" ]
	then
		MESSAGE="Pulling from ${BRANCH}"
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
		git reset --hard ${BRANCH} >/dev/null 2>&1
			error_validate
	fi
}

## Show Version
function show_version {
	echo -e "========================================================"
	MESSAGE="${BOLD}${PROGRAM}${NC} by ${CYAN}@vmstan${NC}"
	echo_info

	MESSAGE="${BLUE}https://github.com/vmstan/gravity-sync${NC}"
	echo_info

	if [ -f $HOME/${LOCAL_FOLDR}/dev ]
	then
		DEVVERSION="dev"
	elif [ -f $HOME/${LOCAL_FOLDR}/beta ]
	then 
		DEVVERSION="beta"
	else
		DEVVERSION=""
	fi
	
	MESSAGE="Running Version: ${GREEN}${VERSION}${NC} ${DEVVERSION}"
	echo_info

	GITVERSION=$(curl -sf https://raw.githubusercontent.com/vmstan/gravity-sync/master/VERSION)
	if [ -z "$GITVERSION" ]
	then
		MESSAGE="Latest Version: ${RED}Unknown${NC}"
	else
		if [ "$GITVERSION" != "$VERSION" ]
		then
		MESSAGE="Update Available: ${PURPLE}${GITVERSION}${NC}"
		else
		MESSAGE="Latest Version: ${GREEN}${GITVERSION}${NC}"
		fi
	fi
	echo_info
	echo -e "========================================================"
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
	elif [ -f $HOME/${LOCAL_FOLDR}/beta ]
	then
		MESSAGE="Disabling BETA"
		echo_stat
		rm -f $HOME/${LOCAL_FOLDR}/beta
			error_validate
		
		MESSAGE="Enabling ${TASKTYPE}"
		echo_stat
		touch $HOME/${LOCAL_FOLDR}/dev
			error_validate
	else
		MESSAGE="Enabling ${TASKTYPE}"
		echo_stat
		touch $HOME/${LOCAL_FOLDR}/dev
			error_validate

		MESSAGE="Updating Cache"
		echo_stat
		git fetch --all >/dev/null 2>&1
			error_validate
	fi
		
		git branch -r

		MESSAGE="Select Branch to Update Against"
		echo_need
		read INPUT_BRANCH

		echo -e "BRANCH='${INPUT_BRANCH}'" >> $HOME/${LOCAL_FOLDR}/dev
	fi
	
	update_gs
	
	exit_withchange
}

## Update Task
function task_update {
	TASKTYPE='UPDATE'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	dbclient_warning
	
	update_gs

	exit_withchange
}

## Version Task
function task_version {
	TASKTYPE='VERSION'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	show_version
	exit_nochange
}
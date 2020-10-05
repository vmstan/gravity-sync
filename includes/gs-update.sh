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
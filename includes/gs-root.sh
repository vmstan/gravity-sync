# GRAVITY SYNC BY VMSTAN #####################
# gs-root.sh #################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Sudo Creation Task
function task_sudo {
	TASKTYPE='SUDO'
	MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
	echo_good

	MESSAGE="Creating Sudoer.d Template"
	echo_stat

	NEW_SUDO_USER=$(whoami)
	echo -e "${NEW_SUDO_USER} ALL=(ALL) NOPASSWD: ${PIHOLE_DIR}" > $HOME/${LOCAL_FOLDR}/templates/gs-nopasswd.sudo
		error_validate

	MESSAGE="Installing Sudoer.d File"
	echo_stat

	sudo install -m 0440 $HOME/${LOCAL_FOLDR}/templates/gs-nopasswd.sudo /etc/sudoers.d/gs-nopasswd
		error_validate
}

# Root Check
function root_check {
	if [ ! "$EUID" -ne 0 ]
  	then 
		TASKTYPE='ROOT'
		MESSAGE="${MESSAGE} ${TASKTYPE}"
		echo_fail
	  	
		MESSAGE="${PROGRAM} Must Not Run as Root"
		echo_warn
		
		exit_nochange
	fi
}
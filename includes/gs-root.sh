# GRAVITY SYNC BY VMSTAN #####################
# gs-root.sh #################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Sudo Creation Task
function task_sudo {
    TASKTYPE='SUDO'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    MESSAGE="Creating sudoers.d template file"
    echo_stat
    
    NEW_SUDO_USER=$(whoami)
    echo -e "${NEW_SUDO_USER} ALL=(ALL) NOPASSWD: ALL" > ${LOCAL_FOLDR}/templates/gs-nopasswd.sudo
    error_validate
    
    MESSAGE="Installing sudoers.d file on $HOSTNAME"
    echo_stat
    
    sudo install -m 0440 ${LOCAL_FOLDR}/templates/gs-nopasswd.sudo /etc/sudoers.d/gs-nopasswd
    error_validate
    
    exit_withchange
}

## Root Check
function root_check {
    if [ ! "$EUID" -ne 0 ]
    then
        TASKTYPE='ROOT'
        MESSAGE="${MESSAGE} ${TASKTYPE}"
        echo_fail
        
        MESSAGE="${PROGRAM} should not run as 'root'"
        echo_warn
        
        exit_nochange
    fi
}

function new_root_check {
    CURRENTUSER=$(whoami)
    if [ ! "$EUID" -ne 0 ]
    then
        LOCALADMIN=""
    else
        # Check Sudo
        SUDOCHECK=$(groups ${CURRENTUSER} | grep -e 'sudo' -e 'wheel')
        if [ "$SUDOCHECK" == "" ]
        then
            LOCALADMIN="nosudo"
        else
            LOCALADMIN="sudo"
        fi
    fi
    
    if [ "$LOCALADMIN" == "nosudo" ]
    then
        TASKTYPE='ROOT'
        MESSAGE="${MESSAGE} ${TASKTYPE}"
        echo_fail
        
        MESSAGE="${CURRENTUSER} has insufficent user rights for ${PROGRAM}"
        echo_warn
        
        exit_nochange
    fi
}
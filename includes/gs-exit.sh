# GRAVITY SYNC BY VMSTAN #####################
# gs-exit.sh #################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## No Changes Made
function exit_nochange {
    SCRIPT_END=$SECONDS
    
    if [ "${TASKTYPE}" == "" ]
    then
        MESSAGE="${PROGRAM} Aborting ($((SCRIPT_END-SCRIPT_START)) seconds)"
    else
        MESSAGE="${PROGRAM} ${TASKTYPE} Aborting ($((SCRIPT_END-SCRIPT_START)) seconds)"
    fi
    
    echo_grav
    exit 0
}

## Changes Made
function exit_withchange {
    SCRIPT_END=$SECONDS
    
    if [ "${TASKTYPE}" == "" ]
    then
        MESSAGE="${PROGRAM} Completed ($((SCRIPT_END-SCRIPT_START)) seconds)"
    else
        MESSAGE="${PROGRAM} ${TASKTYPE} Completed ($((SCRIPT_END-SCRIPT_START)) seconds)"
    fi
    
    echo_grav
    exit 0
}

## List GS Arguments
function list_gs_arguments {
    echo -e "Usage: $0 [options]"
    echo -e "Example: '$0 pull'"
    echo_lines
    echo -e "Setup Options:"
    echo -e " ${YELLOW}config${NC}      Creates a new ${PROGRAM} configuration file"
    echo -e " ${YELLOW}automate${NC}    Schedules the ${PROGRAM} replication task using crontab"
    echo -e " ${YELLOW}version${NC}     Shows the installed version of ${PROGRAM} and check for updates"
    echo -e " ${YELLOW}update${NC}      Upgrades ${PROGRAM} to the latest available version using Git"
    echo -e " ${YELLOW}dev${NC}         Sets update command to use a development version of ${PROGRAM}"
    echo -e " ${YELLOW}sudo${NC}        Configures passwordless sudo for current user"
    echo_blank
    echo -e "Replication Options:"
    echo -e " ${YELLOW}smart${NC}       Detects Pi-hole changes on primary and secondary and then combines them"
    echo -e " ${YELLOW}pull${NC}        Brings the remote Pi-hole configuration to this server"
    echo -e " ${YELLOW}push${NC}        Sends the local Pi-hole configuration to the primary"
    echo -e " ${YELLOW}compare${NC}     Just checks for Pi-hole differences at each side without making changes"
    echo -e " ${YELLOW}restore${NC}     Restores the Pi-hole configuration on this server"
    echo -e " ${YELLOW}backup${NC}      Just backs up the Pi-hole on this server"
    echo_blank
    echo -e "Debug Options:"
    echo -e " ${YELLOW}logs${NC}        Shows the recent successful replication jobs/times"
    echo -e " ${YELLOW}cron${NC}        Displays the output of last crontab execution"
    echo -e " ${YELLOW}info${NC}        Shows information about the current configuration"
    echo_lines
    exit_nochange
}
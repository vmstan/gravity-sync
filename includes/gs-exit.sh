# GRAVITY SYNC BY VMSTAN #####################
# gs-exit.sh #################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## No Changes Made
function exit_nochange {
    SCRIPT_END=$SECONDS
    MESSAGE="${PROGRAM} ${TASKTYPE} Aborting ($((SCRIPT_END-SCRIPT_START)) seconds)"
    echo_info
    exit 0
}

## Changes Made
function exit_withchange {
    SCRIPT_END=$SECONDS
    MESSAGE="${PROGRAM} ${TASKTYPE} Completed ($((SCRIPT_END-SCRIPT_START)) seconds)"
    echo_info
    exit 0
}

## List GS Arguments
function list_gs_arguments {
    echo -e "Usage: $0 [options]"
    echo -e "Example: '$0 pull'"
    echo_lines
    echo -e "Setup Options:"
    echo -e " ${YELLOW}config${NC}      Create a new ${CONFIG_FILE} file"
    echo -e " ${YELLOW}automate${NC}    Add a scheduled pull task to crontab"
    echo -e " ${YELLOW}update${NC}      Update ${PROGRAM} to the latest version"
    echo -e " ${YELLOW}version${NC}     Display installed version of ${PROGRAM}"
    echo -e " ${YELLOW}sudo${NC}        Configure passwordless sudo for current user"
    echo_blank
    echo -e "Replication Options:"
    echo -e " ${YELLOW}smart${NC}       Detect changes on each side and bring them together"
    echo -e " ${YELLOW}pull${NC}        Force remote configuration changes to this server"
    echo -e " ${YELLOW}push${NC}        Force local configuration made on this server back"
    echo -e " ${YELLOW}restore${NC}     Restore the ${GRAVITY_FI} on this server"
    echo -e " ${YELLOW}backup${NC}      Backup the ${GRAVITY_FI} on this server"
    echo -e " ${YELLOW}compare${NC}     Just check for differences"
    echo_blank
    echo -e "Debug Options:"
    echo -e " ${YELLOW}logs${NC}        Show recent successful replication jobs"
    echo -e " ${YELLOW}cron${NC}        Display output of last crontab execution"
    echo -e " ${YELLOW}info${NC}        Shows information about the current system"
    echo_lines
    exit_nochange
}
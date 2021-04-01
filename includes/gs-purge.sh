# GRAVITY SYNC BY VMSTAN #####################
# gs-purge.sh ################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Purge Task
function task_purge {
    TASKTYPE="THE-PURGE"
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    echo_lines
    echo -e "THIS WILL RESET YOUR ENTIRE GRAVITY SYNC INSTALLATION"
    echo -e "This will remove:"
    echo -e "- All backups files."
    echo -e "- Your ${CONFIG_FILE} file."
        
    if [ -f "${LOCAL_FOLDR}/dev" ]
    then
        echo -e "- Your development branch updater."
    elif [ -f "${LOCAL_FOLDR}/beta" ]
    then
        echo -e "- Your beta branch updater."
    fi
        
    echo -e "- All cronjob/automation tasks."
    echo -e "- All job history/logs."
    echo -e "- Associated SSH id_rsa keys."
    echo -e ""
    echo -e "This function cannot be undone!"
    echo -e ""
    echo -e "YOU WILL NEED TO REBUILD GRAVITY SYNC AFTER EXECUTION"
    echo -e "Pi-hole binaries, configuration and services ARE NOT impacted!"
    echo -e "Your device will continue to resolve and block DNS requests,"
    echo -e "but your ${UI_GRAVITY_NAME} and ${UI_CUSTOM_NAME} WILL NOT sync anymore,"
    echo -e "until you reconfigure Gravity Sync on this device."
    echo_lines
        
    intent_validate
    
    MESSAGE="${UI_PURGE_CLEANING_DIR}"
    echo_stat
    
    git clean -f -X -d >/dev/null 2>&1
    error_validate
    
    clear_cron
    
    MESSAGE="${UI_PURGE_DELETE_SSH_KEYS}"
    echo_stat
    
    rm -f $HOME/${SSH_PKIF} >/dev/null 2>&1
    rm -f $HOME/${SSH_PKIF}.pub >/dev/null 2>&1
    error_validate
    
    MESSAGE="${UI_PURGE_MATRIX_ALIGNMENT}"
    echo_info
    
    sleep 1
    
    # MESSAGE="Realigning Dilithium Matrix"
    # echo_good
    
    update_gs
}
# GRAVITY SYNC BY VMSTAN #####################
# gs-compare.sh ##############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Compare Task
function task_compare {
    TASKTYPE='COMPARE'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    show_target
    validate_gs_folders
    validate_ph_folders
    
    if [ "${INCLUDE_CNAME}" == "1" ]
    then
        validate_dns_folders
    fi
    
    validate_os_sshpass
    
    previous_md5
    md5_compare
    backup_cleanup
    
    exit_withchange
}
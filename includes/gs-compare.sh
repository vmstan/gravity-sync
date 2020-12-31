## Compare Task
function task_compare {
    TASKTYPE='COMPARE'
    MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
    echo_good

    show_target
    validate_gs_folders
    validate_ph_folders
    validate_os_sshpass
    
    previous_md5
    md5_compare
    exit_withchange
}
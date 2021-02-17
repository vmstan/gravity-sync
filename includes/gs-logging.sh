# GRAVITY SYNC BY VMSTAN #####################
# gs-logging.sh ##############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Logs Task
function task_logs {
    TASKTYPE='LOGS'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    logs_gs
}

## Core Logging
### Write Logs Out
function logs_export {
    if [ "${TASKTYPE}" != "BACKUP" ]
    then
        MESSAGE="${UI_LOGGING_HASHES}"
        echo_stat
        rm -f ${LOG_PATH}/${HISTORY_MD5}
        echo -e ${primaryDBMD5} >> ${LOG_PATH}/${HISTORY_MD5}
        echo -e ${secondDBMD5} >> ${LOG_PATH}/${HISTORY_MD5}
        echo -e ${primaryCLMD5} >> ${LOG_PATH}/${HISTORY_MD5}
        echo -e ${secondCLMD5} >> ${LOG_PATH}/${HISTORY_MD5}
        echo -e ${primaryCNMD5} >> ${LOG_PATH}/${HISTORY_MD5}
        echo -e ${secondCNMD5} >> ${LOG_PATH}/${HISTORY_MD5}
        error_validate
    fi
    
    MESSAGE="${UI_LOGGING_SUCCESS} ${TASKTYPE}"
    echo_stat
    echo -e $(date) "[${TASKTYPE}]" >> ${LOG_PATH}/${SYNCING_LOG}
    error_validate
}

### Output Sync Logs
function logs_gs {
    MESSAGE="${UI_LOGGING_DISPLAY}"
    echo_info
    
    echo_lines
    echo -e "${UI_LOGGING_RECENT_COMPLETE} ${YELLOW}SMART${NC}"
    tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep SMART
    echo -e "${UI_LOGGING_RECENT_COMPLETE} ${YELLOW}PULL${NC}"
    tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep PULL
    echo -e "${UI_LOGGING_RECENT_COMPLETE} ${YELLOW}PUSH${NC}"
    tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep PUSH
    echo -e "${UI_LOGGING_RECENT_COMPLETE} ${YELLOW}BACKUP${NC}"
    tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep BACKUP
    echo -e "${UI_LOGGING_RECENT_COMPLETE} ${YELLOW}RESTORE${NC}"
    tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep RESTORE
    echo_lines
    
    exit_nochange
}

## Crontab Logs
### Core Crontab Logs
function show_crontab {
    MESSAGE="${UI_LOGGING_DISPLAY}"
    echo_stat
    
    if [ -f ${LOG_PATH}/${CRONJOB_LOG} ]
    then
        if [ -s ${LOG_PATH}/${CRONJOB_LOG} ]
        echo_good
        
        # MESSAGE="Tailing ${LOG_PATH}/${CRONJOB_LOG}"
        # echo_info
        
        echo_lines
        date -r ${LOG_PATH}/${CRONJOB_LOG}
        cat ${LOG_PATH}/${CRONJOB_LOG}
        echo_lines
        
        exit_nochange
        then
            echo_fail
            
            MESSAGE="${LOG_PATH}/${CRONJOB_LOG} ${UI_LOGGING_EMPTY}"
            echo_info
            
            exit_nochange
        fi
    else
        echo_fail
        
        MESSAGE="${LOG_PATH}/${CRONJOB_LOG} ${UI_LOGGING_MISSING}"
        echo_info
        
        exit_nochange
    fi
}

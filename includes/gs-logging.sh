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
        MESSAGE="Saving File Hashes"
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
    
    MESSAGE="Logging Successful ${TASKTYPE}"
    echo_stat
    echo -e $(date) "[${TASKTYPE}]" >> ${LOG_PATH}/${SYNCING_LOG}
    error_validate
}

### Output Sync Logs
function logs_gs {
    MESSAGE="Tailing ${LOG_PATH}/${SYNCING_LOG}"
    echo_info
    
    echo -e "========================================================"
    echo -e "Recent Complete ${YELLOW}SMART${NC} Executions"
    tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep SMART
    echo -e "Recent Complete ${YELLOW}PULL${NC} Executions"
    tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep PULL
    echo -e "Recent Complete ${YELLOW}PUSH${NC} Executions"
    tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep PUSH
    echo -e "Recent Complete ${YELLOW}BACKUP${NC} Executions"
    tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep BACKUP
    echo -e "Recent Complete ${YELLOW}RESTORE${NC} Executions"
    tail -n 7 "${LOG_PATH}/${SYNCING_LOG}" | grep RESTORE
    echo -e "========================================================"
    
    exit_nochange
}

## Crontab Logs
### Core Crontab Logs
function show_crontab {
    MESSAGE="Replaying Last Cronjob"
    echo_stat
    
    if [ -f ${LOG_PATH}/${CRONJOB_LOG} ]
    then
        if [ -s ${LOG_PATH}/${CRONJOB_LOG} ]
        echo_good
        
        MESSAGE="Tailing ${LOG_PATH}/${CRONJOB_LOG}"
        echo_info
        
        echo -e "========================================================"
        date -r ${LOG_PATH}/${CRONJOB_LOG}
        cat ${LOG_PATH}/${CRONJOB_LOG}
        echo -e "========================================================"
        
        exit_nochange
        then
            echo_fail
            
            MESSAGE="${LOG_PATH}/${CRONJOB_LOG} is Empty"
            echo_info
            
            exit_nochange
        fi
    else
        echo_fail
        
        MESSAGE="${LOG_PATH}/${CRONJOB_LOG} is Missing"
        echo_info
        
        exit_nochange
    fi
}

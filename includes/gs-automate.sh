# GRAVITY SYNC BY VMSTAN #####################
# gs-automate.sh #############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Automate Task
function task_automate {
    TASKTYPE='AUTOMATE'
    MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
    echo_good
    
    CRON_EXIST='0'
    CRON_CHECK=$(crontab -l | grep -q "${GS_FILENAME}"  && echo '1' || echo '0')
    if [ ${CRON_CHECK} == 1 ]
    then
        MESSAGE="Automation Task Already Exists"
        echo_info
        CRON_EXIST='1'
    fi
    
    MESSAGE="Configuring Automated Synchronization"
    echo_info
    
    if [[ $1 =~ ^[0-9][0-9]?$ ]]
    then
        INPUT_AUTO_FREQ=$1
    else
        MESSAGE="Synchronization Frequency in Minutes (5, 10, 15, 30) or 0 to Disable (default 15)"
        echo_need
        read INPUT_AUTO_FREQ
        INPUT_AUTO_FREQ="${INPUT_AUTO_FREQ:-15}"
    fi
    
    if [ $INPUT_AUTO_FREQ == 5 ] || [ $INPUT_AUTO_FREQ == 10 ] || [ $INPUT_AUTO_FREQ == 15 ] || [ $INPUT_AUTO_FREQ == 30 ]
    then
        if [ $CRON_EXIST == 1 ]
        then
            clear_cron
        fi
        
        MESSAGE="Saving New Synchronization Automation"
        echo_stat
        (crontab -l 2>/dev/null; echo "*/${INPUT_AUTO_FREQ} * * * * ${BASH_PATH} ${LOCAL_FOLDR}/${GS_FILENAME} smart > ${LOG_PATH}/${CRONJOB_LOG}") | crontab -
        error_validate
    elif [ $INPUT_AUTO_FREQ == 0 ]
    then
        if [ $CRON_EXIST == 1 ]
        then
            clear_cron
            
            MESSAGE="Synchronization Automation Disabled"
            echo_warn
        else
            MESSAGE="No Synchronization Automation Scheduled"
            echo_warn
        fi
    else
        MESSAGE="Invalid Frequency Range"
        echo_fail
        exit_nochange
    fi
    
   # MESSAGE="Configuring Daily Backup Frequency"
   # echo_info
    
   # if [[ $2 =~ ^[0-9][0-9]?$ ]]
   # then
   #     INPUT_AUTO_BACKUP=$2
   # else
   #     MESSAGE="Hour of Day to Backup (1-24) or 0 to Disable"
   #     echo_need
   #     read INPUT_AUTO_BACKUP
   # fi
    
   # if [ $INPUT_AUTO_BACKUP -gt 24 ]
   # then
   #     MESSAGE="Invalid Frequency Range"
   #     echo_fail
   #     exit_nochange
   # elif [ $INPUT_AUTO_BACKUP -lt 1 ]
   # then
   #     MESSAGE="No Backup Automation Scheduled"
   #     echo_warn
   # else
   #     MESSAGE="Saving New Backup Automation"
   #     echo_stat
   #     (crontab -l 2>/dev/null; echo "0 ${INPUT_AUTO_BACKUP} * * * ${BASH_PATH} ${LOCAL_FOLDR}/${GS_FILENAME} backup >/dev/null 2>&1") | crontab -
   #     error_validate
   # fi
    
    exit_withchange
}

## Clear Existing Automation Settings
function clear_cron {
    MESSAGE="Removing Existing Automation"
    echo_stat
    
    crontab -l > cronjob-old.tmp
    sed "/${GS_FILENAME}/d" cronjob-old.tmp > cronjob-new.tmp
    crontab cronjob-new.tmp 2>/dev/null
    error_validate
    rm cronjob-old.tmp
    rm cronjob-new.tmp
}

## Cron Task
function task_cron {
    TASKTYPE='CRON'
    MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
    echo_good
    
    show_crontab
}
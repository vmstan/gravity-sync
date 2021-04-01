# GRAVITY SYNC BY VMSTAN #####################
# gs-automate.sh #############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Automate Task
function task_automate {
    TASKTYPE='AUTOMATE'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    CRON_EXIST='0'
    CRON_CHECK=$(crontab -l | grep -q "${GS_FILENAME}"  && echo '1' || echo '0')
    if [ ${CRON_CHECK} == 1 ]
    then
        MESSAGE="${UI_AUTO_CRON_EXISTS}"
        echo_warn
        CRON_EXIST='1'
    fi
    
    MESSAGE="${UI_AUTO_CRON_DISPLAY_FREQ}"
    echo_info
    
    if [[ $1 =~ ^[0-9][0-9]?$ ]]
    then
        INPUT_AUTO_FREQ=$1
    else
        MESSAGE="${UI_AUTO_CRON_SELECT_FREQ}"
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
        
        MESSAGE="${UI_AUTO_CRON_SAVING}"
        echo_stat
        (crontab -l 2>/dev/null; echo "*/${INPUT_AUTO_FREQ} * * * * ${BASH_PATH} ${LOCAL_FOLDR}/${GS_FILENAME} smart > ${LOG_PATH}/${CRONJOB_LOG}") | crontab -
        error_validate
    elif [ $INPUT_AUTO_FREQ == 0 ]
    then
        if [ $CRON_EXIST == 1 ]
        then
            clear_cron
            
            # MESSAGE="Synchronization automation has been disabled"
            # echo_warn
        else
            MESSAGE="${UI_AUTO_CRON_DISABLED}"
            echo_warn
        fi
    else
        MESSAGE="${UI_INVALID_SELECTION}"
        echo_fail
        exit_nochange
    fi
    
    exit_withchange
}

## Clear Existing Automation Settings
function clear_cron {
    MESSAGE="${UI_AUTO_CRON_DISABLED}"
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
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    show_crontab
}
# GRAVITY SYNC BY VMSTAN #####################
# gs-restore.sh ##############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Restore Task
function task_restore {
    TASKTYPE='RESTORE'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    show_target
    validate_gs_folders
    validate_ph_folders
    
    if [ "${INCLUDE_CNAME}" == "1" ]
    then
        validate_dns_folders
    fi
    
    validate_sqlite3
    
    restore_gs
    exit
}

## Restore Gravity
function restore_gs {
    MESSAGE=""
    echo_warn
    
    GRAVITY_DATE_LIST=$(ls ${LOCAL_FOLDR}/${BACKUP_FOLD} | grep $(date +%Y) | grep ${GRAVITY_FI} | colrm 18)
    
    if [ "${GRAVITY_DATE_LIST}" != "" ]
    then
        MESSAGE="${UI_RESTORE_WARNING}"
        echo_info
        
        echo_lines
        ls ${LOCAL_FOLDR}/${BACKUP_FOLD} | grep $(date +%Y) | grep ${GRAVITY_FI} | colrm 18
        echo -e "IGNORE-GRAVITY"
        echo_lines
        
        MESSAGE="${UI_RESTORE_SELECT_DATE} ${UI_GRAVITY_NAME}"
        echo_need
        read INPUT_BACKUP_DATE
        
        if [ "$INPUT_BACKUP_DATE" == "IGNORE-GRAVITY" ]
        then
            MESSAGE="${UI_RESTORE_SKIPPING} ${UI_GRAVITY_NAME}"
            echo_warn
        elif [ -f ${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_BACKUP_DATE}-${GRAVITY_FI}.backup ]
        then
            MESSAGE="${UI_GRAVITY_NAME} ${UI_RESTORE_BACKUP_SELECTED}"
            echo_good
            
            DO_GRAVITY_RESTORE='1'
        else
            MESSAGE="${UI_RESTORE_INVALID}"
            echo_info
            
            exit_nochange
        fi
    fi
    
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
        then
            CUSTOM_DATE_LIST=$(ls ${LOCAL_FOLDR}/${BACKUP_FOLD} | grep $(date +%Y) | grep ${CUSTOM_DNS} | colrm 18)
            
            if [ "${CUSTOM_DATE_LIST}" != "" ]
            then
                # MESSAGE="${UI_RESTORE_SELECT_DATE} ${UI_CUSTOM_NAME}"
                # echo_info
                
                echo_lines
                ls ${LOCAL_FOLDR}/${BACKUP_FOLD} | grep $(date +%Y) | grep ${CUSTOM_DNS} | colrm 18
                echo -e "IGNORE-CUSTOM"
                echo_lines
                
                MESSAGE="${UI_RESTORE_SELECT_DATE} ${UI_CUSTOM_NAME}"
                echo_need
                read INPUT_DNSBACKUP_DATE
                
                if [ "$INPUT_DNSBACKUP_DATE" == "IGNORE-CUSTOM" ]
                then
                    MESSAGE="${UI_RESTORE_SKIPPING} ${UI_CUSTOM_NAME}"
                    echo_warn
                elif [ -f ${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_DNSBACKUP_DATE}-${CUSTOM_DNS}.backup ]
                then
                    MESSAGE="${UI_CUSTOM_NAME} ${UI_RESTORE_BACKUP_SELECTED}"
                    echo_good
                    
                    DO_CUSTOM_RESTORE='1'
                else
                    MESSAGE="${UI_RESTORE_INVALID}"
                    echo_fail
                    
                    exit_nochange
                fi
            else
                MESSAGE="${UI_CUSTOM_NAME} ${UI_RESTORE_BACKUP_UNAVAILABLE}"
                echo_info
            fi
        fi
    fi
    
    if [ "$INCLUDE_CNAME" == '1' ]
    then
        if [ -f ${DNSMAQ_DIR}/${CNAME_CONF} ]
        then
            CNAME_DATE_LIST=$(ls ${LOCAL_FOLDR}/${BACKUP_FOLD} | grep $(date +%Y) | grep ${CNAME_CONF} | colrm 18)
            
            if [ "${CNAME_DATE_LIST}" != "" ]
            then
                # MESSAGE="${UI_RESTORE_SELECT_DATE} ${UI_CNAME_NAME}"
                # echo_info
                
                echo_lines
                ls ${LOCAL_FOLDR}/${BACKUP_FOLD} | grep $(date +%Y) | grep ${CNAME_CONF} | colrm 18
                echo -e "IGNORE-CNAME"
                echo_lines
                
                MESSAGE="${UI_RESTORE_SELECT_DATE} ${UI_CNAME_NAME}"
                echo_need
                read INPUT_CNAMEBACKUP_DATE
                
                if [ "$INPUT_CNAMEBACKUP_DATE" == "IGNORE-CNAME" ]
                then
                    MESSAGE="${UI_RESTORE_SKIPPING} ${UI_CNAME_NAME}"
                    echo_warn
                elif [ -f ${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_CNAMEBACKUP_DATE}-${CNAME_CONF}.backup ]
                then
                    MESSAGE="${UI_CNAME_NAME} ${UI_RESTORE_BACKUP_SELECTED}"
                    echo_good
                    
                    DO_CNAME_RESTORE='1'
                else
                    MESSAGE="${UI_RESTORE_INVALID}"
                    echo_fail
                    
                    exit_nochange
                fi
            else
                MESSAGE="${UI_CNAME_NAME} ${UI_RESTORE_BACKUP_UNAVAILABLE}"
                echo_info
            fi
        fi
    fi
    
    if [ "$DO_GRAVITY_RESTORE" == "1" ]
    then
        MESSAGE="${UI_GRAVITY_NAME} ${UI_RESTORE_FROM} ${INPUT_BACKUP_DATE}"
        echo_info
    else
        MESSAGE="${UI_GRAVITY_NAME} ${UI_RESTORE_BACKUP_UNAVAILABLE}"
        echo_info
    fi
    
    if [ "$DO_CUSTOM_RESTORE" == "1" ]
    then
        MESSAGE="${UI_CUSTOM_NAME} ${UI_RESTORE_FROM} ${INPUT_DNSBACKUP_DATE}"
        echo_info
    else
        MESSAGE="${UI_CUSTOM_NAME} ${UI_RESTORE_BACKUP_UNAVAILABLE}"
        echo_info
    fi
    
    if [ "$DO_CNAME_RESTORE" == "1" ]
    then
        MESSAGE="${UI_CNAME_NAME} ${UI_RESTORE_FROM} ${INPUT_CNAMEBACKUP_DATE}"
        echo_info
    else
        MESSAGE="${UI_CNAME_NAME} ${UI_RESTORE_BACKUP_UNAVAILABLE}"
        echo_info
    fi
    
    intent_validate
    
    MESSAGE="${UI_RESTORE_TIME_TRAVEL}"
    echo_info
    
    # MESSAGE="Stopping FTLDNS services on $HOSTNAME"
    # echo_stat
    
    # ${PH_EXEC} stop >/dev/null 2>&1
    # error_validate
    
    if [ "$DO_GRAVITY_RESTORE" == "1" ]
    then
        MESSAGE="${UI_RESTORE_SECONDARY} ${UI_GRAVITY_NAME}"
        echo_stat
        sudo cp ${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_BACKUP_DATE}-${GRAVITY_FI}.backup ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
        error_validate
        
        validate_gravity_permissions
    fi
    
    if [ "$DO_CUSTOM_RESTORE" == '1' ]
    then
        if [ -f ${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_DNSBACKUP_DATE}-${CUSTOM_DNS}.backup ]
        then
            MESSAGE="${UI_RESTORE_SECONDARY} ${UI_CUSTOM_NAME}"
            echo_stat
            sudo cp ${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_DNSBACKUP_DATE}-${CUSTOM_DNS}.backup ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
            error_validate
            
            validate_custom_permissions
        fi
    fi
    
    if [ "$DO_CNAME_RESTORE" == '1' ]
    then
        if [ -f ${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_CNAMEBACKUP_DATE}-${CNAME_CONF}.backup ]
        then
            MESSAGE="${UI_RESTORE_SECONDARY} ${UI_CNAME_NAME}"
            echo_stat
            sudo cp ${LOCAL_FOLDR}/${BACKUP_FOLD}/${INPUT_CNAMEBACKUP_DATE}-${CNAME_CONF}.backup ${DNSMAQ_DIR}/${CNAME_CONF} >/dev/null 2>&1
            error_validate
            
            validate_cname_permissions
        fi
    fi
    
    pull_gs_reload
    
    MESSAGE="${UI_RESTORE_PUSH_PROMPT}"
    echo_need
    read PUSH_TO_PRIMARY
    
    if [ "${PUSH_TO_PRIMARY}" == "Yes" ] || [ "${PUSH_TO_PRIMARY}" == "yes" ] || [ "${PUSH_TO_PRIMARY}" == "Y" ] || [ "${PUSH_TO_PRIMARY}" == "y" ]
    then
        push_gs
    elif [ "${PUSH_TO_PRIMARY}" == "No" ] || [ "${PUSH_TO_PRIMARY}" == "no" ] || [ "${PUSH_TO_PRIMARY}" == "N" ] || [ "${PUSH_TO_PRIMARY}" == "n" ]
    then
        MESSAGE="${UI_RESTORE_PUSH_NOPUSH}"
        echo_info
        
        logs_export
        exit_withchange
    else
        MESSAGE="${UI_INVALID_SELECTION} - ${UI_RESTORE_PUSH_NOPUSH}"
        echo_warn
        
        logs_export
        exit_withchange
    fi
}
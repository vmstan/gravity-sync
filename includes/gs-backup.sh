# GRAVITY SYNC BY VMSTAN #####################
# gs-backup.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Backup Task
function task_backup() {
    TASKTYPE='BACKUP'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    backup_settime
    backup_local_gravity
    backup_local_gravity_integrity
    backup_local_custom
    backup_local_cname
    backup_cleanup
    
    logs_export
    exit_withchange
}

function backup_settime() {
    BACKUPTIMESTAMP=$(date +%F-%H%M%S)
}

function backup_local_gravity() {
    MESSAGE="${UI_BACKUP_SECONDARY} ${UI_GRAVITY_NAME}"
    echo_stat
    
    sqlite3 ${PIHOLE_DIR}/${GRAVITY_FI} ".backup '${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${GRAVITY_FI}.backup'"
    error_validate
}

function backup_local_gravity_integrity() {
    MESSAGE="${UI_BACKUP_INTEGRITY}"
    echo_stat
    
    secondaryIntegrity=$(sqlite3 ${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${GRAVITY_FI}.backup 'PRAGMA integrity_check;' | sed 's/\s.*$//')
    error_validate
    
    if [ "$secondaryIntegrity" != 'ok' ]
    then
        MESSAGE="${UI_BACKUP_INTEGRITY_FAILED} ${UI_GRAVITY_NAME}"
        echo_fail
        
        MESSAGE="${UI_BACKUP_INTEGRITY_DELETE} ${UI_GRAVITY_NAME}"
        echo_stat
            
        sudo rm ${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${GRAVITY_FI}.backup
        error_validate
        
        exit_nochange
    fi
}

function backup_local_custom() {
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
        then
            MESSAGE="${UI_BACKUP_SECONDARY} ${UI_CUSTOM_NAME}"
            echo_stat
            
            cp ${PIHOLE_DIR}/${CUSTOM_DNS} ${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${CUSTOM_DNS}.backup
            error_validate
        else
            MESSAGE="No local ${CUSTOM_DNS} detected"
            echo_info
        fi
    fi
}

function backup_local_cname() {
    if [ "${INCLUDE_CNAME}" == '1' ]
    then
        if [ -f ${DNSMAQ_DIR}/${CNAME_CONF} ]
        then
            MESSAGE="${UI_BACKUP_SECONDARY} ${UI_CNAME_NAME}"
            echo_stat
            
            cp ${DNSMAQ_DIR}/${CNAME_CONF} ${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${CNAME_CONF}.backup
            error_validate
        else
            MESSAGE="No local ${CNAME_CONF} detected"
            echo_info
        fi
    fi
}

function backup_remote_gravity() {
    MESSAGE="${UI_BACKUP_PRIMARY} ${UI_GRAVITY_NAME}"
    echo_stat
    
    CMD_TIMEOUT=$BACKUP_TIMEOUT
    CMD_REQUESTED="sudo sqlite3 ${RIHOLE_DIR}/${GRAVITY_FI} \".backup '${RIHOLE_DIR}/${GRAVITY_FI}.backup'\""
    create_sshcmd
}

function backup_remote_gravity_integrity() {
    MESSAGE="${UI_BACKUP_INTEGRITY}"
    echo_stat
    
    primaryIntegrity=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "sqlite3 ${RIHOLE_DIR}/${GRAVITY_FI}.backup 'PRAGMA integrity_check;'" | sed 's/\s.*$//')
    error_validate
    
    if [ "$primaryIntegrity" != 'ok' ]
    then
        MESSAGE="${UI_BACKUP_INTEGRITY_FAILED} ${UI_GRAVITY_NAME}"
        echo_fail
        
        MESSAGE="{UI_BACKUP_INTEGRITY_DELETE} ${UI_GRAVITY_NAME}"
        echo_stat
        
        CMD_TIMEOUT='15'
        CMD_REQUESTED="sudo rm ${RIHOLE_DIR}/${GRAVITY_FI}.backup"
        create_sshcmd
        
        exit_nochange
    fi
}

function backup_remote_custom() {
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        MESSAGE="${UI_BACKUP_PRIMARY} ${UI_CUSTOM_NAME}"
        echo_stat
        
        CMD_TIMEOUT='15'
        CMD_REQUESTED="sudo cp ${RIHOLE_DIR}/${CUSTOM_DNS} ${RIHOLE_DIR}/${CUSTOM_DNS}.backup"
        create_sshcmd
    fi
}

function backup_remote_cname() {
    if [ "$INCLUDE_CNAME" == '1' ]
    then
        MESSAGE="${UI_BACKUP_PRIMARY} ${UI_CNAME_NAME}"
        echo_stat
        
        CMD_TIMEOUT='15'
        CMD_REQUESTED="sudo cp ${RNSMAQ_DIR}/${CNAME_CONF} ${RIHOLE_DIR}/dnsmasq.d-${CNAME_CONF}.backup"
        create_sshcmd
    fi
}

function backup_cleanup() {
    MESSAGE="${UI_BACKUP_PURGE}"
    echo_stat
    
    find ${LOCAL_FOLDR}/${BACKUP_FOLD}/*.backup -mtime +${BACKUP_RETAIN} -type f -delete
    error_validate
    
    BACKUP_FOLDER_SIZE=$(du -h ${LOCAL_FOLDR}/${BACKUP_FOLD}  | sed 's/\s.*$//')
    
    MESSAGE="${BACKUP_RETAIN} ${UI_BACKUP_REMAIN} (${BACKUP_FOLDER_SIZE})"
    echo_info
}
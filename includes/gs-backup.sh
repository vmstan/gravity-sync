
# GRAVITY SYNC BY VMSTAN #####################
# gs-backup.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

function backup_settime() {
    BACKUPTIMESTAMP=$(date +%F-%H%M%S)
}

function backup_local_gravity() {
    MESSAGE="${UI_BACKUP_SECONDARY} ${UI_GRAVITY_NAME}"
    echo_stat
    
    sqlite3 ${PIHOLE_DIR}/${GRAVITY_FI} ".backup '${PIHOLE_DIR}/${GRAVITY_FI}.gsbackup'"
    error_validate
}

function backup_local_gravity_integrity() {
    MESSAGE="${UI_BACKUP_INTEGRITY}"
    echo_stat
    
    sleep $BACKUP_INTEGRITY_WAIT
    secondaryIntegrity=$(sqlite3 ${PIHOLE_DIR}/${GRAVITY_FI}.gsbackup 'PRAGMA integrity_check;' | sed 's/\s.*$//')
    error_validate
    
    if [ "$secondaryIntegrity" != 'ok' ]
    then
        MESSAGE="${UI_BACKUP_INTEGRITY_FAILED} ${UI_GRAVITY_NAME}"
        echo_fail
        
        MESSAGE="${UI_BACKUP_INTEGRITY_DELETE} ${UI_GRAVITY_NAME}"
        echo_stat
            
        sudo rm ${PIHOLE_DIR}/${GRAVITY_FI}.gsbackup
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
            
            cp ${PIHOLE_DIR}/${CUSTOM_DNS} ${PIHOLE_DIR}/${CUSTOM_DNS}.gsbackup
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
            
            cp ${DNSMAQ_DIR}/${CNAME_CONF} ${PIHOLE_DIR}/${CNAME_CONF}.gsbackup
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
    CMD_REQUESTED="sudo sqlite3 ${RIHOLE_DIR}/${GRAVITY_FI} \".backup '${RIHOLE_DIR}/${GRAVITY_FI}.gsbackup'\""
    create_sshcmd
}

function backup_remote_gravity_integrity() {
    MESSAGE="${UI_BACKUP_INTEGRITY}"
    echo_stat
    
    sleep $BACKUP_INTEGRITY_WAIT
    primaryIntegrity=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "sqlite3 ${RIHOLE_DIR}/${GRAVITY_FI}.gsbackup 'PRAGMA integrity_check;'" | sed 's/\s.*$//')
    error_validate
    
    if [ "$primaryIntegrity" != 'ok' ]
    then
        MESSAGE="${UI_BACKUP_INTEGRITY_FAILED} ${UI_GRAVITY_NAME}"
        echo_fail
        
        MESSAGE="{UI_BACKUP_INTEGRITY_DELETE} ${UI_GRAVITY_NAME}"
        echo_stat
        
        CMD_TIMEOUT=$BACKUP_TIMEOUT
        CMD_REQUESTED="sudo rm ${RIHOLE_DIR}/${GRAVITY_FI}.gsbackup"
        create_sshcmd
        
        exit_nochange
    fi
}

function backup_remote_custom() {
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        MESSAGE="${UI_BACKUP_PRIMARY} ${UI_CUSTOM_NAME}"
        echo_stat
        
        CMD_TIMEOUT=$BACKUP_TIMEOUT
        CMD_REQUESTED="sudo cp ${RIHOLE_DIR}/${CUSTOM_DNS} ${RIHOLE_DIR}/${CUSTOM_DNS}.gsbackup"
        create_sshcmd
    fi
}

function backup_remote_cname() {
    if [ "$INCLUDE_CNAME" == '1' ]
    then
        MESSAGE="${UI_BACKUP_PRIMARY} ${UI_CNAME_NAME}"
        echo_stat
        
        CMD_TIMEOUT=$BACKUP_TIMEOUT
        CMD_REQUESTED="sudo cp ${RNSMAQ_DIR}/${CNAME_CONF} ${RIHOLE_DIR}/${CNAME_CONF}.gsbackup"
        create_sshcmd
    fi
}

function backup_cleanup() {
    MESSAGE="${UI_BACKUP_PURGE} on local"
    echo_stat
    # git clean -fq
    rm -f ${PIHOLE_DIR}/*.gsbackup
    error_validate

    MESSAGE="${UI_BACKUP_PURGE} on remote"
    echo_stat
    CMD_TIMEOUT=$BACKUP_TIMEOUT
    CMD_REQUESTED="rm -f ${RIHOLE_DIR}/*.gsbackup"
    create_sshcmd
}
# GRAVITY SYNC BY VMSTAN #####################
# gs-push.sh #################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Push Task
function task_push {
    TASKTYPE='PUSH'
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
    validate_os_sshpass
    
    push_gs
    exit
}

## Push Gravity
function push_gs_grav {
    backup_remote_gravity
    backup_local_gravity
    backup_local_gravity_integrity
    
    MESSAGE="${UI_BACKUP_COPY} ${UI_GRAVITY_NAME}"
    echo_stat
    RSYNC_REPATH="rsync"
    RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${RIHOLE_DIR}/${GRAVITY_FI}.backup"
    RSYNC_TARGET="${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.push"
    create_rsynccmd
    
    MESSAGE="${UI_PUSH_SECONDARY} ${UI_GRAVITY_NAME}"
    echo_stat
    RSYNC_REPATH="sudo rsync"
    RSYNC_SOURCE="${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${GRAVITY_FI}.backup"
    RSYNC_TARGET="${REMOTE_USER}@${REMOTE_HOST}:${RIHOLE_DIR}/${GRAVITY_FI}"
    create_rsynccmd
    
    MESSAGE="${UI_SET_FILE_OWNERSHIP} ${UI_GRAVITY_NAME}"
    echo_stat
    CMD_TIMEOUT='15'
    CMD_REQUESTED="sudo chown ${RILE_OWNER} ${RIHOLE_DIR}/${GRAVITY_FI}"
    create_sshcmd
    
    MESSAGE="${UI_SET_FILE_PERMISSION} ${UI_GRAVITY_NAME}"
    echo_stat
    CMD_TIMEOUT='15'
    CMD_REQUESTED="sudo chmod 664 ${RIHOLE_DIR}/${GRAVITY_FI}"
    create_sshcmd
}

## Push Custom
function push_gs_cust {
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ "$REMOTE_CUSTOM_DNS" == "1" ]
        then
            backup_remote_custom
            backup_local_custom
            
            MESSAGE="${UI_BACKUP_COPY} ${UI_CUSTOM_NAME}"
            echo_stat
            RSYNC_REPATH="rsync"
            RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${RIHOLE_DIR}/${CUSTOM_DNS}.backup"
            RSYNC_TARGET="${LOCAL_FOLDR}/${BACKUP_FOLD}/${CUSTOM_DNS}.push"
            create_rsynccmd
            
            MESSAGE="${UI_PUSH_SECONDARY} ${UI_CUSTOM_NAME}"
            echo_stat
            RSYNC_REPATH="sudo rsync"
            RSYNC_SOURCE="${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${CUSTOM_DNS}.backup"
            RSYNC_TARGET="${REMOTE_USER}@${REMOTE_HOST}:${RIHOLE_DIR}/${CUSTOM_DNS}"
            create_rsynccmd
            
            MESSAGE="${UI_SET_FILE_OWNERSHIP} ${UI_CUSTOM_NAME}"
            echo_stat
            CMD_TIMEOUT='15'
            CMD_REQUESTED="sudo chown root:root ${RIHOLE_DIR}/${CUSTOM_DNS}"
            create_sshcmd
            
            MESSAGE="${UI_SET_FILE_PERMISSIONS} ${UI_CUSTOM_NAME}"
            echo_stat
            CMD_TIMEOUT='15'
            CMD_REQUESTED="sudo chmod 644 ${RIHOLE_DIR}/${CUSTOM_DNS}"
            create_sshcmd
        fi
    fi
}

## Push Custom
function push_gs_cname {
    if [ "${INCLUDE_CNAME}" == '1' ]
    then
        if [ "$REMOTE_CNAME_DNS" == "1" ]
        then
            backup_remote_cname
            backup_local_cname
            
            MESSAGE="${UI_BACKUP_COPY} ${UI_CNAME_NAME}"
            echo_stat
            RSYNC_REPATH="rsync"
            RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${RIHOLE_DIR}/dnsmasq.d-${CNAME_CONF}.backup"
            RSYNC_TARGET="${LOCAL_FOLDR}/${BACKUP_FOLD}/${CNAME_CONF}.push"
            create_rsynccmd
            
            MESSAGE="${UI_PUSH_SECONDARY} ${UI_CNAME_NAME}"
            echo_stat
            RSYNC_REPATH="sudo rsync"
            RSYNC_SOURCE="${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${CNAME_CONF}.backup"
            RSYNC_TARGET="${REMOTE_USER}@${REMOTE_HOST}:${RNSMAQ_DIR}/${CNAME_CONF}"
            create_rsynccmd
            
            MESSAGE="${UI_SET_FILE_OWNERSHIP} ${UI_CNAME_NAME}"
            echo_stat
            CMD_TIMEOUT='15'
            CMD_REQUESTED="sudo chown root:root ${RNSMAQ_DIR}/${CNAME_CONF}"
            create_sshcmd
            
                        
            MESSAGE="${UI_SET_FILE_PERMISSIONS} ${UI_CNAME_NAME}"
            echo_stat
            CMD_TIMEOUT='15'
            CMD_REQUESTED="sudo chmod 644 ${RNSMAQ_DIR}/${CNAME_CONF}"
            create_sshcmd
        fi
    fi
}

## Push Reload
function push_gs_reload {
    MESSAGE="${UI_PUSH_RELOAD_WAIT}"
    echo_info
    sleep 1
    
    MESSAGE="${UI_FTLDNS_CONFIG_PUSH_UPDATE}"
    echo_stat
    CMD_TIMEOUT='15'
    CMD_REQUESTED="${RH_EXEC} restartdns reloadlists"
    create_sshcmd
    
    MESSAGE="${UI_FTLDNS_CONFIG_PUSH_RELOAD}"
    echo_stat
    CMD_TIMEOUT='15'
    CMD_REQUESTED="${RH_EXEC} restartdns"
    create_sshcmd
}

## Push Function
function push_gs {
    previous_md5
    md5_compare
    backup_settime
    
    intent_validate
    
    push_gs_grav
    push_gs_cust
    push_gs_cname
    push_gs_reload
    md5_recheck
    backup_cleanup
    
    logs_export
    exit_withchange
}
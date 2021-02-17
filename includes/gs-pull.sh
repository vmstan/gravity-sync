# GRAVITY SYNC BY VMSTAN #####################
# gs-pull.sh #################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Pull Task
function task_pull {
    TASKTYPE='PULL'
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
    
    pull_gs
    exit
}

## Pull Gravity
function pull_gs_grav {
    
    backup_local_gravity
    backup_remote_gravity
    
    MESSAGE="Pulling ${GRAVITY_FI} from ${REMOTE_HOST}"
    echo_stat
    RSYNC_REPATH="rsync"
    RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${RIHOLE_DIR}/${GRAVITY_FI}.backup"
    RSYNC_TARGET="${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull"
    create_rsynccmd
    
    MESSAGE="Replacing ${GRAVITY_FI} on $HOSTNAME"
    echo_stat
    sudo cp ${LOCAL_FOLDR}/${BACKUP_FOLD}/${GRAVITY_FI}.pull ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
    error_validate
    
    validate_gravity_permissions
}

## Pull Custom
function pull_gs_cust {
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ "$REMOTE_CUSTOM_DNS" == "1" ]
        then
            backup_local_custom
            backup_remote_custom
            
            MESSAGE="Pulling ${CUSTOM_DNS} from ${REMOTE_HOST}"
            echo_stat
            RSYNC_REPATH="rsync"
            RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${RIHOLE_DIR}/${CUSTOM_DNS}.backup"
            RSYNC_TARGET="${LOCAL_FOLDR}/${BACKUP_FOLD}/${CUSTOM_DNS}.pull"
            create_rsynccmd
            
            MESSAGE="Replacing ${CUSTOM_DNS} on $HOSTNAME"
            echo_stat
            sudo cp ${LOCAL_FOLDR}/${BACKUP_FOLD}/${CUSTOM_DNS}.pull ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
            error_validate
            
            validate_custom_permissions
        fi
    fi
}

## Pull CNAME
function pull_gs_cname {
    if [ "${INCLUDE_CNAME}" == '1' ]
    then
        if [ "$REMOTE_CNAME_DNS" == "1" ]
        then
            backup_local_cname
            backup_remote_cname
            
            MESSAGE="Pulling ${CNAME_CONF} from ${REMOTE_HOST}"
            echo_stat
            RSYNC_REPATH="rsync"
            RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${RIHOLE_DIR}/dnsmasq.d-${CNAME_CONF}.backup"
            RSYNC_TARGET="${LOCAL_FOLDR}/${BACKUP_FOLD}/${CNAME_CONF}.pull"
            create_rsynccmd
            
            MESSAGE="Replacing ${CNAME_CONF} on $HOSTNAME"
            echo_stat
            sudo cp ${LOCAL_FOLDR}/${BACKUP_FOLD}/${CNAME_CONF}.pull ${DNSMAQ_DIR}/${CNAME_CONF} >/dev/null 2>&1
            error_validate
            
            MESSAGE="Validating settings on ${CNAME_CONF}"
            echo_stat
            
            validate_cname_permissions
        fi
    fi
}

## Pull Reload
function pull_gs_reload {
    MESSAGE="Isolating regeneration pathways"
    echo_info
    sleep 1
    
    MESSAGE="Updating FTLDNS configuration"
    echo_stat
    ${PH_EXEC} restartdns reloadlists >/dev/null 2>&1
    error_validate
    
    MESSAGE="Reloading FTLDNS services"
    echo_stat
    ${PH_EXEC} restartdns >/dev/null 2>&1
    error_validate
}

## Pull Function
function pull_gs {
    previous_md5
    md5_compare
    
    backup_settime
    pull_gs_grav
    pull_gs_cust
    pull_gs_cname
    pull_gs_reload
    md5_recheck
    backup_cleanup
    
    logs_export
    exit_withchange
}
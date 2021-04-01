# GRAVITY SYNC BY VMSTAN #####################
# gs-core.sh #################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

# Standard Output
function start_gs {
    MESSAGE="${UI_CORE_INIT}"
    echo_grav
    cd ${LOCAL_FOLDR}
    
    import_gs
    ph_type
    
    MESSAGE="${UI_CORE_EVALUATING}"
    echo_stat
    
    if [ "${ROOT_CHECK_AVOID}" != "1" ]
    then
        new_root_check
    fi
    
    if [ "${INCLUDE_CNAME}" == "1" ] && [ "${SKIP_CUSTOM}" == "1" ]
    then
        MESSAGE="${UI_INVALID_DNS_CONFIG} ${CONFIG_FILE}"
        echo_fail
        
        exit_nochange
    fi
}

# Standard Output No Config
function start_gs_noconfig {
    MESSAGE="${UI_CORE_INIT}"
    echo_grav
    cd ${LOCAL_FOLDR}
    
    MESSAGE="${UI_CORE_EVALUATING}"
    echo_stat
}

## Import Settings
function import_gs {
    relocate_config_gs
    
    MESSAGE="${UI_CORE_LOADING} ${CONFIG_FILE}"
    echo -en "${STAT} $MESSAGE"
    if [ -f ${LOCAL_FOLDR}/settings/${CONFIG_FILE} ]
    then
        source ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
        
        # MESSAGE="Targeting ${REMOTE_USER}@${REMOTE_HOST}"
        # echo_info
        
        # detect_ssh
    else
        echo_fail
        
        MESSAGE="${UI_CORE_MISSING} ${CONFIG_FILE}"
        echo_info
        
        TASKTYPE='CONFIG'
        config_generate
    fi
}

function relocate_config_gs {
    if [ -f ${LOCAL_FOLDR}/${CONFIG_FILE} ]
    then
        MESSAGE="${UI_CORE_RELOCATING} ${CONFIG_FILE}"
        echo -en "${STAT} $MESSAGE"
        
        mv ${LOCAL_FOLDR}/${CONFIG_FILE} ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
    fi
    
    if [ -f ${LOCAL_FOLDR}/${SYNCING_LOG} ]
    then
        MESSAGE="${UI_CORE_RELOCATING} ${SYNCING_LOG}"
        echo -en "${STAT} $MESSAGE"
        
        mv ${LOCAL_FOLDR}/${SYNCING_LOG} ${LOG_PATH}/${SYNCING_LOG}
        error_validate
    fi
    
    if [ -f ${LOCAL_FOLDR}/${CRONJOB_LOG} ]
    then
        MESSAGE="${UI_CORE_RELOCATING} ${CRONJOB_LOG}"
        echo -en "${STAT} $MESSAGE"
        
        mv ${LOCAL_FOLDR}/${CRONJOB_LOG} ${LOG_PATH}/${CRONJOB_LOG}
        error_validate
    fi
    
    if [ -f ${LOCAL_FOLDR}/${HISTORY_MD5} ]
    then
        MESSAGE="${UI_CORE_RELOCATING} ${HISTORY_MD5}"
        echo -en "${STAT} $MESSAGE"
        
        mv ${LOCAL_FOLDR}/${HISTORY_MD5} ${LOG_PATH}/${HISTORY_MD5}
        error_validate
    fi
}

## Invalid Tasks
function task_invalid {
    echo_fail
    list_gs_arguments
}

## Error Validation
function error_validate {
    if [ "$?" != "0" ]
    then
        echo_fail
        exit 1
    else
        echo_good
    fi
}

## Error Validation
function silent_error_validate {
    if [ "$?" != "0" ]
    then
        echo_fail
        exit 1
    else
        echo_sameline
    fi
}

function ph_type {
    if [ "$PH_IN_TYPE" == "default" ]
    then
        PH_EXEC="${PIHOLE_BIN}"
    elif [ "$PH_IN_TYPE" == "docker" ]
    then
        PH_EXEC="sudo ${DOCKER_BIN} exec $(sudo ${DOCKER_BIN} ps -qf name=${DOCKER_CON}) pihole"
    elif [ "$PH_IN_TYPE" == "podman" ]
    then
        PH_EXEC="sudo ${PODMAN_BIN} exec ${DOCKER_CON} pihole"
    fi
    
    if [ "$RH_IN_TYPE" == "default" ]
    then
        RH_EXEC="${RIHOLE_BIN}"
    elif [ "$RH_IN_TYPE" == "docker" ]
    then
        RH_EXEC="sudo ${ROCKER_BIN} exec \$(sudo ${ROCKER_BIN} ps -qf name=${ROCKER_CON}) pihole"
    elif [ "$RH_IN_TYPE" == "podman" ]
    then
        RH_EXEC="sudo ${RODMAN_BIN} exec ${ROCKER_CON} pihole"
    fi
}

# GRAVITY SYNC BY VMSTAN #####################
# gs-core.sh #################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Import Settings
function import_gs {
    MESSAGE="Importing ${CONFIG_FILE} Settings"
    echo -en "${STAT} $MESSAGE"
    if [ -f ${LOCAL_FOLDR}/${CONFIG_FILE} ]
    then
        source ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate
        
        # MESSAGE="Targeting ${REMOTE_USER}@${REMOTE_HOST}"
        # echo_info
        
        # detect_ssh
    else
        echo_fail
        
        MESSAGE="${CONFIG_FILE} Missing"
        echo_info
        
        TASKTYPE='CONFIG'
        config_generate
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

function ph_type {
    if [ "$PH_IN_TYPE" == "default" ]
    then
        PH_EXEC="${PIHOLE_BIN}"
    elif [ "$PH_IN_TYPE" == "docker" ]
    then
        PH_EXEC="sudo ${DOCKER_BIN} exec ${DOCKER_CON} pihole"
    fi
    
    if [ "$RH_IN_TYPE" == "default" ]
    then
        RH_EXEC="${RIHOLE_BIN}"
    elif [ "$RH_IN_TYPE" == "docker" ]
    then
        RH_EXEC="sudo ${ROCKER_BIN} exec ${ROCKER_CON} pihole"
    fi
}

# Standard Output
function start_gs {
    MESSAGE="${PROGRAM} ${VERSION} Executing"
    echo_grav
    cd ${LOCAL_FOLDR}
    
    import_gs
    ph_type
    
    MESSAGE="Evaluating Arguments"
    echo_stat
    
    if [ "${ROOT_CHECK_AVOID}" != "1" ]
    then
        new_root_check
    fi
    
    if [ "${INCLUDE_CNAME}" == "1" ] && [ "${SKIP_CUSTOM}" == "1" ]
    then
        MESSAGE="Invalid Local DNS Settings in ${CONFIG_FILE}"
        echo_fail
        
        exit_nochange
    fi
}

# Standard Output No Config
function start_gs_noconfig {
    MESSAGE="${PROGRAM} ${VERSION} Executing"
    echo_grav
    cd ${LOCAL_FOLDR}
    
    MESSAGE="Evaluating Arguments"
    echo_stat
}
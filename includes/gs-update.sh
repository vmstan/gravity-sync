# GRAVITY SYNC BY VMSTAN #####################
# gs-update.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Master Branch
function update_gs {
    if [ -f "${LOCAL_FOLDR}/dev" ]
    then
        source ${LOCAL_FOLDR}/dev
    else
        BRANCH='origin/master'
    fi
    
    if [ "$BRANCH" != "origin/master" ]
    then
        MESSAGE="Pulling from ${BRANCH}"
        echo_info
    fi
    
    GIT_CHECK=$(git status | awk '{print $1}')
    if [ "$GIT_CHECK" == "fatal:" ]
    then
        MESSAGE="Updater usage requires GitHub installation"
        echo_warn
        exit_nochange
    else
        MESSAGE="Downloading updates via GitHub"
        echo_stat
        git fetch --all >/dev/null 2>&1
        error_validate
        MESSAGE="Deploying the latest ${PROGRAM} code"
        echo_stat
        git reset --hard ${BRANCH} >/dev/null 2>&1
        error_validate
    fi
}

## Show Version
function show_version {
    echo_lines
    MESSAGE="${PURPLE}${PROGRAM}${NC} for Pi-hole"
    echo_info
    
    MESSAGE="${BLUE}https://github.com/vmstan/gravity-sync${NC}"
    echo_info
    
    if [ -f ${LOCAL_FOLDR}/dev ]
    then
        DEVVERSION="dev"
    elif [ -f ${LOCAL_FOLDR}/beta ]
    then
        DEVVERSION="beta"
    else
        DEVVERSION=""
    fi
    
    MESSAGE="Running version: ${GREEN}${VERSION}${NC} ${DEVVERSION}"
    echo_info
    
    GITVERSION=$(curl -sf https://raw.githubusercontent.com/vmstan/gravity-sync/master/VERSION)
    if [ -z "$GITVERSION" ]
    then
        MESSAGE="Latest version: ${RED}Unknown${NC}"
    else
        if [ "$GITVERSION" != "$VERSION" ]
        then
            MESSAGE="Update available: ${RED}${GITVERSION}${NC}"
        else
            MESSAGE="Latest version: ${GREEN}${GITVERSION}${NC}"
        fi
    fi
    echo_info
    echo_lines
}

function show_info() {
    if [ -f ${LOCAL_FOLDR}/dev ]
    then
        DEVVERSION="-dev"
    elif [ -f ${LOCAL_FOLDR}/beta ]
    then
        DEVVERSION="-beta"
    else
        DEVVERSION=""
    fi
    
    echo_lines
    echo -e "${YELLOW}Local Software Versions${NC}"
    echo -e "${PURPLE}Gravity Sync${NC} ${VERSION}${DEVVERSION}"
    echo -e "${BLUE}Pi-hole${NC}"
    if [ "${PH_IN_TYPE}" == "default" ]
    then
        pihole version
    elif [ "${PH_IN_TYPE}" == "docker" ]
    then 
        sudo docker exec -it pihole pihole -v
    elif [ "${PH_IN_TYPE}" == "podman" ]
    then 
        sudo podman exec -it pihole pihole -v
    fi
    
    uname -srm
    echo -e "bash $BASH_VERSION"
    ssh -V
    rsync --version | grep version
    SQLITE3_VERSION=$(sqlite3 --version)
    echo -e "sqlite3 ${SQLITE3_VERSION}"
    sudo --version | grep "Sudo version"
    git --version
    
    if hash docker 2>/dev/null
    then
        docker --version
    fi

    if hash podman 2>/dev/null
    then
        podman --version
    fi

    echo -e ""
    
    echo -e "${YELLOW}Local/Secondary Instance Settings${NC}"
    echo -e "Local Hostname: $HOSTNAME"
    echo -e "Local Pi-hole Type: ${PH_IN_TYPE}"
    echo -e "Local Pi-hole Config Directory: ${PIHOLE_DIR}"
    echo -e "Local DNSMASQ Config Directory: ${DNSMAQ_DIR}"
    
    if [ "${PH_IN_TYPE}" == "default" ]
    then
        echo -e "Local Pi-hole Binary Directory: ${PIHOLE_BIN}"
    elif [ "${PH_IN_TYPE}" == "docker" ]
    then 
        echo -e "Local Pi-hole Container Name: ${DOCKER_CON}"
        echo -e "Local Docker Binary Directory: ${DOCKER_BIN}"
    elif [ "${PH_IN_TYPE}" == "podman" ]
    then 
        echo -e "Local Pi-hole Container Name: ${DOCKER_CON}"
        echo -e "Local Podman Binary Directory: ${PODMAN_BIN}"
    fi
    
    echo -e "Local File Owner Settings: ${FILE_OWNER}"
    
    if [ ${SKIP_CUSTOM} == '0' ]
    then
        echo -e "DNS Replication: Enabled (default)"
    elif [ ${SKIP_CUSTOM} == '1' ]
    then
        echo -e "DNS Replication: Disabled (custom)"
    else
        echo -e "DNS Replication: Invalid Configuration"
    fi
    
    if [ ${INCLUDE_CNAME} == '1' ]
    then
        echo -e "CNAME Replication: Enabled (custom)"
    elif [ ${INCLUDE_CNAME} == '0' ]
    then
        echo -e "CNAME Replication: Disabled (default)"
    else
        echo -e "CNAME Replication: Invalid Configuration"
    fi
    
    if [ ${VERIFY_PASS} == '1' ]
    then
        echo -e "Verify Operations: Enabled (default)"
    elif [ ${VERIFY_PASS} == '0' ]
    then
        echo -e "Verify Operations: Disabled (custom)"
    else
        echo -e "Verify Operations: Invalid Configuration"
    fi
    
    if [ ${PING_AVOID} == '0' ]
    then
        echo -e "Ping Test: Enabled (default)"
    elif [ ${PING_AVOID} == '1' ]
    then
        echo -e "Ping Test: Disabled (custom)"
    else
        echo -e "Ping Test: Invalid Configuration"
    fi
    
    if [ ${BACKUP_RETAIN} == '7' ]
    then
        echo -e "Backup Retention: 7 days (default)"
    elif [ ${BACKUP_RETAIN} == '1' ]
    then
        echo -e "Backup Retention: 1 day (custom)"
    else
        echo -e "Backup Retention: ${BACKUP_RETAIN} days (custom)"
    fi
        
    echo -e ""
    echo -e "${YELLOW}Remote/Primary Instance Settings${NC}"
    echo -e "Remote Hostname/IP: ${REMOTE_HOST}"
    echo -e "Remote Username: ${REMOTE_USER}"
    echo -e "Remote Pi-hole Type: ${RH_IN_TYPE}"
    echo -e "Remote Pi-hole Config Directory: ${RIHOLE_DIR}"
    echo -e "Remote DNSMASQ Config Directory: ${RNSMAQ_DIR}"

    if [ "${RH_IN_TYPE}" == "default" ]
    then
        echo -e "Remote Pi-hole Binary Directory: ${RIHOLE_BIN}"
    elif [ "${RH_IN_TYPE}" == "docker" ]
    then 
        echo -e "Remote Pi-hole Container Name: ${ROCKER_CON}"
        echo -e "Remote Docker Binary Directory: ${ROCKER_BIN}"
    elif [ "${RH_IN_TYPE}" == "podman" ]
    then 
        echo -e "Remote Pi-hole Container Name: ${ROCKER_CON}"
        echo -e "Remote Podman Binary Directory: ${RODMAN_BIN}"
    fi

    echo -e "Remote File Owner Settings: ${RILE_OWNER}"
    echo_lines
}

## Devmode Task
function task_devmode {
    TASKTYPE='DEV'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    if [ -f ${LOCAL_FOLDR}/dev ]
    then
        MESSAGE="Disabling ${TASKTYPE}"
        echo_stat
        rm -f ${LOCAL_FOLDR}/dev
        error_validate
    elif [ -f ${LOCAL_FOLDR}/beta ]
    then
        MESSAGE="Disabling BETA"
        echo_stat
        rm -f ${LOCAL_FOLDR}/beta
        error_validate
        
        MESSAGE="Enabling ${TASKTYPE}"
        echo_stat
        touch ${LOCAL_FOLDR}/dev
        error_validate
    else
        MESSAGE="Enabling ${TASKTYPE}"
        echo_stat
        touch ${LOCAL_FOLDR}/dev
        error_validate
        
        MESSAGE="Checking available branches"
        echo_stat
        git fetch --all >/dev/null 2>&1
        error_validate
        
        git branch -r
        
        MESSAGE="Select GitHub branch to update against"
        echo_need
        read INPUT_BRANCH
        
        echo -e "BRANCH='${INPUT_BRANCH}'" >> ${LOCAL_FOLDR}/dev
    fi
    
    update_gs
    
    exit_withchange
}

## Update Task
function task_update {
    TASKTYPE='UPDATE'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    dbclient_warning
    
    update_gs
    
    exit_withchange
}

## Version Task
function task_version {
    TASKTYPE='VERSION'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    show_version
    exit_nochange
}

## Info Task

function task_info() {
    TASKTYPE='INFO'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    show_info
    
    exit_nochange
}
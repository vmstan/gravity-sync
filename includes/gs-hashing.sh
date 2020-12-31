# GRAVITY SYNC BY VMSTAN #####################
# gs-hasing.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Validate Sync Required
function md5_compare {
    HASHMARK='0'

    MESSAGE="Analyzing ${GRAVITY_FI} on ${REMOTE_HOST}"
    echo_stat
    primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//') 
        error_validate
    
    MESSAGE="Analyzing ${GRAVITY_FI} on $HOSTNAME"
    echo_stat
    secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
        error_validate
    
    if [ "$primaryDBMD5" == "$last_primaryDBMD5" ] && [ "$secondDBMD5" == "$last_secondDBMD5" ]
    then
        HASHMARK=$((HASHMARK+0))
    else
        MESSAGE="Differenced ${GRAVITY_FI} Detected"
        echo_warn
        HASHMARK=$((HASHMARK+1))
    fi

    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
        then
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="Analyzing ${CUSTOM_DNS} on ${REMOTE_HOST}"
                echo_stat

                primaryCLMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//'") 
                    error_validate
                
                MESSAGE="Analyzing ${CUSTOM_DNS} on $HOSTNAME"
                echo_stat
                secondCLMD5=$(md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//')
                    error_validate
                
                if [ "$primaryCLMD5" == "$last_primaryCLMD5" ] && [ "$secondCLMD5" == "$last_secondCLMD5" ]
                then
                    HASHMARK=$((HASHMARK+0))
                else
                    MESSAGE="Differenced ${CUSTOM_DNS} Detected"
                    echo_warn
                    HASHMARK=$((HASHMARK+1))
                fi
            else
                MESSAGE="No ${CUSTOM_DNS} Detected on ${REMOTE_HOST}"
                echo_info
            fi
        else
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${REMOTE_HOST} has ${CUSTOM_DNS}"
                HASHMARK=$((HASHMARK+1))
                echo_info
            fi	
            MESSAGE="No ${CUSTOM_DNS} Detected on $HOSTNAME"
            echo_info
        fi
    fi

    if [ "$HASHMARK" != "0" ]
    then
        MESSAGE="Replication Required"
        echo_warn
        HASHMARK=$((HASHMARK+0))
    else
        MESSAGE="No Replication Required"
        echo_info
            exit_nochange
    fi
}

function previous_md5 {
    if [ -f "${LOG_PATH}/${HISTORY_MD5}" ]
    then
        last_primaryDBMD5=$(sed "1q;d" ${LOG_PATH}/${HISTORY_MD5})
        last_secondDBMD5=$(sed "2q;d" ${LOG_PATH}/${HISTORY_MD5})
        last_primaryCLMD5=$(sed "3q;d" ${LOG_PATH}/${HISTORY_MD5})
        last_secondCLMD5=$(sed "4q;d" ${LOG_PATH}/${HISTORY_MD5})
    else
        last_primaryDBMD5="0"
        last_secondDBMD5="0"
        last_primaryCLMD5="0"
        last_secondCLMD5="0"
    fi
}

function md5_recheck {
    MESSAGE="Performing Replicator Diagnostics"
    echo_info
    
    HASHMARK='0'

    MESSAGE="Reanalyzing ${GRAVITY_FI} on ${REMOTE_HOST}"
    echo_stat
    primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//') 
        error_validate
    
    MESSAGE="Reanalyzing ${GRAVITY_FI} on $HOSTNAME"
    echo_stat
    secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
        error_validate

    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
        then
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="Reanalyzing ${CUSTOM_DNS} on ${REMOTE_HOST}"
                echo_stat

                primaryCLMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//'") 
                    error_validate
                
                MESSAGE="Reanalyzing ${CUSTOM_DNS} on $HOSTNAME"
                echo_stat
                secondCLMD5=$(md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//')
                    error_validate
            else
                MESSAGE="No ${CUSTOM_DNS} Detected on ${REMOTE_HOST}"
                echo_info
            fi
        else
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${REMOTE_HOST} has ${CUSTOM_DNS}"
                echo_info
            fi	
            MESSAGE="No ${CUSTOM_DNS} Detected on $HOSTNAME"
            echo_info
        fi
    fi
}
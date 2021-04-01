# GRAVITY SYNC BY VMSTAN #####################
# gs-hasing.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Validate Sync Required
function md5_compare {
    HASHMARK='0'
    
    MESSAGE="${UI_HASHING_HASHING} ${UI_GRAVITY_NAME}"
    echo_stat
    primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//')
    error_validate
    
    MESSAGE="${UI_HASHING_COMPARING} ${UI_GRAVITY_NAME}"
    echo_stat
    secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
    error_validate
    
    if [ "$primaryDBMD5" == "$last_primaryDBMD5" ] && [ "$secondDBMD5" == "$last_secondDBMD5" ]
    then
        HASHMARK=$((HASHMARK+0))
    else
        MESSAGE="${UI_HASHING_DIFFERNCE} ${UI_GRAVITY_NAME}"
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
                MESSAGE="${UI_HASHING_HASHING} ${UI_CUSTOM_NAME}"
                echo_stat
                
                primaryCLMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//'")
                error_validate
                
                MESSAGE="${UI_HASHING_COMPARING} ${UI_CUSTOM_NAME}"
                echo_stat
                secondCLMD5=$(md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//')
                error_validate
                
                if [ "$primaryCLMD5" == "$last_primaryCLMD5" ] && [ "$secondCLMD5" == "$last_secondCLMD5" ]
                then
                    HASHMARK=$((HASHMARK+0))
                else
                    MESSAGE="${UI_HASHING_DIFFERNCE} ${UI_CUSTOM_NAME}"
                    echo_warn
                    HASHMARK=$((HASHMARK+1))
                fi
            else
                MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_PRIMARY}"
                echo_info
            fi
        else
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_DETECTED} ${UI_HASHING_PRIMARY}"
                HASHMARK=$((HASHMARK+1))
                echo_info
            fi
            MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_SECONDARY}"
            echo_info
        fi
    fi
    
    if [ "${SKIP_CUSTOM}" != '1' ]
    then
        if [ "${INCLUDE_CNAME}" == "1" ]
        then
            if [ -f ${DNSMAQ_DIR}/${CNAME_CONF} ]
            then
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${CNAME_CONF}
                then
                    REMOTE_CNAME_DNS="1"
                    MESSAGE="${UI_HASHING_HASHING} ${UI_CNAME_NAME}"
                    echo_stat
                    
                    primaryCNMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RNSMAQ_DIR}/${CNAME_CONF} | sed 's/\s.*$//'")
                    error_validate
                    
                    MESSAGE="${UI_HASHING_COMPARING} ${UI_CNAME_NAME}"
                    echo_stat
                    secondCNMD5=$(md5sum ${DNSMAQ_DIR}/${CNAME_CONF} | sed 's/\s.*$//')
                    error_validate
                    
                    if [ "$primaryCNMD5" == "$last_primaryCNMD5" ] && [ "$secondCNMD5" == "$last_secondCNMD5" ]
                    then
                        HASHMARK=$((HASHMARK+0))
                    else
                        MESSAGE="${UI_HASHING_DIFFERNCE} ${UI_CNAME_NAME}"
                        echo_warn
                        HASHMARK=$((HASHMARK+1))
                    fi
                else
                    MESSAGE="${UI_CNAME_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_PRIMARY}"
                    echo_info
                fi
            else
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${CNAME_CONF}
                then
                    REMOTE_CNAME_DNS="1"
                    MESSAGE="${UI_CNAME_NAME} ${UI_HASHING_DETECTED} ${UI_HASHING_PRIMARY}"
                    HASHMARK=$((HASHMARK+1))
                    echo_info
                fi
                
                MESSAGE="${UI_CNAME_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_SECONDARY}"
                echo_info
            fi
        fi
    fi
    
    if [ "$HASHMARK" != "0" ]
    then
        MESSAGE="${UI_HASHING_REQUIRED}"
        echo_warn
        HASHMARK=$((HASHMARK+0))
    else
        MESSAGE="${UI_HASHING_NOREP}"
        echo_info
        backup_cleanup
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
        last_primaryCNMD5=$(sed "5q;d" ${LOG_PATH}/${HISTORY_MD5})
        last_secondCNMD5=$(sed "6q;d" ${LOG_PATH}/${HISTORY_MD5})
    else
        last_primaryDBMD5="0"
        last_secondDBMD5="0"
        last_primaryCLMD5="0"
        last_secondCLMD5="0"
        last_primaryCNMD5="0"
        last_secondCNMD5="0"
    fi
}

function md5_recheck {
    MESSAGE="${UI_HASHING_DIAGNOSTICS}"
    echo_info
    
    HASHMARK='0'
    
    MESSAGE="${UI_HASHING_REHASHING} ${UI_GRAVITY_NAME}"
    echo_stat
    primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//')
    silent_error_validate
    
    MESSAGE="${UI_HASHING_RECOMPARING} ${UI_GRAVITY_NAME}"
    echo_stat
    secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
    silent_error_validate
    
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
        then
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${UI_HASHING_REHASHING} ${UI_CUSTOM_NAME}"
                echo_stat
                
                primaryCLMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//'")
                silent_error_validate
                
                MESSAGE="${UI_HASHING_RECOMPARING} ${UI_CUSTOM_NAME}"
                echo_stat
                secondCLMD5=$(md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//')
                silent_error_validate
            else
                MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_PRIMARY}"
                echo_info
            fi
        else
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_DETECTED} ${UI_HASHING_PRIMARY}"
                echo_info
            fi
            MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_SECONDARY}"
            echo_info
        fi
    fi
    
    if [ "${SKIP_CUSTOM}" != '1' ]
    then
        if [ "${INCLUDE_CNAME}" == "1" ]
        then
            if [ -f ${DNSMAQ_DIR}/${CNAME_CONF} ]
            then
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${CNAME_CONF}
                then
                    REMOTE_CNAME_DNS="1"
                    MESSAGE="${UI_HASHING_REHASHING} ${UI_CNAME_NAME}"
                    echo_stat
                    
                    primaryCNMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RNSMAQ_DIR}/${CNAME_CONF} | sed 's/\s.*$//'")
                    silent_error_validate
                    
                    MESSAGE="${UI_HASHING_RECOMPARING} ${UI_CNAME_NAME}"
                    echo_stat
                    secondCNMD5=$(md5sum ${DNSMAQ_DIR}/${CNAME_CONF} | sed 's/\s.*$//')
                    silent_error_validate
                else
                    MESSAGE="${UI_CNAME_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_PRIMARY}"
                    echo_info
                fi
            else
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${CNAME_CONF}
                then
                    REMOTE_CNAME_DNS="1"
                    MESSAGE="${UI_CNAME_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_PRIMARY}"
                    echo_info
                fi
                
                MESSAGE="${UI_CNAME_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_SECONDARY}"
                echo_info
            fi
        fi
    fi
}
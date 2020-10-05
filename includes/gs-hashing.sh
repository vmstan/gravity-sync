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
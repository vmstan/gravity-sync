# GRAVITY SYNC BY VMSTAN #####################
# gs-ui.sh ###################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

# Interface Settings
UI_GRAVITY_NAME='Domain Database'
UI_CUSTOM_NAME='Local DNS Records'
UI_CNAME_NAME='Local DNS CNAMEs'

# File Validation
UI_COMPENSATE='Attempting to compensate'
UI_SET_FILE_OWNERSHIP='Setting file ownership on'
UI_SET_FILE_PERMISSION='Setting file permissions on'
UI_VAL_FILE_OWNERSHIP='Validating file ownership on'
UI_VAL_FILE_PERMISSION='Validating file permissions on'

# Configuration
UI_DROPBEAR_DEP='Dropbear support has been deprecated'

# Pull
UI_PULL_PRIMARY='Pulling the primary'
UI_REPLACE_SECONDARY='Replacing the secondary'
UI_PULL_RELOAD_WAIT='Isolating regeneration pathways'
UI_FTLDNS_CONFIG_UPDATE='Updating FTLDNS configuration'
UI_FTLDNS_CONFIG_RELOAD='Reloading FTLDNS services'

# Logging
UI_LOGGING_SUCCESS='Logging successful'
UI_LOGGING_HASHES='Saving the updated hashes from this replication'
UI_LOGGING_DISPLAY='Displaying output of previous jobs'
UI_LOGGING_EMPTY='is empty'
UI_LOGGING_MISSING='is missing'
UI_LOGGING_RECENT_COMPLETE='Recent complete executions of'

# Backup
UI_BACKUP_PRIMARY='Performing backup of primary'
UI_BACKUP_SECONDARY='Performing backup of secondary'
UI_BACKUP_PURGE='Purging redundant backups on secondary Pi-hole instance'
UI_BACKUP_REMAIN='days of backups remain'
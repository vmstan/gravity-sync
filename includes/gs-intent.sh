# GRAVITY SYNC BY VMSTAN #####################
# gs-intent.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Validate Intent
function intent_validate {
    if [ "$VERIFY_PASS" == "0" ]
    then
        PHASER=$((( RANDOM % 4 ) + 1 ))
        if [ "$PHASER" = "1" ]
        then
            INTENT="FIRE PHOTON TORPEDOS"
        elif [ "$PHASER" = "2" ]
        then
            INTENT="FIRE ALL PHASERS"
        elif [ "$PHASER" = "3" ]
        then
            INTENT="EJECT THE WARPCORE"
        elif [ "$PHASER" = "4" ]
        then
            INTENT="ENGAGE TRACTOR BEAM"
        fi
        
        MESSAGE="Type ${INTENT} to confirm"
        echo_need
        
        read INPUT_INTENT
        
        if [ "${INPUT_INTENT}" != "${INTENT}" ]
        then
            MESSAGE="${TASKTYPE} aborted"
            echo_info
            exit_nochange
        fi
    else
        MESSAGE="Verification bypassed"
        echo_warn
    fi
}
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
		
		MESSAGE="Type ${INTENT} to Confirm"
		echo_need

		read INPUT_INTENT

		if [ "${INPUT_INTENT}" != "${INTENT}" ]
		then
			MESSAGE="${TASKTYPE} Aborted"
			echo_info
			exit_nochange
		fi
	else
		MESSAGE="Verification Bypassed"
		echo_warn
	fi
}
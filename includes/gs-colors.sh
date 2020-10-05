# Script Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
BOLD='\033[1m'
NC='\033[0m'

# Message Codes
FAIL="[ ${RED}FAIL${NC} ]"
WARN="[ ${PURPLE}WARN${NC} ]"
GOOD="[ ${GREEN} OK ${NC} ]"
STAT="[ ${CYAN}EXEC${NC} ]"
INFO="[ ${YELLOW}INFO${NC} ]"
NEED="[ ${BLUE}NEED${NC} ]"

# Echo Stack
## Informative
function echo_info {
	echo -e "${INFO} ${YELLOW}${MESSAGE}${NC}"
}

## Warning
function echo_warn {
	echo -e "${WARN} ${PURPLE}${MESSAGE}${NC}"
}

## Executing
function echo_stat {
	echo -en "${STAT} ${MESSAGE}"
} 

## Success
function echo_good {
	echo -e "\r${GOOD} ${MESSAGE}"
}

## Failure
function echo_fail {
	echo -e "\r${FAIL} ${MESSAGE}"
}

## Request
function echo_need {
	echo -en "${NEED} ${MESSAGE}: "
}
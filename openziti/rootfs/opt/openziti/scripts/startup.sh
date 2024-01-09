#!/usr/bin/with-contenv bashio
####################################################################################################
# 20230119 - Written by Nic Fragale @ NetFoundry.
MyName="startup.sh"
MyPurpose="Ziti-Edge-Tunnel Startup Script for Home Assistant."
####################################################################################################
#set -e -u -o pipefail
[[ ${ZITI_ENV_LOG:-INFO} == "DEBUG" ]] &&
    bashio::log.info "MyName: ${MyName}" &&
    bashio::log.info "MyPurpose: ${MyPurpose}"

####################################################################################################
# Functions
####################################################################################################
function CheckWait() {
    # 1/TARGETNAME, 2/TARGETPID
    local TARGETNAME="${1}"
    local TARGETPID="${2}"
    local ITR=0
    while true; do
        if [[ -d /proc/${TARGETPID} ]]; then
            # Trigger a log entry only every 5m.
            [[ $((++ITR % 60)) -eq 0 ]] &&
                bashio::log.info "ZITI-EDGE-TUNNEL: [$((ITR / 60))/$(date)] [PID:${TARGETPID}] [WAIT:${TARGETNAME}]"
            sleep 5
        else
            bashio::log.notice "ZITI-EDGE-TUNNEL: [$((++ITR / 60))/$(date)] [PID:${TARGETPID}] [END:${TARGETNAME}]"
            break
        fi
    done
}

function SetSystemResolver() {
    # 1/SETTOIP
    local SETTOIP="${1}"
    if [[ -n "${SETTOIP}" ]]; then
        if /usr/bin/ha dns options --servers dns://"${SETTOIP}" &>/dev/null; then
            bashio::log.info "Setup of system resolver via REST to [${SETTOIP}] succeeded."
        else
            bashio::log.warning "Setup of system resolver via REST to [${SETTOIP}] failed."
        fi
    else
        bashio::log.error "Setup of system resolver via REST failed because pass-in was empty."
    fi
}

function ObtainIPInfo() {
    # 1/IP_CIDR, 2/TYPE
    local INPUTADDRESS="${1}"
    local OUTPUTTYPE="${2}"
    local RAWADDRESS IP1 IP2 IP3 IP4 MASK1 MASK2 MASK3 MASK4

    # Check for proper input.
    [[ "${INPUTADDRESS%/*}" == "${INPUTADDRESS#*/}" ]] &&
        return 1

    INPUTADDRESS=("${INPUTADDRESS%/*}" "${INPUTADDRESS#*/}")
    RAWADDRESS=$((0xffffffff ^ ((1 << (32 - INPUTADDRESS[1])) - 1)))
    IFS=. read -r IP1 IP2 IP3 IP4 <<<"${INPUTADDRESS[0]}"
    IFS=. read -r MASK1 MASK2 MASK3 MASK4 <<<"$(((RAWADDRESS >> 24) & 0xff)).$(((RAWADDRESS >> 16) & 0xff)).$(((RAWADDRESS >> 8) & 0xff)).$((RAWADDRESS & 0xff))"

    case ${OUTPUTTYPE} in
        "NETWORK") echo "$((IP1 & MASK1)).$((IP2 & MASK2)).$((IP3 & MASK3)).$((IP4 & MASK4))" ;;
        "BROADCAST") echo "$((IP1 & MASK1 | 255 - MASK1)).$((IP2 & MASK2 | 255 - MASK2)).$((IP3 & MASK3 | 255 - MASK3)).$((IP4 & MASK4 | 255 - MASK4))" ;;
        "FIRSTIP") echo "$((IP1 & MASK1)).$((IP2 & MASK2)).$((IP3 & MASK3)).$(((IP4 & MASK4) + 1))" ;;
        "LASTIP") echo "$((IP1 & MASK1 | 255 - MASK1)).$((IP2 & MASK2 | 255 - MASK2)).$((IP & MASK3 | 255 - MASK3)).$(((IP4 & MASK4 | 255 - MASK4) - 1))" ;;
    esac
}

function StartAssistBinaries() {
    # 1/RUNBINARY, 2/RUNOPTS
    local RUNBINARY="${1}"
    local RUNOPTS="${2}"
    if ! pidof "${RUNBINARY}"; then
        ${RUNBINARY} ${RUNOPTS}
        bashio::log.info "Assisting application \"${RUNBINARY}\" has been started with syntax options \"${RUNOPTS:-NONE}\"."
    else
        bashio::log.warning "Assisting application \"${RUNBINARY}\" is already running."
    fi
}

function PreCheck() {
    # Set permissions as required for normal operations.
    chmod 700 -R "${SCRIPTDIRECTORY}"

    # Check identities folder for validity and list available identities.
    if [[ -d "/share/NetFoundry" ]]; then
        bashio::log.warning "Found old directory structure.  Renaming..."
        mv -vf "/share/NetFoundry" "/share/openziti"
    fi
    if [[ ! -d ${IDENTITYDIRECTORY} ]] && ! mkdir -vp "${IDENTITYDIRECTORY}"; then
        bashio::log.error "IDENTITY LISTING ERROR"
        bashio::exit.nok "ZITI-EDGE-TUNNEL: PROGRAM END"
    fi
}

function RunEnrollment() {
    # 1/RUNTIME, 2/ENROLLSTRING, 3/ENROLLJWT
    local RUNTIME="${1}"
    local ENROLLJWT="${2}"
    local ENROLLSTRING
    bashio::log.notice "ZITI-EDGE-TUNNEL: ENROLL BEGIN"
    ENROLLSTRING="enroll -j \"-\" -i \"${IDENTITYDIRECTORY}/ZTID-$(date +"%Y%m%d_%H%M%S").json\""
    /bin/bash -c "${RUNTIME} ${ENROLLSTRING} <<< ${ENROLLJWT}" &
    ENROLLPID=$!
    CheckWait "ENROLL" "${ENROLLPID}" &
    wait $!
    find "${IDENTITYDIRECTORY}" -maxdepth 1 -type f -empty -delete
    bashio::log.notice "ZITI-EDGE-TUNNEL: ENROLL END"
}

function IdentityCheck() {
    # 1/IDENTITYDIRECTORY
    local IDENTITYDIRECTORY="${1}"
    local FOUNDIDENTITIES
    FOUNDIDENTITIES="$(find "${IDENTITYDIRECTORY}" -type f -name "*.json")"
    if [[ $(grep -c . <<< "${FOUNDIDENTITIES}") -gt 0 ]]; then
        # NEEDS IMPROVEMENT.
        for EACHID in ${FOUNDIDENTITIES}; do
            bashio::log.info "IDENTITY: [${EACHID}]"
        done
    else
        bashio::log.error "NO VALID IDENTITIES AVAILABLE - ENROLL ONE FIRST (SLEEPING 60s)"
        sleep 60
        bashio::exit.nok "ZITI-EDGE-TUNNEL: PROGRAM END"
    fi
}

####################################################################################################
# MAIN
####################################################################################################
############################
# Variables Declaration
############################
# 1/IDENTITYDIRECTORY, 2/RESOLUTIONRANGE, 3/UPSTREAMRESOLVER, 4/LOGLEVEL, 5/ENROLLJWT
IDENTITYDIRECTORY="${1:-/share/openziti/identities}"
RESOLUTIONRANGE="${2:-100.64.64.0/18}"
ZITI_DNS_IP="$(ObtainIPInfo "${RESOLUTIONRANGE}" "FIRSTIP")"
UPSTREAMRESOLVER="${3:-1.1.1.1}"
LOGLEVEL="${4:-3}"
ENROLLJWT="${5:-UNSET}"
RUNTIME="/opt/openziti/ziti-edge-tunnel"
SCRIPTDIRECTORY="/opt/openziti/scripts"
ASSISTAPPBINARIES=("nginx" "php-fpm82")
ASSISTAPPOPTS=("" "")

############################
# PreInit
############################
bashio::log.notice "ZITI-EDGE-TUNNEL: PREINIT BEGIN"

# Run prechecking.
PreCheck

# Perform enrollment should a JWT be available.
if [[ ${ENROLLJWT} != "UNSET" ]]; then
    bashio::log.info "ZITI-EDGE-TUNNEL: ENROLLMENT REQUESTED"
    RunEnrollment "${RUNTIME}" "${ENROLLJWT}"
else
    bashio::log.info "ZITI-EDGE-TUNNEL: ENROLLMENT NOT REQUESTED"
fi

# Check for available identities.
IdentityCheck "${IDENTITYDIRECTORY}"

# Ensure existing configuration is saved for reinstallation later.
bashio::log.info "ZITI_DNS_IP: ${ZITI_DNS_IP:-ERROR}"

# Set the system first resolver to ZITI.
SetSystemResolver "${ZITI_DNS_IP}"

# Startup of assisting binaries.
for ((i = 0; i < ${#ASSISTAPPBINARIES[*]}; i++)); do
    StartAssistBinaries "${ASSISTAPPBINARIES[${i}]}" "${ASSISTAPPOPTS[${i}]}"
done

# Set the syntax string for startup.
RUNTIMEOPTS="run -I ${IDENTITYDIRECTORY} -d ${RESOLUTIONRANGE} -u ${UPSTREAMRESOLVER} -v ${LOGLEVEL}"
bashio::log.info "INIT STRING: [${RUNTIME} ${RUNTIMEOPTS}]"

bashio::log.notice "ZITI-EDGE-TUNNEL: PREINIT END"

############################
# Program Runtime
############################
bashio::log.notice "ZITI-EDGE-TUNNEL: PROGRAM BEGIN"
# Runtime is sent to the background for monitoring.
/bin/bash -c "${RUNTIME} ${RUNTIMEOPTS}" &
ZETPID=$!
CheckWait "MAIN LOOP" "${ZETPID}" &
wait $!

# Set the system resolver back to initial state.
SetSystemResolver "${UPSTREAMRESOLVER}"

bashio::log.notice "ZITI-EDGE-TUNNEL: PROGRAM END"
#!/usr/bin/with-contenv bashio
####################################################################################################
# 20230119 - Written by Nic Fragale @ NetFoundry.
MyName="startup.sh"
MyPurpose="NetFoundry ZITI Edge Tunnel Startup Script for Home Assistant."
####################################################################################################
set -e -u -o pipefail

####################################################################################################
# Functions
####################################################################################################
function CheckWait() {
	local TARGETNAME="${1}"
	local TARGETPID="${2}"
	local ITR=0
	while true; do
		if [[ -d /proc/${TARGETPID} ]]; then
			bashio::log.info "ZITI EDGE TUNNEL - [$((++ITR))/$(date)] [PID:${TARGETPID}] [WAIT:${TARGETNAME}]"
			sleep 300
		else
			bashio::log.notice "ZITI EDGE TUNNEL - [$((++ITR))/$(date)] [PID:${TARGETPID}] [END:${TARGETNAME}]"
			break
		fi
	done
}

function ObtainIPInfo() {
	# Expect Input [0=IP/CIDR, 1=TYPE]i.
	local INPUTADDRESS="${1}"
	local OUTPUTTYPE="${2}"
	local RAWADDRESS IP1 IP2 IP3 IP4 MASK1 MASK2 MASK3 MASK4

	# Check for proper input.
	[[ "${INPUTADDRESS%/*}" == "${INPUTADDRESS#*/}" ]] \
		&& return 1

	INPUTADDRESS=( "${INPUTADDRESS%/*}" "${INPUTADDRESS#*/}" )
	RAWADDRESS=$(( 0xffffffff ^ ((1 << (32 - INPUTADDRESS[1])) - 1) ))
	IFS=. read -r IP1 IP2 IP3 IP4 <<< "${INPUTADDRESS[0]}"
	IFS=. read -r MASK1 MASK2 MASK3 MASK4 <<< "$(( (RAWADDRESS >> 24) & 0xff )).$(( (RAWADDRESS >> 16) & 0xff )).$(( (RAWADDRESS >> 8) & 0xff )).$(( RAWADDRESS & 0xff ))"

	case ${OUTPUTTYPE} in
		"NETWORK") echo "$((IP1 & MASK1)).$((IP2 & MASK2)).$((IP3 & MASK3)).$((IP4 & MASK4))";;
		"BROADCAST") echo "$((IP1 & MASK1 | 255-MASK1)).$((IP2 & MASK2 | 255-MASK2)).$((IP3 & MASK3 | 255-MASK3)).$((IP4 & MASK4 | 255-MASK4))";;
		"FIRSTIP") echo "$((IP1 & MASK1)).$((IP2 & MASK2)).$((IP3 & MASK3)).$(((IP4 & MASK4)+1))";;
		"LASTIP") echo "$((IP1 & MASK1 | 255-MASK1)).$((IP2 & MASK2 | 255-MASK2)).$((IP & MASK3 | 255-MASK3)).$(((IP4 & MASK4 | 255-MASK4)-1))";;
	esac
}

####################################################################################################
# MAIN
####################################################################################################
# 1/IDENTITYDIRECTORY, 2/RESOLUTIONRANGE, 3/UPSTREAMRESOLVER, 4/LOGLEVEL, 5/JWTSTRING, 6/IDENTITYOUT
IDENTITYDIRECTORY="${1:-/share/NetFoundry/identities}"
RESOLUTIONRANGE="${2}"
UPSTREAMRESOLVER="${3}"
LOGLEVEL="${4}"
ENROLLMENTJWT="${5}"
ENROLLSTRING="enroll -j <(echo \"${5}\") -i \"${1}/${6}\""
RUNTIME="/opt/NetFoundry/ziti-edge-tunnel"

bashio::log.notice "ZITI EDGE TUNNEL - PREINIT BEGIN"
# Check identities folder for validity and list available identities.
if [[ ! -d ${IDENTITYDIRECTORY} ]] && ! mkdir -vp "${IDENTITYDIRECTORY}"; then
	bashio::log.error "ID LISTING ERROR"
	bashio::exit.nok "ZITI EDGE TUNNEL - PROGRAM END"
fi
# Perform enrollment should a JWT be available.
if [[ ${ENROLLMENTJWT} != "UNSET" ]]; then
	bashio::log.notice "ZITI EDGE TUNNEL - ENROLL BEGIN"
	/bin/bash -c "${RUNTIME} ${ENROLLSTRING}" &
	ENROLLPID=$!
	CheckWait "ENROLL" "${ENROLLPID}" &
	wait $!
	find "${IDENTITYDIRECTORY}" -maxdepth 1 -type f -empty -delete
	sleep 5
	bashio::log.notice "ZITI EDGE TUNNEL - ENROLL END"
fi
bashio::log.info "IDENTITIES: [$(ls -1 "${IDENTITYDIRECTORY}")]"

# DNS upstream assignment.
UPSTREAMRESOLVER="${3}"

# Ensure existing configuration is saved for reinstallation later.
bashio::log.info "ZITI_DNS_IP=[${ZITIDNSIP:=$(ObtainIPInfo "${RESOLUTIONRANGE}" "FIRSTIP")}]"
cat /etc/resolv.conf > /etc/resolv.conf.system
echo > /etc/resolv.conf.ziti
NSSEMA="FALSE"
NSERV="$(ObtainIPInfo "${RESOLUTIONRANGE}" "FIRSTIP")"
while IFS=$'\n' read -r EachLine; do
	if [[ ${NSSEMA} == "FALSE" ]] && [[ ${EachLine%% *} == "nameserver" ]]; then
		echo "nameserver ${NSERV}"
		NSSEMA="TRUE"
	else
		echo "${EachLine}"
	fi
done < /etc/resolv.conf >> /etc/resolv.conf.ziti
cat /etc/resolv.conf.ziti > /etc/resolv.conf

# Set the system first resolver to ZITI.
if ha dns options --servers dns://"${NSERV}" &>/dev/null; then
	bashio::log.info "Setup of system resolver via REST to [${NSERV}] succeeded."
else
	bashio::log.warning "Setup of system resolver via REST to [${NSERV}] failed."
fi

# Set the syntax string for startup.
RUNSTRING="run -I ${IDENTITYDIRECTORY} -d ${RESOLUTIONRANGE} -u ${UPSTREAMRESOLVER} -v ${LOGLEVEL}"
bashio::log.info "INIT STRING: [${RUNTIME} ${RUNSTRING}]"
bashio::log.notice "ZITI EDGE TUNNEL - PREINIT END"

bashio::log.notice "ZITI EDGE TUNNEL - PROGRAM BEGIN"
# Runtime is sent to the background for monitoring.
/bin/bash -c "${RUNTIME} ${RUNSTRING}" &
ZETPID=$!
CheckWait "MAIN LOOP" "${ZETPID}" &
wait $!
bashio::log.notice "ZITI EDGE TUNNEL - PROGRAM END"

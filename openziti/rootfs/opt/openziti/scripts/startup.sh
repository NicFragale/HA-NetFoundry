#!/usr/bin/with-contenv bashio
####################################################################################################
# 20260601 - Written by Nic Fragale @ NetFoundry.
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
    # 1/TARGETNAME, 2/TARGETPID, 3/CURRENTDNSRESOLVER
    local TARGETNAME="${1}"
    local TARGETPID="${2}"
    local CURRENTDNSRESOLVER="${3}"
    local ITR="0"
    local NEWRESOLV RESOLVBOOL

    while true; do
        # Prevent modification to resolvers.
        NEWRESOLV=""
        RESOLVBOOL="FALSE"
        while IFS=$'\n' read -r EachLine; do
            if [[ "${EachLine}" == "nameserver ${CURRENTDNSRESOLVER}" ]]; then
                NEWRESOLV="${NEWRESOLV}\n#${EachLine}"
                RESOLVBOOL="TRUE"
                # Set the system first resolver to ZITI.
                bashio::log.info "ZITI_DNS_IP: ${EachLine/nameserver /}"
                SetSystemResolver "${EachLine/nameserver /}"
            else
                NEWRESOLV="${NEWRESOLV}\n${EachLine}"
            fi
        done < /etc/resolv.conf
        [[ ${RESOLVBOOL} == "TRUE" ]] \
            && echo -e "${NEWRESOLV}" > /etc/resolv.conf \
            && bashio::log.info "UPDATED RESOLV CONFIGURATION"

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
    # Assess the runtime and environment.
    local RuntimeVersion SystemArch
    RuntimeVersion="$(/bin/bash -c "/opt/openziti/ziti-edge-tunnel version 2>/dev/null || echo ERROR")"
    SystemArch="$(/bin/bash -c "arch")"
    bashio::log.info "Runtime version is \"${RuntimeVersion}\"."
    bashio::log.info "Architecture is \"${SystemArch}\"."

    # Set permissions as required for normal operations.
    chmod -R 700 "${SCRIPTDIRECTORY}"

    # Check identities folder for validity and list available identities.
    if [[ -d "/share/NetFoundry" ]]; then
        bashio::log.warning "Found old directory structure.  Renaming..."
        mv -vf "/share/NetFoundry" "/share/openziti"
    fi
    if [[ ! -d ${IDENTITYDIRECTORY} ]] && ! mkdir -vp "${IDENTITYDIRECTORY}"; then
        bashio::log.error "IDENTITY LISTING ERROR"
        bashio::exit.nok "ZITI-EDGE-TUNNEL: PROGRAM END"
        sleep 15
    fi
    if ! ValidateRange "${RESOLUTIONRANGE}"; then
        bashio::log.error "RESOLUTION RANGE ERROR"
        bashio::exit.nok "ZITI-EDGE-TUNNEL: PROGRAM END"
        sleep 15
    fi
}

function RunEnrollment() {
    # 1/RUNTIME, 2/ENROLLJWT, 3/CURRENTDNSRESOLVER
    local RUNTIME="${1}"
    local ENROLLJWT="${2}"
    local CURRENTDNSRESOLVER="${3}"
    local ENROLLSTRING
    bashio::log.notice "ZITI-EDGE-TUNNEL: ENROLL BEGIN"
    ENROLLSTRING="enroll -j \"-\" -i \"${IDENTITYDIRECTORY}/ZTID-$(date +"%Y%m%d_%H%M%S").json\""
    /bin/bash -c "${RUNTIME} ${ENROLLSTRING} <<< ${ENROLLJWT}" &
    ENROLLPID=$!
    CheckWait "ENROLL" "${ENROLLPID}" "${CURRENTDNSRESOLVER}" &
    wait $!
    find "${IDENTITYDIRECTORY}" -maxdepth 1 -type f -empty -delete
    bashio::log.notice "ZITI-EDGE-TUNNEL: ENROLL END"
}

function IdentityCheck() {
    # 1/IDENTITYDIRECTORY
    local IDENTITYDIRECTORY="${1}"
    local FOUNDIDENTITIES
    FOUNDIDENTITIES="$(find "${IDENTITYDIRECTORY}" -type f -name "*.json")"
    if [[ -n "${FOUNDIDENTITIES}" ]]; then
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

function ObtainIPInfo() {
    # 1/IP_CIDR, 2/TYPE
    local INPUTADDRESS="${1}"
    local OUTPUTTYPE="${2}"
    local RAWADDRESS IP1 IP2 IP3 IP4 MASK1 MASK2 MASK3 MASK4

    # Check for proper input.
    if [[ "${INPUTADDRESS%/*}" == "${INPUTADDRESS#*/}" ]]; then
        return 1
    fi

    # Split INPUTADDRESS into IP and CIDR mask
    IFS='/' read -r IP CIDR <<< "${INPUTADDRESS}"

    # Calculate the raw subnet mask from the CIDR
    RAWADDRESS=$((((0xffffffff ^ ((1 << (32 - CIDR)) - 1)))))

    # Split IP into octets
    IFS='.' read -r IP1 IP2 IP3 IP4 <<< "${IP}"

    # Calculate the subnet mask octets
    IFS='.' read -r MASK1 MASK2 MASK3 MASK4 <<< "$(((RAWADDRESS >> 24) & 0xff)).$(((RAWADDRESS >> 16) & 0xff)).$(((RAWADDRESS >> 8) & 0xff)).$((RAWADDRESS & 0xff))"

    # Determine the output based on OUTPUTTYPE
    case ${OUTPUTTYPE} in
        "NETWORK")
            echo "$((IP1 & MASK1)).$((IP2 & MASK2)).$((IP3 & MASK3)).$((IP4 & MASK4))"
            ;;
        "BROADCAST")
            echo "$((IP1 & MASK1 | 255 - MASK1)).$((IP2 & MASK2 | 255 - MASK2)).$((IP3 & MASK3 | 255 - MASK3)).$((IP4 & MASK4 | 255 - MASK4))"
            ;;
        "FIRSTIP")
            echo "$((IP1 & MASK1)).$((IP2 & MASK2)).$((IP3 & MASK3)).$(((IP4 & MASK4) + 1))"
            ;;
        "LASTIP")
            echo "$((IP1 & MASK1 | 255 - MASK1)).$((IP2 & MASK2 | 255 - MASK2)).$((IP3 & MASK3 | 255 - MASK3)).$(((IP4 & MASK4 | 255 - MASK4) - 1))"
            ;;
        *)
            echo "Invalid OUTPUTTYPE specified."
            return 1
            ;;
    esac
}

function ValidateRange() {
    local input="${1}"
    local ip cidr
    local ip_int mask_int network_int broadcast_int host_bits
    local o1 o2 o3 o4

    # ─── Parse CIDR notation ───────────────────────────────────────────────────
    if [[ "${input}" =~ ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/([0-9]{1,2})$ ]]; then
        ip="${BASH_REMATCH[1]}"
        cidr="${BASH_REMATCH[2]}"
    else
        bashio::log.error "ERROR: Input must be CIDR notation (e.g. 192.168.1.0/24)" >&2
        return 1
    fi

    # ─── Validate each octet ───────────────────────────────────────────────────
    IFS='.' read -r o1 o2 o3 o4 <<< "${ip}"
    for octet in "${o1}" "${o2}" "${o3}" "${o4}"; do
        if (( octet < 0 || octet > 255 )); then
            echo "ERROR: Invalid IP '${ip}' — octet '${octet}' out of range 0-255" >&2
            return 1
        fi
    done

    # ─── Validate prefix length ────────────────────────────────────────────────
    if (( cidr < 0 || cidr > 32 )); then
        bashio::log.error "ERROR: Invalid prefix length '${cidr}' — must be 0-32" >&2
        return 1
    fi

    if (( cidr >= 29 )); then
        local total_addrs=$(( 1 << (32 - cidr) ))
        local usable_addrs=$(( total_addrs - 2 ))
        bashio::log.error "ERROR: Prefix length '/${cidr}' is too small — must be /28 or larger (/${cidr} yields ${total_addrs} total addresses, ${usable_addrs} usable)" >&2
        return 1
    fi

    # ─── Convert IP to 32-bit integer ─────────────────────────────────────────
    ip_int=$(( (o1 << 24) | (o2 << 16) | (o3 << 8) | o4 ))

    # ─── Build subnet mask and derive network/broadcast ───────────────────────
    if (( cidr == 0 )); then
        mask_int=0
    else
        mask_int=$(( 0xFFFFFFFF << (32 - cidr) & 0xFFFFFFFF ))
    fi

    network_int=$(( ip_int & mask_int ))

    if (( cidr == 32 )); then
        broadcast_int=${network_int}
    else
        broadcast_int=$(( network_int | ( (1 << (32 - cidr)) - 1 ) ))
    fi

    # ─── Reject host bits set ─────────────────────────────────────────────────
    host_bits=$(( ip_int & ~mask_int & 0xFFFFFFFF ))
    if (( host_bits != 0 )); then
        local n1=$(( (network_int >> 24) & 0xFF ))
        local n2=$(( (network_int >> 16) & 0xFF ))
        local n3=$(( (network_int >>  8) & 0xFF ))
        local n4=$(( network_int         & 0xFF ))
        bashio::log.error "ERROR: '${ip}' has host bits set — did you mean ${n1}.${n2}.${n3}.${n4}/${cidr}?" >&2
        return 1
    fi

    # ─── RFC 1918 / RFC 6598 check ────────────────────────────────────────────
    # Block              Min int      Max int      Min prefix
    # 10.0.0.0/8         167772160    184549375    8
    # 100.64.0.0/10      1681915904   1686110207   10
    # 172.16.0.0/12      2886729728   2887778303   12
    # 192.168.0.0/16     3232235520   3232301055   16
    local in_private=0
    local -a private_blocks=(
        "167772160  184549375  8"
        "1681915904 1686110207 10"
        "2886729728 2887778303 12"
        "3232235520 3232301055 16"
    )

    local block_min block_max block_min_cidr
    for block in "${private_blocks[@]}"; do
        read -r block_min block_max block_min_cidr <<< "${block}"
        if (( network_int >= block_min && network_int <= block_max )); then
            if (( cidr >= block_min_cidr )); then
                in_private=1
            else
                bashio::log.error "ERROR: '${input}' prefix /${cidr} is broader than the private block boundary (/${block_min_cidr}) — subnet would span public IPs" >&2
                return 1
            fi
            break
        fi
    done

    if (( in_private == 0 )); then
        bashio::log.error "ERROR: '${input}' is not within private address space (RFC 1918: 10/8, 172.16/12, 192.168/16 — RFC 6598: 100.64/10)" >&2
        return 1
    fi

    # ─── Kernel route conflict check ──────────────────────────────────────────
    local -a route_conflicts=()
    local route_line r_ip r_cidr r1 r2 r3 r4
    local r_ip_int r_mask_int r_network_int r_broadcast_int

    while IFS= read -r route_line; do
        [[ "${route_line}" =~ ^default ]] && continue
        [[ "${route_line}" =~ dev[[:space:]]+ziti ]] && continue
        [[ "${route_line}" =~ ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/([0-9]{1,2}) ]] || continue

        r_ip="${BASH_REMATCH[1]}"
        r_cidr="${BASH_REMATCH[2]}"

        IFS='.' read -r r1 r2 r3 r4 <<< "${r_ip}"

        r_ip_int=$(( (r1 << 24) | (r2 << 16) | (r3 << 8) | r4 ))

        if (( r_cidr == 0 )); then
            r_mask_int=0
        else
            r_mask_int=$(( 0xFFFFFFFF << (32 - r_cidr) & 0xFFFFFFFF ))
        fi

        r_network_int=$(( r_ip_int & r_mask_int ))

        if (( r_cidr == 32 )); then
            r_broadcast_int=${r_network_int}
        else
            r_broadcast_int=$(( r_network_int | ( (1 << (32 - r_cidr)) - 1 ) ))
        fi

        if (( network_int <= r_broadcast_int && broadcast_int >= r_network_int )); then
            route_conflicts+=("${r_ip}/${r_cidr}")
        fi

    done < <(ip route show)

    if (( ${#route_conflicts[@]} > 0 )); then
        bashio::log.error "ERROR: '${input}' conflicts with existing kernel route(s): ${route_conflicts[*]}" >&2
        return 1
    fi

    # ─── All checks passed ─────────────────────────────────────────────────────
    return 0
}

####################################################################################################
# MAIN
####################################################################################################
############################
# Variables Declaration
############################
# 1/IDENTITYDIRECTORY, 2/RESOLUTIONRANGE, 3/UPSTREAMRESOLVER, 4/LOGLEVEL, 5/ENROLLJWT
IDENTITYDIRECTORY="${1:-/share/openziti/identities}"
RESOLUTIONRANGE="${2:-100.64.64.0/24}"
ZITI_DNS_IP="$(ObtainIPInfo "${RESOLUTIONRANGE}" "FIRSTIP")"
UPSTREAMRESOLVER="${3:-1.1.1.1}"
LOGLEVEL="${4:-2}"
ENROLLJWT="${5:-UNSET}"
RUNTIME="/opt/openziti/ziti-edge-tunnel"
SCRIPTDIRECTORY="/opt/openziti/scripts"
ASSISTAPPBINARIES=("nginx" "php")
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
    RunEnrollment "${RUNTIME}" "${ENROLLJWT}" "${ZITI_DNS_IP}"
else
    bashio::log.info "ZITI-EDGE-TUNNEL: ENROLLMENT NOT REQUESTED"
fi

# Check for available identities.
IdentityCheck "${IDENTITYDIRECTORY}"

# Startup of assisting binaries.
for ((i = 0; i < ${#ASSISTAPPBINARIES[*]}; i++)); do
    THISAPPBINARY="$(find /usr/sbin -name "${ASSISTAPPBINARIES[${i}]}*" | head -1)"
    StartAssistBinaries "${THISAPPBINARY##*\/}" "${ASSISTAPPOPTS[${i}]}"
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
CheckWait "MAIN LOOP" "${ZETPID}" "${ZITI_DNS_IP}" &
wait $!

# Set the system resolver back to initial state.
SetSystemResolver "${UPSTREAMRESOLVER}"

bashio::log.notice "ZITI-EDGE-TUNNEL: PROGRAM END"
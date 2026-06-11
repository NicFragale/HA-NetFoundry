#!/usr/bin/with-contenv bashio
####################################################################################################
# 20260601 - Written by Nic Fragale @ NetFoundry.
MyName="infodisplay.sh"
MyPurpose="Ziti-Edge-Tunnel Host Information Display."
####################################################################################################
#set -e -u -o pipefail
[[ ${ZITI_ENV_LOG:-INFO} == "DEBUG" ]] &&
    bashio::log.info "MyName: ${MyName}" &&
    bashio::log.info "MyPurpose: ${MyPurpose}"

ShowMode="${1:-DEFAULT}"
ZitiLogo=(
    '                                                                                       '
    '             ██████  ██████  ███████ ███    ██ ███████ ██ ████████ ██                  '
    '            ██    ██ ██   ██ ██      ████   ██    ███  ██    ██    ██                  '
    '            ██    ██ ██████  █████   ██ ██  ██   ███   ██    ██    ██                  '
    '            ██    ██ ██      ██      ██  ██ ██  ███    ██    ██    ██                  '
    '             ██████  ██      ███████ ██   ████ ███████ ██    ██    ██                  '
    '███    ██ ███████ ████████ ███████  ██████  ██    ██ ███    ██ ██████  ██████  ██    ██'
    '████   ██ ██         ██    ██      ██    ██ ██    ██ ████   ██ ██   ██ ██   ██  ██  ██ '
    '██ ██  ██ █████      ██    █████   ██    ██ ██    ██ ██ ██  ██ ██   ██ ██████    ████  '
    '██  ██ ██ ██         ██    ██      ██    ██ ██    ██ ██  ██ ██ ██   ██ ██   ██    ██   '
    '██   ████ ███████    ██    ██       ██████   ██████  ██   ████ ██████  ██   ██    ██   '
    '                       ZERO TRUST NETWORKING FOR HOME ASSISTANT                        ')
ZETVersion="$(/opt/openziti/ziti-edge-tunnel version 2>/dev/null || echo UNKNOWN)"
HACLIInfo="$(ha cli info 2>/dev/null | awk '/version:/{print $2}' || echo UNKNOWN)"

# Quick socket health check (non-blocking).
ZETSock="/tmp/.ziti/ziti-edge-tunnel.sock"
[[ -e "${ZETSock}" ]] || ZETSock="$(find /tmp -name ziti-edge-tunnel.sock 2>/dev/null | head -1)"
if [[ -e "${ZETSock}" ]]; then
    SOCKET_PILL="<span class=\"FG-GREEN\">&#x25CF;&nbsp;SOCKET&nbsp;READY</span>"
else
    SOCKET_PILL="<span class=\"FG-RED\">&#x2715;&nbsp;SOCKET&nbsp;OFFLINE</span>"
fi

if [[ ${ShowMode} == "FULLDETAIL" ]]; then
    for ((i=0; i<${#ZitiLogo[*]}; i++)); do
        printf "%s\n" "${ZitiLogo[${i}]}"
    done
    echo
    printf "\n%-30s: %s\n" "Ziti-Edge-Tunnel Version" "${ZETVersion}"
    echo
    printf "%-30s: %s\n" "Home Assistant CLI Version" "${HACLIInfo}"
    echo
else
    printf "<span id=\"OPENZITITEXT\">\n"
    for ((i = 0; i < ${#ZitiLogo[*]}; i++)); do
        printf "<span>%s</span><br>" "${ZitiLogo[${i}]// /\&nbsp}"
    done
    printf "</span>"
    printf "<span id=\"SYSTEMINFO\" class=\"FULLWIDTH FG-BOLD ANIMATED T500MS\"><hr>"
    printf "Ziti-Edge-Tunnel:&nbsp;%s&nbsp;|&nbsp;" "v${ZETVersion}"
    printf "HA&nbsp;CLI:&nbsp;%s&nbsp;|&nbsp;" "v${HACLIInfo}"
    printf "%s" "${SOCKET_PILL}"
    printf "</span>"
fi

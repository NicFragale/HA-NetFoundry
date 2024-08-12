#!/usr/bin/with-contenv bashio
####################################################################################################
# 20230428 - Written by Nic Fragale @ NetFoundry.
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
HACLIInfo="$(ha cli info | awk '/version:/{print $2}' || echo UNKNOWN)"
readarray -t HADNSInfo < <(/usr/bin/ha dns info 2>/dev/null || echo UNKNOWN)

if [[ ${ShowMode} == "FULLDETAIL" ]]; then
    for ((i=0; i<${#ZitiLogo[*]}; i++)); do
        printf "%s\n" "${ZitiLogo[${i}]}"
    done
    echo

    printf "\n%-30s: %s\n" "Ziti-Edge-Tunnel Version" "${ZETVersion}"
    echo

    printf "%-30s: %s\n" "Home Assistant CLI Version" "${HACLIInfo}"
    echo

    for ((i=0; i<${#HADNSInfo[*]}; i++)); do
        printf "%-30s: %s\n" "Home Assistant DNS Info [${i}]" "${HADNSInfo[${i}]}"
    done
    echo
else
    printf "<span id=\"OPENZITITEXT\">\n"
    for ((i = 0; i < ${#ZitiLogo[*]}; i++)); do
        printf "<span>%s</span><br>" "${ZitiLogo[${i}]// /\&nbsp}"
    done
    printf "</span><span id=\"SYSTEMINFO\" class=\"FULLWIDTH FG-BOLD ANIMATED T500MS\"><hr>"
    printf "Ziti-Edge-Tunnel: %s<br>" "v${ZETVersion}"
    printf "Home Assistant CLI: %s" "v${HACLIInfo}"
    printf "</span>"
fi
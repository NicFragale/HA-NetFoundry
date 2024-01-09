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
    '                       BETA: THIS IS A WORK IN PROGRESS                                ')
ZETVersion="$(/opt/openziti/ziti-edge-tunnel version 2>/dev/null || echo UNKNOWN)"

if [[ -n ${1} ]] && [[ ${1} == "FULLDETAIL" ]]; then
    for ((i = 0; i < ${#ZitiLogo[*]}; i++)); do
        printf "%s\n" "${ZitiLogo[${i}]}"
    done
    echo

    printf "\n%-30s: %s\n" "Ziti-Edge-Tunnel Version" "${ZETVersion}"
    echo

    HACLIInfo="$(ha cli info | awk '/version:/{print $2}' || echo UNKNOWN)"
    printf "%-30s: %s\n" "Home Assistant CLI Version" "${HACLIInfo}"
    echo

    readarray -t HADNSInfo < <(/usr/bin/ha dns info 2>/dev/null || echo UNKNOWN)
    for ((i = 0; i < ${#HADNSInfo[*]}; i++)); do
        printf "%-30s: %s\n" "Home Assistant DNS Info [${i}]" "${HADNSInfo[${i}]}"
    done
    echo
else
    printf "<span id=\"OPENZITITEXT\">\n"
    for ((i = 0; i < ${#ZitiLogo[*]}; i++)); do
        printf "<span>%s</span><br>" "${ZitiLogo[${i}]// /\&nbsp}"
    done
    printf "</span><hr>"
    printf "<span id=\"OPENZITIVERSION\" class=\"FULLWIDTH BG-LTGREY ANIMATED T500MS\">Ziti-Edge-Tunnel: %s</span>" "v${ZETVersion}"
fi

#!/usr/bin/with-contenv bashio
####################################################################################################
# 20230119 - Written by Nic Fragale @ NetFoundry.
MyName="openziti.profile"
MyPurpose="Ziti-Edge-Tunnel User Login Profile for Home Assistant."
####################################################################################################
#set -e -u -o pipefail
[[ ${ZITI_ENV_LOG:-INFO} == "DEBUG" ]] &&
    bashio::log.info "MyName: ${MyName}" &&
    bashio::log.info "MyPurpose: ${MyPurpose}"

export PS1='$(RC=$?; if [[ ${RC} == 0 ]]; then echo "\[\e[1;92;40m\]\u@\h \w>"; else echo "(${RC}) \[\e[1;91;40m\]\u@\h \w>"; fi)\[\e[0;0m\] '
export SUPERVISOR_TOKEN={{ .supervisor_token }}

/opt/openziti/scripts/infodisplay.sh "FULLDETAIL"

#!/usr/bin/with-contenv bashio
####################################################################################################
# 20230119 - Written by Nic Fragale @ NetFoundry.
MyName="netfoundry.profile"
MyPurpose="NetFoundry ZITI Edge Tunnel User Login Profile for Home Assistant."
####################################################################################################
export PS1='$(RC=$?; if [[ ${RC} == 0 ]]; then echo "\[\e[1;92;40m\]\u@\h \w>"; else echo "(${RC}) \[\e[1;91;40m\]\u@\h \w>"; fi)\[\e[0;0m\] '
export SUPERVISOR_TOKEN={{ .supervisor_token }}

[[ ${ZITI_ENV_LOG:-INFO} == "DEBUG" ]] \
    && bashio::log.info "MyName: ${MyName}" \
    && bashio::log.info "MyPurpose: ${MyPurpose}"

echo '
███    ██ ███████ ████████ ███████  ██████  ██    ██ ███    ██ ██████  ██████  ██    ██
████   ██ ██         ██    ██      ██    ██ ██    ██ ████   ██ ██   ██ ██   ██  ██  ██
██ ██  ██ █████      ██    █████   ██    ██ ██    ██ ██ ██  ██ ██   ██ ██████    ████
██  ██ ██ ██         ██    ██      ██    ██ ██    ██ ██  ██ ██ ██   ██ ██   ██    ██
██   ████ ███████    ██    ██       ██████   ██████  ██   ████ ██████  ██   ██    ██


             ██████  ██████  ███████ ███    ██ ███████ ██ ████████ ██
            ██    ██ ██   ██ ██      ████   ██    ███  ██    ██    ██
            ██    ██ ██████  █████   ██ ██  ██   ███   ██    ██    ██
            ██    ██ ██      ██      ██  ██ ██  ███    ██    ██    ██
             ██████  ██      ███████ ██   ████ ███████ ██    ██    ██
'
echo "NetFoundry ZITI Version: $(/opt/NetFoundry/ziti-edge-tunnel version || echo UNKNOWN)"
echo "Home Assistant DNS Info:"
ha &>/dev/null \
	&& ha dns info \
	|| echo "ERROR: Could not gather REST response."

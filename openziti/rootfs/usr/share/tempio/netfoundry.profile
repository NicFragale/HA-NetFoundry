#!/usr/bin/with-contenv bashio
####################################################################################################
# 20230119 - Written by Nic Fragale @ NetFoundry.
MyName="netfoundry.profile"
MyPurpose="NetFoundry ZITI Edge Tunnel User Login Profile for Home Assistant."
MyWarranty="This program comes without any warranty, implied or otherwise."
MyLicense="This program has no license."
MyVersion="1.0"
####################################################################################################
export PS1='$(RC=$?; if [[ ${RC} == 0 ]]; then echo "\[\e[1;92;40m\]\u@\h \w>"; else echo "(${RC}) \[\e[1;91;40m\]\u@\h \w>"; fi)\[\e[0;0m\] '
export SUPERVISOR_TOKEN={{ .supervisor_token }}

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

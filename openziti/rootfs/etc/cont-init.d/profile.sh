#!/usr/bin/with-contenv bashio
####################################################################################################
# 20230119 - Written by Nic Fragale @ NetFoundry.
MyName="profile.sh"
MyPurpose="Ziti-Edge-Tunnel Profile Loading Script for Home Assistant."
####################################################################################################
#set -e -u -o pipefail
[[ ${ZITI_ENV_LOG:-INFO} == "DEBUG" ]] &&
    bashio::log.info "MyName: ${MyName}" &&
    bashio::log.info "MyPurpose: ${MyPurpose}"

# Assess directories available.
readonly DIRECTORIES=(share)

# Make Home Assistant TOKEN available on the CLI.
mkdir -p /etc/profile.d
bashio::var.json \
    supervisor_token "${SUPERVISOR_TOKEN}" |
    tempio \
        -template /usr/share/tempio/openziti.profile \
        -out /etc/profile.d/openziti.sh

# Link common directories.
for dir in "${DIRECTORIES[@]}"; do
    ln -s "/${dir}" "${HOME}/${dir}" ||
        bashio::log.warning "Failed linking common directory: ${dir}"
done

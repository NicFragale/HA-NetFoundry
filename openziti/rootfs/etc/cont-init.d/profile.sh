#!/usr/bin/with-contenv bashio
####################################################################################################
# 20230119 - Written by Nic Fragale @ NetFoundry.
MyName="profile.sh"
MyPurpose="NetFoundry ZITI Edge Tunnel Profile Loading Script for Home Assistant."
####################################################################################################
readonly DIRECTORIES=(share)

[[ ${ZITI_ENV_LOG:-INFO} == "DEBUG" ]] \
    && bashio::log.info "MyName: ${MyName}" \
    && bashio::log.info "MyPurpose: ${MyPurpose}"

# Make Home Assistant TOKEN available on the CLI.
mkdir -p /etc/profile.d
bashio::var.json \
    supervisor_token "${SUPERVISOR_TOKEN}" \
    | tempio \
        -template /usr/share/tempio/netfoundry.profile \
        -out /etc/profile.d/netfoundry.sh

# Link common directories.
for dir in "${DIRECTORIES[@]}"; do
    ln -s "/${dir}" "${HOME}/${dir}" \
        || bashio::log.warning "Failed linking common directory: ${dir}"
done

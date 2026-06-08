####################################################################################################
# 20240701 - Written by Nic Fragale @ NetFoundry.
####################################################################################################
# Utilize the build image that is appropriate.
ARG BUILD_FROM="ghcr.io/hassio-addons/base:17.2.1"
FROM $BUILD_FROM

# Set the shell.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Initialize other variables.
ARG BUILD_ARCH BUILD_VERSION CLIVERSION ZTVERSION ZTBRANCHOVERRIDE

# Add labels to the image.
LABEL \
    io.hass.name="OpenZiti by NetFoundry" \
    io.hass.description="True zero trust networking." \
    io.hass.arch="armhf|armv7|aarch64|amd64|i386" \
    io.hass.type="addon" \
    io.hass.image.licenses="APACHE2.0" \
    io.hass.image.url="https://github.com/NicFragale/HA-NetFoundry" \
    io.hass.image.documentation="https://github.com/NicFragale/HA-NetFoundry/blob/07b636f23eca256c185f695794c52be1feb3d124/openziti/README.md" \
    maintainer="Nic Fragale <nic.fragale@netfoundry.io>"

# Overlay port for stc: adds -Dwerror=false to fix GCC 14 C11 strict errors on Alpine.
COPY stc-overlay /opt/stc-overlay

# 1. Update the system and download required software.
# 2. Setup NGINX.
# 3. Build and setup OpenZiti.
# 4. Add the Home Assistant CLI.
RUN \
    apk add --update --no-cache musl libcrypto3 libssl3 \
    && apk add --update --no-cache \
        sudo sed iproute2 cmake build-base linux-headers bind-tools automake libtool \
        gawk git jq socat nginx php84-fpm ninja zip unzip curl perl autoconf python3 \
        libuv-dev zlib-dev linux-headers libpcap-dev doxygen graphviz \
    && mkdir -vp '/var/run/nginx' '/var/run/php' '/var/www/html/images' \
    && sed -i \
        -e 's/^;listen =.*\|^listen =.*/listen = \/var\/run\/php\/php-fpm.sock/' \
        -e 's/^;listen.owner =.*\|^listen.owner =.*/listen.owner = nginx/' \
        -e 's/^;listen.group =.*\|^listen.group =.*/listen.group = nginx/' \
        -e 's/nobody/nginx/g' /etc/php*/php-fpm.d/www.conf \
    && echo -e "nginx ALL = (root) NOPASSWD: /opt/openziti/scripts/infodisplay.sh\nnginx ALL = (root) NOPASSWD: /opt/openziti/scripts/zetdisplay.sh\n" >> /etc/sudoers \
    && printf '#!/bin/sh\nF=""; T=""\nfor A in "$@"; do case "$A" in -*) F="$F $A";; *) T="$T $A";; esac; done\nexec /usr/bin/ninja $F $T\n' > /usr/local/bin/ninja \
    && chmod a+x /usr/local/bin/ninja \
    && export HOME="/root" \
    && export PATH="${PATH}:/usr/bin:/usr/share/" \
    && export VCPKG_FORCE_SYSTEM_BINARIES="1" \
    && export ZITI_ROOT="/opt/openziti" \
    && export ZITIBUILD_ROOT="${ZITI_ROOT}/build" \
    && export VCPKG_ROOT="${ZITI_ROOT}/vcpkg" \
    && mkdir -vp "${VCPKG_ROOT}" \
    && cd "${ZITI_ROOT}" \
    && git clone "https://github.com/microsoft/vcpkg.git" "${VCPKG_ROOT}" \
    && "${VCPKG_ROOT}/bootstrap-vcpkg.sh" -disableMetrics -musl \
    && cd "${ZITI_ROOT}" \
    && ZTVERSION="${ZTVERSION:-$(curl -Ls 'https://github.com/openziti/ziti-tunnel-sdk-c/tags' | awk '/tags/{if(match($0,/v[0-9].[0-9]+.[0-9]+/)){ALLVERSIONS[substr($0,RSTART,RLENGTH)]++}}END{for(EACHVERSION in ALLVERSIONS){gsub("v","",EACHVERSION);print EACHVERSION}}' | sort -rnt '.' -k1,1 -k2,2 -k3,3 | head -n1)}" \
    && curl -Lso "v${ZTVERSION}.zip" "${ZTBRANCHOVERRIDE:-https://github.com/openziti/ziti-tunnel-sdk-c/archive/refs/tags/v${ZTVERSION}.zip}" \
    && unzip "v${ZTVERSION}.zip" \
    && export CMAKE_PRESET="$(\
        [[ -z "${CMAKE_PRESET}" ]] \
            && [[ "${BUILD_ARCH}" == "aarch64" ]] \
            && echo "ci-linux-arm64" \
            && sed -i 's/x64/aarch64/' "${VCPKG_ROOT}/triplets/x64-linux.cmake" \
            && sed -i 's/aarch64-linux-gnu/aarch64-alpine-linux-musl/' "${ZITI_ROOT}/ziti-tunnel-sdk-c-${ZTVERSION}/toolchains/Linux-arm64.cmake" \
            || echo "${CMAKE_PRESET}" \
        )" \
    && export CMAKE_PRESET="$(\
        [[ -z "${CMAKE_PRESET}" ]] \
            && [[ "${BUILD_ARCH}" == "armv7" ]] \
            && echo "ci-linux-arm" \
            || echo "${CMAKE_PRESET}" \
        )" \
    && export CMAKE_PRESET="$(\
        [[ -z "${CMAKE_PRESET}" ]] \
            && [[ "${BUILD_ARCH}" == "amd64" ]] \
            && echo "ci-linux-x64" \
            || echo "${CMAKE_PRESET}" \
        )" \
    && sed -i '/attempting copy/d; /copy successful/d' "${ZITI_ROOT}/ziti-tunnel-sdk-c-${ZTVERSION}/programs/ziti-edge-tunnel/netif_driver/linux/resolvers.c" \
    && mkdir -p "${ZITI_ROOT}/custom-triplets" \
    && printf 'set(VCPKG_TARGET_ARCHITECTURE arm64)\nset(VCPKG_CRT_LINKAGE dynamic)\nset(VCPKG_LIBRARY_LINKAGE static)\nset(VCPKG_CMAKE_SYSTEM_NAME Linux)\nset(VCPKG_BUILD_TYPE release)\n' > "${ZITI_ROOT}/custom-triplets/arm64-linux.cmake" \
    && printf 'set(VCPKG_TARGET_ARCHITECTURE x64)\nset(VCPKG_CRT_LINKAGE dynamic)\nset(VCPKG_LIBRARY_LINKAGE dynamic)\nset(VCPKG_CMAKE_SYSTEM_NAME Linux)\nset(VCPKG_BUILD_TYPE release)\n' > "${ZITI_ROOT}/custom-triplets/x64-linux.cmake" \
    && printf 'set(VCPKG_TARGET_ARCHITECTURE arm)\nset(VCPKG_CRT_LINKAGE dynamic)\nset(VCPKG_LIBRARY_LINKAGE static)\nset(VCPKG_CMAKE_SYSTEM_NAME Linux)\nset(VCPKG_BUILD_TYPE release)\n' > "${ZITI_ROOT}/custom-triplets/arm-linux.cmake" \
    && cmake \
        --preset "${CMAKE_PRESET:-ci-linux-x64}" \
        -DGIT_VERSION="${ZTVERSION}-0-0" \
        -DDISABLE_LIBSYSTEMD_FEATURE="ON" \
        -DCMAKE_BUILD_TYPE="release" \
        -DVCPKG_BUILD_TYPE="release" \
        -DBUILD_DIST_PACKAGES="OFF" \
        -DCMAKE_CONFIGURATION_TYPES="Release" \
        -DVCPKG_MANIFEST_FEATURES="" \
        -DVCPKG_OVERLAY_TRIPLETS="${ZITI_ROOT}/custom-triplets" \
        "-DVCPKG_OVERLAY_PORTS=/opt/stc-overlay;${ZITI_ROOT}/ziti-tunnel-sdk-c-${ZTVERSION}/vcpkg-overlays/json-c-disable-duplocale" \
        -S "${ZITI_ROOT}/ziti-tunnel-sdk-c-${ZTVERSION}" \
        -B "${ZITIBUILD_ROOT}" \
    && sed -i '/Ziti C SDK version/i ZITI_LOG(INFO, "Welcome to Ziti - Home Assistant Edition [v'"${BUILD_VERSION}"']");' "${ZITIBUILD_ROOT}/_deps/ziti-sdk-c-src/library/utils.c" \
    && sed -i '/#include <sys\/time.h>/d ; /#define ZITI_SDK_MODEL_SUPPORT_H/a #include <sys\/time.h>' "${ZITIBUILD_ROOT}/_deps/ziti-sdk-c-src/includes/ziti/model_support.h" \
    && cmake \
        --build "${ZITIBUILD_ROOT}" \
        --config "Release" \
        --target "ziti-edge-tunnel" \
    && find "${ZITIBUILD_ROOT}/" -name ziti-edge-tunnel -type f -exec mv -vf {} "${ZITI_ROOT}" \; \
    && find "${ZITIBUILD_ROOT}/vcpkg_installed" -maxdepth 4 -name "*.so*" -not -type d \
        -exec cp -Pf {} /usr/lib/ \; 2>/dev/null; true \
    && rm -rf "v${ZTVERSION}.zip" "ziti-tunnel-sdk-c-${ZTVERSION}" "${ZITIBUILD_ROOT}" "${VCPKG_ROOT}" \
    && echo 'ziti:x:99:' >> "/etc/group" \
    && { CLIVERSION="${CLIVERSION:-$(curl -LsH 'Accept: application/vnd.github.v3+json' 'https://api.github.com/repos/home-assistant/cli/releases/latest' 2>/dev/null | jq -r '.tag_name' 2>/dev/null; true)}" \
         && [[ -n "${CLIVERSION}" && "${CLIVERSION}" != "null" ]] \
         && curl -Lso "/usr/bin/ha" "https://github.com/home-assistant/cli/releases/download/${CLIVERSION}/ha_${BUILD_ARCH}" \
         && chmod a+x "/usr/bin/ha" \
         || true; }

# Copy files into the image.
COPY rootfs /
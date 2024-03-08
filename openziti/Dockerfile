####################################################################################################
# 20231101 - Written by Nic Fragale @ NetFoundry.
####################################################################################################
# Utilize the build image that is appropriate.
ARG BUILD_FROM
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

# 1. Update the system and download required software.
# 2. Setup NGINX.
# 3. Build and setup OpenZiti.
# 4. Add the Home Assistant CLI.
RUN \
    apk add --no-cache \
        sudo sed iproute2 cmake build-base linux-headers \
        gawk git jq socat nginx php-fpm ninja zip unzip curl perl \
        libuv-dev zlib-dev linux-headers openssl-dev doxygen graphviz \
    && mkdir -vp '/var/run/nginx' '/var/run/php' '/var/www/html/images' \
    && sed -i \
        -e 's/^;listen =.*\|^listen =.*/listen = \/var\/run\/php\/php-fpm.sock/' \
        -e 's/^;listen.owner =.*\|^listen.owner =.*/listen.owner = nginx/' \
        -e 's/^;listen.group =.*\|^listen.group =.*/listen.group = nginx/' \
        -e 's/nobody/nginx/g' /etc/php*/php-fpm.d/www.conf \
    && echo -e "nginx ALL = (root) NOPASSWD: /opt/openziti/scripts/infodisplay.sh\nnginx ALL = (root) NOPASSWD: /opt/openziti/scripts/zetdisplay.sh\n" >> /etc/sudoers \
    && export HOME="/root" \
    && export PATH="${PATH}:/usr/bin" \
    && export CMAKE_PRESET="$([[ -z "${CMAKE_PRESET}" ]] && [[ "${BUILD_ARCH}" == "aarch64" ]] && echo "ci-linux-arm64")" \
    && export CMAKE_PRESET="$([[ -z "${CMAKE_PRESET}" ]] && [[ "${BUILD_ARCH}" == "armv7" ]] && echo "ci-linux-arm")" \
    && export CMAKE_PRESET="$([[ -z "${CMAKE_PRESET}" ]] && [[ "${BUILD_ARCH}" == "amd64" ]] && echo "ci-linux-x64")" \
    && export VCPKG_FORCE_SYSTEM_BINARIES="1" \
    && export ZITI_ROOT="/opt/openziti" \
    && export ZITIBUILD_ROOT="${ZITI_ROOT}/build" \
    && export VCPKG_ROOT="${ZITI_ROOT}/vcpkg" \
    && mkdir -vp "${VCPKG_ROOT}" \
    && cd "${ZITI_ROOT}" \
    && git clone "https://github.com/microsoft/vcpkg" "${VCPKG_ROOT}" \
    && "${VCPKG_ROOT}/bootstrap-vcpkg.sh" -disableMetrics -musl \
    && cd "${ZITI_ROOT}" \
    && ZTVERSION="${ZTVERSION:-$(curl -Ls 'https://github.com/openziti/ziti-tunnel-sdk-c/tags' | awk '/tags/{if(match($0,/v[0-9].[0-9]+.[0-9]+/)){ALLVERSIONS[substr($0,RSTART,RLENGTH)]++}}END{for(EACHVERSION in ALLVERSIONS){gsub("v","",EACHVERSION);print EACHVERSION}}' | sort -rnt '.' -k1,1 -k2,2 -k3,3 | head -n1)}" \
    && curl -Lso "v${ZTVERSION}.zip" "${ZTBRANCHOVERRIDE:-https://github.com/openziti/ziti-tunnel-sdk-c/archive/refs/tags/v${ZTVERSION}.zip}" \
    && unzip "v${ZTVERSION}.zip" \
    && sed -i 's/arm-linux-gnueabihf/armv6-alpine-linux-musleabihf/' "${ZITI_ROOT}/ziti-tunnel-sdk-c-${ZTVERSION}/toolchains/Linux-arm.cmake" \
    && sed -i 's/aarch64-linux-gnu/aarch64-alpine-linux-musl/' "${ZITI_ROOT}/ziti-tunnel-sdk-c-${ZTVERSION}/toolchains/Linux-arm64.cmake" \
    && sed -i 's/arm64/aarch64/; 4i set(VCPKG_BUILD_TYPE release)' "${VCPKG_ROOT}/triplets/community/arm64-linux.cmake" \
    && sed -i 's/arm/aarch64/; 4i set(VCPKG_BUILD_TYPE release)' "${VCPKG_ROOT}/triplets/community/arm-linux.cmake" \
    && sed -i '4i set(VCPKG_BUILD_TYPE release)' "${VCPKG_ROOT}/triplets/x64-linux.cmake" \
    && sed -i '/attempting copy/d; /copy successful/d' "${ZITI_ROOT}/ziti-tunnel-sdk-c-${ZTVERSION}/programs/ziti-edge-tunnel/netif_driver/linux/resolvers.c" \
    && sed -i '/"mbedtls",/d' "${ZITI_ROOT}/ziti-tunnel-sdk-c-${ZTVERSION}/vcpkg.json" \
    && cmake \
        --fresh \
        -DGIT_VERSION="${ZTVERSION}" \
        -DTLSUV_TLSLIB="openssl" \
        -DHAVE_LIBSODIUM="ON" \
        -DDISABLE_LIBSYSTEMD_FEATURE="ON" \
        --preset "${CMAKE_PRESET:-ci-linux-x64}-static-libssl" \
        -DBUILD_DIST_PACKAGES="OFF" \
        -S "${ZITI_ROOT}/ziti-tunnel-sdk-c-${ZTVERSION}" \
        -B "${ZITIBUILD_ROOT}" \
    && sed -i '/Ziti C SDK version/i ZITI_LOG(INFO, "Welcome to Ziti - Home Assistant Edition [v'"${BUILD_VERSION}"']");' "${ZITIBUILD_ROOT}/_deps/ziti-sdk-c-src/library/utils.c" \
    && cmake \
        --build "${ZITIBUILD_ROOT}" \
        --target "ziti-edge-tunnel" \
#        --config "Release" \
    && find "${ZITIBUILD_ROOT}/programs/ziti-edge-tunnel/" -name ziti-edge-tunnel -type f -exec mv -vf {} "${ZITI_ROOT}" \; \
    && rm -rf "v${ZTVERSION}.zip" "ziti-tunnel-sdk-c-${ZTVERSION}" "${ZITIBUILD_ROOT}" "${VCPKG_ROOT}" \
    && echo 'ziti:x:99:' >> "/etc/group" \
    && CLIVERSION="${CLIVERSION:-$(curl -LsH 'Accept: application/json' 'https://github.com/home-assistant/cli/releases/latest' | jq -r '.tag_name')}" \
    && curl -Lso "/usr/bin/ha" "https://github.com/home-assistant/cli/releases/download/${CLIVERSION}/ha_${BUILD_ARCH}" \
    && chmod a+x "/usr/bin/ha"

# Copy files into the image.
COPY rootfs /
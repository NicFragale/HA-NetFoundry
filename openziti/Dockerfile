####################################################################################################
# 20231101 - Written by Nic Fragale @ NetFoundry.
####################################################################################################
ARG BUILD_FROM
FROM $BUILD_FROM
ARG BUILD_ARCH

# Add labels to the image.
LABEL \
	io.hass.name="${BUILD_NAME}" \
	io.hass.description="${BUILD_DESCRIPTION}" \
	io.hass.arch="armhf|aarch64|i386|amd64" \
	io.hass.type="addon" \
	io.hass.version=${BUILD_VERSION} \
	io.hass.image.licenses="APACHE2.0" \
	io.hass.image.url="https://github.com/NicFragale/HA-NetFoundry" \
	io.hass.image.documentation="https://github.com/NicFragale/HA-NetFoundry/blob/07b636f23eca256c185f695794c52be1feb3d124/openziti/README.md" \
	io.hass.image.created=${BUILD_DATE} \
	io.hass.image.version=${BUILD_VERSION} \
	maintainer="Nic Fragale <nic.fragale@netfoundry.io>"

# Update the system and download required software.
RUN set -x \
	&& apk update \
	&& apk add --no-cache sudo sed iproute2 cmake build-base \
	gawk git jq socat nginx php-fpm ninja zip unzip curl git \
	libuv-dev zlib-dev linux-headers

# Setup NGINX.
RUN set -x \
	&& mkdir -vp '/var/run/nginx' '/var/run/php' '/var/www/html/images' \
	&& sed -i -e 's/^;listen =.*\|^listen =.*/listen = \/var\/run\/php\/php8.1-fpm.sock/' \
	-e 's/^;listen.owner =.*\|^listen.owner =.*/listen.owner = nginx/' \
	-e 's/^;listen.group =.*\|^listen.group =.*/listen.group = nginx/' \
	-e 's/nobody/nginx/g' /etc/php8*/php-fpm.d/www.conf \
	&& echo -e "nginx ALL = (root) NOPASSWD: /opt/NetFoundry/scripts/infodisplay.sh\nnginx ALL = (root) NOPASSWD: /opt/NetFoundry/scripts/zetdisplay.sh\n" >> /etc/sudoers

# Build and setup NetFoundry OpenZITI.
RUN set -x \
	&& export CMAKE_PRESET="$(\
		[[ $(arch) == \"arm64\" ]] \
			&& echo \"ci-linux-arm64\" \
			|| echo)" \
	&& export VCPKG_FORCE_SYSTEM_BINARIES=1 \
	&& export ZITI_ROOT="/opt/NetFoundry" \
	&& export ZITIBUILD_ROOT="${ZITI_ROOT}/build" \
	&& export VCPKG_ROOT="${ZITI_ROOT}/vcpkg" \
	&& mkdir -vp "${VCPKG_ROOT}" "${ZITI_ROOT}" "${ZITIBUILD_ROOT}" \
	&& cd "${ZITI_ROOT}" \
	&& git clone "https://github.com/microsoft/vcpkg" "${VCPKG_ROOT}" \
	&& "${VCPKG_ROOT}"/bootstrap-vcpkg.sh -disableMetrics \
	&& cd "${ZITI_ROOT}" \
	&& ZTVERSION="$(\
		curl -Ls 'https://github.com/openziti/ziti-tunnel-sdk-c/tags' \
		| awk '/tags/{if(match($0,/v[0-9].[0-9]+.[0-9]+/)){ALLVERSIONS[substr($0,RSTART,RLENGTH)]++}}END{for(EACHVERSION in ALLVERSIONS){gsub("v","",EACHVERSION);print EACHVERSION}}' \
		| sort -rnt '.' -k1,1 -k2,2 -k3,3 \
		| head -n1)" \
	&& curl -Lso "v${ZTVERSION}.zip" \
	"https://github.com/openziti/ziti-tunnel-sdk-c/archive/refs/tags/v${ZTVERSION}.zip" \
	&& unzip v${ZTVERSION}.zip \
	&& cd ziti-tunnel-sdk-c-${ZTVERSION} \
	&& sed -i 's/aarch64-linux-gnu/aarch64-alpine-linux-musl/' toolchains/Linux-arm64.cmake \
	&& cmake \
		--fresh \
		-DGIT_VERSION=${ZTVERSION} \
		-DTLSUV_TLSLIB=mbedtls \
		-DUSE_MBEDTLS=ON \
		-DHAVE_LIBSODIUM=ON \
		-DDISABLE_LIBSYSTEMD_FEATURE=ON \
		--preset "${CMAKE_PRESET:-ci-linux-x64}" \
			-DCMAKE_BUILD_TYPE="Release" \
			-DBUILD_DIST_PACKAGES="OFF" \
			-DVCPKG_OVERLAY_PORTS="./vcpkg-overlays/linux-syslibs/ubuntu18" \
		-B ${ZITIBUILD_ROOT} \
	&& cd ${ZITI_ROOT} \
	&& cmake --build ${ZITIBUILD_ROOT} --target ziti-edge-tunnel \
	&& mv -vf ${ZITIBUILD_ROOT}/programs/ziti-edge-tunnel/Debug/ziti-edge-tunnel . \
	&& rm -rf v${ZTVERSION}.zip ziti-tunnel-sdk-c-${ZTVERSION} ${ZITIBUILD_ROOT} ${VCPKG_ROOT} \
	&& echo 'ziti:x:99:' >> /etc/group 

# Add the Home Assistant CLI.
RUN set -x \
	&& CLIVERSION="$(curl -LsH 'Accept: application/json' \
	'https://github.com/home-assistant/cli/releases/latest' \
	| jq -r '.tag_name')" \
	&& curl -Lso "/usr/bin/ha" \
	"https://github.com/home-assistant/cli/releases/download/${CLIVERSION}/ha_${BUILD_ARCH}" \
	&& chmod a+x /usr/bin/ha

# Copy files into the image.
COPY default.conf /etc/nginx/http.d/
COPY index.php /var/www/html
COPY zetdisplay.php /var/www/html
COPY infodisplay.php /var/www/html
COPY jquery-3.6.4.min.js /var/www/html
COPY logo.png /var/www/html/images
COPY rootfs /
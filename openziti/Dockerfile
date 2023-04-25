ARG BUILD_FROM
FROM $BUILD_FROM

# Add labels to the image.
LABEL \
	io.hass.name="${BUILD_NAME}" \
	io.hass.description="${BUILD_DESCRIPTION}" \
	io.hass.arch="${BUILD_ARCH}" \
	io.hass.type="addon" \
	io.hass.version=${BUILD_VERSION} \
	io.hass.image.licenses="APACHE2.0" \
	io.hass.image.url="https://github.com/NicFragale/HA-NetFoundry" \
	io.hass.image.documentation="https://github.com/NicFragale/HA-NetFoundry/blob/07b636f23eca256c185f695794c52be1feb3d124/openziti/DOCS.md" \
	io.hass.image.created=${BUILD_DATE} \
	io.hass.image.version=${BUILD_VERSION} \
	maintainer="Nic Fragale <nic.fragale@netfoundry.io>"

# Update the system and download required software.
RUN set -x \
	&& apk update \
	&& apk add --no-cache sed iproute2 cmake build-base libatomic zlib-dev linux-headers gawk rsyslog git jq libuv-dev unzip zip openssl-dev doxygen libsodium-dev

# Build NetFoundry OpenZITI.
RUN set -x \
	&& mkdir -vp /opt/NetFoundry/build \
	&& cd /opt/NetFoundry/build \
	&& ZTVERSION="$(\
	curl -Ls 'https://github.com/openziti/ziti-tunnel-sdk-c/tags' \
	| awk '/tags/{if(match($0,/v[0-9].[0-9]+.[0-9]+/)){ALLVERSIONS[substr($0,RSTART,RLENGTH)]++}}END{for(EACHVERSION in ALLVERSIONS){gsub("v","",EACHVERSION);print EACHVERSION}}' \
	| sort -rnt '.' -k1,1 -k2,2 -k3,3 \
	| head -n1)" \
	&& curl -Lso "v${ZTVERSION}.zip" \
	"https://github.com/openziti/ziti-tunnel-sdk-c/archive/refs/tags/v${ZTVERSION}.zip" \
	&& unzip v${ZTVERSION}.zip \
	&& cd ziti-tunnel-sdk-c-${ZTVERSION} \
	&& cmake -DGIT_VERSION=${ZTVERSION} -DUSE_OPENSSL=on -DHAVE_LIBUV=on -DHAVE_LIBSODIUM=on -DDISABLE_LIBSYSTEMD_FEATURE=ON -B../ \
	&& sed -i 's|/tmp/ziti-edge-tunnel.sock|/share/ziti-edge-tunnel.sock|' programs/ziti-edge-tunnel/ziti-edge-tunnel.c \
	&& sed -i 's|/tmp/ziti-edge-tunnel-event.sock|/share/ziti-edge-tunnel-event.sock|' programs/ziti-edge-tunnel/ziti-edge-tunnel.c \
	&& sed -i '/# if ! __GNUC_PREREQ(4,9)/,+2d' ../_deps/ziti-sdk-c-src/inc_internal/metrics.h \
	&& sed -i 's|-luv_a|-luv|' /opt/NetFoundry/build/programs/ziti-edge-tunnel/CMakeFiles/ziti-edge-tunnel.dir/link.txt \
	&& cd /opt/NetFoundry/ \
	&& cmake --build ./build --target ziti-edge-tunnel \
	&& mv -vf build/programs/ziti-edge-tunnel/ziti-edge-tunnel . \
	&& rm -rf build

# Add the Home Assistant CLI.
RUN set -x \
	&& curl -Lso "/usr/bin/ha" \
	"https://github.com/home-assistant/cli/releases/download/$(\
	curl -LH 'Accept: application/json' \
	'https://github.com/home-assistant/cli/releases/latest' \
	| jq -r '.tag_name' \
	)/ha_${BUILD_ARCH}" \
	&& chmod a+x /usr/bin/ha

# All work has been done.
COPY rootfs /
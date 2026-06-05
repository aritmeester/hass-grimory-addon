FROM ghcr.io/grimmory-tools/grimmory:v3.2.0 AS grimmory-source
FROM eclipse-temurin:25-jre-alpine AS java-runtime

FROM ghcr.io/hassio-addons/base:14.3.1

RUN apk add --no-cache curl jq mariadb-client su-exec libarchive libgcc libstdc++

COPY --from=grimmory-source /app/app.jar /app/app.jar
COPY --from=grimmory-source /usr/local/bin/ffprobe /usr/local/bin/ffprobe
COPY --from=grimmory-source /usr/local/bin/kepubify /usr/local/bin/kepubify
COPY --from=java-runtime /opt/java/openjdk /opt/java/openjdk

COPY run.sh /usr/local/bin/grimmory-run.sh
COPY rootfs /

RUN chmod a+x /usr/local/bin/grimmory-run.sh \
	&& chmod a+x /etc/cont-init.d/00-grimmory-setup \
    && chmod a+x /etc/services.d/dbcheck/run \
    && chmod a+x /etc/services.d/grimmory/run

LABEL \
	org.opencontainers.image.title="Home Assistant Add-on: Grimmory" \
	org.opencontainers.image.description="Hosts Grimmory inside Home Assistant with a /share bookdrop, S6 services, and a MariaDB backend." \
	org.opencontainers.image.source="https://github.com/aritmeester/hass-grimory-addon"

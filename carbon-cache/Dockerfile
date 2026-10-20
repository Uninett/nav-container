# Fetch NAV's recommended carbon config from the same NAV version as the nav
# image, so the retention rules match the metrics that NAV version sends
FROM alpine:3.24 AS nav-graphite-config
ARG NAV_VERSION
WORKDIR /graphite
RUN for conf in storage-schemas.conf storage-aggregation.conf; do \
      wget -q "https://raw.githubusercontent.com/Uninett/nav/${NAV_VERSION}/python/nav/etc/graphite/${conf}" || exit 1; \
    done

FROM debian:trixie-slim
LABEL description="A carbon-cache instance configured explicitly for use with NAV"
LABEL maintainer="Morten Brekkevold <morten.brekkevold@sikt.no>"

# Add Tini
RUN apt-get update && apt-get install -y tini
ENTRYPOINT ["/usr/bin/tini", "--"]

ENV GRAPHITE_CONF_DIR=/etc/carbon

RUN apt-get update && apt-get install -y graphite-carbon

COPY carbon.conf ${GRAPHITE_CONF_DIR}/carbon.conf
COPY --from=nav-graphite-config /graphite/ ${GRAPHITE_CONF_DIR}/

EXPOSE 2003/udp 2003 2004 7002
VOLUME ["/var/lib/graphite/whisper"]
USER   _graphite

CMD    ["/usr/bin/carbon-cache", "--nodaemon", "--config=/etc/carbon/carbon.conf", "start"]

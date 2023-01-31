FROM debian:bullseye-slim
LABEL description="A carbon-cache instance configured explicitly for use with NAV"
LABEL maintainer="Morten Brekkevold <morten.brekkevold@sikt.no>"

# Add Tini
RUN apt-get update && apt-get install -y tini
ENTRYPOINT ["/usr/bin/tini", "--"]

ENV GRAPHITE_CONF_DIR /etc/carbon

RUN apt-get update && apt-get install -y graphite-carbon

COPY carbon.conf ${GRAPHITE_CONF_DIR}/carbon.conf
COPY --from=mbrekkevold/nav:latest /etc/nav/graphite/storage-schemas.conf ${GRAPHITE_CONF_DIR}/storage-schemas.conf
COPY --from=mbrekkevold/nav:latest /etc/nav/graphite/storage-aggregation.conf ${GRAPHITE_CONF_DIR}/storage-aggregation.conf

EXPOSE 2003/udp 2003 2004 7002
VOLUME ["/var/lib/graphite/whisper"]
USER   _graphite

CMD    ["/usr/bin/carbon-cache", "--nodaemon", "--config=/etc/carbon/carbon.conf", "start"]

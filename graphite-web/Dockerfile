FROM debian:trixie-slim
LABEL description="A graphite-web instance for NAV"
LABEL maintainer="Morten Brekkevold <morten.brekkevold@sikt.no>"

# Add Tini
RUN apt-get update && apt-get install -y tini
ENTRYPOINT ["/usr/bin/tini", "--"]

ENV GRAPHITE_CONF_DIR /etc/graphite
ENV GRAPHITE_STORAGE_DIR /var/lib/graphite/whisper

RUN apt-get -y update && \
    apt-get -y install graphite-web supervisor nginx gunicorn

# Basic configuration and permissions

# Copy configuration files
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY local_settings.py ${GRAPHITE_CONF_DIR}/local_settings.py

# Initialize database
ENV DJANGO_SETTINGS_MODULE graphite.settings
ENV GRAPHITE_SETTINGS_MODULE=local_settings
RUN mkdir -p ${GRAPHITE_STORAGE_DIR} && chown _graphite:_graphite ${GRAPHITE_STORAGE_DIR}

USER _graphite
RUN /usr/bin/django-admin migrate --run-syncdb
USER root

EXPOSE 80
VOLUME ["/var/lib/graphite/whisper"]
CMD    ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

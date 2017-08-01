FROM python:2.7

# Add Tini
ENV TINI_VERSION v0.14.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

ENV LIBDIR /usr/local/lib/python2.7/site-packages
ENV GRAPHITE_CONF_DIR /var/lib/graphite/conf
ENV GRAPHITE_STORAGE_DIR /var/lib/graphite/storage

# Add user to run it, and install the software
RUN adduser --system --group --no-create-home --home=/var/lib/graphite --shell=/bin/bash graphite
RUN pip install whisper
RUN pip install graphite-web --install-option="--install-scripts=/usr/local/bin" --install-option="--install-lib=$LIBDIR" --install-option="--install-data=/var/lib/graphite"

RUN apt-get -y update && \
    apt-get -y install supervisor nginx-light gunicorn

# Basic configuration and permissions

RUN chown -R graphite:graphite /var/lib/graphite

# Copy configuration files
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY local_settings.py ${LIBDIR}/graphite/local_settings.py

# Initialize database
ENV DJANGO_SETTINGS_MODULE graphite.settings
RUN su -c '/usr/local/bin/django-admin migrate --run-syncdb' graphite

EXPOSE 80
VOLUME ["/var/lib/graphite/storage/whisper"]

CMD    ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

FROM python:3.5-stretch
LABEL maintainer="Morten Brekkevold <morten.brekkevold@uninett.no>"

RUN apt-get update \
    && apt-get -y --no-install-recommends install \
       supervisor \
       libsnmp30 \
       cron \
       sudo \
       pwgen \
       apache2 \
       libapache2-mod-wsgi-py3 \
       nbtscan \
       libpq5 \
       postgresql-client \
       python3-gammu

# possibly want these packages for debugging inside the container:
#       vim \
#       less \


# Install python module dependencies, assuming they have already been made
# available as wheels
COPY nav/requirements/ /requirements
COPY nav/requirements.txt database.sq[l] /
COPY .wheels/ /wheelhouse
RUN pip3 install --no-index --find-links=/wheelhouse -r requirements.txt

# Install NAV itself
RUN adduser --system --group --home=/usr/local/nav --shell=/bin/bash nav
COPY .build/ /
RUN mkdir /etc/nav &&  chown nav /etc/nav && su nav -c 'nav config install /etc/nav'
RUN mkdir /var/log/nav && chown nav /var/log/nav
RUN mkdir -p /var/lib/nav/uploads/images/rooms && mkdir -p /var/lib/nav/htdocs/static && chown -R nav /var/lib/nav

RUN mkdir -p /usr/local/share/nav/var && \
    ln -s /var/lib/nav/uploads /usr/local/share/nav/var/uploads && \
    mkdir -p /usr/local/share/nav/www && \
    ln -s /var/lib/nav/htdocs/static /usr/local/share/nav/www/static && \
    django-admin collectstatic --noinput --settings=nav.django.settings

# Add Tini
ENV TINI_VERSION v0.14.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--", "/docker-entrypoint.sh"]

# Install our config and entrypoints
COPY etc/ /etc
COPY docker-entrypoint.sh /
COPY docker-initdb.sh /
RUN a2dissite 000-default; a2ensite nav-site

# Run all NAV processes in one container by default
CMD ["/usr/bin/supervisord", "-n"]

# Final environment
ENV    PATH /usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
ENV    ADMIN_MAIL root@localhost
ENV    DEFAULT_FROM_EMAIL nav@localhost
ENV    DOMAIN_SUFFIX .example.org

VOLUME ["/var/log/nav", "/var/lib/nav/uploads/images/rooms"]
EXPOSE 80

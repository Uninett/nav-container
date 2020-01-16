FROM python:3.5-stretch AS builder
ENV VERSION=5.0.4
ENV REPO deb.debian.org
ENV GIT_COMMITTER_NAME Dummy
ENV GIT_COMMITTER_EMAIL dummy@example.org
# We need source archives as well
RUN echo "\n\
\
deb http://security.debian.org/ stretch/updates main\n\
deb-src http://security.debian.org/ stretch/updates main\n\
deb http://$REPO/debian stretch main contrib non-free\n\
deb-src http://$REPO/debian stretch main contrib non-free\n\
deb http://$REPO/debian stretch-updates main contrib non-free\n\
deb-src http://$REPO/debian stretch-updates main contrib non-free\n\
\
" > /etc/apt/sources.list

# Unfortunately, we need heaps of stuff just to build the docs, since autodoc
# requires Python imports to work. In other words, these requirements are
# normally only needed for the runtime.
RUN apt-get update \
    && apt-get -y --no-install-recommends build-dep \
       python3-psycopg2 \
       python3-lxml \
       python-imaging \
       python-ldap

# Build wheels from requirements so they can be re-used in a production image
# without installing all the dev tools there too
RUN pip3 install --upgrade pip
RUN mkdir /.cache && chmod 777 /.cache

RUN mkdir /source
WORKDIR /source
RUN git clone https://github.com/Uninett/nav.git nav --branch $VERSION --depth 1
RUN mkdir -p .wheels
RUN pip3 wheel -w ./.wheels/ -r nav/requirements.txt
RUN pip3 install --root="/source/.build" ./nav


FROM python:3.5-stretch
LABEL maintainer="Morten Brekkevold <morten.brekkevold@uninett.no>"

# Start by adding Tini
ENV TINI_VERSION v0.14.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--", "/docker-entrypoint.sh"]

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
COPY --from=builder /source/nav/requirements/ /requirements
COPY --from=builder /source/nav/requirements.txt /
COPY --from=builder /source/.wheels/ /wheelhouse
RUN pip3 install --no-index --find-links=/wheelhouse -r requirements.txt

# Install NAV itself
RUN adduser --system --group --home=/usr/local/nav --shell=/bin/bash nav
COPY --from=builder /source/.build/ /
RUN mkdir /etc/nav &&  chown nav /etc/nav && su nav -c 'nav config install /etc/nav'
RUN mkdir /var/log/nav && chown nav /var/log/nav
RUN mkdir -p /var/lib/nav/uploads/images/rooms && mkdir -p /var/lib/nav/htdocs/static && chown -R nav /var/lib/nav

RUN mkdir -p /usr/local/share/nav/var && \
    ln -s /var/lib/nav/uploads /usr/local/share/nav/var/uploads && \
    mkdir -p /usr/local/share/nav/www && \
    ln -s /var/lib/nav/htdocs/static /usr/local/share/nav/www/static && \
    django-admin collectstatic --noinput --settings=nav.django.settings

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

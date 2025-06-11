FROM python:3.11-slim-bookworm AS builder
ENV REPO=deb.debian.org
ENV GIT_COMMITTER_NAME=Dummy
ENV GIT_COMMITTER_EMAIL=dummy@example.org
# We need source archives as well
RUN echo "\n\
\
deb http://security.debian.org/ bookworm-security main contrib non-free\n\
deb-src http://security.debian.org/ bookworm-security main contrib non-free\n\
deb http://$REPO/debian bookworm main contrib non-free\n\
deb-src http://$REPO/debian bookworm main contrib non-free\n\
deb http://$REPO/debian bookworm-updates main contrib non-free\n\
deb-src http://$REPO/debian bookworm-updates main contrib non-free\n\
" > /etc/apt/sources.list

# We're using mount caches, so don't clean the apt cache after every apt command!
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Unfortunately, we need heaps of stuff just to build the docs, since autodoc
# requires Python imports to work. In other words, these requirements are
# normally only needed for the runtime.
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt-get update \
    && apt-get -y --no-install-recommends build-dep \
       python3-psycopg2 \
       python3-lxml \
       python3-pil \
       python3-ldap

# Enable us to build the python-gammu module:
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt-get update \
    && apt-get -y install \
       # Enable us to build the python-gammu module \
       libgammu-dev \
       # No git in slim image \
       git

# Build wheels from requirements so they can be re-used in a production image
# without installing all the dev tools there too
RUN pip3 install --upgrade pip
RUN mkdir /.cache && chmod 777 /.cache

RUN mkdir /source
WORKDIR /source
ARG NAV_VERSION
RUN git clone https://github.com/Uninett/nav.git nav --branch ${NAV_VERSION} --depth 1
RUN mkdir -p .wheels
RUN --mount=type=cache,target=/root/.cache/pip pip3 wheel -w ./.wheels/ -r nav/requirements.txt -c nav/constraints.txt python-gammu==3.2.4
RUN --mount=type=cache,target=/root/.cache/pip pip3 install --root="/source/.build" ./nav

# Now, build the actual installation stage
FROM python:3.11-slim-bookworm

# We're using mount caches, so don't clean the apt cache after every apt command!
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt-get update \
    && apt-get -y --no-install-recommends install \
       tini \
       supervisor \
       libsnmp40 \
       cron \
       sudo \
       pwgen \
       apache2 \
       libapache2-mod-wsgi-py3 \
       nbtscan \
       libpq5 \
       git \
       gpg \
       postgresql-client


# Use tini as our image init process
ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]

ARG NAV_VERSION
LABEL maintainer="Morten Brekkevold <morten.brekkevold@sikt.no>"
LABEL description="Network Administration Visualized ${NAV_VERSION}"

# Install python module dependencies, assuming they have already been made
# available as wheels
COPY --from=builder /source/nav/requirements/ /requirements
COPY --from=builder /source/nav/requirements.txt /
COPY --from=builder /source/nav/constraints.txt /
COPY --from=builder /source/.wheels/ /wheelhouse
RUN --mount=type=cache,target=/root/.cache/pip pip3 install --no-index --find-links=/wheelhouse -r requirements.txt -c constraints.txt

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
ENV    PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
ENV    ADMIN_MAIL=root@localhost
ENV    DEFAULT_FROM_EMAIL=nav@localhost
ENV    DOMAIN_SUFFIX=.example.org

VOLUME ["/var/log/nav", "/var/lib/nav/uploads/images/rooms"]
EXPOSE 80

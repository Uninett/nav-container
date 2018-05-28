FROM python:2.7-jessie
LABEL maintainer="Morten Brekkevold <morten.brekkevold@uninett.no>"

RUN apt-get update \
    && apt-get -y --no-install-recommends install \
       supervisor \
       libsnmp30 \
       cron \
       sudo \
       pwgen \
       apache2 \
       libapache2-mod-wsgi \
       nbtscan \
       libpq5 \
       postgresql-client \
       python-gammu

# possibly want these packages for debugging inside the container:
#       vim \
#       less \


# Install python module dependencies, assuming they have already been made
# available as wheels
COPY nav/requirements/ /requirements
COPY nav/requirements.txt /
COPY .wheels/ /wheelhouse
RUN pip install --no-index --find-links=/wheelhouse -r requirements.txt

# Install NAV itself
RUN adduser --system --group --no-create-home --home=/usr/local/nav --shell=/bin/bash nav
COPY .build/ /
RUN chown -R nav /usr/local/nav
RUN echo "import sys\nsys.path.extend(['/usr/local/nav/lib/python', '/usr/lib/python2.7/dist-packages'])" > /usr/local/lib/python2.7/sitecustomize.py


# Add Tini
ENV TINI_VERSION v0.14.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# Install our config and entrypoints
COPY etc/ /etc
COPY docker-entrypoint.sh /
COPY docker-initdb.sh /
RUN a2dissite 000-default; a2ensite nav-site

# Our own prep program
CMD ["/docker-entrypoint.sh"]

# Final environment
ENV    PATH /usr/local/nav/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
ENV    ADMIN_MAIL root@localhost
ENV    DEFAULT_FROM_EMAIL nav@localhost
ENV    DOMAIN_SUFFIX .example.org

RUN    echo "PATH=$PATH" > /etc/profile.d/navpath.sh
VOLUME ["/usr/local/nav/var/log", "/usr/local/nav/var/uploads/images/rooms"]
EXPOSE 80

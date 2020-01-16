# Containerized NAV distribution

This project aims to package NAV for containerized production distribution,
using Docker and docker-compose, which could later be used as a basis for
deploying on Kubernetes.


## How to build and run

This command should be sufficient to get things up and running using Docker
Compose:

```
docker-compose up
```

This should bring up various containers, for NAV, PostgreSQL and Graphite.
These will have various data and log directories mounted under the `data/`
directory.

## How it's organized

The `nav` container includes all NAV backend processes and the NAV web
interfaces served through Apache2/mod_wsgi (using NAV's supplied Apache
example config). Supervisord is used to start and supervise all NAV services
(and Apache and cron), thereby bypassing NAV's builtin service manager. Once
you go container-based, it doesn't make much sense to control individual NAV
services by starting up a shell process inside an existing container to do so.

A fully distributed/scalable Graphite infrastructure is not provided, but the
two minimum requirements of a `carbon-cache` daemon and a `graphite-web`
interface is provided by two separate containers. These two containers will
share a storage volume mounted from a third container. NAV's recommended
configuration for carbon storage schemas and aggregation rules are installed
into the `carbon-cache` image directly from the NAV source code.

https://github.com/Banno/graphite-setup was a good inspiration, and should be
looked at if you want to scale out your Graphite install.

The `postgres` container is a bog standard `postgres` image from the Docker
Hub.


## Configuration


The NAV container will accept various basic and necessary options as
environment variables. The rest of the NAV config must either be manipulated
through editing the files inside the running container, or mounting the config
files from external media.

| Variable      | Description                                       |
| ------------- | ------------------------------------------------- |
| `PGHOST`      | PostgreSQL server host name or IP                 |
| `PGPORT`      | PostgreSQL server port                            |
| `PGDATABASE`  | PostgreSQL database name where NAV can store data |
| `PGUSER`      | Username used to access the PostgreSQL database   |
| `PGPASSWORD`  | Password to use for the PostgreSQL user           |
| `NOINITDB`    | If set to 1, the container will assume the database has already been created externally and will only run schema updates against it. If set to 0, the container will assume it can access PostgreSQL as the postgres superuser without a password and attempt to create the database and user   |
| `SKIPDBTEST`    | If set to 1, the container will skip all PostgreSQL connection wait and schema init or schema sync steps |
| `CARBONPORT`  | The port number of the carbon backend             |
| `GRAPHITEWEB` | The URL to the graphite-web interface             |

These variables from
[nav.conf](https://github.com/UNINETT/nav/blob/master/etc/nav.conf) can also
be supplied as environment variables:

| Variable              |
| --------------------- |
| `ADMIN_MAIL`          |
| `DEFAULT_FROM_EMAIL`  |
| `SECRET_KEY`          |
| `EMAIL_HOST`          |
| `EMAIL_PORT`          |
| `EMAIL_HOST_USER`     |
| `EMAIL_HOST_PASSWORD` |
| `EMAIL_USE_TLS`       |
| `DOMAIN_SUFFIX`       |
| `DJANGO_DEBUG`        |
| `TIME_ZONE`           |

## Using an existing database dump

If you wish to bootstrap your NAV installation from an existing database dump
(made from the `navpgdump` program), you can do so by mounting the dump file to
the nav container as `/database.sql`. The database will be initialized with this
as the baseline the first time the container is started.

## Ideas for future improvement

- Apache may be replaced by nginx
- The entire web app should maybe just provide a WSGI interface using uwsgi,
  so that one can configure one's own user-facing nginx proxy with SSL in
  front of it.
- What to do about accessing the various configuration options spread
  throughout NAV's configuration files? Only options affecting access to
  external services such as PostgreSQL and Graphite are supported so far.
  Configuring an SMTP relay server, a domain, etc. should also be in there.
- memcache integration is a *must* for production use of graphite-web.

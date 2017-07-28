Containerized NAV distribution
------------------------------

This project aims to package NAV for containerized production distribution,
using Docker and docker-compose, which could later be used as a basis for
deploying on Kubernetes.


How to build and run
--------------------

These commands should be sufficient to get things up and running using Docker
Compose:

```
./build.sh
docker-compose up
```

This should bring up three containers, one for NAV, one for PostgreSQL and one
for Graphite. These will have various data and log directories mounted under
the `data/` directory.

How it's organized
------------------

The `nav` container includes all NAV backend processes and the NAV web
interfaces served through Apache2/mod_wsgi (using NAV's supplied Apache
example config). Supervisord is used to start and supervise all NAV services
(and Apache and cron), thereby bypassing NAV's builtin service manager. Once
you go container-based, it doesn't make much sense to control individual NAV
services by starting up a shell process inside an existing container to do so.

The `graphite` container is defined by the development version provided in
NAV's source code, and consists of a single `carbon-cache` daemon listening to
standard ports 2003 and 2004, and a `graphite-web` process on port 8000 (as of
NAV 4.7.1). All processes are supervised by `supervisord`. NAV's example
configuration for carbon storage schemas and aggregation rules are installed
into the image directly from the NAV source code.

The `postgres` container is a bog standard `postgres` image from the Docker
Hub.


Configuration
-------------

The NAV container will accept various basic and necessary options as
environment variables. The rest of the NAV config must either be manipulated
through editing the files inside the running container, or mounting the config
files from external media.

| Variable    | Description                                       |
| ----------- | ------------------------------------------------- |
| PGHOST      | PostgreSQL server host name or IP                 |
| PGPORT      | PostgreSQL server port                            |
| PGDATABASE  | PostgreSQL database name where NAV can store data |
| PGUSER      | Username used to access the PostgreSQL database   |
| PGPASSWORD  | Password to use for the PostgreSQL user           |
| NOINITDB    | If set to 1, the container will assume the database has already been created externally and will only run schema updates against it. If set to 0, the container will assume it can access PostgreSQL as the postgres superuser without a password and attempt to create the database and user   |
| CARBONHOST  | The hostname or IP of the carbon backend to use   |
| CARBONPORT  | The port number of the carbon backend             |
| GRAPHITEWEB | The URL to the graphite-web interface             |


Ideas for future improvement
----------------------------

- Apache may be replaced by nginx
- The entire web app should maybe just provide a WSGI interface using uwsgi,
  so that one can configure one's own user-facing nginx proxy with SSL in
  front of it.
- What to do about accessing the various configuration options spread
  throughout NAV's configuration files? Only the database config is supported
  so far. Configuring an SMTP relay server, a domain, etc. should also be in
  there.
- The graphite container could potentially be split into two, since it
  provides two different services with shared storage.
  https://github.com/Banno/graphite-setup might actually be a good source of
  inspiration here.

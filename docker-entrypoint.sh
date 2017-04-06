#!/bin/sh -ex
# Verify PostgreSQL availability and initialize / synchronize database schema
/docker-initdb.sh

# Init Graphite connection config
CARBONHOST=${CARBONHOST:-graphite}
CARBONPORT=${CARBONPORT:-2003}
GRAPHITEWEB=${GRAPHITEWEB:-http://graphite:8000/}

cat > /usr/local/nav/etc/graphite.conf <<EOF
[carbon]
host = ${CARBONHOST}
port = ${CARBONPORT}

[graphiteweb]
base=${GRAPHITEWEB}
EOF

# Set up all NAV cron jobs
cat /usr/local/nav/etc/cron.d/* | crontab -u nav -



# Have supervisord do the rest
exec /usr/bin/supervisord -n

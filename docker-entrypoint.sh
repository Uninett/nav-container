#!/bin/bash -e

#######################################
#                                     #
# Ensure PostgreSQL database is ready #
#                                     #
#######################################
SKIPDBTEST=${SKIPDBTEST:-0}
if [ "${SKIPDBTEST}" -eq 0 ]; then
    /docker-initdb.sh
fi

###################################
#                                 #
# Init Graphite connection config #
#                                 #
###################################
CARBONHOST=${CARBONHOST:-graphite}
CARBONPORT=${CARBONPORT:-2003}
GRAPHITEWEB=${GRAPHITEWEB:-http://graphite:8000/}

cat > "/etc/nav/graphite.conf" <<EOF
[carbon]
host = ${CARBONHOST}
port = ${CARBONPORT}

[graphiteweb]
base=${GRAPHITEWEB}
EOF

##################################
#                                #
# Configure basic NAV parameters #
#                                #
##################################
NAVCONF="/etc/nav/nav.conf"
SECRETPERSIST="/etc/nav/secret.persist"

if [ -z "$SECRET_KEY" ] && [ -f "$SECRETPERSIST" ]; then
    . "$SECRETPERSIST" || true
fi
if [ -z "$SECRET_KEY" ]; then
    # If no secret key was given, generate a random one and persist it between restarts
    SECRET_KEY="$(gpg -a --gen-random 1 51)"
    echo "SECRET_KEY=${SECRET_KEY}" > "$SECRETPERSIST"
fi

cat > "$NAVCONF" <<EOF
# Generated at $(date)
NAV_USER=nav
PID_DIR=/tmp
LOG_DIR=/var/log/nav
UPLOAD_DIR=/var/lib/nav/uploads
EOF
for var in ADMIN_MAIL DEFAULT_FROM_EMAIL SECRET_KEY EMAIL_HOST EMAIL_PORT EMAIL_HOST_USER EMAIL_HOST_PASSWORD EMAIL_USE_TLS DOMAIN_SUFFIX DJANGO_DEBUG TIME_ZONE; do

    if [ -n "${!var}" ]; then
	cat >> "$NAVCONF" <<EOF
${var} = ${!var}
EOF
    fi
done


############################
#                          #
# Set up all NAV cron jobs #
#                          #
############################
cat /etc/nav/cron.d/* | crontab -u nav -


##########################################
#                                        #
# Verify permissions on writable volumes #
#                                        #
##########################################
chown -R nav /var/lib/nav/uploads/images/rooms
chown -R nav /var/log/nav
mkdir -p /var/run/apache2; chown www-data /var/run/apache2

##########################
#                        #
# Run the user's command #
#                        #
##########################
exec "$@"

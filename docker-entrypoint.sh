#!/bin/bash -e
NAVROOT=/usr/local/nav

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

cat > "$NAVROOT/etc/graphite.conf" <<EOF
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
NAVCONF="$NAVROOT/etc/nav.conf"
SECRETPERSIST="$NAVROOT/etc/secret.persist"

if [ -z "$SECRET_KEY" ] && [ -f "$SECRETPERSIST" ]; then
    . "$SECRETPERSIST" || true
fi
if [ -z "$SECRET_KEY" ]; then
    # If no secret key was given, generate a random one and persist it between restarts
    SECRET_KEY="$(gpg -a --gen-random 1 51)"
    echo "SECRET_KEY=${SECRET_KEY}" > "$SECRETPERSIST"
fi

echo "# Generated at $(date)" > "$NAVCONF"
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
cat /usr/local/nav/etc/cron.d/* | crontab -u nav -


##########################################
#                                        #
# Verify permissions on writable volumes #
#                                        #
##########################################
chown -R nav /usr/local/nav/var/uploads/images/rooms
chown -R nav /usr/local/nav/var/log


################################
#                              #
# Have supervisord do the rest #
#                              #
################################
exec /usr/bin/supervisord -n

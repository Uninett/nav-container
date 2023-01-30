import os
from datetime import datetime

GRAPHITE_ROOT = '/usr/share/graphite-web'
CONF_DIR = '/etc/graphite'
CONTENT_DIR = '/usr/share/graphite-web/static'
LOG_DIR = '/var/log/graphite'
INDEX_FILE = '/var/lib/graphite/search_index'  # Search index file

if os.getenv("CARBONLINK_HOSTS"):
    CARBONLINK_HOSTS = os.getenv("CARBONLINK_HOSTS").split(',')

if os.getenv("CLUSTER_SERVERS"):
    CLUSTER_SERVERS = os.getenv("CLUSTER_SERVERS").split(',')

if os.getenv("MEMCACHE_HOSTS"):
    MEMCACHE_HOSTS = os.getenv("MEMCACHE_HOSTS").split(',')

WHISPER_DIR = os.getenv("WHISPER_DIR", "/var/lib/graphite/whisper")

if os.getenv("TIME_ZONE"):
    TIME_ZONE = os.getenv("TIME_ZONE")

SECRET_KEY = str(datetime.now())

import os
from datetime import datetime

if os.getenv("CARBONLINK_HOSTS"):
    CARBONLINK_HOSTS = os.getenv("CARBONLINK_HOSTS").split(',')

if os.getenv("CLUSTER_SERVERS"):
    CLUSTER_SERVERS = os.getenv("CLUSTER_SERVERS").split(',')

if os.getenv("MEMCACHE_HOSTS"):
    MEMCACHE_HOSTS = os.getenv("MEMCACHE_HOSTS").split(',')

if os.getenv("WHISPER_DIR"):
    WHISPER_DIR = os.getenv("WHISPER_DIR")

if os.getenv("TIME_ZONE"):
    TIME_ZONE = os.getenv("TIME_ZONE")

SECRET_KEY = str(datetime.now())

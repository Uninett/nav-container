REPO := mbrekkevold
BUILDIMAGE := navbuild
uid := $(shell id -u)
nav_version := 4.9.8

.PHONY: navbuild nav carbon-cache graphite-web push

all: navbuild nav carbon-cache graphite-web

navbuild:
	docker build -f Dockerfile.build -t "$(BUILDIMAGE)" .
	docker run --rm -v "$(CURDIR):/source:Z" -v "$(HOME)/.cache/pip:/.cache/pip:Z" --cap-drop=all -u "$(uid)" "$(BUILDIMAGE)"

nav:
	docker build -t $(REPO)/nav .
	docker tag $(REPO)/nav:latest $(REPO)/nav:$(nav_version)

carbon-cache/storage-schemas.conf: nav/python/nav/etc/graphite/storage-schemas.conf
	cp nav/python/nav/etc/graphite/storage-schemas.conf carbon-cache/

carbon-cache/storage-aggregation.conf: nav/python/nav/etc/graphite/storage-aggregation.conf
	cp nav/python/nav/etc/graphite/storage-aggregation.conf carbon-cache/

carbon-cache: carbon-cache/storage-schemas.conf carbon-cache/storage-aggregation.conf
	docker build -t $(REPO)/nav-carbon-cache carbon-cache

graphite-web:
	graphite-web; docker build -t $(REPO)/graphite-web graphite-web

syslog-ng:
	docker build -t $(REPO)/syslog-ng syslog-ng

#push:
#	docker push $(REPO)/nav:latest
#	docker push $(REPO)/nav:$(nav_version)
#	docker push $(REPO)/nav-carbon-cache
#	docker push $(REPO)/graphite-web
#	docker push $(REPO)/syslog-ng

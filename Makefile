REPO := mbrekkevold
uid := $(shell id -u)
nav_version := 5.0.4

.PHONY: navbuild nav carbon-cache graphite-web push

all: nav carbon-cache graphite-web

nav:
	docker build -t $(REPO)/nav .
	docker tag $(REPO)/nav:latest $(REPO)/nav:$(nav_version)

carbon-cache:
	docker build -t $(REPO)/nav-carbon-cache carbon-cache

graphite-web:
	graphite-web; docker build -t $(REPO)/graphite-web graphite-web

push:
	docker push $(REPO)/nav:latest
	docker push $(REPO)/nav:$(nav_version)
	docker push $(REPO)/nav-carbon-cache
	docker push $(REPO)/graphite-web

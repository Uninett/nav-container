REPO := mbrekkevold
BUILDIMAGE := navbuild
uid := $(shell id -u)

.PHONY: nav carbon-cache graphite-web push

all: nav carbon-cache graphite-web

nav:
	docker build -f Dockerfile.build -t "$(BUILDIMAGE)" .
	docker run -ti --rm -v "$(CURDIR):/source" --cap-drop=all -u "$(uid)" "$(BUILDIMAGE)"
	docker build -t $(REPO)/nav .

carbon-cache:
	docker build -t $(REPO)/carbon-cache carbon-cache

graphite-web:
	graphite-web; docker build -t $(REPO)/graphite-web graphite-web

push:
	docker push $(REPO)/nav
	docker push $(REPO)/carbon-cache
	docker push $(REPO)/graphite-web

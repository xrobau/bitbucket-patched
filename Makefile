VERSION=7.21.0
PKG=bitbucket
PORT=7990
SSHPORT=7999
DEBUGPORT=7991
FILE=atlassian-$(PKG)-$(VERSION)-x64.bin
SRCURL=https://product-downloads.atlassian.com/software/stash/downloads/$(FILE)

ARGS=--build-arg VERSION=$(VERSION) --build-arg FILE=$(FILE) --build-arg SRCURL=$(SRCURL) --build-arg PKG=$(PKG)

VOLUMES=-v $(shell pwd)/debug:/usr/local/debug -v /usr/local/$(PKG):/var/atlassian/$(PKG)

ENVS=-e "PROXY_NAME=git.xrob.au" -e "PROXY_PORT=443" -e "PROXY_SCHEME=https"

.PHONY: help
help: setup
	@echo "Run 'make build' to create the patched $(PKG)"
	@echo "Run 'make start' to start it. If you are prompted for a licence,"
	@echo "use your existing licence."
	@echo ""
	@echo "  ** Note that you MUST HAVE AN EXISTING LICENCE! **"
	@echo ""

.PHONY: setup
setup: /usr/local/$(PKG)

/usr/local/$(PKG):
	mkdir $@
	chmod 777 $@

.PHONY: start
start: .docker_build
	@[ "$(shell docker ps -q -f name=$(PKG))" ] && echo "$(PKG) already running" || docker run -d $(VOLUMES) --publish=$(PORT):$(PORT) --publish $(SSHPORT):$(SSHPORT) $(ENVS) --name $(PKG) $(PKG):$(VERSION)
	docker logs -f $(PKG)

.PHONY: stop
stop:
	docker rm -f $(PKG) || :

.PHONY: build
build: .docker_build

.docker_build: setup $(wildcard docker/*)
	docker build --tag $(PKG):$(VERSION) $(ARGS) docker/
	touch $@

.PHONY: shell
shell: start
	docker exec -it --user=0 $(PKG) /bin/bash

debug: stop .docker_build
	docker run -it --user=0 --rm --publish=$(DEBUGPORT):$(DEBUGPORT) --name $(PKG)-debug $(PKG):$(VERSION) /bin/bash


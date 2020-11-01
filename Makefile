.DEFAULT_GOAL := warning
.PHONY: warning

tag ?= $(shell test -f .cache/tag && cat .cache/tag || echo 'ns0')
tld ?= $(shell test -f .cache/tld && cat .cache/tld || echo 'docker')
name ?= $(shell test -f .cache/name && cat .cache/name || echo '${tag}')

install: warning
	@sudo -H pip3 install -r requirements.txt
	@./bin/docker-dns install -t "$(tag)" -d "$(tld)" -n "$(name)"

uninstall: warning
	@./bin/docker-dns uninstall

show-domain: warning
	@./bin/docker-dns show-domain

tunnel: warning
	@./bin/docker-dns tunnel

warning:
	@echo "\nWARNING: Deprecated Makefile usage, please use \"./bin/docker-dns\" command\n"
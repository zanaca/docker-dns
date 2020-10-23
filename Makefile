.DEFAULT_GOAL := warning
.PHONY: warning

tag ?= $(shell test -f .cache/tag && cat .cache/tag || echo 'ns0')
tld ?= $(shell test -f .cache/tld && cat .cache/tld || echo 'docker')
name ?= $(shell test -f .cache/name && cat .cache/name || echo '${tag}')

install: warning
	@./src/__main__.py install -t "$(tag)" -d "$(tld)" -n "$(name)" 

uninstall: warning
	@./src/__main__.py uninstall

show-domain: warning
	@./src/__main__.py show-domain

tunnel: warning
	@./src/__main__.py tunnel

warning:
	@echo "\nWARNING: Deprecated Makefile usage, please use \"./docker-dns\" command\n"
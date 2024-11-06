SHELL := /bin/bash

NOW := $(shell date +%m%d-%H%M%S)
DATE ?= $(NOW)

ISSUE := 1

GIT_DIR   := ~/webapp
APP_NAME  := isucondition.go
APP_DIR   := $(GIT_DIR)/go
BUILD_CMD := go build
BENCH_DIR := ~/bench
BENCH_CMD := ./bench -all-addresses 127.0.0.11 -target 127.0.0.11:443 -tls -jia-service-url http://127.0.0.1:4999
# ./bench -all-addresses 127.0.0.11 -target 127.0.0.11:3000 -jia-service-url http://127.0.0.1:4999

ALP_MATCH := '^/api/condition/[0-9a-f\-]+$$','^/api/isu/[0-9a-f\-]+$$','^/api/isu/[0-9a-f\-]+/graph$$','^/api/isu/[0-9a-f\-]+/icon$$','^/isu/[0-9a-f\-]+$$','^/isu/[0-9a-f\-]+/condition$$','^/isu/[0-9a-f\-]+/graph$$'
ALP_OPTS ?= # -q --qs-ignore-values --limit 10000

NGINX_ACCESS_LOG := /var/log/nginx/access
NGINX_ERROR_LOG := /var/log/nginx/error
NGINX_CONF := /etc/nginx/nginx.conf
NGINX_SITES_AVAIL := /etc/nginx/sites-available

DB_MIDDLE ?= mariadb
SLOW_QUERY_LOG := /var/log/mysql/$(DB_MIDDLE)-slow
MYSQL_ERROR_LOG := /var/log/mysql/error
MARIADBD_CONF := /etc/mysql/mariadb.conf.d/50-server.cnf
MYSQLD_CONF := /etc/mysql/mysql.conf.d/mysqld.cnf

.PHONY: conf/backup conf/nginx/deploy conf/mariadb/deploy rotate truncate build restart prepare bench/before bench bench/after alp slp issue

all: bench bench/after
bench/after: alp slp issue

conf/backup:
	mkdir -p $(GIT_DIR)/etc/{nginx/sites-available,mysql/mariadb.conf.d}
	cp {,$(GIT_DIR)}$(NGINX_CONF)
	cp $(NGINX_SITES_AVAIL)/*.conf $(GIT_DIR)$(NGINX_SITES_AVAIL)/
	cp {,$(GIT_DIR)}$(MARIADBD_CONF)
    # cp {,$(GIT_DIR)}$(MYSQLD_CONF)

conf/nginx/deploy:
	sudo cp $(NGINX_CONF){,.$(DATE)}
	sudo cp {$(GIT_DIR),}$(NGINX_CONF)
	sudo cp -r $(NGINX_SITES_AVAIL){,.$(DATE)}
	sudo cp $(GIT_DIR)$(NGINX_SITES_AVAIL)/*.conf $(NGINX_SITES_AVAIL)/

conf/mariadb/deploy:
	sudo cp -p $(MARIADBD_CONF){,.$(DATE)}
	sudo cp -p {$(GIT_DIR),}$(MARIADBD_CONF)
    # sudo cp -p $(MYSQLD_CONF){,.$(DATE)}
    # sudo cp -p {$(GIT_DIR),}$(MYSQLD_CONF)

rotate:
	sudo mv $(NGINX_ACCESS_LOG){,-$(DATE)}.log
	sudo mv $(NGINX_ERROR_LOG){,-$(DATE)}.log
	sudo mv $(SLOW_QUERY_LOG){,-$(DATE)}.log
	sudo mv $(MYSQL_ERROR_LOG){,-$(DATE)}.log

truncate:
	sudo truncate -s0 -c $(NGINX_ACCESS_LOG).log $(NGINX_ERROR_LOG).log $(SLOW_QUERY_LOG).log $(MYSQL_ERROR_LOG).log
    # mysqladmin flush-logs

build:
	cd $(APP_DIR) && $(BUILD_CMD)
	sudo systemctl restart $(APP_NAME)

restart:
	sudo systemctl restart $(DB_MIDDLE)
	sudo systemctl restart nginx
	# sudo systemctl restart datadog-agent
    # sudo systemctl restart memcached

prepare:
	mkdir -p ~/logs

bench: prepare truncate build restart
	cd $(BENCH_DIR); \
	$(BENCH_CMD) \
	> >(tee ~/logs/bench-$(DATE).log) \
	2> >(tee ~/logs/bench-error-$(DATE).log >&2)

alp: prepare # avg, sum
	sudo alp json --file $(NGINX_ACCESS_LOG).log \
	$(ALP_OPTS) --sort avg -r \
	-m $(ALP_MATCH) | \
	tee ~/logs/alp-$(DATE).log

slp: prepare
	sudo pt-query-digest $(SLOW_QUERY_LOG).log \
	| tee ~/logs/pt-query-digest-$(DATE).log

issue:
	(cd $(APP_DIR); git rev-parse HEAD; \
	echo "<details><summary>Bench</summary>"; echo -e "\n\`\`\`"; cat ~/logs/bench-$(DATE).log; echo "\`\`\`"; echo "</details>"; \
	echo "<details><summary>Bench error</summary>"; echo -e "\n\`\`\`"; cat ~/logs/bench-error-$(DATE).log; echo "\`\`\`"; echo "</details>"; \
	echo "<details><summary>alp</summary>"; echo -e "\n\`\`\`"; cat ~/logs/alp-$(DATE).log; echo "\`\`\`";  echo "</details>"; \
	echo "<details><summary>NGINX error</summary>"; echo -e "\n\`\`\`"; sudo cat $(NGINX_ERROR_LOG).log; echo "\`\`\`"; echo "</details>"; \
	echo "<details><summary>MySQL error</summary>"; echo -e "\n\`\`\`"; sudo cat $(MYSQL_ERROR_LOG).log; echo "\`\`\`";  echo "</details>"; \
	echo "<details><summary>App error</summary>"; echo -e "\n\`\`\`"; sudo journalctl -u $(APP_NAME) --since "$$(systemctl show $(APP_NAME) -p ActiveEnterTimestamp | cut -d= -f2)" --no-pager -p err; echo "\`\`\`"; echo "</details>"; \
	) | \
	gh issue comment $(ISSUE) -F-
	# echo "<details><summary>Slow query</summary>"; echo -e "\n\`\`\`"; cat ~/logs/pt-query-digest-$(DATE).log; echo "\`\`\`";  echo "</details>"; \
	# echo "<details><summary>App error</summary>"; echo -e "\n\`\`\`"; sudo journalctl -u $(APP_NAME) --since "$$(systemctl show $(APP_NAME) -p ActiveEnterTimestamp | cut -d= -f2)" --no-pager -o json | jq -r .MESSAGE | jq -R 'fromjson? | select(.error != "")'; echo "\`\`\`"; echo "</details>"; \
    # TODO

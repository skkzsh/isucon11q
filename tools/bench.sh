#!/bin/bash
set -euvx

sudo truncate -s 0 -c /var/log/nginx/access.log
sudo truncate -s 0 -c /var/log/nginx/error.log
sudo truncate -s 0 -c /var/log/mysql/mariadb-slow.log
sudo truncate -s 0 -c /var/log/mysql/error.log
# mysqladmin flush-logs

cd /home/isucon/webapp/go
go build -o isucondition main.go
sudo systemctl restart isucondition.go

sudo systemctl restart jiaapi-mock
sudo systemctl restart mysql
sudo systemctl restart nginx

mkdir -p ~/logs

cd ~/bench
./bench -all-addresses 127.0.0.11 -target 127.0.0.11:443 -tls -jia-service-url http://127.0.0.1:4999 |
	tee ~/logs/bench-$(date +%Y%m%d-%H%M%S).log

sudo cat /var/log/nginx/access.log |
	alp json --sort avg -r -m '^/api/condition/[0-9a-f\-]+$','^/api/isu/[0-9a-f\-]+$','^/api/isu/[0-9a-f\-]+/graph$','^/api/isu/[0-9a-f\-]+/icon$','^/isu/[0-9a-f\-]+$','^/isu/[0-9a-f\-]+/condition$','^/isu/[0-9a-f\-]+/graph$' |
	tee ~/logs/alp-$(date +%Y%m%d-%H%M%S).log
# -q --qs-ignore-values 

# sudo mysqldumpslow /var/log/mysql/mariadb-slow.log | tee ~/logs/slow-$(date +%Y%m%d-%H%M%S).log
# sudo pt-query-digest /var/log/mysql/mariadb-slow.log | tee ~/logs/pt-query-digest-$(date +%Y%m%d-%H%M%S).log

# go tool pprof -http=:10060 http://localhost:6060/debug/pprof/profile


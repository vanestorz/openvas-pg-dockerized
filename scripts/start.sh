#!/bin/bash

echo "Starting OpenVAS..."

service postgresql start 
echo "[PostgreSQL] Wait until postgresql is ready..."
sleep 1
until grep "database system is ready to accept connections" /var/log/postgresql/postgresql-9.5-main.log
do
        echo "[PostgreSQL] Waiting for PostgreSQL to start..."
        sleep 2
done

redis-server /etc/redis/redis.conf
sleep 1

cd /usr/local/sbin

echo "Starting OpenVAS Scanner..."
openvassd
sleep 8

echo "Starting GSAD Service..."
gsad --listen=0.0.0.0 --port=4000

echo "Starting OpenVAS Manager..."
openvasmd
sleep 5

echo "Checking Setup..."
/openvas/openvas-check-setup --v9 --server
echo "Done."

echo "Finished startup"

tail -f /usr/local/var/log/openvas/*
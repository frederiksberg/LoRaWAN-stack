#!/bin/bash

set -e

# Using timescaledb tuning tool to improve postgres performance
timescaledb-tune --conf-path=/var/lib/postgresql/data/postgresql.conf --quiet --yes --dry-run >> /var/lib/postgresql/data/postgresql.conf

# Load updated config
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    SELECT pg_reload_conf();
EOSQL
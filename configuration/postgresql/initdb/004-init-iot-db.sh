#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    create role iot with login password 'YourPassword';
    create role grafanareader with login password 'YourPassword';
    create database iot with owner iot;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "iot" <<-EOSQL
    create extension postgis;
    create extension timescaledb;
EOSQL
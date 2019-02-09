# LoRaWAN stack Docker setup

This repository contains a skeleton setting up the [LoRa Server](https://www.loraserver.io), [PostgreSQL](https://www.postgresql.org), [Node-RED](https://nodered.org) and [Grafana](https://grafana.com)
project using [docker-compose](https://docs.docker.com/compose/).

**Note:** Please use this `docker-compose.yml` file as a starting point for testing
but keep in mind that for production usage it might need modifications. 

## Directory layout

* `docker-compose.yml`: the docker-compose file containing the services
* `configuration/lora*`: directory containing the LoRa Server configuration files, see:
    * https://www.loraserver.io/lora-gateway-bridge/install/config/
    * https://www.loraserver.io/loraserver/install/config/
    * https://www.loraserver.io/lora-app-server/install/config/
    * https://www.loraserver.io/lora-geo-server/install/config/
* `configuration/postgresql/initdb/`: directory containing PostgreSQL initialization scripts
* `data/postgresql`: directory containing the PostgreSQL data (auto-created)
* `data/redis`: directory containing the Redis data (auto-created)
* `data/grafana`: directory containing the Grafana data (auto-created)
* `data/nodered`: directory containing the Node-RED data (auto-created)


## Configuration

### LoRa Server
The LoRa Server components are pre-configured to work with the provided
`docker-compose.yml` file and defaults to the EU868 LoRaWAN band. Please refer
to the `configuration/loraserver/loraserver.toml` configuration file to
configure a different band.
### Grafana
Add plugins to Grafana in `docker-compose.yml` under  `GF_INSTALL_PLUGINS`. here's available plugins: https://grafana.com/plugins
### PostgreSQL
The DB needs a bit of tuning to increase performance which is automatically done by [`timescaledb-tune`](https://docs.timescale.com/v1.2/getting-started/configuring) here: `configuration/postgresql/initdb/005-postgresql-tuning.sh`


## Requirements

Before using this `docker-compose.yml` file, make sure you have [Docker](https://www.docker.com/community-edition)
installed.

## Security
In order to secure the stack following passwords need to be changed before running `dokcer-compose up`:
* `postgres` PostgreSQL user here: `docker-compose.yml`
* `iot` PostgreSQL user here: `configuration/postgresql/initdb/004-init-iot-db.sh`
* Grafana readonly PostgreSQL user here: `configuration/postgresql/initdb/004-init-iot-db.sh`
* Grafana admin user: `docker-compose.yml`
* Node-RED users: https://nodered.org/docs/security

TODO:
* HTTPS
* Default Node-RED auth 

## Usage

To start all the LoRaWAN stack components, simply run:

```bash
$ docker-compose up
```

**Note:** during the startup of services, it is normal to see the following errors:

* ping database error, will retry in 2s: dial tcp 172.20.0.4:5432: connect: connection refused
* ping database error, will retry in 2s: pq: the database system is starting up


After all the components have been initialized and started, you should be able
to open http://localhost:8080/ (LoRa Server), http://localhost:3000/ (Grafana) and http://localhost:1880/ (Node-RED) in your browser.

### Add network-server

When adding the network-server in the LoRa App Server web-interface
(see [network-servers](https://www.loraserver.io/lora-app-server/use/network-servers/)),
you must enter `loraserver:8000` as the network-server `hostname:IP`.

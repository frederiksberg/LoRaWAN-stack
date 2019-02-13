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

## Persistent storage
Docker volumes are used for persistent storage of data from the different apps and are defined in `docker-compose.yml`

* `postgresql-data`: volume containing the PostgreSQL data
* `redis-data`: volume containing the Redis data
* `grafana-data`: volume containing the Grafana data
* `nodered-data`: volume containing the Node-RED data


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
* Grafana `admin` user: `docker-compose.yml`
* Node-RED [enable admin auth](https://nodered.org/docs/security): `data/nodered/settings.js` (Currently needs to be done after `docker-compose up` and entails `docker restart nodered`)

TODO:
* HTTPS
* Default Node-RED auth 

## Usage

When configuration and security steps are done start all the LoRaWAN stack components by simply running:

```bash
$ docker-compose up
```

**Note:** during the startup of services, it is normal to see the following errors:

* ping database error, will retry in 2s: dial tcp 172.20.0.4:5432: connect: connection refused
* ping database error, will retry in 2s: pq: the database system is starting up


After all the components have been initialized and started, you should be able
to open http://localhost:8080/ (LoRa Server), http://localhost:3000/ (Grafana) and http://localhost:1880/ (Node-RED) in your browser.

## Getting started
### First gateway and device on Lora Server
Here's a tutorial for setteing up [first gateway and device](https://www.loraserver.io/guides/first-gateway-device/)

#### Add network-server
When adding the network-server in the LoRa App Server web-interface
(see [network-servers](https://www.loraserver.io/lora-app-server/use/network-servers/)),
you must enter `loraserver:8000` as the network-server `hostname:IP`.

### First timeseries table in PostgreSQL
TimescaleDB is used to handle large reading and writing of data.
```sql
CREATE TABLE water_level (
	ts timestamptz NOT null,
	pressure float NOT NULL,
	temperature float NOT NULL,
	battery float NOT NULL,
	device_id int4 NULL
);

-- Create the hypertable
SELECT create_hypertable('water_level', 'ts');
```

### First flow in Node-RED
We will create a flow which takes device data from Lora server and writes the data to table in PostgreSQL. In order to read and write data to PostgreSQL, we can make use of the [node-red-contrib-postgres](https://flows.nodered.org/node/node-red-contrib-postgres) nodes, which can be installed under Manage palette in the top left menu. From here we need to:
1. Get data from Lora server.
* Make sure to register a new HTTP integration for the Application on Lora server and point the Uplink data url to `http://nodered:1880/<nodered-http-endpoint>`
2. Prepare data for table insert in postgres.
3. Write the data to the database.

You can simply refer to `postgresql` as the host when setting up the connection details in the postgres node.

Here's a bit of flow inspiration, which can easily be imported to yout Node-RED in the top left menu:
```json
[{"id":"a7bcd21.0d4a33","type":"http in","z":"1914bc60.4cc104","name":"","url":"/iot/gps","method":"post","upload":false,"swaggerDoc":"","x":110,"y":60,"wires":[["880cbd3e.d8045","32d5646a.05929c"]]},{"id":"23f16f1d.91b9f","type":"template","z":"1914bc60.4cc104","name":"format query","field":"payload","fieldType":"msg","format":"handlebars","syntax":"mustache","template":"insert into gps(time, latitude, longitude, altitude, temperature, battery) \nvalues (to_timestamp($time/1000.0), $latitude, $longitude, $altitude, $temperature, $battery)","x":490,"y":60,"wires":[["da29f2e3.cec04","590fc4ed.76e5cc"]]},{"id":"880cbd3e.d8045","type":"function","z":"1914bc60.4cc104","name":"setup params","func":"var data = msg.payload.object\n\n\nmsg.queryParameters = msg.queryParameters || {};\nmsg.queryParameters.time = data.timestamp;\nmsg.queryParameters.latitude = data.latitude;\nmsg.queryParameters.longitude = data.longitude;\nmsg.queryParameters.altitude = data.altitude; \nmsg.queryParameters.temperature = data.temperature;    \nmsg.queryParameters.battery = data.battery;\n\n\n\n\nreturn msg;","outputs":1,"noerr":0,"x":300,"y":60,"wires":[["23f16f1d.91b9f"]]},{"id":"da29f2e3.cec04","type":"postgres","z":"1914bc60.4cc104","postgresdb":"17235061.c3afa","name":"iot db","output":false,"outputs":0,"x":650,"y":60,"wires":[]},{"id":"590fc4ed.76e5cc","type":"debug","z":"1914bc60.4cc104","name":"","active":false,"tosidebar":true,"console":false,"tostatus":false,"complete":"payload","x":670,"y":100,"wires":[]},{"id":"32d5646a.05929c","type":"http response","z":"1914bc60.4cc104","name":"","statusCode":"200","headers":{},"x":280,"y":100,"wires":[]},{"id":"17235061.c3afa","type":"postgresdb","z":"","hostname":"postgresql","port":"5432","db":"iot","ssl":false}]
```

### First dashboard in Grafana
1. Add PostgreSQL datasource. Hostname is `postgresql` and it is reommendeed to use the `grafanareader` read only user.
2. Create a new dashboard and add a Graph panel.
3. Edit panel and make sure `grafanareader` has privileges to read from the  table.
4. Under `Metrics` pane it is possible to query the table using a Query Builder or plain SQL. Grafana needs time and metric column in order to generate the gragh.

## References
* [TimescaleDB](https://docs.timescale.com/v1.2/main)
* [Node-RED](https://nodered.org/docs/)
* [Grafana](http://docs.grafana.org/)
* [Lora Server](https://www.loraserver.io/overview/)

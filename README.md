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

## Getting started
### First gateway and device on Lora Server
Here's a tutorial for setteing up [first gateway and device](https://www.loraserver.io/guides/first-gateway-device/)
### First flow in Node-RED
We will create a flow which takes device data from Lora server and writes the data to table in PostgreSQL. In order to read and write data to PostgreSQL, we can make use of the [node-red-contrib-postgres](https://flows.nodered.org/node/node-red-contrib-postgres) nodes, which can be installed under Manage palette in the top left menu. From here we need to:
* Get data from Lora server.
* Prepare data for table insert in postgres.
* Write the data to the database.

You can simply refer to `postgresql` as the host when setting up the connection details in the postgres node.

Here's a bit of flow inspiration, which can easily be imported to yout Node-RED in the top left menu:
```json
[{"id":"a6f64345.dd68d","type":"template","z":"685dbfc9.ddad2","name":"format query","field":"payload","fieldType":"msg","format":"handlebars","syntax":"mustache","template":"insert into water_level(ts, pressure, temperature, battery, device_id) \nvalues ($ts, $pressure, $temperature, $battery, $device_id)","x":810,"y":60,"wires":[["667e4583.b1377c","8163b867.624158"]]},{"id":"ac011bc7.a8ec18","type":"function","z":"685dbfc9.ddad2","name":"setup params","func":"var data = msg.payload\n\n\nmsg.queryParameters = msg.queryParameters || {};\nmsg.queryParameters.ts = new Date(data.ts).toISOString();\nmsg.queryParameters.pressure = data.pressure;\nmsg.queryParameters.temperature = data.temperature;\nmsg.queryParameters.battery = data.battery;\nmsg.queryParameters.device_id = data.device_id;    \n\n\n\n\nreturn msg;","outputs":1,"noerr":0,"x":640,"y":60,"wires":[["a6f64345.dd68d"]]},{"id":"667e4583.b1377c","type":"postgres","z":"685dbfc9.ddad2","postgresdb":"9f412736.e4a068","name":"iot db","output":false,"outputs":0,"x":970,"y":60,"wires":[]},{"id":"a8772bf2.505278","type":"function","z":"685dbfc9.ddad2","name":"decode payload","func":"var data = msg.data\n\nvar ts = msg.ts\nvar pressure = (parseInt(data.slice(10,14), 16)/16384)/32768;\nvar temp = (parseInt(data.slice(14,18), 16)-384)/64000*200-50;\nvar battery = parseInt(data.slice(18,22), 16)/1000;\nvar device_id = parseInt(data.slice(2,6), 16);\n\nmsg.payload = {\n    ts: ts,\n    pressure: pressure,\n    temperature: temp,\n    battery: battery,\n    device_id : device_id\n};\n\n\nreturn msg;","outputs":1,"noerr":0,"x":460,"y":60,"wires":[["ac011bc7.a8ec18"]]},{"id":"37f2d02.354b63","type":"websocket in","z":"685dbfc9.ddad2","name":"water level loriot","server":"9e15ab1b.7bd928","client":"","x":100,"y":60,"wires":[["1a0d8e61.868ed2"]]},{"id":"8163b867.624158","type":"debug","z":"685dbfc9.ddad2","name":"","active":true,"tosidebar":true,"console":false,"tostatus":false,"complete":"payload","x":990,"y":100,"wires":[]},{"id":"1a0d8e61.868ed2","type":"switch","z":"685dbfc9.ddad2","name":"only 'rx' payload","property":"cmd","propertyType":"msg","rules":[{"t":"eq","v":"rx","vt":"str"}],"checkall":"true","repair":false,"outputs":1,"x":280,"y":60,"wires":[["a8772bf2.505278"]]},{"id":"9f412736.e4a068","type":"postgresdb","z":"685dbfc9.ddad2","hostname":"postgresql","port":"5432","db":"iot","ssl":false},{"id":"9e15ab1b.7bd928","type":"websocket-listener","z":"","path":"wss://iotnet.teracom.dk/app?token=YourTOKEN","wholemsg":"true"}]
```

### First dashboard in Grafana
Add datasource
`grafanareader` read only user
### First timeseries table in PostgreSQL

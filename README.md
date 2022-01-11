# nuodb-compose #
Docker compose files for starting a nuodb database on the local host.

These docker compose files will create:
* a new docker network specifically for this database;
* separate AP (admin), TE, and SM containers - one for each NuoDB process;
* a separate CD (collector) container for each engine container - to enable NuoDB Insights;
* influxdb and grafana containers to host the NuoDB Insights dashboards.

Note that the container names will have the `project` name embedded - which is the name of the directory (`nuodb`), or set with the `-p` option to `docker-compose`.

# Instructions #
## Creating the database ##
0. clone the repo.

1. cd to the `nuodb` directory.

2. copy the `env-default` file to `.env` (this step is _NOT_ optional).

3. edit the `.env` file:
   - if you want to use a specific SQL engine - for example `scalar` - you will need an image that supports that engine;
   - if you want to access the database from outside the `docker network` - for example from an app running direcly on the local host - then set `EXTERNAL_ADDRESS`;
     - either in the `.env` file, _or_ by setting `EXTERNAL_ADDRESS` on the `docker-compose up` command-line;
   - if you want to import initial state from a database backup into the new database, set `IMPORT_SOURCE` to a path
     on the _local_ machine. The SM container will mount this file as a volume and extract (`untar`) it into the
     archive dir prior to starting the SM process;
     - this is only done only when the archive dir is _empty_ - so the SM container can be stopped and restarted without being reinitialised.
     - if you have set `IMPORT_SOURCE` _and_ it is a large file that takes multiple minutes to extract, you _will_ need to
        set `STARTUP_TIMEOUT` to a larger value, to stop the startup from timing out before the IMPORT has completed.

4. create and start the nuodb database with `docker-compose up -d`.

## Stopping the database ##
1. To stop all containers, but retain all stored state including the database contents:
  - cd to the `nuodb` directory;
  - execute `docker-compose down`

2. To restart a stopped database - complete with the database contents:
  - cd to the `nuodb` directory;
  - execute `docker-compose start`.

## Deleting the database and all its storage ##
1. To stop all containers, and delete all resources - including the stored state and database contents:
  - cd to the `nuodb` directory;
  - execute `docker-compose down`.

## Notes ##
1. You can specify env vars on the command-line in linux or MacOS, by setting them _before_ the `docker-compose` command.
- Ex: `$ IMPORT_SOURCE=./mydb.bak.tgz STARTUP_TIMEOUT=300 docker-compose up -d`

## What could possibly go wrong?? ##

1. If you get an error in the form:
```
    WARNING: The NUODB_IMAGE variable is not set. Defaulting to a blank string.
    WARNING: The PEER_ADDRESS variable is not set. Defaulting to a blank string.
    WARNING: The IMPORT_SOURCE variable is not set. Defaulting to a blank string.
    ...
    ERROR: Couldn't find env file: /a/b/c/nuodb/.env
  ```
- then you have most likely forgotten to copy the `env-default` file to `.env`;
- or (less popular) create your own `.env` file from scratch.

2. If an error causes only part of the database to be deployed, you can start the remaining containers - after fixing the error - by simply running `docker-compose up -d` again. The `up` command only starts those containers that are missing.

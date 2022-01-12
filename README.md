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
     - set to the address of the local host machine (Ex `192.168.0.123`);
     - on some platforms, setting `EXTERNAL_ADDRESS` to `127.0.0.1` also works;
   - if you want to import initial state from a database backup into the new database, set `IMPORT_LOCAL` and/or `IMPORT_REMOTE` (see `Notes` below for details of `IMPORT_LOCAL` and `IMPORT_REMOTE`);
      - the `import` operation is only performed when the archive dir is _empty_ - so the SM container can be stopped and restarted without being reinitialised each time.
     - if you have set `IMPORT_LOCAL` or `IMPORT_REMOTE` _and_ it is a large file that takes multiple minutes to extract, you _will_ need to
        set `STARTUP_TIMEOUT` to a larger value, to stop the startup from timing out before the IMPORT has completed.

4. create and start the nuodb database with `docker-compose up -d`.

## Stopping the database ##
1. To stop all containers, but retain all stored state including the database contents:
  - cd to the `nuodb` directory;
  - execute `docker-compose stop`

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

2. the `docker-compose` command may suggest to you to use `docker compose` instead.
Don't - it doesn't work.

3. the initial state of the database can be imported using `IMPORT_LOCAL` and/or `IMPORT_REMOTE`, as follows:
- set `IMPORT_LOCAL` to a path on the _local_ machine.
  The SM container will mount this file as a volume and extract (`untar`) it into the
  archive dir prior to starting the SM process;
- set `IMPORT_REMOTE` to a URL of a remote file hosted on a server - typically accessed through `http(s)` or `(s)ftp`.
  The SM container will download the file via the URL and extract it into
  the archive dir prior to starting the SM process.
- if you set _both_ `IMPORT_LOCAL` _and_ `IMPORT_REMOTE`, then `IMPORT_REMOTE` is treated as the remote copy, and `IMPORT_LOCAL` is treated as a locally cached copy - hence the behaviour is as follows:
  - if `IMPORT_LOCAL` is a `file` _and_ is non-empty, then it is used directly, and `IMPORT_REMOTE` is ignored;
  - if `IMPORT_LOCAL` is a file _and_ is `empty`, then `IMPORT_REMOTE` is downloaded into `IMPORT_LOCAL`, and the `import` is then performed from `IMPORT_LOCAL`;
  - if `IMPORT_LOCAL` does _not_ exist - or is _not_ a file (ex a `directory`), then it is ignored, and the archive is imported directly from `IMPORT_REMOTE`.

  _*NOTE:*_ To cause the initial download from `IMPORT_REMOTE` to be cached in `IMPORT_LOCAL`, `IMPORT_LOCAL` _must_ exist _and_ be empty.
  To ensure this, you can do something like the following:
    - `$ rm -rf a/b/c`
    - `$ touch a/b/c`
    
    Now you can set `IMPORT_LOCAL` to be `a/b/c`.

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
- or (less popular) not created your own `.env` file from scratch.

2. If you get one or more warnings of the form:
```
    WARNING: The <xyz> variable is not set. Defaulting to a blank string.
```
  - but NO ERROR, then you probably need to update your `.env` file.
  - Do a `diff` of `.env` vs `env-default`, and look for new VARs defined in the latest `env-default`.

3. if you get an error of the form:
```
ERROR: for nuodb_nuocd-sm_1  Cannot start service nuocd-sm: container ... is not running
```
then check the logs of the `sm_1` container to see why it has failed to start.
To check the logs of any container, run `docker logs <name-of-container>`
Ex: `docker logs nuodb_sm_1`

4. If you get an error of the form:
```
host:/a/a/c is not a valid, non-empty file - import failed...
```
then you have probably set `IMPORT_LOCAL` to point to a non-existent file, or to a directory.

5. If an error causes only part of the database to be deployed, you can start the remaining containers - after fixing the error - by simply running `docker-compose up -d` again. The `up` command only starts those containers that are not currently running.


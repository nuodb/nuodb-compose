# nuodb-compose
Docker compose files for starting a nuodb database on the local host.

These docker compose files will create:
* a new docker network specifically for this database;
* separate AP (admin), TE, and SM containers for each NuoDB process;
* a separate CD (collector) container for each engine container - to enable NuoDB Insights;
* an influxdb and grafana container to host the NuoDB Insights dashboards.

Note that the container names will have the `project` name embedded - which is the name of the directory (`nuodb`), or set with the `-p` option to `docker-compose`.

# Instructions
0. clone the repo;
1. cd to the `nuodb` directory;
2. edit the `.env` file
   - if you want to use the a specific SQL engine, you will need an image that supports that engine;
   - if you want to access the database from outside the `docker network` then set `EXTERNAL_ADDRESS`
     -- either in the `.env` file, _or_ by setting `EXTERNAL_ADDRESS` on the `docker-compose up` command-line;
   - if you want to import initial state from a backup into the new database, set `IMPORT_SOURCE` to a path
     on the _local_ machine. The SM container will mount this file as a volume and extract (untar) it into the
     archive dir prior to starting the SM process;
     (only if the archive dir is empty - so the SM container can be stopped and restarted without being reinitialised.)
     -- if you have set `IMPORT_SOURCE` _and_ it is a large file that takes multiple minutes to extract, you _may_ need to
        set `STARTUP_TIMEOUT` to a larger value, to stop the starup from timeing our _before_ the IMPORT has completed.
3. create and start the nuodb database with `docker-compose up -d`;
4. stop and delete everything with `docker-compose down`;

To specify env vars on the command-line, specify them _before_ the `docker-compose` command.
Ex: `IMPORT_SOURCE=./mydb.bak.tgz STARTUP_TIMEOUT=300 docker-compose up -d`
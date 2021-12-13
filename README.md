# nuodb-compose
Docker compose files for starting a nuodb database on the local host.

These docker compose will create:
* a new docker network specifically for this database;
* separate AP (admin), TE, and SM containers for the NuoDB processes;
* a separate CD (collector) container for each engine container - to enable NuoDB Insights;
* an influxdb and grafana container to host the NuoDB Insights dashboards.

Note that the container names will have the `project` name embedded - which is the name of the directory (`nuodb`), or set with the `-p` option to `docker-compose`.

# Instructions
cd to the `nuodb` directory;
3. edit the `.env` file
   - if you want to use the a specific SQL engine, you will need an image that supports that engine;
   - if you want to access the database from outside the `docker network` then set `EXTERNAL_ADDRESS`
     -- either in the `.env` file, _or_ by setting `EXTERNAL_ADDRESS` on the `docker-compose up` command-line;
4. create and start the nuodb database with `docker-compose up -d`;
5. stop and delete everything with `docker-compose down`;

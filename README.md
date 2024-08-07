# nuodb-compose #

Docker compose files for starting a NuoDB database on your local host;

- and, optionally, initializing the database state from an existing NuoDB backup.

_NOTE:_ `docker compose` is intentionally a very simple tool - so the commands are more wordy than would be ideal; some desirable automation is just not possible; and some benign error messages are occasionally emitted.

## Use Cases ##

- Create a local NuoDB database in Docker on a developer's laptop;
- Create a local copy of an existing database for diagnostic purposes;
  - see the `IMPORT_LOCAL` and `IMPORT_REMOTE` options;
- Create a local copy of an existing database for UAT or testing purposes;
  - see the `IMPORT_LOCAL` and `IMPORT_REMOTE` options;
- Create a local database for testing versions, SQL, ...
- Create a simple multi-engine database on a single cloud node (VM);
- Create multiple local databases for testing different software versions of either NuoDB or an application.

## Configurations Supported ##

- `distributed` (default)
  - This is a database comprising a _separate_ container for each database process:
    - Separate AP (admin), TE, and SM containers - one for each NuoDB process;
    - This is the same topology used when NuoDB is deployed in production and under Kubernetes, but may be overkill for a local machine - especially a laptop.
- `distributed + insights`
  - This is a database comprising 3 separate containers for the database processes (as above), plus additional containers including `influxdb` and `grafana` to enable metrics publishing and display.
  - This is currently the _only_ configuration that supports NuoDB `Insights` monitoring.
- `monolith`
  - This is a database in a single container (monolith). All 3 NuoDB processes are running inside the same container.
    - This is _not_ how NuoDB is deployed in production, but is an easily managed, resource optimized, option on a local machine.
    - This is the simplest configuration for a developer to run a local DB for testing and debugging.
- `instadb`
  - This is a database in a single container (as per `monolith`) - but with _dynamic port mapping_.
    - This allows multiple `instadb` databases to run on the same host simultaneously.
    - The downside is that because of the dynamically-mapped ports, the mapped public port cannot be predicted, and so external connections (such as non-containerized applications running on the same computer) will need to use the `direct=true` connection property;
    - To ensure container name uniqueness, each `instadb` instance must be running in a different `project` from any other `instadb` instance.

These Docker compose files will create:

- A new Docker network specifically for the project;
- A database in one of 4 possible configurations (see above).

### Scaling a Database ##

A second TE can be added to a `distributed` database

- See the `scale-te2` profile.

Note that all container names will have the `project` name embedded, which is the name of the directory (`nuodb`), but you can override the project name using the `-p` option to `docker compose`.

- This default is fine for all configurations _except_ `instadb` databases (you can use the default for your first `instadb` database, but all subsequent databases must be named explicitly using `-p` to ensure unique container names).

## Instructions ##

### Getting Started ##

1. Clone this repo.

1. `cd` to the `nuodb` directory.

1. Copy the `env-default` file to `.env` (this step is _NOT_ optional).

1. If using NuoDB v6.0.2 or greater, acquire a NuoDB license file.
   - If you or your organisation do not have a valid NuoDB license file, contact NuoDB support to request one: NuoDB.Support...at...3ds.com.
   - Store your NuoDB license file somewhere on your local disk

1. Edit the `.env` file:
    - `ENGINE_MEM`
      - Sets the memory cache size for each TE and SM.
    - `SQL_ENGINE`:
      - If you want to use a specific SQL engine, such as `scalar` (the vector engine, `vee`, is the default). You will also need an image that supports that engine;
    - `EXTERNAL_ADDRESS`:
      - If you want to access the database from outside the `docker network` - for example from an app running directly on the local host - then set `EXTERNAL_ADDRESS`;
        - either in the `.env` file, _or_ by setting `EXTERNAL_ADDRESS` on the `docker compose up` command-line (Linux/MacOS) or by first setting `EXTERNAL_ADDRESS` as an environment variable (Windows);
        - set to the address of the local host machine (Ex `192.168.0.123`);
        - on some platforms, setting `EXTERNAL_ADDRESS` to `127.0.0.1` also works;
    - `LICENSE_PATH` :
      - If you have a valid NuoDB license file - per step #4 above - then set `LICENSE_PATH` to point to that file path.
        - Eg: `LICENSE_PATH=./nuodb.lic`
    - `IMPORT_LOCAL`, `IMPORT_REMOTE`, `IMPORT_TIMEOUT`, `IMPORT_AUTH`, `IMPORT_LEVEL`
      - If you want to import initial state from a database backup into the new database, set `IMPORT_LOCAL` and/or `IMPORT_REMOTE` (see `Notes` below for details of `IMPORT_LOCAL` and `IMPORT_REMOTE`);
        - the `import` operation is only performed when the archive dir is _empty_ - so the SM container can be stopped and restarted without being reinitialized each time.
        - if you have set `IMPORT_LOCAL` or `IMPORT_REMOTE` _and_ it is a large archive that takes multiple minutes to import, you _will_ need to
          set `IMPORT_TIMEOUT` to a value larger than the time taken to import - in order to stop the DB startup from timing out before the IMPORT has completed.

_NOTE:_ In earlier versions of `docker`, the `docker-compose` command was the only form that worked with `nuodb-compose`.
However, with newer versions of `docker` both `docker-compose` _and_ `docker compose` work. `docker-compose` is slated to be removed from the `docker` product.

### About Managing Databases ###

- A database is created using `docker compose ... up ...`;
  - NOTE: the `docker compose ... down` command will _destroy_ the database and all its storage. More on this below:
- A database can be `stopped` _WITHOUT_ deleting its storage:
  - `docker compose ... stop ...`;
- A stopped database can be `restarted` and will _CONTINUE_ using its previous existing storage:
  - `docker compose ... start ...`;
  - this is often needed after a host machine has been woken up after sleep/hibernation.
- A database that _was_ running, but has stopped for some environmental reason, can be `restarted` with a single command:
  - `docker compose ... restart`
  - for example, if the host machine was hibernated, and then re-awakened, the database will typically need to be `restarted`.
- A database is `deleted` _WITH_ its storage using:
  - `docker compose ... down`;
- A client app connects to a database by configuring a port on the host network - set with the variable `EXTERNAL_ADDRESS` - into its connection string/params;
  - example: `EXTERNAL_ADDRESS=192.167.0.123` if the local host's network address is `192.168.0.123`
  - example: `EXTERNAL_ADDRESS=localhost` if `docker` can resolve `localhost`.
- Because `docker compose` does not scope the Docker networks it creates to a particular file or profile, `docker compose ... down` may attempt to delete a network that is still in use by a different database.
  The error looks like the following, and can be ignored:

   ```text
    ⠿ Network nuodb_net          Error                                                                                                                                                0.0s
    failed to remove network df0df85905b1702fea9c1a20a1142b9f4ff85f07844087b520f072c8a6af5e68: Error response from daemon: error while removing network: network nuodb_net id df0df85905b1702fea9c1a20a1142b9f4ff85f07844087b520f072c8a6af5e68 has active endpoints
   ```

**WARNING:** In the following do not confuse `start` and `stop` with `up` and `down`.

- `docker up` is used to create the database container and start it running.
- You can stop and restart the container using `docker stop` and `docker start` - no database data will be lost.
- `docker down` _destroys_ the container and your database will be lost.

### Managing a `distributed` Database ###

_NOTE:_ the `distributed` database is the default configuration.

- `create` with: `docker compose up -d`
- `stop` (temporarily) all containers with: `docker compose stop`
  - this will _NOT_ delete the database storage;
- `restart` a stopped database with: `docker compose start`
- `stop` and `start` a database in limbo with `docker compose restart`
- `delete` - including storage - with `docker compose down`
- `connect` to a `distributed` database using the value of `EXTERNAL_ADDRESS` in the connection string.

#### Scaling Out a `distributed` Database ####

- To scale out a `distributed` database with a _second_ TE:
  - `docker compose --profile scale-te2 up -d`
- to scale in a `te2` on a `distributed` database:
  - `docker compose --profile scale-te2 stop`
- to delete a `distributed` database _plus_ its scaled-out `te2` in a single command:
  - `docker compose --profile scale-te2 down`

### Managing a `monolith` Database ###

_NOTE:_ the `monolith` topology must be specified explicitly by using `-f monolith.yaml`.

- `create` with: `docker compose -f monolith.yaml up -d`
- `stop` (temporarily) all containers with: `docker compose -f monolith.yaml stop`
  - this will _NOT_ delete the database storage;
- `restart` a stopped database with: `docker compose -f monolith.yaml start`
- `stop` and `start` a database in limbo with `docker compose -f monolith.yaml restart`
- `delete` - including storage - with `docker compose -f monolith down`
- `connect` to a `monolith` database using the value of `EXTERNAL_ADDRESS` in the connection string;
  - example connection string: `jdbc:com.nuodb://192/.168.0.123/demo`
  - example connection string: `jdbc:com.nuodb://localhost/demo`

### Managing an `instadb` Database ###

_NOTE:_ the `instadb` topology must be specified explicitly by using `-f instadb.yaml`.

- `create` with: `docker compose -f instadb.yaml up -d`
- `stop` (temporarily) all containers with: `docker compose -f instadb.yaml stop`
  - this will _NOT_ delete the database storage;
- `restart` a stopped database with: `docker compose -f instadb.yaml start`
- `stop` and `start` an instadb database in limbo with: `docker compose -f instadb.yaml restart`
- `delete` - including storage - with `docker compose -f instadb.yaml down`
- `connect` to an `instadb` by setting `direct=true` in the connection properties;
  - and setting the value of `EXTERNAL_ADDRESS:<mapped-port>` in the connection string;
    - where `<mapped-port>` is the public port mapped to port `48006` for that container.

**Port mapping example:**

Note that the TE is always on container (internal) port 48006

```sh
$ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS                                                                                                   NAMES
458760270ee7   nuodb/nuodb:5.0.0.2    "docker-entrypoint.s…"   6 minutes ago   Up 6 minutes   0.0.0.0:54587->8888/tcp, 0.0.0.0:54584->48004/tcp, 0.0.0.0:54585->48005/tcp, 0.0.0.0:54586->48006/tcp   nuodb-instadb-1

$ docker compose port instadb 48006
0.0.0.0:54586
```

In this example, to connect to the database (actually to its TE) use the value of `EXTERNAL_ADDRESS:54586` in the connection string (along with `direct=true`).

- Example connection string: `jdbc:com.nuodb://192.168.0.123:54586/demo?direct=true`
- Example connection string: `jdbc:com.nuodb://localhost:54586/demo?direct=true`

### Managing _Multiple_ `instadb` Databases ###

- `create` an additional `instadb` with: `docker compose -p <new-project-name> -f instadb.yaml up -d`
- `stop` (temporarily) all containers of a specific `instadb` with: `docker compose -p <project-name> -f instadb.yaml stop`
  - this will _NOT_ delete the database storage;
- `restart` a stopped database with: `docker compose -p <project-name> -f intadb.yaml start`
- `stop` and `start` an instadb in limbo with: `docker compose -p <project-name> -f instadb.yaml restart`
- `delete` - including storage - with `docker compose -p <project-name> -f instadb.yaml down`

## Importing Existing Data ##

The initial state of the database can be imported using `IMPORT_LOCAL` and/or `IMPORT_REMOTE`.

_NOTE:_ You can specify environment variables on the command-line on Linux or MacOS, by setting them _before_ the `docker compose` command.

- _Example:_ `$ IMPORT_LOCAL=./mydb.bak.tgz STARTUP_TIMEOUT=300 docker compose up -d`

Steps required:

- Set `IMPORT_LOCAL` to a path on the _local_ machine.
  The SM container will mount this path as a volume and import its contents into the archive dir prior to starting the SM process (presuming the archive is empty);

  The path that `IMPORT_LOCAL` points to can be one of:
  - a `tar.gzip` file of a `nuodb backup`;
  - a directory containing a `nuodb backup`.

  _Note:_ that a `nuodb backup` can come in one of two formats:
  - a nuodb `backup set` - which is the result of a `hotcopy --type full` backup;
  - a nuodb `archive` - which is the result of a `hotcopy --type simple`, or just a copy of an SM archive and journal copied while the SM is _NOT_ running.

  _Note:_ a `backupset` can only be imported from a directory.

- Set `IMPORT_REMOTE` to the URL of a remote `file` hosted on a server - typically accessed through `http(s)` or `(s)ftp`.
  - Example: `https://some.server.io/backup-4-3.tz`
  - Example: `sftp://sftp.some.domain.com/backup-4-3.tz`
  
  _Note:_ The SM container will download a `remote` file via the URL and extract it into the archive directory prior to starting the SM process.
- If you set _both_ `IMPORT_LOCAL` _and_ `IMPORT_REMOTE`, then `IMPORT_REMOTE` is treated as the remote source, and `IMPORT_LOCAL` is treated as a locally cached copy.
  Hence the behaviour is as follows:
  - If `IMPORT_LOCAL` is a _non-empty_ `file` or `directory`, then it is used directly, and `IMPORT_REMOTE` is ignored.
  - If `IMPORT_LOCAL` is an _empty_ `file` then `IMPORT_REMOTE` is downloaded into `IMPORT_LOCAL`, and the `import` is then performed by `extracting` from `IMPORT_LOCAL` into the `archive`;
    - note this _only_ works for a `tar.gzip` file of an `archive` (see above).
  - If `IMPORT_LOCAL` is an _empty_ `directory` then `IMPORT_REMOTE` is downloaded and extracted into `IMPORT_LOCAL`, and the `import` is then performed from `IMPORT_LOCAL` into the `archive`;
    - note this works for _both_ forms of `nuodb backup` (see above);
    - _Note:_ importing from a `directory` can be significantly _slower_ than importing (`extracting directly`) from a `tar.gzip` file.

  _Hence:_ To cause the initial download from `IMPORT_REMOTE` to be cached in `IMPORT_LOCAL`, `IMPORT_LOCAL` _must_ exist _and_ be empty.
  To ensure this, you can do something like the following:

  - `$ rm -rf a/b/c`
  - `$ touch a/b/c` or `mkdir -p /a/b/c`

    Now you can set `IMPORT_REMOTE` as needed, and set `IMPORT_LOCAL` to `a/b/c`.

## What Could Possibly Go Wrong?? ##

1. If you get an error in the form:

    ```text
    WARNING: The NUODB_IMAGE variable is not set. Defaulting to a blank string.
    WARNING: The PEER_ADDRESS variable is not set. Defaulting to a blank string.
    WARNING: The IMPORT_SOURCE variable is not set. Defaulting to a blank string.
    ...
    ERROR: Couldn't find env file: /a/b/c/nuodb/.env
    ```

    - then you have most likely forgotten to copy the `env-default` file to `.env`;
    - or (less popular) not created your own `.env` file from scratch.

2. If you get one or more warnings of the form:

    ```text
    WARNING: The <xyz> variable is not set. Defaulting to a blank string.
    ```

    - but NO ERROR, then you probably need to update your `.env` file.
    - Do a `diff` of `.env` vs `env-default`, and look for new VARs defined in the latest `env-default`.

3. If you get an error of the form:

    ```text
    ERROR: for nuodb_nuocd-sm_1  Cannot start service nuocd-sm: container ... is not running
    ```

    check the logs of the `sm_1` container to see why it has failed to start.
    - To check the logs of any container, run `docker logs <name-of-container>`
    - Example: `docker logs nuodb_sm_1`

4. If you get an error in the form:

    ```text
    IMPORT_REMOTE is not a valid URL: ... - import aborted
    ```

    then you have not set `IMPORT_REMOTE` to a valid URL.
    - URL is expected to be in the form: `<protocol>://<host>/<path>`
    - Example: `sftp://myhost.com/my-archives/backup-xyz.tar.gzip`

5. If you get an error in the form:

    ```text
    This database has <n> archives with no running SM.
    No new SMs can start while the database is in this state.
    ```

    then you have somehow restarted the database with existing archives but too few running SMs.
    - This could happen if an import has somehow failed after the initial import started, and you restart with `IMPORT_X` set.
    - This could also happen if an SM has shut down, and you try to restart it with `docker compose up`, but have accidentally set `IMPORT_X`.
    (You cannot attempt to import the database state if there is existing state in some archive - even if the SM for that archive is not currently running.)
    - Follow the instructions following the error message to resolve the problem(s), and then continue stating with:
    `... docker compose up -d`

6. If an error causes only part of a `distributed` database to be deployed, you can start the remaining containers - after fixing the error - by simply running `... docker compose up -d` again. The `up` command only starts those containers that are not currently running.
    - When running `... docker compose up` a subsequent time, you need to decide if you still need to set `IMPORT_X` variable(s):
      - you _DON'T_ need to if the database state has already been successfully imported;
      - you probably _DO_ need to if you had them set for the original `docker compose up` command, and the `import` has not yet succeeded.

7. If you get an error about being unable to delete a network because it has active end-points, you can normally safely ignore this.

    ```text
     ⠿ Network nuodb_net          Error                                                                                                                                                0.0s
    failed to remove network df0df85905b1702fea9c1a20a1142b9f4ff85f07844087b520f072c8a6af5e68: Error response from daemon: error while removing network: network nuodb_net id df0df85905b1702fea9c1a20a1142b9f4ff85f07844087b520f072c8a6af5e68 has active endpoints
    ```

    If you think that the network _should_ have been deleted, then run the `docker compose ... down` command once more.
    If the end-points have now been successfully deleted, the network delete will now succeed.

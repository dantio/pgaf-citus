# pg_auto_failover + citus Postgres image for docker swarm

* `postgresql-15-citus-11.2`
* `topn`
* `hll`
* `cron`


## Custom pg_hba.conf
Create `pgconf` folder and `postgresql.conf` file with content: `hba_file '/etc/pgaf/pg_hba.conf'`
Create `pg_hba.conf` inside `pgconf` with your custom config.

Mount the folder:
``` 
volumes:
- "./pgconf:/etc/pgaf"
```

## pg_hba.conf example

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust

# monitor
hostssl "pg_auto_failover" "autoctl_node" 10.0.0.0/8 trust

# coord
hostssl "citus" "citus" 10.0.0.0/8 trust
hostssl all "pgautofailover_monitor" 10.0.0.0/8 trust
hostssl all "pgautofailover_replicator" 10.0.0.0/8 trust
hostssl replication "pgautofailover_replicator" 10.0.0.0/8 trust # The "all" keyword does not match "replication"

# your app must be in same network
hostssl "app" "app" 10.0.0.0/8 trust

```

## Release
`npx standard-version`
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

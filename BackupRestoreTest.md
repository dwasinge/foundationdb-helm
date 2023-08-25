# Backup and Restore Test Process

## Initialize Project, Cluster, and Backup

```
./fdb_helper.sh init
```

## Wait for reconciliation to finish

```
./fdb_helper.sh cluster-status
```

## Check if Initial Backup Reconciliation Complete

```
./fdb_helper.sh controller-manager-logs
```

## Add data

```
./fdb_helper.sh add-data
```

## Check if Key Exists

```
./fdb_helper.sh check-key-exists
```

## Wait for Backup to finish

Not currently automated.

Steps:
* get current date
* run fdbbackup status
* `Last complete log version and timestamp` should be after current date above

## Stop backup

```
./fdb_helper.sh stop-backup
```

## Check if Backup is Stopped

Not currently automated:

Steps:
* run fdbbackup status

## Clear Data from Cluster

```
./fdb_helper.sh clear-data
```

## Check if Key Exists

```
./fdb_helper.sh check-key-exists
```

## Start Restore

```
./fdb_helper.sh restore
```

## Check if restore is complete

Not currently automated.

Steps:
* run fdbrestore status --dest-cluster-file /var/dynamic-conf/fdb.cluster

## Check if Key Exists 

```
./fdb_helper.sh check-key-exists
```

## Cleanup

```
./fdb_helper.sh clean-all
```
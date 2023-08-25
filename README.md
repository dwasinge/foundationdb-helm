# foundationdb-helm

This repository contains Helm Charts to deploy the FoundationDB Operator, a FoundationDB Cluster with Backups, and S3 Proxy.

NOTE:  S3 Proxy is used if deploying to a non s3 compatible API, such as Azure Blob Storage

# Charts

## S3 Proxy

This example assumes you have an Azure Storage Account and the associated ID and Access Key.

In the values.yaml file, replace the TO_REPLACE place holders with the specified values.

- `TO_REPLACE_WITH_AZURE_ID` - ID for the Azure Storage Account
- `TO_REPLACE_WITH_BASE64_AZURE_ID` - Base64 encoded value of the ID for the Azure Storage Account
- `TO_REPLACE_WITH_AZURE_ACCESS_KEY` - Access Key for the Azure Storage Account
- `TO_REPLACE_WITH_BASE64_AZURE_ACCESS_KEY` - Base64 encoded value of the Access Key for the Azure Storage Account

NOTE:  Currently a secret is created using the Base64 encoded values, but they are not being used in the deployment as it is not working when s3 Proxy starts up.  Still looking into the issue so for now just using the values directly.

NOTE:  The authentication of S3 Proxy is currently set to none.  If enabling authentication, set `s3proxy.s3.authorization` to `aws-v2-or-v4` and set `s3proxy.s3.identity` and `s3proxy.s3.credential`.  The id and credential will then be required when calling the S3 Proxy API.

We will now deploy S3 Proxy into it's own namespace:

```
# switch to default namespace
oc new-project fdb-s3-proxy

# run helm chart
helm install s3-proxy s3proxy
```

## Operator

For now, we are just using the default namespace.

```
# switch to default namespace
oc project default

# run helm chart
helm install fdb-operator operator
```

NOTE:  Currently, the operator is only working when deployed to the default namespace.  

The issues revolve around security context constraints.  The operator will deploy in another namespace with the following role and rolebindings:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: fdb-kubernetes-operator-manager-scc-role
rules:
- apiGroups:
  - security.openshift.io 
  resourceNames:
  - nonroot-v2
  resources:
  - securitycontextconstraints 
  verbs: 
  - use
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: fdb-kubernetes-operator-manager-scc-rolebinding
subjects:
  - kind: ServiceAccount
    name: fdb-kubernetes-operator-controller-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: fdb-kubernetes-operator-manager-scc-role
```

This allows the operator pod to start up, but when a FoundationDBCluster resource created, the pods fail to start because they are trying to run commands as user 0.  This will take more research to determine what roles are required for the pods to start.


## Cluster

The Cluster chart will create secret containing the credentials to connect to S3 Proxy.  The credentials must be in the following format:

```
{
    "accounts": {
        "<service-name>.<project-name>:8080": {}
    }
}
```

Replace the <service-name> and <project-name> with the values used when running the `s3proxy` chart.

For now, we are just using the default namespace.

```
# switch to default namespace
oc project default

# run helm chart
helm install fdb-cluster cluster
```
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
* run `fdbbackup status`
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
* run `fdbrestore status --dest-cluster-file /var/dynamic-conf/fdb.cluster`

## Check if Key Exists 

```
./fdb_helper.sh check-key-exists
```

## Cleanup

```
./fdb_helper.sh clean-all
```
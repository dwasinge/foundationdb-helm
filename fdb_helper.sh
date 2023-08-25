# initialize resources:
#    - create foundationdb project
#    - deploy s3-proxy
#    - deploy fdb operator
#    - credentials, cluster, and backup
function init() {

    echo "initializing resources"
    oc new-project foundationdb
    helm install s3-proxy s3proxy
    helm install fdb-operator operator
    helm install fdb-cluster cluster --set resources.createS3Credentials=true,resources.createCluster=true,resources.createBackup=true

}

# cluster status:
#   - view reconciliation status of cluster
function cluster_status() {
    oc get foundationdbcluster fdb
}

# controller manager logs:
#   - tail logs
#   - can be used to determine in backup reconciliation is complete
function controller_manager_logs() {
    oc logs -f -l app=fdb-kubernetes-operator-controller-manager --container=manager
}

# add-data:
#    - set key 'this' value 'that'
function add_data() {

  echo "adding key 'this' with value 'that"
  oc fdb exec -c fdb -- fdbcli --exec "writemode on;set this that"

}

# check key exists:
#     - get key 'this'
function check_key_exists() {
    echo "checking if the key 'this' exists: "
    oc fdb exec -c fdb -- fdbcli --exec "get this"
}

# stop-backup:
#     - set backup state to Stopped
function stop_backup() {

    echo "Stopping FoundationDB Backup"
        helm upgrade fdb-cluster cluster --set resources.createS3Credentials=true,resources.createCluster=true,resources.createBackup=true,fdb.backup.stopped=true
    echo "..cluster and backup created."

}

# clear-data:
#     - clear all data from cluster
function clear_data() {
    echo "clearing all data from FoundationDB cluster"
    oc fdb exec -c fdb -- fdbcli --exec "writemode on; clearrange '' \xff"
}

# restore
#     - create FoundationDBRestore resource
function restore() {
    echo "restoring data from backup"
    helm upgrade fdb-cluster cluster --set resources.createS3Credentials=true,resources.createCluster=true,resources.createBackup=true,fdb.backup.stopped=true,resources.createRestore=true
}

# clean all:
#    - uninstall cluster chart
#    - uninstall operator chart
#    - uninstall s3proxy chart
#    - delete foundationdb project
function clean_all() {

    helm uninstall fdb-cluster
    helm uninstall fdb-operator
    helm uninstall s3-proxy
    oc delete project foundationdb

}

####################
# Helper functions #
####################

function check_args() {
    # if -h or --help is passed, show the help
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        echo "Usage: ./test.sh <option>"
        echo "Or: ./test.sh -h|--help"
        echo "This script can be used with the options:"
        echo "  - init             --> create project, deploy s3-proxy and the foundationdb operator, and cluster/backup resources"
        echo "  - add-data         --> adds sample data to the database"
        echo "  - stop-backup      --> sets the backup state to Stopped"
        echo "  - clear-data       --> clears the data in the cluster"
        echo "  - restore          --> restores data from backup in object store"
        echo "  - check-key-exists --> determines if sample data key exists"
        echo "  - clean-all        --> removes all resources and deletes project"
        exit 0
    fi

}

##########
## Main ##
##########

if [[ "$1" != "1" ]]; then
    check_args "$@"
fi

if [ "$1" == "init" ]
then
    init
elif [ "$1" == "add-data" ]
then
    add_data
elif [ "$1" == "stop-backup" ]
then
    stop_backup
elif [ "$1" == "clear-data" ]
then
    clear_data
elif [ "$1" == "restore" ]
then
    restore
elif [ "$1" == "check-key-exists" ]
then
    check_key_exists
elif [ "$1" == "clean-all" ]
then
    clean_all
elif [ "$1" == "cluster-status" ]
then
    cluster_status
elif [ "$1" == "controller-manager-logs" ]
then
    controller_manager_logs
else
    echo "Unknown option '$1' supplied.  Please use '-h' to see available options."
fi


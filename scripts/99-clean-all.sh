#! /bin/bash -e
TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)

IAAS=$(yq e .iaas $PARAMS_YAML)

if [ "$IAAS" = "do" ];
then
    export KUBECONFIG=$(pwd)/.kube-config

    export DO_KCLUSTER_ID=$(doctl k cluster list | awk '{if(NR>1)print}' | awk '{ print $1 }')

    doctl kubernetes cluster delete $DO_KCLUSTER_ID --force --dangerous -v
else
    export KUBECONFIG=~/.kube-tkg/config
    kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

    echo "Beginning Cleanup your Workspace starting..."
    tanzu standalone-cluster delete $CLUSTER_NAME --yes
fi

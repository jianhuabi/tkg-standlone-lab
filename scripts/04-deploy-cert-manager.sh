#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
IAAS=$(yq e .iaas $PARAMS_YAML)

if [ "$IAAS" = "do" ];
then
    export KUBECONFIG=$(pwd)/.kube-config
else

    export KUBECONFIG=~/.kube-tkg/config

    kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
fi

VERSION=$(tanzu package available list cert-manager.tanzu.vmware.com -oyaml -n tanzu-kapp | yq eval ".[0].version" -)

tanzu package install cert-manager \
    --package-name cert-manager.tanzu.vmware.com \
    --version $VERSION \
    --namespace tanzu-kapp

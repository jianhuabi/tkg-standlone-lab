#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
IAAS=$(yq e .iaas $PARAMS_YAML)

export KUBECONFIG=~/.kube-tkg/config

kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

tanzu package repository add tanzu-standard --url projects.registry.vmware.com/tkg/packages/standard/repo:v1.4.0  --namespace tanzu-kapp --create-namespace

kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
kubectl apply -f storage-classes/default-storage-class-$IAAS.yaml

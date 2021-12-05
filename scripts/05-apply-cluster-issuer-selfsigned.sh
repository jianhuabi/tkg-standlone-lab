#!/bin/bash -e
TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)

export KUBECONFIG=~/.kube-tkg/config

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/contour/

cp tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-selfsigned.yaml generated/$CLUSTER_NAME/contour/contour-cluster-issuer-selfsigned.yaml

kubectl apply -f generated/$CLUSTER_NAME/contour/contour-cluster-issuer-selfsigned.yaml

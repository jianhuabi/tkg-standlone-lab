#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export CLUSTER=$(yq e .management-cluster.name $PARAMS_YAML)

mkdir -p generated/$CLUSTER
cp config-templates/do-cluster-config.yaml generated/$CLUSTER/do-cluster-config.yaml

export REGION=$(yq e .do.region $PARAMS_YAML)
export DO_NODE_SIZE=$(yq e .do.vm-size $PARAMS_YAML)
export DO_NODE_COUNT=$(yq e .do.node-count $PARAMS_YAML)
export DO_K8S_VERSION=$(yq e .do.k8s-version $PARAMS_YAML)

yq e -i '.CLUSTER_NAME = env(CLUSTER)' generated/$CLUSTER/do-cluster-config.yaml
yq e -i '.REGION = env(REGION)' generated/$CLUSTER/do-cluster-config.yaml
yq e -i '.DO_NODE_SIZE = env(DO_NODE_SIZE)' generated/$CLUSTER/do-cluster-config.yaml
yq e -i '.DO_NODE_COUNT = env(DO_NODE_COUNT)' generated/$CLUSTER/do-cluster-config.yaml
yq e -i '.DO_K8S_VERSION = env(DO_K8S_VERSION)' generated/$CLUSTER/do-cluster-config.yaml

echo "cluster creating...."
echo "doctl k cluster create $CLUSTER --count=$DO_NODE_COUNT --region=$REGION --size=$DO_NODE_SIZE --version=$DO_K8S_VERSION --wait"

doctl k cluster create $CLUSTER --count=$DO_NODE_COUNT --region=$REGION --size=$DO_NODE_SIZE --version=$DO_K8S_VERSION --wait
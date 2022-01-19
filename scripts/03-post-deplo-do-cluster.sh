#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
IAAS=$(yq e .iaas $PARAMS_YAML)

export KUBECONFIG=$(pwd)/.kube-config
export DO_KCLUSTER_ID=$(doctl k cluster list | awk '{if(NR>1)print}' | awk '{ print $1 }')

doctl k cluster kubeconfig save $DO_KCLUSTER_ID

pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='1.0.0' --product-file-id=1105820
mkdir tanzu-cluster-essentials
tar -xvf tanzu-cluster-essentials-darwin-amd64-1.0.0.tgz -C tanzu-cluster-essentials

export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:82dfaf70656b54dcba0d4def85ccae1578ff27054e7533d08320244af7fb0343

cd tanzu-cluster-essentials
./install.sh
cd ..

tanzu package repository add tanzu-standard --url projects.registry.vmware.com/tkg/packages/standard/repo:v1.4.0  --namespace tanzu-kapp --create-namespace



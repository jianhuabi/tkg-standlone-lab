#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export CLUSTER=$(yq e .management-cluster.name $PARAMS_YAML)

mkdir -p generated/$CLUSTER
cp config-templates/aws-cluster-config.yaml generated/$CLUSTER/cluster-config.yaml

export REGION=$(yq e .aws.region $PARAMS_YAML)
export AWS_NODE_AZ=$(yq e .aws.region $PARAMS_YAML)a
export AWS_PROFILE=$(yq e .aws.profile $PARAMS_YAML)
export SSH_KEY_NAME=tkg-$(yq e .environment-name $PARAMS_YAML)-default
export AWS_AMI_ID=$(yq e .aws.aws_ami_id $PARAMS_YAML)
export AWS_CONTROL_PLANE_MACHINE_TYPE=$(yq e .aws.control-plane-machine-type $PARAMS_YAML)
export AWS_NODE_MACHINE_TYPE=$(yq e .aws.node-machine-type $PARAMS_YAML)

yq e -i '.CLUSTER_NAME = env(CLUSTER)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.AWS_REGION = env(REGION)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.AWS_SSH_KEY_NAME = env(SSH_KEY_NAME)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.AWS_AMI_ID = env(AWS_AMI_ID)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.CONTROL_PLANE_MACHINE_TYPE = env(AWS_CONTROL_PLANE_MACHINE_TYPE)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.NODE_MACHINE_TYPE = env(AWS_NODE_MACHINE_TYPE)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.AWS_NODE_AZ = env(AWS_NODE_AZ)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.AWS_PROFILE = env(AWS_PROFILE)' generated/$CLUSTER/cluster-config.yaml

tanzu standalone-cluster create $CLUSTER  --file=generated/$CLUSTER/cluster-config.yaml -v 6
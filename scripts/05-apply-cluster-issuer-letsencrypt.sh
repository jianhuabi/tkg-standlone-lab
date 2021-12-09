#!/bin/bash -e
TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)

export KUBECONFIG=~/.kube-tkg/config

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/contour/

IAAS=$(yq e .iaas $PARAMS_YAML)

export LETS_ENCRYPT_ACME_EMAIL=$(yq e .lets-encrypt-acme-email $PARAMS_YAML)

if [ "$IAAS" = "vsphere" ];
then
  if [ "$DNS_PROVIDER" = "gcloud-dns" ];
  then
    # Using Google Cloud DNS
    cp tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-dns-gcloud.yaml generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
    kubectl create secret generic gcloud-dns-service-account \
        --from-file=credentials.json=keys/gcloud-dns-credentials.json \
        -n cert-manager -o yaml --dry-run=client | kubectl apply -f-
    export GCLOUD_PROJECT=$(yq e .gcloud.project $PARAMS_YAML )
    yq e -i '.spec.acme.solvers[0].dns01.cloudDNS.project = env(GCLOUD_PROJECT)' generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
  else
    # Using Route53
    cp tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-dns-aws.yaml generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
    kubectl create secret generic prod-route53-credentials-secret \
        --from-literal=secret-access-key=$(yq e .aws.secret-access-key $PARAMS_YAML) \
        -n cert-manager -o yaml --dry-run=client | kubectl apply -f-

    export AWS_ACCESS_KEY_ID=$(yq e .aws.access-key-id $PARAMS_YAML )
    export AWS_REGION=$(yq e .aws.region $PARAMS_YAML)
    export AWS_HOSTED_ZONE_ID=$(yq e .aws.hosted-zone-id $PARAMS_YAML)
    yq e -i '.spec.acme.solvers[0].dns01.route53.accessKeyID = env(AWS_ACCESS_KEY_ID)' generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
    yq e -i '.spec.acme.solvers[0].dns01.route53.region = env(AWS_REGION)' generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
    yq e -i '.spec.acme.solvers[0].dns01.route53.hostedZoneID = env(AWS_HOSTED_ZONE_ID)' generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
  fi
else
  cp tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-http.yaml generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
fi
yq e -i '.spec.acme.email = env(LETS_ENCRYPT_ACME_EMAIL)' generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml

kubectl apply -f generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
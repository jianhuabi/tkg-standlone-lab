#!/bin/bash -e
TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export PROMETHEUS_FQDN=$(yq e .management-cluster.prometheus-fqdn $PARAMS_YAML)

IAAS=$(yq e .iaas $PARAMS_YAML)

if [ "$IAAS" = "do" ];
then
    export KUBECONFIG=$(pwd)/.kube-config
else
    export KUBECONFIG=~/.kube-tkg/config
    kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
fi

mkdir -p generated/$CLUSTER_NAME/monitoring/

kubectl create ns tanzu-system-monitoring --dry-run=client --output yaml | kubectl apply -f -

# Create certificate
cp tkg-extensions-mods-examples/monitoring/prometheus-cert.yaml generated/$CLUSTER_NAME/monitoring/prometheus-cert.yaml
yq e -i ".spec.dnsNames[0] = env(PROMETHEUS_FQDN)" generated/$CLUSTER_NAME/monitoring/prometheus-cert.yaml
kubectl apply -f generated/$CLUSTER_NAME/monitoring/prometheus-cert.yaml
# Wait for cert to be ready
while kubectl get certificates -n tanzu-system-monitoring prometheus-cert | grep True ; [ $? -ne 0 ]; do
	echo prometheus certificate is not yet ready
	sleep 5
done

# Read prometheus certificate details and store in files
export PROMETHEUS_CERT_CRT=$(kubectl get secret prometheus-cert-tls -n tanzu-system-monitoring -o=jsonpath={.data."tls\.crt"} | base64 --decode)
export PROMETHEUS_CERT_KEY=$(kubectl get secret prometheus-cert-tls -n tanzu-system-monitoring -o=jsonpath={.data."tls\.key"} | base64 --decode)

export TRUE_VALUE=true
yq e ".ingress.enabled = env(TRUE_VALUE)" --null-input > generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml
yq e -i ".ingress.virtual_host_fqdn = env(PROMETHEUS_FQDN)" generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml
yq e -i '.ingress.tlsCertificate."tls.crt" = strenv(PROMETHEUS_CERT_CRT)' generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml
yq e -i '.ingress.tlsCertificate."tls.key" = strenv(PROMETHEUS_CERT_KEY)' generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml

# Apply Monitoring
VERSION=$(tanzu package available list prometheus.tanzu.vmware.com -oyaml -n tanzu-kapp | yq eval ".[0].version" -)
tanzu package install prometheus \
    --package-name prometheus.tanzu.vmware.com \
    --version $VERSION \
    --namespace tanzu-kapp \
    --values-file generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml
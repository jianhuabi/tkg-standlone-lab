# Install Tanzu Application Platform Beta 0.4.0-build.12 

The following steps leverage AWS as well as Tanzu Community Edition CLI to create a standalone cluster to host TAP. 

Offical TAP beta 0.4 installation document could be access via [official docs TAP](https://docs-staging.vmware.com/en/Tanzu-Application-Platform/0.4/tap/GUID-install-intro.html)

>Note: DO NOT USING HARBOR CLUSTER to deploy TAP since currently Some Tanzu package will conflicts with TAP & Harbor release if you use tanzu package manager to deploy those components.

## Initial Install of Blank standalone TCE cluster.

```bash
tanzu standalone-cluster create --ui
```

### Step 0 - Remove TCE kapp-controller since it might conflicts with TAP's

```bash
kubectl delete deployment kapp-controller -n tkg-system
```
### Step 1 - Install Tanzu Package Manager prerequisite

[prerequisistes] (https://docs-staging.vmware.com/en/Tanzu-Application-Platform/0.4/tap/GUID-install-general.html#install-tanzu-prerequisites-5)

### Step 2 - Install Tanzu CLI plugin

[prerequisistes] (https://docs-staging.vmware.com/en/Tanzu-Application-Platform/0.4/tap/GUID-install-general.html#clean-install-tanzu-cli-7)


### Step 3 - Install TAP based on Profiles

I was using `Dev` profile to deploy TAP. Follow this 
[offical documentation](https://docs-staging.vmware.com/en/Tanzu-Application-Platform/0.4/tap/GUID-install.html#add-the-tanzu-application-platform-package-repository-0)

Sample `Dev Profile`

```bash
profile: dev
ceip_policy_disclosed: true # Expects a true or false boolean value

buildservice:
  kp_default_repository: "harbor.dragonstone.tkg-aws-e2-lab.winterfell.be/tanzu/build-service"
  kp_default_repository_username: "admin"
  kp_default_repository_password: "YOURPASSWORD"
  tanzunet_username: "YOUR_TANZUNET_NAME"
  tanzunet_password: "YOUR_TANZUNET_PASSWORD"

supply_chain: basic

ootb_supply_chain_basic:
  registry:
    server: "harbor.dragonstone.tkg-aws-e2-lab.winterfell.be"
    repository: "<harbor-project>/<repo>" # like `tanzu/apps`

tap_gui:
  service_type: LoadBalancer # NodePort for distributions that don't support LoadBalancer
  # Existing tap-values.yml above
  app_config:
    app:
      baseUrl: http://<url from `kubectl get svc -n tap-gui`>:7000
    integrations:
      github: # Other integrations available see NOTE below
        - host: github.com
          token: ${GITHUB_TOKEN}
    catalog:
      locations:
        - type: url
          target: https://github.com/tanzu-demo/tap-gui-catalogs/blob/main/blank/catalog-info.yaml
    backend:
        baseUrl: http://<url from `kubectl get svc -n tap-gui`>:7000
        cors:
          origin: http://<url from `kubectl get svc -n tap-gui`>:7000


metadata_store:
  app_service_type: LoadBalancer # (optional) Defaults to LoadBalancer. Change to NodePort for distributions that don't support LoadBalancer

contour:
  envoy:
    service:
      type: LoadBalancer


cnrs:
  ingress:
    external:
      namespace: tanzu-system-ingress
    internal:
      namespace: tanzu-system-ingress
  domain_name: YOUR_APP_DEFAULT_DOMAIN # default is example.com but I am using Route53 domain like `tap-app.tkg-aws-e2-lab.winterfell.be`
```

>Note: You need at least 8vCPU worker node to deploy TAP otherwise might face resource limitation issue where pod is pending for availabe Node.

## Getting Started with Tanzu Application Platform.

### Section 1: Developing Your First Application on Tanzu Application Platform

Follow [offical documentation](https://docs-staging.vmware.com/en/Tanzu-Application-Platform/0.4/tap/GUID-getting-started.html) to deploy a first sample workload by TAP.

#### Prereq: Set Up Developer Namespaces to Use Installed Packages
You need first to setup a account for workload to run. Follow [this link](https://docs-staging.vmware.com/en/Tanzu-Application-Platform/0.4/tap/GUID-install-components.html#set-up-developer-namespaces-to-use-installed-packages-42)


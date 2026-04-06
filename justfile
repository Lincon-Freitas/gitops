# Default Applications directory

helm_apps_dir := "apps"
helm_timeout := "5m"

# Kind configuration

cluster_name := "dev01"
cluster_config := "kind/config.yaml"

# ArgoCD configuration

argocd_repo_name := "argo"
argocd_chart_name := "argo-cd"
argocd_chart_url := "https://argoproj.github.io/argo-helm"
argocd_chart_version := "9.4.17"
argocd_release_name := "argocd"
argocd_release_namespace := "argocd"
argocd_values_file := helm_apps_dir + "/" + argocd_release_name + "/values.yaml"
argocd_url := "http://argocd.apps.127.0.0.1.nip.io"
argocd_app_path := "argocd/app-of-apps.yaml"
argocd_app_name := "app-of-apps"

# 📚 Information from recipes available
default:
    @just --list

# 🚀 Provision a Kubernetes cluster with required dependencies
provision: _docker-start _check-kind _check_gateway-api-crds _check-argocd _check-argocd-deploy argocd-url

_docker-start:
    @docker desktop start

_check-kind:
    #!/usr/bin/env bash
    set -e
    if [[ `just _kind-status-cluster` == "0" ]]; then \
        just _kind-create-cluster
    else
        echo 'Cluster {{ cluster_name }} is already running! 🚀'
    fi

_kind-status-cluster:
    #!/usr/bin/env bash
    set -e
    cluster_status=`kind get clusters | grep {{ cluster_name }} | wc -l`
    echo $cluster_status
     
_kind-create-cluster:
    @kind create cluster --config={{ cluster_config }} --name={{ cluster_name }}

_kind-update-context:
    @kubectl cluster-info --context kind-{{ cluster_name }}
    @kubectl config use-context kind-{{ cluster_name }}

_check_gateway-api-crds:
    #!/usr/bin/env bash
    set -e
    if [[ `just _status-gateway-api-crds` == "0" ]]; then \
        just _add-gateway-api-crds
    else
        echo 'GatewayAPI CRDs is already installed! 🚀'
    fi

# Check whether the GatewayAPI CRDs are already applied
_status-gateway-api-crds:
    #!/usr/bin/env bash
    set -e
    gateway_status=`kubectl get gateways -A -o name 2>/dev/null | grep "traefik-gateway" | wc -l`
    echo $gateway_status

_add-gateway-api-crds:
    @kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml


_repo-argocd:
    @just _add-helm-repo {{ argocd_repo_name }} {{ argocd_chart_url }}

_status-argocd:
    @just _status-helm-package {{ argocd_release_name }} {{ argocd_release_namespace }}

_install-argocd:
    @just _install-helm-package {{ argocd_chart_name }} {{ argocd_repo_name }} \
    {{ argocd_release_name }} {{ argocd_release_namespace }} {{ argocd_values_file }}

_update-argocd:
    @just _update-helm-package {{ argocd_chart_name }} {{ argocd_repo_name }} \
    {{ argocd_release_name }} {{ argocd_release_namespace }} {{ argocd_values_file }}

_check-argocd: _repo-argocd _kind-update-context
    #!/usr/bin/env bash
    set -e
    if [[ `just _status-argocd` == "0" ]]; then
        just _install-argocd
    elif [[ `just _status-argocd` == "1" ]]; then
        just _update-argocd
    fi

# Decide if app-of-apps should be applied or not
_check-argocd-deploy:
    #!/usr/bin/env bash
    set -e
    if [[ `just _status-argocd-deploy` == "0" ]]; then
        just _apply-argocd-deploy
    else
        echo 'ArgoCD {{ argocd_app_name }} app was already applied! 🚀'
    fi

# Check whether the app-of-apps is already applied
_status-argocd-deploy:
    #!/usr/bin/env bash
    set -e
    app_status=`kubectl get applications -A -o name | grep "app-of-apps" | wc -l`
    echo $app_status

# Apply the app-of-apps manifest
_apply-argocd-deploy:
    @kubectl apply -f {{ argocd_app_path }}

# Add helm repository
_add-helm-repo repo_name repo_url:
    @helm repo add {{ repo_name }} {{ repo_url }}

# Check status of a release with helm
_status-helm-package release_name release_namespace:
    #!/usr/bin/env bash
    set -e
    status=`helm -n {{ release_namespace }} ls | grep {{ release_name }} | wc -l`
    echo $status

# Install a release with helm
_install-helm-package chart_name repo_name release_name release_namespace values_file:
    helm install {{ release_name }} {{ repo_name }}/{{ chart_name }} \
    --namespace={{ release_namespace }} --values={{ values_file }} \
    --timeout={{ helm_timeout }} --create-namespace --wait

# Update a release with helm
_update-helm-package chart_name repo_name release_name release_namespace values_file:
    helm upgrade {{ release_name }} {{ repo_name }}/{{ chart_name }} \
    --namespace={{ release_namespace }} --values={{ values_file }} \
    --timeout={{ helm_timeout }} --wait

# 🐙 Prints ArgoCD instance url
argocd-url:
    @echo "\nEnvironment {{ cluster_name }} is ready, you can access ArgoCD at {{ argocd_url }} 🐙"

# 🧻 Cleans up the provisioned environment
delete:
    kind delete cluster --name={{ cluster_name }}
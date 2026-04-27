# GitOps

Local Kubernetes development environment powered by Kind, ArgoCD, and an app-of-apps pattern.

## Dependencies

| Tool | Description |
|------|-------------|
| [just](https://github.com/casey/just) | Command runner used to execute project recipes |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Container runtime required by Kind |
| [kind](https://kind.sigs.k8s.io/) | Runs local Kubernetes clusters inside Docker |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) | Kubernetes CLI for interacting with the cluster |
| [helm](https://helm.sh/) | Kubernetes package manager used to install ArgoCD |

### Install via Homebrew

```sh
brew install just kind kubectl helm
brew install --cask docker
```

## Quick Start

```sh
# Provision the full environment (Kind cluster + Gateway API CRDs + ArgoCD + app-of-apps)
just provision

# List all available recipes
just

# Print the ArgoCD URL
just argocd-url

# Tear down the environment
just delete
```

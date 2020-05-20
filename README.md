# Boomerang Charts

Helm charts for Boomerang projects ready to launch on Kubernetes using [Helm](https://helm.sh).

Currently all our charts are Helm v2 charts. We are working on creating v3 supported versions.

## Pre-requisites

- Kubernetes
- Helm v2

And also any additional dependencies by chart. For example Boomerang Flow depends on MongoDB. Please read the individual charts READMEs

## Getting Started

To quickly get started, install into a kubernetes cluster of 1.13+ via Helm using the following commands

**Step 1**

Ensure a kubernetes namespace and MongoDB are installed

**Step 2**

Ensure you have a docker registry secret in your namespace for access to github packages. Follow the instructions [here](https://help.github.com/en/github/managing-packages-with-github-packages/configuring-docker-for-use-with-github-packages#authenticating-to-github-packages) to get the github token.

```sh
kubectl create secret docker-registry boomerang.registrykey --docker-server=docker.pkg.github.com --docker-username=<github_username> --docker-password=<github_token> --docker-email=<github_email> --namespace=<namespace>
```

**Step 3**

Download the helm chart

```sh
CHART_VERSION=1.1.2
CHART_NAME=bmrg-bosun or bmrg-flow
curl -LO https://github.com/boomerang-io/boomerang.docs/raw/stable/content/$CHART_NAME-$CHART_VERSION.tgz
```

**Step 4**

Install the helm chart

```sh
helm install --namespace <namespace> --set database.mongodb.host=<service_name> --set database.mongodb.secretName=<mongodb_secret> bmrg-bosun-$CHART_VERSION.tgz
```

*Or Manually*

Extract the values.yaml from the helm chart and update the values in detail

```sh
helm inspect values bmrg-bosun-1.0.4.tgz > bmrg-bosun-values.yaml
vi bmrg-bosun-values.yaml
helm install --namespace <namespace> -f bmrg-bosun-values.yaml bmrg-bosun-$CHART_VERSION.tgz
```

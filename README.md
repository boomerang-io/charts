# Boomerang Helm Charts

Helm charts for Boomerang-io projects ready to launch on Kubernetes using [Helm](https://helm.sh).

All our charts are Helm v3 charts. 

## Available Charts

- Boomerang Bosun
- Boomerang Flow
- Boomerang oauth2-proxy (forked from [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy))

## Pre-requisites

- Kubernetes 1.13+
- Helm v3

Plus any additional dependencies by chart. For example Boomerang Flow depends on MongoDB. Please read the individual charts READMEs.

## Getting Started

To quickly get started, install into a kubernetes cluster of 1.13+ via Helm using the following commands

**Step 1**

Ensure you have a docker registry secret in your namespace for access to github packages. Follow the instructions [here](https://help.github.com/en/github/managing-packages-with-github-packages/configuring-docker-for-use-with-github-packages#authenticating-to-github-packages) to get the github token.

```sh
kubectl create secret docker-registry boomerang.registrykey --docker-server=docker.pkg.github.com --docker-username=<github_username> --docker-password=<github_token> --docker-email=<github_email> --namespace=<namespace>
```

**Step 2**

Add the helm repository

```sh
helm repo add boomerang-io https://raw.githubusercontent.com/boomerang-io/charts/index
```

**Step 3**

Install or upgrade the helm chart using the relevant helm commands and passing in any properties

```sh
helm install --namespace <namespace> --set database.mongodb.host=<service_name> --set database.mongodb.secretName=<mongodb_secret> boomerang-io/bmrg-bosun
```

*Or Manually*

Extract the values.yaml from the helm chart and update the values in detail

```sh
helm inspect values boomerang-io/bmrg-bosun > bmrg-bosun-values.yaml
vi bmrg-bosun-values.yaml
helm install --namespace <namespace> -f bmrg-bosun-values.yaml boomerang-io/bmrg-bosun
```

## Repository Structure

This helm repository services dual purposes as both the source control of the raw charts, and also the helm repository.

The helm repository uses the tgz files from the repositories Releases but also the index.yaml in the `index` branch. This branch is protected and only used by the CICD system.

## CICD

The CICD for this repository is currently using an instance of Boomerang CICD inside of IBM. This automation will package the charts and push them back to this repository as mentioned in the repositroy structure above.

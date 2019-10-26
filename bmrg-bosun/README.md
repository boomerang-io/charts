# Boomerang Bosun

Helm chart for the Boomerang Bosun project.

## Release Notes

### What's New

- TBA

### Known Issues

- We are currently applying the `ingress.kubernetes.io/client-max-body-size: 1m` annotation to the ingress for [issue](https://github.com/kubernetes/ingress-nginx/issues/2494).
- Starting with IBM Boomerang CICD helm chart version 3.0.0 the backwards compatibility is broken due to the ICP 3.2+ and NGINX Ingress Controller 0.22.0 versions

## Dependencies

- Kubernetes 1.13+
- MongoDB
- OpenPolicyAgent

### Optional Boomerang Integration
- Boomerang Core

### If Auth Enabled on Ingress
- Boomerang Auth Proxy, OR
- Authentication Provider

## Configuration

The following table lists the configurable parameters of the chart and their default values.

### General Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `general.namePrefix` | The name prefix used in the naming of all Kubernetes objects  | `$.Chart.Name` |
| `general.enable.apidocs` | Enable the API Docs endpoint on the services to be picked up by the API Docs | `false` |
| `general.enable.debug` | Enables;<ul><li>additional logging in microservces</li><li>additional logging available to users in CI kubernetes modes</li><li>port forwarding advice on installation</li></ul> | `false` |

### Boomerang Core Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `core.namePrefix` | The name prefix used when installing Boomerang Core. Used to reference Core services  | `bmrg-core` |

### Image Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `image.registry` | Boomerang Docker Registry | `"tools.boomerangplatform.net:8500"` |
| `image.pullPolicy` | Image Pull Policy | `IfNotPresent` |

### Job Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `job.data.enabled` | Enable the data loader on installation and upgrade | `false` |
| `job.data.profile` | The data loader profile to use | `cicd` |
| `job.data.image.repository` | Image Repository Path | `/ise/<image-name>`
| `job.data.image.tag` | Image Version | `<sem_ver>`

### Per Image Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `replicaCount` | How many pods to spin up | `1`
| `image.repository` | Docker Registry Image Repository | `/ise/<image-name>`
| `image.tag` | Image Version | `<sem_ver>`
| `service.type` | Service Type to Expose | `NodePort` or `ClusterIP`
| `service.nodeport` | Image tag | 

### Ingress Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `enabled` | Enable creation of ingress definitions | `false`
| `root` | Chart root context path | `/stage`
| `hosts` | An array of hosts to accept requests on | `wdc1.cloud.boomerangplatform.net`
| `tlsSecret` | If there is an associated TLS secret | `bmrg-secret-tls`
| `auth.enabled` | Enable addition of auth annotations on ingress | `true`
| `auth.url.internal` |  | `http://bmrg-auth-proxy-bmrg-auth-proxy-4180/oauth/auth`
| `auth.url.external` |  | `https://$host/oauth/start?rd=$uri`

### Database Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `mongodb.host` | Connection Host or Internal Service | `bmrg-mdb001-ibm-mongodb-dev`
| `mongodb.port` | Connection Port| `27017`
| `mongodb.user` | Database user | `boomerang`
| `mongodb.password` | Database user password | `passw0rd`
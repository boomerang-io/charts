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
| `general.enable.standalone` | This allows Boomerang Bosun to run without any integrations to the Boomerang Core platform. This means that certain team and user management is embedded in the app | `true` |

### Boomerang Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `boomerang.core.namePrefix` | The name prefix used when installing Boomerang Core. Used to reference Core services. | `bmrg-core` |
| `boomerang.core.namespace` | The namespace where Boomerang Core is installed. Used to reference Core services. | |
| `boomerang.cicd.namePrefix` | The name prefix used when installing Boomerang CICD. Used to reference CICD services. | `bmrg-cicd` |
| `boomerang.cicd.namespace` | The namespace where Boomerang CICD is installed. Used to reference CICD services. | |

### Image Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `image.registry` | Boomerang Docker Registry | `boomerangio` |
| `image.pullPolicy` | Image Pull Policy | `IfNotPresent` |
| `image.pullSecret` | Image Pull Secret. See [here](https://github.com/boomerang-io/charts) for more information on how to access the Boomerang-io docker containers. | |

### Job Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `job.data.enabled` | Enable the data loader on installation and upgrade | `false` |
| `job.data.profile` | The data loader profile to use | `cicd` | |
| `job.data.image.repository` | Image Repository Path | `/<image-name>` |
| `job.data.image.tag` | Image Version | `<sem_ver>` |

### Per Image Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `replicaCount` | How many pods to spin up | `1` |
| `image.repository` | Docker Registry Image Repository | `/ise/<image-name>` |
| `image.tag` | Image Version | `<sem_ver>` |
| `service.type` | Service Type to Expose | `NodePort` or `ClusterIP` |
| `zone` | The network zone to be placed in if the corresponding network policy is used. Options are trusted, semitrusted, and untrusted | |

### Ingress Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `ingress.enabled` | Enable creation of ingress definitions | `false` |
| `ingress.root` | Chart root context path. Can be used for putting an environment designator in front such as `/dev`. | `""` |
| `ingress.host` | An array of hosts to accept requests on | `cloud.boomerangplatform.net` |
| `ingress.tlsSecretName` | If there is an associated TLS secret | `bmrg-tls-cloud` |
| `ingress.annotationsPrefix` | The prefix for the annotations inside the ingress definition. Typically for IKS Community Ingress you need to set it to `nginx.global.ingress.kubernetes.io` | `ingress.kubernetes.io` |
| `ingress.class` | The class of the ingress, it is used to mark the ingress resources to be picked-up by a specific controller. For IKS Community Ingress set it to `public-iks-k8s-nginx` | `nginx` |

### Auth Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `auth.enabled` | Enable addition of auth annotations on ingress | `true` |
| `auth.mode` | Type of auth being implemented. Relates to the Auth Proxy mode. Options are `basic` or `oauth` | `basic` |
| `auth.serviceName` | The Boomerang Auth Proxy service to integrate to. | `bmrg-auth-proxy` |
| `auth.namespace` | The Boomerang Auth Proxy namespace | |
| `auth.prefix` | The Boomerang Auth Proxy context path. This is appended to the end of `ingress.root` | `/oauth` |

### Database Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `mongodb.host` | Connection Host or Internal Service | `bmrg-mdb001-ibm-mongodb-dev` |
| `mongodb.port` | Connection Port| `27017` |
| `mongodb.user` | Database user | `boomerang` |
| `mongodb.password` | Database user password | `passw0rd` |
| `database.mongodb.secretName` | The secret to get the password from. | |

### JFrog XRay Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `xray.token` | Authentication token | |
| `xray.url` | Connection URL | |
| `xray.user` | Authentication User | |

### Sonarqube Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `sonarqube.token` | Authentication token | |
| `sonarqube.url` | Connection URL | |
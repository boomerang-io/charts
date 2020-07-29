# Boomerang Flow

Boomerang Flow is a modern cloud native workflow automation tool built on top of Kubernetes. Enable new ways of approaching your business tasks or combine with existing tools to extend your current workloads.

[What's new in this release?](https://launch.boomerangplatform.net/docs/boomerang-flow/introduction/whats-new)

[How to install?](https://launch.boomerangplatform.net/docs/boomerang-flow/installing/installing)

## Dependencies

- IBM Cloud Private 3.2.+ OR Kubernetes 1.13+
- MongoDB 
- LDAP (OpenLDAP) _optional_
- NGINX Ingress Controller 0.22+
- Helm v3
- Boomerang Auth Proxy or an Authentication Provider

For more information on the dependencies please see the Application Architecture.

### Worker RBAC

The worker priviledged RBAC is dependent on the IBM Cloud Private resources;
 - Pod Security Policy `ibm-privileged-psp`, and
 - Cluster Role `ibm-privileged-clusterrole` 

If you allow priviledge access by default then you can disable the creation of this service account by removing the value in the value yaml under `workers.rbac.role`

If you do not use IBM Cloud Private, you can change the value to a Cluster Role that has priviledged access

## Configuration

The following table lists the configurable parameters of the chart and their default values.

### General Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `general.namePrefix` | The name prefix used in the naming of all Kubernetes objects  | `$.Chart.Name` |
| `general.enable.apidocs` | Enable the API Docs endpoint on the services to be picked up by the API Docs | `false` |
| `general.enable.debug` | Enables additional logging and port forwarding advice on installation | `false` |

### Worker Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `workers.rbac.role` | The kubernetes service account name that allows priviledged access. | `ibm-privileged-clusterrole` |
| `workers.logging.type` | The logging implementation to use. Default is kubernetes log api. Available Options: `default` and `elastic` | `default` |
| `workers.logging.host` | The elasticsearch host service name. _Only required if type is 'elastic'_ | <ul><li>default:</li><li>elastic: `elasticsearch.kube-system`</li></ul> |
| `workers.logging.port` | The elasticsearch port. _Only required if type is 'elastic'_ | <ul><li>default:</li><li>elastic: `9200`</li></ul> |
| `workers.logging.secrets` | The elastic logging certs secret. _Only required if type is 'elastic'_ | <ul><li>default:</li><li>elastic: `logging-elk-certs`</li></ul> |
| `workers.enable.deletion` | Will delete any workers that are completed and in non error state. | `true` |
| `workers.enable.dedicatedNodes` | Runs the CICD wokers to run on specific nodes with the taint `dedicated=bmrg-worker:NoSchedule` and also a label of `node-role.kubernetes.io/bmrg-worker=true` | `false` |

*Note:*
1. If you need the elasticsearch logging certificates, then you will need to have these available in the same namespace. The following command can help achieve this.
```kubectl get secret logging-elk-certs --namespace=kube-system --export -o yaml | kubectl --namespace="bmrg-dev" apply -f -```
2. If you choose `elastic` make sure to adjust your retention period. https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.1/manage_metrics/log_change_retention.html
3. If you choose `default` be aware of the kubernetes log rotation and storage requirements.

*References:*
- [Kubernetes Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
- [Kubernetes Node Selection](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector)

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
| `job.data.profile` | The data loader profile to use | `flow` |
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
| `annotationsPrefix` | The prefix for the annotations inside the ingress definition. Typically for IKS Community Ingress you need to set it to "nginx.ingress.kubernetes.io" | `ingress.kubernetes.io`
| `class` | The class of the ingress, it is used to mark the ingress resources to be picked-up by a specific controller. For IKS Community Ingress set it to "public-iks-k8s-nginx" | `nginx`

### Database Configuration

| Parameter | Description | Default Value |
|---|---|---|
| `mongodb.host` | Connection Host or Internal Service | `bmrg-mdb001-ibm-mongodb-dev`
| `mongodb.port` | Connection Port| `27017`
| `mongodb.user` | Database user | `boomerang`
| `mongodb.password` | Database user password | `passw0rd`

## Known Issues

- We are currently applying the `ingress.kubernetes.io/client-max-body-size: 1m` annotation to the ingress for [issue](https://github.com/kubernetes/ingress-nginx/issues/2494).
- Starting with IBM Boomerang Flow helm chart version 2.0.0 the backwards compatibility is broken due to the ICP 3.2+ and NGINX Ingress Controller 0.22.0 versions
- We only support single host ingresses

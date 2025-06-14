# Boomerang Flow

Boomerang Flow is a modern cloud native workflow automation tool built on top of Kubernetes. Enable new ways of approaching your business tasks or combine with existing tools to extend your current workloads.

[What's new in this release?](https://www.useboomerang.io/docs/boomerang-flow/introduction/whats-new)

[How to install?](https://www.useboomerang.io/docs/boomerang-flow/installing/installing)

## Dependencies

- Kubernetes 1.20+
- MongoDB \
- NGINX Ingress Controller 0.22+
- Helm v3
- Auth2 Proxy or an Authentication Provider
- Tekton

For more information on the dependencies please see the Application Architecture.

### Worker RBAC

The charts allows the end-user to configure the name of the security policy bound to a role depending on the underlying Kubernetes implementation.
For example:

- running on a OpenShift Container Platform, the name depends on the existence of `securitycontextconstraints` named resource,
- running on a vanilla Kubernetes flavor, the name depends on the existence of `podsecuritypolicies` named resource.

If you allow privileged access by default then you can disable the creation of this service account by removing the value in the value yaml under `workers.rbac.role`

You can change the value to a Cluster Role that has privileged access.

## Configuration

The following table lists the configurable parameters of the chart and their default values.

### General Configuration

| Parameter                | Description                                                                  | Default Value  |
| ------------------------ | ---------------------------------------------------------------------------- | -------------- |
| `general.namePrefix`     | The name prefix used in the naming of all Kubernetes objects                 | `$.Chart.Name` |
| `general.enable.apidocs` | Enable the API Docs endpoint on the services to be picked up by the API Docs | `false`        |
| `general.enable.debug`   | Enables additional logging and port forwarding advice on installation        | `false`        |

### Tasks Configuration

| Parameter                     | Description                                                                                                                                        | Default Value                                                     |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `tasks.rbac.role`             | The kubernetes service account name that allows privileged access.                                                                                 | `ibm-privileged-clusterrole`                                      |
| `tasks.logging.type`          | The logging implementation to use. Default is kubernetes log api. Available Options: `default` and `loki`                                          | `default`                                                         |
| `tasks.logging.host`          | The elasticsearch host service name. _Only required if type is 'loki'_                                                                             | <ul><li>default:</li><li>loki: `loki.svc.cluster.local`</li></ul> |
| `tasks.logging.port`          | The elasticsearch port. _Only required if type is 'loki'_                                                                                          | <ul><li>default:</li><li>loki: `3100`</li></ul>                   |
| `tasks.enable.deletion`       | Will delete any workers that are completed and in non error state.                                                                                 | `true`                                                            |
| `tasks.enable.dedicatedNodes` | Runs the Flow workers to run on specific nodes with the taint `dedicated=tasks:NoSchedule` and also a label of `node-role.boomerang.io/tasks=true` | `false`                                                           |

_Note:_

1. If you choose `loki` make sure to adjust your retention period. <https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.1/manage_metrics/log_change_retention.html>
2. If you choose `default` be aware of the kubernetes log rotation and storage requirements.

_References:_

- [Kubernetes Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
- [Kubernetes Node Selection](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector)

### Boomerang Core Configuration

| Parameter         | Description                                                                          | Default Value |
| ----------------- | ------------------------------------------------------------------------------------ | ------------- |
| `core.namePrefix` | The name prefix used when installing Boomerang Core. Used to reference Core services | `bmrg-core`   |

### Image Configuration

| Parameter          | Description                                                                                                                                     | Default Value  |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| `image.registry`   | Boomerang Docker Registry                                                                                                                       | `boomerangio`  |
| `image.pullPolicy` | Image Pull Policy                                                                                                                               | `IfNotPresent` |
| `image.pullSecret` | Image Pull Secret. See [here](https://github.com/boomerang-io/charts) for more information on how to access the Boomerang-io docker containers. |                |

### Job Configuration

| Parameter                   | Description                                        | Default Value       |
| --------------------------- | -------------------------------------------------- | ------------------- |
| `job.data.enabled`          | Enable the data loader on installation and upgrade | `false`             |
| `job.data.profile`          | The data loader profile to use                     | `flow`              |
| `job.data.image.repository` | Image Repository Path                              | `/ise/<image-name>` |
| `job.data.image.tag`        | Image Version                                      | `<sem_ver>`         |

### Per Image Configuration

| Parameter          | Description                                                                                                                   | Default Value             |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| `replicaCount`     | How many pods to spin up                                                                                                      | `1`                       |
| `image.repository` | Docker Registry Image Repository                                                                                              | `/ise/<image-name>`       |
| `image.tag`        | Image Version                                                                                                                 | `<sem_ver>`               |
| `service.type`     | Service Type to Expose                                                                                                        | `NodePort` or `ClusterIP` |
| `zone`             | The network zone to be placed in if the corresponding network policy is used. Options are trusted, semitrusted, and untrusted |                           |

### Ingress Configuration

| Parameter                   | Description                                                                                                                                                             | Default Value           |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| `ingress.enabled`           | Enable creation of ingress definitions                                                                                                                                  | `false`                 |
| `ingress.root`              | Chart root context path. Can be used for putting an environment designator in front such as `/dev`.                                                                     | `""`                    |
| `ingress.host`              | An array of hosts to accept requests on                                                                                                                                 | `host.example.io`       |
| `ingress.tlsSecretName`     | If there is an associated TLS secret                                                                                                                                    | `bmrg-tls-cloud`        |
| `ingress.annotationsPrefix` | The prefix for the annotations inside the ingress definition. Typically for IKS Community Ingress you need to set it to `nginx.ingress.kubernetes.io`                   | `ingress.kubernetes.io` |
| `ingress.class`             | The class of the ingress, it is used to mark the ingress resources to be picked-up by a specific controller. For IKS Community Ingress set it to `public-iks-k8s-nginx` | `nginx`                 |
| `ingress.enableAppRoot`     | If enabled it sets the `app-root` ingress annotation to the ingress.root provided value, in order to redirect to the flow app                                           | `false`                 |

### Auth Configuration

| Parameter          | Description                                                                                    | Default Value     |
| ------------------ | ---------------------------------------------------------------------------------------------- | ----------------- |
| `auth.enabled`     | Enable addition of auth annotations on ingress                                                 | `true`            |
| `auth.mode`        | Type of auth being implemented. Relates to the Auth Proxy mode. Options are `basic` or `oauth` | `basic`           |
| `auth.serviceName` | The Boomerang Auth Proxy service to integrate to.                                              | `bmrg-auth-proxy` |
| `auth.namespace`   | The Boomerang Auth Proxy namespace                                                             |                   |
| `auth.prefix`      | The Boomerang Auth Proxy context path. This is appended to the end of `ingress.root`           | `/oauth`          |

### Database Configuration

| Parameter               | Description                                                                                                                            | Default Value                                      |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `mongodb.host`          | Connection Host or Internal Service                                                                                                    | `mongodb` or `host1:27017,host2:27017,host3:27017` |
| `mongodb.port`          | Connection Port. Leave empty if not port.                                                                                              | `27017`                                            |
| `mongodb.args`          | Additional connection parameters. Leave empty if not needed. Example: `tlsEnable=true&authSource=xxx&authMechanism=xxx&replicaSet=xxx` |                                                    |
| `mongodb.user`          | Database user                                                                                                                          | `boomerang`                                        |
| `mongodb.password`      | Database user password                                                                                                                 | `passw0rd`                                         |
| `mongodb.secretName`    | The secret containing the password from                                                                                                |                                                    |
| `mongodb.secretKey`     | The key reference inside the secret to get the password. Used in conjunction with `mongodb.secretName`. from                           |                                                    |
| `mongodb.tlsSecretName` | Secret name reference for the Base64 encoded certificate. Leave empty if you don't need to attach a TLS Secret.                        |                                                    |

Note: For `mongodb.tlsSecretName` you will need to create a generic secret and import your certificate file, e.g.

`kubectl -n <namespace> create secret generic <tlsSecretName> --from-file=mongodb.crt=<your certificate file>`

### Host Alias Configuration

| Parameter   | Description                                                                          | Default Value |
| ----------- | ------------------------------------------------------------------------------------ | ------------- |
| hostAliases | An array of hostname-IP address mappings. Adds entries to a Pod's `/etc/hosts` file. | `[]`          |

Example configuration:

```
hostAliases:
- hostnames:
  - my.example.com
  ip: 10.200.0.4
- hostnames:
  - another.example.com
  - and.another.example.com
  ip: 10.200.0.5
```

### Eventing Configuration

| Parameter           | Description                                                                                                                                                                                   | Default Value                 |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `eventing.enabled`  | Enables the producing of the WorkflowRun and TaskRun status and phase CloudEvents. If this is disabled, and you are using the default Tekton Handler, then the integration will stop working. | `true`                        |
| `eventing.sinkUrls` | A list of comma separated sink URLs. This is where the CloudEvents will be sent everytime a WorkflowRun or TaskRun changes phase or status.                                                   | `http://flow-service-handler` |

### OAuth2 Proxy Configuration

| Parameter             | Description         | Default Value |
| --------------------- | ------------------- | ------------- |
| `oauth2proxy.enabled` | Enable OAuth2 Proxy | `true`        |

### Extra Configuration

| Parameter              | Description                                   | Default Value |
| ---------------------- | --------------------------------------------- | ------------- |
| `extraConfig.services` | Extra configuration for Java backend services | `""`          |

Example configuration:

```
extraConfig:
  services: |
    server.max-http-header-size=64000
    server.tomcat.max-http-header-size=65536
    server.tomcat.max-http-post-size=2097152
```

## Known Issues

- We are currently applying the `ingress.kubernetes.io/client-max-body-size: 1m` annotation to the ingress for [issue](https://github.com/kubernetes/ingress-nginx/issues/2494).
- We only support single host ingresses

## Chart Development

In the template yaml files when reference the context `.` or Values `.Values` consideration has to be made as to whether you want to reference the static root or dynamic.

To handle the looping we set the Values and Context as variables outside of the loop at the top metadata in the template yamls.

Additionally, we have a number of the properties in the Values under `global` so that they can be provided by the parent chart.

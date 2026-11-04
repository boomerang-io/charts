# Boomerang Flow

Boomerang Flow is a modern cloud native workflow automation tool built on top of Kubernetes. Enable new ways of approaching your business tasks or combine with existing tools to extend your current workloads.

[What's new in this release?](https://www.useboomerang.io/docs/boomerang-flow/introduction/whats-new)

[How to install?](https://www.useboomerang.io/docs/boomerang-flow/installing/installing)

This chart (6.x) deploys Flow v5 and needs Flow 5.0.0-beta.39 or later. Flow v5 is one product line: one tag builds the three images this chart runs, and every image tag defaults to the chart's `appVersion`.

| Component | Image | Port | Role |
| --- | --- | --- | --- |
| `core` | `boomerangio/flow-service-core` | 7700 | API, engine, scheduler. Migrates the database as it starts. |
| `dispatcher` | `boomerangio/flow-service-dispatcher` | 7702 | Claims tasks and runs each as a Tekton TaskRun or a batch/v1 Job in this namespace |
| `web` | `boomerangio/flow-client-web` | 3000 | The browser-facing web app at `/apps/flow`. Calls service-core server-side. |

## Dependencies

- Kubernetes 1.25+
- MongoDB
- NGINX Ingress Controller (for the ingress definitions)
- Helm v3
- Tekton Pipelines, only when `dispatcher.executor` is `tekton`. The default `kube-jobs` executor needs nothing more.
- An S3-compatible object store, when run artifacts are enabled (`core.artifacts`). Use a managed service (AWS S3, Cloud Storage in S3 mode) or install your own, such as SeaweedFS, MinIO or Rook-Ceph. The chart installs none and does not create the bucket.
- An OpenID Connect identity provider. Flow v5 signs users in with OIDC itself. An authenticating proxy (OAuth2 Proxy) is needed only for a provider that is not OIDC, such as GitHub OAuth or an htpasswd file.

## Upgrading from chart 5.x (Flow v3/v4)

Chart 6.0.0 is a breaking change in values and objects:

- The loader Job and the `flow-service-loader` image are gone. service-core migrates the database itself before it serves HTTP. Read the Flow release notes on upgrading from v3 first: back up the database, check for users sharing an email, and expect no HTTP until the migrations finish.
- The migration accepts a database left by chart 4.13.5 to 4.14.3 (flow-loader 0.5.9). An older v3 install is refused at startup and must upgrade to one of those charts first. A v4 database (chart 5.x) is refused as well; restore the v3 database it came from.
- `apps.*` and `services.*` are replaced by `core`, `dispatcher` and `web`. The agent, engine and workflow services are now service-core; the agent is now the dispatcher.
- The agent and worker RBAC is replaced by the dispatcher's own ServiceAccount and Role (`templates/rbac-role-dispatcher.yaml`) and an optional task ServiceAccount (`dispatcher.tasks.serviceAccount`).
- `tasks.*` moved under `dispatcher.*`. `database.mongodb.*` stays under `global.database.mongodb` and gains `uriSecretName` and `collectionPrefix`.
- The `/_api/v2` ingress is gone; the browser no longer calls service-core.
- An upgrade in place keeps the release's generated Secret. service-core reads `FLOW_ENCRYPT_SECRET`/`FLOW_ENCRYPT_SALT` from it for both the v5 key and the v3 key, so the v3 encrypted settings decrypt without further configuration.
- Set `core.startupProbe` for the largest instance's run history and keep `core.replicaCount: 1` for the first start against a v3 database.

## Configuration

The following tables list the configurable parameters of the chart and their default values.

### General

| Parameter | Description | Default |
| --- | --- | --- |
| `general.namePrefix` | The name prefix used in the naming of all Kubernetes objects | `bmrg-flow` |
| `general.enable.apidocs` | Serve the OpenAPI spec and Swagger UI at `<root>/api/docs` | `false` |
| `general.enable.debug` | DEBUG logging in service-core and the dispatcher, port-forward advice on install | `false` |
| `image.registry` | Docker registry | `boomerangio` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.pullSecret` | Image pull secret | |
| `image.tag` | The product tag for all three images | `.Chart.AppVersion` |
| `hostAliases` | Pod `hostAliases` for the Java services | `[]` |
| `proxy.enable`, `proxy.host`, `proxy.port` | Outbound HTTP proxy for the Java services | `false` |

### service-core (`core`)

| Parameter | Description | Default |
| --- | --- | --- |
| `core.image.repository`, `core.image.tag` | Image; the tag falls back to `image.tag` | `/flow-service-core` |
| `core.replicaCount` | Replicas. The Deployment rolls one pod at a time. | `1` |
| `core.service.type` | Service type | `ClusterIP` |
| `core.resources` | Container resources | `requests.memory: 1Gi` |
| `core.startupProbe.periodSeconds`, `core.startupProbe.failureThreshold` | How long the migrations may take before the pod is restarted (period x threshold) | `10`, `180` (30 min) |
| `core.workspace.single` | `flow.workspace.single`: one seeded workspace, no workspace or user management. For an embedded engine, with security off. | `false` |
| `core.security.enabled` | `flow.security.enabled`. Set false only for a headless embedded engine. | `true` |
| `core.auth.oidc.issuer`, `core.auth.oidc.clientId` | OIDC sign-in, seeded into the auth settings while they are empty (an admin's later change wins). The issuer must be an absolute https URL. | `""` |
| `core.security.adminClaim.name`, `values`, `trustForwardedToken` | Let the identity provider decide who is an admin: a token whose claim `name` holds any of the comma-separated `values`. A proxy-forwarded JWT is read only with `trustForwardedToken`. Both empty leaves admin to the first sign-in. | `""`, `""`, `false` |
| `core.security.bootstrapToken` | `flow.security.bootstrap-token`: a `bfg_` token with 32+ further characters, registered as a global service token and used by the dispatcher. Generated and kept when empty. The chart always sets it; clearing the variable on service-core revokes the stored token at the next start. | generated |
| `core.security.existingSecret` | Secret with key `FLOW_BOOTSTRAP_TOKEN` | |
| `core.encrypt.secret`, `core.encrypt.salt` | `flow.encrypt.*`, the key secured settings are encrypted with. Required; generated and kept when empty. | generated |
| `core.encrypt.existingSecret` | Secret with keys `FLOW_ENCRYPT_SECRET`, `FLOW_ENCRYPT_SALT` | |
| `core.encrypt.v3.secret`, `core.encrypt.v3.salt`, `core.encrypt.v3.existingSecret` | The v3 pair (`mongo.encrypt.*`), read once by the migration. Secret keys `MONGO_ENCRYPT_SECRET`, `MONGO_ENCRYPT_SALT`. Not needed for an in-place upgrade. | |
| `core.migration.resetUnreadableSettings` | Blank a v3 setting that does not decrypt instead of stopping the upgrade | `false` |
| `core.artifacts.enabled` | Run artifacts in an S3-compatible store | `false` |
| `core.artifacts.store.endpoint`, `linkEndpoint`, `region`, `bucket`, `pathStyle` | Store settings (`flow.artifacts.store.*`) | |
| `core.artifacts.store.accessKey`, `secretKey`, `existingSecret` | Credentials, written to the chart Secret or read from `existingSecret` (keys `FLOW_ARTIFACTS_STORE_ACCESS_KEY`, `FLOW_ARTIFACTS_STORE_SECRET_KEY`) | |
| `core.eventing.enabled`, `core.eventing.sinkUrls` | Status CloudEvents to external sinks | `false` |
| `core.env` | Extra environment, `NAME: value`. Any `application.properties` key is settable through Spring's relaxed binding (`flow.encrypt.secret` is `FLOW_ENCRYPT_SECRET`). | `{}` |
| `core.extraEnv` | Extra raw container env entries | `[]` |

### service-dispatcher (`dispatcher`)

| Parameter | Description | Default |
| --- | --- | --- |
| `dispatcher.enabled` | Deploy the dispatcher | `true` |
| `dispatcher.image.repository`, `dispatcher.image.tag` | Image | `/flow-service-dispatcher` |
| `dispatcher.replicaCount` | Replicas | `1` |
| `dispatcher.name` | The name it registers with | `<namePrefix>-dispatcher` |
| `dispatcher.executor` | `kube-jobs` (plain batch/v1 Jobs) or `tekton` (Tekton TaskRuns, needs the CRDs) | `kube-jobs` |
| `dispatcher.taskTypes` | The task types it registers for | `template,custom,script,ai,uploadartifact,downloadartifact` |
| `dispatcher.maxInFlight` | The most tasks run at once; 0 is no cap | `25` |
| `dispatcher.logs.upload` | Store a finished task's log with service-core (needs artifacts) | `true` |
| `dispatcher.logging.type`, `host`, `port` | Where a running task's log is read: `default` (Kubernetes log API) or `loki`. The Loki query selects `boomerang_io_taskrun_ref`, `boomerang_io_workflow_ref` and `container=~"task\|step-task"`, so the log shipper must `labelmap` the task pod labels onto the stream and set the container name as `container`. | `default` |
| `dispatcher.workspace.storageClass`, `size`, `accessMode` | Workspace PVC defaults. Use `ReadWriteOnce` where the StorageClass has no RWX. | `""`, `1Gi`, `ReadWriteMany` |
| `dispatcher.tasks.serviceAccount.create`, `name`, `securityPolicy` | The ServiceAccount task pods run under (`<namePrefix>-tasks`). It has no API access. `securityPolicy` names an OpenShift SCC it may `use`. | `true` |
| `dispatcher.tasks.nodeSelector`, `tolerations`, `hostAliases`, `runtimeClassName` | Placement and runtime of task pods | |
| `dispatcher.tasks.image.pullPolicy`, `pullSecret` | Task image pulls; the secret defaults to `image.pullSecret` | `IfNotPresent` |
| `dispatcher.tasks.resources.limits.*`, `requests.*` | `memory`, `ephemeralStorage`, `cpu` applied to every task container; blank leaves a value unset | `16Gi/16Gi/""`, `2Gi/2Gi/""` |
| `dispatcher.serviceAccount.create`, `name` | The dispatcher's own ServiceAccount | `true` |
| `dispatcher.rbac.create` | Its namespace Role and RoleBinding | `true` |
| `dispatcher.env`, `dispatcher.extraEnv` | Extra environment | |

The dispatcher reaches service-core at `http://<core service>:7700`, passed as `FLOW_ENGINE_URL` (`flow.engine.url`; the variable and value are the `flow.dispatcher.engineUrlEnv` and `flow.dispatcher.engineUrl` helpers in `templates/_helpers.tpl`), and authenticates with the bootstrap token. service-core reads a running task's log from the dispatcher Service on 7702.

#### Dispatcher RBAC

The Role in `templates/rbac-role-dispatcher.yaml` grants only what the dispatcher's Kubernetes client calls: `jobs` create/get/list/watch/delete, `pods` get/list, `pods/log` get, `persistentvolumeclaims` and `configmaps` create/get/list/delete, and with the Tekton executor `taskruns` create/get/list/watch/delete plus `taskruns/status` get/update/patch. Verify with:

```sh
kubectl auth can-i create jobs --namespace <namespace> --as=system:serviceaccount:<namespace>:<namePrefix>-dispatcher
```

### client-web (`web`)

| Parameter | Description | Default |
| --- | --- | --- |
| `web.image.repository`, `web.image.tag` | Image | `/flow-client-web` |
| `web.replicaCount` | Replicas | `1` |
| `web.service.type` | Service type | `ClusterIP` |
| `web.resources` | Container resources | `requests.memory: 128Mi` |
| `web.env`, `web.extraEnv` | Extra environment | |

The web app's base path `/apps/flow` is built into the image, so it is always served at that path on the ingress host.

### Database

| Parameter | Description | Default |
| --- | --- | --- |
| `global.database.mongodb.uriSecretName`, `uriSecretKey` | A Secret holding the full connection string. Takes precedence over the parts. | `""`, `mongodb-uri` |
| `global.database.mongodb.host`, `port`, `database`, `args`, `user` | Connection parts | `mongodb`, `27017`, `boomerang`, `boomerang` |
| `global.database.mongodb.secretName`, `secretKey` | A Secret holding the password | `mongodb`, `mongodb-password` |
| `global.database.mongodb.password` | The password, written to the chart Secret when `secretName` is empty | `passw0rd` |
| `global.database.mongodb.tls.enabled` | Connect to MongoDB over TLS | `false` |
| `global.database.mongodb.tls.caSecretName`, `caKey` | A Secret holding the CA certificate in PEM. It is handed to the driver as a Spring SSL bundle, so no truststore import is needed. Leave empty for a publicly trusted certificate. | `""`, `ca.crt` |
| `global.database.mongodb.collectionPrefix` | Collection prefix. A v3 install keeps its own: the v3 `namePrefix` without `bmrg-`, dashes as underscores. | `flow` |

### Ingress

| Parameter | Description | Default |
| --- | --- | --- |
| `global.ingress.enabled` | Create the web and API ingresses | `false` |
| `global.ingress.host` | Host | `host.example.io` |
| `global.ingress.root` | Path prefix for the API routes (`<root>/api/v2`). The web app stays at `/apps/flow`. | `""` |
| `global.ingress.tlsSecretName` | TLS secret | `bmrg-tls-cloud` |
| `global.ingress.class` | `ingressClassName` | `nginx` |
| `global.ingress.annotationsPrefix` | Annotation prefix | `nginx.ingress.kubernetes.io` |
| `global.ingress.enableAppRoot` | Redirect `/` to `/apps/flow` | `false` |
| `global.ingress.annotations` | Extra annotations on both ingresses | `{}` |
| `global.ingress.api.limitRps`, `limitConnections` | Per-client-IP limits on the API ingress. Empty disables. | `"50"`, `"50"` |

The API ingress is never behind the sign-in proxy: direct API calls carry a Flow token, and webhooks, CloudEvents and the GitHub and Slack callbacks (`/api/v2/integration/...`) authenticate themselves.

### Sign-in

Flow v5 signs users in itself with OpenID Connect: the web app's server runs the authorization code flow with PKCE and service-core verifies the id token. Set the issuer and client id with `core.auth.oidc.issuer` and `core.auth.oidc.clientId`, which service-core seeds into Settings > Auth on first start, or set them later in Settings > Auth. Empty means proxy mode. Register `https://<host>/apps/flow/auth/callback` as the redirect URI with the provider; the web app derives it from the request's host and forwarded protocol.

In proxy mode an authenticating proxy guards the web app ingress and the identity it forwards (`X-Forwarded-Email`, `X-Forwarded-User`, `Authorization`) is exchanged for a Flow session by the web app's server. Use it for a provider that is not OIDC, such as GitHub OAuth or an htpasswd file; the chart can deploy the upstream oauth2-proxy chart for that (`oauth2proxy.enabled`).

On an empty database the first person to sign in activates the instance with the activation code from the chart Secret (`FLOW_ACTIVATION_CODE`, printed by the install notes) and becomes its admin. The code is generated once, kept across upgrades, and stops working after activation. With `core.security.adminClaim` set, the identity provider's claim decides admins instead.

| Parameter | Description | Default |
| --- | --- | --- |
| `global.auth.enabled` | Add the auth annotations to the web app ingress | `false` |
| `global.auth.mode` | `oauth` or `basic` (selects the proxy's sign-in route) | `oauth` |
| `global.auth.serviceName` | The proxy Service | `flow-auth-proxy` |
| `global.auth.namespace` | The proxy namespace | release namespace |
| `global.auth.prefix` | The proxy path | `/oauth` |
| `global.auth.signOutRedirect` | Where the proxy sends the browser after sign out | |
| `oauth2proxy.enabled` | Deploy the upstream oauth2-proxy chart as the proxy, with Flow's sign-in page | `false` |
| `oauth2proxy.*` | Values passed to the oauth2-proxy subchart | see `values.yaml` |

See `examples/` for a GitHub and a basic-auth proxy setup.

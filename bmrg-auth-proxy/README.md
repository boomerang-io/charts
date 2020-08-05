# Boomerang Auth Proxy

Boomerang Auth Reverse Proxy, forked from [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy), for integrating to authentication providers and has been extended to support manual provider integration for IBM ID, GitHub id, Basic Authentication and Azure AD.

### New in this release

1. IBM OIDC provider
2. Support for running on ICP Proxy node
3. Based on the pusher managed code
4. Encrypted cookie (including email and user)
5. Identity providerse without ./well-known/openid-configuration endpoint are managed as manual OIDC
6. Session refresh code
7. New config values
8. Introduced the config parameter `-cookie-path`
9. Basic-Authentication provider
10. Azure Active Directory provider
11. Redis back-end session support
12. Support for SAML based auth
13. Migrated to helm v3 structure

### Prerequisites

- Kubernetes 1.13+

### Known Issues
- This chart cannot be deployed multiple times into the same namespaces.
- Authentication Refresh for IBM OIDC
- `-skip-auth-regex` flag does not work when using a redirect

### Deployment checklist

Before deploying the `oauth-proxy` module, please make sure to follow these steps:

The helm chart comes with a default generated cookie-secret that is used to secure the cookies. 
We suggest to generate a new value by using `python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(16)).decode())'`.

#### Deployment
  - Update the following attributes.
    ```
    clientId:
    clientSecret:
    issuerUrl:
    loginUrl:
    redeemUrl:
    oidcJwksUrl:
    ```
  - Update the `--cookie-domain` argument with the full domain name of the endpoint, eg. `launch.boomerangplatform.net`,
  - Update the `--cookie-path` argument with the name proxy path, eg. `/` or `/live`,
  - Make sure you have the correct docker version and that the docker version of the `oauth-proxy` has commented out the hard-coded session expiration,
  - Update the `ingress` definition with the production correct values.
  - Run the command to update the installation `helm upgrade --install bmrg-auth-proxy-live -f bmrg-auth-proxy-values.yaml --namespace bmrg-live --tls --debug bmrg-artifactory/bmrg-auth-proxy`.

## Managing this Chart in IBM Cloud Private

 - Installing the Chart: To install the chart navigate to **Catalog**, select the chart, and run the configure and install steps.
 - Uninstalling the Chart: Navigate to **Workloads > Helm Releases** and run the uninstall step.

## Configuration

The following table lists the configurable parameters of the oauth2-proxy chart and their default values.

|                  Parameter                   |             Description               |                         Default                          |
|----------------------------------------------|---------------------------------------|----------------------------------------------------------|
| `affinity` | node/pod affinities | None
| `config.clientID` | oauth client ID | `""`
| `config.clientSecret` | oauth client secret | `""`
| `config.cookieSecret` | server specific cookie for the secret; create a new one with `python -c 'import os,base64; print base64.b64encode(os.urandom(16))'` | `""`
| `config.configFile` | custom [oauth2_proxy.cfg](https://github.com/bitly/oauth2_proxy/blob/master/contrib/oauth2_proxy.cfg.example) contents for settings not overridable via environment nor command line | `""`
| `extraArgs` | key:value list of extra arguments to give the binary | `{}`
| `image.registry` | Registry of the image | `tools.boomerangplatform.net:8500/ise`
| `image.pullPolicy` | Image pull policy | `IfNotPresent`
| `image.pullSecret` | Specify image pull secret | `boomerang-io.registrykey`
| `image.replicaCount` | desired number of pods | `1`
| `general.zone` | The zone where the pod will be deployed. Check the platform's network architecture | `untrusted`
| `ingress.enabled` | enable ingress | `false`
| `ingress.path` | The ingress path where the auth-proxy will be exposed | `/oauth`
| `ingress.host` | The host name where the auth-proxy will be exposed | `cloud.boomerangplatform.net`
| `ingress.tlsSecretName` | The TLS secret name object, that match the host attribute | `bmrg-tls-cloud`
| `annotationsPrefix` | The prefix for the annotations inside the ingress definition. Typically for IKS Community Ingress you need to set it to "nginx.ingress.kubernetes.io" | `ingress.kubernetes.io`
| `class` | The class of the ingress, it is used to mark the ingress resources to be picked-up by a specific controller. For IKS Community Ingress set it to "public-iks-k8s-nginx" | `nginx`
| `nodeSelector` | node labels for pod assignment | `{}`
| `podAnnotations` | annotations to add to each pod | `{}`
| `podLabels` | additional labesl to add to each pod | `{}`
| `resources` | pod resource requests & limits | `{}`
| `services.authProxy.image.repository` | Name of the Docker image that will secured the backend. Possible values are: bmrg-auth-proxy or bmrg-saml-proxy  | `/bmrg-auth-proxy`
| `services.authProxy.image.tag` | The tag of the Docker image that will secured the backend  | `/bmrg-auth-proxy`
| `service.type` | type of service | `ClusterIP`
| `tolerations` | List of node taints to tolerate | `[]`
| `redis.enabled` | Enable or disables the redis backend session storage | `false`
| `redis.*` | Configuration specific to redis backend | `{}`
| `auth.displayHtpasswdForm` | Enables or disables the basic-auth form | `false`
| `auth.provider` | Selects the identity provider. Possible values are: oidcw3, oidcibm, saml or empty (in case of basic auth)  | `oidcw3`
| `allowEmailList.enabled` | Enables the access filtered by the selected email list | `false`
| `allowEmailList.emailList` | Authenticate against emails via file (one per line) | `[]`

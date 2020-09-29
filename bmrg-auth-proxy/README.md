# Boomerang Auth Proxy

Boomerang Auth Reverse Proxy, forked from [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy), for integrating with authentication providers. It has been extended to support manual provider integration. Specific integrration details for the following options are described below:
 - [W3ID](#integrating-with-w3id-provider),
 - [IBM ID](#integrating-with-iBMid-provider),
 - [Basic Authentication](#integrating-with-basic-auth-authentication),
 - [GitHub](#integrating-with-gitHub-provider),
 - [Azure Active Directory](#integrating-with-azure-aD-provider) and
 - [SAML](#integrating-with-sAML-based-providers) based providers.

### New in this release

1. IBM OIDC provider
2. Support for running on ICP Proxy node
3. Based on the pusher managed code
4. Encrypted cookie (including email and user)
5. Identity providers without ./well-known/openid-configuration endpoint are managed as manual OIDC
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
- Helm v3,

### Known Issues
- This chart cannot be deployed multiple times into the same namespaces.
- Authentication Refresh for IBM OIDC
- `-skip-auth-regex` flag does not work when using a redirect

### Deployment checklist

Before deploying the `oauth-proxy` module, please make sure to follow these steps:

 - The helm chart comes with a default generated cookie-secret that is used to secure the cookies. We suggest to generate a new value by using `python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(16)).decode())'`.
 - Depending on the desired identity provider additional configurations must be done. You can check the following section for specific detailed information.


#### Integrating with w3id provider
Configuring the auth-proxy to work with w3id identity provider requires the following setup:

```yaml
auth:
  args:
  - --oidc-issuer-url=<<W3ID_ISSUER_ENDPOINT>>/isam
  - --login-url=<<W3ID_LOGIN_ENDPOINT>>/amapp-runtime-oidcidp/authorize
  - --redeem-url=<<W3ID_REDEEM_ENDPOINT>>/amapp-runtime-oidcidp/token
  - --oidc-jwks-url=<<W3ID_JWKS_ENDPOINT>>.jwk
  - --cookie-secret=L_7zkUsPN3jxRkND9zne3w==
  - --client-id=<<CLIENT_ID>>
  - --client-secret=<<CLIENT_SECRET>>
  - --set-authorization-header=true
  - --pass-authorization-header=true
  - --skip-provider-button=true
  - --skip-oidc-discovery=true
  - --insecure-oidc-allow-unverified-email=true
  - --cookie-expire=24h0m0s
  - --whitelist-domain=w3id.alpha.sso.ibm.com
  - --set-basic-auth=false
  displayHtpasswdForm: false
  provider: oidcw3
```


#### Integrating with IBMid provider
Configuring the auth-proxy to work with IBMid identity provider requires the following setup:

```yaml
auth:
  args:
  - --oidc-issuer-url=<<IBMID_ISSUER_ENDPOINT>>/default
  - --login-url=<<IBMID_LOGIN_ENDPOINT>>/default/authorize
  - --redeem-url=<<IBMID_REDEEM_ENDPOINT>>/default/token
  - --oidc-jwks-url=<<IBMID_JWKS_ENDPOINT>>/default/jwks
  - --cookie-secret=L_7zkUsPN3jxRkND9zne3w==
  - --client-id=<<CLIENT_ID>>
  - --client-secret=<<CLIENT_SECRET>>
  - --set-authorization-header=true
  - --pass-authorization-header=true
  - --skip-provider-button=true
  - --skip-oidc-discovery=true
  - --insecure-oidc-allow-unverified-email=true
  - --whitelist-domain=<<IBMID_ISSUER_ENDPOINT>>
  - --set-basic-auth=false
  displayHtpasswdForm: false
  provider: oidcibm
```


#### Integrating with basic auth authentication
To configure the auth-proxy to work with Basic-Auth you need to provide the following args:
Important arguments are:
1. Set the `display-htpasswd-form` to activate the auth-basic form.
2. The `htpasswd-file` is the path to the file that contains the usernames and passwords from within the container
3. The `basic-auth-password` is to be set to the cookie-secret in order for the up-stream systems to receive the Authorization header in the format of username:password
4. The `pass-basic-auth` and `set-basic-auth` must be set to `true` in order for the Authorization header to be passed to the up-stream systems
5. The rest of the arguments are well known and they don't need to be explained

```yaml
auth:
  args:
    - --cookie-secret=L_7zkUsPN3jxRkND9zne3w==
    - --client-id=<<CLIENT_ID>>
    - --client-secret=<<CLIENT_SECRET>>
    - --cookie-secure=true
    - --upstream=file:///dev/null
    - --http-address=0.0.0.0:4180
    - --skip-oidc-discovery=true
    - --skip-provider-button=false
    - --cookie-expire=24h0m0s
    - --htpasswd-file=/opt/config/htpasswd
    - --cookie-refresh=0
    - --pass-basic-auth=true
    - --set-basic-auth=true
    - --basic-auth-password=<<password_to_be_sent_to_upstreams>>
  displayHtpasswdForm: true
  provider:
```

The ingress of the `auth-proxy` has to have the following snippet in the `configuration-snippet`. This is for the request body to be passed on during the authentication method (where the username and password are sent from the HTTP form) and the redirect argument is sent for the multiple authentication attempts, in case the first ones are failed.  
```
proxy_pass_request_body     on;
proxy_set_header X-Auth-Request-Redirect $arg_rd;
```

The helm chart can be installed, using the values.yaml option in two ways:
- the default credentials or
- by creating a custom list of usernames/passwords and passing it as a config-map.

##### Configure using the default credentials for basic-auth provider
The `auth-proxy` Helm chart comes with a default `bmrgadmin`/`youll-come-a-waltzing-maltilda-with-me` credentials so it can be used easily without any change.
For this configuration you have to have the following set-up in the values.yaml file.
```yaml
configMap:
  htpasswdData:
```

This way, the deployment will use the default config-map `auth-proxy-users-config` which has the following data, representing the `bmrgadmin`/`youll-come-a-waltzing-maltilda-with-me` values.
```yaml
data:  
  htpasswd: |
    bmrgadmin:$2y$05$88dgk3Kl/r9dLVu7RiDreOiPYU325DW4/KeC7xPvTrmsLdfGyfX8e
```

##### Configuring using a new htpasswd file (containing custom credentials)
The `auth-proxy` Helm chart comes also with the option to provide your own usernames/passwords file, in the format documented [here](https://httpd.apache.org/docs/2.4/programs/htpasswd.html).
For this configuration, you have to have the following set-up in the values.yaml file.
```yaml
configMap:
  htpasswdData: <<<name-of-config-map-that-stores-the-custom-credentials>>>
```

To create the configmap, first generate the htpasswd file, following the instructions from the chapter bellow, and then create a normal kubernetes configmap where the data is pasted right after the `htpasswd: |` entry.
For example, let's assume you have create a `htpasswd` file with the following content (consisting of two test users):
```
testuser:{SHA}RcVxoVbdzvQTUacTvN3uW6fpVGA=
testuser2:{SHA}O1u359Ev4+VrxpvcDbzDVvZMHXM=
```
Your configmap should look like:
```yaml
data:  
  htpasswd: |
    testuser:{SHA}RcVxoVbdzvQTUacTvN3uW6fpVGA=
    testuser2:{SHA}O1u359Ev4+VrxpvcDbzDVvZMHXM=
```

Adding new users to the htpasswd file you can follow the detailed documentation from [here](https://httpd.apache.org/docs/2.4/programs/htpasswd.html). Make sure you generate the password using the sha or bcrypt options.

To create a new file with one entry with username `uname` and password `pword` use the following command.
```
htpasswd -cbs testhtpasswd uname pword
```
To add additional entries in the file just use the following command. Removing the `-c` will do it.
```
htpasswd -bs testhtpasswd uname2 pword2
```


#### Integrating with GitHub provider
Configuring the auth-proxy to work with GitHub identity provider requires the following setup:

```yaml
auth:
  args:
    - --email-domain=*
    - --cookie-secure=true
    - --upstream=file:///dev/null
    - --http-address=0.0.0.0:4180
    - --cookie-secret=L_7zkUsPN3jxRkND9zne3w==
    - --scope=user:email
    - --set-authorization-header=true
    - --pass-authorization-header=true
    - --skip-provider-button=true
    - --skip-oidc-discovery=true
    - --insecure-oidc-allow-unverified-email=true
    - --cookie-expire=24h0m0s
    - --set-basic-auth=false
  displayHtpasswdForm: false
  provider: github
```
***Note***: Make sure that in the `args` section you don't introduce the `oidc-issuer-url`, `login-url`, `redeem-url` or `oidc-jwks-url` entries that are typically necessary for other providers.


#### Integrating with Azure AD provider
To configure the `auth-proxy` to work with **Azure AD** you need to provide the following important arguments:
1. Set the `provider: azure` to activate the azure provider.
2. Because Azure's headers are very high, the auth-proxy provider must use the redis backend for session storage. We do that by `-session-store-type=redis` option. However in the helm chart provided values you don't need to explicitly provide them, this parameter as well as the url connectivity to redis will be activated based on the `redis.enabled` flag.
3. Enable `redis` middleware deployment.

```yaml
auth:
  args:
  - --cookie-secure=true
  - --upstream=file:///dev/null
  - --http-address=0.0.0.0:4180
  - --cookie-secret=L_7zkUsPN3jxRkND9zne3w==
  - --client-id=<<AZURE_ID_CLIENT_ID>>
  - --client-secret=<<AZURE_ID_CLIENT_SECRET>>
  - --skip-provider-button=true
  - --skip-oidc-discovery=true
  - --insecure-oidc-allow-unverified-email=true
  - --set-authorization-header=true
  - --pass-authorization-header=true
  - --set-basic-auth=false
  - --pass-basic-auth=false
  - --session-store-type=redis
  - --whitelist-domain=login.microsoftonline.com
  displayHtpasswdForm: false
  provider: azure
redis:
  enabled: true
```

Registering and configuring the application in Azure Portal is not in the scope of this framework, however make sure you have selected the following two permissions: `email` and `openid` in the `API permissions` page.


#### Integrating with SAML based providers
SAML based authentication works using certificates validations between the service providers and the identity providers.
The current implementation for SAML based authentication is using httpd mellon implementation and it's details can be found [here](https://jdennis.fedorapeople.org/doc/mellon-user-guide/mellon_user_guide.html).

***Known issue***: Unable to establish the Upgrade to websocket through the mellon. See the `LocationMatch` entry from proxy.conf file that needs to be adjusted to allow the upgrade of the connection.

To configure the `auth-proxy` to work with **SAML** you need to provide the following configuration:
1. Set the `provider: saml` to activate the SAML type authentication.
2. Set the `displayHtpasswdForm: false` in order to disable the basic authentication mechanism.
3. Because the SAML container is based on apache mellon module the `args` attribute must be empty. The httpd module doesn't take its arguments throught this mechanism. The correct values should be `args: `.
4. Disable `redis` middleware deployment. It is not being used while SAML authentication is activated.
5. Make sure to update the service image repository and tag to the SAML based ones. Please check the following snippet for a valid configuration.
6. Make sure to correctly update the `configmap-saml` file with the certificate, key and metadata xml for the service provider. These can be generated using the `mellon_create_metadata.sh` script from the saml image container repository.
7. Ingress must be enabled and exposed under a path that is also the `ingress.root` value for the `core`'s installation.


```yaml
auth:
  provider: saml
  displayHtpasswdForm: false
  args:
services:
  authProxy:
    image:
      repository: /bmrg-saml-proxy
      tag: 0.1.0-bmrg.1
ingress:
  enabled: true
  host: <<SERVER_HOST>>
  path: <<PATH_FOR_DEPLOYED_APP>>
  tlsSecretName: <<SECRET_NAME_FOR_TLS>>
redis:
  enabled: false
```

##### Headers passed to downstream systems

After the authentication is successful, the IDP - identity provider will send back the Response xml with the user's data that was configured in the IDP. The list of attributes sent back to the authentication proxy can be mapped in the deployment `env` section so that the mellon component will send them as headers to the downstream systems.

For example, using `auth0` IDP, you need to:
1. Update the `auth0` xml response (in the IDP admin page) to send the user's email address as a field name `EmailAddress`.
2. In the `bmrg-auth-proxy` deployment env section use this section to define an attribute that will be passed back to the downstream systems. The attributes must be prefixed with **SAML_MAP_** in order for the mellon to know to map them correctly.
```yaml
- name: SAML_MAP_EmailAddress
  value: X-WEBAUTH-EMAIL
```
3. The user's email address will be now mapped as header attribute under `X-WEBAUTH-EMAIL`.

The current implementation of `auth-proxy` is mapping the following attributes for authentication purposes for core backend:
 - User's email address under `X-WEBAUTH-EMAIL`,
 - User's first name under `X-WEBAUTH-FNAME`,
 - User's last name under `X-WEBAUTH-LNAME`.



#### Deployment
Besides the specific configuration for each identity provider here are the generic configuration that you need to do:

  - Update the following arguments:
   - `--cookie-domain` and `--cookie-path` arguments with the full domain name and the path of the deployed auth-proxy, eg. :
   ```yaml
     args:
       - --cookie-domain=useboomerang.io
       - --cookie-path=/public
   ```
   - `--client-id` and `--client-secret` arguments with the id and the secret received from the identity provider, eg. :
   ```yaml
     args:
       - --client-id=<<CLIENT_ID>>
       - --client-secret=<<CLIENT_SECRET>>
   ```
   - `--cookie-secure` and `--cookie-secret` arguments to secure the cookie that is being sent to the client. We suggest to generate a new cookie secret for each auth-proxy deployment, details above in the section named [Deployment checklist](#deployment-checklist) eg. :
   ```yaml
     args:
       - --cookie-secure=true
       - --cookie-secret=L_7zkUsPN3jxRkND9zne3w==
   ```
  - Enable the `ingress` definition and update it with the correct environment specific values,
  - Make sure you have the correct docker image version,
  - Run the command to install/update the release, eg. :

   `helm upgrade --install <<RELEASE_NAME>> --namespace <<NAMESPACE>> --debug -f <<CUSTOM_CONFIG_FILE>> boomerang-io/bmrg-auth-proxy`.

## Configuration

The following table lists the configurable parameters of the auth-proxy chart and their default values.

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

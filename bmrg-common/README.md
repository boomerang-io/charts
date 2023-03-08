# Boomerang Common Helpers

This is the common helper chart as a sharable library of helper templates which are configurable and reusable by various teams in their product chart templates.

### New in this release

1. The `bmrg.core.services` helper now supports also the metering service.
2. The `bmrg.core.services` helper now prefixes generated items with `core.` i.e. `auth.service.host` now becomes `core.auth.service.host`.
3. The common helpers offers multi Jaeger agent configuration deployment.

## Prerequisites

- Kubernetes 1.13+
- Helm v3

## Managing this chart

This chart does not install as a standalone chart. It is to be used as a dependency library by other Helm v3 charts.
In order to use this chart, you need to add the following snippet in your `Chart.yaml` descriptor file.
```
dependencies:
  - name: bmrg-common
    repository: https://raw.githubusercontent.com/boomerang-io/charts/index
    version: ~3.0.0
    alias: ch
```

## Usage

The chart exposes common helper methods to allow teams to have a unified approach in designing, building and running their own charts.

The following table lists the helper methods of the `bmrg-common` chart and their description.

|                  Method                   |             Description               |                         Example Usage                          |
|--------------------------------------------------|---------------------------------------|-------------------------------------------------------------|
| `bmrg.labels.standard`                           | This will generate all the labels used in a resources spec block of match labels and metadata labels | `{{ include "bmrg.labels.standard" (dict "context" . "platform" $platform "product" $product "tier" $tier "component" $k ) | nindent 6 }}`
| `bmrg.labels.chart` | This will generate labels for the top metadata and should conside with the recommended helm labels | `{{ include "bmrg.labels.chart" (dict "context" $ "tier" $tier "component" $k ) | nindent 6 }}`
| `bmrg.core.services` | If you need to loop through and create linkage to the Core platform services, such as in a configmap to be passed to your microservices. Handles appending the namespace if in a different namespace as long as `boomerang.core.namespace` is set in your values yaml. | `{{- include "bmrg.core.services" $ | indent 4 }}`
| `bmrg.name.prefix` | Name prefix. Will default to the chart name unless a name prefix is supplied on install | `{{- include "bmrg.name.prefix" $ }}`
| `bmrg.name` | Create a name of a resource by merging `bmrg.name.prefix` with variables for full name | `{{ include "bmrg.name" (dict "context" $ "tier" $tier "component" $k ) }}`
| `bmrg.chart` | Create chart name and version as used by the chart label. | `{{ include "bmrg.chart" }}`
| `bmrg.util.unique` | A unique 6 character random number. | `{{ include "bmrg.util.unique" }}`
| `bmrg.util.time` | Uses the `$.Release.Time` global variable and removes certain string content | `{{ include "bmrg.util.time" }`
| `bmrg.util.joinListWithNL` | Create a string from joining a list with new line. | `{{ include "bmrg.util.joinListWithNL" .Values.authorization.allowEmailList.emailList | b64enc }}`
| `bmrg.ingress.config.auth_proxy_authorization` | Inserts nginx configuration snippet to set the Authorization header | `{{- include "bmrg.ingress.config.auth_proxy_access_control" $ | nindent 6 }}`
| `bmrg.ingress.config.auth_proxy_user_email` | Inserts nginx configuration snippet to set the X-Forwarded-User and X-Forwarded-Email headers | `{{- include "bmrg.ingress.config.auth_proxy_user_email" $ | nindent 6 }}`
| `bmrg.ingress.config.auth_proxy_access_control` | Inserts nginx configuration snippet for Access Control for auth proxy. | `{{- include "bmrg.ingress.config.auth_proxy_access_control" $ | nindent 6 }}`
| `bmrg.ingress.config.auth_proxy_auth_annotations` | Inserts nginx auth-url, auth-signin and auth-response-headers ingress annotations. These rely on `auth.*` from the values yaml. | `{{- include "bmrg.ingress.config.auth_proxy_auth_annotations" $ | nindent 4 }}`
| `bmrg.ingress.config.auth_proxy_auth_annotations.global` | Inserts nginx auth-url, auth-signin and auth-response-headers ingress annotations. These rely on `global.auth.*` from the values yaml. | `{{- include "bmrg.ingress.config.auth_proxy_auth_annotations.global" $ | nindent 4 }}`
| `bmrg.ingress.config.auth_proxy_lua` | Define the Access-Control LUA block to set the header for up stream systems. | `{{- include "bmrg.ingress.config.auth_proxy_lua" $ | nindent 6 }}`
| `bmrg.host.suffix` | Get the http_origin from the `global.ingress.host` or `ingress.host` values yaml, should return subdomain.domain | `{{ include "bmrg.host.suffix" $ }}`
| `bmrg.authorization.email-domains` | Creates a list of `--email-domain=` entries based on the provided `authorization.emailDomains` values yaml. | `{{- include "bmrg.authorization.email-domains" $ }}`
| `bmrg.config.node_selector` | Define the `nodeSelector` section of the deployment based on the `nodeSelector` value yaml | `{{- include "bmrg.config.node_selector" $ }}`
| `bmrg.config.affinity` | Define the `affinity` section of the deployment based on the `affinity` value yaml | `{{- include "bmrg.config.affinity" $ }}`
| `bmrg.config.tolerations` | Define the `tolerations` section of the deployment based on the `tolerations` value yaml | `{{- include "bmrg.config.tolerations" $ }}`
| `bmrg.resources.chart` | Chart resources to insert in the pod definition.  This works by being fed a dictionary of Values plus the item for which it generates the resource request/limits. | `{{- include "bmrg.resources.chart" (dict "context" $.Values "item" $v "tier" $tier ) | nindent 10 }}`
| `bmrg.jaeger.deployment.agents` | Insert the Jaeger agents deployed as side-cars to the app container | `{{- include "bmrg.jaeger.deployment.agents" (dict "context" $.Values) }}`
| `bmrg.jaeger.config.agents` | Create the application.properties entries for the multiple agents definition. It is backward compatible with the one entry configuration | `{{- include "bmrg.jaeger.config.agents" (dict "context" $) }}`

{{- /*
********************************************************************
*** This file is shared across multiple charts, and changes must be
*** made in centralized and controlled process.
*** Do NOT modify this file with chart specific changes.
*****************************************************************

Author:
 - Tyson Lawrie (twlawrie@us.ibm.com)
 - Costel Moraru (costel.moraru-germany@ibm.com)
Last Updated:   16/12/2019
*/ -}}

{{/*
Labels to insert on object and matchLabels. This works by being fed a dictionary of current context
plus additional variables
Example Usage:  (dict "context" . "platform" $platform "product" $product "tier" $tier "component" $k "zone" $v.zone )
*/}}
{{- define "bmrg.labels.standard" -}}
platform: {{ .platform | quote }}
product: {{ .product | quote }}
{{- if .tier }}
tier: {{ .tier | quote }}
{{- end -}}
{{- if .component }}
component: {{ .component | quote }}
{{- end -}}
{{- if .zone }}
zone: {{ .zone | quote }}
{{- end -}}
{{- end -}}

{{/*
Chart labels to insert in top metadata. This works by being fed a dictionary of current context
plus additional variables
Example Usage: {{- include "bmrg.labels.chart" (dict "context" $ "tier" $tier "component" $k ) | nindent 6 }}
*/}}
{{- define "bmrg.labels.chart" -}}
name: {{ include "bmrg.name" (dict "context" .context "tier" .tier "component" .component) | quote }}
chart: {{ include "bmrg.chart" .context | quote }}
release: {{ .context.Release.Name | quote }}
heritage: {{ .context.Release.Service | quote }}
{{- end -}}

{{/*
Create a name prefix to merge with variables for full name
We truncate at 40 chars because some Kubernetes name fields are limited to 63 (by the DNS naming spec) and this is a prefix string
Example Usage: {{- include "bmrg.name" (dict "context" $ "tier" $tier "component" $k ) }}
*/}}
{{- define "bmrg.name.prefix" -}}
{{- default .Chart.Name .Values.general.namePrefix | trunc 40 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a name prefix to merge with variables for full name
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
Example Usage:
 - {{- include "bmrg.name" (dict "context" $ ) }}
 - {{- include "bmrg.name" (dict "context" $ "tier" $tier ) }}
 - {{- include "bmrg.name" (dict "context" $ "tier" $tier "component" $k ) }}
*/}}
{{- define "bmrg.name" -}}
{{- if and (.tier) (.component) }}
{{- printf "%s-%s-%s" (include "bmrg.name.prefix" .context) .tier .component | trunc 63 | trimSuffix "-" -}}
{{- else if (.tier) -}}
{{- printf "%s-%s" (include "bmrg.name.prefix" .context) .tier | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "bmrg.name.prefix" .context) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bmrg.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Insert the core services
*/}}
{{- define "bmrg.core.services" -}}
{{- if hasKey .Values "core" }}
{{- $prefix := .Values.core.namePrefix -}}
{{- $namespace := .Values.core.namespace -}}
{{- range (list "admin" "audit" "auth" "launchpad" "messaging" "slack" "mail" "notifications" "settings" "status" "support" "users" ) }}
core.{{ . }}.service.host={{ $prefix }}-services-{{ . }}{{ if $namespace }}.{{ $namespace }}{{ end }}
{{- end -}}
{{- else -}}
{{- $prefix := .Values.boomerang.core.namePrefix -}}
{{- $namespace := .Values.boomerang.core.namespace -}}
{{- range (list "admin" "audit" "auth" "launchpad" "messaging" "slack" "mail" "notifications" "settings" "status" "support" "users" ) }}
core.{{ . }}.service.host={{ $prefix }}-services-{{ . }}{{ if $namespace }}.{{ $namespace }}{{ end }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bmrg.util.unique" -}}
{{- randNumeric 6 | toString -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bmrg.util.time" -}}
{{- toString $.Release.Time | replace "seconds:" "" | replace " nano:" "" | trunc 6 | printf "%s" -}}
{{- end -}}

{{/*
Define the Authorization header to be set up for up stream systems.
*/}}
{{- define "bmrg.ingress.config.auth_proxy_authorization" -}}
auth_request_set $token $upstream_http_authorization;
proxy_set_header Authorization $token;
{{- end -}}

{{/*
Get the http_origin from the values host, should return boomerangplatform.net
*/}}
{{- define "bmrg.host.suffix" -}}
{{- if .Values.ingress.host -}}
{{- $parts := splitList "." .Values.ingress.host -}}
{{- $nElement := last $parts -}}
{{- $firstElements := initial $parts -}}
{{- $nMinusOneElement := last $firstElements -}}

{{ printf "%s\\.%s" $nMinusOneElement $nElement }}
{{- else -}}
{{ printf "*" }}
{{- end -}}
{{- end -}}


{{/*
Define the Access-Control-Allow header to be set up for up stream systems.
*/}}
{{- define "bmrg.ingress.config.auth_proxy_access_control" -}}
if ($http_origin ~* '^https?://.*\.{{ include "bmrg.host.suffix" $ }}$' ) {
add_header Access-Control-Allow-Origin $http_origin;
add_header 'Access-Control-Allow-Credentials' 'true';}
{{- end -}}

{{/*
Define the auth-* annotations for the ingress controller.
*/}}
{{- define "bmrg.ingress.config.auth_proxy_auth_annotations" -}}
{{ default "ingress.kubernetes.io" $.Values.ingress.annotationsPrefix}}/auth-signin: "https://$host{{ if $.Values.ingress.enabled }}{{ $.Values.ingress.root }}{{ end }}{{ $.Values.auth.prefix }}/{{ if eq $.Values.auth.mode "basic" }}sign_in{{ else }}start{{ end }}?rd=$request_uri"
{{ default "ingress.kubernetes.io" $.Values.ingress.annotationsPrefix}}/auth-url: "http://{{ $.Values.auth.serviceName }}.{{ $.Values.auth.namespace }}.svc.cluster.local{{ if $.Values.ingress.enabled }}{{ $.Values.ingress.root }}{{ end }}{{ $.Values.auth.prefix }}/auth"
{{- if eq $.Values.auth.mode "basic" }}
{{ default "ingress.kubernetes.io" $.Values.ingress.annotationsPrefix}}/auth-response-headers: "Authorization, X-Forwarded-User"
{{- end -}}
{{- end -}}

{{/*
Define the Access-Control LUA block to set the header for up stream systems.
*/}}
{{- define "bmrg.ingress.config.auth_proxy_lua" -}}
auth_request_set $name_upstream_1 $upstream_cookie_{{ toString $.Release.Name | replace "-" "_" }};
access_by_lua_block {
  if ngx.var.name_upstream_1 ~= "" then
    ngx.header["Set-Cookie"] = "{{ toString $.Release.Name | replace "-" "_" }}=" .. ngx.var.name_upstream_1 .. ngx.var.auth_cookie:match("(; .*)")
  end
}
{{- end -}}

{{/*
Chart resources to insert in the pod definition.  This works by being fed a dictionary of Values plus the item for which it generates the resource request/limits.
Example Usage: {{- include "bmrg.resources.chart" (dict "context" $.Values "item" $v "tier" $tier ) | nindent 10 }}
*/}}
{{- define "bmrg.resources.chart" -}}
{{- if .item.resources }}
{{- with .item.resources }}
resources:
{{ toYaml . | trim | indent 2 }}
{{- end }}
{{- else if .context.resources }}
{{- if hasKey .context.resources .tier }}
{{- with .context.resources.services }}
resources:
{{ toYaml . | trim | indent 2 }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Define the helper method to define the nodeSelector .
Example Usage: {{- include "bmrg.config.node_selector" $ }}
*/}}
{{- define "bmrg.config.node_selector" -}}
    {{- with $.Values.nodeSelector }}
      nodeSelector:
{{ toYaml . | indent 8 }}
    {{- end }}
{{- end -}}

{{/*
Define the helper method to define the affinity .
Example Usage: {{- include "bmrg.config.affinity" $ }}
*/}}
{{- define "bmrg.config.affinity" -}}
    {{- with .Values.affinity }}
      affinity:
{{ toYaml . | indent 8 }}
    {{- end }}
{{- end -}}

{{/*
Define the helper method to define the tolerations .
Example Usage: {{- include "bmrg.config.tolerations" $ }}
*/}}
{{- define "bmrg.config.tolerations" -}}
    {{- with .Values.tolerations }}
      tolerations:
{{ toYaml . | indent 8 }}
    {{- end }}
{{- end -}}

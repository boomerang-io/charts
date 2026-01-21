{{- /*
********************************************************************
*** This file is shared across multiple charts, and changes must be
*** made in centralized and controlled process.
*** Do NOT modify this file with chart specific changes.
*****************************************************************

Author:
 - Tyson Lawrie (twlawrie@us.ibm.com)
 - Costel Moraru (costel.moraru-germany@ibm.com)
 - Glen Hickman (gchickma@us.ibm.com)
Last Updated:   07/07/2022
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
{{- default .Release.Name .Values.general.namePrefix | trunc 40 | trimSuffix "-" -}}
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
{{- else if (.component) -}}
{{- printf "%s-%s" (include "bmrg.name.prefix" .context) .component | trunc 63 | trimSuffix "-" -}}
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
{{- range (list "admin" "audit" "auth" "launchpad" "messaging" "slack" "mail" "notifications" "settings" "status" "support" "users" "metering" "clamav" ) }}
core.{{ . }}.service.host={{ $prefix }}-services-{{ . }}{{ if $namespace }}.{{ $namespace }}{{ end }}
{{- end -}}
{{- else -}}
{{- $prefix := .Values.boomerang.core.namePrefix -}}
{{- $namespace := .Values.boomerang.core.namespace -}}
{{- range (list "admin" "audit" "auth" "launchpad" "messaging" "slack" "mail" "notifications" "settings" "status" "support" "users" "metering" "clamav" ) }}
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
Create a string from joining a list with new line.
Example Usage: {{ include "bmrg.util.joinListWithNL" .Values.allowEmailList.emailList }}
*/}}
{{- define "bmrg.util.joinListWithNL" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}{{- if not $local.first -}}{{ printf "\n" }}{{- end -}}{{- $v -}}{{- $_ := set $local "first" false -}}{{- end -}}
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
Define the X-Forwarded-User and X-Forwarded-Email headers to be set up for up stream systems.
*/}}
{{- define "bmrg.ingress.config.auth_proxy_user_email" -}}
auth_request_set $user   $upstream_http_x_auth_request_user;
auth_request_set $email  $upstream_http_x_auth_request_email;
proxy_set_header X-Forwarded-User  $user;
proxy_set_header X-Forwarded-Email $email;
{{- end -}}

{{/*
Get the http_origin from the values host, should return subdomain.domain
*/}}
{{- define "bmrg.host.suffix" -}}
{{- $host := "" -}}
{{- if ((($.Values).global).ingress).host }}
{{- $host = $.Values.global.ingress.host -}}
{{- else if (($.Values).ingress).host -}}
{{- $host = $.Values.ingress.host -}}
{{- end -}}
{{- if $host -}}
{{- $parts := splitList "." $host -}}
{{- $nElement := last $parts -}}
{{- $firstElements := initial $parts -}}
{{- $nMinusOneElement := last $firstElements -}}
{{ printf "%s\\.%s" $nMinusOneElement $nElement }}
{{- else -}}
{{ printf "*" }}
{{- end -}}
{{- end -}}

{{/*
Define the email domain list based on csv string
*/}}
{{- define "bmrg.authorization.email-domains" -}}
{{- if $.Values.authorization.emailDomains -}}
{{- $parts := splitList "," .Values.authorization.emailDomains -}}
{{- range $k, $v := $parts }}
{{ printf "- --email-domain=%s" $v | indent 8 }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Get the http_origin from the values host, should return fully qualified domain
*/}}
{{- define "bmrg.host.fullname" -}}
{{- $host := "" -}}
{{- if ((($.Values).global).ingress).host }}
{{- $host = $.Values.global.ingress.host -}}
{{- else if (($.Values).ingress).host -}}
{{- $host = $.Values.ingress.host -}}
{{- end -}}
{{ printf "%s" $host }}
{{- end -}}

{{/*
Define the Access-Control-Allow header to be set up for up stream systems.
*/}}
{{- define "bmrg.ingress.config.auth_proxy_access_control" -}}
add_header "Access-Control-Allow-Origin" "https://{{ include "bmrg.host.fullname" $ }}";
add_header "Access-Control-Allow-Credentials" "true";
{{- end -}}

{{- define "bmrg.ingress.config.auth_proxy_auth_annotations" -}}
{{- if hasKey $.Values "auth" -}}
{{ default "ingress.kubernetes.io" $.Values.ingress.annotationsPrefix }}/auth-signin: "https://$host{{ $.Values.auth.prefix }}/{{ if eq $.Values.auth.mode "basic" }}sign_in{{ else }}start{{ end }}?rd=$escaped_request_uri"
{{ default "ingress.kubernetes.io" $.Values.ingress.annotationsPrefix }}/auth-url: "http://{{ $.Values.auth.serviceName }}.{{ $.Values.auth.namespace }}.svc.cluster.local{{ $.Values.auth.prefix }}/auth"
{{- if eq $.Values.auth.mode "basic" }}
{{ default "ingress.kubernetes.io" $.Values.ingress.annotationsPrefix }}/auth-response-headers: "Authorization, X-Forwarded-User"
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "bmrg.ingress.config.auth_proxy_auth_annotations.global" -}}
{{- if hasKey $.Values.global "auth" -}}
{{ default "ingress.kubernetes.io" $.Values.global.ingress.annotationsPrefix }}/auth-signin: "https://$host{{ $.Values.global.auth.prefix }}/{{ if eq $.Values.global.auth.mode "basic" }}sign_in{{ else }}start{{ end }}?rd=$escaped_request_uri"
{{ default "ingress.kubernetes.io" $.Values.global.ingress.annotationsPrefix }}/auth-url: "http://{{ $.Values.global.auth.serviceName }}.{{ $.Values.global.auth.namespace }}.svc.cluster.local{{ $.Values.global.auth.prefix }}/auth"
{{- if eq $.Values.global.auth.mode "basic" }}
{{ default "ingress.kubernetes.io" $.Values.global.ingress.annotationsPrefix }}/auth-response-headers: "Authorization, X-Forwarded-User"
{{- end -}}
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

{{/*
Insert the Jaeger agents deployed as side-cars to the app cntr
Example Usage: {{- include "bmrg.jaeger.deployment.agents" (dict "context" $.Values) | nindent 8 }}
*/}}
{{- define "bmrg.jaeger.deployment.agents" -}}
{{- if .context.Values.monitoring.jaeger.enabled }}
{{- range $kj, $vj := .context.Values.monitoring.jaeger.instances }}
{{- if ne $vj.name "operational" }}
- name: "jaeger-agent-{{ $vj.name }}-cntr"
  image: "{{ $vj.agent.image.repository }}:{{ $vj.agent.image.tag }}"
  args: ["--reporter.grpc.host-port={{ $vj.collector.host }}.{{ $vj.namespace }}.svc:14250"]
  ports:
  - containerPort: 5775
    protocol: UDP
  - containerPort: 6831
    protocol: UDP
  - containerPort: 6832
    protocol: UDP
  - containerPort: 5778
    protocol: TCP
  - containerPort: 14271
    name: admin
    protocol: TCP
  livenessProbe:
    failureThreshold: 3
    httpGet:
      path: /
      port: admin
      scheme: HTTP
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 1
  readinessProbe:
    failureThreshold: 3
    httpGet:
      path: /
      port: admin
      scheme: HTTP
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 1
{{- if $vj.agent.resources }}
{{- with $vj.agent.resources }}
  resources:
{{ toYaml . | trim | indent 4 }}
{{- end }}
{{- else }}
  resources:
    limits:
      cpu: 20m
      memory: 20Mi
    requests:
      cpu: 10m
      memory: 10Mi
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the application.properties entries for the multiple agents, backward compatible
Example Usage: {{- include "bmrg.jaeger.config.agents" (dict "context" $) | nindent 4 }}
*/}}
{{- define "bmrg.jaeger.config.agents" }}
opentracing.jaeger.enabled={{ .Values.monitoring.jaeger.enabled }}
opentracing.jaeger.remote-controlled-sampler.host-port={{ .Values.monitoring.jaeger.remoteControlledSampler.host }}:{{ .Values.monitoring.jaeger.remoteControlledSampler.port }}
opentracing.jaeger.sampler-type=remote
opentracing.jaeger.sampler-param=1
{{- if .Values.monitoring.jaeger.instances }}
{{- range $index, $v := .Values.monitoring.jaeger.instances }}
opentracing.jaeger.instance.[{{ $index }}].http-sender.enabled={{ if eq $v.name "operational" }}false{{ else }}true{{ end }}
opentracing.jaeger.instance.[{{ $index }}].udp-sender.host={{ $v.agent.host }}
opentracing.jaeger.instance.[{{ $index }}].udp-sender.port={{ $v.agent.port }}
opentracing.jaeger.instance.[{{ $index }}].http-sender.url=http://{{ $v.collector.host }}.{{ $v.namespace }}:{{ $v.collector.port }}/api/traces
{{- end }}
{{- else }}
# backward compatible jaeger reporters definition
opentracing.jaeger.instance.[0].http-sender.enabled=true
opentracing.jaeger.instance.[0].udp-sender.host={{ .Values.monitoring.jaeger.agent.host }}.{{ .Values.monitoring.jaeger.namespace }}
opentracing.jaeger.instance.[0].udp-sender.port={{ .Values.monitoring.jaeger.agent.port }}
opentracing.jaeger.instance.[0].http-sender.url=http://{{ .Values.monitoring.jaeger.collector.host }}.{{ .Values.monitoring.jaeger.namespace }}:{{ .Values.monitoring.jaeger.collector.port }}/api/traces
{{- end }}
{{- end -}}

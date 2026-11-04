{{/*
Chart-local helpers. Shared helpers come from bmrg-common (bmrg.*).
*/}}

{{/*
The environment variable the dispatcher reads service-core's address from, and its value: one full
URL (flow.engine.url, boomerang-io/flow#755). Images released before flow#808 read FLOW_ENGINE_SERVICE_HOST
(host:port) and default flow.engine.url to http://${flow.engine.service.host}; FLOW_ENGINE_URL overrides
that default on them as well, so one variable serves both.
*/}}
{{- define "flow.dispatcher.engineUrlEnv" -}}
FLOW_ENGINE_URL
{{- end -}}

{{- define "flow.dispatcher.engineUrl" -}}
http://{{ include "flow.core.serviceName" . }}:7700
{{- end -}}

{{- define "flow.core.serviceName" -}}
{{ include "bmrg.name" (dict "context" . "tier" "service" "component" "core") }}
{{- end -}}

{{- define "flow.dispatcher.serviceName" -}}
{{ include "bmrg.name" (dict "context" . "tier" "service" "component" "dispatcher") }}
{{- end -}}

{{- define "flow.web.serviceName" -}}
{{ include "bmrg.name" (dict "context" . "tier" "apps" "component" "flow") }}
{{- end -}}

{{- define "flow.secretName" -}}
{{ include "bmrg.name" (dict "context" . "tier" "secrets") }}
{{- end -}}

{{/*
Image reference. Usage: include "flow.image" (dict "context" $ "image" .Values.core.image)
Tag precedence: component tag, image.tag, .Chart.AppVersion.
*/}}
{{- define "flow.image" -}}
{{- $tag := default (default .context.Chart.AppVersion .context.Values.image.tag) .image.tag -}}
{{- printf "%s%s:%s" .context.Values.image.registry .image.repository $tag -}}
{{- end -}}

{{- define "flow.dispatcher.name" -}}
{{ default (printf "%s-dispatcher" (include "bmrg.name.prefix" .)) .Values.dispatcher.name }}
{{- end -}}

{{- define "flow.dispatcher.serviceAccountName" -}}
{{- if .Values.dispatcher.serviceAccount.create -}}
{{ default (include "bmrg.name" (dict "context" . "component" "dispatcher")) .Values.dispatcher.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.dispatcher.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "flow.tasks.serviceAccountName" -}}
{{- if .Values.dispatcher.tasks.serviceAccount.create -}}
{{ default (include "bmrg.name" (dict "context" . "component" "tasks")) .Values.dispatcher.tasks.serviceAccount.name }}
{{- else -}}
{{ .Values.dispatcher.tasks.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
MongoDB connection string built from the parts. The password is expanded by Kubernetes from the
MONGODB_PASSWORD variable defined before it, so it never appears in the pod spec.
*/}}
{{- define "flow.mongodb.uri" -}}
{{- with .Values.global.database.mongodb -}}
mongodb://{{ if .user }}{{ .user }}:$(MONGODB_PASSWORD)@{{ end }}{{ .host }}{{ if .port }}:{{ .port }}{{ end }}/{{ .database }}{{ if .args }}?{{ .args }}{{ end }}
{{- end -}}
{{- end -}}

{{/*
The public origin plus ingress root, e.g. https://flow.example.io/dev. Empty without an ingress.
*/}}
{{- define "flow.externalUrl" -}}
{{- if .Values.global.ingress.enabled -}}
https://{{ .Values.global.ingress.host }}{{ default "" .Values.global.ingress.root }}
{{- end -}}
{{- end -}}

{{/*
Environment shared by the Java services.
*/}}
{{- define "flow.env.common" -}}
- name: FLOW_ENVIRONMENT
  value: {{ .Release.Namespace | quote }}
- name: FLOW_INSTANCE
  value: {{ .Release.Name | quote }}
- name: FLOW_PRODUCT
  value: {{ include "bmrg.name.prefix" . | quote }}
- name: FLOW_VERSION
  value: {{ .Chart.AppVersion | quote }}
{{- if .Values.proxy.enable }}
- name: PROXY_ENABLE
  value: "true"
- name: PROXY_HOST
  value: {{ .Values.proxy.host | quote }}
- name: PROXY_PORT
  value: {{ .Values.proxy.port | quote }}
{{- end }}
{{- end -}}

{{/*
Render a NAME: value map as container env entries.
*/}}
{{- define "flow.env.map" -}}
{{- range $k, $v := . }}
- name: {{ $k }}
  value: {{ $v | quote }}
{{- end }}
{{- end -}}

{{/*
Return the target Kubernetes version
*/}}
{{- define "helper.kubeVersion" -}}
{{- if .Capabilities.KubeVersion.Version -}}
{{- .Capabilities.KubeVersion.Version -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
Usage:
{{ include "helper.ingress.apiVersion" $ }}
*/}}
{{- define "helper.ingress.apiVersion" -}}
{{- if .Values.global.ingress.enabled -}}
{{- if semverCompare "<1.14-0" (include "helper.kubeVersion" .) -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" (include "helper.kubeVersion" .) -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate backend entry that is compatible with all Kubernetes API versions.
Usage:
{{ include "helper.ingress.backend" (dict "serviceName" "backendName" "servicePort" "backendPort" "context" $) }}

Params:
  - serviceName - String. Name of an existing service backend
  - servicePort - String/Int. Port name (or number) of the service. It will be translated to different yaml depending if it is a string or an integer.
  - context - Dict - Required. The context for the template evaluation.
*/}}
{{- define "helper.ingress.backend" -}}
{{- $apiVersion := (include "helper.ingress.apiVersion" .context) -}}
{{- if or (eq $apiVersion "extensions/v1beta1") (eq $apiVersion "networking.k8s.io/v1beta1") -}}
serviceName: {{ .serviceName }}
servicePort: {{ .servicePort }}
{{- else -}}
service:
  name: {{ .serviceName }}
  port:
    {{- if typeIs "string" .servicePort }}
    name: {{ .servicePort }}
    {{- else if or (typeIs "int" .servicePort) (typeIs "float64" .servicePort) }}
    number: {{ .servicePort | int }}
    {{- end }}
{{- end -}}
{{- end -}}

{{/*
Print "true" if the API pathType field is supported
Usage:
{{ include "helper.ingress.supportsPathType" $ }}
*/}}
{{- define "helper.ingress.supportsPathType" -}}
{{- if (semverCompare "<1.18-0" (include "helper.kubeVersion" .)) -}}
{{- print "false" -}}
{{- else -}}
{{- print "true" -}}
{{- end -}}
{{- end -}}

{{/*
Returns true if the ingressClassname field is supported
Usage:
{{ include "helper.ingress.supportsIngressClassname" $ }}
*/}}
{{- define "helper.ingress.supportsIngressClassname" -}}
{{- if semverCompare "<1.18-0" (include "helper.kubeVersion" .) -}}
{{- print "false" -}}
{{- else -}}
{{- print "true" -}}
{{- end -}}
{{- end -}}
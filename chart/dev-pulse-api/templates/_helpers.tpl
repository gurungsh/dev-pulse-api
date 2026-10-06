{{- define "dev-pulse-api.name" -}}
{{ .Release.Name }}
{{- end }}

{{- define "dev-pulse-api.postgresqlName" -}}
{{ .Release.Name }}-postgresql
{{- end }}

{{- define "dev-pulse-api.labels" -}}
app.kubernetes.io/part-of: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "dev-pulse-api.appSelectorLabels" -}}
app.kubernetes.io/name: {{ include "dev-pulse-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: api
{{- end }}

{{- define "dev-pulse-api.postgresqlSelectorLabels" -}}
app.kubernetes.io/name: {{ include "dev-pulse-api.postgresqlName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
{{- end }}

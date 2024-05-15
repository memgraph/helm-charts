
{{/* Full name of the application */}}
{{- define "memgraph.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}



{{/* Define the chart version and app version */}}
{{- define "memgraph.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}


{{/* Define the name of the application */}}
{{- define "memgraph.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end -}}


{{/* Common labels */}}
{{- define "memgraph.labels" -}}
app.kubernetes.io/name: {{ include "memgraph.name" . }}
helm.sh/chart: {{ include "memgraph.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}


{{/*
Create the name of the service account to use
*/}}
{{- define "memgraph.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "memgraph.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

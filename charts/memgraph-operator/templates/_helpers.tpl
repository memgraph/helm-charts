{{/*
Chart name, overridable with nameOverride.
*/}}
{{- define "memgraph-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified release name, the prefix of every object this chart creates.
*/}}
{{- define "memgraph-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Name of the controller Deployment, its ServiceAccount and its metrics Service.
*/}}
{{- define "memgraph-operator.managerName" -}}
{{- printf "%s-controller-manager" (include "memgraph-operator.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name of the Service in front of the metrics endpoint.
*/}}
{{- define "memgraph-operator.metricsServiceName" -}}
{{- printf "%s-metrics-service" (include "memgraph-operator.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Namespace the namespaced objects are installed into.
*/}}
{{- define "memgraph-operator.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride }}
{{- end }}

{{- define "memgraph-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels. The Deployment selector is immutable, so these must stay
stable across chart versions.
*/}}
{{- define "memgraph-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "memgraph-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
control-plane: controller-manager
{{- end }}

{{- define "memgraph-operator.labels" -}}
helm.sh/chart: {{ include "memgraph-operator.chart" . }}
{{ include "memgraph-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/component: controller
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
ServiceAccount the operator runs as. An externally managed account must be
named explicitly, because the chart cannot bind a name it does not know.
*/}}
{{- define "memgraph-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "memgraph-operator.managerName" .) .Values.serviceAccount.name }}
{{- else }}
{{- required "serviceAccount.name is required when serviceAccount.create is false" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

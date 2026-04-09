{{/*
Expand the name of the chart.
*/}}
{{- define "memgraph.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "memgraph.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "memgraph.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "memgraph.labels" -}}
helm.sh/chart: {{ include "memgraph.chart" . }}
{{ include "memgraph.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "memgraph.selectorLabels" -}}
app.kubernetes.io/name: {{ include "memgraph.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

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

{{- define "container.readinessProbe" -}}
readinessProbe:
{{- if .exec }}
  exec:
    command:
{{- range .exec.command }}
    - {{ . | quote }}
{{- end }}
{{- else }}
  tcpSocket:
    port: {{ .tcpSocket.port }}
{{- end }}
  failureThreshold: {{ .failureThreshold }}
  timeoutSeconds: {{ .timeoutSeconds }}
  periodSeconds: {{ .periodSeconds }}
  initialDelaySeconds: {{ .initialDelaySeconds }}
{{- end }}


{{- define "container.livenessProbe" -}}
livenessProbe:
{{- if .exec }}
  exec:
    command:
{{- range .exec.command }}
    - {{ . | quote }}
{{- end }}
{{- else }}
  tcpSocket:
    port: {{ .tcpSocket.port }}
{{- end }}
  failureThreshold: {{ .failureThreshold }}
  timeoutSeconds: {{ .timeoutSeconds }}
  periodSeconds: {{ .periodSeconds }}
  initialDelaySeconds: {{ .initialDelaySeconds }}
{{- end }}


{{- define "container.startupProbe" -}}
startupProbe:
{{- if .exec }}
  exec:
    command:
{{- range .exec.command }}
    - {{ . | quote }}
{{- end }}
{{- else }}
  tcpSocket:
    port: {{ .tcpSocket.port }}
{{- end }}
  failureThreshold: {{ .failureThreshold }}
  timeoutSeconds: {{ .timeoutSeconds }}
  periodSeconds: {{ .periodSeconds }}
  initialDelaySeconds: {{ .initialDelaySeconds }}
{{- end }}

{{- define "memgraph.vector.script" -}}
# Give Memgraph time to open the log websocket (avoids "Connection refused" on startup)
sleep 15
cat > /tmp/vector.yaml << VECEOF
data_dir: /tmp/vector-data

sources:
  memgraph_logs:
    type: websocket
    uri: "ws://127.0.0.1:{{ .Values.service.websocketPortMonitoring }}"

transforms:
  enrich:
    type: remap
    inputs: [memgraph_logs]
    source: |
      normalized_level = ""
      if exists(.message) && is_string(.message) {
        parsed, err = parse_json(.message)
        if err == null && is_object(parsed) {
          . = merge!(., parsed)
        }
      }
      if exists(.level) {
        normalized_level = downcase(to_string!(.level))
      } else if exists(.severity) {
        normalized_level = downcase(to_string!(.severity))
      }
      if normalized_level == "warning" {
        normalized_level = "warn"
      } else if normalized_level == "critical" {
        normalized_level = "fatal"
      }
      if normalized_level == "" {
        normalized_level = "unknown"
      }
      .level = normalized_level
      if !exists(._msg) {
        if exists(.message) {
          ._msg = to_string!(.message)
        } else if exists(.msg) {
          ._msg = to_string!(.msg)
        } else if exists(.log) {
          ._msg = to_string!(.log)
        } else {
          ._msg = encode_json(.)
        }
      }
      .message = ._msg
      .app = "memgraph"
      .job = "memgraph"
      .role = get_env_var!("ROLE")
      .namespace = get_env_var!("POD_NAMESPACE")
      .pod = get_env_var!("POD_NAME")
      .cluster_id = get_env_var!("CLUSTER_ID")
      .service_name = get_env_var!("SERVICE_NAME")
      .cluster_env = get_env_var!("CLUSTER_ENV")

sinks:
  logs:
    type: loki
    inputs: [enrich]
    endpoint: "{{ required "vectorRemote.logsEndpoint is required when vectorRemote is enabled" .Values.vectorRemote.logsEndpoint }}"
    healthcheck:
      enabled: false
{{- if .Values.vectorRemote.auth.secretName }}
    auth:
      strategy: basic
      user: "{{ "$" }}{{ "{MONITORING_USERNAME}" }}"
      password: "{{ "$" }}{{ "{MONITORING_PASSWORD}" }}"
{{- end }}
    encoding:
      codec: text
    labels:
      app: "{{ "{{ app }}" }}"
      job: "{{ "{{ job }}" }}"
      role: "{{ "{{ role }}" }}"
      namespace: "{{ "{{ namespace }}" }}"
      pod: "{{ "{{ pod }}" }}"
      level: "{{ "{{ level }}" }}"
      cluster_id: "{{ "{{ cluster_id }}" }}"
      service_name: "{{ "{{ service_name }}" }}"
      cluster_env: "{{ "{{ cluster_env }}" }}"
    remove_label_fields: true
VECEOF
mkdir -p /tmp/vector-data
exec vector -c /tmp/vector.yaml
{{- end }}

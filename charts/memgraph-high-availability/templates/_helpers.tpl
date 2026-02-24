
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

{{- define "container.data.readinessProbe" -}}
readinessProbe:
  tcpSocket:
    port: {{ .tcpSocket.port }}
  failureThreshold: {{ .failureThreshold }}
  timeoutSeconds: {{ .timeoutSeconds }}
  periodSeconds: {{ .periodSeconds }}
{{- end }}


{{- define "container.data.livenessProbe" -}}
livenessProbe:
  tcpSocket:
    port: {{ .tcpSocket.port }}
  failureThreshold: {{ .failureThreshold }}
  timeoutSeconds: {{ .timeoutSeconds }}
  periodSeconds: {{ .periodSeconds }}
{{- end }}


{{- define "container.data.startupProbe" -}}
startupProbe:
  tcpSocket:
    port: {{ .tcpSocket.port }}
  failureThreshold: {{ .failureThreshold }}
  timeoutSeconds: {{ .timeoutSeconds }}
  periodSeconds: {{ .periodSeconds }}
{{- end }}



{{- define "container.coordinators.readinessProbe" -}}
readinessProbe:
  tcpSocket:
    port: {{ .tcpSocket.port }}
  failureThreshold: {{ .failureThreshold }}
  timeoutSeconds: {{ .timeoutSeconds }}
  periodSeconds: {{ .periodSeconds }}
{{- end }}


{{- define "container.coordinators.livenessProbe" -}}
livenessProbe:
  tcpSocket:
    port: {{ .tcpSocket.port }}
  failureThreshold: {{ .failureThreshold }}
  timeoutSeconds: {{ .timeoutSeconds }}
  periodSeconds: {{ .periodSeconds }}
{{- end }}


{{- define "container.coordinators.startupProbe" -}}
startupProbe:
  tcpSocket:
    port: {{ .tcpSocket.port }}
  failureThreshold: {{ .failureThreshold }}
  timeoutSeconds: {{ .timeoutSeconds }}
  periodSeconds: {{ .periodSeconds }}
{{- end }}


{{/*
Core dump uploader sidecar container.
Expects a dict with keys: volumeName, mountPath, values (coreDumpUploader values block).
*/}}
{{- define "memgraph.coreDumpUploader" -}}
- name: core-dump-uploader
  image: "{{ .values.image.repository }}:{{ .values.image.tag }}"
  imagePullPolicy: {{ .values.image.pullPolicy }}
  command: ["/bin/sh", "-c"]
  args:
    - |
      WATCH_DIR="$WATCH_DIR"
      UPLOADED="/tmp/uploaded_files"
      touch "$UPLOADED"
      echo "Core dump uploader started. Watching $WATCH_DIR every ${POLL_INTERVAL}s."
      while true; do
        for f in "$WATCH_DIR"/core.*; do
          [ -e "$f" ] || continue
          fname=$(basename "$f")
          if grep -qxF "$fname" "$UPLOADED"; then
            continue
          fi
          echo "New core dump detected: $fname. Waiting 5s for write to complete..."
          sleep 5
          echo "Uploading $fname to s3://${S3_BUCKET}/${S3_PREFIX}/${HOSTNAME}/${fname}"
          aws s3 cp "$f" "s3://${S3_BUCKET}/${S3_PREFIX}/${HOSTNAME}/${fname}" --region "$AWS_REGION"
          if [ $? -eq 0 ]; then
            echo "$fname" >> "$UPLOADED"
            echo "Upload complete: $fname"
          else
            echo "Upload failed: $fname. Will retry next cycle."
          fi
        done
        sleep "$POLL_INTERVAL"
      done
  env:
    - name: WATCH_DIR
      value: {{ .mountPath | quote }}
    - name: S3_BUCKET
      value: {{ .values.s3BucketName | quote }}
    - name: S3_PREFIX
      value: {{ .values.s3Prefix | quote }}
    - name: AWS_REGION
      value: {{ .values.awsRegion | quote }}
    - name: POLL_INTERVAL
      value: {{ .values.pollIntervalSeconds | quote }}
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: {{ .values.secretName }}
          key: {{ .values.accessKeySecretKey }}
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: {{ .values.secretName }}
          key: {{ .values.secretAccessKeySecretKey }}
  volumeMounts:
    - name: {{ .volumeName }}
      mountPath: {{ .mountPath }}
      readOnly: true
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
    readOnlyRootFilesystem: false
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  {{- with .values.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}

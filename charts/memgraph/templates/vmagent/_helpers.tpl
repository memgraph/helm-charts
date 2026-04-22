{{/*
Helpers for the vmagent workload. The workload is split across
vmagent/configmap.yaml, vmagent/rbac.yaml, and vmagent/deployment.yaml —
these helpers centralize shared values and validations so each file does
not re-derive them.
*/}}

{{- define "memgraph.vmagent.namespace" -}}
{{- .Values.vmagentRemote.namespace | default .Values.prometheus.namespace -}}
{{- end -}}

{{- define "memgraph.vmagent.exporterNamespace" -}}
{{- .Values.prometheus.namespace -}}
{{- end -}}

{{/* "true" when optional Kubernetes scrape jobs are enabled, empty otherwise. */}}
{{- define "memgraph.vmagent.kubernetesMetricsEnabled" -}}
{{- if .Values.vmagentRemote.kubernetes.enabled -}}true{{- end -}}
{{- end -}}

{{/* "true" when at least one enabled scrape job needs Kubernetes API access. */}}
{{- define "memgraph.vmagent.kubernetesApiAccessRequired" -}}
{{- if and (include "memgraph.vmagent.kubernetesMetricsEnabled" .) (or .Values.vmagentRemote.kubernetes.kubelet.enabled (and .Values.vmagentRemote.kubernetes.nodeExporter.enabled .Values.vmagentRemote.kubernetes.nodeExporter.useKubernetesDiscovery)) -}}true{{- end -}}
{{- end -}}

{{/* Runs all vmagent value validations. Callers must gate this on vmagentRemote.enabled. */}}
{{- define "memgraph.vmagent.validations" -}}
{{- if not .Values.prometheus.enabled -}}
{{- fail "vmagentRemote.enabled requires prometheus.enabled=true because vmagentRemote scrapes mg-exporter" -}}
{{- end -}}
{{- if and .Values.vmagentRemote.remoteWrite.basicAuth.secretName (not .Values.vmagentRemote.remoteWrite.basicAuth.usernameKey) -}}
{{- fail "vmagentRemote.remoteWrite.basicAuth.usernameKey must be set when vmagentRemote.remoteWrite.basicAuth.secretName is provided" -}}
{{- end -}}
{{- if and .Values.vmagentRemote.remoteWrite.basicAuth.secretName (not .Values.vmagentRemote.remoteWrite.basicAuth.passwordKey) -}}
{{- fail "vmagentRemote.remoteWrite.basicAuth.passwordKey must be set when vmagentRemote.remoteWrite.basicAuth.secretName is provided" -}}
{{- end -}}
{{- $k8s := include "memgraph.vmagent.kubernetesMetricsEnabled" . -}}
{{- if and $k8s .Values.vmagentRemote.kubernetes.kubeStateMetrics.enabled (not .Values.vmagentRemote.kubernetes.kubeStateMetrics.targets) -}}
{{- fail "vmagentRemote.kubernetes.kubeStateMetrics.targets must contain at least one target when kubeStateMetrics is enabled" -}}
{{- end -}}
{{- if and $k8s .Values.vmagentRemote.kubernetes.nodeExporter.enabled (not .Values.vmagentRemote.kubernetes.nodeExporter.useKubernetesDiscovery) (not .Values.vmagentRemote.kubernetes.nodeExporter.targets) -}}
{{- fail "vmagentRemote.kubernetes.nodeExporter.targets must contain at least one target when nodeExporter is enabled" -}}
{{- end -}}
{{- if and $k8s .Values.vmagentRemote.kubernetes.kubelet.enabled (not .Values.vmagentRemote.kubernetes.kubelet.apiServerAddress) -}}
{{- fail "vmagentRemote.kubernetes.kubelet.apiServerAddress must be set when kubelet scraping is enabled" -}}
{{- end -}}
{{- if and $k8s .Values.vmagentRemote.kubernetes.kubelet.enabled (not .Values.vmagentRemote.kubernetes.kubelet.metricsPath) -}}
{{- fail "vmagentRemote.kubernetes.kubelet.metricsPath must be set when kubelet scraping is enabled" -}}
{{- end -}}
{{- if and $k8s .Values.vmagentRemote.kubernetes.kubelet.additionalMetricsEnabled (not .Values.vmagentRemote.kubernetes.kubelet.additionalJobName) -}}
{{- fail "vmagentRemote.kubernetes.kubelet.additionalJobName must be set when additional kubelet metrics scraping is enabled" -}}
{{- end -}}
{{- if and $k8s .Values.vmagentRemote.kubernetes.kubelet.additionalMetricsEnabled (not .Values.vmagentRemote.kubernetes.kubelet.additionalMetricsPath) -}}
{{- fail "vmagentRemote.kubernetes.kubelet.additionalMetricsPath must be set when additional kubelet metrics scraping is enabled" -}}
{{- end -}}
{{- end -}}

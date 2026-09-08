# memgraph-prometheus-exporter

Standalone Helm chart for the [Memgraph HA Prometheus exporter](https://github.com/memgraph/prometheus-exporter). It deploys the exporter (a `Deployment` + `Service` + optional `ServiceMonitor`); the exporter polls each Memgraph node's `:9091` JSON metrics endpoint and exposes aggregated + HA cluster-state metrics (main/replica roles, coordinator leadership) on `exporter.port` (default `9115`). Memgraph must serve JSON on `:9091` (its default) — not OpenMetrics — or the exporter cannot parse the response.

Use this when Memgraph runs **outside** Kubernetes (e.g. on EC2) and you only want the exporter in-cluster — the full `memgraph-high-availability` chart bundles the exporter with Memgraph itself.

## Instance list — three interchangeable sources

The exporter needs an explicit per-node list. This chart can build it three ways (precedence top to bottom):

| Source | `values` | External dependency |
|---|---|---|
| Existing Secret | `hosts.existingSecret.name` | a `Secret` holding a ready `ha_config.yaml` (e.g. synced from a secrets manager) |
| Explicit list | `hosts.instances[]` | none |
| Templated (default) | `hosts.cluster.*` | none |

Templated mode derives every node URL from the deterministic naming `‹namePrefix›-{coordinator,data}-‹startIndex+i›.‹domain›`. Every string field is rendered with `tpl`, so values may contain Helm expressions:

```yaml
hosts:
  cluster:
    namePrefix: '{{ .Values.global.env }}-memgraph-adr'
    domain: '{{ .Values.global.internalDomainSuffix }}'
    coordinatorCount: 3
    dataCount: 3
```

## Notes
- The exporter reads its config once at startup; the Deployment carries a `checksum/ha-config` annotation so it rolls when the templated/explicit list changes. For the Secret source, set `reloaderEnabled: true` (requires Stakater Reloader) so it rolls on Secret change.
- `global.imageRegistry` overrides `image.registry` (point at a private mirror without editing the chart).
- `serviceMonitor.enabled` is `false` by default (it needs the Prometheus Operator CRDs); set it `true` where the operator is installed.
- **Cluster mode** requires `hosts.cluster.namePrefix` and `hosts.cluster.domain` to be set (otherwise the rendered URLs are incomplete).
- **Instances mode**: each entry needs `name`, `url` (host only — no `:port`), `port`, and `type` (`coordinator` or `data_instance`); add `skipTlsVerify: true` for an `https` node.
- **existingSecret mode**: the Secret's `ha_config.yaml` is used verbatim — its `exporter.port` must match `.Values.exporter.port` (the Service/probe port), and instance `type`s must be `coordinator`/`data_instance` or the exporter exits.

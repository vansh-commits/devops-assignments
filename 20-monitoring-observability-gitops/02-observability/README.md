# Session 20 – Task 2: Observability

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

## What is observability?

**Observability** is how well you can understand what is happening *inside* a system just by looking at the data it produces from the outside. If a system is observable, you can answer questions like *"why is checkout slow only for some users since 3 pm?"* – even if you never thought of that question before.

### Monitoring vs observability

| Monitoring | Observability |
| :--- | :--- |
| Watches **known** problems (known-unknowns) | Helps investigate **new/unexpected** problems (unknown-unknowns) |
| "Is something wrong?" | "**Why** is it wrong, and where?" |
| Dashboards + alerts on fixed thresholds | Rich, correlated data you can slice and query freely |
| Example: alert when CPU > 80% | Example: follow one slow request across 6 microservices to find the DB query causing it |

Monitoring is actually a part of observability – you need both.

## The three pillars

### 1. Metrics

**Metrics** are **numbers measured over time** (time-series), usually with labels.

- Examples: CPU %, memory used, requests per second, error rate, p95 latency, number of pod restarts.
- Very cheap to store and fast to query, so good for **dashboards and alerts**.
- They tell you **that** something is wrong and **how much**, but not the exact details.
- Common methods: **RED** (Rate, Errors, Duration) for services, **USE** (Utilisation, Saturation, Errors) for resources, and Google's **4 golden signals** (latency, traffic, errors, saturation).

```text
http_requests_total{service="checkout", status="500"}  1523   @ 15:02:00
```

### 2. Logs

**Logs** are **timestamped text records of events** that happened.

- Examples: `ERROR payment failed: connection timeout to db:5432`, nginx access logs, stack traces.
- Very detailed – they tell you **what exactly happened**.
- Can get large and expensive; best written as **structured logs** (JSON) so they can be searched and filtered.

```json
{"time":"2026-10-15T15:02:11Z","level":"error","service":"payment","trace_id":"a1b2c3","msg":"db timeout after 2000ms"}
```

### 3. Traces

A **trace** follows **one request through all the services** it touches. Each step is a **span** with a start time and duration; spans are linked by a **trace ID**.

- Tells you **where** the time is spent or where the error happened in a distributed system.
- Needs the app to be instrumented (OpenTelemetry SDK) or a service mesh.

```text
Trace a1b2c3  (total 2.4 s)
└─ frontend   GET /checkout         2.4 s
   └─ cart-service  getCart          0.05 s
   └─ payment-service charge         2.3 s   ← slow!
      └─ postgres  SELECT ...         2.2 s   ← root cause
```

### How they work together

```text
Metrics  →  alert: "checkout error rate is 12%"          (WHAT / symptom)
Traces   →  "the slow part is payment → postgres"         (WHERE)
Logs     →  "db timeout after 2000ms, pool exhausted"     (WHY / details)
```

The trick is **correlation** – putting the same `trace_id` in logs and linking dashboards to traces so you can jump between the three.

## Why observability is required

- **Microservices and Kubernetes are distributed** – one user click can go through 10+ services, pods move between nodes and get recreated, so you can't just SSH into "the server" and read a log file.
- **Faster incident response** – reduce MTTD (mean time to detect) and MTTR (mean time to recover).
- **Unknown failures** – real outages are often things nobody built a dashboard for.
- **SLOs / SLAs** – to promise 99.9% availability you need to measure it.
- **Performance tuning and capacity planning** – find bottlenecks, right-size resources, save cost.
- **Safe deployments** – compare error rate/latency before and after a release (canary analysis), and roll back quickly.

## Common tools

| Pillar | Open source | Managed / commercial |
| :--- | :--- | :--- |
| Metrics | **Prometheus**, Grafana, Thanos/Mimir, VictoriaMetrics | Datadog, New Relic, CloudWatch, Grafana Cloud |
| Logs | **Loki**, ELK (Elasticsearch + Logstash + Kibana), EFK (Fluentd/Fluent Bit), OpenSearch | Splunk, Datadog Logs, CloudWatch Logs |
| Traces | **Jaeger**, Grafana **Tempo**, Zipkin | AWS X-Ray, Datadog APM, Honeycomb |
| All / standard | **OpenTelemetry** (vendor-neutral SDKs + Collector for metrics, logs and traces) | Dynatrace, Elastic Observability |
| Alerting | Alertmanager, Grafana Alerting | PagerDuty, Opsgenie |

A very common open-source combo is the **"LGTM" stack**: **L**oki (logs), **G**rafana (visualisation), **T**empo (traces), **M**imir/Prometheus (metrics), with OpenTelemetry for collection.

## Kubernetes observability

### Metrics in Kubernetes

| Source | Gives |
| :--- | :--- |
| **metrics-server** | current CPU/memory of pods & nodes → `kubectl top`, HPA |
| **cAdvisor** (inside kubelet) | per-container CPU, memory, network, disk |
| **node-exporter** (DaemonSet) | node-level OS metrics |
| **kube-state-metrics** | state of objects: desired vs ready replicas, pod phase, restarts |
| **app `/metrics` endpoints** | business metrics, scraped by Prometheus via `ServiceMonitor` |

### Logs in Kubernetes

- Containers write to **stdout/stderr**; the container runtime stores them on the node under `/var/log/containers/`.
- `kubectl logs` reads them – but they're gone when the pod is deleted.
- A **log agent DaemonSet** (Fluent Bit, Promtail/Grafana Alloy, Fluentd) runs on every node, tails these files, adds pod/namespace labels and ships them to Loki/Elasticsearch.
- **Events** (`kubectl get events`) are also important: scheduling failures, image pull errors, probe failures, OOMKills.

### Traces in Kubernetes

- Apps are instrumented with **OpenTelemetry SDKs** (or auto-instrumentation via the OTel Operator).
- Spans are sent to an **OTel Collector** (Deployment or DaemonSet) and exported to Jaeger/Tempo.
- **Service meshes** (Istio, Linkerd) can generate traces and golden metrics for all traffic without changing app code.

### Health signals built into Kubernetes

- **Probes** (liveness, readiness, startup) – automatic health checks and self-healing.
- **Pod status / restarts / conditions** – `kubectl get pods`, `kubectl describe pod`.

### Typical Kubernetes observability architecture

```text
            ┌───────────── Kubernetes cluster ─────────────┐
 pods ──stdout──► Fluent Bit / Alloy (DaemonSet) ──────────┼──► Loki ─────┐
 pods ──/metrics─► Prometheus (+ node-exporter, KSM) ──────┼──► Prometheus├──► Grafana (dashboards, explore)
 pods ──OTLP────► OpenTelemetry Collector ─────────────────┼──► Tempo ────┘
                                   Prometheus rules ───────┼──► Alertmanager ──► Slack / email / PagerDuty
            └──────────────────────────────────────────────┘
```

In Task 1 ([`../01-monitoring`](../01-monitoring/README.md)) I set up the metrics + alerting part of this with kube-prometheus-stack.

## Summary

- **Metrics** = numbers over time → *is something wrong, how much?*
- **Logs** = event records → *what exactly happened?*
- **Traces** = request journey → *where in the system is the problem?*
- Observability = having all three, **correlated**, so you can debug problems you didn't predict.

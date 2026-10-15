# Session 20 – Monitoring, Observability & GitOps

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

This session was about knowing what's going on inside a running system (monitoring & observability) and about deploying in a safe, automated way using Git (GitOps).

## Folder structure

```text
20-monitoring-observability-gitops/
├── 01-monitoring/                # Task 1 – hands-on demo
│   ├── demo-app.yaml             # nginx app with probes + resource limits
│   ├── cpu-stress.yaml           # pod that generates CPU load
│   ├── high-cpu-alert.yaml       # PrometheusRule (HighPodCPU, PodNotReady)
│   ├── README.md
│   └── screenshots/
├── 02-observability/             # Task 2 – documentation
│   └── README.md
└── 03-gitops/                    # Task 3 – concepts + Argo CD demo
    ├── gitops-repo/app/          # desired state watched by Argo CD
    │   ├── deployment.yaml
    │   └── service.yaml
    ├── argocd-application.yaml
    ├── README.md
    └── screenshots/
```

## Tasks

| Task | What I did | Link |
| :--- | :--- | :--- |
| 1. Monitoring | Installed kube-prometheus-stack (Prometheus, Grafana, Alertmanager) on Minikube; showed metrics, logs, alerts, CPU/memory utilisation and app health with probes | [01-monitoring](01-monitoring/README.md) |
| 2. Observability | Wrote notes on metrics, logs and traces, why observability matters, tools, and Kubernetes observability | [02-observability](02-observability/README.md) |
| 3. GitOps | Explained GitOps concepts and did a demo with Argo CD: auto-sync from Git, scaling via a commit, self-heal of manual changes, rollback with `git revert` | [03-gitops](03-gitops/README.md) |

## Tools used

- Minikube + kubectl
- Helm (`prometheus-community/kube-prometheus-stack`)
- Prometheus, Grafana, Alertmanager, metrics-server
- Argo CD
- GitHub (as the GitOps source of truth)

## Quick summary

- **Monitoring** = watch known signals and alert on them (CPU high, pod down).
- **Observability** = metrics + logs + traces together, so I can figure out *why* something broke, even for problems I didn't expect.
- **GitOps** = Git holds the desired state; an agent like Argo CD continuously makes the cluster match it.

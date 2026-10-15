# Session 10 – Kubernetes Pods, ReplicaSets & Deployments

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

In this session I practised the 4 common deployment strategies and studied the Pod lifecycle on my Minikube cluster (`minikube start --driver=docker`). Every strategy has its own folder with the YAML files, the commands I ran, screenshots and what I observed.

## Folder structure

```text
10-k8s-pods-replicasets-deployments/
├── 01-rolling-update/   deployment-v1.yaml, deployment-v2.yaml, README.md
├── 02-blue-green/       blue.yaml, green.yaml, service.yaml, README.md
├── 03-canary/           stable.yaml, canary.yaml, service.yaml, README.md
├── 04-recreate/         deployment.yaml, README.md
└── pod-lifecycle/       01..06 pod YAMLs, README.md
```

## Task 1 – Deployment strategies

| # | Strategy | Folder | One-line idea |
| :--- | :--- | :--- | :--- |
| 1 | Rolling Update | [01-rolling-update](01-rolling-update/README.md) | Replace pods a few at a time, no downtime. Default in Kubernetes. |
| 2 | Blue-Green | [02-blue-green](02-blue-green/README.md) | Run old (blue) and new (green) side by side, flip the Service selector to switch all traffic at once. |
| 3 | Canary | [03-canary](03-canary/README.md) | Send a small % of users to the new version first (here 1 pod out of 10 ≈ 10%). |
| 4 | Recreate | [04-recreate](04-recreate/README.md) | Kill all old pods, then start new ones. Simple but has downtime. |

### Quick comparison

| | Rolling | Blue-Green | Canary | Recreate |
| :--- | :--- | :--- | :--- | :--- |
| Downtime | No | No | No | **Yes** |
| Extra resources needed | A little (maxSurge) | Double (2 full sets) | A little | None |
| Rollback speed | Medium (`rollout undo`) | Instant (flip selector) | Instant (delete canary) | Slow (redeploy) |
| Old + new running together | Yes, briefly | Yes | Yes | **Never** |
| Good for | Most stateless apps | Big releases that need instant switch | Testing risky changes on real users | Apps that can't run 2 versions at once (DB schema change) |

## Task 2 – Pod lifecycle

See [pod-lifecycle/README.md](pod-lifecycle/README.md). I made one YAML for each interesting state: Running, Succeeded, Failed, CrashLoopBackOff, Pending and a pod with an init container + lifecycle hooks.

## Pods vs ReplicaSets vs Deployments (my notes)

- **Pod** – the smallest unit, wraps one or more containers. If it dies nobody recreates it.
- **ReplicaSet** – makes sure N copies of a pod are always running. If I delete a pod it creates a new one.
- **Deployment** – manages ReplicaSets. When I change the pod template it creates a *new* ReplicaSet and moves pods from the old one to the new one according to the strategy. That's why every update shows a new ReplicaSet in `kubectl get rs`.

```bash
kubectl get deploy,rs,pods            # see all three levels together
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
```

## Cleanup

```bash
kubectl delete -f 01-rolling-update/deployment-v2.yaml
kubectl delete -f 02-blue-green/
kubectl delete -f 03-canary/
kubectl delete -f 04-recreate/
kubectl delete -f pod-lifecycle/
```

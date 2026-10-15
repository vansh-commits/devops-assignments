# Session 11 – Task 2: Kubernetes Object Comparison

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

---

## 1. Deployment vs ReplicaSet

| Point | ReplicaSet | Deployment |
| :--- | :--- | :--- |
| **Purpose** | Keep a fixed number of identical pods running. | Manage the full life of an app – replicas *plus* updates and rollbacks. |
| **Pod management** | Creates/deletes pods directly to match `replicas`. Watches pods by label selector. | Doesn't touch pods directly. It creates and manages ReplicaSets, and they manage the pods. |
| **Scaling** | `kubectl scale rs <name> --replicas=5` works. | `kubectl scale deploy <name> --replicas=5` – the Deployment passes it to its current ReplicaSet. HPA usually targets Deployments. |
| **Rolling updates** | **Not supported.** If I change the image in a ReplicaSet, existing pods keep the old image; only new pods get the new one. | **Supported.** Changing the pod template creates a new ReplicaSet and shifts pods gradually (RollingUpdate or Recreate). Also has `rollout history` and `rollout undo`. |
| **Used directly?** | Rarely. | Yes – this is what we write for stateless apps. |

### Relationship between them

```text
Deployment (app-rolling)
 ├── ReplicaSet app-rolling-7c9f6   (revision 1, old image)  → 0 pods
 └── ReplicaSet app-rolling-5d84b   (revision 2, new image)  → 4 pods
        ├── Pod app-rolling-5d84b-abcde
        ├── Pod ...
```

- Deployment **owns** ReplicaSets, ReplicaSets **own** Pods (you can see `ownerReferences` in `kubectl get rs -o yaml`).
- Every change to the pod template = a new ReplicaSet. The old ones are kept at 0 replicas (`revisionHistoryLimit`, default 10) so rollback is quick.
- The hash in the ReplicaSet name (`pod-template-hash`) comes from the pod template.

```bash
kubectl get deploy,rs,pods
kubectl describe rs <rs-name> | grep "Controlled By"
```

---

## 2. Deployment vs DaemonSet vs StatefulSet

| Point | Deployment | DaemonSet | StatefulSet |
| :--- | :--- | :--- | :--- |
| **Use case** | Stateless apps – web servers, APIs, frontends. | One copy on **every node** – log collectors, monitoring agents, network plugins. | Stateful apps that need a stable identity – databases, Kafka, Zookeeper, Elasticsearch. |
| **Pod creation** | All pods created in parallel with random names (`web-5d84b-xk2pq`). | One pod per node automatically; new node joins → pod is added. | Created **one by one in order** with fixed names: `db-0`, then `db-1`, then `db-2`. Deleted in reverse order. |
| **Scaling** | `--replicas=N`, any order. | No replicas field – number of pods = number of (matching) nodes. | `--replicas=N`, but scaled up/down in order. |
| **Networking** | Normal Service, pods are interchangeable. | Often uses `hostNetwork`/`hostPort` to access node-level stuff. | Needs a **headless Service**; each pod gets its own DNS name: `db-0.db-svc.ns.svc.cluster.local`. |
| **Storage** | Usually none, or one shared PVC. | Usually `hostPath` to read node files (e.g. `/var/log`). | `volumeClaimTemplates` – **each pod gets its own PVC**, and it stays attached to the same pod name even after restart. |
| **Examples** | nginx, React frontend, Node/Python API. | Fluent Bit, Prometheus node-exporter, kube-proxy, Calico. | MySQL, PostgreSQL, MongoDB, Kafka, Redis cluster. |

**Easy way I remember it:**
- Deployment = "I need N copies, any pod is fine."
- DaemonSet = "I need exactly one on every machine."
- StatefulSet = "Each copy is special and must keep its name and its disk."

---

## 3. ReplicaSet vs Service

These two are often confused because both use **label selectors**, but they do completely different jobs.

| Point | ReplicaSet | Service |
| :--- | :--- | :--- |
| **Responsibility** | Keeps the right **number** of pods alive (self-healing). | Gives those pods a stable **network address** and load-balances traffic. |
| **Creates pods?** | Yes. | No – it only finds pods by label. |
| **What it gives** | Pods with changing IPs. | A fixed ClusterIP + DNS name. |
| **If a pod dies** | Creates a replacement pod. | Removes the dead pod from its endpoints and adds the new one. |

### Why a Service is required

- Pod IPs change every time a pod is recreated, scaled or rescheduled.
- There are multiple pods, and the client shouldn't have to choose one.
- Without a Service, a frontend would need to know the current IPs of all backend pods – impossible to maintain.

So the ReplicaSet makes sure pods **exist**, and the Service makes sure they are **reachable**.

### How traffic reaches pods

```text
Client pod
   │  http://backend-clusterip
   ▼
CoreDNS  → returns ClusterIP 10.96.x.x
   │
   ▼
kube-proxy rules (iptables/IPVS on the node)
   │  picks one endpoint (pod IP) randomly / round-robin
   ▼
Pod 10.244.0.12:80   (one of the pods selected by app=backend,
                      kept alive by the ReplicaSet)
```

1. Service selector `app=backend` matches the pods → the **EndpointSlice** controller keeps a list of ready pod IPs.
2. kube-proxy watches that list and writes forwarding rules on every node.
3. Client resolves the Service name through CoreDNS and gets the ClusterIP.
4. The packet to the ClusterIP is rewritten (DNAT) to one real pod IP.

```bash
kubectl get endpointslices -l kubernetes.io/service-name=backend-clusterip
```

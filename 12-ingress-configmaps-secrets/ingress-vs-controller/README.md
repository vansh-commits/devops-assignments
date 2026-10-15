# Session 12 – Task 4: Ingress vs Ingress Controller

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

When I started this topic I thought "Ingress" was one thing, but actually there are two separate pieces that work together. Here is what I understood.

## What is Ingress?

An **Ingress** is a Kubernetes **API object** (`kind: Ingress`) – just a YAML file with **rules** for HTTP/HTTPS traffic coming from outside the cluster. A rule says something like:

- "if the host is `shop.example.com` and the path starts with `/api`, send it to the `api-service` on port 80"
- "use this TLS certificate for `shop.example.com`"

Example (from my demo in Task 3):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: hello.local
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
```

On its own this object does **nothing**. It is only stored in etcd, like a note saying how traffic *should* be routed.

## What is an Ingress Controller?

An **Ingress Controller** is the actual **software running in the cluster** (usually a Deployment of reverse-proxy pods, exposed by a LoadBalancer or NodePort Service). It:

1. **Watches** the Kubernetes API for Ingress objects (and Services/Endpoints).
2. **Converts** the rules into its own proxy configuration (for ingress-nginx this is an `nginx.conf`).
3. **Receives** the real incoming requests and **forwards** them to the correct pods.
4. Handles extras like TLS termination, redirects, rewrites, rate limiting, etc.

Kubernetes does **not** ship with a controller installed – I had to enable one with `minikube addons enable ingress`.

## Difference between them

| | Ingress | Ingress Controller |
| :--- | :--- | :--- |
| What it is | A resource / YAML config | A running application (pods) |
| Job | **Declares** the routing rules | **Implements** the rules and moves the traffic |
| Created by | Developer writing YAML | Cluster admin installs it (Helm, addon, manifest) |
| Works alone? | No – without a controller nothing happens | Runs, but without Ingress objects it has no rules (returns 404) |
| How many? | Usually many (one per app/team) | Usually one or a few per cluster |
| Linked by | `spec.ingressClassName` | `IngressClass` it registers (e.g. `nginx`) |

A simple analogy I used to remember it: the **Ingress is the traffic rule book**, the **Ingress Controller is the traffic police officer** who reads the book and actually directs the cars.

## Why both are required

- Kubernetes wants to stay **vendor neutral**. By separating the *what* (Ingress rules) from the *how* (controller), the same Ingress YAML can run on NGINX, Traefik, AWS ALB, etc. by just changing `ingressClassName`.
- The Ingress gives developers a simple **declarative** way to describe routing, while the controller does the heavy work of being a reverse proxy.
- Together they let **one** external IP/load balancer serve many apps using host and path rules, which is much cheaper than one cloud LoadBalancer per Service.

Flow:

```
User ──► LoadBalancer / NodePort ──► Ingress Controller pod
                                         │ (reads Ingress rules from API server)
                                         ▼
                                     Service ──► Pods
```

## Examples

**Ingress Controllers:**

| Controller | Notes |
| :--- | :--- |
| ingress-nginx | Most common, community maintained, used in my minikube demo |
| Traefik | Default in k3s, auto-discovers routes, has a dashboard |
| HAProxy Ingress | High performance HAProxy based |
| AWS Load Balancer Controller | Creates a real AWS ALB for every Ingress |
| GKE Ingress | Creates a Google Cloud HTTP(S) Load Balancer |
| Kong / Istio Gateway | API gateway / service mesh style |

**Ingress examples:**

- Path based: `hello.local/app1` → app1, `hello.local/app2` → app2 (my Task 3 demo)
- Host based: `api.example.com` → api-service, `www.example.com` → frontend-service
- TLS: add a `tls:` section with a Secret containing the certificate so the controller serves HTTPS

Small side note: newer Kubernetes also has the **Gateway API** (`Gateway`, `HTTPRoute`), which is like a more powerful successor of Ingress, but the same idea applies – resources describe the routing and a controller implements it.

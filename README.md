# DevOps Homework – Assignment Solutions

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

This folder has my solutions for all the DevOps homework from the course: Linux, shell scripting, networking, Git, Docker, Kubernetes, Helm, CI/CD, DevSecOps, Terraform/AWS, and monitoring/GitOps. Each session has its own folder with a `README.md`, the code/YAML I used, and a `screenshots/` folder with the output of the commands I ran.

## Index

| Session | Topic | Folder |
| :--- | :--- | :--- |
| 2 | Linux – soft/hard links, adduser vs useradd, journalctl, cheat sheet | [`02-linux`](02-linux/README.md) |
| 3 | Shell scripting – system information script | [`03-shell-scripting`](03-shell-scripting/README.md) |
| 4 | Networking commands | [`04-networking`](04-networking/README.md) |
| 5 | Git – `commit -a -m` and cherry-pick | [`05-git`](05-git/README.md) |
| 6 & 7 | Docker – Hello World apps and multi-stage build | [`06-07-docker`](06-07-docker/README.md) |
| 8 | Docker networking and volumes | [`08-docker-networking-volume`](08-docker-networking-volume/README.md) |
| 9 | Kubernetes fundamentals (Minikube) | [`09-kubernetes-fundamentals`](09-kubernetes-fundamentals/README.md) |
| 10 | Pods, ReplicaSets and Deployments – 4 deployment strategies and the pod lifecycle | [`10-k8s-pods-replicasets-deployments`](10-k8s-pods-replicasets-deployments/README.md) |
| 11 | Kubernetes networking and Services, FQDN, CoreDNS | [`11-k8s-networking-services`](11-k8s-networking-services/README.md) |
| 12 | Ingress, ConfigMaps and Secrets | [`12-ingress-configmaps-secrets`](12-ingress-configmaps-secrets/README.md) |
| 13 | Storage, HPA and probes | [`13-storage-hpa-probes`](13-storage-hpa-probes/README.md) |
| 14 | Kubernetes troubleshooting | [`14-k8s-troubleshooting`](14-k8s-troubleshooting/README.md) |
| 15 | Helm | [`15-helm`](15-helm/README.md) |
| 16 | CI/CD with GitHub Actions | [`16-cicd-github-actions`](16-cicd-github-actions/README.md) |
| 17 | Complete CI/CD and DevSecOps | [`17-devsecops`](17-devsecops/README.md) |
| 18 | Terraform S3 demo and AWS services research | [`18-terraform-iac`](18-terraform-iac/README.md) |
| 19 | Cloud and Terraform in action (VPC → EC2 → S3) | [`19-cloud-terraform`](19-cloud-terraform/README.md) |
| 20 | Monitoring, observability and GitOps | [`20-monitoring-observability-gitops`](20-monitoring-observability-gitops/README.md) |

## My setup

- macOS with Docker Desktop
- Minikube / kind for Kubernetes, with `kubectl` and `helm`
- Terraform with my own AWS free-tier account (I always ran `terraform destroy` afterwards)
- GitHub Actions for the CI/CD sessions

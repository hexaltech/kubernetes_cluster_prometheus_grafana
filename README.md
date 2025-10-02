# 🚀 Kubernetes Lab sur Proxmox + Debian 12

Ce dépôt contient un guide et des fichiers de configuration pour monter un cluster Kubernetes sur Proxmox (3 VM Debian 12) avec :
- 1 master
- 2 workers
- CNI Calico
- LoadBalancer MetalLB
- Monitoring (Prometheus + Grafana via Helm)
- Metrics Server

---

## 📖 Documentation

- [Pré-requis Proxmox](docs/00-prerequis.md)
- [Installation Kubernetes](docs/01-install-k8s.md)
- [Déploiements (Nginx + MetalLB)](docs/02-deploiements.md)
- [Monitoring avec Helm](docs/03-monitoring.md)
- [Metrics Server](docs/04-metrics-server.md)

---

## 📂 Structure

- `docs/` → Guides détaillés étape par étape  
- `manifests/` → Manifests Kubernetes (YAML) prêts à appliquer  
- `scripts/` → Scripts shell pour automatiser les installations  

---

## ⚙️ Exemple de ressources VM

| Rôle        | vCPU | RAM     | Disque   | IP             |
|-------------|------|---------|----------|----------------|
| k8s-master  | 2    | 4–6 GiB | 20–40 GiB| 192.168.1.100  |
| k8s-worker1 | 2    | 4 GiB   | 20 GiB   | 192.168.1.101  |
| k8s-worker2 | 2    | 4 GiB   | 20 GiB   | 192.168.1.102  |

---

## 🚧 Notes

- Les IP sont des exemples, adapte-les à ton réseau.  
- Avant les grosses étapes, prends des snapshots Proxmox.  
- Les fichiers `manifests/` sont conçus pour être appliqués tels quels :  

```bash
kubectl apply -f manifests/metallb-config.yaml
kubectl apply -f manifests/metrics-server.yaml
```

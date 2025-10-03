# Kubernetes Cluster avec Prometheus, Grafana & Autoscaling

## 📌 Description
Ce projet présente un déploiement complet d’un **cluster Kubernetes** incluant :  
- **Installation du cluster** (master + workers)  
- **Monitoring** avec **Prometheus** et **Grafana**  
- **Metrics Server** pour la collecte des métriques Kubernetes  
- **Autoscaling (HPA)** sur une application PHP-Apache  
- **Load Balancing** avec **MetalLB**  

L’objectif est de mettre en place une plateforme de monitoring et d’observation complète, capable d’autoscaler dynamiquement en fonction des ressources consommées.

---

## 📂 Structure du projet
```
.
├── README.md                # Ce guide
├── docs/                    # Documentation étape par étape
│   ├── 00-prerequis.md
│   ├── 01-install-k8s.md
│   ├── 02-deploiements.md
│   ├── 03-monitoring.md
│   ├── 04-metrics-server.md
│   └── 05-hpa-grafana.md
├── manifests/               # Manifests Kubernetes
│   ├── metallb-config.yaml
│   └── hpa_php_apache.json
└── scripts/                 # Scripts d’installation
    ├── setup-master.sh
    └── setup-worker.sh
```

---

## ⚙️ Prérequis
- Machines ou VM avec Linux (Ubuntu/Debian recommandé)  
- Kubernetes (via `kubeadm`, voir docs)  
- `kubectl` installé et configuré  
- Accès root/sudo  
- Accès réseau entre master et workers  

---

## 🚀 Installation

### 1. Préparer le cluster
Sur le **master** :
```bash
bash scripts/setup-master.sh
```

Sur chaque **worker** :
```bash
bash scripts/setup-worker.sh
```

⚠️ Le script master fournit la commande `kubeadm join` à exécuter sur les workers.

---

### 2. Installer MetalLB
```bash
kubectl apply -f manifests/metallb-config.yaml
```

---

### 3. Déployer le monitoring
Suivre la documentation : [`docs/03-monitoring.md`](docs/03-monitoring.md)  

Cela installe **Prometheus** et **Grafana**.  

Par défaut :  
- Grafana est exposé sur le **LoadBalancer** défini par MetalLB  
- Identifiants par défaut : `admin / admin` (changer immédiatement)

---

### 4. Installer Metrics Server
```bash
kubectl apply -f <fichiers-metrics-server>
```
(voir [`docs/04-metrics-server.md`](docs/04-metrics-server.md))

---

### 5. Autoscaling avec HPA
Exemple : PHP-Apache autoscalé avec Metrics Server :  
```bash
kubectl apply -f manifests/hpa_php_apache.json
```

Vous pouvez tester le scaling avec un **stress test** (ex: `ab` ou `wrk`).

---

## 📊 Visualisation
- **Grafana** : tableaux de bord pour observer CPU, mémoire, pods, etc.  
- **Prometheus** : collecte des métriques Kubernetes  
- **HPA** : ajuste automatiquement le nombre de pods  

---

## 📖 Documentation détaillée
Retrouvez toutes les étapes dans le dossier [`docs/`](docs/).  
- [00 - Prérequis](docs/00-prerequis.md)  
- [01 - Installation du cluster Kubernetes](docs/01-install-k8s.md)  
- [02 - Déploiements d’applications](docs/02-deploiements.md)  
- [03 - Mise en place du monitoring](docs/03-monitoring.md)  
- [04 - Configuration du metrics-server](docs/04-metrics-server.md)  
- [05 - HPA et dashboards Grafana](docs/05-hpa-grafana.md)  

---

💡 Avec ce projet, vous obtenez un cluster Kubernetes complet, observé et capable de s’autoscaler en fonction de la charge !  

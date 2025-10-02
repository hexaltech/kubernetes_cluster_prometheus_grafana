# Monitoring avec Prometheus + Grafana

## 1️⃣ Installer Helm

🖥️ **Sur le master** :

```bash
# Installer Helm 3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Vérifier la version
helm version
```

---

## 2️⃣ Ajouter les repos Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

---

## 3️⃣ Créer le namespace `monitoring` (si nécessaire)

```bash
kubectl create namespace monitoring
```

> ⚠️ Si le namespace existe déjà, tu peux ignorer cette étape.

---

## 4️⃣ Installer kube-prometheus-stack (Prometheus + Grafana)

```bash
helm install kube-prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
```

Vérifie que tous les pods sont `Running` :

```bash
kubectl get pods -n monitoring
```

Tu devrais voir :

* prometheus-operator
* prometheus
* alertmanager
* kube-state-metrics
* node-exporter
* prometheus-grafana

---

## 5️⃣ Exposer Grafana via MetalLB

```bash
kubectl patch svc kube-prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc -n monitoring
```

* La colonne **EXTERNAL-IP** doit afficher une IP de ton pool MetalLB.

---

## 6️⃣ Récupérer le mot de passe admin de Grafana

```bash
kubectl get secret kube-prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
```

---

## 7️⃣ Accéder à Grafana

Dans ton navigateur, ouvre l’IP externe attribuée par MetalLB, par exemple :

```
http://192.168.1.200
```

Login par défaut :

* **user** : admin
* **password** : récupéré à l’étape précédente

---

## 8️⃣ Vérifier la collecte de métriques

Pour tester si les métriques fonctionnent :

```bash
kubectl top nodes
kubectl top pods --all-namespaces
```

> Si tu vois des valeurs CPU/MEMORY, tout fonctionne correctement.

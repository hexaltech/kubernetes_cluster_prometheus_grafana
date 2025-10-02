# Monitoring avec Prometheus + Grafana

## 1. Ajouter Helm

🖥️ **Sur le master** :

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## 2. Installer Prometheus + Grafana

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install kube-prometheus prometheus-community/kube-prometheus-stack
```

## 3. Accéder à Grafana

Récupérer le mot de passe admin :

```bash
kubectl get secret kube-prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

Port-forward :

```bash
kubectl port-forward svc/kube-prometheus-grafana 3000:80
```

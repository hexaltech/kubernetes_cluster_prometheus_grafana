# Monitoring avec Prometheus + Grafana

## 1. Installer Helm

🖥️ **Sur le master** :

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

## 2. Ajouter les repos Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

## 3. Installer Prometheus + Grafana dans le namespace monitoring

Créer le namespace monitoring si nécessaire :

```bash
kubectl create namespace monitoring
```

Installer kube-prometheus-stack :

```bash
helm install kube-prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
```

Vérifie que tous les pods sont `Running` :

```bash
kubectl get pods -n monitoring
```

## 4. Exposer Grafana via MetalLB

```bash
kubectl patch svc kube-prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc -n monitoring
```

* La colonne **EXTERNAL-IP** doit afficher une IP du pool MetalLB.

## 5. Accéder à Grafana

Récupérer le mot de passe admin :

```bash
kubectl get secret kube-prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
```

Ouvre ton navigateur à l’IP externe attribuée par MetalLB, par exemple :

```
http://192.168.1.2xx (202 par exemple)
```

Login par défaut :

* user : admin
* password : récupéré ci-dessus

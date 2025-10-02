# Déploiements Nginx + MetalLB

## 1. Installer MetalLB

👑 **Sur le master uniquement** :

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
```

Vérifie que les pods sont `Running` :

```bash
kubectl get pods -n metallb-system
```

## 2. Configurer MetalLB

👑 **Sur le master uniquement** :

Crée ton fichier de configuration `manifests/metallb-config.yaml`, exemple :

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: my-ip-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.200-192.168.1.210
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advert
  namespace: metallb-system
```

Applique la config :

```bash
kubectl apply -f manifests/metallb-config.yaml
```

Vérifie que tout est OK :

```bash
kubectl get pods -n metallb-system
kubectl get svc -n metallb-system
```

## 3. Déploiement Nginx

👑 **Sur le master uniquement** :

```bash
kubectl create deployment nginx --image=nginx --replicas=2
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

Vérifie :

```bash
kubectl get deployments
kubectl get pods
kubectl get svc
```

* La colonne **EXTERNAL-IP** doit afficher une IP du pool MetalLB.
* Test depuis un PC ou VM avec accès réseau :

```bash
curl http://<EXTERNAL-IP>
```

* Tu devrais voir le contenu par défaut de Nginx.

💡 Astuce : `kubectl describe svc nginx` permet de voir l’IP attribuée par MetalLB.

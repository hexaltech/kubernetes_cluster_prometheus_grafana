# Déploiement Nginx + MetalLB

## 1. Installer MetalLB

👑 **Sur le master uniquement** :

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
```

## 2. Configurer MetalLB

👑 **Sur le master uniquement** :

```bash
kubectl apply -f manifests/metallb-config.yaml
```

## 3. Déploiement Nginx

👑 **Sur le master uniquement** :

```bash
kubectl create deployment nginx --image=nginx --replicas=2
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

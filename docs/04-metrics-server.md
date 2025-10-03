# Metrics Server pour Kubernetes

Ce document décrit l'installation et la configuration du **Metrics Server** dans un cluster Kubernetes, ainsi que la procédure de nettoyage complet si nécessaire.

---


## 1. Installer le Metrics Server
👑 Sur le master :

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Si tout est correct, le Metrics Server doit être `READY` et l’API Metrics disponible.

---

## 2. Patcher pour environnement de test
Dans un environnement Proxmox avec des certificats auto-signés, il faut désactiver la vérification TLS :

```bash
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'
```
---

## 3. Vérifier l'installation
Attends que le pod soit Running :

```bash
kubectl get pods -n kube-system | grep metrics-server
```

Vérifie que les métriques sont collectées :

```bash
kubectl top nodes
kubectl top pods -A
```

🔧 Dépannage
Si kubectl top ne fonctionne toujours pas après quelques minutes, vérifie les logs :

```bash
kubectl logs -n kube-system deployment/metrics-server
```

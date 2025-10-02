# Metrics Server

👑 **Sur le master uniquement** :

```bash
kubectl apply -f manifests/metrics-server.yaml
```

Vérification :

```bash
kubectl top nodes
kubectl top pods
```

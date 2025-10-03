# Metrics Server pour Kubernetes

Ce document décrit l'installation et la configuration du **Metrics Server** dans un cluster Kubernetes, ainsi que la procédure de nettoyage complet si nécessaire.

---

## 1. Nettoyage complet de Metrics Server

Cette étape permet de repartir sur une base propre en supprimant tous les objets liés à Metrics Server.

```bash
# Supprimer les pods
kubectl delete pod -n kube-system -l k8s-app=metrics-server

# Supprimer le déploiement
kubectl delete deployment metrics-server -n kube-system

# Supprimer le service
kubectl delete service metrics-server -n kube-system

# Supprimer le ServiceAccount
kubectl delete serviceaccount metrics-server -n kube-system

# Supprimer le ClusterRole et le ClusterRoleBinding
kubectl delete clusterrole system:metrics-server
kubectl delete clusterrolebinding system:metrics-server

# Supprimer les ClusterRoleBindings additionnels si présents
kubectl delete clusterrolebinding metrics-server-auth
kubectl delete clusterrolebinding metrics-server:system:auth-delegator

# Vérifier qu'il ne reste aucun pod ni API Service Metrics Server
kubectl get pods -n kube-system -l k8s-app=metrics-server
kubectl get apiservice | grep metrics
```

Après exécution, tu devrais obtenir :

```
No resources found in kube-system namespace.
```

---

## 2. Installation propre de Metrics Server

### Fichier YAML `metrics-server.yaml`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:metrics-server
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["extension-apiserver-authentication"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["nodes", "nodes/stats", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["nodes", "pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    k8s-app: metrics-server
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      containers:
      - name: metrics-server
        image: registry.k8s.io/metrics-server/metrics-server:v0.8.0
        args:
        - --cert-dir=/tmp
        - --secure-port=10250
        - --kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP
        - --kubelet-use-node-status-port
        - --kubelet-insecure-tls
        - --metric-resolution=15s
        ports:
        - containerPort: 10250
          name: https
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /livez
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
          timeoutSeconds: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /readyz
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
          timeoutSeconds: 1
          failureThreshold: 3
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
          seccompProfile:
            type: RuntimeDefault
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
      volumes:
      - name: tmp-dir
        emptyDir: {}
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      restartPolicy: Always
      dnsPolicy: ClusterFirst
      terminationGracePeriodSeconds: 30
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    k8s-app: metrics-server
  ports:
  - port: 443
    targetPort: 10250
```

### Application du YAML

```bash
kubectl apply -f metrics-server.yaml
```

### Vérification

```bash
kubectl get pods -n kube-system -l k8s-app=metrics-server
kubectl get apiservice | grep metrics
kubectl top nodes
kubectl top pods --all-namespaces
```

Si tout est correct, le Metrics Server doit être `READY` et l’API Metrics disponible.

---

## 3. ClusterRoleBindings additionnels (si nécessaire)

```bash
kubectl create clusterrolebinding metrics-server-auth \
  --clusterrole=system:metrics-server \
  --serviceaccount=kube-system:metrics-server \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create clusterrolebinding metrics-server:system:auth-delegator \
  --clusterrole=system:auth-delegator \
  --serviceaccount=kube-system:metrics-server
```

---

## 4. Redémarrage du déploiement (si modification des arguments)

```bash
kubectl rollout restart deployment metrics-server -n kube-system
```

Ensuite, revérifier que les pods sont `READY` et que l’API fonctionne correctement.

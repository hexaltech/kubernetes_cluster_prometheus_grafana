# Metrics Server Installation et Nettoyage

Ce document explique comment installer le Metrics Server sur Kubernetes et comment supprimer toutes les ressources liées pour repartir d'une base propre.

---

## Installation Metrics Server

Fichier `metrics-server.yaml` pour installer Metrics Server v0.8.0 :

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

### Commandes utiles

```bash
# Appliquer le YAML
kubectl apply -f metrics-server.yaml

# Redémarrer le déploiement si besoin
kubectl rollout restart deployment metrics-server -n kube-system

# Vérifier les pods
kubectl get pods -n kube-system -l k8s-app=metrics-server

# Vérifier l'API
kubectl get apiservice | grep metrics

# Tester les métriques
kubectl top nodes
kubectl top pods --all-namespaces
```

---

## Nettoyage complet de Metrics Server

Pour repartir sur une base propre et supprimer toutes les ressources liées à Metrics Server :

```bash
kubectl delete deployment metrics-server -n kube-system
kubectl delete service metrics-server -n kube-system
kubectl delete serviceaccount metrics-server -n kube-system
kubectl delete clusterrole system:metrics-server
kubectl delete clusterrolebinding system:metrics-server
kubectl delete clusterrolebinding metrics-server-auth
kubectl delete clusterrolebinding metrics-server:system:auth-delegator
```

Ensuite, tu peux réinstaller proprement avec le YAML ci-dessus.

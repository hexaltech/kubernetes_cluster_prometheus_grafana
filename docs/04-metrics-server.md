# Metrics Server Deployment

Ce document décrit l'installation et la configuration du **Metrics Server** dans un cluster Kubernetes.

Le Metrics Server permet de collecter les métriques de ressources (CPU, mémoire) des **nœuds** et des **pods**, utilisées par `kubectl top` ou pour l’auto-scaling horizontal.

---

## Fichier YAML complet

```yaml
# metrics-server.yaml
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
  resources: ["pods", "nodes", "nodes/stats", "namespaces", "configmaps"]
  resourceNames: ["extension-apiserver-authentication"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods", "nodes"]
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
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      containers:
      - name: metrics-server
        image: registry.k8s.io/metrics-server/metrics-server:v0.8.0
        imagePullPolicy: IfNotPresent
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

---

## Commandes à exécuter

1. **Appliquer le YAML complet**

```bash
kubectl apply -f metrics-server.yaml
```

2. **Vérifier que le pod démarre correctement**

```bash
kubectl get pods -n kube-system -l k8s-app=metrics-server
```

> Le pod doit passer en `READY 1/1` rapidement.

3. **Tester les métriques**

```bash
kubectl top nodes
kubectl top pods --all-namespaces
```

4. **Vérifier l’API Metrics Server**

```bash
kubectl get apiservice | grep metrics
```

---

### Notes

* Version moderne **v0.8.0** du Deployment.
* RBAC complet dès le départ, y compris accès au `ConfigMap extension-apiserver-authentication`.
* **Aucun besoin** de modifier manuellement le déploiement après l’installation.

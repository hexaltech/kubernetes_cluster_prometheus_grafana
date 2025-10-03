Pré-requis sur Proxmox (ce que tu dois préparer)

Créer 3 VM KVM, installer Debian 12 (Bookworm) sur chacune. Exemple de ressources (pour un lab) :

Master : 2 vCPU, 4–6 GiB RAM, 20–40 GiB disque.

Worker1/Worker2 : 2 vCPU, 4 GiB RAM, 20 GiB disque.

Mise réseau : relier les VM au bridge Proxmox (ex. vmbr0) pour qu’elles puissent se pinguer.

Assure-toi que chaque VM a accès à Internet pour apt et kubectl apply.

Optionnel : snapshots Proxmox avant chaque grosse étape (pratique pour la vidéo).

🔧 PARTIE 1 — Script pas-à-pas (copier/coller dans chaque VM Debian 12)

Choix d’IP/hostnames : adapte les IP à ton réseau. Exemple utilisé ici :
master = 192.168.1.100 (hostname k8s-master)
worker1 = 192.168.1.101 (hostname k8s-worker1)
worker2 = 192.168.1.102 (hostname k8s-worker2)
Si tu utilises DHCP, remplace/ignore les lignes echo "IP HOSTNAME ..." >> /etc/hosts et vérifie les IP réelles.

On part sur 3 VMs Debian 12 dans Proxmox :

VM	IP	Rôle
k8s-master	192.168.1.100	control-plane
k8s-worker1	192.168.1.101	worker
k8s-worker2	192.168.1.102	worker

On suppose que tu es root sur chaque VM.

🧰 Étape 0 : Nettoyage préalable (si nécessaire)
# Désinstaller d’anciennes installations
apt remove -y kubelet kubeadm kubectl
apt autoremove -y
swapoff -a

🧰 Étape 1 : Configurer hostname et /etc/hosts
k8s-master
hostnamectl set-hostname k8s-master
cat > /etc/hosts <<EOF
192.168.1.100 k8s-master
192.168.1.101 k8s-worker1
192.168.1.102 k8s-worker2
EOF

k8s-worker1
hostnamectl set-hostname k8s-worker1
cat > /etc/hosts <<EOF
192.168.1.100 k8s-master
192.168.1.101 k8s-worker1
192.168.1.102 k8s-worker2
EOF

k8s-worker2
hostnamectl set-hostname k8s-worker2
cat > /etc/hosts <<EOF
192.168.1.100 k8s-master
192.168.1.101 k8s-worker1
192.168.1.102 k8s-worker2
EOF

🧰 Étape 2 : Mettre à jour le système et installer outils de base

Toutes les VMs

apt update && apt upgrade -y
apt install -y curl gnupg lsb-release vim git

🧰 Étape 3 : Ajouter la clé GPG Kubernetes et le dépôt

Toutes les VMs

# Ajouter clé GPG officielle
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg

# Ajouter le dépôt Kubernetes
echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

# Mettre à jour la liste des paquets
apt update

🧰 Étape 4 : Désactiver swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

🧰 Étape 5 : Charger modules kernel requis
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

🧰 Étape 6 : Configurer paramètres réseau
cat > /etc/sysctl.d/99-k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

🧰 Étape 7 : Installer containerd

Toutes les VMs

apt install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

🧰 Étape 8 : Installer Kubernetes

Toutes les VMs

apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

🧰 Étape 9 : Initialiser le master

k8s-master uniquement

kubeadm init --pod-network-cidr=192.168.0.0/16


Configurer kubectl

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config


Installer Calico pour le réseau des pods

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml
kubectl get pods -n kube-system

Étapes suivantes

Sur le master, récupère la commande pour joindre les workers :

kubeadm token create --print-join-command


Sur worker1 et worker2, exécute exactement la commande générée. Par exemple :

kubeadm join 192.168.1.100:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>


Vérifie sur le master que les nodes apparaissent :

kubectl get nodes

kubectl get nodes

Créer un service Nginx

Exécute sur le master :

kubectl create deployment nginx --image=nginx
kubectl scale deployment nginx --replicas=3
kubectl expose deployment nginx --port=80 --target-port=80 --name=nginx-service --type=ClusterIP


Vérifie que tout est OK :

kubectl get pods
kubectl get svc


À ce stade, tu as un déploiement Nginx mais pas encore d’IP externe.

Étape 2 — Installer MetalLB (master seulement)

Télécharger le manifeste officiel MetalLB v0.15.2 :

curl -sSL https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml -o metallb-native.yaml
kubectl apply -f metallb-native.yaml


Vérifie que les pods MetalLB sont en Running :

kubectl get pods -n metallb-system

Étape 3 — Configurer MetalLB

Crée un fichier metallb-config.yaml sur le master avec ce contenu :

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


Applique la config :

kubectl apply -f metallb-config.yaml

Étape 4 — Exposer Nginx via MetalLB

Modifie le service Nginx pour utiliser LoadBalancer :

kubectl patch svc nginx-service -p '{"spec": {"type": "LoadBalancer"}}'


Vérifie l’IP attribuée :

kubectl get svc
kubectl get pods -o wide

GRAFANA et Prometheus avec HELM : 
Télécharger Helm
curl -fsSL https://get.helm.sh/helm-v3.12.1-linux-amd64.tar.gz -o helm.tar.gz

2️⃣ Décompresser
tar -zxvf helm.tar.gz

3️⃣ Déplacer l’exécutable
mv linux-amd64/helm /usr/local/bin/helm

4️⃣ Vérifier l’installation
helm version

Ajouter les repos Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

2️⃣ Créer un namespace pour le monitoring
kubectl create namespace monitoring

3️⃣ Installer Prometheus (avec kube-prometheus-stack)
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring


Ça va créer : Prometheus, Alertmanager, Node Exporter, Kube State Metrics.

Tous les pods tournent dans le namespace monitoring.

4️⃣ Vérifier les pods
kubectl get pods -n monitoring

Vérifie le namespace

Grafana est installé dans monitoring. On va l’exposer depuis le service existant.

kubectl get svc -n monitoring


Tu devrais voir un service prometheus-grafana de type ClusterIP. On va changer ça en LoadBalancer.

2️⃣ Patch le service pour LoadBalancer

Exécute sur le master :

kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'


3️⃣ Vérifie l’IP attribuée par MetalLB
kubectl get svc -n monitoring


Tu devrais voir une colonne EXTERNAL-IP avec une IP (celle définie dans ton metallb-config.yaml).

Exemple :

NAME               TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)  AGE
prometheus-grafana LoadBalancer   10.97.50.10    192.168.1.200   80:30001/TCP  5m

4️⃣ Accède à Grafana depuis ton PC

Dans ton navigateur, va sur :

http://192.168.1.200


Login par défaut :

user : admin

password : prom-operator (souvent avec kube-prometheus-stack) ou vérifie dans le secret Grafana :

kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode

Crée un fichier metrics-server.yaml (tu peux le mettre dans k8s/metrics-server/ par exemple) avec ce contenu :

# ServiceAccount pour Metrics Server
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
# ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:metrics-server
rules:
- apiGroups: [""]
  resources: ["pods", "nodes", "nodes/stats", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods", "nodes"]
  verbs: ["get", "list", "watch"]
---
# ClusterRoleBinding
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
# Deployment
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
        # Image moderne et stable
        image: registry.k8s.io/metrics-server/metrics-server:v0.13.12
        imagePullPolicy: IfNotPresent
        args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP
        - --metric-resolution=15s
        ports:
        - containerPort: 4443
          name: main-port
          protocol: TCP
      restartPolicy: Always
      dnsPolicy: ClusterFirst
---
# Service ClusterIP pour Metrics Server
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
    targetPort: 4443


Points importants :

--kubelet-insecure-tls permet de ne pas bloquer les kubelets avec certificats auto-signés.

--kubelet-preferred-address-types=InternalIP force Metrics Server à utiliser les IP internes des nœuds, évitant les problèmes de connexion.

L’image v0.13.12 est stable et disponible sur registry.k8s.io.

2️⃣ Déployer Metrics Server
# Appliquer le fichier YAML
kubectl apply -f metrics-server.yaml

# Vérifier que le pod est créé
kubectl get pods -n kube-system | grep metrics-server

# Vérifier l’API service
kubectl get apiservices | grep metrics


Le pod doit passer à Running rapidement.

L’API v1beta1.metrics.k8s.io doit être True.

3️⃣ Tester Metrics Server
# Vérifier les métriques des nœuds
kubectl top nodes

# Vérifier les métriques des pods
kubectl top pods --all-namespaces


Si tout fonctionne, tu verras l’utilisation CPU et mémoire pour tous tes nœuds et pods, ce qui te permettra de compléter ton monitoring avec Prometheus et Grafana.

4️⃣ Dépannage courant

ImagePullBackOff ou ErrImagePull

Vérifie l’accès internet des nœuds.

Si besoin, change d’image :

image: k8s.gcr.io/metrics-server/metrics-server:v0.5.2


403 Forbidden lors du scraping des nœuds

Vérifie que ClusterRole et ClusterRoleBinding sont bien appliqués.

Les arguments --kubelet-insecure-tls et --kubelet-preferred-address-types=InternalIP sont essentiels.

Metrics non disponibles immédiatement

Attends 20–30 secondes et reteste kubectl top.

Vérifie les logs :

kubectl logs -n kube-system deploy/metrics-server

5️⃣ Intégration avec Grafana

Une fois Metrics Server en place :

Grafana peut maintenant utiliser la source de métriques Kubernetes Metrics pour afficher CPU/Memory via Metrics Server.

Tu peux créer des dashboards combinés avec tes données Prometheus et Node Exporter.

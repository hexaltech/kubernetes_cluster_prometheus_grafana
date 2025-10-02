# 01-install-k8s.md

# 🧰 Installation de Kubernetes avec containerd et Calico

## 🧰 Étape 0 : Nettoyage préalable (toutes les VMs)

```bash
apt remove -y kubelet kubeadm kubectl
apt autoremove -y
swapoff -a
```

**Pourquoi :**

* Supprime d’anciennes installations de Kubernetes.
* `swapoff -a` désactive le swap, obligatoire pour Kubernetes.

## 🧰 Étape 1 : Configurer le hostname et /etc/hosts

### Sur le master

```bash
hostnamectl set-hostname k8s-master
cat > /etc/hosts <<EOF
192.168.1.100 k8s-master
192.168.1.101 k8s-worker1
192.168.1.102 k8s-worker2
EOF
```

### Sur worker1

```bash
hostnamectl set-hostname k8s-worker1
cat > /etc/hosts <<EOF
192.168.1.100 k8s-master
192.168.1.101 k8s-worker1
192.168.1.102 k8s-worker2
EOF
```

### Sur worker2

```bash
hostnamectl set-hostname k8s-worker2
cat > /etc/hosts <<EOF
192.168.1.100 k8s-master
192.168.1.101 k8s-worker1
192.168.1.102 k8s-worker2
EOF
```

**Pourquoi :**

* Kubernetes utilise le hostname pour identifier les nœuds.
* `/etc/hosts` permet la résolution de noms entre VMs sans DNS.

## 🧰 Étape 2 : Mettre à jour le système et installer outils de base

```bash
apt update && apt upgrade -y
apt install -y curl gnupg lsb-release vim git
```

**Pourquoi :**

* `curl` et `gnupg` : récupérer et vérifier la clé GPG Kubernetes.
* `vim` et `git` : outils pratiques.
* `lsb-release` : détecter la version Debian.

## 🧰 Étape 3 : Ajouter la clé GPG Kubernetes et le dépôt

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt update
```

**Pourquoi :**

* Debian refuse les paquets non signés.
* La clé GPG officielle permet à `apt` de vérifier les paquets Kubernetes.

## 🧰 Étape 4 : Désactiver le swap

```bash
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
```

**Pourquoi :**

* Kubernetes ne supporte pas le swap.
* `/etc/fstab` empêche le swap au reboot.

## 🧰 Étape 5 : Charger les modules kernel requis

```bash
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
```

**Pourquoi :**

* `overlay` : réseau overlay pour pods.
* `br_netfilter` : filtrage réseau sur bridges Kubernetes.

## 🧰 Étape 6 : Configurer les paramètres réseau

```bash
cat > /etc/sysctl.d/99-k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
```

**Pourquoi :**

* Permet aux pods de communiquer entre eux et avec les nœuds.
* Active le routage IP et le filtrage iptables.

## 🧰 Étape 7 : Installer containerd

```bash
apt install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd
```

**Pourquoi :**

* Containerd exécute les conteneurs Kubernetes.
* `SystemdCgroup=true` permet au kubelet de gérer correctement les ressources.

## 🧰 Étape 8 : Installer Kubernetes

```bash
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```

**Pourquoi :**

* `kubeadm` : créer et gérer le cluster.
* `kubelet` : agent sur chaque nœud.
* `kubectl` : interface admin du cluster.
* `apt-mark hold` : évite les mises à jour automatiques.

## 🧰 Étape 9 : Initialiser le master

```bash
# Sur k8s-master uniquement
kubeadm config images pull  # pré-pull des images
kubeadm init --pod-network-cidr=192.168.0.0/16 --kubernetes-version=v1.30.14
```

**Pourquoi :**

* Crée le control-plane.
* `--pod-network-cidr` : nécessaire pour Calico.

Configurer kubectl pour le master :

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

## 🧰 Étape 10 : Installer Calico

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml
kubectl get pods -n kube-system
```

**Pourquoi :**

* Calico gère le réseau des pods et les règles de sécurité.
* Tous les pods doivent être Running avant de joindre les workers.

## 🧰 Étape 11 : Joindre les workers

```bash
# Sur k8s-worker1 et k8s-worker2
kubeadm join 192.168.1.100:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

**Pourquoi :**

* Connecte le worker au master.

## 🧰 Étape 12 : Vérification finale

```bash
kubectl get nodes
kubectl get pods -A
```

**Résultat attendu :**

```
NAME          STATUS   ROLES           AGE   VERSION
k8s-master    Ready    control-plane
k8s-worker1   Ready
k8s-worker2   Ready
```

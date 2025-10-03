# HPA - php-apache Dashboard

Ce dépôt contient un **dashboard Grafana** pour visualiser un Horizontal Pod Autoscaler (HPA) appliqué à un déploiement `php-apache`.

---

## 1️⃣ Génération de charge pour tester le HPA

On utilise Busybox pour générer une charge HTTP sur le service `php-apache` :

```bash
kubectl run -it --rm load-generator --image=busybox:1.28 -- /bin/sh
```

Puis à l’intérieur du pod :

```sh
while sleep 0.01; do wget -q -O- http://php-apache; done
```

> Cela envoie des requêtes HTTP en continu pour provoquer le scaling automatique du HPA.

---

## 2️⃣ Importation du dashboard dans Grafana

1. Ouvrir Grafana.
2. Aller dans **Dashboard > Manage > Import**.
3. Télécharger le fichier JSON `dashboard/hpa_php_apache.json`.
4. Vérifier les métriques :

   * Replicas actuels
   * Replicas désirés
   * CPU par pod
   * CPU total + HPA target
   * HPA ratio actuel / désiré

---

## 3️⃣ Explication des métriques

* **Replicas actuels** : nombre de pods actuellement en fonctionnement.
* **Replicas désirés** : nombre de pods que le HPA souhaite avoir selon la charge.
* **CPU par pod** : utilisation CPU de chaque pod (en cores).
* **CPU total + HPA target** : CPU total consommé par tous les pods vs CPU cible par pod.
* **HPA ratio (actuel / désiré)** : rapport entre le nombre de pods actuel et le nombre désiré.

  * Rouge si ratio < 0.7
  * Orange si 0.7 ≤ ratio < 1
  * Vert si ratio ≥ 1

> Les couleurs permettent de voir rapidement si le HPA réagit correctement à la charge.

---

## 4️⃣ Structure du JSON du dashboard

* **bargauge** : pour visualiser les réplicas actuels et désirés.
* **timeseries** : pour les mesures CPU.
* **stat** : pour le ratio HPA avec seuils visuels.
* **refresh** : toutes les 5 secondes pour suivre en temps réel.

---

## 5️⃣ Notes

* Ce dashboard fonctionne avec **Prometheus + kube-state-metrics**.
* Il est prêt à l’emploi pour n’importe quel déploiement HPA sur Kubernetes.
* Le fichier JSON peut être modifié pour ajouter des alertes ou d’autres métriques.

---

## 6️⃣ Fichier JSON du dashboard

Le fichier JSON complet est disponible dans `dashboard/hpa_php_apache.json`.


# TeamSpeak 3 Helm Chart

Ce chart Helm déploie un serveur TeamSpeak 3 sur Kubernetes avec support ARM64.

## Prérequis

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner supportant les PVC (optionnel, pour la persistence)
- Traefik v2/v3 (optionnel, pour le forwarding TCP/UDP)

## Installation

### Ajouter le repo Helm (si applicable)

```bash
helm repo add everhome https://rexbut.github.io/EverHome/charts
helm repo update
```

### Installation rapide

```bash
helm install teamspeak ./teamspeak
```

### Installation avec valeurs personnalisées

```bash
helm install teamspeak ./teamspeak \
  --set service.type=NodePort \
  --set persistence.size=5Gi
```

## Ports exposés

| Port  | Protocole | Description           |
|-------|-----------|----------------------|
| 9987  | UDP       | Voice (principal)    |
| 10011 | TCP       | ServerQuery (raw)    |
| 10022 | TCP       | ServerQuery (SSH)    |
| 30033 | TCP       | File Transfer        |

## Configuration

Les paramètres configurables sont listés ci-dessous :

| Paramètre                          | Description                                    | Valeur par défaut           |
|------------------------------------|------------------------------------------------|-----------------------------|
| `replicaCount`                     | Nombre de réplicas                             | `1`                         |
| `image.repository`                 | Image Docker                                   | `ghcr.io/rexbut/teamspeak`  |
| `image.tag`                        | Tag de l'image                                 | `appVersion`                |
| `image.pullPolicy`                 | Politique de pull                              | `IfNotPresent`              |
| `teamspeak.serverPassword`         | Mot de passe du serveur (optionnel)           | `""`                        |
| `teamspeak.serverAdminPassword`    | Mot de passe admin (auto-généré si vide)      | `""`                        |
| `service.type`                     | Type de service                                | `LoadBalancer`              |
| `service.voice.port`               | Port voix                                      | `9987`                      |
| `service.serverQuery.port`         | Port ServerQuery                               | `10011`                     |
| `service.fileTransfer.port`        | Port transfert fichiers                        | `30033`                     |
| `persistence.enabled`              | Activer la persistence                         | `true`                      |
| `persistence.size`                 | Taille du PVC                                  | `1Gi`                       |
| `persistence.storageClass`         | Classe de stockage                             | `""`                        |
| `hostNetwork`                      | Utiliser le réseau hôte                        | `false`                     |
| `resources`                        | Limites/requêtes de ressources                 | `{}`                        |
| `traefik.enabled`                  | Activer les IngressRoute Traefik               | `false`                     |
| `traefik.udp.voice.entryPoint`     | EntryPoint Traefik pour voice (UDP)            | `teamspeak-voice`           |
| `traefik.tcp.serverQuery.entryPoint` | EntryPoint Traefik pour ServerQuery          | `teamspeak-query`           |
| `traefik.tcp.fileTransfer.entryPoint` | EntryPoint Traefik pour File Transfer       | `teamspeak-filetransfer`    |

## Récupérer le token admin

Au premier démarrage, TeamSpeak génère un token admin. Pour le récupérer :

```bash
kubectl logs -f deployment/teamspeak
```

Recherchez une ligne contenant `token=` dans les logs.

## Persistence

Par défaut, le chart crée un PVC de 1Gi pour stocker :
- La base de données SQLite
- Les logs
- Les fichiers uploadés

Pour utiliser un PVC existant :

```yaml
persistence:
  enabled: true
  existingClaim: my-existing-pvc
```

## Configuration Traefik (TCP/UDP Forwarding)

Ce chart supporte Traefik comme Ingress Controller avec forwarding TCP et UDP natif.

### 1. Configurer les entrypoints dans Traefik

Ajoutez ces entrypoints dans votre configuration Traefik (values Helm ou fichier statique) :

```yaml
# Traefik Helm values
ports:
  teamspeak-voice:
    port: 9987
    protocol: UDP
    expose:
      default: true
  teamspeak-query:
    port: 10011
    protocol: TCP
    expose:
      default: true
  teamspeak-query-ssh:
    port: 10022
    protocol: TCP
    expose:
      default: true
  teamspeak-filetransfer:
    port: 30033
    protocol: TCP
    expose:
      default: true
```

### 2. Activer Traefik dans le chart TeamSpeak

```yaml
# Service en ClusterIP car Traefik gère l'exposition
service:
  type: ClusterIP

# Activer Traefik IngressRoute
traefik:
  enabled: true
  udp:
    voice:
      entryPoint: teamspeak-voice
  tcp:
    serverQuery:
      entryPoint: teamspeak-query
    serverQuerySsh:
      entryPoint: teamspeak-query-ssh
    fileTransfer:
      entryPoint: teamspeak-filetransfer
```

### 3. Déployer

```bash
helm install teamspeak ./teamspeak -f values-traefik.yaml
```

### Ressources créées

Avec `traefik.enabled: true`, le chart crée :
- `IngressRouteUDP` pour le port voice (9987/UDP)
- `IngressRouteTCP` pour ServerQuery (10011/TCP)
- `IngressRouteTCP` pour ServerQuery SSH (10022/TCP)
- `IngressRouteTCP` pour File Transfer (30033/TCP)

## Mise à jour

```bash
helm upgrade teamspeak ./teamspeak
```

**Note importante** : Utilisez `strategy.type: Recreate` (par défaut) car TeamSpeak ne supporte pas plusieurs instances sur la même base de données.

## Désinstallation

```bash
helm uninstall teamspeak
```

**Attention** : Le PVC n'est pas supprimé automatiquement pour préserver les données.

## Licence

TeamSpeak est un logiciel propriétaire. En utilisant cette image, vous acceptez la licence TeamSpeak.


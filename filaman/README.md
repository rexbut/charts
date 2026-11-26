# FilaMan Helm Chart

Ce chart Helm déploie [FilaMan](https://github.com/Fire-Devils/filaman-system), un gestionnaire de bobines de filament pour l'impression 3D, sur Kubernetes. L'image `ghcr.io/fire-devils/filaman-system` est publiée pour amd64, arm64 et armv7.

## Prérequis

- Kubernetes 1.19+
- Helm 3.0+
- Un PV provisioner supportant les PVC (Longhorn, local-path…), pour la base SQLite
- Optionnel : une base PostgreSQL (par exemple CloudNativePG) ou MySQL

## Installation

Deux clés secrètes sont obligatoires. Générez-les avec `openssl rand -hex 32` :

```bash
helm install filaman oci://ghcr.io/rexbut/charts/filaman \
  --version 0.1.0 \
  --namespace filaman --create-namespace \
  --set filaman.secretKey=$(openssl rand -hex 32) \
  --set filaman.csrfSecretKey=$(openssl rand -hex 32) \
  --set filaman.admin.email=admin@example.com \
  --set filaman.admin.password='change-me'
```

L'UI écoute sur le port 8000 :

```bash
kubectl port-forward -n filaman svc/filaman 8000:8000
```

## Exemple : Traefik + TLS

```yaml
filaman:
  secretKey: "<openssl rand -hex 32>"
  csrfSecretKey: "<openssl rand -hex 32>"
  publicUrl: https://filaman.example.com
  admin:
    email: admin@example.com
    password: "<mot de passe initial>"

ingress:
  enabled: true
  className: traefik
  hosts:
    - host: filaman.example.com
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: example-com-tls
      hosts:
        - filaman.example.com

persistence:
  storageClass: longhorn
```

## Base de données

`database.type` choisit le backend :

| Type         | `DATABASE_URL` générée                                          | Persistance |
|--------------|-----------------------------------------------------------------|-------------|
| `sqlite`     | `sqlite+aiosqlite:////app/data/filaman.db`                      | Requise (PVC sur `/app/data`) |
| `postgresql` | `postgresql+asyncpg://$(DB_USER):$(DB_PASSWORD)@host:port/base` | Optionnelle |
| `external`   | URL complète lue depuis un Secret                               | Optionnelle |

Avec PostgreSQL ou MySQL, les sauvegardes automatiques de FilaMan sont désactivées : sauvegardez la base vous-même (par exemple avec les backups CNPG).

### PostgreSQL avec CloudNativePG

CNPG crée un Secret `<cluster>-app` qui contient les clés `username` et `password`. Le chart le lit directement :

```yaml
database:
  type: postgresql
  postgresql:
    host: pg-cluster-rw.postgresql.svc.cluster.local
    port: 5432
    database: filaman
    existingSecret: pg-cluster-app
    # usernameKey: username
    # passwordKey: password
    # params: "ssl=require"

persistence:
  enabled: false
```

Le Secret doit se trouver dans le même namespace que FilaMan. Répliquez-le si besoin, par exemple avec kubernetes-replicator. Créez la base et l'utilisateur au préalable.

L'URL est construite avec la substitution `$(VAR)` de Kubernetes. Le mot de passe ne doit donc pas contenir de caractères spéciaux d'URL (`@`, `:`, `/`, `?`, `#`). Les mots de passe générés par CNPG sont alphanumériques. Sinon, utilisez `database.type: external` avec une URL encodée.

Sans Secret existant, renseignez `username` et `password` : ils sont stockés dans le Secret du chart.

### Autre base (MySQL…)

```yaml
database:
  type: external
  external:
    url: mysql+aiomysql://filaman:password@mysql.db.svc:3306/filaman
    # ou bien :
    # existingSecret: filaman-db
    # urlKey: database-url
```

### Passer de SQLite à PostgreSQL

Le chart ne migre pas les données. Exportez vos données depuis l'UI FilaMan (si votre version le permet), basculez `database.type`, puis réimportez-les. Testez d'abord sur une copie.

## Configuration

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `image.repository` | Image Docker | `ghcr.io/fire-devils/filaman-system` |
| `image.tag` | Tag de l'image | `appVersion` |
| `filaman.secretKey` | Clé de signature des sessions (**obligatoire**) | `""` |
| `filaman.csrfSecretKey` | Clé CSRF (**obligatoire**) | `""` |
| `filaman.oidcEncKey` | Clé de chiffrement OIDC (SSO uniquement) | `""` |
| `filaman.existingSecret` | Secret existant (`secret-key`, `csrf-secret-key`, `admin-password`, `oidc-enc-key`) | `""` |
| `filaman.admin.email` | Email du compte admin créé au premier démarrage | `""` |
| `filaman.admin.password` | Mot de passe admin initial | `""` |
| `filaman.admin.displayName` | Nom affiché de l'admin | `Admin` |
| `filaman.admin.language` | Langue de l'admin | `en` |
| `filaman.admin.superadmin` | Droits superadmin | `true` |
| `filaman.publicUrl` | URL publique de l'UI | `""` |
| `filaman.corsOrigins` | Origines CORS autorisées | `*` |
| `filaman.webConcurrency` | Workers Gunicorn (~90 Mo chacun) | `2` |
| `filaman.logLevel` | Niveau de log | `INFO` |
| `filaman.logFormat` | `text` ou `json` | `text` |
| `filaman.extraEnv` | Variables d'environnement supplémentaires | `[]` |
| `database.type` | `sqlite`, `postgresql` ou `external` | `sqlite` |
| `database.postgresql.*` | Voir la section PostgreSQL | |
| `database.external.*` | Voir la section Autre base | |
| `service.type` | Type de service | `ClusterIP` |
| `service.port` | Port du service | `8000` |
| `ingress.enabled` | Activer l'Ingress | `false` |
| `persistence.enabled` | Volume persistant sur `/app/data` | `true` |
| `persistence.storageClass` | StorageClass | `""` |
| `persistence.size` | Taille du volume | `1Gi` |
| `persistence.existingClaim` | PVC existant | `""` |
| `resources` | Ressources du conteneur | requests 100m/256Mi, limit 512Mi |

## Opérations

Réinitialiser le mot de passe d'un utilisateur :

```bash
kubectl exec -it -n filaman deploy/filaman -- python -m app.cli reset-password <email>
```

Logs :

```bash
kubectl logs -n filaman deploy/filaman -f
```

## Notes

- Gardez `replicaCount: 1` et `strategy: Recreate` avec SQLite et un volume ReadWriteOnce.
- L'image tourne en root (pas de `USER` dans le Dockerfile).
- Changer `secretKey` déconnecte tous les utilisateurs.

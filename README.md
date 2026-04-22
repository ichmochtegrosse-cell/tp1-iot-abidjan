# TP1 IoT — Stack MQTT + InfluxDB + Grafana

**Étudiant :** KOUADIO KOUASSI HIPOLITE  
**Formation :** Master 1 Bases de Données & Génie Logiciel — UFHB Abidjan  
**Année :** 2025-2026

---

## Description

Déploiement d'une chaîne IoT complète pour la collecte et la visualisation de données de capteurs simulés :

```
ESP32 (Wokwi) → HiveMQ (MQTT) → Telegraf → InfluxDB → Grafana
```

---

## Prérequis

- **macOS 12+ / Windows / Linux**
- **Docker Desktop** (voir requirements.md pour la version compatible macOS 12)
- **Navigateur web** (Chrome ou Firefox)
- **Compte Wokwi** (connexion avec GitHub sur wokwi.com)

---

## Démarrage rapide

### 1. Cloner le projet

```bash
git clone https://github.com/ichmochtegrosse-cell/tp1-iot-abidjan.git
cd tp1-iot-abidjan
```

### 2. Lancer la stack Docker

```bash
docker compose up -d
```

### 3. Vérifier que les 4 services tournent

```bash
docker compose ps
```

Vous devez voir **4 conteneurs** avec le statut `running` :

| Service    | Port       | Statut attendu |
|------------|------------|----------------|
| mosquitto  | 1883, 9001 | ✅ running |
| influxdb   | 8086       | ✅ running |
| telegraf   | —          | ✅ running |
| grafana    | 3000       | ✅ running |

---

## Accès aux interfaces

| Service  | URL                        | Identifiants          |
|----------|----------------------------|-----------------------|
| InfluxDB | http://localhost:8086      | admin / ufhb2024!     |
| Grafana  | http://localhost:3000      | admin / ufhb2024!     |

---

## Configuration Telegraf — Token InfluxDB

Après le premier démarrage, vous devez générer un token InfluxDB et le configurer dans Telegraf :

1. Ouvrir http://localhost:8086 → **Load Data → API Tokens**
2. Cliquer **Generate API Token → All Access Token**
3. Copier le token généré
4. Modifier `telegraf/telegraf.conf` — remplacer `YOUR_TOKEN` par votre token :

```toml
[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "VOTRE_TOKEN_ICI"
  organization = "UFHB-IoT"
  bucket = "raw_7d"
```

5. Redémarrer Telegraf :

```bash
docker compose restart telegraf
```

6. Vérifier la connexion :

```bash
docker compose logs telegraf | grep Connected
# Attendu : Connected [tcp://broker.hivemq.com:1883]
```

---

## Simulation Wokwi (ESP32 + DHT22)

1. Ouvrir le projet : https://wokwi.com/projects/460187929326734337
2. Cliquer sur **▶ Play** pour lancer la simulation
3. L'ESP32 publie des données toutes les 30 secondes sur :
   - **Topic :** `iot/CI/abidjan/cocody/env`
   - **Broker :** `broker.hivemq.com:1883`
   - **Format :** Line Protocol InfluxDB

---

## Requêtes Flux QL

Les 5 requêtes sont dans les fichiers `.flux` à la racine du projet :

| Fichier          | Description                        |
|------------------|------------------------------------|
| `r1_last.flux`   | Dernière valeur reçue              |
| `r2_moyenne.flux`| Moyenne horaire sur 24h            |
| `r3_alertes.flux`| Températures > 32°C               |
| `r4_pivot.flux`  | Pivot temp/humidité                |
| `r5_stats.flux`  | Min/Max/Moyenne sur 24h            |

Pour exécuter : InfluxDB → **Data Explorer → Script Editor** → coller le contenu du fichier.

---

## Commandes utiles

```bash
# Démarrer la stack
docker compose up -d

# Arrêter la stack
docker compose down

# Voir les logs en temps réel
docker compose logs -f telegraf

# Redémarrer un service
docker compose restart telegraf

# Vérifier l'état
docker compose ps
```

---

## Structure du projet

```
tp1-iot-abidjan/
├── docker-compose.yml          # Orchestration des 4 services
├── mosquitto/
│   └── config/
│       └── mosquitto.conf      # Configuration broker MQTT
├── telegraf/
│   └── telegraf.conf           # Agent : MQTT → InfluxDB
├── captures/                   # Captures d'écran R1-R5
├── r1_last.flux
├── r2_moyenne.flux
├── r3_alertes.flux
├── r4_pivot.flux
├── r5_stats.flux
└── README.md
```

---

## Dépannage

**Docker : command not found**  
→ Docker Desktop n'est pas lancé. Ouvrir l'application Docker Desktop et attendre que l'icône baleine apparaisse dans la barre de menu.

**Telegraf : erreur 401 Unauthorized**  
→ Le token InfluxDB a expiré. Générer un nouveau token (voir section Configuration Telegraf).

**InfluxDB : aucun résultat**  
→ Vérifier que la simulation Wokwi est active (▶ Play) et que Telegraf est connecté à HiveMQ.
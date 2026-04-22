# 🚦 Système Multi-Agent de Régulation du Trafic Urbain — Abidjan

> **Plateforme de simulation décentralisée** basée sur l'architecture **BDI** (Belief-Desire-Intention) et le protocole **FIPA-ACL**, appliquée au réseau urbain d'Abidjan (Côte d'Ivoire).

---

## 📋 Table des Matières

1. [Vue d'ensemble](#-vue-densemble)
2. [Résultats des scénarios](#-résultats-des-scénarios)
3. [Architecture du système](#-architecture-du-système)
4. [Algorithmes clés](#-algorithmes-clés)
5. [Structure du projet](#-structure-du-projet)
6. [Installation](#-installation)
7. [Utilisation](#-utilisation)
8. [Protocole FIPA-ACL](#-protocole-fipa-acl)
9. [Scénarios Abidjan](#-scénarios-abidjan)
10. [KPI et performances](#-kpi-et-performances)
11. [Évolutions futures](#-évolutions-futures)

---

## 🎯 Vue d'ensemble

Ce projet implémente une **plateforme de simulation multi-agent décentralisée** pour réguler le trafic urbain dans la métropole d'Abidjan. Contrairement aux systèmes centralisés, les décisions sont prises **localement par des agents autonomes** qui communiquent via le protocole **FIPA-ACL** (IEEE Standard).

### Points forts

| Aspect | Solution implémentée |
|--------|---------------------|
| **Architecture agents** | BDI (Belief-Desire-Intention) |
| **Communication** | FIPA-ACL : INFORM, REQUEST, CFP, PROPOSE, ACCEPT-PROPOSAL |
| **Coordination** | Contract Net Protocol + Onde verte |
| **Routage** | Dijkstra + K-shortest paths + reroutage dynamique |
| **Optimisation feux** | Algorithme Max-Pressure (adaptatif, décentralisé) |
| **Gestion de crise** | AgentGestionnaireCrise (ambulances, incidents) |
| **Compatibilité** | Python 3.10+ — Mac Intel, Linux, Windows |

---

## 📊 Résultats des scénarios

### Scénario 1 — Heure de pointe (Yopougon / Abobo → Plateau)

```
Messages FIPA   : 130     Performative : INFORM (onde verte, congestion)
Véhicules       : 10/10 arrivés
Temps trajet    : 2.32 étapes en moyenne
Reroutages      : 0  (Max-Pressure absorbe la charge)
```

### Scénario 2 — Incident Pont De Gaulle

```
Route normale   : Yopougon → Degaulle → HKB → Marcory     (dist=5)
Route de secours: Yopougon → Adjamé → Plateau → HKB → Marcory  (dist=6, +1 unité)
Véhicules reroutés : 8/8
Messages FIPA   : 121  (INFORM + REQUEST)
```

### Scénario 3 — Urgence ambulance SAMU (Contract Net Protocol)

```
Trajet prioritaire : Cocody → 2-Plateaux → Adjamé → Plateau
CFP envoyés        : 4    (Call For Proposals)
PROPOSE reçus      : 4    (une par intersection)
ACCEPT-PROPOSAL    : 1    (meilleur délai sélectionné)
REJECT-PROPOSAL    : 3    (autres intersections informées)
Onde verte activée : OUI
Crise résolue en   : 4 étapes
```

### Tableau comparatif

| Scénario | Msgs FIPA | Reroutages | Résultat |
|----------|-----------|------------|----------|
| Heure de pointe | 130 | 0 | ✅ 10/10 arrivés |
| Incident Pont De Gaulle | 121 | 8 | ✅ Contournement HKB |
| Urgence SAMU | 16 | — | ✅ Crise résolue en 4 étapes |

---

## 🏗️ Architecture du système

### 1. AgentIntersection (`src/agents/bdi/intersection_agent.py`)

Gère un carrefour avec 4 voies (N, S, E, O).

```
Beliefs  : nb_vehicules_voie, etat_feux, congestion_voisins, messages_reçus
Desires  : maximiser le débit, minimiser l'attente, coordonner les voisins
Intentions: voie_verte_suivante (Max-Pressure), durée_feu, mode_onde_verte
Actions  : changer phase feu, proposer onde verte (PROPOSE), diffuser alerte (INFORM)
```

### 2. AgentVehicule (`src/agents/bdi/vehicle_agent.py`)

Représente un véhicule en circulation avec itinéraire Dijkstra.

```
Beliefs  : position_actuelle, route_planifiée, congestion_détectée
Desires  : atteindre destination, minimiser temps, éviter congestion
Intentions: route_actuelle, besoin_reroutage
Actions  : avancer, se rerouter (REQUEST), répondre aux alertes FIPA
```

### 3. AgentGestionnaireCrise (`src/agents/bdi/crisis_manager_agent.py`)

Agent de niveau avancé pour ambulances, pompiers et bus SOTRA.

```
Beliefs  : route_urgence, statuts_intersections, position_véhicule
Desires  : passage rapide véhicule prioritaire, impact minimal sur trafic
Intentions: envoyer CFP, activer onde verte, avancer véhicule, résoudre crise
Protocole: Contract Net Protocol (CFP → PROPOSE → ACCEPT/REJECT → INFORM)
```

### Diagramme de communication

```
AgentGestionnaireCrise
    │
    ├── CFP ──────────────────► AgentIntersection [cocody]
    │                               └── PROPOSE(delay=4s) ──► AGC
    ├── CFP ──────────────────► AgentIntersection [adjame]
    │                               └── PROPOSE(delay=6s) ──► AGC
    │
    ├── ACCEPT-PROPOSAL ──────► AgentIntersection [cocody]  ← gagnant
    ├── REJECT-PROPOSAL ──────► AgentIntersection [adjame]
    │
    └── INFORM(onde_verte) ───► Toutes intersections du trajet
                                    └── ACK ────────────────► AGC
```

---

## 🔧 Algorithmes clés

### Max-Pressure (optimisation des feux)

```python
def _max_pressure_decision(self):
    """Choisir la voie avec max(véhicules entrants - véhicules sortants)."""
    pressure = {voie: self.beliefs['nb_vehicules_voie'][voie] for voie in voies}
    return max(pressure, key=pressure.get)
```

**Avantage** : adaptatif, décentralisé, prouvé asymptotiquement optimal.

### Dijkstra + reroutage dynamique

```python
path, distance = graph.dijkstra(start="yopougon", end="marcory")
# → ['yopougon', 'adjame', 'plateau', 'hkb', 'marcory'], dist=6

# Avec pont bloqué :
path_alt, _ = graph.dijkstra("yopougon", "marcory",
                              blocked_edges=["yopougon-degaulle"])
# → route alternative via HKB automatiquement
```

**Complexité** : O((V + E) log V) avec tas binaire.

### Onde verte (Green Wave)

```
Intersection[i]   : T_phase = t
Intersection[i+1] : T_phase = t + 5s (offset configurable)
Intersection[i+2] : T_phase = t + 10s
```

Résultat : les flux se succèdent sans stopper aux feux rouges.

### Contract Net Protocol (FIPA)

```
1. AGC → CFP(priority_request)  ──────────► Intersections du trajet
2. Intersections → PROPOSE(delay_seconds) ► AGC
3. AGC évalue : best = min(proposals, key=delay_seconds)
4. AGC → ACCEPT_PROPOSAL ─────────────────► Intersection gagnante
4. AGC → REJECT_PROPOSAL ─────────────────► Autres intersections
5. AGC → INFORM(onde_verte) ──────────────► Toutes intersections
```

---

## 📁 Structure du projet

```
traffic_sma_project/
├── src/
│   ├── agents/
│   │   ├── base_agent.py                      # Classe BDI de base
│   │   ├── bdi/
│   │   │   ├── intersection_agent.py          # AgentIntersection (Max-Pressure)
│   │   │   ├── vehicle_agent.py               # AgentVéhicule (Dijkstra)
│   │   │   └── crisis_manager_agent.py        # AgentGestionnaireCrise (Contract Net)
│   │   └── communication/
│   │       └── fipa_acl.py                    # ACLMessage + MessageBus + ContractNetHelper
│   ├── algorithms/
│   │   └── routing.py                         # Dijkstra + K-shortest paths
│   ├── simulation/
│   │   ├── base_model.py
│   │   └── traffic_model.py
│   └── data/
│       └── kpi_collector.py                   # KPI → CSV
├── config/abidjan/
│   ├── abidjan.net.xml
│   ├── nodes.nod.xml
│   ├── edges.edg.xml
│   └── routes.rou.xml
├── results/
│   ├── abidjan_peak_hour_kpi.csv
│   ├── abidjan_incident_degaulle_kpi.csv
│   └── abidjan_emergency_ambulance_kpi.csv
├── run_abidjan_scenarios.py                   # ← Point d'entrée principal
├── run_simulation.py
├── run_fipa_test.py
├── run_comprehensive_test.py
├── requirements.txt
└── README.md
```

---

## 📦 Installation

### Prérequis

- Python 3.10+
- pip

### Étapes

```bash
# 1. Cloner le projet
git clone https://github.com/votre-username/traffic_sma_project.git
cd traffic_sma_project

# 2. Créer l'environnement virtuel
python3 -m venv venv
source venv/bin/activate        # Mac / Linux
# ou
venv\Scripts\activate           # Windows

# 3. Installer les dépendances
pip install -r requirements.txt

# 4. Vérifier l'installation
python3 -c "import src; print('✅ Installation réussie')"
```

### requirements.txt

```
python-dotenv>=0.19.0
```

---

## 🎮 Utilisation

### Lancer tous les scénarios Abidjan (recommandé)

```bash
python3 run_abidjan_scenarios.py --all
```

### Scénarios individuels

```bash
# Scénario 1 — Heure de pointe
python3 run_abidjan_scenarios.py --scenario peak

# Scénario 2 — Incident Pont De Gaulle
python3 run_abidjan_scenarios.py --scenario incident

# Scénario 3 — Urgence ambulance SAMU
python3 run_abidjan_scenarios.py --scenario emergency
```

### Options avancées

```bash
# Modifier le nombre d'étapes
python3 run_abidjan_scenarios.py --all --steps 50

# Sans sauvegarde CSV
python3 run_abidjan_scenarios.py --all --no-csv
```

### Test FIPA-ACL seul

```bash
python3 run_fipa_test.py
```

### Simulation complète avec KPI

```bash
python3 run_comprehensive_test.py
```

### Ouvrir le dashboard de démonstration

```bash
# Option 1 — directement
open dashboard_abidjan_sma.html

# Option 2 — via serveur HTTP
python3 -m http.server 8001
# Puis ouvrir : http://localhost:8001/dashboard_abidjan_sma.html
```

---

## 📨 Protocole FIPA-ACL

### Performatives implémentées

| Performative | Usage dans le projet |
|-------------|---------------------|
| `INFORM` | Diffusion congestion, onde verte, statut intersection |
| `REQUEST` | Demande de reroutage véhicule |
| `PROPOSE` | Réponse Contract Net (intersection → AGC) |
| `CFP` | Call For Proposals — lancement Contract Net |
| `ACCEPT-PROPOSAL` | Sélection de la meilleure intersection |
| `REJECT-PROPOSAL` | Notification des intersections non retenues |
| `REFUSE` | Intersection trop chargée pour participer |
| `FAILURE` | Notification d'échec d'exécution |

### Exemple de trace FIPA (Scénario 3)

```
[000] AGC_SAMU_01 → [cocody, adjame, plateau] : CFP(priority_request, crisis=ambulance)
[001] cocody      → AGC_SAMU_01              : PROPOSE(delay_seconds=4, can_green_wave=True)
[001] adjame      → AGC_SAMU_01              : PROPOSE(delay_seconds=6, can_green_wave=True)
[001] plateau     → AGC_SAMU_01              : PROPOSE(delay_seconds=7, can_green_wave=True)
[002] AGC_SAMU_01 → cocody                   : ACCEPT-PROPOSAL(awarded=True)
[002] AGC_SAMU_01 → [adjame, plateau]        : REJECT-PROPOSAL(reason=better_proposal)
[002] AGC_SAMU_01 → [cocody, adjame, plateau]: INFORM(onde_verte, decalage=5s)
```

---

## 🗺️ Scénarios Abidjan

### Réseau simulé (12 nœuds)

```
Yopougon ──── Adjamé ──── 2-Plateaux ──── Cocody ──── Riviera
    │              │              │
  Degaulle      Plateau ─────────┘
    │              │
   HKB ───────────┤
    │              │
Treichville ── Marcory ── Port-Bouët
```

### Scénario 1 — Heure de pointe

- **Contexte** : Flux massif Yopougon/Abobo → Plateau (8h-9h du matin)
- **Charge simulée** : 14-16 véhicules/voie sur Adjamé (goulot)
- **Mécanismes activés** : Max-Pressure, onde verte Adjamé→Plateau (offset=5s)
- **KPI** : 10/10 véhicules arrivés, 130 messages FIPA

### Scénario 2 — Incident Pont De Gaulle

- **Contexte** : Panne de véhicule — Pont De Gaulle inaccessible
- **Détection** : INFORM(bridge_blocked) diffusé par l'agent `degaulle`
- **Reroutage** : Dijkstra recalcule via Pont HKB (+1 unité de distance)
- **KPI** : 8/8 véhicules reroutés, allongement maîtrisé (+20%)

### Scénario 3 — Urgence SAMU (Contract Net)

- **Contexte** : Ambulance SAMU — trajet Cocody → Plateau en urgence
- **Protocole** : CFP → PROPOSE × 4 → ACCEPT-PROPOSAL → Onde verte
- **Résultat** : Crise résolue en 4 étapes, onde verte activée, trafic normal restauré

---

## 📈 KPI et performances

### Indicateurs collectés

| KPI | Description | Unité |
|-----|-------------|-------|
| `avg_travel` | Temps de trajet moyen | étapes |
| `msgs_total` | Nombre total de messages FIPA échangés | messages |
| `reroutages` | Nombre de reroutages dynamiques effectués | véhicules |
| `arrived` | Nombre de véhicules ayant atteint destination | véhicules |
| `hkb_load` | Charge sur le Pont HKB (scénario 2) | véhicules/voie |

### Fichiers CSV générés

```
results/
├── abidjan_peak_hour_kpi.csv         # Scénario 1 — 25 lignes
├── abidjan_incident_degaulle_kpi.csv # Scénario 2 — 25 lignes
└── abidjan_emergency_ambulance_kpi.csv # Scénario 3 — N lignes
```

---

## 🚀 Évolutions futures

### Court terme

- [ ] Intégration SUMO complète (vraie physique de véhicules)
- [ ] Visualisation 2D temps réel (pygame / matplotlib)
- [ ] Scénarios complets : Pont HKB, Boulevard VGE

### Moyen terme

- [ ] Q-Learning pour optimisation feux (comparaison avec Max-Pressure)
- [ ] Base de données MongoDB/PostgreSQL pour historisation KPI
- [ ] API REST pour exposer la simulation en HTTP

### Long terme

- [ ] Déploiement distribué multi-machines (agents sur nœuds séparés)
- [ ] Deep Q-Network (DQN) pour adaptation météo/événements
- [ ] Intégration OpenStreetMap — vrai réseau Abidjan

---

## 🤝 Contribution

```bash
# 1. Fork le projet
# 2. Créer une branche
git checkout -b feature/NomFeature

# 3. Committer
git commit -m "Add: NomFeature"

# 4. Pusher
git push origin feature/NomFeature

# 5. Ouvrir une Pull Request
```

---

## 📄 Licence

Ce projet est sous licence **MIT**. Voir le fichier `LICENSE` pour les détails.

---

## 👥 Auteurs

**Équipe de Simulation Multi-Agent** — Cours Intelligence Artificielle Distribuée  
Université / École d'Ingénieurs — Abidjan, Côte d'Ivoire

---

## 📚 Références

- FIPA ACL Message Structure Specification — IEEE, 2002
- Max-Pressure Traffic Signal Control — Varaiya, 2013
- Dijkstra, E.W. — A note on two problems in connexion with graphs, 1959
- Wooldridge, M. — An Introduction to MultiAgent Systems, 2009
- SUMO — Simulation of Urban MObility : https://sumo.dlr.de

---

*Dernière mise à jour : Mars 2026 — Version 1.0.0*

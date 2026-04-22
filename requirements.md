# Requirements & Guide d'installation

## Outils nécessaires

### Docker Desktop
- **macOS 14+ (Sonoma) :** https://desktop.docker.com/mac/main/amd64/Docker.dmg
- **macOS 12-13 (Monterey/Ventura) :** https://desktop.docker.com/mac/main/amd64/93002/Docker.dmg
- **Windows :** https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe
- **Linux :** `sudo apt install docker.io docker-compose`

### Git
- macOS : `xcode-select --install` (inclut git)
- Windows : https://git-scm.com/download/win

### VS Code (recommandé)
- https://code.visualstudio.com/download
- Extensions utiles : **Docker** (Microsoft), **YAML** (Red Hat)

---

## Versions utilisées dans ce projet

| Outil           | Version   |
|-----------------|-----------|
| Docker Engine   | 20.10.21  |
| Docker Compose  | v2.13.0   |
| Mosquitto       | 2.x       |
| InfluxDB        | 2.7       |
| Telegraf        | 1.28      |
| Grafana         | 10.0.0    |

---

## Vérification de l'installation

Après avoir installé Docker Desktop et l'avoir lancé :

```bash
docker --version
# Docker version 20.10.x

docker compose version
# Docker Compose version v2.x.x
```

Si ces commandes retournent `command not found`, Docker Desktop n'est pas démarré.

---

## Notes spécifiques macOS

- **macOS 12 (Monterey) :** Utiliser Docker Desktop 4.15 (lien ci-dessus), pas la version actuelle
- Ignorer les alertes de mise à jour Docker — le projet fonctionne avec la version 4.15
- Obtenir son IP locale : `ipconfig getifaddr en0`
- Autoriser les connexions réseau quand macOS le demande (ports 1883, 8086, 3000)

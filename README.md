# Leetchi — Widget iOS TCL Lyon

Application iOS avec widget WidgetKit affichant les **prochains passages TCL** (bus, tram, métro) de Lyon, en appelant directement l'API Datapusher du Grand Lyon.

![Schéma du widget](.github/widget-preview.png)

## Fonctionnalités

- **Widget homescreen** (petit, moyen, grand) affichant les prochains passages TCL en temps réel
- **Application principale** avec vue liste complète et rafraîchissement manuel
- **Configuration flexible** : URL Datapusher Grand Lyon, identifiants optionnels, lignes et IDs d'arrêts personnalisables
- Rafraîchissement automatique du widget toutes les **5 minutes**

## Architecture

```
leetchi/
├── Shared/                          # Code partagé (app + widget)
│   ├── TCLModels.swift              # Modèles de données & configuration
│   └── TCLService.swift             # Service réseau (Datapusher Grand Lyon)
│
├── leetchi/                         # Cible application iOS
│   ├── leetchApp.swift
│   ├── ContentView.swift            # Liste des passages avec pull-to-refresh
│   ├── ConfigurationView.swift      # Paramètres (URL, lignes, arrêts)
│   ├── Assets.xcassets/
│   ├── Info.plist
│   └── leetchi.entitlements
│
├── leetchWidget/                    # Cible extension WidgetKit
│   ├── leetchWidgetBundle.swift
│   ├── leetchWidget.swift           # Provider de timeline
│   ├── leetchWidgetView.swift       # Vues (small / medium / large)
│   ├── Assets.xcassets/
│   ├── Info.plist
│   └── leetchWidgetExtension.entitlements
│
└── project.yml                      # Spécification XcodeGen
```

## Prérequis

- **Xcode 15+** (macOS 13 Ventura ou supérieur)
- **iOS 17+** sur l'appareil ou simulateur cible
- Accès à l'API Datapusher Grand Lyon : `https://data.grandlyon.com/fr/datapusher/ws/rdata/`
- Identifiants Grand Lyon (optionnels dans l'app, selon votre accès)
- **XcodeGen** pour générer le `.xcodeproj` (recommandé) :

  ```sh
  brew install xcodegen
  ```

## Installation

### 1. Générer le projet Xcode

```sh
git clone https://github.com/LudovicDebost/leetchi.git
cd leetchi
xcodegen generate
open leetchi.xcodeproj
```

### 2. Configurer les App Groups

Dans Xcode, pour les **deux** cibles (`leetchi` et `leetchWidget`) :

1. Sélectionnez la cible → onglet **Signing & Capabilities**
2. Cliquez **+ Capability** → ajoutez **App Groups**
3. Ajoutez le groupe : `group.fr.leetchi.shared`

> Les deux cibles doivent utiliser **le même** identifiant d'App Group.

### 3. Configurer votre équipe de développement

Dans `project.yml` (ou dans Xcode), renseignez votre `DEVELOPMENT_TEAM`.

### 4. Lancer sur simulateur / appareil

Sélectionnez le scheme `leetchi` et appuyez sur ▶.

## Configuration de l'app

Au premier lancement, l'app utilise les valeurs par défaut :

| Paramètre | Valeur par défaut |
|-----------|------------------|
| URL base Datapusher | `https://data.grandlyon.com/fr/datapusher/ws/rdata/` |
| Utilisateur | *(vide)* |
| Mot de passe | *(vide)* |
| Lignes | `C26,70` |
| IDs d'arrêts | `2294,42561` |
| Directions | *(toutes)* |

Appuyez sur ⚙️ dans l'app pour modifier ces valeurs.

### Trouver les IDs d'arrêts

Les IDs sont disponibles sur le [portail data Grand Lyon](https://data.grandlyon.com/portail/fr/jeux-de-donnees/points-arret-reseau-transports-commun-lyonnais/donnees).

> ⚠️ Un ID d'arrêt est lié à **une direction** (un quai). Pour afficher les deux sens, il faut les deux IDs de quai (ex. `30101` et `30459` pour Perrache ligne A).

## API Datapusher Grand Lyon utilisée

Le service appelle directement ces endpoints :

```text
GET /tcl_sytral.tclpassagearret/all.json?ligne__in=C26,70&id__in=2294,42561
GET /tcl_sytral.tclarret/all.json?id__in=2294,42561
```

Le premier endpoint renvoie les passages (ligne, direction, heure, id d'arrêt) et le second permet de résoudre `id -> nom d'arrêt`.

L'app reconstruit ensuite une structure métier :

```json
{
  "C26": {
    "Montluc": {
      "Gare Part-Dieu": ["14:32", "14:47"]
    }
  },
  "70": {
    "Montluc": {
      "Bellecour": ["14:35", "14:50"]
    }
  }
}
```

## Ajouter le widget

1. Maintenez appuyé sur l'écran d'accueil jusqu'au mode édition
2. Appuyez sur **+** → recherchez **Leetchi**
3. Choisissez la taille (petit, moyen, grand) et ajoutez-le

Le widget se rafraîchit automatiquement toutes les 5 minutes.

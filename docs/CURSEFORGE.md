# Fiche du projet CurseForge

Tout ce qu'il faut pour créer le projet sur CurseForge (formulaire « Create project »), puis brancher
l'envoi automatique des versions.

## 1. Formulaire de création

| Champ | Valeur |
|---|---|
| **Project name** | `Questify` |
| **Logo** | [`docs/curseforge/logo-400.png`](curseforge/logo-400.png) (400 × 400). Grande version : [`logo-1024.png`](curseforge/logo-1024.png), source : [`logo.svg`](curseforge/logo.svg). Dessin original : un « Q » en boussole dont la queue mène à un repère ; ni logo du jeu, ni élément de Blizzard. |
| **Summary** (anglais, une ligne) | `Free, open-source leveling guide: optimized step-by-step routes, navigation and quest automation.` |
| **Class** | Addons |
| **Main category** | Quests & Leveling |
| **Additional categories** | Map & Minimap ; Class (si la catégorie est proposée) |
| **Allow Comments** | coché |
| **Unlisted project** | décoché (cocher seulement pour un essai privé avant les premiers retours en jeu) |
| **Social Links** | GitHub : `https://github.com/questify-addon/questify` |

Après la création, dans les réglages du projet :
- **License** : GNU General Public License version 3 (GPLv3), comme le dépôt.
- **Source / Issues / Wiki** : `https://github.com/questify-addon/questify`,
  `https://github.com/questify-addon/questify/issues`, `https://github.com/questify-addon/questify/wiki`.
- **Description** : le texte de la section 3 ci-dessous (éditeur en Markdown).
- **Images** : les aperçus anglais de `docs/media/apercus/en/`, dans l'ordre et avec les légendes de la
  section 4 (marqués « Interface preview » ; les captures en jeu de `docs/media/` les remplaceront).
  Vidéos : liens YouTube.

## 2. Envoi automatique des versions

Le workflow `.github/workflows/release.yml` envoie le zip sur CurseForge à chaque tag `vX.Y.Z`, dès que
deux secrets existent. À faire une fois, par toi (les jetons ne passent jamais par moi) :

1. Note l'**ID du projet** : encadré « About Project » de la page du projet (un nombre).
2. Crée un **jeton d'API** : <https://authors.curseforge.com/#/settings/api-tokens>.
3. Enregistre les deux secrets dans le dépôt GitHub (chaque commande demande la valeur, à coller) :

```bash
gh secret set CF_PROJECT_ID --repo questify-addon/questify
```

```bash
gh secret set CF_API_KEY --repo questify-addon/questify
```

La version du jeu envoyée est `1.60.1` (WoW: Forever) ; pour une autre, crée la variable
`CF_GAME_VERSION` dans les réglages du dépôt (Settings > Secrets and variables > Actions > Variables).
Type de fichier : « release » pour un tag `vX.Y.Z`, « beta » pour `vX.Y.Z-beta.N`, « alpha » pour
`vX.Y.Z-alpha.N`. Si les secrets sont posés après un tag, relance le job : `gh run rerun <id> --failed`.

## 3. Description (à coller)

---

## Questify — free leveling guide for WoW: Forever

**Français** — Guide de leveling **gratuit et open source** pour World of Warcraft: Forever, niveaux 1 à 30,
toutes les races et les deux factions.

- Route optimisée étape par étape : toutes les quêtes d'un avant-poste prises d'un coup, un seul passage
  par zone d'objectifs, pas d'aller-retour inutile.
- Étapes cochées automatiquement selon ton journal ; étapes impossibles pour ton personnage sautées.
- Navigation : repère 3D natif, ou ShortestPath Forever, WaypointUI, TomTom.
- Mode zone : objectifs de plusieurs quêtes regroupés (objets, nommés, puis monstres).
- Monstres à tuer sous l'objectif : un clic cible et pose le crâne.
- Quêtes de classe et donjons conseillés selon ton niveau et ta faction, ajoutables à la route.
- Acceptation, rendu et choix de récompense automatiques (désactivables).
- Épingles numérotées sur la carte du monde.

**Requis :** [QuestieDB](https://www.curseforge.com/wow/addons/questiedb).
**Optionnels :** [ShortestPath Forever](https://www.curseforge.com/wow/addons/shortest-path-forever),
[WaypointUI](https://www.curseforge.com/wow/addons/waypointui), [TomTom](https://www.curseforge.com/wow/addons/tomtom).

**English** — A **free and open-source** leveling guide for World of Warcraft: Forever, levels 1 to 30,
every race and both factions.

- Optimized step-by-step routes: whole hub pickups, one pass per objective area, no pointless
  back-and-forth; progress follows your quest log.
- Navigation: native marker, ShortestPath Forever, WaypointUI or TomTom; zone mode; mob targeting with
  a skull marker; numbered map pins.
- Class quests and suggested dungeons; optional auto accept / turn-in / reward choice.

**Required:** QuestieDB. **Optional:** ShortestPath Forever, WaypointUI, TomTom.

Code, issues, wiki and installation guide: <https://github.com/questify-addon/questify>

---

## 4. Images à téléverser

Aperçus en anglais (maquettes tirées du code, marquées « Interface preview »), 1920 × 1080, dans
l'ordre conseillé : la première sert de couverture. Sources : `docs/media/apercus/src/en/*.html`, rendu
avec `sh docs/media/apercus/src/render.sh docs/media/apercus/src/en/*.html`. Colle la légende dans le
champ « Description » de chaque image (le titre peut reprendre sa première partie).

| # | Fichier | Légende (anglais) |
|---|---|---|
| 1 (couverture) | [`en/01-tracker.png`](media/apercus/en/01-tracker.png) | The tracker: chapter progress, XP left and XP per hour, the current step with its distance and the monsters to kill, then the next steps. |
| 2 | [`en/11-zone-mode.png`](media/apercus/en/11-zone-mode.png) | Zone mode: objectives of several quests in the same place are grouped into one visit, objects first, then elites and named, then monsters. |
| 3 | [`en/08-journal-route.png`](media/apercus/en/08-journal-route.png) | The journal (/qf): your faction's chapters and every step of the route. Click a step to make it the current one. |
| 4 | [`en/13-cave-entrance.png`](media/apercus/en/13-cave-entrance.png) | Caves: when the objective is inside a known cave, the waypoint leads to the entrance first, titled "Cave entrance — The Grizzled Den". |
| 5 | [`en/10-quest-item.png`](media/apercus/en/10-quest-item.png) | Quest item button next to the tracker: click to use the item the current step needs, or bind it to a key. |
| 6 | [`en/14-equip-pair.png`](media/apercus/en/14-equip-pair.png) | Gear upgrades announced in the middle of the screen. With a two-hander equipped, a better one-hander and shield pair is equipped in one click. |
| 7 | [`en/06-class-quest.png`](media/apercus/en/06-class-quest.png) | Class quests: an alert when a chain becomes available, its start, rewards and XP, and one click to add it to your route. |
| 8 | [`en/07-dungeon.png`](media/apercus/en/07-dungeon.png) | Suggested dungeons for your level and faction, with the quests to pick up in town before you go. |
| 9 | [`en/02-wizard.png`](media/apercus/en/02-wizard.png) | First-run wizard: required and optional addons are detected, with a CurseForge link for the missing ones. |
| 10 | [`en/08b-journal-options.png`](media/apercus/en/08b-journal-options.png) | The options window: eleven sections, search, an "i" help on every setting, and profiles you can share. |
| 11 | [`en/bonus-themes.png`](media/apercus/en/bonus-themes.png) | Four tracker themes: Parchment (default), Black, Transparent and Grey fade. |

La maquette du choix de suite (popup refaite en v2) et celle de l'alerte d'avant-poste viendront plus
tard.

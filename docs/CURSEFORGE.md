# Fiche du projet CurseForge

Tout ce qu'il faut pour créer le projet sur CurseForge (formulaire « Create project »), puis brancher
l'envoi automatique des versions.

## 1. Formulaire de création

| Champ | Valeur |
|---|---|
| **Project name** | `Questify` |
| **Logo** | [`docs/curseforge/logo-400.png`](curseforge/logo-400.png) (400 × 400). Grande version : [`logo-1024.png`](curseforge/logo-1024.png), source : [`logo.svg`](curseforge/logo.svg). Dessin original : un « Q » en boussole dont la queue mène à un repère ; ni logo du jeu, ni élément de Blizzard. |
| **Summary** (anglais, une ligne) | `Free, open-source leveling guide: optimized step-by-step routes, navigation, talent builds and quest automation.` |
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
- **Images** : les captures de `docs/media/` (en attendant, les aperçus de `docs/media/apercus/`,
  marqués « Aperçu de l'interface »). Vidéos : liens YouTube.

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
- **Builds de talents niveau par niveau** pour les 9 classes, suivis tout seuls selon ta spécialisation :
  à chaque point, une fenêtre « Apprendre » ; halo sur le bon talent dans la fenêtre des talents ;
  éditeur pour créer, partager (texte `QFYB1:`) ou importer un lien du calculateur Icy Veins.
- **Sorts à apprendre** : prix chez le maître, route vers le maître le plus proche, quêtes de totems.
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
- **Level-by-level talent builds** for all 9 classes, followed automatically for your specialization:
  a "Learn" popup at each point, a halo on the right talent in the talent window, and an editor to create,
  share (`QFYB1:` text) or import an Icy Veins calculator link.
- **Spells to learn**: trainer cost, route to the nearest trainer, totem quests.
- Class quests and suggested dungeons; optional auto accept / turn-in / reward choice.

**Required:** QuestieDB. **Optional:** ShortestPath Forever, WaypointUI, TomTom.

Talent builds credit their sources (Icy Veins, Wowhead) or come from Questify's own analysis.
Code, issues, wiki and installation guide: <https://github.com/questify-addon/questify>

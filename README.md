# Questify Vanilla

Guide de leveling **gratuit et open source** pour **World of Warcraft: Forever** (niveaux 1 à 30).
*A **free and open-source** leveling guide for **World of Warcraft: Forever** (levels 1 to 30).*

---

## Français

### Ce que fait l'addon
- Une route optimisée par race et par faction, étape par étape : prendre, faire et rendre les quêtes,
  points de vol, pierre de foyer, bateaux.
- Les étapes se cochent toutes seules selon ton journal de quêtes ; les étapes impossibles pour ton
  personnage sont sautées.
- Navigation vers chaque étape (marqueur natif du jeu, ou TomTom, WaypointUI, ShortestPath Forever).
- Monstres à tuer sous chaque objectif (clic ou touche de ciblage auto : cible + crâne), quêtes de classe, acceptation et rendu automatiques (désactivables).

### Installation
Le zip est téléchargeable dans la dernière version publiée du dépôt GitHub :
<https://github.com/questify-addon/questify/releases/tag/latest>.
1. Télécharge `Questify_Vanilla-<version>-forever.zip` et décompresse-le dans
   `World of Warcraft\_forever_\Interface\AddOns\` (le dossier `Questify_Vanilla` doit se trouver
   directement dans `AddOns`).
2. Installe [**QuestieDB**](https://www.curseforge.com/wow/addons/questiedb) depuis CurseForge :
   c'est une dépendance obligatoire (les données de quêtes viennent de là).
3. Facultatif : installe [**ShortestPath Forever**](https://www.curseforge.com/wow/addons/shortest-path-forever)
   (calcul d'itinéraire), [**WaypointUI**](https://www.curseforge.com/wow/addons/waypointui) ou
   [**TomTom**](https://www.curseforge.com/wow/addons/tomtom) (affichage de la destination).

### Dépendances
| Addon | Rôle | Obligatoire |
|---|---|---|
| QuestieDB | Données des quêtes, PNJ et objets | oui |
| ShortestPath Forever | Itinéraire entre zones (vols, bateaux) | non |
| WaypointUI | Marqueur de destination | non |
| TomTom | Flèche de destination | non |

Sans addon de navigation, Questify utilise le marqueur 3D natif du jeu.

### Première connexion : liste de vérification
Ces points ne se vérifient que dans le jeu (le client Forever n'est pas simulable). Commence par
`/qf check` : l'addon vérifie seul les fonctions du jeu qu'il utilise, QuestieDB, le repère, la
navigation et la route, et affiche une ligne par point. Si quelque chose échoue (ici ou dans la
liste ci-dessous), tape `/qf bug`, copie le texte (il est déjà sélectionné : Ctrl + C) et colle-le
dans une issue GitHub : il contient la version, le client, le personnage, la route (étape courante
et suivantes, cible), la position, la navigation, le journal de quêtes, les réglages, le résultat
de `/qf check` et les erreurs Lua avec leur pile d'appels (gardées même après `/reload`, y compris
celles du chargement).
Si le jeu indique l'addon « périmé » (numéro d'interface changé par un patch), coche « Charger les
addons périmés ».
- [ ] L'addon apparaît dans la liste des addons, sans message d'erreur Lua au chargement (le client
      reconnaît `Questify_Vanilla_Camelot.toc` ; QuestieDB est chargé, sinon le client ou Questify le signale).
- [ ] L'assistant de navigation s'ouvre environ 3 secondes après la première connexion, applique le
      choix tout de suite et ne se rouvre pas après « Terminer » ou la fermeture.
- [ ] Le marqueur natif s'affiche sur l'étape courante (et TomTom, WaypointUI ou ShortestPath Forever
      si installés) ; il disparaît ou change quand l'étape change.
- [ ] Les étapes se cochent toutes seules : prise et rendu de quête, point de vol découvert, pierre
      de foyer liée. Le rayon de 15 yards des étapes `goto` n'est pas trop serré.
- [ ] `/tm` fonctionne en solo : un clic sur un monstre sous l'objectif cible le plus proche et lui pose
      un crâne, une seule fois par clic, avec `ActionButtonUseKeyDown` à 0 puis à 1.
- [ ] Option « Touche de ciblage auto » : une touche liée dans Échap > Raccourcis > Questify Vanilla
      cible le monstre d'objectif le plus proche et lui pose un crâne hors combat, et ne fait rien
      en combat.
- [ ] Étape avec un objet à utiliser (coffre, seau) et marqueur natif : animation dorée centrée sur
      l'objet, qui disparaît hors de l'écran ou au-delà de 50 m (option « Animer l'objet à utiliser »).
- [ ] L'acceptation et le rendu automatiques fonctionnent sur les quêtes de la route, et Maj (Shift)
      les suspend.
- [ ] Le choix de récompense automatique propose une amélioration ou, à défaut, l'objet qui se vend le
      plus cher ; il ne choisit rien quand les objets ne sont pas encore chargés.
- [ ] Aucune erreur en combat : pas de message d'action d'interface bloquée par un addon,
      le suivi peut grandir en combat, les boutons de ciblage se replacent à la fin du combat.
- [ ] Aucune erreur avec des valeurs secrètes en combat, ni dans une instance (barres de nom
      interdites).
- [ ] Le suivi est bien placé à 1080p, avec une échelle d'interface de 1 et de 0,8 : lisible, les
      textes longs passent à la ligne, le déplacement et le verrouillage marchent, la position
      survit à `/reload`, les boutons de taille fonctionnent, pas de chevauchement avec le suivi de Blizzard.
- [ ] Les monstres sous l'objectif : modèle 3D au survol (point d'interrogation si le modèle n'est pas
      en cache), icône qui rebondit sur les bonnes barres de nom et qui disparaît à l'objectif rempli.
- [ ] Le journal : cadre, titre, onglets, Échap pour fermer, défilement à la molette, infobulles des
      objets ; la fenêtre des quêtes de classe (icône de classe, objets, zone de départ).
- [ ] Les commandes : `/qf`, `/questify`, le bouton du menu des addons, `/qf reset` demande une
      confirmation, `/qf export` sélectionne le texte pour Ctrl + C.
- [ ] Client français : aucun bouton tronqué (par exemple « Réinitialiser la progression du
      chapitre »), noms de quêtes et de monstres corrects, ciblage par nom opérationnel.
- [ ] Les quêtes à plusieurs sites d'objectifs (par exemple 3361 au chapitre 1) pointent le bon objectif.

### Commandes
- `/questify` ou `/qf` : ouvrir ou fermer le journal.
- `/qf skip` : passer l'étape courante ; `/qf back` : revenir à l'étape précédente.
- `/qf options` : options ; `/qf wizard` : assistant de navigation.
- `/qf export` : exporter les mesures de temps par étape (rien n'est envoyé automatiquement).
- `/qf check` : autodiagnostic (fonctions du jeu, QuestieDB, repère, navigation, route, erreurs).
- `/qf bug` (ou `/qf report`) : rapport de bug prêt à copier (bouton « Rapport de bug » dans les
  options) ; `/qf bug clear` vide les erreurs enregistrées.
- `/qf talents` : relevé des arbres de talents du client (pour écrire les builds).
- `/qf debug` : mode débogage ; `/qf reset` : réinitialiser la progression du personnage.

Dans le suivi : clic droit pour passer une étape, Maj + clic droit pour revenir en arrière.
Maintenir Maj (Shift) suspend l'acceptation et le rendu automatiques.

### Licence
GPL-3.0-or-later (voir `LICENSE`). Les données de QuestieDB ne sont pas redistribuées : elles sont
lues en jeu depuis l'addon QuestieDB.

---

## English

### What it does
- An optimized route per race and faction, step by step: accept, complete and turn in quests,
  flight paths, hearthstone, boats.
- Steps tick themselves off from your quest log; steps your character cannot do are skipped.
- Navigation to every step (native in-game marker, or TomTom, WaypointUI, ShortestPath Forever).
- Mob list for objectives, class quests, automatic accept and turn-in (can be turned off).

### Installation
The zip can be downloaded from the GitHub repository's latest release:
<https://github.com/questify-addon/questify/releases/tag/latest>.
1. Download `Questify_Vanilla-<version>-forever.zip` and unzip it into
   `World of Warcraft\_forever_\Interface\AddOns\` (the `Questify_Vanilla` folder must sit directly
   inside `AddOns`).
2. Install [**QuestieDB**](https://www.curseforge.com/wow/addons/questiedb) from CurseForge: it is a
   required dependency (quest data comes from it).
3. Optional: install [**ShortestPath Forever**](https://www.curseforge.com/wow/addons/shortest-path-forever)
   (routing), [**WaypointUI**](https://www.curseforge.com/wow/addons/waypointui) or
   [**TomTom**](https://www.curseforge.com/wow/addons/tomtom) (destination display).

### Dependencies
| Addon | Role | Required |
|---|---|---|
| QuestieDB | Quest, NPC and object data | yes |
| ShortestPath Forever | Routing between zones (flights, boats) | no |
| WaypointUI | Destination marker | no |
| TomTom | Destination arrow | no |

Without a navigation addon, Questify uses the game's native 3D waypoint.

### First launch: checklist
These can only be checked in game (the Forever client cannot be simulated). Start with `/qf check`:
the addon checks on its own the game functions it uses, QuestieDB, the map pin, navigation and the
route, and prints one line per item. If something fails (there or in the list below), type
`/qf bug`, copy the text (it is already selected: Ctrl + C) and paste it in a GitHub issue: it holds
the version, client, character, route (current and next steps, target), position, navigation, quest
log, settings, the `/qf check` results and the Lua errors with their call stack (kept even after
`/reload`, including those raised while loading).
If the game says the addon is out of date (interface number changed by a patch), tick "Load out of
date AddOns".
- [ ] The addon shows in the addon list with no Lua error on load (the client recognizes
      `Questify_Vanilla_Camelot.toc`; QuestieDB is loaded, otherwise the client or Questify warns you).
- [ ] The navigation wizard opens about 3 seconds after the first login, applies your choice at once
      and does not reopen after Finish or close.
- [ ] The native marker shows on the current step (and TomTom, WaypointUI or ShortestPath Forever
      when installed); it disappears or changes when the step changes.
- [ ] Steps tick themselves off: quest accept and turn-in, discovered flight path, bound
      hearthstone. The 15-yard radius of `goto` steps is not too tight.
- [ ] `/tm` works solo: clicking a mob in the panel targets the nearest one and puts a skull on it,
      once per click, with `ActionButtonUseKeyDown` set to 0 and then 1.
- [ ] Automatic accept and turn-in work on route quests, and Shift pauses them.
- [ ] Automatic reward choice picks an upgrade or, failing that, the item with the highest vendor
      price; it picks nothing while the reward items are not loaded yet.
- [ ] No errors in combat: no "Interface action failed because of an AddOn" message, the tracker can
      grow in combat, the mob panel rebuilds after combat.
- [ ] No errors with secret values in combat, or inside instances (forbidden nameplates).
- [ ] The tracker is well placed at 1080p, with UI scale 1 and 0.8: readable, long texts wrap,
      drag and lock work, the position survives `/reload`, the size buttons work, no overlap with
      Blizzard's tracker.
- [ ] The mob panel: 3D model on hover (question mark when the model is not cached), icon bounces on
      the right nameplates and disappears when the objective is complete.
- [ ] The journal: frame, title, tabs, Escape closes it, mouse-wheel scrolling, item tooltips; the
      class quest popup (class icon, items, starting zone).
- [ ] Commands: `/qf`, `/questify`, the addon compartment button, `/qf reset` asks for confirmation,
      `/qf export` selects the text for Ctrl + C.
- [ ] French client: no truncated buttons (for example "Réinitialiser la progression du chapitre"),
      correct quest and mob names, targeting by name works.
- [ ] Quests with several objective sites (for example 3361 in chapter 1) point to the right objective.

### Commands
- `/questify` or `/qf`: open or close the journal.
- `/qf skip`: skip the current step; `/qf back`: go back one step.
- `/qf options`: options; `/qf wizard`: navigation wizard.
- `/qf export`: export the per-step timing data (nothing is ever sent automatically).
- `/qf check`: self-check (game functions, QuestieDB, map pin, navigation, route, errors).
- `/qf bug` (or `/qf report`): bug report ready to copy ("Bug report" button in the options);
  `/qf bug clear` empties the saved errors.
- `/qf talents`: records the client's talent trees (to write builds).
- `/qf debug`: debug mode; `/qf reset`: reset this character's progress.

In the tracker: right-click skips a step, Shift + right-click goes back.
Holding Shift pauses automatic accept and turn-in.

### License
GPL-3.0-or-later (see `LICENSE`). QuestieDB data is not redistributed: it is read in game from the
QuestieDB addon.

---

## Développement / Development

- Tests: `luajit tests/run.lua [pattern]` (WoW API mock in `tests/wow_mock.lua`).
- Syntax check: `tools/check_syntax.sh`.
- Release check and zip: `tools/package.sh` runs the syntax check, the tests and `tools/validate_guides.lua`,
  then writes `dist/Questify_Vanilla-<version>.zip` (version read from `## Version:` in the TOC).
  Changes are listed in `CHANGELOG.md`.

# Questify Vanilla

Guide de leveling **gratuit et open source** pour **World of Warcraft: Forever** (niveaux 1 à 30).
*A **free and open-source** leveling guide for **World of Warcraft: Forever** (levels 1 to 30).*

## Installation rapide / Quick install

| Addon | Statut / Status | Lien / Link |
|---|---|---|
| **Questify Vanilla** | requis / required | [Télécharger / Download](https://github.com/questify-addon/questify/releases/tag/latest) (`Questify_Vanilla-<version>-forever.zip`) |
| **QuestieDB** | **requis / required** | [CurseForge](https://www.curseforge.com/wow/addons/questiedb) |
| ShortestPath Forever | optionnel / optional | [CurseForge](https://www.curseforge.com/wow/addons/shortest-path-forever) |
| WaypointUI | optionnel / optional | [CurseForge](https://www.curseforge.com/wow/addons/waypointui) |
| TomTom | optionnel / optional | [CurseForge](https://www.curseforge.com/wow/addons/tomtom) |

Décompresse chaque zip dans `World of Warcraft\_forever_\Interface\AddOns\`, relance le jeu, puis suis
l'assistant. *Unzip each zip into `World of Warcraft\_forever_\Interface\AddOns\`, restart the game,
then follow the wizard.* Guide complet / full guide : [docs/wiki/Installation.md](docs/wiki/Installation.md).

## Galerie / Gallery

Captures et vidéos à venir : liste des prises de vue dans [docs/media/README.md](docs/media/README.md).
*Screenshots and videos coming soon.*

<!-- Quand les fichiers existent, décommenter / When the files exist, uncomment:
![Suivi / Tracker](docs/media/01-tracker.png)
![Mode zone / Zone mode](docs/media/03-zone-mode.gif)
![Ciblage / Targeting](docs/media/04-mobs-target.gif)
![Carte / Map pins](docs/media/05-map-pins.png)
-->

---

## Français

### Ce que fait l'addon
- Une route optimisée par race et par faction, étape par étape : prendre, faire et rendre les quêtes,
  points de vol, pierre de foyer, bateaux.
- Les étapes se cochent toutes seules selon ton journal de quêtes ; les étapes impossibles pour ton
  personnage sont sautées.
- Navigation vers chaque étape (marqueur natif du jeu, ou TomTom, WaypointUI, ShortestPath Forever).
- Monstres à tuer sous chaque objectif (clic ou touche de ciblage auto : cible + crâne), quêtes de classe, acceptation et rendu automatiques (désactivables).
- Donjons conseillés selon ton niveau et ta faction (non publié) : un clic ajoute ses quêtes à prendre
  en ville, l'entrée et les rendus à la route (option pour couper l'alerte).
- Repères numérotés de l'étape courante et des 5 suivantes sur la carte du monde et la minicarte (non publié, option).
- Mode zone (non publié, option) : objectifs proches de plusieurs quêtes regroupés en une seule visite (repère vert, puis objets, nommés et monstres par priorité).
- Un assistant de premier démarrage : addons installés ou manquants (avec leur lien CurseForge),
  itinéraire, repère, automatisations.

### Installation
Un seul zip, pour WoW: Forever, dans la dernière version publiée du dépôt GitHub :
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

### Assistant de premier démarrage
Il s'ouvre environ 3 secondes après la connexion (jamais en combat), en cinq pages. Chaque page a
« Précédent », « Ignorer » (garde les réglages actuels de la page) et « Suivant » ; la dernière a
« Terminer ».
1. **Bienvenue et addons** : état de QuestieDB, ShortestPath Forever, WaypointUI et TomTom
   (installé, désactivé, activé mais pas encore chargé, périmé, absent).
   - Addon absent : son lien CurseForge s'affiche dans un champ. Le jeu ne peut pas ouvrir de
     navigateur : clique dans le champ (le lien se sélectionne), Ctrl+C, puis colle-le dans ton
     navigateur.
   - Addon désactivé : bouton « Activer » (pour ce personnage), puis « Recharger l'interface ».
   - Sans QuestieDB, le suivi affiche un bouton « Lien » qui ouvre cette page.
   - Un addon tout juste téléchargé n'apparaît qu'après un redémarrage complet du jeu, pas après
     `/reload`.
2. **Calcul d'itinéraire** : ShortestPath Forever, s'il est chargé.
3. **Affichage** : WaypointUI, TomTom ou le repère du jeu.
4. **Automatisations** : accepter et rendre les quêtes, choisir la récompense, vendre la camelote.
5. **Récapitulatif** : « Terminer » enregistre les choix.

L'assistant reprend où tu l'as laissé : après « Recharger l'interface », `/reload` ou une
reconnexion, il se rouvre sur la même page tant qu'il n'est pas terminé (une fois par session).
Le fermer avec la croix ne le termine pas : `/qf wizard` le rouvre sur la même page.

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
- [ ] L'assistant s'ouvre environ 3 secondes après la première connexion et applique les choix à
      « Terminer ». Les liens CurseForge se sélectionnent d'un clic et Ctrl+C les copie. « Activer »
      puis « Recharger l'interface » rouvrent l'assistant sur la même page, avec l'addon chargé.
      Fermé avec la croix, il ne revient pas dans la session, mais revient à la suivante ; après
      « Terminer », il ne revient plus.
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
- `/qf options` : options ; `/qf wizard` : assistant de démarrage (reprend à la page laissée).
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

Bibliothèques incluses dans `Questify_Vanilla/Libs/`, copiées sans modification :
- HereBeDragons 2.18 (Nevcairiel, licence BSD indiquée dans son TOC) : épingles sur la carte.
- LibStub (domaine public) et CallbackHandler-1.0 (BSD), depuis Ace3 `Release-r1403`.

---

## English

### What it does
- An optimized route per race and faction, step by step: accept, complete and turn in quests,
  flight paths, hearthstone, boats.
- Steps tick themselves off from your quest log; steps your character cannot do are skipped.
- Navigation to every step (native in-game marker, or TomTom, WaypointUI, ShortestPath Forever).
- Monsters to kill under each objective in the tracker (click or auto-targeting key: target +
  skull), class quests, automatic accept and turn-in (can be turned off).
- Suggested dungeons for your level and faction (unreleased): one click adds its quests to pick up
  in town, the entrance and the turn-ins to the route (the alert can be turned off).
- Numbered pins for the current step and the next 5 on the world map and minimap (unreleased, can be turned off).
- Zone mode (unreleased, can be turned off): nearby objectives of several quests grouped into one visit (green marker, then objects, named mobs and monsters by priority).
- A first-launch wizard: installed or missing addons (with their CurseForge link), routing, marker,
  automations.

### Installation
A single zip, for WoW: Forever, in the GitHub repository's latest release:
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

### First-launch wizard
It opens about 3 seconds after login (never in combat) and has five pages. Every page has
"Previous", "Skip" (keeps the page's current settings) and "Next"; the last one has "Finish".
1. **Welcome and addons**: state of QuestieDB, ShortestPath Forever, WaypointUI and TomTom
   (installed, disabled, enabled but not loaded yet, out of date, not installed).
   - Missing addon: its CurseForge link shows in a text field. The game cannot open a browser:
     click the field (the link gets selected), press Ctrl+C, then paste it in your browser.
   - Disabled addon: "Enable" button (for this character), then "Reload UI".
   - Without QuestieDB, the tracker shows a "Link" button that opens this page.
   - A newly downloaded addon only shows up after a full game restart, not after `/reload`.
2. **Route planning**: ShortestPath Forever, when loaded.
3. **Display**: WaypointUI, TomTom or the game's own map pin.
4. **Automations**: accept and turn in quests, choose the reward, sell junk.
5. **Summary**: "Finish" saves your choices.

The wizard resumes where you left it: after "Reload UI", `/reload` or a new login, it reopens on
the same page until it is finished (once per session). Closing it with the X does not finish it:
`/qf wizard` reopens it on the same page.

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
- [ ] The wizard opens about 3 seconds after the first login and applies your choices on Finish.
      CurseForge links get selected with one click and Ctrl+C copies them. "Enable" then
      "Reload UI" reopen the wizard on the same page, with the addon loaded. Closed with the X, it
      does not come back in the same session but does in the next one; after Finish, it never
      comes back.
- [ ] The native marker shows on the current step (and TomTom, WaypointUI or ShortestPath Forever
      when installed); it disappears or changes when the step changes.
- [ ] Steps tick themselves off: quest accept and turn-in, discovered flight path, bound
      hearthstone. The 15-yard radius of `goto` steps is not too tight.
- [ ] `/tm` works solo: clicking a mob under the objective in the tracker targets the nearest one
      and puts a skull on it, once per click, with `ActionButtonUseKeyDown` set to 0 and then 1.
- [ ] "Auto targeting key" option: a key bound in Esc > Key Bindings > Questify Vanilla targets the
      nearest objective mob and puts a skull on it out of combat, and does nothing in combat.
- [ ] Step with an object to use (chest, bucket) and the native marker: golden animation centered on
      the object, which disappears off screen or beyond 50 m ("Animate the object to use" option).
- [ ] Automatic accept and turn-in work on route quests, and Shift pauses them.
- [ ] Automatic reward choice picks an upgrade or, failing that, the item with the highest vendor
      price; it picks nothing while the reward items are not loaded yet.
- [ ] No errors in combat: no "Interface action failed because of an AddOn" message, the tracker can
      grow in combat, the targeting buttons under the objectives move back into place after combat.
- [ ] No errors with secret values in combat, or inside instances (forbidden nameplates).
- [ ] The tracker is well placed at 1080p, with UI scale 1 and 0.8: readable, long texts wrap,
      drag and lock work, the position survives `/reload`, the size buttons work, no overlap with
      Blizzard's tracker.
- [ ] Mobs under the objective: 3D model on hover (question mark when the model is not cached), icon
      bounces on the right nameplates and disappears when the objective is complete.
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
- `/qf options`: options; `/qf wizard`: first-launch wizard (resumes on the page you left).
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

Libraries bundled in `Questify_Vanilla/Libs/`, copied unchanged:
- HereBeDragons 2.18 (Nevcairiel, BSD license stated in its TOC): map pins.
- LibStub (public domain) and CallbackHandler-1.0 (BSD), from Ace3 `Release-r1403`.

---

## Développement / Development

### Publier une version / Publishing a release

1. Mettre la nouvelle version dans `## Version:` des deux TOC (`Questify_Vanilla.toc` et
   `Questify_Vanilla_Camelot.toc`, identiques), au format `X.Y.Z` (ou `X.Y.Z-beta.1`), et ajouter une
   section `## X.Y.Z (date)` dans `CHANGELOG.md`. Fusionner dans `main`.
2. Créer et pousser le tag : `git tag vX.Y.Z && git push origin vX.Y.Z`.
3. Le workflow « Release » vérifie que le tag correspond au TOC, lance les tests, construit le zip, crée la
   release GitHub (notes tirées du CHANGELOG), puis envoie le zip sur CurseForge.

Pour l'envoi sur CurseForge, créer une fois deux secrets dans GitHub (Settings > Secrets and variables >
Actions) : `CF_API_KEY` (jeton créé sur https://authors.curseforge.com/#/settings/api-tokens) et
`CF_PROJECT_ID` (ID numérique du projet, encadré « About Project » de la page CurseForge). Sans eux, seule
la release GitHub est publiée. Variable facultative `CF_GAME_VERSION` (1.60.1 par défaut).

English: bump `## Version:` in both TOC files and add a `## X.Y.Z (date)` section to `CHANGELOG.md`, merge
into `main`, then push a `vX.Y.Z` tag. The "Release" workflow checks the tag against the TOC, runs the tests,
builds the zip, creates the GitHub release and uploads to CurseForge once the `CF_API_KEY` and
`CF_PROJECT_ID` secrets are set (optional variable `CF_GAME_VERSION`, default 1.60.1).

- Tests: `luajit tests/run.lua [pattern]` (WoW API mock in `tests/wow_mock.lua`).
- Syntax check: `tools/check_syntax.sh`.
- Release check and zip: `tools/package.sh` runs the syntax check, the tests and `tools/validate_guides.lua`,
  then writes `dist/Questify_Vanilla-<version>-forever.zip` (version read from `## Version:` in the TOC).
  Changes are listed in `CHANGELOG.md`.

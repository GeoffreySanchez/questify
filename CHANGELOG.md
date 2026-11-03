# Changelog

## Non publié

### Français
- Version de test pour WoW Classic Era (1.15.8, 1.15.9) : fichier `Questify_Vanilla_Vanilla.toc`,
  couche de compatibilité `Core/Compat.lua` (journal de quêtes, objets, fenêtre de quêtes sans
  dialogue reconnue par le titre, repère natif absent sur Era), route Nain / Gnome 1-12
  (`Guides/Era/`, générée par `tools/routebuilder/build_era.lua`). La version Forever est inchangée.
- `/qf check` : autodiagnostic en jeu (fonctions du jeu utilisées, QuestieDB, repère natif et
  marqueur 3D, navigation choisie et réellement utilisée, route du personnage, ciblage, erreurs).
- `/qf report` (et bouton « Rapport de bug » des options) : rapport de bug à copier, avec version,
  client, personnage, étape, cible, réglages, résultat du diagnostic et erreurs Lua.
- Les erreurs Lua sont gardées avec leur pile d'appels (les 20 dernières, nombre de répétitions
  compris) et survivent à `/reload` ; la première erreur d'une session indique `/qf report`.

### English
- Test build for WoW Classic Era (1.15.8, 1.15.9): `Questify_Vanilla_Vanilla.toc`, compatibility
  layer `Core/Compat.lua` (quest log, items, title-based quest greeting, no native waypoint on Era),
  Dwarf / Gnome 1-12 route (`Guides/Era/`, built by `tools/routebuilder/build_era.lua`). The Forever
  build is unchanged.
- `/qf check`: in-game self-check (game functions used, QuestieDB, native pin and 3D marker,
  chosen and actually used navigation, character route, targeting, errors).
- `/qf report` (and a "Bug report" button in the options): a bug report to copy, with version,
  client, character, step, target, settings, self-check results and Lua errors.
- Lua errors are kept with their call stack (the last 20, with repeat counts) and survive
  `/reload`; the first error of a session points to `/qf report`.

## 0.1.0 (2026-11-03)

### Français

Première version de **Questify Vanilla**, guide de leveling gratuit et open source pour
World of Warcraft: Forever (niveaux 1 à 30).

#### Nouveautés
- Une route étape par étape par race et par faction : prendre, faire et rendre les quêtes, points
  de vol, pierre de foyer, bateaux. Les routes s'arrêtent au niveau 30 avec un message clair.
- Suivi automatique : les étapes se cochent d'après le journal de quêtes, les étapes impossibles
  pour le personnage sont sautées. `/qf skip` passe une étape, `/qf back` revient en arrière.
- Navigation vers chaque étape avec le marqueur 3D natif du jeu, ou avec TomTom, WaypointUI et
  ShortestPath Forever s'ils sont installés. Un assistant de premier démarrage propose le choix.
- Suivi des étapes à l'écran (déplaçable, verrouillable, taille réglable).
- Panneau des monstres à tuer : modèle 3D au survol, clic pour cibler le monstre le plus proche et
  lui poser un crâne ; icône sur les barres de nom (nameplates) des monstres de l'objectif.
- Journal (`/questify` ou `/qf`) : chapitres, étapes, récompenses et onglet des quêtes de classe.
- Quêtes de classe : alerte, ajout à la route ou ignorer.
- Acceptation et rendu automatiques des quêtes de la route, et choix automatique de la récompense
  (meilleure amélioration pour la classe, sinon plus haut prix de vente). Chaque automatisation
  est désactivable ; Maj (Shift) enfoncée les suspend.
- Mesure du temps passé par étape, exportable avec `/qf export` (rien n'est envoyé).
- Interface en anglais et en français.
- Les données de quêtes viennent de l'addon QuestieDB, lu en jeu et jamais recopié (dépendance
  obligatoire).

#### Limites connues
- À vérifier en jeu le jour du lancement :
  - `/tm` (marqueur de crâne) en solo ;
  - valeurs secrètes en combat (aucune erreur attendue, mais non testé sur le vrai client) ;
  - reconnaissance du fichier `Questify_Vanilla_Camelot.toc` par le client Forever ;
  - affichage du marqueur natif.
- Pas de routes 30-60, de guides de donjon, de métiers, de réputation ni de raids. Pas de mode
  Hardcore.
- Pas d'épingles sur la carte du monde ni sur la minimap : le marqueur 3D et la navigation
  suffisent pour cette version.
- QuestieDB est incomplet pour les nouvelles quêtes Forever : environ 15 % n'ont pas de PNJ de rendu
  localisé, et leur XP est estimée (elle n'est pas publiée dans les données).
- Les noms de monstres et de quêtes sont ceux de QuestieDB : en français, ils restent en anglais
  quand QuestieDB n'a pas la traduction, et le ciblage par nom (`/targetexact`) en dépend.
- Le suivi se place à gauche du suivi d'objectifs de Blizzard et le suit quand il bouge ; il peut
  chevaucher d'autres éléments d'interface jusqu'à ce que tu le déplaces.
- Le choix automatique de la récompense est une estimation à poids de caractéristiques simples par
  classe, pas un simulateur.

### English

First release of **Questify Vanilla**, a free and open-source leveling guide for World of Warcraft:
Forever (levels 1 to 30).

#### What is new
- A step-by-step route per race and faction: accept, complete and turn in quests, flight paths,
  hearthstone, boats. Routes end at level 30 with a clear message.
- Automatic tracking: steps tick themselves off from your quest log, and steps your character
  cannot do are skipped. `/qf skip` skips a step, `/qf back` goes back.
- Navigation to every step with the game's native 3D waypoint, or with TomTom, WaypointUI and
  ShortestPath Forever when installed. A first-launch wizard offers the choice.
- On-screen step tracker (movable, lockable, adjustable size).
- Mob panel for kill objectives: 3D model on hover, click to target the nearest mob and mark it
  with a skull; an icon on the nameplates of the objective's mobs.
- Journal (`/questify` or `/qf`): chapters, steps, rewards and a class quests tab.
- Class quests: alert, add to the route or ignore.
- Automatic accept and turn-in of route quests, and automatic reward choice (best upgrade for your
  class, otherwise the highest vendor price). Each automation can be turned off; holding Shift
  pauses them.
- Per-step timing data, exportable with `/qf export` (nothing is ever sent).
- English and French interface.
- Quest data comes from the QuestieDB addon, read in game and never copied (required dependency).

#### Known limits
- To check in game on launch day:
  - `/tm` (skull marker) when playing solo;
  - secret values in combat (no error expected, but untested on the real client);
  - the Forever client recognizing `Questify_Vanilla_Camelot.toc`;
  - the native waypoint display.
- No 30-60 routes, dungeon guides, professions, reputation or raids. No Hardcore mode.
- No pins on the world map or the minimap: the 3D waypoint and navigation are enough for this
  version.
- QuestieDB is incomplete for the new Forever quests: about 15% have no localized turn-in NPC, and
  their XP is estimated (it is not published in the data).
- Mob and quest names come from QuestieDB: on a French client they stay in English where QuestieDB
  has no translation, and targeting by name (`/targetexact`) depends on them.
- The tracker sits to the left of Blizzard's objective tracker and follows it when it moves; it can
  overlap other interface elements until you move it.
- Automatic reward choice is an estimate based on simple per-class stat weights, not a simulator.

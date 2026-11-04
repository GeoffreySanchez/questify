# Changelog

## Non publié

### Français
- Vérification de version entre joueurs : Questify envoie sa version par un message d'addon invisible à la
  guilde (une fois, après la connexion) et au groupe (au plus une fois par minute, jamais en combat). Si un
  joueur a une version plus récente, une ligne dans la discussion et un message à l'écran le disent une fois
  par session : la mise à jour se fait via CurseForge. Option « versionCheck », activée par défaut.
- Publication : un tag `vX.Y.Z` crée la release GitHub avec le zip et les notes du CHANGELOG, puis envoie le
  même zip sur CurseForge quand les secrets `CF_API_KEY` et `CF_PROJECT_ID` sont réglés.
- Mode zone : quand plusieurs quêtes ont leurs objectifs au même endroit, un repère vert mène à la zone, puis le suivi et la flèche les enchaînent en une visite (objets, puis élites et nommés, puis monstres ; un coffre attend la clé de son monstre). Option, activée par défaut.
- Vols automatiques : chez le maître de vol, l'étape « Prendre un vol vers X » choisit et prend le
  bon trajet (Maj pour choisir toi-même, jamais en combat).
- Pierre de foyer dans le suivi : « Pierre prête » ou « Pierre dans 12 min », et sinon le trajet à
  pied ou le vol conseillé. Sur « Lier la pierre de foyer », le foyer actuel.
- Alerte de danger : élite ou monstre de 3 niveaux ou plus au-dessus de toi près d'un objectif
  (une ligne dans le suivi, un message par monstre toutes les 5 minutes, jamais en instance).
- Rappel sacs pleins et réparation avant de partir loin d'un marchand (au plus toutes les 10 min).
- XP/h et temps avant le prochain niveau dans le suivi, XP restante estimée du chapitre.
- Options : groupe « Confort » dans le journal pour couper chacune de ces aides.
- Assistant de premier démarrage refait, en cinq pages : bienvenue et addons, calcul d'itinéraire,
  affichage, automatisations (dont la vente de la camelote), récapitulatif.
  - Pour chaque addon absent (QuestieDB, ShortestPath Forever, WaypointUI, TomTom), le lien
    CurseForge s'affiche dans un champ en lecture seule, sélectionné d'un clic pour Ctrl+C.
  - Un addon installé mais désactivé a un bouton « Activer », puis « Recharger l'interface ».
  - « Précédent », « Ignorer » et « Suivant » sur chaque page, « Terminer » sur la dernière.
  - L'assistant reprend à la même page après « Recharger l'interface », `/reload` ou une
    reconnexion. Fermé avec la croix, il n'est plus considéré comme terminé : il revient à la
    session suivante (une fois par session) et `/qf wizard` le rouvre sur la même page.
  - Le choix des métiers vient après l'assistant, qu'il soit terminé ou seulement fermé (une fois
    par session au plus).
- Sans QuestieDB (ou avec une version trop ancienne), Questify se charge quand même : le suivi
  l'explique et son bouton « Lien » ouvre l'assistant sur la page des addons, où le lien
  CurseForge de QuestieDB est prêt à copier.
- Rappels de talents dès le niveau 10 : alerte dans le suivi tant qu'un point reste à dépenser,
  message à chaque niveau avec le talent conseillé par le build choisi, clic : fenêtre des talents.
  Choix du build en cartes animées (monde ouvert ou donjon) au niveau 10 et dans les options.
  Aucune classe de Forever n'a encore de build : seuls les rappels s'affichent. `/qf talents`
  relève les arbres de talents du client pour écrire ces builds.
- Bouton de l'objet de quête de l'étape, à gauche du suivi, avec un raccourci dans les Raccourcis
  du jeu ; il ne change que hors combat. Option, activée par défaut.
- Quand le donneur ne propose pas la quête attendue (quête modifiée), l'étape est passée avec un
  message ; `/qf back` la rouvre.
- Les monstres à tuer s'affichent dans le suivi, sous la ligne d'objectif de l'étape « Faire »
  (crâne, nom, niveau), au lieu du panneau « Cibles » séparé. Un clic cible toujours le plus proche
  et lui pose un crâne.
- Nouvelle option « Touche de ciblage auto » : un raccourci (Échap > Raccourcis > Questify Vanilla)
  cible le monstre d'objectif le plus proche de l'étape courante et le marque d'un crâne, hors
  combat seulement.
- Forever : animation dorée (ondes et étoile qui tourne) autour de l'objet à utiliser quand l'étape
  pointe sur un objet du monde (coffre, seau…), avec le marqueur natif. Option « Animer l'objet à
  utiliser », activée par défaut.
- Alerte « nouveaux sorts » dans le suivi selon le niveau, les sorts déjà appris (liste relevée
  chez le maître de classe) et l'or disponible (seuls les sorts payables comptent) ; clic : étape
  vers le maître de classe le plus proche.
- Annonce « Équipez <objet> pour gagner en puissance » au milieu de l'écran quand un objet reçu
  améliore l'équipement (clic : équiper).
- Vente automatique de la camelote chez les marchands (option, Maj pour suspendre).
- Choix des métiers à l'accueil ; la route passe chez le maître du métier quand il est proche.
- Dans la zone d'objectif, la flèche (marqueur, TomTom, WaypointUI) suit le monstre le plus proche.
- Largeur du suivi réglable avec une poignée en bas à droite.
- Routes : pierre de foyer liée au premier passage à l'auberge et utilisée ; objectifs faits à un
  niveau sûr (quête au plus +1, monstres au plus +1).
- `/qf check` : autodiagnostic en jeu (fonctions du jeu utilisées, QuestieDB, repère natif et
  marqueur 3D, navigation choisie et réellement utilisée, route du personnage, ciblage, erreurs).
- `/qf bug` (alias `/qf report`, et bouton « Rapport de bug » des options) : rapport de bug à copier,
  avec version, client, personnage, addons, route (étape courante et suivantes, cible), position,
  navigation, journal de quêtes, réglages, résultat du diagnostic et erreurs Lua.
- Les erreurs Lua sont gardées avec leur pile d'appels (les 20 dernières, nombre de répétitions
  compris), y compris celles du chargement, et survivent à `/reload` ; la première erreur d'une
  session indique `/qf bug`.
- Classic Era n'est plus pris en charge : l'addon vise WoW: Forever seul, avec un seul zip
  (`Questify_Vanilla-<version>-forever.zip`).
- Donjons selon le niveau et la faction : alerte « Donjon conseillé : X (niv a-b) » dans le suivi ;
  « Ajouter à la route » insère ses quêtes à prendre en ville (la plus proche d'abord, ville par
  ville), l'entrée du donjon, puis les rendus. Jamais le Gouffre de Ragefeu pour l'Alliance. Section
  « Donjons » dans l'onglet Quêtes de classe du journal, option pour couper l'alerte.
- Carte du monde et minicarte : repères numérotés de l'étape courante et des 5 suivantes (option).

### English
- Version check between players: Questify sends its version in a hidden addon message to your guild (once,
  after login) and to your group (at most once a minute, never in combat). If a player has a newer version,
  a chat line and an on-screen message tell you once per session: update via CurseForge. Option
  "versionCheck", on by default.
- Publishing: a `vX.Y.Z` tag creates the GitHub release with the zip and the CHANGELOG notes, then uploads
  the same zip to CurseForge when the `CF_API_KEY` and `CF_PROJECT_ID` secrets are set.
- Zone mode: when several quests have objectives in the same place, a green marker leads to the zone, then the tracker and the arrow chain them in one visit (objects, then elites and named mobs, then monsters; a chest waits for the key its mob drops). Option, on by default.
- Automatic flights: at the flight master, a "Take a flight to X" step picks and takes the right
  route (hold Shift to choose yourself, never in combat).
- Hearthstone in the tracker: "ready" or "ready in 12 min", otherwise the suggested walk or flight.
  On "Bind your hearthstone", the current home.
- Danger alert: elite or mob 3+ levels above you near an objective (one tracker line, one chat
  message per mob every 5 minutes, never in instances).
- Bags-full and repair reminder before you leave a merchant area for far away (at most every 10 min).
- XP/h and time to next level in the tracker, estimated XP left in the chapter.
- Options: a "Comfort" group in the journal to turn each of these off.
- First-launch wizard redone, in five pages: welcome and addons, route planning, display,
  automations (including junk selling), summary.
  - For each missing addon (QuestieDB, ShortestPath Forever, WaypointUI, TomTom), its CurseForge
    link shows in a read-only field, selected with one click for Ctrl+C.
  - An installed but disabled addon has an "Enable" button, then "Reload UI".
  - "Previous", "Skip" and "Next" on every page, "Finish" on the last one.
  - The wizard resumes on the same page after "Reload UI", `/reload` or a new login. Closing it
    with the X no longer counts as finished: it comes back in the next session (once per session)
    and `/qf wizard` reopens it on the same page.
  - The profession choice comes after the wizard, whether it was finished or only closed (at most
    once per session).
- Without QuestieDB (or with a version that is too old), Questify still loads: the tracker says so
  and its "Link" button opens the wizard on the addons page, where the QuestieDB CurseForge link is
  ready to copy.
- Talent reminders from level 10: a tracker alert while a point is left to spend, a message at each
  level with the talent advised by the chosen build, click: talent window. Build choice on animated
  cards (open world or dungeon) at level 10 and in the options. No Forever class has a build yet:
  only the reminders show. `/qf talents` records the client's talent trees to write those builds.
- Button for the current step's quest item, left of the tracker, with a key in the game's Key
  Bindings; it only changes out of combat. Option, on by default.
- When the quest giver does not offer the expected quest (changed quest), the step is skipped with
  a message; `/qf back` reopens it.
- Monsters to kill are shown in the tracker, under the objective line of the current "Complete"
  step (skull, name, level), instead of the separate "Targets" panel. Clicking still targets the
  nearest one and marks it with a skull.
- New "Auto targeting key" option: a key binding (Esc > Key Bindings > Questify Vanilla) targets
  the nearest objective monster of the current step and marks it with a skull, out of combat only.
- Forever: golden animation (waves and a spinning star) around the object to use when the step
  points at a world object (chest, bucket…), with the built-in marker. "Animate the object to use"
  option, on by default.
- "New spells" alert in the tracker from your level, known spells (list read at the class
  trainer) and gold (only spells you can pay for count); click: step to the nearest class trainer.
- "Equip <item> to gain power" announcement in the middle of the screen when a received item is an
  upgrade (click: equip).
- Automatic junk selling at merchants (option, Shift to pause).
- Profession choice on first login; the route stops at the trainer when one is nearby.
- Inside an objective area, the arrow (marker, TomTom, WaypointUI) follows the nearest monster.
- Tracker width adjustable with a grip in the bottom-right corner.
- Routes: hearthstone bound on the first visit to the inn and actually used; objectives done at a
  safe level (quest at most +1, monsters at most +1).
- `/qf check`: in-game self-check (game functions used, QuestieDB, native pin and 3D marker,
  chosen and actually used navigation, character route, targeting, errors).
- `/qf bug` (alias `/qf report`, and a "Bug report" button in the options): a bug report to copy,
  with version, client, character, addons, route (current and next steps, target), position,
  navigation, quest log, settings, self-check results and Lua errors.
- Lua errors are kept with their call stack (the last 20, with repeat counts), including those
  raised while loading, and survive `/reload`; the first error of a session points to `/qf bug`.
- Classic Era is no longer supported: the addon targets WoW: Forever only, with a single zip
  (`Questify_Vanilla-<version>-forever.zip`).
- Dungeons by level and faction: "Suggested dungeon: X (lvl a-b)" alert in the tracker; "Add to
  route" inserts its quests to pick up in town (nearest first, city by city), the dungeon entrance,
  then the turn-ins. Never Ragefire Chasm for the Alliance. "Dungeons" section in the journal's
  Class quests tab, and an option to turn the alert off.
- World map and minimap: numbered pins for the current step and the next 5 (option, on by default).

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

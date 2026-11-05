# Changelog

## Non publié

### Français
- Itinéraire ShortestPath avec WaypointUI : le repère ne part plus dans le coin nord-ouest de la
  carte (« Trajet vers … 2129 yds » pour un PNJ à 65 yards). ShortestPath confie ses virages à
  WaypointUI en coordonnées 0-1, que WaypointUI lit en 0-100 ; Questify convertit ces coordonnées au
  passage, quand les deux addons sont chargés. Les trajets lancés soi-même avec ShortestPath en
  profitent aussi.
- Itinéraire ShortestPath avec WaypointUI : plus de « ding » à chaque virage (les virages passent en
  silence), un virage identique n'est pas reposé, et le repère ne saute plus sur la cible puis sur le
  virage à chaque nouvelle cible (toutes les 3 s pendant un objectif).
- Talents : les builds fournis ne sont plus tous marqués « obsolète » en jeu. Dans Forever, un talent
  appartient à la fois à son arbre (Élémentaire, Amélioration, Restauration…) et à des groupes de
  palier, dans un ordre quelconque ; Questify prenait le premier groupe pour l'arbre et ne lisait que
  7 talents sur 50 (relevé du chaman). Il prend maintenant celui qui est un arbre.
- `/qf talents` : le relevé se fait aussi sans l'API des points restants, et enregistre l'arbre tel que
  Questify le lit et la validation de chaque build de la classe (raison, point et talent en cause).
- Journal : un chapitre fini (par exemple après un clic droit de trop sur sa dernière étape, qui fait
  passer au chapitre suivant) peut être rechoisi dans l'onglet Route et reste affiché ; on y rouvre
  l'étape passée avec `/qf back` ou en cliquant dessus. Avant, le journal renvoyait aussitôt au chapitre
  suivant et il n'y avait aucun moyen de revenir.

### English
- ShortestPath routing with WaypointUI: the waypoint no longer lands in the north-west corner of the
  map ("Journey to … 2129 yds" for an NPC 65 yards away). ShortestPath hands its turns to WaypointUI in
  0-1 coordinates, which WaypointUI reads as 0-100; Questify converts them on the way, when both addons
  are loaded. Journeys you start yourself with ShortestPath benefit too.
- ShortestPath routing with WaypointUI: no more "ding" on every turn (turns are silent), an identical
  turn is not placed again, and the waypoint no longer jumps to the target and back to the turn on
  every new target (every 3 s during an objective).
- Talents: the shipped builds are no longer all marked "obsolete" in game. In Forever, a talent belongs
  both to its tree (Elemental, Enhancement, Restoration…) and to tier groups, in any order; Questify
  took the first group as the tree and read only 7 talents out of 50 (shaman dump). It now takes the
  one that is a tree.
- `/qf talents`: the dump also works without the unspent-points API, and records the tree as Questify
  reads it and the validation of each build of the class (reason, point and talent at fault).
- Journal: a finished chapter (for example after one right-click too many on its last step, which moves
  on to the next chapter) can be chosen again in the Route tab and stays shown; reopen the skipped step
  with `/qf back` or by clicking it. Before, the journal sent you straight back to the next chapter and
  there was no way back.

## 0.3.0 (2026-11-05)

### Français
- Grottes : avant une quête dont l'objectif est dans une grotte, le repère pointe d'abord l'ENTRÉE de la
  grotte (« Entrée de la grotte — <étape> »), quel que soit l'affichage (repère du jeu, WaypointUI,
  TomTom, ShortestPath). Une fois l'entrée passée, la flèche va droit vers l'objectif ; en sortant, le
  repère repasse par l'entrée. Un joueur sur la montagne au-dessus de la grotte n'a plus la flèche directe.
  5 grottes du parcours : The Grizzled Den, Echo Ridge Mine, Dustwind Cave, Skull Rock, Night Web's
  Hollow. Les entrées viennent de sources publiques et sont à confirmer en jeu ; l'intérieur de chaque
  grotte est calculé à partir de QuestieDB.
- Repère WaypointUI : il affiche le titre de l'étape ; sur les virages d'un itinéraire ShortestPath, le
  nom de l'étape reste visible.
- Équipement :
  - plus de bouclier ni de main gauche proposés comme amélioration avec une arme à deux mains portée,
    sauf si la paire fait mieux ;
  - avec un bâton porté et une masse à une main dans le sac, un bouclier ramassé propose « Équipez
    <masse> et <bouclier> » quand la paire bat le bâton, et le clic équipe les deux (main droite d'abord) ;
  - le choix de la récompense de quête compte aussi la meilleure arme des sacs pour une paire.
- Vente automatique : le gris, et l'équipement BLANC qui ne sert pas. Jamais vendus : le vert et mieux,
  les objets blancs non équipables (composants, plantes, tissu, nourriture…), les outils, un objet
  que Questify vient de recommander (10 min), la meilleure arme de main droite et la meilleure main
  gauche quand une arme à deux mains est portée, un objet qui remplirait un emplacement vide.
- Métiers :
  - l'étape « apprendre le métier » n'apparaît que près d'un maître ET avec l'argent nécessaire (coût
    relevé chez le maître, sinon 10 pc pour Apprenti) ;
  - passer chez le maître sans payer ne compte plus comme appris : l'étape revient au passage suivant
    en ville avec l'argent ;
  - l'étape reste tant qu'on ne s'éloigne pas à plus de 800 yards du maître (ou qu'on ne change pas de
    zone) : elle ne clignote plus autour de la ville ; aucune étape ne s'ajoute dans une grotte ;
  - quand la compétence et le niveau le permettent, une étape propose le rang suivant (Compagnon, puis
    Expert pour les métiers principaux).

### English
- Caves: before a quest whose objective is inside a cave, the waypoint first points at the cave ENTRANCE
  ("Cave entrance — <step>"), whatever the display (game waypoint, WaypointUI, TomTom, ShortestPath).
  Once past the entrance, the arrow goes straight to the objective; on the way out, it goes back through
  the entrance. A player on the mountain above the cave no longer gets the direct arrow. 5 caves on the
  route: The Grizzled Den, Echo Ridge Mine, Dustwind Cave, Skull Rock, Night Web's Hollow. Entrances come
  from public sources and still need an in-game check; the inside of each cave is computed from QuestieDB.
- WaypointUI waypoint shows the step title; ShortestPath route turns keep the step name.
- Gear:
  - no more shield or off-hand offered as an upgrade while a two-hander is worn, unless the pair is better;
  - with a staff worn and a one-handed mace in the bags, a looted shield offers "Equip <mace> and
    <shield>" when the pair beats the staff, and the click equips both (main hand first);
  - quest reward choice also counts the best weapon in the bags for a pair.
- Auto-sell: grey items, and WHITE gear you don't need. Never sold: green and better, non-equippable white
  items (trade goods, herbs, cloth, food…), tools, an item Questify has just recommended (10 min), the best
  main hand and off-hand while a two-hander is worn, an item that would fill an empty slot.
- Professions:
  - the "learn the profession" step shows only near a trainer AND with the money needed (cost read at the
    trainer, otherwise 10c for Apprentice);
  - visiting the trainer without paying no longer counts as learned: the step comes back on your next
    visit to town with the money;
  - the step stays until you are more than 800 yards from the trainer (or change zone): it no longer
    flickers around town; no step is added while you are in a cave;
  - when skill and level allow it, a step offers the next rank (Journeyman, then Expert for primary
    professions).

## 0.2.0 (2026-11-04)

### Français
- Builds de talents niveau par niveau : 45 builds pour les 9 classes (Icy Veins, Wowhead, théorie de Questify), « <Spé> — Leveling / Donjon / PvP / Raid ». Un build actif par spécialisation, suivi automatiquement.
  - Fenêtre au centre de l'écran quand un point de talent est disponible : « Apprendre » achète les points dus en une validation ; jamais en combat, une seule fois par point. « Talent appris » s'affiche à la fin de l'incantation ; avec des points déjà posés en attente, elle demande « Valide d'abord tes points en attente (bouton Appliquer) ».
  - Build obsolète ou arbre qui ne suit plus le build : la fenêtre dit seulement « Tu as un point de talent à dépenser », sans bouton, et se ferme d'un clic ou après 10 secondes.
  - Un clic sur la ligne talents du suivi rouvre cette fenêtre.
  - Tant que le jeu n'a pas encore ouvert la fenêtre des talents, « Ouvrir les talents » ne la charge pas et dit « Ouvre tes talents avec N » (ta touche des talents).
  - Les builds fournis incomplets (moins de 51 points) finissent par « · partiel » et ne sont plus choisis d'office.
  - Dans la fenêtre des talents du jeu : onglets « Build » et « Sorts à apprendre », halo doré sur le prochain talent (et ligne dans son infobulle), bandeau « Build suivi » avec « Créer un build à partir de mon arbre » quand l'arbre s'écarte. Rien en inspection ni sur la spécialisation inactive.
  - Éditeur : trois arbres et ordre niveau par niveau ; Enregistrer, Dupliquer, Utiliser ; builds obsolètes grisés, copie qui garde la partie valide ; import/export `QFYB1:`, export de tous les builds, import d'un lien du calculateur Icy Veins ; menu à roue dentée avec l'option de la fenêtre (retirée des options).
  - Onglet « Sorts à apprendre » : sorts par niveau, état, coût chez le maître, filtres, « Route vers le maître le plus proche », « Suivre la quête » / « Récupérer la quête » pour les sorts liés à une quête (totems du chaman).
  - `/qf build` et l'entrée « Build du personnage » du menu de la minicarte ouvrent la fenêtre seule ; `/qf bug` indique pourquoi l'apprentissage en un clic est indisponible.
  - L'ancien sélecteur de préréglages est retiré.
- Quêtes de classe : une suite à plusieurs donneurs ou à plusieurs branches ne propose plus que celle
  du maître le plus proche. Exemple : un Guerrier nain de niveau 10 se voit proposer « Muren Stormpike »
  (Granis Swiftaxe, Kharanos), et non plus la suite de Hurlevent ou de Darnassus. La fenêtre de la
  quête nomme le donneur le plus proche, et une suite déjà prise, ajoutée ou ignorée garde la main.
- Quêtes de classe : chaque branche a ses propres quêtes, récompenses et XP. Les branches du Guerrier 10
  (Hurlevent, Forgefer, Darnassus et, côté Horde, Orc/Troll/Tauren et Mort-vivant) étaient fondues en
  une seule suite, et « Ajouter à la route » y insérait les étapes des autres branches.
- Nouvelle fenêtre d'options (`/qf options`, « Options… » du bouton de la minicarte et du journal, ou Échap > Options > AddOns > Questify).
  - Les sections sont à gauche : Route, Navigation, Automatisation, Butin, Classe et donjons, Carte et repères, Suivi, Thème, Confort, Outils, Profils.
  - Dans chaque section, des catégories, et une icône « i » sur chaque option qui explique ce qu'elle fait.
  - Une recherche sans accents ni majuscules (« butin », « thème »…) trouve les options de toutes les sections. `/qf options <mot>` l'ouvre directement sur une recherche.
  - L'onglet Options du journal est remplacé par un bouton « Options… ».
- Section Thème : aperçu de chaque thème du suivi, et curseur d'opacité du fond de 0 à 100 %.
- Profils d'options, par compte (profil partagé « Par défaut ») ou par personnage.
  - Un profil garde toutes les options et la position, la taille, la largeur et le thème du suivi.
  - Boutons Nouveau, Copier depuis…, Supprimer…, Réinitialiser.
  - Exporter et Importer une chaîne de texte (`QFY1:…`), contrôlée valeur par valeur.
  - Changer de profil applique tout de suite.
  - Les options existantes deviennent le profil « Par défaut » ; la progression des personnages ne change pas.
- Le profil de butin reste propre à chaque personnage, hors profils d'options : jamais partagé, exporté ni importé, et changer de profil n'y touche pas.
- Nouvelle option « Proposer le profil de butin de la spécialisation quand j'en choisis une » (activée par défaut).
- Le rapport de bug indique le profil d'options actif.
- Thèmes du suivi : Parchemin (par défaut), Noir, Transparent, Fondu de gris, et transparence du fond
  réglable (le texte reste opaque) ; `/qf theme <nom>` et `/qf opacity <0-100>`.
- Bouton de la minicarte (option « Bouton de la minicarte », activée par défaut) : son icône montre le
  profil de butin de quête. Clic gauche : choix rapides (profil de butin de la classe, accepter / rendre
  automatiquement, choisir la récompense, mode zone, épingles sur la carte, puis Options…, Journal,
  Assistant de démarrage, Signaler un bug). Clic droit : journal ; Ctrl+clic : assistant ; se déplace en
  le glissant autour de la minicarte (position gardée).
- Spécialisation : à partir du niveau 10, quand tu choisis une spécialisation dont le profil de butin
  diffère du tien, une fenêtre propose de l'utiliser (« Oui » ou « Non, garder X » ; « Non » n'est plus
  redemandé pour cette spécialisation). Jamais en combat. `/qf bug` indique la spécialisation détectée.
- Choix de la récompense par rôle (Élémentaire, Amélioration, Restauration, tank, distance…),
  par personnage, dans les options et l'assistant ; « Automatique » garde le comportement de classe.
- Maître de classe : lecture des sorts dans l'ordre de Forever (niveau requis, rang) ; l'alerte
  revient à chaque niveau après la première visite ; les filtres de la fenêtre ne sont plus touchés
  (fini la fenêtre qui se redessinait sans arrêt).
- Une étape « Faire » avec un objectif précis est validée dès que la quête est complète, même si
  l'objectif indiqué par le guide est faux.
- Clic gauche sur une étape bateau, vol, pierre de foyer, point de vol ou lien du foyer : marquée
  faite (les quais sont des positions estimées).
- Clic sur un repère de la carte : la flèche y reste jusqu'à l'étape suivante (la minuterie et le
  mode zone ne la reprennent plus au bout de 3 s).
- Métiers : évènement LEARNED_SPELL_IN_SKILL_LINE (LEARNED_SPELL_IN_TAB n'existe plus en 12.x).
- Annonce « Équipez X » : jamais en combat ; elle attend la fin du combat, et un clic en combat ne
  la ferme plus.
- Talents : /qf talents relève les vrais arbres de Forever (C_ClassTalents / C_Traits : nœuds,
  positions, rangs, sorts, monnaie) dans talentDump.forever[<classe>] ; le rappel des points à
  dépenser lit la monnaie de l'arbre ; sans API, message clair et rappel muet.
- Alerte danger : message dans la discussion pour les élites et les rares seulement (une fois par
  monstre toutes les 5 minutes) ; un monstre plus haut en niveau n'a que la ligne du suivi.
- Distances : une carte sans position monde n'est plus réinterrogée à chaque calcul (nouvel essai
  après 30 s).
- StepGuard : une quête grise (cachée sans le suivi des quêtes de bas niveau) ou dont les prérequis
  ne sont pas faits n'est plus passée ; une ligne d'aide l'explique.
- Avis de nouvelle version : « mets à jour (CurseForge ou GitHub) ».
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
- Nouvelle option « Touche de ciblage auto » : un raccourci (Échap > Raccourcis > Questify)
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
  (`Questify-<version>-forever.zip`).
- Donjons selon le niveau et la faction : alerte « Donjon conseillé : X (niv a-b) » dans le suivi ;
  « Ajouter à la route » insère ses quêtes à prendre en ville (la plus proche d'abord, ville par
  ville), l'entrée du donjon, puis les rendus. Jamais le Gouffre de Ragefeu pour l'Alliance. Section
  « Donjons » dans l'onglet Quêtes de classe du journal, option pour couper l'alerte.
- Carte du monde et minicarte : repères numérotés de l'étape courante et des 5 suivantes (option).

### English
- Level-by-level talent builds: 45 builds for the 9 classes (Icy Veins, Wowhead, Questify theorycraft), "<Spec> — Leveling / Dungeon / PvP / Raid". One active build per specialization, followed automatically.
  - Popup in the middle of the screen when a talent point is available: "Learn" buys the due points with one confirmation; never in combat, once per point. "Talent learned" shows when the apply cast ends; with points already pending, it asks "Apply your pending points first (Apply button)".
  - Obsolete build, or a tree that no longer follows the build: the popup only says "You have a talent point to spend", with no button, and closes on a click or after 10 seconds.
  - Clicking the talent line of the tracker reopens this popup.
  - Until the game has opened the talent window once, "Open talents" does not load it and says "Open your talents with N" (your talent key).
  - Provided builds that are incomplete (under 51 points) end with "· partial" and are no longer picked by default.
  - In the game's talent window: "Build" and "Spells to learn" tabs, a gold halo on the next talent (and a line in its tooltip), a "Followed build" band offering "Create a build from my tree" when the tree drifts. Nothing while inspecting or on the inactive specialization.
  - Editor: three trees and level-by-level order; Save, Duplicate, Use; obsolete builds greyed out, a copy keeps the valid part; `QFYB1:` import/export, export of all builds, import of an Icy Veins calculator link; gear menu with the popup toggle (removed from the options).
  - "Spells to learn" tab: spells by level, state, trainer cost, filters, "Route to the nearest trainer", "Track the quest" / "Pick up the quest" for quest-gated spells (Shaman totems).
  - `/qf build` and the minimap menu entry "Character build" open the window on its own; `/qf bug` reports why one-click learning is unavailable.
  - The old preset picker is removed.
- Class quests: a chain offered by several trainers, or split into branches, now only shows the one
  whose quest giver is nearest. A level 10 Dwarf Warrior gets "Muren Stormpike" (Granis Swiftaxe,
  Kharanos) instead of the Stormwind or Darnassus chain. The quest window names the nearest giver, and
  a chain already taken, added or ignored keeps priority.
- Class quests: each branch now has its own quests, rewards and XP. The level 10 Warrior branches
  (Stormwind, Ironforge, Darnassus, and on the Horde side Orc/Troll/Tauren and Undead) were merged into
  one chain, and "Add to route" inserted the steps of the other branches.
- New options window (`/qf options`, "Options…" in the minimap button menu and the journal, or Esc > Options > AddOns > Questify).
  - Sections on the left: Route, Navigation, Automation, Loot, Class and dungeons, Map and markers, Tracker, Theme, Comfort, Tools, Profiles.
  - Each section has categories, and each option has an "i" icon that explains what it does.
  - A search that ignores accents and case ("loot", "theme"…) finds options in every section. `/qf options <word>` opens the window on a search.
  - The journal's Options tab is replaced by an "Options…" button.
- Theme section: a preview of each tracker theme, and a background opacity slider from 0 to 100 %.
- Option profiles, per account (shared "Default" profile) or per character.
  - A profile holds every option and the tracker position, size, width and theme.
  - New, Copy from…, Delete… and Reset buttons.
  - Export and Import as a text string (`QFY1:…`), checked value by value.
  - Switching profiles applies everything at once.
  - Existing options become the "Default" profile; character progress is unchanged.
- The loot profile stays specific to each character, outside option profiles: never shared, exported or imported, and switching profiles leaves it alone.
- New option "Offer the matching loot profile when I pick a specialization" (on by default).
- The bug report names the active option profile.
- Tracker themes: Parchment (default), Black, Transparent, Grey fade, with adjustable background
  opacity (text stays opaque); `/qf theme <name>` and `/qf opacity <0-100>`.
- Minimap button ("Minimap button" option, on by default): its icon shows the quest loot profile.
  Left-click: quick choices (the class's loot profiles, auto accept / turn in, choose the reward, zone
  mode, map pins, then Options…, Journal, Setup wizard, Report a bug). Right-click: journal;
  Ctrl+click: wizard; drag it around the minimap to move it (position kept).
- Specialization: from level 10, when you pick a specialization whose loot profile differs from yours,
  a window offers to use it ("Yes" or "No, keep X"; "No" is not asked again for that
  specialization). Never in combat. `/qf bug` shows the detected specialization.
- Reward choice by role (Elemental, Enhancement, Restoration, tank, ranged…), per character, in the
  options and the wizard; "Automatic" keeps the class behaviour.
- Class trainer: reads spells in Forever's order; the alert comes back at every level; the trainer
  filters are no longer touched (no more endless redraw).
- A "Do" step with a specific objective is done as soon as the quest is complete.
- Left-click marks boat, flight, hearthstone, flight-path and bind steps done.
- Map pin click: the arrow stays on it until the next step.
- Professions: LEARNED_SPELL_IN_SKILL_LINE event (LEARNED_SPELL_IN_TAB no longer exists).
- "Equip X" popup: never in combat, it waits for combat to end.
- Talents: /qf talents dumps the real Forever trees (C_ClassTalents / C_Traits); the unspent-points
  reminder reads the tree currency.
- Danger alert: chat message for elites and rares only.
- Distances: a map without a world position is retried after 30 s instead of on every computation.
- StepGuard: a gray quest or one with missing prerequisites is no longer skipped; a hint explains why.
- New-version notice: "update it (CurseForge or GitHub)".
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
- New "Auto targeting key" option: a key binding (Esc > Key Bindings > Questify) targets
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
  (`Questify-<version>-forever.zip`).
- Dungeons by level and faction: "Suggested dungeon: X (lvl a-b)" alert in the tracker; "Add to
  route" inserts its quests to pick up in town (nearest first, city by city), the dungeon entrance,
  then the turn-ins. Never Ragefire Chasm for the Alliance. "Dungeons" section in the journal's
  Class quests tab, and an option to turn the alert off.
- World map and minimap: numbered pins for the current step and the next 5 (option, on by default).

## 0.1.0 (2026-11-03)

### Français

Première version de **Questify**, guide de leveling gratuit et open source pour
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
  - reconnaissance du fichier `Questify_Camelot.toc` par le client Forever ;
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

First release of **Questify**, a free and open-source leveling guide for World of Warcraft:
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
  - the Forever client recognizing `Questify_Camelot.toc`;
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

# Questify — guide de leveling gratuit pour WoW Forever

Document de conception, 2026-11-03.

Nom de l'addon : **Questify**, dossier `Questify/`, espace de noms et globale
`Questify`. Dans la suite du document, « Questify » désigne cet addon.

Version **indépendante** : elle ne reprend rien du projet `~/dev/quick_path`
(QuickPath), qui ne doit pas être modifié.

## 1. Intention

Questify est un addon World of Warcraft **gratuit et open source** qui guide le joueur pas à pas
de 1 à 60 sur **World of Warcraft: Forever**, comme RestedXP mais sans payer 30 $. Il sera publié
sur CurseForge pour toute la communauté.

Le joueur veut monter le plus vite possible et sans friction :
- regrouper les quêtes par avant-poste (prendre X/Y/Z, faire les objectifs dans la même zone,
  revenir rendre et reprendre les suites) ;
- ne pas faire d'allers-retours inutiles ni traverser la carte pour quelques % d'XP ;
- profiter des suites de quêtes et des quêtes « de transport » qui rapportent peu d'XP mais ouvrent
  un point de vol ou une nouvelle zone (exemple : la lettre à porter à Orgrimmar) ;
- ramasser les quêtes de donjon dès qu'on passe devant le PNJ ;
- s'adapter au personnage : faction, race, classe, niveau, quêtes déjà rendues ou en cours.

Premier test réel : **au lancement de Forever, le 2026-11-04 à 23:00 UTC** (minuit à Paris), sur le
personnage nain Alliance de l'utilisateur. Le livrable doit donc être installable le **4 novembre
au soir**.

## 2. Objectifs, non-objectifs, anti-objectifs

### Objectifs v1 (pour le lancement)
1. Routes **1-30** pour toutes les races, dans cet ordre de priorité :
   1. Alliance : Nain/Gnome d'abord, puis Humain, Elfe de la nuit ;
   2. Horde : Orc/Troll, Tauren, Mort-vivant ;
   3. Skyborne (Alliance et Horde, île de Zephras), en dernier.
2. Suivi automatique de la progression : étapes cochées toutes seules, étapes impossibles sautées.
3. Navigation vers chaque étape (PNJ, zone de mobs, objet à utiliser).
4. Panneau des mobs à tuer, avec modèle 3D au survol et ciblage + crâne au clic.
5. Quêtes de classe : alerte, ajout à la route ou ignorer, onglet dédié dans le journal.
6. Acceptation et rendu automatiques des quêtes de la route, avec choix de récompense automatique
   (deux options désactivables).
7. Assistant de premier démarrage pour choisir la navigation.
8. Packaging prêt pour CurseForge (dépendances déclarées) et zip installable à la main.

### Non-objectifs v1
- Routes 30-60 : elles viendront ensuite. Au-delà du 30, la route s'arrête avec un message clair.
- Guides de donjon (déroulé des boss), métiers, réputation, raids.
- Hardcore (mode qui arrive plus tard sur Forever).

### Anti-objectifs (échec même si « ça marche »)
- Recopier du contenu protégé : textes ou séquences d'étapes de RestedXP, Joana, Sage, Wowhead,
  Guidelime. Ils ne servent qu'à vérifier des faits.
- Embarquer le code d'un autre addon sans licence compatible (TomTom est « All Rights Reserved »).
- Une route qui fait traverser la carte pour un gain minime, ou qui bloque le joueur sur une étape
  impossible sans moyen de la passer.
- Une erreur Lua au lancement qui casse l'interface : chaque module doit échouer proprement.
- Toute monétisation.

## 3. Contraintes techniques (faits vérifiés)

### Client Forever
- Patch 1.60.1, version de jeu à part dans Battle.net, dossier `World of Warcraft\_forever_`.
- TOC : `## Interface: 16001`. Suffixe de fichier **`_Camelot.toc`** (le seul reconnu par le packager
  BigWigs ; Questie, Guidelime et WaypointUI l'utilisent).
- **API moderne (famille Mainline 12.1.5, « Midnight »)**, pas l'API Classic Era :
  - `C_QuestLog` complet : `IsQuestFlaggedCompleted`, `GetAllCompletedQuestIDs`,
    `GetNumQuestLogEntries`, `GetInfo(i).questID`, `GetQuestObjectives`, `IsComplete`,
    `GetLogIndexForQuestID`, `GetTitleForQuestID`. `GetQuestsCompleted` et `GetQuestLogTitle`
    n'existent pas.
  - Évènements : `QUEST_ACCEPTED(questID)` (un seul argument), `QUEST_TURNED_IN(questID, xp, money)`,
    `QUEST_REMOVED(questID)`, `QUEST_LOG_UPDATE`, `QUEST_DETAIL`, `QUEST_PROGRESS`,
    `QUEST_COMPLETE`, `QUEST_GREETING`, `GOSSIP_SHOW`.
  - Gossip : `C_GossipInfo.GetAvailableQuests/GetActiveQuests/SelectAvailableQuest/SelectActiveQuest`.
  - Quêtes : `AcceptQuest`, `CompleteQuest`, `GetQuestReward(i)`, `GetNumQuestChoices`,
    `IsQuestCompletable`. Objets : `C_Item.GetItemInfo`, `C_Item.GetItemStats`.
  - Position : `C_Map.GetBestMapForUnit("player")`, `C_Map.GetPlayerMapPosition` (0-1, nil en
    instance), `C_Map.GetWorldPosFromMapPos`.
  - Marqueur 3D natif : `C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))` puis
    `C_SuperTrack.SetSuperTrackedUserWaypoint(true)`. Vérifier `C_Map.CanSetUserWaypointOnMap`.
  - Compétences : `C_SkillInfo` remplace l'API globale des compétences.
- **Restrictions Midnight (« secret values »)** :
  - `UnitGUID`, `UnitName`, `UnitCreatureID` peuvent renvoyer une valeur secrète pour un PNJ en
    combat. Toujours tester `issecretvalue(v)` (si la fonction existe) avant d'utiliser la valeur.
  - `SetRaidTarget` est protégée depuis 12.0 : poser le crâne via `/tm` dans une macro sécurisée.
  - `TargetUnit` est protégée : cibler uniquement via un `SecureActionButtonTemplate`
    (`type = "macro"`, `macrotext = "/cleartarget\n/targetexact <Nom>\n/tm !8"`), attributs
    modifiés **hors combat** seulement (`InCombatLockdown()`).
  - Infobulles : utiliser `C_TooltipInfo` / `TooltipDataProcessor`, jamais lire les FontStrings.
- Détection de Forever : interface entre 16000 et 16999 (`select(4, GetBuildInfo())`).
  `WOW_PROJECT_ID` vaut 1 comme Retail, il ne sert pas.
- Les GUID de créatures sont brouillés mais le npcID reste le champ 6.
- Coordonnées : quatre cartes ont changé de cadre par rapport à Era (Mulgore 1412, Maleterres de
  l'Est 1423, Carmines 1433, Hurlevent 1453). Les données QuestieDB Forever sont déjà converties.

### Données : QuestieDB
- Addon séparé, publié sur CurseForge, **API publique pour les addons tiers** : globals `LibQuestieDB`,
  `QuestDB`, `NpcDB`, `ObjectDB`, `ItemDB` (`QuestDB.Get(id, "name")`, `NpcDB.spawns(id)`…).
  Doc : `docs/api.md` du dépôt github.com/Questie/QuestieDB. Contrat 4
  (`LibQuestieDB.RequireContract(4)`).
- Les getters numériques renvoient `0`, jamais `nil`. Chaque lecture de table renvoie une copie.
- Spawns : `{[areaId] = {{x, y}, ...}}` en 0-100. Passage en uiMapID via
  `LibQuestieDB.Support.Get("ZoneDB")` (`areaIdToUiMapId`, chaîne à `loadstring`), puis
  `subZoneToParentZone`.
- Masques de races sur plus de 32 bits (Skyborne = 2^32 et 2^33) : `bit.band` ne marche pas, tester
  avec `math.floor(mask / bitValue) % 2 == 1`. Races : Humain 1, Orc 2, Nain 4, Elfe de la nuit 8,
  Mort-vivant 16, Tauren 32, Gnome 64, Troll 128, Skyborne Alliance 2^32, Skyborne Horde 2^33.
  Classes : Guerrier 1, Paladin 2, Chasseur 4, Voleur 8, Prêtre 16, Chaman 64, Mage 128,
  Démoniste 256, Druide 1024.
- Nouvelles quêtes Forever présentes (couche `src/corrections/Forever/generated/`, environ 655 de
  niveau ≤ 32), mais incomplètes : environ 15 % sans PNJ de rendu localisé.
- **XP** : `support/Forever/QuestXP/xpDB-classic.lua` couvre les quêtes Classic, **aucune** nouvelle
  quête Forever. Il faut l'estimer (voir § 7).
- Licence : Questie/QuestieDB ne garantissent pas une licence GPL propre sur tout l'historique.
  **On ne redistribue pas leur base** : Questify la lit à l'exécution et la déclare en dépendance
  obligatoire. Nos guides ne contiennent que des IDs et des coordonnées choisies par notre
  générateur, c'est-à-dire des faits.

### Addons de navigation (dépendances optionnelles)

| Addon | Licence | Slug CurseForge (ID) | API utile |
|---|---|---|---|
| ShortestPath Forever | GPL-3.0+ | `shortest-path-forever` (1708599) | `ShortestPathForever.API.Navigate(owner, map, x, y, title, kind)`, `NavigateRoute`, `Cancel(owner)` ; coords 0-1 ; renvoie false en combat |
| WaypointUI | GPLv3 | `waypointui` (1275146) | `WaypointUIAPI.Navigation.NewUserNavigation({name, mapID, x, y})` coords **0-100**, `ClearUserNavigation()` |
| TomTom | All Rights Reserved | `tomtom` (18808) | `TomTom:AddWaypoint(map, x, y, {title, crazy=true, persistent=false})` coords 0-1, `TomTom:RemoveWaypoint(uid)` |

ShortestPath calcule l'itinéraire entre zones (vols, bateaux, portails) et transmet sa destination
à WaypointUI ou TomTom s'ils sont présents. WaypointUI redessine le marqueur 3D natif.

### Licence de Questify
GPL-3.0 pour le code et les guides générés.

## 4. Décisions prises par l'utilisateur

- Addon gratuit, publié sur CurseForge.
- Dépendances déclarées (pas embarquées) + solution de secours sans addon tiers.
- Assistant au premier démarrage pour choisir la navigation, avec un seul fournisseur actif.
- Route **100 % maison** construite à partir des données Forever connues (pas de reprise des guides
  RestedXP, même sous CC BY-NC-SA).
- Le générateur tient compte de l'XP, des suites de quêtes, des positions de prise et de rendu,
  **et de la valeur stratégique** (point de vol, ouverture de zone) des quêtes peu rentables en XP.
- Quêtes de donjon ramassées au passage.
- Objectifs :
  - waypoint vers la zone des mobs ou vers l'objet à utiliser ;
  - marqueur au-dessus des mobs à tuer ;
  - liste des mobs à côté du suivi, modèle 3D au survol, clic = ciblage du plus proche + crâne.
- Automatisation en option (désactivable) : accepter et rendre les quêtes ; choisir la récompense
  (utilisable et meilleure que l'équipée, sinon la plus chère chez le marchand).
- Quêtes de classe :
  - alerte dans le suivi sous la minimap ;
  - au clic, choix « Ajouter à la route » ou « Ignorer » ;
  - onglet « Quêtes de classe » dans le journal principal, d'où on peut les réajouter ;
  - aperçu des récompenses.
- Priorité de contenu : Alliance, puis Horde, puis Skyborne. Niveau 1-30 pour le lancement.

## 5. Architecture

```
questify/
  Questify/                     dossier de l'addon (ce qui est publié)
    Questify.toc                Interface 16001 (secours si le suffixe n'est pas reconnu)
    Questify_Camelot.toc        identique
    Locales/                    enUS (défaut) + frFR
    Core/                       init, évènements, réglages (SavedVariables), utilitaires, log
    Data/                       façade QuestieDB, cartes, constantes races/classes
    Engine/                     registre de guides, étapes, progression, quêtes de classe, mesures
    Nav/                        abstraction de navigation + 4 fournisseurs
    Automation/                 auto quêtes + choix de récompense
    UI/                         suivi (et mobs sous les objectifs), journal, assistant, options, barres de nom
    Guides/                     guides générés (Alliance/, Horde/, Skyborne/) + données de classe
  tools/routebuilder/           générateur de routes hors jeu (LuaJIT)
  tests/                        harnais LuaJIT qui simule l'API WoW
  docs/
  .pkgmeta  LICENSE  README.md
```

Espace de noms : tous les fichiers reçoivent `local addonName, Q = ...`. Une seule globale publique,
`Questify`, pour les macros et le débogage. SavedVariables : `QuestifyDB` et
`QuestifyCharDB`. Commandes : `/questify`, `/qf`. Pas de bibliothèque tierce obligatoire en v1.

### 5.0 Priorités si le temps manque (mon choix, ordre de livraison)
1. Moteur de route + suivi + navigation (natif + 3 fournisseurs).
2. Acceptation et rendu automatiques.
3. Quêtes de classe (alerte, ajout, ignorer, onglet).
4. Panneau des mobs avec modèle 3D et ciblage + crâne.
5. Icônes au-dessus des mobs.
6. Choix de récompense, assistant de premier démarrage, mesures de temps.

Le générateur de route passe en parallèle du point 1 : le contenu Nain/Gnome doit être prêt en
premier. La relecture des chapitres est faite par Claude (cohérence des données et bon sens par
rapport aux guides publics, sans rien recopier).

### 5.1 Façade données (`Data/`)
- Vérifie au chargement que QuestieDB est présent et que `RequireContract(4)` passe. Sinon, affiche
  un message clair et désactive le moteur sans erreur Lua.
- Fonctions : nom et niveau de quête, PNJ et objets de départ et de rendu, objectifs, spawns en
  uiMapID 0-100, nom et niveau d'un PNJ, sources de loot d'un objet.
- Quête éligible pour le personnage : race, classe, niveau requis, prérequis
  (`preQuestSingle` = au moins un, `preQuestGroup` = tous, `exclusiveTo`).
- Noms localisés : QuestieDB d'abord, puis `C_QuestLog.GetTitleForQuestID`, puis l'anglais.

### 5.2 Format des guides (contrat entre générateur et addon)

```lua
local _, Q = ...
Q:RegisterGuide({
  id = "A_DwarfGnome_01",            -- unique, ordre lexical = ordre de la route
  title = "Coldridge Valley",        -- nom de chapitre (anglais, affiché localisé si possible)
  faction = "Alliance",              -- "Alliance" | "Horde"
  races = { "Dwarf", "Gnome" },      -- facultatif : chapitre de départ réservé à ces races
  minLevel = 1, maxLevel = 6,
  next = "A_DwarfGnome_02",          -- chapitre suivant (peut dépendre de la race : nextByRace)
  steps = {
    { "accept", 179 },
    { "accept", 233 },
    { "complete", 170, at = { 1426, 26.1, 74.3 } },   -- at = {uiMapID, x, y} en 0-100
    { "complete", 3361, obj = 2 },                     -- un objectif précis
    { "turnin", 179 },
    { "goto", 1426, 22.6, 71.4, note = "..." },
    { "fp", 1426, 55.8, 47.8 },                        -- prendre le point de vol
    { "sethearth", 1426, 47.4, 52.5 },                 -- lier la pierre de foyer (aubergiste)
    { "hearth", 1426 },                                -- utiliser la pierre (destination)
    { "fly", 1453 },                                   -- prendre un vol vers la carte
    { "boat", 1437, 4.6, 57.1, note = "..." },         -- prendre le bateau / zeppelin
    { "level", 6 },                                    -- tuer des mobs jusqu'au niveau 6
    { "note", "..." },                                 -- étape manuelle
  },
})
```

Champs facultatifs sur toute étape : `race = {...}`, `class = {...}`, `optional = true`,
`dungeon = "Deadmines"`, `note = "..."`, `at = {...}`, `xp = <estimation>`.

### 5.3 Moteur de progression (`Engine/`)
- **Étape terminée** :
  - `accept` : la quête est dans le journal ou déjà rendue ;
  - `complete` : la quête (ou l'objectif `obj`) est terminée, ou déjà rendue ;
  - `turnin` : `IsQuestFlaggedCompleted` ;
  - `goto` / `boat` : joueur à moins de 15 m de la position (via coordonnées monde) ;
  - `fp` : `TAXIMAP_OPENED` à moins de 30 m du point ;
  - `sethearth` : évènement `HEARTHSTONE_BOUND` ;
  - `hearth` / `fly` : arrivée sur la carte de destination ;
  - `level` : niveau atteint ;
  - `note` : clic du joueur.
- **Étape sautée** (affichée grisée, jamais bloquante) :
  - filtre race ou classe qui ne correspond pas ;
  - quête non éligible (race, classe, prérequis manquant dont la quête a été sautée) ;
  - `complete` / `turnin` d'une quête ni dans le journal ni rendue ;
  - `optional` quand l'option « quêtes de donjon » est désactivée.
- Un niveau requis pas encore atteint **n'est pas** un saut : l'étape affiche « niveau N requis ».
- L'étape courante est la première ni terminée ni sautée. Le joueur peut toujours passer une étape
  ou revenir en arrière (clic droit).
- **Chapitres** : au premier lancement, choix automatique selon la faction, la race et le niveau.
  Un chapitre fini enchaîne sur `next`. Le joueur peut choisir un autre chapitre dans le journal.
- **État par personnage** (`SavedVariablesPerCharacter`) : chapitre courant, étapes manuelles
  cochées, quêtes de classe ajoutées ou ignorées, mesures de temps.
- **Mesures** : temps passé par étape, enregistré localement. `/questify export` produit une chaîne
  à copier pour améliorer les routes après le lancement.

### 5.4 Navigation (`Nav/`)
- Interface interne unique : `Nav:SetTarget(uiMapID, x01, y01, title)` et `Nav:Clear()`.
- **Cible de l'étape** :
  - `accept` : spawn le plus proche du PNJ ou de l'objet de départ ;
  - `turnin` : spawn le plus proche du PNJ de rendu ;
  - `complete` : `at` s'il existe, sinon le spawn d'objectif le plus proche (mob, objet, ou mob qui
    lâche l'objet). La cible est recalculée toutes les 5 s pendant que le joueur se déplace ;
  - les autres étapes : leurs coordonnées.
- **Fournisseurs** :

  | Fournisseur | Rôle | Appel |
  |---|---|---|
  | ShortestPath | calcul d'itinéraire, s'il est activé | `Navigate("Questify", ...)` ; il gère l'affichage via WaypointUI ou TomTom |
  | WaypointUI | affichage | `NewUserNavigation` |
  | TomTom | affichage | flèche `crazy` ; on retire l'ancien point avant d'en poser un nouveau |
  | Natif | affichage, toujours disponible | user waypoint + super-track |

- En combat, ShortestPath refuse : on retente à `PLAYER_REGEN_ENABLED`.
- **Assistant de premier démarrage** :
  1. liste les addons détectés (`C_AddOns.IsAddOnLoaded`) et explique chacun ;
  2. choix 1 : calcul d'itinéraire ShortestPath, oui ou non ;
  3. choix 2 : affichage WaypointUI, TomTom ou natif ;
  4. les deux options d'automatisation.

  On peut le rouvrir depuis les options.

### 5.5 Objectifs, mobs et barres de nom (`UI/`)
- **Mobs de l'étape courante** (dans le suivi, sous chaque ligne d'objectif de l'étape « Faire » :
  crâne, nom, niveau ; 6 au plus, grisés quand l'objectif est rempli).
  - Sources : objectifs de type créature, killcredit, et mobs qui lâchent les objets demandés,
    triés par taux de loot.
  - Pour chaque mob : nom, niveau (la progression est sur la ligne d'objectif au-dessus).
  - Survol : modèle 3D (`PlayerModel:SetCreature(npcID)`), avec une icône si le modèle reste vide.
  - Clic : bouton sécurisé `/cleartarget`, `/targetexact Nom`, `/tm !8`, posé par-dessus la ligne
    par coordonnées d'écran (jamais enfant du suivi, qui resterait sinon protégé). Les boutons se
    replacent hors combat uniquement, avec une file d'attente pendant le combat.
  - Option « Touche de ciblage auto » (désactivée par défaut) : un raccourci (`Bindings.xml`) clique
    un bouton sécurisé caché dont la macro (`/stopmacro [combat]`, puis `/targetexact` sur chaque
    nom, objectifs restants d'abord, puis `/tm !8`) cible et marque le plus proche. Le client
    interdit tout ciblage sans touche ni clic : un ciblage entièrement automatique est impossible.
- **Objets à utiliser** (coffres, plantes) : la cible de navigation pointe sur l'objet, et le
  marqueur 3D natif ou WaypointUI flotte au-dessus. Le suivi affiche « Utiliser : <objet> ».
  - Forever, marqueur natif : animation dorée (deux ondes, étoile qui tourne) accrochée au cadre
    d'écran du marqueur (`C_Navigation.GetFrame()`), affichée si l'objet est à l'écran
    (`WasClampedToScreen` faux) et à moins de 50 m, taille selon `GetDistance()`. Un addon ne peut
    rien dessiner dans le monde 3D : c'est la seule accroche possible. Option `objectGlow`.
- **Barres de nom** : sur `NAME_PLATE_UNIT_ADDED`, si le npcID fait partie des mobs d'objectif, on
  pose une icône animée qui rebondit au-dessus de la barre. Toute valeur secrète est ignorée sans
  erreur.

### 5.6 Automatisation (`Automation/`)
- Deux options, activées par défaut, désactivables : « Accepter / rendre automatiquement » et
  « Choisir la récompense automatiquement ». Maintenir Maj (Shift) suspend l'automatisation.
- Ne concerne que les quêtes présentes dans les chapitres chargés ou dans les quêtes de classe
  ajoutées.
- **Choix de récompense** :
  1. Parmi les choix utilisables par la classe (type d'armure, type d'arme, niveau requis), prendre
     la meilleure amélioration par rapport à l'objet équipé dans l'emplacement. Pour les anneaux,
     les bijoux et les armes à une main : comparer au moins bon des deux.
  2. Le score vient de poids de stats simples par classe (table en dur) appliqués à
     `C_Item.GetItemStats`, plus l'armure et le DPS pour les armes.
  3. Si rien n'améliore : prendre l'objet qui se revend le plus cher.
  4. Un message dans le chat dit quoi et pourquoi.

### 5.7 Quêtes de classe (`Engine/ClassQuests` + `UI/`)
- **Liste calculée** depuis QuestieDB : quêtes dont `requiredClasses` inclut la classe du joueur,
  éligibles pour sa race et sa faction, regroupées en chaînes (`preQuestSingle`,
  `nextQuestInChain`), hors quêtes déjà dans la route. Récompenses (objets, XP) précalculées par le
  générateur dans `Guides/ClassQuestData.lua`.
- **Alerte** : une icône pulsée dans le suivi quand une chaîne devient disponible (niveau atteint,
  prérequis faits, pas ignorée). Au clic, une fenêtre montre la description, les récompenses
  (infobulles d'objets) et le lieu, avec deux boutons : « Ajouter à la route » et « Ignorer ».
- **Ajout** : les étapes de la chaîne (prendre, faire, rendre, suite…) s'insèrent avant l'étape
  courante. La navigation y va, puis la route principale reprend.
- **Onglet « Quêtes de classe »** dans le journal : toutes les chaînes avec leur état (disponible,
  à venir avec le niveau, ajoutée, ignorée, faite). On peut les réajouter depuis là.

### 5.8 Interface
- **Suivi** (sous la minimap, déplaçable, verrouillable) :
  - en-tête : chapitre, niveaux, barre de progression ;
  - étape courante en gros (icône d'action, texte, distance) ;
  - les 3 étapes suivantes en petit ;
  - mobs à tuer sous les objectifs de l'étape courante ;
  - alerte de quête de classe.
- **Journal** (`/questify`, `/qf`, ou bouton du compartiment d'addons), trois onglets :
  1. **Route** : toutes les étapes du chapitre, cochées ou grisées, avec un sélecteur de chapitre ;
  2. **Quêtes de classe** ;
  3. **Options** : automatisations, navigation, quêtes de donjon, taille et verrouillage du suivi,
     réinitialisation.
- Style sobre, inspiré de l'interface Blizzard (modèles natifs), lisible en 1080p.

## 6. Routes : principes

- **Ordre des zones** par faction et par race : établi à la main à partir des connaissances
  communautaires, qui sont des faits. Par défaut :
  - Nain/Gnome : Coldridge 1-6, Dun Morogh 6-11 (pré-quêtes de Hall of Thanes), Loch Modan 11-14,
    Marche de l'Ouest 13-15, Sombrivage 14-19, Les Carmines 19-20, Ashenvale / Les Serres-Rocheuses
    20-23, Les Paluns 23-24, Bois de la Pénombre / Les Carmines 24-27, Les Paluns / Contreforts
    d'Hautebrande 27-29, Ashenvale 29-30.
  - Humain : Northshire, Elwynn, puis même tronc commun à partir de la Marche de l'Ouest.
  - Elfe de la nuit : Shadowglen, Teldrassil, Sombrivage, puis tronc commun.
  - Horde : vallée des Épreuves / Durotar, Mulgore, Clairières de Tirisfal / Forêt des
    Pins-Argentés, puis tronc commun aux Tarides 12-17, Les Serres-Rocheuses / Les Tarides /
    Ashenvale 17-22, Contreforts d'Hautebrande 21-23, Tarides du Sud / Les Serres-Rocheuses 23-26,
    Ashenvale 26-28, Mille pointes 28-30.
  - Skyborne : île de Zephras 1-13, puis bateau et tronc commun de la faction.

  Le générateur peut proposer de déplacer une zone quand ses calculs montrent un meilleur rendement.
- **Contenu de chaque zone** : choisi et ordonné par le générateur (§ 7), puis relu à la main.
- Nouveaux donjons Forever :
  - Hall of Thanes 13-18 (Alliance, pré-quêtes 96391-96393 à Dun Morogh) ;
  - Ruins of Lordaeron 15-22 ;
  - Excavation Site: Wetlands 24-29 ;
  - Dalaran 28-33.

  Leurs quêtes sont ramassées au passage, en `optional`.

## 7. Générateur de routes (`tools/routebuilder/`)

Outil LuaJIT hors jeu. Il lit QuestieDB (clone local, chemin en argument) avec le chargeur isolé
déjà écrit (`questie_extract.lua` : fichiers lus en texte, exécutés sans `os`/`io`/`load`) et écrit
les fichiers de `Questify/Guides/`.

1. **Données** :
   - vue Forever (Era convertie + corrections + nouvelles quêtes), filtrée par faction ;
   - positions en coordonnées monde (yards) via les bornes de carte `UiMapAssignment` du client
     1.60.1 (export CSV de wago.tools ; à défaut, tailles de zones Classic en dur) ;
   - points de vol et aubergistes via `npcFlags`.
2. **XP des quêtes** : table QuestXP si connue. Sinon, estimation par la médiane des quêtes Classic
   de même niveau, ajustée selon le type (simple, suite, élite, donjon −50 %).
3. **Règles d'XP Classic** :
   - quête rendue au niveau ≤ niveau de la quête + 5 : 100 %, puis 80 / 60 / 40 / 20 %, et 10 % à
     partir de +10 ;
   - XP par mob : `niveau × 5 + 45` à niveau égal, +5 % par niveau au-dessus, réduite en dessous
     selon la « différence zéro » de Classic ;
   - table d'XP par niveau de Classic.
4. **Coût en temps** :
   - course à 7 yards/s ;
   - environ 20 s par mob tué, repos compris ;
   - objet à ramasser = nombre / taux de loot × mobs ;
   - environ 6 s par objet du monde, plus le déplacement entre les spawns.
5. **Simulation** :
   - un personnage part du point de départ de sa race, avec un journal plafonné à 20 quêtes ;
   - dans chaque zone, il construit des tâches (prendre, faire les objectifs, rendre) avec leurs
     contraintes d'ordre (prendre avant faire avant rendre ; rendre la quête N avant prendre N+1) ;
   - il choisit les quêtes par rendement (XP + bonus stratégique) / temps marginal, jusqu'à la fin de
     la tranche de niveaux de la zone ;
   - il ordonne les tâches : plus proche voisin faisable, puis amélioration locale (2-opt / or-opt)
     qui respecte les contraintes.
6. **Bonus stratégique** :
   - une quête de transport (`breadcrumbForQuestId`, rendu dans la zone suivante) ou qui mène à un
     point de vol inconnu reçoit un bonus égal au temps qu'elle fait gagner ;
   - une quête qui ouvre une chaîne reçoit la valeur actualisée de la chaîne.
7. **Étapes logistiques insérées automatiquement** :
   - `fp` quand la route passe à moins de 150 yards d'un maître de vol inconnu ;
   - `sethearth` dans l'auberge du hub où la route reviendra ;
   - `hearth` quand c'est plus rapide que la marche et que la pierre est disponible (60 min) ;
   - `fly` / `boat` entre zones ;
   - `level` si la simulation manque d'XP.
8. **Sortie** :
   - fichiers de guides lisibles, avec en commentaire le nom de chaque quête, l'XP estimée et le
     niveau simulé ;
   - un rapport par chapitre : XP/h estimée, quêtes écartées et pourquoi, alertes de données
     (quête sans PNJ de rendu, coordonnées manquantes) ;
   - `Guides/ClassQuestData.lua` avec les récompenses des quêtes de classe.
9. **Relecture humaine** de chaque chapitre avant publication.

## 8. Tests (sans le jeu)

- Harnais LuaJIT dans `tests/` :
  - simule l'API WoW utile (frames factices, évènements, `C_QuestLog`, `C_Map`, `UnitRace`…) ;
  - charge les fichiers dans l'ordre du TOC.
- Scénarios :
  - choix du chapitre ;
  - étapes terminées ou sautées après acceptation, objectifs remplis, rendu ;
  - quête de classe ajoutée puis ignorée ;
  - choix de récompense ;
  - changement de fournisseur de navigation ;
  - aucune erreur si QuestieDB est absent.
- Validation des guides contre QuestieDB : chaque ID existe, est éligible pour au moins une race
  visée, les coordonnées sont dans les bornes, les actions sont valides, chaque `turnin` suit son
  `accept`.
- Vérification syntaxique de tous les `.lua` (`luajit -bl` ou `loadfile`).
- Limites connues, à vérifier en jeu le jour du lancement :
  - `/tm` en solo ;
  - valeurs secrètes en combat ;
  - reconnaissance du TOC `_Camelot` ;
  - marqueur natif.

## 9. Packaging

- `.pkgmeta` :
  - `package-as: Questify` ;
  - `required-dependencies` : QuestieDB (slug à confirmer) ;
  - `optional-dependencies` : `shortest-path-forever`, `waypointui`, `tomtom`.
- TOC :
  - `## Dependencies: QuestieDB` ;
  - `## OptionalDeps: ShortestPathForever, WaypointUI, TomTom` (noms de dossiers à confirmer) ;
  - `## SavedVariables: QuestifyDB` ;
  - `## SavedVariablesPerCharacter: QuestifyCharDB` ;
  - `## AddonCompartmentFunc`.
- Script `tools/package.sh` qui produit `dist/Questify-<version>.zip` pour une installation manuelle.

## 10. Laissé au constructeur

Mise en page exacte, textures et icônes (fichiers du jeu uniquement), poids de stats exacts par
classe, structure interne des modules, seuils numériques du générateur (à ajuster en voyant les
rapports), découpage précis des chapitres.

## 11. Mes choix (à vérifier par l'utilisateur)

1. Nom de l'addon : **Questify** (demandé par l'utilisateur), version indépendante de QuickPath.
2. QuestieDB lu à l'exécution plutôt que copié, pour la licence et les mises à jour automatiques.
3. Marqueur 3D natif du client comme solution de secours sans addon tiers (pas de flèche maison).
4. Ordre des zones fixé à la main, contenu des zones choisi par le générateur.
5. XP des nouvelles quêtes Forever estimée (non publiée dans les données).
6. Automatisations activées par défaut, Shift pour suspendre, uniquement sur les quêtes de la route.
7. Score d'amélioration par poids de stats simples par classe, pas de simulateur.
8. Interface en anglais et en français dès la v1.
9. Pas d'épingles sur la carte du monde ni sur la minimap en v1 (le marqueur 3D et la navigation
   suffisent) ; elles pourront venir ensuite avec HereBeDragons (licence BSD).
10. Mesure locale des temps par étape, export manuel uniquement, rien n'est envoyé.

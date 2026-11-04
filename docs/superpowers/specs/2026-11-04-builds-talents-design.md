# Builds de talents et sorts à apprendre — design

Date : 4 novembre 2026. Statut : proposé, à valider par l'utilisateur.
Maquette cliquable validée : [`2026-11-04-builds-talents-maquette.html`](2026-11-04-builds-talents-maquette.html)
(à ouvrir dans un navigateur ; rendu approximatif, données réelles du Chaman).

## 1. Intention

Le joueur veut monter de niveau vite, sans réfléchir à ses talents ni rater un sort. Concrètement :
- à chaque point de talent gagné, savoir quel talent prendre et le prendre d'un clic ;
- suivre un build à jour (Icy Veins pour commencer), le modifier ou en créer un à soi, le partager ;
- voir les sorts déjà appris et ceux à venir, avec niveau et prix, et y aller (maître ou quête).

Cette fonction remplace le système actuel de presets de talents (`Questify/Engine/Talents.lua`,
`Questify/UI/TalentPicker.lua`, `Questify/Data/TalentBuilds.lua`). Celui-ci désigne les talents par
`GetTalentInfo` (arbre, palier, colonne), une API absente de Forever, et aucune classe n'a de preset.

L'utilisateur joue un Nain Chaman : Élémentaire pour monter, Restauration en seconde spécialisation
pour les donjons et le JcJ. C'est le premier cas à faire marcher de bout en bout.

## 2. Objectifs

1. **Builds fournis** par classe, dans l'addon : pour chaque spécialisation publiée par Icy Veins
   (guide « leveling » de WoW Forever), l'ordre des points niveau par niveau, du 10 au 60 (un point par
   niveau, 51 points). Au minimum, un build de montée par classe pour la sortie.
2. **Popup au centre de l'écran** quand un ou plusieurs points sont à dépenser : icône, nom et rang du
   ou des talents, arbre, build suivi ; boutons « Apprendre », « Ouvrir les talents », « Plus tard ».
3. **Onglets Questify dans la fenêtre des talents du jeu**, au style du jeu : « Build » (éditeur) et
   « Sorts à apprendre ». L'affichage des talents reste celui du jeu.
4. **Dans l'affichage des talents du jeu** : halo sur le prochain talent du build, ligne Questify
   dans son infobulle (« prochain point de ton build, niveau X, rang r/max »), bande en haut
   « Build suivi : … · prochain point : … » avec un bouton « Modifier le build ».
5. **Éditeur de build** (onglet Build), comme un simulateur :
   - les trois arbres avec les vraies icônes et les infobulles du jeu ;
   - clic gauche sur un talent : ajoute un point au prochain niveau libre ; clic droit : retire le
     dernier point de ce talent ;
   - à droite, la liste « Niv. N → talent, rang r/max » ; ✕ sur une ligne retire ce point et fait
     remonter les suivants ; niveaux déjà passés cochés, prochain niveau surligné ;
   - curseur « Voir l'arbre au niveau N » ;
   - validation à chaque modification, refus avec la raison (rang max, points requis dans l'arbre,
     talent requis) ;
   - « Enregistrer » sous un nom choisi, « Dupliquer », « Utiliser ce build » ;
   - les builds fournis ne s'écrasent pas : modifier puis enregistrer crée une copie personnelle.
6. **Builds obsolètes** : un build dont un talent n'existe plus, dont un rang max a changé ou dont
   l'ordre ne respecte plus les règles de l'arbre est grisé avec « ⚠ Build obsolète » et la raison.
   Il reste consultable mais ne peut pas être le build actif. « Dupliquer » en fait une copie sans
   les talents disparus, à compléter.
7. **Import / export dans l'onglet Build**, hors des profils d'options :
   - « Exporter » un build : chaîne de texte à copier ;
   - « Importer » : coller une chaîne Questify ;
   - « Exporter tous mes builds » pour une sauvegarde.
8. **Onglet « Sorts à apprendre »** :
   - sorts de la classe regroupés par niveau : icône, nom, rang, niveau requis, prix, état
     (« Appris », « Disponible chez le maître », « Niveau X », « Quête de classe ») ;
   - filtres : Tous, À apprendre, Appris, À venir ;
   - bandeau : maître le plus proche, nombre de sorts à apprendre maintenant, coût total, or du joueur ;
   - bouton « Route vers le maître le plus proche » ;
   - pastille sur l'onglet avec le nombre de sorts à apprendre maintenant.
9. **Sorts obtenus par une quête** : si la quête est dans le journal, bouton « Suivre la quête »
   (ses étapes passent en tête du suivi) ; sinon, bouton « Récupérer la quête » (la chaîne restante
   est ajoutée à la route, en partant du donneur de la première quête non faite). Chaîne pas encore
   accessible : bouton grisé « Disponible au niveau X ».

## 3. Non-objectifs

- Remplacer la fenêtre des talents du jeu ou prendre sa touche (N).
- Gérer les configurations de talents enregistrées par le jeu (le système de « loadouts » de la
  fenêtre Blizzard) ou leur format d'import.
- Talents JcJ, glyphes, builds de fin de jeu au-delà de ce qu'Icy Veins publie pour Forever.
- Dépenser un point sans action du joueur.
- Mettre les builds dans les profils d'options partageables (`QFY1:`) : même logique que le choix de
  butin, qui reste hors profil.

## 4. Anti-objectifs (échec même si « ça marche »)

- Une erreur « action bloquée » ou une contamination (taint) de l'interface du jeu à cause de nos
  onglets, surtout en combat.
- Conseiller un talent qui n'existe plus, ou utiliser un build obsolète sans le dire.
- Recopier des textes d'Icy Veins dans l'addon : seuls les ID de sorts et l'ordre des points sont
  stockés, avec la source et la date ; tous les textes affichés viennent du jeu.
- Une popup envahissante : en combat, plusieurs fois pour le même point, ou sans point à dépenser.

## 5. Faits techniques établis

Vérifiés dans le code de l'interface publié par Blizzard pour Forever (dépôt `Gethe/wow-ui-source`,
branche `forever`, dossier `Interface/AddOns/Blizzard_PlayerSpells/Camelot/`) :

- **La fenêtre** est `PlayerSpellsFrame` (variante Camelot). `IsTabSystemAvailable()` y renvoie
  `false` : grimoire et talents s'ouvrent séparément comme en Classic (boutons du micro-menu), sans
  onglets principaux visibles. Le `TabSystem` principal, caché, est ancré en bas à gauche de la
  fenêtre (`x = 22`). Nos onglets vont donc en bas, à cet endroit (forme « classique » de la maquette).
- **L'affichage des talents** est `PlayerSpellsFrame.TalentsFrame`, issu de `ClassTalentsFrameTemplate`
  (base `TalentFrameBaseTemplate`). Il a son propre `TabSystem` en haut : « spécialisation
  principale / secondaire » (double spécialisation, verrouillée tant que `GetNumSpecGroups() == 1`).
  Les points se posent en attente puis se valident avec le bouton « Appliquer » (`ApplyButton`),
  avec annuler et réinitialiser, et une barre d'incantation « application des talents ».
- **Les talents passent par `C_Traits`** : un arbre de classe dont les trois arbres classiques sont des
  groupes (`C_Traits.GetGroupDisplayInfoByTreeID`, `C_Traits.GetGroupCurrencyInfo`) ; chaque nœud a
  des entrées, chaque entrée une définition avec un `spellID`. Le relevé `/qf talents` de
  `Talents:Dump()` lit déjà tout cela (nœuds, positions, rangs, groupes, sorts, monnaie).
- **Le grimoire** sait afficher des sorts à venir (`Enum.SpellBookItemType.FutureSpell`) ; reste à
  voir si Forever le remplit.
- **Le lien du calculateur Icy Veins** contient tout le build :
  `…/wow-forever/<classe>-talent-calculator#tc-<un caractère par point>~…`. Chaque caractère est
  l'index d'un talent dans l'ordre de la page. La page donne pour chaque index l'arbre, le palier,
  la colonne, le rang max et le `spellID` du rang 1 (`data-spell`). Exemple du Chaman Élémentaire,
  relevé le 4 novembre (mis à jour pour les correctifs d'avant la sortie) :
  `111114445565000a8899cddd9eeeeefzzzzzAAADDGhhhhh00ii`, soit Concussion 5/5 aux niveaux 10-14,
  Elemental Alacrity 3/3 aux niveaux 15-17, …, Lightning Mastery au 40, puis Restauration.
  Règles de l'arbre constatées : 5 points dans l'arbre par palier, certains talents en requièrent un
  autre au rang max.

Règles du dépôt qui s'appliquent : tests LuaJIT (`luajit tests/run.lua`, simulateur `tests/wow_mock.lua`) ;
valeurs « secrètes » vérifiées par `Q.Util.IsSecret` avant toute comparaison ; import analysé
strictement, jamais de `loadstring` (comme `Questify/Core/Profiles.lua` pour `QFY1:`) ; données par
compte dans `QuestifyDB`, par personnage dans `QuestifyCharDB` ; textes en français et en anglais
dans `Questify/Locales/`.

## 6. Ce que l'utilisateur a décidé

- Popup au centre de l'écran à chaque point gagné ; un clic prend le bon talent du build.
- Presets niveau par niveau, modifiables ; éditeur façon simulateur (3 arbres, liste à droite) ;
  enregistrer sous le nom voulu ; choisir le build qui sert de source.
- Infobulles et icônes du jeu, retrouvées par l'ID du talent.
- Build importé devenu obsolète : grisé, « Build obsolète ».
- Deux onglets : talents (build) et sorts (appris et non appris, niveau, prix, bouton « Route vers
  le maître le plus proche »).
- Sorts de quête : « Suivre la quête » si elle est dans le journal, sinon « Récupérer la quête ».
- Tout est intégré en onglets dans la fenêtre des talents du jeu, au même style ; rien dans les
  Options de l'addon ; import et export dédiés aux builds.
- La maquette jointe est le rendu attendu.

## 7. Choix de Claude (à relire par l'utilisateur)

1. **Écart au build.** Rien n'est bloqué. Le « prochain talent » est la première entrée de l'ordre
   dont le rang n'est pas encore atteint dans l'arbre réel et qui est possible maintenant ; les
   entrées impossibles sont sautées. Si l'arbre réel contient des points hors du build, la bande
   Questify affiche « Ton arbre ne suit plus le build X » avec « Créer un build à partir de mon
   arbre ». Ce build reprend les points actuels palier par palier (l'ordre réel des points n'est pas
   connu) et laisse les niveaux suivants libres.
2. **Build actif par personnage et par spécialisation** (principale, secondaire), dans
   `QuestifyCharDB` : par exemple Élémentaire en principale, Restauration en secondaire. La popup et
   le halo suivent la spécialisation active.
3. **Où vivent les builds.** Les builds fournis sont dans le code (`Questify/Data/`), jamais copiés
   dans les sauvegardes : une nouvelle version de l'addon les remplace. Les builds personnels sont
   par compte (`QuestifyDB`), rangés par classe.
4. **Identité d'un talent dans un build** : le `spellID` du rang 1, avec l'arbre, le palier, la
   colonne et le rang max en contrôle. Correspondance avec l'arbre réel par `spellID` de la
   définition de l'entrée du nœud. Talent introuvable, rang max différent ou règle violée : build
   obsolète.
5. **« Apprendre » dans la popup** fait ce que fait le bouton « Appliquer » de la fenêtre du jeu :
   achat du rang sur le nœud puis validation (le builder lit la séquence exacte dans
   `Blizzard_PlayerSpells` et `Blizzard_SharedTalentUI` de la branche `forever`). Jamais en combat :
   le bouton attend la fin du combat. Si un appel échoue ou est bloqué, repli pour la session :
   « Apprendre » ouvre la fenêtre des talents avec le halo.
6. **Popup** : seulement s'il y a au moins un point à dépenser et un prochain talent ; jamais en
   combat (elle attend la sortie) ; « Plus tard » la cache jusqu'au prochain point gagné ; la ligne
   d'alerte talents du suivi la rouvre. Le réglage existant `talentAlert` (Options, section Classe)
   quitte les Options pour une roue dentée dans l'onglet Build.
   **Plusieurs points en attente** (seconde spécialisation débloquée, talents réinitialisés, addon
   installé en cours de route, « Plus tard » plusieurs fois) : la popup dit « N points à dépenser »
   et liste les N prochains talents du build ; « Apprendre » les achète tous puis valide une seule
   fois (une seule barre d'incantation). Le moteur expose donc la liste ordonnée des points dus
   maintenant, pas seulement le prochain.
7. **Nos onglets** sont nos propres boutons, faits avec le modèle d'onglet du jeu, accrochés à
   `PlayerSpellsFrame` en bas à gauche, visibles quand l'affichage des talents est montré. On
   n'appelle pas `AddNamedTab` sur un `TabSystem` de Blizzard, on ne remplace aucune méthode de leurs
   mixins, on ne cache ni ne déplace leurs éléments en combat. Notre contenu se pose par-dessus la
   zone des talents ; l'onglet « Talents » nous retire. Créations et changements d'affichage hors
   combat (`InCombatLockdown`), sinon différés.
8. **Accès de secours** : `/qf build` et une entrée « Build du personnage » dans le menu de la
   minimap ouvrent le même contenu dans une fenêtre Questify autonome. Elle sert aussi si
   l'accroche à la fenêtre du jeu échoue (fenêtre absente ou changée par un patch), sans erreur.
9. **Format d'échange** : `QFYB1:` suivi du base64 d'une table sérialisée de façon déterministe
   (classe, nom, source, ordre des `spellID`), analysée strictement comme `QFY1:`. « Exporter tous
   mes builds » produit la même forme avec une liste. Un build importé est vérifié tout de suite.
   Collage d'un lien du calculateur Icy Veins : bonus, à faire en dernier. Il demande une table
   index → `spellID` par classe dans les données ; un caractère inconnu refuse l'import.
10. **Données des sorts** : appris ou non par le jeu (`IsPlayerSpell` / `IsSpellKnown`) ; liste,
    niveaux et prix relevés chez le maître à chaque visite (le module `Questify/Engine/Trainer.lua`
    relève déjà nom, rang, niveau et prix) ; avant toute visite, une liste fournie par l'addon
    (niveaux sans prix : « — ») ; le grimoire s'il donne les sorts à venir. Le lien
    sort → chaîne de quête de classe vient d'une table dans les données (`Q.ClassQuestData` a les
    chaînes, pas encore le sort obtenu).
11. **Boutons d'action réutilisés** : « Route vers le maître le plus proche » insère l'étape `train`
    comme `Trainer:Go()`, même sans liste relevée ; « Récupérer la quête » appelle la même logique
    que `ClassQuests:Add(key)` ; « Suivre la quête » remonte les étapes de cette quête en tête et
    pointe la flèche dessus.
12. **Build et spécialisation du jeu.** Forever fait choisir une spécialisation (lue par
    `C_SpecializationInfo.GetSpecialization()`, déjà utilisée par `Questify/Automation/SpecRole.lua`).
    Chaque build fourni porte sa spécialisation. Quand le groupe de spécialisation actif n'a pas de
    build, Questify choisit le build fourni de la spécialisation du joueur et le dit dans la
    discussion (« Build suivi : … — à changer dans l'onglet Build »). Sans build fourni pour cette
    spécialisation, la popup propose seulement « Choisir un build » (ouvre l'onglet Build). La liste
    des builds de l'onglet Build met en avant ceux de la spécialisation du groupe affiché. Un
    sélecteur « Spé principale / Spé secondaire » dans l'onglet Build permet de donner un build à
    chaque groupe sans changer de spécialisation. Si le relevé de ce soir montre que la
    spécialisation impose un arbre (points d'abord dans l'arbre de la spé), cette règle rejoint les
    vérifications de l'éditeur et des builds obsolètes.
13. **Clic sur le talent en halo** dans la fenêtre du jeu : comportement normal du jeu (le point se
    pose en attente, le joueur valide avec « Appliquer »). Le halo et la ligne d'infobulle ne font
    qu'indiquer ; on n'intercepte pas les clics des boutons de Blizzard. Seul « Apprendre » de la
    popup dépense directement.
14. **Liste des sorts fournie par l'addon** : générée pour les 9 classes par un outil dans `tools/`
    depuis les tables du jeu de Forever (fichiers DB2 de wago.tools, comme les tables de cartes et de
    vols déjà utilisées par `tools/routebuilder`) : `spellID`, rang, niveau. Les prix ne viennent que
    du maître. Le relevé du maître devient la source principale dès la première visite ; il est
    étendu pour retrouver le `spellID` de chaque ligne quand le jeu le donne. Le lien sort → chaîne
    de quête de classe vient du sort de récompense des quêtes dans QuestieDB s'il existe, sinon d'une
    courte table écrite à la main (totems du Chaman, etc.). L'onglet Sorts arrive en dernier
    (point 15) : s'il manque une source, il sort d'abord avec le relevé du maître seul.
15. **Ordre de livraison** (l'utilisateur n'a pas tranché) : 1) moteur (correspondance avec l'arbre,
    prochain talent, obsolète), builds fournis, popup, halo et bande ; 2) onglet Build (éditeur,
    import et export) ; 3) onglet Sorts à apprendre.

## 8. Laissé au builder

Découpage en fichiers et modules, structure des données et outil qui génère les builds fournis à
partir des pages Icy Veins (dans `tools/`), mise en page exacte, animations, textes, organisation
des tests, gestion des tailles d'écran.

## 9. À vérifier en jeu (ce soir, au lancement)

Chaque point débloque une partie ; aucun ne bloque tout :
1. `/qf talents` sur un Chaman : les `spellID` des nœuds correspondent à ceux d'Icy Veins.
2. « Apprendre » par l'addon (achat du rang + validation) fonctionne hors combat.
3. Le maître liste aussi les sorts pas encore disponibles (liste complète de la classe dès la
   première visite) et donne ou non leur `spellID`.
4. Le grimoire de Forever liste les sorts à venir (`FutureSpell`).
5. Comment le jeu compte les points de talent hors des trois arbres, s'il y en a (monnaies de
   l'arbre dans le relevé).

## 10. Critères de réussite

- Au niveau 10, un Nain Chaman Élémentaire suit sans rien faire le build Icy Veins Élémentaire et
  voit la popup « Concussion 1/5 » ; un clic sur « Apprendre » dépense le point ; la popup ne revient
  pas avant le niveau 11. Dans la fenêtre du jeu, Concussion est en halo.
- Avec 5 points en attente, la popup liste les 5 talents et « Apprendre » les prend tous en une
  validation.
- Un build contenant un talent retiré (Lava Burst) apparaît « Build obsolète », grisé, et ne peut
  pas être choisi.
- Un build créé dans l'éditeur, exporté puis importé sur un autre personnage de la même classe, est
  identique.
- L'onglet Sorts d'un Chaman niveau 12 montre ses sorts appris, ceux à prendre chez le maître avec
  leur prix une fois le maître visité, et « Searing Totem » relié à « Call of Fire » avec le bon bouton.
- Aucune erreur Lua ni « action bloquée » en ouvrant, fermant ou changeant d'onglet, y compris en
  combat ; les tests LuaJIT passent.

# Questify Vanilla — reste à faire (4 novembre 2026)

Branche : `main`. Les branches `claude/cibles-dans-objectifs` et `claude/lucid-planck-m8c36r` y sont
fusionnées. Classic Era est retiré : l'addon ne vise plus que WoW: Forever (un seul zip,
`Questify_Vanilla-<version>-forever.zip`).

## Fait, mais pas encore déployé dans le jeu

`main` contient ces ajouts testés (tests verts), pas encore copiés dans le dossier AddOns :

- Monstres à tuer sous l'objectif dans le suivi, touche de ciblage auto, flèche qui suit le monstre
  le plus proche dans la zone d'objectif.
- Animation autour de l'objet à utiliser, bouton d'objet de quête (option + raccourci dans les
  Raccourcis du jeu).
- Alerte nouveaux sorts et étape vers le maître de classe, annonce « Équipez X », vente de la
  camelote, choix des métiers, largeur du suivi réglable.
- Talents : rappels de points à dépenser et `/qf talents` (relevé des arbres). Aucun build n'est
  livré (les builds guerrier Era sont retirés) : pas de choix de build tant que les builds Forever
  ne sont pas écrits.
- StepGuard : un donneur qui ne propose pas la quête attendue -> étape passée, `/qf back` pour la rouvrir.
- `/qf bug` (alias `/qf report`, bouton « Rapport de bug » des options) : un seul rapport à copier
  avec versions, addons, perso, route (étape courante et suivantes, cible), position, navigation,
  journal de quêtes, réglages, résultat de `/qf check` et erreurs Lua avec pile (y compris celles du
  chargement, gardées après `/reload`). `/qf bug clear` vide les erreurs.
- `/qf check` (alias `/qf diag`) : autodiagnostic dans la discussion, une ligne par point.

**À faire au rallumage :** mettre à jour le clone du Bureau (`git pull` sur `main`), copier
`Questify_Vanilla/` dans `_forever_\Interface\AddOns\` (ou installer le zip de la release `latest`),
puis **relancer le jeu** : de nouveaux fichiers sont dans le TOC (`Core\Diagnostics.lua`,
`Locales\StringsDiag.lua`, `Engine\StepGuard.lua`, `UI\QuestItemButton.lua`, `UI\Report.lua`, entre
autres) et `/reload` ne les charge pas. Supprimer l'ancien `UI\BugReport.lua` s'il reste dans le
dossier AddOns (il n'est plus chargé).

## Au lancement de Forever (ce soir, minuit à Paris)

1. Sur le perso Forever : `/qf check`, puis `/qf talents` et `/reload` (relevé des vrais arbres de
   talents dans `WTF\Account\...\SavedVariables\Questify_Vanilla.lua`, clé `talentDump[<classe>]`).
2. Lire ce relevé, vérifier comment le jeu expose le talent « Talented » (points hors des trois
   arbres) et adapter `Engine/Talents.lua` (compte des points à dépenser).
3. Écrire les builds Forever (monde ouvert / donjon) dans `Data/TalentBuilds.lua` sur ces arbres,
   d'après les guides mis à jour après le lancement (Icy Veins : le calculateur intégré donne le
   build final, le texte donne les niveaux ; le texte du 21 octobre n'est plus à jour). Le test
   `test_talentdata` bloque les builds impossibles.
4. Jouer avec `/qf bug` sous la main : coller chaque rapport pour corriger les étapes cassées.

## Demandé, pas encore commencé

### Confort de jeu
- **Vols automatiques** : chez le maître de vol, choisir le trajet de l'étape « Prendre un vol vers X » (Maj pour annuler).
- **Pierre de foyer** : temps de recharge dans le suivi sur les étapes « utiliser la pierre » ; si elle
  n'est pas prête, proposer le trajet à pied ou en vol.
- **Alerte élites / danger** : élites ou monstres 3 niveaux au-dessus de toi dans la zone d'objectif.
- **Sacs pleins et réparation** : rappel avant de partir loin d'un marchand.
- **XP/h et temps restant** dans l'en-tête du suivi.

### Plus ambitieux
- **Donjons selon niveau et faction** : proposer le donjon adapté au niveau, insérer ses quêtes à prendre
  en ville puis l'étape donjon. **Jamais le Gouffre de Ragefeu pour l'Alliance** (Orgrimmar, Horde
  seulement) ; table des donjons avec faction autorisée (Les Mortemines : Alliance pour les quêtes,
  Cavernes des lamentations : les deux, etc.).
- **Boucle télémétrie -> générateur** : importer les exports `/qf export` (temps réels par étape) dans
  `tools/routebuilder` pour recaler les constantes (vitesse de marche, temps par mob, temps PNJ) et régénérer les routes.

### Talents
- Builds Forever des 9 classes (voir « Au lancement »).

### Divers
- Marqueurs sur la carte du monde : préciser ce qui est voulu.
- Comparaison avec la route RestedXP : accès au dossier `RXPGuides` non accordé (fenêtre expirée) ;
  objectif = en tirer des règles pour le générateur, sans recopier leurs étapes.
- README anglais : la liste « First launch » parle encore du « mob panel » (les monstres sont
  maintenant sous l'objectif dans le suivi, comme dans la version française).
- CHANGELOG : ajouter les talents (rappels, `/qf talents`), le bouton d'objet de quête et StepGuard,
  absents de la section « Non publié ».
- Publier une release versionnée (tag `vX.Y.Z`) quand le jeu aura été testé.

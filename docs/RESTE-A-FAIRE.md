# Questify Vanilla — reste à faire (4 novembre 2026)

Branche : `claude/cibles-dans-objectifs` (pas encore fusionnée dans `main`).

## Fait, mais pas encore déployé dans le jeu

Ce commit contient trois ajouts testés (tests verts), pas encore copiés dans les dossiers AddOns :

- `/qf bug` : rapport à copier (versions, QuestieDB, perso, position, étape, journal, erreurs).
- Bouton d'objet de quête (option + raccourci dans les Raccourcis du jeu).
- StepGuard : un donneur qui ne propose pas la quête attendue -> étape passée, `/qf back` pour la rouvrir.

**À faire au rallumage :** mettre à jour le clone du Bureau (`git pull` sur la branche), copier
`Questify_Vanilla/` dans `_forever_\Interface\AddOns\`, puis
**relancer le jeu** (nouveaux fichiers : `UI\QuestItemButton.lua`, `UI\BugReport.lua`, `Engine\StepGuard.lua`).

## Au lancement de Forever (ce soir, minuit à Paris)

1. Sur le perso Forever : `/qf talents` puis `/reload` (relevé des vrais arbres de talents dans
   `WTF\Account\...\SavedVariables\Questify_Vanilla.lua`).
2. Lire ce relevé, vérifier comment le jeu expose le talent « Talented » (points hors des trois
   arbres) et adapter `Engine/Talents.lua` (compte des points à dépenser).
3. Écrire les builds Forever (monde ouvert / donjon) sur ces arbres, d'après les guides mis à jour
   après le lancement (Icy Veins : le calculateur intégré donne le build final, le texte donne les
   niveaux ; le texte du 21 octobre n'est plus à jour). Le test `test_talentdata` bloque les builds impossibles.
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
- Fusionner la branche dans `main` et publier une release quand le jeu aura été testé.

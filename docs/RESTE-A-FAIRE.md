# Questify — reste à faire (4 novembre 2026)

Branche : `main`. Les branches `claude/cibles-dans-objectifs` et `claude/lucid-planck-m8c36r` y sont
fusionnées. Classic Era est retiré : l'addon ne vise plus que WoW: Forever (un seul zip,
`Questify-<version>-forever.zip`).

## Fait, mais pas encore déployé dans le jeu

`main` contient ces ajouts testés (tests verts), pas encore copiés dans le dossier AddOns :

- Monstres à tuer sous l'objectif dans le suivi, touche de ciblage auto, flèche qui suit le monstre
  le plus proche dans la zone d'objectif.
- Animation autour de l'objet à utiliser, bouton d'objet de quête (option + raccourci dans les
  Raccourcis du jeu).
- Alerte nouveaux sorts et étape vers le maître de classe, annonce « Équipez X », vente de la
  camelote, choix des métiers, largeur du suivi réglable.
- Talents : rappels de points à dépenser, `/qf talents` (relevé des arbres) et builds niveau par
  niveau (45 builds, popup « Apprendre », onglets Build et Sorts à apprendre dans la fenêtre des
  talents, `/qf build`). Voir « À vérifier en jeu ».
- StepGuard : un donneur qui ne propose pas la quête attendue -> étape passée, `/qf back` pour la rouvrir.
- `/qf bug` (alias `/qf report`, bouton « Rapport de bug » des options) : un seul rapport à copier
  avec versions, addons, perso, route (étape courante et suivantes, cible), position, navigation,
  journal de quêtes, réglages, résultat de `/qf check` et erreurs Lua avec pile (y compris celles du
  chargement, gardées après `/reload`). `/qf bug clear` vide les erreurs.
- `/qf check` (alias `/qf diag`) : autodiagnostic dans la discussion, une ligne par point.

**À faire au rallumage :** mettre à jour le clone du Bureau (`git pull` sur `main`), copier
`Questify/` dans `_forever_\Interface\AddOns\` (ou installer le zip de la release `latest`),
puis **relancer le jeu** : de nouveaux fichiers sont dans le TOC (`Core\Diagnostics.lua`,
`Locales\StringsDiag.lua`, `Engine\StepGuard.lua`, `UI\QuestItemButton.lua`, `UI\Report.lua`, entre
autres) et `/reload` ne les charge pas. Supprimer l'ancien `UI\BugReport.lua` s'il reste dans le
dossier AddOns (il n'est plus chargé).

## À vérifier en jeu (lancement de Forever)

Chaque point débloque une partie ; aucun ne bloque tout. Jouer avec `/qf bug` sous la main.

1. `/qf check`, puis `/qf talents` sur un Chaman : les `spellID` des nœuds correspondent à ceux d'Icy Veins.
2. « Apprendre » par l'addon (achat du rang + validation) fonctionne hors combat.
3. Le maître de classe liste aussi les sorts pas encore disponibles (liste complète de la classe dès
   la première visite) et donne ou non leur `spellID`.
4. Le grimoire de Forever liste les sorts à venir (`FutureSpell`).
5. Comment le jeu compte les points de talent hors des trois arbres, s'il y en a (monnaies de
   l'arbre dans le relevé).
6. Rang lu = `currentRank`, points en attente compris : un point posé sans « Appliquer » fait avancer
   le halo et la bande ; `C_Traits.ConfigHasStagedChanges` est alors vrai et « Apprendre » demande de
   valider d'abord.
7. `C_ClassTalents.CommitConfig` renvoie `true` en cas de succès, et « Talent appris » ne s'affiche qu'à
   la fin de l'incantation d'application (`TRAIT_CONFIG_UPDATED`).
8. Les `specID` de Mainline correspondent à ceux de `GetSpecializationInfo` de Forever (sinon le build
   fourni est choisi par l'index de spé ; `/qf bug` affiche la ligne « Talent spec: group, index, specID »).
9. Placement de l'onglet, du bandeau et du halo dans la vraie fenêtre des talents.
10. Incantation d'application interrompue (bouger pendant « Apprendre ») : `CONFIG_COMMIT_FAILED` arrive,
    message d'échec, « Apprendre » reste disponible ; les points restent-ils en attente ?
11. Premier affichage des talents via la popup (« Ouvrir les talents ») puis sort lancé depuis le
    grimoire : pas d'action bloquée. Tant que le jeu n'a pas chargé la fenêtre des talents (pas encore
    ouverte depuis la connexion), « Ouvrir les talents » dit « Ouvre tes talents avec N » (touche lue
    des raccourcis).
12. Grotte livrée, entrée à confirmer : The Grizzled Den (Dun Morogh, [42, 55]) (la première : vérifier que le point mène bien à la grotte côté nain).
13. Grotte livrée, entrée à confirmer : Echo Ridge Mine ([47.8, 31.6]).
14. Grotte livrée, entrée à confirmer : Dustwind Cave ([52.8, 28.7]).
15. Grotte livrée, entrée à confirmer : Skull Rock ([55, 11]).
16. Grotte livrée, entrée à confirmer : Night Web's Hollow ([27, 59]).
   (Data/Caves.lua : entrées relevées dans des sources publiques ; le point doit montrer l'entrée avant d'entrer.)
17. Grottes non livrées : relever en jeu l'entrée réelle (la bouche) de Fargodeep Mine, Jasperlode Mine,
    The Venture Co. Mine et Shadowthread Cave. Les valeurs publiques sont un point d'exploration de quête
    ou un marqueur de sous-zone (voir `tools/caves/research.md`) ; pour la Venture Co. Mine, choisir aussi
    des PNJ qui ne vivent que dans la mine (ses PNJ ont des camps à ciel ouvert).
18. Grottes : dans une grotte, la carte du joueur reste celle de la zone (pas de sous-carte). Sinon
    `Caves:Track` ne voit pas le passage par l'entrée.
19. Grottes : `IsIndoors()` vaut vrai dans les grottes livrées (connexion ou pierre de foyer dans une grotte).
20. ShortestPath Forever expose bien `ShortestPathForever.API.NavigateRoute` (itinéraire entrée de la
    grotte puis cible) ; sans elle, seule l'entrée est confiée au calcul.
21. Métiers : coûts réels des rangs (`Professions.RANKS` : Apprenti 10 pc, Compagnon 5 pa, Expert 1 po,
    Artisan 5 po) et maximums renvoyés par `GetProfessionInfo` (75, 150, 225, 300).
22. Métiers : le maître le plus proche enseigne bien le rang Expert (sinon l'étape mène chez un maître
    qui ne l'a pas).
23. Équipement d'une paire (main droite puis main gauche) : le délai suffit en jeu (3 s pour voir la main
    droite en place, jusqu'à 30 s quand la confirmation de liaison est ouverte) ; `PLAYER_EQUIPMENT_CHANGED`
    arrive bien pour l'emplacement 16 et `StaticPopup_Visible("EQUIP_BIND")` voit la confirmation.

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

### Divers
- Marqueurs sur la carte du monde : préciser ce qui est voulu.
- Comparaison avec la route RestedXP : accès au dossier `RXPGuides` non accordé (fenêtre expirée) ;
  objectif = en tirer des règles pour le générateur, sans recopier leurs étapes.
- README anglais : la liste « First launch » parle encore du « mob panel » (les monstres sont
  maintenant sous l'objectif dans le suivi, comme dans la version française).
- CHANGELOG : ajouter les rappels de talents, `/qf talents`, le bouton d'objet de quête et StepGuard
  (les builds de talents y sont).
- Publier une release versionnée (tag `vX.Y.Z`) quand le jeu aura été testé.

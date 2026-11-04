# Builds de talents WoW Forever — état du relevé (4 novembre 2026)

## Référence des spellID

Les 50 talents de chaque classe ont été lus dans le calculateur Icy Veins (DOM : `input[data-talenturlid]`, `.tbctalent-talent-details[data-spell]`) puis comparés au calculateur Wowhead Forever (`.ctc-tree-talent` : rangée, colonne, rangs max, lien `/forever/spell=<id>`). Les deux sources donnent les mêmes spellID, positions et rangs max pour les 9 classes. Tous les ID des builds livrés sont donc vérifiés par deux sources. Table de référence : `raw/icyveins/capture-2026-11-04.txt`.

Règles vérifiées par script sur chaque fichier : palier n requiert (n−1)×5 points dans l'arbre, talent requis au rang max, jamais au-delà du rang max, 51 points au plus, un point par niveau à partir du 10.

## État par classe

| Classe | Wowhead (raw/wowhead) | Questify (raw/questify) | État |
|---|---|---|---|
| Chaman | Elemental (51, deux corrections documentées), Restoration (49, donjon) | Elemental-leveling, Restoration-dungeon, Enhancement-leveling | fait ; Enhancement Wowhead non livrable (arbre périmé) |
| Chasseur | BeastMastery (51) | BeastMastery-leveling, Marksmanship-leveling | fait ; Survie non traité (déconseillé avant 32 par Wowhead) |
| Voleur | aucun (pages Wowhead périmées) | Combat-leveling, Assassination-leveling, Subtlety-leveling | fait côté Questify, pas de source publiée valide |
| Paladin | Retribution (45, le guide s'arrête à 54), Protection (51, donjon) | Retribution-leveling | fait |
| Druide | Feral (51), FeralTank (51, donjon) | Feral-leveling | fait |
| Guerrier | Fury (51) | Fury-leveling | fait |
| Prêtre | Shadow (51) | Shadow-leveling | fait |
| Mage | Frost (24 points, niveaux 10-33 : le guide respé à 33) | Frost-leveling | fait |
| Démoniste | Affliction (51) | Affliction-leveling | fait |

Total : 11 builds Wowhead, 14 builds Questify. Les hash Icy Veins des 27 guides de leveling ont été décodés ; ils servent de comparaison dans les fiches, pas de livrable (dossier non demandé). Hash périmés (illisibles ou invalides avec l'arbre actuel) : Voleur ×3, Chasseur Maîtrise des bêtes et Précision, Chaman Amélioration, Paladin Vindicte.

## Ordre des builds Wowhead

Seuls les deux guides de Drakanthos (Chaman Élémentaire et Amélioration, 20 oct.) donnent des tableaux niveau par niveau ; les pages « leveling tips » du 4 novembre donnent un build final et une consigne en prose (« de haut en bas », talents à prendre d'abord). Pour celles-ci, l'ordre livré est ma lecture de la consigne, arbre par arbre et palier par palier, et les fiches le disent. Les liens calculateur Wowhead (`vkndmh…`) ont été décodés par position (ordre rangée puis colonne, `-` entre arbres) et recoupés avec les compteurs « x/y » affichés sur les pages.

## Incertitudes principales

1. Stormstrike (Chaman) : Wowhead (20 oct.) dit qu'il ne s'entraîne pas avant 40 ; Icy Veins, Method (3 nov.) et Warcraft Tavern le placent à 25. Les builds suivent 25. À vérifier en jeu.
2. Chaman Élémentaire Wowhead : le point « Lava Burst » du niveau 30 a été remplacé par Call of Thunder (même case, prérequis de Lightning Mastery) et Toughness 4/5 → 3/5 + Improved Lightning Shield 1/3 pour ouvrir le palier 4 d'Amélioration. Tout autre choix cassait le build.
3. Valeurs chiffrées des talents : seules les descriptions de rang 1 ont été lues (Icy Veins) et quelques valeurs max (tableaux Wowhead du Chaman) ; le theorycraft repose sur ces descriptions, pas sur des tests en jeu. Les talents liés à des capacités nouvelles (Shank/Flash of Steel, Poised/Composure, Holy Strike/Sacred Arbiter, Shadow Word: Death/Early Demise) sont évalués à l'aveugle.
4. Mage Givre Wowhead : seul le build 10-33 est livré ; le guide respé à 33 et le build 33-60 n'a pas d'ordre.
5. Voleur : aucune source publiée valide ; les trois builds sont du theorycraft pur.
6. Mobalytics répond 403 : non consulté. Reddit et Discord : aucune discussion avec ordre niveau par niveau trouvée par recherche web (4 nov.).
7. Les builds Icy Veins décodés ne sont pas des livrables ; leurs liens pointent pour partie vers un arbre antérieur au patch du 15 octobre.

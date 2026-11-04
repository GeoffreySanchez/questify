# Chasseur — builds de talents WoW Forever (relevé du 4 novembre 2026)

## Sources consultées

- Wowhead Forever, calculateur Chasseur (4 nov., identique à Icy Veins : 50 talents, mêmes spellID) : https://www.wowhead.com/forever/talent-calc/hunter
- Wowhead Forever, « Beast Mastery Hunter Leveling Guide » (Docoda, relu par Neteyes, mis à jour le 4 nov. 2026), build final 31/16/4 et consigne d'ordre « de haut en bas, Maîtrise des bêtes puis Précision » : https://www.wowhead.com/forever/guide/classes/hunter/beast-mastery/dps-leveling-tips
- Wowhead Forever, « Survival Hunter Leveling Guide » (4 nov. 2026) : déconseille Survie avant 32, build final 16/9/26 sans ordre : https://www.wowhead.com/forever/guide/classes/hunter/survival/dps-leveling-tips
- Icy Veins, guides de leveling Maîtrise des bêtes, Précision, Survie (17 oct. 2026) et leurs hash : https://www.icy-veins.com/wow-forever/beast-mastery-hunter-leveling
- Warcraft Tavern, « Hunter Leveling Guide » (Sponge, bêta niveau 30), liens calculateur `#?t=A1111144662aaaaaeeeefj`, `B222226666655588eeeeed`, `C111115544499988dddddg` : https://www.warcrafttavern.com/forever/guides/hunter-leveling/
- Method, « Hunter Leveling Guide and Talents » (jalons seulement) : https://www.method.gg/wow-forever/wow-forever-hunter-leveling-guide-and-talents

## Ce qui change dans l'arbre

- Careful Aim (1223984) : +20 % de l'Intelligence en puissance d'attaque par rang, palier 2 Précision.
- Summon Hawk (1293241) : faucon qui attaque 18 s, partage le temps de recharge d'Arcane Shot, profite d'Unleashed Fury et Ferocity.
- Lone Wolf (415370) existe, mais c'est l'inverse de ce qu'on veut en montée : le familier est l'assurance-vie du Chasseur.
- Intimidation requiert Bestial Swiftness, Frenzy requiert Ferocity 5/5, Bestial Wrath requiert Intimidation.

## Build Wowhead Maîtrise des bêtes (raw/wowhead/HUNTER-BeastMastery.json)

Build final de Docoda (31/16/4), déroulé selon sa consigne : Maîtrise des bêtes de haut en bas (10-40), puis Précision de haut en bas (41-56), puis Improved Tracking 4/5 (57-60). Le guide précise que Pathfinding, Improved Revive Pet ou Endurance Training sont interchangeables pour les trois points de remplissage, et que les deux points de Rapid Killing peuvent aller ailleurs.

Les builds Icy Veins (17 oct.) sont périmés : leur lien prend Pathfinding (palier 3) avec 5 points dans l'arbre.

Warcraft Tavern (bêta, 21 points) : Deadly Aspects 5, Focused Fire 2, Improved Revive Pet 2, Endurance Training 1, Unleashed Fury 5, Ferocity 4, Summon Hawk, Bestial Discipline 1 — proche de l'ordre Questify jusqu'à 30.

## Questify — Maîtrise des bêtes, montée en solo (35/16/0)

- 10-14 Deadly Aspects 5/5 : 10 % de chance par tir automatique de gagner 30 % de vitesse de tir 12 s, environ +10 % de dégâts à distance en continu.
- 15-16 Focused Fire 2/2 : +2 % sur tout, joueur et familier.
- 17-19 Endurance Training 3/5 : un familier qui tient, c'est zéro temps de réanimation ; remplissage le plus utile pour ouvrir le palier 3.
- 20-24 Unleashed Fury 5/5 : +15 % de dégâts du familier (et des faucons), la moitié des dégâts à ces niveaux.
- 25 Summon Hawk : dégâts supplémentaires à chaque recharge d'Arcane Shot.
- 26-30 Ferocity 5/5 : +10 % de critique familier et prérequis de Frenzy.
- 31 Bestial Swiftness (prérequis d'Intimidation, et le familier arrive plus vite sur la cible), 32 Intimidation (étourdissement 3 s, menace), 33-34 Bestial Discipline 2/2 (focus du familier).
- 35-39 Frenzy 5/5, 40 Bestial Wrath.
- 41-45 Lethal Attacks 5/5 (+5 % critique), 46-50 Careful Aim 5/5 (puissance d'attaque égale à l'Intelligence), 51-55 Efficiency 5/5 (mana), 56-57 Spirit Bond 2/2 (2 % de vie toutes les 10 s pour les deux), 58-59 Endurance Training 5/5, 60 Rapid Killing 1/2.

Talents jugés faibles : Improved Aspect of the Monkey (on ne se fait pas taper), Improved Mend Pet, Improved Revive Pet (ne vaut que si le familier meurt), Pathfinding (vitesse d'Aspect of the Cheetah, 3 % par rang), Hawk Eye, Improved Concussive Shot, Improved Stings (Serpent Sting est cher en mana).

Écarts : Wowhead met Endurance Training avant Focused Fire et garde Bestial Swiftness pour 20 ; Questify prend Focused Fire dès 15 et Summon Hawk dès 25 (Wowhead à 31, après Ferocity). Les trois points Survie de Wowhead (Improved Tracking) vont chez Questify dans Efficiency, qui fait durer le mana aux niveaux 50+.

## Questify — Précision, montée en solo (9/42/0)

Pour qui préfère tirer plus fort que faire travailler le familier ; on garde quand même le familier (pas de Lone Wolf).

- 10-14 Lethal Attacks 5/5, 15-19 Careful Aim 5/5 (le gain de puissance d'attaque le plus net de l'arbre), 20-21 Rapid Killing 2/2, 22-24 Improved Arcane Shot 3/5.
- 25 Trueshot Aura, 26-30 Mortal Shots 5/5 (bonus de critique à distance), 31-32 Rapid Recuperation (mana après un kill), 33-34 Improved Arcane Shot 5/5.
- 35-39 Ranged Weapon Specialization 5/5, 40 Sniper Shot.
- 41-45 Efficiency 5/5, 46-48 Barrage 3/3, 49-51 Hawk Eye 3/3, 52-56 Deadly Aspects 5/5, 57-58 Focused Fire 2/2, 59-60 Endurance Training 2/5.

Le build Icy Veins Précision est périmé (Pathfinding avec 9 points en Maîtrise des bêtes au niveau 51). Pas de build Wowhead Précision.

## Survie

Wowhead (4 nov.) déconseille Survie avant 32 (Strider Kick et Expose Prey arrivent au palier 5) ; pas de build Questify Survie, un build Maîtrise des bêtes est fourni à la place.

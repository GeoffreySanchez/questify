# Voleur — builds de talents WoW Forever (relevé du 4 novembre 2026)

## Sources consultées

- Wowhead Forever, calculateur Voleur (4 nov., identique à Icy Veins) : https://www.wowhead.com/forever/talent-calc/rogue
- Wowhead Forever, « Assassination Rogue Leveling Guide » et « Subtlety Rogue Leveling Guide » (4 nov. 2026) : les deux pages affichent l'avertissement Wowhead « build fait avant un changement d'arbre » avec des points non dépensés (Murder, Lethality, Seal Fate, Vile Poisons, Cold Blood, Improved Poisons, Mutilate, Ghostly Strike pour Assassinat ; Murder, Camouflage pour Finesse). Seul le conseil d'ouverture est exploitable : Efficient Strikes 2 et Remorseless Attacks 2 en premier, et Combat jusqu'à 30 (Assassinat) ou 18 (Finesse). https://www.wowhead.com/forever/guide/classes/rogue/assassination/dps-leveling-tips , https://www.wowhead.com/forever/guide/classes/rogue/subtlety/dps-leveling-tips
- Icy Veins, guides Combat / Assassinat / Finesse : les trois hash sont illisibles avec l'arbre actuel (Blade Flurry pris deux fois, Adrenaline Rush cinq fois…), donc périmés.
- Warcraft Tavern, « Rogue Leveling Guide » (Nevermore) : pas de lien calculateur, niveaux d'ouverture des talents seulement (Blade Flurry 30, Adrenaline Rush 40, Mutilate 30, Hemorrhage 30) : https://www.warcrafttavern.com/forever/guides/rogue-leveling/

Aucun build Wowhead valide : pas de fichier `raw/wowhead/ROGUE-*.json`.

## Ce qui change dans l'arbre

- Combat palier 1 : Efficient Strikes (13732, Sinister Strike et Hemorrhage −3 énergie par rang), Coup de Grace (Eviscerate +7 %/rang).
- Combat palier 2 : Puncturing Wounds (critique de Backstab/Mutilate) a remplacé Improved Backstab.
- Combat palier 3 : Endurance (Sprint et Evasion −30 % de recharge par rang), Composure (lié à Poised, capacité Forever du niveau 32).
- Combat palier 4 : Flawless Execution (Eviscerate −15 énergie), Weapon Expertise requiert Precision 3/3.
- Combat palier 5 : Dual Wield Specialization n'a que 2 rangs (+25 % par rang).
- Combat palier 6 : Flash of Steel (Shank, nouvelle capacité).
- Assassinat : Remorseless Attacks (+20 % de critique par rang sur le prochain générateur après un kill), Blood Splatter, Venom (prérequis de Mutilate), Relentless Strikes au palier 5.
- Finesse : Setup, Dirty Tricks (prérequis de Quick Getaway), Boot Knife au palier 6, Death Mark au palier 7 (requiert Preparation).

## Questify — Combat, montée en solo (10/41/0)

- 10-11 Efficient Strikes 2/2 : −6 énergie par Sinister Strike, un coup de plus toutes les trois barres.
- 12-13 Remorseless Attacks 2/2 : +40 % de critique sur le premier coup de chaque combat suivant un kill ; en montée on enchaîne les kills.
- 14-16 Coup de Grace 3/3 : Eviscerate +21 %.
- 17-19 Precision 3/3 : +3 % de toucher, prérequis de Weapon Expertise.
- 20-22 Deflection 3/3 puis 23 Riposte : avec 6 % de parade en plus, Riposte (150 % de l'arme + désarmement) part souvent contre les monstres qui tapent au corps à corps.
- 24-25 Endurance 2/2 : Sprint et Evasion presque deux fois plus souvent.
- 26 Lightning Reflexes 1/5 : point de remplissage pour atteindre 15.
- 27-29 Aggression 3/3 (+15 % Sinister Strike et Eviscerate), 30 Flawless Execution, 31-32 Weapon Expertise 2/2.
- 33-34 Dual Wield Specialization 2/2 (main gauche +50 %), 35 Blade Flurry, 36-40 Hack and Slash 5/5.
- 41-42 Flash of Steel 1-2, 43 Adrenaline Rush, 44-46 Flash of Steel 5/5.
- 47-51 Malice 5/5, 52-54 Ruthlessness 3/3, 55-56 Improved Kick, 57-58 Improved Sprint, 59-60 Lightning Reflexes 3/5.

Adrenaline Rush arrive à 43 au lieu de 40 : les trois points de Deflection (parade, Riposte) et les deux d'Endurance valent plus en solo que trois niveaux d'avance sur un temps de recharge de 5 min.

Talents jugés faibles : Improved Gouge, Improved Expose Armor, Improved Kick avant 55 (ne sert que contre les lanceurs), Composure (dépend de Poised, valeur inconnue), Improved Sprint avant la fin.

## Questify — Assassinat, montée en solo (40/11/0)

Mutilate n'arrive qu'à 40 (palier 7, requiert Venom) : jusque-là, on joue Sinister Strike avec les poisons.

- 10-11 Remorseless Attacks, 12-14 et 18-19 Malice 5/5, 15-17 Ruthlessness 3/3 (points de combo gratuits).
- 20-21 Lethality 2/2, 22-23 Vigor 2/2 (énergie max), 24 Improved Slice and Dice 1/3.
- 25 Cold Blood, 26-30 Vile Poisons 5/5, 31-35 Relentless Strikes 5/5 (énergie rendue par les finishers), 36 Venom, 37-39 Seal Fate 3/3, 40 Mutilate.
- 41-45 Improved Poisons 5/5, 46-47 Efficient Strikes, 48-50 Lightning Reflexes 3/5, 51-53 Puncturing Wounds 3/3 (Mutilate +5 % de critique par rang), 54-56 Precision 3/3, 57-58 Improved Slice and Dice 3/3, 59-60 Improved Expose Armor 2/2.

Wowhead conseille de rester Combat jusqu'à 30 puis de respé : sans respé, l'arbre Assassinat jusqu'à 30 (Malice, Ruthlessness, Lethality, Vigor, Vile Poisons) reste correct avec Sinister Strike.

## Questify — Finesse, montée en solo (12/5/34)

Build d'ouverture (Ambush) : chaque combat commence par un Ambush amplifié.

- 10-14 Opportunity 5/5, 15-17 Improved Ambush 3/3, 18-19 et 23 Camouflage 3/3, 20-22 Initiative 3/3, 24 Master of Deception 1/3.
- 25-27 Serrated Blades 3/3 (prérequis d'Hemorrhage), 28-29 Elusiveness 2/2 (Vanish plus souvent), 30 Hemorrhage, 31 Preparation, 32 Premeditation, 33-34 Dirty Tricks 2/2.
- 35-39 Boot Knife 5/5, 40 Death Mark, 41-42 Quick Getaway 2/2.
- 43-44 Remorseless Attacks, 45-49 Malice 5/5, 50-52 Ruthlessness 3/3, 53-54 Lethality 2/2, 55-56 Efficient Strikes 2/2 (Hemorrhage −6 énergie), 57-59 Coup de Grace 3/3, 60 Master of Deception 2/3.

Wowhead conseille Combat jusqu'à 18 (Ambush s'apprend à 18) puis respé ; ce build commence directement Finesse pour éviter la respé, avec Opportunity qui sert aussi à Backstab.

Talents jugés faibles : Setup, Ghostly Strike (un point de dégâts médiocre), Heightened Senses, Dirty Deeds en solo.

# Druide — builds de talents WoW Forever (relevé du 4 novembre 2026)

## Sources consultées

- Wowhead Forever, calculateur Druide (4 nov., identique à Icy Veins) : https://www.wowhead.com/forever/talent-calc/druid
- Wowhead Forever, « Feral Druid DPS Leveling Guide » (4 nov. 2026), build final 9/32/10, texte du build encore vide (« A bit of information and context to go here ») : https://www.wowhead.com/forever/guide/classes/druid/feral/dps-leveling-tips
- Wowhead Forever, « Feral Druid Tank Leveling Guide » (4 nov. 2026), deux builds finals (variante Restauration conseillée 0/34/17, variante Nature's Splendor 8/32/11) : https://www.wowhead.com/forever/guide/classes/druid/feral/tank-leveling-tips
- Icy Veins, guides Farouche (3 nov.), Équilibre, Restauration : https://www.icy-veins.com/wow-forever/feral-druid-leveling (le hash Farouche se décode mais place Primal Bite et Shifting Power à 40-41 sans Lacerate ; ordre non repris)
- Warcraft Tavern, « Druid Leveling Guide » (Luxrah), liens calculateur bêta (`B1111144222abb99ffeeeh22C222` pour Farouche ; ce hash est périmé, il prend trois rangs d'un talent à un rang) : https://www.warcrafttavern.com/forever/guides/druid-leveling/

## Ce qui change dans l'arbre

- Farouche palier 2 : Feral Swiftness (+15 % de vitesse en Chat et +2 % d'esquive par rang, 2 rangs).
- Palier 3 : Feral Charge (ours), Savage Fury (Claw, Rake, Shred, Maul, Swipe +5 %/rang), Sharpened Claws (+3 % critique/rang, 2 rangs).
- Palier 4 : Predatory Strikes (puissance d'attaque +50 % du niveau par rang), Lacerate (talent, requiert Savage Fury), Predatory Discipline (Ferocious Bite ne consomme plus l'énergie excédentaire), Blood Frenzy (requiert Sharpened Claws).
- Palier 5 : Leader of the Pack, Natural Instinct (bonus de critique +10 %/rang).
- Palier 6 : Rend and Tear (requiert Predatory Strikes 3/3), Natural Reaction.
- Palier 7 : Primal Bite (requiert Leader of the Pack), Shifting Power (mana → 40 énergie, requiert Predatory Discipline).
- Restauration palier 1-2 : Heart of the Wild (+2 % Int, Force en Chat +2 %/rang), Naturalist (+2 % de dégâts par rang).

## Builds Wowhead (raw/wowhead/DRUID-Feral.json, raw/wowhead/DRUID-FeralTank.json)

Les deux pages ne donnent qu'un build final ; l'ordre livré est l'arbre Farouche de haut en bas (Feral Charge à 22, Predatory Strikes 25-27, Leader of the Pack à 32, Rend and Tear 35-39, Primal Bite à 40), puis Restauration, puis Équilibre pour le build DPS. Le build tank reprend la variante Restauration conseillée par le guide (Reflection, Natural Shapeshifter, Bloom).

## Questify — Farouche (Chat), montée en solo (0/38/13)

Forme de Chat au niveau 20 : avant, on joue Ours et sorts, d'où Ferocity (Maul) et Furor en premier.

- 10-14 Ferocity 5/5 : Maul, Claw, Rake, Swipe −5 d'énergie ou de rage.
- 15-16 Feral Swiftness 2/2 : +30 % de vitesse en Chat, le talent de montée.
- 17-19 Furor 3/5 : énergie ou rage à chaque changement de forme.
- 20-21 Savage Fury 2/2 : +10 % sur les coups de Chat dès la forme obtenue.
- 22-23 Sharpened Claws 2/2 : +6 % de critique.
- 24 Feral Charge : interruption et rapprochement en Ours.
- 25-27 Predatory Strikes 3/3 : +150 % du niveau en puissance d'attaque.
- 28-29 Blood Frenzy 2/2 : points de combo supplémentaires sur critique.
- 30 Leader of the Pack, 31 Predatory Discipline, 32-33 Natural Instinct 2/2, 34 Furor 4/5.
- 35-39 Rend and Tear 5/5 : +15 % sur une cible qui saigne (Rake).
- 40 Primal Bite, 41 Shifting Power.
- 42-46 Heart of the Wild 5/5, 47-51 Naturalist 5/5 (+10 % de dégâts), 52 Furor 5/5, 53-55 Natural Shapeshifter 3/3 (changements de forme −30 % de mana), 56-58 Thick Hide 3/3, 59-60 Brutal Impact 2/2.

Talents jugés faibles en montée : Feral Instinct (Swipe et furtivité), Thick Hide avant 56, Lacerate (menace d'Ours : donjon), Natural Reaction (Ours), Shredding Attacks (Shred demande le dos de la cible), Genesis et Nature's Reach (Équilibre) pour un Chat.

Écarts : Wowhead prend Lacerate à 28 et met les 5 derniers points en Équilibre (Genesis) ; Questify remplace Lacerate et Genesis par Natural Shapeshifter, Thick Hide et Brutal Impact (Bash plus souvent). Icy Veins ne prend pas Lacerate non plus et finit en Équilibre.

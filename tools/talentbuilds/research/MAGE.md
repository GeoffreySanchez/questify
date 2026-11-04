# Mage — builds de talents WoW Forever (relevé du 4 novembre 2026)

## Sources consultées

- Wowhead Forever, calculateur Mage (4 nov., identique à Icy Veins) : https://www.wowhead.com/forever/talent-calc/mage
- Wowhead Forever, « Frost Mage Leveling Guide » (4 nov. 2026) : deux builds, « Levels 1-33 » (2/0/22, 24 points) et « Levels 33-60 » (0/0/33) avec respé conseillée à 33 ; Wand Specialization d'abord : https://www.wowhead.com/forever/guide/classes/mage/frost/dps-leveling-tips
- Icy Veins, guides Givre / Feu / Arcanes, hash valides : https://www.icy-veins.com/wow-forever/frost-mage-leveling
- Warcraft Tavern, « Mage Leveling Guide » (Nevermore) : Givre conseillé, niveaux d'ouverture (Ice Lance 20, Shatter 25, Fingers of Frost 30, Ice Barrier 40) : https://www.warcrafttavern.com/forever/guides/mage-leveling/

## Ce qui change dans l'arbre

- Givre : Ice Lance (1312002) talent de palier 3 (×4 sur cible gelée), Fingers of Frost (400647) au palier 5 (requiert Ice Lance), Winter's Chill retravaillé autour de Cone of Cold, Ice Barrier au palier 7 avec +15 % de dégâts de Givre et plus de pushback.
- Arcanes palier 1 : Wand Specialization 2 rangs, Improved Channeling, Arcane Resilience (armure selon l'Intelligence) ; palier 2 : Missile Barrage.

## Build Wowhead Givre (raw/wowhead/MAGE-Frost.json)

Seul le build « Levels 1-33 » est livré (24 points, niveaux 10 à 33) : le guide respé à 33 vers un build sans Wand Specialization ni Frostbite, ce qu'un ordre niveau par niveau ne peut pas représenter. Ordre d'après le guide : baguette d'abord, puis Givre de haut en bas (Ice Lance à 22, Shatter 29-31, Fingers of Frost 32-33).

## Questify — Givre, montée en solo (10/0/41)

Sans respé : la combinaison Frost Nova / Frostbite → Ice Lance avec Shatter est le moteur de dégâts du 20 au 40, puis Ice Barrier rend le Mage presque intouchable.

- 10-11 Wand Specialization 2/2 : la baguette finit les monstres gratuitement.
- 12-16 Improved Frostbolt 5/5 : −0,5 s d'incantation.
- 17-19 Frostbite 3/3 : 15 % de chance de geler sur chaque ralentissement, donc des cibles gelées pour Ice Lance.
- 20-21, 23-25 Ice Shards 5/5 : +100 % de bonus de critique de Givre.
- 22 Ice Lance : ×4 sur cible gelée.
- 26, 30-31 Frost Channeling 3/3 : −15 % de mana.
- 27-29 Shatter 3/3 : +50 % de critique sur cible gelée.
- 32-33 Fingers of Frost 2/2, 34 Cold Snap, 35-36 Permafrost 2/3.
- 37-41 Winter's Chill 5/5, 42 Ice Barrier.
- 43-45 Precision 3/3, 46-48 Improved Cone of Cold 3/3, 49 Permafrost 3/3, 50 Ice Block.
- 51-53 Arcane Resilience 3/3, 54-58 Arcane Concentration 5/5 (sorts gratuits), 59-60 Arctic Reach.

Talents jugés faibles : Frost Warding, Improved Frost Nova (Frostbite fait le travail), Improved Blizzard (groupe), Improved Channeling et Missile Barrage (Arcane Missiles n'est pas le sort de montée), Magic Absorption.

Écarts : Wowhead (1-33) prend Precision 20-21 et Ice Shards 23-27 avant Ice Lance à 22 et Shatter à 29 ; Questify prend Ice Lance dès 22 et Shatter 27-29. Icy Veins prend Precision 10-11 avant la baguette et Missile Barrage 17-18 : deux points Arcanes sans effet pour un Mage qui lance Frostbolt.

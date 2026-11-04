# Démoniste — builds de talents WoW Forever (relevé du 4 novembre 2026)

## Sources consultées

- Wowhead Forever, calculateur Démoniste (4 nov., identique à Icy Veins) : https://www.wowhead.com/forever/talent-calc/warlock
- Wowhead Forever, « Affliction Warlock Leveling Guide » (4 nov. 2026), build final 40/7/4 et logique (Corruption instantanée d'abord, Suppression, Unholy Power avant la Sayaad à 20, talents de drain fin 20, Siphon Life tard) : https://www.wowhead.com/forever/guide/classes/warlock/affliction/dps-leveling-tips
- Icy Veins, guides Affliction / Démonologie / Destruction, hash valides : https://www.icy-veins.com/wow-forever/affliction-warlock-leveling
- Warcraft Tavern, « Warlock Leveling Guide » (Zephan), Affliction conseillé, lien calculateur bêta 51 points `A00111112222266688999abbbcccccddhiiimmmmmB3333377C1111` (se décode avec l'arbre actuel : Improved Life Tap 10-11, Suppression 12-16, Improved Corruption 17-21, … Shadow Mastery 45-49, Unholy Power 50-54, Demonic Energies, Improved Shadow Bolt) : https://www.warcrafttavern.com/forever/guides/warlock-leveling/

## Ce qui change dans l'arbre

- Affliction : Soul Harvest (palier 2, régénération après un kill au Drain Soul), Improved Drains (palier 2), Pandemic (palier 3, critique des DoT), Malevolence (palier 4, critique d'Ombre), Wrack (palier 7, requiert Siphon Life).
- Démonologie : Unholy Power dès le palier 1, Demonic Energies (palier 2, le familier est soigné par les dégâts de sorts), Fel Vitality (+5 % de mana propre).

## Build Wowhead Affliction (raw/wowhead/WARLOCK-Affliction.json)

Build final 40/7/4 ordonné d'après le guide : Improved Corruption 10-14, Unholy Power 15-19 (avant la Sayaad à 20), Suppression 20-24, Improved Drains 25-27, puis Affliction de haut en bas, Siphon Life à 54, Demonic Energies et Improved Shadow Bolt en fin ; pas de Wrack.

## Questify — Affliction, montée en solo (41/10/0)

Le Démoniste ne s'arrête jamais si ses DoT tuent avant que le familier meure et si Drain Life compense la vie donnée par Life Tap.

- 10-14 Improved Corruption 5/5 : Corruption instantanée, on pose et on passe au suivant.
- 15-17 Improved Drains 3/3 : Drain Life +21 % dès son apprentissage à 14.
- 18-19 Improved Life Tap 2/2 : +20 % de mana par Life Tap.
- 20-24 Suppression 5/5 : +5 % de toucher sur les DoT, moins de menace pour le Marcheur du Vide.
- 25-26 Improved Bane of Agony 2/2, 27-28 Nightfall 2/2 (Shadow Bolt instantanés), 29 Amplify Curse.
- 30 Siphon Life, 31-33 Soul Siphon 3/3 (Drain Life +12 % avec trois effets d'Affliction).
- 34 Malevolence 1/5 : remplissage pour le palier 6.
- 35-39 Shadow Mastery 5/5, 40 Wrack.
- 41-43 Pandemic 3/3, 44-47 Malevolence 5/5, 48-50 Fel Concentration 3/3.
- 51-55 Demonic Embrace 5/5 (+15 % d'Endurance pour Life Tap), 56-58 Fel Vitality 3/3, 59-60 Demonic Energies 2/2 (le familier se soigne sur les dégâts de sorts).

Talents jugés faibles : Grim Reach, Soul Harvest (Drain Soul en fin de combat rallonge le combat), Curse of Exhaustion, Improved Health Funnel, Improved Imp, Improved Voidwalker (10 % sur des sorts secondaires).

Écarts : Wowhead prend Unholy Power 15-19 avant Suppression et Improved Drains, et ne prend pas Wrack ; Questify préfère Drain Life amélioré dès 15 et prend Wrack à 40. Icy Veins prend Demonic Embrace 31-35 avant Shadow Mastery.

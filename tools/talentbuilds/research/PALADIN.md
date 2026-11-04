# Paladin — builds de talents WoW Forever (relevé du 4 novembre 2026)

## Sources consultées

- Wowhead Forever, calculateur Paladin (4 nov., identique à Icy Veins) : https://www.wowhead.com/forever/talent-calc/paladin
- Wowhead Forever, « Retribution Paladin Leveling Guide » (4 nov. 2026), build final 12/5/28 à 45 points (« Required level: 54 ») et logique d'ordre : https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips
- Wowhead Forever, « Protection Paladin Leveling Guide » (4 nov. 2026), build final 0/32/19 : https://www.wowhead.com/forever/guide/classes/paladin/protection/tank-leveling-tips
- Icy Veins, guides Vindicte / Protection / Sacré : https://www.icy-veins.com/wow-forever/retribution-paladin-leveling (le hash Vindicte est périmé : il contient des caractères absents de la table actuelle)
- Warcraft Tavern, « Paladin Leveling Guide » (Passion) : images seulement, Vindicte conseillé pour les 20-30 premiers niveaux : https://www.warcrafttavern.com/forever/guides/paladin-leveling/

## Ce qui change dans l'arbre

- Vindicte palier 2 : Sanctified Judgement (1311074, Judgement rend 20 % du coût du sceau, 33 % de chance par rang) ; palier 3 Seal of Command (20375) ; palier 4 Sacred Arbiter (Holy Strike +20 % et rafraîchit les Judgements) ; palier 6 Champion of the Light (dégâts des sorts selon l'Intelligence) ; palier 7 Unsealed Wrath (requiert Repentance).
- Vengeance requiert Seal of Command ; Two-Handed Weapon Specialization n'a que 3 rangs.
- Sacré palier 2 : Reverence (régénération en incantant), Improved Seals (+3 % sceaux et Judgements par rang).

## Build Wowhead Vindicte (raw/wowhead/PALADIN-Retribution.json)

Build final à 45 points (le guide s'arrête au niveau 54), ordonné d'après le texte du guide : Benediction d'abord (mana des sceaux et Judgements), Pursuit of Justice et Seal of Command dès le palier 3, Sanctified Judgement, puis le reste de Vindicte de haut en bas ; Unsealed Wrath volontairement absent (le guide le juge peu rentable en mana) ; le Sacré (Divine Strength, Reverence, Improved Seals, Holy Conduit) puis Divine Intellect ferment la marche.

## Build Wowhead Protection, donjon (raw/wowhead/PALADIN-Protection.json)

Build final 0/32/19 ordonné d'après le guide : Pursuit of Justice 2/2 au niveau 21 via Benediction, Conviction et Improved Judgement, puis Protection de haut en bas (Holy Shield à 42, Shieldsworn à 53), et les 7 derniers points Vindicte (Sanctified Judgement, Vindication, Sacred Arbiter).

## Questify — Vindicte, montée en solo (12/0/39)

Le Paladin en montée manque de mana, pas de dégâts : les premiers points réduisent les coûts, puis viennent les gros gains de dégâts dès qu'ils s'ouvrent.

- 10-14 Benediction 5/5 : sceaux et Judgements −10 %.
- 15-17 Conviction 3/3 : +6 % de critique.
- 18-19 Improved Judgement 2/2 : Judgement toutes les 8 s.
- 20 Seal of Command : le saut de dégâts du niveau 20.
- 21-22 Pursuit of Justice 2/2 : +16 % de vitesse, soit moins de temps entre deux quêtes.
- 23-25 Sanctified Judgement 3/3 : le mana revient avec chaque Judgement.
- 26-28 Two-Handed Weapon Specialization 3/3 : +6 % de dégâts.
- 29-30 et 35 Vindication 3/3 : remplissage de palier 3 qui réduit aussi les dégâts reçus.
- 31-33 Vengeance 3/3 : +5 % après un critique, cumulable.
- 34 Repentance : contrôle d'un humanoïde, prérequis d'Unsealed Wrath.
- 36-40 Champion of the Light 5/5 : dégâts de sorts (Judgement, Exorcism, Consecration) selon l'Intelligence.
- 41-45 Divine Strength 5/5, 46-50 Improved Seals 5/5 (+15 % sceaux et Judgements).
- 51 Unsealed Wrath, 52 Sacred Arbiter, 53-54 Reverence, 55-56 Eye for an Eye, 57-60 Deflection 4/5.

Talents jugés faibles : Deflection avant la fin, Unyielding Faith, Turn Evil, Eye for an Eye (dégâts subis uniquement sur critique), Spiritual Focus, Purifying Power.

Écarts : Wowhead prend Vindication 26-28 avant Two-Handed Weapon Specialization et s'arrête à 54 ; Questify prend l'arme à deux mains d'abord et remplit jusqu'à 60. Icy Veins (lien périmé) n'est pas comparable.

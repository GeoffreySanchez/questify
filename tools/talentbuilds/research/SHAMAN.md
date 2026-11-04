# Chaman — builds de talents WoW Forever (relevé du 4 novembre 2026)

## Sources consultées

- Wowhead Forever, calculateur Chaman (données du 4 nov., identiques à Icy Veins pour les 50 talents : mêmes spellID, mêmes positions, mêmes rangs) : https://www.wowhead.com/forever/talent-calc/shaman
- Wowhead Forever, « Elemental Shaman Leveling Guide » (Drakanthos, mis à jour le 20 oct. 2026, patch 1.60.1), tableaux niveau par niveau : https://www.wowhead.com/forever/guide/elemental-shaman-leveling-guide-for-wow-forever-35069
- Wowhead Forever, « Enhancement Shaman Leveling Guide » (Drakanthos, 20 oct. 2026) : https://www.wowhead.com/forever/guide/enhancement-shaman-leveling-guide-for-wow-forever-35070
- Wowhead Forever, « Restoration Shaman Leveling Guide » (mis à jour le 4 nov. 2026, build final 0/8/41, 49 points) : https://www.wowhead.com/forever/guide/classes/shaman/restoration/healer-leveling-tips
- Icy Veins, calculateur et guides de leveling Élémentaire / Amélioration / Restauration (hash du lien « Open in Calculator ») : https://www.icy-veins.com/wow-forever/elemental-shaman-leveling, https://www.icy-veins.com/wow-forever/enhancement-shaman-leveling, https://www.icy-veins.com/wow-forever/restoration-shaman-leveling
- Warcraft Tavern, « Shaman Leveling Guide » (Shadostruct, builds bêta niveau 30-35) et ses liens calculateur `#?t=` (un caractère par point, caractère = slot de grille) : https://www.warcrafttavern.com/forever/guides/shaman-leveling/
- Method, « WoW Forever Shaman Leveling Guide and Talents » (Erik, 3 nov. 2026) : jalons seulement (Stormstrike à 25, puis Loup fantôme amélioré) : https://www.method.gg/wow-forever/wow-forever-shaman-leveling-guide-and-talents
- Mobalytics : répond 403 aux requêtes, non lu.

## État de l'arbre au 4 novembre

- Lava Burst n'est plus un talent : les deux calculateurs (Wowhead, Icy Veins) ont Call of Thunder (16120, palier 5, colonne 2) à sa place, et le talent de palier 7 est Lightning Mastery (16166, ex-« Elemental Mastery »), qui requiert Call of Thunder.
- Improved Ghost Wolf est au palier 4 (15 points en Amélioration), plus au palier 2. Toute source qui le prend avant 15 points en Amélioration est antérieure au dernier patch.
- Water Shield (408510) est un talent de palier 3 Restauration : 2 % du mana max par globe quand on est touché ou qu'un sort est critique.

## Build Wowhead Élémentaire (raw/wowhead/SHAMAN-Elemental.json)

Branche A du guide Drakanthos (31/20/0), avec deux corrections rendues nécessaires par l'arbre actuel, documentées ici :

- Le point « Lava Burst » du niveau 30 est devenu Call of Thunder (16120) : même case de l'arbre, et ce talent est le prérequis de Lightning Mastery que le guide prend à 40. Le guide lui-même dit que ce point était Call of Thunder avant le patch du 15 octobre.
- Côté Amélioration, le guide prend Improved Ghost Wolf à 51-52 après seulement 10 points (ancienne position palier 2). Avec 14 points aux paliers 1-3 (Thundering Strikes 5, Ancestral Knowledge 5, Shamanistic Focus, Anticipation 3), le palier 4 est inaccessible : j'ai remplacé un point de Toughness (4/5 → 3/5) par Improved Lightning Shield 1/3 à 55 pour ouvrir le palier 4, puis Improved Ghost Wolf 56-57 et Toughness 58-60.

La branche B (38/13/0, « community ») n'est pas livrée : elle contient le même point Lava Burst et prend Improved Ghost Wolf avec 10 points en Amélioration, et Wowhead la présente comme une reprise d'un build communautaire.

## Build Wowhead Restauration (raw/wowhead/SHAMAN-Restoration.json)

Build final du guide « healer-leveling-tips » (4 nov.), 49 points car Wowhead signale lui-même le point d'Improved Ghost Wolf « non dépensé » après le changement d'arbre. L'ordre n'est pas donné niveau par niveau ; j'ai suivi l'indication du guide (Tidal Focus, Mindfulness et Water Shield en premier) puis l'arbre de haut en bas, Amélioration en dernier.

## Build Wowhead Amélioration : non livrable

Les deux branches du guide (17/34/0 et 8/33/10) ont 8 ou 10 points aux paliers 1-2 et 4 au palier 3 : avec Improved Ghost Wolf désormais au palier 4, aucune des deux n'atteint les 15 points nécessaires à Stormstrike, Flurry et Improved Ghost Wolf. Il faudrait changer la liste des talents, pas seulement l'ordre, donc pas de fichier `wowhead/SHAMAN-Enhancement.json`. Le build Questify ci-dessous reprend les mêmes idées avec un arbre valide.

## Questify — Élémentaire, montée en solo (31/9/11)

Principe : en solo, l'Élémentaire tue à l'Éclair (Lightning Bolt) et perd son temps à boire. Les points vont d'abord à ce qui raccourcit le combat, puis à ce qui raccourcit la pause.

- 10-14 Concussion 5/5 : +5 % sur Lightning Bolt, Chain Lightning et Earth Shock, le seul talent de palier 1 qui augmente directement les dégâts.
- 15-17 Elemental Alacrity 3/3 : −0,5 s sur un Éclair de 2,5-3 s, soit 17 à 20 % de dégâts par seconde en plus ; c'est aussi le prérequis de Lightning Overload.
- 18-19, 21 Call of Flame 3/3 : +15 % sur Flame Shock, Searing Totem et Fire Nova, et Flame Shock dure 9 s de plus (ticks supplémentaires gratuits).
- 20 Elemental Focus : un sort gratuit sur dix dès que le palier 3 ouvre.
- 22-24 et 26-27 Convection 5/5 : −10 % de mana sur tout ce qu'on lance, premier levier contre le temps mort.
- 25 Earthbound : Earthbind Totem enracine 5 s à la pose, ce qui vaut deux Éclairs de plus avant le corps à corps, pour un seul point.
- 28-29 et 34 Eye of the Storm 3/3 : les monstres frappent pendant qu'on incante ; 70 % de pushback en moins.
- 30 Call of Thunder : critique sur l'Éclair et prérequis de Lightning Mastery.
- 31-33 Lightning Overload 3/3 : 10 % de chance d'un Éclair à demi-dégâts gratuit, +5 % de dégâts moyens sans mana.
- 35-39 Elemental Fury 5/5 : bonus de critique doublé ; avec 10-15 % de critique, +10 à +15 % de dégâts.
- 40-44 Tidal Focus 5/5 : +5 % de toucher, donc moins d'Éclairs ratés (chaque raté coûte le mana et le temps d'incantation).
- 45-47 Mindfulness 3/3 : 51 % de la régénération continue en incantant.
- 48-49 Improved Reincarnation 2/2 : +4 % de vie et Reincarnation toutes les 40 min au lieu de 60, utile en solo ; ce sont les deux points les moins faibles du palier 2 Restauration pour ouvrir Water Shield.
- 50 Water Shield : 2 % du mana max par coup reçu ou par critique, souvent 4 à 6 % de mana par combat.
- 51-55 Thundering Strikes 5/5 : +5 % de critique, doublé par Elemental Fury.
- 56-59 Ancestral Knowledge 4/5 : réserve de mana.
- 60 Lightning Mastery : repoussé en dernier, c'est un temps de recharge de 3 min, pas un gain continu.

Talents jugés faibles en montée : Elemental Devastation (critique en mêlée, inutile à distance), Elemental Warding, Reverberation (−1 s sur les Shocks à 5 points, un Shock par combat en solo), Elemental Reach (+6 m, bon mais derrière Earthbound), Trial by Fire (Fire Nova n'est pas un sort de solo), Guardian Totems, Natural Grace, Totemic Focus.

Écarts : Icy Veins suit presque le même ordre jusqu'à 40 (il prend Trial by Fire 26-27 et Lightning Mastery à 40) puis va aussi chercher Water Shield à 51 ; Questify avance le paquet Restauration de dix niveaux et repousse Lightning Mastery à 60. Wowhead (Drakanthos) prend Call of Flame avant Alacrity, met Convection à 24-28 et ne touche pas à Restauration : il préfère Shamanistic Focus et Anticipation ; sans Water Shield ni Mindfulness, le temps mort reste le problème numéro un de l'Élémentaire.

## Questify — Restauration, donjon (0/10/41)

- 10-14 Tidal Focus 5/5 : mana des soins −5 % et +5 % de toucher pour les quelques sorts offensifs.
- 15-17 Mindfulness 3/3 : régénération en incantant, le talent de mana du soigneur.
- 18-19, 21-23 Improved Healing Wave 5/5 : Healing Wave 0,5 s plus rapide, le soin principal avant Chain Heal.
- 20 Water Shield : dès 10 points, mana sur chaque critique de soin.
- 24 Totemic Focus 1/5 : un point pour atteindre le palier 4.
- 25 Mana Tide Totem ; 26-29 et 34 Tidal Mastery 5/5 ; 30 Nature's Swiftness ; 31-33 Healing Way 3/3 ; 35-39 Purification 5/5 ; 40 Riptide.
- 41-43 Ancestral Healing 3/3 (armure du tank +24 % sur critique), 44-48 Restorative Totems 5/5, 49-50 Healing Focus 2/3.
- 51-55 Thundering Strikes 5/5 (critique de soin), 56-60 Ancestral Knowledge 5/5.

Écart : Icy Veins va chercher Thundering Strikes à 46-50 avant Restorative Totems ; Wowhead (4 nov.) ne prend ni Totemic Focus ni Improved Reincarnation, et termine 0/8/41 avec 49 points.

## Questify — Amélioration, montée en solo (8/43/0)

- 10-14 Thundering Strikes 5/5 (+5 % critique), 15-17 Mental Dexterity 3/3 (puissance d'attaque égale à l'Intelligence), 18-19 Ancestral Knowledge 2/5 pour ouvrir le palier 3.
- 20 Shamanistic Focus (Shocks et Lightning Shield −45 % de mana), 21-23 Elemental Weapons 3/3 (Rockbiter +20 %, Windfury +40 %), 24 Anticipation 1/3 pour ouvrir le palier 4.
- 25 Stormstrike, 26-27 Improved Ghost Wolf 2/2 (instantané, utilisable en intérieur), 28-32 Flurry 5/5.
- 33-34 Mental Quickness, 35-36 Improved Stormstrike, 37-41 Maelstrom Weapon 5/5, 42 Rage of the Farseer.
- 43-45 Ancestral Knowledge 5/5, 46-47 Anticipation 3/3, 48-52 Concussion 5/5 (Earth Shock et les Éclairs Maelstrom), 53-55 Elemental Devastation 3/3, 56-60 Toughness.

Incertitude : Wowhead (20 oct.) affirme que Stormstrike ne s'entraîne pas avant le niveau 40 ; Icy Veins, Method (3 nov.) et Warcraft Tavern le placent à 25. Le build suit la majorité ; si Wowhead a raison, le point du niveau 25 reste inutilisé jusqu'à 40.

Talents jugés faibles : Earth's Grasp, Guardian Totems, Improved Lightning Shield (bouclier qui tombe vite en mêlée), Spirit Weapons (menace, parade : donjon), Elemental Weapons au-delà de 3 (pas de rang), Toughness avant 55.

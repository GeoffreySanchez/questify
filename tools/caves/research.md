# Grottes et mines des routes Questify : recherche

Données jointes : `caves.json` (même dossier). 22 grottes listées, 10 avec une entrée sourcée (dont 3 points d'exploration de quête), 12 sans (`entrance: null`).

**Livrées dans `Questify/Data/Caves.lua` (ruling F2-quinquies) : 5** — The Grizzled Den, Echo Ridge Mine, Dustwind Cave, Skull Rock, Night Web's Hollow. Champ `shipped` de `caves.json` : `true` pour ces 5, `false` pour les autres. Écartées malgré une entrée sourcée : Fargodeep Mine, Jasperlode Mine, The Venture Co. Mine, Shadowthread Cave (raison dans leur section, « Non livrée ») et Boulderslide Cavern (confiance basse).

## Méthode et limites

- Routes lues : `Questify/Guides/Alliance/*.lua` et `Horde/*.lua`. Zones : Coldridge, Dun Morogh, Loch Modan, Westfall, Northshire, Elwynn, Shadowglen, Teldrassil, Darkshore, Ashenvale, Stonetalon, Redridge, Duskwood, Wetlands, Hillsbrad, Valley of Trials, Durotar, Camp Narache, Mulgore, Barrens, Thousand Needles, Deathknell, Tirisfal, Silverpine. Les chapitres Zephras Isle (Skyborne) sont du contenu Forever sans source publique (« Free the Hollows », « The Fate of the Den ») : non traités.
- Les PNJ et objets viennent de la copie locale de QuestieDB (`.cache/questiedb/data/Forever/*.lua`). Pour chaque grotte, j'ai listé les spawns dans une boîte autour des mobs de la grotte et gardé ceux qui y sont entièrement ou presque. Les mobs partagés avec l'extérieur sont signalés.
- Les coordonnées d'entrée sont rares dans les sources publiques. Les wikis (warcraft.wiki.gg, Wowpedia) donnent seulement un texte de localisation ou le marqueur de la sous-zone. Wowpedia et wowwiki-archive (fandom) renvoient 402 à WebFetch : leurs valeurs viennent de résumés de recherche, pas d'une lecture directe de la page. Aucune source payante (RestedXP, Joana, Sage, Guidelime) n'a servi.
- Certaines valeurs sont un « point d'exploration » de quête (objectif « Explore X ») de QuestieDB, projet public. Ce point est dans la grotte, près de l'entrée, pas devant la bouche. Il est repris par games.gg. Je le signale à chaque fois.
- Je n'ai rien deviné : quand aucune source ne donne l'entrée, `entrance` vaut `null` et je donne, à titre d'indice, la zone occupée par les spawns.
- Le guide games.gg « WoW Forever » semble en partie généré à partir de QuestieDB. Ses coordonnées de mobs coïncident avec la base. Je le traite comme faible indépendance.

## uiMapID

| Zone | uiMapID | Contrôle |
|---|---|---|
| Dun Morogh | 1426 | donné, utilisé dans les guides |
| Elwynn Forest | 1429 | donné, utilisé dans les guides |
| Westfall | 1436 | donné, utilisé dans les guides |
| Loch Modan | 1432 | donné, utilisé dans les guides |
| Teldrassil | 1438 | donné, utilisé dans les guides |
| Darkshore | 1439 | donné, utilisé dans les guides |
| Durotar | 1411 | donné, utilisé dans les guides |
| Mulgore | 1412 | donné, utilisé dans les guides |
| Tirisfal Glades | 1420 | donné, utilisé dans les guides |
| The Barrens | 1413 | donné, utilisé dans les guides |
| Silverpine Forest | 1421 | donné, utilisé dans les guides |
| Redridge Mountains | 1433 | donné, utilisé dans les guides |
| Duskwood | 1431 | présent dans les guides (`at = { 1431 ...`) |
| Wetlands | 1437 | présent dans les guides |
| Ashenvale | 1440 | présent dans les guides |
| Stonetalon Mountains | 1442 | présent dans les guides |
| Hillsbrad Foothills | 1424 | présent dans les guides |
| Thousand Needles | 1441 | présent dans les guides |

Remarque : la page warcraft.wiki.gg/wiki/UiMapID donne les anciens identifiants (Dun Morogh 27, Elwynn 37, etc.), qui ne sont pas ceux de ce client. J'ai gardé la série 14xx.

---

## Dun Morogh (uiMapID 1426)

### Frostmane Hovel, « The Troll Cave » (Coldridge Valley) : `dunmorogh_frostmane_hovel`
- Zone : Dun Morogh, vallée de Coldridge. uiMapID 1426.
- Entrée : **aucune source publique**. Le wiki appelle la grotte « Frostmane Hovel » et la situe au sud de Coldridge Valley, « dans la grotte au sud-est » pour la quête voisine « Ice and Fire ». Le wiki donne Grik'nir à [37.2, 78.4] (https://warcraft.wiki.gg/wiki/Grik%27nir_the_Cold). QuestieDB et games.gg le placent à [30, 80]. Les deux se contredisent, je fais confiance à QuestieDB (cohérent avec la route : `complete 182 at 28.79, 80.25`).
- Indice (QuestieDB, pas une source) : whelps x 20 à 31, y 75 à 83. Entrée vraisemblable à l'ouest de cette zone, à vérifier.
- PNJ : Frostmane Troll Whelp 706 (63 spawns, tous dans la boîte), Grik'nir the Cold 808. Objet : Battered Chest 2843 (le « Felix's Chest » de games.gg, [22.8, 80.0]).
- Aussi présents : Rockjaw Trogg 707 et Burly Rockjaw Trogg 724 sont à moitié dehors, non retenus. Grelin Whitebeard 786 et Apprentice Soren 1354 sont des donneurs de quête, non retenus.
- Utilisé par : chapitre Coldridge Valley (A_DwarfGnome_01), quête 182 « The Troll Cave ».
- Confiance : basse (entrée inconnue).

### The Grizzled Den : `dunmorogh_grizzled_den`
- Zone : Dun Morogh. uiMapID 1426.
- Entrée : **[42, 55]**, « grande grotte au sud-ouest de Kharanos ». Source : article « Grizzled Den » sur classic-wow-archive.fandom.com et wowwiki-archive.fandom.com (valeur lue via résumé de recherche ; page non lisible directement, erreur 402). Autres sources textuelles : « à l'ouest de Kharanos » (quête 313), « au sud-ouest de la ville, descendre la colline vers l'ouest » (https://warcraft.wiki.gg/wiki/Culling_the_Wendigos). Un résumé de recherche a aussi cité [42, 54].
- Contrôle QuestieDB : les Young Wendigo (1134) sont au sud, vers [42.5, 55.5], donc devant la bouche. Les Wendigo (1135) partent de [42.4, 55.2] et montent vers le nord (y jusqu'à 45). Edan the Howler 1137 à [42.6, 50.3] et [39, 47.5] (rare, grande salle du fond). Old Icebeard 1271 à [38.5, 54.2] (chemin latéral). Cela confirme l'entrée vers [42, 55].
- Sources :
  - https://warcraft.wiki.gg/wiki/Culling_the_Wendigos
  - https://warcraft.wiki.gg/wiki/Old_Icebeard (Old Icebeard [38.5, 53.9], PNJ 1271)
  - https://warcraft.wiki.gg/wiki/Frosthowl (Frosthowl [39.6, 48.6], variante Forever)
  - https://games.gg/world-of-warcraft/guides/wow-forever-dun-morogh/ (grotte [38.5, 54.2] pour Old Icebeard)
- PNJ : Wendigo 1135, Edan the Howler 1137, Old Icebeard 1271. Young Wendigo 1134 : à la bouche (le wiki les place dehors), non inclus dans `npcs`, à ajouter si l'on veut englober la bouche. Aucun objet propre à la grotte (Copper Vein 1731 et Battered Chest 106318 sont partagés avec le reste de la zone).
- Utilisé par : chapitre Dun Morogh (A_DwarfGnome_02), quête 313 « The Grizzled Den ».
- Confiance : moyenne (valeur ponctuelle, sans précision sur le point exact, mais cohérente avec la base).

### Frostmane Hold : `dunmorogh_frostmane_hold`
- Zone : Dun Morogh (Chill Breeze Valley), grotte en bordure ouest. uiMapID 1426.
- Entrée : **aucune source publique**. https://warcraft.wiki.gg/wiki/Frostmane_Hold dit « grotte de montagne sur la bordure ouest, au sud de Gnomeregan / New Tinkertown » sans coordonnées. Le point d'exploration de la quête 287 (QuestieDB, valeur non reprise ici) est au cœur du repaire, où se trouve Great Father Arctikus. Ce n'est pas l'entrée.
- Indice : trolls x 20 à 28, y 49 à 57.
- PNJ : Frostmane Troll 1120, Hideskinner 1122, Headhunter 1123, Shadowcaster 1124, Great Father Arctikus 1260. Les Frostmane Snowstrider 1121 sont à moitié dehors, non retenus.
- Utilisé par : chapitre Dun Morogh, quête 287 « Frostmane Hold ».
- Confiance : basse.

### Gol'Bolar Quarry Mine : `dunmorogh_golbolar_quarry_mine`
- Zone : Dun Morogh, sud-est. La carrière est à ciel ouvert ([69, 59]) ; la mine est une sous-zone fermée au cœur de la carrière. uiMapID 1426.
- Entrée : **aucune source publique** (https://warcraft.wiki.gg/wiki/Gol%27Bolar_Quarry_Mine, sans coordonnées ; un commentaire Wowhead parle d'une rampe, sans coordonnées).
- Indice : Bonesnapper à [77.8, 53.4] dans la mine (wiki). Spawns QuestieDB : x 70 à 81, y 50 à 62.
- PNJ : Rockjaw Bonesnapper 1117, Backbreaker 1118, Hammerspine 1119 (rare au fond). Les Skullthumper 1115 sont en surface, non retenus.
- Utilisé par : chapitre Dun Morogh, quêtes 432 « Those Blasted Troggs! » (en surface) et 433 « The Public Servant » (Bonesnappers).
- Confiance : basse. À arbitrer : cette mine est-elle assez enfermée pour justifier un routage ?

### Non retenus
- The Mountain Den (nord-est de South Gate Outpost) : « n'abrite aucun PNJ » (https://warcraft.wiki.gg/wiki/Mountain_Den), aucune quête.

## Elwynn Forest (uiMapID 1429)

### Echo Ridge Mine : `elwynn_echo_ridge_mine`
- Zone : nord-ouest de Northshire Valley, dans Elwynn. uiMapID 1429.
- Entrée : **[47.8, 31.6]**. Source : https://games.gg/world-of-warcraft/guides/wow-forever-elwynn-forest/ ; texte de localisation sur https://warcraft.wiki.gg/wiki/Echo_Ridge_Mine (aucune coordonnée).
- Contrôle QuestieDB : Kobold Laborer 80 sur x 47 à 50, y 26 à 32. L'entrée au sud de cette zone est cohérente.
- PNJ : Kobold Laborer 80. Kobold Worker 257 est mixte (20 spawns sur 45 dans la boîte), non inclus ; il sert la quête 15. Pas d'objet.
- Utilisé par : chapitre Northshire (A_Human_01), quêtes 15 « Investigate Echo Ridge », 21 « Skirmish at Echo Ridge ».
- Confiance : moyenne.

### Fargodeep Mine : `elwynn_fargodeep_mine`
- Zone : sud d'Elwynn. uiMapID 1429.
- Entrée : **non retenue**. La seule valeur trouvée est le point d'exploration de la quête 62 « The Fargodeep Mine » (QuestieDB, non reprise ici), recopié par https://games.gg/world-of-warcraft/guides/wow-forever-elwynn-forest/ ; il est dans la mine, pas devant la bouche. Wiki : https://warcraft.wiki.gg/wiki/Fargodeep_Mine (sans coordonnées).
- Contrôle : Kobold Tunneler 475 (39 spawns, x 36 à 42, y 78 à 87), Goldtooth 327 à [42, 78], Narg the Taskmaster 79 à [41, 78].
- PNJ : Kobold Tunneler 475, Narg the Taskmaster 79, Goldtooth 327. Kobold Miner 40 est partagé avec Jasperlode et Elwynn.
- Utilisé par : chapitre Elwynn Forest (A_Human_02), quêtes 62 « The Fargodeep Mine », 60 « Kobold Candles ».
- Confiance : moyenne (c'est le point d'exploration, dans la mine, pas devant la bouche).
- **Non livrée.** La valeur est le point d'exploration QuestieDB de la quête 62 : il est dans la mine, pas devant la bouche, et games.gg ne fait que le reprendre. C'est une donnée QuestieDB : ne pas la reprendre dans les fichiers livrés. À relever en jeu (bouche réelle).

### Jasperlode Mine : `elwynn_jasperlode_mine`
- Zone : est d'Elwynn. uiMapID 1429.
- Entrée : **non retenue**. La seule valeur trouvée est le point d'exploration de la quête 76 « The Jasperlode Mine » (QuestieDB, non reprise ici), recopié par games.gg ; il est dans la mine. Un résumé de recherche cite aussi « environ [61, 53] » (non confirmé). https://warcraft.wiki.gg/wiki/Jasperlode_Mine : sans coordonnées.
- Contrôle : Mine Spider 43 (8/8) x 60 à 62, y 47 à 49 ; Mother Fang 471 à [62, 48] ; Kobold Geomancer 476.
- PNJ : Mine Spider 43, Mother Fang 471, Kobold Geomancer 476. Kobold Miner 40 est partagé.
- Utilisé par : chapitre Elwynn Forest, quête 76.
- Confiance : moyenne.
- **Non livrée.** La valeur est le point d'exploration QuestieDB de la quête 76 (repris par games.gg) : dans la mine, pas devant la bouche, et mal attribuée comme entrée. C'est une donnée QuestieDB : ne pas la reprendre dans les fichiers livrés. À relever en jeu (bouche réelle).

## Westfall (uiMapID 1436)

### Jangolode Mine : `westfall_jangolode_mine`
- Zone : nord de Saldean's Farm et de Sentinel Hill. uiMapID 1436.
- Entrée : **aucune source publique** (https://warcraft.wiki.gg/wiki/Jangolode_Mine ; guide https://allthings.how/the-state-of-the-mines-walkthrough-in-wow-forever/ : texte seul).
- Indice (QuestieDB) : Kobold Digger 1236 sur x 45 à 46, y 18 à 23 ; Master Digger 1424 à [46, 19].
- PNJ : Kobold Digger 1236, Master Digger 1424.
- Utilisé par : chapitre Westfall (A_Human_03 et A_DwarfGnome_04), quête « The State of the Mines » (4 Kobold Diggers dans Jangolode).
- Confiance : basse.

### Gold Coast Quarry : `westfall_gold_coast_quarry`
- Zone : ouest de Westfall. uiMapID 1436. Ancienne carrière à ciel ouvert avec galeries ; on ignore si une partie est fermée.
- Entrée : **aucune source publique** (https://warcraft.wiki.gg/wiki/Gold_Coast_Quarry).
- Indice : Riverpaw Miner 1426 (8 spawns) sur x 29 à 31, y 45 à 51.
- PNJ : Riverpaw Miner 1426.
- Utilisé par : même quête « The State of the Mines » (6 Riverpaw Miners dans la carrière).
- Confiance : basse. Candidat à écarter s'il n'y a pas de bouche.

## Loch Modan (uiMapID 1432)

### Silver Stream Mine : `lochmodan_silver_stream_mine`
- Zone : nord de Loch Modan, à l'est d'Algaz Station, au sud-ouest de Stonewrought Dam. uiMapID 1432.
- Entrée : **aucune source publique** (https://warcraft.wiki.gg/wiki/Silver_Stream_Mine, texte seul).
- Indice (QuestieDB) : Tunnel Rat Digger/Geomancer/Surveyor sur x 34 à 37, y 20 à 28 ; objet Miners' League Crates 271 sur x 34 à 37, y 19 à 27.
- PNJ : Tunnel Rat Geomancer 1174, Digger 1175, Surveyor 1177, Grizlak 1425. Objet : Miners' League Crates 271. Tunnel Rat Vermin/Scout/Forager (1172, 1173, 1176) sont aussi à l'extérieur, non retenus.
- Utilisé par : chapitre Loch Modan (A_DwarfGnome_03), quête 307 « Filthy Paws ».
- Confiance : basse.

### Non retenus (Loch Modan)
- Mo'grosh Stronghold (repaire d'ogres) : non vérifié, aucune donnée.

## Teldrassil (uiMapID 1438)

### Shadowthread Cave : `teldrassil_shadowthread_cave`
- Zone : nord-ouest de Shadowglen. uiMapID 1438.
- Entrée : **[56.7, 32.0]**. Sources : https://warcraft.wiki.gg/wiki/Shadowthread_Cave et https://wowpedia.fandom.com/wiki/Shadowthread_Cave (marqueur de la grotte, pas du point devant la bouche).
- Contrôle : Webwood Spider 1986 sur x 56 à 59, y 25 à 34 ; Webwood Eggs 4406 à [57, 26-27].
- PNJ : Webwood Spider 1986, Githyiss the Vile 1994. Objet : Webwood Eggs 4406. Iverron 8584 est un PNJ de quête à la grotte, non inclus.
- Utilisé par : chapitre Shadowglen (A_NightElf_01), quêtes 916 « Webwood Venom », 917 « Webwood Egg », 4495 « A Good Friend ».
- Confiance : moyenne.
- **Non livrée.** [56.7, 32.0] est le marqueur de la sous-zone sur les wikis, pas la bouche : le détour mènerait au mauvais endroit. À relever en jeu.

### Gnarlpine Hold : `teldrassil_gnarlpine_hold`
- Zone : sud-ouest de Teldrassil. uiMapID 1438. Ursal the Mauler y vit (quête 486).
- Entrée : **aucune source publique**. Je n'ai pas confirmé que le lieu est une grotte fermée.
- Indice : Gnarlpine Pathfinder/Avenger/Totemic 2012-2014 sur x 38 à 43, y 77 à 81 ; Ursal the Mauler 2039 à [39, 80].
- PNJ : 2012, 2013, 2014, 2039.
- Utilisé par : chapitre Teldrassil (A_NightElf_02), quête 486 « Ursal the Mauler ».
- Confiance : basse.

### Ban'ethil Barrow Den : `teldrassil_banethil_barrow_den`
- Zone : au fond de Ban'ethil Hollow, au sud de la route Dolanaar-Darnassus. uiMapID 1438.
- Entrée : **aucune source publique**. Une valeur de commentaire classicdb [45.55, ?] est non vérifiée. https://wowpedia.fandom.com/wiki/Ban%27ethil_Hollow et https://warcraft.wiki.gg/wiki/Barrow_den : texte seul.
- Indice : Oben Rageclaw 7317 à [45, 62], Rageclaw 7318 à [46, 59].
- PNJ : Oben Rageclaw 7317, Rageclaw 7318, Vorlus Vilehoof 6128. Objets : Chest of the Black Feather 2739, Chest of the Raven Claw 2740, Chest of the Sky 2741, Chest of Nesting 2742 (relics de la quête 483).
- Utilisé par : chapitre Teldrassil, quêtes 483 « The Relics of Wakening » et « Escaping Ban'ethil ».
- Confiance : basse.

### Fel Rock : `teldrassil_fel_rock`
- Zone : centre de Teldrassil. uiMapID 1438.
- Entrée : **aucune source publique**. Un guide cite [51.2, 50.8] pour « nettoyer Fel Rock » (https://games.gg/world-of-warcraft/guides/wow-forever-teldrassil-leveling/) : c'est un point dans la zone des mobs (Lord Melenas à [51-53, 50-51]), pas l'entrée.
- PNJ : Lord Melenas 2038, Rascal Sprite 2002, Shadow Sprite 2003, Dark Sprite 2004, Vicious Grell 2005 (tous dans la boîte).
- Utilisé par : chapitre Teldrassil, quête 932 « Twisted Hatred » (Lord Melenas).
- Confiance : basse.

## Darkshore (uiMapID 1439)

### Grotte aux champignons (quête « Cave Mushrooms ») : `darkshore_cave_mushrooms`
- Zone : Darkshore, est. uiMapID 1439.
- Entrée : **aucune source publique**. https://warcraft.wiki.gg/wiki/Scaber_Stalk place la plante à [55, 34], sans nom de grotte. Je n'ai pas pu confirmer qu'il s'agit d'une grotte fermée (le nom de la quête le suggère seulement).
- Objets (QuestieDB) : Death Cap 11713 (x 55 à 56, y 35 à 36), Scaber Stalk 11714 (x 55 à 57, y 33 à 37).
- Utilisé par : A_01 et A_NightElf_03, quête 947 « Cave Mushrooms ».
- Confiance : basse. Entrée à écarter si une vérification en jeu infirme la grotte.

### Non retenus (Darkshore)
- « The Red Crystal » / « As Water Cascades » : le cristal [47, 49] est le long de la chaîne est, pas dans une grotte.
- Twilight's Hammer camp (« The Twilight Camp ») : camp à ciel ouvert.

## Durotar et Valley of Trials (uiMapID 1411)

### Burning Blade Coven : `durotar_burning_blade_coven`
- Zone : Durotar, nord-est de la Valley of Trials. uiMapID 1411.
- Entrée : **aucune source publique**. Un guide non identifié dit environ [45, 56], au nord-est de The Den, mais je n'ai pas son URL : non retenu. Le centre des spawns QuestieDB est aussi [45, 56].
- PNJ : Vile Familiar 3101 (37/37, x 43 à 47, y 53 à 58), Felstalker 3102, Yarrog Baneshadow 3183 (médaillon, quête 794).
- Utilisé par : chapitre Valley of Trials (H_OrcTroll_01), quêtes 792 « Vile Familiars », 794 « Burning Blade Medallion ».
- Confiance : basse.

### Dustwind Cave : `durotar_dustwind_cave`
- Zone : haut des falaises de Razorwind Canyon, au nord-est de Razor Hill. uiMapID 1411.
- Entrée : **[52.8, 28.7]**. Source : https://warcraft.wiki.gg/wiki/Dustwind_Cave. Anciens commentaires : [52, 29] et [52, 28].
- Contrôle : Burning Blade Thug 3195, Neophyte 3196, Cultist 3199 sur x 52 à 53, y 25 à 29, cohérent avec une grotte juste au nord de l'entrée.
- PNJ : 3195, 3196, 3199. Objet : Stolen Supply Sack 3290.
- Utilisé par : chapitre Durotar (H_OrcTroll_02). Le Searing Collar (objet 4871) tombe de 3195 à 3199, mais la quête 827 parle de « Skull Rock » : lien à confirmer.
- Confiance : moyenne.

### Skull Rock : `durotar_skull_rock`
- Zone : nord-est de Durotar, à l'est de la porte principale d'Orgrimmar. uiMapID 1411.
- Entrée : **[55, 11]** (wiki), environ [55, 10] (guide). Sources : https://warcraft.wiki.gg/wiki/Skull_Rock, https://allthings.how/skull-rock-location-in-world-of-warcraft-classic-durotar/.
- Contrôle : Burning Blade Fanatic 3197 et Apprentice 3198 (19 et 13 spawns dans la boîte), Gazz'uz 3204. Margoz 3208 est à son camp [56, 20], dehors.
- PNJ : 3197, 3198, 3204. Pas d'objet.
- Utilisé par : chapitre Durotar, quête 827 « Skull Rock ».
- Confiance : moyenne.

### Non retenus
- Sarkoth (quête 790) : le PNJ est seul à [40, 67] dans une grotte, sans nom ; Hana'zua et autres. Pas de source.

## Mulgore (uiMapID 1412)

### The Venture Co. Mine : `mulgore_venture_co_mine`
- Zone : falaises est de Mulgore. uiMapID 1412.
- Entrée : **[61, 47]**. Sources : https://warcraft.wiki.gg/wiki/Venture_Co._Mine (« la seule entrée accessible à pied ») ; commentaires classicdb.ch/?quest=765 : entrée [61, 47], Fizsprocket [64, 43] (anciennes versions, non vérifié).
- Contrôle : Supervisor Fizsprocket 3051 à [61, 49] dans la base.
- PNJ : Supervisor Fizsprocket 3051, Venture Co. Worker 2978, Supervisor 2979. Attention : 2978 et 2979 ont aussi des spawns dans les camps ouverts de l'ouest et du nord (127 et 67 spawns sur x 40 à 63) : le calcul de l'intérieur doit filtrer par proximité de l'entrée.
- Utilisé par : chapitre Mulgore (H_Tauren_02), quêtes 764 « The Venture Co. », 765 « Supervisor Fizsprocket ».
- Confiance : moyenne.
- **Non livrée.** Les PNJ de la mine vivent aussi dans des camps à ciel ouvert près de l'entrée : le contour calculé depuis leurs apparitions englobe du dehors, et le joueur y serait compté « dans la grotte ». À relever en jeu (bouche réelle) et à revoir avec des PNJ propres à la mine.

## Tirisfal Glades (uiMapID 1420)

### Night Web's Hollow : `tirisfal_night_webs_hollow`
- Zone : nord-ouest de Deathknell. uiMapID 1420.
- Entrée : **[27, 59]**. Des commentaires donnent [26.96, 59.40], [27, 59] et [26, 60] pour la mine/grotte ; StrategyWiki cite [27, 59]. Sources : https://warcraft.wiki.gg/wiki/Night_Web%27s_Hollow, https://classicdb.ch/?quest=380, https://strategywiki.org/wiki/World_of_Warcraft/Zones/Tirisfal_Glades (valeurs lues via résumé de recherche).
- Contrôle : Young Night Web Spider 1504 (30/30), Night Web Spider 1505, Night Web Matriarch 1688 à [24, 58].
- PNJ : 1505, 1688. Pas d'objet. Young Night Web Spider 1504 n'est pas listée : elle vit aussi dehors (vers [29, 58]) et élargit le contour.
- Utilisé par : chapitre Deathknell (H_Undead_01), quête « Night Web's Hollow ».
- Confiance : moyenne.

### Non retenus (Tirisfal)
- Agamand Family Crypt (quête 408 « The Family Crypt ») : crypte, pas vérifiée, aucune donnée publique lue.

## Stonetalon Mountains (uiMapID 1442)

### Boulderslide Cavern : `stonetalon_boulderslide_cavern`
- Zone : ravin de Boulderslide, sud de Stonetalon. uiMapID 1442.
- Entrée : **non retenue**. Le point d'exploration de la quête 6421 (QuestieDB, non repris ici) et le wiki, qui place le ravin à [65, 91] (https://warcraft.wiki.gg/wiki/Boulderslide_Ravine, « Boulderslide Cavern » est la grotte), se contredisent.
- PNJ : Gogger Rock Keeper 11915, Geomancer 11917, Stonepounder 11918. Objets : Resonite Crystal 178104, 178105, 178106 ; Resonite Cask 178145.
- Utilisé par : chapitre Stonetalon (H_02), quête 6421 « Boulderslide Ravine ».
- Confiance : basse.

## Wetlands (uiMapID 1437)

### Ironbeard's Tomb : `wetlands_ironbeards_tomb`
- Zone : centre nord des Wetlands, « juste à l'ouest de la route de Dun Modr ». uiMapID 1437.
- Entrée : **aucune source publique** (https://warcraft.wiki.gg/wiki/Ironbeard%27s_Tomb).
- Indice : Crimson Ooze 1031 (8/8) sur x 44 à 45, y 24 à 25. Black Ooze 1032 et Monstrous Ooze 1033 sont aussi dehors, non retenus.
- Utilisé par : chapitre Wetlands (A_04), quête 470 « Digging Through the Ooze ».
- Confiance : basse.

---

## Cavités examinées et écartées

| Lieu | Zone | Raison |
|---|---|---|
| Vul'Gol Ogre Mound | Duskwood (1431) | Bassin à ciel ouvert avec une petite grotte ; entrée inconnue. Zzarc' Vul 300 à [36-38, 80-84] (quête 181). |
| Foulweald Den | Ashenvale (1440) | Statut « grotte » non confirmé (wiki 404). Foulweald 3743-3750 sur x 49 à 58, y 60 à 65. Quête 1025. |
| Thistlefur Village / Hold | Ashenvale (1440) | Village ouvert ; la « Hold » n'est pas documentée. Thistlefur sur x 30 à 43, y 30 à 46. Quête 216. |
| Talon Den (Stonetalon Peak) | Stonetalon (1442) | Quête 1089 « The Den » ; objets 5689-5691, pas de coordonnées. |
| Zephras Isle | Skyborne | Contenu Forever sans source publique. |
| Wailing Caverns, Deadmines, Shadowfang | - | Instances, hors périmètre. |
| Redridge, Hillsbrad, Barrens, Silverpine | - | Aucune grotte vérifiée dans les quêtes de ces routes. Azurelode Mine (Hillsbrad) existe mais n'apparaît pas dans les quêtes retenues. |

## Lacunes principales

- Entrées sans source publique : Frostmane Hovel, Frostmane Hold, Gol'Bolar Quarry Mine, Jangolode Mine, Gold Coast Quarry, Silver Stream Mine, Gnarlpine Hold, Ban'ethil Barrow Den, Fel Rock, grotte de Darkshore, Burning Blade Coven, Ironbeard's Tomb. À relever en jeu, ou sur Wowhead avec le navigateur (pages de sous-zone) si l'on veut une valeur citable.
- Les coordonnées « point d'exploration » (Fargodeep, Jasperlode, Boulderslide) et les marqueurs wiki (Shadowthread) sont à l'intérieur ou au centre de la zone, pas devant la bouche : ces grottes ne sont pas livrées. Les points d'exploration sont des données QuestieDB, à ne pas reprendre ; l'entrée réelle est à relever en jeu.
- Wowpedia et wowwiki-archive n'ont pas pu être lus directement (402). Les valeurs du Grizzled Den et de Night Web's Hollow viennent de résumés de recherche.
- Les routes Redridge, Wetlands, Hillsbrad, Silverpine et Barrens n'ont pas révélé d'autres grottes via les descriptions de quêtes de QuestieDB. Une grotte nommée seulement par la zone de combat (sans mot-clé dans la quête) peut m'avoir échappé.

local addonName, Q = ...

-- Entrées relevées dans des sources publiques ; à vérifier en jeu. Pas livrées : les grottes dont la
-- valeur connue est un point d'exploration de quête ou un marqueur de sous-zone (pas la bouche), ou
-- dont les PNJ vivent aussi dans des camps à ciel ouvert (voir tools/caves/research.md).
-- Grottes et mines où la navigation doit passer par l'entrée (Nav/Caves.lua).
-- Sans hauteur, un point dans une grotte creusée sous une montagne est ambigu : un calcul
-- d'itinéraire (ShortestPath) peut le poser sur la montagne au-dessus, une flèche pointe à travers
-- la roche. Pour une cible dans une de ces grottes, le joueur est d'abord mené à l'entrée.
-- Aucun contour n'est recopié : l'intérieur est calculé à l'exécution (enveloppe convexe, élargie
-- d'une marge) depuis les apparitions QuestieDB des PNJ et objets listés, sur la carte de la grotte
-- et à moins de 250 yards (ou `radius`) de l'entrée. Sans QuestieDB, ou avec moins de 3 points, la grotte est
-- ignorée.
--   key       identifiant (messages de débogage, état « joueur entré »)
--   name      nom de la grotte (commentaire et débogage seulement, jamais affiché)
--   mapId     uiMapID des coordonnées (0-100)
--   entrance  { x, y } : point dehors, devant l'entrée
--   npcs      { id, ... } PNJ (QuestieDB) qui vivent dans la grotte
--   objects   { id, ... } objets du monde (QuestieDB) dans la grotte
--   radius    (facultatif) yards autour de l'entrée où chercher les apparitions (défaut 250)
--   inside    (facultatif) contour explicite { { x, y }, ... } : repli quand aucun PNJ ni objet ne
--             convient (tests surtout) ; il remplace le calcul
--   source    URL publique d'où vient l'entrée (aucune coordonnée n'est inventée)
-- Exemple :
--   { key = "dun_morogh_example", name = "Example Cave (Dun Morogh)", mapId = 1426,
--     entrance = { 27.1, 80.7 }, npcs = { 1234, 1235 }, objects = {},
--     source = "https://example.org/entrée-de-la-grotte" },
Q.CaveData = {
  -- Entrée : grande grotte au sud-ouest de Kharanos. Grande grotte : rayon 400 yd.
  -- Source : valeur [42, 55] citée par la page https://classic-wow-archive.fandom.com/wiki/Grizzled_Den
  -- (lue via un résumé de recherche, la page n'a pas pu être ouverte) ;
  -- position décrite aussi par https://warcraft.wiki.gg/wiki/Culling_the_Wendigos
  {
    key = "dunmorogh_grizzled_den",
    name = "The Grizzled Den (Dun Morogh)",
    mapId = 1426,
    entrance = { 42, 55 },
    npcs = { 1135, 1137, 1271 },
    objects = {},
    radius = 400,
    source = "https://classic-wow-archive.fandom.com/wiki/Grizzled_Den",
  },
  -- Mine au nord-ouest de Northshire.
  -- Source : https://games.gg/world-of-warcraft/guides/wow-forever-elwynn-forest/
  {
    key = "elwynn_echo_ridge_mine",
    name = "Echo Ridge Mine (Elwynn Forest)",
    mapId = 1429,
    entrance = { 47.8, 31.6 },
    npcs = { 80 },
    objects = {},
    source = "https://games.gg/world-of-warcraft/guides/wow-forever-elwynn-forest/",
  },
  -- Grotte de Durotar.
  -- Source : https://warcraft.wiki.gg/wiki/Dustwind_Cave
  {
    key = "durotar_dustwind_cave",
    name = "Dustwind Cave (Durotar)",
    mapId = 1411,
    entrance = { 52.8, 28.7 },
    npcs = { 3195, 3196, 3199 },
    objects = { 3290 },
    source = "https://warcraft.wiki.gg/wiki/Dustwind_Cave",
  },
  -- Grotte de Durotar (aussi allthings.how, Skull Rock).
  -- Source : https://warcraft.wiki.gg/wiki/Skull_Rock
  {
    key = "durotar_skull_rock",
    name = "Skull Rock (Durotar)",
    mapId = 1411,
    entrance = { 55, 11 },
    npcs = { 3197, 3198, 3204 },
    objects = {},
    source = "https://warcraft.wiki.gg/wiki/Skull_Rock",
  },
  -- Grotte de Tirisfal. Valeur [27, 59] citée par classicdb.ch/?quest=380 et strategywiki.org (lue via
  -- un résumé de recherche).
  -- Source : https://warcraft.wiki.gg/wiki/Night_Web%27s_Hollow
  {
    key = "tirisfal_night_webs_hollow",
    name = "Night Web's Hollow (Tirisfal Glades)",
    mapId = 1420,
    entrance = { 27, 59 },
    -- Sans Young Night Web Spider (1504) : elle vit aussi dehors (vers [29, 58]) et élargit le contour.
    npcs = { 1505, 1688 },
    objects = {},
    source = "https://warcraft.wiki.gg/wiki/Night_Web%27s_Hollow",
  },
}

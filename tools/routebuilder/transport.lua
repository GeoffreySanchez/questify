-- tools/routebuilder/transport.lua : liaisons de transport (bateaux, tram, zeppelins, portails) et
-- régions de marche. Utilisé par sim.route pour les trajets entre zones.
--
-- Régions : deux points d'une même région sont reliés à pied en ligne droite. Entre deux régions,
-- il faut une liaison (ou un vol). Les montagnes entre Dun Morogh et Elwynn, le tronc de Teldrassil
-- (Rut'theran en bas, Dolanaar et Darnassus en haut) imposent ces coupures.
--
-- Positions des quais : déclencheurs de zone du client Classic (tram 2173 / 2175, portails 527 / 542,
-- exportés dans Questie/ExternalScripts) ou PNJ / objets de QuestieDB placés sur les quais
-- (Idrieth Mossgrove au port de Stormwind, Raul Sweete à Southshore, maîtres des zeppelins, panneaux
-- « Boat to ... »). Faits vérifiés sur method.gg et conquestcapped (itinéraires de Forever) :
--   * Stormwind (port, nouveau dans Forever) <-> Auberdine ;
--   * boucle à sens unique Auberdine -> Menethil -> Southshore -> Auberdine ;
--   * Auberdine <-> Rut'theran ; tram Stormwind <-> Ironforge ; zeppelins Orgrimmar <-> Undercity ;
--   * Skyborne : Valanaar (quai est) <-> Dalaran (Alliance, puis portail Skyborne vers Stormwind),
--     Valanaar (quai ouest) <-> plateau des Guetteurs du ciel, en Mulgore (Horde).
-- Durées : attente moyenne (demi-rotation) + traversée, en secondes (estimations).

local transport = {}

-- uiMapID -> région de marche
local REGION = {
  -- Royaumes de l'Est, nord des montagnes
  [1426] = "EK_N", [1455] = "EK_N", [1432] = "EK_N", [1437] = "EK_N", [1417] = "EK_N", [1424] = "EK_N",
  [1416] = "EK_N", [1421] = "EK_N", [1420] = "EK_N", [1458] = "EK_N", [1418] = "EK_N", [1422] = "EK_N",
  [1423] = "EK_N", [1425] = "EK_N", [1427] = "EK_N",
  -- Royaumes de l'Est, sud
  [1429] = "EK_S", [1453] = "EK_S", [1436] = "EK_S", [1433] = "EK_S", [1431] = "EK_S", [1434] = "EK_S",
  [1430] = "EK_S", [1428] = "EK_S", [1435] = "EK_S",
  -- Kalimdor (Teldrassil à part, voir regionOf)
  [1439] = "KAL", [1440] = "KAL", [1442] = "KAL", [1413] = "KAL", [1411] = "KAL", [1454] = "KAL", [1412] = "KAL",
  [1456] = "KAL", [1441] = "KAL", [1443] = "KAL", [1445] = "KAL", [1444] = "KAL", [1446] = "KAL", [1447] = "KAL",
  [1448] = "KAL", [1449] = "KAL", [1450] = "KAL", [1451] = "KAL", [1452] = "KAL",
  [1457] = "TELD",
}

-- Région d'un point (carte, y). Teldrassil : Rut'theran (bas du tronc) est séparé du plateau.
function transport.regionOf(m, x, y)
  if m == 1438 then
    if y and x and y >= 84 and x >= 45 then return "RUT" end
    return "TELD"
  end
  return REGION[m]
end

-- Liaisons orientées. faction = "Alliance" | "Horde" | nil (toutes) ; races = {...} | nil.
--   from / to = { uiMapID, x, y } ; time = s (attente moyenne + trajet) ; kind = "boat" | "portal"
--   note = texte de l'étape (anglais, affiché tel quel)
local L = {}
local function link(t) L[#L + 1] = t end
local function both(a, b)
  link(a)
  link({ id = b.id, kind = a.kind, faction = a.faction, races = a.races, from = a.to, to = a.from,
         time = b.time or a.time, note = b.note })
end

local SW_TRAM, IF_TRAM = { 1453, 69.6, 30.3 }, { 1455, 78.0, 51.4 }
local SW_HARBOR = { 1453, 24.1, 55.4 }
local AUB_SW, AUB_LOOP, AUB_RUT = { 1439, 32.7, 41.8 }, { 1439, 32.4, 43.8 }, { 1439, 33.2, 40.2 }
local MENETHIL = { 1437, 4.9, 57.3 }
local SOUTHSHORE = { 1424, 50.5, 67.0 }
local RUT_DOCK, RUT_PORTAL, DARN_PORTAL = { 1438, 54.9, 96.8 }, { 1438, 55.9, 89.3 }, { 1457, 29.1, 41.2 }
local ORG_ZEP, UC_ZEP = { 1411, 50.8, 13.5 }, { 1420, 60.7, 58.9 }
local ZEPHRAS_EAST, ZEPHRAS_WEST = { 2521, 65.1, 81.4 }, { 2521, 58.1, 80.4 }
local DALARAN, DALARAN_PORTAL, SW_PORTAL_ARRIVAL = { 1416, 15.0, 57.0 }, { 1416, 12.0, 56.2 }, { 1453, 49.0, 87.0 }
local SKYWATCHER = { 1412, 33.6, 24.7 }

both({ id = "tram_if_sw", kind = "boat", from = IF_TRAM, to = SW_TRAM, time = 180,
       note = "Take the Deeprun Tram to Stormwind" },
     { id = "tram_sw_if", note = "Take the Deeprun Tram to Ironforge" })
both({ id = "boat_sw_aub", kind = "boat", faction = "Alliance", from = SW_HARBOR, to = AUB_SW, time = 300,
       note = "Take the boat to Auberdine (Stormwind Harbor)" },
     { id = "boat_aub_sw", note = "Take the boat to Stormwind Harbor" })
-- boucle à sens unique Auberdine -> Menethil -> Southshore -> Auberdine
link({ id = "boat_aub_men", kind = "boat", from = AUB_LOOP, to = MENETHIL, time = 420,
       note = "Take the boat to Menethil Harbor" })
link({ id = "boat_men_ss", kind = "boat", from = MENETHIL, to = SOUTHSHORE, time = 420,
       note = "Take the boat to Southshore" })
link({ id = "boat_ss_aub", kind = "boat", from = SOUTHSHORE, to = AUB_LOOP, time = 420,
       note = "Take the boat to Auberdine" })
link({ id = "boat_men_aub", kind = "boat", from = MENETHIL, to = AUB_LOOP, time = 660,
       note = "Take the boat to Auberdine (it stops at Southshore first: stay aboard)" })
link({ id = "boat_ss_men", kind = "boat", from = SOUTHSHORE, to = MENETHIL, time = 660,
       note = "Take the boat to Menethil Harbor (it stops at Auberdine first: stay aboard)" })
both({ id = "boat_aub_rut", kind = "boat", faction = "Alliance", from = AUB_RUT, to = RUT_DOCK, time = 300,
       note = "Take the boat to Rut'theran Village" },
     { id = "boat_rut_aub", note = "Take the boat to Auberdine" })
link({ id = "portal_rut_darn", kind = "portal", faction = "Alliance", from = RUT_PORTAL, to = DARN_PORTAL, time = 15,
       note = "Take the portal up to Darnassus" })
link({ id = "portal_darn_rut", kind = "portal", faction = "Alliance", from = DARN_PORTAL, to = RUT_PORTAL, time = 15,
       note = "Take the portal down to Rut'theran Village" })
both({ id = "zep_org_uc", kind = "boat", faction = "Horde", from = ORG_ZEP, to = UC_ZEP, time = 420,
       note = "Take the zeppelin to Undercity (Tirisfal Glades)" },
     { id = "zep_uc_org", note = "Take the zeppelin to Orgrimmar (Durotar)" })
-- Skyborne
both({ id = "sky_zephras_dalaran", kind = "boat", faction = "Alliance", races = { "Skyborne" }, from = ZEPHRAS_EAST,
       to = DALARAN, time = 330, note = "Take the skyboat to Dalaran (east dock of Valanaar)" },
     { id = "sky_dalaran_zephras", note = "Take the skyboat to Zephras Isle" })
link({ id = "portal_dalaran_sw", kind = "portal", faction = "Alliance", races = { "Skyborne" }, from = DALARAN_PORTAL,
       to = SW_PORTAL_ARRIVAL, time = 15, note = "Take the Skyborne portal to Stormwind" })
both({ id = "sky_zephras_mulgore", kind = "boat", faction = "Horde", races = { "Skyborne" }, from = ZEPHRAS_WEST,
       to = SKYWATCHER, time = 330, note = "Take the skyboat to Skywatcher Plateau (west dock of Valanaar)" },
     { id = "sky_mulgore_zephras", note = "Take the skyboat to Zephras Isle" })

transport.links = L

-- Liaisons utilisables par une faction et une race (race nil : toutes les races de la faction).
function transport.linksFor(faction, race)
  local out = {}
  for _, l in ipairs(L) do
    local ok = not l.faction or l.faction == faction
    if ok and l.races then
      ok = false
      for _, r in ipairs(l.races) do if r == race then ok = true end end
    end
    if ok then out[#out + 1] = l end
  end
  return out
end

return transport

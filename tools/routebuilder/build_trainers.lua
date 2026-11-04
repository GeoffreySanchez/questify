-- tools/routebuilder/build_trainers.lua : liste des maîtres de classe pour l'addon.
-- Lua 5.1 / LuaJIT, hors jeu, lancé depuis la racine du projet :
--   luajit tools/routebuilder/build_trainers.lua [--db PATH] [--questie PATH] [--out FILE] [--date YYYY-MM-DD]
-- Lit la vue Forever de QuestieDB et écrit Questify/Data/ClassTrainers.lua :
-- pour chaque classe et chaque faction, les IDs des PNJ dont le sous-titre anglais est exactement
-- « <Classe> Trainer », qui portent le drapeau TRAINER et ont au moins une position ; puis, pour
-- chaque métier, les maîtres qui l'enseignent (sous-titre reconnu par les motifs de PROFS, hors
-- spécialistes de haut niveau). Un ID absent du client est simplement ignoré à l'exécution, où les
-- positions sont relues dans le QuestieDB du joueur.
package.path = "tools/routebuilder/?.lua;" .. package.path
local qdb = require("qdb")

local CLASSES = {
  { "WARRIOR", "Warrior" }, { "PALADIN", "Paladin" }, { "HUNTER", "Hunter" }, { "ROGUE", "Rogue" },
  { "PRIEST", "Priest" }, { "SHAMAN", "Shaman" }, { "MAGE", "Mage" }, { "WARLOCK", "Warlock" },
  { "DRUID", "Druid" },
}

-- Métiers : motifs (Lua, sur le sous-titre anglais) des maîtres qui enseignent le rang Apprenti,
-- et motifs exclus (spécialisations).
local PROFS = {
  { "ALCHEMY", { "Alchem" } },
  { "BLACKSMITHING", { "Blacksmith" } },
  { "ENCHANTING", { "Enchant" } },
  { "ENGINEERING", { "Engineer" }, { "Gnome", "Goblin" } },
  { "HERBALISM", { "Herbalis" } },
  { "LEATHERWORKING", { "Leatherwork", "Leathercrafter" }, { "Dragonscale", "Elemental", "Tribal" } },
  { "MINING", { "Mining Trainer", "^Miner$" } },
  { "SKINNING", { "Skinn" } },
  { "TAILORING", { "Tailor" }, { "Shadoweave" } },
  { "COOKING", { "Cook" } },
  { "FIRSTAID", { "First Aid", "Physician", "Medic", "Trauma Surgeon" } },
  { "FISHING", { "Fish" } },
}

local function matchesProf(subName, def)
  for _, bad in ipairs(def[3] or {}) do
    if subName:find(bad) then return false end
  end
  for _, pat in ipairs(def[2]) do
    if subName:find(pat) then return true end
  end
  return false
end

local function parseArgs(argv)
  local o = { db = qdb.DEFAULT_DB, questie = nil, out = "Questify/Data/ClassTrainers.lua",
    date = os.date("%Y-%m-%d") }
  local i = 1
  while i <= #argv do
    local k, v = argv[i], argv[i + 1]
    if k == "--db" then o.db = v elseif k == "--questie" then o.questie = v
    elseif k == "--out" then o.out = v elseif k == "--date" then o.date = v
    else error("option inconnue : " .. tostring(k)) end
    i = i + 2
  end
  return o
end

local function hasSpawn(npc)
  for _, list in pairs(npc.spawns or {}) do
    if type(list) == "table" and #list > 0 then return true end
  end
  return false
end

local function hasBit(v, bit)
  return bit and bit > 0 and math.floor((v or 0) / bit) % 2 == 1
end

local function addFaction(t, f, id)
  if f == "A" or f == "AH" then t.A[id] = true end
  if f == "H" or f == "AH" then t.H[id] = true end
end

-- -> { [CLASS|PROF] = { A = { [id] = true }, H = { [id] = true } } }
local function collect(D, into, profInto)
  local trainerBit = D.npcFlagValues and D.npcFlagValues.TRAINER
  for id, npc in pairs(D.npcs) do
    if type(npc.subName) == "string" and hasBit(npc.npcFlags, trainerBit) and hasSpawn(npc) then
      for _, def in ipairs(PROFS) do
        if matchesProf(npc.subName, def) then
          profInto[def[1]] = profInto[def[1]] or { A = {}, H = {} }
          addFaction(profInto[def[1]], npc.friendly, id)
        end
      end
    end
    for _, c in ipairs(CLASSES) do
      if npc.subName == c[2] .. " Trainer" and hasBit(npc.npcFlags, trainerBit) and hasSpawn(npc) then
        local f = npc.friendly
        into[c[1]] = into[c[1]] or { A = {}, H = {} }
        if f == "A" or f == "AH" then into[c[1]].A[id] = true end
        if f == "H" or f == "AH" then into[c[1]].H[id] = true end
      end
    end
  end
end

local function sortedIds(set)
  local out = {}
  for id in pairs(set or {}) do out[#out + 1] = id end
  table.sort(out)
  return out
end

local function main(argv)
  local o = parseArgs(argv)
  local found, profs = {}, {}
  local forever = qdb.load({ db = o.db, faction = "Alliance", questie = o.questie })
  collect(forever, found, profs)
  local lines = {
    "local addonName, Q = ...",
    "-- Généré par tools/routebuilder/build_trainers.lua. Ne pas modifier à la main.",
    ("-- Source : QuestieDB commit %s, généré le %s."):format(tostring(forever.commit), o.date),
    "-- Maîtres de classe par classe et faction (A = Alliance, H = Horde) : IDs de PNJ.",
    "Q.ClassTrainerData = {",
  }
  for _, c in ipairs(CLASSES) do
    local t = found[c[1]] or { A = {}, H = {} }
    local a, h = sortedIds(t.A), sortedIds(t.H)
    lines[#lines + 1] = ("  %s = { A = { %s }, H = { %s } },"):format(c[1], table.concat(a, ", "), table.concat(h, ", "))
    print(("%-8s Alliance %3d  Horde %3d"):format(c[1], #a, #h))
  end
  lines[#lines + 1] = "}"
  lines[#lines + 1] = "-- Maîtres de métier (rang Apprenti) par métier et faction."
  lines[#lines + 1] = "Q.ProfTrainerData = {"
  for _, def in ipairs(PROFS) do
    local t = profs[def[1]] or { A = {}, H = {} }
    local a, h = sortedIds(t.A), sortedIds(t.H)
    lines[#lines + 1] = ("  %s = { A = { %s }, H = { %s } },"):format(def[1], table.concat(a, ", "), table.concat(h, ", "))
    print(("%-14s Alliance %3d  Horde %3d"):format(def[1], #a, #h))
  end
  lines[#lines + 1] = "}"
  local f = assert(io.open(o.out, "w"))
  f:write(table.concat(lines, "\n"), "\n")
  f:close()
  print("wrote " .. o.out)
end

main(arg or {})

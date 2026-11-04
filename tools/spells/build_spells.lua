-- tools/spells/build_spells.lua : sorts de classe pour l'addon, d'après les tables DB2 du client Forever
-- 1.60.1.70707 (exports CSV de wago.tools dans tools/routebuilder/data/).
-- Lua 5.1 / LuaJIT, hors jeu, lancé depuis la racine du projet :
--   luajit tools/spells/build_spells.lua [--data DIR] [--out FILE] [--quests FILE] [--chains FILE]
-- Écrit Questify/Data/ClassSpells.lua (Q.ClassSpellData) et Questify/Data/SpellQuests.lua
-- (Q.SpellQuestData, Q.SpellQuestChains : sorts qui EXIGENT une chaîne de quêtes de classe). Sortie
-- déterministe : pas de date, tris explicites.
package.path = "tools/routebuilder/?.lua;tools/spells/?.lua;" .. package.path
local world = require("world")

local HEADER = "-- Généré par tools/spells/build_spells.lua. Ne pas modifier à la main."

-- Classes : bit de ClassMask = identifiant de classe - 1 ; lignes de compétence de la classe (arbres de
-- talents et ligne de poisons du Voleur). Liste fermée : aucun métier, aucune ligne de familier, de monture,
-- de runes ni de gravure de Saison de la Découverte.
local CLASSES = {
  { "WARRIOR", 1,  { 26, 256, 257 } },
  { "PALADIN", 2,  { 184, 267, 594 } },
  { "HUNTER",  4,  { 50, 51, 163 } },
  { "ROGUE",   8,  { 38, 39, 40, 253 } },
  { "PRIEST",  16, { 56, 78, 613 } },
  { "SHAMAN",  64, { 373, 374, 375 } },
  { "MAGE",    128, { 6, 8, 237 } },
  { "WARLOCK", 256, { 354, 355, 593 } },
  { "DRUID",   1024, { 134, 573, 574 } },
}

-- AcquireMethod : 0 = appris au maître ou en quête, 2 = acquis à la création (Foudre, Vague de soins),
-- 3 = runes et sorts d'événement de Saison de la Découverte (exclus), 1 = hors classe.
local ACQUIRE_OK = { [0] = true, [2] = true }
local PASSIVE = 64 -- SpellMisc.Attributes_0 : SPELL_ATTR0_PASSIVE
local MAX_LEVEL = 60

-- Deux sorts d'un même niveau et du même nom qui se disputent un prédécesseur : liste blanche explicite des
-- prédécesseurs que la DB2 donne à plusieurs sorts (SupercedesSpell). Vide : la DB2 Forever n'en a pas.
local SHARED_PREDECESSORS = {}
-- Masque de toutes les races jouables (Alliance 77 + Horde 178 en bits bas, 1 et 2 en bits hauts) : un masque
-- qui les couvre toutes n'est pas une restriction.
local ALL_LO, ALL_HI = 255, 3
local TWO32 = 4294967296

local function num(v) return tonumber(v) or 0 end
local function unsigned(v) v = num(v); if v < 0 then v = v + TWO32 end; return v end
local function hasAll(mask, lo, hi)
  return bit.band(mask % TWO32, lo) == lo and bit.band(math.floor(mask / TWO32), hi) == hi
end

local function parseArgs(args)
  local o = { data = "tools/routebuilder/data", out = "Questify/Data/ClassSpells.lua",
    quests = "Questify/Data/SpellQuests.lua", chains = "Questify/Guides/ClassQuestData.lua",
    handwritten = "tools/spells/quest_spells.lua" }
  local i = 1
  while i <= #args do
    local k = args[i]:match("^%-%-(%w+)$")
    assert(k and o[k] ~= nil and args[i + 1], "usage: build_spells.lua [--data DIR] [--out FILE] [--quests FILE] [--chains FILE]")
    o[k] = args[i + 1]; i = i + 2
  end
  return o
end

local function readChainKeys(path)
  local Q = {}
  local fn = assert(loadfile(path))
  setfenv(fn, {})
  fn("Questify", Q)
  local keys = {}
  for _, list in pairs(Q.ClassQuestData) do
    for _, chain in ipairs(list) do keys[chain.key] = chain end
  end
  return keys
end

local function main(args)
  local o = parseArgs(args)
  -- Tous les CSV doivent exister avant d'écrire quoi que ce soit : pas de sortie à moitié vide.
  for _, name in ipairs({ "SkillLineAbility", "SpellLevels", "SpellName", "SpellMisc", "SpellEffect", "Talent",
      "TraitDefinition" }) do
    local f = io.open(o.data .. "/" .. name .. ".csv", "rb")
    if not f then
      io.stderr:write(("%s.csv absent : lance tools/spells/fetch_db2.sh\n"):format(name))
      os.exit(1)
    end
    f:close()
  end
  local function csv(name) return world.readCSV(o.data .. "/" .. name .. ".csv") end

  local names = {}
  for _, r in ipairs(csv("SpellName")) do names[num(r.ID)] = r.Name_lang end

  local level = {} -- spellID -> niveau (difficulté 0 : BaseLevel, à défaut SpellLevel)
  for _, r in ipairs(csv("SpellLevels")) do
    if num(r.DifficultyID) == 0 then
      local lv = num(r.BaseLevel)
      if lv <= 0 then lv = num(r.SpellLevel) end
      local id = num(r.SpellID)
      if lv > 0 and (level[id] == nil or lv < level[id]) then level[id] = lv end
    end
  end

  local passive = {}
  for _, r in ipairs(csv("SpellMisc")) do
    if num(r.DifficultyID) == 0 and math.floor(num(r.Attributes_0) / PASSIVE) % 2 == 1 then
      passive[num(r.SpellID)] = true
    end
  end

  -- Sorts accordés par un talent : tables de talents du client (Talent : rangs, remplacés ; TraitDefinition :
  -- sort, sort remplacé, sort visible). Ni eux ni leurs chaînes de rangs ne sont des sorts à apprendre.
  local talent = {}
  for _, r in ipairs(csv("Talent")) do
    for k, v in pairs(r) do
      if (k:match("^SpellRank_") or k == "SpellID" or k == "OverridesSpellID") and num(v) > 0 then talent[num(v)] = true end
    end
  end
  for _, r in ipairs(csv("TraitDefinition")) do
    for _, k in ipairs({ "SpellID", "OverridesSpellID", "VisibleSpellID" }) do
      if num(r[k]) > 0 then talent[num(r[k])] = true end
    end
  end

  -- Effets : EffectTriggerSpell d'un effet qui n'est pas « apprendre un sort » (36) = sort déclenché par un
  -- autre ; avec l'aura 42 (PROC_TRIGGER_SPELL) c'est un déclenchement de talent ou d'objet, pas un sort lançable.
  local procTriggered = {}
  for _, r in ipairs(csv("SpellEffect")) do
    if num(r.DifficultyID) == 0 and num(r.EffectTriggerSpell) > 0 and num(r.Effect) ~= 36 and num(r.EffectAura) == 42 then
      procTriggered[num(r.EffectTriggerSpell)] = true
    end
  end

  local baseLevel1NoRank = {} -- niveau 1, MaxLevel 0 : effet d'aura sans rang (Chilled, Master of Elements)
  for _, r in ipairs(csv("SpellLevels")) do
    if num(r.DifficultyID) == 0 and num(r.MaxLevel) == 0 and math.max(num(r.BaseLevel), num(r.SpellLevel)) == 1 then
      baseLevel1NoRank[num(r.SpellID)] = true
    end
  end

  local abilities = csv("SkillLineAbility")
  local out, perClass, byClassName = { "local addonName, Q = ...", HEADER,
    "-- Sorts de classe appris chez le maître ou par quête (client Forever 1.60.1.70707, tables DB2 SkillLineAbility,",
    "-- SpellLevels, SpellMisc, SpellName). Q.ClassSpellData[CLASSE] = { { spellID, level, supersedes } … } trié par niveau.",
    "-- supersedes : sort du rang précédent (SupercedesSpell, à défaut même nom dans la classe au niveau inférieur).",
    "Q.ClassSpellData = {" }, {}, {}

  local classOrder = {}
  for _, c in ipairs(CLASSES) do classOrder[#classOrder + 1] = c end
  table.sort(classOrder, function(a, b) return a[1] < b[1] end)

  for _, c in ipairs(classOrder) do
    local class, mask, lines = c[1], c[2], {}
    for _, l in ipairs(c[3]) do lines[l] = true end
    -- Lignes de la classe (tous niveaux) : sorts de talent repérés ici, avec le nom de leurs rangs.
    local raw, talentNames = {}, {}
    for _, r in ipairs(abilities) do
      local id = num(r.Spell)
      if num(r.ClassMask) == mask and lines[num(r.SkillLine)] then
        raw[#raw + 1] = r
        if talent[id] and names[id] then talentNames[names[id]] = true end
      end
    end
    local spells, explicit, raceLo, raceHi, raceAll = {}, {}, {}, {}, {}
    for _, r in ipairs(raw) do
      local id = num(r.Spell)
      if ACQUIRE_OK[num(r.AcquireMethod)] and level[id] and level[id] <= MAX_LEVEL and not passive[id]
         and not talent[id] and not (names[id] and talentNames[names[id]])
         and not procTriggered[id] and not (baseLevel1NoRank[id] and num(r.AcquireMethod) ~= 2) then
        spells[id] = spells[id] or { spellID = id, level = level[id] }
        -- Doublons : on garde le premier SupercedesSpell non nul de n'importe quelle ligne du sort.
        if num(r.SupercedesSpell) > 0 and not explicit[id] then explicit[id] = num(r.SupercedesSpell) end
        -- Races : OU des masques des lignes ; une ligne sans restriction (0 ou toutes les races) libère le sort.
        local lo, hi = unsigned(r.RaceMasks_0), unsigned(r.RaceMasks_1)
        if (lo == 0 and hi == 0) or (bit.band(lo, ALL_LO) == ALL_LO and bit.band(hi, ALL_HI) == ALL_HI) then
          raceAll[id] = true
        else
          raceLo[id], raceHi[id] = raceLo[id] or 0, raceHi[id] or 0
          raceLo[id] = bit.bor(raceLo[id], lo) % TWO32; raceHi[id] = bit.bor(raceHi[id], hi) % TWO32
        end
      end
    end
    local list = {}
    for id, s in pairs(spells) do
      if not raceAll[id] and raceLo[id] then s.races = raceLo[id] + raceHi[id] * TWO32 end
      list[#list + 1] = s
    end
    table.sort(list, function(a, b)
      if a.level ~= b.level then return a.level < b.level end
      return a.spellID < b.spellID
    end)
    -- Rang. 1) SupercedesSpell de la DB2 quand le sort remplacé est de la classe. 2) À défaut, ligne par nom :
    -- les sorts de même nom triés par (niveau, spellID) ; seul le premier de chaque niveau est maillon de la
    -- ligne et remplace le maillon du niveau précédent ; les variantes de même niveau et de même nom
    -- (formes de Polymorph) restent des entrées séparées. Un sort n'est remplacé que par un seul sort.
    local groups = {}
    for _, s in ipairs(list) do
      local n = names[s.spellID]
      if n then groups[n] = groups[n] or {}; table.insert(groups[n], s) end
    end
    local successorOf = {}
    for _, s in ipairs(list) do
      local e = explicit[s.spellID]
      if e and spells[e] and spells[e].level <= s.level then
        assert(not successorOf[e] or SHARED_PREDECESSORS[e], class .. " : deux sorts remplacent " .. e)
        s.supersedes = e; successorOf[e] = s.spellID
      end
    end
    for _, group in pairs(groups) do
      local prevLink
      for _, s in ipairs(group) do -- déjà trié par (niveau, spellID)
        if not prevLink or s.level > prevLink.level then
          if prevLink and not s.supersedes and not successorOf[prevLink.spellID] then
            s.supersedes = prevLink.spellID; successorOf[prevLink.spellID] = s.spellID
          end
          prevLink = s
        end
      end
    end
    perClass[class] = list
    byClassName[class] = groups
    out[#out + 1] = ("  %s = {"):format(class)
    for _, s in ipairs(list) do
      local extra = (s.supersedes and (", supersedes = %d"):format(s.supersedes) or "")
        .. (s.races and (", races = %d"):format(s.races) or "")
      out[#out + 1] = ("    { spellID = %d, level = %d%s },"):format(s.spellID, s.level, extra)
    end
    out[#out + 1] = "  },"
    print(("%-8s %4d sorts"):format(class, #list))
  end
  out[#out + 1] = "}"
  local f = assert(io.open(o.out, "w")); f:write(table.concat(out, "\n"), "\n"); f:close()
  print("wrote " .. o.out)

  -- Sorts de quête : table écrite à la main, résolue sur les noms et validée sur ClassQuestData.
  local chainKeys = readChainKeys(o.chains)
  local entries = dofile(o.handwritten)
  local primary, all = {}, {}
  for _, e in ipairs(entries) do
    for _, key in ipairs(e.chains) do
      assert(chainKeys[key], "chaîne inconnue dans ClassQuestData : " .. key)
      assert(key:sub(1, #e.class + 1) == e.class .. "_", "chaîne d'une autre classe : " .. key)
    end
    for _, n in ipairs(e.names) do
      local group = byClassName[e.class][n]
      assert(group and #group > 0, "sort inconnu pour " .. e.class .. " : " .. n)
      for _, s in ipairs(group) do
        assert(not primary[s.spellID], "sort en double : " .. s.spellID)
        primary[s.spellID] = e.chains[1]
        all[s.spellID] = e.chains
      end
    end
  end
  local ids = {}
  for id in pairs(primary) do ids[#ids + 1] = id end
  table.sort(ids)
  -- Une table par chaîne d'équivalence, partagée par tous les sorts qui l'exigent.
  local shared, sharedOrder = {}, {}
  for _, e in ipairs(entries) do
    local name = "chains" .. (#sharedOrder + 1)
    shared[e.chains] = name; sharedOrder[#sharedOrder + 1] = e.chains
  end
  local q = { "local addonName, Q = ...", HEADER,
    "-- Sorts qui EXIGENT une chaîne de quêtes de classe (par ex. un totem du Chaman : sans la quête, pas de totem),",
    "-- et non sorts « appris par la quête ». Table tools/spells/quest_spells.lua, écrite à la main (QuestieDB n'a pas",
    "-- de sort de récompense). SpellQuestData[spellID] = clé de la chaîne Alliance de Q.ClassQuestData ;",
    "-- SpellQuestChains[spellID] = toutes les chaînes équivalentes (Alliance d'abord, puis Horde), une table par chaîne." }
  for i, chains in ipairs(sharedOrder) do
    local keys = {}
    for _, k in ipairs(chains) do keys[#keys + 1] = ("%q"):format(k) end
    q[#q + 1] = ("local chains%d = { %s }"):format(i, table.concat(keys, ", "))
  end
  q[#q + 1] = "Q.SpellQuestData = {"
  for _, id in ipairs(ids) do q[#q + 1] = ("  [%d] = %q,"):format(id, primary[id]) end
  q[#q + 1] = "}"
  q[#q + 1] = "Q.SpellQuestChains = {"
  for _, id in ipairs(ids) do q[#q + 1] = ("  [%d] = %s,"):format(id, shared[all[id]]) end
  q[#q + 1] = "}"
  local g = assert(io.open(o.quests, "w")); g:write(table.concat(q, "\n"), "\n"); g:close()
  print(("wrote %s (%d sorts de quête)"):format(o.quests, #ids))
end

main(arg or {})

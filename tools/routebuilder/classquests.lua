-- tools/routebuilder/classquests.lua : chaînes de quêtes de classe (niveau <= 30) pour
-- Questify/Guides/ClassQuestData.lua (forme de la Task 7) :
--   Q.ClassQuestData = { [classFile] = { { key, title, faction, races, level, quests = {...},
--                                         exclusive = { clés des chaînes qui s'excluent avec celle-ci },
--                                         rewards = { [questId] = { items = {...}, xp = n } } }, ... } }

local qdb = require("qdb")
local emitm = require("emit")

local cq = {}
cq.MAX_LEVEL = 30

local ALLIANCE_BITS = 1 + 4 + 8 + 64 + 4294967296
local HORDE_BITS = 2 + 16 + 32 + 128 + 8589934592
local RACE_LIST = { 1, 2, 4, 8, 16, 32, 64, 128, 4294967296, 8589934592 }

-- Faction déduite du masque de races : nil si les deux factions (ou toutes les races).
local function factionOf(mask)
  if not mask or mask == 0 then return nil end
  local a, h = false, false
  for _, b in ipairs(RACE_LIST) do
    if qdb.hasBit(mask, b) then
      if qdb.hasBit(ALLIANCE_BITS, b) then a = true end
      if qdb.hasBit(HORDE_BITS, b) then h = true end
    end
  end
  if a and not h then return "Alliance" end
  if h and not a then return "Horde" end
  return nil
end
cq.factionOf = factionOf

local function questLevel(q)
  if q.level and q.level > 0 then return q.level end
  return q.reqLevel or 0
end

-- cq.build(D) -> { [classFile] = { chain, ... } }
function cq.build(D)
  -- objets de récompense par quête
  local rewards = {}
  for _, itemId in ipairs(qdb.sortedKeys(D.items)) do
    for _, qid in ipairs(D.items[itemId].questRewards or {}) do
      rewards[qid] = rewards[qid] or {}
      table.insert(rewards[qid], itemId)
    end
  end
  local out = {}
  local classes = {}
  for name in pairs(qdb.CLASS_BITS) do classes[#classes + 1] = name end
  table.sort(classes)
  for _, cls in ipairs(classes) do
    local bit = qdb.CLASS_BITS[cls]
    local set = {}
    for _, id in ipairs(qdb.sortedKeys(D.quests)) do
      local q = D.quests[id]
      if qdb.isClassQuest(q) and qdb.hasBit(q.classes, bit) and not q.blacklisted
         and questLevel(q) <= cq.MAX_LEVEL and questLevel(q) > 0 and q.name
         and qdb.hasBit(q.specialFlags or 0, 1) == false then
        set[id] = q
      end
    end
    -- liens de chaîne : pré-requis (preSingle / preGroup) et nextQuestInChain, à l'intérieur du lot
    local children, hasParent = {}, {}
    local function link(a, b)
      if a == b or not set[a] or not set[b] then return end
      children[a] = children[a] or {}
      for _, c in ipairs(children[a]) do if c == b then return end end
      table.insert(children[a], b)
      hasParent[b] = true
    end
    local ids = qdb.sortedKeys(set)
    -- Parents directs : quêtes du lot dont la suite (nextQuestInChain) ou la lettre (breadcrumb)
    -- mène à id.
    local direct = {}
    for _, id in ipairs(ids) do
      local q = set[id]
      for _, c in ipairs({ q.next or false, q.breadcrumbFor or false }) do
        if c and c ~= id and set[c] then
          direct[c] = direct[c] or {}
          direct[c][id] = true
        end
      end
      for _, b in ipairs(q.breadcrumbs or {}) do
        if b ~= id and set[b] then
          direct[id] = direct[id] or {}
          direct[id][b] = true
        end
      end
    end
    for _, id in ipairs(ids) do
      local q = set[id]
      -- preQuestSingle = une au choix. Quand plusieurs choix existent et que la quête a déjà des
      -- parents directs, les autres choix sont des branches parallèles (Guerrier 10 de l'Alliance :
      -- « Beat Bartleby », « Tormus Deepforge » et « The Shade of Elura » acceptent chacune les trois
      -- premières parties) : seuls les parents directs sont reliés, sinon les branches se fondent.
      local only = #q.preSingle > 1 and direct[id] or nil
      for _, p in ipairs(q.preSingle) do
        if not only or only[p] then link(p, id) end
      end
      for _, p in ipairs(q.preGroup) do link(p, id) end
      if q.next then link(id, q.next) end
      -- lettre / quête de transport vers la suite
      if q.breadcrumbFor then link(id, q.breadcrumbFor) end
      for _, b in ipairs(q.breadcrumbs or {}) do link(b, id) end
    end
    -- Liens manquants dans les données (chaînes sans pré-requis ni suite) :
    --   (a) passage de relais : B (id suivant, à +3 au plus) commence chez le PNJ qui termine A ;
    --       B peut aussi précéder A (à -3 au plus) s'il ouvre lui-même une suite (« Elanaria » 1684
    --       puis « Vorlus Vilehoof » 1683, suivi de 1686) ;
    --   (b) même titre, même masque de races : ordre par niveau puis id (« Call of Water » 1 à 9).
    -- (a) seulement entre quêtes ouvertes à au moins une race commune ; (b) jamais entre deux quêtes
    -- qui s'excluent (exclusiveTo) : ce sont des variantes de la même étape chez des maîtres
    -- différents (« Returning Home », « Desperate Prayer » du Prêtre), pas une suite. (a) ne regarde
    -- pas exclusiveTo : une lettre y est souvent marquée exclusive de sa propre suite (1638 et 1639).
    local function sameRaces(a, b)
      local ma, mb = set[a].races or 0, set[b].races or 0
      if ma == 0 or mb == 0 then return true end
      for _, bit in ipairs(RACE_LIST) do
        if qdb.hasBit(ma, bit) and qdb.hasBit(mb, bit) then return true end
      end
      return false
    end
    local function excludes(a, b)
      for _, x in ipairs(set[a].exclusiveTo or {}) do if x == b then return true end end
      for _, x in ipairs(set[b].exclusiveTo or {}) do if x == a then return true end end
      return false
    end
    local function isolatedEnd(id) return not children[id] end
    local function reaches(from, target)
      local seen = {}
      local function walk(x)
        if x == target then return true end
        if seen[x] then return false end
        seen[x] = true
        for _, c in ipairs(children[x] or {}) do if walk(c) then return true end end
        return false
      end
      return walk(from)
    end
    for _, a in ipairs(ids) do
      local qa = set[a]
      if isolatedEnd(a) then
        for _, d in ipairs({ 1, 2, 3, -1, -2, -3 }) do
          local b = a + d
          local qb = set[b]
          local opens = d > 0 or (qb and qb.next and set[qb.next])
          if qb and opens and not hasParent[b] and sameRaces(a, b) and not reaches(b, a) then
            local hand = false
            for _, f in ipairs(qa.finishers.npcs or {}) do
              for _, st in ipairs(qb.starters.npcs or {}) do if f == st then hand = true end end
            end
            if hand then link(a, b); break end
          end
        end
      end
    end
    local byTitle = {}
    for _, id in ipairs(ids) do
      local q = set[id]
      local key = (q.name or "") .. "#" .. tostring(q.races or 0)
      byTitle[key] = byTitle[key] or {}
      table.insert(byTitle[key], id)
    end
    for _, key in ipairs(qdb.sortedKeys(byTitle)) do
      local list = byTitle[key]
      if #list > 1 then
        table.sort(list, function(x, y)
          local lx, ly = questLevel(set[x]), questLevel(set[y])
          if lx ~= ly then return lx < ly end
          return x < y
        end)
        for k = 2, #list do
          -- relie la fin de la chaîne précédente à la tête suivante, sans créer de branche
          local prev, cur = list[k - 1], list[k]
          local tail = prev
          local guard = 0
          while children[tail] and #children[tail] == 1 and guard < 30 do tail = children[tail][1]; guard = guard + 1 end
          if not hasParent[cur] and not children[tail] and tail ~= cur and not excludes(prev, cur)
             and not excludes(tail, cur) then
            link(tail, cur)
          end
        end
      end
    end
    for _, list in pairs(children) do table.sort(list) end
    local used, chains = {}, {}
    for _, id in ipairs(ids) do
      if not hasParent[id] then
        -- parcours en profondeur depuis chaque tête : une queue commune à plusieurs lettres de départ
        -- (une par race) est reprise dans la chaîne de chaque tête
        local order, seen = {}, {}
        local function visit(q)
          if seen[q] then return end
          seen[q] = true
          used[q] = true
          order[#order + 1] = q
          for _, c in ipairs(children[q] or {}) do visit(c) end
        end
        visit(id)
        local first = set[order[1]]
        local mask = first.races
        local chain = {
          key = cls .. "_" .. order[1], title = first.name, faction = factionOf(mask),
          races = (mask and mask ~= 0) and mask or nil,
          level = (first.reqLevel and first.reqLevel > 0) and first.reqLevel or questLevel(first),
          quests = order, rewards = {},
        }
        for _, q in ipairs(order) do
          local r = { items = rewards[q] or {}, xp = D.xp[q] and D.xp[q][2] or nil }
          chain.rewards[q] = r
        end
        chains[#chains + 1] = chain
      end
    end
    -- quêtes restées hors chaîne (cycles) : une chaîne chacune
    for _, id in ipairs(qdb.sortedKeys(set)) do
      if not used[id] then
        used[id] = true
        local q = set[id]
        chains[#chains + 1] = { key = cls .. "_" .. id, title = q.name, faction = factionOf(q.races),
          races = (q.races ~= 0) and q.races or nil, level = (q.reqLevel > 0) and q.reqLevel or questLevel(q),
          quests = { id }, rewards = { [id] = { items = rewards[id] or {}, xp = D.xp[id] and D.xp[id][2] or nil } } }
      end
    end
    -- Chaînes qui s'excluent (exclusiveTo entre leurs quêtes) : une seule se fait, l'addon propose
    -- celle dont le donneur est le plus proche.
    local owner = {}
    for _, ch in ipairs(chains) do
      for _, q in ipairs(ch.quests) do
        owner[q] = owner[q] or {}
        owner[q][ch.key] = true
      end
    end
    for _, ch in ipairs(chains) do
      local ex, mine = {}, {}
      for _, q in ipairs(ch.quests) do mine[q] = true end
      local function mark(q)
        for key in pairs(owner[q] or {}) do if key ~= ch.key then ex[key] = true end end
      end
      for _, q in ipairs(ch.quests) do
        for _, x in ipairs(set[q].exclusiveTo or {}) do if not mine[x] then mark(x) end end
      end
      for _, other in ipairs(chains) do
        if other.key ~= ch.key and not ex[other.key] then
          for _, q in ipairs(other.quests) do
            for _, x in ipairs(set[q].exclusiveTo or {}) do
              if mine[x] and not owner[q][ch.key] then ex[other.key] = true end
            end
          end
        end
      end
      local list = qdb.sortedKeys(ex)
      if #list > 0 then ch.exclusive = list end
    end
    table.sort(chains, function(a, b)
      if a.level ~= b.level then return a.level < b.level end
      return a.quests[1] < b.quests[1]
    end)
    out[cls] = chains
  end
  return out
end

-- Fusionne les données de plusieurs factions (chaînes identiques par clé).
function cq.merge(a, b)
  local out = {}
  for _, src in ipairs({ a or {}, b or {} }) do
    for cls, chains in pairs(src) do
      out[cls] = out[cls] or {}
      local seen = {}
      for _, c in ipairs(out[cls]) do seen[c.key] = true end
      for _, c in ipairs(chains) do if not seen[c.key] then table.insert(out[cls], c); seen[c.key] = true end end
      table.sort(out[cls], function(x, y)
        if x.level ~= y.level then return x.level < y.level end
        return x.quests[1] < y.quests[1]
      end)
    end
  end
  return out
end

local function racesValue(v)
  -- masque > 2^31 : écrit en entier
  return ("%.0f"):format(v)
end

-- Texte du fichier ClassQuestData.lua.
function cq.emit(data, meta)
  meta = meta or {}
  local out = {}
  local function w(s) out[#out + 1] = s end
  w("local addonName, Q = ...")
  w("-- Généré par tools/routebuilder/classquests.lua (via build.lua). Ne pas modifier à la main.")
  w(("-- Source : QuestieDB commit %s, généré le %s."):format(meta.commit or "unknown", meta.date or os.date("%Y-%m-%d")))
  w("-- Chaînes de quêtes de classe jusqu'au niveau 30 : IDs de quêtes, ordre, niveaux, IDs des objets de récompense.")
  w("Q.ClassQuestData = {")
  local classes = {}
  for k in pairs(data) do classes[#classes + 1] = k end
  table.sort(classes)
  for _, cls in ipairs(classes) do
    w(("  %s = {"):format(cls))
    for _, c in ipairs(data[cls]) do
      local parts = {
        ("key = %s"):format(emitm.value(c.key)),
        ("title = %s"):format(emitm.value(c.title or "")),
      }
      if c.faction then parts[#parts + 1] = ("faction = %s"):format(emitm.value(c.faction)) end
      if c.races then parts[#parts + 1] = ("races = %s"):format(racesValue(c.races)) end
      parts[#parts + 1] = ("level = %d"):format(c.level)
      parts[#parts + 1] = ("quests = %s"):format(emitm.value(c.quests))
      if c.exclusive and #c.exclusive > 0 then
        parts[#parts + 1] = ("exclusive = %s"):format(emitm.value(c.exclusive))
      end
      local rw = {}
      for _, q in ipairs(c.quests) do
        local r = c.rewards[q] or { items = {} }
        local fields = { ("items = %s"):format(emitm.value(r.items or {})) }
        if r.xp then fields[#fields + 1] = ("xp = %d"):format(r.xp) end
        rw[#rw + 1] = ("[%d] = { %s }"):format(q, table.concat(fields, ", "))
      end
      parts[#parts + 1] = ("rewards = { %s }"):format(table.concat(rw, ", "))
      w("    { " .. table.concat(parts, ", ") .. " },")
    end
    w("  },")
  end
  w("}")
  return table.concat(out, "\n") .. "\n"
end

return cq

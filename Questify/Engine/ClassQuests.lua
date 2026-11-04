local addonName, Q = ...

-- Quêtes de classe (spec § 5.7) : chaînes précalculées par le générateur (Q.ClassQuestData),
-- état par personnage, alerte, ajout à la route et abandon.
-- Q.ClassQuestData = { [classFile] = { { key, title, faction, races, level, quests, rewards }, ... } }
-- est défini par Guides/ClassQuestData.lua, chargé après ce fichier : on le lit à chaque appel.
local ClassQuests = {}
Q.ClassQuests = ClassQuests

local TAG_PREFIX = "cq:"

---------------------------------------------------------------------------
-- Données et état sauvegardé
---------------------------------------------------------------------------
-- Q.char.classQuests = { added = {[key]=true}, ignored = {...}, seen = {...} }
local function saved()
  local c = Q.char
  if not c then return nil end
  if type(c.classQuests) ~= "table" then c.classQuests = {} end
  local cq = c.classQuests
  for _, k in ipairs({ "added", "ignored", "seen" }) do
    if type(cq[k]) ~= "table" then cq[k] = {} end
  end
  return cq
end

-- Chaînes de la classe du joueur dont la faction et les races conviennent.
local function chainsForPlayer()
  local P = Q.Player
  local byClass = type(Q.ClassQuestData) == "table" and Q.ClassQuestData[P.classFile]
  local out = {}
  if type(byClass) ~= "table" then return out end
  for _, chain in ipairs(byClass) do
    if type(chain) == "table" and type(chain.key) == "string" and type(chain.quests) == "table" then
      local factionOk = chain.faction == nil or chain.faction == P.faction
      if factionOk and Q.Util.MaskAllows(chain.races, P.raceBit) then out[#out + 1] = chain end
    end
  end
  return out
end

local function findChain(key)
  for _, chain in ipairs(chainsForPlayer()) do
    if chain.key == key then return chain end
  end
  return nil
end

local function isTurnedIn(id) return Q.Progress:IsTurnedIn(id) end

-- État d'une chaîne, dans cet ordre de priorité :
-- done, inprogress, added, ignored, available, upcoming.
local function chainState(chain, cq)
  local quests = chain.quests
  local last = quests[#quests]
  if last and Q.Progress:IsTurnedIn(last) then return "done" end
  for _, id in ipairs(quests) do
    if Q.Progress:InLog(id) then return "inprogress" end
  end
  if cq.added[chain.key] then return "added" end
  if cq.ignored[chain.key] then return "ignored" end
  local first
  for _, id in ipairs(quests) do
    if not Q.Progress:IsTurnedIn(id) then first = id; break end
  end
  if first and (chain.level or 1) <= (Q.Player.level or 1) and Q.QDB:PrereqsMet(first, isTurnedIn) then
    return "available"
  end
  return "upcoming"
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
-- List() -> { { chain, state }, ... } dans l'ordre des données.
function ClassQuests:List()
  local out = {}
  local cq = Q.Progress:IsEnabled() and saved()
  if not cq then return out end
  for _, chain in ipairs(chainsForPlayer()) do
    out[#out + 1] = { chain = chain, state = chainState(chain, cq) }
  end
  return out
end

-- Alerts() -> chaînes disponibles que le joueur n'a pas encore vues : { { chain, state }, ... }.
function ClassQuests:Alerts()
  local out = {}
  local cq = saved()
  if not cq then return out end
  for _, row in ipairs(self:List()) do
    if row.state == "available" and not cq.seen[row.chain.key] then out[#out + 1] = row end
  end
  return out
end

function ClassQuests:MarkSeen(key)
  local cq = saved()
  if cq and type(key) == "string" then cq.seen[key] = true end
end

-- Add(key) : insère « prendre, faire, rendre » pour chaque quête restante, avant la route.
function ClassQuests:Add(key)
  local cq = saved()
  if not cq or not Q.Progress:IsEnabled() then return false end
  local chain = findChain(key)
  if not chain then return false end
  local steps = {}
  for _, id in ipairs(chain.quests) do
    if not Q.Progress:IsTurnedIn(id) then
      steps[#steps + 1] = { "accept", id }
      steps[#steps + 1] = { "complete", id }
      steps[#steps + 1] = { "turnin", id }
    end
  end
  if #steps == 0 then return false end
  -- l'état est enregistré avant l'insertion : celle-ci déclenche déjà des mises à jour
  cq.added[key] = true
  cq.ignored[key] = nil
  Q.Progress:InsertSteps(TAG_PREFIX .. key, steps)
  Q:Fire("CLASSQUESTS_CHANGED")
  return true
end

-- Track(key) : les étapes de la chaîne passent en tête des étapes insérées (elles sont d'abord ajoutées si
-- la quête est au journal sans étapes insérées) ; le suivi et la flèche pointent alors sur l'étape en cours
-- (STEP_CHANGED). -> vrai si la chaîne est en tête.
function ClassQuests:Track(key)
  if not Q.Progress:IsEnabled() or not findChain(key) then return false end
  local tag = TAG_PREFIX .. key
  local inserted = false
  for _, e in ipairs(Q.Progress:Entries()) do
    if e.tag == tag then inserted = true; break end
  end
  if not inserted then
    if not self:Add(key) then return false end   -- Add range le groupe en fin : on le remonte
  end
  return Q.Progress:MoveInsertedFirst(tag)
end

-- Ignore(key) : retire les étapes insérées et mémorise le choix.
function ClassQuests:Ignore(key)
  local cq = saved()
  if not cq or not findChain(key) then return false end
  cq.ignored[key] = true
  cq.added[key] = nil
  Q.Progress:RemoveInserted(TAG_PREFIX .. key)
  Q:Fire("CLASSQUESTS_CHANGED")
  return true
end

-- Unignore(key) : la chaîne redevient disponible (ou à venir).
function ClassQuests:Unignore(key)
  local cq = saved()
  if not cq or type(key) ~= "string" or not cq.ignored[key] then return false end
  cq.ignored[key] = nil
  Q:Fire("CLASSQUESTS_CHANGED")
  return true
end

---------------------------------------------------------------------------
-- Une chaîne insérée se retire d'elle-même quand toutes ses étapes sont faites
---------------------------------------------------------------------------
-- Une chaîne insérée est finie quand sa dernière quête est rendue, ou quand il ne lui reste
-- aucune étape à faire (toutes faites ou sautées).
local function finishedTags()
  local groups, order = {}, {}
  for _, e in ipairs(Q.Progress:Entries()) do
    local tag = e.tag
    if tag and tag:sub(1, #TAG_PREFIX) == TAG_PREFIX then
      local g = groups[tag]
      if not g then g = { open = false }; groups[tag] = g; order[#order + 1] = tag end
      local state = Q.Progress:State(e)
      if state == "active" or state == "blocked" then g.open = true end
      g.last = e.step.questId   -- les étapes suivent l'ordre de la chaîne : la dernière gagne
    end
  end
  local out = {}
  for _, tag in ipairs(order) do
    local g = groups[tag]
    local chain = findChain(tag:sub(#TAG_PREFIX + 1))
    local lastQuest = chain and chain.quests[#chain.quests] or g.last
    if not g.open or (lastQuest and Q.Progress:IsTurnedIn(lastQuest)) then out[#out + 1] = tag end
  end
  return out
end

Q:On("PROGRESS_UPDATED", function()
  if not Q.Progress:IsEnabled() then return end
  local cq = saved()
  for _, tag in ipairs(finishedTags()) do
    Q.Progress:RemoveInserted(tag)
    cq.added[tag:sub(#TAG_PREFIX + 1)] = nil
    Q:Fire("CLASSQUESTS_CHANGED")
  end
end)

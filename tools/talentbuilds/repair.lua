-- tools/talentbuilds/repair.lua : réparation de l'ordre d'un build dont l'ensemble final est légal mais
-- dont certains points arrivent avant que leur palier ou leur talent requis soit ouvert.
--
-- Report stable : on parcourt l'ordre ; un point pas encore légal attend dans une file ; après chaque
-- point placé, tout point en attente devenu légal est placé, le plus ancien d'abord. Le reste garde son
-- ordre relatif.
--   Repair(Q, order, tree) -> nouvel ordre, nombre de points déplacés   ou   nil si un point reste bloqué
local function Repair(Q, order, tree)
  local ranks, out, pending = {}, {}, {}
  local function legal(spellID)
    local node = tree.nodes[spellID]
    if not node or (ranks[spellID] or 0) >= node.maxRanks then return false end
    return (Q.TalentTree:Rules(tree, ranks)(node))
  end
  local function place(spellID)
    ranks[spellID] = (ranks[spellID] or 0) + 1
    out[#out + 1] = spellID
  end
  for _, spellID in ipairs(order) do
    if not tree.nodes[spellID] then return nil end
    if legal(spellID) then place(spellID) else pending[#pending + 1] = spellID end
    local moved = true
    while moved do
      moved = false
      for i, p in ipairs(pending) do
        if legal(p) then table.remove(pending, i); place(p); moved = true; break end
      end
    end
  end
  if #pending > 0 then return nil end
  local count = 0
  for i, v in ipairs(out) do if v ~= order[i] then count = count + 1 end end
  return out, count
end

return Repair

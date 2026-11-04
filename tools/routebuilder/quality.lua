-- tools/routebuilder/quality.lua : contrôle qualité de l'itinéraire d'un chapitre (allers-retours évitables).
--
-- quality.check(legs, opts) -> { pickups = {...}, turnins = {...}, areas = {...}, revisits = {...} }
--   legs = itinéraire de la marche (sim.lua, report.legs) : { kind, q, pos, id, task, level, log }, dans
--          l'ordre ; level = niveau juste avant la tâche, log = quêtes dans le journal juste avant.
--   opts = { yards = function(posA, posB) -> yd, hub = 40, turnin = 60, area = 120, logCap = 20,
--            feasible = function(seq) -> bool|nil, relax = function(what) -> fopts }
--
-- Pour chaque tâche j, cherche le premier passage antérieur i à portée (prise A ou point de vol :
-- hub ; rendu T : turnin ; objectif O et prise par objet ramassé : area, depuis un autre objectif)
-- tel que la route soit repartie entre i et j (à plus de max(150, rayon + 100) yd), et que la tâche ait
-- été possible juste après i :
-- précédences faites, niveau atteint (niveau requis ou niveau « sûr »), journal pas plein pour une prise.
--   * pickups  : prise faite à un passage ultérieur (missed pickup) ;
--   * turnins  : quête terminée rendue plus tard alors qu'on est passé près du rendu (missed turn-in) ;
--   * areas    : zone d'objectifs visitée deux fois alors qu'un passage suffisait (split area) ;
--   * revisits : retour à un endroit dont toutes les prises et tous les rendus étaient possibles avant
--                (avoidable revisit).
-- Chaque élément porte `reason` : pourquoi l'ordonnancement ne l'a pas avancé (« log cap », « level »,
-- « chain » : contrainte plus loin dans la route) ou « free » (aucune contrainte : défaut à corriger).

local quality = {}

local function isArea(l)
  return l.kind == "O" or (l.kind == "A" and l.task and l.task.itemStart)
end

-- Rayon d'une tâche selon le passage antérieur considéré (nil : pas de contrôle).
local function radius(l, anchor, o)
  if l.kind == "C" or l.kind == "F" or (l.task and l.task.final) then return nil end
  if isArea(l) and isArea(anchor) then return o.area end
  if l.kind == "A" then return o.hub end
  if l.kind == "T" then return o.turnin end
  return nil
end

function quality.check(legs, opts)
  local o = { hub = opts.hub or 40, turnin = opts.turnin or 60, area = opts.area or 120, logCap = opts.logCap or 20 }
  local yards = opts.yards
  local res = { pickups = {}, turnins = {}, areas = {}, revisits = {} }
  local index = {}
  for i, l in ipairs(legs) do if l.id then index[l.id] = i end end
  local issueAt = {}

  -- raison d'un report : séquence des tâches avec la tâche j ramenée juste après i
  local function reasonFor(i, j)
    if not opts.feasible then return "free" end
    local seq = {}
    for k = 1, #legs do
      if k ~= j and legs[k].task then seq[#seq + 1] = legs[k].task end
      if k == i and legs[j].task then seq[#seq + 1] = legs[j].task end
    end
    if opts.feasible(seq) then return "free" end
    if opts.feasible(seq, "logCap") then return "log cap" end
    if opts.feasible(seq, "level") then return "level" end
    return "chain"
  end

  for j, l in ipairs(legs) do
    if l.pos and l.task then
      for i = 1, j - 1 do
        local a = legs[i]
        local r = a.pos and radius(l, a, o)
        if r and yards(a.pos, l.pos) <= r then
          -- la route est vraiment repartie : plus de LEAVE yd (r + 100, au moins 150) entre les deux passages ;
          -- un détour de quelques dizaines de mètres entre deux PNJ du même hub n'est pas un retour
          local leave = math.max(150, r + 100)
          local left = false
          for m = i + 1, j - 1 do
            local p = legs[m].pos
            if p and yards(p, l.pos) > leave then left = true; break end
          end
          if not left then break end
          -- possible juste après i ?
          local ok = true
          for _, dep in ipairs(l.task.after or {}) do
            if index[dep] and index[dep] > i then ok = false; break end
          end
          local nxt = legs[i + 1]
          local level = nxt and nxt.level or l.level
          if ok and l.task.reqLevel and level and level < l.task.reqLevel then ok = false end
          local log = nxt and nxt.log or l.log
          if ok and l.kind == "A" and log and log + 1 > o.logCap then ok = false end
          if ok then
            local item = { j = j, i = i, kind = l.kind, q = l.q, name = l.name, reason = reasonFor(i, j) }
            if isArea(l) and isArea(a) then res.areas[#res.areas + 1] = item
            elseif l.kind == "A" then res.pickups[#res.pickups + 1] = item
            else res.turnins[#res.turnins + 1] = item end
            issueAt[j] = item
          end
          break
        end
      end
    end
  end

  -- retours évitables : groupe de tâches consécutives au même endroit (rayon hub) fait uniquement de
  -- prises et de rendus qui pouvaient se faire à un passage antérieur
  local j = 1
  while j <= #legs do
    local l = legs[j]
    local e = j
    if l.pos then
      while e + 1 <= #legs and legs[e + 1].pos and yards(legs[e + 1].pos, l.pos) <= o.hub do e = e + 1 end
    end
    local all, any = true, false
    for k = j, e do
      local x = legs[k]
      if x.kind == "A" or x.kind == "T" then
        if issueAt[k] and not isArea(x) then any = true else all = false end
      elseif x.kind ~= "F" then
        all = false
      end
    end
    if any and all then
      local first = issueAt[j] or issueAt[e]
      res.revisits[#res.revisits + 1] = { j = j, e = e, i = first and first.i, q = l.q, name = l.name,
        reason = first and first.reason or "free" }
    end
    j = e + 1
  end
  return res
end

-- Nombre total d'éléments signalés.
function quality.count(res)
  if not res then return 0 end
  return #res.pickups + #res.turnins + #res.areas + #res.revisits
end

-- Section Markdown « Qualité » d'un rapport de chapitre.
function quality.markdown(res, legs)
  local out = {}
  local function w(s) out[#out + 1] = s or "" end
  w("## Qualité")
  w()
  w("Checks of the itinerary (see `tools/routebuilder/quality.lua`): avoidable revisits (a place left,")
  w("then returned to only for accepts or turn-ins possible on the earlier visit), missed pickups")
  w("(within 40 yd), missed passing turn-ins (within 60 yd) and split objective areas (within 120 yd).")
  w("A place counts as left when the route went more than 150 yd away (220 yd for an objective area).")
  w("Reason: why the ordering kept it: `log cap`, `level` or `chain` (a constraint later in the route),")
  w("`free` (no constraint: a defect).")
  w()
  if not res then w("Not computed."); w(); return table.concat(out, "\n") end
  w(("| Check | Count |"):format())
  w("|---|---|")
  w(("| Avoidable revisits | %d |"):format(#res.revisits))
  w(("| Missed pickups | %d |"):format(#res.pickups))
  w(("| Split areas | %d |"):format(#res.areas))
  w(("| Missed passing turn-ins | %d |"):format(#res.turnins))
  w()
  local rows = {}
  local function add(label, list)
    for _, it in ipairs(list) do
      rows[#rows + 1] = ("| %s | %s | %s | #%d | #%d | %s |"):format(label, tostring(it.q or ""), it.name or "",
        it.j, it.i or 0, it.reason or "")
    end
  end
  add("revisit", res.revisits)
  add("pickup", res.pickups)
  add("area", res.areas)
  add("turn-in", res.turnins)
  if #rows > 0 then
    w("| Check | Quest | Name | Itinerary # | Earlier # | Reason |")
    w("|---|---|---|---|---|---|")
    for _, r in ipairs(rows) do w(r) end
    w()
  end
  return table.concat(out, "\n")
end

return quality

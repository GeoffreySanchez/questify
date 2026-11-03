-- tools/routebuilder/order.lua : ordonnancement des tâches d'un chapitre.
--
-- order.build(tasks, start, distFn, opts) -> tâches ordonnées
--   tasks  = { { id, kind = "A"|"O"|"T"|"C", q, pos, endPos = pos|nil, dur, after = {ids}, final = bool }, ... }
--            (kind "C" = quête faite d'une traite, prise en `pos` et rendue en `endPos`)
--   start  = position de départ ; distFn(posA, posB) -> secondes de trajet
--   opts   = { logCap = 20, initialLog = 0, finish = pos|nil, tieSeconds = 20/7, maxPasses = 200,
--              levelXP = xp.LEVEL_XP|nil, level = n, xp = n, maxSegment = 3,
--              anneal = bool, seed = n, annealIters = n, annealMax = n, T0 = s, T1 = s }
--   Facultatif sur une tâche : reqLevel (niveau requis pour une tâche A ou C) et gain(level) -> XP.
--
-- Contraintes : chaque tâche passe après ses `after` ; le journal compte au plus logCap quêtes
-- acceptées non rendues (A +1, T −1) ; une tâche `final` attend toutes les tâches non finales ;
-- avec levelXP, une tâche A ou C attend que le niveau simulé atteigne son reqLevel. Quand plus rien
-- n'est possible, la tâche bloquée par le plus petit niveau est marquée `needLevel` (farm avant) ;
-- sinon une tâche finale est avancée, et en dernier recours le plafond est dépassé (signalé).
-- Renvoie seq, issues (liste de messages pour le rapport ; vide si tout est respecté).
-- Méthode : plus proche voisin faisable (égalité à moins de 20 yd : T avant A avant O), puis or-opt
-- (déplacement de segments de 1 à maxSegment tâches) tant que le temps total de trajet baisse, puis,
-- si opts.anneal, recuit simulé sur les mêmes déplacements et nouveau passage d'or-opt.

local order = {}

local KIND_RANK = { T = 1, A = 2, C = 2, O = 3 }

local function logDelta(task)
  if task.kind == "A" then return 1 elseif task.kind == "T" then return -1 end
  return 0
end

-- Niveau simulé : ajoute le gain d'une tâche et passe les niveaux.
local function advance(t, level, xp, levelXP)
  if not levelXP then return level, xp end
  if t.needLevel and t.reqLevel and level < t.reqLevel then level, xp = t.reqLevel, 0 end
  local g = t.gain and t.gain(level) or 0
  xp = xp + g
  while levelXP[level] and xp >= levelXP[level] do xp = xp - levelXP[level]; level = level + 1 end
  return level, xp
end

local function levelOk(t, level, levelXP)
  if not levelXP or not t.reqLevel or t.needLevel then return true end
  if t.kind ~= "A" and t.kind ~= "C" then return true end
  return level >= t.reqLevel
end

-- Vérifie qu'une séquence respecte précédences, tâches finales, plafond du journal et niveaux.
function order.feasible(seq, opts)
  opts = opts or {}
  local cap = opts.logCap or 20
  local log = opts.initialLog or 0
  local level, xp, levelXP = opts.level or 1, opts.xp or 0, opts.levelXP
  local placed, nonFinalLeft = {}, 0
  for _, t in ipairs(seq) do if not t.final then nonFinalLeft = nonFinalLeft + 1 end end
  for _, t in ipairs(seq) do
    for _, a in ipairs(t.after or {}) do
      if placed[a] == nil and opts.ids and opts.ids[a] then return false end
    end
    if t.final and nonFinalLeft > 0 then return false end
    if not levelOk(t, level, levelXP) then return false end
    log = log + logDelta(t)
    if log > cap then return false end
    level, xp = advance(t, level, xp, levelXP)
    placed[t.id] = true
    if not t.final then nonFinalLeft = nonFinalLeft - 1 end
  end
  return true
end

local function cost(seq, start, distFn, finish)
  local total, prev = 0, start
  for _, t in ipairs(seq) do
    total = total + distFn(prev, t.pos)
    prev = t.endPos or t.pos
  end
  if finish then total = total + distFn(prev, finish) end
  return total
end
order.cost = cost

function order.build(tasks, start, rawDist, opts)
  opts = opts or {}
  -- Coûts quantifiés en centièmes de seconde (entiers) : les comparaisons ne dépendent plus du bruit
  -- flottant (code compilé par le JIT ou interprété), d'où un résultat reproductible.
  local function distFn(a, b) return math.floor(rawDist(a, b) * 100 + 0.5) end
  local cap = opts.logCap or 20
  local tie = math.floor((opts.tieSeconds or (20 / 7)) * 100 + 0.5)
  local ids = {}
  for _, t in ipairs(tasks) do ids[t.id] = t end
  local levelXP = opts.levelXP
  for _, t in ipairs(tasks) do t.needLevel = nil end
  local fopts = { logCap = cap, initialLog = opts.initialLog or 0, ids = ids, levelXP = levelXP,
                  level = opts.level or 1, xp = opts.xp or 0 }

  local issues = {}
  -- 1. Plus proche voisin faisable
  local done, seq, pos, log = {}, {}, start, opts.initialLog or 0
  local level, xp = opts.level or 1, opts.xp or 0
  local nonFinalLeft = 0
  for _, t in ipairs(tasks) do if not t.final then nonFinalLeft = nonFinalLeft + 1 end end
  local remaining = #tasks
  while remaining > 0 do
    local best, bestD
    for idx, t in ipairs(tasks) do
      if not done[t.id] then
        local ok = not (t.final and nonFinalLeft > 0)
        if ok then
          for _, a in ipairs(t.after or {}) do
            if ids[a] and not done[a] then ok = false; break end
          end
        end
        if ok and t.kind == "A" and log + 1 > cap then ok = false end
        if ok and not levelOk(t, level, levelXP) then ok = false end
        if ok then
          local d = distFn(pos, t.pos)
          if not best then best, bestD = t, d
          else
            if d < bestD - tie then best, bestD = t, d
            elseif math.abs(d - bestD) <= tie then
              local rb, rt = KIND_RANK[best.kind] or 9, KIND_RANK[t.kind] or 9
              if rt < rb or (rt == rb and d < bestD) then best, bestD = t, d end
            end
          end
        end
        t._idx = t._idx or idx
      end
    end
    if not best then
      -- impasse : une prise bloquée par le niveau (la plus basse) passe après un farm ; sinon
      -- (contrainte impossible) on prend la première tâche restante pour ne pas boucler
      for _, t in ipairs(tasks) do
        if not done[t.id] and t.reqLevel and (t.kind == "A" or t.kind == "C") and not levelOk(t, level, levelXP) then
          local free = not (t.final and nonFinalLeft > 0) and not (t.kind == "A" and log + 1 > cap)
          for _, a in ipairs(t.after or {}) do if ids[a] and not done[a] then free = false end end
          if free and (not best or t.reqLevel < best.reqLevel) then best = t end
        end
      end
      if best then best.needLevel = true end
      local function afterOk(t)
        for _, a in ipairs(t.after or {}) do if ids[a] and not done[a] then return false end end
        return true
      end
      if not best then
        -- tâche « finale » (rendu hors région, quête reprise du chapitre précédent) avancée pour
        -- libérer le journal : on retire son caractère final plutôt que de dépasser le plafond
        for _, t in ipairs(tasks) do
          if not done[t.id] and t.final and afterOk(t) and not (t.kind == "A" and log + 1 > cap)
             and levelOk(t, level, levelXP) and (not best or (KIND_RANK[t.kind] or 9) < (KIND_RANK[best.kind] or 9)) then
            best = t
          end
        end
        if best then
          best.final = nil
          nonFinalLeft = nonFinalLeft + 1
          issues[#issues + 1] = ("task %s moved before the end of the chapter to free the quest log"):format(best.id)
        end
      end
      if not best then
        -- dernier recours : une prise qui dépasse le plafond du journal (signalée ; le validateur la refusera)
        for _, t in ipairs(tasks) do
          if not done[t.id] and afterOk(t) and not (t.final and nonFinalLeft > 0) then best = t; break end
        end
        if best then
          cap = cap + 1
          fopts.logCap = cap
          issues[#issues + 1] = ("quest log cap exceeded to place task %s (log %d)"):format(best.id, log + 1)
        end
      end
      if not best then
        for _, t in ipairs(tasks) do if not done[t.id] then best = t; break end end
        issues[#issues + 1] = ("no feasible task left: %s placed against its constraints"):format(best.id)
      end
      bestD = distFn(pos, best.pos)
    end
    done[best.id] = true
    seq[#seq + 1] = best
    pos = best.endPos or best.pos
    log = log + logDelta(best)
    level, xp = advance(best, level, xp, levelXP)
    if not best.final then nonFinalLeft = nonFinalLeft - 1 end
    remaining = remaining - 1
  end

  -- 2. Or-opt : déplacer un segment de 1 à maxSegment tâches tant que le coût baisse.
  local finish = opts.finish
  local maxPasses = opts.maxPasses or 200
  -- position de sortie de l'élément i (départ si i < 1) ; posIn = position d'entrée
  local function posAt(s, i)
    if i < 1 then return start end
    return s[i] and (s[i].endPos or s[i].pos) or nil
  end
  local function posIn(s, i)
    return s[i] and s[i].pos or nil
  end
  -- coût d'un raccord prev -> (nxt ou fin de parcours)
  local function link(p, q)
    if q then return distFn(p, q) end
    if finish then return distFn(p, finish) end
    return 0
  end
  -- variation de coût quand le segment [i, i + len - 1] est inséré après l'élément j
  local function moveDelta(s, i, len, j)
    local prev, nxt = posAt(s, i - 1), posIn(s, i + len)
    local first, last = s[i].pos, s[i + len - 1].endPos or s[i + len - 1].pos
    local removeGain = distFn(prev, first) + link(last, nxt) - link(prev, nxt)
    local pj, nj = posAt(s, j), posIn(s, j + 1)
    local addCost = distFn(pj, first) + link(last, nj) - link(pj, nj)
    return addCost - removeGain
  end
  local function moved(s, i, len, j)
    local cand, n = {}, #s
    if j == 0 then for k = i, i + len - 1 do cand[#cand + 1] = s[k] end end
    for k = 1, n do
      if k < i or k > i + len - 1 then cand[#cand + 1] = s[k] end
      if k == j then for x = i, i + len - 1 do cand[#cand + 1] = s[x] end end
    end
    return cand
  end
  local function oropt(s, current)
    for _ = 1, maxPasses do
      local improved = false
      local n = #s
      for len = 1, (opts.maxSegment or 3) do
        local i = 1
        while i + len - 1 <= n do
          local bestCand, bestCost
          for j = 0, n do
            -- insertion après l'élément j (hors segment et hors position actuelle)
            if (j < i - 1 or j > i + len - 1) and moveDelta(s, i, len, j) < 0 then
              local cand = moved(s, i, len, j)
              if order.feasible(cand, fopts) then
                local c = cost(cand, start, distFn, finish)
                if c < current and (not bestCost or c < bestCost) then bestCand, bestCost = cand, c end
              end
            end
          end
          if bestCand then
            s, current = bestCand, bestCost
            improved = true
          end
          i = i + 1
        end
      end
      if not improved then break end
    end
    return s, current
  end
  local current
  seq, current = oropt(seq, cost(seq, start, distFn, finish))

  -- 3. Recuit simulé (opts.anneal) : déplacements aléatoires de segments de 1 à 12 tâches, acceptés
  -- selon la température (secondes de trajet), en gardant la meilleure séquence faisable ; puis
  -- nouveau passage d'or-opt. Générateur pseudo-aléatoire à graine fixe : résultat reproductible.
  if opts.anneal and #seq > 4 then
    local state = (opts.seed or 12345) % 2147483647
    if state <= 0 then state = state + 2147483646 end
    local function rand()
      state = (state * 16807) % 2147483647
      return state / 2147483647
    end
    local n = #seq
    local iters = math.min(opts.annealIters or 40 * n * n, opts.annealMax or 400000)
    local T0, T1 = (opts.T0 or 60) * 100, (opts.T1 or 0.5) * 100
    local best, bestCost = seq, current
    local curSeq, curCost = seq, current
    local maxLen = math.min(12, n - 1)
    for it = 1, iters do
      local T = T0 * (T1 / T0) ^ (it / iters)
      local len = 1 + math.floor(rand() * rand() * maxLen)
      local i = 1 + math.floor(rand() * (n - len + 1))
      local j = math.floor(rand() * (n + 1))
      if j < i - 1 or j > i + len - 1 then
        local delta = moveDelta(curSeq, i, len, j)
        -- déplacement neutre (delta = 0) refusé : il défait le regroupement des prises au hub
        if delta < 0 or (delta > 0 and rand() < math.exp(-delta / T)) then
          local cand = moved(curSeq, i, len, j)
          if order.feasible(cand, fopts) then
            curSeq, curCost = cand, cost(cand, start, distFn, finish)
            if curCost < bestCost then best, bestCost = curSeq, curCost end
          end
        end
      end
    end
    seq, current = oropt(best, bestCost)
  end

  -- 4. Prises au premier passage : une prise (A) ou un point de vol (F) est avancé juste après la
  -- première tâche faite au même endroit (à moins de tieSeconds), si la séquence reste faisable et
  -- le trajet pas plus long. On ramasse ainsi toutes les quêtes d'un hub quand on y passe.
  local hoisted = true
  local guard = 0
  while hoisted and guard < 5 * #seq do
    hoisted, guard = false, guard + 1
    for k = 2, #seq do
      local t = seq[k]
      if t.kind == "A" or t.kind == "F" then
        for j = 1, k - 1 do
          if distFn(posAt(seq, j), t.pos) <= tie then
            if j < k - 1 and moveDelta(seq, k, 1, j) <= 0 then
              local cand = moved(seq, k, 1, j)
              if order.feasible(cand, fopts) then
                seq = cand
                hoisted = true
              end
            end
            break
          end
        end
        if hoisted then break end
      end
    end
  end
  for _, t in ipairs(tasks) do t._idx = nil end
  if not order.feasible(seq, fopts) then
    issues[#issues + 1] = "final task order breaks a constraint (precedence, final turn-ins, log cap or level)"
  end
  return seq, issues
end

return order

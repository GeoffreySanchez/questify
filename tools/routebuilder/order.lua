-- tools/routebuilder/order.lua : ordonnancement des tâches d'un chapitre.
--
-- order.build(tasks, start, distFn, opts) -> tâches ordonnées
--   tasks  = { { id, kind = "A"|"O"|"T"|"C", q, pos, endPos = pos|nil, dur, after = {ids}, final = bool }, ... }
--            (kind "C" = quête faite d'une traite, prise en `pos` et rendue en `endPos`)
--   start  = position de départ ; distFn(posA, posB) -> secondes de trajet
--   opts   = { logCap = 20, initialLog = 0, finish = pos|nil, tieSeconds = 20/7, maxPasses = 200,
--              levelXP = xp.LEVEL_XP|nil, level = n, xp = n, maxSegment = 3,
--              grindCost = function(level, xp, targetLevel) -> s | nil,
--              sweep = { hub = s, turnin = s, area = s } | nil,
--              anneal = bool, seed = n, annealIters = n, annealMax = n, T0 = s, T1 = s }
--   Facultatif sur une tâche : reqLevel (niveau requis pour une tâche A, C ou O) et gain(level) -> XP.
--
-- Contraintes : chaque tâche passe après ses `after` ; le journal compte au plus logCap quêtes
-- acceptées non rendues (A +1, T −1) ; une tâche `final` attend toutes les tâches non finales ;
-- avec levelXP, une tâche A ou C attend que le niveau simulé atteigne son reqLevel. Quand plus rien
-- n'est possible, la tâche bloquée par le plus petit niveau est marquée `needLevel` (farm avant) ;
-- sinon une tâche finale est avancée, et en dernier recours le plafond est dépassé (signalé).
-- Le farm d'une tâche `needLevel` (du niveau atteint à son reqLevel) est compté dans le coût avec
-- opts.grindCost : or-opt et recuit ne l'avancent donc plus vers un niveau plus bas pour gagner
-- quelques mètres de marche (le temps de farm en plus l'emporte), et peuvent la retarder.
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
  if t.kind ~= "A" and t.kind ~= "C" and t.kind ~= "O" then return true end
  return level >= t.reqLevel
end

-- Vérifie qu'une séquence respecte précédences, tâches finales, plafond du journal et niveaux.
-- Renvoie aussi le coût du farm des tâches `needLevel` (opts.grindCost, en unités de opts.grindCost).
local function check(seq, opts)
  local cap = opts.logCap or 20
  local log = opts.initialLog or 0
  local level, xp, levelXP = opts.level or 1, opts.xp or 0, opts.levelXP
  local grindCost, grind = opts.grindCost, 0
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
    if grindCost and t.needLevel and t.reqLevel and levelXP and level < t.reqLevel then
      grind = grind + grindCost(level, xp, t.reqLevel)
    end
    level, xp = advance(t, level, xp, levelXP)
    placed[t.id] = true
    if not t.final then nonFinalLeft = nonFinalLeft - 1 end
  end
  return true, grind
end

function order.feasible(seq, opts)
  return (check(seq, opts or {}))
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
  -- farm compté en centièmes de seconde entiers (comme les trajets)
  local grindCost = opts.grindCost and levelXP and function(level, xp, target)
    return math.floor(opts.grindCost(level, xp, target) * 100 + 0.5)
  end or nil
  local fopts = { logCap = cap, initialLog = opts.initialLog or 0, ids = ids, levelXP = levelXP,
                  level = opts.level or 1, xp = opts.xp or 0, grindCost = grindCost }

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
        if not done[t.id] and t.reqLevel and (t.kind == "A" or t.kind == "C" or t.kind == "O") and not levelOk(t, level, levelXP) then
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
  -- coût complet d'une séquence faisable : trajet + farm ; nil si infaisable
  local function fullCost(cand)
    local ok, grind = check(cand, fopts)
    if not ok then return nil end
    return cost(cand, start, distFn, finish) + grind, grind
  end
  -- segment qui contient une tâche à farmer : déplacement évalué même s'il allonge la marche
  local function hasNeed(s, i, len)
    if not grindCost then return false end
    for k = i, i + len - 1 do if s[k].needLevel then return true end end
    return false
  end
  local function oropt(s, current)
    for _ = 1, maxPasses do
      local improved = false
      local n = #s
      for len = 1, (opts.maxSegment or 3) do
        local i = 1
        while i + len - 1 <= n do
          local bestCand, bestCost
          local need = hasNeed(s, i, len)
          for j = 0, n do
            -- insertion après l'élément j (hors segment et hors position actuelle)
            if (j < i - 1 or j > i + len - 1) and (need or moveDelta(s, i, len, j) < 0) then
              local cand = moved(s, i, len, j)
              local c = fullCost(cand)
              if c and c < current and (not bestCost or c < bestCost) then bestCand, bestCost = cand, c end
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
  local current = fullCost(seq) or cost(seq, start, distFn, finish)
  seq, current = oropt(seq, current)

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
    local curGrind = select(2, check(seq, fopts)) or 0
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
          local ok, grind = check(cand, fopts)
          -- farm en plus : même règle d'acceptation sur le seul supplément de farm
          if ok and grind > curGrind and rand() >= math.exp(-(grind - curGrind) / T) then ok = false end
          if ok then
            curSeq, curCost, curGrind = cand, cost(cand, start, distFn, finish) + grind, grind
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
  local seqGrind = select(2, check(seq, fopts)) or 0
  while hoisted and guard < 5 * #seq do
    hoisted, guard = false, guard + 1
    for k = 2, #seq do
      local t = seq[k]
      if t.kind == "A" or t.kind == "F" then
        for j = 1, k - 1 do
          if distFn(posAt(seq, j), t.pos) <= tie then
            if j < k - 1 and moveDelta(seq, k, 1, j) <= 0 then
              local cand = moved(seq, k, 1, j)
              local ok, grind = check(cand, fopts)
              if ok and grind <= seqGrind then
                seq, seqGrind = cand, grind
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
  -- 5. Balayage (opts.sweep, rayons en secondes de marche) : à chaque tâche de la séquence, les tâches
  -- plus loin qui se font au même endroit sont ramenées juste après elle si la séquence reste
  -- faisable (précédences, journal, niveaux ; farm pas plus long) :
  --   * prises (A) et points de vol (F) à moins de sweep.hub : tout ce qui se prend au hub ;
  --   * rendus (T) à moins de sweep.turnin : rendu au passage ;
  --   * objectifs (O) et prises par objet ramassé (A itemStart) à moins de sweep.area d'un objectif :
  --     un seul passage par zone d'objectifs.
  -- Puis, dans chaque zone, ordre objets > mobs nommés ou élites > mobs ordinaires (t.cat 1, 2, 3),
  -- dans le respect des précédences (clé lâchée par un mob nommé avant le coffre).
  if opts.sweep then
    local R = { hub = math.floor(opts.sweep.hub * 100 + 0.5), turnin = math.floor(opts.sweep.turnin * 100 + 0.5),
                area = math.floor(opts.sweep.area * 100 + 0.5) }
    local function isAreaTask(t) return t.kind == "O" or (t.kind == "A" and t.itemStart) end
    local function radiusFor(t, anchor)
      if t.final or t.kind == "C" then return nil end
      if isAreaTask(t) and isAreaTask(anchor) then return R.area end
      if t.kind == "A" or t.kind == "F" then return R.hub end
      if t.kind == "T" then return R.turnin end
      return nil
    end
    local seqGrind2 = select(2, check(seq, fopts)) or 0
    local changed, rounds = true, 0
    while changed and rounds < 8 do
      changed, rounds = false, rounds + 1
      local k = 1
      while k <= #seq do
        local anchor = seq[k]
        local apos = anchor.endPos or anchor.pos
        local ins = k
        local j = k + 1
        while j <= #seq do
          local t = seq[j]
          local r = radiusFor(t, anchor)
          if r and distFn(apos, t.pos) <= r then
            if j == ins + 1 then
              ins = j
            else
              local cand = moved(seq, j, 1, ins)
              local ok, grind = check(cand, fopts)
              if ok and grind <= seqGrind2 then
                seq, seqGrind2, ins, changed = cand, grind, ins + 1, true
              end
            end
          end
          j = j + 1
        end
        k = k + 1
      end
    end
    -- ordre interne des zones d'objectifs
    local i = 1
    while i <= #seq do
      local first = seq[i]
      local e = i
      if isAreaTask(first) then
        while e + 1 <= #seq and isAreaTask(seq[e + 1]) and distFn(first.pos, seq[e + 1].pos) <= R.area do e = e + 1 end
      end
      if e > i then
        local run, inRun = {}, {}
        for k = i, e do run[#run + 1] = seq[k]; inRun[seq[k].id] = true end
        local want, placed = {}, {}
        while #want < #run do
          local pick
          for _, t in ipairs(run) do
            if not placed[t.id] then
              local ready = true
              for _, a in ipairs(t.after or {}) do if inRun[a] and not placed[a] then ready = false end end
              if ready and (not pick or (t.cat or 3) < (pick.cat or 3)) then pick = t end
            end
          end
          if not pick then break end
          placed[pick.id] = true
          want[#want + 1] = pick
        end
        if #want == #run then
          local cand = {}
          for k = 1, i - 1 do cand[#cand + 1] = seq[k] end
          for _, t in ipairs(want) do cand[#cand + 1] = t end
          for k = e + 1, #seq do cand[#cand + 1] = seq[k] end
          local ok, grind = check(cand, fopts)
          if ok and grind <= seqGrind2 then seq, seqGrind2 = cand, grind end
        end
      end
      i = e + 1
    end
  end

  for _, t in ipairs(tasks) do t._idx = nil end
  if not order.feasible(seq, fopts) then
    issues[#issues + 1] = "final task order breaks a constraint (precedence, final turn-ins, log cap or level)"
  end
  return seq, issues
end

return order

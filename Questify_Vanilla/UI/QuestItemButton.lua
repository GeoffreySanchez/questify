local addonName, Q = ...

-- Bouton de l'objet de quête à utiliser pour l'étape courante (fiole, torche, objet à poser…).
-- Objet retenu : celui que le journal de quêtes désigne (GetQuestLogSpecialItemInfo) ; sinon le
-- premier objet des sacs parmi ceux que la quête donne ou demande (QuestieDB) et qui a un effet
-- « Utiliser » (GetItemSpell). Bouton sécurisé (type « item ») posé à gauche du suivi par
-- coordonnées d'écran, jamais ancré au suivi ; ses attributs, sa position et son affichage ne
-- changent que hors combat (en combat : en attente, appliqué sur PLAYER_REGEN_ENABLED).
-- Raccourci clavier dans les Raccourcis du jeu (Bindings.xml). Option questItemButton.
Q.UI = Q.UI or {}
local Btn = { pending = false }
Q.UI.QuestItemButton = Btn

local L = Q.L

local SIZE = 36
local GAP = 6
local BUTTON_NAME = "QuestifyVanillaQuestItem"

local function setting(path) return Q.Settings:Get(path) end
local function inCombat() return InCombatLockdown and InCombatLockdown() end

local function call(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a, b, c, d = pcall(fn, ...)
  if not ok then return nil end
  return a, b, c, d
end

local function itemCount(id)
  return tonumber(call((C_Item and C_Item.GetItemCount) or GetItemCount, id)) or 0
end

local function itemSpell(id)
  return call((C_Item and C_Item.GetItemSpell) or GetItemSpell, id)
end

local function itemIcon(id)
  return call((C_Item and C_Item.GetItemIconByID) or GetItemIcon, id) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function idOf(link)
  return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

---------------------------------------------------------------------------
-- Objet de l'étape
---------------------------------------------------------------------------
-- ItemFor(entry) -> itemId ou nil
function Btn:ItemFor(entry)
  local step = type(entry) == "table" and entry.step
  if type(step) ~= "table" or not step.questId then return nil end
  if step.action ~= "complete" and step.action ~= "turnin" then return nil end
  local qid = step.questId
  if not Q.Progress:InLog(qid) then return nil end
  -- 1. objet désigné par le journal
  local logIndex = call(C_QuestLog and C_QuestLog.GetLogIndexForQuestID, qid)
  if logIndex and type(GetQuestLogSpecialItemInfo) == "function" then
    local link = call(GetQuestLogSpecialItemInfo, logIndex)
    local id = idOf(link)
    if id and itemCount(id) > 0 then return id end
  end
  -- 2. objets donnés ou demandés par la quête, présents dans les sacs et utilisables
  if step.action ~= "complete" then return nil end
  local q = Q.QDB:Quest(qid)
  if not q then return nil end
  local cands = {}
  if q.sourceItem then cands[#cands + 1] = q.sourceItem end
  for _, id in ipairs(q.sourceItems or {}) do cands[#cands + 1] = id end
  for _, o in ipairs(q.objectives and q.objectives.ordered or {}) do
    if o.kind == "item" and o.ids[1] then cands[#cands + 1] = o.ids[1] end
  end
  for _, id in ipairs(cands) do
    if itemCount(id) > 0 and itemSpell(id) then return id end
  end
  return nil
end

---------------------------------------------------------------------------
-- Bouton
---------------------------------------------------------------------------
function Btn:Create()
  if self.button then return self.button end
  local b = CreateFrame("Button", BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
  b:SetSize(SIZE, SIZE)
  b:SetFrameStrata("MEDIUM")
  b:RegisterForClicks("AnyUp", "AnyDown")
  b:SetAttribute("type", "item")
  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints(b)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  border:SetBlendMode("ADD")
  border:SetVertexColor(1, 0.82, 0)
  border:SetPoint("CENTER", b, "CENTER", 0, 0)
  border:SetSize(SIZE * 1.8, SIZE * 1.8)
  local count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
  hl:SetBlendMode("ADD")
  hl:SetAllPoints(b)
  local cd = CreateFrame("Cooldown", BUTTON_NAME .. "Cooldown", b, "CooldownFrameTemplate")
  cd:SetAllPoints(b)
  b:SetScript("OnEnter", function(self)
    if not (GameTooltip and Btn.itemId) then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    if GameTooltip.SetItemByID then GameTooltip:SetItemByID(Btn.itemId) else GameTooltip:SetHyperlink("item:" .. Btn.itemId) end
    GameTooltip:AddLine(L.UI_QUESTITEM_HINT, 0.6, 0.8, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  b:Hide()
  self.button, self.icon, self.count, self.cooldown = b, icon, count, cd
  return b
end

-- Textes et compte à rebours : autorisés en combat (régions, pas le cadre sécurisé).
function Btn:UpdateLook()
  local id = self.itemId
  if not (self.button and id) then return end
  self.icon:SetTexture(itemIcon(id))
  local n = itemCount(id)
  self.count:SetText(n > 1 and tostring(n) or "")
  self.icon:SetDesaturated(n == 0)
  local start, duration = call((C_Container and C_Container.GetItemCooldown) or GetItemCooldown, id)
  if start and duration and duration > 0 and self.cooldown.SetCooldown then
    self.cooldown:SetCooldown(start, duration)
  end
end

-- Position : à gauche du coin haut du suivi, en coordonnées d'écran.
local function place(b)
  local T = Q.UI.Tracker and Q.UI.Tracker.frame
  b:ClearAllPoints()
  local left, top = T and T:GetLeft(), T and T:GetTop()
  if left and top then
    b:SetScale(T:GetScale() or 1)
    local k = T:GetEffectiveScale() / b:GetEffectiveScale()
    b:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", left * k - GAP, top * k - 40)
  else
    b:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
  end
end

function Btn:Refresh()
  local want
  if setting("questItemButton") ~= false and Q.Progress and Q.Progress:IsEnabled() then
    want = self:ItemFor(Q.Progress:Current())
  end
  if inCombat() then
    if want ~= self.itemId then self.pending = true end
    self:UpdateLook()
    return
  end
  self.pending = false
  local b = self:Create()
  if not want then
    self.itemId = nil
    b:Hide()
    return
  end
  self.itemId = want
  local attr = "item:" .. want
  if b:GetAttribute("item") ~= attr then b:SetAttribute("item", attr) end
  place(b)
  b:Show()
  self:UpdateLook()
end

-- Le suivi a bougé ou changé de taille (hors combat seulement).
function Btn:Reposition()
  if not (self.button and self.button:IsShown()) then return end
  if inCombat() then
    self.pending = true
    return
  end
  place(self.button)
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
_G["BINDING_NAME_CLICK " .. BUTTON_NAME .. ":LeftButton"] = L.UI_QUESTITEM_BINDING

local function refresh() Q.SafeCall(Btn.Refresh, Btn) end
Q:On("LOGIN", refresh)
Q:On("PROGRESS_UPDATED", refresh)
Q:On("STEP_CHANGED", refresh)
Q:On("SETTINGS_CHANGED", function(path) if path == "questItemButton" or path == "tracker.scale" then refresh() end end)
Q:RegisterEvent("BAG_UPDATE_DELAYED", refresh)
Q:RegisterEvent("BAG_UPDATE_COOLDOWN", function() Q.SafeCall(Btn.UpdateLook, Btn) end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if Btn.pending then refresh() end
end)

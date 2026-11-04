local addonName, Q = ...

-- Vérification de version entre joueurs qui ont l'addon.
-- Un message d'addon silencieux (préfixe QVVER, jamais affiché dans la discussion) porte la
-- version installée :
--   - à la guilde, une fois, quelques secondes après la connexion (seulement si le joueur en a une) ;
--   - au groupe, à chaque changement de composition, au plus une fois par minute
--     (INSTANCE_CHAT en groupe d'instance, sinon RAID en raid, sinon PARTY) ;
--   - jamais hors groupe et hors guilde ;
--   - jamais en combat : l'envoi attend la fin du combat (les messages d'addon envoyés en combat
--     peuvent être bridés), ou la fin du verrouillage de la messagerie.
-- Réception d'une version plus récente : une ligne dans la discussion et un message court au
-- milieu de l'écran, une seule fois par session ; la mise à jour se fait ensuite via CurseForge.
-- Réception d'une version plus ancienne : réponse avec notre version sur le même canal (en
-- chuchotement à l'expéditeur pour un chuchotement), au plus une par minute tous joueurs
-- confondus, et jamais deux fois au même joueur dans la session.
-- Option « versionCheck » (activée par défaut) : désactivée, rien n'est inscrit ni envoyé.
-- Une API absente (C_ChatInfo, IsInGuild, GetTime…) rend le module muet, sans erreur.
local VC = {}
Q.VersionCheck = VC

VC.PREFIX = "QVVER"
VC.LOGIN_DELAY = 8        -- secondes entre PLAYER_LOGIN et l'envoi à la guilde
VC.GROUP_INTERVAL = 60    -- secondes au moins entre deux envois au groupe
VC.REPLY_INTERVAL = 60    -- secondes au moins entre deux réponses, tous joueurs confondus
VC.RETRY_DELAY = 10       -- nouvel essai quand la messagerie est verrouillée hors combat

local MAX_VERSION_LENGTH = 32   -- au-delà, le texte reçu n'est pas une version
local MAX_PART_DIGITS = 6       -- chiffres au plus par composante (MAJOR, MINOR, PATCH)

-- Canaux sur lesquels une réponse est possible (CHANNEL demanderait un numéro de canal).
local REPLY_CHANNELS = {
  GUILD = true, OFFICER = true, PARTY = true, RAID = true, INSTANCE_CHAT = true, WHISPER = true,
}

-- Option par défaut : ajoutée aux valeurs par défaut des réglages avant leur copie à l'INIT
-- (Core/Settings.lua est chargé avant ce fichier).
if Q.Settings and type(Q.Settings.defaults) == "table" and Q.Settings.defaults.versionCheck == nil then
  Q.Settings.defaults.versionCheck = true
end

---------------------------------------------------------------------------
-- Versions (MAJOR.MINOR.PATCH, suffixe facultatif ignoré pour la comparaison)
---------------------------------------------------------------------------
-- Parse("1.2.3-beta") -> { 1, 2, 3 } ; nil si le texte n'est pas une version.
-- Le suffixe (« -beta », « -alpha.2 », « +build ») est admis mais ignoré. Seuls chiffres,
-- lettres, « . », « - » et « + » sont acceptés : un texte reçu valide peut donc être affiché.
function VC.Parse(text)
  if type(text) ~= "string" or #text == 0 or #text > MAX_VERSION_LENGTH then return nil end
  local major, minor, patch, rest = text:match("^(%d+)%.(%d+)%.(%d+)(.*)$")
  if not major then return nil end
  if #major > MAX_PART_DIGITS or #minor > MAX_PART_DIGITS or #patch > MAX_PART_DIGITS then return nil end
  if rest ~= "" and not rest:match("^[%-+][%w%.%-+]*$") then return nil end
  return { tonumber(major), tonumber(minor), tonumber(patch) }
end

-- Compare(a, b) -> -1 (a plus ancienne), 0 (égales), 1 (a plus récente) ; nil si l'une des deux
-- n'est pas une version. a et b sont des textes ou des résultats de Parse.
function VC.Compare(a, b)
  local pa = type(a) == "table" and a or VC.Parse(a)
  local pb = type(b) == "table" and b or VC.Parse(b)
  if not (pa and pb) then return nil end
  for i = 1, 3 do
    if pa[i] ~= pb[i] then return pa[i] < pb[i] and -1 or 1 end
  end
  return 0
end

---------------------------------------------------------------------------
-- Lecture prudente du client
---------------------------------------------------------------------------
-- Appel protégé : première valeur de l'API, ou nil (API absente, erreur, valeur secrète).
local function call(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, v = pcall(fn, ...)
  if not ok or Q.Util.IsSecret(v) then return nil end
  return v
end

-- Fonction de C_ChatInfo, ou nil.
local function chatApi(name)
  local api = C_ChatInfo
  if type(api) ~= "table" then return nil end
  local fn = api[name]
  if type(fn) ~= "function" then return nil end
  return fn
end

-- Notre version : métadonnée « Version » du TOC, sinon Q.version ; nil si ce n'est pas une
-- version (« dev ») : rien n'est alors envoyé ni comparé.
function VC.MyVersion()
  local get = type(C_AddOns) == "table" and C_AddOns.GetAddOnMetadata or nil
  local v = call(get, addonName, "Version")
  if type(v) == "string" and VC.Parse(v) then return v end
  v = Q.version
  if type(v) == "string" and VC.Parse(v) then return v end
  return nil
end

local function now()
  return call(GetTime) or 0
end

local function inCombat()
  return call(InCombatLockdown) == true
end

-- Verrouillage de la messagerie (restrictions de sécurité du client, rencontres…).
local function chatLocked()
  return call(chatApi("InChatMessagingLockdown")) == true
end

local function isBlocked()
  return inCombat() or chatLocked()
end

-- Canal du groupe : INSTANCE_CHAT, RAID, PARTY, ou nil hors groupe.
function VC.GroupChannel()
  if LE_PARTY_CATEGORY_INSTANCE ~= nil and call(IsInGroup, LE_PARTY_CATEGORY_INSTANCE) == true then
    return "INSTANCE_CHAT"
  end
  if call(IsInRaid) == true then return "RAID" end
  if call(IsInGroup) == true then return "PARTY" end
  return nil
end

-- Vrai si l'expéditeur est le joueur lui-même (« Nom » ou « Nom-Royaume »). Nom secret ou
-- illisible : faux (un message de soi porte notre version et ne déclenche alors rien).
local function isSelf(sender)
  local me = call(UnitName, "player")
  if type(me) ~= "string" or me == "" then return false end
  local name, realm = sender:match("^([^%-]+)%-(.+)$")
  if not name then return sender == me end
  if name ~= me then return false end
  local myRealm = call(GetNormalizedRealmName)
  if type(myRealm) ~= "string" or myRealm == "" then return true end
  return realm == myRealm
end

---------------------------------------------------------------------------
-- État de la session
---------------------------------------------------------------------------
local state = {
  enabled = false,      -- préfixe et évènements inscrits
  notified = false,     -- avertissement de mise à jour déjà affiché
  newest = nil,         -- version la plus récente reçue d'un autre joueur (texte)
  guildSent = false,    -- envoi à la guilde de la session fait
  guildTimer = false,   -- envoi à la guilde programmé
  lastGroup = nil,      -- GetTime() du dernier envoi au groupe
  groupTimer = false,   -- envoi au groupe différé (fenêtre d'une minute)
  lastReply = nil,      -- GetTime() de la dernière réponse
  replied = {},         -- [expéditeur] = true : déjà répondu
  queue = {},           -- [clé] = fonction : envois en attente de la fin du combat
  queueOrder = {},      -- clés de queue dans l'ordre d'arrivée
  retryTimer = false,   -- nouvel essai programmé (verrouillage hors combat)
}

local function isActive()
  return state.enabled and Q.Settings:Get("versionCheck") == true and type(GetTime) == "function"
end

-- Version la plus récente vue chez un autre joueur pendant la session, ou nil.
function VC:NewestSeen()
  return state.newest
end

---------------------------------------------------------------------------
-- Envoi
---------------------------------------------------------------------------
-- Envoie notre version sur un canal (cible : nom du destinataire d'un chuchotement).
-- Vrai si l'appel a eu lieu.
local function transmit(channel, target)
  local send = chatApi("SendAddonMessage")
  local version = VC.MyVersion()
  if not (send and version and channel) then return false end
  local ok, res = pcall(send, VC.PREFIX, version, channel, target)
  if not ok then
    Q:Debug("versioncheck: send failed", channel, res)
    return false
  end
  Q:Debug("versioncheck: sent", version, channel, target, res)
  return true
end

local flush

local function scheduleRetry()
  if state.retryTimer then return end
  state.retryTimer = true
  Q:After(VC.RETRY_DELAY, function()
    state.retryTimer = false
    flush()
  end)
end

-- Met un envoi en attente (un seul par clé). La fin du combat le relance ; un verrouillage de la
-- messagerie hors combat est réessayé quelques secondes plus tard.
local function enqueue(key, fn)
  if not state.queue[key] then
    state.queue[key] = fn
    state.queueOrder[#state.queueOrder + 1] = key
  end
  if not inCombat() then scheduleRetry() end
end

-- Relance les envois en attente ; chacun revérifie ses conditions (et se remet en attente si besoin).
flush = function()
  local order, queue = state.queueOrder, state.queue
  state.queueOrder, state.queue = {}, {}
  if not isActive() then return end
  for _, key in ipairs(order) do queue[key]() end
end

-- Envoi à la guilde : une fois par session, seulement dans une guilde.
function VC:BroadcastGuild()
  if not isActive() or state.guildSent then return end
  if call(IsInGuild) ~= true then return end
  if isBlocked() then
    enqueue("guild", function() VC:BroadcastGuild() end)
    return
  end
  if transmit("GUILD") then state.guildSent = true end
end

-- Envoi au groupe : au plus un par minute. Une demande dans la fenêtre est reportée à sa fin
-- (un seul report), pour que les joueurs arrivés entre-temps reçoivent aussi la version.
function VC:BroadcastGroup()
  if not isActive() or not VC.GroupChannel() then return end
  if isBlocked() then
    enqueue("group", function() VC:BroadcastGroup() end)
    return
  end
  local elapsed = state.lastGroup and (now() - state.lastGroup)
  if elapsed and elapsed < VC.GROUP_INTERVAL then
    if not state.groupTimer then
      state.groupTimer = true
      Q:After(VC.GROUP_INTERVAL - elapsed, function()
        state.groupTimer = false
        VC:BroadcastGroup()
      end)
    end
    return
  end
  if transmit(VC.GroupChannel()) then state.lastGroup = now() end
end

-- Réponse à une version plus ancienne : même canal, chuchotement pour un chuchotement.
local function reply(channel, sender)
  if not REPLY_CHANNELS[channel] or state.replied[sender] then return end
  local t = now()
  if state.lastReply and t - state.lastReply < VC.REPLY_INTERVAL then return end
  state.replied[sender] = true
  state.lastReply = t
  local target = (channel == "WHISPER") and sender or nil
  local key = "reply:" .. channel .. ":" .. (target or "")
  local function send()
    if isBlocked() then
      enqueue(key, send)
      return
    end
    transmit(channel, target)
  end
  send()
end

local function scheduleGuild()
  if state.guildTimer or state.guildSent then return end
  state.guildTimer = true
  Q:After(VC.LOGIN_DELAY, function()
    state.guildTimer = false
    VC:BroadcastGuild()
  end)
end

---------------------------------------------------------------------------
-- Réception
---------------------------------------------------------------------------
-- Message court au milieu de l'écran. Sur Forever, RaidNotice_AddMessage fait partie des
-- fonctions dépréciées (définie seulement avec le CVar loadDeprecationFallbacks) :
-- RaidWarningUtil.AddMessage d'abord, l'ancienne fonction sinon, rien si aucune n'existe.
local function centerMessage(text)
  local color = type(ChatTypeInfo) == "table" and ChatTypeInfo["SYSTEM"] or nil
  if type(color) ~= "table" or type(color.r) ~= "number" then color = { r = 1, g = 1, b = 0 } end
  if not RaidWarningFrame then return end
  local ok, err = true, nil
  if type(RaidWarningUtil) == "table" and type(RaidWarningUtil.AddMessage) == "function" then
    ok, err = pcall(RaidWarningUtil.AddMessage, text, color)
  elseif type(RaidNotice_AddMessage) == "function" then
    ok, err = pcall(RaidNotice_AddMessage, RaidWarningFrame, text, color)
  end
  if not ok then Q:Debug("versioncheck: center message failed", err) end
end

-- Avertissement de mise à jour : une seule fois par session.
local function notify(theirs, mine)
  if state.notified then return end
  state.notified = true
  Q:Print(Q.L.VERSION_AVAILABLE, theirs, mine)
  centerMessage(string.format(Q.L.VERSION_AVAILABLE_SHORT, theirs))
end

-- CHAT_MSG_ADDON(prefix, text, channel, sender, ...)
local function onAddonMessage(_, prefix, text, channel, sender)
  local IsSecret = Q.Util.IsSecret
  -- aucune comparaison avant d'avoir écarté les valeurs secrètes
  if IsSecret(prefix) or IsSecret(text) or IsSecret(channel) or IsSecret(sender) then return end
  if prefix ~= VC.PREFIX or not isActive() then return end
  if type(text) ~= "string" or type(channel) ~= "string" or type(sender) ~= "string" or sender == "" then return end
  if isSelf(sender) then return end
  local theirs = VC.Parse(text)
  local mine = VC.MyVersion()
  if not (theirs and mine) then return end
  if not state.newest or VC.Compare(theirs, state.newest) > 0 then state.newest = text end
  local cmp = VC.Compare(theirs, mine)
  if cmp > 0 then
    notify(text, mine)
  elseif cmp < 0 then
    reply(channel, sender)
  end
end

local function onRosterUpdate()
  VC:BroadcastGroup()
end

---------------------------------------------------------------------------
-- Activation
---------------------------------------------------------------------------
-- Inscrit le préfixe et les évènements si l'option est active et C_ChatInfo présent.
function VC:Enable()
  if state.enabled or Q.Settings:Get("versionCheck") ~= true then return end
  local register = chatApi("RegisterAddonMessagePrefix")
  if not register then return end
  local ok, res = pcall(register, VC.PREFIX)
  if not ok then
    Q:Debug("versioncheck: prefix not registered", res)
    return
  end
  state.enabled = true
  Q:RegisterEvent("CHAT_MSG_ADDON", onAddonMessage)
  Q:RegisterEvent("GROUP_ROSTER_UPDATE", onRosterUpdate)
  if Q.loggedIn then scheduleGuild() end
end

-- Option coupée en cours de session : plus rien n'est reçu ni envoyé (le préfixe reste inscrit,
-- le jeu n'a pas de fonction pour le retirer).
function VC:Disable()
  if not state.enabled then return end
  state.enabled = false
  Q:UnregisterEvent("CHAT_MSG_ADDON", onAddonMessage)
  Q:UnregisterEvent("GROUP_ROSTER_UPDATE", onRosterUpdate)
  state.queue, state.queueOrder = {}, {}
end

Q:On("INIT", function() VC:Enable() end)

Q:On("LOGIN", function()
  if state.enabled then scheduleGuild() end
end)

Q:On("COMBAT_ENDED", function() flush() end)

Q:On("SETTINGS_CHANGED", function(path, value)
  if path ~= "versionCheck" then return end
  if value == true then VC:Enable() else VC:Disable() end
end)

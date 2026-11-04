-- tests/mock_ext_versioncheck.lua
-- Compléments du mock pour les tests de la vérification de version (Core/VersionCheck.lua).
-- Utilisation dans un test :
--   local Ext = dofile(Mock.root .. "/tests/mock_ext_versioncheck.lua")
--   Ext.install()      -- après Mock.reset() (fait par le lanceur), avant Mock.loadAddon
-- L'état est dans Mock.vc ; chaque API le lit à l'appel, un test peut donc le changer à tout
-- moment, ou retirer une fonction (globale = nil) pour simuler une API absente :
--   guild, party, raid, instance (booléens), lockdown (InChatMessagingLockdown), realm.
-- Appels notés dans Mock.calls :
--   "C_ChatInfo.RegisterAddonMessagePrefix" (prefix)
--   "C_ChatInfo.SendAddonMessage" (prefix, message, chatType, target)
--   "RaidWarningUtil.AddMessage" (text, color), "RaidNotice_AddMessage" (frame, text, color)

local Ext = {}

Ext.PREFIX = "QVVER"

function Ext.install()
  local S = { guild = false, party = false, raid = false, instance = false, lockdown = false, realm = "Testrealm" }
  Mock.vc = S

  -- Groupe et guilde (LE_PARTY_CATEGORY_HOME = 1, LE_PARTY_CATEGORY_INSTANCE = 2, comme en jeu)
  LE_PARTY_CATEGORY_HOME = 1
  LE_PARTY_CATEGORY_INSTANCE = 2
  IsInGuild = function() return S.guild == true end
  IsInGroup = function(category)
    if category == LE_PARTY_CATEGORY_INSTANCE then return S.instance == true end
    if category == LE_PARTY_CATEGORY_HOME then return S.party == true or S.raid == true end
    return S.party == true or S.raid == true or S.instance == true
  end
  IsInRaid = function() return S.raid == true end
  GetNormalizedRealmName = function() return S.realm end

  -- Messages d'addon (les valeurs de retour suivent Enum.*Result : 0 = Success)
  C_ChatInfo = {
    RegisterAddonMessagePrefix = function(prefix)
      Mock.record("C_ChatInfo.RegisterAddonMessagePrefix", prefix)
      return 0
    end,
    SendAddonMessage = function(prefix, message, chatType, target)
      Mock.record("C_ChatInfo.SendAddonMessage", prefix, message, chatType, target)
      return 0
    end,
    InChatMessagingLockdown = function() return S.lockdown == true end,
  }

  -- Message au milieu de l'écran
  ChatTypeInfo = { SYSTEM = { r = 1, g = 1, b = 0 } }
  RaidWarningFrame = Mock.newObject("Frame", "RaidWarningFrame")
  RaidWarningUtil = {
    AddMessage = function(text, color) Mock.record("RaidWarningUtil.AddMessage", text, color) end,
  }
  RaidNotice_AddMessage = function(frame, text, color) Mock.record("RaidNotice_AddMessage", frame, text, color) end
  return S
end

-- Envois de notre version : { { prefix, message, chatType, target }, ... }
function Ext.sends()
  local out = {}
  for _, c in ipairs(Mock.callsTo("C_ChatInfo.SendAddonMessage")) do
    out[#out + 1] = { c.args[1], c.args[2], c.args[3], c.args[4] }
  end
  return out
end

-- Simule la réception d'un message d'addon (charge utile de CHAT_MSG_ADDON).
function Ext.receive(text, channel, sender, prefix)
  Mock.fire("CHAT_MSG_ADDON", prefix or Ext.PREFIX, text, channel, sender, "", 0, 0, "", 0)
end

return Ext

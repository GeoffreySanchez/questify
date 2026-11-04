-- Tests de l'import / export des builds (Q.BuildCodec, QFYB1:) et du dialogue de BuildPane.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_specrole.lua")

local ICY = "https://www.icy-veins.com/wow-forever/shaman-talent-calculator#tc-111114445565000a8899cddd9eeeeefzzzzzAAADDGhhhhh00ii~70755-d1899b7d"

local function load(class)
  Mock.player.classFile = class or "SHAMAN"; Mock.player.level = 60
  Mock.player.combat = false
  Ext.install()
  Mock.spec.index = 1
  C_SpecializationInfo.GetNumSpecGroups = function() return 1 end
  C_SpecializationInfo.GetActiveSpecGroup = function() return 1 end
  C_Spell = { GetSpellName = function(id) return "S" .. id end, GetSpellTexture = function(id) return 900000 + id end }
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  Q.TalentBuildData = { SHAMAN = {} }
  return Q
end

local function sample(extra)
  local b = { class = "SHAMAN", specID = 262, name = "Mon build", source = "copy", order = { 16035, 16035, 16039 } }
  for k, v in pairs(extra or {}) do b[k] = v end
  return b
end

local function reencode(Q, tbl)
  local P = Q.Profiles
  return Q.BuildCodec.PREFIX .. P.Base64Encode(P.Serialize(tbl))
end

local function personal(Q)
  return (Q.db.builds and Q.db.builds.SHAMAN) or {}
end

local function openPane(Q)
  SlashCmdList.QUESTIFY("build")
  return Q.UI.BuildPane
end

return {
  roundtrip_single = function(t)
    local Q = load()
    local text = Q.BuildCodec:Encode(sample())
    t.eq(text:sub(1, 6), "QFYB1:")
    local list, reason = Q.BuildCodec:Decode(text, "SHAMAN")
    t.eq(reason, nil)
    t.eq(#list, 1)
    t.eq(list[1].name, "Mon build"); t.eq(list[1].specID, 262); t.eq(list[1].class, "SHAMAN")
    t.eq(list[1].source, "copy"); t.eq(list[1].order, { 16035, 16035, 16039 })
  end,

  roundtrip_all = function(t)
    local Q = load()
    local text = Q.BuildCodec:EncodeAll({ sample(), sample({ name = "Deux", order = { 16039 } }) })
    local list = Q.BuildCodec:Decode(text, "SHAMAN")
    t.eq(#list, 2)
    t.eq(list[2].name, "Deux"); t.eq(list[2].order, { 16039 })
  end,

  encode_localized_official_name = function(t)
    local Q = load()
    local text = Q.BuildCodec:Encode(sample({ name = { enUS = "Elemental", frFR = "Élémentaire" } }))
    local list = Q.BuildCodec:Decode(text, "SHAMAN")
    t.eq(list[1].name, "Elemental")
  end,

  long_name_is_shortened = function(t)
    local Q = load()
    local list = Q.BuildCodec:Decode(Q.BuildCodec:Encode(sample({ name = string.rep("x", 40) })), "SHAMAN")
    t.eq(#list[1].name, Q.Profiles.MAX_NAME)
  end,

  rejects_other_class = function(t)
    local Q = load()
    local text = Q.BuildCodec:Encode(sample())
    t.eq({ Q.BuildCodec:Decode(text, "MAGE") }, { nil, "class" })
    t.eq({ Q.BuildCodec:Decode(reencode(Q, { v = 1, builds = { sample(), sample({ class = "MAGE" }) } }), "SHAMAN") },
      { nil, "class" })
  end,

  rejects_bad_prefix = function(t)
    local Q = load()
    t.eq({ Q.BuildCodec:Decode("QFY1:abcd", "SHAMAN") }, { nil, "prefix" })
    t.eq({ Q.BuildCodec:Decode("", "SHAMAN") }, { nil, "prefix" })
    t.eq({ Q.BuildCodec:Decode(nil, "SHAMAN") }, { nil, "prefix" })
  end,

  rejects_garbage_after_prefix = function(t)
    local Q = load()
    t.eq({ Q.BuildCodec:Decode("QFYB1:!!!!", "SHAMAN") }, { nil, "format" })
    t.eq({ Q.BuildCodec:Decode("QFYB1:" .. Q.Profiles.Base64Encode("pas une table"), "SHAMAN") }, { nil, "format" })
    t.eq({ Q.BuildCodec:Decode(reencode(Q, { v = 1 }), "SHAMAN") }, { nil, "format" })
    t.eq({ Q.BuildCodec:Decode(reencode(Q, { v = 1, builds = {} }), "SHAMAN") }, { nil, "format" })
    t.eq({ Q.BuildCodec:Decode(reencode(Q, { v = 2, builds = { sample() } }), "SHAMAN") }, { nil, "format" })
  end,

  rejects_non_numeric_order = function(t)
    local Q = load()
    t.eq({ Q.BuildCodec:Decode(reencode(Q, { v = 1, builds = { sample({ order = { 16035, "x" } }) } }), "SHAMAN") },
      { nil, "format" })
    t.eq({ Q.BuildCodec:Decode(reencode(Q, { v = 1, builds = { sample({ order = { 1.5 } }) } }), "SHAMAN") },
      { nil, "format" })
    t.eq({ Q.BuildCodec:Decode(reencode(Q, { v = 1, builds = { sample({ specID = "x" }) } }), "SHAMAN") },
      { nil, "format" })
  end,

  rejects_too_long_order = function(t)
    local Q = load()
    local order = {}
    for i = 1, 52 do order[i] = 16035 end
    t.eq({ Q.BuildCodec:Decode(reencode(Q, { v = 1, builds = { sample({ order = order }) } }), "SHAMAN") },
      { nil, "toolong" })
    order[52] = nil
    t.ok(Q.BuildCodec:Decode(reencode(Q, { v = 1, builds = { sample({ order = order }) } }), "SHAMAN"))
  end,

  rejects_oversized_text = function(t)
    local Q = load()
    t.eq({ Q.BuildCodec:Decode("QFYB1:" .. string.rep("A", Q.Profiles.MAX_IMPORT), "SHAMAN") }, { nil, "size" })
  end,

  unknown_fields_ignored = function(t)
    local Q = load()
    local list = Q.BuildCodec:Decode(reencode(Q, { v = 1, extra = 1, builds = { sample({ evil = { 1 }, key = "k1" }) } }),
      "SHAMAN")
    t.eq(list[1].evil, nil); t.eq(list[1].key, nil)
  end,

  import_writes_nothing_on_error = function(t)
    local Q = load()
    local P = openPane(Q)
    P:ShowCodec("import")
    P.ui.codecBox:SetText(reencode(Q, { v = 1, builds = { sample(), sample({ class = "MAGE" }) } }))
    Mock.click(P.ui.codecOk)
    t.eq(#personal(Q), 0)
    t.ok(P.ui.codecMsg:GetText():find(Q.L.BUILD_IMPORT_ERR_class, 1, true), tostring(P.ui.codecMsg:GetText()))
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  import_saves_personal_builds_and_counts = function(t)
    local Q = load()
    local P = openPane(Q)
    P:ShowCodec("import")
    P.ui.codecBox:SetText(Q.BuildCodec:EncodeAll({ sample(), sample({ name = "Deux" }) }))
    Mock.click(P.ui.codecOk)
    t.eq(#personal(Q), 2)
    t.eq(personal(Q)[1].official, false)
    t.eq(personal(Q)[2].name, "Deux")
    t.ok(Mock.countPrinted(string.format(Q.L.BUILD_IMPORT_DONE, 2)) > 0, "count printed")
    t.ok(not P.ui.codec:IsShown(), "closed")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  export_dialog_shows_current_build = function(t)
    local Q = load()
    Q.Builds:Save(sample())
    local P = openPane(Q)
    P:Select(personal(Q)[1].key)
    Mock.click(P.ui.export)
    t.ok(P.ui.codec:IsShown())
    local list = Q.BuildCodec:Decode(P.ui.codecBox:GetText(), "SHAMAN")
    t.eq(list[1].name, "Mon build")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  export_all_personal_builds = function(t)
    local Q = load()
    Q.Builds:Save(sample()); Q.Builds:Save(sample({ name = "Deux" }))
    local P = openPane(Q)
    P:ExportAll()
    local list = Q.BuildCodec:Decode(P.ui.codecBox:GetText(), "SHAMAN")
    t.eq(#list, 2)
    t.ok(P.ui.exportAll, "gear menu entry")
  end,

  every_import_error_has_a_string = function(t)
    local Q = load()
    for _, r in ipairs({ "prefix", "format", "class", "toolong", "size", "icyveins", "icyversion" }) do
      local s = Q.L["BUILD_IMPORT_ERR_" .. r]
      t.ok(s and not s:find("BUILD_IMPORT_ERR", 1, true), r)
    end
  end,

  icyveins_link_shaman_elemental = function(t)
    local Q = load()
    local list, reason = Q.BuildCodec:Decode(ICY, "SHAMAN")
    t.eq(reason, nil)
    t.eq(#list, 1)
    t.eq(list[1].order[1], 16035)
    t.eq(#list[1].order, 51)
    t.eq(list[1].source, "Icy Veins (lien)")
    t.eq(list[1].class, "SHAMAN")
    t.ok(list[1].name:find("Import Icy Veins (", 1, true), list[1].name)
  end,

  icyveins_link_variants = function(t)
    local Q = load()
    for _, u in ipairs({ ICY:gsub("https://", ""), (ICY:gsub("www%.", "")), (ICY:gsub("https://www%.", "")) }) do
      t.ok(Q.BuildCodec:Decode(u, "SHAMAN"), u)
    end
  end,

  icyveins_unknown_char_refused = function(t)
    local Q = load()
    t.eq({ Q.BuildCodec:Decode(ICY:gsub("#tc%-1", "#tc-!"), "SHAMAN") }, { nil, "icyveins" })
    t.eq({ Q.BuildCodec:Decode("https://www.icy-veins.com/wow-forever/shaman-talent-calculator#tc-", "SHAMAN") },
      { nil, "icyveins" })
  end,

  -- I8 : lien d'une autre version du calculateur (suffixe « ~… » différent) : refusé ; sans suffixe : accepté.
  icyveins_other_calculator_version_refused = function(t)
    local Q = load()
    t.eq({ Q.BuildCodec:Decode(ICY:gsub("~70755%-d1899b7d", "~70801-0badc0de"), "SHAMAN") }, { nil, "icyversion" })
    local s = Q.L.BUILD_IMPORT_ERR_icyversion
    t.ok(s and s:find("Icy Veins", 1, true), "explained")
    local list = Q.BuildCodec:Decode((ICY:gsub("~70755%-d1899b7d", "")), "SHAMAN")
    t.ok(list and #list[1].order == 51, "no suffix: accepted")
    t.ok(Q.BuildCodec:Decode(ICY, "SHAMAN"), "same version: accepted")
  end,

  icyveins_other_class_refused = function(t)
    local Q = load("MAGE")
    t.eq({ Q.BuildCodec:Decode(ICY, "MAGE") }, { nil, "icyveins" })
    t.eq({ Q.BuildCodec:Decode("https://www.icy-veins.com/wow-forever/beast-mastery-talent-calculator#tc-1", "MAGE") },
      { nil, "icyveins" })
  end,

  icyveins_import_through_dialog = function(t)
    local Q = load()
    local P = openPane(Q)
    Mock.click(P.ui.import)
    t.ok(P.ui.codec:IsShown())
    P.ui.codecBox:SetText(ICY)
    Mock.click(P.ui.codecOk)
    t.eq(#personal(Q), 1)
    t.eq(personal(Q)[1].order[1], 16035)
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  dialog_not_created_in_combat = function(t)
    local Q = load()
    local P = openPane(Q)
    Mock.player.combat = true
    P:ShowCodec("import")
    t.ok(not (P.ui.codec and P.ui.codec:IsShown()))
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,
}

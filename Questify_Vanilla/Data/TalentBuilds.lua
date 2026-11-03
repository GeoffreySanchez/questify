local addonName, Q = ...
-- Presets de talents par classe (rempli classe par classe).
-- Chaque preset : key, flavor ("era" ou "forever" : les arbres de Forever sont refaits), kind
-- ("leveling" ou "dungeon"), title et desc = { enUS, frFR }, source (d'où viennent les choix),
-- order = un talent par point, du niveau 10 au niveau 60. Un talent est désigné par
-- { arbre, palier, colonne, rang max, nom anglais } : les trois premiers sont les indices de
-- GetTalentInfo (indépendants de la langue du client) ; rang max et nom servent de vérification
-- (nom vérifié seulement sur un client anglais). Vérification ratée : aucun conseil.
Q.TalentBuildData = Q.TalentBuildData or {}

-- build({ { talent, points }, ... }) -> order (un élément par point)
local function build(seq)
  local order = {}
  for _, s in ipairs(seq) do
    for _ = 1, s[2] do order[#order + 1] = s[1] end
  end
  return order
end

---------------------------------------------------------------------------
-- Guerrier (Classic Era) : 1 Armes, 2 Fureur, 3 Protection
---------------------------------------------------------------------------
local W = {
  IMP_REND = { 1, 1, 3, 3, "Improved Rend" },
  DEFLECTION = { 1, 1, 2, 5, "Deflection" },
  IMP_CHARGE = { 1, 2, 1, 2, "Improved Charge" },
  TACTICAL = { 1, 2, 2, 5, "Tactical Mastery" },
  IMP_OVERPOWER = { 1, 3, 1, 2, "Improved Overpower" },
  ANGER = { 1, 3, 2, 1, "Anger Management" },
  DEEP_WOUNDS = { 1, 3, 3, 3, "Deep Wounds" },
  TWO_HAND = { 1, 4, 2, 5, "Two-Handed Weapon Specialization" },
  AXE = { 1, 5, 1, 5, "Axe Specialization" },
  SWEEPING = { 1, 5, 2, 1, "Sweeping Strikes" },
  IMP_HAMSTRING = { 1, 6, 3, 3, "Improved Hamstring" },
  MORTAL = { 1, 7, 2, 1, "Mortal Strike" },
  BOOMING = { 2, 1, 2, 5, "Booming Voice" },
  CRUELTY = { 2, 1, 3, 5, "Cruelty" },
  PIERCING = { 2, 3, 2, 1, "Piercing Howl" },
  BLOOD_CRAZE = { 2, 3, 3, 3, "Blood Craze" },
  IMP_BATTLE_SHOUT = { 2, 3, 4, 5, "Improved Battle Shout" },
  ENRAGE = { 2, 4, 3, 5, "Enrage" },
  SHIELD_SPEC = { 3, 1, 2, 5, "Shield Specialization" },
  ANTICIPATION = { 3, 1, 3, 5, "Anticipation" },
  IMP_BLOODRAGE = { 3, 2, 1, 2, "Improved Bloodrage" },
  TOUGHNESS = { 3, 2, 3, 5, "Toughness" },
  LAST_STAND = { 3, 3, 1, 1, "Last Stand" },
  IMP_SHIELD_BLOCK = { 3, 3, 2, 3, "Improved Shield Block" },
  IMP_REVENGE = { 3, 3, 3, 3, "Improved Revenge" },
  DEFIANCE = { 3, 3, 4, 5, "Defiance" },
  IMP_TAUNT = { 3, 4, 3, 2, "Improved Taunt" },
  CONCUSSION = { 3, 5, 2, 1, "Concussion Blow" },
  ONE_HAND = { 3, 6, 3, 5, "One-Handed Weapon Specialization" },
  SHIELD_SLAM = { 3, 7, 2, 1, "Shield Slam" },
}

Q.TalentBuildData.WARRIOR = {
  {
    key = "ERA_WARRIOR_ARMS_LEVELING", flavor = "era", kind = "leveling",
    title = { enUS = "Arms (two-handed weapon)", frFR = "Armes (arme à deux mains)" },
    desc = { enUS = "Mortal Strike at 40, then Fury for the shouts.", frFR = "Frappe mortelle au 40, puis Fureur pour les cris." },
    source = "Icy Veins, Classic Arms Warrior Leveling Guide 1-60",
    order = build({
      { W.IMP_REND, 3 }, { W.DEFLECTION, 2 }, { W.IMP_CHARGE, 2 }, { W.TACTICAL, 3 }, { W.IMP_OVERPOWER, 2 },
      { W.DEEP_WOUNDS, 3 }, { W.TACTICAL, 2 }, { W.ANGER, 1 }, { W.TWO_HAND, 2 }, { W.SWEEPING, 1 },
      { W.AXE, 5 }, { W.IMP_HAMSTRING, 3 }, { W.TWO_HAND, 1 }, { W.MORTAL, 1 }, { W.CRUELTY, 5 },
      { W.BOOMING, 5 }, { W.PIERCING, 1 }, { W.BLOOD_CRAZE, 3 }, { W.IMP_BATTLE_SHOUT, 1 }, { W.ENRAGE, 5 },
    }),
  },
  {
    key = "ERA_WARRIOR_PROT_DUNGEON", flavor = "era", kind = "dungeon",
    title = { enUS = "Protection (tank)", frFR = "Protection (tank)" },
    desc = { enUS = "Shield and threat for dungeons, Shield Slam at 40.", frFR = "Bouclier et menace pour les donjons, Heurt de bouclier au 40." },
    source = "Icy Veins, Classic Protection Warrior Leveling Guide 1-60",
    order = build({
      { W.SHIELD_SPEC, 5 }, { W.TOUGHNESS, 5 }, { W.IMP_SHIELD_BLOCK, 1 }, { W.IMP_BLOODRAGE, 2 }, { W.LAST_STAND, 1 },
      { W.IMP_REVENGE, 1 }, { W.DEFIANCE, 5 }, { W.CONCUSSION, 1 }, { W.IMP_REVENGE, 2 }, { W.IMP_TAUNT, 2 },
      { W.ONE_HAND, 5 }, { W.SHIELD_SLAM, 1 }, { W.DEFLECTION, 5 }, { W.ANTICIPATION, 5 }, { W.TACTICAL, 5 },
      { W.ANGER, 1 }, { W.CRUELTY, 4 },
    }),
  },
}

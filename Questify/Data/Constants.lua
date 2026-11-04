local addonName, Q = ...

-- Races (identifiant UnitRace -> clé de guide et bit du masque QuestieDB requiredRaces).
-- Les bits Skyborne dépassent 32 bits : utiliser Q.Util.HasBit, jamais bit.band.
Q.RACE_BY_ID = {
  [1] = { key = "Human", bit = 1 },
  [2] = { key = "Orc", bit = 2 },
  [3] = { key = "Dwarf", bit = 4 },
  [4] = { key = "NightElf", bit = 8 },
  [5] = { key = "Undead", bit = 16 },
  [6] = { key = "Tauren", bit = 32 },
  [7] = { key = "Gnome", bit = 64 },
  [8] = { key = "Troll", bit = 128 },
  [95] = { key = "Skyborne", bit = 4294967296 },
  [96] = { key = "Skyborne", bit = 8589934592 },
}

-- Classes (classFile UnitClass -> bit du masque QuestieDB requiredClasses).
Q.CLASS_BITS = {
  WARRIOR = 1,
  PALADIN = 2,
  HUNTER = 4,
  ROGUE = 8,
  PRIEST = 16,
  SHAMAN = 64,
  MAGE = 128,
  WARLOCK = 256,
  DRUID = 1024,
}

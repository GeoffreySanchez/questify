-- tools/spells/quest_spells.lua : sorts dont l'apprentissage passe par une chaîne de quêtes de classe.
-- QuestieDB n'a pas de champ « sort de récompense » (ses quêtes ont requiredSpell, pas rewardSpell) : la
-- table est écrite à la main. Chaque entrée : une classe, les noms anglais des sorts (tous les rangs sont
-- repris, d'après les noms de la table DB2 SpellName) et les clés de chaînes de Q.ClassQuestData ; la
-- première clé est la chaîne Alliance, les suivantes les équivalents Horde (même titre).
-- Les quêtes « Call of … » donnent le totem d'élément : le sort EXIGE la chaîne (on ne peut pas le lancer sans
-- le totem), il n'est pas « appris par la quête » : il s'apprend chez le maître. Mana Tide Totem est un talent. Le générateur refuse une clé absente de ClassQuestData ou un nom absent de la classe.
return {
  { class = "SHAMAN", -- Call of Earth (niveau 4)
    names = { "Earthbind Totem", "Stoneclaw Totem", "Stoneskin Totem", "Strength of Earth Totem", "Tremor Totem" },
    chains = { "SHAMAN_94373", "SHAMAN_1516", "SHAMAN_1517", "SHAMAN_1518", "SHAMAN_1519", "SHAMAN_1520",
      "SHAMAN_1521" } },
  { class = "SHAMAN", -- Call of Fire (niveau 10)
    names = { "Searing Totem", "Magma Totem", "Fire Nova", "Flametongue Totem", "Frost Resistance Totem" },
    chains = { "SHAMAN_94449", "SHAMAN_1522", "SHAMAN_2983", "SHAMAN_2984", "SHAMAN_97243" } },
  { class = "SHAMAN", -- Call of Water (niveau 20)
    names = { "Healing Stream Totem", "Mana Spring Totem", "Poison Cleansing Totem", "Disease Cleansing Totem",
      "Fire Resistance Totem" },
    chains = { "SHAMAN_94494", "SHAMAN_1528", "SHAMAN_2985", "SHAMAN_2986" } },
  { class = "SHAMAN", -- Call of Air (niveau 30) ; Sentry Totem est un totem d'air
    names = { "Grounding Totem", "Windfury Totem", "Grace of Air Totem", "Nature Resistance Totem",
      "Windwall Totem", "Sentry Totem" },
    chains = { "SHAMAN_94789", "SHAMAN_1531" } },
}

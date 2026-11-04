# Sorts de classe

`luajit tools/spells/build_spells.lua` (depuis la racine) écrit `Questify/Data/ClassSpells.lua` et
`Questify/Data/SpellQuests.lua` d'après les CSV DB2 de `tools/routebuilder/data/` (client Forever 1.60.1.70707 ;
`https://wago.tools/db2/<Table>/csv?build=1.60.1.70707`) : `SkillLineAbility`, `SpellLevels`, `SpellMisc`,
`SpellName`, `SpellEffect`, `Talent`, `TraitDefinition`, `SkillLine`, `ChrClasses`.

Préparation : `SpellEffect.csv`, `SpellMisc.csv` et `SpellName.csv` sont trop gros pour le dépôt (ignorés par git). `bash tools/spells/fetch_db2.sh` télécharge les tables lues par le générateur (build épinglé dans le script ; `--force` pour retélécharger) ; sans elles le générateur affiche « lance tools/spells/fetch_db2.sh » et s'arrête. Les tests ne lisent que `Questify/Data/*`.

Filtre : ligne `SkillLineAbility` dont `ClassMask` est exactement le bit de la classe, sur une ligne de
compétence de la liste fermée de la classe (arbres de talents, poisons du Voleur), `AcquireMethod` 0 ou 2
(3 = runes de Saison de la Découverte, exclues), niveau de `SpellLevels` (BaseLevel, sinon SpellLevel) de 1 à 60,
sort non passif (`SpellMisc.Attributes_0` bit 0x40). 
Sorts de talent et déclenchements exclus :
- tout spellID des tables `Talent` (SpellRank_*, SpellID, OverridesSpellID) et `TraitDefinition` (SpellID, OverridesSpellID, VisibleSpellID), et tout sort de la classe qui porte le même nom qu'un de ces sorts (leurs rangs : Mana Tide Totem) ;
- sorts déclenchés par un effet d'aura 42 (PROC_TRIGGER_SPELL) d'un autre sort, hors « apprendre un sort » (effet 36) : Impact, Frostbite ;
- sorts de niveau 1 dont `MaxLevel` est 0 (aura sans rang : Chilled, Master of Elements), sauf `AcquireMethod` 2 (sorts de départ).
Heuristique : la DB2 n'a pas de table de maîtres (`Trainer*`) ; un déclenchement sans aucun de ces indices passerait donc le filtre.

Races : `races` = masque 64 bits (bas = RaceMasks_0, haut = RaceMasks_1, non signés, OU des lignes du sort) pris dans SkillLineAbility ; absent si aucune restriction ou si toutes les races jouables sont couvertes. Le filtrage par race du joueur se fait à l'exécution.

Rang : `SupercedesSpell` s'il reste dans la classe, sinon ligne par nom triée par (niveau, spellID) : seul le premier sort de chaque niveau est maillon, les variantes de même niveau et de même nom (Polymorph) restent séparées. Un sort a au plus un successeur (liste blanche `SHARED_PREDECESSORS` du générateur, vide).

Lien sort -> quête : `chainKey` signifie « ce sort EXIGE cette chaîne de quêtes » (totems du Chaman), pas « appris par la quête ». `quest_spells.lua`, écrit à la main (QuestieDB n'a pas de sort de récompense) ; `Q.SpellQuestChains` partage une table par chaîne. Le
générateur échoue si une chaîne n'existe pas dans `Questify/Guides/ClassQuestData.lua`.

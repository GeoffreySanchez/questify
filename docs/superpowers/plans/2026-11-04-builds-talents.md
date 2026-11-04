# Builds de talents et sorts à apprendre — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** remplacer les presets de talents morts par des builds niveau par niveau (fournis d'après Icy
Veins, modifiables, partageables), une popup « Apprendre » à chaque point, nos onglets Build et Sorts
à apprendre dans la fenêtre des talents de Forever.

**Architecture:** un moteur pur (`TalentTree` lit l'arbre `C_Traits`, `Builds` valide, calcule les
points dus, stocke) testé au simulateur ; une couche jeu mince (`TalentLearn`, `TalentFrameHook`,
`TalentPopup`, `BuildWindow`) ; des données générées hors jeu (`tools/talentbuilds`, `tools/spells`).
Trois livrables : A) moteur + builds fournis + popup + halo ; B) éditeur + import/export ;
C) onglet Sorts à apprendre.

**Tech Stack:** Lua 5.1 (client WoW Forever, Interface 16001, API Mainline 12.x) ; tests LuaJIT
(`luajit tests/run.lua`, simulateur `tests/wow_mock.lua`) ; outils LuaJIT dans `tools/`.

**Spec:** `docs/superpowers/specs/2026-11-04-builds-talents-design.md` (+ maquette
`docs/superpowers/specs/2026-11-04-builds-talents-maquette.html`). Lire les deux avant chaque tâche.

## Global Constraints

- Code Blizzard de référence : dépôt `Gethe/wow-ui-source`, branche `forever`,
  `Interface/AddOns/Blizzard_PlayerSpells/Camelot/` et `Interface/AddOns/Blizzard_SharedTalentUI/`.
- Talent identifié par le `spellID` du rang 1 (définition de l'entrée du nœud). 51 points max,
  un par niveau du 10 au 60. Règles : `(palier - 1) * 5` points dans l'arbre (groupe) avant un palier ;
  talent requis au rang max.
- Toute valeur lue du jeu passe par `Q.Util.IsSecret` avant comparaison.
- Jamais de `loadstring` ; import analysé strictement (`Q.Profiles.Deserialize`, `Q.Profiles.Base64Decode`).
- Builds fournis : dans `Questify/Data/`, générés, jamais copiés dans les sauvegardes. Builds perso :
  `QuestifyDB.builds[<CLASS>]`. Build actif : `QuestifyCharDB.builds.active[<groupe 1|2>]`.
- Builds hors des profils d'options (`QFY1:`) ; format d'échange `QFYB1:`.
- Pas de texte d'Icy Veins dans l'addon : seulement `spellID`, ordre, source, date.
- Fenêtre du jeu : pas d'`AddNamedTab` sur un `TabSystem` Blizzard, pas de remplacement de méthode de
  mixin, rien caché/déplacé de Blizzard ; créations et changements d'affichage hors combat
  (`InCombatLockdown`), sinon différés à `PLAYER_REGEN_ENABLED`.
- Textes en `Questify/Locales/StringsTalents.lua`, `frFR` et `enUS` complets, accents compris.
- Nouveaux fichiers ajoutés aux deux TOC identiques (`Questify/Questify.toc`, `Questify/Questify_Camelot.toc`).
- Les agents ne lancent jamais git : le contrôleur commite. Ne jamais lire ni écrire `~/dev/quick_path`.
- Vérif finale de chaque tâche : `luajit tests/run.lua` tout vert, `luajit tools/validate_guides.lua` OK,
  `bash tools/check_syntax.sh` OK.

## Review Focus

- **Arbre non encore chargé à la connexion** (`C_ClassTalents.GetActiveConfigID()` nil) : rien
  n'affiche d'erreur, la popup attend `TRAIT_CONFIG_UPDATED`. Test en tâche 6.
- **Points en attente non validés dans la fenêtre du jeu** (`excludeStaged`) : le moteur lit les rangs
  validés, la popup ne propose pas un point déjà posé en attente. Test en tâche 1.
- **Spécialisation secondaire pas encore débloquée** (`GetNumSpecGroups() == 1`) : le sélecteur de
  groupe ne montre que la principale. Test en tâche 3.
- **Chaîne d'import abîmée ou d'une autre classe** : refus clair, aucune écriture. Test en tâche 11.
- **Combat pendant « Apprendre »** : rien n'est acheté, la popup se rouvre à la sortie du combat. Test
  en tâche 5.

---

## Livrable A — moteur, builds fournis, popup, halo

### Task 1: lecture de l'arbre (`TalentTree`)

**Files:**
- Create: `Questify/Engine/TalentTree.lua`
- Modify: les deux TOC (insérer `Engine\TalentTree.lua` juste avant `Engine\Talents.lua`)
- Test: `tests/test_talenttree.lua` (le simulateur `C_Traits` de `tests/test_talents.lua` passe dans
  `tests/mock_ext_traits.lua`, réutilisé par les deux fichiers)

**Interfaces:**
- Produces: `Q.TalentTree:Read() -> tree | nil, reason` ; `reason` ∈ `"noapi"`, `"noconfig"`, `"empty"`.
  `tree = { configID, treeID, groups = { [1..3] = { groupID, name, spent } }, nodes = { [spellID] = node },
  byNodeID = { [nodeID] = node }, unspent = number }`.
  `node = { nodeID, entryID, spellID, group (1..3), tier, col, maxRanks, rank, requires = { nodeID… } }`.
- `Q.TalentTree:Rules(tree, ranksBySpell) -> fn(node) -> ok, reason` (règles palier / requis), partagé
  par `Builds` et l'éditeur.

- [ ] **Step 1: tests** — `tests/mock_ext_traits.lua` expose `Traits.install{ groups = { { name, talents = { { spellID, tier, col, maxRanks, requires = spellID? } } } }, ranks = { [spellID] = n }, staged = { [spellID] = n }, unspent = n }`
  (nœud n° = spellID + 1000, entrée + 2000, définition + 3000 ; `posY = tier * 600`, `posX = col * 600 + groupe * 3000` ;
  arêtes `visibleEdges = { { targetNode } }` sur le nœud source).
  Tests : `read_maps_groups_tiers_cols` (3 groupes, `nodes[16035].tier == 1`, `.col == 3`, `.group == 1`) ;
  `read_uses_committed_ranks_not_staged` (`ranks[16035]=2, staged=3` → `rank == 2`) ;
  `read_reports_noconfig` (`GetActiveConfigID` nil → `nil, "noconfig"`) ;
  `read_ignores_secret_values` (`Mock.secret` sur `maxRanks` d'un nœud → nœud absent, pas d'erreur) ;
  `rules_tier_and_requires` (palier 2 refusé avec 4 points dans le groupe, accepté avec 5 ; requis pas au max → `"requires"`).
- [ ] **Step 2:** `luajit tests/run.lua talenttree` → FAIL (`Q.TalentTree` nil).
- [ ] **Step 3:** implémenter. Palier = rang du `posY` parmi les `posY` distincts de l'arbre (croissants) ;
  colonne = rang du `posX` parmi les `posX` distincts du groupe. Groupe = position du `groupIDs[1]` du nœud
  dans `C_Traits.GetGroupDisplayInfoByTreeID` trié par `orderIndex`. Rang validé = `C_Traits.GetNodeInfo(...).ranksPurchased`
  lu sur la config active **sans** les changements en attente (lire le code Blizzard pour le bon champ) ; `unspent` =
  `Q.Talents:TreeCurrencyUnspent()` existant. `requires` = nœuds sources des `visibleEdges` qui pointent vers ce nœud.
- [ ] **Step 4:** `luajit tests/run.lua talenttree` → PASS ; puis la suite complète.
- [ ] **Step 5:** commit (contrôleur) `feat(talents): lecture de l'arbre C_Traits par spellID`.

### Task 2: builds — validation et points dus (`Builds`, partie pure)

**Files:**
- Create: `Questify/Engine/Builds.lua` (TOC : juste après `Engine\TalentTree.lua`)
- Test: `tests/test_builds.lua`

**Interfaces:**
- Consumes: `TalentTree:Read`, `TalentTree:Rules`.
- Produces:
  - format d'un build : `{ key, class, specID, name, source, date, official, order = { spellID, … } }` (≤ 51).
  - `Q.Builds:Validate(build, tree) -> ok, reason, index` ; `reason` ∈ `"missing"` (spellID absent de l'arbre),
    `"maxrank"`, `"tier"`, `"requires"`, `"toolong"` ; `index` = position du premier point fautif.
  - `Q.Builds:Due(build, tree) -> { { spellID, node, rank, level } … }` : jusqu'à `tree.unspent` entrées, dans l'ordre
    du build, en sautant les points déjà couverts par l'arbre réel et ceux impossibles maintenant ; `level = 10 + index - 1`.
  - `Q.Builds:Deviates(build, tree) -> bool` : un talent de l'arbre réel a plus de rangs que le build n'en donne
    sur ses N premiers points (N = points dépensés).
  - `Q.Builds:FromTree(tree, class, specID) -> build` : rangs actuels, palier par palier puis colonne, `official = false`.

- [ ] **Step 1: tests** avec l'arbre Chaman réduit de la maquette (Concussion 16035 5 rangs palier 1 ;
  Elemental Alacrity 16578 palier 2 ; Call of Thunder 16120 ; Lightning Overload 408438 requiert 16578 au max) :
  `validate_ok` ; `validate_missing_reports_index` (Lava Burst 51505 au 6e point → `false, "missing", 6`) ;
  `validate_maxrank` (6 × 16035) ; `validate_tier` ; `due_lists_unspent_points_in_order` (niveau 13, 3 rangs
  placés, 1 point → `{ 16035 rang 4 niveau 13 }`) ; `due_five_points` (5 points dus → 5 entrées, rangs successifs) ;
  `due_skips_impossible` ; `deviates_when_off_build` ; `fromtree_roundtrip_validates`.
- [ ] **Step 2:** `luajit tests/run.lua builds` → FAIL.
- [ ] **Step 3:** implémenter (fonctions pures sur `tree`, aucune lecture du jeu).
- [ ] **Step 4:** PASS + suite complète.
- [ ] **Step 5:** commit `feat(talents): validation des builds et points dus`.

### Task 3: builds — stockage, build actif, choix automatique

**Files:**
- Modify: `Questify/Engine/Builds.lua`
- Test: `tests/test_builds.lua`

**Interfaces:**
- Consumes: `Q.TalentBuildData[<CLASS>]` (liste de builds fournis, tâche 4), `QuestifyDB`, `QuestifyCharDB`
  (via `Q.db`, `Q.char`), `C_SpecializationInfo.GetActiveSpecGroup()`, `GetNumSpecGroups()`,
  `C_SpecializationInfo.GetSpecialization()` / `GetSpecializationInfo` (comme `Questify/Automation/SpecRole.lua`).
- Produces: `Builds:List(class) -> { build… }` (fournis puis perso) ; `Builds:Get(key)` ; `Builds:Save(build) -> key`
  (perso seulement ; un build fourni modifié devient une copie, nouvelle clé `u<time>`) ; `Builds:Delete(key)` ;
  `Builds:Groups() -> { 1 } | { 1, 2 }` ; `Builds:ActiveGroup()` ; `Builds:Active(group?) -> build | nil` ;
  `Builds:SetActive(group, key) -> ok, reason` (refuse un build invalide pour l'arbre : `reason` de `Validate`) ;
  `Builds:AutoPick(group) -> build | nil` (build fourni de la spé du joueur, message `TALENT_AUTOPICK` une fois) ;
  évènement `BUILDS_CHANGED`.

- [ ] **Step 1: tests** : `save_official_makes_copy` ; `active_is_per_character_and_group`
  (deux persos simulés via `Mock.reload`) ; `setactive_refuses_obsolete` ; `autopick_matches_spec`
  (spé Élémentaire → build `specID` correspondant ; message imprimé une seule fois) ; `groups_single_when_locked`
  (`GetNumSpecGroups()==1` → `{1}`) ; `personal_builds_shared_by_class_on_account`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** PASS + suite.
- [ ] **Step 5:** commit `feat(talents): builds perso, build actif par spé`.

### Task 4: builds fournis (Icy Veins) — capture, générateur, données

**Files:**
- Create: `tools/talentbuilds/capture.js` (extrait à coller dans la console d'une page Icy Veins),
  `tools/talentbuilds/raw/<CLASS>.json`, `tools/talentbuilds/build.lua`, `tools/talentbuilds/README.md`
- Replace: `Questify/Data/TalentBuilds.lua` (généré : `-- Généré par tools/talentbuilds/build.lua. Ne pas modifier à la main.`)
- Replace: `tests/test_talentdata.lua`

**Interfaces:**
- Produces: `Q.TalentBuildData = { [CLASS] = { { key, class, specID, name = { enUS, frFR }, source = "Icy Veins",
  url, date = "2026-11-04", official = true, order = { spellID… } } } }` et
  `Q.TalentIndexData = { [CLASS] = { [char] = spellID } }` (table d'index du calculateur, pour la tâche 12),
  `Q.TalentShapeData = { [CLASS] = { [spellID] = { group, tier, col, maxRanks, requires } } }` (contrôle hors jeu).
- Capture (**contrôleur, navigateur requis** : Icy Veins renvoie 403 aux requêtes directes) : sur chaque page
  `https://www.icy-veins.com/wow-forever/<spé>-<classe>-leveling`, `capture.js` lit
  `input[data-talenturlid]` (id, `name="…[arbre---slot]"`, `max`), `.tbctalent-talent-details[data-spell]`,
  `data-talent-requiredtalent`, et le lien « Open in Calculator » (`#tc-<ordre>~…`), puis copie un JSON
  `{ class, spec, url, date, talents = [{ id, tree, slot, max, spell, requires }], order }`.
  Exemple déjà relevé : Chaman Élémentaire, ordre `111114445565000a8899cddd9eeeeefzzzzzAAADDGhhhhh00ii`.

- [ ] **Step 1: tests** `tests/test_talentdata.lua` : pour chaque build fourni, `#order <= 51` ; chaque `spellID`
  présent dans `TalentShapeData` ; `Q.Builds:Validate` sur un arbre construit depuis `TalentShapeData`
  → `true` ; `name.enUS` et `name.frFR` présents ; `specID` numérique ; Chaman Élémentaire : `order[1] == 16035`
  (niveau 10), `order[22] == 408438` (Lightning Overload, niveau 31), `order[31] == 16166` (Lightning Mastery,
  niveau 40), `order[32] == 16179` (Tidal Focus, niveau 41).
- [ ] **Step 2:** FAIL. **Step 3:** contrôleur capture au moins les 9 classes (une spé de montée chacune ; toutes
  celles publiées si possible) ; `build.lua` convertit (`slot` → palier `slot // 4 + 1`, colonne `slot % 4 + 1`).
  **Step 4:** PASS + suite. **Step 5:** commit `feat(talents): builds de montée fournis (Icy Veins, 4 nov.)`.

### Task 5: apprendre (`TalentLearn`)

**Files:**
- Create: `Questify/Engine/TalentLearn.lua` (TOC : juste après `Engine\Builds.lua`)
- Test: `tests/test_talentlearn.lua`

**Interfaces:**
- Consumes: `tree` (`TalentTree:Read`), liste de `Builds:Due`.
- Produces: `Q.TalentLearn:Learn(tree, due) -> "ok" | "combat" | "unavailable" | "failed"`. `specID` = id de la spé
  active (`GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())`). Séquence (celle du bouton
  « Appliquer », `ClassTalentsFrameMixin:CommitConfigInternal` dans la branche `forever`) : pour chaque entrée
  `C_Traits.PurchaseRank(tree.configID, node.nodeID)`, puis une seule fois
  `C_ClassTalents.CommitConfig(savedConfigID)` avec `savedConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)`
  (peut être nil). Un achat ou la validation renvoie faux ou lève une erreur → `C_Traits.RollbackConfig(configID)`,
  `TalentLearn.available = false` pour la session, `"failed"`. `InCombatLockdown()` → rien, `"combat"`.
  `Q.TalentLearn:IsAvailable() -> bool`.

- [ ] **Step 1: tests** : `learn_buys_then_commits_once` (3 dus → 3 `PurchaseRank`, 1 `CommitConfig`, via `Mock.countCalls`) ;
  `learn_refuses_in_combat` ; `learn_rolls_back_on_failure` (2e achat renvoie false → `RollbackConfig` appelé,
  `IsAvailable() == false`, l'appel suivant renvoie `"unavailable"` sans achat).
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** PASS + suite. **Step 5:** commit `feat(talents): apprendre d'un clic`.

### Task 6: moteur talents branché, ancien système retiré

**Files:**
- Modify: `Questify/Engine/Talents.lua` (garder `Dump`, `TreeCurrencyUnspent`, `Unspent`, `OpenFrame` ; retirer
  `Find`, `Spent`, `Presets`, `PresetTitle`, `Chosen`, `HasAnswered`, `Choose`, `Next`, `TALENTS_ASK`)
- Delete: `Questify/UI/TalentPicker.lua` (et sa ligne des deux TOC), l'entrée `talentBuild` de `Questify/Core/OptionsSchema.lua`
- Modify: `Questify/UI/Tracker.lua:767-800` (alerte et infobulle talents)
- Create: `Questify/Locales/StringsTalents.lua` (+ TOC) ; retirer les chaînes mortes de l'ancien système
- Test: `tests/test_talents.lua` (réécrit sur `mock_ext_traits.lua`)

**Interfaces:**
- Produces: `Q.Talents:Alert() -> nil | { unspent, due = { … }, build = build | nil, tree, deviates = bool }` ;
  `Q.Talents:Advice(entry) -> "Concussion (Élémentaire, rang 4/5)"` (nom par `C_Spell.GetSpellName`) ;
  évènement `TALENTS_CHANGED` (inchangé) ; `TALENTS_DUE` quand `due` devient non vide (lu par la popup).
  `Q.Talents:OpenFrame()` ouvre l'affichage des talents (`PlayerSpellsUtil.ToggleClassTalentFrame` si présent,
  sinon `ToggleTalentFrame`), hors combat.

- [ ] **Step 1: tests** : `alert_lists_due_from_active_build` ; `alert_without_build_offers_choose` (`build == nil`, infobulle
  `UI_TALENT_NO_PRESET` → nouveau texte « Choisir un build ») ; `no_alert_before_level_10` ; `waits_for_config`
  (config nil à la connexion → aucune erreur, alerte après `Mock.fire("TRAIT_CONFIG_UPDATED")`) ;
  `old_picker_gone` (`Q.UI.TalentPicker == nil`, pas d'option `talentBuild`).
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** PASS + suite. **Step 5:** commit `refactor(talents): moteur sur les builds, ancien sélecteur retiré`.

### Task 7: popup de talent (`TalentPopup`)

**Files:**
- Create: `Questify/UI/TalentPopup.lua` (+ TOC)
- Test: `tests/test_talentpopup.lua`

**Interfaces:**
- Consumes: `Talents:Alert`, `TalentLearn:Learn`, `Talents:OpenFrame`, `Q.UI.BuildWindow:Open("build")` (tâche 9 ;
  appel protégé tant qu'elle n'existe pas).
- Produces: `Q.UI.TalentPopup:Show()`, `:Hide()`, `:Snooze()`. Règles : montrée sur `TALENTS_DUE` si
  `talentAlert ~= false` ; jamais en combat (attend `PLAYER_REGEN_ENABLED`) ; une seule fois par valeur de
  `unspent` (`Q.char.talentPopup.seen`) ; « Plus tard » = `Snooze` jusqu'à ce que `unspent` augmente.
  Contenu : titre `TALENT_POPUP_LEVEL` (« Niveau %d ! ») ou `TALENT_POPUP_POINTS` (« %d points à dépenser ») ;
  jusqu'à 5 icônes (`C_Spell.GetSpellTexture`) avec rang ; ligne « Build : <nom> » ; boutons « Apprendre »,
  « Ouvrir les talents », « Plus tard ». Sans build : un seul bouton « Choisir un build ».
  « Apprendre » appelle `TalentLearn:Learn(alert.tree, alert.due)` ; résultat `"unavailable"`/`"failed"` → ouvre
  les talents et imprime `TALENT_LEARN_FALLBACK` ; `"combat"` → la popup se rouvre à `PLAYER_REGEN_ENABLED`.

- [ ] **Step 1: tests** : `shows_once_per_point` ; `waits_out_of_combat` ; `snooze_until_next_point` ;
  `learn_click_calls_learn_with_due` ; `learn_failure_opens_frame` ; `no_build_shows_choose_button` ;
  `respects_talentAlert_off`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter (cadre centré, style des popups existantes, `UIPanelButtonTemplate`).
  **Step 4:** PASS + suite. **Step 5:** commit `feat(talents): popup au passage de niveau`.

### Task 8: accroche à la fenêtre du jeu — onglets, halo, bande, infobulle

**Files:**
- Create: `Questify/UI/TalentFrameHook.lua` (+ TOC)
- Test: `tests/test_talentframehook.lua` (simuler `PlayerSpellsFrame` avec `TalentsFrame` et
  `GetTalentButtonByNodeID(nodeID)` dans le mock)

**Interfaces:**
- Consumes: `ADDON_LOADED` de `Blizzard_PlayerSpells` (ou fenêtre déjà chargée), `PlayerSpellsFrame.TalentsFrame`,
  `TalentsFrame:GetTalentButtonByNodeID(nodeID)`, `Talents:Alert`, `Q.UI.BuildWindow` (tâche 9).
- Produces: `Q.UI.TalentFrameHook:IsHooked() -> bool` ; onglets « Talents », « Build », « Sorts à apprendre »
  (nos boutons, modèle `PanelTabButtonTemplate`, ancrés `TOPLEFT` sur `PlayerSpellsFrame` `BOTTOMLEFT` x=22 y=2,
  visibles seulement quand `TalentsFrame` est montré ; « Sorts à apprendre » porte la pastille du nombre à apprendre) ;
  halo (cadre à nous, enfant du bouton du prochain talent, animation) ; ligne d'infobulle via
  `button:HookScript("OnEnter", …)` (`TALENT_TIP_NEXT`) ; bande en haut de `TalentsFrame` (« Build suivi : … ·
  prochain point : … », bouton « Modifier le build » ; si `alert.deviates` : « Ton arbre ne suit plus le build X »
  et bouton « Créer un build à partir de mon arbre » → `Builds:FromTree`). Le halo n'intercepte aucun clic : le
  clic reste celui du jeu (point en attente, puis « Appliquer »). Fenêtre absente ou méthode manquante →
  `IsHooked() == false`, aucune erreur.

- [ ] **Step 1: tests** : `tabs_created_out_of_combat_only` (chargement en combat → créés à `PLAYER_REGEN_ENABLED`) ;
  `halo_on_next_talent_button` ; `tooltip_line_added` ; `missing_frame_no_error` (`PlayerSpellsFrame` nil →
  `IsHooked()==false`) ; `no_blizzard_tab_api_called` (`Mock.countCalls("AddNamedTab") == 0`) ;
  `halo_does_not_intercept_click` (aucun `SetScript("OnClick")` sur le bouton Blizzard, halo `EnableMouse(false)`) ;
  `band_shows_deviation_and_from_tree_button`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** PASS + suite.
- [ ] **Step 5:** commit `feat(talents): onglets Questify et halo dans la fenêtre des talents`.

**Fin du livrable A : vérification en jeu par l'utilisateur (points 1 et 2 de la section 9 du spec).**

---

## Livrable B — éditeur, import / export

### Task 9: fenêtre build (coquille) et éditeur pur

**Files:**
- Create: `Questify/Engine/BuildEditor.lua`, `Questify/UI/BuildWindow.lua` (+ TOC)
- Modify: `Questify/UI/Slash.lua` (`COMMANDS.build`), `Questify/UI/MinimapButton.lua` (entrée `build` après `journal`)
- Test: `tests/test_buildeditor.lua`, `tests/test_buildwindow.lua`

**Interfaces:**
- Produces:
  - `Q.BuildEditor.new(build, shape) -> ed` avec `ed:Add(spellID) -> ok, reason`, `ed:RemoveLast(spellID)`,
    `ed:RemoveAt(index)`, `ed:RanksAt(level) -> { [spellID] = rank }, spentByGroup`, `ed:Order()`,
    `ed:Error() -> reason, index | nil`. `shape` = `TalentTree:Read()` en jeu, `Q.TalentShapeData` hors arbre.
  - `Q.UI.BuildWindow:Open(pane)` (`"build"` | `"spells"`), `:Close()`, `:SetHost(frame | nil)` : dans la fenêtre
    du jeu (appelé par `TalentFrameHook`) ou autonome (`/qf build`, menu minimap, repli).

- [ ] **Step 1: tests** `buildeditor` : `add_respects_rules` (mêmes cas que tâche 2) ; `remove_at_shifts_levels` ;
  `ranks_at_level_view` ; `remove_breaking_later_points_refused` (retirer Elemental Alacrity alors que Lightning
  Overload suit → refus `"requires"`, ordre inchangé). `buildwindow` : `slash_build_opens_standalone` ;
  `minimap_has_build_entry`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** PASS + suite. **Step 5:** commit `feat(build): éditeur et fenêtre build`.

### Task 10: onglet Build — interface de l'éditeur

**Files:**
- Create: `Questify/UI/BuildPane.lua` (+ TOC)
- Modify: `Questify/Core/OptionsSchema.lua` (retirer `talentAlert` des Options ; le réglage `talentAlert` reste dans
  `Questify/Core/Settings.lua`)
- Test: `tests/test_buildpane.lua`

**Interfaces:**
- Consumes: `BuildEditor`, `Builds`, `TalentTree`.
- Produces (rendu de la maquette, onglet Build) : liste déroulante des builds (★ actif, « (fourni) », « ⚠ … — build
  obsolète » grisé ; ceux de la spé du groupe affiché en tête) ; sélecteur « Spé principale / Spé secondaire » si
  `Builds:Groups()` en a deux ; champ nom ; « Enregistrer », « Dupliquer », « Utiliser ce build », « Importer »,
  « Exporter » ; bandeau obsolète avec la raison (`BUILD_OBSOLETE_<reason>`) ; trois arbres (icônes
  `C_Spell.GetSpellTexture`, infobulle `GameTooltip:SetSpellByID`, rang) ; clic gauche `Add`, clic droit `RemoveLast` ;
  liste « Niv. N → nom r/max » avec ✕ ; curseur de niveau 10-60 ; roue dentée avec la case `talentAlert` et
  « Créer un build à partir de mon arbre » (`Builds:FromTree`).

- [ ] **Step 1: tests** : `obsolete_build_greyed_and_not_usable` ; `edit_official_then_save_creates_copy` ;
  `duplicate_obsolete_drops_missing` ; `group_selector_hidden_when_single` ; `talentAlert_not_in_options` ;
  `from_tree_creates_build`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** PASS + suite. **Step 5:** commit `feat(build): onglet Build`.

### Task 11: import / export (`BuildCodec`)

**Files:**
- Create: `Questify/Engine/BuildCodec.lua` (+ TOC), dialogue dans `Questify/UI/BuildPane.lua`
- Test: `tests/test_buildcodec.lua`

**Interfaces:**
- Produces: `Q.BuildCodec.PREFIX = "QFYB1:"` ; `Q.BuildCodec:Encode(build) -> string` ;
  `Q.BuildCodec:EncodeAll(builds) -> string` ; `Q.BuildCodec:Decode(text, class) -> { build… } | nil, reason` avec
  `reason` ∈ `"prefix"`, `"format"`, `"class"`, `"toolong"`, `"size"` (texte > `Q.Profiles.MAX_IMPORT`). Contenu :
  `{ v = 1, builds = { { class, specID, name, source, order } } }` via `Q.Profiles.Serialize` + `Base64Encode`.
  Nom nettoyé comme `Profiles:CleanName`. Un build importé est enregistré perso puis validé (obsolète affiché).

- [ ] **Step 1: tests** : `roundtrip_single` ; `roundtrip_all` ; `rejects_other_class` ; `rejects_bad_prefix` ;
  `rejects_garbage_after_prefix` ; `rejects_non_numeric_order` ; `import_writes_nothing_on_error`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** PASS + suite. **Step 5:** commit `feat(build): import et export QFYB1`.

### Task 12: import d'un lien du calculateur Icy Veins (bonus, en dernier du livrable B)

**Files:**
- Modify: `Questify/Engine/BuildCodec.lua`
- Test: `tests/test_buildcodec.lua`

**Interfaces:**
- Produces: `BuildCodec:Decode` accepte aussi `https://www.icy-veins.com/wow-forever/<classe>-talent-calculator#tc-<ordre>~…` :
  chaque caractère de `<ordre>` → `Q.TalentIndexData[class][char]` ; caractère inconnu ou classe différente →
  `nil, "icyveins"`. Source du build : `"Icy Veins (lien)"`.

- [ ] **Step 1: test** `icyveins_link_shaman_elemental` (lien de la tâche 4 → `order[1] == 16035`, 51 points) ;
  `icyveins_unknown_char_refused`. **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** PASS + suite.
- [ ] **Step 5:** commit `feat(build): import d'un lien Icy Veins`.

---

## Livrable C — sorts à apprendre

### Task 13: données des sorts de classe (générateur DB2)

**Files:**
- Create: `tools/spells/build_spells.lua`, `tools/spells/README.md`
- Add: `tools/routebuilder/data/SkillLineAbility.csv`, `SpellLevels.csv`, `SkillLine.csv`
  (`https://wago.tools/db2/<Table>/csv?build=1.60.1.70707`, même build que les autres tables)
- Create (généré): `Questify/Data/ClassSpells.lua` (+ TOC) ; `Questify/Data/SpellQuests.lua` (+ TOC)
- Test: `tests/test_classspells.lua`

**Interfaces:**
- Produces: `Q.ClassSpellData = { [CLASS] = { { spellID, level, supersedes = spellID | nil } … } }` (sorts appris chez
  le maître ou par quête : lignes `SkillLineAbility` de la classe — `ClassMask` et lignes de compétence de classe —
  niveau = `SpellLevels.BaseLevel`, rang = position dans la chaîne `SupercedesSpell`) ;
  `Q.SpellQuestData = { [spellID] = chainKey }` (clé de `Q.ClassQuestData`) : sort de récompense des quêtes dans
  QuestieDB s'il existe, sinon table écrite à la main dans `tools/spells/quest_spells.lua` (au minimum les totems
  du Chaman : Searing Totem ↔ `SHAMAN_94449` côté Alliance).

- [ ] **Step 1: tests** : chaque classe a ≥ 20 sorts ; niveaux entre 1 et 60 ; Chaman : Lightning Bolt (403) niveau 1 ;
  `supersedes` pointe vers un sort de la même classe ; chaque `chainKey` existe dans `Q.ClassQuestData`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter l'outil, générer. **Step 4:** PASS + suite.
- [ ] **Step 5:** commit `feat(sorts): liste des sorts de classe générée`.

### Task 14: moteur de la liste des sorts (`SpellList`) et relevé du maître

**Files:**
- Create: `Questify/Engine/SpellList.lua` (+ TOC)
- Modify: `Questify/Engine/Trainer.lua` (`readServices` garde le `spellID` de chaque ligne quand le jeu le donne ;
  sinon correspondance nom + rang avec `C_Spell.GetSpellName` / `C_Spell.GetSpellSubtext` sur `Q.ClassSpellData`)
- Test: `tests/test_spelllist.lua`

**Interfaces:**
- Produces: `Q.SpellList:Rows() -> { { spellID, name, rank, level, cost | nil, state, chainKey | nil, questState } }`,
  `state` ∈ `"known"` (`IsPlayerSpell`/`IsSpellKnown`), `"now"` (niveau atteint, maître), `"quest"`, `"soon"` ;
  `questState` ∈ `"inlog"`, `"available"`, `"upcoming"`, `"done"` (via `Q.ClassQuests:List()`) ;
  `Q.SpellList:Summary() -> { now = n, cost = cuivre, money = cuivre, trainer = { name, zone, distance } | nil }` ;
  évènement `SPELLS_CHANGED` relayé.

- [ ] **Step 1: tests** : `known_from_game` ; `cost_from_trainer_cache_else_nil` ; `trainer_full_list_overrides_data` ;
  `quest_spell_states` (Call of Fire dans le journal → `"inlog"` ; absente et accessible → `"available"`) ;
  `summary_counts_now`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** PASS + suite. **Step 5:** commit `feat(sorts): liste des sorts à apprendre`.

### Task 15: onglet Sorts à apprendre

**Files:**
- Create: `Questify/UI/SpellsPane.lua` (+ TOC)
- Modify: `Questify/Engine/Trainer.lua` (`Trainer:GoNearest()` : insère l'étape `train` même sans liste relevée) ;
  `Questify/Engine/ClassQuests.lua` (`ClassQuests:Track(key)` : remonte les étapes de la chaîne en tête et
  pointe la flèche sur l'étape en cours)
- Test: `tests/test_spellspane.lua`

**Interfaces:**
- Consumes: `SpellList`, `Trainer:GoNearest`, `ClassQuests:Add`, `ClassQuests:Track`.
- Produces (rendu de la maquette, onglet Sorts) : bandeau maître + résumé + bouton « Route vers le maître le plus
  proche » ; filtres Tous / À apprendre / Appris / À venir ; lignes groupées par niveau (icône, nom, rang, niveau,
  prix ou « — », état) ; ligne de quête : « Suivre la quête » (`inlog`), « Récupérer la quête » (`available`), grisé
  « Disponible au niveau X » (`upcoming`).

- [ ] **Step 1: tests** : `route_button_inserts_train_step` ; `track_button_moves_steps_first` ;
  `get_button_adds_chain` ; `upcoming_quest_button_disabled` ; `filters` ; `pill_count_matches_summary`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** PASS + suite. **Step 5:** commit `feat(sorts): onglet Sorts à apprendre`.

### Task 16: docs et paquet

**Files:**
- Modify: `README.md` (FR/EN : section « Builds de talents », `/qf build`), `CHANGELOG.md` (« Non publié » FR/EN),
  `docs/RESTE-A-FAIRE.md` (retirer « Builds Forever des 9 classes », ajouter les vérifs en jeu du spec §9)
- Test: `tests/test_boot.lua` (les deux TOC listent les mêmes fichiers, tous présents) ; `bash tools/package.sh`

- [ ] **Step 1:** mettre à jour les docs. **Step 2:** `luajit tests/run.lua` vert, `bash tools/package.sh` OK
  (zip contient `Engine\TalentTree.lua`, `UI\TalentPopup.lua`, `Data\ClassSpells.lua`).
- [ ] **Step 3:** commit `docs: builds de talents et sorts à apprendre`.

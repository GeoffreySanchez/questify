local addonName, Q = ...
-- Presets de talents par classe (rempli classe par classe, pour les arbres de Forever).
-- Chaque preset : key, kind ("leveling" ou "dungeon"), title et desc = { enUS, frFR }, source
-- (d'où viennent les choix), order = un talent par point, du niveau 10 au niveau 60. Un talent est
-- désigné par { arbre, palier, colonne, rang max, nom anglais } : les trois premiers sont les
-- indices de GetTalentInfo (indépendants de la langue du client) ; rang max et nom servent de
-- vérification (nom vérifié seulement sur un client anglais). Vérification ratée : aucun conseil.
-- Les arbres de Forever se relèvent en jeu avec /qf talents (QuestifyVanillaDB.talentDump).
-- Aucune classe n'a encore de preset : sans preset, ni choix de build ni conseil de talent.
Q.TalentBuildData = Q.TalentBuildData or {}

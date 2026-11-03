local addonName, Q = ...
-- Presets de talents par classe (rempli classe par classe).
-- Chaque preset : key, kind ("leveling" ou "dungeon"), title = { enUS, frFR }, source (d'où viennent
-- les choix), order = un talent par point, du niveau 10 au niveau 60, désigné par
-- { arbre, palier, colonne } (indices de GetTalentInfo : indépendants de la langue du client).
Q.TalentBuildData = Q.TalentBuildData or {}

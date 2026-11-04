-- Fixture : erreur signalée pendant le chargement des fichiers, avant ADDON_LOADED
-- (les SavedVariables ne sont pas encore là) ; elle doit être enregistrée à l'INIT.
local _, Q = ...
Q:ReportError("early error before saved variables")

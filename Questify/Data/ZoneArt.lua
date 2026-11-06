local addonName, Q = ...

-- Images de fond des zones pour le choix de suite (UI/RouteChoicePopup.lua) :
--   Q.ZoneArt[uiMapID] = { texture = "Interface\\AddOns\\Questify\\Media\\Zones\\<nom>",
--                          coords = { gauche, droite, haut, bas }?, width = 1024?, height = 512? }
-- texture : fichier TGA 32 bits (1024 × 512 par défaut) livré dans Questify/Media/Zones/ (voir le
-- README du dossier), chemin sans extension. coords (facultatif, 0 à 1) : partie de l'image à montrer ;
-- la carte la recadre ensuite au centre pour remplir sa forme. width / height : taille de l'image
-- quand elle n'est pas en 1024 × 512.
-- Zone sans entrée : la carte du monde de la zone (textures du client), sinon un fond uni du thème.
-- Livrée vide : les images viendront de captures faites en jeu.
Q.ZoneArt = Q.ZoneArt or {}

-- Exemple (à décommenter quand le fichier Media/Zones/Westfall.tga existe) :
-- Q.ZoneArt[1436] = { texture = "Interface\\AddOns\\Questify\\Media\\Zones\\Westfall" }

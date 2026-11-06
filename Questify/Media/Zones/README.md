# Images de fond des zones

Ce dossier contient les images de fond des cartes du choix de suite (fenêtre « Choisis la suite de ta
route »). Il est livré vide : sans image, la carte montre la carte du monde de la zone (textures du
jeu), ou un fond uni.

## Format

- TGA 32 bits (RGBA, sans compression RLE), 1024 × 512 pixels. Les dimensions doivent être des
  puissances de deux, sinon le jeu n'affiche rien.
- Une image par zone, nommée d'après le nom anglais de la zone, sans espace ni apostrophe :
  `Westfall.tga`, `Darkshore.tga`, `RedridgeMountains.tga`, `TheBarrens.tga`.
- Le centre de l'image est la partie la plus visible : chaque carte est plus haute que large et
  recadre l'image au centre (environ un tiers de la largeur reste visible).
- Uniquement des captures faites soi-même en jeu. Aucune image reprise d'un site ou d'un autre addon.

## Ajouter une image

1. Faire une capture en jeu (paysage typique de la zone, interface masquée avec Alt+Z).
2. La recadrer et la redimensionner en 1024 × 512, puis l'enregistrer en TGA 32 bits dans ce dossier.
3. Déclarer la zone dans `Questify/Data/ZoneArt.lua`, avec son uiMapID :

   ```lua
   Q.ZoneArt[1436] = { texture = "Interface\\AddOns\\Questify\\Media\\Zones\\Westfall" }
   ```

   `coords = { gauche, droite, haut, bas }` (valeurs de 0 à 1) choisit au besoin une partie de l'image.
   `width` et `height` donnent la taille d'une image qui n'est pas en 1024 × 512.
4. Relancer le jeu (un nouveau fichier n'est pas vu par un simple /reload).

Les uiMapID des zones sont dans `Questify/Engine/Guides.lua` (table `ZONE_MAPS`).

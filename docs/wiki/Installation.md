# Installation

[Français](#français) · [English](#english)

---

## Français

### 1. Les addons à installer

| Addon | Statut | Lien CurseForge | À quoi il sert |
|---|---|---|---|
| **Questify** | requis | [GitHub (release « latest »)](https://github.com/GeoffreySanchez/questify/releases/tag/latest) | Le guide lui-même |
| **QuestieDB** | **requis** | [curseforge.com/wow/addons/questiedb](https://www.curseforge.com/wow/addons/questiedb) | Données des quêtes, PNJ et objets |
| **ShortestPath Forever** | optionnel | [curseforge.com/wow/addons/shortest-path-forever](https://www.curseforge.com/wow/addons/shortest-path-forever) | Itinéraire complet entre zones (vols, bateaux, portails) |
| **WaypointUI** | optionnel | [curseforge.com/wow/addons/waypointui](https://www.curseforge.com/wow/addons/waypointui) | Joli repère 3D flottant vers la destination |
| **TomTom** | optionnel | [curseforge.com/wow/addons/tomtom](https://www.curseforge.com/wow/addons/tomtom) | Flèche de navigation classique |

Sans addon optionnel, Questify utilise le repère 3D natif du jeu : tout fonctionne déjà.
Conseil : **ShortestPath Forever + WaypointUI** pour le meilleur confort.

### 2. Installer Questify
1. Télécharge `Questify-<version>-forever.zip` depuis la
   [release « latest »](https://github.com/GeoffreySanchez/questify/releases/tag/latest).
2. Décompresse-le dans `World of Warcraft\_forever_\Interface\AddOns\`.
3. Vérifie le chemin : le dossier `Questify` doit être **directement** dans `AddOns`
   (`…\AddOns\Questify\Questify.toc`), pas dans un sous-dossier en double.

### 3. Installer QuestieDB et les optionnels
- Avec l'application CurseForge : cherche chaque addon par son nom et installe-le pour
  **World of Warcraft: Forever**.
- À la main : télécharge le zip sur la page CurseForge et décompresse-le dans le même dossier `AddOns`.

### 4. Premier lancement
1. **Relance complètement le jeu** : un addon ajouté pendant que le jeu tourne n'est vu qu'au
   redémarrage, pas avec `/reload`.
2. Dans la liste des addons (écran de sélection du personnage) : coche Questify et QuestieDB.
   S'ils sont marqués « Périmé », coche « Charger les addons périmés ».
3. En jeu, l'assistant s'ouvre tout seul : il montre les addons trouvés ou manquants (avec leur lien à
   copier), puis te fait choisir l'itinéraire, le repère et les automatisations. `/qf wizard` le rouvre.
4. `/qf check` vérifie que tout est en place. En cas de souci, `/qf bug` ouvre un rapport à copier.

### Problèmes fréquents
- **Le suivi affiche « QuestieDB est requis »** : QuestieDB n'est pas installé ou pas activé. Le bouton
  « Lien » ouvre l'assistant sur la page des addons, avec le lien CurseForge.
- **L'addon n'apparaît pas dans la liste** : le dossier est mal placé (double dossier
  `Questify\Questify`), ou le jeu n'a pas été redémarré.
- **Pas de flèche** : ouvre l'assistant (`/qf wizard`) et choisis un affichage installé.

---

## English

### 1. Addons to install

| Addon | Status | CurseForge link | What it does |
|---|---|---|---|
| **Questify** | required | [GitHub ("latest" release)](https://github.com/GeoffreySanchez/questify/releases/tag/latest) | The guide itself |
| **QuestieDB** | **required** | [curseforge.com/wow/addons/questiedb](https://www.curseforge.com/wow/addons/questiedb) | Quest, NPC and object data |
| **ShortestPath Forever** | optional | [curseforge.com/wow/addons/shortest-path-forever](https://www.curseforge.com/wow/addons/shortest-path-forever) | Full routing across zones (flights, boats, portals) |
| **WaypointUI** | optional | [curseforge.com/wow/addons/waypointui](https://www.curseforge.com/wow/addons/waypointui) | Nice floating 3D marker to the destination |
| **TomTom** | optional | [curseforge.com/wow/addons/tomtom](https://www.curseforge.com/wow/addons/tomtom) | Classic navigation arrow |

Without any optional addon, Questify uses the game's native 3D marker: everything already works.
Tip: **ShortestPath Forever + WaypointUI** for the best experience.

### 2. Install Questify
1. Download `Questify-<version>-forever.zip` from the
   ["latest" release](https://github.com/GeoffreySanchez/questify/releases/tag/latest).
2. Unzip it into `World of Warcraft\_forever_\Interface\AddOns\`.
3. Check the path: the `Questify` folder must sit **directly** in `AddOns`
   (`…\AddOns\Questify\Questify.toc`), not in a duplicated subfolder.

### 3. Install QuestieDB and the optional addons
- With the CurseForge app: search each addon by name and install it for **World of Warcraft: Forever**.
- By hand: download the zip from the CurseForge page and unzip it into the same `AddOns` folder.

### 4. First launch
1. **Fully restart the game**: an addon added while the game runs is only seen after a restart, not
   with `/reload`.
2. In the addon list (character selection screen): enable Questify and QuestieDB. If they show
   "Out of date", tick "Load out of date AddOns".
3. In game, the wizard opens by itself: it shows the addons found or missing (with a link to copy),
   then lets you pick routing, display and automations. `/qf wizard` reopens it.
4. `/qf check` verifies everything is in place. If something goes wrong, `/qf bug` opens a report to copy.

### Common problems
- **The tracker says "QuestieDB is required"**: QuestieDB is not installed or not enabled. The "Link"
  button opens the wizard on the addons page, with the CurseForge link.
- **The addon is not in the list**: the folder is misplaced (duplicated
  `Questify\Questify`), or the game was not restarted.
- **No arrow**: open the wizard (`/qf wizard`) and pick an installed display.

# Captures en jeu : la commande cachée `/qf demo`

`/qf demo` montre les **vraies** fenêtres et alertes de Questify avec des données d'exemple, sans rien
modifier : rien n'est écrit dans la progression ni dans les réglages, aucune quête n'est ajoutée, ignorée
ou choisie, aucun objet n'est équipé ni vendu. Les boutons des fenêtres se contentent de les fermer.
La commande est cachée : absente de `/qf help`, des options et du menu de la minicarte.

## Réglages avant de capturer
- Résolution 1920×1080, échelle d'interface par défaut, interface **visible** (surtout pas Alt+Z, qui
  masque aussi Questify).
- Autres addons d'interface fermés, sauf ceux que la capture doit montrer (WaypointUI ou TomTom pour la
  scène `cave`).
- Client **en anglais** pour CurseForge (fichiers dans `docs/media/apercus/en/`), puis une deuxième série
  **en français** (`docs/media/apercus/`). Changer de langue de jeu change les textes de Questify.
- Hors combat : en combat la commande répond « après le combat » et n'ouvre rien ; un début de combat
  pendant une scène la range.
- Capture : touche **Impr. écran** ; les fichiers arrivent dans le dossier `Screenshots` du jeu. Les
  renommer ensuite avec les noms ci-dessous.

## Commandes
| Commande | Ce qu'on voit | Où se placer | Nom du fichier |
|---|---|---|---|
| `/qf demo` | la liste des scènes dans la discussion | n'importe où | (pas de capture) |
| `/qf demo classquest` | alerte « Quête de classe disponible » dans le suivi et la fenêtre de la première chaîne de ta classe | n'importe où ; un personnage de niveau 4 à 10 donne un bel exemple | `06-class-quest.png` |
| `/qf demo classlate` | alerte du suivi « Quête de classe en retard : … » (clic sur l'alerte : la fenêtre) | n'importe où, de préférence un personnage au-dessus du niveau de la chaîne | `15-class-late.png` |
| `/qf demo dungeon` | alerte « Donjon conseillé » et la fenêtre des Mortemines (Alliance) ou du Gouffre de Ragefeu (Horde) | n'importe où | `07-dungeon.png` |
| `/qf demo upgrade` | l'annonce « Équipez … » au milieu de l'écran avec un objet réel | n'importe où | `14a-equip-upgrade.png` |
| `/qf demo pair` | l'annonce « Équipez X et Y » : une arme à une main et un bouclier réels | n'importe où | `14-equip-pair.png` |
| `/qf demo route` | la fenêtre de choix de suite : les deux suites de la fin de Loch Modan (Marche de l'Ouest, Sombrivage), carte conseillée calculée comme en vrai | n'importe où | `16-route-choice.png` |
| `/qf demo supplies` | l'alerte d'avant-poste : lignes du suivi, message au centre de l'écran et discussion (« 4 places libres sur 64, pas de boisson ») | une auberge ou une ville, suivi visible | `17-outpost-alert.png` |
| `/qf demo cave` | le repère « Entrée de la grotte — The Grizzled Den » posé à l'entrée réelle, avec l'affichage choisi dans les options (WaypointUI, TomTom ou repère natif) | Dun Morogh, au sud-ouest de Kharanos, en vue de l'entrée | `13-cave-entrance.png` |
| `/qf demo profession` | l'étape « Métier : Herboristerie (Compagnon) » : titre dans la discussion, texte dans la zone d'avertissements du suivi (rien n'est inséré dans la route) | n'importe où, suivi visible | `18-profession-step.png` |
| `/qf demo all` | enchaîne toutes les scènes, dans l'ordre du tableau (hors la liste) | n'importe où | une capture par scène |
| `/qf demo next` | passe à la scène suivante de `all` | n'importe où | |
| `/qf demo off` | ferme tout et remet l'état d'avant : fenêtres, lignes et alertes du suivi, repère de navigation | n'importe où | |

Une scène remplace la précédente : une seule à la fois. Les scènes restent à l'écran jusqu'à la suivante,
jusqu'à `/qf demo off`, ou jusqu'à ce qu'un clic les ferme (l'annonce d'équipement ne disparaît pas seule).

## Données d'exemple
- Classe, faction et race : celles du personnage connecté. `classquest` et `classlate` prennent la
  première chaîne disponible de la classe (sinon la première de la classe) ; `dungeon` prend le donjon
  de la faction ; l'état des quêtes affichées est celui du personnage.
- `route` est toujours calculée pour un Nain de l'Alliance qui finit Loch Modan, quelle que soit la
  position du personnage.
- `upgrade` et `pair` utilisent des objets réels de Classic (liste `Demo.ITEMS` de `UI/Demo.lua`) : le
  premier connu du client est pris. Si le client ne les connaît pas encore, la scène le dit : relancer
  la commande une seconde plus tard.
- `cave` utilise la grotte « The Grizzled Den » des données livrées (`Q.CaveData`).
- Une donnée ou une fonction du jeu absente : la scène l'écrit dans la discussion et ne plante pas.

## Après la séance
Taper `/qf demo off` (ou `/reload`) pour tout remettre en place. Mettre les fichiers dans
`docs/media/apercus/en/` (anglais) ou `docs/media/apercus/` (français), puis décommenter les blocs
d'images concernés (voir `docs/media/README.md`).

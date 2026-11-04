# Médias : check-list des captures et vidéos

Fichiers utilisés par le README, le wiki GitHub et la page CurseForge. Dépose-les dans ce dossier
(`docs/media/`) avec exactement ces noms : je décommente ensuite les blocs d'images.

## Réglages avant de filmer
- Résolution 1920×1080, échelle d'interface par défaut, client **en français** (une variante en anglais
  si tu as le temps pour 01 et 05).
- Enregistrement : OBS (1080p, 60 i/s) ; GIF : ScreenToGif ou `ffmpeg` (15 i/s, 1280 px de large,
  moins de 8 Mo).
- Masque ce que tu ne veux pas montrer (nom de perso, guilde, discussion) ; ferme les autres addons
  d'interface pour que l'écran reste lisible.
- Garde les options par défaut de Questify (tout activé), WaypointUI ou le repère natif visible.

## Captures (PNG, 1920×1080)

- [ ] **`01-tracker.png`** — Coldridge, niveau 2-4 : le suivi sous la minimap avec l'étape en cours,
      la distance, les 3 étapes suivantes et la ligne XP/h (attendre 3 min de jeu pour qu'elle
      s'affiche). Sert d'image de couverture CurseForge.
- [ ] **`02-wizard.png`** — premier lancement, page « Addons » de l'assistant, avec au moins un addon
      optionnel absent pour montrer son lien CurseForge.
- [ ] **`05-map-pins.png`** — carte du monde ouverte sur Dun Morogh : épingles numérotées (1 = étape
      en cours, puis les 5 suivantes), souris sur une épingle pour l'infobulle.
- [ ] **`06-class-quest.png`** — alerte de quête de classe dans le suivi + fenêtre ouverte
      (« Ajouter à la route / Ignorer », récompenses). Exemple : Nain Chaman niveau 4, Guerrier 10.
- [ ] **`07-dungeon.png`** — alerte « Donjon conseillé » + sa fenêtre (quêtes à prendre, entrée).
      Plus tard dans la montée (vers 17-18) ; à défaut, la section Donjons du journal.
- [ ] **`08-journal-route.png`** — `/qf`, onglet Route : chapitres à gauche, étapes cochées / grisées /
      en cours à droite.
- [ ] **`08b-journal-options.png`** — onglet Options (groupes Route, Confort, Affichage, Outils).
- [ ] **`10-quest-item.png`** — une quête avec objet à utiliser : le bouton à gauche du suivi.
- [ ] **`11-zone-mode.png`** — en mode zone : la ligne « Zone : … » et les objectifs groupés
      Objets / Nommés / Monstres (image fixe pour CurseForge, en plus du GIF 03).

## GIF animés (README et wiki)

| Fichier | Durée | Ce qu'on doit voir |
|---|---|---|
| [ ] **`03-zone-mode.gif`** | 12-15 s | Arrivée dans une zone d'objectifs : repère vert, entrée dans la zone, liste groupée, la flèche passe à l'objectif prioritaire |
| [ ] **`04-mobs-target.gif`** | 6-10 s | Clic sur un monstre sous l'objectif (ou la touche de ciblage) : il est ciblé et reçoit le crâne |
| [ ] **`09-auto-quest.gif`** | 8-12 s | Parler à un PNJ : quête prise toute seule, puis rendu + récompense choisie avec le message |
| [ ] **`12-nameplates.gif`** | 5-8 s | Icônes qui rebondissent au-dessus des monstres d'objectif |
| [ ] **`13-auto-fly.gif`** | 8-10 s | Chez le maître de vol, sur une étape « Prendre un vol » : le trajet part tout seul |

## Vidéos (YouTube, 1080p, liées sur CurseForge et le README)

- [ ] **Bande-annonce, 60-90 s** (la plus importante) :
  1. 0-10 s : installation et assistant (page Addons, choix du repère) ;
  2. 10-25 s : Coldridge, tour du hub (toutes les quêtes prises d'un coup) ;
  3. 25-45 s : mode zone sur un camp (objets, nommé, monstres en un passage) ;
  4. 45-55 s : ciblage + crâne, icônes au-dessus des monstres ;
  5. 55-70 s : carte avec les épingles, clic qui déplace la flèche ;
  6. 70-90 s : alerte quête de classe ou donjon, rendu automatique avec récompense.
- [ ] **Tutoriel d'installation, 2-3 min** (facultatif) : téléchargement du zip, dossier `_forever_`,
      QuestieDB et optionnels, assistant, `/qf check`.
- [ ] **Accéléré « Coldridge 1-6 », 3-5 min** (facultatif) : les ~36 min de la vallée accélérées,
      pour montrer qu'aucun aller-retour n'est perdu.

## Où ça va
- README et wiki : 01, 03, 04, 05 (et le lien de la bande-annonce).
- Galerie CurseForge (onglet « Images » du projet) : 01, 02, 05, 06, 07, 08, 10, 11 en PNG.
- Vidéos CurseForge : liens YouTube de la bande-annonce et du tutoriel.

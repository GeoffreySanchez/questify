# Builds de talents fournis

Génère `Questify/Data/TalentBuilds.lua` (`Q.TalentBuildData`, `Q.TalentIndexData`, `Q.TalentShapeData`) :
des builds de montée, un `spellID` (rang 1) par point du niveau 10 au niveau 60. Aucun texte des sources
n'est copié : seulement les `spellID`, l'ordre, la source, l'adresse et la date.

```sh
luajit tools/talentbuilds/build.lua [--out FICHIER] [--raw DOSSIER]   # depuis la racine du projet
```

Sortie déterministe. Un build n'est livré que s'il passe `Q.Builds:Validate` sur la forme de l'arbre de sa
classe ; les builds rejetés sont affichés avec la raison. Les dossiers `raw/wowhead/` et `raw/questify/`
peuvent être vides ou absents ; l'outil se relance à tout moment. Il ne modifie jamais `raw/`.

## Sources

- `raw/icyveins/capture-<date>.txt` : relevé fait dans un navigateur (Icy Veins répond 403 aux requêtes
  directes). Format décrit en tête du fichier : lignes `T <CLASSE> id:arbre:slot:max:spellID:slotRequis`
  (table du calculateur) et `B <CLASSE> <page> <date> <ordre>~<suffixe>` (lien « Open in Calculator »).
  Conversion : arbre 0..2 = groupe 1..3 ; palier = `slot // 4 + 1` ; colonne = `slot % 4 + 1` ; chaque
  caractère de l'ordre donne un talent via la table de la classe ; point i = niveau 9 + i.
- `raw/wowhead/*.json`, `raw/questify/*.json` : `{ "source", "class", "spec", "kind": "leveling"|"dungeon"|"pvp"|"raid",
  "url", "date", "orderSpells": [spellID…] }`.

## Refaire le relevé

1. Ouvrir `https://www.icy-veins.com/wow-forever/<spé>-<classe>-leveling` dans un navigateur.
2. Coller les extraits de `capture.js` dans la console : le premier donne `page|ordre~suffixe|date`
   (à écrire en ligne `B`), le second la table du calculateur (ligne `T`, une fois par classe ; lire en
   deux morceaux si la sortie est tronquée).
3. Enregistrer dans un nouveau `raw/icyveins/capture-<date>.txt`, puis lancer `build.lua`.

## Exclusions et limites (relevé du 4 nov. 2026)

- Version du calculateur : seuls les liens de suffixe `70755-d1899b7d` sont livrés. Exclus : Druide
  Farouche (`70755-f7fd84eb`) et Voleur Finesse (`70707-06ce77b5`), dont les index peuvent désigner
  d'autres talents.
- Rejetés par la validation (relevé Icy Veins dont la table du calculateur est incomplète ou mal indexée ;
  même l'ordre réparé reste illégal) : Icy Veins Chasseur Précision (tier, point 42), Voleur Assassinat
  (tier, point 21), Voleur Combat (tier, point 13), Chaman Amélioration (tier, point 9) ; Icy Veins
  Paladin Vindicte (caractère d'ordre M absent de la table). Ces spécialisations restent couvertes par
  d'autres sources (Wowhead, Questify) : Voleur (3 builds Questify), Chaman Amélioration, Chasseur
  Précision et Paladin Vindicte (builds Questify, Vindicte aussi Wowhead).
- Dernière génération : 45 builds livrés, 7 rejetés (les 2 exclus ci-dessus pour la version du calculateur,
  plus les 5 de cette liste). Un build ajusté (ordre réparé) : IV_HUNTER_BEAST_MASTERY (38 points déplacés).
- `specID` : la table DB2 `ChrSpecialization` de Forever (build 1.60.1.70707,
  `tools/routebuilder/data/ChrSpecialization.csv`) ne contient que les lignes de classe, aucune
  spécialisation. Les `specID` sont ceux de la branche Mainline (table `SPECS` de `build.lua`) ; à vérifier
  en jeu avec `C_SpecializationInfo.GetSpecializationInfo`, sinon le choix automatique du build ne
  trouvera pas la spécialisation.

## Builds ajustés (ordre réparé)

Quand l'ordre d'un build viole la règle de palier ou de talent requis alors que l'ensemble final est
légal, `repair.lua` reporte chaque point trop tôt jusqu'au premier moment où il devient légal (file
d'attente, le plus ancien d'abord ; le reste garde son ordre). Le build est livré avec `adjusted = true`.
Ajusté dans la dernière génération : IV_HUNTER_BEAST_MASTERY (38 points déplacés).

## Noms et crédits

Les noms livrés ne portent pas le nom de la source : « <Spé> — Leveling » / « — Donjon » / « — PvP » / « — Raid »
(enUS « <Spec> — Leveling » / « — Dungeon » / « — PvP » / « — Raid »). Les pages Icy Veins sont toutes en leveling. Les builds suivants de même classe, spécialisation et sorte
prennent « · variante 2 », « · variante 3 »… (ordre : Icy Veins, Wowhead, Questify, puis clé).
Les champs `source` et `url` de chaque build restent dans les données.

Crédits : relevés Icy Veins et Wowhead (ordre des points) ; builds « Questify » issus de notre théorycraft,
dont les recherches sont dans `tools/talentbuilds/research/`.

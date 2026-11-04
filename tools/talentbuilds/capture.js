// tools/talentbuilds/capture.js : relevé des builds de montée d'Icy Veins (WoW Forever).
// À coller dans la console d'un navigateur ouvert sur
//   https://www.icy-veins.com/wow-forever/<spé>-<classe>-leveling
// (Icy Veins répond 403 aux requêtes directes : le relevé passe par un vrai navigateur.)
// Chaque extrait renvoie une chaîne à copier dans tools/talentbuilds/raw/icyveins/capture-<date>.txt,
// au format décrit en tête de ce fichier. Voir tools/talentbuilds/README.md.

// 1. Ordre des points (lien « Open in Calculator ») et date de mise à jour -> ligne « B » :
//    B <CLASSE> <page> <date> <ordre>~<suffixe>   (ici « page|ordre~suffixe|date », à recomposer)
await new Promise(r => setTimeout(r, 1500));
const hs = [...new Set([...document.querySelectorAll('a')]
  .filter(x => /talent-calculator#tc-/.test(x.href)).map(x => x.href.split('#tc-')[1]))];
location.pathname.split('/').pop() + '|' + hs.join(',') + '|' +
  ((document.body.innerText.match(/Last Updated:\s*([A-Z][a-z]{2} \d+, \d{4})/) || [])[1]);

// 2. Table du calculateur (une fois par classe) -> ligne « T <CLASSE> ... » :
//    id:arbre:slot:rangs max:spellID du rang 1:slot requis (vide si aucun).
//    La sortie de certains outils est tronquée vers 1000 caractères : lire en deux morceaux,
//    en remplaçant slice(0, 30) par slice(30, 64) pour le second.
const ins = [...document.querySelectorAll('input[data-talenturlid]')].filter(i => i.id.startsWith('talentcalculator-1-'));
ins.length + '#' + ins.slice(0, 30).map(i => {
  const [t, s] = i.name.match(/\[(\d+)---(\d+)\]/).slice(1);
  const d = i.closest('li').querySelector('.tbctalent-talent-details');
  return [i.dataset.talenturlid, t, s, i.max, d.dataset.spell, i.dataset.talentRequiredtalent || ''].join(':');
}).join(' ');

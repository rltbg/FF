# Statut : ce qui est fait, testé, pas fait, impossible ici

Dernière passe complète depuis zéro : `scripts/all.sh` → « TOUT OK » (`logs/all.log`). Environnement de test : conteneur
Linux x86_64, 4 vCPU, 16 Go, sans GPU, Xvfb. **C'est un banc d'essai de la boucle F* → F# → Avalonia, pas un produit fini.**

## Fait et vérifié (chaque ligne a un test ou une mesure rejouable)

| Domaine | Ce qui est vérifié | Où |
|---|---|---|
| Preuves F* | invariant de `update` (compteur, ids, sélection < 100 000, pas de débordement u32), correction fonctionnelle de `parse_nat`, équivalence `fnv_bytes` = spécification, condensé exact du texte haché, 21 lemmes | `fst/` |
| Extraction | `Core.fst` et `App.fst` extraits tels quels, 0 warning ; 1 seul contournement F* (`u32_of_char`) | `scripts/extract.sh` |
| Tests exécutables | 950 833 vérifications, 0 échec, en JIT et en NativeAOT | `scripts/test.sh` |
| Mutations | 3 mutations toutes détectées (une par F*, deux par les tests) | `scripts/mutate.sh` |
| Interface | 3 onglets + Volumes, pilotés par xdotool, **état du modèle vérifié à chaque étape**, AOT et JIT | `scripts/ui_smoke.sh` |
| Rechargement à chaud | 5 scénarios (vue, logique, type du modèle, mode sans preuves, onglet Volumes) ; déchargement de **tous** les contextes | `scripts/hotreload.sh` |
| NativeAOT | publication, 0 warning sauf `IL3053`/`IL2104` de FSharp.Core, démarrage, RSS, taille | `scripts/build.sh`, `scripts/startup.sh` |
| Modes sans preuves | `--lax` et `--admit_smt_queries true` testés (`logs/loop_bench.log`) : vérification de 1,0 à 1,8 s au lieu de 2,7 à 4,9 s ; la compilation F# (≈ 5 s) domine la boucle dans les trois modes | `scripts/loop.sh`, `scripts/loop_bench.sh` |
| Gros volumes | liste de 100 000 lignes virtualisée (côté hôte), texte de 1 022 080 octets haché par la fonction F* prouvée, coût mesuré du modèle F* à 100 000 éléments | `docs/GUIDE.md` §7 |
| Sous-ensemble F* extractible | 28 cas (chaînes, listes, Seq/Map/Set, entiers machine, Bytes, Printf, Float64…), passage à l'échelle | `docs/MATRICE-FSTAR.md` |
| Défauts de F* documentés | 6 constats avec reproduction et correctif proposé | `docs/UPSTREAM-FSTAR.md` |
| Défaut d'Avalonia | cause trouvée dans le code source, contournement en place, note pour le remonter | `REPORT.md` §5, `docs/TODO-avalonia-upstream.md` |

## Mesuré mais limité (comportement connu, pas un défaut du banc)

- **Liste non virtualisée** (onglet Liste, un contrôle par élément) : à 1 000 éléments l'interface est occupée 1,7 s après le
  changement d'onglet en AOT (4,9 s en JIT) ; à 5 000, 6 s (8 s en JIT) et 0,9 à 1 Go de RSS. Une fois libre, un clic répond en
  ~115 ms. **Au-delà de quelques centaines d'éléments, utiliser la liste virtualisée** (`BigList`). Rejouer : `scripts/list_scale.sh`.
- **`TextBox` de 1 Mo** : +170 Mo de RSS (330 Mo contre 160 Mo). Le gros texte est donc affiché par un visualiseur de lignes
  virtualisé (+6 Mo) ; un vrai éditeur de 1 Mo reste à concevoir.
- **Rechargement à chaud** : 8 à 12 s de la sauvegarde à l'affichage (la compilation F# domine) ; un changement de type du
  modèle réinitialise l'état ; `dotnet watch` ne recharge pas F# (`Restart is needed`).
- **`FStar.Set`** déborde de la pile entre 100 000 et 1 000 000 éléments ; `Seq.index` est O(n) (liste).
- **Réconciliation par position, sans clés** : correcte mais retire/ajoute des contrôles quand on supprime au milieu d'une liste
  non virtualisée.

## Pas fait, faisable ici

- Éditeur de texte de grande taille (édition, pas seulement lecture) : conception à faire.
- Réconciliation avec clés (identifiants F* des éléments).
- Réalisation de `char_code`/négation/division euclidienne **dans F* lui-même** : nécessite de reconstruire F* (amorçage OCaml) ;
  les correctifs proposés (`docs/UPSTREAM-FSTAR.md`) ne sont pas appliqués.
- Rechercher les doublons et déposer les tickets F* et Avalonia (accord de l'utilisateur à obtenir, accès aux dépôts amont à
  prévoir : cette session n'a accès qu'à `rltbg/FF`).

## Impossible ou non testé ici

| Sujet | Pourquoi |
|---|---|
| Rendu **GPU** (GLX/EGL/Vulkan, Wayland) | aucune carte graphique ; sous Xvfb Avalonia utilise Mesa en rastérisation logicielle ; les temps et la mémoire ne valent pas pour un GPU |
| **Windows, macOS** | aucun accès ; aucune des mesures n'est transposable (autre backend de fenêtrage, autre AOT) |
| **Mobile** (Android, iOS) | aucun accès |
| Taux de rafraîchissement, fluidité de défilement | pas de capture vidéo ni de mesure d'images par seconde |
| **Intégration continue** | décision de l'utilisateur : **pas de GitHub Actions**. `scripts/all.sh` est la passe complète, exécutable par n'importe quel outil si besoin |
| `make fsharp-test` du dépôt F* | demande de reconstruire F* ; non lancé |

## Pour reprendre
1. `scripts/setup.sh` puis `scripts/all.sh` (≈ 7 min) : tout doit être vert.
2. Lire `docs/GUIDE.md` (architecture et règles) puis choisir dans « Pas fait, faisable ici ».

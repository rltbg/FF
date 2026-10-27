# Statut : ce qui est fait, testé, pas fait, impossible ici

Dernière passe complète depuis zéro : `scripts/all.sh` → « TOUT OK » (`logs/all.log`). Environnement de test : conteneur
Linux x86_64, 4 vCPU, 16 Go, sans GPU, Xvfb. **C'est un banc d'essai de la boucle F* → F# → Avalonia, pas un produit fini.**

## Fait et vérifié (chaque ligne a un test ou une mesure rejouable)

| Domaine | Ce qui est vérifié | Où |
|---|---|---|
| Preuves F* | invariant de `update` (compteur, ids, sélection < 100 000, pas de débordement u32), correction fonctionnelle de `parse_nat`, équivalence `fnv_bytes` = spécification, condensé exact du texte haché, 21 lemmes | `fst/` |
| Extraction | `Core.fst` et `App.fst` extraits tels quels, 0 warning ; 1 seul contournement F* (`u32_of_char`) | `scripts/extract.sh` |
| Tests exécutables | **1 490 342 vérifications écrites en F\***, 0 échec, en JIT et en NativeAOT ; 171/187 réalisations Custard exercées | `scripts/test.sh`, `docs/ULIB-COUVERTURE.md` |
| Mutations | 13 mutations toutes détectées (5 par F*, les autres par les tests) | `scripts/mutate.sh` |
| Interface | 3 onglets + Volumes, pilotés par xdotool, **état du modèle vérifié à chaque étape**, AOT et JIT | `scripts/ui_smoke.sh` |
| Rechargement à chaud | 5 scénarios (vue, logique, type du modèle, mode sans preuves, onglet Volumes) ; déchargement de **tous** les contextes | `scripts/hotreload.sh` |
| NativeAOT | publication, **0 warning** (bureau ; option `--reflectionfree`, `docs/AVERTISSEMENTS-AOT.md`), démarrage, RSS, taille | `scripts/build.sh`, `scripts/startup.sh` |
| Modes sans preuves | `--lax` et `--admit_smt_queries true` testés (`logs/loop_bench.log`) : vérification de 1,0 à 1,8 s au lieu de 2,7 à 4,9 s ; la compilation F# (≈ 5 s) domine la boucle dans les trois modes | `scripts/loop.sh`, `scripts/loop_bench.sh` |
| Gros volumes | liste de 100 000 lignes virtualisée (côté hôte), texte de 1 022 080 octets haché par la fonction F* prouvée, coût mesuré du modèle F* à 100 000 éléments | `docs/GUIDE.md` §7 |
| Sous-ensemble F* extractible | 46 cas (matrice : 25 OK, 6 EXTRACT, 1 BUILD, 13 RUN attendus) ; tests amont : 33 OK, 3 EXTRACT ; balayage d'ulib : 61 OK, 69 vides, 84 EXTRACT, 7 BUILD (chaînes, listes, Seq/Map/Set, entiers machine, Bytes, Printf, Float64…), passage à l'échelle | `docs/MATRICE-FSTAR.md` |
| Multi-plateformes | **en local (`all.sh`)** : JIT, NativeAOT Linux x64, navigateur (WebAssembly, **exécuté** dans Chromium). **En CI** (`docs/CI.md`) : NativeAOT Windows/macOS/Linux × x64/arm64, Android arm64, iOS (appareil, non signé), WebAssembly. Le développement se fait en JIT (`scripts/dev.sh`) ; `scripts/platforms.sh` (JIT multi-RID, Android, iOS en local) reste disponible à la main | `docs/PLATEFORMES.md`, `docs/CI.md`, `scripts/platforms.sh` |
| Défauts de F* documentés | 14 constats avec reproduction et correctif proposé | `docs/UPSTREAM-FSTAR.md` |
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
| **Windows, macOS** (lancement) | aucun accès ; les binaires se **construisent** (publication croisée) mais n'ont jamais été lancés ; aucune mesure n'est transposable |
| **Android, iOS** (lancement) | APK construit, jamais installé (pas d'émulateur) ; iOS jamais compilé (macOS + Xcode requis) |
| Taux de rafraîchissement, fluidité de défilement | pas de capture vidéo ni de mesure d'images par seconde |
| **Intégration continue** | GitHub Actions **pour construire** toutes les plateformes (`.github/workflows/build.yml`, `docs/CI.md`) : **exécuté avec succès sur les 9 jobs** (run 40365069048, cibles `all`, 7 min 6 s de bout en bout) : extraction F*, Linux x64/arm64, Windows x64/arm64, macOS arm64+x64, WebAssembly, Android NativeAOT arm64, iOS simulateur. Les binaires ne sont **pas lancés** par la CI. Les tests restent `scripts/all.sh` |
| `make fsharp-test` du dépôt F* | demande de reconstruire F* ; non lancé |

## Part de F* (`scripts/loc.sh`)
F* livré 369 lignes (Core 99, Big 41, App 229) contre 273 de F# à la main livré (Ui 236, HostStatic 37) : **57 %** ; HostDev 169 (dev seulement). Tests : 0 ligne de F#.
Reste en F# : interprétation des nœuds en contrôles Avalonia et réconciliation par position, boucle MVU, `LazyRows` (plomberie `IList`), colle `toNode`, rechargement à chaud par réflexion. Les tests unitaires de `LazyRows` (F#) ont disparu : l'`IList` n'est couverte que par le smoke GUI (défilement, sélection) ; la logique (contenu, réciproque) est testée exhaustivement en F* (`TBig`).

## Pour reprendre
1. `scripts/setup.sh` puis `scripts/all.sh` (≈ 21 min) : tout doit être vert.
2. Lire `docs/GUIDE.md` (architecture et règles) puis choisir dans « Pas fait, faisable ici ».

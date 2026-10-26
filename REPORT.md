# Rapport (2e passe) : boucle F* → F# → Avalonia, revue contre les documentations

**Verdict : boucle viable avec contournements mineurs.**
- La logique applicative entière est écrite et prouvée en F*. Elle s'extrait en F# sans retouche et tourne à l'identique en JIT et en NativeAOT.
- Le rechargement à chaud exige l'hôte maison : `dotnet watch` ne recharge pas F#, et la doc Microsoft le dit (« Hot Reload … is not supported when you debug F# code »).
- Un changement de type du modèle réinitialise l'état.
- Les gros volumes (liste de 100 000 lignes, texte de 1 Mo) sont gérés côté hôte, virtualisés, le modèle F* ne gardant que des identifiants et un condensé (§7).

Documents complémentaires : [`docs/GUIDE.md`](docs/GUIDE.md) (tout), [`docs/STATUT.md`](docs/STATUT.md) (fait / limité / impossible),
[`docs/MATRICE-FSTAR.md`](docs/MATRICE-FSTAR.md), [`docs/UPSTREAM-FSTAR.md`](docs/UPSTREAM-FSTAR.md), [`docs/FSTAR-char_code.md`](docs/FSTAR-char_code.md).

Versions : F* 2026.10.25 (commit 362e792), .NET SDK 10.0.403 (dotnet-install.sh, version épinglée), Avalonia 12.1.4,
FSharp.Core 10.1.403. Environnement : conteneur Linux x86_64, 4 vCPU, sans GPU, Xvfb.
1re passe : commit `1a45fba` (rapport et code d'origine).

Cette passe est partie d'une remise à zéro complète :
- espace de travail, caches NuGet et outils supprimés ;
- réinstallation par `scripts/setup.sh` ;
- relecture de chaque implémentation contre sa documentation ;
- corrections, puis exécution de `scripts/all.sh` depuis zéro : `TOUT OK` (≈ 7 min, `logs/all.log`).

Puis extension de la passe (étapes laissées « non testées » dans la version précédente) : défauts de F* investigués et documentés, matrice d'extraction F* (28 cas), gros volumes, passage à l'échelle. Décision de l'utilisateur : **pas d'intégration continue GitHub Actions**.

## 1. Erreurs trouvées dans le code de la 1re passe, et corrections

| # | Défaut | Référence | Correction | Vérifié par |
|---|---|---|---|---|
| 1 | L'« empreinte FNV-1a » hachait l'octet bas de chaque unité UTF-16 : collision entre U+0100 et U+0000, et ce n'est pas FNV-1a d'une chaîne au sens du draft | draft-eastlake-fnv-21 : le hash porte sur des octets | `fnv_utf8 = fnv_bytes (FStar.Bytes.utf8_encode s)`, avec `lemma_fnv_bytes` : implémentation `byte[]` = spécification liste | tests « utf8 Ā ≠ \0 », « é », emoji, 20 000 cas différentiels contre `Encoding.UTF8` |
| 2 | Message « caractères imprimables » alors que DEL (0x7F) et les contrôles C1 (0x80–0x9F) étaient acceptés | — | `printable` rejette C0, DEL et C1 ; le message dit « sans caractère de contrôle » | test exhaustif sur les 65 536 unités UTF-16 |
| 3 | `parse_nat` : seule la borne ≤ 1000 était prouvée, pas la valeur | — | Spec `dec_value` (`noextract`) et `lemma_parse_nat` : `Some n` ⇔ chaîne non vide de chiffres ASCII de valeur ≤ 1000, et `n` = cette valeur | 200 000 cas différentiels contre `Int64.Parse` |
| 4 | `lemma_accepted_valid` ne faisait que répéter le type | — | Renforcé : Accepté ⇒ nom = saisie, `name_ok`, âge = `parse_age`, empreinte = `fnv_utf8 nom` ; Rejeté ⇒ nom invalide ou âge invalide ; jamais `Editing` après `Submit` | marches aléatoires 300 × 400 messages |
| 5 | Compteur en `Prims.int` (`bigint`), alors que le brief demande des entiers machine | brief | `FStar.Int32` → `int32` natif, sans débordement prouvé | tests de saturation ±1000 |
| 6 | **Course dans l'interpréteur** : `TextChanged` est asynchrone et l'arbre était reconstruit à chaque frappe, donc un clic juste après une frappe visait un bouton remplacé entre l'appui et le relâchement (« Ajouter » perdu, saisie dans le mauvais champ) | doc `TextBox.TextChanged` : « Occurs asynchronously after text changes » | Interpréteur **réconciliant** (réutilisation des contrôles, propriétés mises à jour, `msg` lu dans `Tag` au moment de l'événement) et écoute synchrone de `TextProperty` via `PropertyChanged` | smoke test avec frappe à 10 ms puis clic immédiat, 10/10 runs OK |
| 7 | Le smoke test de la 1re passe se contentait de « 5 captures différentes » et a annoncé OK sur une UI fausse | — | Oracle sur l'**état du modèle** : `MVU_TRACE` journalise le modèle après chaque rendu, vérifié à chaque étape | `scripts/ui_smoke.sh` |
| 8 | `X11RenderingMode.Software` forcé seul | doc `X11PlatformOptions.RenderingMode` : ajouter `Software` comme **repli** | Modes par défaut de la plateforme ; `MVU_SOFTWARE_RENDERING=1` pour forcer | GUI OK dans les deux modes |
| 9 | `UseX11().UseSkia().UseHarfBuzz()` écrit à la main | doc Avalonia 12 (breaking changes) : HarfBuzz est inclus avec `UsePlatformDetect` | `UsePlatformDetect()`, compatible AOT | GUI AOT OK |
| 10 | Analyseurs AOT inactifs sur les bibliothèques | doc Avalonia Native AOT : `IsAotCompatible` sur toutes les bibliothèques | `app/Directory.Build.props`, qui s'applique aussi au projet généré par F* | 0 warning sur nos assemblies |
| 11 | `HostDev` : le premier contexte chargé ne se déchargeait jamais | doc .NET « unloadability » ; **code source Avalonia 12.1.4** (`ScrollContentPresenter`) | racine **stable** dans le `ScrollViewer` : on ne remplace que son enfant (cause racine : §5, « Fuite du premier contexte ») ; `Interp.Reset()` au remplacement du cœur | dump ClrMD avant/après, `hotreload.sh` (assertion) |
| 12 | `HostDev` : transfert de modèle sans contrôle des types primitifs, et exceptions autres que `TransplantFailed` non rattrapées | — | Contrôle de type strict et capture générique, qui mène à une réinitialisation | scénario C |
| 13 | Scripts avec chemins absolus de la machine d'essai | — | `scripts/` relatifs au dépôt, outils dans `.tools/` | `all.sh` depuis zéro |
| 14 | Mesure « `fnv` 10 fois plus lent en JIT » | — | Échauffement insuffisant : avec un échauffement correct, la liste donne 0,091 µs en JIT comme en AOT | `logs/bench_sizes.log` |

## 2. Conformité aux documentations, par implémentation

| Implémentation | Documentation consultée | Constat |
|---|---|---|
| Constantes FNV-1a | draft-eastlake-fnv-21 §2, annexe C | offset 0x811C9DC5 et prime 0x01000193 conformes ; les 6 vecteurs FNV32 de l'annexe C (avec et sans terminateur nul) passent |
| `FStar.Bytes` | `ulib/FStar.Bytes.fsti` ; réalisations dans `PrintFSharp.fst` | `utf8_encode` exige `maxlen s 2^30`, prouvé par `lemma_name_ok_maxlen`. .NET remplace un demi-surrogate isolé par U+FFFD ; la spec ne promet pas l'injectivité, donc c'est cohérent |
| `FStar.Char` / `FStar.String` | `ulib/*.fsti`, `custard.md` §122.9 | `char` .NET = unité UTF-16 ; `length` et `list_of_string` comptent des unités UTF-16, de façon cohérente entre elles |
| `FStar.Char.u32_of_char` | `PrintFSharp.fst` (`supported_realizations`) | la fonction figure dans la liste mais son type `char_code` ne l'est pas : `Error 395`, **reconfirmé sur l'installation neuve**. Contournement : `int_of_char` |
| `noextract` | `custard.md` §4.3–4.4 | utilisé seulement pour des fonctions de spec ; les spécifications de type `prop` sont éliminées sans |
| Options F* | `fstar.exe --help` | `--lax` existe et `--admit_smt_queries true` aussi ; les deux permettent l'extraction |
| Démarrage Avalonia | doc `StartWithClassicDesktopLifetime` : « lifetime builder to modify the lifetime **before application started** » | fenêtre créée dans `OnFrameworkInitializationCompleted` |
| `TextBox.PlaceholderText` | doc Avalonia 12 breaking changes : `Watermark` devient obsolète | `PlaceholderText` utilisé |
| `AssemblyLoadContext` | learn.microsoft.com « unloadability » | déchargement coopératif, poignée forte du runtime pendant le déchargement ; mesuré, voir §5 |
| Hot Reload F# | learn.microsoft.com, page Hot Reload : « not supported when you debug F# code » | mesuré : `Restart is needed to apply the changes.` |

## 3. Tests (`logs/all.log`, `logs/mutations.log`)

- **Suite :** 950 851 vérifications, **0 échec en JIT et en AOT**. Elle couvre : vecteurs FNV du draft ; équivalence entre implémentation tableau et spec liste ; `fnv_append` ; `fnv_utf8` contre `Encoding.UTF8` ; analyse décimale (cas limites et différentiel) ; `printable` exhaustif ; invariant de `update` recalculé indépendamment ; tous les lemmes d'application ; garde de débordement des identifiants (`next_id` = 0xFFFFFFFD accepté, 0xFFFFFFFE refusé) ; totalité de `view` ; sélection `Select` (0, 99 999 acceptés ; 100 000 et 4 294 967 295 refusés) ; `HashText` (4 000 000 unités acceptées, 4 000 001 refusées, texte de 1 Mo comparé à une référence indépendante).
- **Mutations** (`scripts/mutate.sh`, toutes détectées) :

| Mutation | Preuves F* | Tests |
|---|---|---|
| M1 : prime FNV 0x01000193 → 0x01000192 | acceptée (aucune preuve ne fixe la constante) | 39 534 échecs |
| M2 : borne d'âge 150 → 151 | **rejetée** (`Failed to prove: FStar.UInt32.v n <= 150`) | en `--lax` : 10 échecs |
| M3 : règle C1 159 → 158 | acceptée | 2 échecs (test exhaustif) |

- **GUI** (`scripts/ui_smoke.sh`, oracles sur l'état du modèle) : OK en AOT et en JIT, en rendu par défaut et en logiciel forcé. 10 runs consécutifs OK. La fenêtre X11 appartient au processus (`_NET_WM_PID`). Le parcours valide : compteur = 2, ajout de deux éléments, refus d'un nom de 25 caractères, cocher, supprimer les cochés, formulaire accepté avec l'empreinte 4267605246 (= FNV-1a de l'UTF-8 de « Ada Lovelace »), rejet de l'âge 200. Le parcours inclut maintenant l'onglet **Volumes** : sélection d'une ligne, défilement jusqu'à la ligne 99 999, hachage du texte de 1 Mo par F* (`digest=1,832080,1791175457`, égal à la référence Python). Captures : `shots/smoke/`.

## 4. Part de F*

| Source | Lignes utiles |
|---|---|
| F* (Core 99 + App 206) | **305**, dont ≈ 90 de lemmes et ≈ 4 de spec non extraite |
| F# à la main livré (Ui 232 + HostStatic 49, dont ≈ 20 lignes de journal de test) | **281** |
| F# à la main, dev seulement (HostDev) | 165 |
| Tests | 248 |
| F# extrait (+ bibliothèque Custard générée) | 366 (+ 228) |

Toute la logique applicative est en F*. Le F# écrit à la main est un interpréteur générique, l'affichage des gros volumes et une colle de 12 lignes. En lignes, F* représente 52 % du code livré écrit à la main (305 sur 586).

**21 lemmes :**
- Core : `fnv_append`, `lemma_fnv_bytes`, `lemma_dec_mono`, `lemma_parse_digits`, `lemma_parse_nat`, `lemma_parse_bounded`, `lemma_empty_rejected`, `lemma_name_len`, `lemma_len_maxlen`, `lemma_name_ok_maxlen` ;
- App : `lemma_weaken`, `lemma_remove`, `lemma_toggle`, `lemma_drop`, `lemma_inc_dec`, `lemma_add_grows`, `lemma_remove_gone`, `lemma_accepted_valid`, `lemma_select`, `lemma_select_out_of_range`, `lemma_hash_text`.

S'y ajoutent l'invariant de `update` (dans son type, y compris `sel < 100 000`) et l'absence de débordement de l'arithmétique machine.

## 5. Boucle de dev

**Tour de boucle sur de vraies éditions** (`logs/loop_bench.log`, médiane de 3, en ms) :

| Édition | Mode | Vérif. F* | Extraction | `dotnet build` | Total |
|---|---|---|---|---|---|
| vue (App.fst) | complet | 3 532 | 778 | 5 174 | 9 486 |
| Core.fst (+ App) | complet | 4 745 | 752 | 5 274 | 10 845 |
| vue | `--admit_smt_queries true` | 1 314 | 733 | 4 934 | 7 046 |
| Core.fst | `--admit_smt_queries true` | 1 573 | 744 | 5 091 | 7 362 |
| vue | `--lax` | 1 283 | 843 | 5 394 | 7 820 |
| Core.fst | `--lax` | 1 619 | 765 | 4 953 | 7 361 |

La compilation F# (≈ 5 s) domine dans les trois modes. Les preuves ajoutées (grands volumes) coûtent ≈ 0,6 à 1,5 s de plus en mode complet qu'avant.

**Rechargement à chaud** (`scripts/hotreload.sh`, passe finale) :

| Scénario | Sauvegarde → rendu | Rechargement | Résultat |
|---|---|---|---|
| A : texte de vue | 12,2 s | 35 ms | état conservé (`Valeur HOT : 3`) |
| B : logique de `update` (Reset → 10) | 11,7 s | 13 ms | appliquée sans redémarrage |
| C : champ ajouté au modèle | 10,6 s | 11 ms | `model-RESET (champs changés: app_model)` ; **changement de type = état réinitialisé** |
| D : texte de vue, `--lax` | 8,2 s | 12 ms | OK |
| E : onglet Volumes (`BigList` : réflexion sur une `option`) puis rechargement | — | — | sélection (`sel=2`) et condensé (`832080`) **conservés** après rechargement |

Les durées de bout en bout varient de 7,7 à 12,2 s selon les passes (charge de la machine) ; 5 contextes remplacés, **tous déchargés** (`alc-alive 0/5`).

**Fuite du premier contexte : cause trouvée et corrigée.** Dans la passe précédente, le premier contexte remplacé ne se déchargeait jamais (`1/N vivants=0`), les suivants si. Analyse :
- `gcroot` (dotnet-dump) ne trouvait aucune racine managée : il ne montre que les poignées internes du runtime. J'ai donc écrit un analyseur ClrMD (non versionné) qui calcule les objets vivants depuis les vraies racines (pile, poignées fortes, statiques) puis cherche qui référence le `LoaderAllocator` fuyant.
- Résultat : 6 `Avalonia.Controls.Button` vivants, via `EffectiveValue<object>` (la propriété `Tag`, qui contient les `msg` de l'ancien assembly). Chemin depuis la racine : `Interp` → nouvelle racine → `ScrollContentPresenter` → champ **`_scrollSnapPointsInfo`** = **ancienne racine** (`StackPanel`) → ses `Button`.
- Source Avalonia 12.1.4 : `ScrollContentPresenter.MeasureOverride` exécute `UpdateSnapPoints()` **une seule fois** (drapeau `_isSnapPointsUpdated`), qui mémorise le contenu d'alors dans `_scrollSnapPointsInfo` et s'abonne à ses événements. `ChildChanged` ne le rafraîchit jamais. Remplacer le contenu du `ScrollViewer` retient donc la **première** racine pour toute la vie du presenter. C'est un défaut d'Avalonia ; je n'ai pas cherché de ticket amont.
- Pourquoi seulement le premier : le champ est écrit au premier `Measure`, avec la première racine, et plus jamais ensuite.
- Hypothèses écartées par mesure : réflexion F# et transfert de modèle (dépôt console : 5 contextes chaînés, tous déchargés), nombre d'appels `MethodInfo.Invoke` (jusqu'à 200), tiering et PGO du JIT (désactivés : rien ne change), création de la fenêtre dans `Opened` ou différée, journal de rendu, détachement explicite du contenu.
- **Correctif** (`Ui/Runner.fs`) : un `StackPanel` hôte stable est placé une fois dans le `ScrollViewer` ; on ne remplace que son enfant. Le presenter ne voit jamais de nouveau contenu, donc `_scrollSnapPointsInfo` désigne l'hôte, qui ne retient rien de l'ancien assembly.
- **Vérification :** `0/1`, `0/2`, `0/3` dans le journal (au lieu de `1/N`). Dump ClrMD après deux rechargements : 1 seul `LoaderAllocator` et 1 seul `Extracted.dll` chargé (contre 2 et 2 avant). `scripts/hotreload.sh` contient maintenant une assertion (0 ancien contexte vivant) ; **sans le correctif elle échoue** (`KO déchargement : alc-alive 1/4 vivants=0`), avec elle passe (`0/4`).

**`dotnet watch`** (`logs/watch_check*.log`) :
- `Restart is needed to apply the changes.`, sur le F# extrait comme sur le F# écrit à la main ; état perdu ; 5,6 à 7,5 s.
- Avec `PublishAot=true` dans le projet (recommandé par la doc Avalonia), `dotnet watch` annonce aussi « Project does not support Hot Reload: 'PublishAot' property is 'True' ». Avec `StartupHookSupport=true`, cet avertissement disparaît, mais F# donne toujours `Restart is needed`.

## 6. NativeAOT (`logs/startup_bench_final.log`)

- **Warnings :** `IL3053` et `IL2104` sur **FSharp.Core seulement** ; 0 sur Ui, Extracted, HostStatic et Tests, avec `IsAotCompatible`.
- **Taille :** binaire 20,7 Mo + libSkiaSharp 11,2 Mo + libHarfBuzzSharp 2,8 Mo = **34,7 Mo** (hors `.dbg`, 47 Mo). Tests AOT : 3,5 Mo.
- **Démarrage et RSS** (délai jusqu'à la fenêtre X11 mappée, pas le premier rendu ; 10 runs ; p95 sur 10 = max) :

| Mode | Médiane | p95 | RSS au repos |
|---|---|---|---|
| AOT, rendu par défaut | 111 ms | 142 ms | 109 Mo |
| AOT, logiciel forcé | 63 ms | 80 ms | 40 Mo |
| JIT, rendu par défaut | 716 ms | 916 ms | 156 Mo |
| JIT, logiciel forcé | 622 ms | 730 ms | 88 Mo |

À froid (cache de pages vidé, 1 run, rendu par défaut) : AOT 374 ms, JIT 1 192 ms.

Sous Xvfb, le mode par défaut passe par GLX et Mesa (`libgallium`, rastérisation logicielle), d'où ≈ +70 Mo de RSS. Sur une machine avec GPU, ce mode utiliserait l'accélération matérielle : ces chiffres ne valent ni pour le GPU ni pour le mobile.

- **Micro-mesures** (JIT / AOT, µs) :

| Opération | JIT | AOT |
|---|---|---|
| `fnv_bytes` 64 octets | 0,132 | 0,057 |
| `fnv` liste 64 octets | 0,091 | 0,092 |
| `update` Inc+Dec | 0,106 | 0,084 |
| `update` Toggle (1 000 éléments) | 19,6 | 28,5 |
| `view` (1 000 éléments) | 116 | 119 |
| `update` Select | 0,059 | 0,054 |
| `fnv_utf8` du texte de 1 022 080 octets | 3 643 | 3 027 |
| `update` HashText (même texte) | 2 307 | 2 346 |

Les résultats de calcul sont identiques en JIT et en AOT.

## 7. Gros volumes

Conception : les données restent **côté hôte** ; le modèle F* ne garde que `sel : option U32.t` (< 100 000, prouvé) et `digest` (longueur, FNV-1a). Détail et alternatives : `docs/GUIDE.md` §7.

| Mesure | Résultat |
|---|---|
| 100 000 éléments **dans le modèle F\*** (`Tests bench`) | construction 238 à 346 ms, 10,8 Mo, `Toggle` 7 à 17 ms, `view` 75 à 81 ms pour 200 008 nœuds : impraticable à afficher sans virtualisation |
| Liste de 100 000 lignes **virtualisée** (`BigList`) | +0 Mo de RSS ; défilement jusqu'à la ligne 99 999 ; sélection par F* |
| `TextBox` avec le texte de 1 Mo | **+170 Mo** de RSS (330 Mo contre 160 Mo) : abandonné |
| Visualiseur de lignes virtualisé pour le texte | +6 Mo de RSS (AOT) |
| Hachage du texte de 1 022 080 octets par la fonction F* prouvée | 3,0 à 3,6 ms ; résultat égal à une référence Python (832 080 caractères, FNV-1a 1791175457) |
| Liste **non virtualisée** (un contrôle par élément), `scripts/list_scale.sh` | 1 000 éléments : interface occupée 1,7 s (AOT) / 4,9 s (JIT) ; 5 000 : 6,2 s / 8,2 s et 0,9 à 1 Go de RSS ; clic ensuite en ≈ 115 ms |

## 8. Matrice d'extraction F* et défauts de F*

28 cas (`docs/matrix/`, `scripts/matrix.sh`) : **24 OK, 3 échecs d'extraction, 1 divergence à l'exécution** ; résultats détaillés dans `docs/MATRICE-FSTAR.md`. Passage à l'échelle (`scripts/scale.sh`) : `Seq` = liste F# (index O(n)), `Map`/`Set` = chaînes de fermetures, `Set` déborde la pile entre 10⁵ et 10⁶ éléments.

Défauts de F* constatés, avec reproduction et correctif proposé (**non déposés**, `docs/UPSTREAM-FSTAR.md`) :
1. **`/` et `%` de `Prims.int` : F* est euclidien, le F# extrait tronque vers zéro** (F* prouve `(-7)/2 = -4`, le F# calcule `-3`) : un fait prouvé est faux à l'exécution pour des opérandes négatifs. Les entiers machine ne sont pas concernés.
2. `FStar.Char.u32_of_char` : `Error 395` (`docs/FSTAR-char_code.md`).
3. Négation unaire d'un `int` non constant et `Prims.abs` : `Error 395 Prims.op_Tilde_Minus`.
4. Borne de `char_code` : `0xD7FF` exclu ; 5. `char_of_u32` tronque au-delà de `0xFFFF` ; 6. documentation (28 tests F# et non 24) et suite F# qui n'exerce pas `Char`.

## 9. Contournements restants

| Contournement | Erreur exacte | Classe |
|---|---|---|
| `int_of_char` au lieu de `u32_of_char` (ou `assume val` + `@@custard_extern`, testé) | `Error 395: Custard: the type FStar.Char.char_code is realized by hand-written OCaml and has no F# realization.` | inévitable (F* 2026.10.25) |
| Vérifier Core avant App | `Warning 247 … checked file _cache/Core.fst.checked does not exist`, puis `Error 317` | comportement F* (le Makefile du dépôt le gère via `.depend`) |
| Hôte `AssemblyLoadContext` au lieu de `dotnet watch` | `Restart is needed to apply the changes.` | inévitable (F# non supporté, d'après la doc) |
| Sondage du fichier au lieu de `FileSystemWatcher` | aucun événement inotify à la réécriture par MSBuild dans ce conteneur | environnement (cause non vérifiée) |

## 10. Limites

- Interpréteur réconciliant par **position** : pas de clés. Une liste dont on retire un élément réutilise les contrôles suivants, avec leurs propriétés mises à jour. C'est correct, mais pas optimal.
- Non testés (impossibles ici) : Windows, macOS, mobile, GPU réel, fluidité de défilement (pas de mesure d'images par seconde). Détail : `docs/STATUT.md`.
- Éditeur de texte de grande taille (édition) non conçu : un `TextBox` de 1 Mo coûte +170 Mo ; le gros texte est en lecture seule.
- Liste non virtualisée utilisable jusqu'à quelques centaines d'éléments seulement (§7).
- Les preuves ne fixent ni les constantes FNV ni la règle des caractères : ce sont les tests qui les gardent (M1, M3).
- `custard.md` se décrit comme « design sketch ». `make fsharp-test` du dépôt F* n'a pas été lancé.

## 11. Conditions qui changeraient le verdict

- **Vers « viable » :** un Hot Reload F# dans `dotnet watch`, et une réalisation F# de `char_code`.
- **Vers « non viable » :** des types de modèle qui changent à chaque édition, un besoin GPU ou mobile non couvert ici, ou une compilation F# qui grossirait au point de dominer encore plus la boucle.

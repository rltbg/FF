# Rapport (2e passe) : boucle F* → F# → Avalonia, revue contre les documentations

**Verdict : boucle viable avec contournements mineurs.**
- La logique applicative entière est écrite et prouvée en F*. Elle s'extrait en F# sans retouche et tourne à l'identique en JIT et en NativeAOT.
- Le rechargement à chaud exige l'hôte maison : `dotnet watch` ne recharge pas F#, et la doc Microsoft le dit (« Hot Reload … is not supported when you debug F# code »).
- Un changement de type du modèle réinitialise l'état.

Versions : F* 2026.10.25 (commit 362e792), .NET SDK 10.0.403 (dotnet-install.sh, version épinglée), Avalonia 12.1.4,
FSharp.Core 10.1.403. Environnement : conteneur Linux x86_64, 4 vCPU, sans GPU, Xvfb.
1re passe : commit `1a45fba` (rapport et code d'origine).

Cette passe est partie d'une remise à zéro complète :
- espace de travail, caches NuGet et outils supprimés ;
- réinstallation par `scripts/setup.sh` ;
- relecture de chaque implémentation contre sa documentation ;
- corrections, puis exécution de `scripts/all.sh` depuis zéro : `TOUT OK` en 4 min 15 s (`logs/all.log`).

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

- **Suite :** 949 803 vérifications, **0 échec en JIT et en AOT**. Elle couvre : vecteurs FNV du draft ; équivalence entre implémentation tableau et spec liste ; `fnv_append` ; `fnv_utf8` contre `Encoding.UTF8` ; analyse décimale (cas limites et différentiel) ; `printable` exhaustif ; invariant de `update` recalculé indépendamment ; tous les lemmes d'application ; garde de débordement des identifiants (`next_id` = 0xFFFFFFFD accepté, 0xFFFFFFFE refusé) ; totalité de `view`.
- **Mutations** (`scripts/mutate.sh`, toutes détectées) :

| Mutation | Preuves F* | Tests |
|---|---|---|
| M1 : prime FNV 0x01000193 → 0x01000192 | acceptée (aucune preuve ne fixe la constante) | 37 972 échecs |
| M2 : borne d'âge 150 → 151 | **rejetée** (`Failed to prove: FStar.UInt32.v n <= 150`) | en `--lax` : 10 échecs |
| M3 : règle C1 159 → 158 | acceptée | 2 échecs (test exhaustif) |

- **GUI** (`scripts/ui_smoke.sh`, oracles sur l'état du modèle) : OK en AOT et en JIT, en rendu par défaut et en logiciel forcé. 10 runs consécutifs OK. La fenêtre X11 appartient au processus (`_NET_WM_PID`). Le parcours valide : compteur = 2, ajout de deux éléments, refus d'un nom de 25 caractères, cocher, supprimer les cochés, formulaire accepté avec l'empreinte 4267605246 (= FNV-1a de l'UTF-8 de « Ada Lovelace »), rejet de l'âge 200. Captures : `shots/smoke/`.

## 4. Part de F*

| Source | Lignes utiles |
|---|---|
| F* (Core 96 + App 157) | **253**, dont ≈ 74 de lemmes et ≈ 15 de spec non extraite |
| F# à la main livré (Ui 161 + HostStatic 37, dont 12 lignes de journal de test) | **198** |
| F# à la main, dev seulement (HostDev) | 157 |
| Tests | 193 |
| F# extrait (+ bibliothèque Custard générée) | 279 (+ 228) |

Toute la logique applicative est en F*. Le F# écrit à la main est un interpréteur générique et une colle de 10 lignes. En lignes, F* représente 56 % du code livré écrit à la main (253 sur 451).

**17 lemmes :**
- Core : `fnv_append`, `lemma_fnv_bytes`, `lemma_dec_mono`, `lemma_parse_digits`, `lemma_parse_nat`, `lemma_parse_bounded`, `lemma_empty_rejected`, `lemma_name_len`, `lemma_name_ok_maxlen` ;
- App : `lemma_weaken`, `lemma_remove`, `lemma_toggle`, `lemma_drop`, `lemma_inc_dec`, `lemma_add_grows`, `lemma_remove_gone`, `lemma_accepted_valid`.

S'y ajoutent l'invariant de `update` (dans son type) et l'absence de débordement de l'arithmétique machine.

## 5. Boucle de dev

**Tour de boucle sur de vraies éditions** (`logs/loop_bench.log`, médiane de 3, en ms) :

| Édition | Mode | Vérif. F* | Extraction | `dotnet build` | Total |
|---|---|---|---|---|---|
| vue (App.fst) | complet | 2 912 | 795 | 5 123 | 8 753 |
| Core.fst (+ App) | complet | 4 384 | 721 | 5 416 | 10 125 |
| vue | `--admit_smt_queries true` | 1 175 | 778 | 5 086 | 6 834 |
| Core.fst | `--admit_smt_queries true` | 1 760 | 819 | 5 066 | 7 520 |
| vue | `--lax` | 1 168 | 743 | 4 835 | 6 705 |
| Core.fst | `--lax` | 1 308 | 722 | 4 604 | 6 608 |

La compilation F# (≈ 5 s) domine. Les preuves renforcées coûtent environ 1 s de plus qu'en 1re passe.

**Rechargement à chaud** (`scripts/hotreload.sh`, passe finale) :

| Scénario | Sauvegarde → rendu | Rechargement | Résultat |
|---|---|---|---|
| A : texte de vue | 9,8 s | 33 ms | état conservé (`Valeur HOT : 3`) |
| B : logique de `update` (Reset → 10) | 9,5 s | 11 ms | appliquée sans redémarrage |
| C : champ ajouté au modèle | 9,5 s | 11 ms | `model-RESET (champs changés: app_model)` ; **changement de type = état réinitialisé** |
| D : texte de vue, `--lax` | 8,4 s | 11 ms | OK |

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

## 6. NativeAOT (`logs/startup.log`, `logs/bench_sizes.log`)

- **Warnings :** `IL3053` et `IL2104` sur **FSharp.Core seulement** ; 0 sur Ui, Extracted, HostStatic et Tests, avec `IsAotCompatible`.
- **Taille :** binaire 20,6 Mo + libSkiaSharp 11,2 Mo + libHarfBuzzSharp 2,8 Mo = **34,6 Mo** (hors `.dbg`, 46 Mo). Tests AOT : 3,4 Mo.
- **Démarrage et RSS** (délai jusqu'à la fenêtre X11 mappée, pas le premier rendu ; 10 runs ; p95 sur 10 = max) :

| Mode | Médiane | p95 | RSS au repos |
|---|---|---|---|
| AOT, rendu par défaut | 110 ms | 123 ms | 117 Mo |
| AOT, logiciel forcé | 60 ms | 66 ms | 39 Mo |
| JIT, rendu par défaut | 639 ms | 699 ms | 163 Mo |
| JIT, logiciel forcé | 544 ms | 592 ms | 88 Mo |

À froid (cache de pages vidé, 1 run, rendu par défaut) : AOT 281 ms, JIT 1 029 ms.

Sous Xvfb, le mode par défaut passe par GLX et Mesa (`libgallium`, rastérisation logicielle), d'où +77 Mo de RSS. Sur une machine avec GPU, ce mode utiliserait l'accélération matérielle : ces chiffres ne valent ni pour le GPU ni pour le mobile.

- **Micro-mesures** (JIT / AOT, µs) :

| Opération | JIT | AOT |
|---|---|---|
| `fnv_bytes` 64 octets | 0,143 | 0,062 |
| `fnv` liste 64 octets | 0,091 | 0,091 |
| `update` Inc+Dec | 0,083 | 0,068 |
| `update` Toggle (1 000 éléments) | 19,9 | 27,1 |
| `view` (1 000 éléments) | 103 | 124 |

Les résultats de calcul sont identiques en JIT et en AOT.

## 7. Contournements restants

| Contournement | Erreur exacte | Classe |
|---|---|---|
| `int_of_char` au lieu de `u32_of_char` | `Error 395: Custard: the type FStar.Char.char_code is realized by hand-written OCaml and has no F# realization.` | inévitable (F* 2026.10.25) |
| Vérifier Core avant App | `Warning 247 … checked file _cache/Core.fst.checked does not exist`, puis `Error 317` | comportement F* (le Makefile du dépôt le gère via `.depend`) |
| Hôte `AssemblyLoadContext` au lieu de `dotnet watch` | `Restart is needed to apply the changes.` | inévitable (F# non supporté, d'après la doc) |
| Sondage du fichier au lieu de `FileSystemWatcher` | aucun événement inotify à la réécriture par MSBuild dans ce conteneur | environnement (cause non vérifiée) |

## 8. Limites

- Interpréteur réconciliant par **position** : pas de clés. Une liste dont on retire un élément réutilise les contrôles suivants, avec leurs propriétés mises à jour. C'est correct, mais pas optimal.
- Non testés : liste de 100 000 lignes, texte de 1 Mo, `Seq`/`Map`/`Set` d'F*, Windows et macOS, GPU réel.
- Les preuves ne fixent ni les constantes FNV ni la règle des caractères : ce sont les tests qui les gardent (M1, M3).
- `custard.md` se décrit comme « design sketch ». `make fsharp-test` du dépôt F* n'a pas été lancé.

## 9. Conditions qui changeraient le verdict

- **Vers « viable » :** un Hot Reload F# dans `dotnet watch`, et une réalisation F# de `char_code`.
- **Vers « non viable » :** des types de modèle qui changent à chaque édition, un besoin GPU ou mobile non couvert ici, ou une compilation F# qui grossirait au point de dominer encore plus la boucle.

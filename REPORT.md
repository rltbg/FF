# Rapport : boucle F* → F# → Avalonia (hot reload en dev, NativeAOT en release)

**Verdict : boucle viable avec contournements mineurs.** Réserves : le rechargement à chaud exige l'hôte maison
(`dotnet watch` ne recharge pas F#), et un changement de type du modèle exige une réinitialisation.
Versions : F* 2026.10.25 (commit 362e792), .NET SDK 10.0.403 (dot.net, builds.dotnet.microsoft.com), Avalonia 12.1.4, FSharp.Core 10.1.403.
Aucun hôte bloqué pendant le test.

## 1. Étapes
| # | Étape | Résultat |
|---|---|---|
| 1 | Environnement | OK |
| 2 | Support F# du dépôt | OK sans bricolage : plus de `fsharp/` + `ulibfs` ni de `make lib-fsharp`. Le backend Custard émet son projet et une bibliothèque de 288 lignes. Test `Hello` du dépôt reproduit à la main ; `make fsharp-test` non lancé. |
| 3 | F* → F# tel quel | OK avec 1 contournement inévitable |
| 4 | Prototype MVU (compteur, liste, formulaire) | OK, 0 warning à la compilation du code extrait |
| 6 | Boucle de dev | OK avec l'hôte `AssemblyLoadContext` ; `dotnet watch` : restart nécessaire |
| 7 | NativeAOT | OK |
| 8 | Tests + mutation | OK : 683 322 vérifications, 0 échec (JIT et AOT) |
| 9 | UI sous Xvfb | OK |

## 2. Journal des contournements
| Problème | Erreur exacte | Classe | Action |
|---|---|---|---|
| `FStar.Char.u32_of_char` | `Error 395: Custard: the type FStar.Char.char_code is realized by hand-written OCaml and has no F# realization.` | Inévitable (cette version) | `FStar.Char.int_of_char` |
| Vérification à froid | `Warning 247 … Checked file _cache/App.fst.checked was not written. Reason: checked file _cache/Core.fst.checked does not exist` puis `Error 317` | Comportement F* | Vérifier dans l'ordre des dépendances |
| Backend Avalonia | `No text shaping system configured. Consider calling UseHarfBuzz().` | Inévitable (API 12.x) | `.UseHarfBuzz()` |
| Fenêtre | `Unable to locate 'Avalonia.Platform.IWindowingPlatform'` | Évitable (mon code) | Créer la fenêtre dans `OnFrameworkInitializationCompleted` |
| Plantage AOT (onglet Formulaire) | `KeyNotFoundException … FSharpValue.GetUnionFields … StructuredPrintfImpl … Ui.Interp.Build` | Évitable (mon code) | `string tag` (réflexion) remplacé par une clé `obj` |
| FileSystemWatcher muet | aucun événement quand MSBuild réécrit la DLL ; `touch` en déclenche un | Environnement (cause non vérifiée) | Sondage mtime/taille toutes les 250 ms |
| `xdotool` introuvable | `Unable to locate package xdotool` | Environnement | `apt-get update` |

Non nécessaires : `LangVersion 5.0`, `noextract`, `uint_to_t`, adaptateur d'`option`.
Non testés : `UsePlatformDetect` après correction, rendu X11 hors mode logiciel.

## 3. Comparaison avec F* 2025.03.25
| Point | 2025.03.25 | 2026.10.25 |
|---|---|---|
| Support F# | `fsharp/` + `ulibfs`, non testé | Custard, bibliothèque embarquée |
| `#light "off"` / LangVersion 5.0 | requis | inutile |
| Littéraux u8 | `0xA5` (int) refusé | `0xa5uy` natif |
| `FStar_UInt8.t` | bigint | uint8 natif |
| `option` | adaptateur manuel | option F# native |
| Spec pure | `noextract` requis | éliminée automatiquement |
| `u32_of_char` | non rencontré | Error 395 |
| Hash FNV 64 octets | 7,6 µs JIT / 12,7 µs AOT | 0,89 µs JIT / 0,09 µs AOT (harnais différent ; écart JIT/AOT non élucidé) |

## 4. Part de F* et preuves
Lignes hors blancs/commentaires : F* 199 (Core 46 + App 153, dont ~37 de lemmes) ; F# à la main livré 140 (Ui 107 + HostStatic 33) ;
HostDev (dev seulement) 153 ; F# extrait 271 (319 brutes) ; bibliothèque Custard générée 289. F* = 59 % du code écrit à la main (199/339).
Toute la logique applicative est en F* ; le F# à la main est un interpréteur générique + ≈15 lignes de colle.
Preuves : invariant de `update` (compteur borné, ids strictement décroissants < `next_id`, pas de débordement u32) ; lemmes
`remove` (élément retiré), `add` (+1), `inc`/`dec`, âge accepté ≤ 150, `parse` ≤ 1000, `fnv_append`, `name_ok` borne la longueur.

## 5. Boucle de dev (secondes)
| Édition | Vérif. F* | Extraction | `dotnet build` | Total | Sauvegarde → rendu visible |
|---|---|---|---|---|---|
| Vue (complet) | 1,8–2,0 | 0,7 | 4,4–5,1 | 7,0–7,8 | 7,2 |
| Logique | 1,8 | 0,8 | 4,4 | 7,0 | 7,3 |
| Type du modèle | 1,9 | 0,7 | 4,9 | 7,5 | 7,7 |
| Preuve (Core) | 2,3 | 0,7 | 4,2 | 7,2 | n.m. |
| Vue (`--admit_smt_queries true`) | 1,0 | 0,7 | 4,8 | 6,5 | n.m. |
| Preuve (`--admit_smt_queries true`) | 1,2 | 0,8 | 4,7 | 6,6 | n.m. |

`--lax` non testé. La compilation F# domine ; le mode sans preuves gagne 0,6–1 s.
Rechargement `AssemblyLoadContext` : 9–32 ms, modèle transféré par réflexion. Vue : état conservé (compteur 3). Logique : nouveau `Reset` (→10) appliqué sans redémarrage.
Changement de type (champ `note`) : `model-RESET (champ absent: app_model.note)`, compteur remis à 0.
`dotnet watch` (F# extrait et F# à la main) : `Restart is needed to apply the changes.` ; relance en 5,6–6,4 s, état perdu.

## 6. NativeAOT (linux-x64)
Publication 1 min 04 s. Warnings : `IL3053`, `IL2104` (FSharp.Core) seulement. Taille : 20,7 + 11,2 (Skia) + 2,8 (HarfBuzz) = 34,6 Mo (hors `.dbg` 46 Mo).
Démarrage jusqu'à la fenêtre X11 mappée (10 exécutions) : AOT médiane 55 ms / p95 73 ms ; JIT 552 / 597 ms.
Premier lancement, cache de pages vidé (1 exécution) : AOT 133 ms, JIT 694 ms. RSS au repos : AOT 38,9 Mo, JIT 88 Mo, hôte de dev 99 Mo.
Hot reload non applicable en AOT. CI proposée : publier en AOT, lancer sous Xvfb, scripter les 3 onglets (xdotool), vérifier processus vivant et image changeante.
Micro-bench (JIT / AOT) : update Inc 0,30 / 0,19 µs ; Toggle 1000 éléments 34 / 23 µs ; view 1000 éléments 128 / 109 µs.

## 7. Tests et mutations
Vecteurs FNV-1a publics + différentiel contre une boucle indépendante ; cas limites d'analyse décimale ; marches aléatoires 300×400 messages avec invariant indépendant.
Mutation 1 (constante FNV 16777619→16777618) : passe la vérification F* (aucune preuve ne fixe la constante), 19 596 échecs de tests.
Mutation 2 (borne d'âge 151) : rejetée par F* (`Failed to prove: FStar.UInt32.v n <= 150`) ; sans preuves, 14 échecs de tests.

## 8. UI sous Xvfb
Fenêtre « F* MVU » visible dans `xwininfo`, `_NET_WM_PID` = PID du binaire AOT, contenu non vide, SHA des captures différents après clics.
Formulaire sur le binaire AOT : « Ada Lovelace » + « 36 » → empreinte 4267605246 (confirmée par un calcul FNV-1a indépendant) ; « 200 » → « âge: entier entre 0 et 150 ».
Résultats d'une VM sans GPU : ne valent ni pour le GPU ni pour le mobile.

## 9. Limites
`char` .NET = unité UTF-16 (écart avec `char_code` de F* hors BMP) ; compteur en `bigint` ; transfert de modèle par réflexion (dev seulement, non AOT) ;
non testés : liste de 100 000 lignes, texte de 1 Mo, `Seq`/`Map`/`Set`, Windows/macOS, GPU ; `custard.md` se décrit comme « design sketch » ; projet petit donc coût F* faible.

## 10. Conditions de changement du verdict
Vers « viable » : Hot Reload F# via `dotnet watch`, réalisation de `char_code`. Vers « non viable » : types de modèle changeant à chaque édition, besoin GPU/mobile non couvert ici.

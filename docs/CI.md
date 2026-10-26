# Intégration continue (GitHub Actions) : construire toutes les plateformes

Décision de l'utilisateur (remplace l'ancienne règle « pas de GitHub Actions ») : GitHub Actions sert à **construire** les binaires de chaque plateforme.
Workflow : `.github/workflows/build.yml`.

## Dernier run complet : tout vert (run 40365069048, cibles `all`, 2026-10-26)

| Job | Runner | Durée | Artefact |
|---|---|---|---|
| extract | ubuntu-24.04 | 16 s | `extracted` (9 Ko) |
| linux-x64 | ubuntu-24.04 | 80 s | 15,2 Mo |
| linux-arm64 | ubuntu-24.04-arm | 81 s | 14,5 Mo |
| windows win-x64 | windows-2025 | 131 s | 42,2 Mo |
| windows win-arm64 | windows-11-arm | 178 s | 41,1 Mo |
| macos (arm64 + x64) | macos-15 | 145 s | 40,8 Mo |
| wasm (AOT partiel) | ubuntu-24.04 | 199 s | 20,6 Mo (disque, avec les copies compressées) |
| android (NativeAOT arm64) | ubuntu-24.04 | 163 s | 19,4 Mo |
| ios (simulateur) | macos-26 | 404 s | 70,7 Mo |

Durée de bout en bout : 7 min 6 s. Trois correctifs ont été nécessaires (Xcode 26.0.1, IL stripping iOS, NDK r27 Android : voir « Limites connues »). **Ce que la CI ne prouve pas** : aucun binaire n'est lancé (ni bureau, ni navigateur, ni APK sur appareil, ni app iOS sur simulateur) ; l'efficacité des caches n'a pas été mesurée (l'API des caches n'est pas accessible depuis ce conteneur).

## Sorties : un fichier par plateforme, téléchargeable directement

Chaque job envoie **un seul fichier** avec `actions/upload-artifact@v7` en `archive: false` (pas de zip supplémentaire autour : on télécharge le fichier lui-même, depuis la page du run, onglet *Artifacts*). Vérifiés par le run 40370127417 (tous) et 40370843903 (iOS) :

| Fichier | Contenu | Vérifié par la CI |
|---|---|---|
| `fstar-mvu-linux-x64.tar.gz`, `…-linux-arm64.tar.gz` | exécutable NativeAOT + `libSkiaSharp.so` + `libHarfBuzzSharp.so` | `ldd` (voir limite ci-dessous) |
| `fstar-mvu-win-x64.zip`, `…-win-arm64.zip` | exécutable NativeAOT + DLL natives | publication réussie |
| `fstar-mvu-osx-arm64.app.zip`, `…-osx-x64.app.zip` | bundle **`FStarMVU.app`** (Info.plist, signature ad hoc) | `codesign --verify --deep --strict` : « valid on disk » ; exécutable Mach-O arm64 ; l'app arm64 **reste vivante 8 s au lancement** sur le runner |
| `fstar-mvu-android-arm64.apk` | APK NativeAOT, signé (clé de débogage) | `apksigner verify` (schémas v2 et v3), `aapt2 dump badging` (paquet `net.fstar.mvu`, cible SDK 36, `native-code: arm64-v8a`), `libHostAndroid.so` présente (31,6 Mo), **aucun** Mono ni DLL, `zipalign` 16 Ko OK |
| `fstar-mvu-ios-unsigned.ipa` | `Payload/HostIOS.app`, NativeAOT, arm64, **non signé** | Info.plist (`Avalonia.FStarMVU`, `iphoneos`, iOS ≥ 13.0), exécutable Mach-O 64 bits arm64 |
| `fstar-mvu-wasm.zip` | `wwwroot` WebAssembly (Mono AOT partiel) à servir en HTTP | `dotnet.js` présent |

**Installation.**
- **macOS** : sans certificat « Developer ID », la signature est seulement ad hoc. Après téléchargement, macOS met l'app en quarantaine : clic droit > Ouvrir, ou `xattr -dr com.apple.quarantine FStarMVU.app`. Notarisation = compte Apple, non fait.
- **iOS** : l'`.ipa` est **non signé** (aucun compte Apple dans la CI) : iOS le refuse tel quel. Il faut le re-signer avec un outil de sideloading (AltStore, Sideloadly, TrollStore) ou avec `codesign` + votre certificat et profil de provisionnement. Un `.ipa` directement installable exige ces éléments Apple, à fournir en secrets du dépôt : non fait.
- **Android** : activer l'installation d'applications externes ; l'APK est signé avec la clé de débogage (pas une clé de publication).

**Limite connue, décision en attente : les bibliothèques natives ne sont PAS liées dans l'exécutable.** Bureau : `HostStatic` + `libSkiaSharp` + `libHarfBuzzSharp` (+ `libAvaloniaNative.dylib` sur macOS) à côté (Linux x64 : `HostStatic` 20,7 Mo, `libSkiaSharp.so` 11,2 Mo, `libHarfBuzzSharp.so` 2,8 Mo). Android : les `.so` sont dans l'APK à côté de `libHostAndroid.so`. Les paquets officiels (SkiaSharp 3.119.4, HarfBuzzSharp) ne fournissent pas d'archives statiques pour le bureau. Piste trouvée : le paquet communautaire `Summpot.StaticAvalonia` 3.119.4-avalonia.12.1.4-r1 (même versions que nous ; archives `.a`/`.lib` pour win-x64/arm64, linux-x64/arm64, osx-x64/arm64 ; licence MIT ; ses cibles MSBuild sont lisibles : `DirectPInvoke` + `NativeLibrary`) ; binaires non officiels, 145 Mo, **non testés ici** (la session a refusé de les construire : binaires natifs tiers). `libAvaloniaNative.dylib` (macOS) n'est pas couvert par ce paquet ; Linux garde fontconfig/FreeType/glibc dynamiques (système).

## Déclenchement (pour ne gaspiller aucune minute)

- **Jamais sur un simple push ni une pull request.** Seulement : lancement manuel (*Actions → build → Run workflow*, champ `targets` : `wasm`, `linux`, `windows`, `macos`, `android`, `ios`, une liste séparée par des virgules, ou `all`) et étiquette `v*` (tout).
- Valeur par défaut du lancement manuel : `wasm` seul (le plus rapide) ; Android : toujours NativeAOT (plus d'APK Mono).
- `concurrency` : une exécution plus récente sur la même référence annule la précédente.
- `timeout-minutes` par job (25 à 40) : un build qui part en boucle est coupé.

## Ce qui est construit, et sur quoi

| Cible | Runner | Méthode |
|---|---|---|
| WebAssembly | `ubuntu-24.04` | Mono AOT partiel (`RunAOTCompilation` + `PartialAot`), une seule fois : le résultat ne dépend pas de l'architecture (donc valable pour Linux x86 **et** ARM) |
| Linux x64 | `ubuntu-24.04` | NativeAOT |
| Linux arm64 | `ubuntu-24.04-arm` | NativeAOT sur runner ARM natif (pas de chaîne croisée) |
| Windows x64 | `windows-2025` | NativeAOT (outils C++ de Visual Studio préinstallés) |
| Windows arm64 | `windows-11-arm` | NativeAOT sur runner ARM natif ; image récente, outils C++ ARM64 non vérifiés ici |
| macOS arm64 + x64 | `macos-15` (un seul) | NativeAOT ; le x64 est compilé en croisé **entre architectures du même OS**, permis (seul le croisé entre OS ne l'est pas) |
| Android | `ubuntu-24.04` | **APK NativeAOT arm64 uniquement** (pas de x86/x64 : décision de l'utilisateur) (SDK, NDK et JDK de l'image) |
| iOS | `macos-26` | build pour simulateur (`iossimulator-arm64`) ; un `.ipa` d'appareil exige certificat et profil Apple (secrets à fournir) |

## Économies

- **Le F# extrait n'est plus commité** (`app/Extracted/*` est dans `.gitignore`) : un job `extract` installe F* (`scripts/setup.sh fstar`, version lue dans `scripts/env.sh`), vérifie `Core`, `Big`, `App` puis extrait (`scripts/extract.sh full`, 22 s à froid ici) **une seule fois** ; les autres jobs téléchargent l'artefact `extracted` (3 fichiers, quelques centaines de Ko). Le code est ainsi identique sur toutes les plateformes, et une erreur de preuve F* arrête toute la construction avant le moindre build de plateforme. Les jobs de plateforme n'installent que .NET. F* (≈ 690 Mo installé) et le cache de vérification sont mis en cache.
- **Checkout partiel** : `sparse-checkout: app` (≈ 200 Ko au lieu du dépôt entier), `fetch-depth: 1`.
- **Caches** : paquets NuGet (`~/.nuget/packages`) par cible ; dossier .NET complet **avec ses workloads** (`wasm-tools`, `android`) pour ne pas les retélécharger. Les caches se lisent depuis la branche par défaut : lancer une première fois depuis `main` pour les remplir, avant une étiquette (une étiquette ne remplit pas un cache réutilisable par les suivantes).
- Un seul runner macOS (facturé ×10 hors dépôt public) pour deux architectures ; l'image Android évite le téléchargement du SDK.
- Artefacts : uniquement les binaires, `retention-days: 3`, symboles de débogage supprimés.
- Job iOS et Android lourds : ne les lancer que quand c'est nécessaire (ils ne sont pas dans la valeur par défaut).

## Coût

Le dépôt `rltbg/FF` est **public** : les runners standard de GitHub sont gratuits et sans plafond de minutes pour un dépôt public, y compris `ubuntu-24.04-arm` et macOS ([changelog arm64](https://github.blog/changelog/2025-08-07-arm64-hosted-runners-for-public-repositories-are-now-generally-available/), [runner-images](https://github.com/actions/runner-images)). Si le dépôt devient privé, les minutes sont facturées avec un facteur ≈ ×1 (Linux), ≈ ×2 (Windows), ≈ ×10 (macOS) : voir [la tarification](https://docs.github.com/en/billing/reference/actions-runner-pricing) (chiffres à revérifier à ce moment-là, les sources trouvées divergent).

## Les runners Cloudflare peuvent-ils remplacer GitHub Actions ? Non, pas pour ce projet

Cloudflare n'a pas d'équivalent de runners GitHub Actions. Ce qui existe est **Workers Builds** ([limites et tarifs](https://developers.cloudflare.com/workers/ci-cd/builds/limits-and-pricing/), [cache](https://developers.cloudflare.com/workers/ci-cd/builds/build-caching)) : une CI pour **déployer** des Workers/Pages, branchée sur GitHub ou GitLab. D'après ces pages :

- **builders Linux uniquement**, 2 vCPU, 8 Go de mémoire, 20 Go de disque, **20 minutes maximum** par build, un build à la fois sur l'offre gratuite, 3 000 minutes par mois ;
- donc **ni Windows, ni macOS, ni iOS** (Xcode et les outils C++ de Windows y sont impossibles) ; or NativeAOT ne compile pas d'un OS vers un autre (voir `docs/NATIVEAOT.md` §2) ;
- pas de runner ARM documenté dans ces pages (non vérifié) ; pas de matrice, pas d'artefacts, pas de barrière de pull request au sens de GitHub Actions.

Il pourrait théoriquement construire le seul WebAssembly (≈ 3 min ici, sous les 20 min), mais cela doublerait la configuration (workload `wasm-tools`) pour une cible que GitHub construit gratuitement. **Utilité réelle de Cloudflare ici : héberger le résultat** (Pages ou R2 pour servir le `wwwroot` WebAssembly avec les fichiers `.br`), pas le construire. Non mis en place sans demande.

## Limites connues (à confirmer au premier lancement)

- Le binaire F* Linux x86_64 tourne ici (conteneur) ; sur le runner `ubuntu-24.04`, ses dépendances système (non listées par la release) ne sont pas vérifiées.
- `DOTNET_INSTALL_DIR` (dossier .NET mis en cache) : variable lue par `actions/setup-dotnet` d'après sa documentation ; non vérifiée ici.
- Android, premier run (40361968206) : le SDK de l'image convient (les projets compilent), mais le lien NativeAOT échoue avec `ANDROID_NDK_LATEST_HOME` = NDK 30.0.16248370 : `ld.lld : error : duplicate symbol: __unw_init_local` (20 symboles `__unw_*` et `libunwind::LocalAddressSpace::sThisAddressSpace`, définis à la fois dans `libunwind.a` du NDK et dans `libRuntime.WorkstationGC.a` du paquet `microsoft.netcore.app.runtime.nativeaot.android-arm64` 10.0.14). Correctif : `ANDROID_NDK_HOME` (27.3.13750724, défaut de l'image). **Vérifié** (run 40362696619 : job `android` en succès, APK NativeAOT signés de 19,98 Mo en arm64 et 20,82 Mo en x64 ; le x64 a été retiré ensuite, décision de l'utilisateur). Les APK n'ont jamais été lancés. Hypothèse de départ (à garder) : suppose que l'image `ubuntu-24.04` fournit la plateforme Android et le NDK (r27+) attendus par le workload ; sinon le job échoue (on n'ajoute pas `AcceptAndroidSDKLicenses`, décision de l'utilisateur).
- iOS, deuxième run (40362696619) : le correctif Xcode marche (`Xcode 26.0.1` accepté), puis `ILStrip failed for obj/Release/net10.0-ios/iossimulator-arm64/linked/FSharp.Core.dll: Object reference not set to an instance of an object` (FSharp.Core 10.1.403). Contournement dans `app/HostIOS/HostIOS.fsproj` : `EnableAssemblyILStripping=false` (inévitable ; **vérifié** : run 40363119755, job `ios` en succès, artefact `ios-simulator` produit ; build pour simulateur seulement, jamais lancé). Historique : premier run,  (40361968206) : `error : This version of .NET for iOS (26.0.11017) requires Xcode 26.0. The current version of Xcode is 26.6` (Xcode par défaut de l'image `macos-26-arm64`). Correctif : `xcode-select -s /Applications/Xcode_26.0.1.app` (versions de l'image : 26.0.1 à 26.6, [liste](https://github.com/actions/runner-images/blob/macos-26-arm64/20261013.0424/images/macos/macos-26-arm64-Readme.md)). **Correctif non encore vérifié par un run** ; `HostIOS` (jamais compilé avant) a été restauré sans erreur jusqu'à ce point.
- Aucun de ces binaires n'est lancé par la CI : seule la compilation est vérifiée (pas de test de fumée).

## Versions des actions (relevées le 2026-10-26 sur les pages de versions de chaque action)

`actions/checkout@v7`, `actions/setup-dotnet@v6`, `actions/cache@v6`, `actions/upload-artifact@v7`, `actions/download-artifact@v8` : dernières versions majeures publiées. Les notes de version ne montrent aucune rupture touchant ce workflow (téléchargement d'artefact : décompression automatique des archives zip, erreur en cas de hash différent ; envoi : archive zip par défaut). Les versions sont épinglées par version majeure, pas par SHA : à durcir si la chaîne d'approvisionnement compte. Non exécuté : une rupture non signalée dans ces notes ne serait vue qu'au premier lancement.

## Développement (JIT, local) et construction (NativeAOT, CI) : deux chemins séparés

- **Dev** : `scripts/dev.sh run` (fenêtre en JIT, Debug) ou `scripts/dev.sh watch` (rechargement à chaud à chaque sauvegarde de `fst/*.fst`). Aucune autre plateforme, aucun NativeAOT, aucun runner. Mesuré ici (Xvfb, sans GPU) : un tour de boucle en mode `lax` = 6,9 à 7,9 s ; rechargement dans la fenêtre = 33 ms, état du modèle conservé.
- **Local, avant de conclure** : `scripts/all.sh` (JIT, NativeAOT Linux x64, tests F*, GUI, rechargement à chaud, navigateur). Il ne reconstruit plus les autres plateformes.
- **CI** : le NativeAOT de chaque plateforme (Windows, macOS, Linux arm64, Android, iOS), seulement à la demande (lancement manuel ou étiquette).

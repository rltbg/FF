# Intégration continue (GitHub Actions) : construire toutes les plateformes

Décision de l'utilisateur (remplace l'ancienne règle « pas de GitHub Actions ») : GitHub Actions sert à **construire** les binaires de chaque plateforme.
Workflow : `.github/workflows/build.yml`. **Il n'a jamais été exécuté** (ce conteneur n'a pas accès aux runners) : seule la syntaxe YAML a été vérifiée
(`actionlint` n'a pas pu être téléchargé ici). Le premier lancement réel est le vrai test ; attendre des corrections.

## Déclenchement (pour ne gaspiller aucune minute)

- **Jamais sur un simple push ni une pull request.** Seulement : lancement manuel (*Actions → build → Run workflow*, champ `targets` : `wasm`, `linux`, `windows`, `macos`, `android`, `ios`, une liste séparée par des virgules, ou `all`) et étiquette `v*` (tout).
- Valeur par défaut du lancement manuel : `wasm` seul (le plus rapide) ; l'APK NativeAOT Android est une case à cocher (désactivée).
- `concurrency` : une exécution plus récente sur la même référence annule la précédente.
- `timeout-minutes` par job (25 à 40) : un build qui part en boucle est coupé.

## Ce qui est construit, et sur quoi

| Cible | Runner | Méthode |
|---|---|---|
| WebAssembly | `ubuntu-24.04` | Mono AOT partiel (`RunAOTCompilation` + `PartialAot`), une seule fois : le résultat ne dépend pas de l'architecture (donc valable pour Linux x86 **et** ARM) |
| Linux x64 | `ubuntu-24.04` | NativeAOT |
| Linux arm64 | `ubuntu-24.04-arm` | NativeAOT sur runner ARM natif (pas de chaîne croisée) |
| Windows x64 | `windows-2025` | NativeAOT (outils C++ de Visual Studio préinstallés) |
| macOS arm64 + x64 | `macos-15` (un seul) | NativeAOT ; le x64 est compilé en croisé **entre architectures du même OS**, permis (seul le croisé entre OS ne l'est pas) |
| Android | `ubuntu-24.04` | APK Mono (SDK, NDK et JDK de l'image) ; NativeAOT arm64/x64 en option |
| iOS | `macos-26` | build pour simulateur (`iossimulator-arm64`) ; un `.ipa` d'appareil exige certificat et profil Apple (secrets à fournir) |

## Économies

- **Aucune installation de F\* ni de Custard** : le F# extrait (`app/Extracted`) est commité. Seul .NET est installé.
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

- `DOTNET_INSTALL_DIR` (dossier .NET mis en cache) : variable lue par `actions/setup-dotnet` d'après sa documentation ; non vérifiée ici.
- Android : suppose que l'image `ubuntu-24.04` fournit la plateforme Android et le NDK (r27+) attendus par le workload ; sinon le job échoue (on n'ajoute pas `AcceptAndroidSDKLicenses`, décision de l'utilisateur).
- iOS : `HostIOS` n'a jamais été compilé ; la version d'Xcode requise par le workload n'a pas pu être lue (aucune source trouvée) ; l'image `macos-26` est un choix à valider.
- Aucun de ces binaires n'est lancé par la CI : seule la compilation est vérifiée (pas de test de fumée).

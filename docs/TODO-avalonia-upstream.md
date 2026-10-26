# À explorer / remonter à Avalonia (non fait)

**Statut :** constaté dans notre application, **pas reproduit dans un projet isolé**, **aucun ticket recherché ni déposé**.
Rien n'a été envoyé à Avalonia.

## Le constat
Avalonia 12.1.4, `src/Avalonia.Controls/Presenters/ScrollContentPresenter.cs` :
- `MeasureOverride` appelle `UpdateSnapPoints()` **une seule fois** (drapeau `_isSnapPointsUpdated`).
- `GetScrollSnapPointsInfo` mémorise alors le contenu du moment dans le champ `_scrollSnapPointsInfo` et s'abonne à ses
  événements `VerticalSnapPointsChanged` / `HorizontalSnapPointsChanged`.
- `ChildChanged` ne rafraîchit pas ce champ quand le contenu est remplacé.

Conséquence : le **premier** contenu d'un `ScrollViewer` reste retenu par le presenter après avoir été remplacé
(ainsi que ses enfants et leurs valeurs, par exemple `Tag`). Chez nous, cela retenait les `msg` de l'ancien assembly et
empêchait de décharger le premier `AssemblyLoadContext`.

Le code de la branche principale d'Avalonia (lu le 2026-10-26) contient toujours le drapeau et le même `ChildChanged`.

## Preuves disponibles dans ce dépôt
- `REPORT.md` §5 « Fuite du premier contexte » : chemin racine → bouton obtenu avec ClrMD.
- `tools/dumpscan/` : l'analyseur de dump utilisé.
- `scripts/hotreload.sh` : l'assertion « 0 ancien contexte vivant » échoue sans le contournement de `app/Ui/Runner.fs`
  (`alc-alive 1/4`) et passe avec (`0/4`).

## Contournement en place
`app/Ui/Runner.fs` : un `StackPanel` hôte stable est placé une fois dans le `ScrollViewer` ; seul son enfant change.

## Pour remonter plus tard
1. Chercher un ticket existant (la recherche web du 2026-10-26 n'en a pas trouvé de correspondant ; des tickets voisins sur
   les snap points et le remplacement de contenu existent, non lus).
2. Écrire une reproduction minimale (idée, **non testée**) : fenêtre + `ScrollViewer` en rendu headless, contenu A puis B
   puis C, `WeakReference` sur A, GC répétés : A devrait rester vivant, alors que le contenu B ne l'est plus.
3. Piste de correctif à discuter avec les mainteneurs : réinitialiser `_isSnapPointsUpdated` dans `ChildChanged`, ou se
   désabonner de l'ancien `_scrollSnapPointsInfo` quand l'enfant change.

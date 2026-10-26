namespace Ui

open System
open System.Collections

/// Données volumineuses, côté hôte uniquement (jamais dans le modèle F*). Sans dépendance à Avalonia
/// (compilé aussi par le projet de tests).
module BigData =
  /// Ligne i de la grande liste, calculée à la demande (rien n'est stocké pour les 100 000 lignes).
  let row (i: int) : string = "Ligne " + i.ToString("D6") + " — donnée côté hôte"

  /// Indice d'une ligne de la grande liste, ou -1 si la chaîne n'en est pas une (réciproque de [row]).
  let rowIndex (s: string) : int =
    if not (s.StartsWith("Ligne ", StringComparison.Ordinal)) || s.Length < 12 then -1
    else
      match Int32.TryParse(s.AsSpan(6, 6)) with
      | true, i when i >= 0 && String.Equals(row i, s, StringComparison.Ordinal) -> i
      | _ -> -1

  /// Texte d'environ 1 Mo (1 022 080 octets UTF-8, 832 080 unités UTF-16), déterministe : 38 000 lignes.
  let textLines = 38000
  /// Ligne i du texte, calculée à la demande (le visualiseur n'a besoin que des lignes affichées).
  let line (i: int) : string = "Texte " + i.ToString("D6") + " — éàü " + string (i % 97)

  /// Indice d'une ligne du texte, ou -1 (réciproque de [line]).
  let lineIndex (s: string) : int =
    if not (s.StartsWith("Texte ", StringComparison.Ordinal)) || s.Length < 12 then -1
    else
      match Int32.TryParse(s.AsSpan(6, 6)) with
      | true, i when i >= 0 && i < textLines && String.Equals(line i, s, StringComparison.Ordinal) -> i
      | _ -> -1

  /// Le texte complet n'est construit que si F* doit le hacher.
  let text : Lazy<string> =
    lazy (
      let sb = System.Text.StringBuilder(textLines * 28)
      for i in 0 .. textLines - 1 do sb.Append(line i).Append('\n') |> ignore
      sb.ToString())

/// Lignes générées à la demande : IList non générique en lecture seule que l'ItemsControl d'Avalonia virtualise.
/// Source Avalonia 12.1.4 (ItemsSourceView) : IndexOf/Contains/CopyTo/GetEnumerator sont transmis à cette liste ;
/// IndexOf sert à la sélection PAR OBJET (SelectedItem, SelectedValue, ScrollIntoView(obj), ContainerFromItem),
/// d'où une réciproque exacte de [get].
type LazyRows(count: int, get: int -> string, indexOf: string -> int) =
  let indexOfObj (o: obj) = match o with :? string as s -> (let i = indexOf s in if i < count then i else -1) | _ -> -1
  interface IList with
    member _.Item
      with get (i: int) : obj =
        if i < 0 || i >= count then raise (ArgumentOutOfRangeException "index")
        box (get i)
      and set (_: int) (_: obj) = raise (NotSupportedException())
    member _.Add(_: obj) : int = raise (NotSupportedException())
    member _.Clear() = raise (NotSupportedException())
    member _.Contains(o: obj) = indexOfObj o >= 0
    member _.IndexOf(o: obj) = indexOfObj o
    member _.Insert(_: int, _: obj) = raise (NotSupportedException())
    member _.Remove(_: obj) = raise (NotSupportedException())
    member _.RemoveAt(_: int) = raise (NotSupportedException())
    member _.IsFixedSize = true
    member _.IsReadOnly = true
  interface ICollection with
    member _.Count = count
    member _.IsSynchronized = false
    member _.SyncRoot = box count
    member _.CopyTo(a: Array, index: int) = for i in 0 .. count - 1 do a.SetValue(box (get i), index + i)
  interface IEnumerable with
    member _.GetEnumerator() : IEnumerator = (Seq.init count get :> IEnumerable).GetEnumerator()
  member _.Count = count

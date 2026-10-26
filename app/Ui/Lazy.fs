namespace Ui

open System
open System.Collections

/// Lignes générées à la demande (par F*) : IList non générique en lecture seule que l'ItemsControl d'Avalonia virtualise.
/// Simple plomberie : toute la logique (contenu des lignes, indice réciproque) est dans fst/Big.fst.
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

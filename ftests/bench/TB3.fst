module TB3
(* Banc : construction (comme TB1) puis 5 appels de [view] sur l'onglet Liste (100 008 enfants de colonne, 200 000 nœuds avec leurs lignes). *)
open FStar.All
open App
let rec apply_all (m:model{inv m}) (l:list msg) : Tot (m':model{inv m'}) (decreases l) =
  match l with [] -> m | g :: t -> apply_all (update m g) t
(* nombre d'enfants de la colonne de la liste (longueur itérative côté .NET) : pas de récursion profonde sur 100 000 éléments *)
let nodes (v:view_tree) : nat =
  match v with
  | VColumn [_; VColumn xs] -> FStar.List.Tot.length xs
  | _ -> 0
let rec views (k:nat) (m:model) (acc:nat) : ML nat =
  if k = 0 then acc else views (k - 1) m (acc + nodes (view m))
let main () : ML unit =
  let m = apply_all init (Goto TItems :: preload_msgs (TUtil.blur 100000)) in
  FStar.IO.print_string ("noeuds x5=" ^ string_of_int (views 5 m 0) ^ "\n")

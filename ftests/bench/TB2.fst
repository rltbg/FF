module TB2
(* Banc : construction (comme TB1) puis 20 Toggle de l'élément le plus ancien (parcours complet de la liste de 100 000). *)
open FStar.All
open App
let rec apply_all (m:model{inv m}) (l:list msg) : Tot (m':model{inv m'}) (decreases l) =
  match l with [] -> m | g :: t -> apply_all (update m g) t
let rec toggles (k:nat) (m:model{inv m}) : ML (m':model{inv m'}) =
  if k = 0 then m else toggles (k - 1) (update m (Toggle 0ul))
let main () : ML unit =
  let m = apply_all init (preload_msgs (TUtil.blur 100000)) in
  let m = toggles 20 m in
  FStar.IO.print_string ("items=" ^ string_of_int (FStar.List.Tot.length m.items) ^ "\n")

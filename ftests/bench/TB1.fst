module TB1
(* Banc : 100 000 éléments dans le MODÈLE F* (200 000 messages Typed + AddItem). Phase 1 : construction seule. *)
open FStar.All
open App
let rec apply_all (m:model{inv m}) (l:list msg) : Tot (m':model{inv m'}) (decreases l) =
  match l with [] -> m | g :: t -> apply_all (update m g) t
let main () : ML unit =
  let m = apply_all init (preload_msgs (TUtil.blur 100000)) in
  FStar.IO.print_string ("items=" ^ string_of_int (FStar.List.Tot.length m.items) ^ "\n")

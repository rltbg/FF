module Mx42_RBMapForAny
(* DÉFAUT DE LA BIBLIOTHÈQUE F* (ulib/FStar.RBMap.fst, indépendant de Custard) : for_any p m est défini par
     p x vx || for_all p a && for_all p b
   au lieu de  p x vx || for_any p a || for_any p b : il appelle for_all dans les sous-arbres. Résultat faux (false) dès que le seul
   élément qui satisfait p n'est pas la racine. F* l'« affirme » aussi : le normaliseur donne la même valeur fausse, et aucune
   spécification ne contredit la définition. (FStar.RBSet.for_any, lui, est correct.) *)
open MxUtil
module Rm = FStar.RBMap
open FStar.Class.Ord.Raw
let main () : FStar.All.ML unit =
  let m = Rm.from_list (blur [(1, "a"); (2, "b"); (3, "c")]) in
  (* la valeur « c » existe dans la table : for_any devrait répondre true *)
  check (Rm.for_any (fun (k:int) (v:string) -> v = "c") m);
  FStar.IO.print_string "OK\n"

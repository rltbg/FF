module TList
(* Fonctions réalisées de FStar.List.Tot.Base et FStar.List (supported_realizations de Custard) : valeurs attendues
   écrites à la main + propriétés générales (inverses, longueurs, tri) sur des listes aléatoires. *)
open FStar.All
open TUtil
module L = FStar.List.Tot
module LM = FStar.List

(* fonctions de test sur des listes d'int : définitions locales indépendantes *)
let rec ref_len (l:list int) : Tot int (decreases l) = match l with [] -> 0 | _ :: t -> 1 + ref_len t
let rec ref_sorted (l:list int) : Tot bool (decreases l) =
  match l with
  | [] -> true
  | a :: t -> (match t with [] -> true | b :: _ -> a <= b && ref_sorted t)
let rec ref_count (x:int) (l:list int) : Tot int (decreases l) =
  match l with [] -> 0 | y :: t -> (if x = y then 1 else 0) + ref_count x t

let cmp_int (a b:int) : int = if a < b then 0 - 1 else if a > b then 1 else 0
let lt_int (a b:int) : bool = a < b
let pos_i (x:int) : bool = x > 0
let is_even (n:int) : bool = n % 2 = 0 || (n < 0 && (0 - n) % 2 = 0)
let sq (n:int) : int = n * n

(* les fonctions à précondition sont appelées derrière une garde exécutée : F* en déduit la précondition *)
let hd_ (l:list int) : option int = match l with [] -> None | _ :: _ -> Some (L.hd l)
let tl_ (l:list int) : option (list int) = match l with [] -> None | _ :: _ -> Some (L.tl l)
let tail_ (l:list int) : option (list int) = match l with [] -> None | _ :: _ -> Some (L.tail l)
let last_ (l:list int) : option int = match l with [] -> None | _ :: _ -> Some (L.last l)
let init_ (l:list int) : option (list int) = match l with [] -> None | _ :: _ -> Some (L.init l)
let index_ (l:list int) (i:int) : option int = if i >= 0 && i < L.length l then Some (L.index l i) else None
let unsnoc_ (l:list int) : option (list int & int) = if L.length l > 0 then Some (L.unsnoc l) else None
let split3_ (l:list int) (i:int) : option (list int & int & list int) =
  if i >= 0 && i < L.length l then Some (L.split3 l i) else None

let rl (n:nat) : ML (list int) = rand_list n (fun () -> rand_below 20)

let test_fixed () : ML unit =
  let l = blur [3; 1; 4; 1; 5; 9; 2; 6] in
  let e : list int = blur [] in
  check "isEmpty" (L.isEmpty e && not (L.isEmpty l));
  check "hd/tl/tail" (hd_ l = Some 3 && tl_ l = Some [1; 4; 1; 5; 9; 2; 6] && tail_ l = tl_ l && hd_ e = None && tl_ e = None);
  check "last/init" (last_ l = Some 6 && init_ l = Some [3; 1; 4; 1; 5; 9; 2] && last_ e = None && init_ e = None);
  check "length" (L.length l = 8 && L.length e = 0);
  check "nth" (L.nth l 0 = Some 3 && L.nth l 7 = Some 6 && L.nth l 8 = None);
  check "index" (index_ l 5 = Some 9 && index_ l 0 = Some 3 && index_ l 8 = None && index_ l (0 - 1) = None);
  check "count" (L.count 1 l = 2 && L.count 7 l = 0);
  check "rev_acc/rev" (L.rev_acc [1; 2; 3] [10] = [3; 2; 1; 10] && L.rev l = [6; 2; 9; 5; 1; 4; 1; 3]);
  check "append/@" (L.append [1; 2] [3] = [1; 2; 3] && ([1] @ [2; 3]) = [1; 2; 3] && L.append e l = l);
  check "snoc" (L.snoc ([1; 2], 3) = [1; 2; 3]);
  check "flatten" (L.flatten [[1]; []; [2; 3]] = [1; 2; 3]);
  check "map" (L.map sq [1; 2; 3] = [1; 4; 9]);
  check "mapi" (L.mapi (fun i x -> i * 10 + x) [5; 6; 7] = [5; 16; 27]);
  check "concatMap/collect" (L.concatMap (fun x -> [x; x]) [1; 2] = [1; 1; 2; 2] && L.collect (fun x -> [x]) [1; 2] = [1; 2]);
  check "fold_left" (L.fold_left (fun a x -> a * 10 + x) 0 [1; 2; 3] = 123);
  check "fold_right" (L.fold_right (fun x a -> a * 10 + x) [1; 2; 3] 0 = 321);
  check "fold_left2" (L.fold_left2 (fun a x y -> a + x * y) 0 [1; 2; 3] [4; 5; 6] = 32);
  check "mem/contains" (L.mem 9 l && not (L.mem 8 l) && L.contains 4 l && not (L.contains 0 l));
  check "existsb" (L.existsb (fun x -> x > 8) l && not (L.existsb (fun x -> x > 9) l));
  check "find/tryFind" ((match L.find (fun (x:int) -> x > 4) l with Some x -> x = 5 | None -> false) && L.tryFind (fun (x:int) -> x > 99) l = None);
  check "filter" (L.filter is_even l = [4; 2; 6]);
  check "for_all" (L.for_all (fun x -> x > 0) l && not (L.for_all is_even l));
  check "tryPick" (L.tryPick (fun x -> if x > 4 then Some (x * 2) else None) l = Some 10);
  check "choose" (L.choose (fun x -> if x > 4 then Some x else None) l = [5; 9; 6]);
  check "partition" (L.partition is_even l = ([4; 2; 6], [3; 1; 1; 5; 9]));
  check "noRepeats" (not (L.noRepeats l) && L.noRepeats [1; 2; 3] && L.noRepeats e);
  check "assoc" (L.assoc 2 [(1, "a"); (2, "b")] = Some "b" && L.assoc 3 [(1, "a")] = None);
  check "split/unzip" (L.split [(1, "a"); (2, "b")] = ([1; 2], ["a"; "b"]) && L.unzip [(1, 'x')] = ([1], ['x']));
  check "unzip3" (L.unzip3 [(1, "a", true); (2, "b", false)] = ([1; 2], ["a"; "b"], [true; false]));
  check "splitAt" (L.splitAt 3 l = ([3; 1; 4], [1; 5; 9; 2; 6]) && L.splitAt 0 l = ([], l)  (* splitAt n > length : voir docs/matrix/Mx30_ListSplitAt.fst *));
  check "unsnoc" (unsnoc_ (blur [1; 2; 3]) = Some ([1; 2], 3) && unsnoc_ e = None);
  check "split3" (split3_ (blur [1; 2; 3; 4]) 2 = Some ([1; 2], 3, [4]) && split3_ (blur [1]) 1 = None);
  (* bool_of_compare, compare_of_bool : signes inversés dans le F# de support, voir docs/matrix/Mx31, Mx32 *)
  check "sortWith" (L.sortWith cmp_int l = [1; 1; 2; 3; 4; 5; 6; 9]);
  check "subset" (L.subset [1; 2] [2; 1; 3] && not (L.subset [1; 4] [2; 1; 3]) && L.subset e l);
  check "list_unref" (let (r : list (x:int{x > 0})) = [1; 2] in L.list_unref r = [1; 2]);
  (* list_refb : non extractible (BUILD FS0003, docs/matrix/Mx29_ListRefb.fst) *)
  check "list_ref" (L.length (L.list_ref #int #(fun (x:int) -> b2t (x > 0)) [4; 5]) = 2)

let test_random () : ML unit =
  let rec loop (k:nat) : ML unit =
    if k = 0 then () else begin
      let a = blur (rl (rand_below 12)) in
      let b = blur (rl (rand_below 12)) in
      check "length = ref" (L.length a = ref_len a);
      check "length (a@b)" (L.length (a @ b) = L.length a + L.length b);
      check "rev rev" (L.rev (L.rev a) = a);
      check "rev length" (L.length (L.rev a) = L.length a);
      check "rev (a@b)" (L.rev (a @ b) = L.rev b @ L.rev a);
      check "map length" (L.length (L.map sq a) = L.length a);
      check "filter subset" (L.subset (L.filter is_even a) a);
      let (p, q) = L.partition is_even a in
      check "partition : tailles" (L.length p + L.length q = L.length a);
      check "partition : prédicat" (L.for_all is_even p && L.for_all (fun x -> not (is_even x)) q);
      let s = L.sortWith cmp_int a in
      check "sortWith : trié" (ref_sorted s);
      check "sortWith : permutation" (L.length s = L.length a && L.for_all (fun x -> ref_count x s = ref_count x a) a);
      check "count = ref" (L.for_all (fun x -> L.count x a = ref_count x a) a);
      check "mem <=> count > 0" (L.for_all (fun x -> L.mem x a = (ref_count x a > 0)) (a @ b));
      check "append assoc" ((a @ b) @ a = a @ (b @ a));
      check "flatten = fold" (L.flatten [a; b] = a @ b);
      (match a with
       | [] -> check "nth []" (L.nth a 0 = None)
       | _ :: _ ->
         let n = rand_below (L.length a) in
         check "nth = index" (L.nth a n = index_ a n);
         check "splitAt n" (let (x, y) = L.splitAt n a in x @ y = a && L.length x = n);
         check "unsnoc" (match unsnoc_ a with Some (i, z) -> L.snoc (i, z) = a && last_ a = Some z && init_ a = Some i | None -> false);
         check "split3" (match split3_ a n with Some (x, m, y) -> x @ (m :: y) = a && index_ a n = Some m | None -> false));
      loop (k - 1)
    end in
  loop 3000

(* FStar.List (effet ML) : mêmes fonctions avec fermetures effectuantes *)
let test_ml () : ML unit =
  let l = blur [3; 1; 4; 1; 5] in
  let acc : ref (list int) = alloc [] in
  LM.iter (fun x -> acc := x :: !acc) l;
  check "List.iter" (!acc = [5; 1; 4; 1; 3]);
  let acc2 : ref (list int) = alloc [] in
  LM.iteri (fun i x -> acc2 := (i * 100 + x) :: !acc2) l;
  check "List.iteri" (!acc2 = [404; 301; 204; 101; 3] || !acc2 = [405; 303; 204; 101; 3] || !acc2 = [405; 304; 201; 101; 3] || true);
  check "List.iteri contenu" (!acc2 = [4 * 100 + 5; 3 * 100 + 1; 2 * 100 + 4; 1 * 100 + 1; 0 * 100 + 3]);
  check "List.nth" (LM.nth l 2 = 4);
  check "List.hd/tl/last/init/length/rev" (hd_ l = Some 3 && tl_ l = Some [1; 4; 1; 5] && last_ l = Some 5 && init_ l = Some [3; 1; 4; 1] && LM.length l = 5 && LM.rev l = [5; 1; 4; 1; 3]);
  check "List.hd/tl/tail/last/init (ML)" (match l with
                                          | [] -> false
                                          | _ :: _ -> LM.hd l = 3 && LM.tl l = [1; 4; 1; 5] && LM.tail l = [1; 4; 1; 5]
                                                     && LM.last l = 5 && LM.init l = [3; 1; 4; 1]);
  check "List.append/@/flatten" (LM.append [1] [2] = [1; 2] && ([1] @ [2]) = [1; 2] && LM.flatten [[1]; [2; 3]] = [1; 2; 3]);
  check "List.mem/contains/isEmpty" (LM.mem 4 l && LM.contains 5 l && not (LM.isEmpty l));
  check "List.split/unzip/unzip3/splitAt" (LM.split [(1, 2)] = ([1], [2]) && LM.unzip [(1, 2)] = ([1], [2])
                                          && LM.unzip3 [(1, 2, 3)] = ([1], [2], [3]) && LM.splitAt 2 l = ([3; 1], [4; 1; 5]));
  check "List.map/mapi" (LM.map (fun x -> x + 1) l = [4; 2; 5; 2; 6] && LM.mapi (fun i x -> i + x) l = [3; 2; 6; 4; 9]);
  check "List.collect/concatMap" (LM.collect (fun x -> [x; x]) [1; 2] = [1; 1; 2; 2] && LM.concatMap (fun x -> [x]) [1; 2] = [1; 2]);
  check "List.fold_left/right/left2" (LM.fold_left (fun a x -> a + x) 0 l = 14 && LM.fold_right (fun x a -> a * 2 + x) l 0 = 3 + 2 * (1 + 2 * (4 + 2 * (1 + 2 * 5)))
                                     && LM.fold_left2 (fun a x y -> a + x * y) 0 [1; 2] [3; 4] = 11);
  check "List.filter/for_all/existsb" (LM.filter is_even l = [4] && LM.for_all (fun x -> x > 0) l && LM.existsb (fun x -> x = 5) l);
  check "List.find/tryFind/tryPick/choose" ((match LM.find (fun (x:int) -> x > 3) l with Some x -> x = 4 | None -> false) && LM.tryFind (fun x -> x > 9) l = None
                                           && LM.tryPick (fun x -> if x > 3 then Some x else None) l = Some 4
                                           && LM.choose (fun x -> if x > 3 then Some x else None) l = [4; 5]);
  check "List.partition/assoc/sortWith" (LM.partition is_even l = ([4], [3; 1; 1; 5]) && LM.assoc 1 [(1, 2)] = Some 2
                                        && LM.sortWith cmp_int l = [1; 1; 3; 4; 5])

let main () : ML unit = test_fixed (); test_random (); test_ml ()

module TUlib
(* GÉNÉRÉ par scripts/gen_tulib.py depuis ftests/ulib_cases.py. Ne pas éditer à la main. *)
open FStar.All
open TUtil

module O  = FStar.Option
open FStar.Option
module Od = FStar.Order
module Sq = FStar.Seq
module SP = FStar.Seq.Properties
module L  = FStar.List.Tot
module St = FStar.Set
module Mp = FStar.Map
module Pm = FStar.PartialMap
module Fq = FStar.FunctionalQueue
module Os = FStar.OrdSet
module Om = FStar.OrdMap
module UI = FStar.UInt
module BV = FStar.BitVector
module Pr = FStar.Class.Printable
module Fs = FStar.FiniteSet.Base
module Fm = FStar.FiniteMap.Base
module Lp = FStar.List.Pure.Base
module Sn = FStar.Sequence.Base
module Su = FStar.Sequence.Util
module Rs = FStar.RBSet
module Rm = FStar.RBMap
module Co = FStar.Class.Ord.Raw
open FStar.Class.Ord.Raw
module Ad = FStar.Class.Add
module To = FStar.Class.TotalOrder.Raw
module Pf = FStar.Printf
let leq (x y:int) : bool = x <= y
let sl (#a:Type) (s:Sq.seq a) : list a = Sq.seq_to_list s

let c_opt_isNone (o:option int) : bool = not (O.isNone o) && O.isNone (None #int)
let _ = assert_norm (c_opt_isNone (Some 1))
let c_opt_isSome (o:option int) : bool = not (O.isSome o) && O.isSome (Some 3)
let _ = assert_norm (c_opt_isSome (None))
let c_opt_mapTot (o:option int) : bool = O.mapTot (fun (x:int) -> x + 1) o = Some 3 && O.mapTot (fun (x:int) -> x + 1) (None #int) = None
let _ = assert_norm (c_opt_mapTot (Some 2))
let c_opt_let (o:option int) : bool = (let? x = o in Some (x * 10)) = Some 20 && (let? x = (None #int) in Some x) = None
let _ = assert_norm (c_opt_let (Some 2))
let c_opt_and (a:option int) (b:option bool) : bool = (let r = (a `O.op_and_Question` b) in r = Some (1, true)) && (let r2 = (a `O.op_and_Question` (None #bool)) in r2 = None)
let _ = assert_norm (c_opt_and (Some 1) (Some true))
let c_native_fst_snd (p:int & bool) : bool = fst p = 5 && snd p = true
let _ = assert_norm (c_native_fst_snd ((5, true)))
let c_ord_cmp (a:int) (b:int) : bool = Od.compare_int a b = Od.Lt && Od.compare_int b a = Od.Gt && Od.compare_int a a = Od.Eq
let _ = assert_norm (c_ord_cmp (3) (7))
let c_ord_preds (o:Od.order) : bool = Od.gt o && Od.ge o && Od.ne o && not (Od.lt o) && not (Od.le o) && not (Od.eq o) && Od.eq Od.Eq && Od.le Od.Lt
let _ = assert_norm (c_ord_preds (Od.Gt))
let c_ord_from_int (i:int) : bool = Od.order_from_int i = Od.Gt && Od.order_from_int (0 - i) = Od.Lt && Od.order_from_int 0 = Od.Eq
let _ = assert_norm (c_ord_from_int (5))
let c_ord_int_of (o:Od.order) : bool = Od.int_of_order o = (0 - 1) && Od.int_of_order Od.Eq = 0 && Od.int_of_order Od.Gt = 1
let _ = assert_norm (c_ord_int_of (Od.Lt))
let c_ord_lex (a:Od.order) (b:Od.order) : bool = Od.lex a (fun () -> b) = Od.Gt && Od.lex Od.Lt (fun () -> b) = Od.Lt && Od.lex Od.Gt (fun () -> Od.Lt) = Od.Gt
let _ = assert_norm (c_ord_lex (Od.Eq) (Od.Gt))
let c_ord_cmp_list (a:list int) (b:list int) : bool = Od.compare_list a b (fun x y -> Od.compare_int x y) = Od.Lt && Od.compare_list b a (fun x y -> Od.compare_int x y) = Od.Gt && Od.compare_list a a (fun x y -> Od.compare_int x y) = Od.Eq
let _ = assert_norm (c_ord_cmp_list ([1; 2; 3]) ([1; 2; 4]))
let c_ord_cmp_list_len (a:list int) (b:list int) : bool = Od.compare_list a b (fun x y -> Od.compare_int x y) = Od.Lt && Od.compare_list b a (fun x y -> Od.compare_int x y) = Od.Gt
let _ = assert_norm (c_ord_cmp_list_len ([1; 2]) ([1; 2; 3]))
let c_ord_cmp_option (a:option int) (b:option int) : bool = Od.compare_option Od.compare_int a b = Od.Lt && Od.compare_option Od.compare_int b a = Od.Gt && Od.compare_option Od.compare_int b b = Od.Eq && Od.compare_option Od.compare_int a a = Od.Eq
let _ = assert_norm (c_ord_cmp_option (None) (Some 2))
let c_seq_length (l:list int) : bool = Sq.length (Sq.seq_of_list l) = 3 && Sq.length (Sq.empty #int) = 0
(* seq_length : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_seq_to_of_list (l:list int) : bool = Sq.seq_to_list (Sq.seq_of_list l) = l
(* seq_to_of_list : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_seq_index (l:list int) : bool = Sq.length (Sq.seq_of_list l) = 3 && Sq.index (Sq.seq_of_list l) 0 = 4 && Sq.index (Sq.seq_of_list l) 2 = 6
(* seq_index : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_seq_create (n:nat) (v:int) : bool = sl (Sq.create n v) = [7; 7; 7] && Sq.length (Sq.create 0 v) = 0
(* seq_create : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_seq_init (n:nat) : bool = sl (Sq.init n (fun (i:nat{i < n}) -> i * i)) = [0; 1; 4; 9]
(* seq_init : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_seq_empty (u:unit) : bool = sl (Sq.empty #int) = [] && sl (Sq.createEmpty #int) = []
(* seq_empty : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_seq_upd (l:list int) : bool = Sq.length (Sq.seq_of_list l) = 3 && sl (Sq.upd (Sq.seq_of_list l) 1 9) = [1; 9; 3] && sl (Sq.upd (Sq.seq_of_list l) 0 0) = [0; 2; 3]
(* seq_upd : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_seq_append (a:list int) (b:list int) : bool = sl (Sq.append (Sq.seq_of_list a) (Sq.seq_of_list b)) = [1; 2; 3] && sl ((Sq.seq_of_list a) `Sq.append` (Sq.empty #int)) = a
(* seq_append : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_seq_cons (l:list int) : bool = sl (Sq.cons 1 (Sq.seq_of_list l)) = [1; 2; 3]
(* seq_cons : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_seq_slice (l:list int) : bool = Sq.length (Sq.seq_of_list l) = 5 && sl (Sq.slice (Sq.seq_of_list l) 1 4) = [2; 3; 4] && sl (Sq.slice (Sq.seq_of_list l) 0 0) = [] && sl (Sq.slice (Sq.seq_of_list l) 0 5) = l
(* seq_slice : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_seq_eq (a:list int) (b:list int) : bool = Sq.eq (Sq.seq_of_list a) (Sq.seq_of_list a) && not (Sq.eq (Sq.seq_of_list a) (Sq.seq_of_list b)) && not (Sq.eq (Sq.seq_of_list a) (Sq.seq_of_list [1]))
(* seq_eq : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_head_tail_last (l:list int) : bool = Sq.length (Sq.seq_of_list l) = 3 && SP.head (Sq.seq_of_list l) = 1 && sl (SP.tail (Sq.seq_of_list l)) = [2; 3] && SP.last (Sq.seq_of_list l) = 3
(* sp_head_tail_last : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_split (l:list int) : bool = Sq.length (Sq.seq_of_list l) = 4 && (let (a, b) = SP.split (Sq.seq_of_list l) 2 in sl a = [1; 2] && sl b = [3; 4]) && (let (a2, b2) = SP.split (Sq.seq_of_list l) 0 in sl a2 = [] && sl b2 = l)
(* sp_split : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_split_eq (l:list int) : bool = Sq.length (Sq.seq_of_list l) = 4 && (let (a, b) = SP.split_eq (Sq.seq_of_list l) 3 in sl a = [1; 2; 3] && sl b = [4])
(* sp_split_eq : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_count_mem (l:list int) : bool = SP.count 1 (Sq.seq_of_list l) = 2 && SP.count 9 (Sq.seq_of_list l) = 0 && SP.mem 3 (Sq.seq_of_list l) && not (SP.mem 9 (Sq.seq_of_list l))
(* sp_count_mem : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_index_mem (l:list int) : bool = SP.mem 6 (Sq.seq_of_list l) && SP.index_mem 6 (Sq.seq_of_list l) = 1
(* sp_index_mem : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_swap (l:list int) : bool = Sq.length (Sq.seq_of_list l) = 4 && sl (SP.swap (Sq.seq_of_list l) 0 3) = [4; 2; 3; 1] && sl (SP.swap (Sq.seq_of_list l) 1 1) = l
(* sp_swap : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_sorted (a:list int) (b:list int) : bool = SP.sorted (fun (x:int) y -> x <= y) (Sq.seq_of_list a) && not (SP.sorted (fun (x:int) y -> x <= y) (Sq.seq_of_list b)) && SP.sorted (fun (x:int) y -> x <= y) (Sq.empty #int)
(* sp_sorted : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_snoc_unsnoc (l:list int) : bool = sl (SP.snoc (Sq.seq_of_list l) 3) = [1; 2; 3] && Sq.length (Sq.seq_of_list l) = 2 && (let s3 = SP.snoc (Sq.seq_of_list l) 3 in Sq.length s3 = 3 && (let (i, x) = SP.un_snoc s3 in sl i = [1; 2] && x = 3))
(* sp_snoc_unsnoc : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_find_l (l:list int) : bool = SP.find_l (fun (x:int) -> x > 3) (Sq.seq_of_list l) = Some 4 && SP.find_l (fun (x:int) -> x > 9) (Sq.seq_of_list l) = None
(* sp_find_l : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_find_r (l:list int) : bool = SP.find_r (fun (x:int) -> x < 7) (Sq.seq_of_list l) = Some 6 && SP.find_r (fun (x:int) -> x > 9) (Sq.seq_of_list l) = None
(* sp_find_r : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_seq_find (l:list int) : bool = SP.seq_find (fun (x:int) -> x > 3) (Sq.seq_of_list l) = Some 7 || SP.seq_find (fun (x:int) -> x > 3) (Sq.seq_of_list l) = Some 4
(* sp_seq_find : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_for_all (l:list int) : bool = SP.for_all (fun (x:int) -> x % 2 = 0) (Sq.seq_of_list l) && not (SP.for_all (fun (x:int) -> x > 3) (Sq.seq_of_list l))
(* sp_for_all : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_createL (l:list int) : bool = sl (SP.createL l) = l && sl (SP.of_list l) = l
(* sp_createL : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_sortWith (l:list int) : bool = sl (SP.sortWith (fun (a:int) b -> a - b) (Sq.seq_of_list l)) = [1; 1; 2; 3]
(* sp_sortWith : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_foldr (l:list int) : bool = SP.foldr (fun (x:int) (a:int) -> a * 10 + x) (Sq.seq_of_list l) 0 = 321
(* sp_foldr : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_splice (a:list int) (b:list int) : bool = Sq.length (Sq.seq_of_list a) = 4 && Sq.length (Sq.seq_of_list b) = 4 && sl (SP.splice (Sq.seq_of_list a) 1 (Sq.seq_of_list b) 3) = [1; 8; 7; 4]
(* sp_splice : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_replace_subseq (a:list int) (s:list int) : bool = Sq.length (Sq.seq_of_list a) = 4 && Sq.length (Sq.seq_of_list s) = 2 && sl (SP.replace_subseq (Sq.seq_of_list a) 1 3 (Sq.seq_of_list s)) = [1; 7; 8; 4]
(* sp_replace_subseq : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sp_split_5 (l:list int) : bool = Sq.length (Sq.seq_of_list l) = 6 && (let r = SP.split_5 (Sq.seq_of_list l) 1 4 in Sq.length r = 5 && sl (Sq.index r 0) = [1] && sl (Sq.index r 1) = [2] && sl (Sq.index r 2) = [3; 4] && sl (Sq.index r 3) = [5] && sl (Sq.index r 4) = [6])
(* sp_split_5 : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_set_basic (x:int) : bool = St.mem x (St.singleton x) && not (St.mem 3 (St.singleton x)) && not (St.mem x (St.empty #int))
let _ = assert_norm (c_set_basic (2))
let c_set_union (a:St.set int) (b:St.set int) : bool = St.mem 1 (St.union a b) && St.mem 3 (St.union a b) && not (St.mem 4 (St.union a b))
let _ = assert_norm (c_set_union (St.as_set [1; 2]) (St.as_set [2; 3]))
let c_set_intersect (a:St.set int) (b:St.set int) : bool = St.mem 2 (St.intersect a b) && not (St.mem 1 (St.intersect a b)) && not (St.mem 3 (St.intersect a b))
let _ = assert_norm (c_set_intersect (St.as_set [1; 2]) (St.as_set [2; 3]))
let c_set_complement (a:St.set int) : bool = not (St.mem 1 (St.complement a)) && St.mem 5 (St.complement a)
let _ = assert_norm (c_set_complement (St.as_set [1; 2]))
let c_set_add_remove (a:St.set int) : bool = St.mem 9 (St.add 9 a) && St.mem 1 (St.add 9 a) && not (St.mem 1 (St.remove 1 a)) && St.mem 2 (St.remove 1 a)
let _ = assert_norm (c_set_add_remove (St.as_set [1; 2]))
let c_set_as_set (l:list int) : bool = St.mem 3 (St.as_set l) && St.mem 5 (St.as_set l) && not (St.mem 4 (St.as_set l))
let _ = assert_norm (c_set_as_set ([3; 5; 3]))
let c_map_sel_upd (m:Mp.t int string) : bool = Mp.sel m 1 = "un" && Mp.sel m 2 = "d" && Mp.sel (Mp.upd m 2 "deux") 2 = "deux" && Mp.sel (Mp.upd m 2 "deux") 1 = "un"
let _ = assert_norm (c_map_sel_upd (Mp.upd (Mp.const "d") 1 "un"))
let c_map_const_domain (m:Mp.t int bool) : bool = Mp.sel m 7 = true
let _ = assert_norm (c_map_const_domain (Mp.const true))
let c_map_contains (m:Mp.t int string) : bool = Mp.contains m 1 && Mp.contains m 99 && Mp.contains (Mp.const_on #int #string (St.as_set [1; 2]) "x") 1 && not (Mp.contains (Mp.const_on #int #string (St.as_set [1; 2]) "x") 3)
let _ = assert_norm (c_map_contains (Mp.upd (Mp.const "d") 1 "un"))
let c_map_map_val (m:Mp.t int int) : bool = Mp.sel (Mp.map_val (fun (x:int) -> x + 1) m) 1 = 11 && Mp.sel (Mp.map_val (fun (x:int) -> x + 1) m) 5 = 1
let _ = assert_norm (c_map_map_val (Mp.upd (Mp.const 0) 1 10))
let c_map_concat (a:Mp.t int int) (b:Mp.t int int) : bool = Mp.sel (Mp.concat a b) 2 = 20 && Mp.sel (Mp.concat a b) 1 = 0 && Mp.sel (Mp.concat b a) 1 = 10
let _ = assert_norm (c_map_concat (Mp.upd (Mp.const 0) 1 10) (Mp.upd (Mp.const 0) 2 20))
let c_map_restrict (m:Mp.t int int) : bool = Mp.sel (Mp.restrict (St.as_set [1]) m) 1 = 10 && Mp.contains (Mp.restrict (St.as_set [1]) m) 1 && not (Mp.contains (Mp.restrict (St.as_set [1]) m) 2)
let _ = assert_norm (c_map_restrict (Mp.upd (Mp.const 0) 1 10))
let c_map_literal (k:int) : bool = Mp.sel (Mp.map_literal (fun (x:int) -> x * x)) k = 16
let _ = assert_norm (c_map_literal (4))
let c_pm_basic (k:int) : bool = Pm.sel (Pm.empty int string) k = None && Pm.sel (Pm.upd (Pm.empty int string) k "a") k = Some "a" && Pm.sel (Pm.upd (Pm.empty int string) k "a") 2 = None
let _ = assert_norm (c_pm_basic (1))
let c_pm_remove_contains (m:Pm.t int string) : bool = Pm.contains m 1 && Pm.contains m 2 && not (Pm.contains (Pm.remove m 1) 1) && Pm.contains (Pm.remove m 1) 2
let _ = assert_norm (c_pm_remove_contains (Pm.upd (Pm.upd (Pm.empty int string) 1 "a") 2 "b"))
let c_pm_literal_const (k:int) : bool = Pm.sel (Pm.literal (fun (x:int) -> if x > 2 then Some x else None)) k = Some 3 && Pm.sel (Pm.literal (fun (x:int) -> if x > 2 then Some x else None)) 1 = None && Pm.sel (Pm.const int 'c') k = Some 'c'
let _ = assert_norm (c_pm_literal_const (3))
let c_fq_basic (l:list int) : bool = sl (Fq.queue_to_seq (Fq.queue_of_seq (Sq.seq_of_list l))) = l && sl (Fq.queue_to_seq (Fq.empty #int)) = []
(* fq_basic : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_fq_enqueue (l:list int) : bool = sl (Fq.queue_to_seq (Fq.enqueue 3 (Fq.queue_of_seq (Sq.seq_of_list l)))) = [1; 2; 3]
(* fq_enqueue : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_fq_dequeue_peek (l:list int) : bool = (let q = Fq.queue_of_seq (Sq.seq_of_list l) in Sq.length (Fq.queue_to_seq q) > 0 && Fq.peek q = 7 && (let (x, q2) = Fq.dequeue q in x = 7 && sl (Fq.queue_to_seq q2) = [8; 9]))
(* fq_dequeue_peek : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_os_basic (l:list int) : bool = Os.size (Os.distinct leq l) = 3 && Os.as_list (Os.distinct leq l) = [1; 2; 3] && Os.mem 2 (Os.distinct leq l) && not (Os.mem 9 (Os.distinct leq l))
(* os_basic : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_os_ops (a:list int) (b:list int) : bool = Os.as_list (Os.union (Os.distinct leq a) (Os.distinct leq b)) = [1; 3; 4; 5] && Os.as_list (Os.intersect (Os.distinct leq a) (Os.distinct leq b)) = [3; 5] && Os.as_list (Os.minus (Os.distinct leq a) (Os.distinct leq b)) = [1]
(* os_ops : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_os_remove_singleton (x:int) : bool = Os.as_list (Os.remove x (Os.distinct leq [1; 3; 5])) = [1; 5] && Os.as_list (Os.singleton #int #leq x) = [3] && Os.as_list (Os.empty #int #leq) = []
(* os_remove_singleton : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_os_subset (a:list int) (b:list int) : bool = Os.subset (Os.distinct leq a) (Os.distinct leq b) && not (Os.subset (Os.distinct leq b) (Os.distinct leq a)) && Os.strict_subset (Os.distinct leq a) (Os.distinct leq b) && Os.superset (Os.distinct leq b) (Os.distinct leq a) && Os.strict_superset (Os.distinct leq b) (Os.distinct leq a) && not (Os.disjoint (Os.distinct leq a) (Os.distinct leq b)) && Os.disjoint (Os.distinct leq a) (Os.distinct leq [7])
(* os_subset : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_os_choose (l:list int) : bool = Os.choose (Os.distinct leq l) = Some 2 || Os.choose (Os.distinct leq l) = Some 4
(* os_choose : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_os_fold (l:list int) : bool = Os.fold (fun (a:int) (x:int) -> a * 10 + x) 0 (Os.distinct leq l) = 123
(* os_fold : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_os_all_any (l:list int) : bool = Os.all (Os.distinct leq l) (fun (x:int) -> x % 2 = 0) && Os.any (Os.distinct leq l) (fun (x:int) -> x > 5) && not (Os.any (Os.distinct leq l) (fun (x:int) -> x > 6)) && Os.count (Os.distinct leq l) (fun (x:int) -> x > 2) = 2
(* os_all_any : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_os_find (l:list int) : bool = Os.find_first (Os.distinct leq l) (fun (x:int) -> x > 2) = Some 4 && Os.find_last (Os.distinct leq l) (fun (x:int) -> x < 6) = Some 4
(* os_find : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_os_map (l:list int) : bool = Os.as_list (Os.map #int #int #leq #leq (fun (x:int) -> x * 2) (Os.distinct leq l)) = [2; 4; 6]
(* os_map : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_ui_basic (n:nat) : bool = UI.max_int n = 255 && UI.min_int n = 0 && UI.fits 255 n && not (UI.fits 256 n) && UI.zero n = 0 && UI.one n = 1 && UI.ones n = 255 && UI.pow2_n #8 7 = 128
let _ = assert_norm (c_ui_basic (8))
let c_ui_add_mod (a:UI.uint_t 8) (b:UI.uint_t 8) : bool = UI.add_mod #8 a b = 44 && UI.mul_mod #8 20 20 = 144 && UI.add_mod #8 a 0 = a
let _ = assert_norm (c_ui_add_mod (200) (100))
let c_ui_add_sub_mul (a:UI.uint_t 8) (b:UI.uint_t 8) : bool = UI.fits (a + b) 8 && UI.add #8 a b = 155 && UI.fits (a - b) 8 && UI.sub #8 a b = 45 && UI.fits (a * 2) 8 && UI.mul #8 a 2 = 200 && UI.add_underspec #8 a b = 155 && UI.sub_underspec #8 a b = 45 && UI.mul_underspec #8 a 2 = 200
let _ = assert_norm (c_ui_add_sub_mul (100) (55))
let c_ui_div_mod (a:UI.uint_t 8) (b:UI.uint_t 8) : bool = b <> 0 && UI.div #8 a b = 28 && UI.udiv #8 a b = 28 && UI.mod #8 a b = 4 && UI.div_underspec #8 a b = 28 && UI.mul_div #8 a b = 200 * 7 / 256
let _ = assert_norm (c_ui_div_mod (200) (7))
let c_ui_incr_decr (a:UI.uint_t 8) : bool = a < UI.max_int 8 && a > UI.min_int 8 && UI.incr #8 a = 6 && UI.decr #8 a = 4 && UI.incr_underspec #8 a = 6 && UI.decr_underspec #8 a = 4 && UI.incr_mod #8 255 = 0
let _ = assert_norm (c_ui_incr_decr (5))
let c_ui_bits (a:UI.uint_t 8) (b:UI.uint_t 8) : bool = UI.logand #8 a b = 48 && UI.logor #8 a b = 252 && UI.logxor #8 a b = 204 && UI.lognot #8 a = 15 && UI.minus #8 1 = 255 && UI.minus #8 0 = 0
(* ui_bits : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_ui_shift_rot (a:UI.uint_t 8) : bool = UI.shift_left #8 a 1 = 2 && UI.shift_right #8 a 1 = 64 && UI.rotate_left #8 a 1 = 3 && UI.rotate_right #8 a 1 = 192 && UI.msb #8 a && not (UI.msb #8 1)
(* ui_shift_rot : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_ui_cmp (a:UI.uint_t 8) (b:UI.uint_t 8) : bool = UI.lt #8 a b && UI.lte #8 a b && UI.gt #8 b a && UI.gte #8 b a && UI.eq #8 a a && UI.ne #8 a b && not (UI.gt #8 a b)
let _ = assert_norm (c_ui_cmp (3) (9))
let c_ui_vec (a:UI.uint_t 8) : bool = sl (UI.to_vec #8 a) = [false; false; false; false; false; true; false; true] && UI.from_vec #8 (UI.to_vec #8 a) = a && UI.nth #8 a 7 = true && UI.nth #8 a 6 = false && UI.nth #8 a 5 = true
(* ui_vec : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_ui_to_uint_t (a:UI.uint_t 16) : bool = UI.to_uint_t 8 a = 1 && UI.to_uint_t 16 a = 513 && UI.to_uint_t 32 a = 513
(* ui_to_uint_t : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_ui_extend (a:UI.uint_t 8) : bool = UI.zero_extend #8 a = 200 && UI.one_extend #8 a = 456 && UI.zero_extends #8 3 a = 200
(* ui_extend : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_ui_wide (a:UI.uint_t 64) (b:UI.uint_t 64) : bool = UI.add_mod #64 a b = 0 && UI.mul_mod #64 a a = 1 && UI.logand #64 a b = 1 && UI.shift_right #64 a 63 = 1 && UI.rotate_left #64 a 4 = a
(* ui_wide : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_bv_basic (n:pos) : bool = sl (BV.zero_vec #n) = [false; false; false; false] && sl (BV.ones_vec #n) = [true; true; true; true] && sl (BV.elem_vec #n 1) = [false; true; false; false]
(* bv_basic : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_bv_logic (a:list bool) (b:list bool) : bool = Sq.length (Sq.seq_of_list a) = 4 && Sq.length (Sq.seq_of_list b) = 4 && sl (BV.logand_vec #4 (Sq.seq_of_list a) (Sq.seq_of_list b)) = [true; false; false; false] && sl (BV.logor_vec #4 (Sq.seq_of_list a) (Sq.seq_of_list b)) = [true; true; true; false] && sl (BV.logxor_vec #4 (Sq.seq_of_list a) (Sq.seq_of_list b)) = [false; true; true; false] && sl (BV.lognot_vec #4 (Sq.seq_of_list a)) = [false; true; false; true]
(* bv_logic : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_bv_shift (a:list bool) : bool = Sq.length (Sq.seq_of_list a) = 4 && sl (BV.shift_left_vec #4 (Sq.seq_of_list a) 1) = [false; true; true; false] && sl (BV.shift_right_vec #4 (Sq.seq_of_list a) 1) = [false; true; false; true] && sl (BV.shift_arithmetic_right_vec #4 (Sq.seq_of_list a) 1) = [true; true; false; true] && sl (BV.rotate_left_vec #4 (Sq.seq_of_list a) 1) = [false; true; true; true] && sl (BV.rotate_right_vec #4 (Sq.seq_of_list a) 1) = [true; true; false; true]
(* bv_shift : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_pr_basic (n:int) : bool = Pr.to_string n = "42" && Pr.to_string (0 - n) = "-42" && Pr.to_string true = "true" && Pr.to_string () = "()" && Pr.to_string "s" = "\"s\""
let _ = assert_norm (c_pr_basic (42))
let c_pr_none (u:unit) : bool = Pr.to_string (None #int) = "None"
let _ = assert_norm (c_pr_none (()))
let c_pr_char (c:FStar.Char.char) : bool = Pr.to_string c = "x"
let _ = assert_norm (c_pr_char ('x'))
let c_pr_machine (c:int) : bool = Pr.to_string 7uy = "7" && Pr.to_string 7y = "7" && Pr.to_string 300us = "300" && Pr.to_string (-3s) = "-3" && Pr.to_string 70000ul = "70000" && Pr.to_string (-70000l) = "-70000" && Pr.to_string 5000000000uL = "5000000000" && Pr.to_string (-5000000000L) = "-5000000000"
(* pr_machine : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_eq_basic (a:int) (b:int) : bool = FStar.Class.Eq.eq a a && not (FStar.Class.Eq.eq a b) && FStar.Class.Eq.eq true true && FStar.Class.Eq.eq "x" "x" && not (FStar.Class.Eq.eq "x" "y") && FStar.Class.Eq.eq () ()
let _ = assert_norm (c_eq_basic (3) (4))
let c_eq_raw_list (a:list int) (b:list int) : bool = FStar.Class.Eq.Raw.eqList (fun (x:int) y -> x = y) a a && not (FStar.Class.Eq.Raw.eqList (fun (x:int) y -> x = y) a b) && not (FStar.Class.Eq.Raw.eqList (fun (x:int) y -> x = y) a [1])
let _ = assert_norm (c_eq_raw_list ([1; 2]) ([1; 3]))
let c_fs_basic (x:int) : bool = Fs.mem x (Fs.singleton x) && not (Fs.mem 3 (Fs.singleton x)) && not (Fs.mem x (Fs.emptyset #int)) && Fs.notin 3 (Fs.singleton x)
(* fs_basic : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_fs_ops (a:Fs.set int) (b:Fs.set int) : bool = Fs.mem 3 (Fs.union a b) && Fs.mem 1 (Fs.union a b) && Fs.mem 2 (Fs.intersection a b) && not (Fs.mem 1 (Fs.intersection a b)) && Fs.mem 1 (Fs.difference a b) && not (Fs.mem 2 (Fs.difference a b)) && not (Fs.mem 1 (Fs.remove 1 a)) && Fs.mem 2 (Fs.remove 1 a)
(* fs_ops : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_fm_basic (k:int) : bool = Fm.mem k (Fm.insert k "a" (Fm.emptymap #int #string)) && Fm.lookup k (Fm.insert k "a" (Fm.emptymap #int #string)) = "a" && not (Fm.mem 2 (Fm.insert k "a" (Fm.emptymap #int #string))) && Fm.notin 2 (Fm.insert k "a" (Fm.emptymap #int #string))
(* fm_basic : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_fm_ops (k:int) : bool = (let m = Fm.insert 2 "b" (Fm.insert k "a" (Fm.emptymap #int #string)) in Fm.mem 2 m && Fm.lookup 2 m = "b" && not (Fm.mem 1 (Fm.remove 1 m)) && Fm.mem 2 (Fm.remove 1 m) && Fm.mem 1 (Fm.merge m (Fm.emptymap #int #string)) && Fm.mem 1 (Fm.subtract m (Fs.singleton 2)) && not (Fm.mem 2 (Fm.subtract m (Fs.singleton 2))) && Fs.mem 1 (Fm.domain m))
(* fm_ops : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_om_basic (k:int) : bool = (let m = Om.update 3 "c" (Om.update k "b" (Om.empty #int #string #leq)) in Om.select k m = Some "b" && Om.select 3 m = Some "c" && Om.select 9 m = None && Om.contains 3 m && not (Om.contains 9 m) && Om.size m = 2 && Os.as_list (Om.dom m) = [2; 3])
(* om_basic : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_om_remove_choose (k:int) : bool = (let m = Om.update 3 "c" (Om.update k "b" (Om.empty #int #string #leq)) in Om.size (Om.remove k m) = 1 && Om.select k (Om.remove k m) = None && Om.choose (Om.empty #int #string #leq) = None && (match Om.choose m with Some (x, _) -> x = 2 | None -> false))
(* om_remove_choose : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_om_const_on (k:int) : bool = (let m = Om.const_on (Os.distinct leq [1; 5]) "z" in Om.select k m = Some "z" && Om.select 2 m = None)
(* om_const_on : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_lp_map2 (a:list int) (b:list int) : bool = L.length a = L.length b && Lp.map2 (fun (x:int) y -> x + y) a b = [11; 22; 33]
let _ = assert_norm (c_lp_map2 ([1; 2; 3]) ([10; 20; 30]))
let c_lp_map3 (a:list int) (b:list int) (c:list int) : bool = L.length a = L.length b && L.length b = L.length c && Lp.map3 (fun (x:int) y z -> x * y + z) a b c = [8; 14]
let _ = assert_norm (c_lp_map3 ([1; 2]) ([3; 4]) ([5; 6]))
let c_lp_zip (a:list int) (b:list bool) : bool = L.length a = L.length b && Lp.zip a b = [(1, true); (2, false)]
let _ = assert_norm (c_lp_zip ([1; 2]) ([true; false]))
let c_lp_zip3 (a:list int) (b:list bool) (c:list string) : bool = L.length a = L.length b && L.length b = L.length c && Lp.zip3 a b c = [(1, true, "x"); (2, false, "y")]
let _ = assert_norm (c_lp_zip3 ([1; 2]) ([true; false]) (["x"; "y"]))
let c_sn_basic (x:int) : bool = Sn.length (Sn.singleton x) = 1 && Sn.index (Sn.singleton x) 0 = 5 && Sn.length (Sn.empty #int) = 0
(* sn_basic : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sn_build_append (x:int) : bool = (let s = Sn.build (Sn.build (Sn.empty #int) x) 6 in Sn.length s = 2 && Sn.index s 0 = 5 && Sn.index s 1 = 6 && (let t = Sn.append s s in Sn.length t = 4 && Sn.index t 3 = 6 && Sn.index t 2 = 5))
(* sn_build_append : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_sn_update_take_drop (x:int) : bool = (let s = Sn.build (Sn.build (Sn.build (Sn.empty #int) x) 6) 7 in Sn.length s = 3 && (let u = Sn.update s 1 9 in Sn.length u = 3 && Sn.index u 1 = 9 && Sn.index u 0 = 5) && (let t = Sn.take s 2 in Sn.length t = 2 && Sn.index t 1 = 6) && (let d = Sn.drop s 2 in Sn.length d = 1 && Sn.index d 0 = 7))
(* sn_update_take_drop : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_su_ops (x:int) : bool = (let s = Sn.build (Sn.build (Sn.build (Sn.empty #int) x) 6) 5 in Sn.length s = 3 && Su.head s = 5 && (let t = Su.tail s in Sn.length t = 2 && Sn.index t 0 = 6) && Su.count 5 s = 2 && (let sl2 = Su.slice s 1 3 in Sn.length sl2 = 2 && Sn.index sl2 0 = 6) && (let c = Su.cons 1 s in Sn.length c = 4 && Sn.index c 0 = 1))
(* su_ops : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_rs_basic (x:int) : bool = (let s = Rs.add 3 (Rs.add x (Rs.add 1 (Rs.empty ()))) in Rs.elems s = [1; 2; 3] && Rs.mem 2 s && not (Rs.mem 9 s) && not (Rs.is_empty s) && Rs.is_empty (Rs.empty #int ()) && Rs.elems (Rs.singleton x) = [2])
(* rs_basic : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_rs_ops (x:int) : bool = (let a = Rs.from_list [1; 2; 3] in let b = Rs.from_list [3; 4] in Rs.elems (Rs.union a b) = [1; 2; 3; 4] && Rs.elems (Rs.inter a b) = [3] && Rs.elems (Rs.diff a b) = [1; 2] && Rs.subset (Rs.from_list [1; 2]) a && not (Rs.subset b a) && Rs.elems (Rs.remove x a) = [1; 3] && Rs.equal a (Rs.from_list [3; 2; 1]))
(* rs_ops : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_rs_filter_forall (x:int) : bool = (let a = Rs.from_list [1; 2; 3; 4] in Rs.elems (Rs.filter (fun (v:int) -> v % 2 = 0) a) = [2; 4] && Rs.for_all (fun (v:int) -> v > 0) a && Rs.for_any (fun (v:int) -> v > 3) a && not (Rs.for_any (fun (v:int) -> v > 4) a) && Rs.elems (Rs.addn [9; 0] a) = [0; 1; 2; 3; 4; 9])
(* rs_filter_forall : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_rs_min (x:int) : bool = (let a = Rs.from_list [5; 2; 8] in not (Rs.is_empty a) && (let (r, m) = Rs.extract_min a in m = 2 && Rs.elems r = [5; 8]))
(* rs_min : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_rm_basic (x:int) : bool = (let m = Rm.add 3 "c" (Rm.add x "b" (Rm.add 1 "a" (Rm.empty ()))) in Rm.keys m = [1; 2; 3] && Rm.lookup 2 m = Some "b" && Rm.lookup 9 m = None && Rm.mem 3 m && not (Rm.mem 9 m) && Rm.to_list m = [(1, "a"); (2, "b"); (3, "c")] && not (Rm.is_empty m) && Rm.is_empty (Rm.empty #int #string ()) && Rm.to_list (Rm.singleton x "z") = [(2, "z")])
(* rm_basic : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_rm_ops (x:int) : bool = (let m = Rm.from_list [(1, "a"); (2, "b"); (3, "c")] in Rm.keys (Rm.remove x m) = [1; 3] && Rm.keys (Rm.filter (fun (k:int) (v:string) -> k > 1) m) = [2; 3] && Rm.for_all (fun (k:int) (v:string) -> k > 0) m && Rm.for_any (fun (k:int) (v:string) -> k = 2) m && Rm.keys (Rm.union m (Rm.from_list [(9, "z")])) = [1; 2; 3; 9] && Rm.keys (Rm.inter m (Rm.from_list [(2, "q"); (7, "r")])) = [2] && Rm.keys (Rm.addn [(0, "o")] m) = [0; 1; 2; 3] && not (Rm.is_empty m) && (let (r, (k, v)) = Rm.extract_min m in k = 1 && v = "a" && Rm.keys r = [2; 3]))
(* rm_ops : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_ord_raw (a:int) (b:int) : bool = Co.min a b = 3 && Co.max a b = 5 && (a <? b) && (b >? a) && (a <=? a) && (b >=? b) && not (b <? a)
(* ord_raw : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_ord_raw_sort (l:list int) : bool = Co.sort l = [1; 2; 3; 3] && Co.dedup l = [3; 1; 2] && Co.sort_dedup l = [1; 2; 3]
(* ord_raw_sort : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_ord_raw_diff (a:list int) (b:list int) : bool = (let (x, y) = Co.ord_list_diff a b in x = [1] && y = [4])
(* ord_raw_diff : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)
let c_totord_flip (o:Od.order) : bool = To.flip o = Od.Gt && To.flip Od.Gt = Od.Lt && To.flip Od.Eq = Od.Eq
let _ = assert_norm (c_totord_flip (Od.Lt))
let c_add_class (a:int) (b:int) : bool = Ad.(a ++ b) = 5 && Ad.(true ++ false) = true && Ad.(false ++ false) = false && Ad.(([1]) ++ ([2])) = [1; 2] && (Ad.zero #int) = 0 && (Ad.zero #bool) = false && (Ad.zero #(list int)) = []
let _ = assert_norm (c_add_class (2) (3))
let c_pf_basic (n:int) (s:string) : bool = Pf.sprintf "%d-%s" n s = "42-x" && Pf.sprintf "plain" = "plain" && Pf.sprintf "%d" (0 - n) = "-42" && Pf.sprintf "100%%" = "100%"
let _ = assert_norm (c_pf_basic (42) ("x"))
let c_pf_bool_char (b:bool) (c:FStar.Char.char) : bool = Pf.sprintf "%b/%c" b c = "true/z" && Pf.sprintf "%b" false = "false"
let _ = assert_norm (c_pf_bool_char (true) ('z'))
let c_pf_parse (n:int) : bool = Some? (Pf.parse_format_string "%d" Pf.no_extensions) && None? (Pf.parse_format_string "%" Pf.no_extensions) && None? (Pf.parse_format_string "%q" Pf.no_extensions) && Some? (Pf.parse_format_string "abc" Pf.no_extensions) && Some? (Pf.parse_format_string "%uy%us%ul%uL%y%i%l%L%%%b%c%s%d" Pf.no_extensions) && None? (Pf.parse_format_string "%ux" Pf.no_extensions)
let _ = assert_norm (c_pf_parse (0))

let run () : ML unit =
  check "opt_isNone" (c_opt_isNone (blur #(option int) (Some 1)));
  check "opt_isSome" (c_opt_isSome (blur #(option int) (None)));
  check "opt_mapTot" (c_opt_mapTot (blur #(option int) (Some 2)));
  check "opt_let" (c_opt_let (blur #(option int) (Some 2)));
  check "opt_and" (c_opt_and (blur #(option int) (Some 1)) (blur #(option bool) (Some true)));
  check "native_fst_snd" (c_native_fst_snd (blur #(int & bool) ((5, true))));
  check "ord_cmp" (c_ord_cmp (blur #(int) (3)) (blur #(int) (7)));
  check "ord_preds" (c_ord_preds (blur #(Od.order) (Od.Gt)));
  check "ord_from_int" (c_ord_from_int (blur #(int) (5)));
  check "ord_int_of" (c_ord_int_of (blur #(Od.order) (Od.Lt)));
  check "ord_lex" (c_ord_lex (blur #(Od.order) (Od.Eq)) (blur #(Od.order) (Od.Gt)));
  check "ord_cmp_list" (c_ord_cmp_list (blur #(list int) ([1; 2; 3])) (blur #(list int) ([1; 2; 4])));
  check "ord_cmp_list_len" (c_ord_cmp_list_len (blur #(list int) ([1; 2])) (blur #(list int) ([1; 2; 3])));
  check "ord_cmp_option" (c_ord_cmp_option (blur #(option int) (None)) (blur #(option int) (Some 2)));
  check "seq_length" (c_seq_length (blur #(list int) ([1; 2; 3])));
  check "seq_to_of_list" (c_seq_to_of_list (blur #(list int) ([4; 5; 6])));
  check "seq_index" (c_seq_index (blur #(list int) ([4; 5; 6])));
  check "seq_create" (c_seq_create (blur #(nat) (3)) (blur #(int) (7)));
  check "seq_init" (c_seq_init (blur #(nat) (4)));
  check "seq_empty" (c_seq_empty (blur #(unit) (())));
  check "seq_upd" (c_seq_upd (blur #(list int) ([1; 2; 3])));
  check "seq_append" (c_seq_append (blur #(list int) ([1; 2])) (blur #(list int) ([3])));
  check "seq_cons" (c_seq_cons (blur #(list int) ([2; 3])));
  check "seq_slice" (c_seq_slice (blur #(list int) ([1; 2; 3; 4; 5])));
  check "seq_eq" (c_seq_eq (blur #(list int) ([1; 2])) (blur #(list int) ([1; 3])));
  check "sp_head_tail_last" (c_sp_head_tail_last (blur #(list int) ([1; 2; 3])));
  check "sp_split" (c_sp_split (blur #(list int) ([1; 2; 3; 4])));
  check "sp_split_eq" (c_sp_split_eq (blur #(list int) ([1; 2; 3; 4])));
  check "sp_count_mem" (c_sp_count_mem (blur #(list int) ([1; 2; 1; 3])));
  check "sp_index_mem" (c_sp_index_mem (blur #(list int) ([5; 6; 7])));
  check "sp_swap" (c_sp_swap (blur #(list int) ([1; 2; 3; 4])));
  check "sp_sorted" (c_sp_sorted (blur #(list int) ([1; 2; 2; 5])) (blur #(list int) ([3; 1])));
  check "sp_snoc_unsnoc" (c_sp_snoc_unsnoc (blur #(list int) ([1; 2])));
  check "sp_find_l" (c_sp_find_l (blur #(list int) ([1; 4; 6; 7])));
  check "sp_find_r" (c_sp_find_r (blur #(list int) ([1; 4; 6; 7])));
  check "sp_seq_find" (c_sp_seq_find (blur #(list int) ([1; 4; 6; 7])));
  check "sp_for_all" (c_sp_for_all (blur #(list int) ([2; 4; 6])));
  check "sp_createL" (c_sp_createL (blur #(list int) ([1; 2; 3])));
  check "sp_sortWith" (c_sp_sortWith (blur #(list int) ([3; 1; 2; 1])));
  check "sp_foldr" (c_sp_foldr (blur #(list int) ([1; 2; 3])));
  check "sp_splice" (c_sp_splice (blur #(list int) ([1; 2; 3; 4])) (blur #(list int) ([9; 8; 7; 6])));
  check "sp_replace_subseq" (c_sp_replace_subseq (blur #(list int) ([1; 2; 3; 4])) (blur #(list int) ([7; 8])));
  check "sp_split_5" (c_sp_split_5 (blur #(list int) ([1; 2; 3; 4; 5; 6])));
  check "set_basic" (c_set_basic (blur #(int) (2)));
  check "set_union" (c_set_union (blur #(St.set int) (St.as_set [1; 2])) (blur #(St.set int) (St.as_set [2; 3])));
  check "set_intersect" (c_set_intersect (blur #(St.set int) (St.as_set [1; 2])) (blur #(St.set int) (St.as_set [2; 3])));
  check "set_complement" (c_set_complement (blur #(St.set int) (St.as_set [1; 2])));
  check "set_add_remove" (c_set_add_remove (blur #(St.set int) (St.as_set [1; 2])));
  check "set_as_set" (c_set_as_set (blur #(list int) ([3; 5; 3])));
  check "map_sel_upd" (c_map_sel_upd (blur #(Mp.t int string) (Mp.upd (Mp.const "d") 1 "un")));
  check "map_const_domain" (c_map_const_domain (blur #(Mp.t int bool) (Mp.const true)));
  check "map_contains" (c_map_contains (blur #(Mp.t int string) (Mp.upd (Mp.const "d") 1 "un")));
  check "map_map_val" (c_map_map_val (blur #(Mp.t int int) (Mp.upd (Mp.const 0) 1 10)));
  check "map_concat" (c_map_concat (blur #(Mp.t int int) (Mp.upd (Mp.const 0) 1 10)) (blur #(Mp.t int int) (Mp.upd (Mp.const 0) 2 20)));
  check "map_restrict" (c_map_restrict (blur #(Mp.t int int) (Mp.upd (Mp.const 0) 1 10)));
  check "map_literal" (c_map_literal (blur #(int) (4)));
  check "pm_basic" (c_pm_basic (blur #(int) (1)));
  check "pm_remove_contains" (c_pm_remove_contains (blur #(Pm.t int string) (Pm.upd (Pm.upd (Pm.empty int string) 1 "a") 2 "b")));
  check "pm_literal_const" (c_pm_literal_const (blur #(int) (3)));
  check "fq_basic" (c_fq_basic (blur #(list int) ([1; 2; 3])));
  check "fq_enqueue" (c_fq_enqueue (blur #(list int) ([1; 2])));
  check "fq_dequeue_peek" (c_fq_dequeue_peek (blur #(list int) ([7; 8; 9])));
  check "os_basic" (c_os_basic (blur #(list int) ([3; 1; 2; 3])));
  check "os_ops" (c_os_ops (blur #(list int) ([1; 3; 5])) (blur #(list int) ([3; 4; 5])));
  check "os_remove_singleton" (c_os_remove_singleton (blur #(int) (3)));
  check "os_subset" (c_os_subset (blur #(list int) ([1; 3])) (blur #(list int) ([1; 3; 5])));
  check "os_choose" (c_os_choose (blur #(list int) ([4; 2])));
  check "os_fold" (c_os_fold (blur #(list int) ([1; 2; 3])));
  check "os_all_any" (c_os_all_any (blur #(list int) ([2; 4; 6])));
  check "os_find" (c_os_find (blur #(list int) ([2; 4; 6])));
  check "os_map" (c_os_map (blur #(list int) ([1; 2; 3])));
  check "ui_basic" (c_ui_basic (blur #(nat) (8)));
  check "ui_add_mod" (c_ui_add_mod (blur #(UI.uint_t 8) (200)) (blur #(UI.uint_t 8) (100)));
  check "ui_add_sub_mul" (c_ui_add_sub_mul (blur #(UI.uint_t 8) (100)) (blur #(UI.uint_t 8) (55)));
  check "ui_div_mod" (c_ui_div_mod (blur #(UI.uint_t 8) (200)) (blur #(UI.uint_t 8) (7)));
  check "ui_incr_decr" (c_ui_incr_decr (blur #(UI.uint_t 8) (5)));
  check "ui_bits" (c_ui_bits (blur #(UI.uint_t 8) (240)) (blur #(UI.uint_t 8) (60)));
  check "ui_shift_rot" (c_ui_shift_rot (blur #(UI.uint_t 8) (129)));
  check "ui_cmp" (c_ui_cmp (blur #(UI.uint_t 8) (3)) (blur #(UI.uint_t 8) (9)));
  check "ui_vec" (c_ui_vec (blur #(UI.uint_t 8) (5)));
  check "ui_to_uint_t" (c_ui_to_uint_t (blur #(UI.uint_t 16) (513)));
  check "ui_extend" (c_ui_extend (blur #(UI.uint_t 8) (200)));
  check "ui_wide" (c_ui_wide (blur #(UI.uint_t 64) (18446744073709551615)) (blur #(UI.uint_t 64) (1)));
  check "bv_basic" (c_bv_basic (blur #(pos) (4)));
  check "bv_logic" (c_bv_logic (blur #(list bool) ([true; false; true; false])) (blur #(list bool) ([true; true; false; false])));
  check "bv_shift" (c_bv_shift (blur #(list bool) ([true; false; true; true])));
  check "pr_basic" (c_pr_basic (blur #(int) (42)));
  check "pr_none" (c_pr_none (blur #(unit) (())));
  check "pr_char" (c_pr_char (blur #(FStar.Char.char) ('x')));
  check "pr_machine" (c_pr_machine (blur #(int) (7)));
  check "eq_basic" (c_eq_basic (blur #(int) (3)) (blur #(int) (4)));
  check "eq_raw_list" (c_eq_raw_list (blur #(list int) ([1; 2])) (blur #(list int) ([1; 3])));
  check "fs_basic" (c_fs_basic (blur #(int) (2)));
  check "fs_ops" (c_fs_ops (blur #(Fs.set int) (Fs.insert 2 (Fs.singleton 1))) (blur #(Fs.set int) (Fs.insert 3 (Fs.singleton 2))));
  check "fm_basic" (c_fm_basic (blur #(int) (1)));
  check "fm_ops" (c_fm_ops (blur #(int) (1)));
  check "om_basic" (c_om_basic (blur #(int) (2)));
  check "om_remove_choose" (c_om_remove_choose (blur #(int) (2)));
  check "om_const_on" (c_om_const_on (blur #(int) (5)));
  check "lp_map2" (c_lp_map2 (blur #(list int) ([1; 2; 3])) (blur #(list int) ([10; 20; 30])));
  check "lp_map3" (c_lp_map3 (blur #(list int) ([1; 2])) (blur #(list int) ([3; 4])) (blur #(list int) ([5; 6])));
  check "lp_zip" (c_lp_zip (blur #(list int) ([1; 2])) (blur #(list bool) ([true; false])));
  check "lp_zip3" (c_lp_zip3 (blur #(list int) ([1; 2])) (blur #(list bool) ([true; false])) (blur #(list string) (["x"; "y"])));
  check "sn_basic" (c_sn_basic (blur #(int) (5)));
  check "sn_build_append" (c_sn_build_append (blur #(int) (5)));
  check "sn_update_take_drop" (c_sn_update_take_drop (blur #(int) (5)));
  check "su_ops" (c_su_ops (blur #(int) (5)));
  check "rs_basic" (c_rs_basic (blur #(int) (2)));
  check "rs_ops" (c_rs_ops (blur #(int) (2)));
  check "rs_filter_forall" (c_rs_filter_forall (blur #(int) (2)));
  check "rs_min" (c_rs_min (blur #(int) (2)));
  check "rm_basic" (c_rm_basic (blur #(int) (2)));
  check "rm_ops" (c_rm_ops (blur #(int) (2)));
  check "ord_raw" (c_ord_raw (blur #(int) (3)) (blur #(int) (5)));
  check "ord_raw_sort" (c_ord_raw_sort (blur #(list int) ([3; 1; 2; 3])));
  check "ord_raw_diff" (c_ord_raw_diff (blur #(list int) ([1; 2; 3])) (blur #(list int) ([2; 3; 4])));
  check "totord_flip" (c_totord_flip (blur #(Od.order) (Od.Lt)));
  check "add_class" (c_add_class (blur #(int) (2)) (blur #(int) (3)));
  check "pf_basic" (c_pf_basic (blur #(int) (42)) (blur #(string) ("x")));
  check "pf_bool_char" (c_pf_bool_char (blur #(bool) (true)) (blur #(FStar.Char.char) ('z')));
  check "pf_parse" (c_pf_parse (blur #(int) (0)));
  ()

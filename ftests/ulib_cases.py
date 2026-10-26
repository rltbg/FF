# Cas « double oracle » pour les modules d'ulib compilés depuis leur définition F* (voir scripts/gen_tulib.py).
# Format : (identifiant, [(paramètre, type, valeur littérale)], corps booléen).
PRELUDE = '''
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
'''
I = "int"
CASES = [
  # ---- FStar.Option, FStar.Pervasives.Native
  ("opt_isNone", [("o", "option int", "Some 1")], "not (O.isNone o) && O.isNone (None #int)"),
  ("opt_isSome", [("o", "option int", "None")], "not (O.isSome o) && O.isSome (Some 3)"),
  ("opt_mapTot", [("o", "option int", "Some 2")], "O.mapTot (fun (x:int) -> x + 1) o = Some 3 && O.mapTot (fun (x:int) -> x + 1) (None #int) = None"),
  ("opt_let", [("o", "option int", "Some 2")], "(let? x = o in Some (x * 10)) = Some 20 && (let? x = (None #int) in Some x) = None"),
  ("opt_and", [("a", "option int", "Some 1"), ("b", "option bool", "Some true")], "(let r = (a `O.op_and_Question` b) in r = Some (1, true)) && (let r2 = (a `O.op_and_Question` (None #bool)) in r2 = None)"),
  ("native_fst_snd", [("p", "int & bool", "(5, true)")], "fst p = 5 && snd p = true"),
  # ---- FStar.Order
  ("ord_cmp", [("a", I, "3"), ("b", I, "7")], "Od.compare_int a b = Od.Lt && Od.compare_int b a = Od.Gt && Od.compare_int a a = Od.Eq"),
  ("ord_preds", [("o", "Od.order", "Od.Gt")], "Od.gt o && Od.ge o && Od.ne o && not (Od.lt o) && not (Od.le o) && not (Od.eq o) && Od.eq Od.Eq && Od.le Od.Lt"),
  ("ord_from_int", [("i", I, "5")], "Od.order_from_int i = Od.Gt && Od.order_from_int (0 - i) = Od.Lt && Od.order_from_int 0 = Od.Eq"),
  ("ord_int_of", [("o", "Od.order", "Od.Lt")], "Od.int_of_order o = (0 - 1) && Od.int_of_order Od.Eq = 0 && Od.int_of_order Od.Gt = 1"),
  ("ord_lex", [("a", "Od.order", "Od.Eq"), ("b", "Od.order", "Od.Gt")], "Od.lex a (fun () -> b) = Od.Gt && Od.lex Od.Lt (fun () -> b) = Od.Lt && Od.lex Od.Gt (fun () -> Od.Lt) = Od.Gt"),
  ("ord_cmp_list", [("a", "list int", "[1; 2; 3]"), ("b", "list int", "[1; 2; 4]")], "Od.compare_list a b (fun x y -> Od.compare_int x y) = Od.Lt && Od.compare_list b a (fun x y -> Od.compare_int x y) = Od.Gt && Od.compare_list a a (fun x y -> Od.compare_int x y) = Od.Eq"),
  ("ord_cmp_list_len", [("a", "list int", "[1; 2]"), ("b", "list int", "[1; 2; 3]")], "Od.compare_list a b (fun x y -> Od.compare_int x y) = Od.Lt && Od.compare_list b a (fun x y -> Od.compare_int x y) = Od.Gt"),
  ("ord_cmp_option", [("a", "option int", "None"), ("b", "option int", "Some 2")], "Od.compare_option Od.compare_int a b = Od.Lt && Od.compare_option Od.compare_int b a = Od.Gt && Od.compare_option Od.compare_int b b = Od.Eq && Od.compare_option Od.compare_int a a = Od.Eq"),
  # ---- FStar.Seq.Base (seq = liste en F#)
  ("seq_length", [("l", "list int", "[1; 2; 3]")], "Sq.length (Sq.seq_of_list l) = 3 && Sq.length (Sq.empty #int) = 0", "nonorm"),
  ("seq_to_of_list", [("l", "list int", "[4; 5; 6]")], "Sq.seq_to_list (Sq.seq_of_list l) = l", "nonorm"),
  ("seq_index", [("l", "list int", "[4; 5; 6]")], "Sq.length (Sq.seq_of_list l) = 3 && Sq.index (Sq.seq_of_list l) 0 = 4 && Sq.index (Sq.seq_of_list l) 2 = 6", "nonorm"),
  ("seq_create", [("n", "nat", "3"), ("v", I, "7")], "sl (Sq.create n v) = [7; 7; 7] && Sq.length (Sq.create 0 v) = 0", "nonorm"),
  ("seq_init", [("n", "nat", "4")], "sl (Sq.init n (fun (i:nat{i < n}) -> i * i)) = [0; 1; 4; 9]", "nonorm"),
  ("seq_empty", [("u", "unit", "()")], "sl (Sq.empty #int) = [] && sl (Sq.createEmpty #int) = []", "nonorm"),
  ("seq_upd", [("l", "list int", "[1; 2; 3]")], "Sq.length (Sq.seq_of_list l) = 3 && sl (Sq.upd (Sq.seq_of_list l) 1 9) = [1; 9; 3] && sl (Sq.upd (Sq.seq_of_list l) 0 0) = [0; 2; 3]", "nonorm"),
  ("seq_append", [("a", "list int", "[1; 2]"), ("b", "list int", "[3]")], "sl (Sq.append (Sq.seq_of_list a) (Sq.seq_of_list b)) = [1; 2; 3] && sl ((Sq.seq_of_list a) `Sq.append` (Sq.empty #int)) = a", "nonorm"),
  ("seq_cons", [("l", "list int", "[2; 3]")], "sl (Sq.cons 1 (Sq.seq_of_list l)) = [1; 2; 3]", "nonorm"),
  ("seq_slice", [("l", "list int", "[1; 2; 3; 4; 5]")], "Sq.length (Sq.seq_of_list l) = 5 && sl (Sq.slice (Sq.seq_of_list l) 1 4) = [2; 3; 4] && sl (Sq.slice (Sq.seq_of_list l) 0 0) = [] && sl (Sq.slice (Sq.seq_of_list l) 0 5) = l", "nonorm"),
  ("seq_eq", [("a", "list int", "[1; 2]"), ("b", "list int", "[1; 3]")], "Sq.eq (Sq.seq_of_list a) (Sq.seq_of_list a) && not (Sq.eq (Sq.seq_of_list a) (Sq.seq_of_list b)) && not (Sq.eq (Sq.seq_of_list a) (Sq.seq_of_list [1]))", "nonorm"),
  # ---- FStar.Seq.Properties
  ("sp_head_tail_last", [("l", "list int", "[1; 2; 3]")], "Sq.length (Sq.seq_of_list l) = 3 && SP.head (Sq.seq_of_list l) = 1 && sl (SP.tail (Sq.seq_of_list l)) = [2; 3] && SP.last (Sq.seq_of_list l) = 3", "nonorm"),
  ("sp_split", [("l", "list int", "[1; 2; 3; 4]")], "Sq.length (Sq.seq_of_list l) = 4 && (let (a, b) = SP.split (Sq.seq_of_list l) 2 in sl a = [1; 2] && sl b = [3; 4]) && (let (a2, b2) = SP.split (Sq.seq_of_list l) 0 in sl a2 = [] && sl b2 = l)", "nonorm"),
  ("sp_split_eq", [("l", "list int", "[1; 2; 3; 4]")], "Sq.length (Sq.seq_of_list l) = 4 && (let (a, b) = SP.split_eq (Sq.seq_of_list l) 3 in sl a = [1; 2; 3] && sl b = [4])", "nonorm"),
  ("sp_count_mem", [("l", "list int", "[1; 2; 1; 3]")], "SP.count 1 (Sq.seq_of_list l) = 2 && SP.count 9 (Sq.seq_of_list l) = 0 && SP.mem 3 (Sq.seq_of_list l) && not (SP.mem 9 (Sq.seq_of_list l))", "nonorm"),
  ("sp_index_mem", [("l", "list int", "[5; 6; 7]")], "SP.mem 6 (Sq.seq_of_list l) && SP.index_mem 6 (Sq.seq_of_list l) = 1", "nonorm"),
  ("sp_swap", [("l", "list int", "[1; 2; 3; 4]")], "Sq.length (Sq.seq_of_list l) = 4 && sl (SP.swap (Sq.seq_of_list l) 0 3) = [4; 2; 3; 1] && sl (SP.swap (Sq.seq_of_list l) 1 1) = l", "nonorm"),
  ("sp_sorted", [("a", "list int", "[1; 2; 2; 5]"), ("b", "list int", "[3; 1]")], "SP.sorted (fun (x:int) y -> x <= y) (Sq.seq_of_list a) && not (SP.sorted (fun (x:int) y -> x <= y) (Sq.seq_of_list b)) && SP.sorted (fun (x:int) y -> x <= y) (Sq.empty #int)", "nonorm"),
  ("sp_snoc_unsnoc", [("l", "list int", "[1; 2]")], "sl (SP.snoc (Sq.seq_of_list l) 3) = [1; 2; 3] && Sq.length (Sq.seq_of_list l) = 2 && (let s3 = SP.snoc (Sq.seq_of_list l) 3 in Sq.length s3 = 3 && (let (i, x) = SP.un_snoc s3 in sl i = [1; 2] && x = 3))", "nonorm"),
  ("sp_find_l", [("l", "list int", "[1; 4; 6; 7]")], "SP.find_l (fun (x:int) -> x > 3) (Sq.seq_of_list l) = Some 4 && SP.find_l (fun (x:int) -> x > 9) (Sq.seq_of_list l) = None", "nonorm"),
  ("sp_find_r", [("l", "list int", "[1; 4; 6; 7]")], "SP.find_r (fun (x:int) -> x < 7) (Sq.seq_of_list l) = Some 6 && SP.find_r (fun (x:int) -> x > 9) (Sq.seq_of_list l) = None", "nonorm"),
  ("sp_seq_find", [("l", "list int", "[1; 4; 6; 7]")], "SP.seq_find (fun (x:int) -> x > 3) (Sq.seq_of_list l) = Some 7 || SP.seq_find (fun (x:int) -> x > 3) (Sq.seq_of_list l) = Some 4", "nonorm"),
  ("sp_for_all", [("l", "list int", "[2; 4; 6]")], "SP.for_all (fun (x:int) -> x % 2 = 0) (Sq.seq_of_list l) && not (SP.for_all (fun (x:int) -> x > 3) (Sq.seq_of_list l))", "nonorm"),
  ("sp_createL", [("l", "list int", "[1; 2; 3]")], "sl (SP.createL l) = l && sl (SP.of_list l) = l", "nonorm"),
  ("sp_sortWith", [("l", "list int", "[3; 1; 2; 1]")], "sl (SP.sortWith (fun (a:int) b -> a - b) (Sq.seq_of_list l)) = [1; 1; 2; 3]", "nonorm"),
  ("sp_foldr", [("l", "list int", "[1; 2; 3]")], "SP.foldr (fun (x:int) (a:int) -> a * 10 + x) (Sq.seq_of_list l) 0 = 321", "nonorm"),
  ("sp_splice", [("a", "list int", "[1; 2; 3; 4]"), ("b", "list int", "[9; 8; 7; 6]")], "Sq.length (Sq.seq_of_list a) = 4 && Sq.length (Sq.seq_of_list b) = 4 && sl (SP.splice (Sq.seq_of_list a) 1 (Sq.seq_of_list b) 3) = [1; 8; 7; 4]", "nonorm"),
  ("sp_replace_subseq", [("a", "list int", "[1; 2; 3; 4]"), ("s", "list int", "[7; 8]")], "Sq.length (Sq.seq_of_list a) = 4 && Sq.length (Sq.seq_of_list s) = 2 && sl (SP.replace_subseq (Sq.seq_of_list a) 1 3 (Sq.seq_of_list s)) = [1; 7; 8; 4]", "nonorm"),
  ("sp_split_5", [("l", "list int", "[1; 2; 3; 4; 5; 6]")], "Sq.length (Sq.seq_of_list l) = 6 && (let r = SP.split_5 (Sq.seq_of_list l) 1 4 in Sq.length r = 5 && sl (Sq.index r 0) = [1] && sl (Sq.index r 1) = [2] && sl (Sq.index r 2) = [3; 4] && sl (Sq.index r 3) = [5] && sl (Sq.index r 4) = [6])", "nonorm"),

  # ---- FStar.Set (ensembles : observations par mem)
  ("set_basic", [("x", I, "2")], "St.mem x (St.singleton x) && not (St.mem 3 (St.singleton x)) && not (St.mem x (St.empty #int))"),
  ("set_union", [("a", "St.set int", "St.as_set [1; 2]"), ("b", "St.set int", "St.as_set [2; 3]")], "St.mem 1 (St.union a b) && St.mem 3 (St.union a b) && not (St.mem 4 (St.union a b))"),
  ("set_intersect", [("a", "St.set int", "St.as_set [1; 2]"), ("b", "St.set int", "St.as_set [2; 3]")], "St.mem 2 (St.intersect a b) && not (St.mem 1 (St.intersect a b)) && not (St.mem 3 (St.intersect a b))"),
  ("set_complement", [("a", "St.set int", "St.as_set [1; 2]")], "not (St.mem 1 (St.complement a)) && St.mem 5 (St.complement a)"),
  ("set_add_remove", [("a", "St.set int", "St.as_set [1; 2]")], "St.mem 9 (St.add 9 a) && St.mem 1 (St.add 9 a) && not (St.mem 1 (St.remove 1 a)) && St.mem 2 (St.remove 1 a)"),
  ("set_as_set", [("l", "list int", "[3; 5; 3]")], "St.mem 3 (St.as_set l) && St.mem 5 (St.as_set l) && not (St.mem 4 (St.as_set l))"),
  # ---- FStar.Map
  ("map_sel_upd", [("m", "Mp.t int string", "Mp.upd (Mp.const \"d\") 1 \"un\"")], "Mp.sel m 1 = \"un\" && Mp.sel m 2 = \"d\" && Mp.sel (Mp.upd m 2 \"deux\") 2 = \"deux\" && Mp.sel (Mp.upd m 2 \"deux\") 1 = \"un\""),
  ("map_const_domain", [("m", "Mp.t int bool", "Mp.const true")], "Mp.sel m 7 = true"),
  ("map_contains", [("m", "Mp.t int string", "Mp.upd (Mp.const \"d\") 1 \"un\"")], "Mp.contains m 1 && Mp.contains m 99 && Mp.contains (Mp.const_on #int #string (St.as_set [1; 2]) \"x\") 1 && not (Mp.contains (Mp.const_on #int #string (St.as_set [1; 2]) \"x\") 3)"),
  ("map_map_val", [("m", "Mp.t int int", "Mp.upd (Mp.const 0) 1 10")], "Mp.sel (Mp.map_val (fun (x:int) -> x + 1) m) 1 = 11 && Mp.sel (Mp.map_val (fun (x:int) -> x + 1) m) 5 = 1"),
  ("map_concat", [("a", "Mp.t int int", "Mp.upd (Mp.const 0) 1 10"), ("b", "Mp.t int int", "Mp.upd (Mp.const 0) 2 20")], "Mp.sel (Mp.concat a b) 2 = 20 && Mp.sel (Mp.concat a b) 1 = 0 && Mp.sel (Mp.concat b a) 1 = 10"),
  ("map_restrict", [("m", "Mp.t int int", "Mp.upd (Mp.const 0) 1 10")], "Mp.sel (Mp.restrict (St.as_set [1]) m) 1 = 10 && Mp.contains (Mp.restrict (St.as_set [1]) m) 1 && not (Mp.contains (Mp.restrict (St.as_set [1]) m) 2)"),
  ("map_literal", [("k", I, "4")], "Mp.sel (Mp.map_literal (fun (x:int) -> x * x)) k = 16"),
  # ---- FStar.PartialMap
  ("pm_basic", [("k", I, "1")], "Pm.sel (Pm.empty int string) k = None && Pm.sel (Pm.upd (Pm.empty int string) k \"a\") k = Some \"a\" && Pm.sel (Pm.upd (Pm.empty int string) k \"a\") 2 = None"),
  ("pm_remove_contains", [("m", "Pm.t int string", "Pm.upd (Pm.upd (Pm.empty int string) 1 \"a\") 2 \"b\"")], "Pm.contains m 1 && Pm.contains m 2 && not (Pm.contains (Pm.remove m 1) 1) && Pm.contains (Pm.remove m 1) 2"),
  ("pm_literal_const", [("k", I, "3")], "Pm.sel (Pm.literal (fun (x:int) -> if x > 2 then Some x else None)) k = Some 3 && Pm.sel (Pm.literal (fun (x:int) -> if x > 2 then Some x else None)) 1 = None && Pm.sel (Pm.const int 'c') k = Some 'c'"),
  # ---- FStar.FunctionalQueue
  ("fq_basic", [("l", "list int", "[1; 2; 3]")], "sl (Fq.queue_to_seq (Fq.queue_of_seq (Sq.seq_of_list l))) = l && sl (Fq.queue_to_seq (Fq.empty #int)) = []", "nonorm"),
  ("fq_enqueue", [("l", "list int", "[1; 2]")], "sl (Fq.queue_to_seq (Fq.enqueue 3 (Fq.queue_of_seq (Sq.seq_of_list l)))) = [1; 2; 3]", "nonorm"),
  ("fq_dequeue_peek", [("l", "list int", "[7; 8; 9]")], "(let q = Fq.queue_of_seq (Sq.seq_of_list l) in Sq.length (Fq.queue_to_seq q) > 0 && Fq.peek q = 7 && (let (x, q2) = Fq.dequeue q in x = 7 && sl (Fq.queue_to_seq q2) = [8; 9]))", "nonorm"),
  # ---- FStar.OrdSet (ordre <=)
  ("os_basic", [("l", "list int", "[3; 1; 2; 3]")], "Os.size (Os.distinct leq l) = 3 && Os.as_list (Os.distinct leq l) = [1; 2; 3] && Os.mem 2 (Os.distinct leq l) && not (Os.mem 9 (Os.distinct leq l))", "nonorm"),
  ("os_ops", [("a", "list int", "[1; 3; 5]"), ("b", "list int", "[3; 4; 5]")], "Os.as_list (Os.union (Os.distinct leq a) (Os.distinct leq b)) = [1; 3; 4; 5] && Os.as_list (Os.intersect (Os.distinct leq a) (Os.distinct leq b)) = [3; 5] && Os.as_list (Os.minus (Os.distinct leq a) (Os.distinct leq b)) = [1]", "nonorm"),
  ("os_remove_singleton", [("x", I, "3")], "Os.as_list (Os.remove x (Os.distinct leq [1; 3; 5])) = [1; 5] && Os.as_list (Os.singleton #int #leq x) = [3] && Os.as_list (Os.empty #int #leq) = []", "nonorm"),
  ("os_subset", [("a", "list int", "[1; 3]"), ("b", "list int", "[1; 3; 5]")], "Os.subset (Os.distinct leq a) (Os.distinct leq b) && not (Os.subset (Os.distinct leq b) (Os.distinct leq a)) && Os.strict_subset (Os.distinct leq a) (Os.distinct leq b) && Os.superset (Os.distinct leq b) (Os.distinct leq a) && Os.strict_superset (Os.distinct leq b) (Os.distinct leq a) && not (Os.disjoint (Os.distinct leq a) (Os.distinct leq b)) && Os.disjoint (Os.distinct leq a) (Os.distinct leq [7])", "nonorm"),
  ("os_choose", [("l", "list int", "[4; 2]")], "Os.choose (Os.distinct leq l) = Some 2 || Os.choose (Os.distinct leq l) = Some 4", "nonorm"),
  ("os_fold", [("l", "list int", "[1; 2; 3]")], "Os.fold (fun (a:int) (x:int) -> a * 10 + x) 0 (Os.distinct leq l) = 123", "nonorm"),
  ("os_all_any", [("l", "list int", "[2; 4; 6]")], "Os.all (Os.distinct leq l) (fun (x:int) -> x % 2 = 0) && Os.any (Os.distinct leq l) (fun (x:int) -> x > 5) && not (Os.any (Os.distinct leq l) (fun (x:int) -> x > 6)) && Os.count (Os.distinct leq l) (fun (x:int) -> x > 2) = 2", "nonorm"),
  ("os_find", [("l", "list int", "[2; 4; 6]")], "Os.find_first (Os.distinct leq l) (fun (x:int) -> x > 2) = Some 4 && Os.find_last (Os.distinct leq l) (fun (x:int) -> x < 6) = Some 4", "nonorm"),
  ("os_map", [("l", "list int", "[1; 2; 3]")], "Os.as_list (Os.map #int #int #leq #leq (fun (x:int) -> x * 2) (Os.distinct leq l)) = [2; 4; 6]", "nonorm"),

  # ---- FStar.UInt (arithmétique sur int bornés : fonctions définies en F*)
  ("ui_basic", [("n", "nat", "8")], "UI.max_int n = 255 && UI.min_int n = 0 && UI.fits 255 n && not (UI.fits 256 n) && UI.zero n = 0 && UI.one n = 1 && UI.ones n = 255 && UI.pow2_n #8 7 = 128"),
  ("ui_add_mod", [("a", "UI.uint_t 8", "200"), ("b", "UI.uint_t 8", "100")], "UI.add_mod #8 a b = 44 && UI.mul_mod #8 20 20 = 144 && UI.add_mod #8 a 0 = a"),  # sub_mod : Mx41
  ("ui_add_sub_mul", [("a", "UI.uint_t 8", "100"), ("b", "UI.uint_t 8", "55")], "UI.fits (a + b) 8 && UI.add #8 a b = 155 && UI.fits (a - b) 8 && UI.sub #8 a b = 45 && UI.fits (a * 2) 8 && UI.mul #8 a 2 = 200 && UI.add_underspec #8 a b = 155 && UI.sub_underspec #8 a b = 45 && UI.mul_underspec #8 a 2 = 200"),
  ("ui_div_mod", [("a", "UI.uint_t 8", "200"), ("b", "UI.uint_t 8", "7")], "b <> 0 && UI.div #8 a b = 28 && UI.udiv #8 a b = 28 && UI.mod #8 a b = 4 && UI.div_underspec #8 a b = 28 && UI.mul_div #8 a b = 200 * 7 / 256"),
  ("ui_incr_decr", [("a", "UI.uint_t 8", "5")], "a < UI.max_int 8 && a > UI.min_int 8 && UI.incr #8 a = 6 && UI.decr #8 a = 4 && UI.incr_underspec #8 a = 6 && UI.decr_underspec #8 a = 4 && UI.incr_mod #8 255 = 0"),  # decr_mod : Mx41
  ("ui_bits", [("a", "UI.uint_t 8", "240"), ("b", "UI.uint_t 8", "60")], "UI.logand #8 a b = 48 && UI.logor #8 a b = 252 && UI.logxor #8 a b = 204 && UI.lognot #8 a = 15 && UI.minus #8 1 = 255 && UI.minus #8 0 = 0", "nonorm"),
  ("ui_shift_rot", [("a", "UI.uint_t 8", "129")], "UI.shift_left #8 a 1 = 2 && UI.shift_right #8 a 1 = 64 && UI.rotate_left #8 a 1 = 3 && UI.rotate_right #8 a 1 = 192 && UI.msb #8 a && not (UI.msb #8 1)", "nonorm"),
  ("ui_cmp", [("a", "UI.uint_t 8", "3"), ("b", "UI.uint_t 8", "9")], "UI.lt #8 a b && UI.lte #8 a b && UI.gt #8 b a && UI.gte #8 b a && UI.eq #8 a a && UI.ne #8 a b && not (UI.gt #8 a b)"),
  ("ui_vec", [("a", "UI.uint_t 8", "5")], "sl (UI.to_vec #8 a) = [false; false; false; false; false; true; false; true] && UI.from_vec #8 (UI.to_vec #8 a) = a && UI.nth #8 a 7 = true && UI.nth #8 a 6 = false && UI.nth #8 a 5 = true", "nonorm"),
  ("ui_to_uint_t", [("a", "UI.uint_t 16", "513")], "UI.to_uint_t 8 a = 1 && UI.to_uint_t 16 a = 513 && UI.to_uint_t 32 a = 513", "nonorm"),
  ("ui_extend", [("a", "UI.uint_t 8", "200")], "UI.zero_extend #8 a = 200 && UI.one_extend #8 a = 456 && UI.zero_extends #8 3 a = 200", "nonorm"),
  ("ui_wide", [("a", "UI.uint_t 64", "18446744073709551615"), ("b", "UI.uint_t 64", "1")], "UI.add_mod #64 a b = 0 && UI.mul_mod #64 a a = 1 && UI.logand #64 a b = 1 && UI.shift_right #64 a 63 = 1 && UI.rotate_left #64 a 4 = a", "nonorm"),
  # ---- FStar.BitVector (seq bool)
  ("bv_basic", [("n", "pos", "4")], "sl (BV.zero_vec #n) = [false; false; false; false] && sl (BV.ones_vec #n) = [true; true; true; true] && sl (BV.elem_vec #n 1) = [false; true; false; false]", "nonorm"),
  ("bv_logic", [("a", "list bool", "[true; false; true; false]"), ("b", "list bool", "[true; true; false; false]")], "Sq.length (Sq.seq_of_list a) = 4 && Sq.length (Sq.seq_of_list b) = 4 && sl (BV.logand_vec #4 (Sq.seq_of_list a) (Sq.seq_of_list b)) = [true; false; false; false] && sl (BV.logor_vec #4 (Sq.seq_of_list a) (Sq.seq_of_list b)) = [true; true; true; false] && sl (BV.logxor_vec #4 (Sq.seq_of_list a) (Sq.seq_of_list b)) = [false; true; true; false] && sl (BV.lognot_vec #4 (Sq.seq_of_list a)) = [false; true; false; true]", "nonorm"),
  ("bv_shift", [("a", "list bool", "[true; false; true; true]")], "Sq.length (Sq.seq_of_list a) = 4 && sl (BV.shift_left_vec #4 (Sq.seq_of_list a) 1) = [false; true; true; false] && sl (BV.shift_right_vec #4 (Sq.seq_of_list a) 1) = [false; true; false; true] && sl (BV.shift_arithmetic_right_vec #4 (Sq.seq_of_list a) 1) = [true; true; false; true] && sl (BV.rotate_left_vec #4 (Sq.seq_of_list a) 1) = [false; true; true; true] && sl (BV.rotate_right_vec #4 (Sq.seq_of_list a) 1) = [true; true; false; true]", "nonorm"),
  # ---- FStar.Class.Printable / Eq
  ("pr_basic", [("n", I, "42")], "Pr.to_string n = \"42\" && Pr.to_string (0 - n) = \"-42\" && Pr.to_string true = \"true\" && Pr.to_string () = \"()\" && Pr.to_string \"s\" = \"\\\"s\\\"\""),
  # pr_compound (liste, option non vide) : boucle infinie à l'exécution, voir docs/matrix/Mx40_PrintableList.fst
  ("pr_none", [("u", "unit", "()")], "Pr.to_string (None #int) = \"None\""),
  ("pr_char", [("c", "FStar.Char.char", "'x'")], "Pr.to_string c = \"x\""),
  ("pr_machine", [("c", I, "7")], "Pr.to_string 7uy = \"7\" && Pr.to_string 7y = \"7\" && Pr.to_string 300us = \"300\" && Pr.to_string (-3s) = \"-3\" && Pr.to_string 70000ul = \"70000\" && Pr.to_string (-70000l) = \"-70000\" && Pr.to_string 5000000000uL = \"5000000000\" && Pr.to_string (-5000000000L) = \"-5000000000\"", "nonorm"),
  ("eq_basic", [("a", I, "3"), ("b", I, "4")], "FStar.Class.Eq.eq a a && not (FStar.Class.Eq.eq a b) && FStar.Class.Eq.eq true true && FStar.Class.Eq.eq \"x\" \"x\" && not (FStar.Class.Eq.eq \"x\" \"y\") && FStar.Class.Eq.eq () ()"),
  ("eq_raw_list", [("a", "list int", "[1; 2]"), ("b", "list int", "[1; 3]")], "FStar.Class.Eq.Raw.eqList (fun (x:int) y -> x = y) a a && not (FStar.Class.Eq.Raw.eqList (fun (x:int) y -> x = y) a b) && not (FStar.Class.Eq.Raw.eqList (fun (x:int) y -> x = y) a [1])"),
  # ---- FStar.FiniteSet.Base / FStar.FiniteMap.Base
  ("fs_basic", [("x", I, "2")], "Fs.mem x (Fs.singleton x) && not (Fs.mem 3 (Fs.singleton x)) && not (Fs.mem x (Fs.emptyset #int)) && Fs.notin 3 (Fs.singleton x)", "nonorm"),
  ("fs_ops", [("a", "Fs.set int", "Fs.insert 2 (Fs.singleton 1)"), ("b", "Fs.set int", "Fs.insert 3 (Fs.singleton 2)")], "Fs.mem 3 (Fs.union a b) && Fs.mem 1 (Fs.union a b) && Fs.mem 2 (Fs.intersection a b) && not (Fs.mem 1 (Fs.intersection a b)) && Fs.mem 1 (Fs.difference a b) && not (Fs.mem 2 (Fs.difference a b)) && not (Fs.mem 1 (Fs.remove 1 a)) && Fs.mem 2 (Fs.remove 1 a)", "nonorm"),
  ("fm_basic", [("k", I, "1")], "Fm.mem k (Fm.insert k \"a\" (Fm.emptymap #int #string)) && Fm.lookup k (Fm.insert k \"a\" (Fm.emptymap #int #string)) = \"a\" && not (Fm.mem 2 (Fm.insert k \"a\" (Fm.emptymap #int #string))) && Fm.notin 2 (Fm.insert k \"a\" (Fm.emptymap #int #string))", "nonorm"),
  ("fm_ops", [("k", I, "1")], "(let m = Fm.insert 2 \"b\" (Fm.insert k \"a\" (Fm.emptymap #int #string)) in Fm.mem 2 m && Fm.lookup 2 m = \"b\" && not (Fm.mem 1 (Fm.remove 1 m)) && Fm.mem 2 (Fm.remove 1 m) && Fm.mem 1 (Fm.merge m (Fm.emptymap #int #string)) && Fm.mem 1 (Fm.subtract m (Fs.singleton 2)) && not (Fm.mem 2 (Fm.subtract m (Fs.singleton 2))) && Fs.mem 1 (Fm.domain m))", "nonorm"),
  # ---- FStar.OrdMap (ordre <=)
  ("om_basic", [("k", I, "2")], "(let m = Om.update 3 \"c\" (Om.update k \"b\" (Om.empty #int #string #leq)) in Om.select k m = Some \"b\" && Om.select 3 m = Some \"c\" && Om.select 9 m = None && Om.contains 3 m && not (Om.contains 9 m) && Om.size m = 2 && Os.as_list (Om.dom m) = [2; 3])", "nonorm"),
  ("om_remove_choose", [("k", I, "2")], "(let m = Om.update 3 \"c\" (Om.update k \"b\" (Om.empty #int #string #leq)) in Om.size (Om.remove k m) = 1 && Om.select k (Om.remove k m) = None && Om.choose (Om.empty #int #string #leq) = None && (match Om.choose m with Some (x, _) -> x = 2 | None -> false))", "nonorm"),
  ("om_const_on", [("k", I, "5")], "(let m = Om.const_on (Os.distinct leq [1; 5]) \"z\" in Om.select k m = Some \"z\" && Om.select 2 m = None)", "nonorm"),

  # ---- FStar.List.Pure.Base
  ("lp_map2", [("a", "list int", "[1; 2; 3]"), ("b", "list int", "[10; 20; 30]")], "L.length a = L.length b && Lp.map2 (fun (x:int) y -> x + y) a b = [11; 22; 33]"),
  ("lp_map3", [("a", "list int", "[1; 2]"), ("b", "list int", "[3; 4]"), ("c", "list int", "[5; 6]")], "L.length a = L.length b && L.length b = L.length c && Lp.map3 (fun (x:int) y z -> x * y + z) a b c = [8; 14]"),
  ("lp_zip", [("a", "list int", "[1; 2]"), ("b", "list bool", "[true; false]")], "L.length a = L.length b && Lp.zip a b = [(1, true); (2, false)]"),
  ("lp_zip3", [("a", "list int", "[1; 2]"), ("b", "list bool", "[true; false]"), ("c", "list string", "[\"x\"; \"y\"]")], "L.length a = L.length b && L.length b = L.length c && Lp.zip3 a b c = [(1, true, \"x\"); (2, false, \"y\")]"),
  # ---- FStar.Sequence.Base / Util (séquences spécifiées par axiomes)
  ("sn_basic", [("x", I, "5")], "Sn.length (Sn.singleton x) = 1 && Sn.index (Sn.singleton x) 0 = 5 && Sn.length (Sn.empty #int) = 0", "nonorm"),
  ("sn_build_append", [("x", I, "5")], "(let s = Sn.build (Sn.build (Sn.empty #int) x) 6 in Sn.length s = 2 && Sn.index s 0 = 5 && Sn.index s 1 = 6 && (let t = Sn.append s s in Sn.length t = 4 && Sn.index t 3 = 6 && Sn.index t 2 = 5))", "nonorm"),
  ("sn_update_take_drop", [("x", I, "5")], "(let s = Sn.build (Sn.build (Sn.build (Sn.empty #int) x) 6) 7 in Sn.length s = 3 && (let u = Sn.update s 1 9 in Sn.length u = 3 && Sn.index u 1 = 9 && Sn.index u 0 = 5) && (let t = Sn.take s 2 in Sn.length t = 2 && Sn.index t 1 = 6) && (let d = Sn.drop s 2 in Sn.length d = 1 && Sn.index d 0 = 7))", "nonorm"),
  ("su_ops", [("x", I, "5")], "(let s = Sn.build (Sn.build (Sn.build (Sn.empty #int) x) 6) 5 in Sn.length s = 3 && Su.head s = 5 && (let t = Su.tail s in Sn.length t = 2 && Sn.index t 0 = 6) && Su.count 5 s = 2 && (let sl2 = Su.slice s 1 3 in Sn.length sl2 = 2 && Sn.index sl2 0 = 6) && (let c = Su.cons 1 s in Sn.length c = 4 && Sn.index c 0 = 1))", "nonorm"),
  # ---- FStar.RBSet / FStar.RBMap (arbres rouge-noir, ordre par classe de types)
  ("rs_basic", [("x", I, "2")], "(let s = Rs.add 3 (Rs.add x (Rs.add 1 (Rs.empty ()))) in Rs.elems s = [1; 2; 3] && Rs.mem 2 s && not (Rs.mem 9 s) && not (Rs.is_empty s) && Rs.is_empty (Rs.empty #int ()) && Rs.elems (Rs.singleton x) = [2])", "nonorm"),
  ("rs_ops", [("x", I, "2")], "(let a = Rs.from_list [1; 2; 3] in let b = Rs.from_list [3; 4] in Rs.elems (Rs.union a b) = [1; 2; 3; 4] && Rs.elems (Rs.inter a b) = [3] && Rs.elems (Rs.diff a b) = [1; 2] && Rs.subset (Rs.from_list [1; 2]) a && not (Rs.subset b a) && Rs.elems (Rs.remove x a) = [1; 3] && Rs.equal a (Rs.from_list [3; 2; 1]))", "nonorm"),
  ("rs_filter_forall", [("x", I, "2")], "(let a = Rs.from_list [1; 2; 3; 4] in Rs.elems (Rs.filter (fun (v:int) -> v % 2 = 0) a) = [2; 4] && Rs.for_all (fun (v:int) -> v > 0) a && Rs.for_any (fun (v:int) -> v > 3) a && not (Rs.for_any (fun (v:int) -> v > 4) a) && Rs.elems (Rs.addn [9; 0] a) = [0; 1; 2; 3; 4; 9])", "nonorm"),
  ("rs_min", [("x", I, "2")], "(let a = Rs.from_list [5; 2; 8] in not (Rs.is_empty a) && (let (r, m) = Rs.extract_min a in m = 2 && Rs.elems r = [5; 8]))", "nonorm"),
  ("rm_basic", [("x", I, "2")], "(let m = Rm.add 3 \"c\" (Rm.add x \"b\" (Rm.add 1 \"a\" (Rm.empty ()))) in Rm.keys m = [1; 2; 3] && Rm.lookup 2 m = Some \"b\" && Rm.lookup 9 m = None && Rm.mem 3 m && not (Rm.mem 9 m) && Rm.to_list m = [(1, \"a\"); (2, \"b\"); (3, \"c\")] && not (Rm.is_empty m) && Rm.is_empty (Rm.empty #int #string ()) && Rm.to_list (Rm.singleton x \"z\") = [(2, \"z\")])", "nonorm"),
  ("rm_ops", [("x", I, "2")], "(let m = Rm.from_list [(1, \"a\"); (2, \"b\"); (3, \"c\")] in Rm.keys (Rm.remove x m) = [1; 3] && Rm.keys (Rm.filter (fun (k:int) (v:string) -> k > 1) m) = [2; 3] && Rm.for_all (fun (k:int) (v:string) -> k > 0) m && Rm.for_any (fun (k:int) (v:string) -> k = 2) m && Rm.keys (Rm.union m (Rm.from_list [(9, \"z\")])) = [1; 2; 3; 9] && Rm.keys (Rm.inter m (Rm.from_list [(2, \"q\"); (7, \"r\")])) = [2] && Rm.keys (Rm.addn [(0, \"o\")] m) = [0; 1; 2; 3] && not (Rm.is_empty m) && (let (r, (k, v)) = Rm.extract_min m in k = 1 && v = \"a\" && Rm.keys r = [2; 3]))", "nonorm"),
  # ---- FStar.Class.Ord.Raw / TotalOrder.Raw / Add
  ("ord_raw", [("a", I, "3"), ("b", I, "5")], "Co.min a b = 3 && Co.max a b = 5 && (a <? b) && (b >? a) && (a <=? a) && (b >=? b) && not (b <? a)", "nonorm"),
  ("ord_raw_sort", [("l", "list int", "[3; 1; 2; 3]")], "Co.sort l = [1; 2; 3; 3] && Co.dedup l = [3; 1; 2] && Co.sort_dedup l = [1; 2; 3]", "nonorm"),
  ("ord_raw_diff", [("a", "list int", "[1; 2; 3]"), ("b", "list int", "[2; 3; 4]")], "(let (x, y) = Co.ord_list_diff a b in x = [1] && y = [4])", "nonorm"),
  ("totord_flip", [("o", "Od.order", "Od.Lt")], "To.flip o = Od.Gt && To.flip Od.Gt = Od.Lt && To.flip Od.Eq = Od.Eq"),
  ("add_class", [("a", I, "2"), ("b", I, "3")], "Ad.(a ++ b) = 5 && Ad.(true ++ false) = true && Ad.(false ++ false) = false && Ad.(([1]) ++ ([2])) = [1; 2] && (Ad.zero #int) = 0 && (Ad.zero #bool) = false && (Ad.zero #(list int)) = []"),


  # ---- FStar.Printf (formats typés)
  ("pf_basic", [("n", I, "42"), ("s", "string", "\"x\"")], "Pf.sprintf \"%d-%s\" n s = \"42-x\" && Pf.sprintf \"plain\" = \"plain\" && Pf.sprintf \"%d\" (0 - n) = \"-42\" && Pf.sprintf \"100%%\" = \"100%\""),
  ("pf_bool_char", [("b", "bool", "true"), ("c", "FStar.Char.char", "'z'")], "Pf.sprintf \"%b/%c\" b c = \"true/z\" && Pf.sprintf \"%b\" false = \"false\""),
  # pf_machine (%y %i %l %L %uy %us %ul %uL) : failwith Prims.admit à l'exécution, voir docs/matrix/Mx46_PrintfMachineInt.fst
  ("pf_parse", [("n", I, "0")], "Some? (Pf.parse_format_string \"%d\" Pf.no_extensions) && None? (Pf.parse_format_string \"%\" Pf.no_extensions) && None? (Pf.parse_format_string \"%q\" Pf.no_extensions) && Some? (Pf.parse_format_string \"abc\" Pf.no_extensions) && Some? (Pf.parse_format_string \"%uy%us%ul%uL%y%i%l%L%%%b%c%s%d\" Pf.no_extensions) && None? (Pf.parse_format_string \"%ux\" Pf.no_extensions)"),
]

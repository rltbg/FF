module TApp
(* Tests de App.fst : marches aléatoires sur [update] avec un invariant recalculé indépendamment, effets message par
   message (les lemmes de App.fst vérifiés ici à l'exécution), cas limites, vue. *)
open FStar.All
open TUtil
module U32 = FStar.UInt32
module I32 = FStar.Int32
module S   = FStar.String
open FStar.List.Tot
open App

(* invariant recalculé ici, sans appeler App.inv *)
let rec strictly_below (n:U32.t) (l:list item) : Tot bool (decreases l) =
  match l with
  | [] -> true
  | x :: t -> U32.lt x.id n && strictly_below x.id t

let indep_inv (m:model) : bool =
  I32.gte m.counter (-1000l) && I32.lte m.counter 1000l
  && strictly_below m.next_id m.items
  && U32.lt m.next_id 0xFFFFFFFFul
  && (match m.sel with Some i -> U32.lt i 100000ul | None -> true)

let rec leaves (v:view_tree) : Tot nat (decreases v) =
  match v with
  | VColumn xs -> leaves_l xs
  | VRow xs -> leaves_l xs
  | _ -> 1
and leaves_l (l:list view_tree) : Tot nat (decreases l) =
  match l with [] -> 0 | x :: t -> leaves x + leaves_l t

(* update gardé : la précondition (inv) est testée à l'exécution *)
let upd (m:model) (g:msg) : ML model = if inv m then update m g else m

let name_ok_s (s:string) : bool = Core.name_ok (S.list_of_string s)

let dig_is (d:option digest) (id:int) (len:int) (h:int) : bool =
  match d with
  | Some x -> U32.eq x.text_id (u32_of id) && U32.eq x.len (u32_of len) && U32.eq x.fnv (u32_of h)
  | None -> false

(* empreintes des deux textes générés, calculées par un script externe indépendant (voir docs/STATUT.md) *)
let text1_len = 832080
let text1_fnv = 1791175457
let empty_fnv = 2166136261

let rec apply_all (m:model{inv m}) (l:list msg) : Tot (m':model{inv m'}) (decreases l) =
  match l with [] -> m | g :: t -> apply_all (update m g) t

let test_show () : ML unit =
  check "show_model init" (show_model init = "tab=counter counter=0 items= draft= name= age= status=editing sel=- digest=-");
  let m1 = apply_all init [Inc; Inc; Goto TItems; Typed (InNew, "pommes"); AddItem; Typed (InNew, "poires"); AddItem; Toggle 1ul] in
  check "show_model liste" (show_model m1 = "tab=items counter=2 items=poires[x],pommes[ ] draft= name= age= status=editing sel=- digest=-");
  let m2 = apply_all init [Typed (InName, "Ada Lovelace"); Typed (InAge, "36"); Submit] in
  check "show_model accepté" (show_model m2 = "tab=counter counter=0 items= draft= name=Ada Lovelace age=36 status=accepted:Ada Lovelace,36,4267605246 sel=- digest=-");
  let m3 = apply_all init [Typed (InAge, "200"); Submit] in
  check "show_model rejeté" (show_model m3 = "tab=counter counter=0 items= draft= name= age=200 status=rejected:nom : 1 à 20 caractères, sans caractère de contrôle|âge : entier décimal entre 0 et 150 sel=- digest=-");
  let m4 = apply_all init [Goto TBig; Select 2ul; HashText 1ul] in
  check "show_model volumes" (show_model m4 = "tab=big counter=0 items= draft= name= age= status=editing sel=2 digest=1,832080,1791175457");
  (* préchargement : n éléments « item i » dans l'ordre *)
  check "preload_msgs 0" (Nil? (preload_msgs 0));
  check "preload_msgs 2" (preload_msgs 2 = [Typed (InNew, "item 1"); AddItem; Typed (InNew, "item 2"); AddItem]);
  let m5 = apply_all init (preload_msgs 3) in
  check "preload appliqué" (show_model m5 = "tab=counter counter=0 items=item 3[ ],item 2[ ],item 1[ ] draft= name= age= status=editing sel=- digest=-");
  check "preload 1000" (length (apply_all init (preload_msgs 1000)).items = 1000)

let test_cases () : ML unit =
  check "init inv" (inv init && indep_inv init);
  let m0 = blur ({ init with counter = 5l }) in
  check "pré m0" (inv m0);
  check "inc/dec (lemma_inc_dec)" ((upd (upd m0 Inc) Dec).counter = 5l);
  check "inc sature" ((upd ({ m0 with counter = 1000l }) Inc).counter = 1000l);
  check "dec sature" ((upd ({ m0 with counter = (-1000l) }) Dec).counter = (-1000l));
  check "reset" ((upd m0 Reset).counter = 0l);
  check "goto" ((upd m0 (Goto TBig)).tab = TBig);
  (* next_id : refus au maximum, accepté juste avant *)
  let full = blur ({ init with next_id = 0xFFFFFFFEul; draft = "x" }) in
  check "pré full" (inv full);
  check "add refusé à next_id max" (Nil? (upd full AddItem).items);
  let near = blur ({ init with next_id = 0xFFFFFFFDul; draft = "x" }) in
  check "pré near" (inv near);
  let added = upd near AddItem in
  check "add accepté juste avant max" (length added.items = 1 && U32.eq added.next_id 0xFFFFFFFEul && inv added);
  (* brouillon invalide : modèle inchangé *)
  let bad = blur ({ init with draft = "" }) in
  check "add brouillon vide" (upd bad AddItem = bad);
  (* grande liste et texte *)
  check "select 99999" ((upd init (Select (blur 99999ul))).sel = Some 99999ul);
  check "select 100000 refusé" (upd init (Select (blur 100000ul)) = init);
  check "select max u32 refusé" (upd init (Select (blur 0xFFFFFFFFul)) = init);
  check "hash src 1" (dig_is (upd init (HashText (blur 1ul))).digest 1 text1_len text1_fnv);
  check "hash src 0 : texte vide" (dig_is (upd init (HashText (blur 0ul))).digest 0 0 empty_fnv);
  check "hash src inconnue : texte vide" (dig_is (upd init (HashText (blur 77ul))).digest 77 0 empty_fnv);
  (* fabriques de messages *)
  check "msg_of_input" (msg_of_input InName (blur "z") = Typed (InName, "z"));
  check "msg_of_select/hash" (msg_of_select (blur 3ul) = Select 3ul && msg_of_hash (blur 1ul) = HashText 1ul);
  (* formulaire : accepté / rejeté, empreinte exacte *)
  let f = blur ({ init with name = "Ada Lovelace"; age = "36" }) in
  check "submit accepté" (match (upd f Submit).status with
                          | Accepted (n, a, h) -> n = "Ada Lovelace" && U32.eq a 36ul && U32.eq h (u32_of 4267605246)
                          | _ -> false);
  let g = blur ({ init with name = "Ada"; age = "200" }) in
  check "submit âge hors plage" ((upd g Submit).status = Rejected [err_age]);
  let h = blur ({ init with name = ""; age = "x" }) in
  check "submit nom+âge invalides" ((upd h Submit).status = Rejected [err_name; err_age]);
  check "typed repasse en Editing" ((upd (upd f Submit) (Typed (InName, "B"))).status = Editing)

(* marche aléatoire : propriétés vérifiées message par message *)
let rand_msg (m:model) : ML msg =
  match rand_below 12 with
  | 0 | 1 | 2 -> Inc
  | 3 -> Dec
  | 4 -> Reset
  | 5 -> Goto (match rand_below 4 with 0 -> TCounter | 1 -> TItems | 2 -> TForm | _ -> TBig)
  | 6 | 7 -> Typed (InNew, string_of_codes (rand_list (rand_below 25) (fun () -> pick [97; 98; 99; 32; 233; 127])))
  | 8 -> AddItem
  | 9 -> (match m.items with [] -> ClearChecked | x :: _ -> Remove (pick (map (fun (i:item) -> i.id) m.items)))
  | 10 -> (match m.items with [] -> ClearChecked | x :: _ -> Toggle (pick (map (fun (i:item) -> i.id) m.items)))
  | _ ->
    (match rand_below 6 with
     | 4 -> Select (u32_of (rand_below 100100))
     | 5 -> if rand_below 6 = 0 then HashText (u32_of (rand_below 3)) else HashText 0ul
     | 0 -> Typed (InName, string_of_codes (rand_list (rand_below 25) (fun () -> pick [97; 98; 9; 32; 233; 0x1F4; 0x2014])))
     | 1 -> Typed (InAge, string_of_codes (rand_list (rand_below 5) (fun () -> pick [48; 49; 50; 51; 52; 53; 54; 55; 56; 57; 120])))
     | 2 -> ClearChecked
     | _ -> Submit)

let rec no_checked (l:list item) : Tot bool (decreases l) =
  match l with [] -> true | x :: t -> not x.checked && no_checked t

let rec no_id (k:U32.t) (l:list item) : Tot bool (decreases l) =
  match l with [] -> true | x :: t -> not (U32.eq x.id k) && no_id k t

let check_step (before:model) (g:msg) (m:model) : ML unit =
  check "inv (App.inv)" (inv m);
  check "inv indépendant" (indep_inv m);
  check "vue non vide" (leaves (view m) > 0);
  match g with
  | AddItem ->
    let ok = name_ok_s before.draft && U32.lt before.next_id 0xFFFFFFFEul in
    check "add <=> nom valide et id libre (lemma_add_grows)" (length m.items = length before.items + (if ok then 1 else 0));
    if ok then
      (if U32.lt before.next_id 0xFFFFFFFEul then check "add : brouillon vidé, id suivant" (m.draft = "" && U32.eq m.next_id (U32.add before.next_id 1ul))
       else check "add : impossible" false)
    else check "add refusé : modèle inchangé" (m = before)
  | Select i ->
    if U32.lt i 100000ul then check "select : sel = Some i (lemma_select)" (m.sel = Some i && m.items = before.items)
    else check "select hors plage : inchangé (lemma_select_out_of_range)" (m = before)
  | HashText id ->
    (* lemma_hash_text : condensé exact du texte généré ; texte de la source 1 : constantes externes *)
    if U32.eq id 1ul then check "hash src 1" (dig_is m.digest 1 text1_len text1_fnv)
    else if U32.eq id 2ul then check "hash src 2 (inconnue)" (dig_is m.digest 2 0 empty_fnv)
    else check "hash src 0" (dig_is m.digest 0 0 empty_fnv)
  | Reset -> check "reset : compteur à 0" (m.counter = 0l)
  | Dec -> if I32.gt before.counter (-1000l) then check "dec : -1" (m.counter = I32.sub before.counter 1l)
           else check "dec : saturé" (m.counter = before.counter)
  | Inc -> if I32.lt before.counter 1000l then check "inc : +1" (m.counter = I32.add before.counter 1l)
           else check "inc : saturé" (m.counter = before.counter)
  | Remove k -> check "remove (lemma_remove_gone)" (no_id k m.items)
  | ClearChecked -> check "clear" (no_checked m.items)
  | Submit ->
    let name_ok = name_ok_s before.name in
    let age_p = Core.parse_age (S.list_of_string before.age) in
    (match m.status with
     | Accepted (n, a, h) ->
       check "accepted : nom" (n = before.name && name_ok);
       check "accepted : âge" ((match age_p with Some b -> U32.eq a b | None -> false) && U32.lte a 150ul);
       check "accepted : empreinte UTF-8" (if S.length n <= 4000000 then (Core.lemma_len_maxlen n; U32.eq h (Core.fnv_utf8 n)) else false)
     | Rejected es -> check "rejected" (Cons? es && (not name_ok || None? age_p))
     | Editing -> check "submit ne laisse pas Editing" false)
  | _ -> ()

let rec walk (n:nat) (m:model{inv m}) : ML unit =
  if n = 0 then () else begin
    let g = rand_msg m in
    let m' = update m g in
    check_step m g m';
    walk (n - 1) m'
  end

let rec walks (k:nat) : ML unit =
  if k = 0 then () else (walk 300 init; walks (k - 1))

let main () : ML unit =
  test_cases (); test_show (); walks 150

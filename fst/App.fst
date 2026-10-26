module App
(* Modèle MVU : Model, Msg, update (pure, avec invariant prouvé), view -> ViewTree (donnée). *)
module U32 = FStar.UInt32
module U8  = FStar.UInt8
module C   = FStar.Char
open FStar.List.Tot

type tab = | TCounter | TItems | TForm

type item = { id: U32.t; text: string; checked: bool }

type input_tag = | InNew | InName | InAge

type msg =
  | Inc | Dec | Reset
  | Goto of tab
  | AddItem | Remove of U32.t | Toggle of U32.t | ClearChecked
  | Typed of input_tag & string
  | Submit

type form_status =
  | Editing
  | Rejected of list string
  | Accepted of string & (a:U32.t{U32.v a <= 150}) & U32.t   (* nom, âge, empreinte FNV-1a *)

type model = {
  tab: tab;
  counter: int;
  items: list item;       (* ids strictement décroissants, tous < next_id *)
  next_id: U32.t;
  draft: string;
  name: string;
  age: string;
  status: form_status;
}

(* ---------- invariants ---------- *)
let counter_ok (c:int) : bool = -1000 <= c && c <= 1000

let rec sorted_below (n:U32.t) (l:list item) : Tot bool (decreases l) =
  match l with
  | [] -> true
  | x :: t -> U32.lt x.id n && sorted_below x.id t

let inv (m:model) : bool =
  counter_ok m.counter && sorted_below m.next_id m.items && U32.lt m.next_id 0xFFFFFFFFul

let init : (m:model{inv m}) =
  { tab = TCounter; counter = 0; items = []; next_id = 0ul; draft = "";
    name = ""; age = ""; status = Editing }

(* ---------- opérations sur la liste ---------- *)
let rec remove_id (k:U32.t) (l:list item) : Tot (list item) (decreases l) =
  match l with
  | [] -> []
  | x :: t -> if U32.eq x.id k then remove_id k t else x :: remove_id k t

let rec toggle_id (k:U32.t) (l:list item) : Tot (list item) (decreases l) =
  match l with
  | [] -> []
  | x :: t -> (if U32.eq x.id k then { x with checked = not x.checked } else x) :: toggle_id k t

let rec drop_checked (l:list item) : Tot (list item) (decreases l) =
  match l with
  | [] -> []
  | x :: t -> if x.checked then drop_checked t else x :: drop_checked t

let rec mem_id (k:U32.t) (l:list item) : Tot bool (decreases l) =
  match l with [] -> false | x :: t -> U32.eq x.id k || mem_id k t

let lemma_weaken (m n:U32.t) (l:list item)
  : Lemma (requires sorted_below m l /\ U32.v m <= U32.v n) (ensures sorted_below n l) 
  = ()

let rec lemma_remove (k n:U32.t) (l:list item)
  : Lemma (requires sorted_below n l) (ensures sorted_below n (remove_id k l) /\ not (mem_id k (remove_id k l)))
          (decreases l)
  = match l with
    | [] -> ()
    | x :: t ->
      lemma_remove k x.id t;
      if U32.eq x.id k then lemma_weaken x.id n t else ()

let rec lemma_toggle (k n:U32.t) (l:list item)
  : Lemma (requires sorted_below n l) (ensures sorted_below n (toggle_id k l)) (decreases l)
  = match l with [] -> () | x :: t -> lemma_toggle k x.id t

let rec lemma_drop (n:U32.t) (l:list item)
  : Lemma (requires sorted_below n l) (ensures sorted_below n (drop_checked l)) (decreases l)
  = match l with
    | [] -> ()
    | x :: t -> lemma_drop x.id t; if x.checked then lemma_weaken x.id n t else ()

(* ---------- validation du formulaire (réutilise Core) ---------- *)
let to_u8 (c:C.char) : U8.t = U8.uint_to_t (C.int_of_char c % 256)
let bytes_of (s:string) : list U8.t = map to_u8 (FStar.String.list_of_string s)

let submit_form (name age:string) : form_status =
  let nm = FStar.String.list_of_string name in
  let ok_name = Core.name_ok nm in
  match Core.parse_age (FStar.String.list_of_string age) with
  | Some a ->
    if ok_name then Accepted (name, a, Core.fnv (bytes_of name))
    else Rejected ["nom: 1 à 20 caractères imprimables"]
  | None ->
    if ok_name then Rejected ["âge: entier entre 0 et 150"]
    else Rejected ["nom: 1 à 20 caractères imprimables"; "âge: entier entre 0 et 150"]

(* ---------- update ---------- *)
let update (m:model{inv m}) (g:msg) : (m':model{inv m'}) =
  match g with
  | Inc -> if m.counter < 1000 then { m with counter = m.counter + 1 } else m
  | Dec -> if m.counter > -1000 then { m with counter = m.counter - 1 } else m
  | Reset -> { m with counter = 0 }
  | Goto t -> { m with tab = t }
  | AddItem ->
    if Core.name_ok (FStar.String.list_of_string m.draft) && U32.lt m.next_id 0xFFFFFFFEul then
      { m with items = { id = m.next_id; text = m.draft; checked = false } :: m.items;
               next_id = U32.add m.next_id 1ul; draft = "" }
    else m
  | Remove k -> lemma_remove k m.next_id m.items; { m with items = remove_id k m.items }
  | Toggle k -> lemma_toggle k m.next_id m.items; { m with items = toggle_id k m.items }
  | ClearChecked -> lemma_drop m.next_id m.items; { m with items = drop_checked m.items }
  | Typed (InNew, s)  -> { m with draft = s }
  | Typed (InName, s) -> { m with name = s; status = Editing }
  | Typed (InAge, s)  -> { m with age = s; status = Editing }
  | Submit -> { m with status = submit_form m.name m.age }

(* lemmes d'application *)
let lemma_inc_dec (m:model{inv m /\ m.counter < 1000})
  : Lemma ((update (update m Inc) Dec).counter == m.counter) = ()

let lemma_add_grows (m:model{inv m /\ Core.name_ok (FStar.String.list_of_string m.draft) /\ U32.v m.next_id < 0xFFFFFFFE})
  : Lemma (length (update m AddItem).items == length m.items + 1) = ()

let lemma_remove_gone (m:model{inv m}) (k:U32.t)
  : Lemma (not (mem_id k (update m (Remove k)).items)) = lemma_remove k m.next_id m.items

let lemma_accepted_valid (m:model{inv m})
  : Lemma (match (update m Submit).status with
           | Accepted (_, a, _) -> U32.v a <= 150
           | _ -> True) = ()

(* ---------- view : donnée pure ---------- *)
type view_tree =
  | VColumn of list view_tree
  | VRow of list view_tree
  | VHeading of string
  | VText of string
  | VButton of string & msg
  | VInput of input_tag & string & string        (* tag, valeur, indication *)
  | VCheck of string & bool & msg

let item_row (x:item) : view_tree =
  VRow [ VCheck (x.text, x.checked, Toggle x.id); VButton ("✕", Remove x.id) ]

let tab_bar (t:tab) : view_tree =
  let mark (s:string) (b:bool) : string = if b then "● " ^ s else s in
  VRow [ VButton (mark "Compteur" (TCounter? t), Goto TCounter);
         VButton (mark "Liste" (TItems? t), Goto TItems);
         VButton (mark "Formulaire" (TForm? t), Goto TForm) ]

let view_counter (m:model) : view_tree =
  VColumn [ VHeading "Compteur";
            VText ("Valeur : " ^ string_of_int m.counter);
            VRow [ VButton ("−", Dec); VButton ("+", Inc); VButton ("Reset", Reset) ] ]

let view_items (m:model) : view_tree =
  VColumn ([ VHeading "Liste";
             VRow [ VInput (InNew, m.draft, "nouvel élément"); VButton ("Ajouter", AddItem) ] ]
           @ map item_row m.items
           @ [ VButton ("Supprimer les cochés", ClearChecked) ])

let view_form (m:model) : view_tree =
  let st : list view_tree =
    match m.status with
    | Editing -> []
    | Rejected es -> map (fun (e:string) -> VText ("✗ " ^ e)) es
    | Accepted (n, a, h) ->
      [ VText ("✓ " ^ n ^ ", " ^ U32.to_string a ^ " ans, empreinte " ^ U32.to_string h) ] in
  VColumn ([ VHeading "Formulaire";
             VInput (InName, m.name, "nom");
             VInput (InAge, m.age, "âge");
             VButton ("Valider", Submit) ] @ st)

let view (m:model) : view_tree =
  VColumn [ tab_bar m.tab;
            (match m.tab with
             | TCounter -> view_counter m
             | TItems -> view_items m
             | TForm -> view_form m) ]

(* point d'entrée pour l'hôte : l'hôte ne fabrique jamais de msg lui-même *)
let msg_of_input (t:input_tag) (s:string) : msg = Typed (t, s)

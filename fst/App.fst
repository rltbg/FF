module App
(* Modèle MVU : Model, Msg, update (pure, avec invariant prouvé), view -> ViewTree (donnée). *)
module U32 = FStar.UInt32
module I32 = FStar.Int32
module Str = FStar.String
open FStar.List.Tot

type tab = | TCounter | TItems | TForm | TBig

type item = { id: U32.t; text: string; checked: bool }

type input_tag = | InNew | InName | InAge

type msg =
  | Inc | Dec | Reset
  | Goto of tab
  | AddItem | Remove of U32.t | Toggle of U32.t | ClearChecked
  | Typed of input_tag & string
  | Submit
  | Select of U32.t              (* ligne choisie dans la grande liste (source Big.src_rows) *)
  | HashText of U32.t            (* hacher le texte volumineux de cette source (généré par Big) : on ne garde que son condensé *)

type form_status =
  | Editing
  | Rejected of list string
  | Accepted of string & (a:U32.t{U32.v a <= 150}) & U32.t   (* nom, âge, empreinte FNV-1a *)

(* Grands volumes : les données (100 000 lignes, texte de 1 Mo) vivent côté hôte ; le modèle F* ne garde que
   des identifiants et un condensé. *)
let big_rows : U32.t = 100000ul   (* = Big.rows_count *)
let big_max_text : nat = 4000000   (* garde : taille maximale acceptée pour HashText (en unités UTF-16) *)

type digest = { text_id: U32.t; len: U32.t; fnv: U32.t }

type model = {
  tab: tab;
  counter: I32.t;        (* borné à [-1000, 1000] *)
  items: list item;       (* ids strictement décroissants, tous < next_id *)
  next_id: U32.t;
  draft: string;
  name: string;
  age: string;
  status: form_status;
  sel: option U32.t;        (* ligne sélectionnée, < big_rows *)
  digest: option digest;    (* condensé du dernier texte haché *)
}

(* ---------- invariants ---------- *)
let counter_ok (c:I32.t) : bool = I32.gte c (-1000l) && I32.lte c 1000l

let rec sorted_below (n:U32.t) (l:list item) : Tot bool (decreases l) =
  match l with
  | [] -> true
  | x :: t -> U32.lt x.id n && sorted_below x.id t

let sel_ok (s:option U32.t) : bool = match s with None -> true | Some i -> U32.lt i big_rows

let inv (m:model) : bool =
  counter_ok m.counter && sorted_below m.next_id m.items && U32.lt m.next_id 0xFFFFFFFFul && sel_ok m.sel

let init : (m:model{inv m}) =
  { tab = TCounter; counter = 0l; items = []; next_id = 0ul; draft = "";
    name = ""; age = ""; status = Editing; sel = None; digest = None }

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
let err_name = "nom : 1 à 20 caractères, sans caractère de contrôle"
let err_age  = "âge : entier décimal entre 0 et 150"

(* Empreinte = FNV-1a 32 bits de l'encodage UTF-8 du nom. *)
let submit_form (name age:string) : form_status =
  let ok_name = Core.name_ok (Str.list_of_string name) in
  match Core.parse_age (Str.list_of_string age) with
  | Some a ->
    if ok_name then (Core.lemma_name_ok_maxlen name; Accepted (name, a, Core.fnv_utf8 name))
    else Rejected [err_name]
  | None ->
    if ok_name then Rejected [err_age] else Rejected [err_name; err_age]

(* ---------- update ---------- *)
let update (m:model{inv m}) (g:msg) : (m':model{inv m'}) =
  match g with
  | Inc -> if I32.lt m.counter 1000l then { m with counter = I32.add m.counter 1l } else m
  | Dec -> if I32.gt m.counter (-1000l) then { m with counter = I32.sub m.counter 1l } else m
  | Reset -> { m with counter = 0l }
  | Goto t -> { m with tab = t }
  | AddItem ->
    if Core.name_ok (Str.list_of_string m.draft) && U32.lt m.next_id 0xFFFFFFFEul then
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
  | Select i -> if U32.lt i big_rows then { m with sel = Some i } else m
  | HashText id ->
    let s = Big.text_of id in
    let n = Str.length s in
    if n <= big_max_text then begin
      Core.lemma_len_maxlen s;
      { m with digest = Some { text_id = id; len = U32.uint_to_t n; fnv = Core.fnv_utf8 s } }
    end else m

(* lemmes d'application *)
let lemma_inc_dec (m:model{inv m /\ I32.v m.counter < 1000})
  : Lemma ((update (update m Inc) Dec).counter == m.counter) = ()

let lemma_add_grows (m:model{inv m /\ Core.name_ok (Str.list_of_string m.draft) /\ U32.v m.next_id < 0xFFFFFFFE})
  : Lemma (length (update m AddItem).items == length m.items + 1) = ()

let lemma_remove_gone (m:model{inv m}) (k:U32.t)
  : Lemma (not (mem_id k (update m (Remove k)).items)) = lemma_remove k m.next_id m.items

(* Accepté <=> nom valide et âge analysé ; l'empreinte est exactement FNV-1a(UTF-8(nom)). *)
let lemma_accepted_valid (m:model{inv m})
  : Lemma (match (update m Submit).status with
           | Accepted (n, a, h) ->
             n == m.name /\ Core.name_ok (Str.list_of_string n) /\
             Core.parse_age (Str.list_of_string m.age) == Some a /\ U32.v a <= 150 /\
             Str.maxlen n (pow2 30) /\ h == Core.fnv_utf8 n
           | Rejected _ ->
             ~(Core.name_ok (Str.list_of_string m.name)) \/ None? (Core.parse_age (Str.list_of_string m.age))
           | Editing -> False)
  = if Core.name_ok (Str.list_of_string m.name) then Core.lemma_name_ok_maxlen m.name

(* ---------- view : donnée pure ---------- *)
type view_tree =
  | VColumn of list view_tree
  | VRow of list view_tree
  | VHeading of string
  | VText of string
  | VButton of string & msg
  | VInput of input_tag & string & string        (* tag, valeur, indication *)
  | VCheck of string & bool & msg
  | VBigList of U32.t & U32.t & option U32.t   (* source Big, nombre de lignes, ligne sélectionnée : lignes demandées à la source *)
  | VBigText of U32.t & U32.t                  (* source Big d'un texte volumineux, nombre de lignes affichées *)

let item_row (x:item) : view_tree =
  VRow [ VCheck (x.text, x.checked, Toggle x.id); VButton ("✕", Remove x.id) ]

let tab_bar (t:tab) : view_tree =
  let mark (s:string) (b:bool) : string = if b then "● " ^ s else s in
  VRow [ VButton (mark "Compteur" (TCounter? t), Goto TCounter);
         VButton (mark "Liste" (TItems? t), Goto TItems);
         VButton (mark "Formulaire" (TForm? t), Goto TForm);
         VButton (mark "Volumes" (TBig? t), Goto TBig) ]

let view_counter (m:model) : view_tree =
  VColumn [ VHeading "Compteur";
            VText ("Valeur : " ^ I32.to_string m.counter);
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

let view_big (m:model) : view_tree =
  let sel_txt =
    match m.sel with
    | None -> "Aucune ligne sélectionnée"
    | Some i -> "Ligne sélectionnée : " ^ U32.to_string i in
  let dig_txt =
    match m.digest with
    | None -> "Texte non haché"
    | Some d -> "Texte " ^ U32.to_string d.text_id ^ " : " ^ U32.to_string d.len ^ " caractères, FNV-1a "
                ^ U32.to_string d.fnv in
  VColumn [ VHeading "Gros volumes";
            VText sel_txt;
            VBigList (Big.src_rows, big_rows, m.sel);
            VBigText (Big.src_text, U32.uint_to_t Big.text_lines);
            VText dig_txt ]

let view (m:model) : view_tree =
  VColumn [ tab_bar m.tab;
            (match m.tab with
             | TCounter -> view_counter m
             | TItems -> view_items m
             | TForm -> view_form m
             | TBig -> view_big m) ]

(* point d'entrée pour l'hôte : l'hôte ne fabrique jamais de msg lui-même *)
let msg_of_input (t:input_tag) (s:string) : msg = Typed (t, s)

(* fabriques de messages pour l'hôte (il ne construit jamais un msg lui-même) *)
let msg_of_select (i:U32.t) : msg = Select i
let msg_of_hash (id:U32.t) : msg = HashText id

(* ---------- lemmes des grands volumes ---------- *)
let lemma_select (m:model{inv m}) (i:U32.t)
  : Lemma (U32.v i < U32.v big_rows ==> (update m (Select i)).sel == Some i /\ (update m (Select i)).items == m.items)
  = ()

let lemma_select_out_of_range (m:model{inv m}) (i:U32.t{U32.v i >= U32.v big_rows})
  : Lemma (update m (Select i) == m)
  = ()

(* HashText : le condensé est exactement (longueur, FNV-1a de l'UTF-8) du texte généré par Big, et seulement s'il n'est pas trop long. *)
let lemma_hash_text (m:model{inv m}) (id:U32.t)
  : Lemma (let s = Big.text_of id in
           let n = Str.length s in
           if n <= big_max_text
           then (update m (HashText id)).digest ==
                  Some ({ text_id = id; len = U32.uint_to_t n; fnv = Core.fnv_utf8 s })
           else update m (HashText id) == m)
  = if Str.length (Big.text_of id) <= big_max_text then Core.lemma_len_maxlen (Big.text_of id)

(* Les deux constantes du nombre de lignes de la grande liste coïncident. *)
let lemma_big_rows () : Lemma (U32.v big_rows == Big.rows_count) = assert_norm (U32.v big_rows == Big.rows_count)

(* ---------- journal de test et préchargement : produits par F* (l'hôte ne formate rien) ---------- *)
let show_tab (t:tab) : string =
  match t with TCounter -> "counter" | TItems -> "items" | TForm -> "form" | TBig -> "big"

let show_item (x:item) : string = x.text ^ (if x.checked then "[x]" else "[ ]")

let show_status (s:form_status) : string =
  match s with
  | Editing -> "editing"
  | Rejected es -> "rejected:" ^ Str.concat "|" es
  | Accepted (n, a, h) -> "accepted:" ^ n ^ "," ^ U32.to_string a ^ "," ^ U32.to_string h

(* Résumé du modèle sur une ligne (MVU_TRACE) : c'est ce que lisent les tests de fumée de l'interface. *)
let show_model (m:model) : string =
  "tab=" ^ show_tab m.tab ^ " counter=" ^ I32.to_string m.counter
  ^ " items=" ^ Str.concat "," (map show_item m.items) ^ " draft=" ^ m.draft
  ^ " name=" ^ m.name ^ " age=" ^ m.age ^ " status=" ^ show_status m.status
  ^ " sel=" ^ (match m.sel with Some i -> U32.to_string i | None -> "-")
  ^ " digest=" ^ (match m.digest with
                  | Some d -> U32.to_string d.text_id ^ "," ^ U32.to_string d.len ^ "," ^ U32.to_string d.fnv
                  | None -> "-")

(* Messages qui ajoutent n éléments « item 1 » .. « item n » (test de charge : MVU_PRELOAD=n), dans cet ordre. *)
let rec preload_acc (n:nat) (acc:list msg) : Tot (list msg) (decreases n) =
  if n = 0 then acc
  else preload_acc (n - 1) (Typed (InNew, "item " ^ string_of_int n) :: AddItem :: acc)
let preload_msgs (n:nat) : list msg = preload_acc n []

module Big
(* Sources de données volumineuses, GÉNÉRÉES À LA DEMANDE par F* (rien n'est stocké : ni dans le modèle, ni dans l'hôte).
   Source 0 : les 100 000 lignes de la grande liste. Source 1 : les 38 000 lignes d'un texte d'environ 1 Mo.
   L'hôte (liste virtualisée) ne demande que les lignes affichées ; F* reconstruit tout le texte pour le hacher. *)
module U32 = FStar.UInt32
module S   = FStar.String
module C   = FStar.Char

let src_rows : U32.t = 0ul
let src_text : U32.t = 1ul
let rows_count : nat = 100000
let text_lines : nat = 38000

(* ---- écriture décimale sur 6 chiffres (n mod 10^6), et analyse réciproque ---- *)
let digit (n:nat) : C.char = C.char_of_int (48 + n % 10)

let pad6 (n:nat) : string =
  S.string_of_list [ digit (n / 100000); digit (n / 10000); digit (n / 1000); digit (n / 100); digit (n / 10); digit n ]

let rec parse_dec (acc:nat) (l:list C.char) : Tot (option nat) (decreases l) =
  match l with
  | [] -> Some acc
  | c :: t -> if Core.is_digit c then parse_dec (10 * acc + (C.int_of_char c - 48)) t else None

(* ---- source 0 : "Ligne 000042 — donnée côté hôte" ---- *)
let row (i:nat) : string = "Ligne " ^ pad6 i ^ " — donnée côté hôte"

(* Indice d'une ligne, ou -1 si la chaîne n'est pas exactement [row n] avec n < rows_count. Correct par construction :
   on ne renvoie n que si [row n = s]. *)
let row_index (s:string) : int =
  match S.list_of_string s with
  | 'L' :: 'i' :: 'g' :: 'n' :: 'e' :: ' ' :: d5 :: d4 :: d3 :: d2 :: d1 :: d0 :: _ ->
    (match parse_dec 0 [d5; d4; d3; d2; d1; d0] with
     | Some n -> if n < rows_count && row n = s then n else -1
     | None -> -1)
  | _ -> -1

(* ---- source 1 : "Texte 000042 — éàü 42" ---- *)
let line (i:nat) : string = "Texte " ^ pad6 i ^ " — éàü " ^ string_of_int (i % 97)

let line_index (s:string) : int =
  match S.list_of_string s with
  | 'T' :: 'e' :: 'x' :: 't' :: 'e' :: ' ' :: d5 :: d4 :: d3 :: d2 :: d1 :: d0 :: _ ->
    (match parse_dec 0 [d5; d4; d3; d2; d1; d0] with
     | Some n -> if n < text_lines && line n = s then n else -1
     | None -> -1)
  | _ -> -1

(* Le texte complet : text_lines lignes, chacune terminée par '\n'. Construit en accumulant (récursion terminale). *)
let rec text_acc (i:nat) (acc:list string) : Tot (list string) (decreases i) =
  if i = 0 then acc else text_acc (i - 1) ((line (i - 1) ^ "\n") :: acc)

let text_of (src:U32.t) : string =
  if U32.eq src src_text then S.concat "" (text_acc text_lines []) else ""

(* ---- interface avec l'hôte : tout passe par un numéro de source ---- *)
let item (src:U32.t) (i:nat) : string =
  if U32.eq src src_rows then row i else if U32.eq src src_text then line i else ""

let index_of (src:U32.t) (s:string) : int =
  if U32.eq src src_rows then row_index s else if U32.eq src src_text then line_index s else -1

(* ---- propriétés ---- *)
(* Correction : un indice renvoyé désigne bien la chaîne demandée. *)
let lemma_row_index_sound (s:string) : Lemma (row_index s >= 0 ==> (row_index s < rows_count /\ row (row_index s) = s)) = ()
let lemma_line_index_sound (s:string) : Lemma (line_index s >= 0 ==> (line_index s < text_lines /\ line (line_index s) = s)) = ()

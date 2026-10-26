module CharCodeFails
(* Reproduction minimale de l'Error 395 : F* 2026.10.25, --codegen FSharp.
   Se vérifie sans problème ; échoue seulement à l'extraction. *)
let f (c:FStar.Char.char) : FStar.UInt32.t = FStar.Char.u32_of_char c
let main () : FStar.All.ML unit = FStar.IO.print_string (FStar.UInt32.to_string (f 'A'))

module TIO
(* FStar.IO (impressions) et FStar.All (failwith, try_with, pipe_right, pipe_left, exit). Les impressions écrivent sur la sortie
   standard : scripts/ftests.sh compare le bloc IO-BEGIN..IO-END à ftests/IO.expected, dont le contenu vient de la réalisation OCaml
   de référence (ulib/FStar.IO-ocaml.fst + tests/machine_integers/TestPrint.out.expected) : hexadécimal « 0x.. » sans remplissage,
   remplissage décimal sur 3/5/10/20 chiffres. *)
open FStar.All
open TUtil
open FStar.IO
module U8  = FStar.UInt8
module U16 = FStar.UInt16
module U32 = FStar.UInt32
module U64 = FStar.UInt64

let line (f:unit -> ML unit) : ML unit = f (); print_newline ()

let print_all () : ML unit =
  print_string "IO-BEGIN\n";
  print_string (blur "chaîne é€\n");
  (* hexadécimal *)
  line (fun () -> print_uint8 (blur 0uy)); line (fun () -> print_uint8 (blur 15uy)); line (fun () -> print_uint8 (blur 255uy));
  line (fun () -> print_uint16 (blur 0us)); line (fun () -> print_uint16 (blur 15us)); line (fun () -> print_uint16 (blur 65535us));
  line (fun () -> print_uint32 (blur 0ul)); line (fun () -> print_uint32 (blur 15ul)); line (fun () -> print_uint32 (blur 4294967295ul));
  line (fun () -> print_uint64 (blur 0uL)); line (fun () -> print_uint64 (blur 15uL)); line (fun () -> print_uint64 (blur 18446744073709551615uL));
  (* décimal *)
  line (fun () -> print_uint8_dec (blur 0uy)); line (fun () -> print_uint8_dec (blur 15uy)); line (fun () -> print_uint8_dec (blur 255uy));
  line (fun () -> print_uint16_dec (blur 0us)); line (fun () -> print_uint16_dec (blur 15us)); line (fun () -> print_uint16_dec (blur 65535us));
  line (fun () -> print_uint32_dec (blur 0ul)); line (fun () -> print_uint32_dec (blur 15ul)); line (fun () -> print_uint32_dec (blur 4294967295ul));
  line (fun () -> print_uint64_dec (blur 0uL)); line (fun () -> print_uint64_dec (blur 15uL)); line (fun () -> print_uint64_dec (blur 18446744073709551615uL));
  (* print_uintN_hex_pad : divergence de la réalisation F# (préfixe 0x), voir docs/matrix/Mx34_PrintHexPad.fst *)
  (* décimal rempli *)
  line (fun () -> print_uint8_dec_pad (blur 0uy)); line (fun () -> print_uint8_dec_pad (blur 15uy)); line (fun () -> print_uint8_dec_pad (blur 255uy));
  line (fun () -> print_uint16_dec_pad (blur 0us)); line (fun () -> print_uint16_dec_pad (blur 15us)); line (fun () -> print_uint16_dec_pad (blur 65535us));
  line (fun () -> print_uint32_dec_pad (blur 0ul)); line (fun () -> print_uint32_dec_pad (blur 15ul)); line (fun () -> print_uint32_dec_pad (blur 4294967295ul));
  line (fun () -> print_uint64_dec_pad (blur 0uL)); line (fun () -> print_uint64_dec_pad (blur 15uL)); line (fun () -> print_uint64_dec_pad (blur 18446744073709551615uL));
  print_string "IO-END\n"

let test_all () : ML unit =
  (* try_with : l'exception de failwith est interceptée, le gestionnaire reçoit l'exception *)
  check "try_with : pas d'exception" (try_with (fun () -> 1 + blur 1) (fun _ -> 0) = 2);
  check "try_with : failwith intercepté" (try_with (fun () -> if blur true then failwith "boom" else 1) (fun _ -> 42) = 42);
  check "try_with : exception imbriquée" (try_with (fun () -> try_with (fun () -> failwith "a") (fun _ -> failwith "b")) (fun _ -> 7) = 7);
  check "pipe_right" ((blur 3 |> (fun x -> x * 2)) = 6);
  check "pipe_left" ((fun x -> x + 1) <| blur 4 = 5);
  check "pipe_right enchaîné" ((blur [1; 2; 3] |> FStar.List.Tot.map (fun x -> x + 1) |> FStar.List.Tot.length) = 3)

let main () : ML unit = print_all (); test_all ()

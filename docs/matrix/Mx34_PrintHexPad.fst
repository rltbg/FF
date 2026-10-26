module Mx34_PrintHexPad
(* FStar.IO.print_uintN_hex_pad : la réalisation OCaml de référence (ulib/FStar.IO-ocaml.fst) imprime to_string_hex_pad, c'est-à-dire
   le remplissage hexadécimal SANS préfixe « 0x » (FStar.UInt8.fsti : left-padded with zeroes, no leading 0x ; tests/machine_integers/
   TestPrint.out.expected : 00 0f ff). Le F# de support (FStarCustard.fs, hexpad) imprime « 0x00 0x0f 0xff ».
   La sortie attendue de référence est dans Mx34_PrintHexPad.expected. *)
open MxUtil
open FStar.IO
let line (f:unit -> FStar.All.ML unit) : FStar.All.ML unit = f (); print_newline ()
let main () : FStar.All.ML unit =
  line (fun () -> print_uint8_hex_pad (blur 0uy)); line (fun () -> print_uint8_hex_pad (blur 15uy)); line (fun () -> print_uint8_hex_pad (blur 255uy));
  line (fun () -> print_uint16_hex_pad (blur 15us)); line (fun () -> print_uint32_hex_pad (blur 15ul)); line (fun () -> print_uint64_hex_pad (blur 15uL));
  FStar.IO.print_string "OK\n"

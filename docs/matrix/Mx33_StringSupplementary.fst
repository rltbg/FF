module Mx33_StringSupplementary
(* Point hors BMP (U+1F642) : F* compte une chaîne en points de code (length du littéral = 1, normaliseur de F étoile),
   .NET en unités UTF-16 (2). Une preuve sur strlen/length est donc fausse à l'exécution pour ces chaînes.
   Voir docs/UPSTREAM-FSTAR.md §5 (char_of_u32 tronque) et custard.md §122 (compromis UTF-16). *)
open MxUtil
module S = FStar.String
let sem () : Lemma (S.length "🙂" = 1) = assert_norm (S.length "🙂" = 1)
let main () : FStar.All.ML unit =
  let s = blur "🙂" in
  check (S.length s = 1);
  FStar.IO.print_string "OK\n"

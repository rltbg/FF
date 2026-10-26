module TFloat
(* FStar.Float32 / FStar.Float64 (types opaques en F*, flottants IEEE .NET en F#) : arithmétique et comparaisons sur des
   valeurs dont le résultat IEEE est connu exactement (puissances de 2, valeurs représentables), NaN et infinis, zéros signés,
   arrondi de of_int. Les littéraux passent par of_literal (chaîne constante exigée par Custard). Rien n'est prouvé en F*
   (opaque) : les attendus viennent du standard IEEE 754. *)
open FStar.All
open TUtil
module F32 = FStar.Float32
module F64 = FStar.Float64

let test64 () : ML unit =
  let one = F64.of_literal "1.0" in let two = F64.of_literal "2.0" in
  let half = F64.of_literal "0.5" in let zero = F64.of_literal "0.0" in
  let nan = F64.of_literal "nan" in let inf = F64.of_literal "inf" in let ninf = F64.of_literal "-inf" in
  let one = blur one in let two = blur two in let half = blur half in let zero = blur zero in
  let nan = blur nan in let inf = blur inf in let ninf = blur ninf in
  check "f64 add" (F64.ieee_eq (F64.add one two) (F64.of_literal "3.0"));
  check "f64 sub" (F64.ieee_eq (F64.sub one two) (F64.of_literal "-1.0"));
  check "f64 mul" (F64.ieee_eq (F64.mul two half) one);
  check "f64 div" (F64.ieee_eq (F64.div one two) half);
  check "f64 div par 0 = inf" (F64.ieee_eq (F64.div one zero) inf);
  check "f64 -1/0 = -inf" (F64.ieee_eq (F64.div (F64.of_literal "-1.0") zero) ninf);
  check "f64 inf - inf = nan" (not (F64.ieee_eq (F64.sub inf inf) (F64.sub inf inf)));
  check "f64 lt/lte" (F64.lt half one && F64.lte half one && F64.lte one one && not (F64.lt one one) && not (F64.lt two one));
  check "f64 nan ne tout" (not (F64.ieee_eq nan nan) && not (F64.lt nan one) && not (F64.lte nan nan) && not (F64.lt one nan));
  check "f64 ieee_eq" (F64.ieee_eq one one && not (F64.ieee_eq one two));
  check "f64 inf compare" (F64.lt one inf && F64.lt ninf one && F64.ieee_eq inf inf);
  (* 0.1 + 0.2 <> 0.3 en binaire ; 0.1 + 0.2 = 0.30000000000000004 *)
  check "f64 0.1+0.2" (not (F64.ieee_eq (F64.add (F64.of_literal "0.1") (F64.of_literal "0.2")) (F64.of_literal "0.3"))
                       && F64.ieee_eq (F64.add (F64.of_literal "0.1") (F64.of_literal "0.2")) (F64.of_literal "0.30000000000000004"));
  (* zéros signés : égaux au sens IEEE, distincts bit à bit *)
  let nz = F64.of_literal "-0.0" in
  check "f64 -0 == +0" (F64.ieee_eq (blur nz) zero);
  (* bit_eq, to_string : non extractibles (Mx43, Mx44) *)
  (* of_int : exact jusqu'à 2^53, arrondi au-delà *)
  check "f64 of_int exact" (F64.ieee_eq (F64.of_int (blur 9007199254740992L)) (F64.of_literal "9007199254740992.0"));
  check "f64 of_int arrondi" (F64.ieee_eq (F64.of_int (blur 9007199254740993L)) (F64.of_literal "9007199254740992.0"));
  check "f64 of_int négatif" (F64.ieee_eq (F64.of_int (blur (-5L))) (F64.of_literal "-5.0"));
  check "f64 zero/one" (F64.ieee_eq F64.zero zero && F64.ieee_eq F64.one one)

let test32 () : ML unit =
  let one = blur (F32.of_literal "1.0") in let two = blur (F32.of_literal "2.0") in
  let zero = blur (F32.of_literal "0.0") in let inf = blur (F32.of_literal "inf") in
  check "f32 add" (F32.ieee_eq (F32.add one two) (F32.of_literal "3.0"));
  check "f32 sub/mul/div" (F32.ieee_eq (F32.sub one two) (F32.of_literal "-1.0") && F32.ieee_eq (F32.mul two two) (F32.of_literal "4.0")
                           && F32.ieee_eq (F32.div one two) (F32.of_literal "0.5"));
  check "f32 lt/lte" (F32.lt one two && F32.lte one one && not (F32.lt two one));
  check "f32 inf" (F32.ieee_eq (F32.div one zero) inf);
  (* précision simple : 0.1f + 0.2f = 0.3f (en double ce ne serait pas égal) ; 16777216 + 1 = 16777216 *)
  check "f32 0.1+0.2" (F32.ieee_eq (F32.add (F32.of_literal "0.1") (F32.of_literal "0.2")) (F32.of_literal "0.3"));
  check "f32 2^24 + 1" (F32.ieee_eq (F32.add (blur (F32.of_literal "16777216.0")) one) (F32.of_literal "16777216.0"));
  check "f32 of_int arrondi" (F32.ieee_eq (F32.of_int (blur 16777217L)) (F32.of_literal "16777216.0"));
  check "f32 zero/one" (F32.ieee_eq F32.zero zero && F32.ieee_eq F32.one one)

let main () : ML unit = test64 (); test32 ()

module PhantomTypeParam
(* Reproduction (extraction en bibliothèque : --custard_entry_module PhantomTypeParam, pas --custard_main).
   Abréviation de type dont un paramètre n'apparaît pas dans le corps : Custard écrit `type phantomTypeParam_tagged<'a> = bigint`,
   que F# 10 refuse (FS0035 : « Type abbreviations must use all declared type parameters »). Même défaut sur 7 modules d'ulib
   (FStar.Fin, FStar.Functions, FStar.Injection, FStar.IntegerIntervals, FStar.Seq.Permutation, FStar.Sequence.Permutation,
   FStar.Tactics.CanonCommSwaps). Sous --custard_main le type est inliné et le défaut ne se voit pas. *)
type tagged (a:Type) = int

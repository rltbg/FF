module TMain
(* Point d'entrée de la suite de tests, extraite avec --custard_main. Aucun test n'est écrit en F#. *)
open FStar.All
let main () : ML unit =
  TCore.main ();
  TBig.main ();
  TApp.main ();
  TList.main ();
  TString.main ();
  TBytes.main ();
  TIO.main ();
  TUlib.run ();
  TFloat.main ();
  TMachine.run ();
  TUtil.report ();
  FStar.All.exit (if !TUtil.fails <> 0 then 1 else 0)

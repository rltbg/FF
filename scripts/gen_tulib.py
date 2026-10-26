#!/usr/bin/env python3
"""Génère ftests/TUlib.fst à partir de ftests/ulib_cases.py : cas « double oracle ».
Chaque cas est un prédicat total c_<id> (paramètres typés, corps = assertion booléenne sur des fonctions d'ulib).
 - À la vérification, F* le PROUVE sur les valeurs littérales (assert_norm : sémantique du normaliseur de F*, la référence).
 - À l'exécution, le F# extrait l'évalue sur les mêmes valeurs passées par un effet (blur) : un écart = défaut d'extraction ou
   de réalisation (le normaliseur et le F# divergent).
Le fichier produit est du F* commité ; ce script n'est qu'un outil de production de texte.
usage : gen_tulib.py ftests/ulib_cases.py > ftests/TUlib.fst"""
import sys, importlib.util
spec = importlib.util.spec_from_file_location("cases", sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
out = []
w = out.append
w("module TUlib\n(* GÉNÉRÉ par scripts/gen_tulib.py depuis ftests/ulib_cases.py. Ne pas éditer à la main. *)\nopen FStar.All\nopen TUtil\n")
for line in m.PRELUDE.strip("\n").split("\n"): w(line)
w("")
n = 0
runs = []
for case in m.CASES:
    cid, params, body = case[:3]
    norm = not (len(case) > 3 and case[3] == "nonorm")
    n += 1
    ps = "".join(f" ({p}:{t})" for (p, t, _) in params)
    w(f"let c_{cid}{ps} : bool = {body}")
    lits = " ".join(f"({l})" for (_, _, l) in params)
    if norm: w(f"let _ = assert_norm (c_{cid} {lits})")
    else: w(f"(* {cid} : pas d'oracle assert_norm (fonctions axiomatisées, sans définition réductible) : valeurs attendues écrites d'après le contrat *)")
    args = " ".join(f"(blur #({t}) ({l}))" for (_, t, l) in params)
    runs.append(f'  check "{cid}" (c_{cid} {args});')
w("\nlet run () : ML unit =")
w("\n".join(runs))
w("  ()")
print("\n".join(out))
sys.stderr.write(f"{n} cas\n")

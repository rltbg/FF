#!/usr/bin/env python3
"""Couverture des réalisations Custard (supported_realizations de PrintFSharp.fst) par la suite de tests F*.

Principe : le F# généré pour la suite (out/ftests/fs/TMain.fs) appelle chaque réalisation par son nom F# ; une réalisation
est « exercée » si son nom F# y figure. Les opérateurs Prims.* sont compilés en opérateurs .NET natifs (pas d'appel nommé) :
ils sont couverts par TString.test_prims (liste PRIMS_OPS ci-dessous, vérifiée à la main). Les alias (deux noms F* pour un même
nom F#) sont signalés « alias ». Sortie : tableau Markdown sur la sortie standard, code retour 1 si une réalisation n'est pas exercée
et n'est pas déclarée bloquée.
usage : coverage_realizations.py <PrintFSharp.fst> <TMain.fs>"""
import re, sys
src = open(sys.argv[1]).read()
gen = open(sys.argv[2]).read()
body = src[src.index("let supported_realizations"):src.index("let supported_realization (n:name)")]
pairs = re.findall(r'"([A-Za-z0-9_.]+)"\s*,\s*"([A-Za-z0-9_.]+)"', body)

# Opérateurs de Prims compilés en natif : testés dans TString.test_prims
PRIMS_NATIVE = {"Prims.op_Plus", "Prims.op_Minus", "Prims.op_Star", "Prims.op_Slash", "Prims.op_Percent",
                "Prims.op_Less", "Prims.op_Less_Equals", "Prims.op_Greater", "Prims.op_Greater_Equals"}
# Réalisations connues non exercées, avec la raison (voir docs/ULIB-COUVERTURE.md et docs/UPSTREAM-FSTAR.md)
BLOCKED = {
 "Prims.op_Minus_Minus": "négation unaire : non atteignable depuis F* (op_Tilde_Minus non réalisé, Mx26)",
 "Prims.abs": "Error 395 op_Tilde_Minus dans la définition F* (Mx27)",
 "FStar.Char.u32_of_char": "Error 395 char_code (docs/FSTAR-char_code.md)",
 "FStar.Char.char_of_u32": "Error 395 char_code",
 "FStar.String.strcat": "non déclaré dans FStar.String.fsti (inaccessible)",
 "FStar.String.op_Hat": "non déclaré dans FStar.String.fsti (inaccessible)",
 "FStar.List.Tot.Base.list_refb": "le F# généré ne compile pas (Mx29)",
 "FStar.IO.print_uint8_hex_pad": "divergence : préfixe 0x (Mx34), comportement observé mais pas conforme",
 "FStar.IO.print_uint16_hex_pad": "idem (Mx34)", "FStar.IO.print_uint32_hex_pad": "idem (Mx34)", "FStar.IO.print_uint64_hex_pad": "idem (Mx34)",
 "FStar.IO.debug_print_string": "pas de contrat (« toujours false », impression de débogage)",
 "FStar.List.Tot.Base.bool_of_compare": "signe inversé dans la réalisation (Mx31) : exercée par la matrice, pas par la suite",
 "FStar.List.Tot.Base.compare_of_bool": "signes inversés dans la réalisation (Mx32) : exercée par la matrice, pas par la suite",
}
# Réalisations que Custard ne laisse pas en appel nommé : (motif cherché dans le F# généré, explication)
INLINED = {
 "Prims.pow2": (r"prims_pow2", "compilé depuis sa définition F* (prims_pow2) : la réalisation F# n'est pas utilisée"),
 "FStar.All.try_with": (r"\(try ", "compilé en try..with natif"),
 "FStar.All.pipe_right": (r"FStar_List_Tot_Base\.length \(FStar_List_Tot_Base\.map", "compilé en application directe"),
 "FStar.All.pipe_left": (r"\(fun \(x", "compilé en application directe"),
}
# Éliminées à l'extraction (identité) : aucun appel dans le F# généré
ELIDED = {
 "FStar.List.Tot.Base.list_unref": "identité : l'appel disparaît du F# généré (le test ne peut pas distinguer)",
 "FStar.List.Tot.Base.list_ref": "identité : l'appel disparaît du F# généré",
}
rows, bad = [], 0
seen = {}
for fs_name, fsharp in pairs:
    seen.setdefault(fsharp, []).append(fs_name)
for fs_name, fsharp in pairs:
    used = re.search(r'(?<![A-Za-z0-9_.])' + re.escape(fsharp) + r'(?![A-Za-z0-9_])', gen) is not None
    alias = len(seen[fsharp]) > 1
    if fs_name in PRIMS_NATIVE: st = "natif (TString.test_prims)"
    elif fs_name in INLINED and re.search(INLINED[fs_name][0], gen): st = "exercé, " + INLINED[fs_name][1]
    elif fs_name in ELIDED: st = "éliminé : " + ELIDED[fs_name]
    elif fs_name in BLOCKED and not used: st = "bloqué : " + BLOCKED[fs_name]
    elif used: st = "exercé" + (" (alias de " + ", ".join(x for x in seen[fsharp] if x != fs_name) + ")" if alias else "")
    elif alias and any(re.search(r'(?<![A-Za-z0-9_.])' + re.escape(fsharp) + r'(?![A-Za-z0-9_])', gen) for _ in [0]): st = "exercé (alias)"
    else: st = "NON EXERCÉ"; bad += 1
    rows.append((fs_name, fsharp, st))
tot = len(rows); ex = sum(1 for r in rows if r[2].startswith(("exercé", "natif")))
bl = sum(1 for r in rows if r[2].startswith(("bloqué", "éliminé")))
print(f"# Couverture des réalisations Custard par la suite F*\n")
print(f"{tot} réalisations déclarées ; {ex} exercées par la suite ; {bl} bloquées ou éliminées (raison dans le tableau) ; {tot-ex-bl} non exercées.\n")
print("| Nom F* | Réalisation F# | État |\n|---|---|---|")
for r in rows: print(f"| `{r[0]}` | `{r[1]}` | {r[2]} |")
sys.exit(1 if bad else 0)

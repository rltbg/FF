#!/usr/bin/env python3
"""Couverture d'ulib par la suite de tests F*.
Entrées : le résultat de scripts/ulib_sweep.sh (logs/ulib_sweep.tsv + logs/ulib/<module>/o/<module>.fs) et le F# généré de la suite
(out/ftests/fs/TMain.fs). Pour chaque module d'ulib dont l'extraction en bibliothèque réussit (OK), on liste ses définitions F#
(let/let rec/and de préfixe <module>_) et on regarde lesquelles sont ATTEINTES par le programme de test, c'est-à-dire présentes dans
le F# généré de la suite : Custard n'émet que ce qui est accessible depuis les racines, donc « présent » = appelé par un test ou par
une fonction appelée par un test (mesure d'atteignabilité, plus faible qu'un test dédié par fonction), ou référencée par son nom dans les sources F* des tests.
Sortie : Markdown sur la sortie standard."""
import re, os, sys
root = sys.argv[1] if len(sys.argv) > 1 else "."
gen = open(f"{root}/out/ftests/fs/TMain.fs").read()
# Sources F* des tests : un identifiant ulib est aussi « référencé » s'il apparaît sous la forme Alias.nom ou Module.nom
# dans ftests/*.fst ou dans la table ftests/ulib_cases.py (les fonctions marquées inline_for_extraction ou résolues par classes
# de types disparaissent du F# généré sans avoir pu être ignorées par les tests).
import glob
srcs = ""
for f in glob.glob(f"{root}/ftests/*.fst") + [f"{root}/ftests/ulib_cases.py"]:
    srcs += open(f).read() + "\n"
aliases = {}
for a, m_ in re.findall(r"module\s+(\w+)\s*=\s*([A-Za-z0-9_.]+)", srcs): aliases.setdefault(m_, set()).add(a)
def referenced(modname, fname):
    pats = [modname + "." + fname] + [a + "." + fname for a in aliases.get(modname, ())]
    return any(re.search(r"(?<![A-Za-z0-9_.])" + re.escape(p) + r"(?![A-Za-z0-9_'])", srcs) for p in pats)
def mangle(m): return m.replace(".", "_").replace("-", "_")
rows = [l.rstrip("\n").split("\t") for l in open(f"{root}/logs/ulib_sweep.tsv")]
status = {r[0]: r for r in rows}
by = {}
for r in rows: by.setdefault(r[1], []).append(r[0])
tot_def = tot_cov = 0
lines = []
for m in sorted(by.get("OK", [])):
    path = f"{root}/logs/ulib/{m}/o/{m}.fs"
    if not os.path.exists(path): continue
    src = open(path).read()
    pre = mangle(m[0].lower() + m[1:]) + "_" if m != "Prims" else "prims_"
    pre = pre[0].lower() + pre[1:]
    names = []
    for mo in re.finditer(r"^(?:let rec|let|and)\s+([A-Za-z0-9_']+)", src, re.M):
        n = mo.group(1)
        if n.startswith(pre) and n not in names: names.append(n)
    if not names: continue
    def short(n): return n[len(pre):]
    cov = [n for n in names if re.search(r"(?<![A-Za-z0-9_'])" + re.escape(n) + r"(?![A-Za-z0-9_'])", gen) or referenced(m, short(n))]
    tot_def += len(names); tot_cov += len(cov)
    lines.append((m, len(names), len(cov), [n for n in names if n not in cov]))
print("# Couverture d'ulib par la suite de tests F*\n")
cnt = {k: len(v) for k, v in by.items()}
print(f"Balayage de {sum(cnt.values())} modules d'ulib (`scripts/ulib_sweep.sh`, extraction en bibliothèque + compilation F#) : "
      + ", ".join(f"{k} {v}" for k, v in sorted(cnt.items())) + ".\n")
print("- **OK** : le module s'extrait et le F# compile ; **VIDE** : rien d'exécutable (spécifications, lemmes, types) ; **EXTRACT** : erreur de Custard "
      "(histogramme dans `docs/ULIB-COUVERTURE.md`) ; **BUILD** : le F# généré ne compile pas.\n")
print(f"Parmi les modules OK, définitions exécutables atteintes par la suite : **{tot_cov} sur {tot_def}**"
      f" ({100*tot_cov//max(tot_def,1)} %). « Atteinte » = présente dans le F# généré du programme de test (voir l'en-tête de `scripts/coverage_ulib.py`).\n")
# histogramme des causes d'échec d'extraction
def cause(msg):
    m = re.search(r"the type (\S+) is realized", msg)
    if m: return "type sans réalisation F# : " + m.group(1)
    m = re.search(r"Custard: (\S+) has no F\* definition", msg)
    if m:
        n = m.group(1)
        if re.match(r"FStar\.(U?Int\d+|SizeT)\.v$", n): return "`v` d'un entier machine (fonction de spécification appelée dans du code exécutable)"
        return "fonction sans définition ni réalisation F# : " + n
    if "Error 238" in msg: return "greffon de tactique (Error 238)"
    if "Error 364" in msg: return "Error 364 (argument d'un binder monomorphisé)"
    if "Error 379" in msg: return "Error 379"
    if "Universe variable" in msg: return "échec interne (Universe variable not found)"
    if "Warning 382" in msg: return "Warning 382 (paramètre effacé d'un externe)"
    return msg[:90]
hist = {}
for r in rows:
    if r[1] == "EXTRACT":
        hist.setdefault(cause(r[3] if len(r) > 3 else ""), []).append(r[0])
print("## Causes d'échec d'extraction (modules EXTRACT)\n")
print("| Cause | Modules | Exemples |\n|---|---|---|")
for k, v in sorted(hist.items(), key=lambda kv: -len(kv[1])):
    print(f"| {k} | {len(v)} | {', '.join(sorted(v)[:4])}{' …' if len(v) > 4 else ''} |")
print("\nModules BUILD (le F# généré ne compile pas) : " + ", ".join(sorted(by.get('BUILD', []))) + " — `FS0035` (paramètre de type fantôme, `docs/UPSTREAM-FSTAR.md` §14).\n")
print("## Détail par module OK\n")
print("| Module | Définitions | Atteintes | Non atteintes |\n|---|---|---|---|")
for m, n, c, miss in lines:
    ms = ", ".join(x.replace(mangle(m[0].lower()+m[1:]) + "_", "") for x in miss[:12]) + (" …" if len(miss) > 12 else "")
    print(f"| `{m}` | {n} | {c} | {ms} |")

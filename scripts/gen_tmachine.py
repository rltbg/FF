#!/usr/bin/env python3
"""Génère ftests/TMachine.fst : une instance du harnais TMachineLib par largeur d'entier machine (et les casts de
FStar.Int.Cast). Le résultat est du F* (commité) ; ce script n'est qu'un outil de production de texte.
usage : gen_tmachine.py <ulib> > ftests/TMachine.fst"""
import re, sys
ulib = sys.argv[1]
# Opérations qui ne s'extraient pas (Error 395 relevée à l'extraction ; détail : docs/ULIB-COUVERTURE.md)
BLOCKED = {("Int128", "to_string"): "FStar.Int128.to_string has no F* definition and no F# realization"}

WIDTHS = [("UInt8", 8, False), ("UInt16", 16, False), ("UInt32", 32, False), ("UInt64", 64, False), ("UInt128", 128, False),
          ("Int8", 8, True), ("Int16", 16, True), ("Int32", 32, True), ("Int64", 64, True), ("Int128", 128, True)]

def vals(mod):
    s = open(f"{ulib}/FStar.{mod}.fsti").read()
    return set(re.findall(r"^(?:val|let|inline_for_extraction let|inline_for_extraction unfold let) ([a-z_0-9]+)", s, re.M))

out = []
w = out.append
w("""module TMachine
(* GÉNÉRÉ par scripts/gen_tmachine.py : tests différentiels des entiers machine, une instance de TMachineLib par largeur.
   Ne pas éditer à la main. *)
open FStar.All
open TUtil
open TMachineLib
module U32 = FStar.UInt32
""")
w("""let mk32 (n:int) : option (x:U32.t{U32.v x == n}) = if n >= 0 && n < 4294967296 then Some (U32.uint_to_t n) else None
""")
for (M, bits, signed) in WIDTHS:
    V = vals(M)
    lo = -(2 ** (bits - 1)) if signed else 0
    hi = 2 ** (bits - 1) - 1 if signed else 2 ** bits - 1
    LO = f"(0 - {-lo})" if lo < 0 else "0"
    HI = str(hi)
    conv = "int_to_t" if signed else "uint_to_t"
    tag = M.lower()
    w(f"module M_{tag} = FStar.{M}")
    hint = f"assert_norm (pow2 {bits - 1 if signed else bits} == {2 ** (bits - 1) if signed else 2 ** bits}); " if bits == 128 else ""
    w(f"let mk_{tag} (n:int) : option (x:M_{tag}.t{{M_{tag}.v x == n}}) = {hint}if n >= {LO} && n <= {HI} then Some (M_{tag}.{conv} n) else None")
    A = f"M_{tag}"
    mk = f"mk_{tag}"
    def bin_(op, pre="true"):
        return (f"(Some (fun (a:int) (b:int) (e:int) -> if {pre} then ({hint}match {mk} a with Some x -> (match {mk} b with Some y -> "
                f"(match {mk} e with Some z -> some_b ({A}.eq ({A}.{op} x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None))")
    def sh_(op, pre):
        return (f"(Some (fun (a:int) (s:int) (e:int) -> if {pre} then ({hint}match {mk} a with Some x -> (match mk32 s with Some c -> "
                f"(match {mk} e with Some z -> some_b ({A}.eq ({A}.{op} x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None))")
    def un_(op):
        return (f"(Some (fun (a:int) (e:int) -> (match {mk} a with Some x -> (match {mk} e with Some z -> some_b ({A}.eq ({A}.{op} x) z) "
                f"| None -> Some false) | None -> Some false)))")
    def cmp_(op):
        return (f"(fun (a:int) (b:int) (e:bool) -> (match {mk} a with Some x -> (match {mk} b with Some y -> some_b (({A}.{op} x y) = e) "
                f"| None -> Some false) | None -> Some false))")
    def has(op): return op in V and (M, op) not in BLOCKED
    def opt(op, builder):
        return builder if has(op) else "None"
    inr = lambda e: f"({e}) >= {LO} && ({e}) <= {HI}"
    if signed:
        pre_add, pre_sub, pre_mul = inr("a + b"), inr("a - b"), inr("a * b")
        pre_div = f"b <> 0 && (a <> {LO} || b <> (0 - 1))"
        pre_shl = f"a >= 0 && s >= 0 && s < {bits} && a * pow2 s <= {HI}"
        pre_shr = f"a >= 0 && s >= 0 && s < {bits}"
    else:
        pre_add, pre_sub, pre_mul = f"a + b <= {HI}", "a - b >= 0", f"a * b <= {HI}"
        pre_div = "b <> 0"
        pre_shl = pre_shr = f"s >= 0 && s < {bits}"
    pre_rot = f"s >= 0 && s < {bits}"
    ts = (f"(Some (fun (a:int) (s:string) -> (match {mk} a with Some x -> {A}.to_string x = s | None -> false)))"
          if has("to_string") else "None")
    zo = (f"(fun () -> {A}.eq {A}.zero ({A}.{conv} 0) && {A}.eq {A}.one ({A}.{conv} 1))" if has("zero") else "(fun () -> true)")
    fields = [
      ("name", f"\"{M}\""), ("bits", str(bits)), ("signed", "true" if signed else "false"),
      ("add_mod", opt("add_mod", bin_("add_mod"))), ("sub_mod", opt("sub_mod", bin_("sub_mod"))), ("mul_mod", opt("mul_mod", bin_("mul_mod"))),
      ("add", opt("add", bin_("add", pre_add))), ("sub", opt("sub", bin_("sub", pre_sub))), ("mul", opt("mul", bin_("mul", pre_mul))),
      ("add_us", opt("add_underspec", bin_("add_underspec"))), ("sub_us", opt("sub_underspec", bin_("sub_underspec"))),
      ("mul_us", opt("mul_underspec", bin_("mul_underspec"))),
      ("div", opt("div", bin_("div", pre_div))), ("rem", opt("rem", bin_("rem", pre_div))),
      ("logand", opt("logand", bin_("logand"))), ("logor", opt("logor", bin_("logor"))), ("logxor", opt("logxor", bin_("logxor"))),
      ("lognot", opt("lognot", un_("lognot"))),
      ("shl", opt("shift_left", sh_("shift_left", pre_shl))), ("shr", opt("shift_right", sh_("shift_right", pre_shr))),
      ("sar", opt("shift_arithmetic_right", sh_("shift_arithmetic_right", pre_rot))),
      # Int128.rotate_* : aucune règle Custard à 128 bits (Builtins.fst : `snd sw <> W128`), la définition F* appelle `v`
      # (Error 395 FStar.Int128.v) : volontairement non testé, voir docs/ULIB-COUVERTURE.md
      ("rotl", "None" if bits == 128 else opt("rotate_left", sh_("rotate_left", pre_rot))),
      ("rotr", "None" if bits == 128 else opt("rotate_right", sh_("rotate_right", pre_rot))),
      ("eq", cmp_("eq")), ("ne", cmp_("ne") if has("ne") else "(fun (a:int) (b:int) (e:bool) -> None)"),
      ("gt", cmp_("gt")), ("gte", cmp_("gte")), ("lt", cmp_("lt")), ("lte", cmp_("lte")),
      ("eq_mask", opt("eq_mask", bin_("eq_mask"))), ("gte_mask", opt("gte_mask", bin_("gte_mask"))),
      ("to_string", ts), ("zero_one", zo),
    ]
    w(f"let ops_{tag} : ops = {{\n  " + ";\n  ".join(f"{k} = {v}" for k, v in fields) + " }\n")

# ---- casts
cast = open(f"{ulib}/FStar.Int.Cast.fst").read()
names = sorted(set(re.findall(r"^val ((?:u?int)\d+_to_(?:u?int)\d+)\s*:", cast, re.M)))
full = open(f"{ulib}/FStar.Int.Cast.Full.fst").read()
fnames = sorted(set(re.findall(r"^val ((?:u?int)\d+_to_(?:u?int)\d+)\s*:", full, re.M)))
mods = {f"{'u' if not s else ''}int{b}": (M, b, s) for (M, b, s) in WIDTHS}
w("""let cast_oracle (fb:nat) (tb:nat) (ts:bool) (a:int) : int =
  let m = if fb > tb then fb else tb in
  of_u tb ts ((if a < 0 then a + pw m else a) % pw tb)

let cast_case (fb:nat) (fs:bool) (tb:nat) (ts:bool) (name:string) (f:int -> int -> bool) : ML unit =
  List.iter (fun (a:int) -> check name (f a (cast_oracle fb tb ts a))) (operands fb fs)
""")
w("let run_casts () : ML unit =")
cnt = 0
for src, names_ in (("FStar.Int.Cast", names), ("FStar.Int.Cast.Full", fnames)):
    for nm in names_:
        f, t = nm.split("_to_")
        (Mf, bf, sf), (Mt, bt, st) = mods[f], mods[t]
        tf, tt = Mf.lower(), Mt.lower()
        w(f"  cast_case {bf} {str(sf).lower()} {bt} {str(st).lower()} \"{src}.{nm}\" (fun (a:int) (e:int) -> "
          f"match mk_{tf} a with Some x -> (match mk_{tt} e with Some y -> M_{tt}.eq ({src}.{nm} x y) | None -> false) | None -> false);".replace("M_"+tt+".eq ("+src, "M_"+tt+".eq ("+src).replace(f"{src}.{nm} x y)", f"{src}.{nm} x) y"))
        cnt += 1
w("  ()\n")
w("let run () : ML unit =\n  " + ";\n  ".join(f"run_ops ops_{M.lower()}" for (M, _, _) in WIDTHS) + ";\n  run_casts ();\n  FStar.IO.print_string (\"machine : exécutés=\" ^ string_of_int !executed ^ \" ignorés (précondition)=\" ^ string_of_int !skipped ^ \"\\n\")")
print("\n".join(out))
sys.stderr.write(f"{cnt} casts\n")

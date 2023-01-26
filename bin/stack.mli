(* This module represents evaluation contexts.

   The stack is a list of frames. The first element of the stack is the
   innermost one in the evaluation.
   For example: `(((t u1) u2) u3)`
   is represented by the stack `[HoleFun u1, HoleFun u2, HoleFun u3]` *)

type frame =
  | HoleFun of Terms.base
  | HoleType of Types.ty
  | HoleIf of Terms.term * Terms.term

and stack = frame list

val pp_frame : Format.formatter -> frame -> unit
val pp_stack : Format.formatter -> stack -> unit
val to_string : frame list -> string
(* pretty printing functions *)

val plug : stack -> Terms.term -> Terms.term
(* [plug s t] plugs the first hole in the stack s with the term t
   and propagates the results to the rest of the stack.
   It returns the new term.
   For example, with `s = [HoleFun u1, HoleFun u2]`, it returns the term `((t u1) u2)` *)

module VarMap : sig
  include Map.S with type key = Atom.t and type 'a t = 'a Map.Make(Atom).t
end

val simplify :
  Terms.term -> stack -> Terms.base VarMap.t -> Types.ty VarMap.t -> Terms.term
(* [simplify t acc p_var p_ty] simplifies the term [t] with the evaluation context [acc].
   It also appplies the substitutions [p_var] on variables and [p_ty] on type variables.
   The simplifications:
   - beta-reduction :
        - `(fun x.t) a` becomes `t[x\a]`
        - `(fun [X].t) Y` becomes `t[X\Y]`
    - if branches simplification :
        - `if true then a else b` becomes `a`
        - `if false then a else b` becomes `b`
*)

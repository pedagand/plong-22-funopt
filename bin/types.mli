exception Not_Polymorphic

type ty =
  | TyFreeVar of tyvar
  | TyBoundVar of int
  | TyFun of ty * ty
  | PolymorphicType of tyvar * ty
  | TyTuple of ty list

and tyvar = Atom.t

val abstract_gen : tyvar -> ty -> int -> ty
(** [abstract_gen x ty c] replaces the free variable
   [x] with the bound variable [c] in the type [ty]. 
   It goes down the type recursively and increments [c]
   each time it enters a new PolyMorphicType binding. *)

val abstract : tyvar -> ty -> ty
(** [abstract X ty] returns a new type `forall X. ty` where
   the free variable [X] is replaced with a bound variable. *)

val fill_gen : int -> ty -> ty -> ty
(** [fill_gen c s t] replaces the bound variable with
   value [c] with the type [s] in the type [t] and decrements
   the others bound variables.
   It does down the type recursively and increments [c]
   each time it enters a new PolymorphicType *)

val fill : ty -> ty -> ty
(** [fill t s] raises Not_Polymorphic if [t] is not a
   PolymorphicType else replaces the bound variable
    of [t] with [s] *)

val pretty_print_type_paren : bool -> ty -> PPrint.document
val print_ty_fun : ty -> ty -> PPrint.document
val print_poly_type : tyvar -> ty -> PPrint.document
val print_ty_tuple : ty list -> PPrint.document
val pretty_print_type : ty -> PPrint.document
val to_string : ty -> string
val pp_ty : Format.formatter -> ty -> unit
val pp_tyvar : Format.formatter -> tyvar -> unit
val equal_ty : ty -> ty -> bool
val equal_tyvar : tyvar -> tyvar -> bool
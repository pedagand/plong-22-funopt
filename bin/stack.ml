open Terms
open Types
open PPrint
module VarSet = Terms.VarSet
module VarMap = Terms.VarMap

type 'a scoped = {
  (* the term *)
  scope : 'a;
  (* the variables that can appear in the next map
     ie the free variables we saw earlier *)
  vars_term : VarSet.t; [@opaque]
  (* the variables that should be substituted in the term *)
  p_term : base VarMap.t; [@opaque]
  (* same thing but for type variables *)
  vars_ty : VarSet.t; [@opaque]
  p_ty : ty VarMap.t; [@opaque]
}
(* [@@deriving show] *)

type frame =
  | HoleFun of base (* applied function: f(term) -> where f is not given *)
  | HoleType of
      ty (* instantiated polymorphism: T[ty] -> where T is not given *)
  | HoleIf of term * term (* for conditions: _ then e1 else e2 *)
[@@deriving show]

and stack = frame list [@@deriving show]

let well_scoped (t : 'a scoped) (freevars_term : 'a -> VarSet.t)
    (freevars_ty : 'a -> VarSet.t) =
  (* vars_term and vars_ty must be disjoint *)
  if not (VarSet.disjoint t.vars_term t.vars_ty) then false
  else
    (* p_term and p_ty must be disjoint *)
    let get_keys map =
      VarSet.of_list @@ fst @@ List.split @@ VarMap.bindings map
    in
    if not (VarSet.disjoint (get_keys t.p_term) (get_keys t.p_ty)) then false
    else
      (* the free variables must be included in vars_term
         and the free type variables must be included in vars_ty *)
      let f_term = freevars_term t.scope in
      let f_ty = freevars_ty t.scope in
      VarSet.subset f_term t.vars_term && VarSet.subset f_ty t.vars_ty

let well_scoped_term t = well_scoped t free_vars free_ty_vars_of_term
(* let well_scoped_base b = well_scoped b free_vars_base (fun _ -> VarSet.empty)
   let well_scoped_ty ty = well_scoped ty (fun _ -> VarSet.empty) free_ty_vars *)

(* let rec well_scoped_stack (s : stack) =
   match s with
   | [] -> true
   | HoleFun a :: s ->
       if not (well_scoped_base a) then false else well_scoped_stack s
   | HoleType t :: s ->
       if not (well_scoped_ty t) then false else well_scoped_stack s
   | HoleIf (e1, e2) :: s ->
       if not (well_scoped_term e1 || well_scoped_term e2) then false
       else well_scoped_stack s *)

(* Returns a scoped term where the scope is [t], and all the sets/maps are empty *)
let empty_scope t =
  {
    scope = t;
    vars_term = VarSet.empty;
    vars_ty = VarSet.empty;
    p_term = VarMap.empty;
    p_ty = VarMap.empty;
  }

let inherit_scope t old =
  {
    scope = t;
    vars_term = old.vars_term;
    vars_ty = old.vars_ty;
    p_term = old.p_term;
    p_ty = old.p_ty;
  }

let scope_with_new_var ~(new_term : term) ~(old : term scoped)
    ~(old_var : Atom.t) ~(new_var : base) =
  let vars_term =
    match new_var with
    | Var x -> VarSet.add x old.vars_term
    | _ -> old.vars_term
  in
  let p_term = VarMap.add old_var new_var old.p_term in
  { old with scope = new_term; vars_term; p_term }

let scope_with_new_ty ~(new_term : term) ~(old : term scoped) ~(old_ty : Atom.t)
    ~(new_ty : ty) =
  let new_ty_fv = free_ty_vars new_ty in
  let vars_ty = VarSet.union new_ty_fv old.vars_ty in
  let p_ty = VarMap.add old_ty new_ty old.p_ty in
  { old with scope = new_term; vars_ty; p_ty }

let discharge_term (t : term scoped) =
  let rec sub_terms term =
    match term with
    | Base (Bool _) as b -> b
    | Base (Var x) -> Base (sub_var x t.p_term)
    | Fun (x, ty, body) -> (
        match sub_var x t.p_term with
        | Var x -> Fun (x, sub_ty ty t.p_ty, sub_terms body)
        | _ -> assert false)
    | FunApply (f, arg) ->
        let arg' =
          match arg with Bool _ as b -> b | Var x -> sub_var x t.p_term
        in
        FunApply (sub_terms f, arg')
    | Let (x, e, body) -> (
        match sub_var x t.p_term with
        | Var x -> Let (x, sub_terms e, sub_terms body)
        | _ -> assert false)
    | IfThenElse (c, e1, e2) ->
        IfThenElse (sub_terms c, sub_terms e1, sub_terms e2)
    | TypeAbstraction (alpha, body) -> (
        match sub_tyvar alpha t.p_ty with
        | TyFreeVar x -> TypeAbstraction (x, sub_terms body)
        | _ -> assert false)
    | TypeApply (f, arg) -> TypeApply (sub_terms f, sub_ty arg t.p_ty)
    | TypeAnnotation (x, ty) -> TypeAnnotation (sub_terms x, sub_ty ty t.p_ty)
  in
  sub_terms t.scope

let discharge_base (t : base scoped) =
  match t.scope with Bool _ as b -> b | Var x -> sub_var x t.p_term

let discharge_ty (t : ty scoped) = sub_ty t.scope t.p_ty

let pretty_print_frame f =
  match f with
  | HoleFun arg ->
      let f = string "_" in
      let x = print_base arg in
      group @@ prefix 2 1 f x
  | HoleType arg ->
      let t = string "_" in
      group @@ t ^^ lbracket ^^ pretty_print_type arg ^^ rbracket
  | HoleIf (e1, e2) ->
      let t = string " _ " in
      group @@ string "if" ^^ t ^^ string "then"
      ^^ surround 2 1 empty (pretty_print e1) empty
      ^^ string "else"
      ^^ surround 0 1 empty (pretty_print e2) empty

let rec pretty_print s =
  match s with
  | [] -> empty
  | f :: tail -> pretty_print_frame f ^^ hardline ^^ nest 1 (pretty_print tail)

let to_string s =
  let b = Buffer.create 16 in
  ToBuffer.pretty 0.8 80 b (pretty_print s);
  Buffer.contents b

let type_fun_frame_error frame actual expected =
  type_error
    (Printf.sprintf "Frame: %s\nExpected a %s->_ type\nReceived type: %s\n"
       (to_string [ frame ]) (Types.to_string expected) (Types.to_string actual))

let type_poly_frame_error frame actual =
  type_error
    (Printf.sprintf "Frame: %s\nExpected a polymorphic type\nReceived type: %s"
       (to_string [ frame ]) (Types.to_string actual))

let type_ite_frame_error frame actual =
  type_error
    (Printf.sprintf "Frame: %s\nExpected a bool type\nReceived type: %s"
       (to_string [ frame ]) (Types.to_string actual))

let rec synth_stack (s : stack) (ty : ty) (ctxt : ty VarMap.t) =
  match s with
  | [] -> ty
  | f :: s -> (
      match f with
      | HoleFun arg -> (
          match ty with
          | TyFun (a, b) -> (
              try
                let _ = check ctxt a (Base arg) in
                synth_stack s b ctxt
              with Type_Error ty' -> type_fun_frame_error f ty ty')
          | _ -> type_fun_frame_error f ty (synth ctxt (Base arg)))
      | HoleType arg -> (
          try synth_stack s (fill ty arg) ctxt
          with Not_Polymorphic -> type_poly_frame_error f ty)
      | HoleIf (e1, e2) ->
          if ty <> TyBool then type_ite_frame_error f ty
          else
            let ty1 = synth ctxt e1 in
            let ty2 = synth ctxt e2 in
            if Types.equal_ty ty1 ty2 then ty1
            else type_if_branches_error e2 ty1 ty2)

let closed_term_in_scope t scope =
  VarSet.subset (free_vars t) scope.vars_term
  && VarSet.subset (free_ty_vars_of_term t) scope.vars_ty

let rec plug (s : stack) (t : term) =
  match s with
  | [] -> t
  | f :: s ->
      let filled_term =
        match f with
        | HoleFun arg -> FunApply (t, arg)
        | HoleType arg -> TypeApply (t, arg)
        | HoleIf (e1, e2) -> IfThenElse (t, e1, e2)
      in
      plug s filled_term

and simplify (t : term) =
  let ty = synth VarMap.empty t in
  let t = simplify_aux (empty_scope t) [] in
  assert (check VarMap.empty ty t = ty);
  t

and simplify_aux (t : term scoped) (acc : stack) =
  let rec go t acc =
    match (t.scope, acc) with
    (* replace base values, renaming variables if they appear in the substitutions *)
    | Base _, acc -> (
        let t = discharge_term t in
        match (t, acc) with
        (* simplify if branches with booleans *)
        | Base (Bool b), HoleIf (e1, e2) :: acc ->
            if b then plug acc e1 else plug acc e2
        | _ -> plug acc t)
    (* abstractions with the right context to simplify *)
    | Fun (x, _, body), HoleFun arg :: acc ->
        let body_scoped =
          scope_with_new_var ~new_term:body ~old:t ~old_var:x ~new_var:arg
        in
        go body_scoped acc
    | TypeAbstraction (alpha, body), HoleType ty2 :: acc ->
        let body_scoped =
          scope_with_new_ty ~new_term:body ~old:t ~old_ty:alpha ~new_ty:ty2
        in
        go body_scoped acc
    (* abstractions but can't simplify in the context *)
    | Fun (x, ty, body), acc ->
        let x' = Atom.fresh x.identifier in
        let ty = discharge_ty (inherit_scope ty t) in
        let body_scoped =
          scope_with_new_var ~new_term:body ~old:t ~old_var:x ~new_var:(Var x')
        in
        let new_body = go body_scoped [] in
        let t = Fun (x', ty, new_body) in
        plug acc t
    | TypeAbstraction (alpha, body), acc ->
        let alpha' = Atom.fresh alpha.identifier in
        let body_scoped =
          scope_with_new_ty ~new_term:body ~old:t ~old_ty:alpha
            ~new_ty:(TyFreeVar alpha')
        in
        let new_body = go body_scoped [] in
        let t = TypeAbstraction (alpha', new_body) in
        plug acc t
    (* cases that create a context that we can simplify in *)
    | FunApply (f, arg), acc ->
        let f = inherit_scope f t in
        let arg = inherit_scope arg t in
        go f (HoleFun (discharge_base arg) :: acc)
    | TypeApply (f, ty), acc ->
        let f = inherit_scope f t in
        let ty = inherit_scope ty t in
        go f (HoleType (discharge_ty ty) :: acc)
    | IfThenElse (t1, t2, t3), acc ->
        let t1 = inherit_scope t1 t in
        let t2 = go (inherit_scope t2 t) [] in
        let t3 = go (inherit_scope t3 t) [] in
        go t1 (HoleIf (t2, t3) :: acc)
    (* other cases *)
    | Let (x, t1, body), acc ->
        let x' = Atom.fresh x.identifier in
        let t1 = go (inherit_scope t1 t) [] in
        let body_scoped =
          scope_with_new_var ~new_term:body ~old:t ~old_var:x ~new_var:(Var x')
        in
        let body = go body_scoped [] in
        let t = Let (x', t1, body) in
        plug acc t
    (* throw away the type annotation *)
    | TypeAnnotation (body, _), acc -> go (inherit_scope body t) acc
  in
  let t' = go t acc in
  (* check that the term is closed *)
  assert (closed_term_in_scope t' t);
  t'

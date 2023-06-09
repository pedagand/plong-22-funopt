open Atom
open Terms
open Types
open Typechecker
open Stack
open Simplify

let () =
  let open Alcotest in
  run "Utils"
    [
      ( "test atom equal and compare",
        [
          test_case "atom equal 1" `Quick test_atom_eq1;
          test_case "atom equal 2" `Quick test_atom_eq2;
          test_case "atom lt 1" `Quick test_atom_lt1;
          test_case "atom lt 2" `Quick test_atom_lt2;
        ] );
      ( "test pp_deriving",
        [
          test_case "pp_term var" `Quick test_pp_term;
          test_case "equal_ty poly 1" `Quick test_pp_equal_ty_poly1;
          test_case "equal_ty poly 2" `Quick test_pp_equal_ty_poly2;
          test_case "equal_ty poly 3" `Quick test_pp_equal_ty_poly3;
          test_case "equal_term" `Quick test_pp_equal_term;
        ] );
      ( "test terms smart constructors",
        [
          test_case "fn id" `Quick test_fn_id;
          test_case "fn poly id" `Quick test_fn_poly_id;
          test_case "fn fun 2" `Quick test_fn2;
          test_case "fn fun 3" `Quick test_fn3;
          test_case "letin" `Quick test_letin;
        ] );
      ( "test abstract",
        [
          test_case "abstract fn" `Quick test_abstract_fn;
          test_case "abstract poly" `Quick test_abstract_poly1;
          test_case "abstract poly2" `Quick test_abstract_poly2;
          test_case "abstract poly3" `Quick test_abstract_poly3;
        ] );
      ( "test smart constructors poly",
        [
          test_case "poly type 1" `Quick test_poly_ty1;
          test_case "poly type 2" `Quick test_poly_ty2;
          test_case "poly type 3" `Quick test_poly_ty3;
          test_case "poly type 4" `Quick test_poly_ty4;
        ] );
      ( "test fill",
        [
          test_case "fill fn" `Quick test_fill_fn;
          test_case "fill poly: basic case" `Quick test_fill_poly1;
          test_case "fill poly2: 2 PolyTypes with the same var name " `Quick
            test_fill_poly2;
          test_case "fill poly3: general case with several other PolyTypes"
            `Quick test_fill_poly3;
        ] );
      ( "test print function type",
        [
          test_case "Simple" `Quick test_print_ty_fun_simple;
          test_case "Left assoc" `Quick test_print_ty_fun_double_left;
          test_case "Right assoc" `Quick test_print_ty_fun_double_right;
          test_case "With line breaks" `Quick test_print_ty_fun_very_long;
        ] );
      ( "test print polymorphic type",
        [
          test_case "Simple" `Quick test_print_poly_type_simple;
          test_case "Double" `Quick test_print_poly_type_double;
          test_case "Complex" `Quick test_print_poly_type_complex;
        ] );
      ( "test print tuple type",
        [
          test_case "Simple" `Quick test_print_ty_tuple_simple;
          test_case "Double" `Quick test_print_ty_tuple_double;
        ] );
      ( "test print type compose",
        [
          test_case "Compose 1" `Quick test_print_ty_compose1;
          test_case "Compose 2" `Quick test_print_ty_compose2;
          test_case "Compose 3" `Quick test_print_ty_compose3;
          test_case "Compose 4" `Quick test_print_ty_compose4;
        ] );
      ( "test print variable",
        [ test_case "Variable" `Quick test_print_variable ] );
      ( "test print fun",
        [
          test_case "Fun 1" `Quick test_print_fun1;
          test_case "Fun 2" `Quick test_print_fun2;
          test_case "Fun 3" `Quick test_print_fun3;
          test_case "Fun 4" `Quick test_print_fun4;
        ] );
      ( "test print fun apply",
        [
          test_case "FunApply 1" `Quick test_print_fun_apply1;
          test_case "FunApply 2" `Quick test_print_fun_apply2;
        ] );
      ( "test print let",
        [
          test_case "Let 1" `Quick test_print_let1;
          test_case "Let 2" `Quick test_print_let2;
          test_case "Let 3" `Quick test_print_let3;
        ] );
      ( "test print type abstraction",
        [
          test_case "TypeAbstraction 1" `Quick test_print_type_abstraction1;
          test_case "TypeAbstraction 2" `Quick test_print_type_abstraction2;
        ] );
      ( "test print type apply",
        [
          test_case "TypeApply 1" `Quick test_print_type_apply1;
          test_case "TypeApply 2" `Quick test_print_type_apply2;
        ] );
      ( "test print frame ",
        [
          test_case "Fun frame" `Quick test_print_fun_frame;
          test_case "Ty Frame" `Quick test_print_ty_frame;
        ] );
      ( "test print stack",
        [
          test_case "Empty stack" `Quick test_print_empty_stack;
          test_case "Big stack" `Quick test_print_big_stack;
        ] );
      ( "test free_vars",
        [
          test_case "Var" `Quick test_free_vars_var;
          test_case "Fun 1" `Quick test_free_vars_fun1;
          test_case "Fun 2" `Quick test_free_vars_fun2;
          test_case "FunApply 1" `Quick test_free_vars_funApply1;
          test_case "FunApply 2" `Quick test_free_vars_funApply2;
          test_case "Let 1" `Quick test_free_vars_Let1;
          test_case "Let 2" `Quick test_free_vars_Let2;
          test_case "Type abstraction" `Quick test_free_var_type_abstraction;
          test_case "TypleApply" `Quick test_free_var_type_apply;
          test_case "TypeAnnotation" `Quick test_free_var_type_annotation;
        ] );
      ( "test typechecking",
        [
          test_case "Var in the map" `Quick test_typecheck_var_in_map;
          test_case "Var not in the map" `Quick test_typecheck_fail_not_in_map;
          test_case "Identity function" `Quick test_typecheck_fun_id;
          test_case "Identity function 2" `Quick test_typecheck_fun_id2;
          test_case "Fun simple" `Quick test_typecheck_fun_simple;
          test_case "Apply identity function" `Quick test_typecheck_fun_apply;
          test_case "Apply identity function 2" `Quick test_typecheck_fun_apply2;
          test_case "Apply identity function simple" `Quick
            test_typecheck_fun_apply_simple;
          test_case "Let simple" `Quick test_typecheck_let_simple;
          test_case "Let" `Quick test_typecheck_let;
          test_case "If true" `Quick test_typecheck_if1;
          test_case "If false" `Quick test_typecheck_if2;
          test_case "If condition not bool" `Quick test_typecheck_if_bad1;
          test_case "If branches not the same" `Quick test_typecheck_if_bad2;
          test_case "Poly function simple" `Quick
            test_typecheck_type_abstract_simple;
          test_case "Poly function" `Quick test_typecheck_type_abstract;
          test_case "TypeApply simple" `Quick test_typecheck_type_apply_simple;
          test_case "TypeApply" `Quick test_typecheck_type_apply;
          test_case "TypeAnnotation easy" `Quick
            test_typecheck_type_annotation_simple;
          test_case "TypeAnnotation" `Quick test_typecheck_type_annotation;
        ] );
      ( "test plug",
        [
          test_case "HoleFun 1" `Quick test_plug_fun1;
          test_case "HoleFun 2" `Quick test_plug_fun2;
          test_case "HoleType 1" `Quick test_plug_ty1;
          test_case "HoleType 2" `Quick test_plug_ty2;
          test_case "both HoleFun and HoleType" `Quick test_plug_mix;
        ] );
      ( "test stack and frame typechecking",
        [
          test_case "Stack Fun 1 good" `Quick test_stack_fun1_good;
          test_case "Stack Fun 1 bad" `Quick test_stack_fun1_bad;
          test_case "Stack Type 1 good" `Quick test_stack_poly1_good;
          test_case "Stack Type 1 bad" `Quick test_stack_poly1_bad;
          test_case "Stack Fun 2 good" `Quick test_stack_fun2_good;
          test_case "Stack Fun 2 bad" `Quick test_stack_fun2_bad;
          test_case "Stack Poly 2 good" `Quick test_stack_poly2_good;
          test_case "Stack Both" `Quick test_stack_both;
          test_case "Stack If good" `Quick test_stack_if_good;
          test_case "Stack If bad" `Quick test_stack_if_bad;
        ] );
      ( "test alpha equivalence",
        [
          test_case "Base bool same" `Quick test_alpha_eq_bool1;
          test_case "Base bool diff" `Quick test_alpha_eq_bool2;
          test_case "Base var same" `Quick test_alpha_eq_var1;
          test_case "Base var same" `Quick test_alpha_eq_var2;
          test_case "Base diff" `Quick test_alpha_eq_base;
          test_case "Fun 1" `Quick test_alpha_eq_fun1;
          test_case "Fun 2" `Quick test_alpha_eq_fun2;
          test_case "Fun 3" `Quick test_alpha_eq_fun3;
          test_case "FunApply 1" `Quick test_alpha_eq_funapply1;
          test_case "FunApply 2" `Quick test_alpha_eq_funapply2;
          test_case "FunApply 3" `Quick test_alpha_eq_funapply3;
          test_case "Let 1" `Quick test_alpha_eq_let1;
          test_case "Let 2" `Quick test_alpha_eq_let2;
          test_case "Let 3" `Quick test_alpha_eq_let3;
          test_case "Let 4" `Quick test_alpha_eq_let4;
          test_case "TypeAbstract 1" `Quick test_alpha_eq_typeabstract1;
          test_case "TypeAbstract 2" `Quick test_alpha_eq_typeabstract2;
          test_case "TypeAbstract 3" `Quick test_alpha_eq_typeabstract3;
          test_case "TypeApply 1" `Quick test_alpha_eq_typeapply1;
          test_case "TypeApply 2" `Quick test_alpha_eq_typeapply2;
          test_case "TypeApply 3" `Quick test_alpha_eq_typeapply3;
        ] );
      ( "test simplification",
        [
          test_case "Atom bool" `Quick test_simplification_atom_bool;
          test_case "Fun" `Quick test_simplification_fun;
          test_case "Fun simple" `Quick test_simplification_fun1;
          test_case "Fun with apply" `Quick test_simplification_fun2;
          test_case "FunApply simple var" `Quick test_simplification_funapply1;
          test_case "FunApply simple bool" `Quick test_simplification_funapply2;
          test_case "FunApply with apply" `Quick test_simplification_funapply3;
          test_case "Let simple" `Quick test_simplification_let1;
          test_case "Let simple with in def" `Quick test_simplification_let2;
          test_case "Let simple with in def and exp" `Quick
            test_simplification_let3;
          test_case "TypeAbstract with apply in letin" `Quick
            test_simplification_typeabstract;
          test_case "TypeApply with apply in letin" `Quick
            test_simplification_typeapply;
          test_case "TypeAnnotation with apply in letin" `Quick
            test_simplification_annotation;
          test_case "IfThenElse with true" `Quick test_simplification_ite_true;
          test_case "IfThenElse with false" `Quick test_simplification_ite_false;
          test_case "IfThenElse with apply in condition" `Quick
            test_simplification_ite1;
          test_case "Fun with x as condition" `Quick test_simplification_fun_if;
          test_case "IfThenElse with var" `Quick test_simplification_var_if;
          test_case "IfThenElse in function" `Quick
            test_simplification_if_in_fun;
        ] );
    ]

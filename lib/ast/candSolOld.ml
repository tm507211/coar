open Core
open Common.Ext
open Common.Util
open LogicOld

type t = sort_env_map * pred_subst_set

let str_of ((_, cand) : t) : string =
  String.concat_map_set ~sep:"\n" cand ~f:(fun (Ident.Pvar pvar, (params, phi)) ->
      let params', map = normalize_sort_env_list params in
      Printf.sprintf "%s(%s) :=\n  %s"
        pvar
        (str_of_sort_env_list Term.str_of_sort params')
        (Formula.str_of @@ Formula.rename map phi))

let str_of_list candidates =
  String.concat_mapi_list ~sep:"\n" candidates ~f:(fun i candidate ->
      Printf.sprintf "**** %s candidate solution\n%s\n"
        (Ordinal.string_of @@ Ordinal.make i)
        (str_of candidate))

let of_fundef (Ident.Tvar x, t) : pred_subst_elem =
  let args, t' = Logic.Term.let_lam t in
  let params = Logic.to_old_sort_env_list Logic.ExtTerm.to_old_sort args in
  let params', map = LogicOld.normalize_sort_env_list params in
  let phi =
    Formula.rename map @@
    Logic.ExtTerm.to_old_formula Map.Poly.empty (Map.of_list_exn args) t' []
  in
  Ident.Pvar x, (params', phi)

let of_subst (sub : Logic.term_subst_map) : t =
  Map.Poly.empty,
  Set.Poly.of_list @@ List.map ~f:of_fundef @@ Map.Poly.to_alist sub

let of_list (cand : pred_subst_list) : t =
  Map.Poly.empty, Set.Poly.of_list cand
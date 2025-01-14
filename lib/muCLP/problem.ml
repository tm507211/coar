open Core
open Common
open Common.Ext
open Common.Util
open Common.Combinator
open Ast
open Ast.LogicOld

(* ToDo *)module Debug = Debug.Make(val Debug.Config.disable)

type query = Formula.t
type t = { preds : Pred.t list; query : query }
type solution = Valid | Invalid | Unknown

exception Timeout

let make preds query = { preds = preds; query = query }

let flip_solution = function
  | Valid -> Invalid
  | Invalid -> Valid
  | x -> x

let str_of_solution = function
  | Valid -> "valid"
  | Invalid -> "invalid"
  | Unknown -> "unknown"
let lts_str_of_solution = function
  | Valid -> "YES"
  | Invalid -> "NO"
  | Unknown -> "MAYBE"

let preds_of muclp = muclp.preds
let query_of muclp = muclp.query
let size_of muclp = List.length muclp.preds

let penv_of ?(init=Map.Poly.empty) muclp =
  Pred.pred_sort_env_map_of_list init muclp.preds

let let_muclp muclp = muclp.preds, muclp.query

let get_depth_ht muclp =
  let res = Hashtbl.Poly.create ~size:(List.length muclp.preds) () in
  List.iteri muclp.preds ~f:(fun i (_, pvar, _, _) ->
      Hashtbl.Poly.add_exn res ~key:pvar ~data:i);
  res

let avoid_dup pvar pvars =
  if not @@ List.exists pvars ~f:(fun pvar' ->
      Stdlib.(Ident.name_of_pvar pvar' = Ident.name_of_pvar pvar)) then
    pvar
  else
    let suffix = ref 2 in
    while List.exists pvars ~f:(fun pvar' ->
        Stdlib.(Ident.name_of_pvar pvar' = Ident.name_of_pvar pvar ^ (string_of_int !suffix))) do
      suffix := !suffix + 1
    done;
    Ident.Pvar (Ident.name_of_pvar pvar ^ string_of_int !suffix)

(* Usage: let query, preds, _ = muclp_of_formula_with_env [] [] [] fml *)
(* Note: bound_tvars: term variables bound by fixpoint predicates *)
let rec of_formula_with_env preds env used_pvars bound_tvars =
  let open Formula in function
    | Atom (atom, info) as fml -> begin
        match atom with
        | App (Fixpoint (fp, pvar, bounds, body), outer_args, info') ->
          (* (fp pvar(bounds). body)(args) *)
          let new_pvar = avoid_dup pvar used_pvars in
          let used_pvars = new_pvar :: used_pvars in
          let env = (pvar, new_pvar) :: env in
          let bound_tvars = Set.Poly.union bound_tvars (Set.Poly.of_list bounds) in
          let body, preds, used_pvars =
            of_formula_with_env preds env used_pvars bound_tvars body
          in

          let fvs_of_body = Formula.term_sort_env_of body in
          let additional_params = Set.Poly.to_list @@
            Set.Poly.diff fvs_of_body
              (Set.Poly.inter bound_tvars (Set.Poly.of_list bounds)) in

          let new_bounds = bounds @ additional_params in
          let new_outer_args = outer_args @ Term.of_sort_env additional_params in
          let new_inner_args = Term.of_sort_env new_bounds in
          let new_sorts = List.map ~f:snd new_bounds in

          let new_pvar_app =
            Formula.mk_atom @@ Atom.mk_pvar_app new_pvar new_sorts new_inner_args
          in
          let body =
            Formula.subst_preds (Map.Poly.singleton pvar (bounds, new_pvar_app)) body
          in
          let preds = (Pred.make fp new_pvar new_bounds body) :: preds in
          let fml' =
            Formula.mk_atom ~info @@
            Atom.mk_pvar_app new_pvar new_sorts new_outer_args ~info:info'
          in
          fml', preds, used_pvars
        | App (Var (pvar, sorts), args, info') ->
          let new_pred =
            Predicate.mk_var (List.Assoc.find_exn ~equal:Stdlib.(=) env pvar) sorts
          in
          let fml' = Formula.mk_atom (Atom.mk_app new_pred args ~info:info') ~info in
          fml', preds, used_pvars
        | _ -> fml, preds, used_pvars
      end
    | UnaryOp (op, fml, info) ->
      let query, preds, used_pvars =
        of_formula_with_env preds env used_pvars bound_tvars fml
      in
      let fml' = Formula.mk_unop op query ~info in
      fml', preds, used_pvars
    | BinaryOp (op, lhs, rhs, info) ->
      let left_query, preds, used_pvars =
        of_formula_with_env preds env used_pvars bound_tvars lhs
      in
      let right_query, preds, used_pvars =
        of_formula_with_env preds env used_pvars bound_tvars rhs
      in
      let fml' = Formula.mk_binop op left_query right_query ~info in
      fml', preds, used_pvars
    | Bind (binder, bounds, body, info) ->
      let query, preds, used_pvars =
        of_formula_with_env preds env used_pvars bound_tvars body
      in
      let fml' = Formula.mk_bind binder bounds query ~info in
      fml', preds, used_pvars
    | LetRec (letrec_preds, body, _) ->
      let env, used_pvars =
        List.fold ~init:(env, used_pvars) letrec_preds
          ~f:(fun (env, used_pvars) (_, pvar, _, _) ->
              let new_pvar = avoid_dup pvar used_pvars in
              let used_pvars = new_pvar :: used_pvars in
              (pvar, new_pvar) :: env, used_pvars)
      in
      let query, preds, used_pvars =
        of_formula_with_env preds env used_pvars bound_tvars body
      in
      let preds, used_pvars =
        List.fold ~init:(preds, used_pvars) letrec_preds
          ~f:(fun (preds, used_pvars) (fp, pvar, bounds, body) ->
              let body, preds, used_pvars =
                of_formula_with_env preds env used_pvars bound_tvars body
              in
              Pred.make fp (List.Assoc.find_exn ~equal:Stdlib.(=) env pvar)
                bounds body :: preds, used_pvars)
      in
      query, preds, used_pvars
    | LetFormula _ -> failwith @@ "'LetFormula' is not supported yet" (* TODO *)
let of_formula phi =
  let query, preds, _ = of_formula_with_env [] [] [] Set.Poly.empty phi in
  make preds query

let to_formula _ = assert false (* TODO *)

let str_of muclp =
  let preds, query = let_muclp muclp in
  Printf.sprintf "%s\ns.t.\n%s" (Formula.str_of query) (Pred.str_of_list preds)

let has_only_mu muclp =
  List.for_all ~f:(fun (fix, _, _, _) -> Stdlib.(fix = Predicate.Mu)) muclp.preds
let has_only_nu muclp =
  List.for_all ~f:(fun (fix, _, _, _) -> Stdlib.(fix = Predicate.Nu)) muclp.preds
let has_only_exists muclp =
  let preds, query = let_muclp muclp in
  let rec check fml =
    if Formula.is_atom fml then
      true
    else if Formula.is_and fml || Formula.is_or fml then
      let _, fml_left, fml_right, _ = Formula.let_binop fml in
      check fml_left && check fml_right
    else if Formula.is_forall fml then
      false
    else if Formula.is_exists fml then
      let _, fml, _ = Formula.let_exists fml in
      check fml
    else
      ((*Debug.print @@ lazy (Printf.sprintf "not implemented for: %s" @@ Formula.str_of fml);*)
        failwith "not implemented")
  in
  List.for_all ~f:(fun fml -> check @@ Evaluator.simplify fml)
  @@ query :: List.map ~f:(fun (_, _, _, body) -> body) preds
let has_only_forall muclp =
  let preds, query = let_muclp muclp in
  let rec check fml =
    if Formula.is_atom fml then
      true
    else if Formula.is_and fml || Formula.is_or fml then
      let _, fml_left, fml_right, _ = Formula.let_binop fml in
      check fml_left && check fml_right
    else if Formula.is_forall fml then
      let _, fml, _ = Formula.let_forall fml in
      check fml
    else if Formula.is_exists fml then
      false
    else
      failwith "not implemented"
  in
  List.for_all ~f:check
  @@ query :: List.map ~f:(fun (_, _, _, body) -> body) preds
let has_no_quantifier muclp = has_only_exists muclp && has_only_forall muclp

let aconv_tvar muclp =
  let query' = Formula.aconv_tvar muclp.query in
  let preds' =
    List.map muclp.preds ~f:(fun (fp, pvar, params, phi) ->
        let pmap =
          List.map params ~f:(fun (x, sort) -> (x, sort, Ident.mk_fresh_tvar ()))
        in
        let map = List.map pmap ~f:(fun (x, sort, x') -> (x, Term.mk_var x' sort)) in
        let params' = List.map pmap ~f:(fun (_, sort, x') -> x', sort) in
        let phi' = Formula.subst (Map.Poly.of_alist_exn map) @@ Formula.aconv_tvar phi in
        (fp, pvar, params', phi'))
  in
  make preds' query'

let move_quantifiers_to_front muclp =
  let preds, query = let_muclp muclp in
  make (Pred.map_list Formula.move_quantifiers_to_front preds)
  @@ Formula.move_quantifiers_to_front query

let rm_forall muclp =
  let _, query' = Formula.rm_forall muclp.query in
  let preds' = Pred.map_list (fun phi -> snd @@ Formula.rm_forall phi) muclp.preds in
  make preds' query'

let complete_tsort muclp =
  make (Pred.map_list Formula.complete_tsort muclp.preds)
    (Formula.complete_tsort muclp.query)

(* TODO : this should be applied to hes Parser *)
let complete_psort uninterp_pvs muclp =
  let map = penv_of ~init:uninterp_pvs (make muclp.preds muclp.query) in
  make (Pred.map_list (Formula.complete_psort map) muclp.preds)
    (Formula.complete_psort map muclp.query)

let simplify muclp =
  make (Pred.map_list Evaluator.simplify muclp.preds) (Evaluator.simplify muclp.query)

let get_dual muclp =
  let pvars = List.map muclp.preds ~f:(fun (_, pvar, _, _) -> pvar) in
  let subst formula =
    List.fold ~init:formula pvars ~f:(fun fml pvar -> Formula.subst_neg pvar fml)
  in
  make
    (List.map muclp.preds ~f:(fun (fixpoint, pvar, args, formula) ->
         (Predicate.flip_fixpoint fixpoint,
          pvar, args, Evaluator.simplify_neg (subst formula))))
    (Evaluator.simplify_neg (subst muclp.query))

let get_greatest_approx muclp =
  make (List.map muclp.preds ~f:(fun (_, pvar, args, phi) -> Predicate.Nu, pvar, args, phi)) muclp.query

let bind_fvs_with_forall muclp =
  let query = Formula.bind_fvs_with_forall muclp.query in
  make muclp.preds query

(*let detect_arity0_preds muclp =
  if List.exists ~f:(fun (_, _, params, _) -> List.length params = 0) muclp.preds
  then failwith "arity0 predicates is not supported."
  else make muclp.preds muclp.query*)

let detect_undefined_preds muclp =
  let check map formula =
    let fpv = LogicOld.Formula.pvs_of formula in
    (*Debug.print @@
      lazy (Printf.sprintf "fpvs: %s" @@ String.concat_set ~sep:"," @@
          Set.Poly.map ~f:(fun (Ident.Pvar pid) -> pid) fpv);*)
    match Set.Poly.find ~f:(fun pvar -> not @@ Map.Poly.mem map pvar) fpv with
    | Some (Ident.Pvar pid) -> failwith @@ "undefined predicates: " ^ pid
    | None -> ()
  in
  let rec mk_env map = function
    | [] -> map
    | (_, pvar, _, _)::xs ->
      mk_env (Map.Poly.add_exn map ~key:pvar ~data:pvar) xs
  in
  let map = mk_env Map.Poly.empty muclp.preds in
  check map muclp.query;
  List.iter ~f:(fun (_, _, _, phi) -> check map phi) muclp.preds;
  make muclp.preds muclp.query

let _check_problem muclp =
  muclp
  (*|> detect_arity0_preds*)
  |> detect_undefined_preds
let check_problem muclp = muclp

let rename_args group =
  let (_, a1, _, _) = List.hd_exn group in
  match Set.Poly.to_list a1 with
  | [] ->
    List.map group ~f:(fun (senv, ps, ns, phi) ->
        assert (Set.Poly.is_empty ps);
        senv, None, ns, Evaluator.simplify_neg phi)
  | [Atom.App (Predicate.Var (_, sorts), _args0, _)] ->
    let new_vars = mk_fresh_sort_env_list sorts in
    let args' = List.map new_vars ~f:(uncurry Term.mk_var) in
    List.map group ~f:(fun (uni_senv, ps, ns, phi) ->
        match Set.Poly.to_list ps with
        | [Atom.App (Predicate.Var (p, _), args, _)] ->
          Map.force_merge uni_senv @@
          Map.of_list_exn @@
          List.map ~f:(Pair.map_snd Logic.ExtTerm.of_old_sort) new_vars,
          Some (p, new_vars),
          ns,
          Formula.and_of @@
          Evaluator.simplify_neg phi :: List.map2_exn args args' ~f:Formula.eq
        | _ -> assert false)
  | _ -> assert false
let of_chc chc =
  let chc = chc |> PCSP.Problem.to_nnf |> PCSP.Problem.to_cnf in
  let groups =
    chc
    |> PCSP.Problem.clauses_of
    |> Ast.ClauseSet.to_old_clause_set (PCSP.Problem.senv_of chc)
    |> Set.to_list
    |> List.classify (fun (_, ps1, _, _)  (_, ps2, _, _) ->
        match Set.Poly.to_list ps1, Set.Poly.to_list ps2 with
        | [], [] -> true
        | [atm1], [atm2] ->
          assert (Atom.is_app atm1 && Atom.is_app atm2);
          let p1, _, _ = Atom.let_app atm1 in
          let p2, _, _ = Atom.let_app atm2 in
          assert (Predicate.is_var p1 && Predicate.is_var p2);
          let pred1 = Predicate.let_var p1 in
          let pred2 = Predicate.let_var p2 in
          Stdlib.(pred1 = pred2)
        | _, _ -> false)
    |> List.map ~f:rename_args
  in
  let goals, defs = List.partition_tf groups ~f:(function
      | [] -> assert false
      | ((_senv, p, _ns, _phi) :: _group) -> Option.is_none p) in
  let make_pred = function
    | ((_, Some (p, args), _, _) :: _) as group ->
      Pred.make Predicate.Mu p args
        (Formula.or_of @@
         List.map group ~f:(fun (senv, _, ns, phi) ->
             let phi = Formula.and_of @@ Evaluator.simplify phi :: List.map (Set.Poly.to_list ns) ~f:Formula.mk_atom in
             let senv =
               let fvs = Formula.fvs_of phi in
               Map.Poly.filter_keys senv ~f:(Set.Poly.mem fvs) in
             let senv, phi = Pair.map_snd Evaluator.simplify_neg @@
               Ast.Qelim.qelim_old (Map.of_list_exn @@ Logic.ExtTerm.of_old_sort_env args) (PCSP.Problem.senv_of chc) (senv, Evaluator.simplify_neg phi) in
             let unbound =
               Map.to_alist @@ Logic.to_old_sort_env_map Logic.ExtTerm.to_old_sort @@
               Map.Poly.filter_keys senv ~f:(fun x -> not @@ List.Assoc.mem ~equal:Stdlib.(=) args x) in
             Formula.exists unbound phi))
    | _ -> assert false
  in
  let preds = List.map ~f:make_pred defs in
  let query =
    match goals with
    | [] -> Formula.mk_false ()
    | [goals] ->
      Formula.or_of @@
      List.map goals ~f:(fun (senv, _, ns, phi) ->
          let phi = Formula.and_of @@ Evaluator.simplify phi :: List.map (Set.Poly.to_list ns) ~f:Formula.mk_atom in
          let senv = let ftvs = Formula.tvs_of phi(*ToDo:also use pvs?*) in Map.Poly.filter_keys senv ~f:(Set.Poly.mem ftvs) in
          let senv, phi = Pair.map_snd Evaluator.simplify_neg @@
            Ast.Qelim.qelim_old Map.Poly.empty (PCSP.Problem.senv_of chc) (senv, Evaluator.simplify_neg phi) in
          let unbound = List.map ~f:(fun (x, s) -> x, Logic.ExtTerm.to_old_sort s) @@ Map.Poly.to_alist senv in
          Formula.exists unbound phi)
    | _ -> assert false
  in
  let undef_preds =
    let def_preds = List.map ~f:(fun (_, p, _, _) -> p) preds in
    let senv = Map.Poly.filter_keys ~f:(fun x -> not @@ List.mem def_preds ~equal:Stdlib.(=) (Ident.tvar_to_pvar x)) @@ PCSP.Problem.senv_of chc in
    Map.Poly.mapi senv ~f:(fun ~key:(Ident.Tvar n) ~data ->
        let sorts = List.map ~f:Logic.ExtTerm.to_old_sort @@ Logic.Sort.args_of data in
        let args sorts =
          let flag = ref 0 in
          List.map sorts ~f:(fun sort ->
              let _ = flag := !flag + 1 in
              Ident.Tvar ("x" ^ (string_of_int !flag)), sort)
        in
        Pred.make Predicate.Mu (Ident.Pvar n) (args sorts) (Formula.mk_false ()))
    |> Map.Poly.to_alist |> List.map ~f:snd in
  get_dual @@ make (preds @ undef_preds) query
(* |>( fun res -> let _ = Printf.printf "\n\n-------------->>>before res<<<--------\n\n%s\n" @@ str_of res in res) *)
(* |>( fun res -> let _ = Printf.printf "\n\n-------------->>>after res<<<--------\n\n%s\n" @@ str_of res in res) *)

let rec of_lts ?(live_vars=None) ?(cut_points=None) = function
  | lts, LTS.Problem.Term ->
    let (start, (*ignore*)_error, (*ignore*)_cutpoint, transitions) = lts in
    let pvar_of s = Ident.Pvar ("state_" ^ s) in
    let tenv_of =
      match live_vars with
      | None ->
        let tenv = Set.Poly.to_list @@ Set.Poly.filter ~f:(fun (x, _) -> not @@ String.is_prefix ~prefix:LTS.Problem.nondet_prefix @@ Ident.name_of_tvar x) @@ LTS.Problem.term_sort_env_of lts in
        fun _ -> tenv
      | Some live_vars -> fun s -> try Set.Poly.to_list (live_vars s) with Caml.Not_found -> failwith ("not found: " ^ s)
    in
    Debug.print @@ lazy (Printf.sprintf "LTS:\n%s" @@ LTS.Problem.str_of_lts lts);
    let preds =
      List.classify (fun (s1, _, _) (s2, _, _) -> String.(s1 = s2)) transitions
      |> List.map ~f:(function
          | [] -> assert false
          | (from, c, to_) :: trs ->
            let next =
              (c, to_) :: List.map trs ~f:(fun (_, c, to_) -> c, to_)
              |> List.map ~f:(fun (c, to_) ->
                  let pvar = pvar_of to_ in
                  let senv = tenv_of to_ in
                  let phi = LTS.Problem.wp c
                      (Formula.mk_atom @@ Atom.pvar_app_of_senv (pvar, senv)) in
                  let nondet_tenv = Set.Poly.to_list @@
                    Set.Poly.filter (Formula.term_sort_env_of phi) ~f:(fun (x, _) ->
                        String.is_prefix ~prefix:LTS.Problem.nondet_prefix @@ Ident.name_of_tvar x)
                  in
                  Formula.mk_forall_if_bounded nondet_tenv phi)
              |> Formula.and_of
            in
            Pred.make
              (match cut_points with None -> Predicate.Mu | Some cut_points -> if Set.Poly.mem cut_points from then Predicate.Mu else Predicate.Nu)
              (pvar_of from)
              (tenv_of from)
              next)
    in
    (match start with
     | None ->
       assert (List.is_empty transitions);
       make [] (Formula.mk_true ())
     | Some start ->
       let undef_preds =
         Set.Poly.diff
           (Set.Poly.add (Set.Poly.of_list @@ List.map transitions ~f:(fun (_, _, _to) -> _to)) start)
           (Set.Poly.of_list @@ List.map transitions ~f:(fun (from, _, _) -> from))
         |> Set.Poly.map ~f:(fun from -> Pred.make Predicate.Mu (pvar_of from) (tenv_of from) (Formula.mk_true ()))
         |> Set.Poly.to_list
       in
       let query =
         let tenv = tenv_of start in
         Formula.mk_forall_if_bounded tenv @@
         Formula.mk_atom @@
         Atom.mk_pvar_app (pvar_of start) (List.map ~f:snd tenv) (Term.of_sort_env tenv) in
       make (preds @ undef_preds) query)
  | lts, LTS.Problem.NonTerm -> get_dual @@ of_lts ~live_vars ~cut_points (lts, LTS.Problem.Term)
  | _, (LTS.Problem.Safe | LTS.Problem.NonSafe | LTS.Problem.CondTerm | LTS.Problem.Rel | LTS.Problem.MuCal) -> assert false

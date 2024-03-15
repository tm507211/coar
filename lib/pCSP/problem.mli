open Core
open Common.Ext
open Ast
open Ast.Logic
open Common.Messenger

type t

type solution = Sat of term_subst_map | Unsat | Unknown | OutSpace of Ident.tvar list
type oracle = CandSolOld.t option

type bounds = (Ident.tvar, int * (sort_env_map * term)) Map.Poly.t
type info +=
  | CandidateSolution of
      (term_subst_map * term_subst_map * ClauseSet.t * ClauseSet.t *
       (sort_env_map * Ast.LogicOld.FunEnv.t * (Ident.tvar, Logic.term) Hashtbl.Poly.t) option)
  | LowerBounds of bounds
  | UpperBounds of bounds

exception Timeout

module type ProblemType = sig val problem : t end

val of_formulas : ?params:Params.t -> (sort_env_map * term) Set.Poly.t -> t
val of_clauses : ?params:Params.t -> Clause.t Set.Poly.t -> t

val to_nnf : t -> t
val to_cnf : t -> t

val params_of : t -> Params.t
val unpreprocessable_clauses_of : t -> ClauseSet.t
val clauses_of : ?full_clauses:bool -> t -> ClauseSet.t
val formulas_of : ?full_clauses:bool -> t -> (sort_env_map * term) Set.Poly.t
val formula_of : ?full_clauses:bool -> t -> term
val senv_of : t -> sort_env_map
val kind_map_of : t -> Kind.kind_map
val dtenv_of : t -> LogicOld.DTEnv.t
val dtenv_of_def : t -> LogicOld.DTEnv.t
val fenv_of : t -> LogicOld.FunEnv.t
val messenger_of : t -> Common.Messenger.t option
val sol_for_eliminated_of : t -> term_subst_map
val args_record_of : t -> (Ident.pvar, bool array * Sort.t list) Map.Poly.t
val partial_sol_targets_of : t -> (Ident.tvar, Params.random_info Set.Poly.t) Map.Poly.t
val dep_graph_of : t -> (Ident.tvar, Ident.tvar Set.Poly.t) Map.Poly.t
val wfpvs_senv_of : t -> sort_env_map
val fnpvs_senv_of : t -> sort_env_map
val nepvs_senv_of : t -> sort_env_map
val sol_space_of : t -> SolSpace.t
val nwfpvs_senv_of : t -> (Ident.tvar, Ident.tvar * Sort.t list * Ident.tvar * Sort.t list * Ident.tvar * Sort.t list) Map.Poly.t
val wfpvs_of : t -> Ident.tvar Set.Poly.t
val fnpvs_of : t -> Ident.tvar Set.Poly.t
val nwfpvs_of : t -> Ident.tvar Set.Poly.t
val nepvs_of : t -> Ident.tvar Set.Poly.t

val num_constrs : t -> int
val num_pvars : t -> int

(** all non-predicate function variables *)
val npfvs_of : t -> Ident.tvar Set.Poly.t
(** all predicate variables including well-founded, functional, and non-empty ones *)
val pvs_of : t -> Ident.tvar Set.Poly.t

val is_wf_pred : t -> Ast.Ident.tvar -> bool
val is_fn_pred : t -> Ast.Ident.tvar -> bool
val is_ord_pred : t -> Ast.Ident.tvar -> bool
val is_nwf_pred : t -> Ast.Ident.tvar -> bool
val is_ne_pred : t -> Ast.Ident.tvar -> bool
val is_int_fun : t -> Ast.Ident.tvar -> bool

val map_if_raw_old : f:((LogicOld.sort_env_map * LogicOld.Formula.t) Set.Poly.t ->
                        (LogicOld.sort_env_map * LogicOld.Formula.t) Set.Poly.t) -> t -> t
val map_if_raw : f:((sort_env_map * term) Set.Poly.t -> (sort_env_map * term) Set.Poly.t) -> t -> t

(*val str_of_pvars: pvars -> string
  val str_of_clause : clause -> string *)
val str_of : t -> string
(*val str_of_senv : t -> string*)
val str_of_info : t -> string
val str_of_solution : solution -> string
val str_of_sygus_solution : solution -> string
val to_yojson : t -> Yojson.Safe.t

val add_non_emptiness : LogicOld.pred_bind -> t -> t
val add_formula : (sort_env_map * term) -> t -> t
val add_clause : Clause.t -> t -> t
val divide : t -> t list

val merge_sols : t -> solution list -> solution
val extend_sol : solution -> term_subst_map -> solution
(*val nest_subst : term_subst_map -> term_subst_map*)

val instantiate_svars_to_int : t -> t
val normalize : t -> t

val of_sygus : SyGuS.Problem.Make(SyGuS.Problem.ExtTerm).t -> t
val of_lts : LTS.Problem.t -> t

val remove_unused_params : t -> t

val update_params : t -> Params.t -> t
val map_params : f:(Params.t -> Params.t) -> t -> t
val update_params_dtenv : t -> t
val update_params_sol_space : t -> SolSpace.t -> t
val normalize_uni_senv : t -> t
val id_of : t -> int option
val ast_size_of : t -> int
val tag_of : t -> Ident.tvar -> (Ident.tvar * Ident.tvar) option
val recover_elimed_params_of_sol : (Ident.pvar, bool array * Sort.t list) Map.Poly.t ->
  term_subst_map -> term_subst_map
val sol_of_candidate : t -> CandSol.t -> term_subst_map
val elim_dup_nwf_predicate : t -> t
val merge_clauses : t -> t

val is_qualified_partial_solution : Ident.tvar Set.Poly.t -> Ident.tvar Set.Poly.t -> ClauseSet.t -> bool

val make :
  ?skolem_pred:bool ->
  LogicOld.Formula.t list * 'a *
  LogicOld.pred_sort_env_set * LogicOld.pred_sort_env_set * LogicOld.pred_sort_env_set *
  (Ident.tvar,
   LogicOld.sort_env_list * LogicOld.Sort.t * LogicOld.Term.t * bool * LogicOld.Formula.t)
    Map.Poly.t *
  (string, LogicOld.Datatype.t) Map.Poly.t -> t

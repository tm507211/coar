open Core
open Common.Util

module type SolverType = sig
  val string_of_pcsp : PCSP.Problem.t -> string
  val print_pcsp: PCSP.Problem.t -> unit Or_error.t
  val print_muclp: MuCLP.Problem.t -> unit
  val print_lts: LTS.Problem.t -> unit
end

module Make (Config: Config.ConfigType): SolverType = struct
  let config = Config.config

  let pvar_eliminator = let open Or_error in
    ExtFile.unwrap config.pvar_eliminator >>= fun cfg ->
    Ok (PCSat.PvarEliminator.make cfg)

  let string_of_pcsp pcsp =
    match config.smt_format with
    | SMT2 ->  (Smtlib2.of_pcsp pcsp)
    | _ ->  (PCSP.Problem.str_of pcsp)
  let print_pcsp pcsp =
    let open Or_error in
    pvar_eliminator >>= fun (module PvarEliminator : PCSat.PvarEliminator.PvarEliminatorType) ->
    let _, pcsp = PvarEliminator.preprocess ~bpvs:Set.Poly.empty pcsp in
    match config.smt_format with
    | SMT2 -> return @@ print_endline (Smtlib2.of_pcsp pcsp)
    | String -> return @@ print_endline (PCSP.Problem.str_of pcsp)
  let print_muclp muclp =
    print_endline (MuCLP.Problem.str_of muclp)
  let print_lts lts =
    match config.lts_format with
    | PCSP -> print_endline (PCSP.Problem.str_of (PCSP.Problem.of_lts lts))
    | MuCLP -> print_endline (MuCLP.Problem.str_of (MuCLP.Problem.of_lts lts))
end
let make (config : Config.t) =
  (module Make (struct let config = config end) : SolverType)
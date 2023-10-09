open Core

module Config = struct

  type t =
    (* SAT solvers *)
    | Z3Sat of Z3Sat.Config.t (** configuration of Z3Sat *)
    | Minisat of MINISAT.Config.t (** configuration of Minisat *)
    (* SMT solvers *)
    | Z3Smt of Z3Smt.Config.t (** configuration of Z3Smt *)
    (* CHC/pCSP/pfwCSP solvers *)
    | PCSat of PCSat.Config.t (** configuration of PCSat *)
    | SPACER of SPACER.Config.t (** configuration of SPACER *)
    | Hoice of Hoice.Config.t (** configuration of Hoice *)
    (* CHC optimizers *)
    | OptPCSat of OptPCSat.Config.t
    (* muCLP solvers *)
    | MuVal of MuVal.Config.t (** configuration of MuVal *)
    (* Refinement Type Inference and Checking Tools for OCaml *)
    | RCaml of RCaml.Config.t (** configuration of RCaml *)
    (* printers *)
    | Printer of Printer.Config.t
  [@@deriving yojson]

  module type ConfigType = sig val config : t end

  let instantiate_ext_files = let open Or_error in
    function
    | Z3Sat cfg ->
      Z3Sat.Config.instantiate_ext_files cfg >>= fun cfg -> Ok (Z3Sat cfg)
    | Minisat cfg ->
      MINISAT.Config.instantiate_ext_files cfg >>= fun cfg -> Ok (Minisat cfg)

    | Z3Smt cfg ->
      Z3Smt.Config.instantiate_ext_files cfg >>= fun cfg -> Ok (Z3Smt cfg)

    | PCSat cfg ->
      PCSat.Config.instantiate_ext_files cfg >>= fun cfg -> Ok (PCSat cfg)
    | SPACER cfg ->
      SPACER.Config.instantiate_ext_files cfg >>= fun cfg -> Ok (SPACER cfg)
    | Hoice cfg ->
      Hoice.Config.instantiate_ext_files cfg >>= fun cfg -> Ok (Hoice cfg)

    | OptPCSat cfg ->
      OptPCSat.Config.instantiate_ext_files cfg >>= fun cfg -> Ok (OptPCSat cfg)

    | MuVal cfg ->
      MuVal.Config.instantiate_ext_files cfg >>= fun cfg -> Ok (MuVal cfg)

    | RCaml cfg ->
      RCaml.Config.instantiate_ext_files cfg >>= fun cfg -> Ok (RCaml cfg)

    | Printer cfg ->
      Printer.Config.instantiate_ext_files cfg >>= fun cfg -> Ok (Printer cfg)

  let load_config filename =
    let open Or_error in
    try_with (fun () -> Yojson.Safe.from_file filename) >>= fun raw_json ->
    match of_yojson raw_json with
    | Ok x -> instantiate_ext_files x
    | Error msg ->
      error_string @@ sprintf "Invalid Solver Configuration (%s): %s" filename msg
end

module type SolverType = sig
  val solve_sat : SAT.Problem.t -> unit Or_error.t
  val solve_smt : SMT.Problem.t -> unit Or_error.t
  val solve_sygus : ?filename:(string option) -> SyGuS.Problem.Make(SyGuS.Problem.ExtTerm).t -> unit Or_error.t
  val solve_pcsp : ?bpvs:(Ast.Ident.tvar Set.Poly.t) -> ?filename:(string option) -> PCSP.Problem.t -> unit Or_error.t
  val solve_chcopt : ?filename:(string option) -> CHCOpt.Problem.t -> unit Or_error.t
  val solve_muclp : MuCLP.Problem.t -> unit Or_error.t
  val solve_muclp_interactive : MuCLP.Problem.t -> unit Or_error.t
  val solve_lts : print:(string lazy_t -> unit) -> LTS.Problem.t -> unit Or_error.t
  val solve_lts_interactive : print:(string lazy_t -> unit) -> LTS.Problem.lts -> unit Or_error.t
  val solve_plts : print:(string lazy_t -> unit) -> PLTS.Problem.t -> unit Or_error.t
  val solve_ml : string -> unit Or_error.t
end

module Make (Config: Config.ConfigType) : SolverType = struct
  open Or_error.Monad_infix
  let solve_sat cnf =
    match Config.config with
    | Z3Sat cfg ->
      let module Z3Sat = Z3Sat.Solver.Make(struct let config = cfg end) in
      Z3Sat.solve ~print_sol:true cnf >>= fun _ -> Ok ()
    | Minisat cfg ->
      let module MINISAT = MINISAT.Solver.Make(struct let config = cfg end) in
      MINISAT.solve ~print_sol:true cnf >>= fun _ -> Ok ()
    | _ -> Or_error.unimplemented "Solver.solve_sat"
  let solve_smt phi =
    match Config.config with
    | Z3Smt cfg ->
      let module Z3Smt = Z3Smt.Solver.Make(struct let config = cfg end) in
      Z3Smt.solve ~print_sol:true phi >>= fun _ -> Ok ()
    | _ -> Or_error.unimplemented "Solver.solve_smt"
  let solve_sygus ?(filename=None) sygus =
    let pcsp = PCSP.Problem.of_sygus sygus in
    match Config.config with
    | PCSat cfg ->
      let module PCSat = PCSat.Solver.Make(struct let config = cfg end) in
      PCSat.solve ~filename ~print_sol:true pcsp >>= fun (solution, _) ->
      Out_channel.print_endline (PCSP.Problem.str_of_solution solution);
      Out_channel.flush stdout;
      Ok ()
    | SPACER cfg ->
      let module SPACER = SPACER.Solver.Make(struct let config = cfg end) in
      SPACER.solve pcsp >>= fun solution ->
      Out_channel.print_endline (PCSP.Problem.str_of_solution solution);
      Out_channel.flush stdout;
      Ok ()
    | Hoice cfg ->
      let module Hoice = Hoice.Solver.Make(struct let config = cfg end) in
      Hoice.solve pcsp >>= fun solution ->
      Out_channel.print_endline (PCSP.Problem.str_of_solution solution);
      Out_channel.flush stdout;
      Ok ()
    | MuVal cfg ->
      let module MuVal = MuVal.Solver.Make(struct let config = cfg end) in
      MuVal.solve_pcsp ~print_sol:true pcsp >>= fun (solution, _) ->
      Out_channel.print_endline (PCSP.Problem.str_of_solution solution);
      Out_channel.flush stdout;
      Ok ()
    | Printer cfg ->
      let module Printer = Printer.Solver.Make(struct let config = cfg end) in
      Printer.print_pcsp pcsp >>= fun _ -> Ok ()
    | _ -> Or_error.unimplemented "Solver.solve_sygus"
  let solve_pcsp ?(bpvs=Set.Poly.empty) ?(filename=None) pcsp =
    match Config.config with
    | PCSat cfg ->
      let module PCSat = PCSat.Solver.Make(struct let config = cfg end) in
      PCSat.solve ~bpvs ~filename ~print_sol:true pcsp >>= fun _ -> Ok ()
    | SPACER cfg ->
      let module SPACER = SPACER.Solver.Make(struct let config = cfg end) in
      SPACER.solve ~print_sol:true pcsp >>= fun _ -> Ok ()
    | Hoice cfg ->
      let module Hoice = Hoice.Solver.Make(struct let config = cfg end) in
      Hoice.solve ~print_sol:true pcsp >>= fun _ -> Ok ()
    | MuVal cfg ->
      let module MuVal = MuVal.Solver.Make(struct let config = cfg end) in
      MuVal.solve_pcsp ~print_sol:true pcsp >>= fun _ -> Ok ()
    | Printer cfg ->
      let module Printer = Printer.Solver.Make(struct let config = cfg end) in
      Printer.print_pcsp pcsp >>= fun _ -> Ok ()
    | _ -> Or_error.unimplemented "Solve.solve_pcsp"
  let solve_chcopt ?(filename=None) chcopt =
    match Config.config with
    | OptPCSat cfg ->
      let module OptPCSat = OptPCSat.Solver.Make(struct let config = cfg end) in
      OptPCSat.solve ~filename ~print_sol:true chcopt |> fun _ -> Ok ()
    | _ -> Or_error.unimplemented "Solver.solve_chcopt"
  let solve_muclp muclp =
    match Config.config with
    | MuVal cfg ->
      let module MuVal = MuVal.Solver.Make(struct let config = cfg end) in
      MuVal.solve ~print_sol:true muclp >>= fun _ -> Ok ()
    | Printer cfg ->
      let module Printer = Printer.Solver.Make(struct let config = cfg end) in
      Printer.print_muclp muclp; Ok ()
    | _ -> Or_error.unimplemented "Solver.solve_muclp"
  let solve_muclp_interactive muclp =
    match Config.config with
    | MuVal cfg ->
      let module MuVal = MuVal.Solver.Make(struct let config = cfg end) in
      MuVal.solve_interactive muclp >>= fun _ -> Ok ()
    | _ -> Or_error.unimplemented "Solver.solve_muclp_interactive"
  let solve_lts ~print (lts, mode) =
    match Config.config with
    | PCSat cfg ->
      let module PCSat = PCSat.Solver.Make(struct let config = cfg end) in
      PCSat.solve ~print_sol:false (PCSP.Problem.of_lts (lts, mode)) >>= fun (sol, _) ->
      print_endline @@ PCSP.Problem.lts_str_of_solution sol;
      Ok ()
    | MuVal _ ->
      let muclp =
        let lvs, cps, lts = LTS.Problem.analyze ~print lts in
        MuCLP.Problem.of_lts ~live_vars:(Some lvs) ~cut_points:(Some cps) (lts, mode)
      in
      begin
        match Config.config with
        | MuVal cfg ->
          let module MuVal = MuVal.Solver.Make(struct let config = cfg end) in
          MuVal.solve ~print_sol:false muclp >>= fun (solution, _, _) ->
          print_endline @@ MuCLP.Problem.lts_str_of_solution solution;
          Ok ()
        | _ -> assert false
      end
    | Printer cfg ->
      let module Printer = Printer.Solver.Make(struct let config = cfg end) in
      Printer.print_lts (lts, mode); Ok ()
    | _ -> Or_error.unimplemented "Solve.solve_lts"
  let solve_lts_interactive ~print lts =
    match Config.config with
    | MuVal cfg ->
      let muclp =
        let lvs, cps, lts = LTS.Problem.analyze ~print lts in
        MuCLP.Problem.of_lts ~live_vars:(Some lvs) ~cut_points:(Some cps) (lts, LTS.Problem.Term)
      in
      let module MuVal = MuVal.Solver.Make(struct let config = cfg end) in
      MuVal.solve_interactive muclp >>= fun _ -> Ok ()
    | _ -> Or_error.unimplemented "Solver.solve_lts_interactive"
  let solve_plts ~print (plts, mode) =
    let lts = PLTS.Problem.lts_of ~print plts in
    let mode = PLTS.Problem.lts_mode_of mode in
    match Config.config with
    | PCSat cfg ->
      let module PCSat = PCSat.Solver.Make(struct let config = cfg end) in
      PCSat.solve ~print_sol:true (PCSP.Problem.of_lts (lts, mode)) >>= fun _ -> Ok ()
    | MuVal _ ->
      let muclp =
        let lvs, cps, lts = LTS.Problem.analyze ~print lts in
        MuCLP.Problem.of_lts ~live_vars:(Some lvs) ~cut_points:(Some cps) (lts, mode)
      in
      begin
        match Config.config with
        | MuVal cfg ->
          let module MuVal = MuVal.Solver.Make(struct let config = cfg end) in
          MuVal.solve ~print_sol:false muclp >>= fun (solution, _, _) ->
          print_endline @@ MuCLP.Problem.lts_str_of_solution solution;
          Ok ()
        | _ -> assert false
      end
    | Printer cfg ->
      let module Printer = Printer.Solver.Make(struct let config = cfg end) in
      Printer.print_lts (lts, mode); Ok ()
    | _ -> Or_error.unimplemented "Solve.solve_plts"
  let solve_ml filename =
    match Config.config with
    | RCaml cfg ->
      let module RCaml = RCaml.Solver.Make(struct let config = cfg end) in
      RCaml.solve_from_file ~print_sol:true filename >>= fun _ -> Ok ()
    | _ -> Or_error.unimplemented "Solver.solve_ml"
end

open Core
open Common.Util

type mode =
  | NoSideCond
  | NonTrivial
  | NonVacuous
[@@deriving yojson]

type t = {
  load_init_sol : bool;
  improve_solver : PCSPSolver.Config.t ext_file;
  opt_check_solver : PCSPSolver.Config.t ext_file;
  verbose : bool;
  one_by_one : bool;
  improve_current : bool;
  mode : mode
} [@@ deriving yojson]
module type ConfigType = sig val config : t end

let is_non_trival_mode = function
  | NonTrivial -> true | _ -> false
let is_non_vacuous_mode = function
  | NonVacuous -> true | _ -> false

let instantiate_ext_files cfg = let open Or_error in
  PCSPSolver.Config.load_ext_file cfg.improve_solver >>= fun improve_solver ->
  PCSPSolver.Config.load_ext_file cfg.opt_check_solver >>= fun opt_check_solver ->
  Ok { cfg with improve_solver=improve_solver; opt_check_solver=opt_check_solver }

let load_ext_file = function
  | ExtFile.Filename filename ->
    begin
      let open Or_error in
      try_with (fun () -> Yojson.Safe.from_file filename)
      >>= fun raw_json ->
      match of_yojson raw_json with
      | Ok x ->
        instantiate_ext_files x >>= fun x ->
        Ok (ExtFile.Instance x)
      | Error msg ->
        error_string @@ Printf.sprintf
          "Invalid OptPCSat Configuration (%s): %s" filename msg
    end
  | Instance x -> Ok (Instance x)

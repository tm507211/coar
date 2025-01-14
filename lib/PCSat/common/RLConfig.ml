open Core
open Common.Util

type t = {
  enable: bool;
  show_num_constrs: bool;
  show_num_pvars: bool;
  show_num_args: bool;
  show_user_time: bool;
  show_elapsed_time: bool;
  show_constraints: bool;
  show_candidates: bool;
  show_examples: bool;
  show_unsat_core: bool;
  ask_smt_timeout: bool
} [@@ deriving yojson]

module type ConfigType = sig val config: t end

let instantiate_ext_files cfg = Ok cfg

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
          "Invalid RL Configuration (%s): %s" filename msg
    end
  | Instance x -> Ok (Instance x)

let disabled : t = {
  enable = false;
  show_num_constrs = false;
  show_num_pvars = false;
  show_num_args = false;
  show_user_time = false;
  show_elapsed_time = false;
  show_constraints = false;
  show_candidates = false;
  show_examples = false;
  show_unsat_core = false;
  ask_smt_timeout = false
}

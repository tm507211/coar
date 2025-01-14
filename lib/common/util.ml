open Core
open Ext

module ExtFile = struct
  type 'a t = Filename of string | Instance of 'a [@@deriving yojson]

  let unwrap = function
    | Filename name ->
      Error
        (Error.of_thunk (fun () ->
             Printf.sprintf "Filename %s cannot unwrap" name))
    | Instance a -> Ok a

  let unwrap_or_abort = function
    | Filename name ->
      ignore (Printf.printf "Filename %s cannot unwrap" name);
      assert false
    | Instance a -> a
end
(** type alias for convinience *)
type 'a ext_file = 'a ExtFile.t [@@deriving yojson]

(** Ordinals *)
module Ordinal : sig
  type t

  val make : int -> t
  (*val pr : Format.formatter -> t -> unit*)
  val string_of : t -> string
end = struct
  type t = int

  let make n = n

  (*let pr ppf n =
    if n = 11 || n = 12 || n = 13 then
      Format.fprintf ppf "%dth" n
    else
      match n mod 10 with
      | 1 -> Format.fprintf ppf "%dst" n
      | 2 -> Format.fprintf ppf "%dnd" n
      | 3 -> Format.fprintf ppf "%drd" n
      | _ -> Format.fprintf ppf "%dth" n
    let string_of = Printer.string_of pr*)
  let string_of n =
    if n = 11 || n = 12 || n = 13 then Printf.sprintf "%dth" n
    else
      Printf.sprintf
        ( match n mod 10 with
          | 1 -> "%dst"
          | 2 -> "%dnd"
          | 3 -> "%drd"
          | _ -> "%dth" )
        n
end

(** Pairs *)
module Pair = struct
  let make x1 x2 = (x1, x2)

  let of_list = function [x1; x2] -> (x1, x2) | _ -> failwith ""
  let list_of (x1, x2) = [x1; x2]

  let map f1 f2 (x1, x2) = (f1 x1, f2 x2)
  let map_fst f (x1, x2) = (f x1, x2)
  let map_snd f (x1, x2) = (x1, f x2)
  let map2 f1 f2 (x1, x2) (y1, y2) = (f1 x1 y1, f2 x2 y2)

  let fold f (x1, x2) = f x1 x2
  let lift f (x1, x2) = (f x1, f x2)
  let lift2 f (x1, x2) (y1, y2) = (f x1 y1, f x2 y2)
  let unfold f1 f2 x = (f1 x, f2 x)

  let pr epr1 epr2 ppf (x1, x2) =
    Format.fprintf ppf "@[(@[<hov>%a,@ %a@])@]" epr1 x1 epr2 x2

  let flip (x1, x2) = (x2, x1)
end

(** Triples *)
module Triple = struct
  let make x1 x2 x3 = (x1, x2, x3)

  let of_list = function [x1; x2; x3] -> (x1, x2, x3) | _ -> failwith ""
  let list_of (x1, x2, x3) = [x1; x2; x3]

  let fst (x1, _x2, _x3) = x1
  let snd (_x1, x2, _x3) = x2
  let trd (_x1, _x2, x3) = x3

  let get12 (x1, x2, _x3) = (x1, x2)
  let get13 (x1, _x2, x3) = (x1, x3)
  let get21 (x1, x2, _x3) = (x2, x1)
  let get23 (_x1, x2, x3) = (x2, x3)
  let get31 (x1, _x2, x3) = (x3, x1)
  let get32 (_x1, x2, x3) = (x3, x2)

  let get123 (x1, x2, x3) = (x1, x2, x3)
  let get132 (x1, x2, x3) = (x1, x3, x2)
  let get213 (x1, x2, x3) = (x2, x1, x3)
  let get231 (x1, x2, x3) = (x2, x3, x1)
  let get312 (x1, x2, x3) = (x3, x1, x2)
  let get321 (x1, x2, x3) = (x3, x2, x1)

  let map f1 f2 f3 (x1, x2, x3) = (f1 x1, f2 x2, f3 x3)
  let map_fst f (x1, x2, x3) = (f x1, x2, x3)
  let map_snd f (x1, x2, x3) = (x1, f x2, x3)
  let map_trd f (x1, x2, x3) = (x1, x2, f x3)

  let fold f (x1, x2, x3) = f x1 x2 x3
  let lift f (x1, x2, x3) = (f x1, f x2, f x3)
  let unfold f1 f2 f3 x = (f1 x, f2 x, f3 x)

  let pr epr1 epr2 epr3 ppf (x1, x2, x3) =
    Format.fprintf ppf "(@[<hov>%a,@ %a,@ %a@])" epr1 x1 epr2 x2 epr3 x3
end

(** Quadruples *)
module Quadruple = struct
  let make x1 x2 x3 x4 = (x1, x2, x3, x4)

  let of_list = function [x1; x2; x3; x4] -> (x1, x2, x3, x4) | _ -> failwith ""
  let list_of (x1, x2, x3, x4) = [x1; x2; x3; x4]

  let fst (x1, _x2, _x3, _x4) = x1
  let snd (_x1, x2, _x3, _x4) = x2
  let trd (_x1, _x2, x3, _x4) = x3
  let fth (_x1, _x2, _x3, x4) = x4

  let get12 (x1, x2, _x3, _x4) = (x1, x2)
  let get13 (x1, _x2, x3, _x4) = (x1, x3)
  let get14 (x1, _x2, _x3, x4) = (x1, x4)
  let get21 (x1, x2, _x3, _x4) = (x2, x1)
  let get23 (_x1, x2, x3, _x4) = (x2, x3)
  let get24 (_x1, x2, _x3, x4) = (x2, x4)
  let get31 (x1, _x2, x3, _x4) = (x3, x1)
  let get32 (_x1, x2, x3, _x4) = (x3, x2)
  let get34 (_x1, _x2, x3, x4) = (x3, x4)
  let get41 (x1, _x2, _x3, x4) = (x4, x1)
  let get42 (_x1, x2, _x3, x4) = (x4, x2)
  let get43 (_x1, _x2, x3, x4) = (x4, x3)

  let get123 (x1, x2, x3, _x4) = (x1, x2, x3)
  let get124 (x1, x2, _x3, x4) = (x1, x2, x4)
  let get132 (x1, x2, x3, _x4) = (x1, x3, x2)
  let get134 (x1, _x2, x3, x4) = (x1, x3, x4)
  let get142 (x1, x2, _x3, x4) = (x1, x4, x2)
  let get143 (x1, _x2, x3, x4) = (x1, x4, x3)
  let get213 (x1, x2, x3, _x4) = (x2, x1, x3)
  let get214 (x1, x2, _x3, x4) = (x2, x1, x4)
  let get231 (x1, x2, x3, _x4) = (x2, x3, x1)
  let get234 (_x1, x2, x3, x4) = (x2, x3, x4)
  let get241 (x1, x2, _x3, x4) = (x2, x4, x1)
  let get243 (_x1, x2, x3, x4) = (x2, x4, x3)
  let get312 (x1, x2, x3, _x4) = (x3, x1, x2)
  let get314 (x1, _x2, x3, x4) = (x3, x1, x4)
  let get321 (x1, x2, x3, _x4) = (x3, x2, x1)
  let get324 (_x1, x2, x3, x4) = (x3, x2, x4)
  let get341 (x1, _x2, x3, x4) = (x3, x4, x1)
  let get342 (_x1, x2, x3, x4) = (x3, x4, x2)
  let get412 (x1, x2, _x3, x4) = (x4, x1, x2)
  let get413 (x1, _x2, x3, x4) = (x4, x1, x3)
  let get421 (x1, x2, _x3, x4) = (x4, x2, x1)
  let get423 (_x1, x2, x3, x4) = (x4, x2, x3)
  let get431 (x1, _x2, x3, x4) = (x4, x3, x1)
  let get432 (_x1, x2, x3, x4) = (x4, x3, x2)

  let map f1 f2 f3 f4 (x1, x2, x3, x4) = (f1 x1, f2 x2, f3 x3, f4 x4)
  let map_fst f (x1, x2, x3, x4) = (f x1, x2, x3, x4)
  let map_snd f (x1, x2, x3, x4) = (x1, f x2, x3, x4)
  let map_trd f (x1, x2, x3, x4) = (x1, x2, f x3, x4)
  let map_fth f (x1, x2, x3, x4) = (x1, x2, x3, f x4)

  let fold f (x1, x2, x3, x4) = f x1 x2 x3 x4
  let lift f (x1, x2, x3, x4) = (f x1, f x2, f x3, f x4)
  let unfold f1 f2 f3 f4 x = (f1 x, f2 x, f3 x, f4 x)

  let pr epr1 epr2 epr3 epr4 ppf (x1, x2, x3, x4) =
    Format.fprintf ppf "(@[<hov>%a,@ %a,@ %a,@ %a@])"
      epr1 x1 epr2 x2 epr3 x3 epr4 x4
end

(** Quintuples *)
module Quintuple = struct
  let make x1 x2 x3 x4 x5 = (x1, x2, x3, x4, x5)

  let of_list = function [x1; x2; x3; x4; x5] -> (x1, x2, x3, x4, x5) | _ -> failwith ""
  let list_of (x1, x2, x3, x4, x5) = [x1; x2; x3; x4; x5]

  let fst (x1, _x2, _x3, _x4, _x5) = x1
  let snd (_x1, x2, _x3, _x4, _x5) = x2
  let trd (_x1, _x2, x3, _x4, _x5) = x3
  let fth (_x1, _x2, _x3, x4, _x5) = x4
  let fifth (_x1, _x2, _x3, _x4, x5) = x5

  let get12 (x1, x2, _x3, _x4, _x5) = (x1, x2)
  let get13 (x1, _x2, x3, _x4, _x5) = (x1, x3)
  let get14 (x1, _x2, _x3, x4, _x5) = (x1, x4)
  let get15 (x1, _x2, _x3, _x4, x5) = (x1, x5)
  let get21 (x1, x2, _x3, _x4, _x5) = (x2, x1)
  let get23 (_x1, x2, x3, _x4, _x5) = (x2, x3)
  let get24 (_x1, x2, _x3, x4, _x5) = (x2, x4)
  let get25 (_x1, x2, _x3, _x4, x5) = (x2, x5)
  let get31 (x1, _x2, x3, _x4, _x5) = (x3, x1)
  let get32 (_x1, x2, x3, _x4, _x5) = (x3, x2)
  let get34 (_x1, _x2, x3, x4, _x5) = (x3, x4)
  let get35 (_x1, _x2, x3, _x4, x5) = (x3, x5)
  let get41 (x1, _x2, _x3, x4, _x5) = (x4, x1)
  let get42 (_x1, x2, _x3, x4, _x5) = (x4, x2)
  let get43 (_x1, _x2, x3, x4, _x5) = (x4, x3)
  let get45 (_x1, _x2, _x3, x4, x5) = (x4, x5)
  let get51 (x1, _x2, _x3, _x4, x5) = (x5, x1)
  let get52 (_x1, x2, _x3, _x4, x5) = (x5, x2)
  let get53 (_x1, _x2, x3, _x4, x5) = (x5, x3)
  let get54 (_x1, _x2, _x3, x4, x5) = (x5, x4)

  let get123 (x1, x2, x3, _x4, _x5) = (x1, x2, x3)
  let get124 (x1, x2, _x3, x4, _x5) = (x1, x2, x4)
  let get125 (x1, x2, _x3, _x4, x5) = (x1, x2, x5)
  let get132 (x1, x2, x3, _x4, _x5) = (x1, x3, x2)
  let get134 (x1, _x2, x3, x4, _x5) = (x1, x3, x4)
  let get135 (x1, _x2, x3, _x4, x5) = (x1, x3, x5)
  let get142 (x1, x2, _x3, x4, _x5) = (x1, x4, x2)
  let get143 (x1, _x2, x3, x4, _x5) = (x1, x4, x3)
  let get145 (x1, _x2, _x3, x4, x5) = (x1, x4, x5)
  let get152 (x1, x2, _x3, _x4, x5) = (x1, x5, x2)
  let get153 (x1, _x2, x3, _x4, x5) = (x1, x5, x3)
  let get154 (x1, _x2, _x3, x4, x5) = (x1, x5, x4)
  let get213 (x1, x2, x3, _x4, _x5) = (x2, x1, x3)
  let get214 (x1, x2, _x3, x4, _x5) = (x2, x1, x4)
  let get215 (x1, x2, _x3, _x4, x5) = (x2, x1, x5)
  let get231 (x1, x2, x3, _x4, _x5) = (x2, x3, x1)
  let get234 (_x1, x2, x3, x4, _x5) = (x2, x3, x4)
  let get235 (_x1, x2, x3, _x4, x5) = (x2, x3, x5)
  let get241 (x1, x2, _x3, x4, _x5) = (x2, x4, x1)
  let get243 (_x1, x2, x3, x4, _x5) = (x2, x4, x3)
  let get245 (_x1, x2, _x3, x4, x5) = (x2, x4, x5)
  let get251 (x1, x2, _x3, _x4, x5) = (x2, x5, x1)
  let get253 (_x1, x2, x3, _x4, x5) = (x2, x5, x3)
  let get254 (_x1, x2, _x3, x4, x5) = (x2, x5, x4)
  let get312 (x1, x2, x3, _x4, _x5) = (x3, x1, x2)
  let get314 (x1, _x2, x3, x4, _x5) = (x3, x1, x4)
  let get315 (x1, _x2, x3, _x4, x5) = (x3, x1, x5)
  let get321 (x1, x2, x3, _x4, _x5) = (x3, x2, x1)
  let get324 (_x1, x2, x3, x4, _x5) = (x3, x2, x4)
  let get325 (_x1, x2, x3, _x4, x5) = (x3, x2, x5)
  let get341 (x1, _x2, x3, x4, _x5) = (x3, x4, x1)
  let get342 (_x1, x2, x3, x4, _x5) = (x3, x4, x2)
  let get345 (_x1, _x2, x3, x4, x5) = (x3, x4, x5)
  let get351 (x1, _x2, x3, _x4, x5) = (x3, x5, x1)
  let get352 (_x1, x2, x3, _x4, x5) = (x3, x5, x2)
  let get354 (_x1, _x2, x3, x4, x5) = (x3, x5, x4)
  let get412 (x1, x2, _x3, x4, _x5) = (x4, x1, x2)
  let get413 (x1, _x2, x3, x4, _x5) = (x4, x1, x3)
  let get415 (x1, _x2, _x3, x4, x5) = (x4, x1, x5)
  let get421 (x1, x2, _x3, x4, _x5) = (x4, x2, x1)
  let get423 (_x1, x2, x3, x4, _x5) = (x4, x2, x3)
  let get425 (_x1, x2, _x3, x4, x5) = (x4, x2, x5)
  let get431 (x1, _x2, x3, x4, _x5) = (x4, x3, x1)
  let get432 (_x1, x2, x3, x4, _x5) = (x4, x3, x2)
  let get435 (_x1, _x2, x3, x4, x5) = (x4, x3, x5)
  let get451 (x1, _x2, _x3, x4, x5) = (x4, x5, x1)
  let get452 (_x1, x2, _x3, x4, x5) = (x4, x5, x2)
  let get453 (_x1, _x2, x3, x4, x5) = (x4, x5, x3)
  let get512 (x1, x2, _x3, _x4, x5) = (x5, x1, x2)
  let get513 (x1, _x2, x3, _x4, x5) = (x5, x1, x3)
  let get514 (x1, _x2, _x3, x4, x5) = (x5, x1, x4)
  let get521 (x1, x2, _x3, _x4, x5) = (x5, x2, x1)
  let get523 (_x1, x2, x3, _x4, x5) = (x5, x2, x3)
  let get524 (_x1, x2, _x3, x4, x5) = (x5, x2, x4)
  let get531 (x1, _x2, x3, _x4, x5) = (x5, x3, x1)
  let get532 (_x1, x2, x3, _x4, x5) = (x5, x3, x2)
  let get534 (_x1, _x2, x3, x4, x5) = (x5, x3, x4)
  let get541 (x1, _x2, _x3, x4, x5) = (x5, x4, x1)
  let get542 (_x1, x2, _x3, x4, x5) = (x5, x4, x2)
  let get543 (_x1, _x2, x3, x4, x5) = (x5, x4, x3)

  let map f1 f2 f3 f4 f5 (x1, x2, x3, x4, x5) =
    (f1 x1, f2 x2, f3 x3, f4 x4, f5 x5)
  let map_fst f (x1, x2, x3, x4, x5) = (f x1, x2, x3, x4, x5)
  let map_snd f (x1, x2, x3, x4, x5) = (x1, f x2, x3, x4, x5)
  let map_trd f (x1, x2, x3, x4, x5) = (x1, x2, f x3, x4, x5)
  let map_fth f (x1, x2, x3, x4, x5) = (x1, x2, x3, f x4, x5)
  let map_fifth f (x1, x2, x3, x4, x5) = (x1, x2, x3, x4, f x5)

  let fold f (x1, x2, x3, x4, x5) = f x1 x2 x3 x4 x5
  let lift f (x1, x2, x3, x4, x5) = (f x1, f x2, f x3, f x4, f x5)
  let unfold f1 f2 f3 f4 _f5 x = (f1 x, f2 x, f3 x, f4 x)

  let pr epr1 epr2 epr3 epr4 epr5 ppf (x1, x2, x3, x4, x5) =
    Format.fprintf ppf "(@[<hov>%a,@ %a,@ %a,@ %a,@ %a@])"
      epr1 x1 epr2 x2 epr3 x3 epr4 x4 epr5 x5
end

module Array2D = struct
  let remove_column a idx = Array.map a ~f:(fun a' -> Array.remove a' idx)
  let num_columns a = if Array.is_empty a then 0 else Array.length a.(0)
  let column_of a idx = Array.map a ~f:(fun a' -> a'.(idx))
end

module LexingHelper = struct
  let update_loc (lexbuf : Lexing.lexbuf) =
    let pos = lexbuf.lex_curr_p in
    lexbuf.lex_curr_p <-
      { pos with
        pos_lnum = pos.pos_lnum + 1;
        pos_bol = pos.pos_cnum; }

  let get_position_string (lexbuf : Lexing.lexbuf) =
    let pos = lexbuf.lex_curr_p in
    Printf.sprintf "%d:%d" pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)
end

module Command : sig
  exception Shell_error of string

  val async_command : string -> string list -> Core_unix.Process_channels.t
  val sync_command : string -> string list -> string list -> string list
  val output_lines : string list -> Out_channel.t -> unit
  val input_lines : In_channel.t -> string list
end = struct
  exception Shell_error of string

  let output_lines (output : string list) (chan : Out_channel.t) : unit =
    List.iter
      ~f:(fun line -> Out_channel.output_string chan (line ^ "\n"))
      output;
    Out_channel.flush chan

  let rec do_channel_lines (f : string -> 'a) (chan : In_channel.t) : 'a list =
    match In_channel.input_line chan with
    | None -> []
    | Some line -> f line :: do_channel_lines f chan

  let input_lines = do_channel_lines Fn.id

  let unlines : string list -> string = String.concat ~sep:"\n"

  let async_command (name : string) (arguments : string list) :
    Core_unix.Process_channels.t =
    Core_unix.open_process_full
      (Printf.sprintf "bash -c '%s %s 2>&1'" name (String.concat ~sep:" " arguments))
      ~env:(Core_unix.environment ())

  let sync_command (name : string) (arguments : string list)
      (input : string list) : string list =
    let pcs = async_command name arguments in
    output_lines input pcs.stdin;
    let out = input_lines pcs.stdout in
    let status = Core_unix.close_process_full pcs in
    match status with
    | Ok _ -> out
    | Error (`Exit_non_zero _) -> raise (Shell_error (unlines out))
    | Error (`Signal x) ->
      if Signal.equal x Signal.int then raise Sys_unix.Break  else out
end

module ListSet = struct
  let cup cmp s1 s2 =
    let res = List.merge ~compare:cmp s1 s2 in
    List.dedup_and_sort ~compare:cmp res

  let sub cmp s1 s2 =
    let rec rep cmp s1 s2 res =
      match s1 with
      | [] -> res
      | h1 :: t1 ->
        match s2 with
        | [] -> List.rev s1 @ res
        | h2 :: t2 ->
          let r = cmp h1 h2 in
          if r < 0 then
            rep cmp t1 s2 (h1 :: res)
          else if r > 0 then
            rep cmp s1 t2 res
          else
            rep cmp t1 s2 res
    in
    List.rev @@ rep cmp s1 s2 []

  let cap cmp s1 s2 =
    let rec rep cmp s1 s2 res =
      match s1 with
      | [] -> res
      | h1 :: t1 ->
        match s2 with
        | [] -> res
        | h2 :: t2 ->
          let r = cmp h1 h2 in
          if r < 0 then
            rep cmp t1 s2 res
          else if r > 0 then
            rep cmp s1 t2 res
          else
            rep cmp t1 s2 (h1 :: res)
    in
    List.rev @@ rep cmp s1 s2 []
end

module Task = struct
  (* Copied from Domainslib.Task*)

  type 'a task = unit -> 'a

  type 'a promise = ('a, exn) result option Atomic.t

  exception TasksActive

  type task_msg =
      Task : 'a task * 'a promise -> task_msg
    | Quit : task_msg

  type pool =
    {domains : unit Domain.t array;
     task_chan : task_msg Domainslib__Multi_channel.t}

  let do_task f p =
    try
      let res = f () in
      Atomic.set p (Some (Ok res))
    with e ->
      Atomic.set p (Some (Error e));
      match e with
      | TasksActive -> raise e
      | _ -> ()

  let setup_pool ~num_additional_domains =
    let task_chan = Domainslib__Multi_channel.make (num_additional_domains+1) in
    let rec worker () =
      match Domainslib__Multi_channel.recv task_chan with
      | Quit -> Domainslib__Multi_channel.clear_local_state task_chan;
      | Task (t, p) ->
        do_task t p;
        worker ()
    in
    let domains = Array.init num_additional_domains ~f:(fun _ -> Domain.spawn worker) in
    {domains; task_chan}

  let async pool task =
    let p = Atomic.make None in
    Domainslib__Multi_channel.send pool.task_chan (Task (task, p));
    p

  let rec await pool promise =
    match Atomic.get promise with
    | None ->
      begin
        try
          match Domainslib__Multi_channel.recv_poll pool.task_chan with
          | Task (t, p) -> do_task t p
          | Quit -> raise TasksActive
        with
        | Exit -> Domain.cpu_relax ()
      end;
      await pool promise
    | Some (Ok v) -> v
    | Some (Error e) -> raise e

  let teardown_pool pool =
    for _i=1 to Array.length pool.domains do
      Domainslib__Multi_channel.send pool.task_chan Quit
    done;
    Domainslib__Multi_channel.clear_local_state pool.task_chan;
    Array.iter ~f:Domain.join pool.domains

  let parallel_for_reduce ?(chunk_size=0) ~start ~finish ~body pool reduce_fun init =
    let chunk_size = if chunk_size > 0 then chunk_size
      else begin
        let n_domains = (Array.length pool.domains) + 1 in
        let n_tasks = finish - start + 1 in
        if n_domains = 1 then n_tasks
        else max 1 (n_tasks/(8*n_domains))
      end
    in
    let rec work s e =
      if e - s < chunk_size then
        let rec loop i acc =
          if i > e then acc
          else loop (i+1) (reduce_fun acc (body i))
        in
        loop s init
      else begin
        let d = s + ((e - s) / 2) in
        let p = async pool (fun _ -> work s d) in
        let right = work (d+1) e in
        let left = await pool p in
        reduce_fun left right
      end
    in
    work start finish

  let parallel_for ?(chunk_size=0) ~start ~finish ~body pool =
    let chunk_size = if chunk_size > 0 then chunk_size
      else begin
        let n_domains = (Array.length pool.domains) + 1 in
        let n_tasks = finish - start + 1 in
        if n_domains = 1 then n_tasks
        else max 1 (n_tasks/(8*n_domains))
      end
    in
    let rec work pool fn s e =
      if e - s < chunk_size then
        for i = s to e do fn i done
      else begin
        let d = s + ((e - s) / 2) in
        let left = async pool (fun _ -> work pool fn s d) in
        work pool fn (d+1) e;
        await pool left
      end
    in
    work pool body start finish

  let parallel_scan pool op elements =
    let scan_part op elements prefix_sum start finish =
      assert (Array.length elements > (finish - start));
      for i = (start + 1) to finish do
        prefix_sum.(i) <- op prefix_sum.(i - 1) elements.(i)
      done
    in
    let add_offset op prefix_sum offset start finish =
      assert (Array.length prefix_sum > (finish - start));
      for i = start to finish do
        prefix_sum.(i) <- op offset prefix_sum.(i)
      done
    in
    let n = Array.length elements in
    let p = (Array.length pool.domains) + 1 in
    let prefix_s = Array.copy elements in
    parallel_for pool ~chunk_size:1 ~start:0 ~finish:(p - 1)
      ~body:(fun i ->
          let s = (i * n) / (p ) in
          let e = (i + 1) * n / (p ) - 1 in
          scan_part op elements prefix_s s e);
    if (p > 2) then begin
      let x = ref prefix_s.(n/p - 1) in
      for i = 2 to p do
        let ind = i * n / p - 1 in
        x := op prefix_s.(ind) !x;
        prefix_s.(ind) <- !x
      done
    end;
    parallel_for pool ~chunk_size:1 ~start:1 ~finish:(p - 1)
      ~body:( fun i ->
          let s = i * n / (p) in
          let e = (i + 1) * n / (p) - 2 in
          let offset = prefix_s.(s - 1) in
          add_offset op prefix_s offset s e
        );
    prefix_s

  (* new functions *)
  let rec await_any_promise pool (promises : 'a promise list) =
    ignore @@ Core_unix.nanosleep 0.1;
    Domain.cpu_relax ();
    match List.find_map promises ~f:(fun promise ->
        match Atomic.get promise with
        | None -> None
        | a -> a) with
    | None -> await_any_promise pool promises
    | Some (Ok v) -> v
    | Some (Error v) -> raise v
end

(** Vectors *)
module Vector = struct
  type 'a t = 'a list

  let make v n = List.duplicate v n

  let pr_float ppf v = Format.fprintf ppf "%a" (List.pr Float.pr " ") v
  let pr_bool ppf v = Format.fprintf ppf "%a" (List.pr Bool.pr " ") v

  let map f = List.map f
  let dot xs ys = Float.sum @@ List.map2_exn xs ys ~f:(fun x y -> x *. y)
  let array_of = Array.of_list
  let of_array = Array.to_list

  (** [multiply \[x1; ... ; xm\] \[y1; ... ; yn\]]
      returns [\[f x1 y1; ... ; f x1 yn;
                 ... ;
                 f xm y1; ... ; f xm yn\]] *)
  let multiply f xs ys = List.concat_map ~f:(fun x -> List.map ~f:(f x) ys) xs

  (** [product f \[\[1; 2; 3\]; \[4\]; \[5; 6\]\]] returns
      [\[f \[1; 4; 5\]; f \[1; 4; 6\];
         f \[2; 4; 5\]; f \[2; 4; 6\];
         f \[3; 4; 5\]; f \[3; 4; 6\]\]] *)
  let product f xss =
    let rec aux ac = function
      | [] -> [f ac]
      | xs :: xss ->
        xs
        |> List.concat_map ~f:(fun x -> aux (ac @ [x]) xss)
    in
    aux [] xss

  let producti f xss =
    let cnt = ref 0 in
    let rec aux ac xss =
      match xss with
      | [] ->
        let res = [f !cnt ac] in
        cnt := !cnt + 1;
        res
      | xs :: xss ->
        xs
        |> List.concat_map ~f:(fun x -> aux (ac @ [x]) xss)
    in
    aux [] xss

  (** [product_ f \[xs1; ...; xsn\]] returns
      [multiply f (...multiply f (multiply f xs1 xs2) xs3...) xsn]
      @require n > 0 *)
  let product_ f = function
    | [] -> assert false
    | xs :: xss -> List.fold_left ~f:(multiply f) ~init:xs xss
end

(** Matrices *)
module Matrix = struct
  type 'a t = 'a Vector.t list

  let make v m n = List.duplicate (List.duplicate v n) m

  let pr_float ppf m =
    Format.fprintf ppf "@[<v>%a@]" (List.pr Vector.pr_float "@,") m

  let rec transpose xss =
    if List.for_all ~f:List.is_empty xss then []
    else
      let xs, xss =
        xss
        |> List.map ~f:(function x :: xs -> x, xs | _ -> assert false )
        |> List.unzip
      in
      xs :: transpose xss

  let cols = List.length
  let rows xss = xss |> List.hd_exn |> List.length

  let elem i j xss = List.nth_exn (List.nth_exn xss i) j

  let replace i j v xss =
    let ys = List.nth_exn xss i in
    List.take xss i
    @ [List.take ys j @ [v] @ List.drop ys (j + 1)]
    @ List.drop xss (i + 1)



  let thread xss =
    let minlength = Integer.min_list (List.map ~f:List.length xss) in
    List.map
      ~f:(fun k -> List.map ~f:(fun ys -> List.nth ys k) xss)
      (List.from_to 0 (minlength - 1))

  let row i xss = List.nth xss i

  let column i xss = List.nth (thread(*@todo replace this with transpose*) xss) i

  let diag_rd (i, j) xss =
    let n = List.length xss in
    List.from_to (-n) n
    |> List.filter ~f:(fun k -> i + k >= 0 && i + k < n && j + k >= 0 && j + k < n)
    |> List.map ~f:(fun k -> List.nth_exn (List.nth_exn xss (i + k)) (j + k))

  let diag_ld (i, j) xss =
    let n = List.length xss in
    List.from_to (-n) n
    |> List.filter ~f:(fun k -> i + k >= 0 && i + k < n && j - k >= 0 && j - k < n)
    |> List.map ~f:(fun k -> List.nth_exn (List.nth_exn xss (i + k)) (j - k))



  let map f = List.map ~f:(List.map ~f)

  let id one zero n =
    List.gen n (fun i -> List.gen n (fun j -> if i = j then one else zero))

  let array_of xss = Array.of_list (List.map ~f:Array.of_list xss)
  let of_array ar = Array.to_list (Array.map ~f:Array.to_list ar)
end

(** Bit vectors *)
module BitVector = struct
  let not =
    List.map ~f:(fun n -> if n = 0 then 1 else if n = 1 then 0 else assert false)

  let inc =
    let rec aux = function
      | [] -> assert false
      | 0 :: bv -> 1 :: bv
      | 1 :: bv -> 0 :: aux bv
      | _ -> assert false
    in
    let open Combinator in
    List.rev >> aux >> List.rev

  let dec =
    let rec aux = function
      | [] -> assert false
      | 0 :: bv -> 1 :: aux bv
      | 1 :: bv -> 0 :: bv
      | _ -> assert false
    in
    let open Combinator in
    List.rev >> aux >> List.rev

  let of_nat n =
    assert (n >= 0);
    let rec aux bv n = if n = 0 then bv else aux (n mod 2 :: bv) (n / 2) in
    if n = 0 then [0] else aux [] n

  let of_int _bits _n = assert false
(*
  if n >= 0 then of_nat bits n else inc (not (of_nat bits (-n)))
*)

  let nat_of = List.fold_left ~f:(fun x y -> x * 2 + y) ~init:0

  let int_of bv =
    if List.hd_exn bv = 0 then nat_of bv
    else if List.hd_exn bv = 1 then -nat_of (not (dec bv))
    else assert false
end

(** Graphs *)
module Graph0 = struct
  (* @todo
     walk can be of the length 0
     trail: walk with no repetition of an edge
     path: walk with no repetition of a vertex

     path <: trail <: walk

     path can be of the length 0
     # a single node is connected

     circuit: trail with the length >= 1 that starts and ends with the same vertex
     cycle: path with the length >= 1 that starts and ends with the same vertex

     cycle <: circuit

     trail/circuit is Eulerian if it contains every edge of the graph
     path/cycle is Hamitonian if it contains every vertex of the graph
  *)

  (** @todo there is a bug related to vertices? *)
  let save_graphviz filename vertices edges =
    let oc = Stdlib.open_out filename in
    let ocf = Format.make_formatter (Stdlib.output_substring oc) (fun () -> Stdlib.flush oc) in
    Format.fprintf ocf "@[<v>digraph flow {@ ";

    List.iter ~f:(fun (vertex, attribute) ->
        Format.fprintf ocf "  \"%s\" %s@ " vertex attribute)
      vertices;
    List.iter ~f:(fun (vertex1, vertex2, attribute) ->
        Format.fprintf ocf "  \"%s\" -> \"%s\" %s@ " vertex1 vertex2 attribute)
      edges;

    Format.fprintf ocf "}@]@?";
    Stdlib.close_out oc

  let succs es v =
    List.filter_map ~f:(fun (v1, v2) -> if v1 = v then Some v2 else None) es
  let preds es v =
    List.filter_map ~f:(fun (v1, v2) -> if v2 = v then Some v1 else None) es

  let rec assign es assigned v root =
    if List.Assoc.mem ~equal:Stdlib.(=) assigned v then assigned
    else
      List.fold_left
        ~f:(fun assigned v -> assign es assigned v root)
        ~init:((v, root) :: assigned)
        (preds es v)

  (** Kosaraju's algorithm *)
  let rec visit es visited l v =
    if List.mem ~equal:Stdlib.(=) visited v
    then (visited, l)
    else
      let visited, l =
        List.fold_left ~f:(Combinator.uncurry2 (visit es)) ~init:(v :: visited, l) (succs es v)
      in
      (visited, v :: l)

  let scc es =
    let vs = List.map ~f:fst es @ List.map ~f:snd es |> List.unique in
    let _, l = List.fold_left ~f:(Combinator.uncurry2 (visit es)) ~init:([], []) vs in
    List.fold_left ~f:(fun assigned v -> assign es assigned v v) ~init:[] l
end

(** Partial orders *)
module PartOrd = struct
  let is_initial ord p = List.for_all ~f:(fun (p1, p2) -> p1 <> p || p1 = p2) ord

  let preds ord p =
    List.filter_map
      ~f:(fun (p1, p2) -> if p2 = p && p1 <> p2 then Some p1 else None)
      ord
  let succs ord p =
    List.filter_map
      ~f:(fun (p1, p2) -> if p1 = p && p1 <> p2 then Some p1 else None)
      ord

  let reflexive_closure_of brel =
    brel
    |> List.concat_map ~f:(fun (e1, e2) -> [e1, e1; e1, e2; e2, e2])
    |> List.unique

  (** Warshall-Floyd algorithm @todo optimize *)
  let transitive_closure_of brel =
    let vs = List.map ~f:fst brel @ List.map ~f:snd brel |> List.unique in
    List.fold_left
      ~f:(fun brel v ->
          let open Combinator in
          let brel1 = List.filter ~f:(snd >> (=) v) brel in
          let brel2 = List.filter ~f:(fst >> (=) v) brel in
          Vector.multiply (fun (v1, _) (_, v2) -> v1, v2) brel1 brel2 @ brel
          |> List.unique)
      ~init:brel vs

  let reflexive_transitive_closure_of brel =
    brel |> transitive_closure_of |> reflexive_closure_of
end

(** Permutations *)
module Permutation = struct
  let permutations n =
    let rec aux = function
      | [] -> []
      | xs ->
        List.concat @@ List.init
          (List.length xs)
          ~f:(fun i ->
              match List.split_n xs i with
              | xs1, x :: xs2 ->
                xs1 @ xs2 |> aux |> List.map ~f:(List.cons x)
              | _ -> failwith "")
    in
    aux (List.init n ~f:Fn.id)

  let maps n1 n2 =
    let xs = List.init n1 ~f:Fn.id in
    permutations n2
    |> List.map ~f:(List.zip xs)

  let rec perm xs n =
    if n <= 0 then [[]]
    else
      xs
      |> List.mapc (fun f x -> List.map ~f:(List.cons x) (perm (f []) (n - 1)))
      |> List.concat
end

(** Combinations *)
module Combination = struct
  let comb2 xs =
    List.concat_mapi
      ~f:(fun i x -> List.map ~f:(Pair.make x) (List.drop xs (i + 1)))
      xs
end

(** Map implemented with asocc list ( Stdlib.(=) can be used for equality check ) *)
module ALMap = struct
  type ('k, 'd) t = ('k * 'd) list
  let empty = []
  let is_empty = List.is_empty
  let length = List.length
  let rec add_exn ~key ~data = function
    | [] -> [key, data]
    | (k, d) :: tl as l ->
      if Stdlib.(key = k) then failwith "key already exists"
      else if Stdlib.(key < k) then (key, data) :: l
      else (k, d) :: add_exn ~key ~data tl
  let singleton key data = add_exn ~key ~data empty
  let find_exn = Stdlib.List.assoc
  let to_alist m = m
  let of_alist_exn l =
    List.fold l ~init:empty ~f:(fun acc (key, data) -> add_exn ~key ~data acc)
  let data m = snd @@ List.unzip m
  let map ~f m = List.map m ~f:(fun (k, d) -> (k, f d))
  let force_merge m1 m2 = List.fold m2 ~init:m1 ~f:(fun acc (key, data) -> add_exn ~key ~data acc)
  let split_lbr m1 m2 =
    let rec aux m1 m2 lefts boths rights =
      match m1, m2 with
      | [], m2 -> lefts, boths, m2 @ rights
      | m1, [] -> m1 @ lefts, boths, rights
      | (k1, d1) :: tl1, (k2, d2) :: tl2 ->
        if Stdlib.(k1 = k2) then aux tl1 tl2 lefts ((k1, (d1, d2)) :: boths) rights
        else if Stdlib.(k1 < k2) then aux tl1 m2 ((k1, d1) :: lefts) boths rights
        else aux m1 tl2 lefts boths ((k2, d2) :: rights)
    in
    aux m1 m2 [] [] []

end
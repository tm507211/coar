type result = Failure | Success of int

type[@boxed] 'a eff =
| Select : bool eff

type ('a, 'b) continuation = K
type 'a effect_handler = { effc: 'b. 'b eff -> (('b,'a) continuation -> 'a) option }
type ('a,'b) handler = {
  retc: 'a -> 'b;
  exnc: exn -> 'b;
  effc: 'c.'c eff -> (('c,'b) continuation -> 'b) option
}
external perform : 'a eff -> 'a = "unknown"
external try_with : ('a -> 'b) -> 'a -> 'b effect_handler -> 'b = "unknown"
external match_with : ('a -> 'b) -> 'a -> ('b, 'c) handler -> 'c = "unknown"
external continue : ('a, 'b) continuation -> 'a -> 'b = "unknown"

let rec ( @ ) l1 l2 = match l1 with [] -> l2 | hd :: tl -> hd :: (tl @ l2)

let push (x: (bool -> result) * bool) q = q := !q @ [x]
let pop_opt (q: ((bool -> result) * bool) list ref) =
  match !q with
  | [] -> None
  | x :: xs -> q := xs; Some x

(* from https://github.com/matijapretnar/eff/blob/master/examples/amb.eff *)

let[@annot_MB "
  (unit -> ({Select: s1} |> result / s => s)) ->
  result
"] bfs (body: unit -> result) =
  let q = ref [] in
  let run_next () =
    match pop_opt q with
    | None -> Failure
    | Some (k,x) -> k x
  in
  match_with body () {
    retc = (fun x ->
      match x with
      | Success x -> Success x
      | Failure -> run_next ()
    );
    exnc = raise;
    effc = fun (type a) (e: a eff) -> match e with
      | Select -> Some (fun (k: (a, _) continuation) ->
        push (continue k, true) q;
        push (continue k, false) q;
        run_next ()
        )
  }

let sqrt_for_4_or_9 squared =
  bfs (fun () ->
    let cand = if perform (Select) then 2 else 3 in
    if cand * cand = squared then Success cand else Failure
  )

let test n = sqrt_for_4_or_9 (n * n) = Failure
[@@@assert "typeof(test) <: (n:{z:int | z = 2 || z = 3}) -> {z: bool | z = true}"]
(*unsat*)
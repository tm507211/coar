open Core

(** Booleans *)
module Bool = struct
  include Bool

  let string_of b = if b then "true" else "false"
  let pr ppf b = Format.fprintf ppf "%s" (string_of b)
  let pr_yn ppf b = Format.fprintf ppf "%s" (if b then "yes" else "no")

  let imply b1 b2 = not b1 || b2
end

(** Integers *)
module Integer = struct
  let pr ppf n = Format.fprintf ppf "%d" n

  (** @return the factorial of n *)
  let rec fact n = if n = 0 then 1 else n * fact (n - 1)
  (** @return n1 to the power of n2 *)
  let rec pow n1 n2 = if n2 = 0 then 1 else n1 * pow n1 (n2 - 1)
  (** the greatest representable integer *)
  let max_int = pow 2 30 - 1
  (** the smallest representable integer *)
  let min_int = -pow 2 30
  (** @return the product of the integers from 1 to n *)
  (** @return the sum of the integers from 0 to n *)
  let rec sum n = if n = 0 then 0 else n + sum (n - 1)
  (* let sum = fold_left (fun x -> fun y -> x + y) 0 *)
  (** @return the sum of integers ns *)
  let sum_list ns = List.fold_left ~f:(+) ~init:0 ns
  let rec prod n = if n = 1 then 1 else n * prod (n - 1)
  (** @return the product of integers ns *)
  let prod_list ns = List.fold_left ~f:( * ) ~init:1 ns
  (** @return the maximum of integers *)
  let max = max
  (** @return the maximum of integers ns *)
  let max_list = function
    | [] -> assert false
    | n :: ns' -> List.fold_left ~f:max ~init:n ns'
  (** @return the minimum of integers
      @ensure -(min x y) = max (-x) (-y) *)
  let min = min
  (** @return the minimum of integers *)
  let min_list = function
    | [] -> assert false
    | n :: ns' -> List.fold_left ~f:min ~init:n ns'
  let rec gcd n1 n2 =
    if n2 = 0 then n1 |> abs (* we need this because (-6) mod 4 = -2 in OCaml *)
    else gcd n2 (n1 mod n2)
  (** @return the greatest common divisor of n1 and n2
      @ensure gcd 0 0 = 0 *)
  (*let gcd = Logger.log_block2 "Integer.gcd" gcd*)
  let gcd_list ns = List.fold_left ~f:gcd ~init:0 ns
  (** @return the greatest common divisor of integers ns
      @ensure gcd_list [0; ...; 0] = 0 *)
  (*let gcd_list = Logger.log_block1 "Integer.gcd_list" gcd_list*)
  let lcm n1 n2 = if n1 = 0 && n2 = 0 then 0 else n1 * n2 / gcd n1 n2
  (** @return the least common multiplier of n1 and n2
      @ensure lcm 0 0 = 0 *)
  (*let lcm = Logger.log_block2 "Integer.lcm" lcm*)
  let lcm_list = function n :: ns -> List.fold_left ~f:lcm ~init:n ns | [] -> failwith ""
  (** @return the least common multiplier of integers ns
      @ensure lcm_list [0; ...; 0] = 0 *)
  (*let lcm_list = Logger.log_block1 "Integer.lcm_list" lcm_list*)
  let rand seed =
    let multiplier = 25173 in
    let increment = 13849 in
    let modulus = 65536 in
    (multiplier * seed + increment) mod modulus
  (** Random number generation *)
  let rand_int () = let n = Random.bits () in if Random.bool () then -n else n
end

(** Natural numbers *)
module Nat = struct
  let of_var_radix radices coeffs =
    coeffs
    |> List.mapi ~f:(fun i coeff ->
        List.drop radices (i + 1)
        |> Integer.prod_list
        |> ( * ) coeff)
    |> Integer.sum_list
end

(** Floating point numbers *)
module Float = struct
  include Float

  let log2 x = log x /. log 2.
  let pi = 4. *. Stdlib.atan 1.

  let pr ppf f = Format.fprintf ppf "%9.6f" f

  (*let num_of_positive_float f =
    let m, e = frexp f in
    let sm = string_of_float m in
    let s = String.make 16 '0' in
    (** sm starts with "0." *)
    let _ = Stdlib.String.blit sm 2 (Bytes.of_string s) 0 (Stdlib.(-) (String.length sm) 2) in
    let e' = Num.power_num (Num.Int 2) (Num.num_of_int e) in
    Num.div_num
      (Num.mult_num (Num.num_of_string s) e')
      (Num.power_num (Num.Int 10) (Num.Int 16))
    let num_of_float f =
    let n = int_of_float f in
    if f = float_of_int n then Num.Int n
    else if f < 0.0 then Num.minus_num (num_of_positive_float (Stdlib.abs_float f))
    else num_of_positive_float f*)

  let rat_of_float f =
    Q.of_float f |> Q.num |> Z.to_int,
    Q.of_float f |> Q.den |> Z.to_int

  let of_q q =
    (Q.num q |> Big_int_Z.float_of_big_int) /.
    (Q.den q |> Big_int_Z.float_of_big_int)

  let round f =
    let f_ceil = Stdlib.ceil f in
    let f_floor = Stdlib.floor f in
    if (f_ceil -. f < f -. f_floor)
    then int_of_float f_ceil
    else int_of_float f_floor

  let sum = List.fold_left ~f:(fun x1 x2 -> x1 +.(*/*) x2) ~init:0.(*Num.num_of_int 0*)
  let prod = List.fold_left ~f:(fun x1 x2 -> x1 *.(*/*) x2) ~init:1.(*Num.num_of_int 1*)
  (** @return the sum of floating point numbers *)
  let sum_list = List.fold_left ~f:(+.) ~init:0.0

  let rand (s, e) seed =
    (float_of_int (Integer.rand seed)) /. 65536. *. (e -. s) +. s
  (** Box-Muller method *)
  let rand_gaussian mu sigma =
    mu +. sigma *. sqrt (-2. *. log (Random.float 1.)) *. Stdlib.cos (2. *. Float.pi *. Random.float 1.)
end

(** Options *)
module Option = struct
  include Option

  let elem_of = function None -> assert false | Some x -> x
  let elem_of_nf = function None -> raise @@ Not_found_s (Sexplib0.Sexp.message "" []) | Some x -> x
  let nf_of f x = match f x with None -> raise @@ Not_found_s (Sexplib0.Sexp.message "" []) | Some res -> res

  let of_nf f x = try Some (f x) with Not_found_s _ -> None
  let of_exc f x = try Some (f x) with _ -> None

  let pr epr none ppf = function
    | None -> Format.fprintf ppf "%s" none
    | Some x -> Format.fprintf ppf "%a" epr x
end

(** Strings *)
module String = struct
  include String

  let pr ppf str = Format.fprintf ppf "%s" str

  let is_int s = try let _ = int_of_string s in true with Failure _ -> false
  let is_float s = try let _ = float_of_string s in true with Failure _ -> false

  (** @todo sufficient for identifiers of OCaml? *)
  let escape s = map ~f:(fun c -> if Char.(c = '.' || c = '!') then '_' else c) s

  let split_at i str =
    if Stdlib.(i < 0) then "", str
    else if Stdlib.(i > Stdlib.String.length str) then str, ""
    else Stdlib.String.sub str 0 i, Stdlib.String.sub str i (String.length str - i)

  let concat_map_list ?(sep = "") ~f l = concat ~sep @@ List.map l ~f
  let concat_mapi_list ?(sep = "") ~f l = concat ~sep @@ List.mapi l ~f
  let concat_set ~sep s = String.concat ~sep @@ Core.Set.Poly.to_list s
  let concat_map_set ?(sep = "") ~f s = concat_set ~sep @@ Core.Set.Poly.map s ~f
end

(** Lists *)
module List = struct
  include List

  let is_singleton l = List.length l = 1

  let rec power f = function
    | [] -> [[]]
    | x :: xs ->
      List.concat_map (power f xs) ~f:(fun ys -> List.map (f x) ~f:(fun y -> y :: ys))

  let cartesian_map ?(init = []) ~f l1 l2 =
    List.fold l1 ~init ~f:(fun acc x1 ->
        List.fold l2 ~init:acc ~f:(fun acc x2 -> f x1 x2 :: acc))

  let rec n_cartesian_product = function
    | [] -> [[]]
    | x :: xs ->
      let rss = n_cartesian_product xs in
      List.concat_map x ~f:(fun r -> List.map rss ~f:(fun rs -> r :: rs))

  let sum_float xs = List.sum (module Float) xs ~f:Fn.id
  let average_float xs = sum_float xs /. (float_of_int @@ List.length xs)

  let zip_index l = List.zip_exn l (List.init (List.length l) ~f:Fn.id)
  let find_distinct_pair ~f l =
    List.find_map l ~f:(fun x1 -> List.find_map l ~f:(fun x2 ->
        if Stdlib.(x1 = x2) then None else f x1 x2))

  let optimize xs ~f ~ord =
    let x_0 = List.hd_exn xs in
    List.fold (List.tl_exn xs) ~init:(x_0, f x_0) ~f:(fun (x, fx) x' ->
        let fx' = f x' in
        if ord fx' fx then (x', fx') else (x, fx))
    |> snd
  let argopt xs ~f ~ord =
    let x_0 = List.hd_exn xs in
    List.fold (List.tl_exn xs) ~init:(x_0, f x_0) ~f:(fun (x, fx) x' ->
        let fx' = f x' in
        if ord fx' fx then (x', fx') else (x, fx))
    |> fst
  let argmax xs ~f = argopt xs ~f ~ord:Stdlib.( > )
  let argmin xs ~f = argopt xs ~f ~ord:Stdlib.( < )

  type 'a mut_list =  {
    hd: 'a;
    mutable tl: 'a list
  }
  external inj : 'a mut_list -> 'a list = "%identity"
  let dummy_node () = { hd = Obj.magic (); tl = [] }
  let unique ?(equal = Stdlib.(=)) l =
    let rec loop dst = function
      | [] -> ()
      | h :: t ->
        match exists ~f:(equal h) t with
        | true -> loop dst t
        | false ->
          let r = { hd =  h; tl = [] }  in
          dst.tl <- inj r;
          loop r t
    in
    let dummy = dummy_node () in
    loop dummy l;
    dummy.tl
  let rec remove_if ~f = function
    | [] -> []
    | x :: xs -> if f x then xs else x :: remove_if ~f xs

  (** {6 Constructors} *)

  let cons x xs = x :: xs
  let return x = [x]

  (** {6 Destructors} *)

  let rec delete p = function
    | [] -> []
    | x :: xs' -> if p x then xs' else x :: delete p xs'

  let rec delete_all p = function
    | [] -> []
    | x :: xs' -> if p x then delete_all p xs' else x :: delete_all p xs'

  let hd_tl = function [] -> assert false | x :: xs' -> (x, xs')

  let rest_last = function
    | [] -> assert false
    | l  -> (take l (List.length l - 1), last_exn l)

  let rec initial_last = function
    | [] -> assert false
    | [x] -> [], x
    | x :: xs' -> let ys, y = initial_last xs' in (x :: ys, y)

  let non_nil_list_of = function [] -> assert false | xs -> xs

  let elem_of_singleton = function
    | [x] -> x
    | xs ->
      failwith @@ Format.sprintf "an error in elem_of_singleton: %d@," (length xs)

  (** {6 Inspectors} *)

  let eq_length l1 l2 = length l1 = length l2

  let rec is_prefix xs ys =
    match xs, ys with
    | [], _ -> true
    | x :: xs', y :: ys' -> x = y && is_prefix xs' ys'
    | _, _ -> false

  let all_equiv eqrel = function
    | [] -> true
    | x :: xs -> for_all ~f:(fun x' -> eqrel x x') xs

  let rec assoc_inverse asso x =
    match asso with
    | [] -> assert false
    | (i, xs) :: rest ->
      let open Combinator in
      match findi ~f:(curry2 (snd >> (=) x)) xs with
      | Some res -> i, fst res
      | None -> assoc_inverse rest x
  let assoc_fail ?(on_failure = fun () -> ()) x xs =
    try Assoc.find_exn x xs with Not_found_s _ -> on_failure (); assert false
  let assocF = assoc_fail
  let assoc_default d x xs = try Assoc.find_exn x xs with Not_found_s _ -> d
  let assocD = assoc_default

  (** {6 Searching operators} *)

  let find_fail ?(on_failure = fun () -> ()) p xs =
    try find ~f:p xs with Not_found_s _ -> on_failure (); assert false

  (* aka pick
     let findlr p xs =
     let rec aux l r =
      match r with
      | [] -> raise Not_found
      | x :: r' ->
        if p x then l, x, r' else aux (l @ [x]) r'
     in
     aux [] xs*)

  let find_maplr f xs =
    let rec aux l r =
      match r with
      | [] -> raise @@ Not_found_s (Sexplib0.Sexp.message "" [])
      | x :: r' ->
        match f l x r' with None -> aux (l @ [x]) r' | Some y -> y
    in
    aux [] xs

  let rec filter_map2 f xs ys =
    match xs, ys with
    | [], [] -> []
    | x :: xs', y :: ys' ->
      begin
        match f x y with
        | None -> filter_map2 f xs' ys'
        | Some r -> r :: filter_map2 f xs' ys'
      end
    | _ -> assert false

  let filter_mapLr f xs =
    let rec aux l r =
      match r with
      | [] -> l
      | x :: r' ->
        match f l x r' with
        | None -> aux l r'
        | Some x' -> aux (l @ [x']) r'
    in
    aux [] xs

  let partitioni f ys =
    let rec aux i xs = fun ls rs ->
      match xs with
      | [] -> ls, rs
      | x :: xs' ->
        if f i x
        then aux (pred i) xs' (x :: ls) rs
        else aux (pred i) xs' ls (x :: rs)
    in
    aux (length ys - 1) (rev ys) [] []

  (** {6 Iterators} *)

  let iter2i f =
    let rec aux i xs ys=
      match xs, ys with
      | [], [] -> ()
      | x :: xs', y :: ys' -> f i x y; aux (i + 1) xs' ys'
      | _ -> assert false
    in
    aux 0

  let rec iter3 f xs ys zs =
    match xs, ys, zs with
    | [], [], [] -> ()
    | x :: xs', y :: ys', z :: zs' -> f x y z; iter3 f xs' ys' zs'
    | _ -> assert false

  let iter3i f =
    let rec aux i xs ys zs=
      match xs, ys, zs with
      | [], [], [] -> ()
      | x :: xs', y :: ys', z :: zs' ->
        f i x y z;
        aux (i + 1) xs' ys' zs'
      | _ -> assert false
    in
    aux 0

  (** {6 Zipping and unzipping operators} *)

  let rec zip3 xs ys zs =
    match xs, ys, zs with
    | [], [], [] -> []
    | x :: xs', y :: ys', z :: zs' -> (x, y, z) :: zip3 xs' ys' zs'
    | _ -> assert false
  let zip3_exn lst1 lst2 lst3 =
    let rec aux lst1 lst2 lst3 ret =
      match lst1, lst2, lst3 with
      | (hd1::tl1), (hd2::tl2), (hd3::tl3) -> aux tl1 tl2 tl3 ((hd1, hd2, hd3)::ret)
      | [], [], [] -> ret
      | _ -> assert false
    in aux (List.rev lst1) (List.rev lst2) (List.rev lst3) []
  let zip4_exn lst1 lst2 lst3 lst4 =
    let rec aux lst1 lst2 lst3 lst4 ret =
      match lst1, lst2, lst3, lst4 with
      | (hd1::tl1), (hd2::tl2), (hd3::tl3), (hd4::tl4) -> aux tl1 tl2 tl3 tl4 ((hd1, hd2, hd3, hd4)::ret)
      | [], [], [], [] -> ret
      | _ -> assert false
    in aux (List.rev lst1) (List.rev lst2) (List.rev lst3) (List.rev lst4) []

  let rec unzip3 ls =
    match ls with
    | [] -> [], [], []
    | (x, y, z) :: ls ->
      let (xs, ys, zs) = unzip3 ls in
      x :: xs, y :: ys, z :: zs
  let split3 = unzip3
  (*let unzip4 = List.fold_right ~f:(fun (a, b, c, d) (al, bl, cl, dl) -> (a::al, b::bl, c::cl, d::dl)) ~init:([], [], [], []) in*)
  let unzip4 lst =
    let rec aux (ws, xs, ys, zs) = function
      | [] -> (ws, xs, ys, zs)
      | (w, x, y, z) :: lst -> aux (w :: ws, x :: xs, y :: ys, z :: zs) lst
    in
    List.rev lst |> aux ([], [], [], [])
  let unzip5 lst =
    let rec aux (vs, ws, xs, ys, zs) = function
      | [] -> (vs, ws, xs, ys, zs)
      | (v, w, x, y, z) :: lst ->
        aux (v :: vs, w :: ws, x :: xs, y :: ys, z :: zs) lst
    in
    List.rev lst |> aux ([], [], [], [], [])
  let unzip6 lst =
    let rec aux (us, vs, ws, xs, ys, zs) = function
      | [] -> (us, vs, ws, xs, ys, zs)
      | (u, v, w, x, y, z) :: lst ->
        aux (u :: us, v :: vs, w :: ws, x :: xs, y :: ys, z :: zs) lst
    in
    List.rev lst |> aux ([], [], [], [], [], [])
  let unzip7 lst =
    let rec aux (ts, us, vs, ws, xs, ys, zs) = function
      | [] -> (ts, us, vs, ws, xs, ys, zs)
      | (t, u, v, w, x, y, z) :: lst ->
        aux (t :: ts, u :: us, v :: vs, w :: ws, x :: xs, y :: ys, z :: zs) lst
    in
    List.rev lst |> aux ([], [], [], [], [], [], [])
  let unzip8 lst =
    let rec aux (ss, ts, us, vs, ws, xs, ys, zs) = function
      | [] -> (ss, ts, us, vs, ws, xs, ys, zs)
      | (s, t, u, v, w, x, y, z) :: lst ->
        aux (s :: ss, t :: ts, u :: us, v :: vs, w :: ws, x :: xs, y :: ys, z :: zs) lst
    in
    List.rev lst |> aux ([], [], [], [], [], [], [], [])

  (** {6 Concatenation operators} *)

  let rec concat_opt = function
    | [] -> []
    | None :: xs' -> concat_opt xs'
    | Some x :: xs' -> x :: concat_opt xs'

  let concat_unzip xs = let ls, rs = unzip xs in concat ls, concat rs

  let concat_rev_map f xs =
    List.fold_left ~f:(fun acc x -> List.rev_append (f x) acc) ~init:[] xs

  let rec concat_map2 f xs ys =
    match xs, ys with
    | [], [] -> []
    | x :: xs', y :: ys' ->
      let r = f x y in
      let rs = concat_map2 f xs' ys' in
      r @ rs
    | _ -> assert false

  let concat_map2i f =
    let rec aux i a xs ys =
      match xs, ys with
      | [], [] -> a
      | x :: xs', y :: ys' ->
        let r = f i x y in
        aux (i + 1) (a @ r) xs' ys'
      | _ -> assert false
    in
    aux 0 []

  let rec concat_map3 f xs ys zs =
    match xs, ys, zs with
    | [], [], [] -> []
    | x :: xs', y :: ys', z :: zs' ->
      let r = f x y z in
      let rs = concat_map3 f xs' ys' zs' in
      r @ rs
    | _ -> assert false

  let concat_map3i f =
    let rec aux i xs ys zs =
      match xs, ys, zs with
      | [], [], [] -> []
      | x :: xs', y :: ys', z :: zs' ->
        let r = f i x y z in
        let rs = aux (i + 1) xs' ys' zs' in
        r @ rs
      | _ -> assert false
    in
    aux 0

  (** {6 Sorting operators} *)

  let sort_by f xs =
    xs
    |> map ~f:(fun x -> f x, x)
    |> sort ~compare:(fun (n1, _) (n2, _) -> n1 - n2)
    |> map ~f:snd
  let sort_dec_by f xs =
    xs
    |> map ~f:(fun x -> f x, x)
    |> sort ~compare:(fun (n1, _) (n2, _) -> n2 - n1)
    |> map ~f:snd

  (** {6 Operators for sublists} *)

  (** @require xs is not empty
      @return xs without the last element *)
  let rec initial = function
    | [] -> assert false
    | [_] -> []
    | x :: xs' -> x :: initial xs'

  (** \[1; 2; 3\] = \[\[\]; \[1\]; \[1; 2\]; \[1; 2; 3\]\] *)
  let inits xs =
    xs
    |> (fold_left
          ~f:(fun (prefix, prefixes) x ->
              let prefix' = prefix @ [x] in
              prefix', prefixes @ [prefix'])
          ~init:([], [[]]))
    |> snd


  (*let rec split_at n xs =
    if n < 0 then failwith "split_at"
    else if n = 0 then [], xs
    else
      let x :: xs' = xs in
      let ls, rs = split_at (n - 1) xs' in
      x::ls, rs*)

  let rec split_by_list ls xs =
    match ls with
    | [] -> [xs]
    | l :: ls' ->
      let xs1, xs2 = split_n xs l in
      xs1 :: split_by_list ls' xs2

  let rec span p = function
    | [] -> [], []
    | x :: xs' ->
      if p x then
        let ls, rs = span p xs' in
        x :: ls, rs
      else [], x :: xs'

  let rec span_map f = function
    | [] -> [], []
    | x :: xs' ->
      match f x with
      | None -> [], x :: xs'
      | Some y -> let ls, rs = span_map f xs' in y :: ls, rs

  let rec break p = function
    | [] -> [], []
    | x :: xs' ->
      if p x then [], x :: xs' else let ls, rs = break p xs' in x :: ls, rs

  let breaklr p xs =
    let rec aux l r =
      match r with
      | [] -> [], []
      | x :: r' -> if p l x r' then l, r else aux (l @ [x]) r
    in
    aux [] xs

  let pick p xs =
    xs |> break p
    |> (function
        | _, [] -> raise @@ Not_found_s (Sexplib0.Sexp.message "" [])
        | l, x :: r -> l, x, r)
  let picklr p xs =
    xs |> breaklr p
    |> (function _, [] -> raise @@ Not_found_s (Sexplib0.Sexp.message "" []) | l, x :: r -> l, x, r)

  let rec pick_map f = function
    | [] -> raise @@ Not_found_s (Sexplib0.Sexp.message "" [])
    | x :: xs' ->
      match f x with
      | None ->
        let ls, y, rs = pick_map f xs' in
        x :: ls, y, rs
      | Some y -> [], y, xs'

  let pick_maplr f xs =
    let rec aux l r =
      match r with
      | [] -> raise @@ Not_found_s (Sexplib0.Sexp.message "" [])
      | x :: r' ->
        match f l x r' with
        | None -> aux (l @ [x]) r'
        | Some y -> l, y, r'
    in
    aux [] xs

  (*
      e.g.
      [[a11; a12; a13]; [a21; a22; a23]; [a31; a32; a33]] -->
      [
        [a11; a21; a31]; [a11; a21; a32]; [a11; a21; a33];
        [a11; a22; a31]; [a11; a22; a32]; [a11; a22; a33];
        ...
        [a13; a23; a31]; [a13; a23; a32]; [a13; a23; a33]
      ]
  *)
  let permutation_without_repetion_of l =
    let rec inner l ret gruop last =
      let aux l next =
        List.fold_left l ~init:[] ~f:(fun ret hd -> ret @ next (Some hd))
      in
      let gruop' = begin match last with | Some t -> gruop @ [t] | _ -> gruop end in
      match l with
      | [] -> gruop'::ret
      | hd::tl -> aux hd (inner tl ret gruop')
    in
    let l = List.filter ~f:(Fn.non List.is_empty) l in
    inner l [] [] None

  (** interleave 1 \[2;3\] = \[ \[1;2;3\]; \[2;1;3\]; \[2;3;1\] \] *)
  let rec interleave x lst =
    match lst with
    | [] -> [[x]]
    | hd::tl -> (x::lst) :: (List.map ~f:(fun y -> hd::y) (interleave x tl))
  (*
      e.g.
      [[a]; [b]; [c]] ---> [[a;b;c];[a;c;b];[b;a;c];[b;c;a];[c;a;b];[c;b;a]]

      [[a;b]; [c]; [d]] --->
      [
        [a;c;d];[a;d;c];[b;c;d];[b;d;c];
        [c;a;d];[c;d;a];[c;b;d];[c;d;b];
        [d;a;c];[d;c;a];[d;b;c];[d;c;b]
      ]
  *)
  let rec permutation_of (l:'a t t) =
    match List.filter ~f:(Fn.non List.is_empty) l with
    | hd :: tl ->
      List.concat_map hd ~f:(fun x -> List.concat_map ~f:(interleave x) @@ permutation_of tl)
    | [] -> [[]]
  (** permutations \[1; 2; 3\] = \[\[1; 2; 3\]; \[2; 1; 3\]; \[2; 3; 1\]; \[1; 3; 2\]; \[3; 1; 2\]; \[3; 2; 1\]\] *)
  let rec permutations = function
    | hd :: tl -> List.concat (List.map ~f:(interleave hd) (permutations tl))
    | lst -> [lst]

  (** {6 Printers} *)

  let rec pr_aux epr sep i ppf = function
    | [] -> ()
    | [x] -> epr ppf (i, x)
    | x :: xs' ->
      Format.fprintf ppf "%a%a%a"
        epr (i, x) Format.fprintf sep (pr_aux epr sep (i + 1)) xs'

  let pr epr ?(header="") ?(footer="") sep ppf xs =
    Format.fprintf ppf "%s@[<v>%a@]%s"
      header (pr_aux (fun ppf (_, x) -> epr ppf x) sep 0) xs footer

  let pri epr sep ppf xs =
    Format.fprintf ppf "@[<v>%a@]" (pr_aux epr sep 0) xs

  let pr_hov epr sep ppf xs =
    Format.fprintf ppf "@[<hov>%a@]"
      (pr_aux (fun ppf (_, x) -> epr ppf x) sep 0) xs

  let pr_ocaml epr ppf xs =
    Format.fprintf ppf "[@[<v>%a@]]"
      (pr_aux (fun ppf (_, x) -> epr ppf x) "; " 0) xs

  let pr_app epr sep ppf = function
    | [] -> ()
    | [x] -> epr ppf x
    | x :: xs ->
      Format.fprintf ppf "@[<hov2>%a@ @[<hov>%a@]@]"
        epr x (pr_aux (fun ppf (_, x) -> epr ppf x) sep 0) xs

  let print_list epr sep = pr epr sep Format.std_formatter

  let rec pr_string_separator epr sep ppf = function
    | [] -> ()
    | [x] -> epr ppf x
    | x :: xs' ->
      Format.fprintf ppf "%a%s%a" epr x sep (pr_string_separator epr sep) xs'

  (** {6 Classification operators} *)

  let rec classify eqrel = function
    | [] -> []
    | x :: xs ->
      let t, f = List.partition_tf ~f:(eqrel x) xs in
      (x :: t) :: classify eqrel f

  (** {6 Shuffling operators} *)

  let shuffle xs =
    List.map ~f:snd @@
    List.sort ~compare:(fun (r1, _) (r2, _) -> Int.compare r1 r2) @@
    List.map ~f:(fun x -> Random.bits (), x) xs

  (** {6 Indexing operators} *)

  let apply_at i f xs =
    match split_n i xs with
    | l, x :: r -> l @ f x :: r
    | _ -> failwith ""

  let replace_at i x = apply_at i (fun _ -> x)

  (** {6 Operators for list contexts} *)

  let rec context_of i = function
    | [] -> assert false
    | x :: xs' ->
      if i = 0 then fun ys -> ys @ xs'
      else if i > 0 then
        let ctx = context_of (i - 1) xs' in
        fun ys -> x :: ctx ys
      else assert false

  (** {6 Mapping operators} *)

  let rec map3 f xs ys zs =
    match xs, ys, zs with
    | [], [], [] -> []
    | x :: xs', y :: ys', z :: zs' -> f x y z :: map3 f xs' ys' zs'
    | _ -> assert false
  let rec map4 f xs ys zs ws =
    match xs, ys, zs, ws with
    | [], [], [], [] -> []
    | x :: xs', y :: ys', z :: zs', w :: ws' ->
      f x y z w :: map4 f xs' ys' zs' ws'
    | _ -> assert false
  let map2i f =
    let rec aux i xs ys =
      match xs, ys with
      | [], [] -> []
      | x :: xs', y :: ys' ->
        f i x y :: aux (i + 1) xs' ys'
      | _ -> assert false
    in
    aux 0
  let map3i f =
    let rec aux i xs ys zs =
      match xs, ys, zs with
      | [], [], [] -> []
      | x :: xs', y :: ys', z :: zs' ->
        f i x y z :: aux (i + 1) xs' ys' zs'
      | _ -> assert false
    in
    aux 0
  let map4i f =
    let rec aux i xs ys zs ws =
      match xs, ys, zs, ws with
      | [], [], [], [] -> []
      | x :: xs', y :: ys', z :: zs', w :: ws' ->
        f i x y z w :: aux (i + 1) xs' ys' zs' ws'
      | _ -> assert false
    in
    aux 0
  let mapc f xs = mapi ~f:(fun i x -> f (context_of i xs) x) xs

  let maplr f xs =
    let rec aux l r =
      match r with
      | [] -> []
      | x :: r' -> f l x r' :: aux (l @ [x]) r'
    in
    aux [] xs

  let mapLr f xs =
    let rec aux l r =
      match r with
      | [] -> l
      | x :: r' -> let y = f l x r' in aux (l @ [y]) r'
    in
    aux [] xs

  let maplR f xs =
    let rec aux l r =
      match l with
      | [] -> r
      | x :: l' -> let y = f (rev l') x r in aux l' (y :: r)
    in
    aux (rev xs) []

  (* similar to Data.List.mapAccumL in Haskell *)
  let mapLar f a xs =
    let rec aux l a r =
      match r with
      | [] -> l, a
      | x :: r' -> let y, a' = f l a x r' in aux (l @ [y]) a' r'
    in
    aux [] a xs

  (* similar to Data.List.mapAccumR in Haskell *)
  let maplaR f xs a =
    let rec aux l a r =
      match l with
      | [] -> a, r
      | x :: l' -> let a', y = f (rev l') x a r in aux l' a' (y :: r)
    in
    aux (rev xs) a []

  (** {6 Folding operators} *)

  let fold_lefti f a xs =
    let rec aux i a = function
      | [] -> a
      | x :: xs' -> aux (i + 1) (f i a x) xs'
    in
    aux 0 a xs

  let rec scan_left f a = function
    | [] -> [a]
    | x :: xs' -> a :: scan_left f (f a x) xs'

  let rec scan_right f xs a =
    match xs with
    | [] -> [a]
    | x :: xs' ->
      match scan_right f xs' a with
      | b :: bs -> f x b :: b :: bs
      | _ -> failwith ""

  (** {6 Generating operators} *)

  let gen n f =
    let rec aux i = if i >= n then [] else f i :: aux (i + 1) in
    aux 0

  let rec unfold f seed =
    match f seed with
    | None -> []
    | Some (x, seed') -> x :: unfold f seed'

  let from_to s e =
    unfold (fun i -> if i <= e then Some (i, i + 1) else None) s

  let duplicate x size =
    unfold (fun i -> if i < size then Some (x, i + 1) else None) 0

  let prefixes xs = map ~f:(take xs) (from_to 0 (List.length xs))

  (** {6 Unclassified operators} *)

  let unzip_map f xs = List.unzip @@ map ~f xs
  let unzip_mapi f xs = List.unzip @@ mapi ~f xs
  let unzip3_map f xs = List.unzip3 @@ map ~f xs
  let unzip3_mapi f xs = List.unzip3 @@ mapi ~f xs

  (*
  (** Sets (lists modulo permutation and contraction) *)
  module Set : sig
    type 'a t = 'a list

    (** {6 Inspectors} *)

    val subset : ?cmp:('a -> 'a -> bool) -> 'a t -> 'a t -> bool
    val equiv : ?cmp:('a -> 'a -> bool) -> 'a t -> 'a t -> bool
    val intersects : ?cmp:('a -> 'a -> bool) -> 'a t -> 'a t -> bool
    val disjoint : ?cmp:('a -> 'a -> bool) -> 'a t -> 'a t -> bool

    (** {6 Operators} *)

    val diff : ?cmp:('a -> 'a -> bool) -> 'a t -> 'a t -> 'a t
    val inter : ?cmp:('a -> 'a -> bool) -> 'a t -> 'a t -> 'a t
    val union : ?cmp:('a -> 'a -> bool) -> 'a t -> 'a t -> 'a t

    val power : 'a t -> 'a t t
    (** [subsets_of_size n s] returns all the subsets of [s] with the size [n] *)
    val subsets_of_size : int -> 'a t -> 'a t t
    (** [equiv_classes rel s] divides [s] by the transitive closure of [rel] *)
    val equiv_classes : ('a -> 'a -> bool) -> 'a t -> 'a t t
    val representatives : ('a -> 'a -> bool) -> 'a t -> 'a t

    (** [minimal p s] returns a minimal subset of [s] that satisfy [p]
        @require [p s] *)
    val minimal : ('a t -> bool) -> 'a t -> 'a t
    (** @todo rename *)
    val cover : 'a t t -> 'a t t


    val reachable : 'a list -> ('a -> 'a list) -> 'a list
  end = struct
    type 'a t = 'a list

    let subset ?(cmp = (=)) l1 l2 =
      List.for_all (fun x -> List.mem ~cmp:cmp x l2) l1
    let equiv ?(cmp = (=)) l1 l2 =
      subset ~cmp:cmp l1 l2 && subset ~cmp:cmp l2 l1
    let intersects ?(cmp = (=)) l1 l2 =
      List.exists (fun x -> List.mem ~cmp:cmp x l2) l1
    let disjoint ?(cmp = (=)) l1 l2 =
      List.for_all (fun x -> not (List.mem ~cmp:cmp x l2)) l1

  (*
  let rec diff xs ys =
    match xs, ys with
    | [], [] | [], _ | _, [] -> xs
    | x' :: xs', ys ->
      if List.mem x' ys
      then diff xs' ys
      else x' :: diff xs' ys *)

    let inter ?(cmp = (=)) l1 l2 = List.filter (fun x -> List.mem ~cmp:cmp x l2) l1
    let union ?(cmp = (=)) l1 l2 = List.unique ~cmp:cmp (l1 @ l2)

    let inter_list = function
      | [] -> []
      | x :: xs -> List.fold_left inter x xs
    let union_list = function
      | [] -> []
      | x :: xs -> List.fold_left union x xs

    let rec power = function
      | [] -> [[]]
      | x :: s' -> List.concat_map (fun s -> [s; x :: s]) (power s')

    let subsets_of_size n s =
      let rec aux n s1s2s =
        if n = 0 then s1s2s
        else
          List.concat_map
            (fun (s1, s2) ->
              (** @invariant Set.equiv (s1 @ s2) s *)
              List.maplr (fun s11 x s12 -> s11 @ s12, x :: s2) s1)
            (aux (n - 1) s1s2s)
      in
      List.map snd (aux n [s, []])

    let rec equiv_classes rel s =
      match s with
      | [] -> []
      | x :: s' ->
        let aux s1 s2 =
          List.partition (fun y -> List.exists (rel y) s1) s2
          |> Pair.map_fst ((@) s1)
        in
        let ls, rs =
          fix
            (uncurry2 aux)
            (comp2 List.eq_length fst fst)
            ([x], s')
        in
        ls :: equiv_classes rel rs

    let rec representatives eqrel = function
      | [] -> []
      | x :: s' -> x :: representatives eqrel (List.filter (eqrel x >> not) s')

    let minimal p s =
      let rec aux s1 s2 =
        match s1 with
        | [] -> s2
        | x :: s1' ->if p (s1' @ s2) then aux s1' s2 else aux s1' (x :: s2)
      in
      aux s []

    let rec cover = function
      | [] -> []
      | s :: ss' ->
        if List.exists (Fn.flip subset s) ss' then cover ss' else s :: cover ss'

  end

  (** Bags (aka multisets, lists modulo permutation) *)
  module Bag = sig
    type 'a t = 'a list

    (** {6 Inspectors} *)

    val subset : 'a t -> 'a t -> bool
    val equiv : 'a t -> 'a t -> bool

    val non_duplicated : ?cmp:('a -> 'a -> bool) -> 'a t -> bool
    val duplicated : ?cmp:('a -> 'a -> bool) -> 'a t -> bool
    val num_occurrences : 'a -> 'a t -> int

    (** {6 Operators} *)

    val inter : 'a t -> 'a t -> 'a t
    val diff : 'a t -> 'a t -> 'a t

    (** @todo verify that this always returns a set *)
    val get_dup_elems : ?cmp:('a -> 'a -> bool) -> 'a t -> 'a Set.t
  end = struct
    type 'a t = 'a list

    (** {6 Inspectors} *)

    let rec subset l1 l2 =
      match l1 with
      | [] -> true
      | x :: l1' ->
        try let l, _, r = List.pick ((=) x) l2 in subset l1' (l @ r)
        with Not_found -> false
    let equiv l1 l2 = subset l1 l2 && subset l2 l1

    let non_duplicated ?(cmp = (=)) b = List.eq_length (List.unique ~cmp:cmp b) b
    let duplicated ?(cmp = (=)) = non_duplicated ~cmp:cmp >> not
    let num_occurrences x = List.filter ((=) x) >> List.length

    let rec get_dup_elems ?(cmp = (=)) = function
      | [] -> []
      | x :: b' ->
        let b'' = List.delete (cmp x) b' in
        if not (List.eq_length b' b'')
        then x :: get_dup_elems b''
        else get_dup_elems b'

    (** {6 Operators} *)

    let rec inter l1 l2 =
      match l1 with
      | [] -> []
      | x :: l1' ->
        try let l, _, r = List.pick ((=) x) l2 in x :: inter l1' (l @ r)
        with Not_found -> inter l1' l2

    let rec diff l1 l2 =
      match l1 with
      | [] -> []
      | x :: l1' ->
        try let l, _, r = List.pick ((=) x) l2 in diff l1' (l @ r)
        with Not_found -> x :: diff l1' l2
  end

  (** Maps *)
  module Map = sig
    type ('a, 'b) _elem = 'a * 'b
    type ('a, 'b) _t = ('a, 'b) _elem list

    (** {6 Printers} *)

    val pr_elem :
      (Format.formatter -> 'a -> unit) ->
      (Format.formatter -> 'b -> unit) ->
      Format.formatter -> ('a, 'b) _elem -> unit
    val pr :
      (Format.formatter -> 'a -> unit) ->
      (Format.formatter -> 'b -> unit) ->
      Format.formatter -> ('a, 'b) _t -> unit

    (** {6 Morphisms} *)

    val map_dom : ('a -> 'c) -> ('a, 'b) _t -> ('c, 'b) _t
    val map_codom : ('b -> 'c) -> ('a, 'b) _t -> ('a, 'c) _t

    (** {6 Inspectors} *)

    (** @raise Not_found if [x] is not in [dom f] *)
    val apply : ('a, 'b) _t -> 'a -> 'b
    val apply_default : 'b -> ('a, 'b) _t -> 'a -> 'b
    val applyD : 'b -> ('a, 'b) _t -> 'a -> 'b
    val apply_fail : ('a, 'b) _t -> 'a -> 'b
    val applyF : ('a, 'b) _t -> 'a -> 'b
    val apply_inverse : ('a, 'b) _t -> 'b -> 'a
    val apply_inverse_fail : ('a, 'b) _t -> 'b -> 'a

    val non_dup : ('a, 'b) _t -> bool
    val is_map : ('a, 'b) _t -> bool
    val in_dom : 'a -> ('a, 'b) _t -> bool

    val dom : ('a, 'b) _t -> 'a list
    val codom : ('a, 'b) _t -> 'b list

    (** {6 Operators} *)

    val diff : ('a, 'b) _t -> 'a list -> ('a, 'b) _t
    val restrict : ('a, 'b) _t -> 'a list -> ('a, 'b) _t
    val update : ('a, 'b) _t -> 'a -> 'b -> ('a, 'b) _t

    val merge : ('a, 'b list) _t -> ('a, 'b list) _t
    val merge2 : ('a, 'b list) _t -> ('a, 'b list) _t -> ('a, 'b list) _t
  end = struct
    type ('a, 'b) _elem = 'a * 'b
    type ('a, 'b) _t = ('a, 'b) _elem list

    (** {6 Printers} *)

    let pr_elem epr1 epr2 ppf (x, y) =
      Format.fprintf ppf "@[<hov>%a ->@ %a@]" epr1 x epr2 y
    let pr epr1 epr2 ppf =
      Format.fprintf ppf "%a" (List.pr (pr_elem epr1 epr2) "@,")

    (** {6 Morphisms} *)

    let map_dom f = List.map (fun (x, y) -> f x, y)
    let map_codom f = List.map (fun (x, y) -> x, f y)

    (** {6 Inspectors} *)

    let empty = []
    let size = List.length
    let apply m x = List.assoc x m
    let apply_default d m x = List.assoc_default d x m
    let applyD = apply_default
    let apply_fail m x = List.assoc_fail x m
    let applyF = apply_fail

    let apply_inverse m x =
      List.find_map (fun (a, b) -> if b = x then Some a else None) m
    let apply_inverse_fail m x =
      try apply_inverse m x with Not_found -> assert false

    let non_dup m =
      m |> List.classify (comp2 (=) fst fst)
      |> List.for_all (List.unique >> List.length >> (=) 1)
    let is_map m = m |> List.map fst |> Bag.non_duplicated
    let in_dom = List.mem_assoc

    let dom m = List.map fst m
    let codom m = List.map snd m

    (** {6 Operators} *)

    let diff m xs = List.filter (fun (x, _) -> not (List.mem x xs)) m
    let restrict m xs = List.filter (fun (x, _) -> List.mem x xs) m
    let update m x y = (x, y) :: diff m [x]

    let rec merge = function
      | [] -> []
      | (x, v) :: m' ->
        let t, f = List.partition (fst >> (=) x) m' in
        (x, v @ List.concat_map snd t) :: merge f
    let merge2 m1 m2 = merge (m1 @ m2)
  end

  (** Set partitions *)
  module Partition = struct
    let top s = [s]
    let bot s = List.map ~f:(fun e -> [e]) s

    let meet ps1 ps2 =
      Vector.multiply Set.inter ps1 ps2
      |> List.unique ~equal:Set.equiv
      |> List.filter ~f:(Fn.non List.is_empty)

    (* this may not return a correct partition
      [join {{1,2},{3,4}} {{2,3},{1,4}}] returns
      [{{1,2,3},{1,2,4},{2,3,4},{1,3,4}}]
    *)
    let join ps1 ps2 =
      Vector.multiply Set.union ps1 ps2
      |> List.unique ~equal:Set.equiv
      |> List.filter ~f:(Fn.non List.is_empty)


    let label_of_ij i j = "x_" ^ string_of_int i ^ "_" ^ string_of_int j
    let ij_of_label label =
      assert (String.is_prefix label ~prefix:"x_");
      try
        Stdlib.String.sub label 2 (String.length label - 2)
        |> String.lsplit2_exn ~on:'_'
        |> Pair.lift int_of_string
      with Not_found_s _ -> assert false
  end*)
end

(** Sets *)
module Set = struct
  include Set

  let is_singleton s = length s = 1

  let of_map m = Set.Poly.of_list @@ Map.Poly.to_alist m

  let cartesian_map ?(init = Set.Poly.empty) ~f s1 s2 =
    Set.Poly.fold s1 ~init ~f:(fun acc x1 ->
        Set.Poly.fold s2 ~init:acc ~f:(fun acc x2 -> Set.Poly.add acc (f x1 x2)))

  let fold_distinct_pairs ?(init = Set.Poly.empty) ~f s =
    Set.Poly.fold s ~init ~f:(fun acc x1 ->
        Set.Poly.fold s ~init:acc ~f:(fun acc x2 ->
            if Stdlib.compare x1 x2 = 0 then acc else Set.Poly.add acc (f x1 x2)))

  let unzip s = (Set.Poly.map s ~f:fst, Set.Poly.map s ~f:snd)

  let concat s = Set.Poly.union_list @@ Set.Poly.to_list s
  let concat_map s ~f =
    Set.Poly.fold s ~init:Set.Poly.empty ~f:(fun acc x -> Set.Poly.union acc (f x))

  let partition_map s ~f =
    Set.Poly.fold s ~init:(Set.Poly.empty, Set.Poly.empty) ~f:(fun (s1, s2) x ->
        match f x with
        | First y -> Set.Poly.add s1 y, s2
        | Second y -> s1, Set.Poly.add s2 y)

  let representatives s ~equiv =
    Set.Poly.group_by s ~equiv
    |> List.map ~f:Set.Poly.choose_exn
    |> Set.Poly.of_list
end

(** Maps *)
module Map = struct
  include Map

  let of_set_exn s = Map.Poly.of_alist_exn @@ Set.Poly.to_list s
  let of_list_exn l = of_set_exn @@ Set.Poly.of_list l (*ToDo: different from [Map.of_alist_exn]?*)
  let to_set = Set.of_map

  let cartesian_map ?(init = Map.Poly.empty) ~f m1 m2 =
    Map.Poly.fold m1 ~init ~f:(fun ~key:key1 ~data:data1 acc ->
        Map.Poly.fold m2 ~init:acc ~f:(fun ~key:key2 ~data:data2 acc ->
            f acc key1 data1 key2 data2))

  (* assume f is injective, params not in dom(f) could be discared *)
  let rename_keys map ~f =
    Map.Poly.fold map ~init:Map.Poly.empty ~f:(fun ~key ~data acc ->
        match f key with
        | None -> if Map.Poly.mem acc key then acc else Map.Poly.add_exn ~key ~data acc
        | Some key' -> Map.Poly.set acc ~key:key' ~data)

  (* assume f is injective, params not in dom(f) will be discared *)
  let rename_keys_and_drop_unused map ~f =
    Map.Poly.fold map ~init:Map.Poly.empty ~f:(fun ~key ~data acc ->
        match f key with
        | None -> acc
        | Some key' -> Map.Poly.add_exn acc ~key:key' ~data)

  let rename_keys_map rename_map map = rename_keys map ~f:(Map.Poly.find rename_map)

  let change_keys map ~f =
    Map.Poly.fold map ~init:Map.Poly.empty ~f:(fun ~key ~data acc ->
        let newkey = f key in
        if Map.Poly.mem acc newkey then assert false
        else Map.Poly.add_exn acc ~key:newkey ~data)

  let force_add map key data =
    try Map.Poly.add_exn map ~key ~data with _ ->
    match Map.Poly.find map key with
    | Some data' -> if Stdlib.(data = data') then map else failwith "force_add"
    | None -> assert false
  (*let force_merge ?(catch_dup=ignore) =
    Map.Poly.merge ~f:(fun ~key -> function
        | `Left data | `Right data -> Some data
        | `Both (data1, data2) ->
          if Stdlib.(data1 = data2) then Some data1
          else (catch_dup (key, data1, data2); failwith "force_merge"))*)
  let force_merge ?(catch_dup=ignore) =
    Map.Poly.merge_skewed ~combine:(fun ~key data1 data2 ->
        if Stdlib.(data1 = data2) then data1
        else (catch_dup (key, data1, data2); failwith "force_merge"))
  let force_merge_list ?(catch_dup=ignore) =
    List.fold ~init:Map.Poly.empty ~f:(force_merge ~catch_dup)
  let update_with map1 map2 =
    Map.Poly.merge_skewed map1 map2 ~combine:(fun ~key _ data -> ignore key; data)
  let update_with_list = List.fold ~init:Map.Poly.empty ~f:update_with

  let restrict ~def map dom =
    Set.Poly.fold dom ~init:Map.Poly.empty ~f:(fun acc key ->
        Map.Poly.add_exn acc ~key
          ~data:(match Map.Poly.find map key with Some data -> data | None -> def key))

  let remove_keys map = List.fold ~init:map ~f:Map.Poly.remove
  let remove_keys_set map = Set.Poly.fold ~init:map ~f:Map.Poly.remove

  let find_with ~f map = Map.Poly.filter map ~f |> to_alist
end

(** Arrays *)
module Array = struct
  include Array

  let remove a idx = Array.filteri a ~f:(fun i _ -> i <> idx)
  let unzip ar = Array.map ~f:fst ar, Array.map ~f:snd ar
end

module IncrArray = struct
  include Array

  let grow_to t dim =
    assert (Array.length t < dim);
    let new_arr = create ~len:dim t.(0) in
    blito ~src:t ~dst:new_arr ();
    new_arr

  let grow t i =
    let rec aux length =
      if length > i then length
      else aux @@ (length + 1) * 2
    in
    grow_to t (aux @@ length t)

  let auto_set t i e =
    let t' = if i < length t then t else grow t i in
    set t' i e; t'
end

module IncrBigArray2 = struct
  include Bigarray.Array2

  let auto_blit src dst =
    for i = 0 to dim1 src - 1 do
      let slice_dst = Bigarray.Array1.sub (slice_left dst i) 0 (dim2 src) in
      let slice_src = slice_left src i in
      Bigarray.Array1.blit slice_src slice_dst
    done

  let grow_to t dim_x dim_y =
    assert (dim1 t <= dim_x && dim2 t <= dim_y);
    let new_arr = create (kind t) (layout t) dim_x dim_y in
    auto_blit t @@ new_arr;
    new_arr

  let rec grow_aux length i=
    if length > i then length
    else grow_aux ((length + 1) * 2) i

  let grow_x_y t x y = grow_to t (grow_aux (dim1 t) x) (grow_aux (dim2 t) y)
  let grow_x t x = grow_to t (grow_aux (dim1 t) x) (dim2 t)
  let grow_y t y = grow_to t (dim1 t) (grow_aux (dim2 t) y)

  let auto_set t x y e =
    let t' =
      if x >= dim1 t && y >= dim2 t then grow_x_y t x y
      else if x >= dim1 t then grow_x t x
      else if y >= dim2 t then grow_y t y
      else t
    in set t' x y e; t'
end

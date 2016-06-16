open Sexplib.Conv
open Core_result.Export

module Stable = struct
  module V1 = struct
    type 'a t = ('a, Error.Stable.V1.t) Core_result.Stable.V1.t [@@deriving bin_io, compare, sexp]

    let map x ~f = Core_result.Stable.V1.map x ~f1:f ~f2:Fn.id
  end
  module V2 = struct
    type 'a t = ('a, Error.Stable.V2.t) Core_result.Stable.V1.t [@@deriving bin_io, compare, sexp]

    let map x ~f = Core_result.Stable.V1.map x ~f1:f ~f2:Fn.id
  end
end

(* 2015-01-14: We don't [include Stable.V1], because that has a different [with bin_io]
   format, and we don't want to change this "unstable" format, which is in use.  We just
   introduced the stable format, so people haven't yet had the time to adjust code to use
   it. *)
type 'a t = ('a, Error.t) Core_result.t [@@deriving bin_io, compare, sexp]

let invariant invariant_a t =
  match t with
  | Ok a -> invariant_a a
  | Error error -> Error.invariant error
;;

module List = Core_list

include (Core_result : Monad.S2
         with type ('a, 'b) t := ('a, 'b) Core_result.t
         with module Let_syntax := Core_result.Let_syntax)

include Applicative.Make (struct
    type nonrec 'a t = 'a t
    let return = return
    let apply f x =
      Core_result.combine f x
        ~ok:(fun f x -> f x)
        ~err:(fun e1 e2 -> Error.of_list [e1; e2])
    let map = `Custom map
  end)

module Let_syntax = struct
  let return = return
  include Monad_infix
  module Let_syntax = struct
    let return = return
    let map    = map
    let bind   = bind
    let both   = both (* from Applicative.Make *)
    module Open_on_rhs  = struct end
  end
end

let ignore = ignore_m

let try_with ?(backtrace = false) f =
  try Ok (f ())
  with exn -> Error (Error.of_exn exn ?backtrace:(if backtrace then Some `Get else None))
;;

let try_with_join ?backtrace f = join (try_with ?backtrace f)

let ok_exn = function
  | Ok x -> x
  | Error err -> Error.raise err
;;

let of_exn ?backtrace exn = Error (Error.of_exn ?backtrace exn)

let of_exn_result = function
  | Ok _ as z -> z
  | Error exn -> of_exn exn
;;

let error ?strict message a sexp_of_a =
  Error (Error.create ?strict message a sexp_of_a)
;;

let error_s sexp = Error (Error.create_s sexp)

let error_string message = Error (Error.of_string message)

let errorf format = Printf.ksprintf error_string format

let%test _ = errorf "foo %d" 13 = error_string "foo 13"

let tag t ~tag = Core_result.map_error t ~f:(Error.tag ~tag)
let tag_arg t message a sexp_of_a =
  Core_result.map_error t ~f:(fun e -> Error.tag_arg e message a sexp_of_a)

let unimplemented s = error "unimplemented" s [%sexp_of: string]

let combine_errors l =
  let ok, errs = List.partition_map l ~f:Core_result.ok_fst in
  match errs with
  | [] -> Ok ok
  | _ -> Error (Error.of_list errs)

let%test_unit _ =
  for i = 0 to 10; do
    assert (combine_errors (List.init i ~f:(fun _ -> Ok ()))
            = Ok (List.init i ~f:(fun _ -> ())));
  done
let%test _ = Core_result.is_error (combine_errors [ error_string "" ])
let%test _ = Core_result.is_error (combine_errors [ Ok (); error_string "" ])


let combine_errors_unit l = Core_result.map (combine_errors l) ~f:(fun (_ : unit list) -> ())

let%test _ = combine_errors_unit [Ok (); Ok ()] = Ok ()
let%test _ = combine_errors_unit [] = Ok ()
let%test _ =
  let a = Error.of_string "a" and b = Error.of_string "b" in
  match combine_errors_unit [Ok (); Error a; Ok (); Error b] with
  | Ok _ -> false
  | Error e -> Error.to_string_hum e = Error.to_string_hum (Error.of_list [a;b])

let filter_ok_at_least_one l =
  let ok, errs = List.partition_map l ~f:Core_result.ok_fst in
  match ok with
  | [] -> Error (Error.of_list errs)
  | _ -> Ok ok

let find_ok l =
  match List.find_map l ~f:Core_result.ok with
  | Some x -> Ok x
  | None ->
    Error (Error.of_list (List.map l ~f:(function
      | Ok _ -> assert false
      | Error err -> err)))

let find_map_ok l ~f =
  With_return.with_return (fun {return} ->
    Error (Error.of_list (List.map l ~f:(fun elt ->
      match f elt with
      | (Ok _ as x) -> return x
      | Error err -> err))))



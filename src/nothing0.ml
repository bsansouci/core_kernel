(* To break the circular dependency *)

type t [@@deriving sexp, compare]

let all = []

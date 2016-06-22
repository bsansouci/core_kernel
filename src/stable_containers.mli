(** The Stable versions of Hashtbl, Hash_set, Map, and Set are defined here rather than in
    their respective modules because:

    1. We guarantee their serializations independent of the implementation of those modules
    2. Given 1. it is cleaner (and still okay) to separate the code into a separate file *)

open Std_internal

module Hashable : sig
  module V1 : sig
    module type S = sig
      type key

      module Table : sig
        type 'a t = (key, 'a) Hashtbl.t [@@deriving sexp]
      end

      module Hash_set : sig
        type t = key Hash_set.t [@@deriving sexp]
      end
    end

    module Make (Key : Hashtbl.Key) : S with type key := Key.t
  end
end

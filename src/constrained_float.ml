open Std_internal

module type S = sig
  type t = private float [@@deriving sexp]
  include Comparable  with type t := t
  include Hashable    with type t := t
  include Robustly_comparable with type t := t
  include Stringable          with type t := t
  include Floatable           with type t := t
end

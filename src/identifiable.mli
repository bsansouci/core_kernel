(** a signature for identifier types. *)

module type S = sig
  type t [@@deriving sexp]
  include Stringable.S         with type t := t
  include Comparable.S with type t := t
  include Hashable.S   with type t := t
  include Pretty_printer.S     with type t := t
end

(** Used for making an Identifiable module.  Here's an example.

    {[
      module Id = struct
        module T = struct
          type t = A | B [@@deriving compare, sexp]
          let hash (t : t) = Hashtbl.hash t
          include Sexpable.To_stringable (struct type nonrec t = t [@@deriving sexp] end)
          let module_name = "My_library.Std.Id"
        end
        include T
        include Identifiable.Make (T)
      end
    ]}
*)
module Make (M : sig
    type t [@@deriving compare, sexp]
    include Stringable.S with type t := t
    val hash : t -> int
    val module_name : string  (** for registering the pretty printer *)
  end) : S
  with type t := M.t

module Make_using_comparator (M : sig
    type t [@@deriving compare, sexp]
    include Comparator.S with type t := t
    include Stringable.S with type t := t
    val hash : t -> int
    val module_name : string
  end) : S
  with type t := M.t
  with type comparator_witness := M.comparator_witness

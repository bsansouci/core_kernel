(** For making an abstract version of a type that ensures a validation check has passed.

    Suppose one wants to have a type of positive integers:

    {[
      module Positive_int = Validated.Make (struct
          type t = int
          let here = [%here]
          let validate = Int.validate_positive
        end)
    ]}

    With this, one is certain that any value of type [Positive_int.t] has passed
    [Int.validate_positive].

    One can call [Positive_int.create_exn n] to create a new positive int from an [n],
    which will of course raise if [n <= 0].  One can call [Positive_int.raw positive_int]
    to get the [int] from a [Positive_int.t].
*)

module type Raw = sig
  type t [@@deriving sexp]

  (** [here] will appear in validation-failure error messages. *)
  val here : Source_code_position.t

  val validate : t Validate.check
end

(* module type Raw_binable = sig
  type t

  include Raw with type t := t

  (** [validate_binio_deserialization] controls whether when the binio representation of a
      value is deserialized, the resulting value is validated.  Whether one needs to
      validate values upon deserialization depends on how serialization is being used.  If
      one only ever serializes/deserializes so that the validation function is the same on
      both ends, then one need not validate upon deserialization, because only values that
      already pass the validation function can be serialized.

      If the validation functions in the serializer and deserializer may be different,
      e.g. because of two different versions of the code compiled at different times, then
      it is possible to serialize a value that may fail validation upon deserialization.
      In that case, having [validate_binio_deserialization = true] is necessary to prevent
      creating values that don't pass the validation function. *)
  val validate_binio_deserialization : bool
end *)

module type S = sig
  type ('raw, 'witness) validated
  type witness
  type raw
  type t = (raw, witness) validated [@@deriving sexp]

  val create     : raw -> t Or_error.t
  val create_exn : raw -> t

  val raw : t -> raw
end

(* module type S_binable = sig
  include S
  include sig type t = (raw, witness) validated end with type t := t
end *)

module type Validated = sig
  type ('raw, 'witness) t = private 'raw

  val raw : ('raw, _) t -> 'raw

  module type Raw = Raw

  module type S         = S         with type ('a, 'b) validated := ('a, 'b) t
  (* module type S_binable = S_binable with type ('a, 'b) validated := ('a, 'b) t *)

  module Make         (Raw : Raw)         : S         with type raw := Raw.t
  (* module Make_binable (Raw : Raw_binable) : S_binable with type raw := Raw.t *)
end

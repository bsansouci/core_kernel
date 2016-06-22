(* A 63bit integer is a 64bit integer with its bits shifted to the left
   and its lowest bit set to 0.
   This is the same kind of encoding as OCaml int on 64bit architecture.
   The only difference being the lowest bit (immediate bit) set to 1.
*)
open Typerep_lib.Std
open Sexplib.Std
(* open Bin_prot.Std *)

module Conv = Int_conversions

module W : sig
  type t [@@deriving sexp, typerep]
  val wrap_exn   : Int64.t -> t
  val wrap_modulo : Int64.t -> t
  val unwrap : t -> Int64.t
  val add    : t -> t -> t
  val sub    : t -> t -> t
  val neg    : t -> t
  val abs    : t -> t
  val succ   : t -> t
  val pred   : t -> t
  val mul    : t -> t -> t
  val pow    : t -> t -> t
  val div    : t -> t -> t
  val rem    : t -> t -> t
  val popcount : t -> int
  val bit_not   : t -> t
  val bit_xor   : t -> t -> t
  val bit_or    : t -> t -> t
  val bit_and   : t -> t -> t
  val shift_left : t -> int -> t
  val shift_right : t -> int -> t
  val shift_right_logical : t -> int -> t
  val min_value : t
  val max_value : t

  val to_int64 : t -> Int64.t
  val of_int64_exn : Int64.t -> t

  val compare : t -> t -> int
end = struct
  type t = int64 [@@deriving typerep]

  let wrap_exn x =
    (* Raises if the int64 value does not fit on int63. *)
    Conv.int64_fit_on_int63_exn x;
    Int64.mul x 2L
  let wrap_modulo x =
    Int64.mul x 2L
  let unwrap x =
    Int64.shift_right x 1

  (* This does not use wrap or unwrap to avoid generating exceptions in the case of
     overflows. This is to preserve the semantics of int type on 64 bit architecture. *)
  let f2 f a b = Int64.mul (f (Int64.shift_right a 1) (Int64.shift_right b 1)) 2L

  let mask = 0xffff_ffff_ffff_fffeL

  let m x = Int64.logand x mask

  let add x y = Int64.add x y
  let sub x y = Int64.sub x y
  let neg x = Int64.neg x
  let abs x = Int64.abs x
  let one = wrap_exn 1L
  let succ a = add a one
  let pred a = sub a one
  let min_value = m Int64.min_int
  let max_value = m Int64.max_int
  let bit_not x = m (Int64.lognot x)
  let bit_and = Int64.logand
  let bit_xor = Int64.logxor
  let bit_or  = Int64.logor
  let shift_left x i = Int64.shift_left x i
  let shift_right x i = m (Int64.shift_right x i)
  let shift_right_logical x i = m (Int64.shift_right_logical x i)
  let pow = f2 Int_math.int63_pow_on_int64
  let mul a b = Int64.mul a (Int64.shift_right b 1)
  let div a b = wrap_modulo (Int64.div a b)
  let rem a b = Int64.rem a b
  let popcount x = Int_math.int64_popcount x

  let to_int64 t = unwrap t
  let of_int64_exn t = wrap_exn t

  let t_of_sexp x = wrap_exn (int64_of_sexp x)
  let sexp_of_t x = sexp_of_int64 (unwrap x)

  let compare (x : t) y = compare x y

end

open W

module T = struct
  type t = W.t [@@deriving sexp, typerep]

  let compare = W.compare

  let equal (x : t) y = x = y

  (* We don't expect [hash] to follow the behavior of int in 64bit architecture *)
  let hash (x : t) = Hashtbl.hash x

  let invalid_str x = failwith (Printf.sprintf "Int63.of_string: invalid input %S" x)

  (*
     "sign" refers to whether the number starts with a '-'
     "signedness = false" means the rest of the number is parsed as unsigned and then cast
     to signed with wrap-around modulo 2^i
     "signedness = true" means no such craziness happens

     The terminology and the logic is due to the code in byterun/ints.c in ocaml 4.03
     ([parse_sign_and_base] function).

     Signedness equals true for plain decimal number (e.g. 1235, -6789)

     Signedness equals false in the following cases:
     - [0xffff], [-0xffff] (hexadecimal representation)
     - [0b0101], [-0b0101] (binary representation)
     - [0o1237], [-0o1237] (octal representation)
     - [0u9812], [-0u9812] (unsigned decimal representation - available from OCaml 4.03)
  *)
  let sign_and_signedness x =
    let len = String.length x in
    let pos,sign =
      if 0 < len
      then match x.[0] with
        | '-' -> 1,`Neg
        | '+' -> 1, `Pos
        | _ -> 0, `Pos
      else
        0, `Pos
    in
    if pos + 2 < len then
      let c1 = x.[pos] in
      let c2 = x.[pos + 1] in
      match c1, c2 with
      | '0', ('0' .. '9') -> sign,true
      | '0', _            -> sign,false
      | _                 -> sign,true
    else sign, true

  let to_string x = Int64.to_string (unwrap x)

  let of_string str =
    try
      let sign,signedness = sign_and_signedness str in
      if signedness
      then of_int64_exn (Int64.of_string str)
      else
        let pos_str =
          if sign = `Neg
          then String.sub str 1 (String.length str - 1)
          else str
        in
        let int64 = Int64.of_string pos_str in
        (* unsigned 63-bit int must parse as a positive signed 64-bit int *)
        if int64 < 0L then invalid_str str;
        let int63 = wrap_modulo int64 in
        if sign = `Neg then neg int63 else int63
    with _ -> invalid_str str

  (* include Binable0.Of_binable
      (struct
        type t = int64
      end)
      (struct
        type t = W.t
        let of_binable = wrap_exn
        let to_binable = unwrap
      end) *)
end

include T

let num_bits = 63

let shift_right_logical = shift_right_logical
let shift_right = shift_right
let shift_left = shift_left
let bit_not = bit_not
let bit_xor = bit_xor
let bit_or = bit_or
let bit_and = bit_and
let popcount = popcount
let abs = abs
let pred = pred
let succ = succ
let pow = pow
let rem = rem
let neg = neg
let max_value = max_value
let min_value = min_value
let minus_one = wrap_exn Int64.minus_one
let one = wrap_exn Int64.one
let zero = wrap_exn Int64.zero
let compare = compare
let to_float x = Int64.to_float (unwrap x)
let of_float x = wrap_modulo (Int64.of_float x)
let of_int64_exn = of_int64_exn
let to_int64 = to_int64

include Comparable.Validate_with_zero (struct
  include T
  let zero = zero
end)

module Replace_polymorphic_compare = struct
  let equal = equal
  let compare = compare
  let ascending = compare
  let descending x y = compare y x
  let min (x : t) y = if x < y then x else y
  let max (x : t) y = if x > y then x else y
  let ( >= ) (x : t) y = x >= y
  let ( <= ) (x : t) y = x <= y
  let ( = ) (x : t) y = x = y
  let ( > ) (x : t) y = x > y
  let ( < ) (x : t) y = x < y
  let ( <> ) (x : t) y = x <> y
  let between t ~low ~high = low <= t && t <= high
  let clamp_unchecked t ~min ~max =
    if t < min then min else if t <= max then t else max

  let clamp_exn t ~min ~max =
    assert (min <= max);
    clamp_unchecked t ~min ~max

  let clamp t ~min ~max =
    if min > max then
      Or_error.error "clamp requires [min <= max]"
        (`Min min, `Max max) [%sexp_of: [`Min of T.t] * [`Max of T.t]]
    else
      Ok (clamp_unchecked t ~min ~max)
end

include Replace_polymorphic_compare

include Hashable.Make (T)
include Comparable.Map_and_set (T)

let ( / ) = div
let ( * ) = mul
let ( - ) = sub
let ( + ) = add
let ( ~- ) = neg

let incr r = r := !r + one
let decr r = r := !r - one

(* We can reuse conversion function from/to int64 here. *)
let of_int x = wrap_exn (Conv.int_to_int64 x)
let of_int_exn x = of_int x
let to_int x = Conv.int64_to_int (unwrap x)
let to_int_exn x = Conv.int64_to_int_exn (unwrap x)

let of_int32 x = wrap_exn (Conv.int32_to_int64 x)
let of_int32_exn x = of_int32 x
let to_int32_exn x = Conv.int64_to_int32_exn (unwrap x)

let of_nativeint_exn x = wrap_exn (Conv.nativeint_to_int64 x)
let to_nativeint_exn x = Conv.int64_to_nativeint_exn (unwrap x)

include Conv.Make (T)

include Conv.Make_hex(struct

  type t = T.t [@@deriving compare, typerep]

  let zero = zero
  let neg = (~-)
  let (<) = (<)
  let to_string i = Printf.sprintf "%Lx" (unwrap i)
  let of_string s = Scanf.sscanf s "%Lx" wrap_exn

  let module_name = "Core_kernel.Std.Int63.Hex"

end)

include Pretty_printer.Register (struct
  type nonrec t = t
  let to_string x = to_string x
  let module_name = "Core_kernel.Std.Int63"
end)

include Quickcheck.Make_int (struct
    type nonrec t = t [@@deriving sexp, compare]
    include (Replace_polymorphic_compare
             : Polymorphic_compare_intf.Infix with type t := t)
    let (+)                 = (+)
    let (-)                 = (-)
    let (~-)                = (~-)
    let zero                = zero
    let one                 = one
    let min_value           = min_value
    let max_value           = max_value
    let succ                = succ
    let bit_and             = bit_and
    let shift_left          = shift_left
    let shift_right         = shift_right
    let shift_right_logical = shift_right_logical
    let of_int_exn          = of_int_exn
    let to_float            = to_float
  end)

module Pre_O = struct
  let ( + ) = ( + )
  let ( - ) = ( - )
  let ( * ) = ( * )
  let ( / ) = ( / )
  let ( ~- ) = ( ~- )
  include (Replace_polymorphic_compare : Polymorphic_compare_intf.Infix with type t := t)
  let abs = abs
  let neg = neg
  let zero = zero
  let of_int_exn = of_int_exn
end

module O = struct
  include Pre_O
  include Int_math.Make (struct
    type nonrec t = t
    include Pre_O
    let rem = rem
    let to_float = to_float
    let of_float = of_float
    let of_string = T.of_string
    let to_string = T.to_string
  end)
end

include O (* [Int63] and [Int63.O] agree value-wise *)

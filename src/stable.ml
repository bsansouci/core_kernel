(* miscellaneous unit tests that can't be put in their respective .mls due to circular
   dependencies *)

module type Stable                    = Stable_module_types.S0
module type Stable_without_comparator = Stable_module_types.S0_without_comparator
module type Stable1                   = Stable_module_types.S1
module type Stable2                   = Stable_module_types.S2

include Stable_internal
include Stable_containers

module Binable       = Binable       .Stable
module Blang         = Blang         .Stable
module Byte_units    = Byte_units    .Stable
module Comparable    = Comparable    .Stable
module Comparator    = Comparator    .Stable
module Day_of_week   = Day_of_week   .Stable
module Either        = Either        .Stable
module Error         = Error         .Stable
module Fdeque        = Fdeque        .Stable
module Fqueue        = Fqueue        .Stable
module Host_and_port = Host_and_port .Stable
module Info          = Info          .Stable
module Int           = Core_int      .Stable
module Lazy          = Core_lazy     .Stable
module Map           = Core_map      .Stable
module Month         = Month         .Stable
module Nothing       = Nothing       .Stable
module Or_error      = Or_error      .Stable
module Percent       = Percent       .Stable
module Perms         = Perms         .Stable
module Result        = Core_result   .Stable
module Set           = Core_set      .Stable
module Sexpable      = Sexpable      .Stable
module String        = Core_string   .Stable
module String_id     = String_id     .Stable

include Perms.Export

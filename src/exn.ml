module Sexp = Sexplib.Sexp
module Conv = Sexplib.Conv
open Sexplib.Std

let sexp_of_exn = Conv.sexp_of_exn
let sexp_of_exn_opt = Conv.sexp_of_exn_opt

type t = exn [@@deriving sexp_of]

exception Finally of t * t [@@deriving sexp]
exception Reraised of string * t [@@deriving sexp]

let reraise exc str =
  raise (Reraised (str, exc))

let reraisef exc format =
  Printf.ksprintf (fun str () -> reraise exc str) format

(* let install_sexp_converters () =
  StdLabels.List.iter
    ~f:(fun (exc, handler) ->
      Conv.Exn_converter.add_auto ~finalise:false exc handler)
    [
      (
        Bin_prot.Common.Read_error (Bin_prot.Common.ReadError.Neg_int8, 0),
        (function
        | Bin_prot.Common.Read_error (err, pos) ->
            let str_err = Bin_prot.Common.ReadError.to_string err in
            Sexp.List [
              Sexp.Atom "Bin_prot.Common.Read_error";
              Sexp.Atom str_err;
              Conv.sexp_of_int pos;
            ]
        | _ -> assert false)
      );
    ] *)

let to_string exc = Sexp.to_string_hum ~indent:2 (sexp_of_exn exc)
let to_string_mach exc = Sexp.to_string_mach (sexp_of_exn exc)

let sexp_of_t = sexp_of_exn

let protectx ~f x ~(finally : _ -> unit) =
  let res =
    try f x
    with exn ->
      (try finally x with final_exn -> raise (Finally (exn, final_exn)));
      raise exn
  in
  finally x;
  res
;;

let protect ~f ~finally = protectx ~f () ~finally

let does_raise (type a) (f : unit -> a) =
  try
    ignore (f () : a);
    false
  with _ ->
    true
;;

let%test _ = not (does_raise Fn.ignore)
let%test _ = does_raise (fun () -> failwith "foo")

include Pretty_printer.Register_pp (struct
  type t = exn
  let pp ppf t =
    match sexp_of_exn_opt t with
    | Some sexp -> Sexp.pp_hum ppf sexp
    | None -> Format.pp_print_string ppf (Printexc.to_string t)
  ;;
  let module_name = "Core_kernel.Std.Exn"
end)

let backtrace = Printexc.get_backtrace

let print_with_backtrace exc raw_backtrace =
  Format.eprintf "@[<2>Uncaught exception:@\n@\n@[%a@]@]@\n@." pp exc;
  if Printexc.backtrace_status () then Printexc.print_raw_backtrace stderr raw_backtrace;
  flush stderr;
;;

let set_uncaught_exception_handler () =
  Printexc.set_uncaught_exception_handler print_with_backtrace
;;

let handle_uncaught_aux ~do_at_exit ~exit f =
  try f ()
  with exc ->
    let raw_backtrace = Printexc.get_raw_backtrace () in
    if do_at_exit then (try Pervasives.do_at_exit () with _ -> ());
    begin
      try
        print_with_backtrace exc raw_backtrace
      with _ ->
        try
          Printf.eprintf "Exn.handle_uncaught could not print; exiting anyway\n%!";
        with _ -> ()
    end;
    exit 1
;;

let handle_uncaught_and_exit f = handle_uncaught_aux f ~exit ~do_at_exit:true

let handle_uncaught ~exit:must_exit f =
  handle_uncaught_aux f ~exit:(if must_exit then exit else ignore)
    ~do_at_exit:must_exit

let reraise_uncaught str func =
  try func () with
  | exn -> raise (Reraised (str, exn))

(* external clear_backtrace : unit -> unit = "clear_caml_backtrace_pos" "noalloc" *)
let raise_without_backtrace e =
  (* We clear the backtrace to reduce confusion, so that people don't think whatever
     is stored corresponds to this raise. *)
  (* clear_backtrace (); *)
  raise_notrace e
;;

let initialize_module () =
  (* install_sexp_converters (); *)
  set_uncaught_exception_handler ();
;;

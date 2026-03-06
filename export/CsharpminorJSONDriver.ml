(* *********************************************************************)
(*              The Compcert verified compiler                         *)
(* *********************************************************************)

open Printf
open Commandline
open CommonOptions
open Driveraux
open Frontend
open Diagnostics

let tool_name = "Csharpminor JSON Exporter"

let export_csharpminor sourcename csyntax ofile =
  let loc = file_loc sourcename in
  let clight =
    match SimplExpr.transl_program csyntax with
    | Errors.OK p ->
        begin match SimplLocals.transf_program p with
        | Errors.OK p' -> p'
        | Errors.Error msg -> fatal_error loc "%a" print_error msg
        end
    | Errors.Error msg -> fatal_error loc "%a" print_error msg in
  
  match Cshmgen.transl_program clight with
  | Errors.OK cshm ->
      let oc = open_out ofile in
      let pp = Format.formatter_of_out_channel oc in
      PrintCsharpminorJSON.print_program pp cshm;
      Format.pp_print_flush pp ();
      close_out oc
  | Errors.Error msg -> fatal_error loc "%a" print_error msg

let compile_c_file sourcename ifile ofile =
  let cs = parse_c_file sourcename ifile in
  export_csharpminor sourcename cs ofile

let output_filename sourcename  =
  let prefixname = Filename.remove_extension sourcename in
  output_filename_default (prefixname ^ ".csm.json")

let process_c_file sourcename =
  ensure_inputfile_exists sourcename;
  let ofile = output_filename sourcename in
  let preproname = Driveraux.tmp_file ".i" in
  preprocess sourcename preproname;
  compile_c_file sourcename preproname ofile

let usage_string =
  version_string tool_name ^
{|Usage: c2json <source files>
Recognized source files:
  .c             C source file
|}

let print_usage_and_exit () =
  printf "%s" usage_string; exit 0

let actions : ((string -> unit) * string) list ref = ref []
let push_action fn arg =
  actions := (fn, arg) :: !actions

let perform_actions () =
  let rec perform = function
    | [] -> ()
    | (fn,arg) :: rem -> fn arg; perform rem
  in perform (List.rev !actions)

let num_input_files = ref 0

let cmdline_actions =
  [ Exact "-help", Unit print_usage_and_exit;
    Exact "--help", Unit print_usage_and_exit; ]
  @ version_options tool_name
  @ prepro_actions
  @ general_options
  @ warning_options
  @ language_support_options
  @ [Prefix "-", Self (fun s -> fatal_error no_loc "Unknown option `%s'" s);
     Suffix ".c", Self (fun s -> incr num_input_files; push_action process_c_file s); ]

let _ =
try
  Gc.set { (Gc.get()) with
              Gc.minor_heap_size = 524288; (* 512k *)
              Gc.major_heap_increment = 4194304 (* 4M *)
         };
  Printexc.record_backtrace true;
  Camlcoq.use_canonical_atoms := true;
  Frontend.init ();
  parse_cmdline cmdline_actions;
  if !num_input_files = 0 then
    fatal_error no_loc "no input file";
  perform_actions ()
with
  | Sys_error msg
  | CmdError msg -> error no_loc "%s" msg; exit 2
  | Abort -> exit 2
  | e -> crash e

(* *********************************************************************)
(*                                                                     *)
(*              The Compcert verified compiler                         *)
(*                                                                     *)
(*          JSON Exporter for Csharpminor                              *)
(*                                                                     *)
(* *********************************************************************)

open Format
open! Camlcoq
open Integers
open AST
open Csharpminor

let destination : string option ref = ref None

let quote_string s =
  let b = Buffer.create (String.length s + 2) in
  Buffer.add_char b '"';
  for i = 0 to String.length s - 1 do
    match s.[i] with
    | '"' -> Buffer.add_string b "\\\""
    | '\\' -> Buffer.add_string b "\\\\"
    | '\n' -> Buffer.add_string b "\\n"
    | '\r' -> Buffer.add_string b "\\r"
    | '\t' -> Buffer.add_string b "\\t"
    | c -> Buffer.add_char b c
  done;
  Buffer.add_char b '"';
  Buffer.contents b

let print_ident p id =
  fprintf p "%s" (quote_string (extern_atom id))

let print_constant p cst =
  match cst with
  | Ointconst n -> fprintf p {|{"const_type": "int", "value": %ld}|} (camlint_of_coqint n)
  | Ofloatconst f -> fprintf p {|{"const_type": "float", "value": %.15F}|} (camlfloat_of_coqfloat f)
  | Osingleconst f -> fprintf p {|{"const_type": "single", "value": %.15F}|} (camlfloat_of_coqfloat32 f)
  | Olongconst n -> fprintf p {|{"const_type": "long", "value": %Ld}|} (camlint64_of_coqint n)

let print_unary_operation p op =
  let name = match op with
    | Cminor.Ocast8unsigned -> "Ocast8unsigned"
    | Cminor.Ocast8signed -> "Ocast8signed"
    | Cminor.Ocast16unsigned -> "Ocast16unsigned"
    | Cminor.Ocast16signed -> "Ocast16signed"
    | Cminor.Onegint -> "Onegint"
    | Cminor.Onotint -> "Onotint"
    | Cminor.Onegf -> "Onegf"
    | Cminor.Oabsf -> "Oabsf"
    | Cminor.Onegfs -> "Onegfs"
    | Cminor.Oabsfs -> "Oabsfs"
    | Cminor.Osingleoffloat -> "Osingleoffloat"
    | Cminor.Ofloatofsingle -> "Ofloatofsingle"
    | Cminor.Ointoffloat -> "Ointoffloat"
    | Cminor.Ointuoffloat -> "Ointuoffloat"
    | Cminor.Ofloatofint -> "Ofloatofint"
    | Cminor.Ofloatofintu -> "Ofloatofintu"
    | Cminor.Ointofsingle -> "Ointofsingle"
    | Cminor.Ointuofsingle -> "Ointuofsingle"
    | Cminor.Osingleofint -> "Osingleofint"
    | Cminor.Osingleofintu -> "Osingleofintu"
    | Cminor.Onegl -> "Onegl"
    | Cminor.Onotl -> "Onotl"
    | Cminor.Ointoflong -> "Ointoflong"
    | Cminor.Olongofint -> "Olongofint"
    | Cminor.Olongofintu -> "Olongofintu"
    | Cminor.Olongoffloat -> "Olongoffloat"
    | Cminor.Olonguoffloat -> "Olonguoffloat"
    | Cminor.Ofloatoflong -> "Ofloatoflong"
    | Cminor.Ofloatoflongu -> "Ofloatoflongu"
    | Cminor.Olongofsingle -> "Olongofsingle"
    | Cminor.Olonguofsingle -> "Olonguofsingle"
    | Cminor.Osingleoflong -> "Osingleoflong"
    | Cminor.Osingleoflongu -> "Osingleoflongu"
  in
  fprintf p "\"%s\"" name

let print_comparison p c =
  let name = match c with
    | Ceq -> "Ceq"
    | Cne -> "Cne"
    | Clt -> "Clt"
    | Cle -> "Cle"
    | Cgt -> "Cgt"
    | Cge -> "Cge"
  in
  fprintf p "\"%s\"" name

let print_binary_operation p op =
  match op with
  | Cminor.Oadd -> fprintf p "\"Oadd\""
  | Cminor.Osub -> fprintf p "\"Osub\""
  | Cminor.Omul -> fprintf p "\"Omul\""
  | Cminor.Odiv -> fprintf p "\"Odiv\""
  | Cminor.Odivu -> fprintf p "\"Odivu\""
  | Cminor.Omod -> fprintf p "\"Omod\""
  | Cminor.Omodu -> fprintf p "\"Omodu\""
  | Cminor.Oand -> fprintf p "\"Oand\""
  | Cminor.Oor -> fprintf p "\"Oor\""
  | Cminor.Oxor -> fprintf p "\"Oxor\""
  | Cminor.Oshl -> fprintf p "\"Oshl\""
  | Cminor.Oshr -> fprintf p "\"Oshr\""
  | Cminor.Oshru -> fprintf p "\"Oshru\""
  | Cminor.Oaddf -> fprintf p "\"Oaddf\""
  | Cminor.Osubf -> fprintf p "\"Osubf\""
  | Cminor.Omulf -> fprintf p "\"Omulf\""
  | Cminor.Odivf -> fprintf p "\"Odivf\""
  | Cminor.Oaddfs -> fprintf p "\"Oaddfs\""
  | Cminor.Osubfs -> fprintf p "\"Osubfs\""
  | Cminor.Omulfs -> fprintf p "\"Omulfs\""
  | Cminor.Odivfs -> fprintf p "\"Odivfs\""
  | Cminor.Oaddl -> fprintf p "\"Oaddl\""
  | Cminor.Osubl -> fprintf p "\"Osubl\""
  | Cminor.Omull -> fprintf p "\"Omull\""
  | Cminor.Odivl -> fprintf p "\"Odivl\""
  | Cminor.Odivlu -> fprintf p "\"Odivlu\""
  | Cminor.Omodl -> fprintf p "\"Omodl\""
  | Cminor.Omodlu -> fprintf p "\"Omodlu\""
  | Cminor.Oandl -> fprintf p "\"Oandl\""
  | Cminor.Oorl -> fprintf p "\"Oorl\""
  | Cminor.Oxorl -> fprintf p "\"Oxorl\""
  | Cminor.Oshll -> fprintf p "\"Oshll\""
  | Cminor.Oshrl -> fprintf p "\"Oshrl\""
  | Cminor.Oshrlu -> fprintf p "\"Oshrlu\""
  | Cminor.Ocmp c -> fprintf p {|{"op_type": "Ocmp", "cmp": %a}|} print_comparison c
  | Cminor.Ocmpu c -> fprintf p {|{"op_type": "Ocmpu", "cmp": %a}|} print_comparison c
  | Cminor.Ocmpf c -> fprintf p {|{"op_type": "Ocmpf", "cmp": %a}|} print_comparison c
  | Cminor.Ocmpfs c -> fprintf p {|{"op_type": "Ocmpfs", "cmp": %a}|} print_comparison c
  | Cminor.Ocmpl c -> fprintf p {|{"op_type": "Ocmpl", "cmp": %a}|} print_comparison c
  | Cminor.Ocmplu c -> fprintf p {|{"op_type": "Ocmplu", "cmp": %a}|} print_comparison c

let print_memory_chunk p chunk =
  fprintf p "\"%s\"" (PrintAST.name_of_chunk chunk)

let rec print_expr p e =
  match e with
  | Evar id ->
      fprintf p {|{"expr_type": "Evar", "id": %a}|} print_ident id
  | Eaddrof id ->
      fprintf p {|{"expr_type": "Eaddrof", "id": %a}|} print_ident id
  | Econst cst ->
      fprintf p {|{"expr_type": "Econst", "const": %a}|} print_constant cst
  | Eunop(op, a1) ->
      fprintf p {|{"expr_type": "Eunop", "op": %a, "arg": %a}|}
        print_unary_operation op
        print_expr a1
  | Ebinop(op, a1, a2) ->
      fprintf p {|{"expr_type": "Ebinop", "op": %a, "arg1": %a, "arg2": %a}|}
        print_binary_operation op
        print_expr a1
        print_expr a2
  | Eload(chunk, a1) ->
      fprintf p {|{"expr_type": "Eload", "chunk": %a, "addr": %a}|}
        print_memory_chunk chunk
        print_expr a1

let print_expr_list p el =
  fprintf p "[";
  let rec print_list = function
    | [] -> ()
    | [e] -> print_expr p e
    | e :: es -> print_expr p e; fprintf p ", "; print_list es
  in
  print_list el;
  fprintf p "]"

let print_option f p opt =
  match opt with
  | None -> fprintf p "null"
  | Some x -> f p x

let print_signature p sg =
  fprintf p {|{"args": [%a], "res": "%s"}|}
    (fun p args ->
      let rec pr first = function
        | [] -> ()
        | t :: ts ->
            if not first then fprintf p ", ";
            fprintf p "\"%s\"" (PrintAST.name_of_xtype t);
            pr false ts
      in pr true args) sg.sig_args
    (PrintAST.name_of_xtype sg.sig_res)

let print_external_function p ef =
  fprintf p "%s" (quote_string (PrintAST.name_of_external ef))

let rec print_lbl_stmt p ls =
  fprintf p "[";
  let rec print_list first = function
    | LSnil -> ()
    | LScons(opt_z, s, ls_next) ->
        if not first then fprintf p ", ";
        fprintf p {|{"case_val": %a, "stmt": %a}|}
          (fun p o -> match o with
             | None -> fprintf p "null"
             | Some z -> fprintf p "%s" (Z.to_string z)) opt_z
          print_stmt s;
        print_list false ls_next
  in
  print_list true ls;
  fprintf p "]"

and print_stmt p s =
  match s with
  | Sskip -> fprintf p {|{"stmt_type": "Sskip"}|}
  | Sset(id, e) ->
      fprintf p {|{"stmt_type": "Sset", "id": %a, "expr": %a}|}
        print_ident id print_expr e
  | Sstore(chunk, a1, a2) ->
      fprintf p {|{"stmt_type": "Sstore", "chunk": %a, "addr": %a, "expr": %a}|}
        print_memory_chunk chunk print_expr a1 print_expr a2
  | Scall(optid, sg, e1, el) ->
      fprintf p {|{"stmt_type": "Scall", "optid": %a, "sig": %a, "func": %a, "args": %a}|}
        (print_option print_ident) optid print_signature sg print_expr e1 print_expr_list el
  | Sbuiltin(optid, ef, el) ->
      fprintf p {|{"stmt_type": "Sbuiltin", "optid": %a, "ef": %a, "args": %a}|}
        (print_option print_ident) optid print_external_function ef print_expr_list el
  | Sseq(s1, s2) ->
      fprintf p {|{"stmt_type": "Sseq", "s1": %a, "s2": %a}|}
        print_stmt s1 print_stmt s2
  | Sifthenelse(e, s1, s2) ->
      fprintf p {|{"stmt_type": "Sifthenelse", "cond": %a, "s1": %a, "s2": %a}|}
        print_expr e print_stmt s1 print_stmt s2
  | Sloop s1 ->
      fprintf p {|{"stmt_type": "Sloop", "body": %a}|} print_stmt s1
  | Sblock s1 ->
      fprintf p {|{"stmt_type": "Sblock", "body": %a}|} print_stmt s1
  | Sexit n ->
      fprintf p {|{"stmt_type": "Sexit", "n": %d}|} (Nat.to_int n)
  | Sswitch(islong, e, ls) ->
      fprintf p {|{"stmt_type": "Sswitch", "islong": %b, "expr": %a, "cases": %a}|}
        islong print_expr e print_lbl_stmt ls
  | Sreturn opt_e ->
      fprintf p {|{"stmt_type": "Sreturn", "expr": %a}|}
        (print_option print_expr) opt_e
  | Slabel(lbl, s1) ->
      fprintf p {|{"stmt_type": "Slabel", "label": %a, "stmt": %a}|}
        print_ident lbl print_stmt s1
  | Sgoto lbl ->
      fprintf p {|{"stmt_type": "Sgoto", "label": %a}|} print_ident lbl

let print_function p id f =
  fprintf p {|{"id": %a, "sig": %a, "params": [%a], "vars": [%a], "temps": [%a], "body": %a}|}
    print_ident id
    print_signature f.fn_sig
    (fun p params ->
      let rec pr first = function
        | [] -> ()
        | v :: vs ->
            if not first then fprintf p ", ";
            print_ident p v;
            pr false vs
      in pr true params) f.fn_params
    (fun p vars ->
      let rec pr first = function
        | [] -> ()
        | (v, sz) :: vs ->
            if not first then fprintf p ", ";
            fprintf p {|{"id": %a, "sz": "%s"}|} print_ident v (Z.to_string sz);
            pr false vs
      in pr true vars) f.fn_vars
    (fun p temps ->
      let rec pr first = function
        | [] -> ()
        | v :: vs ->
            if not first then fprintf p ", ";
            print_ident p v;
            pr false vs
      in pr true temps) f.fn_temps
    print_stmt f.fn_body

let print_init_data p = function
  | Init_int8 i -> fprintf p {|{"type": "int8", "val": %ld}|} (camlint_of_coqint i)
  | Init_int16 i -> fprintf p {|{"type": "int16", "val": %ld}|} (camlint_of_coqint i)
  | Init_int32 i -> fprintf p {|{"type": "int32", "val": %ld}|} (camlint_of_coqint i)
  | Init_int64 i -> fprintf p {|{"type": "int64", "val": %Ld}|} (camlint64_of_coqint i)
  | Init_float32 f -> fprintf p {|{"type": "float32", "val": %.15F}|} (camlfloat_of_coqfloat f)
  | Init_float64 f -> fprintf p {|{"type": "float64", "val": %.15F}|} (camlfloat_of_coqfloat f)
  | Init_space i -> fprintf p {|{"type": "space", "val": "%s"}|} (Z.to_string i)
  | Init_addrof(id, off) -> fprintf p {|{"type": "addrof", "id": %a, "off": %ld}|} print_ident id (camlint_of_coqint off)

let rec print_init_data_list p = function
  | [] -> ()
  | [item] -> print_init_data p item
  | item::rest ->
      print_init_data p item;
      fprintf p ", ";
      print_init_data_list p rest

let print_globvar p gv =
  fprintf p {|{"readonly": %b, "volatile": %b, "init": [%a]}|}
    gv.gvar_readonly gv.gvar_volatile (fun p v -> print_init_data_list p v) gv.gvar_init

let print_globdef p (id, gd) =
  match gd with
  | Gfun(External ef) ->
      fprintf p {|{"def_type": "external_fun", "id": %a, "ef": %a, "sig": %a}|}
        print_ident id print_external_function ef print_signature (ef_sig ef)
  | Gfun(Internal f) ->
      fprintf p {|{"def_type": "internal_fun", "fun": %a}|}
        (fun p -> print_function p id) f
  | Gvar gv ->
      fprintf p {|{"def_type": "var", "id": %a, "var": %a}|}
        print_ident id print_globvar gv

let print_program p prog =
  fprintf p "{\n  \"main\": \"%s\",\n  \"defs\": [\n" (extern_atom prog.prog_main);
  let rec print_defs first = function
    | [] -> ()
    | def :: defs ->
        if not first then fprintf p ",\n";
        fprintf p "    %a" print_globdef def;
        print_defs false defs
  in
  print_defs true prog.prog_defs;
  fprintf p "\n  ]\n}\n"

let print_if prog =
  match !destination with
  | None -> ()
  | Some f ->
      let oc = open_out f in
      let pp = formatter_of_out_channel oc in
      print_program pp prog;
      pp_print_flush pp ();
      close_out oc

open Base
open Minipy

let debug = false

let parse_str data =
  let tmp_file = Caml.Filename.temp_file "minitest" ".py" in
  Exn.protect
    ~f:(fun () ->
      Stdio.Out_channel.write_all tmp_file ~data:(data ^ "\n");
      if debug
      then (
        let tokens = Parse.tokens_file tmp_file in
        Stdio.printf
          "token: %s\n%!"
          (List.map tokens ~f:Parse.token_to_string |> String.concat ~sep:"\n"));
      Parse.parse_file tmp_file |> Parse.ok_exn)
    ~finally:(fun () -> Caml.Sys.remove tmp_file)

let%expect_test "parse" =
  let ast = parse_str "x=1\nprint(42)\n" in
  Stdio.printf !"%{sexp:Ast.t}\n" ast;
  [%expect
    {|
        ((Assign (targets ((Name x))) (value (Num 1)))
         (Expr (value (Call (func (Name print)) (args ((Num 42))) (keywords ())))))
      |}]

let%expect_test "hello" =
  let ast = parse_str "print(\"Hello World!\")\n" in
  Interpreter.simple_eval ast;
  [%expect {|
        ((Val_str"Hello World!"))
      |}];
  let ast = parse_str "print(41+1)" in
  Interpreter.simple_eval ast;
  [%expect {|
        ((Val_int 42))
      |}]

let%expect_test "fn" =
  let ast = parse_str {|
def f(x, y):
  return x+y

print(f(1000, 337))
|} in
  Interpreter.simple_eval ast;
  [%expect {|
        ((Val_int 1337))
      |}]

let%expect_test "builtins" =
  let ast = parse_str {|
print(fact(10))
|} in
  let print_fn args _ =
    match args with
    | [ Interpreter.Val_int i ] ->
      Stdio.printf "%d\n" i;
      Interpreter.Val_none
    | _ ->
      Stdio.printf "unsupported\n";
      Val_none
  in
  let rec fact = function
    | 0 -> 1
    | n -> n * fact (n - 1)
  in
  let fact_fn args _ =
    match args with
    | [ Interpreter.Val_int i ] -> Interpreter.Val_int (fact i)
    | _ -> Val_none
  in
  let builtins =
    [ "print", print_fn; "fact", fact_fn ] |> Map.of_alist_exn (module String)
  in
  Interpreter.simple_eval ~builtins ast;
  [%expect {|
        3628800
      |}]

let%expect_test "fn" =
  let ast = parse_str {|
def f(x, y):
  return [x, y, x+y]

print(f(1000, 337))
|} in
  Interpreter.simple_eval ast;
  [%expect {|
        ((Val_list((Val_int 1000)(Val_int 337)(Val_int 1337))))
      |}]

let%expect_test "semicolon" =
  let ast =
    parse_str
      {|
x=1;
print(x)
x=1 ; y=2
print(x,y)
x=1 ; y=2;y=3;
print(x,y)
def f(x, y):
  x=x+3;y=y
  x=x+3;y=y;
  x=x+3;
  return [x, y, x+y]

print(f(991, 337))
|}
  in
  Interpreter.simple_eval ast;
  [%expect
    {|
        ((Val_int 1))
        ((Val_int 1)(Val_int 2))
        ((Val_int 1)(Val_int 3))
        ((Val_list((Val_int 1000)(Val_int 337)(Val_int 1337))))
      |}]

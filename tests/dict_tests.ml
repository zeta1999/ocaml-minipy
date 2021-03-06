open Base
open Minipy

let%expect_test "dict" =
  let ast =
    Basic_tests.parse_str
      {|
# Dictionary tests
d = { "key": (1, 2), "c": 299792458, 42: 1337 }
d["foo"] = (1, "bar")
print(d["c"], d["foo"])

def set(dd, key, value): dd[key] = value

set(d, (1, 2), "foobar")
print(d[(1, 2)])
set(d, (1, 2), "barfoo")
print(d[1, 2])
|}
  in
  Interpreter.simple_eval ast;
  [%expect
    {|
        ((Val_int 299792458)(Val_tuple((Val_int 1)(Val_str bar))))
        ((Val_str foobar))
        ((Val_str barfoo))
      |}]

let%expect_test "dict-del" =
  let ast =
    Basic_tests.parse_str
      {|
# Dictionary deletion tests
d = { "key": (1, 2), "c": 299792458, 42: 1337 }
del d["ke" + "y"]
print(len(d))
del d["c"]
print(d)
del d[42]
print(d)
|}
  in
  Interpreter.simple_eval ast;
  [%expect
    {|
        ((Val_int 2))
        ((Val_dict(((Val_int 42)(Val_int 1337)))))
        ((Val_dict()))
      |}]

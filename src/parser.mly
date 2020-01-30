%{
%}

%token <string> INTEGER
%token <string> FLOAT
%token <string> IDENTIFIER STRING
%token <bool> BOOL
%token COLON
%token OPADD OPSUB OPMUL OPDIV OPEDIV OPMOD
%token OPNEQ OPEQ
%token DOT COMMA EQUAL
%token DEF RETURN DELETE IF ELIF ELSE WHILE FOR BREAK
%token LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK
%token INDENT DEDENT
%token NEWLINES
%token EOF

%left IF ELSE
%left OPNEQ
%left OPEQ
%left OPADD
%left OPSUB
%left OPMUL
%left OPDIV
%nonassoc LPAREN

%type <Mini_ast.t> mod_
%type <Mini_ast.stmt> stmt stmt_
%type <Mini_ast.expr> expr
%start mod_
%%

mod_:
  | NEWLINES* l=stmt* EOF { l }
;

stmt:
  | s=stmt_ NEWLINES { s }
  | IF test=expr COLON NEWLINES
      INDENT body=nonempty_list(stmt) DEDENT
    { If { test; body; orelse = [] } }
  | WHILE test=expr COLON NEWLINES
      INDENT body=nonempty_list(stmt) DEDENT
    { While { test; body; orelse = [] } }
  | DEF name=IDENTIFIER LPAREN args=separated_list(COMMA, IDENTIFIER) RPAREN COLON NEWLINES
      INDENT body=nonempty_list(stmt) DEDENT
    { FunctionDef { name; args; body }}
;

stmt_:
  | t=IDENTIFIER EQUAL v=expr { Assign { targets = [ Name t ]; value = v } }
  | RETURN { Return { value = None } }
  | RETURN v=expr { Return { value = Some v } }
  | value=expr { Expr { value } }
;

expr:
  | IDENTIFIER { Name $1 }
  | STRING { Str $1 }
  | INTEGER { Num (int_of_string $1) }
  | FLOAT { Float (float_of_string $1) }
  | BOOL { Bool $1 }
  | left=expr OPEQ right=expr { Compare { left; ops = Eq; comparators = right } }
  | left=expr OPNEQ right=expr { Compare { left; ops = NotEq; comparators = right } }
  | left=expr OPMUL right=expr { BinOp { left; op = Mult; right } }
  | left=expr OPDIV right=expr { BinOp { left; op = Div; right } }
  | left=expr OPADD right=expr { BinOp { left; op = Add; right } }
  | left=expr OPSUB right=expr { BinOp { left; op = Sub; right } }
  | body=expr IF test=expr ELSE orelse=expr { IfExp { body; test; orelse } }
  | func=expr LPAREN args=separated_list(COMMA, expr) RPAREN { Call { func; args } }
  | LPAREN e=expr RPAREN { e }
;


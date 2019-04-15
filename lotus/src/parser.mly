%{
open Ast
%}

(* HBIR Keywords *)
%token TARGET
%token MEMORY
%token SIZE
%token WIDTH
%token <string> SIZEDECL
%token <string> WDECL
%token TILE
%token UNKNOWN

%token CONFIG
%token GROUP
%token TEMPORAL
%token BLOCK
%token X
%token Y
%token X_MAX
%token Y_MAX

%token DATA
%token DIM

%token CODE

(* float types *)

(* SPMD Keywords *)
%token WHILE
%token IF
%token FOR
%token ELSE
%token RETURN
%token INT
%token BOOL
%token FLOAT
%token USE
%token LENGTH
%token TRUE
%token FALSE
%token PRINTF

(* Symbols *)
%token LEFT_PAREN
%token RIGHT_PAREN
%token LEFT_BRACKET
%token RIGHT_BRACKET
%token LEFT_BRACE
%token RIGHT_BRACE
%token EOF

%token <int> INT_LITERAL
%token <string> ID
%token <string> STR

%token PLUS
%token MINUS
%token TIMES
%token DIV
%token MOD

%token EQ
%token LT
%token LTE
%token GTE
%token GT
%token EQEQ
%token NEQ
%token AMP
%token BAR
%token BANG
%token AND
%token OR

%token SEMICOLON

%token DOT
%token UNDERSCORE
%token COMMA
%token COLON

%left AND OR
%left EQEQ NEQ LT LTE GT GTE
%left PLUS MINUS
%left TIMES DIV

%start <Ast.program> main

%%

(* Rules *)

(* TODO: Should probably rename things to decl for high level *)
main:
    | targ = target; conf = config; dat = data; cod = code; EOF
        { (targ, conf, dat, cod) }

target:
    | TARGET; LEFT_BRACE; MEMORY; mem = memory; TILE; ti = tile; RIGHT_BRACE
        { (mem, ti) }

memory:
    | id = ID; LEFT_BRACKET; num = expr; RIGHT_BRACKET;
      LEFT_BRACE; SIZE; size = SIZEDECL; SEMICOLON; WIDTH; width = WDECL; SEMICOLON; RIGHT_BRACE
        { (id, num, (size, width)) }
    | id = ID; LEFT_BRACKET; UNKNOWN; RIGHT_BRACKET;
      LEFT_BRACE; SIZE; size = SIZEDECL; SEMICOLON; WIDTH; width = WDECL; SEMICOLON; RIGHT_BRACE
        { (id, String "?", (size, width)) }
    | id = ID; LEFT_BRACKET; num = expr; RIGHT_BRACKET;
      LEFT_BRACE; SIZE; UNKNOWN; SEMICOLON; WIDTH; width = WDECL; SEMICOLON; RIGHT_BRACE
        { (id, num, ("?", width)) }
    | id = ID; LEFT_BRACKET; num = expr; RIGHT_BRACKET;
      LEFT_BRACE; SIZE; size = SIZEDECL; SEMICOLON; WIDTH; UNKNOWN; SEMICOLON; RIGHT_BRACE
        { (id, num, (size, "?")) }
    | id = ID; LEFT_BRACKET; UNKNOWN; RIGHT_BRACKET;
      LEFT_BRACE; SIZE; UNKNOWN; SEMICOLON; WIDTH; width = WDECL; SEMICOLON; RIGHT_BRACE
        { (id, String "?", ("?", width)) }
    | id = ID; LEFT_BRACKET; UNKNOWN; RIGHT_BRACKET;
      LEFT_BRACE; SIZE; size = SIZEDECL; SEMICOLON; WIDTH; UNKNOWN; SEMICOLON; RIGHT_BRACE
        { (id, String "?", (size, "?")) }
    | id = ID; LEFT_BRACKET; num = expr; RIGHT_BRACKET;
      LEFT_BRACE; SIZE; UNKNOWN; SEMICOLON; WIDTH; UNKNOWN; SEMICOLON; RIGHT_BRACE
        { (id, num, ("?", "?")) }
    | id = ID; LEFT_BRACKET; UNKNOWN; RIGHT_BRACKET;
      LEFT_BRACE; SIZE; UNKNOWN; SEMICOLON; WIDTH; UNKNOWN; SEMICOLON; RIGHT_BRACE
        { (id, String "?", ("?", "?")) }

tile:
    | id = ID; LEFT_BRACKET; num1 = expr; RIGHT_BRACKET; LEFT_BRACKET; num2 = expr; RIGHT_BRACKET; LEFT_BRACE; MEMORY; m = memory; RIGHT_BRACE
        { (id, (num1, num2), Some m)}
    | id = ID; LEFT_BRACKET; num1 = expr; RIGHT_BRACKET; LEFT_BRACKET; num2 = expr; RIGHT_BRACKET; SEMICOLON
        { (id, (num1, num2), None)}

tileDecl:
    (* TODO: Remove this where I temporarily return -1 *)
    | TILE; TARGET; DOT; id = ID; LEFT_BRACKET; X; RIGHT_BRACKET; LEFT_BRACKET; Y; RIGHT_BRACKET; SEMICOLON
        { (id, (Int 0, Int 0)) }
    | CONFIG; DOT; id = ID; LEFT_BRACKET; num1 = expr; RIGHT_BRACKET; LEFT_BRACKET; num2 = expr; RIGHT_BRACKET
        { (id, (num1, num2))}

config:
    | CONFIG; LEFT_BRACE; gr = groupList; RIGHT_BRACE
        { (gr) }

groupBlk:
    | t = tileDecl
        { TileWithNothing t }
    | t = tileDecl;
      TEMPORAL; GROUP; BLOCK; LEFT_BRACKET; num3 = INT_LITERAL; RIGHT_BRACKET; SEMICOLON
        { TileWithTemporal (t, num3) }

groupList:
    | g = group
        { g::[] }
    | g1 = groupList; g2 = group
        { g1@(g2::[]) }

group:
    | GROUP; id = ID; LEFT_BRACKET; num1 = expr; RIGHT_BRACKET; LEFT_BRACKET; num2 = expr; RIGHT_BRACKET; LEFT_BRACE; g1 = groupBlk; RIGHT_BRACE
        { GroupStmt (id, (num1, num2), g1)}
    | GROUP; id = ID; LEFT_BRACKET; num1 = expr; RIGHT_BRACKET; LEFT_BRACKET; num2 = expr; RIGHT_BRACKET; LEFT_BRACE; g2 = group; RIGHT_BRACE
        { NestedGroup (id, (num1, num2), g2)}

data:
    | DATA; LEFT_BRACE; DIM; EQ; num = expr; SEMICOLON; dl = dataMaps; RIGHT_BRACE
        { (num, dl) }

dataMap:
    | id = ID; COLON; t = typ; LEFT_BRACKET; num1 = expr; RIGHT_BRACKET; EQ;
               BLOCK; LEFT_BRACKET; s1 = sgmts; DOT; id1 = ID; DOT; num2 = expr; RIGHT_BRACKET;
               LEFT_BRACE; s2 = sgmts; DOT; id2 = ID; LEFT_BRACKET; X; RIGHT_BRACKET; SEMICOLON; RIGHT_BRACE; SEMICOLON
       {id, t, (num1, None), (id1, None), (num2, None), (s1, Some s2, None), id2}
    | id = ID; COLON; t = typ; LEFT_BRACKET; num1 = expr; RIGHT_BRACKET; LEFT_BRACKET; num2 = expr; RIGHT_BRACKET; EQ;
               BLOCK; LEFT_BRACKET; s1 = sgmts; DOT; id1 = ID; DOT; num3 = expr; RIGHT_BRACKET;
               LEFT_BRACE; s2 = sgmts; DOT; id2 = ID; LEFT_BRACKET; X; RIGHT_BRACKET; SEMICOLON; RIGHT_BRACE; SEMICOLON
       {id, t, (num1, Some num2), (id1, None), (num3, None), (s1, Some s2, None), id2}
    | id = ID; COLON; t = typ; LEFT_BRACKET; num1 = expr; RIGHT_BRACKET; LEFT_BRACKET; num2 = expr; RIGHT_BRACKET; EQ;
               BLOCK; LEFT_BRACKET; s1 = sgmts; DOT; id1 = ID; DOT; num3 = expr; RIGHT_BRACKET;
                      LEFT_BRACKET; s2 = sgmts; DOT; id2 = ID; DOT; num4 = expr; RIGHT_BRACKET;
               LEFT_BRACE; s3 = sgmts; DOT; id3 = ID; LEFT_BRACKET; X; RIGHT_BRACKET; SEMICOLON; RIGHT_BRACE; SEMICOLON
       {id, t, (num1, Some num2), (id1, Some id2), (num3, Some num4), (s1, Some s3, Some s2), id3}

dataMaps:
    | d = dataMap
        { d::[] }
    | d1 = dataMaps; d2 = dataMap
        { d1@(d2::[]) }

(* TODO: Once you enter code section, the parser should enter a state of just checking for SPMD (think in how yacc worked in Java) *)
code:
    | CODE; LEFT_BRACE; RIGHT_BRACE
        { ([]) }
    | CODE; LEFT_BRACE; c = codeList; RIGHT_BRACE
        { (c) }

codeList:
    | c = codeBlock
        { c::[] }
    | c1 = codeList; c2 = codeBlock
        { c1@(c2::[]) }

codeBlock:
    | t = tileDecl; LEFT_BRACE; s = stmtList; RIGHT_BRACE
        { (t, s)}

exprList:
    | e = expr
        { e::[] }
    | e1 = exprList; e2 = expr
        { e1@(e2::[]) }

stmtList:
    | s = stmt
        { s::[] }
    | s1 = stmtList; s2 = stmt
        {s1@(s2::[]) }

elseIfList:
    | e = elseIf
        { e::[] }
    | e1 = elseIfList; e2 = elseIf
        { e1@(e2::[]) }

elseIf:
    | ELSE; IF; LEFT_PAREN; e = expr; RIGHT_PAREN; LEFT_BRACE; sl = stmtList; RIGHT_BRACE
        { (e, sl) }

stmt:
    | INT; id = ID; SEMICOLON
        { Decl ("int", id) }
    | BOOL; id = ID; SEMICOLON
        { Decl ("bool", id) }
    | FLOAT; id = ID; SEMICOLON
        { Decl ("float", id) }
    | id = ID; EQ; e = expr; SEMICOLON
        { Assign (id, e) }
    | INT; id = ID; EQ; e = expr; SEMICOLON
        { DeclAssign ("int", id, e) }
    | BOOL; id = ID; EQ; e = expr; SEMICOLON
        { DeclAssign ("bool", id, e) }
    | FLOAT; id = ID; EQ; e = expr; SEMICOLON
        { DeclAssign ("float", id, e) }
    | IF; LEFT_PAREN; e = expr; RIGHT_PAREN; LEFT_BRACE; sl = stmtList; RIGHT_BRACE;
        {If((e, sl), [], None) }
    | IF; LEFT_PAREN; e = expr; RIGHT_PAREN; LEFT_BRACE; sl1 = stmtList; RIGHT_BRACE;
      ELSE; LEFT_BRACE; sl2 = stmtList; RIGHT_BRACE;
        {If((e, sl1), [], Some sl2) }
    | IF; LEFT_PAREN; e = expr; RIGHT_PAREN; LEFT_BRACE; sl1 = stmtList; RIGHT_BRACE;
      el = elseIfList
        {If((e, sl1), el, None) }
    | IF; LEFT_PAREN; e = expr; RIGHT_PAREN; LEFT_BRACE; sl1 = stmtList; RIGHT_BRACE;
      el = elseIfList
      ELSE; LEFT_BRACE; sl2 = stmtList; RIGHT_BRACE;
        {If((e, sl1), el, Some sl2) }
    | WHILE; LEFT_PAREN; e = expr; RIGHT_PAREN; LEFT_BRACE; sl = stmtList; RIGHT_BRACE;
        {While(e, sl) }
    | FOR; LEFT_PAREN; s1 = stmt; e1 = expr; SEMICOLON; i = ID; EQ; e2=expr RIGHT_PAREN; LEFT_BRACE; sl = stmtList; RIGHT_BRACE;
        { For((s1, e1, (i,e2)), sl) }
    | PRINTF; LEFT_PAREN; s = STR; RIGHT_PAREN; SEMICOLON
        { Print s }

expr:
    | LEFT_PAREN; e = expr; RIGHT_PAREN
        { e }
    | X_MAX
        { Literal (XMax) }
    | Y_MAX
        { Literal (YMax) }
    | i = INT_LITERAL
        { Int i }
    | s = STR
        { String s }
    | e1 = expr; PLUS; e2 = expr
        { Plus (e1, e2) }
    | e1 = expr; MINUS; e2 = expr
        { Minus (e1, e2) }
    | e1 = expr; TIMES; e2 = expr
        { Times (e1, e2) }
    | e1 = expr; DIV; e2 = expr
        { Div (e1, e2) }
    | e1 = expr; EQEQ; e2 = expr
        { Eq (e1, e2) }
    | e1 = expr; NEQ; e2 = expr
        { Neq (e1, e2) }
    | e1 = expr; LT; e2 = expr
        { Lt (e1, e2) }
    | e1 = expr; LTE; e2 = expr
        { Lteq (e1, e2) }
    | e1 = expr; GT; e2 = expr
        { Gt (e1, e2) }
    | e1 = expr; GTE; e2 = expr
        { Gteq (e1, e2) }
    | e1 = expr; AND; e2 = expr
        { And (e1, e2) }
    | e1 = expr; OR; e2 = expr
        { Or (e1, e2) }
    | TRUE
        { Bool (true)}
    | FALSE
        { Bool (false)}
    | i = ID
        { Id i }

typ:
    | FLOAT
        { FloatTyp }
    | BOOL
        { BoolTyp }
    | INT
        { IntTyp }

sgmts:
    | TARGET
        { Target }
    | CONFIG
        { Config }
    | DATA
        { Data }
    | CODE
        { Code }
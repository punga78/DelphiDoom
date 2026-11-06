{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the parser (and generator of the code)  }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Parser;

interface

uses
  System.SysUtils, DelphiDoom.Acs.Types, DelphiDoom.Acs.Diagnostics, DelphiDoom.Acs.SymbolTable,
  DelphiDoom.Acs.StringTable, DelphiDoom.Acs.ObjectWriter, DelphiDoom.Acs.Tokenizer;

const
  MAX_STATEMENT_DEPTH = 128;
  MAX_BREAK = 128;
  MAX_CONTINUE = 128;
  MAX_CASE = 128;
  EXPR_STACK_DEPTH = 64;

type
  statement_t = (
    STMT_SCRIPT,
    STMT_IF,
    STMT_ELSE,
    STMT_DO,
    STMT_WHILEUNTIL,
    STMT_SWITCH,
    STMT_FOR
  );

type
  breakInfo_t = record
    level: integer;
    addressPtr: integer;
  end;

type
  continueInfo_t = record
    level: integer;
    addressPtr: integer;
  end;

type
  caseInfo_t = record
    level: integer;
    value: integer;
    isDefault: boolean;
    address: integer;
  end;
  PcaseInfo_t = ^caseInfo_t;

type
  /// <summary>
  ///   Reads the tokens and writes the object code as it goes (one pass, no tree): the
  ///   declarations outside the scripts, then the statements and the expressions of every script.
  ///   It is the port of the parser of ACC 1.10 (the identifiers inside the methods are the
  ///   original ones). The statement for is not implemented by the original compiler
  /// </summary>
  TAcsParser = class
  private
    FDiagnostics: TAcsDiagnostics;
    FSymbols: TAcsSymbolTable;
    FStrings: TAcsStringTable;
    FWriter: TAcsObjectWriter;
    FTokenizer: TAcsTokenizer;
  FScriptVarCount: integer;
  FStatementHistory: array[0..MAX_STATEMENT_DEPTH - 1] of statement_t;
  FStatementIndex: integer;
  FBreakInfo: array[0..MAX_BREAK - 1] of breakInfo_t;
  FBreakIndex: integer;
  FContinueInfo: array[0..MAX_CONTINUE - 1] of continueInfo_t;
  FContinueIndex: integer;
  FCaseInfo: array[0..MAX_CASE - 1] of caseInfo_t;
  FCaseIndex: integer;
  FStatementLevel: integer;
  FExprStack: array[0..EXPR_STACK_DEPTH - 1] of integer;
  FExprStackIndex: integer;
  FConstantExpression: boolean;
  FScriptCount: integer;
  FOpenScriptCount: integer;
  FMapVarCount: integer;
  FWorldVarCount: integer;
    procedure OuterScript;
    procedure OuterMapVar;
    procedure OuterWorldVar;
    procedure OuterSpecialDef;
    procedure OuterDefine;
    procedure OuterInclude;
    function ProcessStatement(const owner: statement_t): boolean;
    procedure LeadingCompoundStatement(const owner: statement_t);
    procedure LeadingVarDeclare;
    procedure LeadingLineSpecial;
    procedure LeadingIdentifier;
    procedure LeadingInternFunc(const sym: TAcsSymbol);
    procedure ProcessInternFunc(const sym: TAcsSymbol);
    procedure LeadingPrint;
    procedure LeadingIf;
    procedure LeadingFor;
    procedure LeadingWhileUntil;
    procedure LeadingDo;
    procedure LeadingSwitch;
    procedure LeadingCase;
    procedure LeadingDefault;
    procedure PushCase(const value: integer; const isDefault: boolean);
    function GetCaseInfo: PcaseInfo_t;
    function DefaultInCurrent: boolean;
    procedure LeadingBreak;
    procedure PushBreak;
    procedure WriteBreaks;
    function BreakAncestor: boolean;
    procedure LeadingContinue;
    procedure PushContinue;
    procedure WriteContinues(const address: integer);
    function ContinueAncestor: boolean;
    procedure LeadingVarAssign(sym: TAcsSymbol);
    function GetAssignPCD(token: integer; symbol: TAcsSymbolKind): Integer;
    procedure LeadingSuspend;
    procedure LeadingTerminate;
    procedure LeadingRestart;
    function EvalConstExpression: Integer;
    procedure EvalExpression;
    procedure ExprLevA;
    procedure ExprLevB;
    procedure ExprLevC;
    procedure ExprLevD;
    procedure ExprLevE;
    procedure ExprLevF;
    procedure ExprLevG;
    procedure ExprLevH;
    procedure ExprLevI;
    procedure ExprLevJ;
    procedure ExprFactor;
    procedure ConstExprFactor;
    procedure SendExprCommand(const pcd: integer);
    procedure PushExStk(const value: integer);
    function PopExStk: integer;
    function TokenToPCD(token: integer): integer;
    function GetPushVarPCD(const symType: TAcsSymbolKind): Integer;
    function GetIncDecPCD(token: integer; symbol: TAcsSymbolKind): Integer;
    function DemandSymbol(const name: string): TAcsSymbol;
    procedure Outside;
  public
    constructor Create(const ADiagnostics: TAcsDiagnostics; const ASymbols: TAcsSymbolTable;
      const AStrings: TAcsStringTable; const AWriter: TAcsObjectWriter;
      const ATokenizer: TAcsTokenizer);
    /// <summary>Compiles all the text of the tokenizer</summary>
    procedure Parse;
    /// <summary>Scripts compiled so far</summary>
    property ScriptCount: Integer read FScriptCount;
    /// <summary>Of those, the ones that start with the map (open)</summary>
    property OpenScriptCount: Integer read FOpenScriptCount;
    property MapVarCount: Integer read FMapVarCount;
    property WorldVarCount: Integer read FWorldVarCount;
  end;

implementation

uses
  DelphiDoom.Acs.Tokens, DelphiDoom.Acs.PCodes, DelphiDoom.Acs.ErrorCodes;

const
  AdjustStmtLevel: array[statement_t] of integer = (
    0,  // STMT_SCRIPT
    0,  // STMT_IF
    0,  // STMT_ELSE
    1,  // STMT_DO
    1,  // STMT_WHILEUNTIL
    1,  // STMT_SWITCH
    1   // STMT_FOR
  );

  IsBreakRoot: array[statement_t] of boolean = (
    false,  // STMT_SCRIPT
    false,  // STMT_IF
    false,  // STMT_ELSE
    true,   // STMT_DO
    true,   // STMT_WHILEUNTIL
    true,   // STMT_SWITCH
    true    // STMT_FOR
  );

  IsContinueRoot: array[statement_t] of boolean = (
    false,  // STMT_SCRIPT
    false,  // STMT_IF
    false,  // STMT_ELSE
    true,   // STMT_DO
    true,   // STMT_WHILEUNTIL
    false,  // STMT_SWITCH
    true    // STMT_FOR
  );

  LevFOps: array[0..2] of integer = (
    TK_EQ,
    TK_NE,
    TK_NONE
  );

  LevGOps: array[0..4] of integer = (
    TK_LT,
    TK_LE,
    TK_GT,
    TK_GE,
    TK_NONE
  );

  LevHOps: array[0..2] of integer = (
    TK_LSHIFT,
    TK_RSHIFT,
    TK_NONE
  );

  LevIOps: array[0..2] of integer = (
    TK_PLUS,
    TK_MINUS,
    TK_NONE
  );

  LevJOps: array[0..3] of integer = (
    TK_ASTERISK,
    TK_SLASH,
    TK_PERCENT,
    TK_NONE
  );

  AssignOps: array[0..6] of integer = (
    TK_ASSIGN,
    TK_ADDASSIGN,
    TK_SUBASSIGN,
    TK_MULASSIGN,
    TK_DIVASSIGN,
    TK_MODASSIGN,
    TK_NONE
  );


function IntVal(AValue: Boolean): Integer;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

{ TAcsParser }

constructor TAcsParser.Create(const ADiagnostics: TAcsDiagnostics; const ASymbols: TAcsSymbolTable;
  const AStrings: TAcsStringTable; const AWriter: TAcsObjectWriter; const ATokenizer: TAcsTokenizer);
begin
  inherited Create;
  FDiagnostics := ADiagnostics;
  FSymbols := ASymbols;
  FStrings := AStrings;
  FWriter := AWriter;
  FTokenizer := ATokenizer;
end;

//==============================================================================
//
// OuterScript
//
//==============================================================================
procedure TAcsParser.OuterScript;
var
  scriptNumber: integer;
  sym: TAcsSymbol;
begin
  FBreakIndex := 0;
  FCaseIndex := 0;
  FStatementLevel := 0;
  FScriptVarCount := 0;
  FSymbols.FreeLocals;
  FTokenizer.NextToken;
  scriptNumber := EvalConstExpression;
  if FTokenizer.Token = TK_LPAREN then
  begin
    if FTokenizer.NextToken = TK_VOID then
      FTokenizer.NextTokenMustBe(TK_RPAREN, ERR_MISSING_RPAREN)
    else
    begin
      FTokenizer.Undo;
      repeat
        FTokenizer.NextTokenMustBe(TK_INT, ERR_BAD_VAR_TYPE);
        FTokenizer.NextTokenMustBe(TK_IDENTIFIER, ERR_INVALID_IDENTIFIER);
        if FSymbols.FindLocal(FTokenizer.Text) <> nil then
        begin  // Redefined
          FDiagnostics.Fail(ERR_REDEFINED_IDENTIFIER, true,
            'Identifier: %s', [FTokenizer.Text]);
        end;
        sym := FSymbols.InsertLocal(FTokenizer.Text, SY_SCRIPTVAR);
        sym.info.svar.index := FScriptVarCount;
        Inc(FScriptVarCount);
        FTokenizer.NextToken;
      until FTokenizer.Token <> TK_COMMA;
      FTokenizer.TokenMustBe(TK_RPAREN, ERR_MISSING_RPAREN);
      if FScriptVarCount > 3 then
        FDiagnostics.Fail(ERR_TOO_MANY_SCRIPT_ARGS, True, '', []);
    end;
  end
  else if FTokenizer.Token = TK_OPEN then
  begin
    scriptNumber := scriptNumber + OPEN_SCRIPTS_BASE;
    Inc(FOpenScriptCount);
  end
  else
    FDiagnostics.Fail(ERR_BAD_SCRIPT_DECL, true, '', []);
  FWriter.AddScript(scriptNumber, FScriptVarCount);
  FTokenizer.NextToken;
  if not ProcessStatement(STMT_SCRIPT) then
    FDiagnostics.Fail(ERR_INVALID_STATEMENT, True, '', []);
  FWriter.AppendCmd(PCD_TERMINATE);
  inc(FScriptCount);
end;

//==============================================================================
//
// OuterMapVar
//
//==============================================================================
procedure TAcsParser.OuterMapVar;
var
  sym: TAcsSymbol;
begin
  repeat
    if FMapVarCount = MAX_MAP_VARIABLES then
      FDiagnostics.Fail(ERR_TOO_MANY_MAP_VARS, True, '', []);
    FTokenizer.NextTokenMustBe(TK_IDENTIFIER, ERR_INVALID_IDENTIFIER);
    if FSymbols.FindGlobal(FTokenizer.Text) <> nil then
    begin  // Redefined
      FDiagnostics.Fail(ERR_REDEFINED_IDENTIFIER, true,
        'Identifier: %s', [FTokenizer.Text]);
    end;
    sym := FSymbols.InsertGlobal(FTokenizer.Text, SY_MAPVAR);
    sym.info.svar.index := FMapVarCount;
    Inc(FMapVarCount);
    FTokenizer.NextToken;
  until FTokenizer.Token <> TK_COMMA;
  FTokenizer.TokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// OuterWorldVar
//
//==============================================================================
procedure TAcsParser.OuterWorldVar;
var
  index: integer;
  sym: TAcsSymbol;
begin
  if FTokenizer.NextToken <> TK_INT then
    FTokenizer.TokenMustBe(TK_STR, ERR_BAD_VAR_TYPE);
  repeat
    FTokenizer.NextTokenMustBe(TK_NUMBER, ERR_MISSING_WVAR_INDEX);
    if FTokenizer.Num >= MAX_WORLD_VARIABLES then
    begin
      FDiagnostics.Fail(ERR_BAD_WVAR_INDEX, True, '', []);
    end;
    index := FTokenizer.Num;
    FTokenizer.NextTokenMustBe(TK_COLON, ERR_MISSING_WVAR_COLON);
    FTokenizer.NextTokenMustBe(TK_IDENTIFIER, ERR_INVALID_IDENTIFIER);
    if FSymbols.FindGlobal(FTokenizer.Text) <> nil then
    begin  // Redefined
      FDiagnostics.Fail(ERR_REDEFINED_IDENTIFIER, true,
        'Identifier: %s', [FTokenizer.Text]);
    end;
    sym := FSymbols.InsertGlobal(FTokenizer.Text, SY_WORLDVAR);
    sym.info.svar.index := index;
    FTokenizer.NextToken;
    inc(FWorldVarCount);
  until FTokenizer.Token <> TK_COMMA;
  FTokenizer.TokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// OuterSpecialDef
//
//==============================================================================
procedure TAcsParser.OuterSpecialDef;
var
  special: integer;
  sym: TAcsSymbol;
begin
  repeat
    FTokenizer.NextTokenMustBe(TK_NUMBER, ERR_MISSING_SPEC_VAL);
    special := FTokenizer.Num;
    FTokenizer.NextTokenMustBe(TK_COLON, ERR_MISSING_SPEC_COLON);
    FTokenizer.NextTokenMustBe(TK_IDENTIFIER, ERR_INVALID_IDENTIFIER);
    if FSymbols.FindGlobal(FTokenizer.Text) <> nil then
    begin  // Redefined
      FDiagnostics.Fail(ERR_REDEFINED_IDENTIFIER, true,
        'Identifier: %s', [FTokenizer.Text]);
    end;
    sym := FSymbols.InsertGlobal(FTokenizer.Text, SY_SPECIAL);
    FTokenizer.NextTokenMustBe(TK_LPAREN, ERR_MISSING_LPAREN);
    FTokenizer.NextTokenMustBe(TK_NUMBER, ERR_MISSING_SPEC_ARGC);
    sym.info.special.value := special;
    sym.info.special.argCount := FTokenizer.Num;
    FTokenizer.NextTokenMustBe(TK_RPAREN, ERR_MISSING_RPAREN);
    FTokenizer.NextToken;
  until FTokenizer.Token <> TK_COMMA;
  FTokenizer.TokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// OuterDefine
//
//==============================================================================
procedure TAcsParser.OuterDefine;
var
  value: integer;
  sym: TAcsSymbol;
begin
  FTokenizer.NextTokenMustBe(TK_IDENTIFIER, ERR_INVALID_IDENTIFIER);
  if FSymbols.FindGlobal(FTokenizer.Text) <> nil then
  begin  // Redefined
    FDiagnostics.Fail(ERR_REDEFINED_IDENTIFIER, true,
      'Identifier: %s', [FTokenizer.Text]);
  end;
  sym := FSymbols.InsertGlobal(FTokenizer.Text, SY_CONSTANT);
  FTokenizer.NextToken;
  value := EvalConstExpression;
  sym.info.constant.value := value;
end;

//==============================================================================
//
// OuterInclude
//
//==============================================================================
procedure TAcsParser.OuterInclude;
begin
  FTokenizer.NextTokenMustBe(TK_STRING, ERR_STRING_LIT_NOT_FOUND);
  FTokenizer.DoInclude(FTokenizer.Text);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// ProcessStatement
//
//==============================================================================
function TAcsParser.ProcessStatement(const owner: statement_t): boolean;
begin
  if FStatementIndex = MAX_STATEMENT_DEPTH then
    FDiagnostics.Fail(ERR_STATEMENT_OVERFLOW, True, '', []);

  FStatementHistory[FStatementIndex] := owner;
  Inc(FStatementIndex);
  case FTokenizer.Token of
    TK_INT,
    TK_STR:
      LeadingVarDeclare;
    TK_LINESPECIAL:
      LeadingLineSpecial;
    TK_RESTART:
      LeadingRestart;
    TK_SUSPEND:
      LeadingSuspend;
    TK_TERMINATE:
      LeadingTerminate;
    TK_IDENTIFIER:
      LeadingIdentifier;
    TK_PRINT,
    TK_PRINTBOLD:
      LeadingPrint;
    TK_IF:
      LeadingIf;
    TK_FOR:
      LeadingFor;
    TK_WHILE,
    TK_UNTIL:
      LeadingWhileUntil;
    TK_DO:
      LeadingDo;
    TK_SWITCH:
      LeadingSwitch;
    TK_CASE:
      begin
        if owner <> STMT_SWITCH then
          FDiagnostics.Fail(ERR_CASE_NOT_IN_SWITCH, True, '', []);
        LeadingCase;
      end;
    TK_DEFAULT:
      begin
        if owner <> STMT_SWITCH then
          FDiagnostics.Fail(ERR_DEFAULT_NOT_IN_SWITCH, True, '', []);
        if DefaultInCurrent then
          FDiagnostics.Fail(ERR_MULTIPLE_DEFAULT, True, '', []);
        LeadingDefault;
      end;
    TK_BREAK:
      begin
        if not BreakAncestor then
          FDiagnostics.Fail(ERR_MISPLACED_BREAK, True, '', []);
        LeadingBreak;
      end;
    TK_CONTINUE:
      begin
        if not ContinueAncestor then
          FDiagnostics.Fail(ERR_MISPLACED_CONTINUE, True, '', []);
        LeadingContinue;
      end;
    TK_LBRACE:
      LeadingCompoundStatement(owner);
    TK_SEMICOLON:
      FTokenizer.NextToken;
  else
    dec(FStatementIndex);
    result := False;
    exit;
  end;
  dec(FStatementIndex);
  result := True;
end;

//==============================================================================
//
// LeadingCompoundStatement
//
//==============================================================================
procedure TAcsParser.LeadingCompoundStatement(const owner: statement_t);
begin
  FStatementLevel := FStatementLevel + AdjustStmtLevel[owner];
  FTokenizer.NextToken; // Eat the TK_LBRACE
  repeat until not ProcessStatement(owner);
  FTokenizer.TokenMustBe(TK_RBRACE, ERR_INVALID_STATEMENT);
  FTokenizer.NextToken;
  FStatementLevel := FStatementLevel - AdjustStmtLevel[owner];
end;

//==============================================================================
//
// LeadingVarDeclare
//
//==============================================================================
procedure TAcsParser.LeadingVarDeclare;
var
  sym: TAcsSymbol;
begin
  repeat
    if FScriptVarCount = MAX_SCRIPT_VARIABLES then
      FDiagnostics.Fail(ERR_TOO_MANY_SCRIPT_VARS, True, '', []);
    FTokenizer.NextTokenMustBe(TK_IDENTIFIER, ERR_INVALID_IDENTIFIER);
    if FSymbols.FindLocal(FTokenizer.Text) <> nil then
    begin  // Redefined
      FDiagnostics.Fail(ERR_REDEFINED_IDENTIFIER, True,
        'Identifier: %s', [FTokenizer.Text]);
    end;
    sym := FSymbols.InsertLocal(FTokenizer.Text, SY_SCRIPTVAR);
    sym.info.svar.index := FScriptVarCount;
    Inc(FScriptVarCount);
    FTokenizer.NextToken;
  until FTokenizer.Token <> TK_COMMA;
  FTokenizer.TokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// LeadingLineSpecial
//
//==============================================================================
procedure TAcsParser.LeadingLineSpecial;
var
  i: integer;
  argCount: integer;
  specialValue: integer;
  direct: boolean;
begin
  argCount := FTokenizer.SpecialArgCount;
  specialValue := FTokenizer.SpecialValue;
  FTokenizer.NextTokenMustBe(TK_LPAREN, ERR_MISSING_LPAREN);
  if FTokenizer.NextToken = TK_CONST then
  begin
    FTokenizer.NextTokenMustBe(TK_COLON, ERR_MISSING_COLON);
    FWriter.AppendCmd(PCD_LSPEC1DIRECT + (argCount - 1));
    FWriter.AppendLong(specialValue);
    direct := True;
  end
  else
  begin
    FTokenizer.Undo;
    direct := False;
  end;
  i := 0;
  repeat
    if i = argCount then
      FDiagnostics.Fail(ERR_BAD_LSPEC_ARG_COUNT, True, '', []);
    FTokenizer.NextToken;
    if direct then
      FWriter.AppendLong(EvalConstExpression)
    else
      EvalExpression;
    inc(i);
  until FTokenizer.Token <> TK_COMMA;
  if i <> argCount then
    FDiagnostics.Fail(ERR_BAD_LSPEC_ARG_COUNT, True, '', []);
  FTokenizer.TokenMustBe(TK_RPAREN, ERR_MISSING_RPAREN);
  FTokenizer.NextTokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  if not direct then
  begin
    FWriter.AppendCmd(PCD_LSPEC1 + (argCount - 1));
    FWriter.AppendLong(specialValue);
  end;
  FTokenizer.NextToken;
end;

//==============================================================================
//
// LeadingIdentifier
//
//==============================================================================
procedure TAcsParser.LeadingIdentifier;
var
  sym: TAcsSymbol;
begin
  sym := DemandSymbol(FTokenizer.Text);
  case sym.typ of
    SY_SCRIPTVAR,
    SY_MAPVAR,
    SY_WORLDVAR:
      LeadingVarAssign(sym);
    SY_INTERNFUNC:
      LeadingInternFunc(sym);
  end;
end;

//==============================================================================
//
// LeadingInternFunc
//
//==============================================================================
procedure TAcsParser.LeadingInternFunc(const sym: TAcsSymbol);
begin
  ProcessInternFunc(sym);
  if sym.info.internFunc.hasReturnValue then
    FWriter.AppendCmd(PCD_DROP);
  FTokenizer.TokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// ProcessInternFunc
//
//==============================================================================
procedure TAcsParser.ProcessInternFunc(const sym: TAcsSymbol);
var
  i: integer;
  argCount: integer;
  direct: boolean;
begin
  argCount := sym.info.internFunc.argCount;
  FTokenizer.NextTokenMustBe(TK_LPAREN, ERR_MISSING_LPAREN);
  if FTokenizer.NextToken = TK_CONST then
  begin
    FTokenizer.NextTokenMustBe(TK_COLON, ERR_MISSING_COLON);
    if sym.info.internFunc.directCommand = PCD_NOP then
      FDiagnostics.Fail(ERR_NO_DIRECT_VER, True, '', []);
    FWriter.AppendCmd(sym.info.internFunc.directCommand);
    direct := True;
    FTokenizer.NextToken;
  end
  else
    direct := False;
  i :=  0;
  if argCount > 0 then
  begin
    FTokenizer.Undo; // Adjust for first expression
    repeat
      if i = argCount then
        FDiagnostics.Fail(ERR_BAD_ARG_COUNT, True, '', []);
      FTokenizer.NextToken;
      if direct then
        FWriter.AppendLong(EvalConstExpression)
      else
        EvalExpression;
      Inc(i);
    until FTokenizer.Token <> TK_COMMA;
  end;
  if i <> argCount then
    FDiagnostics.Fail(ERR_BAD_ARG_COUNT, True, '', []);
  FTokenizer.TokenMustBe(TK_RPAREN, ERR_MISSING_RPAREN);
  if not direct then
    FWriter.AppendCmd(sym.info.internFunc.stackCommand);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// LeadingPrint
//
//==============================================================================
procedure TAcsParser.LeadingPrint;
var
  printCmd: Integer;
  stmtToken: integer;
begin
  stmtToken := FTokenizer.Token; // Will be TK_PRINT or TK_PRINTBOLD
  FWriter.AppendCmd(PCD_BEGINPRINT);
  FTokenizer.NextTokenMustBe(TK_LPAREN, ERR_MISSING_LPAREN);
  repeat
    printCmd := PCD_NOP; // Shut up compiler warning
    case FTokenizer.NextCharacter of
      Ord('s'): // string
        printCmd := PCD_PRINTSTRING;
      Ord('i'), // integer
      Ord('d'): // decimal
        printCmd := PCD_PRINTNUMBER;
      Ord('c'): // character
        printCmd := PCD_PRINTCHARACTER;
    else
      FDiagnostics.Fail(ERR_UNKNOWN_PRTYPE, True, '', []);
    end;
    FTokenizer.NextTokenMustBe(TK_COLON, ERR_MISSING_COLON);
    FTokenizer.NextToken;
    EvalExpression;
    FWriter.AppendCmd(printCmd);
  until FTokenizer.Token <> TK_COMMA;
  FTokenizer.TokenMustBe(TK_RPAREN, ERR_MISSING_RPAREN);
  if stmtToken = TK_PRINT then
    FWriter.AppendCmd(PCD_ENDPRINT)
  else
    FWriter.AppendCmd(PCD_ENDPRINTBOLD);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// LeadingIf
//
//==============================================================================
procedure TAcsParser.LeadingIf;
var
  jumpAddrPtr1: integer;
  jumpAddrPtr2: integer;
begin
  FTokenizer.NextTokenMustBe(TK_LPAREN, ERR_MISSING_LPAREN);
  FTokenizer.NextToken;
  EvalExpression;
  FTokenizer.TokenMustBe(TK_RPAREN, ERR_MISSING_RPAREN);
  FWriter.AppendCmd(PCD_IFNOTGOTO);
  jumpAddrPtr1 := FWriter.Address;
  FWriter.SkipLong;
  FTokenizer.NextToken;
  if not ProcessStatement(STMT_IF) then
    FDiagnostics.Fail(ERR_INVALID_STATEMENT, True, '', []);
  if FTokenizer.Token = TK_ELSE then
  begin
    FWriter.AppendCmd(PCD_GOTO);
    jumpAddrPtr2 := FWriter.Address;
    FWriter.SkipLong;
    FWriter.WriteLong(FWriter.Address, jumpAddrPtr1);
    FTokenizer.NextToken;
    if not ProcessStatement(STMT_ELSE) then
      FDiagnostics.Fail(ERR_INVALID_STATEMENT, True, '', []);
    FWriter.WriteLong(FWriter.Address, jumpAddrPtr2);
  end
  else
    FWriter.WriteLong(FWriter.Address, jumpAddrPtr1);
end;

//==============================================================================
//
// LeadingFor
//
//==============================================================================
procedure TAcsParser.LeadingFor;
begin
  // the original compiler did nothing here and the statement was never consumed: it looped
  // forever on the first for
  FDiagnostics.Fail(ERR_STATEMENT_NOT_IMPLEMENTED, True);
end;

//==============================================================================
//
// LeadingWhileUntil
//
//==============================================================================
procedure TAcsParser.LeadingWhileUntil;
var
  stmtToken: integer;
  topAddr: integer;
  outAddrPtr: integer;
begin
  stmtToken := FTokenizer.Token;
  topAddr := FWriter.Address;
  FTokenizer.NextTokenMustBe(TK_LPAREN, ERR_MISSING_LPAREN);
  FTokenizer.NextToken;
  EvalExpression;
  FTokenizer.TokenMustBe(TK_RPAREN, ERR_MISSING_RPAREN);
  if stmtToken = TK_WHILE then
    FWriter.AppendCmd(PCD_IFNOTGOTO)
  else
    FWriter.AppendCmd(PCD_IFGOTO);
  outAddrPtr := FWriter.Address;
  FWriter.SkipLong;
  FTokenizer.NextToken;
  if not ProcessStatement(STMT_WHILEUNTIL) then
    FDiagnostics.Fail(ERR_INVALID_STATEMENT, True, '', []);
  FWriter.AppendCmd(PCD_GOTO);
  FWriter.AppendLong(topAddr);

  FWriter.WriteLong(FWriter.Address, outAddrPtr);

  WriteContinues(topAddr);
  WriteBreaks;
end;

//==============================================================================
//
// LeadingDo
//
//==============================================================================
procedure TAcsParser.LeadingDo;
var
  topAddr: integer;
  exprAddr: integer;
  stmtToken: integer;
begin
  topAddr := FWriter.Address;
  FTokenizer.NextToken;
  if not ProcessStatement(STMT_DO) then
    FDiagnostics.Fail(ERR_INVALID_STATEMENT, True, '', []);
  if (FTokenizer.Token <> TK_WHILE) and (FTokenizer.Token <> TK_UNTIL) then
    FDiagnostics.Fail(ERR_BAD_DO_STATEMENT, True, '', []);
  stmtToken := FTokenizer.Token;
  FTokenizer.NextTokenMustBe(TK_LPAREN, ERR_MISSING_LPAREN);
  exprAddr := FWriter.Address;
  FTokenizer.NextToken;
  EvalExpression;
  FTokenizer.TokenMustBe(TK_RPAREN, ERR_MISSING_RPAREN);
  FTokenizer.NextTokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  if stmtToken = TK_WHILE then
    FWriter.AppendCmd(PCD_IFGOTO)
  else
    FWriter.AppendCmd(PCD_IFNOTGOTO);
  FWriter.AppendLong(topAddr);
  WriteContinues(exprAddr);
  WriteBreaks;
  FTokenizer.NextToken;
end;

//==============================================================================
//
// LeadingSwitch
//
//==============================================================================
procedure TAcsParser.LeadingSwitch;
var
  switcherAddrPtr: integer;
  outAddrPtr: integer;
  cInfo: PcaseInfo_t;
  defaultAddress: integer;
begin

  FTokenizer.NextTokenMustBe(TK_LPAREN, ERR_MISSING_LPAREN);
  FTokenizer.NextToken;
  EvalExpression;
  FTokenizer.TokenMustBe(TK_RPAREN, ERR_MISSING_RPAREN);

  FWriter.AppendCmd(PCD_GOTO);
  switcherAddrPtr := FWriter.Address;
  FWriter.SkipLong;

  FTokenizer.NextToken;
  if not ProcessStatement(STMT_SWITCH) then
    FDiagnostics.Fail(ERR_INVALID_STATEMENT, True, '', []);

  FWriter.AppendCmd(PCD_GOTO);
  outAddrPtr := FWriter.Address;
  FWriter.SkipLong;

  FWriter.WriteLong(FWriter.Address, switcherAddrPtr);
  defaultAddress := 0;
  while True do
  begin
    cInfo := GetCaseInfo;
    if cInfo = nil then
      Break;
    if cInfo.isDefault then
    begin
      defaultAddress := cInfo.address;
      continue;
    end;
    FWriter.AppendCmd(PCD_CASEGOTO);
    FWriter.AppendLong(cInfo.value);
    FWriter.AppendLong(cInfo.address);
  end;
  FWriter.AppendCmd(PCD_DROP);

  if defaultAddress <> 0 then
  begin
    FWriter.AppendCmd(PCD_GOTO);
    FWriter.AppendLong(defaultAddress);
  end;

  FWriter.WriteLong(FWriter.Address, outAddrPtr);

  WriteBreaks;
end;

//==============================================================================
//
// LeadingCase
//
//==============================================================================
procedure TAcsParser.LeadingCase;
begin
  FTokenizer.NextToken;
  PushCase(EvalConstExpression, False);
  FTokenizer.TokenMustBe(TK_COLON, ERR_MISSING_COLON);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// LeadingDefault
//
//==============================================================================
procedure TAcsParser.LeadingDefault;
begin
  FTokenizer.NextTokenMustBe(TK_COLON, ERR_MISSING_COLON);
  PushCase(0, True);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// PushCase
//
//==============================================================================
procedure TAcsParser.PushCase(const value: integer; const isDefault: boolean);
begin
  if FCaseIndex = MAX_CASE then
    FDiagnostics.Fail(ERR_CASE_OVERFLOW, True, '', []);
  FCaseInfo[FCaseIndex].level := FStatementLevel;
  FCaseInfo[FCaseIndex].value := value;
  FCaseInfo[FCaseIndex].isDefault := isDefault;
  FCaseInfo[FCaseIndex].address := FWriter.Address;
  Inc(FCaseIndex);
end;

//==============================================================================
//
// GetCaseInfo
//
//==============================================================================
function TAcsParser.GetCaseInfo: PcaseInfo_t;
begin
  if FCaseIndex = 0 then
  begin
    result := nil;
    exit;
  end;
  if FCaseInfo[FCaseIndex - 1].level > FStatementLevel then
  begin
    Dec(FCaseIndex);
    result := @FCaseInfo[FCaseIndex];
    exit;
  end;
  result := nil;
end;

//==============================================================================
//
// DefaultInCurrent
//
//==============================================================================
function TAcsParser.DefaultInCurrent: boolean;
var
  i: integer;
begin
  for i := 0 to FCaseIndex - 1 do
  begin
    if FCaseInfo[i].isDefault and (FCaseInfo[i].level = FStatementLevel) then
    begin
      result := true;
      exit;
    end;
  end;
  result := false;
end;

//==============================================================================
//
// LeadingBreak
//
//==============================================================================
procedure TAcsParser.LeadingBreak;
begin
  FTokenizer.NextTokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  FWriter.AppendCmd(PCD_GOTO);
  PushBreak;
  FWriter.SkipLong;
  FTokenizer.NextToken;
end;

//==============================================================================
//
// PushBreak
//
//==============================================================================
procedure TAcsParser.PushBreak;
begin
  if FBreakIndex = MAX_CASE then
    FDiagnostics.Fail(ERR_BREAK_OVERFLOW, True, '', []);
  FBreakInfo[FBreakIndex].level := FStatementLevel;
  FBreakInfo[FBreakIndex].addressPtr := FWriter.Address;
  Inc(FBreakIndex);
end;

//==============================================================================
//
// WriteBreaks
//
//==============================================================================
procedure TAcsParser.WriteBreaks;
begin
  if FBreakIndex = 0 then
    exit;
  while FBreakInfo[FBreakIndex - 1].level > FStatementLevel do
  begin
    dec(FBreakIndex);
    FWriter.WriteLong(FWriter.Address, FBreakInfo[FBreakIndex].addressPtr);
  end;
end;

//==============================================================================
//
// BreakAncestor
//
// Returns YES if the current statement history contains a break root
// statement.
//
//==============================================================================
function TAcsParser.BreakAncestor: boolean;
var
  i: integer;
begin
  for i := 0 to FStatementIndex - 1 do
  begin
    if IsBreakRoot[FStatementHistory[i]] then
    begin
      result := True;
      exit;
    end;
  end;
  result := false;
end;

//==============================================================================
//
// LeadingContinue
//
//==============================================================================
procedure TAcsParser.LeadingContinue;
begin
  FTokenizer.NextTokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  FWriter.AppendCmd(PCD_GOTO);
  PushContinue;
  FWriter.SkipLong;
  FTokenizer.NextToken;
end;

//==============================================================================
//
// PushContinue
//
//==============================================================================
procedure TAcsParser.PushContinue;
begin
  if FContinueIndex = MAX_CONTINUE then
    FDiagnostics.Fail(ERR_CONTINUE_OVERFLOW, True, '', []);
  FContinueInfo[FContinueIndex].level := FStatementLevel;
  FContinueInfo[FContinueIndex].addressPtr := FWriter.Address;
  Inc(FContinueIndex);
end;

//==============================================================================
//
// WriteContinues
//
//==============================================================================
procedure TAcsParser.WriteContinues(const address: integer);
begin
  if FContinueIndex = 0 then
    exit;
  while FContinueInfo[FContinueIndex - 1].level > FStatementLevel do
  begin
    Dec(FContinueIndex);
    FWriter.WriteLong(address, FContinueInfo[FContinueIndex].addressPtr);
  end;
end;

//==============================================================================
//
// ContinueAncestor
//
//==============================================================================
function TAcsParser.ContinueAncestor: boolean;
var
  i: integer;
begin
  for i := 0 to FStatementIndex - 1 do
  begin
    if IsContinueRoot[FStatementHistory[i]] then
    begin
      result := True;
      Exit;
    end;
  end;
  result := False
end;

//==============================================================================
//
// LeadingVarAssign
//
//==============================================================================
procedure TAcsParser.LeadingVarAssign(sym: TAcsSymbol);
var
  done: boolean;
  assignToken: integer;
begin
  done := false;
  repeat
    FTokenizer.NextToken; // Fetch assignment operator
    if (FTokenizer.Token = TK_INC) or (FTokenizer.Token = TK_DEC) then
    begin  // Postfix increment or decrement
      FWriter.AppendCmd(GetIncDecPCD(FTokenizer.Token, sym.typ));
      FWriter.AppendLong(sym.info.svar.index);
      FTokenizer.NextToken;
    end
    else
    begin  // Normal operator
      if not FTokenizer.Member(AssignOps) then
        FDiagnostics.Fail(ERR_MISSING_ASSIGN_OP, True, '', []);
      assignToken := FTokenizer.Token;
      FTokenizer.NextToken;
      EvalExpression;
      FWriter.AppendCmd(GetAssignPCD(assignToken, sym.typ));
      FWriter.AppendLong(sym.info.svar.index);
    end;
    if FTokenizer.Token = TK_COMMA then
    begin
      FTokenizer.NextTokenMustBe(TK_IDENTIFIER, ERR_BAD_ASSIGNMENT);
      sym := DemandSymbol(FTokenizer.Text);
      if (sym.typ <> SY_SCRIPTVAR) and (sym.typ <> SY_MAPVAR) and (sym.typ <> SY_WORLDVAR) then
        FDiagnostics.Fail(ERR_BAD_ASSIGNMENT, True, '', []);
    end
    else
    begin
      FTokenizer.TokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
      FTokenizer.NextToken;
      done := True;
    end;
  until done;
end;

type
  Lookup_t = record
    token: integer;
    symbol: TAcsSymbolKind;
    pcd: integer;
  end;

const
  ASSIGNMENT_LOOKUP_SIZE = 19;

  assignmentLookup: array[0..ASSIGNMENT_LOOKUP_SIZE - 1] of Lookup_t = (
    (token: TK_ASSIGN;    symbol: SY_SCRIPTVAR; pcd: PCD_ASSIGNSCRIPTVAR),
    (token: TK_ASSIGN;    symbol: SY_MAPVAR;    pcd: PCD_ASSIGNMAPVAR),
    (token: TK_ASSIGN;    symbol: SY_WORLDVAR;  pcd: PCD_ASSIGNWORLDVAR),
    (token: TK_ADDASSIGN; symbol: SY_SCRIPTVAR; pcd: PCD_ADDSCRIPTVAR),
    (token: TK_ADDASSIGN; symbol: SY_MAPVAR;    pcd: PCD_ADDMAPVAR),
    (token: TK_ADDASSIGN; symbol: SY_WORLDVAR;  pcd: PCD_ADDWORLDVAR),
    (token: TK_SUBASSIGN; symbol: SY_SCRIPTVAR; pcd: PCD_SUBSCRIPTVAR),
    (token: TK_SUBASSIGN; symbol: SY_MAPVAR;    pcd: PCD_SUBMAPVAR),
    (token: TK_SUBASSIGN; symbol: SY_WORLDVAR;  pcd: PCD_SUBWORLDVAR),
    (token: TK_MULASSIGN; symbol: SY_SCRIPTVAR; pcd: PCD_MULSCRIPTVAR),
    (token: TK_MULASSIGN; symbol: SY_MAPVAR;    pcd: PCD_MULMAPVAR),
    (token: TK_MULASSIGN; symbol: SY_WORLDVAR;  pcd: PCD_MULWORLDVAR),
    (token: TK_DIVASSIGN; symbol: SY_SCRIPTVAR; pcd: PCD_DIVSCRIPTVAR),
    (token: TK_DIVASSIGN; symbol: SY_MAPVAR;    pcd: PCD_DIVMAPVAR),
    (token: TK_DIVASSIGN; symbol: SY_WORLDVAR;  pcd: PCD_DIVWORLDVAR),
    (token: TK_MODASSIGN; symbol: SY_SCRIPTVAR; pcd: PCD_MODSCRIPTVAR),
    (token: TK_MODASSIGN; symbol: SY_MAPVAR;    pcd: PCD_MODMAPVAR),
    (token: TK_MODASSIGN; symbol: SY_WORLDVAR;  pcd: PCD_MODWORLDVAR),
    (token: TK_NONE)
  );

//==============================================================================
//
// GetAssignPCD
//
//==============================================================================
function TAcsParser.GetAssignPCD(token: integer; symbol: TAcsSymbolKind): Integer;
var
  i: integer;
begin
  i := 0;
  while assignmentLookup[i].token <> TK_NONE do
  begin
    if (assignmentLookup[i].token = token) and (assignmentLookup[i].symbol = symbol) then
    begin
      result := assignmentLookup[i].pcd;
      exit;
    end;
    inc(i);
  end;
  result := PCD_NOP;
end;

//==============================================================================
//
// LeadingSuspend
//
//==============================================================================
procedure TAcsParser.LeadingSuspend;
begin
  FTokenizer.NextTokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  FWriter.AppendCmd(PCD_SUSPEND);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// LeadingTerminate
//
//==============================================================================
procedure TAcsParser.LeadingTerminate;
begin
  FTokenizer.NextTokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  FWriter.AppendCmd(PCD_TERMINATE);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// LeadingRestart
//
//==============================================================================
procedure TAcsParser.LeadingRestart;
begin
  FTokenizer.NextTokenMustBe(TK_SEMICOLON, ERR_MISSING_SEMICOLON);
  FWriter.AppendCmd(PCD_RESTART);
  FTokenizer.NextToken;
end;

//==============================================================================
//
// EvalConstExpression
//
//==============================================================================
function TAcsParser.EvalConstExpression: Integer;
begin
  FExprStackIndex := 0;
  FConstantExpression := True;
  ExprLevA;
  if FExprStackIndex <> 1 then
    FDiagnostics.Fail(ERR_BAD_CONST_EXPR, True, '', []);
  result := PopExStk;
end;

//==============================================================================
//
// EvalExpression
//
//==============================================================================
procedure TAcsParser.EvalExpression;
begin
  FConstantExpression := False;
  ExprLevA;
end;

//==============================================================================
// ExprLevA
//
// Operator: ||
//
//==============================================================================
procedure TAcsParser.ExprLevA;
begin
  ExprLevB;
  while FTokenizer.Token = TK_ORLOGICAL do
  begin
    FTokenizer.NextToken;
    ExprLevB;
    SendExprCommand(PCD_ORLOGICAL);
  end;
end;

//==============================================================================
// ExprLevB
//
// Operator: &&
//
//==============================================================================
procedure TAcsParser.ExprLevB;
begin
  ExprLevC;
  while FTokenizer.Token = TK_ANDLOGICAL do
  begin
    FTokenizer.NextToken;
    ExprLevC;
    SendExprCommand(PCD_ANDLOGICAL);
  end;
end;

//==============================================================================
// ExprLevC
//
// Operator: |
//
//==============================================================================
procedure TAcsParser.ExprLevC;
begin
  ExprLevD;
  while FTokenizer.Token = TK_ORBITWISE do
  begin
    FTokenizer.NextToken;
    ExprLevD;
    SendExprCommand(PCD_ORBITWISE);
  end;
end;

//==============================================================================
// ExprLevD
//
// Operator: ^
//
//==============================================================================
procedure TAcsParser.ExprLevD;
begin
  ExprLevE;
  while FTokenizer.Token = TK_EORBITWISE do
  begin
    FTokenizer.NextToken;
    ExprLevE;
    SendExprCommand(PCD_EORBITWISE);
  end;
end;

//==============================================================================
// ExprLevE
//
// Operator: &
//
//==============================================================================
procedure TAcsParser.ExprLevE;
begin
  ExprLevF;
  while FTokenizer.Token = TK_ANDBITWISE do
  begin
    FTokenizer.NextToken;
    ExprLevF;
    SendExprCommand(PCD_ANDBITWISE);
  end;
end;

//==============================================================================
// ExprLevF
//
// Operators: = <>
//
//==============================================================================
procedure TAcsParser.ExprLevF;
var
  token: integer;
begin
  ExprLevG;
  while FTokenizer.Member(LevFOps) do
  begin
    token := FTokenizer.Token;
    FTokenizer.NextToken;
    ExprLevG;
    SendExprCommand(TokenToPCD(token));
  end;
end;

//==============================================================================
// ExprLevG
//
// Operators: < <= > >=
//
//==============================================================================
procedure TAcsParser.ExprLevG;
var
  token: integer;
begin
  ExprLevH;
  while FTokenizer.Member(LevGOps) do
  begin
    token := FTokenizer.Token;
    FTokenizer.NextToken;
    ExprLevH;
    SendExprCommand(TokenToPCD(token));
  end;
end;

//==============================================================================
// ExprLevH
//
// Operators:  shl   shr
//
//==============================================================================
procedure TAcsParser.ExprLevH;
var
  token: integer;
begin
  ExprLevI;
  while FTokenizer.Member(LevHOps) do
  begin
    token := FTokenizer.Token;
    FTokenizer.NextToken;
    ExprLevI;
    SendExprCommand(TokenToPCD(token));
  end;
end;

//==============================================================================
// ExprLevI
//
// Operators: + -
//
//==============================================================================
procedure TAcsParser.ExprLevI;
var
  token: integer;
begin
  ExprLevJ;
  while FTokenizer.Member(LevIOps) do
  begin
    token := FTokenizer.Token;
    FTokenizer.NextToken;
    ExprLevJ;
    SendExprCommand(TokenToPCD(token));
  end;
end;

//==============================================================================
// ExprLevJ
//
// Operators: * /  mod
//
//==============================================================================
procedure TAcsParser.ExprLevJ;
var
  token: integer;
  unaryMinus: boolean;
begin
  unaryMinus := False;
  if FTokenizer.Token = TK_MINUS then
  begin
    unaryMinus := True;
    FTokenizer.NextToken;
  end;
  if FConstantExpression then
    ConstExprFactor
  else
    ExprFactor;
  if unaryMinus then
    SendExprCommand(PCD_UNARYMINUS);
  while FTokenizer.Member(LevJOps) do
  begin
    token := FTokenizer.Token;
    FTokenizer.NextToken;
    if FConstantExpression then
      ConstExprFactor
    else
      ExprFactor;
    SendExprCommand(TokenToPCD(token));
  end;
end;

//==============================================================================
//
// ExprFactor
//
//==============================================================================
procedure TAcsParser.ExprFactor;
var
  sym: TAcsSymbol;
  opToken: integer;
begin
  case FTokenizer.Token of
    TK_STRING:
      begin
        FWriter.AppendCmd(PCD_PUSHNUMBER);
        FWriter.AppendLong(FStrings.Find(FTokenizer.Text));
        FTokenizer.NextToken;
      end;
    TK_NUMBER:
      begin
        FWriter.AppendCmd(PCD_PUSHNUMBER);
        FWriter.AppendLong(FTokenizer.Num);
        FTokenizer.NextToken;
      end;
    TK_LPAREN:
      begin
        FTokenizer.NextToken;
        ExprLevA;
        if FTokenizer.Token <> TK_RPAREN then
          FDiagnostics.Fail(ERR_BAD_EXPR, True, '', []);
        FTokenizer.NextToken;
      end;
    TK_NOT:
      begin
        FTokenizer.NextToken;
        ExprFactor;
        FWriter.AppendCmd(PCD_NEGATELOGICAL);
      end;
    TK_INC,
    TK_DEC:
      begin
        opToken := FTokenizer.Token;
        FTokenizer.NextTokenMustBe(TK_IDENTIFIER, ERR_INCDEC_OP_ON_NON_VAR);
        sym :=  DemandSymbol(FTokenizer.Text);
        if (sym.typ <> SY_SCRIPTVAR) and (sym.typ <> SY_MAPVAR) and (sym.typ <> SY_WORLDVAR) then
          FDiagnostics.Fail(ERR_INCDEC_OP_ON_NON_VAR, True, '', []);
        FWriter.AppendCmd(GetIncDecPCD(opToken, sym.typ));
        FWriter.AppendLong(sym.info.svar.index);
        FWriter.AppendCmd(GetPushVarPCD(sym.typ));
        FWriter.AppendLong(sym.info.svar.index);
        FTokenizer.NextToken;
      end;
    TK_IDENTIFIER:
      begin
        sym := DemandSymbol(FTokenizer.Text);
        case sym.typ of
          SY_SCRIPTVAR,
          SY_MAPVAR,
          SY_WORLDVAR:
            begin
              FWriter.AppendCmd(GetPushVarPCD(sym.typ));
              FWriter.AppendLong(sym.info.svar.index);
              FTokenizer.NextToken;
              if (FTokenizer.Token = TK_INC) or (FTokenizer.Token = TK_DEC) then
              begin
                FWriter.AppendCmd(GetIncDecPCD(FTokenizer.Token, sym.typ));
                FWriter.AppendLong(sym.info.svar.index);
                FTokenizer.NextToken;
              end;
            end;
          SY_INTERNFUNC:
            begin
              if not sym.info.internFunc.hasReturnValue then
                FDiagnostics.Fail(ERR_EXPR_FUNC_NO_RET_VAL, True, '', []);
              ProcessInternFunc(sym);
            end;
        else
          FDiagnostics.Fail(ERR_ILLEGAL_EXPR_IDENT, True, 'Identifier: %s', [FTokenizer.Text]);
        end;
      end;
  else
    FDiagnostics.Fail(ERR_BAD_EXPR, True, '', []);
  end;
end;

//==============================================================================
//
// ConstExprFactor
//
//==============================================================================
procedure TAcsParser.ConstExprFactor;
begin
  case FTokenizer.Token of
    TK_STRING:
      begin
        PushExStk(FStrings.Find(FTokenizer.Text));
        FTokenizer.NextToken;
      end;
    TK_NUMBER:
      begin
        PushExStk(FTokenizer.Num);
        FTokenizer.NextToken;
      end;
    TK_LPAREN:
      begin
        FTokenizer.NextToken;
        ExprLevA;
        if FTokenizer.Token <> TK_RPAREN then
          FDiagnostics.Fail(ERR_BAD_CONST_EXPR, True, '', []);
        FTokenizer.NextToken;
      end;
    TK_NOT:
      begin
        FTokenizer.NextToken;
        ConstExprFactor;
        SendExprCommand(PCD_NEGATELOGICAL);
      end;
  else
    FDiagnostics.Fail(ERR_BAD_CONST_EXPR, True, '', []);
  end;
end;

//==============================================================================
//
// SendExprCommand
//
//==============================================================================
procedure TAcsParser.SendExprCommand(const pcd: integer);
var
  operand2: integer;
begin
  if not FConstantExpression then
  begin
    FWriter.AppendCmd(pcd);
    exit;
  end;

  case pcd of
    PCD_ADD:
      PushExStk(PopExStk + PopExStk);
    PCD_SUBTRACT:
      begin
        operand2 := PopExStk;
        PushExStk(PopExStk - operand2);
      end;
    PCD_MULTIPLY:
      PushExStk(PopExStk * PopExStk);
    PCD_DIVIDE:
      begin
        operand2 := PopExStk;
        PushExStk(PopExStk div operand2);
      end;
    PCD_MODULUS:
      begin
        operand2 := PopExStk;
        PushExStk(PopExStk mod operand2);
      end;
    PCD_EQ:
      PushExStk(IntVal(PopExStk = PopExStk));
    PCD_NE:
      PushExStk(IntVal(PopExStk <> PopExStk));
    PCD_LT:
      PushExStk(IntVal(PopExStk >= PopExStk));
    PCD_GT:
      PushExStk(IntVal(PopExStk <= PopExStk));
    PCD_LE:
      PushExStk(IntVal(PopExStk > PopExStk));
    PCD_GE:
      PushExStk(IntVal(PopExStk < PopExStk));
    PCD_ANDLOGICAL:
      PushExStk(PopExStk and PopExStk);
    PCD_ORLOGICAL:
      PushExStk(PopExStk or PopExStk);
    PCD_ANDBITWISE:
      PushExStk(PopExStk and PopExStk);
    PCD_ORBITWISE:
      PushExStk(PopExStk or PopExStk);
    PCD_EORBITWISE:
      PushExStk(PopExStk xor PopExStk);
    PCD_NEGATELOGICAL:
      PushExStk(not PopExStk);
    PCD_LSHIFT:
      begin
        operand2 := PopExStk;
        PushExStk(PopExStk shr operand2);
      end;
    PCD_RSHIFT:
      begin
        operand2 := PopExStk;
        PushExStk(PopExStk shl operand2);
      end;
    PCD_UNARYMINUS:
      PushExStk(-PopExStk);
  else
    FDiagnostics.Fail(ERR_UNKNOWN_CONST_EXPR_PCD, True, '', []);
  end;
end;

//==============================================================================
//
// PushExStk
//
//==============================================================================
procedure TAcsParser.PushExStk(const value: integer);
begin
  if FExprStackIndex = EXPR_STACK_DEPTH then
    FDiagnostics.Fail(ERR_EXPR_STACK_OVERFLOW, True, '', []);
  FExprStack[FExprStackIndex] := value;
  Inc(FExprStackIndex);
end;

//==============================================================================
//
// PopExStk
//
//==============================================================================
function TAcsParser.PopExStk: integer;
begin
  if FExprStackIndex < 1 then
    FDiagnostics.Fail(ERR_EXPR_STACK_EMPTY, True, '', []);
  Dec(FExprStackIndex);
  result := FExprStack[FExprStackIndex];
end;

type
  operatorLookup_t = record
    token: integer;
    pcd: integer;
  end;

const
  NUM_OPERATOR_LOOKUP = 14;

  operatorLookup: array[0..NUM_OPERATOR_LOOKUP - 1] of operatorLookup_t = (
    (token: TK_EQ;        pcd: PCD_EQ),
    (token: TK_NE;        pcd: PCD_NE),
    (token: TK_LT;        pcd: PCD_LT),
    (token: TK_LE;        pcd: PCD_LE),
    (token: TK_GT;        pcd: PCD_GT),
    (token: TK_GE;        pcd: PCD_GE),
    (token: TK_LSHIFT;    pcd: PCD_LSHIFT),
    (token: TK_RSHIFT;    pcd: PCD_RSHIFT),
    (token: TK_PLUS;      pcd: PCD_ADD),
    (token: TK_MINUS;     pcd: PCD_SUBTRACT),
    (token: TK_ASTERISK;  pcd: PCD_MULTIPLY),
    (token: TK_SLASH;     pcd: PCD_DIVIDE),
    (token: TK_PERCENT;   pcd: PCD_MODULUS),
    (token: TK_NONE;      pcd: PCD_NOP)
  );

//==============================================================================
//
// TokenToPCD
//
//==============================================================================
function TAcsParser.TokenToPCD(token: integer): integer;
var
  i: integer;
begin
  i := 0;
  while operatorLookup[i].token <> TK_NONE do
  begin
    if operatorLookup[i].token = token then
    begin
      result := operatorLookup[i].pcd;
      exit;
    end;
    inc(i);
  end;
  result := PCD_NOP;
end;

//==============================================================================
//
// GetPushVarPCD
//
//==============================================================================
function TAcsParser.GetPushVarPCD(const symType: TAcsSymbolKind): Integer;
begin
  case symType of
    SY_SCRIPTVAR:
      result := PCD_PUSHSCRIPTVAR;
    SY_MAPVAR:
      result := PCD_PUSHMAPVAR;
    SY_WORLDVAR:
      result := PCD_PUSHWORLDVAR;
  else
    result := PCD_NOP;
  end;
end;

const
  NUM_INCDEC_LOOKUP = 7;
  incDecLookup: array[0..NUM_INCDEC_LOOKUP - 1] of Lookup_t = (
    (token: TK_INC;   symbol: SY_SCRIPTVAR; pcd: PCD_INCSCRIPTVAR),
    (token: TK_INC;   symbol: SY_MAPVAR;    pcd: PCD_INCMAPVAR),
    (token: TK_INC;   symbol: SY_WORLDVAR;  pcd: PCD_INCWORLDVAR),
    (token: TK_DEC;   symbol: SY_SCRIPTVAR; pcd: PCD_DECSCRIPTVAR),
    (token: TK_DEC;   symbol: SY_MAPVAR;    pcd: PCD_DECMAPVAR),
    (token: TK_DEC;   symbol: SY_WORLDVAR;  pcd: PCD_DECWORLDVAR),
    (token: TK_NONE)
  );

//==============================================================================
//
// GetIncDecPCD
//
//==============================================================================
function TAcsParser.GetIncDecPCD(token: integer; symbol: TAcsSymbolKind): Integer;
var
  i: integer;
begin
  i := 0;
  while incDecLookup[i].token <> TK_NONE do
  begin
    if (incDecLookup[i].token = token) and (incDecLookup[i].symbol = symbol) then
    begin
      result := incDecLookup[i].pcd;
      exit;
    end;
    inc(i);
  end;
  result := PCD_NOP;
end;

//==============================================================================
//
// DemandSymbol
//
//==============================================================================
function TAcsParser.DemandSymbol(const name: string): TAcsSymbol;
begin
  result := FSymbols.Find(name);
  if result = nil then
    FDiagnostics.Fail(ERR_UNKNOWN_IDENTIFIER, True, 'Identifier: %s', [name]);
end;

//==============================================================================
//
// Outside
//
//==============================================================================
procedure TAcsParser.Outside;
var
  done: boolean;
begin
  done := false;
  while not done do
  begin
    case FTokenizer.Token of
      TK_EOF:
        done := true;
      TK_SCRIPT:
        OuterScript;
      TK_INT,
      TK_STR:
        OuterMapVar;
      TK_WORLD:
        OuterWorldVar;
      TK_SPECIAL:
        OuterSpecialDef;
      TK_NUMBERSIGN:
        begin
          FTokenizer.NextToken;
          case FTokenizer.Token of
            TK_DEFINE:
              OuterDefine;
            TK_INCLUDE:
              OuterInclude;
          else
            FDiagnostics.Fail(ERR_INVALID_DIRECTIVE, True, '', []);
          end;
        end;
    else
      FDiagnostics.Fail(ERR_INVALID_DECLARATOR, True, '', []);
    end;
  end;
end;

//==============================================================================
//
// Parse
//
//==============================================================================
procedure TAcsParser.Parse;
begin
  FTokenizer.NextToken;
  Outside;
end;

end.


{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptCompiler (idCompiler)      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\script\             }
{  Script_Compiler.h, Script_Compiler.cpp. Copyright (C) 1999-2011 id          }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.Compiler;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Token, DelphiDoom.Scanner.IdParser,
  DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventRegistry,
  DelphiDoom.DoomScript.ClassInfo, DelphiDoom.DoomScript.Defs, DelphiDoom.DoomScript.ScriptProgram;

type
  /// <summary>
  ///   idCompiler: compiles the text of a script into a program (statements, definitions, types and
  ///   functions). Nothing is kept between two calls of <c>CompileFile</c>: every call starts from the
  ///   global namespace with a new parser (<c>Libs\Scanner</c>, <c>TIdParser</c>), which reads
  ///   <c>script/doom_defs.script</c> first as the original does. An error is an
  ///   EDoomScriptCompileError with the text of the original ("Error: file F, line N: ...").
  /// </summary>
  TDoomScriptCompiler = class
  strict private
    FProgram: TDoomScriptProgram;
    FEvents: TDoomScriptEventRegistry;
    FSysClass: TDoomScriptClassInfo;
    FLog: IIdLibLog;
    FFileSystem: IIdLibFileSystem;
    FPunctuationValid: array[0..255] of Boolean;
    FParser: TIdParser;
    FToken: TIdToken;
    FImmediateType: TDoomScriptTypeDef;
    FImmediate: TDoomScriptEval;
    FEof: Boolean;
    FConsole: Boolean;
    FCallThread: Boolean;
    FBraceDepth: Integer;
    FLoopDepth: Integer;
    FCurrentLineNumber: Integer;
    FCurrentFileNumber: Integer;
    // the function being parsed, or the namespace
    FScope: TDoomScriptVarDef;
    // for accessing fields
    FBaseType: TDoomScriptVarDef;
    function TypeOf(const AKind: TDoomScriptEType): TDoomScriptTypeDef; inline;
    function FloatAt(const ADef: TDoomScriptVarDef): Single;
    function IntAt(const ADef: TDoomScriptVarDef): Integer;
    function Divide(const ANumerator, ADenominator: Single): Single;
    function Modulo(const ANumerator, ADenominator: Single): Single;
    procedure Error(const AFormat: string; const AArgs: array of const); overload;
    procedure Error(const AText: string); overload;
    function OptimizeOpcode(const AOp: Integer; const AVarA, AVarB: TDoomScriptVarDef): TDoomScriptVarDef;
    function EmitOpcode(const AOp: Integer; const AVarA, AVarB: TDoomScriptVarDef): TDoomScriptVarDef;
    function EmitPush(const AExpression: TDoomScriptVarDef; const AFuncArg: TDoomScriptTypeDef): Boolean;
    procedure NextToken;
    procedure ExpectToken(const AText: AnsiString);
    function CheckToken(const AText: AnsiString): Boolean;
    function ParseName: AnsiString;
    function CheckType: TDoomScriptTypeDef;
    function ParseType: TDoomScriptTypeDef;
    function FindImmediate(const AType: TDoomScriptTypeDef; const AEval: TDoomScriptEval;
      const AText: AnsiString): TDoomScriptVarDef;
    function GetImmediate(const AType: TDoomScriptTypeDef; const AEval: TDoomScriptEval;
      const AText: AnsiString): TDoomScriptVarDef;
    function VirtualFunctionConstant(const AFunc: TDoomScriptVarDef): TDoomScriptVarDef;
    function SizeConstant(const ASize: Integer): TDoomScriptVarDef;
    function JumpConstant(const AValue: Integer): TDoomScriptVarDef;
    function JumpDef(const AJumpFrom, AJumpTo: Integer): TDoomScriptVarDef;
    function JumpTo(const AJumpTo: Integer): TDoomScriptVarDef;
    function JumpFrom(const AJumpFrom: Integer): TDoomScriptVarDef;
    function ParseImmediate: TDoomScriptVarDef;
    function EmitFunctionParms(const AOp: Integer; const AFunc: TDoomScriptVarDef; const AStartArg,
      AStartSize: Integer; const AObject: TDoomScriptVarDef): TDoomScriptVarDef;
    function ParseFunctionCall(const AFuncDef: TDoomScriptVarDef): TDoomScriptVarDef;
    function ParseObjectCall(const AObject, AFunc: TDoomScriptVarDef): TDoomScriptVarDef;
    function ParseEventCall(const AObject, AFuncDef: TDoomScriptVarDef): TDoomScriptVarDef;
    function ParseSysObjectCall(const AFuncDef: TDoomScriptVarDef): TDoomScriptVarDef;
    function LookupDef(const AName: AnsiString; const ABaseObj: TDoomScriptVarDef): TDoomScriptVarDef;
    function ParseValue: TDoomScriptVarDef;
    function GetTerm: TDoomScriptVarDef;
    function GetExpression(const APriority: Integer): TDoomScriptVarDef;
    function GetTypeForEventArg(const AArgType: AnsiChar): TDoomScriptTypeDef;
    procedure PatchLoop(const AStart, AContinuePos: Integer);
    procedure ParseReturnStatement;
    procedure ParseWhileStatement;
    procedure ParseForStatement;
    procedure ParseDoWhileStatement;
    procedure ParseIfStatement;
    procedure ParseStatement;
    procedure ParseObjectDef(const AObjName: AnsiString);
    function ParseFunction(const AReturnType: TDoomScriptTypeDef; const AName: AnsiString): TDoomScriptTypeDef;
    procedure ParseFunctionDef(const AReturnType: TDoomScriptTypeDef; const AName: AnsiString);
    procedure ParseVariableDef(const AType: TDoomScriptTypeDef; const AName: AnsiString);
    procedure ParseEventDef(const AReturnType: TDoomScriptTypeDef; const AName: AnsiString);
    procedure ParseDefs;
    procedure ParseNamespace(const ANewScope: TDoomScriptVarDef);
    procedure ResetState;
  public
    /// <summary>
    ///   <c>ASysClass</c> is the class of the script threads: an event it responds to can be called as
    ///   <c>sys.event()</c>. The log receives the warnings of the parser and "Compiled 'file'".
    /// </summary>
    constructor Create(const AProgram: TDoomScriptProgram; const AEvents: TDoomScriptEventRegistry;
      const ASysClass: TDoomScriptClassInfo; const ALog: IIdLibLog; const AFileSystem: IIdLibFileSystem);
    /// <summary>
    ///   idCompiler::CompileFile: compiles the text, adding definitions to the program. With
    ///   <c>AConsole</c> the error has no file and line.
    /// </summary>
    procedure CompileFile(const AText, AFileName: AnsiString; const AConsole: Boolean);
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.DoomScript.Opcodes;

const
  Punctuation: array[0..35] of AnsiString = ('+=', '-=', '*=', '/=', '%=', '&=', '|=', '++', '--', '&&', '||',
    '<=', '>=', '==', '!=', '::', ';', ',', '~', '!', '*', '/', '%', '(', ')', '-', '+', '=', '[', ']', '.', '<',
    '>', '&', '|', ':');
  IMMEDIATE_NAME: AnsiString = '<IMMEDIATE>';

constructor TDoomScriptCompiler.Create(const AProgram: TDoomScriptProgram; const AEvents: TDoomScriptEventRegistry;
  const ASysClass: TDoomScriptClassInfo; const ALog: IIdLibLog; const AFileSystem: IIdLibFileSystem);
var
  LLexer: TIdLexer;
  LIndex: Integer;
  LId: Integer;
begin
  inherited Create;
  FProgram := AProgram;
  FEvents := AEvents;
  FSysClass := ASysClass;
  FLog := ALog;
  FFileSystem := AFileSystem;
  LLexer := TIdLexer.Create;
  try
    for LIndex := Low(Punctuation) to High(Punctuation) do
    begin
      LId := LLexer.GetPunctuationId(Punctuation[LIndex]);
      if (LId >= 0) and (LId < 256) then
        FPunctuationValid[LId] := True;
    end;
  finally
    LLexer.Free;
  end;
  ResetState;
end;

procedure TDoomScriptCompiler.ResetState;
begin
  FScope := FProgram.DefNamespace;
  FBaseType := nil;
  FCallThread := False;
  FLoopDepth := 0;
  FEof := False;
  FBraceDepth := 0;
  FImmediateType := nil;
  FCurrentLineNumber := 0;
  FCurrentFileNumber := 0;
  FConsole := False;
  FImmediate := Default(TDoomScriptEval);
end;

function TDoomScriptCompiler.TypeOf(const AKind: TDoomScriptEType): TDoomScriptTypeDef;
begin
  Result := FProgram.BuiltinType(AKind);
end;

function TDoomScriptCompiler.FloatAt(const ADef: TDoomScriptVarDef): Single;
begin
  Result := PSingle(FProgram.GlobalPtr(ADef.Value, 4))^;
end;

function TDoomScriptCompiler.IntAt(const ADef: TDoomScriptVarDef): Integer;
begin
  Result := PInteger(FProgram.GlobalPtr(ADef.Value, 4))^;
end;

procedure TDoomScriptCompiler.Error(const AFormat: string; const AArgs: array of const);
begin
  raise EDoomScriptCompileError.CreateFmt(AFormat, AArgs);
end;

procedure TDoomScriptCompiler.Error(const AText: string);
begin
  raise EDoomScriptCompileError.Create(AText);
end;

function TDoomScriptCompiler.VirtualFunctionConstant(const AFunc: TDoomScriptVarDef): TDoomScriptVarDef;
var
  LEval: TDoomScriptEval;
begin
  LEval := Default(TDoomScriptEval);
  LEval.IntValue := AFunc.Scope.TypeDef.GetFunctionNumber(AFunc.FunctionPtr);
  if LEval.IntValue < 0 then
    Error('Function ''%s'' not found in scope ''%s''', [string(AFunc.Name), string(AFunc.Scope.Name)]);
  Result := GetImmediate(TypeOf(evVirtualFunction), LEval, '');
end;

function TDoomScriptCompiler.SizeConstant(const ASize: Integer): TDoomScriptVarDef;
var
  LEval: TDoomScriptEval;
begin
  LEval := Default(TDoomScriptEval);
  LEval.IntValue := ASize;
  Result := GetImmediate(TypeOf(evArgSize), LEval, '');
end;

function TDoomScriptCompiler.JumpConstant(const AValue: Integer): TDoomScriptVarDef;
var
  LEval: TDoomScriptEval;
begin
  LEval := Default(TDoomScriptEval);
  LEval.IntValue := AValue;
  Result := GetImmediate(TypeOf(evJumpOffset), LEval, '');
end;

function TDoomScriptCompiler.JumpDef(const AJumpFrom, AJumpTo: Integer): TDoomScriptVarDef;
begin
  Result := JumpConstant(AJumpTo - AJumpFrom);
end;

function TDoomScriptCompiler.JumpTo(const AJumpTo: Integer): TDoomScriptVarDef;
begin
  Result := JumpDef(FProgram.NumStatements, AJumpTo);
end;

function TDoomScriptCompiler.JumpFrom(const AJumpFrom: Integer): TDoomScriptVarDef;
begin
  Result := JumpDef(AJumpFrom, FProgram.NumStatements);
end;

function TDoomScriptCompiler.Divide(const ANumerator, ADenominator: Single): Single;
begin
  if not TDoomScriptConvert.FloatNonZero(ADenominator) then
    Error('Divide by zero');
  Result := ANumerator / ADenominator;
end;

function TDoomScriptCompiler.Modulo(const ANumerator, ADenominator: Single): Single;
var
  LA: Integer;
  LB: Integer;
begin
  LA := TDoomScriptConvert.FloatToInt(ANumerator);
  LB := TDoomScriptConvert.FloatToInt(ADenominator);
  // the original divides the integers without a check: a crash of the compiler
  if LB = 0 then
    Error('Divide by zero');
  if LB = -1 then
    Result := 0
  else
    Result := LA mod LB;
end;

function TDoomScriptCompiler.FindImmediate(const AType: TDoomScriptTypeDef; const AEval: TDoomScriptEval;
  const AText: AnsiString): TDoomScriptVarDef;
var
  LDef: TDoomScriptVarDef;
  LVector: PSingle;
begin
  // check for a constant with the same value
  LDef := FProgram.GetDefList(IMMEDIATE_NAME);
  while Assigned(LDef) do
  begin
    if LDef.TypeDef = AType then
      case AType.Kind of
        evField, evEntity:
          if IntAt(LDef) = AEval.IntValue then
            Exit(LDef);
        evArgSize, evJumpOffset, evVirtualFunction:
          if LDef.Value = AEval.IntValue then
            Exit(LDef);
        evString:
          if TDoomScriptMemory.ReadString(FProgram.GlobalPtr(LDef.Value, DS_MAX_STRING_LEN)) = AText then
            Exit(LDef);
        evFloat:
          if TDoomScriptConvert.FloatEq(FloatAt(LDef), AEval.FloatValue) then
            Exit(LDef);
        evVector:
          begin
            LVector := PSingle(FProgram.GlobalPtr(LDef.Value, 12));
            if (LVector^ = AEval.Vector[0]) and (PSingle(PByte(LVector) + 4)^ = AEval.Vector[1]) and
              (PSingle(PByte(LVector) + 8)^ = AEval.Vector[2]) then
              Exit(LDef);
          end;
      else
        Error('weird immediate type');
      end;
    LDef := LDef.Next;
  end;
  Result := nil;
end;

function TDoomScriptCompiler.GetImmediate(const AType: TDoomScriptTypeDef; const AEval: TDoomScriptEval;
  const AText: AnsiString): TDoomScriptVarDef;
begin
  Result := FindImmediate(AType, AEval, AText);
  if Assigned(Result) then
    Inc(Result.NumUsers)
  else
  begin
    // allocate a new def
    Result := FProgram.AllocDef(AType, IMMEDIATE_NAME, FProgram.DefNamespace, True);
    if AType.Kind = evString then
      FProgram.SetDefString(Result, AText, True)
    else
      FProgram.SetDefValue(Result, AEval, True);
  end;
end;

function TDoomScriptCompiler.OptimizeOpcode(const AOp: Integer; const AVarA, AVarB: TDoomScriptVarDef): TDoomScriptVarDef;
var
  LC: TDoomScriptEval;
  LType: TDoomScriptTypeDef;
  LVecA: TIdVec3;
  LVecB: TIdVec3;
  LVecC: TIdVec3;

  function FA: Single;
  begin
    Result := FloatAt(AVarA);
  end;

  function FB: Single;
  begin
    Result := FloatAt(AVarB);
  end;

  function IA: Integer;
  begin
    Result := TDoomScriptConvert.FloatToInt(FloatAt(AVarA));
  end;

  function IB: Integer;
  begin
    Result := TDoomScriptConvert.FloatToInt(FloatAt(AVarB));
  end;

  procedure LoadA;
  begin
    Move(FProgram.GlobalPtr(AVarA.Value, 12)^, LVecA, 12);
  end;

  procedure LoadB;
  begin
    Move(FProgram.GlobalPtr(AVarB.Value, 12)^, LVecB, 12);
  end;

  procedure SetBool(const AValue: Boolean);
  begin
    if AValue then
      LC.FloatValue := 1
    else
      LC.FloatValue := 0;
    LType := TypeOf(evFloat);
  end;

  procedure SetFloat(const AValue: Single);
  begin
    LC.FloatValue := AValue;
    LType := TypeOf(evFloat);
  end;

  procedure SetVector;
  begin
    LC.Vector[0] := LVecC.X;
    LC.Vector[1] := LVecC.Y;
    LC.Vector[2] := LVecC.Z;
    LType := TypeOf(evVector);
  end;

begin
  if Assigned(AVarA) and (AVarA.Initialized <> diInitializedConstant) then
    Exit(nil);
  if Assigned(AVarB) and (AVarB.Initialized <> diInitializedConstant) then
    Exit(nil);
  LC := Default(TDoomScriptEval);
  LType := nil;
  // an operator that needs an operand the statement does not have cannot be folded
  case AOp of
    OP_ADD_F, OP_ADD_V, OP_SUB_F, OP_SUB_V, OP_MUL_F, OP_MUL_V, OP_MUL_FV, OP_MUL_VF, OP_DIV_F, OP_MOD_F, OP_BITAND,
    OP_BITOR, OP_GE, OP_LE, OP_GT, OP_LT, OP_AND, OP_OR, OP_EQ_F, OP_EQ_V, OP_EQ_E, OP_NE_F, OP_NE_V, OP_NE_E,
    OP_UADD_F, OP_USUB_F, OP_UMUL_F, OP_UDIV_F, OP_UMOD_F, OP_UOR_F, OP_UAND_F:
      if (not Assigned(AVarA)) or not Assigned(AVarB) then
        Exit(nil);
    OP_NOT_BOOL, OP_NOT_F, OP_NOT_V, OP_NEG_F, OP_NEG_V, OP_INT_F, OP_UINC_F, OP_UDEC_F, OP_COMP_F:
      if not Assigned(AVarA) then
        Exit(nil);
  end;
  case AOp of
    OP_ADD_F: SetFloat(FA + FB);
    OP_ADD_V: begin LoadA; LoadB; LVecC := LVecA + LVecB; SetVector; end;
    OP_SUB_F: SetFloat(FA - FB);
    OP_SUB_V: begin LoadA; LoadB; LVecC := LVecA - LVecB; SetVector; end;
    OP_MUL_F: SetFloat(FA * FB);
    OP_MUL_V: begin LoadA; LoadB; SetFloat(LVecA * LVecB); end;
    OP_MUL_FV: begin LoadB; LVecC := LVecB * FA; SetVector; end;
    OP_MUL_VF: begin LoadA; LVecC := LVecA * FB; SetVector; end;
    OP_DIV_F: SetFloat(Divide(FA, FB));
    OP_MOD_F: SetFloat(Modulo(FA, FB));
    OP_BITAND: SetFloat(IA and IB);
    OP_BITOR: SetFloat(IA or IB);
    OP_GE: SetBool(TDoomScriptConvert.FloatLe(FB, FA));
    OP_LE: SetBool(TDoomScriptConvert.FloatLe(FA, FB));
    OP_GT: SetBool(TDoomScriptConvert.FloatLt(FB, FA));
    OP_LT: SetBool(TDoomScriptConvert.FloatLt(FA, FB));
    OP_AND: SetBool(TDoomScriptConvert.FloatNonZero(FA) and TDoomScriptConvert.FloatNonZero(FB));
    OP_OR: SetBool(TDoomScriptConvert.FloatNonZero(FA) or TDoomScriptConvert.FloatNonZero(FB));
    OP_NOT_BOOL:
      begin
        LC.IntValue := Ord(IntAt(AVarA) = 0);
        LType := TypeOf(evBoolean);
      end;
    OP_NOT_F: SetBool(not TDoomScriptConvert.FloatNonZero(FA));
    OP_NOT_V: begin LoadA; SetBool((LVecA.X = 0) and (LVecA.Y = 0) and (LVecA.Z = 0)); end;
    OP_NEG_F: SetFloat(-FA);
    OP_NEG_V: begin LoadA; LVecC := -LVecA; SetVector; end;
    OP_INT_F: SetFloat(IA);
    OP_EQ_F: SetBool(TDoomScriptConvert.FloatEq(FA, FB));
    OP_EQ_V: begin LoadA; LoadB; SetBool((LVecA.X = LVecB.X) and (LVecA.Y = LVecB.Y) and (LVecA.Z = LVecB.Z)); end;
    OP_EQ_E: SetBool(IntAt(AVarA) = IntAt(AVarB));
    OP_NE_F: SetBool(not TDoomScriptConvert.FloatEq(FA, FB));
    OP_NE_V:
      begin
        LoadA;
        LoadB;
        SetBool(not ((LVecA.X = LVecB.X) and (LVecA.Y = LVecB.Y) and (LVecA.Z = LVecB.Z)));
      end;
    OP_NE_E: SetBool(IntAt(AVarA) <> IntAt(AVarB));
    OP_UADD_F: SetFloat(FB + FA);
    OP_USUB_F: SetFloat(FB - FA);
    OP_UMUL_F: SetFloat(FB * FA);
    OP_UDIV_F: SetFloat(Divide(FB, FA));
    OP_UMOD_F: SetFloat(Modulo(FB, FA));
    OP_UOR_F: SetFloat(IB or IA);
    OP_UAND_F: SetFloat(IB and IA);
    OP_UINC_F: SetFloat(FA + 1);
    OP_UDEC_F: SetFloat(FA - 1);
    OP_COMP_F: SetFloat(not IA);
  end;
  if not Assigned(LType) then
    Exit(nil);
  if Assigned(AVarA) then
  begin
    Dec(AVarA.NumUsers);
    if AVarA.NumUsers <= 0 then
      FProgram.FreeDef(AVarA, nil);
  end;
  if Assigned(AVarB) then
  begin
    Dec(AVarB.NumUsers);
    if AVarB.NumUsers <= 0 then
      FProgram.FreeDef(AVarB, nil);
  end;
  Result := GetImmediate(LType, LC, '');
end;

function TDoomScriptCompiler.EmitOpcode(const AOp: Integer; const AVarA, AVarB: TDoomScriptVarDef): TDoomScriptVarDef;
var
  LIndex: Integer;
  LStatement: PDoomScriptStatement;
  LVarC: TDoomScriptVarDef;
begin
  LVarC := OptimizeOpcode(AOp, AVarA, AVarB);
  if Assigned(LVarC) then
    Exit(LVarC);
  if Assigned(AVarA) and (AVarA.Name = DS_RESULT_STRING) then
    Inc(AVarA.NumUsers);
  if Assigned(AVarB) and (AVarB.Name = DS_RESULT_STRING) then
    Inc(AVarB.NumUsers);
  LIndex := FProgram.AllocStatement;
  if (DoomScriptOpcodes[AOp].TypeC = evVoid) or DoomScriptOpcodes[AOp].RightAssociative then
    // ifs, gotos, and assignments don't need vars allocated
    LVarC := nil
  else
  begin
    // allocate result space, reusing result defs as much as possible
    LVarC := FProgram.FindFreeResultDef(TypeOf(DoomScriptOpcodes[AOp].TypeC), DS_RESULT_STRING, FScope, AVarA,
      AVarB);
    // set user count back to 1, a result def needs to be used twice before it can be reused
    LVarC.NumUsers := 1;
  end;
  LStatement := FProgram.GetStatement(LIndex);
  LStatement.LineNumber := Word(FCurrentLineNumber);
  LStatement.FileNum := Word(FCurrentFileNumber);
  LStatement.Op := AOp;
  LStatement.A := AVarA;
  LStatement.B := AVarB;
  LStatement.C := LVarC;
  if DoomScriptOpcodes[AOp].RightAssociative then
    Result := AVarA
  else
    Result := LVarC;
end;

function TDoomScriptCompiler.EmitPush(const AExpression: TDoomScriptVarDef; const AFuncArg: TDoomScriptTypeDef): Boolean;
var
  LOp: Integer;
  LOut: Integer;
begin
  LOut := -1;
  LOp := OP_PUSH_F;
  while (LOp < NUM_OPCODES) and (DoomScriptOpcodes[LOp].Name = '<PUSH>') do
  begin
    if (AFuncArg.Kind = DoomScriptOpcodes[LOp].TypeA) and (AExpression.Kind = DoomScriptOpcodes[LOp].TypeB) then
    begin
      LOut := LOp;
      Break;
    end;
    Inc(LOp);
  end;
  if LOut < 0 then
  begin
    if (AExpression.TypeDef <> AFuncArg) and not AExpression.TypeDef.Inherits(AFuncArg) then
      Exit(False);
    LOut := OP_PUSH_ENT;
  end;
  EmitOpcode(LOut, AExpression, nil);
  Result := True;
end;

procedure TDoomScriptCompiler.NextToken;
var
  LIndex: Integer;
  LLexer: TIdLexer;
  LToken2: TIdToken;
begin
  // reset our type
  FImmediateType := nil;
  FImmediate := Default(TDoomScriptEval);
  // save the token's line number and filename since when we emit opcodes the current token is always
  // the next one to be read
  FCurrentLineNumber := FToken.Line;
  FCurrentFileNumber := FProgram.GetFilenum(FParser.FileName);
  if not FParser.ReadToken(FToken) then
  begin
    FEof := True;
    Exit;
  end;
  if FCurrentFileNumber <> FProgram.GetFilenum(FParser.FileName) then
    if (FBraceDepth > 0) and not FToken.IsText('}') then
    begin
      // missing a closing brace.  try to give as much info as possible.
      if FScope.Kind = evFunction then
        Error('Unexpected end of file inside function ''%s''.  Missing closing braces.', [string(FScope.Name)])
      else if FScope.Kind = evObject then
        Error('Unexpected end of file inside object ''%s''.  Missing closing braces.', [string(FScope.Name)])
      else if FScope.Kind = evNamespace then
        Error('Unexpected end of file inside namespace ''%s''.  Missing closing braces.', [string(FScope.Name)])
      else
        Error('Unexpected end of file inside braced section');
    end;
  case FToken.TokenType of
    TT_STRING:
      // handle quoted strings as a unit
      FImmediateType := TypeOf(evString);
    TT_LITERAL:
      begin
        // handle quoted vectors as a unit
        FImmediateType := TypeOf(evVector);
        LLexer := TIdLexer.Create(LEXFL_NOERRORS);
        try
          LLexer.LoadMemory(FToken.Text, Length(FToken.Text), FParser.FileName);
          LToken2 := TIdToken.Create;
          for LIndex := 0 to 2 do
          begin
            if not LLexer.ReadToken(LToken2) then
              Error('Couldn''t read vector. ''%s'' is not in the form of ''x y z''', [string(FToken.Text)]);
            if (LToken2.TokenType = TT_PUNCTUATION) and LToken2.IsText('-') then
            begin
              if not LLexer.CheckTokenType(TT_NUMBER, 0, LToken2) then
                Error('expected a number following ''-'' but found ''%s'' in vector ''%s''',
                  [string(LToken2.Text), string(FToken.Text)]);
              FImmediate.Vector[LIndex] := -LToken2.GetFloatValue;
            end
            else if LToken2.TokenType = TT_NUMBER then
              FImmediate.Vector[LIndex] := LToken2.GetFloatValue
            else
              Error('vector ''%s'' is not in the form of ''x y z''.  expected float value, found ''%s''',
                [string(FToken.Text), string(LToken2.Text)]);
          end;
        finally
          LLexer.Free;
        end;
      end;
    TT_NUMBER:
      begin
        FImmediateType := TypeOf(evFloat);
        FImmediate.FloatValue := FToken.GetFloatValue;
      end;
    TT_PUNCTUATION:
      begin
        // entity names
        if FToken.IsText('$') then
        begin
          FImmediateType := TypeOf(evEntity);
          FParser.ReadToken(FToken);
          Exit;
        end;
        if FToken.IsText('{') then
        begin
          Inc(FBraceDepth);
          Exit;
        end;
        if FToken.IsText('}') then
        begin
          Dec(FBraceDepth);
          Exit;
        end;
        if (FToken.SubType >= 0) and (FToken.SubType < 256) and FPunctuationValid[FToken.SubType] then
          Exit;
        Error('Unknown punctuation ''%s''', [string(FToken.Text)]);
      end;
    TT_NAME:
      ;
  else
    Error('Unknown token ''%s''', [string(FToken.Text)]);
  end;
end;

procedure TDoomScriptCompiler.ExpectToken(const AText: AnsiString);
begin
  if not FToken.IsText(AText) then
    Error('expected ''%s'', found ''%s''', [string(AText), string(FToken.Text)]);
  NextToken;
end;

function TDoomScriptCompiler.CheckToken(const AText: AnsiString): Boolean;
begin
  if not FToken.IsText(AText) then
    Exit(False);
  NextToken;
  Result := True;
end;

function TDoomScriptCompiler.ParseName: AnsiString;
begin
  if FToken.TokenType <> TT_NAME then
    Error('''%s'' is not a name', [string(FToken.Text)]);
  Result := FToken.Text;
  NextToken;
end;

function TDoomScriptCompiler.CheckType: TDoomScriptTypeDef;
begin
  if FToken.IsText('float') then
    Result := TypeOf(evFloat)
  else if FToken.IsText('vector') then
    Result := TypeOf(evVector)
  else if FToken.IsText('entity') then
    Result := TypeOf(evEntity)
  else if FToken.IsText('string') then
    Result := TypeOf(evString)
  else if FToken.IsText('void') then
    Result := TypeOf(evVoid)
  else if FToken.IsText('object') then
    Result := TypeOf(evObject)
  else if FToken.IsText('boolean') then
    Result := TypeOf(evBoolean)
  else if FToken.IsText('namespace') then
    Result := TypeOf(evNamespace)
  else if FToken.IsText('scriptEvent') then
    Result := TypeOf(evScriptEvent)
  else
  begin
    Result := FProgram.FindType(FToken.Text);
    if Assigned(Result) and not Result.IsObject then
      Result := nil;
  end;
end;

function TDoomScriptCompiler.ParseType: TDoomScriptTypeDef;
begin
  Result := CheckType;
  if not Assigned(Result) then
    Error('"%s" is not a type', [string(FToken.Text)]);
  if (Result = TypeOf(evScriptEvent)) and (FScope <> FProgram.DefNamespace) then
    Error('scriptEvents can only defined in the global namespace');
  if (Result = TypeOf(evNamespace)) and (FScope.Kind <> evNamespace) then
    Error('A namespace may only be defined globally, or within another namespace');
  NextToken;
end;

function TDoomScriptCompiler.ParseImmediate: TDoomScriptVarDef;
begin
  Result := GetImmediate(FImmediateType, FImmediate, FToken.Text);
  NextToken;
end;

function TDoomScriptCompiler.EmitFunctionParms(const AOp: Integer; const AFunc: TDoomScriptVarDef; const AStartArg,
  AStartSize: Integer; const AObject: TDoomScriptVarDef): TDoomScriptVarDef;
var
  LExpression: TDoomScriptVarDef;
  LType: TDoomScriptTypeDef;
  LFuncArg: TDoomScriptTypeDef;
  LReturnDef: TDoomScriptVarDef;
  LReturnType: TDoomScriptTypeDef;
  LArg: Integer;
  LSize: Integer;
  LResultOp: Integer;
  LStatement: PDoomScriptStatement;
  LResultDef: TDoomScriptVarDef;
begin
  LType := AFunc.TypeDef;
  if AFunc.Kind <> evFunction then
    Error('''%s'' is not a function', [string(AFunc.Name)]);
  // copy the parameters to the global parameter variables
  LArg := AStartArg;
  LSize := AStartSize;
  if not CheckToken(')') then
  begin
    repeat
      if LArg >= LType.NumParameters then
        Error('too many parameters');
      LExpression := GetExpression(DS_TOP_PRIORITY);
      LFuncArg := LType.GetParmType(LArg);
      if not EmitPush(LExpression, LFuncArg) then
        Error('type mismatch on parm %d of call to ''%s''', [LArg + 1, string(AFunc.Name)]);
      if LFuncArg.Kind = evObject then
        Inc(LSize, 4)
      else
        Inc(LSize, LFuncArg.Size);
      Inc(LArg);
    until not CheckToken(',');
    ExpectToken(')');
  end;
  if LArg < LType.NumParameters then
    Error('too few parameters for function ''%s''', [string(AFunc.Name)]);
  if AOp = OP_CALL then
    EmitOpcode(AOp, AFunc, nil)
  else if (AOp = OP_OBJECTCALL) or (AOp = OP_OBJTHREAD) then
  begin
    EmitOpcode(AOp, AObject, VirtualFunctionConstant(AFunc));
    // need arg size seperate since script object may be NULL
    LStatement := FProgram.GetStatement(FProgram.NumStatements - 1);
    LStatement.C := SizeConstant(AFunc.FunctionPtr.ParmTotal);
  end
  else
    EmitOpcode(AOp, AFunc, SizeConstant(LSize));
  // we need to copy off the result into a temporary result location, so figure out the opcode
  LReturnType := LType.ReturnType;
  if LReturnType.Kind = evString then
  begin
    LResultOp := OP_STORE_S;
    LReturnDef := FProgram.ReturnStringDef;
  end
  else
  begin
    FProgram.ReturnDef.TypeDef := LReturnType;
    LReturnDef := FProgram.ReturnDef;
    LResultOp := OP_STORE_OBJ;
    case LReturnType.Kind of
      evVoid, evFloat:
        LResultOp := OP_STORE_F;
      evBoolean:
        LResultOp := OP_STORE_BOOL;
      evVector:
        LResultOp := OP_STORE_V;
      evEntity:
        LResultOp := OP_STORE_ENT;
      evObject:
        LResultOp := OP_STORE_OBJ;
    else
      Error('Invalid return type for function ''%s''', [string(AFunc.Name)]);
    end;
  end;
  if LReturnType.Kind = evVoid then
    // don't need result space since there's no result, so just return the normal result def.
    Exit(LReturnDef);
  // allocate result space, reusing result defs as much as possible
  LStatement := FProgram.GetStatement(FProgram.NumStatements - 1);
  LResultDef := FProgram.FindFreeResultDef(LReturnType, DS_RESULT_STRING, FScope, LStatement.A, LStatement.B);
  // set user count back to 0, a result def needs to be used twice before it can be reused
  LResultDef.NumUsers := 0;
  EmitOpcode(LResultOp, LReturnDef, LResultDef);
  Result := LResultDef;
end;

function TDoomScriptCompiler.ParseFunctionCall(const AFuncDef: TDoomScriptVarDef): TDoomScriptVarDef;
var
  LThisDef: TDoomScriptVarDef;
begin
  Result := nil;
  if AFuncDef.Kind <> evFunction then
    Error('''%s'' is not a function', [string(AFuncDef.Name)]);
  if AFuncDef.Initialized = diUninitialized then
    Error('Function ''%s'' has not been defined yet', [string(AFuncDef.GlobalName)]);
  if FCallThread then
  begin
    if (AFuncDef.Initialized <> diUninitialized) and Assigned(AFuncDef.FunctionPtr.EventDef) then
      Error('Built-in functions cannot be called as threads');
    FCallThread := False;
    Result := EmitFunctionParms(OP_THREAD, AFuncDef, 0, 0, nil);
  end
  else
  begin
    if (AFuncDef.Initialized <> diUninitialized) and Assigned(AFuncDef.FunctionPtr.EventDef) then
    begin
      if (FScope.Kind <> evNamespace) and (FScope.Scope.Kind = evObject) then
      begin
        // get the local object pointer
        LThisDef := FProgram.GetDef(FScope.Scope.TypeDef, 'self', FScope);
        if not Assigned(LThisDef) then
          Error('No ''self'' within scope');
        Exit(ParseEventCall(LThisDef, AFuncDef));
      end
      else
        Error('Built-in functions cannot be called without an object');
    end;
    Result := EmitFunctionParms(OP_CALL, AFuncDef, 0, 0, nil);
  end;
end;

function TDoomScriptCompiler.ParseObjectCall(const AObject, AFunc: TDoomScriptVarDef): TDoomScriptVarDef;
begin
  EmitPush(AObject, AObject.TypeDef);
  if FCallThread then
  begin
    FCallThread := False;
    Result := EmitFunctionParms(OP_OBJTHREAD, AFunc, 1, 4, AObject);
  end
  else
    Result := EmitFunctionParms(OP_OBJECTCALL, AFunc, 1, 0, AObject);
end;

function TDoomScriptCompiler.ParseEventCall(const AObject, AFuncDef: TDoomScriptVarDef): TDoomScriptVarDef;
begin
  if FCallThread then
    Error('Cannot call built-in functions as a thread');
  if AFuncDef.Kind <> evFunction then
    Error('''%s'' is not a function', [string(AFuncDef.Name)]);
  if (not Assigned(AFuncDef.FunctionPtr)) or not Assigned(AFuncDef.FunctionPtr.EventDef) then
    Error('"%s" cannot be called with object notation', [string(AFuncDef.Name)]);
  if AObject.Kind = evObject then
    EmitPush(AObject, TypeOf(evEntity))
  else
    EmitPush(AObject, AObject.TypeDef);
  Result := EmitFunctionParms(OP_EVENTCALL, AFuncDef, 0, 4, nil);
end;

function TDoomScriptCompiler.ParseSysObjectCall(const AFuncDef: TDoomScriptVarDef): TDoomScriptVarDef;
begin
  if FCallThread then
    Error('Cannot call built-in functions as a thread');
  if AFuncDef.Kind <> evFunction then
    Error('''%s'' is not a function', [string(AFuncDef.Name)]);
  if (not Assigned(AFuncDef.FunctionPtr)) or not Assigned(AFuncDef.FunctionPtr.EventDef) then
    Error('"%s" cannot be called with object notation', [string(AFuncDef.Name)]);
  if not FSysClass.RespondsTo(AFuncDef.FunctionPtr.EventDef) then
    Error('"%s" is not callable as a ''sys'' function', [string(AFuncDef.Name)]);
  Result := EmitFunctionParms(OP_SYSCALL, AFuncDef, 0, 0, nil);
end;

function TDoomScriptCompiler.LookupDef(const AName: AnsiString; const ABaseObj: TDoomScriptVarDef): TDoomScriptVarDef;
var
  LDef: TDoomScriptVarDef;
  LField: TDoomScriptVarDef;
  LThisDef: TDoomScriptVarDef;
  LTypeDef: TDoomScriptVarDef;
  LTypeB: TDoomScriptEType;
  LTypeC: TDoomScriptEType;
  LOp: Integer;
begin
  LDef := nil;
  // check if we're accessing a field
  if Assigned(ABaseObj) and (ABaseObj.Kind = evObject) then
  begin
    LTypeDef := ABaseObj;
    while Assigned(LTypeDef) and (LTypeDef <> FProgram.DefObject) do
    begin
      LDef := FProgram.GetDef(nil, AName, LTypeDef);
      if Assigned(LDef) then
        Break;
      LTypeDef := LTypeDef.TypeDef.SuperClass.Def;
    end;
  end
  else
  begin
    // first look through the defs in our scope
    LDef := FProgram.GetDef(nil, AName, FScope);
    if not Assigned(LDef) then
      // if we're in a member function, check types local to the object
      if (FScope.Kind <> evNamespace) and (FScope.Scope.Kind = evObject) then
      begin
        // get the local object pointer
        LThisDef := FProgram.GetDef(FScope.Scope.TypeDef, 'self', FScope);
        LField := LookupDef(AName, FScope.Scope.TypeDef.Def);
        if not Assigned(LField) then
          Error('Unknown value "%s"', [string(AName)]);
        // type check
        LTypeB := LField.Kind;
        if LField.Kind = evFunction then
          LTypeC := LField.TypeDef.ReturnType.Kind
        else
        begin
          // field access gets type from field
          LTypeC := LField.TypeDef.FieldType.Kind;
          if CheckToken('++') then
          begin
            if LTypeC <> evFloat then
              Error('Invalid type for ++');
            Exit(EmitOpcode(OP_UINCP_F, LThisDef, LField));
          end
          else if CheckToken('--') then
          begin
            if LTypeC <> evFloat then
              Error('Invalid type for --');
            Exit(EmitOpcode(OP_UDECP_F, LThisDef, LField));
          end;
        end;
        LOp := OP_INDIRECT_F;
        while (DoomScriptOpcodes[LOp].TypeA <> evObject) or (LTypeB <> DoomScriptOpcodes[LOp].TypeB) or
          (LTypeC <> DoomScriptOpcodes[LOp].TypeC) do
        begin
          if (DoomScriptOpcodes[LOp].Priority = DS_FUNCTION_PRIORITY) and (DoomScriptOpcodes[LOp].TypeA = evObject) and
            (DoomScriptOpcodes[LOp].TypeC = evVoid) and (LTypeC <> DoomScriptOpcodes[LOp].TypeC) then
            // catches object calls that return a value
            Break;
          Inc(LOp);
          if (LOp >= NUM_OPCODES) or (DoomScriptOpcodes[LOp].Name <> '.') then
            // the argument of the message raises its own error for a type that is not an object
            Error('no valid opcode to access type ''%s''', [string(LField.TypeDef.SuperClass.Name)]);
        end;
        if LOp = OP_OBJECTCALL then
        begin
          ExpectToken('(');
          LDef := ParseObjectCall(LThisDef, LField);
        end
        else
        begin
          // emit the conversion opcode
          LDef := EmitOpcode(LOp, LThisDef, LField);
          // field access gets type from field
          LDef.TypeDef := LField.TypeDef.FieldType;
        end;
      end;
  end;
  Result := LDef;
end;

function TDoomScriptCompiler.ParseValue: TDoomScriptVarDef;
var
  LDef: TDoomScriptVarDef;
  LNamespaceDef: TDoomScriptVarDef;
  LName: AnsiString;
begin
  if FImmediateType = TypeOf(evEntity) then
  begin
    // if an immediate entity ($-prefaced name) then create or lookup a def for it.
    // when entities are spawned, they'll lookup the def and point it to them.
    LName := '$' + FToken.Text;
    LDef := FProgram.GetDef(TypeOf(evEntity), LName, FProgram.DefNamespace);
    if not Assigned(LDef) then
      LDef := FProgram.AllocDef(TypeOf(evEntity), LName, FProgram.DefNamespace, True);
    NextToken;
    Exit(LDef);
  end
  else if Assigned(FImmediateType) then
    // if the token is an immediate, allocate a constant for it
    Exit(ParseImmediate);
  LName := ParseName;
  LDef := LookupDef(LName, FBaseType);
  if not Assigned(LDef) then
  begin
    if Assigned(FBaseType) then
      Error('%s is not a member of %s', [string(LName), string(FBaseType.TypeDef.Name)])
    else
      Error('Unknown value "%s"', [string(LName)]);
  end
  else
    // if namespace, then look up the variable in that namespace
    while LDef.Kind = evNamespace do
    begin
      ExpectToken('::');
      LName := ParseName;
      LNamespaceDef := LDef;
      LDef := FProgram.GetDef(nil, LName, LNamespaceDef);
      if not Assigned(LDef) then
        Error('Unknown value "%s::%s"', [string(LNamespaceDef.GlobalName), string(LName)]);
    end;
  Result := LDef;
end;

function TDoomScriptCompiler.GetTerm: TDoomScriptVarDef;
var
  LExpression: TDoomScriptVarDef;
  LOp: Integer;
begin
  if (not Assigned(FImmediateType)) and CheckToken('~') then
  begin
    LExpression := GetExpression(DS_TILDE_PRIORITY);
    if LExpression.Kind <> evFloat then
      Error('type mismatch for ~');
    Exit(EmitOpcode(OP_COMP_F, LExpression, nil));
  end;
  if (not Assigned(FImmediateType)) and CheckToken('!') then
  begin
    LExpression := GetExpression(DS_NOT_PRIORITY);
    LOp := OP_NOT_F;
    case LExpression.Kind of
      evBoolean:
        LOp := OP_NOT_BOOL;
      evFloat:
        LOp := OP_NOT_F;
      evString:
        LOp := OP_NOT_S;
      evVector:
        LOp := OP_NOT_V;
      evEntity, evObject:
        LOp := OP_NOT_ENT;
      evFunction:
        Error('Invalid type for !');
    else
      Error('type mismatch for !');
    end;
    Exit(EmitOpcode(LOp, LExpression, nil));
  end;
  // check for negation operator
  if (not Assigned(FImmediateType)) and CheckToken('-') then
  begin
    // constants are directly negated without an instruction
    if FImmediateType = TypeOf(evFloat) then
    begin
      FImmediate.FloatValue := -FImmediate.FloatValue;
      Exit(ParseImmediate);
    end
    else if FImmediateType = TypeOf(evVector) then
    begin
      FImmediate.Vector[0] := -FImmediate.Vector[0];
      FImmediate.Vector[1] := -FImmediate.Vector[1];
      FImmediate.Vector[2] := -FImmediate.Vector[2];
      Exit(ParseImmediate);
    end
    else
    begin
      LExpression := GetExpression(DS_NOT_PRIORITY);
      LOp := OP_NEG_F;
      case LExpression.Kind of
        evFloat:
          LOp := OP_NEG_F;
        evVector:
          LOp := OP_NEG_V;
      else
        Error('type mismatch for -');
      end;
      Exit(EmitOpcode(LOp, LExpression, nil));
    end;
  end;
  if CheckToken('int') then
  begin
    ExpectToken('(');
    LExpression := GetExpression(DS_INT_PRIORITY);
    if LExpression.Kind <> evFloat then
      Error('type mismatch for int()');
    ExpectToken(')');
    Exit(EmitOpcode(OP_INT_F, LExpression, nil));
  end;
  if CheckToken('thread') then
  begin
    FCallThread := True;
    GetExpression(DS_FUNCTION_PRIORITY);
    if FCallThread then
      Error('Invalid thread call');
    // threads return the thread number
    FProgram.ReturnDef.TypeDef := TypeOf(evFloat);
    Exit(FProgram.ReturnDef);
  end;
  if (not Assigned(FImmediateType)) and CheckToken('(') then
  begin
    LExpression := GetExpression(DS_TOP_PRIORITY);
    ExpectToken(')');
    Exit(LExpression);
  end;
  Result := ParseValue;
end;

function TDoomScriptCompiler.GetExpression(const APriority: Integer): TDoomScriptVarDef;
var
  LOp: Integer;
  LOldOp: Integer;
  LE: TDoomScriptVarDef;
  LE2: TDoomScriptVarDef;
  LOldType: TDoomScriptVarDef;
  LTypeA: TDoomScriptEType;
  LTypeB: TDoomScriptEType;
  LTypeC: TDoomScriptEType;
  LStatement: PDoomScriptStatement;
  LPointed: TDoomScriptEType;

  function Matches: Boolean;
  begin
    Result := (LTypeA = DoomScriptOpcodes[LOp].TypeA) and (LTypeB = DoomScriptOpcodes[LOp].TypeB) and
      ((LTypeC = evVoid) or (LTypeC = DoomScriptOpcodes[LOp].TypeC));
  end;

begin
  if APriority = 0 then
    Exit(GetTerm);
  LE := GetExpression(APriority - 1);
  if FToken.IsText(';') then
    // save us from searching through the opcodes unneccesarily
    Exit(LE);
  while True do
  begin
    if (APriority = DS_FUNCTION_PRIORITY) and CheckToken('(') then
      Exit(ParseFunctionCall(LE));
    // has to be a punctuation
    if Assigned(FImmediateType) then
      Break;
    LOp := 0;
    while LOp < NUM_OPCODES do
    begin
      if (DoomScriptOpcodes[LOp].Priority = APriority) and CheckToken(DoomScriptOpcodes[LOp].Name) then
        Break;
      Inc(LOp);
    end;
    if LOp >= NUM_OPCODES then
      // next token isn't at this priority level
      Break;
    // unary operators act only on the left operand
    if DoomScriptOpcodes[LOp].TypeB = evVoid then
      Exit(EmitOpcode(LOp, LE, nil));
    // preserve our base type
    LOldType := FBaseType;
    // field access needs scope from object
    if (DoomScriptOpcodes[LOp].Name[1] = '.') and LE.TypeDef.IsObject then
      // save off what type this field is part of
      FBaseType := LE.TypeDef.Def;
    if DoomScriptOpcodes[LOp].RightAssociative then
    begin
      // if last statement is an indirect, change it to an address of
      if FProgram.NumStatements > 0 then
      begin
        LStatement := FProgram.GetStatement(FProgram.NumStatements - 1);
        if (LStatement.Op >= OP_INDIRECT_F) and (LStatement.Op < OP_ADDRESS) then
        begin
          LStatement.Op := OP_ADDRESS;
          TypeOf(evPointer).SetPointerType(LE.TypeDef);
          LE.TypeDef := TypeOf(evPointer);
        end;
      end;
      LE2 := GetExpression(APriority);
    end
    else
      LE2 := GetExpression(APriority - 1);
    // restore type
    FBaseType := LOldType;
    // type check
    LTypeA := LE.Kind;
    LTypeB := LE2.Kind;
    // field access gets type from field
    if DoomScriptOpcodes[LOp].Name[1] = '.' then
    begin
      if (LE2.Kind = evFunction) and (LE2.TypeDef.ReturnType <> nil) then
        LTypeC := LE2.TypeDef.ReturnType.Kind
      else if (LE2.TypeDef.FieldType <> nil) then
        LTypeC := LE2.TypeDef.FieldType.Kind
      else
        // not a field
        LTypeC := evError;
    end
    else
      LTypeC := evVoid;
    LOldOp := LOp;
    while not Matches do
    begin
      if (DoomScriptOpcodes[LOp].Priority = DS_FUNCTION_PRIORITY) and (LTypeA = DoomScriptOpcodes[LOp].TypeA) and
        (LTypeB = DoomScriptOpcodes[LOp].TypeB) then
        Break;
      Inc(LOp);
      if (LOp >= NUM_OPCODES) or (DoomScriptOpcodes[LOp].Name <> DoomScriptOpcodes[LOldOp].Name) then
        Error('type mismatch for ''%s''', [string(DoomScriptOpcodes[LOldOp].Name)]);
    end;
    case LOp of
      OP_SYSCALL:
        begin
          ExpectToken('(');
          LE := ParseSysObjectCall(LE2);
        end;
      OP_OBJECTCALL, OP_EVENTCALL:
        begin
          ExpectToken('(');
          if (LE2.Initialized <> diUninitialized) and Assigned(LE2.FunctionPtr) and
            Assigned(LE2.FunctionPtr.EventDef) then
            LE := ParseEventCall(LE, LE2)
          else
            LE := ParseObjectCall(LE, LE2);
        end;
    else
      if FCallThread then
        Error('Expecting function call after ''thread''');
      if LTypeA = evPointer then
      begin
        LPointed := LE.TypeDef.PointerType.Kind;
        if LTypeB <> LPointed then
        begin
          // FIXME: need to make a general case for this
          if (LOp = OP_STOREP_F) and (LPointed = evBoolean) then
            // copy from float to boolean pointer
            LOp := OP_STOREP_FTOBOOL
          else if (LOp = OP_STOREP_BOOL) and (LPointed = evFloat) then
            // copy from boolean to float pointer
            LOp := OP_STOREP_BOOLTOF
          else if (LOp = OP_STOREP_F) and (LPointed = evString) then
            // copy from float to string pointer
            LOp := OP_STOREP_FTOS
          else if (LOp = OP_STOREP_BOOL) and (LPointed = evString) then
            // copy from boolean to string pointer
            LOp := OP_STOREP_BTOS
          else if (LOp = OP_STOREP_V) and (LPointed = evString) then
            // copy from vector to string pointer
            LOp := OP_STOREP_VTOS
          else if (LOp = OP_STOREP_ENT) and (LPointed = evObject) then
            // store an entity into an object pointer
            LOp := OP_STOREP_OBJENT
          else
            Error('type mismatch for ''%s''', [string(DoomScriptOpcodes[LOp].Name)]);
        end;
      end;
      if DoomScriptOpcodes[LOp].RightAssociative then
        LE := EmitOpcode(LOp, LE2, LE)
      else
        LE := EmitOpcode(LOp, LE, LE2);
      if LOp = OP_STOREP_OBJENT then
      begin
        // statement.b points to type_pointer, which is just a temporary that gets its type reassigned, so
        // the real type is stored in statement.c for the type check at run time
        LStatement := FProgram.GetStatement(FProgram.NumStatements - 1);
        LStatement.C := TypeOf(evPointer).PointerType.Def;
      end;
      // field access gets type from field
      if LTypeC <> evVoid then
        LE.TypeDef := LE2.TypeDef.FieldType;
    end;
  end;
  Result := LE;
end;

procedure TDoomScriptCompiler.PatchLoop(const AStart, AContinuePos: Integer);
var
  LIndex: Integer;
  LStatement: PDoomScriptStatement;
begin
  for LIndex := AStart to FProgram.NumStatements - 1 do
  begin
    LStatement := FProgram.GetStatement(LIndex);
    if LStatement.Op = OP_BREAK then
    begin
      LStatement.Op := OP_GOTO;
      LStatement.A := JumpFrom(LIndex);
    end
    else if LStatement.Op = OP_CONTINUE then
    begin
      LStatement.Op := OP_GOTO;
      LStatement.A := JumpDef(LIndex, AContinuePos);
    end;
  end;
end;

procedure TDoomScriptCompiler.ParseReturnStatement;
var
  LExpression: TDoomScriptVarDef;
  LTypeA: TDoomScriptEType;
  LTypeB: TDoomScriptEType;
  LOp: Integer;
  LReturnType: TDoomScriptTypeDef;
begin
  if CheckToken(';') then
  begin
    if FScope.TypeDef.ReturnType.Kind <> evVoid then
      Error('expecting return value');
    EmitOpcode(OP_RETURN, nil, nil);
    Exit;
  end;
  LExpression := GetExpression(DS_TOP_PRIORITY);
  ExpectToken(';');
  LTypeA := LExpression.Kind;
  LTypeB := FScope.TypeDef.ReturnType.Kind;
  if LTypeA = LTypeB then
  begin
    EmitOpcode(OP_RETURN, LExpression, nil);
    Exit;
  end;
  LOp := 0;
  while (LOp < NUM_OPCODES) and (DoomScriptOpcodes[LOp].Name <> '=') do
    Inc(LOp);
  while (LTypeA <> DoomScriptOpcodes[LOp].TypeA) or (LTypeB <> DoomScriptOpcodes[LOp].TypeB) do
  begin
    Inc(LOp);
    if (LOp >= NUM_OPCODES) or (DoomScriptOpcodes[LOp].Name <> '=') then
      Error('type mismatch for return value');
  end;
  LReturnType := FScope.TypeDef.ReturnType;
  if LReturnType.Kind = evString then
    EmitOpcode(LOp, LExpression, FProgram.ReturnStringDef)
  else
  begin
    FProgram.ReturnDef.TypeDef := LReturnType;
    EmitOpcode(LOp, LExpression, FProgram.ReturnDef);
  end;
  EmitOpcode(OP_RETURN, nil, nil);
end;

procedure TDoomScriptCompiler.ParseWhileStatement;
var
  LExpression: TDoomScriptVarDef;
  LPatch1: Integer;
  LPatch2: Integer;
begin
  Inc(FLoopDepth);
  ExpectToken('(');
  LPatch2 := FProgram.NumStatements;
  LExpression := GetExpression(DS_TOP_PRIORITY);
  ExpectToken(')');
  if (LExpression.Initialized = diInitializedConstant) and (IntAt(LExpression) <> 0) then
  begin
    //FIXME: we can completely skip generation of this code in the opposite case
    ParseStatement;
    EmitOpcode(OP_GOTO, JumpTo(LPatch2), nil);
  end
  else
  begin
    LPatch1 := FProgram.NumStatements;
    EmitOpcode(OP_IFNOT, LExpression, nil);
    ParseStatement;
    EmitOpcode(OP_GOTO, JumpTo(LPatch2), nil);
    FProgram.GetStatement(LPatch1).B := JumpFrom(LPatch1);
  end;
  // fixup breaks and continues
  PatchLoop(LPatch2, LPatch2);
  Dec(FLoopDepth);
end;

procedure TDoomScriptCompiler.ParseForStatement;
var
  LExpression: TDoomScriptVarDef;
  LStart: Integer;
  LPatch1: Integer;
  LPatch2: Integer;
  LPatch3: Integer;
  LPatch4: Integer;
begin
  Inc(FLoopDepth);
  LStart := FProgram.NumStatements;
  ExpectToken('(');
  // init
  if not CheckToken(';') then
  begin
    repeat
      GetExpression(DS_TOP_PRIORITY);
    until not CheckToken(',');
    ExpectToken(';');
  end;
  // condition
  LPatch2 := FProgram.NumStatements;
  LExpression := GetExpression(DS_TOP_PRIORITY);
  ExpectToken(';');
  //FIXME: add check for constant expression
  LPatch1 := FProgram.NumStatements;
  EmitOpcode(OP_IFNOT, LExpression, nil);
  // counter
  if not CheckToken(')') then
  begin
    LPatch3 := FProgram.NumStatements;
    EmitOpcode(OP_IF, LExpression, nil);
    LPatch4 := LPatch2;
    LPatch2 := FProgram.NumStatements;
    repeat
      GetExpression(DS_TOP_PRIORITY);
    until not CheckToken(',');
    ExpectToken(')');
    // goto patch4
    EmitOpcode(OP_GOTO, JumpTo(LPatch4), nil);
    // fixup patch3
    FProgram.GetStatement(LPatch3).B := JumpFrom(LPatch3);
  end;
  ParseStatement;
  // goto patch2
  EmitOpcode(OP_GOTO, JumpTo(LPatch2), nil);
  // fixup patch1
  FProgram.GetStatement(LPatch1).B := JumpFrom(LPatch1);
  // fixup breaks and continues
  PatchLoop(LStart, LPatch2);
  Dec(FLoopDepth);
end;

procedure TDoomScriptCompiler.ParseDoWhileStatement;
var
  LExpression: TDoomScriptVarDef;
  LPatch1: Integer;
begin
  Inc(FLoopDepth);
  LPatch1 := FProgram.NumStatements;
  ParseStatement;
  ExpectToken('while');
  ExpectToken('(');
  LExpression := GetExpression(DS_TOP_PRIORITY);
  ExpectToken(')');
  ExpectToken(';');
  EmitOpcode(OP_IF, LExpression, JumpTo(LPatch1));
  // fixup breaks and continues
  PatchLoop(LPatch1, LPatch1);
  Dec(FLoopDepth);
end;

procedure TDoomScriptCompiler.ParseIfStatement;
var
  LExpression: TDoomScriptVarDef;
  LPatch1: Integer;
  LPatch2: Integer;
begin
  ExpectToken('(');
  LExpression := GetExpression(DS_TOP_PRIORITY);
  ExpectToken(')');
  //FIXME: add check for constant expression
  LPatch1 := FProgram.NumStatements;
  EmitOpcode(OP_IFNOT, LExpression, nil);
  ParseStatement;
  if CheckToken('else') then
  begin
    LPatch2 := FProgram.NumStatements;
    EmitOpcode(OP_GOTO, nil, nil);
    FProgram.GetStatement(LPatch1).B := JumpFrom(LPatch1);
    ParseStatement;
    FProgram.GetStatement(LPatch2).A := JumpFrom(LPatch2);
  end
  else
    FProgram.GetStatement(LPatch1).B := JumpFrom(LPatch1);
end;

procedure TDoomScriptCompiler.ParseStatement;
begin
  if CheckToken(';') then
    // skip semicolons, which are harmless and ok syntax
    Exit;
  if CheckToken('{') then
  begin
    repeat
      ParseStatement;
    until CheckToken('}');
    Exit;
  end;
  if CheckToken('return') then
  begin
    ParseReturnStatement;
    Exit;
  end;
  if CheckToken('while') then
  begin
    ParseWhileStatement;
    Exit;
  end;
  if CheckToken('for') then
  begin
    ParseForStatement;
    Exit;
  end;
  if CheckToken('do') then
  begin
    ParseDoWhileStatement;
    Exit;
  end;
  if CheckToken('break') then
  begin
    ExpectToken(';');
    if FLoopDepth = 0 then
      Error('cannot break outside of a loop');
    EmitOpcode(OP_BREAK, nil, nil);
    Exit;
  end;
  if CheckToken('continue') then
  begin
    ExpectToken(';');
    if FLoopDepth = 0 then
      Error('cannot contine outside of a loop');
    EmitOpcode(OP_CONTINUE, nil, nil);
    Exit;
  end;
  if CheckType <> nil then
  begin
    ParseDefs;
    Exit;
  end;
  if CheckToken('if') then
  begin
    ParseIfStatement;
    Exit;
  end;
  GetExpression(DS_TOP_PRIORITY);
  ExpectToken(';');
end;

procedure TDoomScriptCompiler.ParseObjectDef(const AObjName: AnsiString);
var
  LObjType: TDoomScriptTypeDef;
  LType: TDoomScriptTypeDef;
  LParentType: TDoomScriptTypeDef;
  LFieldType: TDoomScriptTypeDef;
  LName: AnsiString;
  LNewType: TDoomScriptTypeDef;
  LOldScope: TDoomScriptVarDef;
  LIndex: Integer;
  LParentSize: Integer;
begin
  LOldScope := FScope;
  if FScope.Kind <> evNamespace then
    Error('Objects cannot be defined within functions or other objects');
  // make sure it doesn't exist before we create it
  if Assigned(FProgram.FindType(AObjName)) then
    Error('''%s'' : redefinition; different basic types', [string(AObjName)]);
  // base type
  if not CheckToken(':') then
    LParentType := TypeOf(evObject)
  else
  begin
    LParentType := ParseType;
    if not LParentType.IsObject then
      Error('Objects may only inherit from objects.');
  end;
  if LParentType = TypeOf(evObject) then
    LParentSize := 0
  else
    LParentSize := LParentType.Size;
  LObjType := FProgram.AllocType(evObject, nil, AObjName, LParentSize, LParentType);
  LObjType.Def := FProgram.AllocDef(LObjType, AObjName, FScope, True);
  FScope := LObjType.Def;
  // inherit all the functions
  for LIndex := 0 to LParentType.NumFunctions - 1 do
    LObjType.AddFunction(LParentType.GetFunction(LIndex));
  ExpectToken('{');
  LNewType := TDoomScriptTypeDef.Create(evField, nil, '', 0, nil);
  try
    repeat
      if CheckToken(';') then
        // skip semicolons, which are harmless and ok syntax
        Continue;
      LFieldType := ParseType;
      LNewType.SetFieldType(LFieldType);
      LNewType.Name := LFieldType.Name + ' field';
      LName := ParseName;
      // check for a function prototype or declaraction
      if CheckToken('(') then
        ParseFunctionDef(LNewType.FieldType, LName)
      else
      begin
        LType := FProgram.GetType(LNewType, True);
        FProgram.AllocDef(LType, LName, FScope, True);
        LObjType.AddField(LType, LName);
        ExpectToken(';');
      end;
    until CheckToken('}');
  finally
    LNewType.Free;
  end;
  FScope := LOldScope;
  ExpectToken(';');
end;

function TDoomScriptCompiler.ParseFunction(const AReturnType: TDoomScriptTypeDef;
  const AName: AnsiString): TDoomScriptTypeDef;
var
  LNewType: TDoomScriptTypeDef;
  LType: TDoomScriptTypeDef;
  LParmName: AnsiString;
begin
  LNewType := TDoomScriptTypeDef.Create(evFunction, nil, AName, 4, AReturnType);
  try
    if FScope.Kind <> evNamespace then
      // create self pointer
      LNewType.AddFunctionParm(FScope.TypeDef, 'self');
    if not CheckToken(')') then
    begin
      repeat
        LType := ParseType;
        LParmName := ParseName;
        LNewType.AddFunctionParm(LType, LParmName);
      until not CheckToken(',');
      ExpectToken(')');
    end;
    Result := FProgram.GetType(LNewType, True);
  finally
    LNewType.Free;
  end;
end;

procedure TDoomScriptCompiler.ParseFunctionDef(const AReturnType: TDoomScriptTypeDef; const AName: AnsiString);
var
  LType: TDoomScriptTypeDef;
  LDef: TDoomScriptVarDef;
  LOldScope: TDoomScriptVarDef;
  LIndex: Integer;
  LNumParms: Integer;
  LParmType: TDoomScriptTypeDef;
  LFunc: TDoomScriptFunction;
  LStatement: PDoomScriptStatement;
  LSuperClass: TDoomScriptTypeDef;
  LSpecial: TDoomScriptFunction;
  LSelfDef: TDoomScriptVarDef;
begin
  if (FScope.Kind <> evNamespace) and not FScope.TypeDef.IsObject then
    Error('Functions may not be defined within other functions');
  LType := ParseFunction(AReturnType, AName);
  LDef := FProgram.GetDef(LType, AName, FScope);
  if not Assigned(LDef) then
  begin
    LDef := FProgram.AllocDef(LType, AName, FScope, True);
    LType.Def := LDef;
    LFunc := FProgram.AllocFunction(LDef);
    if FScope.TypeDef.IsObject then
      FScope.TypeDef.AddFunction(LFunc);
  end
  else
  begin
    LFunc := LDef.FunctionPtr;
    if LFunc.FirstStatement <> 0 then
      Error('%s redeclared', [string(LDef.GlobalName)]);
  end;
  // check if this is a prototype or declaration
  if not CheckToken('{') then
  begin
    // it's just a prototype, so get the ; and move on
    ExpectToken(';');
    Exit;
  end;
  // calculate stack space used by parms
  LNumParms := LType.NumParameters;
  SetLength(LFunc.ParmSize, LNumParms);
  for LIndex := 0 to LNumParms - 1 do
  begin
    LParmType := LType.GetParmType(LIndex);
    if LParmType.IsObject then
      LFunc.ParmSize[LIndex] := 4
    else
      LFunc.ParmSize[LIndex] := LParmType.Size;
    Inc(LFunc.ParmTotal, LFunc.ParmSize[LIndex]);
  end;
  // define the parms
  for LIndex := 0 to LNumParms - 1 do
  begin
    if Assigned(FProgram.GetDef(LType.GetParmType(LIndex), LType.GetParmName(LIndex), LDef)) then
      Error('''%s'' defined more than once in function parameters', [string(LType.GetParmName(LIndex))]);
    FProgram.AllocDef(LType.GetParmType(LIndex), LType.GetParmName(LIndex), LDef, False);
  end;
  LOldScope := FScope;
  FScope := LDef;
  LFunc.FirstStatement := FProgram.NumStatements;
  // check if we should call the super class constructor
  if LOldScope.TypeDef.IsObject and (TIdStrings.Icmp(AName, 'init') = 0) then
  begin
    LSpecial := nil;
    // find the superclass constructor
    LSuperClass := LOldScope.TypeDef.SuperClass;
    while LSuperClass <> TypeOf(evObject) do
    begin
      LSpecial := FProgram.FindFunction(LSuperClass.Name + '::init');
      if Assigned(LSpecial) then
        Break;
      LSuperClass := LSuperClass.SuperClass;
    end;
    // emit the call to the constructor
    if Assigned(LSpecial) then
    begin
      LSelfDef := FProgram.GetDef(LType.GetParmType(0), LType.GetParmName(0), LDef);
      EmitPush(LSelfDef, LSelfDef.TypeDef);
      EmitOpcode(OP_CALL, LSpecial.Def, nil);
    end;
  end;
  // parse regular statements
  while not CheckToken('}') do
    ParseStatement;
  // check if we should call the super class destructor
  if LOldScope.TypeDef.IsObject and (TIdStrings.Icmp(AName, 'destroy') = 0) then
  begin
    LSpecial := nil;
    // find the superclass destructor
    LSuperClass := LOldScope.TypeDef.SuperClass;
    while LSuperClass <> TypeOf(evObject) do
    begin
      LSpecial := FProgram.FindFunction(LSuperClass.Name + '::destroy');
      if Assigned(LSpecial) then
        Break;
      LSuperClass := LSuperClass.SuperClass;
    end;
    if Assigned(LSpecial) then
    begin
      // change all returns to point to the call to the destructor
      for LIndex := LFunc.FirstStatement to FProgram.NumStatements - 1 do
      begin
        LStatement := FProgram.GetStatement(LIndex);
        if LStatement.Op = OP_RETURN then
        begin
          LStatement.Op := OP_GOTO;
          LStatement.A := JumpDef(LIndex, FProgram.NumStatements);
        end;
      end;
      // emit the call to the destructor
      LSelfDef := FProgram.GetDef(LType.GetParmType(0), LType.GetParmName(0), LDef);
      EmitPush(LSelfDef, LSelfDef.TypeDef);
      EmitOpcode(OP_CALL, LSpecial.Def, nil);
    end;
  end;
  // always emit the return opcode
  EmitOpcode(OP_RETURN, nil, nil);
  // record the number of statements in the function
  LFunc.NumStatements := FProgram.NumStatements - LFunc.FirstStatement;
  FScope := LOldScope;
end;

procedure TDoomScriptCompiler.ParseVariableDef(const AType: TDoomScriptTypeDef; const AName: AnsiString);
var
  LDef: TDoomScriptVarDef;
  LDef2: TDoomScriptVarDef;
  LNegate: Boolean;
  LType2: TDoomScriptTypeDef;
begin
  LDef := FProgram.GetDef(AType, AName, FScope);
  if Assigned(LDef) then
    Error('%s redeclared', [string(AName)]);
  LDef := FProgram.AllocDef(AType, AName, FScope, False);
  // check for an initialization
  if CheckToken('=') then
  begin
    // if a local variable in a function then write out interpreter code to initialize variable
    if FScope.Kind = evFunction then
    begin
      LDef2 := GetExpression(DS_TOP_PRIORITY);
      LType2 := LDef2.TypeDef;
      if (AType = TypeOf(evFloat)) and (LType2 = TypeOf(evFloat)) then
        EmitOpcode(OP_STORE_F, LDef2, LDef)
      else if (AType = TypeOf(evVector)) and (LType2 = TypeOf(evVector)) then
        EmitOpcode(OP_STORE_V, LDef2, LDef)
      else if (AType = TypeOf(evString)) and (LType2 = TypeOf(evString)) then
        EmitOpcode(OP_STORE_S, LDef2, LDef)
      else if (AType = TypeOf(evEntity)) and ((LType2 = TypeOf(evEntity)) or LType2.IsObject) then
        EmitOpcode(OP_STORE_ENT, LDef2, LDef)
      else if AType.IsObject and (LType2 = TypeOf(evEntity)) then
        EmitOpcode(OP_STORE_OBJENT, LDef2, LDef)
      else if AType.IsObject and LType2.Inherits(AType) then
        EmitOpcode(OP_STORE_OBJ, LDef2, LDef)
      else if (AType = TypeOf(evBoolean)) and (LType2 = TypeOf(evBoolean)) then
        EmitOpcode(OP_STORE_BOOL, LDef2, LDef)
      else if (AType = TypeOf(evString)) and (LType2 = TypeOf(evFloat)) then
        EmitOpcode(OP_STORE_FTOS, LDef2, LDef)
      else if (AType = TypeOf(evString)) and (LType2 = TypeOf(evBoolean)) then
        EmitOpcode(OP_STORE_BTOS, LDef2, LDef)
      else if (AType = TypeOf(evString)) and (LType2 = TypeOf(evVector)) then
        EmitOpcode(OP_STORE_VTOS, LDef2, LDef)
      else if (AType = TypeOf(evBoolean)) and (LType2 = TypeOf(evFloat)) then
        EmitOpcode(OP_STORE_FTOBOOL, LDef2, LDef)
      else if (AType = TypeOf(evFloat)) and (LType2 = TypeOf(evBoolean)) then
        EmitOpcode(OP_STORE_BOOLTOF, LDef2, LDef)
      else
        Error('bad initialization for ''%s''', [string(AName)]);
    end
    else
    begin
      // global variables can only be initialized with immediate values
      LNegate := False;
      if (FToken.TokenType = TT_PUNCTUATION) and FToken.IsText('-') then
      begin
        LNegate := True;
        NextToken;
        if FImmediateType <> TypeOf(evFloat) then
          Error('wrong immediate type for ''-'' on variable ''%s''', [string(AName)]);
      end;
      if FImmediateType <> AType then
        Error('wrong immediate type for ''%s''', [string(AName)]);
      // global variables are initialized at start up
      if AType = TypeOf(evString) then
        FProgram.SetDefString(LDef, FToken.Text, False)
      else
      begin
        if LNegate then
          FImmediate.FloatValue := -FImmediate.FloatValue;
        FProgram.SetDefValue(LDef, FImmediate, False);
      end;
      NextToken;
    end;
  end
  else if AType = TypeOf(evString) then
  begin
    // local strings on the stack are initialized in the interpreter
    if FScope.Kind <> evFunction then
      FProgram.SetDefString(LDef, '', False);
  end
  else if AType.IsObject then
    if FScope.Kind <> evFunction then
      FProgram.ClearDefObject(LDef);
end;

function TDoomScriptCompiler.GetTypeForEventArg(const AArgType: AnsiChar): TDoomScriptTypeDef;
begin
  case AArgType of
    // an integer is converted by the interpreter
    DS_EVENT_INTEGER, DS_EVENT_FLOAT:
      Result := TypeOf(evFloat);
    DS_EVENT_VECTOR:
      Result := TypeOf(evVector);
    DS_EVENT_STRING:
      Result := TypeOf(evString);
    DS_EVENT_ENTITY, DS_EVENT_ENTITY_NULL:
      Result := TypeOf(evEntity);
    DS_EVENT_VOID:
      Result := TypeOf(evVoid);
  else
    // a trace is not available from script; anything else is probably a typo
    Result := nil;
  end;
end;

procedure TDoomScriptCompiler.ParseEventDef(const AReturnType: TDoomScriptTypeDef; const AName: AnsiString);
var
  LExpectedType: TDoomScriptTypeDef;
  LArgType: TDoomScriptTypeDef;
  LType: TDoomScriptTypeDef;
  LNewType: TDoomScriptTypeDef;
  LIndex: Integer;
  LNum: Integer;
  LFormat: AnsiString;
  LEvent: TDoomScriptEventDef;
  LParmName: AnsiString;
  LFunc: TDoomScriptFunction;
begin
  LEvent := FEvents.FindEvent(AName);
  if not Assigned(LEvent) then
    Error('Unknown event ''%s''', [string(AName)]);
  // set the return type
  LExpectedType := GetTypeForEventArg(LEvent.ReturnType);
  if not Assigned(LExpectedType) then
    Error('Invalid return type ''%s'' in definition of ''%s'' event.', [string(AnsiString(LEvent.ReturnType)),
      string(AName)]);
  if AReturnType <> LExpectedType then
    Error('Return type doesn''t match internal return type ''%s''', [string(LExpectedType.Name)]);
  LNewType := TDoomScriptTypeDef.Create(evFunction, nil, AName, 4, AReturnType);
  try
    ExpectToken('(');
    LFormat := LEvent.ArgFormat;
    LNum := Length(LFormat);
    for LIndex := 0 to LNum - 1 do
    begin
      LExpectedType := GetTypeForEventArg(LFormat[LIndex + 1]);
      if (not Assigned(LExpectedType)) or (LExpectedType = TypeOf(evVoid)) then
        Error('Invalid parameter ''%s'' in definition of ''%s'' event.', [string(AnsiString(LFormat[LIndex + 1])),
          string(AName)]);
      LArgType := ParseType;
      LParmName := ParseName;
      if LArgType <> LExpectedType then
        Error('The type of parm %d (''%s'') does not match the internal type ''%s'' in definition of ''%s'' event.',
          [LIndex + 1, string(LParmName), string(LExpectedType.Name), string(AName)]);
      LNewType.AddFunctionParm(LArgType, '');
      if LIndex < LNum - 1 then
      begin
        if CheckToken(')') then
          Error('Too few parameters for event definition.  Internal definition has %d parameters.', [LNum]);
        ExpectToken(',');
      end;
    end;
    if not CheckToken(')') then
      Error('Too many parameters for event definition.  Internal definition has %d parameters.', [LNum]);
    ExpectToken(';');
    LType := FProgram.FindType(AName);
    if Assigned(LType) then
    begin
      if (not LNewType.MatchesType(LType)) or (not Assigned(LType.Def)) or
        (not Assigned(LType.Def.FunctionPtr)) or (LType.Def.FunctionPtr.EventDef <> LEvent) then
        Error('Type mismatch on redefinition of ''%s''', [string(AName)]);
    end
    else
    begin
      LType := FProgram.AllocType(LNewType);
      LType.Def := FProgram.AllocDef(LType, AName, FProgram.DefNamespace, True);
      LFunc := FProgram.AllocFunction(LType.Def);
      LFunc.EventDef := LEvent;
      SetLength(LFunc.ParmSize, LNum);
      for LIndex := 0 to LNum - 1 do
      begin
        LArgType := LNewType.GetParmType(LIndex);
        Inc(LFunc.ParmTotal, LArgType.Size);
        LFunc.ParmSize[LIndex] := LArgType.Size;
      end;
      // mark the parms as local
      LFunc.Locals := LFunc.ParmTotal;
    end;
  finally
    LNewType.Free;
  end;
end;

procedure TDoomScriptCompiler.ParseDefs;
var
  LName: AnsiString;
  LType: TDoomScriptTypeDef;
  LDef: TDoomScriptVarDef;
  LOldScope: TDoomScriptVarDef;
begin
  if CheckToken(';') then
    // skip semicolons, which are harmless and ok syntax
    Exit;
  LType := ParseType;
  if LType = TypeOf(evScriptEvent) then
  begin
    LType := ParseType;
    LName := ParseName;
    ParseEventDef(LType, LName);
    Exit;
  end;
  LName := ParseName;
  if LType = TypeOf(evNamespace) then
  begin
    LDef := FProgram.GetDef(LType, LName, FScope);
    if not Assigned(LDef) then
      LDef := FProgram.AllocDef(LType, LName, FScope, True);
    ParseNamespace(LDef);
  end
  else if CheckToken('::') then
  begin
    LDef := FProgram.GetDef(nil, LName, FScope);
    if not Assigned(LDef) then
      Error('Unknown object name ''%s''', [string(LName)]);
    LName := ParseName;
    LOldScope := FScope;
    FScope := LDef;
    ExpectToken('(');
    ParseFunctionDef(LType, LName);
    FScope := LOldScope;
  end
  else if LType = TypeOf(evObject) then
    ParseObjectDef(LName)
  else if CheckToken('(') then
    // check for a function prototype or declaraction
    ParseFunctionDef(LType, LName)
  else
  begin
    ParseVariableDef(LType, LName);
    while CheckToken(',') do
    begin
      LName := ParseName;
      ParseVariableDef(LType, LName);
    end;
    ExpectToken(';');
  end;
end;

procedure TDoomScriptCompiler.ParseNamespace(const ANewScope: TDoomScriptVarDef);
var
  LOldScope: TDoomScriptVarDef;
begin
  LOldScope := FScope;
  if ANewScope <> FProgram.DefNamespace then
    ExpectToken('{');
  while not FEof do
  begin
    FScope := ANewScope;
    FCallThread := False;
    if (ANewScope <> FProgram.DefNamespace) and CheckToken('}') then
      Break;
    ParseDefs;
  end;
  FScope := LOldScope;
end;

procedure TDoomScriptCompiler.CompileFile(const AText, AFileName: AnsiString; const AConsole: Boolean);
var
  LText: string;
begin
  ResetState;
  FConsole := AConsole;
  FParser := TIdParser.Create(0, FLog, FFileSystem);
  try
    FParser.SetFlags(LEXFL_ALLOWMULTICHARLITERALS);
    FParser.LoadMemory(AText, Length(AText), AFileName);
    // unread tokens to include script defines
    FToken := TIdToken.Create;
    FToken.Text := DS_DEFAULT_DEFS;
    FToken.TokenType := TT_STRING;
    FToken.SubType := Length(FToken.Text);
    FToken.Line := 0;
    FToken.LinesCrossed := 0;
    FParser.UnreadToken(FToken);
    FToken.Text := 'include';
    FToken.TokenType := TT_NAME;
    FToken.SubType := Length(FToken.Text);
    FParser.UnreadToken(FToken);
    FToken.Text := '#';
    FToken.TokenType := TT_PUNCTUATION;
    FToken.SubType := P_PRECOMP;
    FParser.UnreadToken(FToken);
    // init the current token line to be the first line so that currentLineNumber is set correctly in NextToken
    FToken.Line := 1;
    try
      // read first token
      NextToken;
      while not FEof do
        // parse from global namespace
        ParseNamespace(FProgram.DefNamespace);
    except
      on E: EDoomScriptCompileError do
      begin
        if FConsole then
          // no line number when the script comes from the console
          LText := Format('Error: %s'#10, [E.Message])
        else
          LText := Format('Error: file %s, line %d: %s'#10, [string(FProgram.GetFilename(FCurrentFileNumber)),
            FCurrentLineNumber, E.Message]);
        raise EDoomScriptCompileError.Create(LText);
      end;
    end;
  finally
    FreeAndNil(FParser);
  end;
  // the original printed the time the compilation took: the library has no clock
  if (not AConsole) and Assigned(FLog) then
    FLog.Printf(Format('Compiled ''%s'': 0.0 ms'#10, [string(AFileName)]));
end;

end.

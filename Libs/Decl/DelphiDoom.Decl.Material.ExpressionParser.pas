{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TMaterialExpressionParser                 }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.cpp (ParseTerm, ParseExpressionPriority, ParseExpression, }
{  ParseEmitOp, MatchToken). Copyright (C) 1999-2011 id Software LLC, a        }
{  ZeniMax Media company.                                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.ExpressionParser;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.Material.Types, DelphiDoom.Decl.Material.Registers;

type
  /// <summary>
  ///   Reads an expression ("time * 0.5 + parm3", "sinTable[ time ]", "( a > b ) && c") with an <c>idLexer</c> and
  ///   puts it in a register table; the value is the register that holds the result. Priorities from the
  ///   tightest: <c>* / %</c>, <c>+ -</c>, <c>&gt; &gt;= &lt; &lt;= == !=</c>, <c>&amp;&amp;</c> and <c>||</c>.
  ///   A syntax error is a warning and sets the <c>Defaulted</c> flag of the table.
  /// </summary>
  TMaterialExpressionParser = class
  strict private
    FRegisters: TMaterialRegisterTable;
    FFinder: IDeclFinder;
    FLog: IIdLibLog;
    FMaterialName: AnsiString;
    FFragmentProgramsAvailable: Boolean;
    procedure Warn(const AMessage: string);
    function ParseTerm(const ASource: TIdLexer): Integer;
    function ParseEmitOp(const ASource: TIdLexer; const AA: Integer; const AOpType: TMaterialOpType;
      const APriority: Integer): Integer;
    function ParseExpressionPriority(const ASource: TIdLexer; const APriority: Integer): Integer;
  public
    constructor Create(const ARegisters: TMaterialRegisterTable; const AFinder: IDeclFinder;
      const ALog: IIdLibLog; const AMaterialName: AnsiString; const AFragmentProgramsAvailable: Boolean);
    /// <summary>MatchToken: expects a token; if it is not there the material is defaulted</summary>
    function MatchToken(const ASource: TIdLexer; const AMatch: AnsiString): Boolean;
    /// <summary>ParseExpression: the register index of the expression</summary>
    function ParseExpression(const ASource: TIdLexer): Integer;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Decl.Types;

const
  TOP_PRIORITY = 4;

{ TMaterialExpressionParser }

constructor TMaterialExpressionParser.Create(const ARegisters: TMaterialRegisterTable;
  const AFinder: IDeclFinder; const ALog: IIdLibLog; const AMaterialName: AnsiString;
  const AFragmentProgramsAvailable: Boolean);
begin
  inherited Create;
  FRegisters := ARegisters;
  FFinder := AFinder;
  FLog := ALog;
  FMaterialName := AMaterialName;
  FFragmentProgramsAvailable := AFragmentProgramsAvailable;
end;

procedure TMaterialExpressionParser.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

function TMaterialExpressionParser.MatchToken(const ASource: TIdLexer; const AMatch: AnsiString): Boolean;
begin
  Result := ASource.ExpectTokenString(AMatch);
  if not Result then
    FRegisters.MarkDefaulted;
end;

function TMaterialExpressionParser.ParseTerm(const ASource: TIdLexer): Integer;
var
  LToken: TIdToken;
  LIndex, LValue: Integer;
  LTable: IDecl;
  LBase: Integer;
begin
  LToken := TIdToken.Create;
  ASource.ReadToken(LToken);

  if LToken.IsText('(') then
  begin
    Result := ParseExpression(ASource);
    MatchToken(ASource, ')');
    Exit;
  end;

  if TIdStrings.Icmp(LToken.Text, 'time') = 0 then
  begin
    FRegisters.RegistersAreConstant := False;
    Exit(EXP_REG_TIME);
  end;
  for LIndex := 0 to MAX_ENTITY_SHADER_PARMS - 1 do
    if TIdStrings.Icmp(LToken.Text, AnsiString('parm' + IntToStr(LIndex))) = 0 then
    begin
      FRegisters.RegistersAreConstant := False;
      Exit(EXP_REG_PARM0 + LIndex);
    end;
  LBase := EXP_REG_GLOBAL0;
  for LIndex := 0 to MAX_GLOBAL_SHADER_PARMS - 1 do
    if TIdStrings.Icmp(LToken.Text, AnsiString('global' + IntToStr(LIndex))) = 0 then
    begin
      FRegisters.RegistersAreConstant := False;
      Exit(LBase + LIndex);
    end;
  if TIdStrings.Icmp(LToken.Text, 'fragmentPrograms') = 0 then
  begin
    if FFragmentProgramsAvailable then
      LValue := 1
    else
      LValue := 0;
    Exit(FRegisters.GetConstant(LValue));
  end;

  if TIdStrings.Icmp(LToken.Text, 'sound') = 0 then
  begin
    FRegisters.RegistersAreConstant := False;
    Exit(FRegisters.EmitOp(0, 0, TMaterialOpType.Sound));
  end;

  // parse negative numbers
  if LToken.IsText('-') then
  begin
    ASource.ReadToken(LToken);
    if (LToken.TokenType = TT_NUMBER) or LToken.IsText('.') then
      Exit(FRegisters.GetConstant(-LToken.GetFloatValue));
    ASource.Warning('Bad negative number ''%s''', [string(LToken.Text)]);
    FRegisters.MarkDefaulted;
    Exit(0);
  end;

  if (LToken.TokenType = TT_NUMBER) or LToken.IsText('.') then
    Exit(FRegisters.GetConstant(LToken.GetFloatValue));

  // see if it is a table name
  LTable := FFinder.FindType(DECL_TABLE, LToken.Text, False);
  if not Assigned(LTable) then
  begin
    ASource.Warning('Bad term ''%s''', [string(LToken.Text)]);
    FRegisters.MarkDefaulted;
    Exit(0);
  end;

  // parse a table expression
  MatchToken(ASource, '[');
  LValue := ParseExpression(ASource);
  MatchToken(ASource, ']');
  Result := FRegisters.EmitOp(LTable.GetIndex, LValue, TMaterialOpType.Table);
end;

function TMaterialExpressionParser.ParseEmitOp(const ASource: TIdLexer; const AA: Integer;
  const AOpType: TMaterialOpType; const APriority: Integer): Integer;
var
  LB: Integer;
begin
  LB := ParseExpressionPriority(ASource, APriority);
  Result := FRegisters.EmitOp(AA, LB, AOpType);
end;

function TMaterialExpressionParser.ParseExpressionPriority(const ASource: TIdLexer;
  const APriority: Integer): Integer;
var
  LToken: TIdToken;
  LA: Integer;
begin
  if APriority = 0 then
    Exit(ParseTerm(ASource));

  LA := ParseExpressionPriority(ASource, APriority - 1);

  // we have a parse error
  if FRegisters.Defaulted then
    Exit(0);

  LToken := TIdToken.Create;
  // we won't get EOF in a real file, but we can when parsing from generated strings
  if not ASource.ReadToken(LToken) then
    Exit(LA);

  if (APriority = 1) and LToken.IsText('*') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.Multiply, APriority));
  if (APriority = 1) and LToken.IsText('/') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.Divide, APriority));
  // implied truncate both to integer
  if (APriority = 1) and LToken.IsText('%') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.Modulo, APriority));
  if (APriority = 2) and LToken.IsText('+') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.Add, APriority));
  if (APriority = 2) and LToken.IsText('-') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.Subtract, APriority));
  if (APriority = 3) and LToken.IsText('>') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.GreaterThan, APriority));
  if (APriority = 3) and LToken.IsText('>=') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.GreaterOrEqual, APriority));
  if (APriority = 3) and LToken.IsText('<') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.LessThan, APriority));
  if (APriority = 3) and LToken.IsText('<=') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.LessOrEqual, APriority));
  if (APriority = 3) and LToken.IsText('==') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.Equal, APriority));
  if (APriority = 3) and LToken.IsText('!=') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.NotEqual, APriority));
  if (APriority = 4) and LToken.IsText('&&') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.LogicalAnd, APriority));
  if (APriority = 4) and LToken.IsText('||') then
    Exit(ParseEmitOp(ASource, LA, TMaterialOpType.LogicalOr, APriority));

  // assume that anything else terminates the expression
  ASource.UnreadToken(LToken);
  Result := LA;
end;

function TMaterialExpressionParser.ParseExpression(const ASource: TIdLexer): Integer;
begin
  Result := ParseExpressionPriority(ASource, TOP_PRIORITY);
end;

end.

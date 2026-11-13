{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiExpressionParser                              }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Window.cpp              }
{  (ParseExpression, ParseExpressionPriority, ParseTerm, ParseEmitOp).         }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Regs.Parser;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Regs.Types, DelphiDoom.Gui.Regs.Intf, DelphiDoom.Gui.Regs.Store;

type
  /// <summary>
  ///   Reads an expression (precedence: * / %, + -, comparisons, && || ?:) and emits its operations
  ///   in a store. A name that is not a variable yet is emitted as an operation with
  ///   <c>B = -2</c> that the window resolves after the parse.
  /// </summary>
  TGuiExpressionParser = class
  strict private
    FStore: TGuiExpressionStore;
    FHost: IGuiExpressionHost;
    FTables: IGuiTables;
    function ParseTerm(const ASource: TIdParser): Integer;
    function ParseEmitOp(const ASource: TIdParser; const AA: Integer; const AOpType: TGuiOpType;
      const APriority: Integer; out AOpIndex: Integer): Integer;
    function ParsePriority(const ASource: TIdParser; const APriority: Integer): Integer;
  public
    constructor Create(const AStore: TGuiExpressionStore; const AHost: IGuiExpressionHost; const ATables: IGuiTables);
    /// <summary>Returns the register of the result</summary>
    function ParseExpression(const ASource: TIdParser): Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Float, DelphiDoom.Gui.WinVar.Int,
  DelphiDoom.Gui.WinVar.Str, DelphiDoom.Gui.WinVar.Vec4;

const
  TOP_PRIORITY = 4;

constructor TGuiExpressionParser.Create(const AStore: TGuiExpressionStore; const AHost: IGuiExpressionHost;
  const ATables: IGuiTables);
begin
  inherited Create;
  FStore := AStore;
  FHost := AHost;
  FTables := ATables;
end;

function TGuiExpressionParser.ParseEmitOp(const ASource: TIdParser; const AA: Integer; const AOpType: TGuiOpType;
  const APriority: Integer; out AOpIndex: Integer): Integer;
var
  LB: Integer;
begin
  LB := ParsePriority(ASource, APriority);
  Result := FStore.EmitOp(AA, LB, AOpType, AOpIndex);
end;

function TGuiExpressionParser.ParseTerm(const ASource: TIdParser): Integer;
var
  LToken: TIdToken;
  LA: Integer;
  LB: Integer;
  LTableIndex: Integer;
  LVariable: TGuiWinVar;
  LOp: TGuiOp;
  LOpIndex: Integer;
begin
  LToken := TIdToken.Create;
  ASource.ReadToken(LToken);
  if LToken.IsText('(') then
  begin
    LA := ParseExpression(ASource);
    ASource.ExpectTokenString(')');
    Exit(LA);
  end;
  if TIdStrings.Icmp(LToken.Text, 'time') = 0 then
    Exit(WEXP_REG_TIME);
  // negative numbers
  if LToken.IsText('-') then
  begin
    ASource.ReadToken(LToken);
    if (LToken.TokenType = TT_NUMBER) or LToken.IsText('.') then
      Exit(FStore.ExpressionConstant(-LToken.GetFloatValue));
    ASource.Warning(Format('Bad negative number ''%s''', [string(LToken.Text)]));
    Exit(0);
  end;
  if (LToken.TokenType = TT_NUMBER) or LToken.IsText('.') then
    Exit(FStore.ExpressionConstant(LToken.GetFloatValue));
  // a table
  if Assigned(FTables) and FTables.FindTable(LToken.Text, LTableIndex) then
  begin
    ASource.ExpectTokenString('[');
    LB := ParseExpression(ASource);
    ASource.ExpectTokenString(']');
    Exit(FStore.EmitOp(LTableIndex, LB, otTable));
  end;
  LVariable := FHost.GetWinVarByName(LToken.Text, True);
  if Assigned(LVariable) then
  begin
    FHost.InitVar(LVariable, LToken.Text);
    LB := 0;
    if LVariable is TGuiWinVec4 then
    begin
      if ASource.ReadToken(LToken) then
      begin
        if LToken.IsText('[') then
        begin
          LB := ParseExpression(ASource);
          ASource.ExpectTokenString(']');
        end
        else
          ASource.UnreadToken(LToken);
      end;
      Result := FStore.EmitOp(0, LB, otVar, LOpIndex);
    end
    else if LVariable is TGuiWinFloat then
      Result := FStore.EmitOp(0, LB, otVarf, LOpIndex)
    else if LVariable is TGuiWinInt then
      Result := FStore.EmitOp(0, LB, otVari, LOpIndex)
    else if LVariable is TGuiWinBool then
      Result := FStore.EmitOp(0, LB, otVarb, LOpIndex)
    else if LVariable is TGuiWinStr then
      Result := FStore.EmitOp(0, LB, otVars, LOpIndex)
    else
    begin
      ASource.Warning(Format('Var expression not vec4, float or int ''%s''', [string(LToken.Text)]));
      Exit(0);
    end;
    LOp := FStore.Ops[LOpIndex];
    LOp.Variable := LVariable;
    FStore.Ops[LOpIndex] := LOp;
    Exit;
  end;
  // used after the parse to resolve the names of variables defined later
  Result := FStore.EmitOp(0, -2, otVar, LOpIndex);
  LOp := FStore.Ops[LOpIndex];
  LOp.PendingName := LToken.Text;
  FStore.Ops[LOpIndex] := LOp;
end;

function TGuiExpressionParser.ParsePriority(const ASource: TIdParser; const APriority: Integer): Integer;
var
  LToken: TIdToken;
  LA: Integer;
  LOpIndex: Integer;
  LOp: TGuiOp;

  function Emit(const AOpType: TGuiOpType): Integer;
  begin
    Result := ParseEmitOp(ASource, LA, AOpType, APriority, LOpIndex);
  end;

begin
  if APriority = 0 then
    Exit(ParseTerm(ASource));
  LA := ParsePriority(ASource, APriority - 1);
  LToken := TIdToken.Create;
  // not an error at the end of a text built by the program
  if not ASource.ReadToken(LToken) then
    Exit(LA);
  if APriority = 1 then
  begin
    if LToken.IsText('*') then
      Exit(Emit(otMultiply));
    if LToken.IsText('/') then
      Exit(Emit(otDivide));
    if LToken.IsText('%') then
      Exit(Emit(otMod));
  end
  else if APriority = 2 then
  begin
    if LToken.IsText('+') then
      Exit(Emit(otAdd));
    if LToken.IsText('-') then
      Exit(Emit(otSubtract));
  end
  else if APriority = 3 then
  begin
    if LToken.IsText('>') then
      Exit(Emit(otGt));
    if LToken.IsText('>=') then
      Exit(Emit(otGe));
    if LToken.IsText('<') then
      Exit(Emit(otLt));
    if LToken.IsText('<=') then
      Exit(Emit(otLe));
    if LToken.IsText('==') then
      Exit(Emit(otEq));
    if LToken.IsText('!=') then
      Exit(Emit(otNe));
  end
  else if APriority = 4 then
  begin
    if LToken.IsText('&&') then
      Exit(Emit(otAnd));
    if LToken.IsText('||') then
      Exit(Emit(otOr));
    if LToken.IsText('?') then
    begin
      Result := Emit(otCond);
      if not ASource.ReadToken(LToken) then
        Exit;
      if LToken.IsText(':') then
      begin
        LA := ParsePriority(ASource, APriority - 1);
        // the original writes through a pointer that a growing op list can have moved
        LOp := FStore.Ops[LOpIndex];
        LOp.D := LA;
        FStore.Ops[LOpIndex] := LOp;
      end;
      Exit;
    end;
  end;
  // anything else ends the expression
  ASource.UnreadToken(LToken);
  Result := LA;
end;

function TGuiExpressionParser.ParseExpression(const ASource: TIdParser): Integer;
begin
  Result := ParsePriority(ASource, TOP_PRIORITY);
end;

end.

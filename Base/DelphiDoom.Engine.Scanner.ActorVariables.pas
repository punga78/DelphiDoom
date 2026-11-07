{******************************************************************************}
{                                                                              }
{  DelphiDoom: the variables of the expressions of the actor parameters         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Scanner.ActorVariables;

interface

uses
  DelphiDoom.Scanner.Expression.Intf;

type
  /// <summary>
  ///   Port of OnFindVar and OnVarValue of TActorEvaluator (sc_evaluate_actor.pas): the
  ///   variables are the constants of sc_consts (SC_GetConst); the last one found is
  ///   remembered, as the old code did
  /// </summary>
  TEngineActorExpressionVariables = class(TInterfacedObject, IExpressionVariables)
  strict private
    FLastName: string;
    FLastValue: string;
  public
    function Contains(const AName: string): Boolean;
    function ValueOf(const AName: string): string;
  end;

implementation

uses
  d_delphi,
  sc_consts;

{ TEngineActorExpressionVariables }

function TEngineActorExpressionVariables.Contains(const AName: string): Boolean;
var
  LValue: Integer;
begin
  Result := SC_GetConst(AName, LValue);
  if Result then
  begin
    FLastName := AName;
    FLastValue := itoa(LValue);
  end;
end;

function TEngineActorExpressionVariables.ValueOf(const AName: string): string;
var
  LValue: Integer;
begin
  if AName = FLastName then
    Result := FLastValue
  else if SC_GetConst(AName, LValue) then
    Result := itoa(LValue)
  else
    Result := '0';
end;

end.

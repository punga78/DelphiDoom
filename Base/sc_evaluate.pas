//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------


{$I Doom32.inc}

unit sc_evaluate;

interface

uses
  d_delphi,
  DelphiDoom.Scanner.Expression.Intf,
  DelphiDoom.Scanner.Expression.Evaluator;

//
// The evaluation is done by TExpressionEvaluator (Libs\Scanner); this class keeps the API
// that the engine uses: the variables are two events, the functions take a TDStrings
//

type
  TFindVar = function(v: string): boolean of object;
  TVarValue = function(v: string): string of object;
  TObjFunc = function(p: TDStrings): string of object;
  TExtFunc = function(p: TDStrings): string;

type
  TEvaluator = class(TObject)
  private
    FImpl: TExpressionEvaluator;
    FFindVar: TFindVar;
    FVarValue: TVarValue;
    function GetExpr: string;
    procedure SetExpr(const v: string);
  public
    property Expr: string read GetExpr write SetExpr;
    property FindVar: TFindVar read FFindVar write FFindVar;
    property VarValue: TVarValue read FVarValue write FVarValue;
    constructor Create; virtual;
    destructor Destroy; override;
    function Value: string;
    function EvaluateExpression(const aexpr: string): string;
    procedure AddFunc(aname: string; afunc: TObjFunc; anump: integer); overload; virtual;
    procedure AddFunc(aname: string; afunc: TExtFunc; anump: integer); overload; virtual;
  end;

//==============================================================================
//
// StrIsBool
//
//==============================================================================
function StrIsBool(const s: string): boolean;

//==============================================================================
//
// BoolToStr
//
//==============================================================================
function BoolToStr(v: boolean): string;

//==============================================================================
//
// StrToBool
//
//==============================================================================
function StrToBool(v: string): boolean;

//==============================================================================
//
// StripStr
//
// removes leading and trailing quote marks
//
//==============================================================================
function StripStr(v: string): string;

implementation

uses
  SysUtils,
  DelphiDoom.Engine.Scanner.Log,
  DelphiDoom.Scanner.Expression.Builtins,
  i_system;

type
  // the variables of the expressions are the events of the evaluator
  TEvaluatorVariables = class(TInterfacedObject, IExpressionVariables)
  private
    FOwner: TEvaluator;
  public
    constructor Create(const AOwner: TEvaluator);
    function Contains(const AName: string): Boolean;
    function ValueOf(const AName: string): string;
  end;

//==============================================================================
//
// TEvaluatorVariables.Create
//
//==============================================================================
constructor TEvaluatorVariables.Create(const AOwner: TEvaluator);
begin
  inherited Create;
  FOwner := AOwner;
end;

//==============================================================================
//
// TEvaluatorVariables.Contains
//
//==============================================================================
function TEvaluatorVariables.Contains(const AName: string): Boolean;
begin
  Result := Assigned(FOwner.FFindVar) and FOwner.FFindVar(AName);
end;

//==============================================================================
//
// TEvaluatorVariables.ValueOf
//
//==============================================================================
function TEvaluatorVariables.ValueOf(const AName: string): string;
begin
  Result := FOwner.FVarValue(AName);
end;

//==============================================================================
//
// StripStr
//
//==============================================================================
function StripStr(v: string): string;
begin
  result := TExpressionBuiltins.StripQuotes(v);
end;

//==============================================================================
//
// StrIsBool
//
//==============================================================================
function StrIsBool(const s: string): boolean;
begin
  result := TExpressionEvaluator.IsBoolean(s);
end;

//==============================================================================
//
// BoolToStr
//
//==============================================================================
function BoolToStr(v: boolean): string;
begin
  result := TExpressionEvaluator.BooleanToText(v);
end;

//==============================================================================
//
// StrToBool
//
//==============================================================================
function StrToBool(v: string): boolean;
begin
  result := TExpressionEvaluator.TextToBoolean(v);
end;

//==============================================================================
// TEvaluator.Create
//
// TEvaluator
//
//==============================================================================
constructor TEvaluator.Create;
begin
  inherited Create;
  FFindVar := nil;
  FVarValue := nil;
  FImpl := TExpressionEvaluator.Create(TEngineScannerLog.Create, TEvaluatorVariables.Create(Self));
end;

//==============================================================================
//
// TEvaluator.Destroy
//
//==============================================================================
destructor TEvaluator.Destroy;
begin
  FImpl.Free;
  inherited Destroy;
end;

//==============================================================================
//
// TEvaluator.GetExpr
//
//==============================================================================
function TEvaluator.GetExpr: string;
begin
  result := FImpl.Expression;
end;

//==============================================================================
//
// TEvaluator.SetExpr
//
//==============================================================================
procedure TEvaluator.SetExpr(const v: string);
begin
  FImpl.Expression := v;
end;

//==============================================================================
//
// TEvaluator.Value
//
//==============================================================================
function TEvaluator.Value: string;
begin
  result := FImpl.Value;
end;

//==============================================================================
//
// TEvaluator.EvaluateExpression
//
//==============================================================================
function TEvaluator.EvaluateExpression(const aexpr: string): string;
begin
  result := FImpl.Evaluate(aexpr);
end;

//==============================================================================
//
// TEvaluator.AddFunc
//
//==============================================================================
procedure TEvaluator.AddFunc(aname: string; afunc: TObjFunc; anump: integer);
begin
  try
    FImpl.AddFunction(aname,
      function(const AParams: TArray<string>): string
      var
        l: TDStringList;
        i: integer;
      begin
        l := TDStringList.Create;
        try
          for i := 0 to High(AParams) do
            l.Add(AParams[i]);
          result := afunc(l);
        finally
          l.Free;
        end;
      end, anump);
  except
    on E: EExpressionException do
      I_Error(E.Message);
  end;
end;

//==============================================================================
//
// TEvaluator.AddFunc
//
//==============================================================================
procedure TEvaluator.AddFunc(aname: string; afunc: TExtFunc; anump: integer);
begin
  try
    FImpl.AddFunction(aname,
      function(const AParams: TArray<string>): string
      var
        l: TDStringList;
        i: integer;
      begin
        l := TDStringList.Create;
        try
          for i := 0 to High(AParams) do
            l.Add(AParams[i]);
          result := afunc(l);
        finally
          l.Free;
        end;
      end, anump);
  except
    on E: EExpressionException do
      I_Error(E.Message);
  end;
end;

end.
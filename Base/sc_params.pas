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

//
// JVAL
// Dynamic Custom Parameter List for ACTORDEF LUMPS
//
// Facade (issue #185, slice 1b): the list is Libs\ActorDef\DelphiDoom.ActorDef.ParamList; this
// class keeps the properties that the actions and the DEHACKED applier use. The kinds of
// parameter that read a map or world variable or a custom parameter (GLBF_MAP_*,
// GLBF_WORLD_*, GLBF_MOBJ_*) were never stored by the old code (every one of them became an
// expression of the evaluator) and are gone.

unit sc_params;

interface

uses
  m_fixed,
  DelphiDoom.ActorDef.ParamList,
  DelphiDoom.Scanner.ContextEvaluator.Intf;

type
  TCustomParamList = class
  private
    fList: TActorDefParamList;
    function GetActor: pointer;
    procedure SetActor(const value: pointer);
    function GetCount: integer;
    function GetDeclaration: string;
    function GetIsComputed(index: integer): boolean;
    function GetInteger(index: integer): integer;
    procedure PutInteger(index: integer; const value: integer);
    function GetFloat(index: integer): single;
    procedure PutFloat(index: integer; const value: single);
    function GetFixed(index: integer): fixed_t;
    function GetMBF21Fixed(index: integer): fixed_t;
    function GetBool(index: integer): boolean;
    function GetString(index: integer): string;
    function GetEvaluateString(index: integer): string;
  public
    /// <summary>
    ///   AEvaluator reads the expressions of the parameters (the one that the composition root
    ///   gives to the DEHACKED applier); it may be nil only for a list of numbers, that never
    ///   asks it (P_CheckStateArgs)
    /// </summary>
    constructor Create(const tx: string; const AEvaluator: IContextExpressionEvaluator);
    destructor Destroy; override;
    property Count: integer read GetCount;
    property IsComputed[index: integer]: boolean read GetIsComputed;
    property IntVal[index: integer]: integer read GetInteger write PutInteger;
    property FloatVal[index: integer]: single read GetFloat write PutFloat;
    property FixedVal[index: integer]: fixed_t read GetFixed;
    property MBF21FixedVal[index: integer]: fixed_t read GetMBF21Fixed;
    property BoolVal[index: integer]: boolean read GetBool;
    property StrVal[index: integer]: string read GetString;
    property EvaluateStrVal[index: integer]: string read GetEvaluateString;
    property Declaration: string read GetDeclaration;
    property Actor: pointer read GetActor write SetActor;
  end;

//==============================================================================
//
// SC_EvalString
//
//==============================================================================
function SC_EvalString(const token: string): string;

implementation

uses
  DelphiDoom.ActorDef.ParamList.Intf,
  DelphiDoom.ActorDef.ParamString,
  DelphiDoom.Engine.ActorDef.MissingEvaluator,
  DelphiDoom.Engine.ActorDef.ParamRandom;

var
  // N_Random for RANDOM and FRANDOM; made when the first list needs it
  paramrandom: IActorDefParamRandom = nil;

//==============================================================================
//
// GetParamRandom
//
//==============================================================================
function GetParamRandom: IActorDefParamRandom;
begin
  if paramrandom = nil then
    paramrandom := TEngineParamRandom.Create;
  result := paramrandom;
end;

//==============================================================================
//
// TCustomParamList.Create
//
//==============================================================================
constructor TCustomParamList.Create(const tx: string; const AEvaluator: IContextExpressionEvaluator);
var
  evaluator: IContextExpressionEvaluator;
begin
  evaluator := AEvaluator;
  if evaluator = nil then
    evaluator := TEngineMissingEvaluator.Create(tx);
  fList := TActorDefParamList.Create(tx, evaluator, GetParamRandom);
end;

//==============================================================================
//
// TCustomParamList.Destroy
//
//==============================================================================
destructor TCustomParamList.Destroy;
begin
  fList.Free;
  inherited Destroy;
end;

function TCustomParamList.GetActor: pointer;
begin
  result := fList.Context;
end;

procedure TCustomParamList.SetActor(const value: pointer);
begin
  fList.Context := value;
end;

function TCustomParamList.GetCount: integer;
begin
  result := fList.Count;
end;

function TCustomParamList.GetDeclaration: string;
begin
  result := fList.Declaration;
end;

function TCustomParamList.GetIsComputed(index: integer): boolean;
begin
  result := fList.IsComputed(index);
end;

function TCustomParamList.GetInteger(index: integer): integer;
begin
  result := fList.GetInteger(index);
end;

procedure TCustomParamList.PutInteger(index: integer; const value: integer);
begin
  fList.SetInteger(index, value);
end;

function TCustomParamList.GetFloat(index: integer): single;
begin
  result := fList.GetFloat(index);
end;

procedure TCustomParamList.PutFloat(index: integer; const value: single);
begin
  fList.SetFloat(index, value);
end;

function TCustomParamList.GetFixed(index: integer): fixed_t;
begin
  result := fList.GetFixed(index);
end;

function TCustomParamList.GetMBF21Fixed(index: integer): fixed_t;
begin
  result := fList.GetMBF21Fixed(index);
end;

function TCustomParamList.GetBool(index: integer): boolean;
begin
  result := fList.GetBool(index);
end;

function TCustomParamList.GetString(index: integer): string;
begin
  result := fList.GetString(index);
end;

function TCustomParamList.GetEvaluateString(index: integer): string;
begin
  result := fList.GetEvaluatedString(index);
end;

//==============================================================================
//
// SC_EvalString
//
//==============================================================================
function SC_EvalString(const token: string): string;
begin
  result := TActorDefParamString.Evaluate(token, GetParamRandom);
end;

end.

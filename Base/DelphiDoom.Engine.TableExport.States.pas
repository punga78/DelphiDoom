{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the states for the table exports                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.TableExport.States;

interface

uses
  DelphiDoom.TableExport.Types,
  DelphiDoom.TableExport.Intf;

type
  /// <summary>The table of the states, the names of the engine for them and the sprites</summary>
  TEngineExportStates = class(TInterfacedObject, IExportStateSource)
  public
    function Count: Integer;
    function Get(AIndex: Integer): TExportState;
    function NameCount: Integer;
    function StateName(AIndex: Integer): string;
    function Owners(AIndex: Integer): TArray<Integer>;
    function SpriteCount: Integer;
    function SpriteName(AIndex: Integer): string;
  end;

implementation

uses
  SysUtils,
  d_think,
  deh_main,
  info_h,
  info,
  sc_states;

{ TEngineExportStates }

function TEngineExportStates.Count: Integer;
begin
  Result := numstates;
end;

function TEngineExportStates.NameCount: Integer;
begin
  Result := statenames.Count;
end;

function TEngineExportStates.StateName(AIndex: Integer): string;
begin
  Result := statenames.Strings[AIndex];
end;

function TEngineExportStates.SpriteCount: Integer;
begin
  Result := numsprites;
end;

function TEngineExportStates.SpriteName(AIndex: Integer): string;
var
  LBytes: PByteArray;
begin
  LBytes := PByteArray(@sprnames[AIndex]);
  Result := Char(LBytes[0]) + Char(LBytes[1]) + Char(LBytes[2]) + Char(LBytes[3]);
end;

function TEngineExportStates.Owners(AIndex: Integer): TArray<Integer>;
var
  LIndex: Integer;
begin
  if states[AIndex].owners = nil then
    Exit(nil);
  SetLength(Result, states[AIndex].owners.Count);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := states[AIndex].owners.Numbers[LIndex];
end;

function TEngineExportStates.Get(AIndex: Integer): TExportState;
var
  LState: Pstate_t;
  LAction: Integer;
begin
  Result := Default(TExportState);
  LState := @states[AIndex];
  Result.Numbers[sfSprite] := LState.sprite;
  Result.Numbers[sfFrame] := LState.frame;
  Result.Numbers[sfTics] := LState.tics;
  Result.Numbers[sfTics2] := LState.tics2;
  Result.Numbers[sfNextState] := Ord(LState.nextstate);
  Result.Numbers[sfMisc1] := LState.misc1;
  Result.Numbers[sfMisc2] := LState.misc2;
  Result.Numbers[sfFlagsEx] := LState.flags_ex;
  Result.Numbers[sfMbf21Bits] := LState.mbf21bits;
  Result.HasAction := Assigned(LState.action.acv);
  for LAction := 0 to dehnumactions - 1 do
    if @LState.action.acp1 = @deh_actions[LAction].action.acp1 then
    begin
      Result.ActionName := deh_actions[LAction].name;
      Break;
    end;
  Result.HasParams := LState.params <> nil;
  if Result.HasParams then
    Result.Params := LState.params.Declaration;
  if (LState.sprite >= 0) and (LState.sprite < numsprites) then
    Result.SpriteName := SpriteName(LState.sprite);
end;

end.

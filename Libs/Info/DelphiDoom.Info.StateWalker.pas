{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - the chains of states                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.StateWalker;

interface

uses
  DelphiDoom.Info.Intf;

type
  /// <summary>Walks the chains of states that a thing goes through (nextstate)</summary>
  TInfoStateWalker = class sealed
  strict private
    FMobjs: IInfoMobjSource;
    FStates: IInfoStateSource;
  public
    constructor Create(const AMobjs: IInfoMobjSource; const AStates: IInfoStateSource);
    /// <summary>
    ///   The states of a thing, in the order they are found: the chain that starts at each of
    ///   its twelve entry states (spawn, see, pain, melee, missile, death, xdeath, raise, heal,
    ///   crash, crush, interact), then the states that list the thing as an owner. A chain stops
    ///   at S_NULL or at a state already found. Nothing for a negative thing
    /// </summary>
    function StatesOf(const AMobj: Integer): TArray<Integer>;
    /// <summary>
    ///   The states from which a chain of states without a duration (tics = 0) goes on for
    ///   more than 65535 steps: it is a loop that never ends
    /// </summary>
    function StatesWithEndlessChain: TArray<Integer>;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Info.Types;

{ TInfoStateWalker }

constructor TInfoStateWalker.Create(const AMobjs: IInfoMobjSource; const AStates: IInfoStateSource);
begin
  inherited Create;
  if not Assigned(AMobjs) then
    raise EArgumentNilException.Create('AMobjs');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  FMobjs := AMobjs;
  FStates := AStates;
end;

function TInfoStateWalker.StatesOf(const AMobj: Integer): TArray<Integer>;
var
  LFound: TList<Integer>;
  LSet: TDictionary<Integer, Boolean>;
  LMobj: TInfoMobj;
  LCount: Integer;
  LState: Integer;

  procedure AddChain(AState: Integer);
  var
    LStep: Integer;
  begin
    for LStep := 0 to LCount - 1 do
    begin
      if LSet.ContainsKey(AState) then
        Exit;
      if (AState <= 0) or (AState >= LCount) then
        Exit;
      LFound.Add(AState);
      LSet.Add(AState, True);
      AState := FStates.Get(AState).NextState;
      if AState <= 0 then
        Exit;
    end;
  end;

begin
  Result := nil;
  if AMobj < 0 then
    Exit;
  LCount := FStates.Count;
  LFound := TList<Integer>.Create;
  LSet := TDictionary<Integer, Boolean>.Create;
  try
    LMobj := FMobjs.Get(AMobj);
    AddChain(LMobj.SpawnState);
    AddChain(LMobj.SeeState);
    AddChain(LMobj.PainState);
    AddChain(LMobj.MeleeState);
    AddChain(LMobj.MissileState);
    AddChain(LMobj.DeathState);
    AddChain(LMobj.XDeathState);
    AddChain(LMobj.RaiseState);
    AddChain(LMobj.HealState);
    AddChain(LMobj.CrashState);
    AddChain(LMobj.CrushState);
    AddChain(LMobj.InteractState);

    for LState := 0 to LCount - 1 do
      if not LSet.ContainsKey(LState) then
        if FStates.IsOwnedBy(LState, AMobj) then
        begin
          LFound.Add(LState);
          LSet.Add(LState, True);
        end;
    Result := LFound.ToArray;
  finally
    LSet.Free;
    LFound.Free;
  end;
end;

function TInfoStateWalker.StatesWithEndlessChain: TArray<Integer>;
var
  LList: TList<Integer>;
  LStart: Integer;
  LState: Integer;
  LLoops: Integer;
  LCount: Integer;
begin
  LList := TList<Integer>.Create;
  try
    LCount := FStates.Count;
    for LStart := 0 to LCount - 1 do
    begin
      LLoops := 0;
      LState := LStart;
      repeat
        if FStates.Get(LState).NextState = 0 then
          Break;
        LState := FStates.Get(LState).NextState;
        if (LState < 0) or (LState >= LCount) then
          Break;
        Inc(LLoops);
        if LLoops > $FFFF then
        begin
          LList.Add(LStart);
          Break;
        end;
      until FStates.Get(LState).Tics <> 0;
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

end.

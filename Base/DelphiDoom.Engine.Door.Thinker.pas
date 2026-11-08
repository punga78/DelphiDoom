{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the vertical door thinker (vldoor_t) and the library   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Door.Thinker;

interface

uses
  p_spec,
  DelphiDoom.Thinkers.Door.Types;

//==============================================================================
//
// DoorTickClassic
//
// One tic of a classic door (T_VerticalDoor). The thinker stays the vldoor_t
// of the zone memory that the savegames know: the state is read from it, the
// library runs it and the state is written back. Gives true when the door is
// finished: the caller clears the sector and removes the thinker
//
//==============================================================================
function DoorTickClassic(door: Pvldoor_t): boolean;

//==============================================================================
//
// DoorTickUdmf
//
// One tic of a scripted door (TH_VerticalDoor); the same result as above
//
//==============================================================================
function DoorTickUdmf(door: Pvldoor_t): boolean;

//==============================================================================
//
// DoorInitTagged
//
// The values of a new door made for a sector found by tag: the thinker already
// exists and has its sector. Plays the sound of the kind
//
//==============================================================================
procedure DoorInitTagged(door: Pvldoor_t; AKind: vldoor_e; ASpeed, ATopWait: integer;
  AUdmf: boolean);

//==============================================================================
//
// DoorInitManual
//
// The values of a new door opened by hand from a line; plays the sound. Gives
// true if the caller has to clear the special of the line
//
//==============================================================================
function DoorInitManual(door: Pvldoor_t; ASpecial, ASpeed, ATopWait: integer;
  AUdmf: boolean): boolean;

//==============================================================================
//
// DoorRetrigger
//
// A line is used on a sector whose door is working: false if the special does
// not touch it, otherwise AAction says what to do (the caller changes the door)
//
//==============================================================================
function DoorRetrigger(ASpecial, ADirection: integer; AThingIsPlayer, AUdmf: boolean;
  out AAction: TDoorRetrigger): boolean;

//==============================================================================
//
// DoorInitCloseIn30
//
// The values of the door of a sector that closes after 30 seconds
//
//==============================================================================
procedure DoorInitCloseIn30(door: Pvldoor_t);

//==============================================================================
//
// DoorInitRaiseIn5Mins
//
// The values of the door of a sector that opens after 5 minutes
//
//==============================================================================
procedure DoorInitRaiseIn5Mins(door: Pvldoor_t);

implementation

uses
  r_defs,
{$IF DEFINED(DOOM) OR DEFINED(STRIFE)}
  p_lights,
  p_genlin,
{$IFEND}
  DelphiDoom.Thinkers.Door.Intf,
  DelphiDoom.Engine.Door.Kinds,
  DelphiDoom.Engine.Door.Services;

//==============================================================================
//
// DoorLoadState
//
//==============================================================================
procedure DoorLoadState(door: Pvldoor_t; out AState: TDoorState);
begin
  AState := Default(TDoorState);
  AState.Kind := DoorKindToNeutral(door._type);
  AState.Direction := door.direction;
  AState.TopHeight := door.topheight;
  AState.Speed := door.speed;
  AState.TopWait := door.topwait;
  AState.TopCountdown := door.topcountdown;
{$IFDEF STRIFE}
  AState.OpenSound := door.opensound;
  AState.CloseSound := door.closesound;
{$ENDIF}
end;

//==============================================================================
//
// DoorStoreState
//
// Writes the values of the state in the record (not the kind: the callers know
// when it changed)
//
//==============================================================================
procedure DoorStoreState(const AState: TDoorState; door: Pvldoor_t);
begin
  door.direction := AState.Direction;
  door.topheight := AState.TopHeight;
  door.speed := AState.Speed;
  door.topwait := AState.TopWait;
  door.topcountdown := AState.TopCountdown;
{$IFDEF STRIFE}
  door.opensound := AState.OpenSound;
  door.closesound := AState.CloseSound;
{$ENDIF}
end;

//==============================================================================
//
// DoorSpawnInput
//
// What a new door is given: speed and wait, and in Strife the sounds that the
// caller already found from the textures of the sector
//
//==============================================================================
function DoorSpawnInput(door: Pvldoor_t; ASpeed, ATopWait: integer): TDoorSpawnInput;
begin
  result := Default(TDoorSpawnInput);
  result.Speed := ASpeed;
  result.TopWait := ATopWait;
{$IFDEF STRIFE}
  result.OpenSound := door.opensound;
  result.CloseSound := door.closesound;
{$ENDIF}
end;

{$IF DEFINED(DOOM) OR DEFINED(STRIFE)}

//==============================================================================
//
// DoorLinkedLightsOff
//
// The lights of the tag of the line that made the door (not for the doors that
// the sector made by itself: their line is nil)
//
//==============================================================================
procedure DoorLinkedLightsOff(door: Pvldoor_t);
begin
  if door.line <> nil then
    if door.line.tag <> 0 then
    begin
      if (door.line.special > CGENLOCKEDBASE) and
         (door.line.special and 6 = 6) then //jff 3/9/98 all manual doors
        EV_TurnTagLightsOff(door.line)
      else
        case door.line.special of
          1,
          26,
          27,
          28,
          31,
          32,
          33,
          34,
          117,
          118:
            EV_TurnTagLightsOff(door.line);
        end;
    end;
end;

//==============================================================================
//
// DoorLinkedLightsOn
//
//==============================================================================
procedure DoorLinkedLightsOn(door: Pvldoor_t);
begin
  if door.line <> nil then
    if door.line.tag <> 0 then
    begin
      if (door.line.special > CGENLOCKEDBASE) and
         (door.line.special and 6 = 6) then //jff 3/9/98 all manual doors
        EV_LightTurnOn(door.line, 0)
      else
        case door.line.special of
          1,
          26,
          27,
          28,
          31,
          32,
          33,
          34,
          117,
          118:
            EV_LightTurnOn(door.line, 0);
        end;
    end;
end;

{$IFEND}

//==============================================================================
//
// DoorTick
//
//==============================================================================
function DoorTick(door: Pvldoor_t; AUdmf: boolean): boolean;
var
  LState: TDoorState;
  LOutcome: TDoorTickOutcome;
begin
  DoorLoadState(door, LState);
  LOutcome := DoorRunner(AUdmf).Tick(LState, door.sector, door.sector.floorheight);
  DoorStoreState(LState, door);
  if LOutcome.KindChanged then
    door._type := DoorKindFromNeutral(LState.Kind);
{$IF DEFINED(DOOM) OR DEFINED(STRIFE)}
  if LOutcome.TurnLightsOff then
    DoorLinkedLightsOff(door);
  if LOutcome.TurnLightsOn then
    DoorLinkedLightsOn(door);
{$IFEND}
  result := LOutcome.Removed;
end;

//==============================================================================
//
// DoorTickClassic
//
//==============================================================================
function DoorTickClassic(door: Pvldoor_t): boolean;
begin
  result := DoorTick(door, false);
end;

//==============================================================================
//
// DoorTickUdmf
//
//==============================================================================
function DoorTickUdmf(door: Pvldoor_t): boolean;
begin
  result := DoorTick(door, true);
end;

//==============================================================================
//
// DoorInitTagged
//
//==============================================================================
procedure DoorInitTagged(door: Pvldoor_t; AKind: vldoor_e; ASpeed, ATopWait: integer;
  AUdmf: boolean);
var
  LState: TDoorState;
begin
  LState := DoorSpawner(AUdmf).SpawnTagged(door.sector, door.sector.ceilingheight,
    DoorKindToNeutral(AKind), DoorSpawnInput(door, ASpeed, ATopWait));
  DoorStoreState(LState, door);
  door._type := AKind;
end;

//==============================================================================
//
// DoorInitManual
//
//==============================================================================
function DoorInitManual(door: Pvldoor_t; ASpecial, ASpeed, ATopWait: integer;
  AUdmf: boolean): boolean;
var
  LState: TDoorState;
  LConsume: boolean;
begin
  LState := DoorSpawner(AUdmf).SpawnManual(door.sector, ASpecial,
    DoorSpawnInput(door, ASpeed, ATopWait), LConsume);
  DoorStoreState(LState, door);
  door._type := DoorKindFromNeutral(LState.Kind);
  result := LConsume;
end;

//==============================================================================
//
// DoorRetrigger
//
//==============================================================================
function DoorRetrigger(ASpecial, ADirection: integer; AThingIsPlayer, AUdmf: boolean;
  out AAction: TDoorRetrigger): boolean;
begin
  result := DoorSpawner(AUdmf).Retrigger(ASpecial, ADirection, AThingIsPlayer, AAction);
end;

//==============================================================================
//
// DoorInitCloseIn30
//
//==============================================================================
procedure DoorInitCloseIn30(door: Pvldoor_t);
var
  LState: TDoorState;
begin
  LState := DoorSpawner(false).CloseInThirtySeconds;
  DoorStoreState(LState, door);
  door._type := DoorKindFromNeutral(LState.Kind);
end;

//==============================================================================
//
// DoorInitRaiseIn5Mins
//
//==============================================================================
procedure DoorInitRaiseIn5Mins(door: Pvldoor_t);
var
  LState: TDoorState;
begin
  LState := DoorSpawner(false).RaiseInFiveMinutes(door.sector);
  DoorStoreState(LState, door);
  door._type := DoorKindFromNeutral(LState.Kind);
end;

end.

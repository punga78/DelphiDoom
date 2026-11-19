{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the floor thinker as the library sees it               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Floor.Thinker;

// What changes from Doom to Strife around a classic floor: the enumerations of
// the kinds of floors and of stairs, the version of the engine (only Doom plays
// the demos of the old ones) and the rules of the step of a plane. p_floor.pas,
// one unit for the two games, goes through here and names neither

interface

uses
  p_spec_h,
  DelphiDoom.Thinkers.Plane.Types,
  DelphiDoom.Thinkers.Floor.Types;

//==============================================================================
//
// FloorKindOf
//
// The kind of a classic floor (the floor_e of the game)
//
//==============================================================================
function FloorKindOf(AType: floor_e): TFloorKind;

//==============================================================================
//
// StairKindOf
//
// The kind of a classic staircase (the stair_e of the game)
//
//==============================================================================
function StairKindOf(AType: stair_e): TStairKind;

//==============================================================================
//
// FloorModernEngine
//
// False while a demo of Doom 1.15 or older plays: floors, stairs and donuts
// behave as they did then. Always true in Strife
//
//==============================================================================
function FloorModernEngine: boolean;

//==============================================================================
//
// FloorPlaneRules
//
// The rules of T_MovePlane of the game, read at every step
//
//==============================================================================
function FloorPlaneRules: TPlaneMoveRules;

implementation

uses
{$IFDEF DOOM}
  doomdef,
  g_game,
{$ENDIF}
  DelphiDoom.Thinkers.Plane.Rules;

//==============================================================================
//
// FloorKindOf
//
//==============================================================================
function FloorKindOf(AType: floor_e): TFloorKind;
begin
  case AType of
    lowerFloor:
      result := TFloorKind.LowerFloor;
    lowerFloorToLowest:
      result := TFloorKind.LowerFloorToLowest;
    turboLower:
      result := TFloorKind.TurboLower;
    raiseFloor:
      result := TFloorKind.RaiseFloor;
    raiseFloorToNearest:
      result := TFloorKind.RaiseFloorToNearest;
    lowerFloorToNearest:
      result := TFloorKind.LowerFloorToNearest;
    lowerFloor24:
      result := TFloorKind.LowerFloor24;
    lowerFloor32Turbo:
      result := TFloorKind.LowerFloor32Turbo;
    raiseToTexture:
      result := TFloorKind.RaiseToTexture;
    lowerAndChange:
      result := TFloorKind.LowerAndChange;
{$IFDEF STRIFE}
    raiseFloor64:
      result := TFloorKind.RaiseFloor64;
    raiseFloor512AndChange:
      result := TFloorKind.RaiseFloor512AndChange;
{$ENDIF}
    raiseFloor24:
      result := TFloorKind.RaiseFloor24;
    raiseFloor32Turbo:
      result := TFloorKind.RaiseFloor32Turbo;
    raiseFloor24AndChange:
      result := TFloorKind.RaiseFloor24AndChange;
    raiseFloorCrush:
      result := TFloorKind.RaiseFloorCrush;
    raiseFloorTurbo:
      result := TFloorKind.RaiseFloorTurbo;
    donutRaise:
      result := TFloorKind.DonutRaise;
    raiseFloor512:
      result := TFloorKind.RaiseFloor512;
    genFloorChg:
      result := TFloorKind.GenFloorChg;
    genFloorChg0:
      result := TFloorKind.GenFloorChg0;
    genFloorChgT:
      result := TFloorKind.GenFloorChgT;
  else
    // stairs, plain generalized floors and scripted floors: nothing special
    result := TFloorKind.Other;
  end;
end;

//==============================================================================
//
// StairKindOf
//
//==============================================================================
function StairKindOf(AType: stair_e): TStairKind;
begin
  case AType of
    build8:
      result := TStairKind.Build8;
    turbo16:
      result := TStairKind.Turbo16;
{$IFDEF STRIFE}
    buildDown16:
      result := TStairKind.BuildDown16;
{$ENDIF}
  else
    result := TStairKind.Other;
  end;
end;

//==============================================================================
//
// FloorModernEngine
//
//==============================================================================
function FloorModernEngine: boolean;
begin
{$IFDEF DOOM}
  result := G_PlayingEngineVersion > VERSION115;
{$ELSE}
  result := true;
{$ENDIF}
end;

//==============================================================================
//
// FloorPlaneRules
//
//==============================================================================
function FloorPlaneRules: TPlaneMoveRules;
begin
{$IFDEF DOOM}
  result := TPlaneRules.Doom(G_PlayingEngineVersion > VERSION115);
{$ELSE}
  result := TPlaneRules.Strife;
{$ENDIF}
end;

end.

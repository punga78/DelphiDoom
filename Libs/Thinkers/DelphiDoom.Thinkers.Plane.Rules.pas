{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the rules of the move of a plane per game    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Plane.Rules;

interface

uses
  DelphiDoom.Thinkers.Plane.Types;

type
  /// <summary>The rules of TPlaneMover for each of the old copies of T_MovePlane</summary>
  TPlaneRules = class
  public
    /// <summary>
    ///   The rules of Doom (p_floor.pas). AModern is False for the demos of the engine 1.15 and
    ///   before (the engine version is read at every step, so it can change from a demo to the next)
    /// </summary>
    class function Doom(AModern: Boolean): TPlaneMoveRules; static;
    /// <summary>The rules of Heretic (p_floor.pas)</summary>
    class function Heretic: TPlaneMoveRules; static;
    /// <summary>The rules of Strife (p_floor.pas)</summary>
    class function Strife: TPlaneMoveRules; static;
    /// <summary>The rules of the UDMF specials and of Hexen (udmf_floor.pas): no clamp, always put back</summary>
    class function Udmf: TPlaneMoveRules; static;
  end;

implementation

{ TPlaneRules }

class function TPlaneRules.Doom(AModern: Boolean): TPlaneMoveRules;
begin
  Result.ClampFloorRaiseToCeiling := AModern;
  Result.ClampCeilingLowerToFloor := AModern;
  Result.FloorLowerRestores := True;
  Result.FloorRaiseCrushKeeps := not AModern;
  Result.CeilingLowerCrushKeeps := True;
end;

class function TPlaneRules.Heretic: TPlaneMoveRules;
begin
  Result.ClampFloorRaiseToCeiling := False;
  Result.ClampCeilingLowerToFloor := False;
  Result.FloorLowerRestores := True;
  Result.FloorRaiseCrushKeeps := True;
  Result.CeilingLowerCrushKeeps := True;
end;

class function TPlaneRules.Strife: TPlaneMoveRules;
begin
  Result.ClampFloorRaiseToCeiling := True;
  Result.ClampCeilingLowerToFloor := True;
  Result.FloorLowerRestores := False;
  Result.FloorRaiseCrushKeeps := True;
  Result.CeilingLowerCrushKeeps := True;
end;

class function TPlaneRules.Udmf: TPlaneMoveRules;
begin
  Result.ClampFloorRaiseToCeiling := False;
  Result.ClampCeilingLowerToFloor := False;
  Result.FloorLowerRestores := True;
  Result.FloorRaiseCrushKeeps := False;
  Result.CeilingLowerCrushKeeps := False;
end;

end.

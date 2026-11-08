{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the types of the moving planes               }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Plane.Types;

{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils;

type
  /// <summary>Raised when the plane code is used in a way that cannot work (a bob table that is too short)</summary>
  EPlaneException = class(Exception);

  /// <summary>The plane of a sector that moves</summary>
  TPlaneKind = (Floor, Ceiling);

  /// <summary>What a step of a moving plane did (the old result_e: ok, crushed, pastdest)</summary>
  TPlaneMoveResult = (
    /// <summary>The plane moved by one step</summary>
    Ok,
    /// <summary>Something was in the way: the step was undone (or kept, see the rules)</summary>
    Crushed,
    /// <summary>The plane reached or passed its destination and was put on it</summary>
    PastDest
  );

  /// <summary>
  ///   The differences between the versions of the move of a plane in the games: the four old
  ///   copies of T_MovePlane (Doom, Heretic, Strife and the one of UDMF and Hexen) are the same
  ///   code with these five switches
  /// </summary>
  TPlaneMoveRules = record
    /// <summary>A floor that goes up does not go above the ceiling</summary>
    ClampFloorRaiseToCeiling: Boolean;
    /// <summary>A ceiling that goes down does not go below the floor</summary>
    ClampCeilingLowerToFloor: Boolean;
    /// <summary>
    ///   A floor that goes down and finds an obstacle is put back; when it is False the floor
    ///   stays where it moved (Strife) and the step is not reported as crushed
    /// </summary>
    FloorLowerRestores: Boolean;
    /// <summary>A floor that goes up and crushes does not go back (when the crush flag is set)</summary>
    FloorRaiseCrushKeeps: Boolean;
    /// <summary>A ceiling that goes down and crushes does not go back (when the crush flag is set)</summary>
    CeilingLowerCrushKeeps: Boolean;
  end;

  /// <summary>
  ///   What a waggling floor (Hexen) keeps between two tics: the fields of floorWaggle_t after
  ///   the thinker and the sector
  /// </summary>
  TPlaneWaggleState = record
    OriginalHeight: Integer;
    Accumulator: Integer;
    AccDelta: Integer;
    TargetScale: Integer;
    Scale: Integer;
    ScaleDelta: Integer;
    Ticker: Integer;
    State: Integer;
  end;

const
  /// <summary>The waggle grows to its target scale (WGLSTATE_EXPAND)</summary>
  PLANE_WAGGLE_EXPAND = 1;
  /// <summary>The waggle has its full scale (WGLSTATE_STABLE)</summary>
  PLANE_WAGGLE_STABLE = 2;
  /// <summary>The waggle shrinks until it ends (WGLSTATE_REDUCE)</summary>
  PLANE_WAGGLE_REDUCE = 3;
  /// <summary>The entries of the table of the bobbing offsets (FLOATBOBSIZE)</summary>
  PLANE_BOB_TABLE_SIZE = 64;

implementation

end.

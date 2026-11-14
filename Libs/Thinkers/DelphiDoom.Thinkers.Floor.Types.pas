{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the types of the moving floors               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Floor.Types;

{$SCOPEDENUMS ON}

interface

type
  /// <summary>
  ///   The kinds of the classic floors of Doom and of Strife together (floor_e); a game never
  ///   makes the ones it does not have. The engine record keeps its own enumeration: the adapter
  ///   converts, so the order here does not matter for the savegames
  /// </summary>
  TFloorKind = (
    LowerFloor,
    LowerFloorToLowest,
    TurboLower,
    RaiseFloor,
    RaiseFloorToNearest,
    LowerFloorToNearest,
    LowerFloor24,
    LowerFloor32Turbo,
    RaiseToTexture,
    LowerAndChange,
    /// <summary>Strife</summary>
    RaiseFloor64,
    RaiseFloor24,
    RaiseFloor32Turbo,
    RaiseFloor24AndChange,
    RaiseFloorCrush,
    RaiseFloorTurbo,
    DonutRaise,
    RaiseFloor512,
    /// <summary>Strife</summary>
    RaiseFloor512AndChange,
    /// <summary>Boom: generalized mover that changes the texture</summary>
    GenFloorChg,
    /// <summary>Boom: generalized mover that changes the texture and zeroes the special</summary>
    GenFloorChg0,
    /// <summary>Boom: generalized mover that changes the texture and the special</summary>
    GenFloorChgT,
    /// <summary>Any other kind (stairs, plain generalized movers, scripted floors): nothing special</summary>
    Other
  );

  /// <summary>What a floor that arrived does to its sector</summary>
  TFloorAction = (
    /// <summary>The sector takes the special that the floor carries</summary>
    TransferSpecial,
    /// <summary>The sector takes also the old special that the floor carries (Boom)</summary>
    TransferOldSpecial,
    /// <summary>The sector takes the floor texture that the floor carries</summary>
    ChangeTexture
  );

  TFloorActions = set of TFloorAction;

  /// <summary>Where a new floor goes</summary>
  TFloorTarget = (
    /// <summary>The height of the floor plus Offset</summary>
    Relative,
    /// <summary>The highest floor around</summary>
    HighestFloor,
    /// <summary>The lowest floor around</summary>
    LowestFloor,
    /// <summary>The next floor around below this one</summary>
    NextLowestFloor,
    /// <summary>The next floor around above this one</summary>
    NextHighestFloor,
    /// <summary>The lowest ceiling around, not above the ceiling of the sector</summary>
    LowestCeiling,
    /// <summary>Up by the height of the shortest lower texture around</summary>
    ShortestTexture
  );

  /// <summary>What EV_DoFloor writes in a new floor of a kind</summary>
  TFloorPlan = record
    /// <summary>1 up, -1 down</summary>
    Direction: Integer;
    Speed: Integer;
    /// <summary>The floor crushes (the field is written only when True)</summary>
    Crush: Boolean;
    Target: TFloorTarget;
    /// <summary>For Relative: how far from the floor</summary>
    Offset: Integer;
    /// <summary>The sector takes at once texture and special of the front sector of the line</summary>
    ChangeFromLine: Boolean;
    /// <summary>With ChangeFromLine: the old special too (jff 3/14/98)</summary>
    ChangeOldSpecialToo: Boolean;
    /// <summary>The floor carries texture and special of the sector, or of its model sector</summary>
    CarriesModel: Boolean;
  end;

  /// <summary>The kinds of the classic stairs (stair_e of Doom and of Strife)</summary>
  TStairKind = (
    Build8,
    Turbo16,
    /// <summary>Strife: stairs that go down</summary>
    BuildDown16,
    /// <summary>A value that the game does not have: nothing moves</summary>
    Other
  );

  /// <summary>What EV_BuildStairs writes in the floors of a staircase</summary>
  TStairPlan = record
    Speed: Integer;
    /// <summary>The height of a step (negative: down)</summary>
    StepSize: Integer;
    Direction: Integer;
    /// <summary>The floor of the first sector has the kind of the stairs (in Strife it is left as it is)</summary>
    FirstIsStair: Boolean;
    /// <summary>The crush flag of the first step</summary>
    FirstCrush: Boolean;
    /// <summary>The crush flag of the steps after the first</summary>
    NextCrush: Boolean;
    /// <summary>The first sector loses its tag (Strife, haleyjd 20140919)</summary>
    ClearFirstTag: Boolean;
  end;

  /// <summary>
  ///   The differences between the floors of Doom and of Strife (the two old copies of p_floor):
  ///   the profile replaces the compiler switches and the copies of the code
  /// </summary>
  TFloorProfile = record
    /// <summary>The fast lowering floor stops 8 units above the highest floor around (not in Strife)</summary>
    TurboLowerStopsAbove: Boolean;
    /// <summary>The stairs are the ones of Strife: tag cleared, first step left plain, steps down</summary>
    StrifeStairs: Boolean;
  end;

const
  /// <summary>The normal speed of a floor (FLOORSPEED, one unit per tic)</summary>
  FLOOR_SPEED = 65536;
  /// <summary>The highest destination of a floor that rises by a texture (32000 units)</summary>
  FLOOR_TEXTURE_LIMIT = 32000;

implementation

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the values of the new scrollers              }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Scroll.Spawner;

// The speeds are 16.16 fixed point and the old code let the sums wrap
{$Q-}
{$R-}

interface

type
  /// <summary>How the special of a line drives its scrollers</summary>
  TScrollControl = (
    /// <summary>Constant speed, no control sector</summary>
    None,
    /// <summary>The sector of the first side moves the scroll when its heights change (245-249)</summary>
    Displacement,
    /// <summary>As Displacement, and the amounts add up (214-218)</summary>
    Accelerative
  );

  /// <summary>
  ///   What P_SpawnScrollers of Boom works out from the numbers of a line before it creates
  ///   the thinkers: the kind of control, the speeds and the vector of a wall scroller
  /// </summary>
  TScrollSpawner = class sealed
  public
    const
      /// <summary>Scroll effect ceiling</summary>
      SPECIAL_CEILING = 250;
      /// <summary>Scroll effect floor</summary>
      SPECIAL_FLOOR = 251;
      /// <summary>Carry objects on floor</summary>
      SPECIAL_CARRY = 252;
      /// <summary>Scroll and carry objects on floor</summary>
      SPECIAL_FLOOR_AND_CARRY = 253;
      /// <summary>Scroll wall according to linedef</summary>
      SPECIAL_WALL = 254;
      /// <summary>Scroll according to sidedef offsets</summary>
      SPECIAL_SIDE_OFFSETS = 255;
    /// <summary>
    ///   The special without its control: 245-249 and 214-218 are 250-254 with a control sector,
    ///   any other number is given back as it is with no control
    /// </summary>
    class function Decode(ASpecial: Integer; out AControl: TScrollControl): Integer; static;
    /// <summary>The scroll speed of a line long ALineDelta on an axis (one 32nd)</summary>
    class function LineSpeed(ALineDelta: Integer): Integer; static; inline;
    /// <summary>The speed of the things carried by a floor that scrolls at ASpeed (3/32)</summary>
    class function CarrySpeed(ASpeed: Integer): Integer; static;
    /// <summary>
    ///   The scroll of a wall for a movement (ADeltaX, ADeltaY) of the map: the part along the
    ///   line of the wall is horizontal, the part towards it is vertical
    /// </summary>
    class procedure WallVector(ADeltaX, ADeltaY, ALineDeltaX, ALineDeltaY: Integer;
      out AX, AY: Integer); static;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath, DelphiDoom.MathCore.TableFineSine,
  DelphiDoom.MathCore.TableTanToAngle;

const
  // Amount (dx,dy) vector linedef is shifted right to get scroll amount
  SCROLL_FACTOR = 32;
  // Factor to scale scrolling effect into mobj-carrying properties = 3/32
  CARRY_FACTOR = 6144;
  // FRACBITS - SLOPEBITS of the engine tables
  TANGENT_RANGE = 32;
  ANGLE_90 = Cardinal($40000000);
  ANGLE_TO_FINE_SHIFT = 19;

{ TScrollSpawner }

class function TScrollSpawner.Decode(ASpecial: Integer; out AControl: TScrollControl): Integer;
begin
  if (ASpecial >= 245) and (ASpecial <= 249) then
  begin
    AControl := TScrollControl.Displacement;
    Result := ASpecial + (250 - 245);
  end
  else if (ASpecial >= 214) and (ASpecial <= 218) then
  begin
    AControl := TScrollControl.Accelerative;
    Result := ASpecial + (250 - 214);
  end
  else
  begin
    AControl := TScrollControl.None;
    Result := ASpecial;
  end;
end;

class function TScrollSpawner.LineSpeed(ALineDelta: Integer): Integer;
begin
  Result := ALineDelta div SCROLL_FACTOR;
end;

class function TScrollSpawner.CarrySpeed(ASpeed: Integer): Integer;
begin
  Result := TFixedMath.Mul(ASpeed, CARRY_FACTOR);
end;

class procedure TScrollSpawner.WallVector(ADeltaX, ADeltaY, ALineDeltaX, ALineDeltaY: Integer;
  out AX, AY: Integer);
var
  LLong, LShort, LSwap, LLength: Integer;
  LAngle: Cardinal;
begin
  LLong := TFixedMath.AbsWrap(ALineDeltaX);
  LShort := TFixedMath.AbsWrap(ALineDeltaY);
  if LShort > LLong then
  begin
    LSwap := LLong;
    LLong := LShort;
    LShort := LSwap;
  end;
  // the length of the line from its longer side and the angle of the shorter one: no square
  // root, so that the scroll does not drift (killough 5/25/98)
  LAngle := TAN_TO_ANGLE_TABLE[TFixedMath.Divide(LShort, LLong) div TANGENT_RANGE] + ANGLE_90;
  LLength := TFixedMath.Divide(LLong, FINE_SINE_TABLE[LAngle shr ANGLE_TO_FINE_SHIFT]);
  AX := -TFixedMath.Divide(
    TFixedMath.Mul(ADeltaY, ALineDeltaY) + TFixedMath.Mul(ADeltaX, ALineDeltaX), LLength);
  AY := -TFixedMath.Divide(
    TFixedMath.Mul(ADeltaX, ALineDeltaY) - TFixedMath.Mul(ADeltaY, ALineDeltaX), LLength);
end;

end.

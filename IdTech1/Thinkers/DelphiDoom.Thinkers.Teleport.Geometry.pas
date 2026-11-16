{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the arithmetic of the teleports              }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Teleport.Geometry;

// Fixed point and angles: the old code let the sums and the products wrap and so does this one
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types,
  DelphiDoom.MathCore.Intf;

const
  /// <summary>How far from the exit the destination fog appears (20 units, as the old code wrote it)</summary>
  TELEPORT_FOG_DISTANCE = 20;
  /// <summary>TELEFOGHEIGHT (32 units): the fog of a thing that is not a missile is this high</summary>
  TELEPORT_FOG_HEIGHT = 32 * 65536;

type
  /// <summary>
  ///   The calculations shared by the teleports of all the games: where the fog goes, how the
  ///   momentum and the angle turn, which exit a teleport takes. Static and without state
  /// </summary>
  TTeleportGeometry = class
  public
    /// <summary>The x of the destination fog: the exit x moved 20 units in the direction of the exit angle</summary>
    class function FogX(AX: TFixed; AAngle: TAngle): TFixed; static;
    /// <summary>The y of the destination fog</summary>
    class function FogY(AY: TFixed; AAngle: TAngle): TFixed; static;
    /// <summary>The height of the fog above the thing: 0 for a missile, TELEPORT_FOG_HEIGHT for the others</summary>
    class function FogHeight(AIsMissile: Boolean): TFixed; static;
    /// <summary>The x momentum of a missile that leaves in the direction of an angle</summary>
    class function MissileMomentumX(ASpeed: TFixed; AAngle: TAngle): TFixed; static;
    /// <summary>The y momentum of a missile that leaves in the direction of an angle</summary>
    class function MissileMomentumY(ASpeed: TFixed; AAngle: TAngle): TFixed; static;
    /// <summary>The sine of an angle in the fine table</summary>
    class function SineOf(AAngle: TAngle): TFixed; static;
    /// <summary>The cosine of an angle in the fine table</summary>
    class function CosineOf(AAngle: TAngle): TFixed; static;
    /// <summary>The x of a momentum turned by the angle whose sine and cosine are given</summary>
    class function RotatedMomentumX(AMomentumX, AMomentumY, ASine, ACosine: TFixed): TFixed; static;
    /// <summary>The y of a momentum turned by the angle whose sine and cosine are given</summary>
    class function RotatedMomentumY(AMomentumX, AMomentumY, ASine, ACosine: TFixed): TFixed; static;
    /// <summary>
    ///   The angle that a silent teleport adds to a thing: the angle of the line it crosses, minus
    ///   the angle of the exit, plus a quarter of a turn (so that walking across the line makes
    ///   the thing leave in the direction of the exit)
    /// </summary>
    class function SilentExitAngle(ALineAngle, AExitAngle: TAngle): TAngle; static;
    /// <summary>
    ///   Which of ACount equal destinations a teleport takes, from 1 to ACount (one random number)
    /// </summary>
    class function PickDestination(ACount: Integer; const ARandom: IGameRandom): Integer; static;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath,
  DelphiDoom.MathCore.Trigonometry;

{ TTeleportGeometry }

class function TTeleportGeometry.FogX(AX: TFixed; AAngle: TAngle): TFixed;
begin
  Result := AX + TELEPORT_FOG_DISTANCE * TTrigonometry.FineCosine(AAngle shr ANGLETOFINESHIFT);
end;

class function TTeleportGeometry.FogY(AY: TFixed; AAngle: TAngle): TFixed;
begin
  Result := AY + TELEPORT_FOG_DISTANCE * TTrigonometry.FineSine(AAngle shr ANGLETOFINESHIFT);
end;

class function TTeleportGeometry.FogHeight(AIsMissile: Boolean): TFixed;
begin
  if AIsMissile then
    Result := 0
  else
    Result := TELEPORT_FOG_HEIGHT;
end;

class function TTeleportGeometry.MissileMomentumX(ASpeed: TFixed; AAngle: TAngle): TFixed;
begin
  Result := TFixedMath.Mul(ASpeed, TTrigonometry.FineCosine(AAngle shr ANGLETOFINESHIFT));
end;

class function TTeleportGeometry.MissileMomentumY(ASpeed: TFixed; AAngle: TAngle): TFixed;
begin
  Result := TFixedMath.Mul(ASpeed, TTrigonometry.FineSine(AAngle shr ANGLETOFINESHIFT));
end;

class function TTeleportGeometry.SineOf(AAngle: TAngle): TFixed;
begin
  Result := TTrigonometry.FineSine(AAngle shr ANGLETOFINESHIFT);
end;

class function TTeleportGeometry.CosineOf(AAngle: TAngle): TFixed;
begin
  Result := TTrigonometry.FineCosine(AAngle shr ANGLETOFINESHIFT);
end;

class function TTeleportGeometry.RotatedMomentumX(AMomentumX, AMomentumY, ASine,
  ACosine: TFixed): TFixed;
begin
  Result := TFixedMath.Mul(AMomentumX, ACosine) - TFixedMath.Mul(AMomentumY, ASine);
end;

class function TTeleportGeometry.RotatedMomentumY(AMomentumX, AMomentumY, ASine,
  ACosine: TFixed): TFixed;
begin
  Result := TFixedMath.Mul(AMomentumY, ACosine) + TFixedMath.Mul(AMomentumX, ASine);
end;

class function TTeleportGeometry.SilentExitAngle(ALineAngle, AExitAngle: TAngle): TAngle;
begin
  Result := ALineAngle - AExitAngle + TAngle(ANG90);
end;

class function TTeleportGeometry.PickDestination(ACount: Integer;
  const ARandom: IGameRandom): Integer;
begin
  Result := 1 + (ARandom.NextPlay mod ACount);
end;

end.

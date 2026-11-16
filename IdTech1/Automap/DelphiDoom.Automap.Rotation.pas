{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - the rotation of the points                    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.Rotation;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>
  ///   Rotation in 2D, used by the automap to turn the map around the player and to turn the
  ///   line characters (the old AM_rotate and AM_rotate_dbl). No state.
  /// </summary>
  /// <remarks>
  ///   The wraparound of the fixed point products is wanted (as in the old code), so the unit
  ///   turns overflow and range checks off.
  /// </remarks>
  TAutomapRotation = class
  public
    /// <summary>
    ///   Turns (AX, AY) by AAngle around (ACenterX, ACenterY) with the tables of the fixed angles
    ///   (the old AM_rotate): fast, with the resolution of 65536 angles
    /// </summary>
    class procedure Rotate(var AX, AY: TFixed; const AAngle: TAngle;
      const ACenterX, ACenterY: TFixed); static;
    /// <summary>
    ///   As Rotate but with the sine and the cosine in floating point, for characters that are
    ///   small and turn at any angle (the old AM_rotate_dbl)
    /// </summary>
    class procedure RotateExact(var AX, AY: TFixed; const AAngle: TAngle;
      const ACenterX, ACenterY: TFixed); static;
  end;

implementation

uses
  DelphiDoom.Automap.Types, DelphiDoom.MathCore.FixedMath, DelphiDoom.MathCore.Trigonometry;

{ TAutomapRotation }

class procedure TAutomapRotation.Rotate(var AX, AY: TFixed; const AAngle: TAngle;
  const ACenterX, ACenterY: TFixed);
var
  LTemporaryX: TFixed;
  LIndex: Integer;
begin
  LIndex := AAngle shr FIXED_FRACBITS;

  LTemporaryX := ACenterX +
    TFixedMath.Mul(AX - ACenterX, TTrigonometry.FixedCosine(LIndex)) -
    TFixedMath.Mul(AY - ACenterY, TTrigonometry.FixedSine(LIndex));

  AY := ACenterY +
    TFixedMath.Mul(AX - ACenterX, TTrigonometry.FixedSine(LIndex)) +
    TFixedMath.Mul(AY - ACenterY, TTrigonometry.FixedCosine(LIndex));

  AX := LTemporaryX;
end;

class procedure TAutomapRotation.RotateExact(var AX, AY: TFixed; const AAngle: TAngle;
  const ACenterX, ACenterY: TFixed);
var
  LTemporaryX: TFixed;
  LAngle: Double;
  LSine: Double;
  LCosine: Double;
begin
  LAngle := AAngle * AUTOMAP_ANGLE_TO_RADIANS;
  LSine := Sin(LAngle);
  LCosine := Cos(LAngle);
  LTemporaryX := ACenterX + Round((AX - ACenterX) * LCosine - (AY - ACenterY) * LSine);
  AY := ACenterY + Round((AX - ACenterX) * LSine + (AY - ACenterY) * LCosine);
  AX := LTemporaryX;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the table of the vertical angles of a shot       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): autoangle2 and              }
{  RF_InitTargets of r_public.pas                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.TargetAngles;

// the products of the table are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

const
  /// <summary>MAXAUTO: the side of the table, in steps of 4 units</summary>
  GREED_TARGET_ANGLE_SIZE = 16 * 16;

type
  /// <summary>
  ///   autoangle2: for a target that is ADistance steps away and AHeight steps higher (a step is 4 units), the
  ///   angle (0..192, 1024 in a turn) at which a shot has to climb to hit it; -1 where the original never wrote a
  ///   value. The table is made once, as RF_InitTargets does when the program starts
  /// </summary>
  TGreedTargetAngles = class
  strict private
    class var FAngles: array[0..GREED_TARGET_ANGLE_SIZE - 1, 0..GREED_TARGET_ANGLE_SIZE - 1] of Integer;
    class constructor Create;
  public
    /// <summary>autoangle2[ADistance][AHeight]; both must be in 0..GREED_TARGET_ANGLE_SIZE - 1</summary>
    class function Angle(ADistance, AHeight: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.FixedMath, DelphiDoom.MathCore.FixedMath, DelphiDoom.Greed.TrigTables;

const
  // g_PI of r_public_h.pas, not Pi
  GREED_PI = 3.14159265;
  // DEGREE45 + DEGREE45_2
  LAST_ANGLE = 128 + 64;

{ TGreedTargetAngles }

class constructor TGreedTargetAngles.Create;
var
  LArc, LScaled: Double;
  LStep, LAngle, LColumn, LRow, LIndex: Integer;
  LX, LY: TGreedFixed;
begin
  for LIndex := 0 to GREED_TARGET_ANGLE_SIZE - 1 do
    for LStep := 0 to GREED_TARGET_ANGLE_SIZE - 1 do
      FAngles[LIndex, LStep] := -1;
  LIndex := 0;
  repeat
    LArc := ArcTan(LIndex / GREED_TARGET_ANGLE_SIZE);
    LScaled := LArc * GREED_ANGLES / (2 * GREED_PI);
    // rint
    LAngle := Trunc(LScaled + 0.5);
    for LStep := 0 to GREED_TARGET_ANGLE_SIZE * 2 - 1 do
    begin
      LY := TGreedFixedMath.Mul(TGreedTrigTables.Sine(LAngle), LStep * GREED_FRACUNIT);
      LX := TGreedFixedMath.Mul(TGreedTrigTables.Cosine(LAngle), LStep * GREED_FRACUNIT);
      LColumn := LX div GREED_FRACUNIT;
      LRow := LY div GREED_FRACUNIT;
      if (LColumn >= GREED_TARGET_ANGLE_SIZE) or (LRow >= GREED_TARGET_ANGLE_SIZE) or
        (FAngles[LColumn][LRow] <> -1) then
        Continue;
      FAngles[LColumn][LRow] := LAngle;
    end;
    Inc(LIndex);
  until LAngle >= LAST_ANGLE;
  // the holes take the value under them (the original does it twice)
  for LStep := 1 to 2 do
    for LIndex := GREED_TARGET_ANGLE_SIZE - 1 downto 1 do
      for LColumn := 0 to GREED_TARGET_ANGLE_SIZE - 1 do
        if FAngles[LColumn][LIndex] = -1 then
          FAngles[LColumn][LIndex] := FAngles[LColumn][LIndex - 1];
end;

class function TGreedTargetAngles.Angle(ADistance, AHeight: Integer): Integer;
begin
  Result := FAngles[ADistance][AHeight];
end;

end.

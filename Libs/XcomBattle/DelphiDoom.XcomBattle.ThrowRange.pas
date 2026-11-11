{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - how far a unit can throw              }
{  (ProjectileFlyBState::validThrowRange and getMaxThrowDistance)               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.ThrowRange;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Action;

type
  /// <summary>The range of a throw, from the strength of the thrower and the weight of the item</summary>
  TXcomThrowRange = class
  public
    /// <summary>
    ///   getMaxThrowDistance: the distance in voxels a weight reaches, with the difference in height in voxels
    ///   between the thrower and the target. A strength of 0 is a division by zero in the C++ and an exception here
    /// </summary>
    class function MaxThrowDistance(AWeight, AStrength, ALevel: Integer): Integer; static;
    /// <summary>
    ///   validThrowRange: true when the target tile is within reach (every action that is not a throw is valid)
    /// </summary>
    class function IsValid(const AAction: TXcomBattleAction; const AOrigin: TXcomPosition;
      const ATarget: TXcomTile): Boolean; static;
  end;

implementation

const
  SStrengthZero = 'A unit with strength 0 cannot throw (division by zero in ProjectileFlyBState::getMaxThrowDistance)';

class function TXcomThrowRange.MaxThrowDistance(AWeight, AStrength, ALevel: Integer): Integer;
var
  LCurZ: Double;
  LDz: Double;
  LDist: Integer;
  LStep: Double;
begin
  if AStrength = 0 then
    raise EXcomBattleException.Create(SStrengthZero);
  LCurZ := ALevel + 0.5;
  LDz := 1.0;
  LDist := 0;
  while LDist < 4000 do
  begin
    Inc(LDist, 8);
    if LDz < -1 then
      LCurZ := LCurZ - 8
    else
    begin
      LStep := LDz * 8;
      LCurZ := LCurZ + LStep;
    end;
    if (LCurZ < 0) and (LDz < 0) then
    begin
      LDz := Max(LDz, -1.0);
      if Abs(LDz) > 1E-10 then
      begin
        LStep := LDist - LCurZ / LDz;
        LDist := Trunc(LStep);
      end;
      Break;
    end;
    LStep := (50 * AWeight) div AStrength;
    LDz := LDz - LStep / 100;
    if LDz <= -2.0 then
      Break;
  end;
  Result := LDist;
end;

class function TXcomThrowRange.IsValid(const AAction: TXcomBattleAction; const AOrigin: TXcomPosition;
  const ATarget: TXcomTile): Boolean;
const
  OFFSET = 2;
var
  LDeltaZ: Integer;
  LWeight: Integer;
  LMaxDistance: Double;
  LDeltaX: Integer;
  LDeltaY: Integer;
  LRealDistance: Double;
  LSum: Double;
begin
  if AAction.ActionType <> BA_THROW then
    Exit(True);
  LDeltaZ := AOrigin.Z - ((AAction.Target.Z * 24 + OFFSET) - ATarget.GetTerrainLevel);
  LWeight := AAction.Weapon.Rules.Weight;
  if Assigned(AAction.Weapon.AmmoItem) and (AAction.Weapon.AmmoItem <> AAction.Weapon) then
    Inc(LWeight, AAction.Weapon.AmmoItem.Rules.Weight);
  LMaxDistance := (MaxThrowDistance(LWeight, AAction.Actor.Stats.Strength, LDeltaZ) + 8) / 16.0;
  LDeltaX := AAction.Target.X - AAction.Actor.Position.X;
  LDeltaY := AAction.Target.Y - AAction.Actor.Position.Y;
  LSum := Double(LDeltaX * LDeltaX) + Double(LDeltaY * LDeltaY);
  LRealDistance := Sqrt(LSum);
  Result := LRealDistance <= LMaxDistance;
end;

end.

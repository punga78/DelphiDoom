{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixContactRules                              }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the tests of PIT_CheckThing (p_map.pas) and of P_LookForPlayers     }
{  (p_enemy.pas) that Rad-X added                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Physics.Contact;

interface

type
  /// <summary>
  ///   Two things of Radix that meet: the ones that do not block each other
  ///   (MF3_EX_DONTBLOCKSPECIES), the boxes that touch, the enemies that look for a pilot only
  ///   within their patrol range (MF3_EX_LIMITPATROLRANGE). Lengths are 16.16 fixed point
  /// </summary>
  TRadixContactRules = class
  public
    /// <summary>
    ///   True when two things pass through each other. Rad-X asked for the flag on both and
    ///   then for the same type, or for the same ancestor; but it compared the ancestor of the
    ///   mover with itself, so two things with the flag always pass: kept (AStrict = False).
    ///   With AStrict the ancestors of the two are compared, as it was meant
    /// </summary>
    class function PassesSpecies(AMoverHasFlag, AOtherHasFlag: Boolean; AMoverType, AOtherType, AMoverAncestor,
      AOtherAncestor: Integer; AStrict: Boolean = False): Boolean; static;
    /// <summary>
    ///   True when the boxes of two things overlap on the plane (the test of PIT_CheckThing): the
    ///   centres are nearer than the sum of the radii on both axes
    /// </summary>
    class function BoxesTouch(ADeltaX, ADeltaY, AFirstRadius, ASecondRadius: Integer): Boolean; static;
    /// <summary>True when two things overlap in height (AFirstZ and ASecondZ are their feet)</summary>
    class function HeightsTouch(AFirstZ, AFirstHeight, ASecondZ, ASecondHeight: Integer): Boolean; static;
    /// <summary>
    ///   True when an enemy can pick a pilot at that distance: always without a limited patrol
    ///   range, within the range (included) with it
    /// </summary>
    class function InPatrolRange(ALimited: Boolean; ADistance, APatrolRange: Integer): Boolean; static;
  end;

implementation

{ TRadixContactRules }

class function TRadixContactRules.PassesSpecies(AMoverHasFlag, AOtherHasFlag: Boolean; AMoverType, AOtherType,
  AMoverAncestor, AOtherAncestor: Integer; AStrict: Boolean): Boolean;
begin
  Result := False;
  if not (AMoverHasFlag and AOtherHasFlag) then
    Exit;
  if not AStrict then
    Result := True
  else
    Result := (AMoverType = AOtherType) or (AMoverAncestor = AOtherAncestor);
end;

class function TRadixContactRules.BoxesTouch(ADeltaX, ADeltaY, AFirstRadius, ASecondRadius: Integer): Boolean;
var
  LBlockDistance: Int64;
begin
  LBlockDistance := Int64(AFirstRadius) + ASecondRadius;
  Result := (Abs(Int64(ADeltaX)) < LBlockDistance) and (Abs(Int64(ADeltaY)) < LBlockDistance);
end;

class function TRadixContactRules.HeightsTouch(AFirstZ, AFirstHeight, ASecondZ, ASecondHeight: Integer): Boolean;
begin
  Result := (Int64(AFirstZ) <= Int64(ASecondZ) + ASecondHeight) and (Int64(AFirstZ) + AFirstHeight >= ASecondZ);
end;

class function TRadixContactRules.InPatrolRange(ALimited: Boolean; ADistance, APatrolRange: Integer): Boolean;
begin
  Result := not ALimited or (ADistance <= APatrolRange);
end;

end.

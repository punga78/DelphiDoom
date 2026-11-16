{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixCraftImpactRules                          }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of RX_PlaneHitWall and RX_PlaneHitFloor (radix_player.pas of Rad-X),   }
{  of the penalty of P_HitFloor (p_mobj.pas) and of the floor slide of         }
{  P_TryMove (p_map.pas)                                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Physics.Impact;

interface

{$SCOPEDENUMS ON}

type
  /// <summary>The sound of a craft that hits something</summary>
  TRadixImpactSound = (
    /// <summary>No sound (the last one still plays, or the craft is silent)</summary>
    None,
    /// <summary>radix/SndScrape: a sector of a level of Radix, and every ceiling</summary>
    Scrape,
    /// <summary>radix/SndPlaneHit: a sector that is not of Radix</summary>
    PlaneHit);

  /// <summary>What a hit of a craft does</summary>
  TRadixImpact = record
    /// <summary>False when nothing happens</summary>
    Hit: Boolean;
    /// <summary>The sound to start</summary>
    Sound: TRadixImpactSound;
    /// <summary>
    ///   True when the caller must wait for the length of a sound before the next one. A ceiling
    ///   asks for the length of the scrape even when the craft is silent (as Rad-X did)
    /// </summary>
    StartsSoundTimer: Boolean;
    /// <summary>What is added to the count of the hits of the debriefing (tics)</summary>
    Penalty: Integer;
    /// <summary>How many puffs of smoke are born around the craft</summary>
    Smokes: Integer;
  end;

  /// <summary>
  ///   A craft that hits a wall, a floor or a ceiling: no damage in Radix, only a sound, some
  ///   smoke and the count of the hits that lowers the "proficient flying" mark of the
  ///   debriefing. Speeds are 16.16 fixed point
  /// </summary>
  TRadixCraftImpactRules = class
  public const
    /// <summary>The tics of a second</summary>
    TICRATE = 35;
    /// <summary>A slower vertical speed does not count as a hit (4 map units a tic)</summary>
    SOFT_HIT_SPEED = 4 * 65536;
    /// <summary>A faster vertical speed is a hard hit (8 map units a tic)</summary>
    HARD_HIT_SPEED = 8 * 65536;
    /// <summary>The penalty of a blocked move against a wall (tics)</summary>
    WALL_PENALTY = 1;
    /// <summary>The penalty of a soft hit, and of a landing on a floor</summary>
    SOFT_PENALTY = TICRATE;
    /// <summary>The penalty of a hard hit</summary>
    HARD_PENALTY = 2 * TICRATE;
    /// <summary>The puffs of smoke of a soft hit</summary>
    SOFT_SMOKES = 8;
    /// <summary>The puffs of smoke of a hard hit</summary>
    HARD_SMOKES = 16;
  public
    /// <summary>A move of the craft that a wall or a thing blocked (RX_PlaneHitWall)</summary>
    /// <param name="ASoundTics">The tics left of the last sound of a hit</param>
    /// <param name="ASilent">MF3_EX_NOSOUND</param>
    /// <param name="ARadixSector">The sector of the craft comes from RADIX.DAT (RSF_RADIXSECTOR)</param>
    /// <param name="ARandom">A number 0..255 that is not of the game generator: the smoke is one time out of two</param>
    class function WallHit(ASoundTics: Integer; ASilent, ARadixSector: Boolean; ARandom: Integer): TRadixImpact; static;
    /// <summary>
    ///   A craft on a solid floor or under a solid ceiling (RX_PlaneHitFloor): nothing while the
    ///   last sound plays; the floor is looked at first, a floor that is too slow leaves the
    ///   ceiling its turn
    /// </summary>
    /// <param name="AVerticalSpeed">How far the craft has moved in height in the last tic</param>
    class function PlaneHit(ASoundTics: Integer; AOnFloor, AFloorIsSolid, AOnCeiling, ACeilingIsSolid, ASilent,
      ARadixSector: Boolean; AVerticalSpeed: Integer): TRadixImpact; static;
    /// <summary>
    ///   The penalty of a craft that lands on a floor (P_HitFloor of Rad-X): it was above the
    ///   floor and now lies on it, the floor is the plain one of its sector
    /// </summary>
    class function LandingPenalty(AWasAboveFloor, AOnFloor, APlainFloor: Boolean): Integer; static;
    /// <summary>
    ///   True when the heights of the place a craft moves to are checked: not while it slides on
    ///   a floor or a ceiling (floorslidetics of A_PlayerFloorSlide)
    /// </summary>
    class function ChecksHeights(AFloorSlideTics: Integer): Boolean; static;
    /// <summary>The tics of a count down after a tic (planehittics, floorslidetics)</summary>
    class function CountDown(ATics: Integer): Integer; static;
  end;

implementation

{ TRadixCraftImpactRules }

class function TRadixCraftImpactRules.WallHit(ASoundTics: Integer; ASilent, ARadixSector: Boolean;
  ARandom: Integer): TRadixImpact;
begin
  Result := Default(TRadixImpact);
  Result.Hit := True;
  Result.Penalty := WALL_PENALTY;
  if (ASoundTics <= 0) and not ASilent then
  begin
    if ARadixSector then
      Result.Sound := TRadixImpactSound.Scrape
    else
      Result.Sound := TRadixImpactSound.PlaneHit;
    Result.StartsSoundTimer := True;
  end;
  if ARandom < 128 then
    Result.Smokes := 1;
end;

class function TRadixCraftImpactRules.PlaneHit(ASoundTics: Integer; AOnFloor, AFloorIsSolid, AOnCeiling,
  ACeilingIsSolid, ASilent, ARadixSector: Boolean; AVerticalSpeed: Integer): TRadixImpact;
var
  LSpeed: Int64;
  LOnFloor: Boolean;
begin
  Result := Default(TRadixImpact);
  if ASoundTics > 0 then
    Exit;
  LSpeed := Abs(Int64(AVerticalSpeed));
  if LSpeed <= SOFT_HIT_SPEED then
    Exit;

  LOnFloor := AOnFloor and AFloorIsSolid;
  if not LOnFloor and not (AOnCeiling and ACeilingIsSolid) then
    Exit;

  Result.Hit := True;
  if LSpeed > HARD_HIT_SPEED then
  begin
    Result.Penalty := HARD_PENALTY;
    Result.Smokes := HARD_SMOKES;
  end
  else
  begin
    Result.Penalty := SOFT_PENALTY;
    Result.Smokes := SOFT_SMOKES;
  end;

  if LOnFloor then
  begin
    if not ASilent then
    begin
      if ARadixSector then
        Result.Sound := TRadixImpactSound.Scrape
      else
        Result.Sound := TRadixImpactSound.PlaneHit;
      Result.StartsSoundTimer := True;
    end;
  end
  else
  begin
    if not ASilent then
      Result.Sound := TRadixImpactSound.Scrape;
    Result.StartsSoundTimer := True;
  end;
end;

class function TRadixCraftImpactRules.LandingPenalty(AWasAboveFloor, AOnFloor, APlainFloor: Boolean): Integer;
begin
  if AWasAboveFloor and AOnFloor and APlainFloor then
    Result := SOFT_PENALTY
  else
    Result := 0;
end;

class function TRadixCraftImpactRules.ChecksHeights(AFloorSlideTics: Integer): Boolean;
begin
  Result := AFloorSlideTics <= 0;
end;

class function TRadixCraftImpactRules.CountDown(ATics: Integer): Integer;
begin
  if ATics > 0 then
    Result := ATics - 1
  else
    Result := ATics;
end;

end.

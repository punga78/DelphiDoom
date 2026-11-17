{******************************************************************************}
{                                                                              }
{  DelphiDoom: actions library - the MBF21 flag bits of a thing type           }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Actions.Mbf21Flags;

interface

const
  // The bits of the MBF21 "mbf21bits" field of a thing type (DEHACKED), in the order of the MBF21 specification
  // low gravity
  MF_MBF21_LOGRAV = 1;
  // short missile range
  MF_MBF21_SHORTMRANGE = 2;
  // other things ignore its attacks
  MF_MBF21_DMGIGNORED = 4;
  // doesn't take splash damage
  MF_MBF21_NORADIUSDMG = 8;
  // causes splash damage even if target immune
  MF_MBF21_FORCERADIUSDMG = $10;
  // higher missile attack probability
  MF_MBF21_HIGHERMPROB = $20;
  // use half distance for missile attack probability
  MF_MBF21_RANGEHALF = $40;
  // no targeting threshold
  MF_MBF21_NOTHRESHOLD = $80;
  // long melee range
  MF_MBF21_LONGMELEE = $100;
  // full volume see/death sound + splash immunity
  MF_MBF21_BOSS = $200;
  // Tag 666 "boss" on doom 2 map 7
  MF_MBF21_MAP07BOSS1 = $400;
  // Tag 667 "boss" on doom 2 map 7
  MF_MBF21_MAP07BOSS2 = $800;
  // E1M8 boss
  MF_MBF21_E1M8BOSS = $1000;
  // E2M8 boss
  MF_MBF21_E2M8BOSS = $2000;
  // E3M8 boss
  MF_MBF21_E3M8BOSS = $4000;
  // E4M6 boss
  MF_MBF21_E4M6BOSS = $8000;
  // E4M8 boss
  MF_MBF21_E4M8BOSS = $10000;
  // projectile rips through targets
  MF_MBF21_RIP = $20000;
  // full volume see/death sound
  MF_MBF21_FULLVOLSOUNDS = $40000;

type
  /// <summary>
  ///   The five flag words of a thing type that the MBF21 bits turn on or off (the fields flags, flags2,
  ///   flags_ex, flags2_ex and flags4_ex of the thing type). A game without the second word keeps it at 0
  /// </summary>
  TMbf21FlagWords = record
    Flags: Integer;
    Flags2: Integer;
    FlagsEx: Integer;
    Flags2Ex: Integer;
    Flags4Ex: Integer;
  end;

  /// <summary>
  ///   The masks of the engine flags that each MBF21 bit means, one profile for each game: a mask that the
  ///   game does not have is 0 (turning on a 0 mask changes nothing), so the code does not look at the game
  /// </summary>
  TMbf21Masks = record
    /// <summary>The gravity flag that low gravity turns off (MF_NOGRAVITY, in Flags)</summary>
    NoGravity: Integer;
    /// <summary>Low gravity in Flags2 (Heretic and Hexen); 0 elsewhere</summary>
    Flags2LowGravity: Integer;
    /// <summary>Low gravity in FlagsEx</summary>
    FlagsExLowGravity: Integer;
    /// <summary>The medium gravity that low gravity turns off (in Flags2Ex)</summary>
    Flags2ExMediumGravity: Integer;
    Flags4ExShortMissileRange: Integer;
    Flags4ExDamageIgnored: Integer;
    FlagsExNoRadiusDamage: Integer;
    Flags4ExForceRadiusDamage: Integer;
    Flags4ExHigherMissileProbability: Integer;
    Flags4ExRangeHalf: Integer;
    Flags4ExNoThreshold: Integer;
    Flags4ExLongMeleeRange: Integer;
    /// <summary>The boss flag in Flags2 (Heretic and Hexen); 0 elsewhere</summary>
    Flags2Boss: Integer;
    FlagsExBoss: Integer;
    Flags4ExMap07Boss1: Integer;
    Flags4ExMap07Boss2: Integer;
    /// <summary>The boss of the end of an episode of Doom (0 in the other games)</summary>
    Flags4ExE1M8Boss: Integer;
    Flags4ExE2M8Boss: Integer;
    Flags4ExE3M8Boss: Integer;
    Flags4ExE4M6Boss: Integer;
    Flags4ExE4M8Boss: Integer;
    /// <summary>Rip in Flags2 (Heretic and Hexen); where it is 0 the rip goes in Flags4Ex</summary>
    Flags2Rip: Integer;
    Flags4ExRip: Integer;
    Flags2ExFullVolumeDeath: Integer;
    Flags2ExFullVolumeSee: Integer;
  end;

  /// <summary>
  ///   P_ResolveMBF21Flags: the flags of the engine that the MBF21 bits of a thing type mean
  /// </summary>
  /// <remarks>
  ///   Cold code: once for each thing type with MBF21 bits, when a DEHACKED patch is applied. The masks come
  ///   from the game, as for TDefaultMusic: the unit does not know the flag tables of the games
  /// </remarks>
  TMbf21Flags = class sealed
  public
    /// <summary>Turns on the engine flags of the MBF21 bits (they never turn flags off, but low gravity)</summary>
    /// <param name="AMbf21Bits">The MBF21 bits of the thing type (MF_MBF21_*)</param>
    /// <param name="AMasks">The masks of the game</param>
    /// <param name="AWords">The flag words of the thing type, changed in place</param>
    class procedure Resolve(const AMbf21Bits: Integer; const AMasks: TMbf21Masks;
      var AWords: TMbf21FlagWords); static;
  end;

implementation

{ TMbf21Flags }

class procedure TMbf21Flags.Resolve(const AMbf21Bits: Integer; const AMasks: TMbf21Masks;
  var AWords: TMbf21FlagWords);
begin
  if AMbf21Bits and MF_MBF21_LOGRAV <> 0 then
  begin
    AWords.Flags := AWords.Flags and not AMasks.NoGravity;
    AWords.Flags2 := AWords.Flags2 or AMasks.Flags2LowGravity;
    AWords.FlagsEx := AWords.FlagsEx or AMasks.FlagsExLowGravity;
    AWords.Flags2Ex := AWords.Flags2Ex and not AMasks.Flags2ExMediumGravity;
  end;

  if AMbf21Bits and MF_MBF21_SHORTMRANGE <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExShortMissileRange;

  if AMbf21Bits and MF_MBF21_DMGIGNORED <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExDamageIgnored;

  if AMbf21Bits and MF_MBF21_NORADIUSDMG <> 0 then
    AWords.FlagsEx := AWords.FlagsEx or AMasks.FlagsExNoRadiusDamage;

  if AMbf21Bits and MF_MBF21_FORCERADIUSDMG <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExForceRadiusDamage;

  if AMbf21Bits and MF_MBF21_HIGHERMPROB <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExHigherMissileProbability;

  if AMbf21Bits and MF_MBF21_RANGEHALF <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExRangeHalf;

  if AMbf21Bits and MF_MBF21_NOTHRESHOLD <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExNoThreshold;

  if AMbf21Bits and MF_MBF21_LONGMELEE <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExLongMeleeRange;

  if AMbf21Bits and MF_MBF21_BOSS <> 0 then
  begin
    AWords.Flags2 := AWords.Flags2 or AMasks.Flags2Boss;
    AWords.FlagsEx := AWords.FlagsEx or AMasks.FlagsExBoss;
  end;

  if AMbf21Bits and MF_MBF21_MAP07BOSS1 <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExMap07Boss1;

  if AMbf21Bits and MF_MBF21_MAP07BOSS2 <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExMap07Boss2;

  if AMbf21Bits and MF_MBF21_E1M8BOSS <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExE1M8Boss;

  if AMbf21Bits and MF_MBF21_E2M8BOSS <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExE2M8Boss;

  if AMbf21Bits and MF_MBF21_E3M8BOSS <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExE3M8Boss;

  if AMbf21Bits and MF_MBF21_E4M6BOSS <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExE4M6Boss;

  if AMbf21Bits and MF_MBF21_E4M8BOSS <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExE4M8Boss;

  if AMbf21Bits and MF_MBF21_RIP <> 0 then
  begin
    // Heretic and Hexen keep the rip in the second word; the other games in the fourth extra word
    if AMasks.Flags2Rip <> 0 then
      AWords.Flags2 := AWords.Flags2 or AMasks.Flags2Rip
    else
      AWords.Flags4Ex := AWords.Flags4Ex or AMasks.Flags4ExRip;
  end;

  if AMbf21Bits and MF_MBF21_FULLVOLSOUNDS <> 0 then
  begin
    AWords.Flags2Ex := AWords.Flags2Ex or AMasks.Flags2ExFullVolumeDeath;
    AWords.Flags2Ex := AWords.Flags2Ex or AMasks.Flags2ExFullVolumeSee;
  end;
end;

end.

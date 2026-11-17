{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the MBF21 flag bits (P_ResolveMBF21Flags)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// The wraparound of the generator is wanted
{$Q-}{$R-}
unit DelphiDoom.Tests.Actions.Mbf21Flags;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Actions.Mbf21Flags;

type
  /// <summary>The games the old code told apart with the defines</summary>
  TOldGame = (ogDoom, ogHereticHexen, ogStrife);

  [TestFixture]
  [Category('actions')]
  TTestActionsMbf21Flags = class
  strict private
    FSeed: Cardinal;
    function NextRandom: Integer;
    function MasksOf(const AGame: TOldGame): TMbf21Masks;
    procedure OldResolve(const AGame: TOldGame; const ABits: Integer; var AWords: TMbf21FlagWords);
    procedure CompareAll(const AGame: TOldGame; const ARounds: Integer);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLasciareInvariatiIFlagSenzaBitMbf21;
    [Test]
    procedure DovrebbeSpegnereLaGravitaENonAltroConLograv;
    [Test]
    procedure DovrebbeMettereIlRipInFlags2DoveLaMascheraCe;
    [Test]
    procedure DovrebbeMettereIlRipInFlags4ExDoveFlags2NonCe;
    [Test]
    procedure DovrebbeIgnorareLeMascherePerLeQualiIlGiocoNonHaIFlag;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiDoomInOgniCombinazione;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiHereticEHexenInOgniCombinazione;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiStrifeInOgniCombinazione;
    [Test]
    procedure DovrebbeAvereIValoriDelleCostantiDellaSpecificaMbf21;
  end;

implementation

const
  // the bits of the masks of a game: distinct inside each word, as the real ones are
  M_NOGRAVITY = $200;
  M_FLAGS2_LOGRAV = $1;
  M_FLAGS2_RIP = $100;
  M_FLAGS2_BOSS = $8000;
  M_EX_LOWGRAVITY = $1000000;
  M_EX_NORADIUSDMG = $2000;
  M_EX_BOSS = $40000;
  M_EX2_MEDIUMGRAVITY = $1;
  M_EX2_FULLVOLDEATH = $200000;
  M_EX2_FULLVOLSEE = $400000;
  M_EX4_SHORTMRANGE = $40;
  M_EX4_DMGIGNORED = $80;
  M_EX4_FORCERADIUSDMG = $100;
  M_EX4_HIGHERMPROB = $200;
  M_EX4_RANGEHALF = $400;
  M_EX4_NOTHRESHOLD = $800;
  M_EX4_LONGMELEERANGE = $1000;
  M_EX4_MAP07BOSS1 = $2000;
  M_EX4_MAP07BOSS2 = $4000;
  M_EX4_E1M8BOSS = $20000;
  M_EX4_E2M8BOSS = $40000;
  M_EX4_E3M8BOSS = $80000;
  M_EX4_E4M6BOSS = $100000;
  M_EX4_E4M8BOSS = $200000;
  M_EX4_RIP = $4000000;

{ TTestActionsMbf21Flags }

procedure TTestActionsMbf21Flags.Setup;
begin
  FSeed := 12345;
end;

function TTestActionsMbf21Flags.NextRandom: Integer;
begin
  // a fixed generator: the tests do not change from run to run
  FSeed := FSeed * 1664525 + 1013904223;
  Result := Integer(FSeed);
end;

function TTestActionsMbf21Flags.MasksOf(const AGame: TOldGame): TMbf21Masks;
begin
  Result.NoGravity := M_NOGRAVITY;
  Result.FlagsExLowGravity := M_EX_LOWGRAVITY;
  Result.Flags2ExMediumGravity := M_EX2_MEDIUMGRAVITY;
  Result.Flags4ExShortMissileRange := M_EX4_SHORTMRANGE;
  Result.Flags4ExDamageIgnored := M_EX4_DMGIGNORED;
  Result.FlagsExNoRadiusDamage := M_EX_NORADIUSDMG;
  Result.Flags4ExForceRadiusDamage := M_EX4_FORCERADIUSDMG;
  Result.Flags4ExHigherMissileProbability := M_EX4_HIGHERMPROB;
  Result.Flags4ExRangeHalf := M_EX4_RANGEHALF;
  Result.Flags4ExNoThreshold := M_EX4_NOTHRESHOLD;
  Result.Flags4ExLongMeleeRange := M_EX4_LONGMELEERANGE;
  Result.FlagsExBoss := M_EX_BOSS;
  Result.Flags4ExMap07Boss1 := M_EX4_MAP07BOSS1;
  Result.Flags4ExMap07Boss2 := M_EX4_MAP07BOSS2;
  Result.Flags2ExFullVolumeDeath := M_EX2_FULLVOLDEATH;
  Result.Flags2ExFullVolumeSee := M_EX2_FULLVOLSEE;

  // what each game does not have is 0, as the masks of p_common
  Result.Flags2LowGravity := 0;
  Result.Flags2Boss := 0;
  Result.Flags2Rip := 0;
  Result.Flags4ExRip := 0;
  Result.Flags4ExE1M8Boss := 0;
  Result.Flags4ExE2M8Boss := 0;
  Result.Flags4ExE3M8Boss := 0;
  Result.Flags4ExE4M6Boss := 0;
  Result.Flags4ExE4M8Boss := 0;

  case AGame of
    ogDoom:
      begin
        Result.Flags4ExE1M8Boss := M_EX4_E1M8BOSS;
        Result.Flags4ExE2M8Boss := M_EX4_E2M8BOSS;
        Result.Flags4ExE3M8Boss := M_EX4_E3M8BOSS;
        Result.Flags4ExE4M6Boss := M_EX4_E4M6BOSS;
        Result.Flags4ExE4M8Boss := M_EX4_E4M8BOSS;
        Result.Flags4ExRip := M_EX4_RIP;
      end;
    ogHereticHexen:
      begin
        Result.Flags2LowGravity := M_FLAGS2_LOGRAV;
        Result.Flags2Boss := M_FLAGS2_BOSS;
        Result.Flags2Rip := M_FLAGS2_RIP;
      end;
    ogStrife:
      Result.Flags4ExRip := M_EX4_RIP;
  end;
end;

procedure TTestActionsMbf21Flags.OldResolve(const AGame: TOldGame; const ABits: Integer;
  var AWords: TMbf21FlagWords);
begin
  // P_ResolveMBF21Flags of p_common as it was, copied: the defines are the game of the call
  if ABits and MF_MBF21_LOGRAV <> 0 then
  begin
    AWords.Flags := AWords.Flags and not M_NOGRAVITY;
    if AGame = ogHereticHexen then
      AWords.Flags2 := AWords.Flags2 or M_FLAGS2_LOGRAV;
    AWords.FlagsEx := AWords.FlagsEx or M_EX_LOWGRAVITY;
    AWords.Flags2Ex := AWords.Flags2Ex and not M_EX2_MEDIUMGRAVITY;
  end;

  if ABits and MF_MBF21_SHORTMRANGE <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_SHORTMRANGE;

  if ABits and MF_MBF21_DMGIGNORED <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_DMGIGNORED;

  if ABits and MF_MBF21_NORADIUSDMG <> 0 then
    AWords.FlagsEx := AWords.FlagsEx or M_EX_NORADIUSDMG;

  if ABits and MF_MBF21_FORCERADIUSDMG <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_FORCERADIUSDMG;

  if ABits and MF_MBF21_HIGHERMPROB <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_HIGHERMPROB;

  if ABits and MF_MBF21_RANGEHALF <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_RANGEHALF;

  if ABits and MF_MBF21_NOTHRESHOLD <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_NOTHRESHOLD;

  if ABits and MF_MBF21_LONGMELEE <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_LONGMELEERANGE;

  if ABits and MF_MBF21_BOSS <> 0 then
  begin
    if AGame = ogHereticHexen then
      AWords.Flags2 := AWords.Flags2 or M_FLAGS2_BOSS;
    AWords.FlagsEx := AWords.FlagsEx or M_EX_BOSS;
  end;

  if ABits and MF_MBF21_MAP07BOSS1 <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_MAP07BOSS1;

  if ABits and MF_MBF21_MAP07BOSS2 <> 0 then
    AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_MAP07BOSS2;

  if ABits and MF_MBF21_E1M8BOSS <> 0 then
    if AGame = ogDoom then
      AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_E1M8BOSS;

  if ABits and MF_MBF21_E2M8BOSS <> 0 then
    if AGame = ogDoom then
      AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_E2M8BOSS;

  if ABits and MF_MBF21_E3M8BOSS <> 0 then
    if AGame = ogDoom then
      AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_E3M8BOSS;

  if ABits and MF_MBF21_E4M6BOSS <> 0 then
    if AGame = ogDoom then
      AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_E4M6BOSS;

  if ABits and MF_MBF21_E4M8BOSS <> 0 then
    if AGame = ogDoom then
      AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_E4M8BOSS;

  if ABits and MF_MBF21_RIP <> 0 then
  begin
    if AGame = ogHereticHexen then
      AWords.Flags2 := AWords.Flags2 or M_FLAGS2_RIP
    else
      AWords.Flags4Ex := AWords.Flags4Ex or M_EX4_RIP;
  end;

  if ABits and MF_MBF21_FULLVOLSOUNDS <> 0 then
  begin
    AWords.Flags2Ex := AWords.Flags2Ex or M_EX2_FULLVOLDEATH;
    AWords.Flags2Ex := AWords.Flags2Ex or M_EX2_FULLVOLSEE;
  end;
end;

procedure TTestActionsMbf21Flags.CompareAll(const AGame: TOldGame; const ARounds: Integer);
var
  LMasks: TMbf21Masks;
  LBits, LRound: Integer;
  LStart, LOld, LNew: TMbf21FlagWords;
  LFullBits: Integer;
begin
  LMasks := MasksOf(AGame);
  for LRound := 1 to ARounds do
  begin
    LStart.Flags := NextRandom;
    // a game without the second word has it at 0
    if AGame = ogHereticHexen then
      LStart.Flags2 := NextRandom
    else
      LStart.Flags2 := 0;
    LStart.FlagsEx := NextRandom;
    LStart.Flags2Ex := NextRandom;
    LStart.Flags4Ex := NextRandom;
    // the 19 bits of the specification in every combination; the bits over them are random and must not count
    for LBits := 0 to (1 shl 19) - 1 do
    begin
      LFullBits := LBits or (NextRandom and Integer($FFF80000));
      LOld := LStart;
      LNew := LStart;
      OldResolve(AGame, LFullBits, LOld);
      TMbf21Flags.Resolve(LFullBits, LMasks, LNew);
      if (LOld.Flags <> LNew.Flags) or (LOld.Flags2 <> LNew.Flags2) or (LOld.FlagsEx <> LNew.FlagsEx) or
        (LOld.Flags2Ex <> LNew.Flags2Ex) or (LOld.Flags4Ex <> LNew.Flags4Ex) then
        Assert.Fail(Format('Different result for the bits %x (game %d, round %d)', [LFullBits, Ord(AGame), LRound]));
    end;
  end;
  Assert.Pass;
end;

procedure TTestActionsMbf21Flags.DovrebbeLasciareInvariatiIFlagSenzaBitMbf21;
var
  LWords, LBefore: TMbf21FlagWords;
begin
  LWords.Flags := $12345678;
  LWords.Flags2 := $0F0F0F0F;
  LWords.FlagsEx := $7ABCDEF0;
  LWords.Flags2Ex := $13579BDF;
  LWords.Flags4Ex := $2468ACE0;
  LBefore := LWords;
  TMbf21Flags.Resolve(0, MasksOf(ogDoom), LWords);
  Assert.AreEqual(LBefore.Flags, LWords.Flags);
  Assert.AreEqual(LBefore.Flags2, LWords.Flags2);
  Assert.AreEqual(LBefore.FlagsEx, LWords.FlagsEx);
  Assert.AreEqual(LBefore.Flags2Ex, LWords.Flags2Ex);
  Assert.AreEqual(LBefore.Flags4Ex, LWords.Flags4Ex);
end;

procedure TTestActionsMbf21Flags.DovrebbeSpegnereLaGravitaENonAltroConLograv;
var
  LWords: TMbf21FlagWords;
begin
  LWords.Flags := M_NOGRAVITY or 1;
  LWords.Flags2 := 0;
  LWords.FlagsEx := 0;
  LWords.Flags2Ex := M_EX2_MEDIUMGRAVITY or $10;
  LWords.Flags4Ex := 0;
  TMbf21Flags.Resolve(MF_MBF21_LOGRAV, MasksOf(ogDoom), LWords);
  Assert.AreEqual(1, LWords.Flags);
  Assert.AreEqual(M_EX_LOWGRAVITY, LWords.FlagsEx);
  Assert.AreEqual($10, LWords.Flags2Ex);
  Assert.AreEqual(0, LWords.Flags4Ex);
end;

procedure TTestActionsMbf21Flags.DovrebbeMettereIlRipInFlags2DoveLaMascheraCe;
var
  LWords: TMbf21FlagWords;
begin
  LWords := Default(TMbf21FlagWords);
  TMbf21Flags.Resolve(MF_MBF21_RIP, MasksOf(ogHereticHexen), LWords);
  Assert.AreEqual(M_FLAGS2_RIP, LWords.Flags2);
  Assert.AreEqual(0, LWords.Flags4Ex);
end;

procedure TTestActionsMbf21Flags.DovrebbeMettereIlRipInFlags4ExDoveFlags2NonCe;
var
  LWords: TMbf21FlagWords;
begin
  LWords := Default(TMbf21FlagWords);
  TMbf21Flags.Resolve(MF_MBF21_RIP, MasksOf(ogStrife), LWords);
  Assert.AreEqual(0, LWords.Flags2);
  Assert.AreEqual(M_EX4_RIP, LWords.Flags4Ex);
end;

procedure TTestActionsMbf21Flags.DovrebbeIgnorareLeMascherePerLeQualiIlGiocoNonHaIFlag;
var
  LWords: TMbf21FlagWords;
begin
  LWords := Default(TMbf21FlagWords);
  TMbf21Flags.Resolve(MF_MBF21_E1M8BOSS or MF_MBF21_E2M8BOSS or MF_MBF21_E3M8BOSS or MF_MBF21_E4M6BOSS or
    MF_MBF21_E4M8BOSS, MasksOf(ogStrife), LWords);
  Assert.AreEqual(0, LWords.Flags4Ex);
end;

procedure TTestActionsMbf21Flags.DovrebbeEssereUgualeAlVecchioCodiceDiDoomInOgniCombinazione;
begin
  CompareAll(ogDoom, 2);
end;

procedure TTestActionsMbf21Flags.DovrebbeEssereUgualeAlVecchioCodiceDiHereticEHexenInOgniCombinazione;
begin
  CompareAll(ogHereticHexen, 2);
end;

procedure TTestActionsMbf21Flags.DovrebbeEssereUgualeAlVecchioCodiceDiStrifeInOgniCombinazione;
begin
  CompareAll(ogStrife, 2);
end;

procedure TTestActionsMbf21Flags.DovrebbeAvereIValoriDelleCostantiDellaSpecificaMbf21;
begin
  // the 19 bits of the specification, in a row: 1 shl 0 .. 1 shl 18
  Assert.AreEqual(1 shl 0, MF_MBF21_LOGRAV);
  Assert.AreEqual(1 shl 1, MF_MBF21_SHORTMRANGE);
  Assert.AreEqual(1 shl 2, MF_MBF21_DMGIGNORED);
  Assert.AreEqual(1 shl 3, MF_MBF21_NORADIUSDMG);
  Assert.AreEqual(1 shl 4, MF_MBF21_FORCERADIUSDMG);
  Assert.AreEqual(1 shl 5, MF_MBF21_HIGHERMPROB);
  Assert.AreEqual(1 shl 6, MF_MBF21_RANGEHALF);
  Assert.AreEqual(1 shl 7, MF_MBF21_NOTHRESHOLD);
  Assert.AreEqual(1 shl 8, MF_MBF21_LONGMELEE);
  Assert.AreEqual(1 shl 9, MF_MBF21_BOSS);
  Assert.AreEqual(1 shl 10, MF_MBF21_MAP07BOSS1);
  Assert.AreEqual(1 shl 11, MF_MBF21_MAP07BOSS2);
  Assert.AreEqual(1 shl 12, MF_MBF21_E1M8BOSS);
  Assert.AreEqual(1 shl 13, MF_MBF21_E2M8BOSS);
  Assert.AreEqual(1 shl 14, MF_MBF21_E3M8BOSS);
  Assert.AreEqual(1 shl 15, MF_MBF21_E4M6BOSS);
  Assert.AreEqual(1 shl 16, MF_MBF21_E4M8BOSS);
  Assert.AreEqual(1 shl 17, MF_MBF21_RIP);
  Assert.AreEqual(1 shl 18, MF_MBF21_FULLVOLSOUNDS);
end;

end.

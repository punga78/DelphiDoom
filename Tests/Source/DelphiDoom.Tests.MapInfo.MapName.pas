{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the names of the maps                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.MapName;

{$R-}
{$Q-}

interface

uses
  DUnitX.TestFramework, DelphiDoom.MapInfo.MapName;

type
  [TestFixture]
  [Category('mapinfo')]
  TTestMapInfoMapName = class
  strict private
    procedure CompareAll(const ARules: TMapNameRules; const AGame: Integer;
      const AMinimumLength: Integer);
  public
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiDoomSuTuttiINomiBrevi;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiHereticSuTuttiINomiBrevi;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiStrifeSuTuttiINomiBrevi;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDelComandoNewGame;
    [Test]
    procedure DovrebbeRifiutareUnNomeVuoto;
    [Test]
    procedure DovrebbeLasciareInvariatiIRisultatiSeIlNomeERifiutato;
    [Test]
    procedure DovrebbeDareINomiDelleMappe;
  end;

implementation

uses
  System.SysUtils;

// The routines of d_delphi the old code calls, copied as they were
function isdigit(const c: Char): Boolean;
begin
  Result := CharInSet(c, ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']);
end;

function IsIntegerInRange(const test, i1, i2: Integer): Boolean;
begin
  if i1 < i2 then
    Result := (test >= i1) and (test <= i2)
  else
    Result := (test >= i2) and (test <= i1);
end;

function strupper(const S: string): string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then
      Dec(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

function Pos1(const subs, s: string): Boolean;
begin
  Result := Copy(s, 1, Length(subs)) = subs;
end;

function CharPos(const ch: Char; const s: string): Integer;
begin
  Result := Pos(ch, s);
end;

function atoi(const s: string): Integer;
var
  code: Integer;
  ret2: Integer;
begin
  Val(s, Result, code);
  if code <> 0 then
  begin
    ret2 := 0;
    if Pos1('0x', s) then
      Val('$' + Copy(s, 3, Length(s) - 2), ret2, code)
    else if Pos1('-0x', s) then
    begin
      Val('$' + Copy(s, 4, Length(s) - 3), ret2, code);
      ret2 := -ret2;
    end
    else if CharPos('#', s) = 1 then
      Val(Copy(s, 2, Length(s) - 1), ret2, code);
    if code = 0 then
      Result := ret2
    else
      Result := 0;
  end;
end;

type
  TOldGameMode = (shareware, registered, commercial, retail);

var
  gamemode: TOldGameMode;

// The old G_ValidateMapName of the three games, copied as they were
{$I old_mn.inc}

// The old code of G_CmdNewGame of Doom, Heretic and Strife that reads the arguments, copied as it was
{$I old_ca.inc}

{ TTestMapInfoMapName }

procedure TTestMapInfoMapName.CompareAll(const ARules: TMapNameRules; const AGame: Integer;
  const AMinimumLength: Integer);
const
  ALPHABET = 'EMAPemap019x#$ -+';
var
  LLength: Integer;
  LName: string;
  LCounters: array[1..6] of Integer;
  LIndex: Integer;
  LOldResult: Boolean;
  LNewResult: Boolean;
  LOldEpisode, LOldMap, LNewEpisode, LNewMap: Integer;
  LCarry: Boolean;
begin
  for LLength := AMinimumLength to 5 do
  begin
    for LIndex := 1 to 6 do
      LCounters[LIndex] := 1;
    repeat
      SetLength(LName, LLength);
      for LIndex := 1 to LLength do
        LName[LIndex] := ALPHABET[LCounters[LIndex]];

      LOldEpisode := -77;
      LOldMap := -77;
      case AGame of
        0: LOldResult := OldDoomValidateMapName(LName, @LOldEpisode, @LOldMap);
        1: LOldResult := OldHereticValidateMapName(LName, @LOldEpisode, @LOldMap);
      else
        LOldResult := OldStrifeValidateMapName(LName, @LOldEpisode, @LOldMap);
      end;
      LNewEpisode := -77;
      LNewMap := -77;
      LNewResult := TMapName.TryParse(LName, ARules, LNewEpisode, LNewMap);

      if (LOldResult <> LNewResult) or (LOldEpisode <> LNewEpisode) or (LOldMap <> LNewMap) then
        Assert.Fail(Format('"%s": vecchio %s %d %d, nuovo %s %d %d',
          [LName, BoolToStr(LOldResult, True), LOldEpisode, LOldMap,
          BoolToStr(LNewResult, True), LNewEpisode, LNewMap]));

      // the next name: the counters are the digits of a number in base Length(ALPHABET)
      LIndex := 1;
      repeat
        Inc(LCounters[LIndex]);
        LCarry := LCounters[LIndex] > Length(ALPHABET);
        if LCarry then
        begin
          LCounters[LIndex] := 1;
          Inc(LIndex);
        end;
      until (not LCarry) or (LIndex > LLength);
    until LIndex > LLength;
  end;
end;

procedure TTestMapInfoMapName.DovrebbeEssereUgualeAlVecchioCodiceDiDoomSuTuttiINomiBrevi;
begin
  // the old code of Doom reads outside of the string under three characters
  CompareAll(TMapName.DoomRules, 0, 3);
end;

procedure TTestMapInfoMapName.DovrebbeEssereUgualeAlVecchioCodiceDiHereticSuTuttiINomiBrevi;
begin
  CompareAll(TMapName.HereticRules, 1, 1);
end;

procedure TTestMapInfoMapName.DovrebbeEssereUgualeAlVecchioCodiceDiStrifeSuTuttiINomiBrevi;
begin
  CompareAll(TMapName.StrifeRules, 2, 1);
end;

procedure TTestMapInfoMapName.DovrebbeEssereUgualeAlVecchioCodiceDelComandoNewGame;
const
  ARGUMENTS1: array[0..23] of string = ('1', '7', '12', 'map05', 'MAP32', 'Map1', 'e1m3', 'E2M9',
    'e1m', 'E1M1x', '0x10', '#7', '-0x1', 'abc', 'MAP#5', ' 5', 'E', 'M', 'e9m9', 'MAP', 'e1', '$A',
    'MAP0x', '3.5');
  ARGUMENTS2: array[0..5] of string = ('', '3', '0', 'x', '12', '0x2');
var
  LArgument1, LArgument2: string;
  LOldEpisode, LOldMap, LNewEpisode, LNewMap: Integer;
  LNumbered: Boolean;
  LGame: Integer;
begin
  for LArgument1 in ARGUMENTS1 do
    for LArgument2 in ARGUMENTS2 do
      for LGame := 0 to 3 do
      begin
        LOldEpisode := -77;
        LOldMap := -77;
        // 0 Doom 2, 1 Doom episodes, 2 Heretic, 3 Strife
        case LGame of
          0:
            begin
              gamemode := commercial;
              OldDoomCmdNewGame(LArgument1, LArgument2, LOldEpisode, LOldMap);
            end;
          1:
            begin
              gamemode := retail;
              OldDoomCmdNewGame(LArgument1, LArgument2, LOldEpisode, LOldMap);
            end;
          2: OldHereticCmdNewGame(LArgument1, LArgument2, LOldEpisode, LOldMap);
        else
          OldStrifeCmdNewGame(LArgument1, LArgument2, LOldEpisode, LOldMap);
          LOldEpisode := 0; // Strife has no episodes
        end;
        LNumbered := LGame in [0, 3];
        TMapName.FromArguments(LNumbered, LArgument1, LArgument2, LNewEpisode, LNewMap);
        if LGame = 3 then
          LNewEpisode := 0;
        if (LOldEpisode <> LNewEpisode) or (LOldMap <> LNewMap) then
          Assert.Fail(Format('"%s" "%s" gioco %d: vecchio %d %d, nuovo %d %d',
            [LArgument1, LArgument2, LGame, LOldEpisode, LOldMap, LNewEpisode, LNewMap]));
      end;
end;

procedure TTestMapInfoMapName.DovrebbeRifiutareUnNomeVuoto;
var
  LEpisode, LMap: Integer;
begin
  Assert.IsFalse(TMapName.TryParse('', TMapName.DoomRules, LEpisode, LMap));
  Assert.IsFalse(TMapName.TryParse('E', TMapName.DoomRules, LEpisode, LMap));
  Assert.IsFalse(TMapName.TryParse('EM', TMapName.DoomRules, LEpisode, LMap));
end;

procedure TTestMapInfoMapName.DovrebbeLasciareInvariatiIRisultatiSeIlNomeERifiutato;
var
  LEpisode, LMap: Integer;
begin
  LEpisode := 5;
  LMap := 6;
  Assert.IsFalse(TMapName.TryParse('E9M1', TMapName.DoomRules, LEpisode, LMap));
  Assert.AreEqual(5, LEpisode);
  Assert.AreEqual(6, LMap);
end;

procedure TTestMapInfoMapName.DovrebbeDareINomiDelleMappe;
begin
  Assert.AreEqual('E2M7', TMapName.EpisodeName(2, 7));
  Assert.AreEqual('MAP05', TMapName.NumberedName(5));
  Assert.AreEqual('MAP32', TMapName.NumberedName(32));
end;

end.

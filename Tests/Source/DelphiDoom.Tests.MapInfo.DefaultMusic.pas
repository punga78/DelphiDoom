{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the default music of a map (S_DefaultMusicForMap)      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.DefaultMusic;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.MapInfo.DefaultMusic;

type
  [TestFixture]
  [Category('mapinfo')]
  TTestMapInfoDefaultMusic = class
  strict private
    function OldDoom(const AMapInfoMusic: Integer; const ACommercial: Boolean; const AEpisode, AMap: Integer): Integer;
    function OldHeretic(const AMapInfoMusic, AEpisode, AMap: Integer): Integer;
    function OldStrife(const AMapInfoMusic, AMap: Integer): Integer;
  public
    [Test]
    procedure DovrebbeDareLaMusicaDellaVoceUmapinfoSeEPositiva;
    [Test]
    procedure DovrebbeSeguireLOrdineDelleMappeInDoom2;
    [Test]
    procedure DovrebbeDareLaPrimaMusicaPerLaMappa99;
    [Test]
    procedure DovrebbePrendereLaTabellaDelQuartoEpisodioDopoIlQuarto;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiDoomInOgniCombinazione;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiHereticInOgniCombinazione;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiStrifeInOgniCombinazione;
    [Test]
    procedure DovrebbeDareUnaMusicaPerMappaInHexen;
  end;

implementation

const
  // Ord(mus_e1m1) and Ord(mus_runnin) of the tables of the games (the songs of an episode are in a row)
  FIRST_EPISODE_SONG = 1;
  FIRST_COMMERCIAL_SONG = 40;
  // Ord(mus_e3m4), e3m2, e3m3, e1m5, e2m7, e2m4, e2m6, e2m5, e1m9 (offsets 21, 19, 20, 4, 15, 12, 14, 13, 8 from mus_e1m1)
  FOURTH: array[0..8] of Integer = (22, 20, 21, 5, 16, 13, 15, 14, 9);

function TTestMapInfoDefaultMusic.OldDoom(const AMapInfoMusic: Integer; const ACommercial: Boolean;
  const AEpisode, AMap: Integer): Integer;
begin
  // S_DefaultMusicForMap of Doom (s_sound), copied: the table of the E4 songs written by cases
  if AMapInfoMusic > 0 then
    Result := AMapInfoMusic
  else if ACommercial then
  begin
    if AMap = 99 then
      Result := FIRST_COMMERCIAL_SONG
    else
      Result := FIRST_COMMERCIAL_SONG + AMap - 1;
  end
  else
  begin
    if AEpisode < 5 then
      Result := FIRST_EPISODE_SONG + (AEpisode - 1) * 9 + AMap - 1
    else
    begin
      case AMap of
        1: Result := FIRST_EPISODE_SONG + 21;
        2: Result := FIRST_EPISODE_SONG + 19;
        3: Result := FIRST_EPISODE_SONG + 20;
        4: Result := FIRST_EPISODE_SONG + 4;
        5: Result := FIRST_EPISODE_SONG + 15;
        6: Result := FIRST_EPISODE_SONG + 12;
        7: Result := FIRST_EPISODE_SONG + 14;
        8: Result := FIRST_EPISODE_SONG + 13;
        9: Result := FIRST_EPISODE_SONG + 8;
      else
        Result := FIRST_EPISODE_SONG;
      end;
    end;
  end;
end;

function TTestMapInfoDefaultMusic.OldHeretic(const AMapInfoMusic, AEpisode, AMap: Integer): Integer;
begin
  if AMapInfoMusic > 0 then
    Result := AMapInfoMusic
  else if AEpisode < 6 then
    Result := FIRST_EPISODE_SONG + (AEpisode - 1) * 9 + AMap - 1
  else
  begin
    case AMap of
      1: Result := FIRST_EPISODE_SONG;
      2: Result := FIRST_EPISODE_SONG + 1;
      3: Result := FIRST_EPISODE_SONG + 2;
      4: Result := FIRST_EPISODE_SONG + 3;
      5: Result := FIRST_EPISODE_SONG + 4;
      6: Result := FIRST_EPISODE_SONG + 5;
      7: Result := FIRST_EPISODE_SONG + 6;
      8: Result := FIRST_EPISODE_SONG + 7;
      9: Result := FIRST_EPISODE_SONG + 8;
    else
      Result := FIRST_EPISODE_SONG;
    end;
  end;
end;

function TTestMapInfoDefaultMusic.OldStrife(const AMapInfoMusic, AMap: Integer): Integer;
begin
  if AMapInfoMusic > 0 then
    Result := AMapInfoMusic
  else if AMap <= 31 then
    Result := AMap + 1
  else
    Result := AMap - 30;
end;

procedure TTestMapInfoDefaultMusic.DovrebbeDareLaMusicaDellaVoceUmapinfoSeEPositiva;
begin
  Assert.AreEqual(77, TDefaultMusic.Strife(77, 5));
  Assert.AreEqual(6, TDefaultMusic.Strife(0, 5));
  Assert.AreEqual(6, TDefaultMusic.Strife(-3, 5));
  Assert.AreEqual(77, TDefaultMusic.Heretic(77, 1, 1, FIRST_EPISODE_SONG));
end;

procedure TTestMapInfoDefaultMusic.DovrebbeSeguireLOrdineDelleMappeInDoom2;
begin
  Assert.AreEqual(FIRST_COMMERCIAL_SONG + 4,
    TDefaultMusic.Doom(0, True, 1, 5, FIRST_EPISODE_SONG, FIRST_COMMERCIAL_SONG, FOURTH));
end;

procedure TTestMapInfoDefaultMusic.DovrebbeDareLaPrimaMusicaPerLaMappa99;
begin
  Assert.AreEqual(FIRST_COMMERCIAL_SONG,
    TDefaultMusic.Doom(0, True, 1, 99, FIRST_EPISODE_SONG, FIRST_COMMERCIAL_SONG, FOURTH));
end;

procedure TTestMapInfoDefaultMusic.DovrebbePrendereLaTabellaDelQuartoEpisodioDopoIlQuarto;
begin
  Assert.AreEqual(FOURTH[0],
    TDefaultMusic.Doom(0, False, 5, 1, FIRST_EPISODE_SONG, FIRST_COMMERCIAL_SONG, FOURTH));
  Assert.AreEqual(FIRST_EPISODE_SONG,
    TDefaultMusic.Doom(0, False, 5, 10, FIRST_EPISODE_SONG, FIRST_COMMERCIAL_SONG, FOURTH));
end;

procedure TTestMapInfoDefaultMusic.DovrebbeEssereUgualeAlVecchioCodiceDiDoomInOgniCombinazione;
var
  LInfo, LEpisode, LMap: Integer;
  LCommercial: Boolean;
begin
  for LInfo := -1 to 2 do
    for LCommercial := False to True do
      for LEpisode := 0 to 8 do
        for LMap := -2 to 105 do
          Assert.AreEqual(OldDoom(LInfo * 50, LCommercial, LEpisode, LMap),
            TDefaultMusic.Doom(LInfo * 50, LCommercial, LEpisode, LMap, FIRST_EPISODE_SONG,
            FIRST_COMMERCIAL_SONG, FOURTH),
            Format('info %d commercial %s episode %d map %d', [LInfo, BoolToStr(LCommercial, True), LEpisode, LMap]));
end;

procedure TTestMapInfoDefaultMusic.DovrebbeEssereUgualeAlVecchioCodiceDiHereticInOgniCombinazione;
var
  LInfo, LEpisode, LMap: Integer;
begin
  for LInfo := -1 to 2 do
    for LEpisode := 0 to 9 do
      for LMap := -2 to 12 do
        Assert.AreEqual(OldHeretic(LInfo * 50, LEpisode, LMap),
          TDefaultMusic.Heretic(LInfo * 50, LEpisode, LMap, FIRST_EPISODE_SONG),
          Format('info %d episode %d map %d', [LInfo, LEpisode, LMap]));
end;

procedure TTestMapInfoDefaultMusic.DovrebbeEssereUgualeAlVecchioCodiceDiStrifeInOgniCombinazione;
var
  LInfo, LMap: Integer;
begin
  for LInfo := -1 to 2 do
    for LMap := -2 to 70 do
      Assert.AreEqual(OldStrife(LInfo * 50, LMap), TDefaultMusic.Strife(LInfo * 50, LMap),
        Format('info %d map %d', [LInfo, LMap]));
end;

procedure TTestMapInfoDefaultMusic.DovrebbeDareUnaMusicaPerMappaInHexen;
begin
  Assert.AreEqual(10, TDefaultMusic.Hexen(1, 10));
  Assert.AreEqual(19, TDefaultMusic.Hexen(10, 10));
end;

end.

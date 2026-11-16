{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the limits of the episode and the map of a new game    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.NewGameLimits;

interface

uses
  DUnitX.TestFramework, DelphiDoom.MapInfo.NewGameLimits;

type
  [TestFixture]
  [Category('mapinfo')]
  TTestMapInfoNewGameLimits = class
  public
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiDoomSuTuttiIPunti;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiHereticSuTuttiIPunti;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiStrifeSuTuttiIPunti;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiHexenSuTuttiIPunti;
    [Test]
    procedure DovrebbeLasciareLeMappeSegreteDiDoomComeSono;
    [Test]
    procedure DovrebbeLasciareInvariatoIlNumeroSeLaMappaEsiste;
  end;

implementation

type
  TOldGameMode = (shareware, registered, commercial, retail, extendedwad);
  TOldCustomGame = (cg_none, cg_chex, cg_chex2, cg_hacx);

var
  gamemode: TOldGameMode;
  customgame: TOldCustomGame;

// The first part of G_InitNew, copied as it was; the test of the map in the WADs is the
// parameter missing
procedure OldDoom(const missing: Boolean; var episode, map: Integer);
begin
  if episode < 1 then
    episode := 1;

  if missing then
    if not (((episode = 9) and (map = 9)) or ((map = 99) and (episode = 0))) then
    begin
      if gamemode = retail then
      begin
        if episode > 4 then
          episode := 4;
      end
      else if gamemode = shareware then
      begin
        if episode > 1 then
          episode := 1;  // only start episode 1 on shareware
      end
      else
      begin
        if episode > 3 then
          episode := 3;
      end;

      if map < 1 then
        map := 1;

      if (map > 9) and (gamemode <> commercial) then
        map := 9;

      // JVAL: Chex Support
      if customgame in [cg_chex, cg_chex2] then
      begin
        if map > 5 then
          map := 5;
        if episode > 1 then
          episode := 1;
      end;

      // JVAL: Hacx Support
      if customgame = cg_hacx then
      begin
        if map > 20 then
          map := 20;
        if episode > 1 then
          episode := 1;
      end;
    end;
end;

procedure OldHeretic(const missing: Boolean; var episode, map: Integer);
begin
  if episode < 1 then
    episode := 1;

  if map < 1 then
    map := 1
  else if map > 9 then
    map := 9;

  if missing then
  begin
    if gamemode = shareware then
    begin
      if episode > 1 then
       episode := 1;  // only start episode 1 on shareware
    end
    else
    begin
      if gamemode = extendedwad then
      begin
        if episode > 5 then
          episode := 5;
      end
      else
      begin
        if episode > 3 then
          episode := 3;
      end;
    end;
  end;
end;

procedure OldStrife(var map: Integer);
begin
  if gamemode = shareware then
  begin
    if not (map in [32, 33, 34]) then
      map := 32;
  end
  else
  begin
    if map > 34 then
      map := 1;
  end;

  if map < 1 then
    map := 1;
end;

procedure OldHexen(var map: Integer);
begin
  if map < 1 then
    map := 1
  else if map > 99 then
    map := 99;
end;

function ToEdition(const AMode: TOldGameMode): TNewGameEdition;
begin
  case AMode of
    shareware: Result := ngeShareware;
    registered: Result := ngeRegistered;
    commercial: Result := ngeCommercial;
    retail: Result := ngeRetail;
  else
    Result := ngeExtended;
  end;
end;

function ToCustom(const ACustom: TOldCustomGame): TNewGameCustom;
begin
  case ACustom of
    cg_chex, cg_chex2: Result := ngcChex;
    cg_hacx: Result := ngcHacx;
  else
    Result := ngcNone;
  end;
end;

{ TTestMapInfoNewGameLimits }

procedure TTestMapInfoNewGameLimits.DovrebbeEssereUgualeAlVecchioCodiceDiDoomSuTuttiIPunti;
var
  LMode: TOldGameMode;
  LCustom: TOldCustomGame;
  LMissing: Boolean;
  LEpisode, LMap, LOldEpisode, LOldMap, LNewEpisode, LNewMap: Integer;
begin
  for LMode := Low(TOldGameMode) to High(TOldGameMode) do
    for LCustom := Low(TOldCustomGame) to High(TOldCustomGame) do
      for LMissing := False to True do
        for LEpisode := -2 to 12 do
          for LMap := -2 to 105 do
          begin
            gamemode := LMode;
            customgame := LCustom;
            LOldEpisode := LEpisode;
            LOldMap := LMap;
            OldDoom(LMissing, LOldEpisode, LOldMap);
            LNewEpisode := LEpisode;
            LNewMap := LMap;
            TNewGameLimits.Doom(LMissing, ToEdition(LMode), ToCustom(LCustom), LNewEpisode, LNewMap);
            Assert.AreEqual(LOldEpisode, LNewEpisode, 'episode');
            Assert.AreEqual(LOldMap, LNewMap, 'map');
          end;
end;

procedure TTestMapInfoNewGameLimits.DovrebbeEssereUgualeAlVecchioCodiceDiHereticSuTuttiIPunti;
var
  LMode: TOldGameMode;
  LMissing: Boolean;
  LEpisode, LMap, LOldEpisode, LOldMap, LNewEpisode, LNewMap: Integer;
begin
  for LMode := Low(TOldGameMode) to High(TOldGameMode) do
    for LMissing := False to True do
      for LEpisode := -2 to 12 do
        for LMap := -2 to 30 do
        begin
          gamemode := LMode;
          LOldEpisode := LEpisode;
          LOldMap := LMap;
          OldHeretic(LMissing, LOldEpisode, LOldMap);
          LNewEpisode := LEpisode;
          LNewMap := LMap;
          TNewGameLimits.Heretic(LMissing, ToEdition(LMode), LNewEpisode, LNewMap);
          Assert.AreEqual(LOldEpisode, LNewEpisode, 'episode');
          Assert.AreEqual(LOldMap, LNewMap, 'map');
        end;
end;

procedure TTestMapInfoNewGameLimits.DovrebbeEssereUgualeAlVecchioCodiceDiStrifeSuTuttiIPunti;
var
  LMode: TOldGameMode;
  LMap, LOldMap, LNewMap: Integer;
begin
  for LMode := Low(TOldGameMode) to High(TOldGameMode) do
    for LMap := -5 to 120 do
    begin
      gamemode := LMode;
      LOldMap := LMap;
      OldStrife(LOldMap);
      LNewMap := LMap;
      TNewGameLimits.Strife(ToEdition(LMode), LNewMap);
      Assert.AreEqual(LOldMap, LNewMap, 'map');
    end;
end;

procedure TTestMapInfoNewGameLimits.DovrebbeEssereUgualeAlVecchioCodiceDiHexenSuTuttiIPunti;
var
  LMap, LOldMap, LNewMap: Integer;
begin
  for LMap := -5 to 150 do
  begin
    LOldMap := LMap;
    OldHexen(LOldMap);
    LNewMap := LMap;
    TNewGameLimits.Hexen(LNewMap);
    Assert.AreEqual(LOldMap, LNewMap, 'map');
  end;
end;

procedure TTestMapInfoNewGameLimits.DovrebbeLasciareLeMappeSegreteDiDoomComeSono;
var
  LEpisode, LMap: Integer;
begin
  LEpisode := 9;
  LMap := 9;
  TNewGameLimits.Doom(True, ngeShareware, ngcNone, LEpisode, LMap);
  Assert.AreEqual(9, LEpisode);
  Assert.AreEqual(9, LMap);
  LEpisode := 0;
  LMap := 99;
  TNewGameLimits.Doom(True, ngeRetail, ngcChex, LEpisode, LMap);
  // The test of (0, 99) comes after the episode was brought to 1: it never applied, and the
  // map is clamped (a defect of the old code, kept)
  Assert.AreEqual(1, LEpisode);
  Assert.AreEqual(5, LMap);
end;

procedure TTestMapInfoNewGameLimits.DovrebbeLasciareInvariatoIlNumeroSeLaMappaEsiste;
var
  LEpisode, LMap: Integer;
begin
  LEpisode := 7;
  LMap := 40;
  TNewGameLimits.Doom(False, ngeShareware, ngcNone, LEpisode, LMap);
  Assert.AreEqual(7, LEpisode);
  Assert.AreEqual(40, LMap);
end;

end.

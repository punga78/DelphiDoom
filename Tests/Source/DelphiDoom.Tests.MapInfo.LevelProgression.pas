{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the order of the maps                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.LevelProgression;

interface

uses
  DUnitX.TestFramework, DelphiDoom.MapInfo.LevelProgression;

type
  [TestFixture]
  [Category('mapinfo')]
  TTestMapInfoLevelProgression = class
  public
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiDoomSuTuttiIPunti;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiHereticSuTuttiIPunti;
    [Test]
    procedure DovrebbeLasciareIlNumeroSeLeRegoleNonDannoNulla;
    [Test]
    procedure DovrebbeDireQualiMappeDiDoom2HannoIlFinale;
  end;

implementation

uses
  System.SysUtils;

type
  TOldGameMode = (shareware, registered, commercial, retail);
  TOldCustomGame = (cg_none, cg_bfg2);

var
  gamemode: TOldGameMode;
  customgame: TOldCustomGame;
  secretexit: Boolean;
  gamemap: Integer;
  gameepisode: Integer;
  wminfo: record
    next: Integer;
  end;

// The default order of the maps of G_DoCompleted, copied as it was
{$I old_lp.inc}

{ TTestMapInfoLevelProgression }

procedure TTestMapInfoLevelProgression.DovrebbeEssereUgualeAlVecchioCodiceDiDoomSuTuttiIPunti;
var
  LCommercial, LSecret, LBfg: Boolean;
  LEpisode, LMap, LNew: Integer;
begin
  for LCommercial := False to True do
    for LSecret := False to True do
      for LBfg := False to True do
        for LEpisode := 0 to 6 do
          for LMap := 0 to 40 do
          begin
            if LCommercial then
              gamemode := commercial
            else
              gamemode := retail;
            if LBfg then
              customgame := cg_bfg2
            else
              customgame := cg_none;
            secretexit := LSecret;
            gameepisode := LEpisode;
            gamemap := LMap;
            wminfo.next := -99;
            OldDoomNext;
            LNew := -99;
            TLevelProgression.DoomNextMap(LCommercial, LSecret, LBfg, LEpisode, LMap, LNew);
            if wminfo.next <> LNew then
              Assert.Fail(Format('commerciale %s segreta %s episodio %d mappa %d: vecchio %d, nuovo %d',
                [BoolToStr(LCommercial, True), BoolToStr(LSecret, True), LEpisode, LMap,
                wminfo.next, LNew]));
          end;
end;

procedure TTestMapInfoLevelProgression.DovrebbeEssereUgualeAlVecchioCodiceDiHereticSuTuttiIPunti;
var
  LSecret: Boolean;
  LEpisode, LMap, LNew: Integer;
begin
  for LSecret := False to True do
    for LEpisode := 0 to 7 do
      for LMap := 0 to 12 do
      begin
        secretexit := LSecret;
        gameepisode := LEpisode;
        gamemap := LMap;
        wminfo.next := -99;
        OldHereticNext;
        LNew := -99;
        TLevelProgression.HereticNextMap(LSecret, LEpisode, LMap, LNew);
        Assert.AreEqual(wminfo.next, LNew);
      end;
end;

procedure TTestMapInfoLevelProgression.DovrebbeLasciareIlNumeroSeLeRegoleNonDannoNulla;
var
  LNext: Integer;
begin
  LNext := 55;
  TLevelProgression.DoomNextMap(True, True, False, 1, 7, LNext);
  Assert.AreEqual(55, LNext);
  LNext := 55;
  TLevelProgression.HereticNextMap(False, 9, 9, LNext);
  Assert.AreEqual(55, LNext);
end;

procedure TTestMapInfoLevelProgression.DovrebbeDireQualiMappeDiDoom2HannoIlFinale;
begin
  Assert.IsTrue(TLevelProgression.DoomCommercialFinale(False, 30));
  Assert.IsFalse(TLevelProgression.DoomCommercialFinale(False, 15));
  Assert.IsTrue(TLevelProgression.DoomCommercialFinale(True, 15));
  Assert.IsFalse(TLevelProgression.DoomCommercialFinale(True, 7));
end;

end.

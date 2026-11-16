{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of what happens when a level ends (G_DoCompleted)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.LevelExit;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapInfo.LevelExit;

type
  [TestFixture]
  [Category('mapinfo')]
  TTestMapInfoLevelExit = class
  strict private
    procedure OldDoom(const ACommercial: Boolean; const ACustom: TLevelExitCustom;
      const AMap: Integer; out AVictory, ASecret: Boolean);
    procedure OldHeretic(const ACustom: TLevelExitCustom; const AMap: Integer;
      out AVictory, ASecret: Boolean);
  public
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiDoomInOgniCombinazione;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiHereticInOgniCombinazione;
    [Test]
    procedure DovrebbePreferireLaMappaSegretaDopoUnUscitaSegreta;
    [Test]
    procedure DovrebbeUsareLaMappaNormaleSeLaSegretaManca;
  end;

implementation

{ TTestMapInfoLevelExit }

procedure TTestMapInfoLevelExit.OldDoom(const ACommercial: Boolean;
  const ACustom: TLevelExitCustom; const AMap: Integer; out AVictory, ASecret: Boolean);
begin
  // the start of G_DoCompleted of Doom, copied (gameaction := ga_victory is AVictory,
  // players[i].didsecret := true is ASecret)
  AVictory := False;
  ASecret := False;

  if not ACommercial then
  begin
    case AMap of
      8:
        begin
          AVictory := True;
          Exit;
        end;
      9: ASecret := True;
    end;
  end;

  if ACustom = lecChex then
    if AMap = 5 then
    begin
      AVictory := True;
      Exit;
    end;

  if ACustom = lecHacx then
    if AMap = 20 then
    begin
      AVictory := True;
      Exit;
    end;
end;

procedure TTestMapInfoLevelExit.OldHeretic(const ACustom: TLevelExitCustom; const AMap: Integer;
  out AVictory, ASecret: Boolean);
begin
  // the start of G_DoCompleted of Heretic, copied
  AVictory := False;
  ASecret := False;
  case AMap of
    3:
      begin
        if ACustom = lecBeta then
        begin
          AVictory := True;
          Exit;
        end;
      end;
    8:
      begin
        AVictory := True;
        Exit;
      end;
    9: ASecret := True;
  end;
end;

procedure TTestMapInfoLevelExit.DovrebbeEssereUgualeAlVecchioCodiceDiDoomInOgniCombinazione;
var
  LCommercial: Boolean;
  LCustom: TLevelExitCustom;
  LMap: Integer;
  LVictory, LSecret: Boolean;
  LVerdict: TLevelExitVerdict;
begin
  for LCommercial := False to True do
    for LCustom := Low(TLevelExitCustom) to High(TLevelExitCustom) do
      for LMap := 0 to 40 do
      begin
        OldDoom(LCommercial, LCustom, LMap, LVictory, LSecret);
        LVerdict := TLevelExit.Check(legDoom, LCommercial, LCustom, LMap);
        Assert.AreEqual(LVictory, LVerdict.Victory, Format('vittoria mappa %d', [LMap]));
        Assert.AreEqual(LSecret, LVerdict.SecretForAll, Format('segreto mappa %d', [LMap]));
      end;
end;

procedure TTestMapInfoLevelExit.DovrebbeEssereUgualeAlVecchioCodiceDiHereticInOgniCombinazione;
var
  LCommercial: Boolean;
  LCustom: TLevelExitCustom;
  LMap: Integer;
  LVictory, LSecret: Boolean;
  LVerdict: TLevelExitVerdict;
begin
  // Heretic has no commercial case: the flag must not matter
  for LCommercial := False to True do
    for LCustom := Low(TLevelExitCustom) to High(TLevelExitCustom) do
      for LMap := 0 to 40 do
      begin
        OldHeretic(LCustom, LMap, LVictory, LSecret);
        LVerdict := TLevelExit.Check(legHeretic, LCommercial, LCustom, LMap);
        Assert.AreEqual(LVictory, LVerdict.Victory, Format('vittoria mappa %d', [LMap]));
        Assert.AreEqual(LSecret, LVerdict.SecretForAll, Format('segreto mappa %d', [LMap]));
      end;
end;

procedure TTestMapInfoLevelExit.DovrebbePreferireLaMappaSegretaDopoUnUscitaSegreta;
begin
  Assert.AreEqual('MAP31', TLevelExit.PickNextMapName(True, 'MAP31', 'MAP16'));
  Assert.AreEqual('MAP16', TLevelExit.PickNextMapName(False, 'MAP31', 'MAP16'));
end;

procedure TTestMapInfoLevelExit.DovrebbeUsareLaMappaNormaleSeLaSegretaManca;
begin
  Assert.AreEqual('MAP16', TLevelExit.PickNextMapName(True, '', 'MAP16'));
  Assert.AreEqual('', TLevelExit.PickNextMapName(True, '', ''));
end;

end.

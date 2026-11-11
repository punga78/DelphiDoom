{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom basescape library - the grid of a base and the }
{  little maps against a frame of the real OpenXcom (skipped without the data)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.BaseViewParity;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Tests.XcomGeoscape.World;

type
  /// <summary>
  ///   The basescape of the new game of the real OpenXcom (nightly 2026-06-05, TFTD): the 6 x 6 grid of the starting
  ///   base and the little maps are drawn with the library and compared, in RGB, with the frame (twice the size)
  /// </summary>
  [TestFixture]
  [Category('XcomGeoscape')]
  TTestXcomBaseViewParity = class
  strict private
    FWorld: TXcomGeoWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDisegnareLaBaseDiPartenzaComeIlVeroOpenXcom;
  end;

implementation

uses
  DelphiDoom.Png.Provider, DelphiDoom.Png.Client, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.NewGame, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.DefaultSettings,
  DelphiDoom.XcomBasescape.BaseView, DelphiDoom.XcomBasescape.MiniBaseView, DelphiDoom.Tests.XcomGeoscape.Host;

procedure TTestXcomBaseViewParity.Setup;
begin
  FWorld := TXcomGeoWorld.Create;
end;

procedure TTestXcomBaseViewParity.TearDown;
begin
  FWorld.Free;
end;

procedure TTestXcomBaseViewParity.DovrebbeDisegnareLaBaseDiPartenzaComeIlVeroOpenXcom;
var
  LPath: string;
  LFrame: TPngIndexedImage;
  LRules: TXcomRulesetRules;
  LSave: TXcomSavedGame;
  LHost: TXcomClockHost;
  LView: TXcomBaseView;
  LMini: TXcomMiniBaseView;
  LTarget: TXcomSurface;
  LPalette: TXcomPalette;
  LColors: array[0..255] of TXcomColor;
  LIndex, LX, LY, LCompared, LDifferent, LRealIndex, LRealColor, LColor: Integer;
  LStatePalette: TArray<TXcomColor>;
begin
  LPath := TPath.Combine(TPath.Combine(FWorld.Root, 'golden_geoscape'), 'base.png');
  if not (FWorld.HasData and TFile.Exists(LPath)) then
    Exit;
  LFrame := TPngProvider.Client.DecodeIndexed(TFile.ReadAllBytes(LPath));
  // PAL_BASESCAPE is the second palette of PALETTES.DAT
  LPalette := FWorld.GamePalette(1);
  SetLength(LStatePalette, 256);
  for LIndex := 0 to 255 do
  begin
    LColors[LIndex] := LPalette.Colors[LIndex];
    LStatePalette[LIndex] := LPalette.Colors[LIndex];
  end;
  LRules := TXcomRulesetRules.Create(FWorld.Rules.Ruleset);
  LSave := TXcomNewGame.Create(FWorld.Rules.Ruleset, LRules, TXcomDefaultSaveSettings.Create,
    TXcomRandom.Create(1)).NewSave;
  LHost := TXcomClockHost.Create;
  try
    FWorld.Rules.SetPalette(LStatePalette, 0);
    LView := TXcomBaseView.Create(LHost.Clock, FWorld.Rules.Ruleset, 192, 192, 0, 8);
    LMini := TXcomMiniBaseView.Create(FWorld.Rules.Ruleset, 128, 16, 192, 41);
    LTarget := TXcomSurface.Create(320, 200);
    try
      LTarget.SetColors(LColors);
      LView.SetPalette(@LColors[0], 0, 256);
      LMini.SetPalette(@LColors[0], 0, 256);
      LView.SetTexture(FWorld.Rules.GetSurfaceSet('BASEBITS.PCK'));
      LMini.SetTexture(FWorld.Rules.GetSurfaceSet('BASEBITS.PCK'));
      LMini.SetBases(LSave.Bases);
      // the interface "basescape": the elements baseView (213, 16) and miniBase (8, 80)
      LView.SetColor(213);
      LView.SetSecondaryColor(16);
      LMini.SetColor(8);
      LMini.SetSecondaryColor(80);
      LMini.SetSelectedBase(0);
      LView.SetBase(LSave.Bases.First);
      LView.Blit(LTarget);
      LMini.Blit(LTarget);
      LCompared := 0;
      LDifferent := 0;
      for LY := 16 to 199 * 2 do
        for LX := 0 to 639 do
        begin
          // the part of the screen of the two views (the name, the region and the funds are other widgets)
          if not (((LX < 384) and (LY >= 16)) or ((LX >= 384) and (LY >= 82) and (LY < 114))) then
            Continue;
          LRealIndex := LFrame.Pixels[LY * 640 + LX];
          LRealColor := (LFrame.Palette[LRealIndex * 4] shl 16) or (LFrame.Palette[LRealIndex * 4 + 1] shl 8) or
            LFrame.Palette[LRealIndex * 4 + 2];
          LIndex := LTarget.GetPixel(LX div 2, LY div 2);
          LColor := (LColors[LIndex].Blue shl 16) or (LColors[LIndex].Green shl 8) or LColors[LIndex].Red;
          Inc(LCompared);
          if LColor <> LRealColor then
            Inc(LDifferent);
        end;
      Assert.IsTrue(LCompared > 100000, 'pixels compared ' + IntToStr(LCompared));
      Assert.AreEqual(0, LDifferent, 'pixels that differ');
    finally
      LTarget.Free;
      LMini.Free;
      LView.Free;
    end;
  finally
    LHost.Free;
    LSave.Free;
    LRules.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomBaseViewParity);

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom geoscape library - the globe against a frame   }
{  of the real OpenXcom (skipped when the data and the frame are missing)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.GlobeParity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Tests.XcomGeoscape.World;

type
  /// <summary>
  ///   The real OpenXcom (nightly 2026-06-05, TFTD, window of 640 x 400, geoscape of 320 x 200 shown at twice the size)
  ///   draws the globe of a new game with a noise that rand() makes and that depends on what the program did before:
  ///   the frame says what it was. For every cell of the noise the values 0..3 are tried and the pixels of the frame
  ///   must agree with at least one value: a pixel that no value explains is an error of the drawing
  /// </summary>
  [TestFixture]
  [Category('XcomGeoscape')]
  TTestXcomGlobeParity = class
  strict private
    FWorld: TXcomGeoWorld;
    function FramePath(const AName: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDisegnareIlGloboDiUnaPartitaNuovaComeIlVeroOpenXcom;
  end;

implementation

uses
  DelphiDoom.Png.Provider, DelphiDoom.Png.Client, DelphiDoom.Xcom.Palette, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.NewGame,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.DefaultSettings, DelphiDoom.XcomGeoscape.Globe,
  DelphiDoom.Tests.XcomGeoscape.Host;

procedure TTestXcomGlobeParity.Setup;
begin
  FWorld := TXcomGeoWorld.Create;
end;

procedure TTestXcomGlobeParity.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomGlobeParity.FramePath(const AName: string): string;
begin
  Result := TPath.Combine(TPath.Combine(FWorld.Root, 'golden_geoscape'), AName);
end;

procedure TTestXcomGlobeParity.DovrebbeDisegnareIlGloboDiUnaPartitaNuovaComeIlVeroOpenXcom;
const
  WIDTH = 256;
  HEIGHT = 200;
  SCREEN_WIDTH = 640;
var
  LRules: TXcomRulesetRules;
  LSave: TXcomSavedGame;
  LHost: TXcomClockHost;
  LGlobe: TXcomGlobe;
  LTarget: TXcomSurface;
  LFrame: TPngIndexedImage;
  LRendered: array[0..3] of TBytes;
  LNoise: TArray<SmallInt>;
  LMatch: array of Byte;
  LValue, LX, LY, LCell, LCompared, LHard, LBaseX, LBaseY, LRealIndex: Integer;
  LMask: Byte;
  LRealColor, LColor, LIndex: Integer;
  LPalette: TXcomPalette;
  LLon, LLat: Double;
  LFirst: string;
begin
  if not (FWorld.HasData and TFile.Exists(FramePath('newgame.png'))) then
    Exit;
  LPalette := FWorld.GeoscapePalette;
  LFrame := TPngProvider.Client.DecodeIndexed(TFile.ReadAllBytes(FramePath('newgame.png')));
  LRules := TXcomRulesetRules.Create(FWorld.Rules.Ruleset);
  LSave := TXcomNewGame.Create(FWorld.Rules.Ruleset, LRules, TXcomDefaultSaveSettings.Create,
    TXcomRandom.Create(1)).NewSave;
  LHost := TXcomClockHost.Create;
  try
    LGlobe := TXcomGlobe.Create(LHost, LSave, FWorld.Rules.Ruleset, FWorld.Rules.GetSurfaceSet('TEXTURE.DAT'),
      FWorld.Rules.GetSurfaceSet('GlobeMarkers'), WIDTH div 2, HEIGHT div 2, WIDTH, HEIGHT, 0, 0);
    try
      // the frame was taken while the choice of the site of the first base had the mouse at (238, 343) of the window
      LGlobe.RadarLines := True;
      LGlobe.SetNewBaseHover(True);
      Assert.IsTrue(LGlobe.CartToPolar(238 div 2, 343 div 2, LLon, LLat));
      LGlobe.SetNewBaseHoverPos(LLon, LLat);
      SetLength(LNoise, TXcomGlobe.NOISE_SIZE * TXcomGlobe.NOISE_SIZE);
      for LValue := 0 to 3 do
      begin
        for LCell := 0 to High(LNoise) do
          LNoise[LCell] := LValue;
        LGlobe.SetNoise(LNoise);
        LGlobe.Draw;
        // what the screen shows: the globe with the radars, the borders and the markers over it
        LTarget := TXcomSurface.Create(WIDTH, HEIGHT);
        try
          LGlobe.Blit(LTarget);
          LRendered[LValue] := System.Copy(LTarget.Pixels);
        finally
          LTarget.Free;
        end;
      end;
      // the cell of the noise that a pixel uses: bit v set if the value v gives the pixel of the frame
      SetLength(LMatch, TXcomGlobe.NOISE_SIZE * TXcomGlobe.NOISE_SIZE);
      for LCell := 0 to High(LMatch) do
        LMatch[LCell] := 15;
      LCompared := 0;
      LHard := 0;
      LFirst := '';
      for LY := 60 to 2 * HEIGHT - 1 do
        for LX := 0 to 2 * WIDTH - 1 do
        begin
          // the mouse cursor
          if (LX >= 225) and (LX < 262) and (LY >= 335) and (LY < 372) then
            Continue;
          LBaseX := LX div 2;
          LBaseY := LY div 2;
          if LRendered[0][LBaseY * WIDTH + LBaseX] = 0 then
            Continue;
          // the png of the frame is indexed but its palette is in order of appearance: the colors are compared
          LRealIndex := LFrame.Pixels[LY * SCREEN_WIDTH + LX];
          LRealColor := (LFrame.Palette[LRealIndex * 4] shl 16) or (LFrame.Palette[LRealIndex * 4 + 1] shl 8) or
            LFrame.Palette[LRealIndex * 4 + 2];
          Inc(LCompared);
          LMask := 0;
          for LValue := 0 to 3 do
          begin
            LIndex := LRendered[LValue][LBaseY * WIDTH + LBaseX];
            LColor := (LPalette.Colors[LIndex].Blue shl 16) or (LPalette.Colors[LIndex].Green shl 8) or
              LPalette.Colors[LIndex].Red;
            if LColor = LRealColor then
              LMask := LMask or (1 shl LValue);
          end;
          if LMask = 0 then
          begin
            Inc(LHard);
            if Length(LFirst) < 300 then
              LFirst := LFirst + Format(' (%d,%d:%x/%d)', [LX, LY, LRealColor, LRendered[0][LBaseY * WIDTH + LBaseX]]);
          end
          else
            LMatch[(LBaseY mod 60) * 60 + (LBaseX mod 60)] := LMatch[(LBaseY mod 60) * 60 + (LBaseX mod 60)] and LMask;
        end;
      LCell := 0;
      for LValue := 0 to High(LMatch) do
        if LMatch[LValue] = 0 then
          Inc(LCell);
      Assert.IsTrue(LCompared > 40000, 'pixels compared ' + IntToStr(LCompared));
      Assert.AreEqual(0, LHard, 'pixels that no noise explains:' + LFirst);
      Assert.AreEqual(0, LCell, 'cells of the noise with no value');
    finally
      LGlobe.Free;
    end;
  finally
    LHost.Free;
    LSave.Free;
    LRules.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomGlobeParity);

end.

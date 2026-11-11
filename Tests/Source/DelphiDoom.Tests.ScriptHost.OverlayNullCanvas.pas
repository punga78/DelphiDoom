{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the canvas of an overlay with no screen                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.OverlayNullCanvas;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Overlay.Intf,
  DelphiDoom.ScriptHost.Overlay.NullCanvas,
  DelphiDoom.ScriptHost.Overlay.Types;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostOverlayNullCanvas = class(TObject)
  strict private
    FCanvas: IOverlayCanvas;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeAvereLoSchermoDelBuffer;
    [Test]
    procedure DovrebbeNonAvereTempoNeColoriNePatchNeFont;
    [Test]
    procedure DovrebbeNonFareNullaPerAvvisiAreaModificataEFlash;
  end;

implementation

{ TTestScriptHostOverlayNullCanvas }

procedure TTestScriptHostOverlayNullCanvas.Setup;
begin
  FCanvas := TOverlayNullCanvas.Create;
end;

procedure TTestScriptHostOverlayNullCanvas.DovrebbeAvereLoSchermoDelBuffer;
begin
  Assert.AreEqual(OVERLAYWIDTH, FCanvas.ScreenWidth);
  Assert.AreEqual(OVERLAYHEIGHT, FCanvas.ScreenHeight);
end;

procedure TTestScriptHostOverlayNullCanvas.DovrebbeNonAvereTempoNeColoriNePatchNeFont;
begin
  Assert.AreEqual(0, FCanvas.LevelTime);
  Assert.AreEqual(Byte(0), FCanvas.FindColorIndex(255, 255, 255));
  Assert.IsTrue(FCanvas.FindPatchLump('ANY') < 0);
  Assert.IsNull(FCanvas.CachePatch(0));
  Assert.IsNull(FCanvas.FontPatch('A'));
  Assert.IsFalse(FCanvas.IsFirstInterpolation);
end;

procedure TTestScriptHostOverlayNullCanvas.DovrebbeNonFareNullaPerAvvisiAreaModificataEFlash;
var
  LData: TOverlayFlashData;
begin
  FCanvas.Warning('ignored');
  FCanvas.MarkScreenDirty;
  FillChar(LData, SizeOf(LData), 0);
  FCanvas.Flash(LData);
  Assert.IsTrue(True);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptHostOverlayNullCanvas);

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the functions of the unit PS_OVERLAY                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.OverlayFunctions;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Overlay.Drawer,
  DelphiDoom.ScriptHost.Overlay.Functions,
  DelphiDoom.ScriptHost.Overlay.Intf,
  DelphiDoom.Tests.ScriptHost.Fakes,
  DelphiDoom.Tests.ScriptHost.OverlayFakes;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostOverlayFunctions = class(TObject)
  strict private
    FCanvas: TFakeOverlayCanvas;
    FCanvasRef: IOverlayCanvas;
    FDrawer: TOverlayDrawer;
    FSection: IScriptFunctionSection;
    FFunctions: TScriptOverlayFunctions;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareEccezioneSeLaFunzioneDellOverlayENil;
    [Test]
    procedure DovrebbeDescrivereLeDieciFunzioniNellOrdineEConLeDichiarazioniDiPrima;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniComeMetodiDellOggetto;
    [Test]
    procedure DovrebbeInoltrareOgniFunzioneAllOverlay;
    [Test]
    procedure DovrebbeSvuotareLOverlayConOverlayClear;
    [Test]
    procedure DovrebbeNonFareNullaSeLOverlayNonCe;
    [Test]
    procedure DovrebbeChiedereLOverlayOgniVolta;
  end;

implementation

const
  EXPECTED_DECLARATIONS: array[0..9] of string = (
    'procedure OverlayClear;',
    'procedure OverlayDrawPatch(const ticks: Integer; const patchname: string; const x, y: Integer);',
    'procedure OverlayDrawPatchStretched(const ticks: Integer; const patchname: string; const x1, y1, x2, y2: Integer);',
    'procedure OverlayDrawPixel(const ticks: Integer; const red, green, blue : byte; const x, y : Integer);',
    'procedure OverlayDrawRect(const ticks: Integer; const red, green, blue: byte; const x1, y1, x2, y2: Integer);',
    'procedure OverlayDrawLine(const ticks: Integer; const red, green, blue: byte; const x1, y1, x2, y2: Integer);',
    'procedure OverlayDrawText(const ticks: Integer; const txt: string; const align: Integer; const x, y: Integer);',
    'procedure OverlayDrawLeftText(const ticks: Integer; const txt: string; const x, y: Integer);',
    'procedure OverlayDrawRightText(const ticks: Integer; const txt: string; const x, y: Integer);',
    'procedure OverlayDrawCenterText(const ticks: Integer; const txt: string; const x, y: Integer);');

{ TTestScriptHostOverlayFunctions }

procedure TTestScriptHostOverlayFunctions.Setup;
begin
  FCanvas := TFakeOverlayCanvas.Create;
  FCanvasRef := FCanvas;
  FCanvas.AddPatch('PATCH', TFakeOverlayCanvas.BuildPatch(1, 1, 0, 0, [9]));
  FDrawer := TOverlayDrawer.CreateWithCanvas(FCanvasRef);
  FFunctions := TScriptOverlayFunctions.Create(
    function: TOverlayDrawer
    begin
      Result := FDrawer;
    end);
  FSection := FFunctions;
end;

procedure TTestScriptHostOverlayFunctions.TearDown;
begin
  FSection := nil;
  FFunctions := nil;
  FDrawer.Free;
  FCanvasRef := nil;
end;

procedure TTestScriptHostOverlayFunctions.DovrebbeDareEccezioneSeLaFunzioneDellOverlayENil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptOverlayFunctions.Create(nil);
    end,
    EArgumentNilException);
end;

procedure TTestScriptHostOverlayFunctions.DovrebbeDescrivereLeDieciFunzioniNellOrdineEConLeDichiarazioniDiPrima;
var
  LTable: TFakeFunctionTable;
  LTableRef: IScriptFunctionTable;
  LIndex: Integer;
begin
  LTable := TFakeFunctionTable.Create;
  LTableRef := LTable;
  FSection.Describe(LTableRef);
  Assert.AreEqual(10, LTable.Declarations.Count);
  for LIndex := 0 to 9 do
    Assert.AreEqual(EXPECTED_DECLARATIONS[LIndex], LTable.Declarations[LIndex]);
end;

procedure TTestScriptHostOverlayFunctions.DovrebbeDescrivereLeFunzioniComeMetodiDellOggetto;
var
  LTable: TFakeFunctionTable;
  LTableRef: IScriptFunctionTable;
  LIndex: Integer;
begin
  LTable := TFakeFunctionTable.Create;
  LTableRef := LTable;
  FSection.Describe(LTableRef);
  for LIndex := 0 to 9 do
  begin
    Assert.IsTrue(LTable.Instances[LIndex] = FFunctions);
    Assert.IsNotNull(LTable.Codes[LIndex]);
  end;
end;

procedure TTestScriptHostOverlayFunctions.DovrebbeInoltrareOgniFunzioneAllOverlay;
begin
  FFunctions.OverlayDrawPatch(10, 'PATCH', 1, 2);
  FFunctions.OverlayDrawPatchStretched(10, 'PATCH', 0, 0, 2, 2);
  FFunctions.OverlayDrawPixel(10, 1, 2, 3, 4, 5);
  FFunctions.OverlayDrawRect(10, 1, 2, 3, 0, 0, 1, 1);
  FFunctions.OverlayDrawLine(10, 1, 2, 3, 0, 0, 5, 5);
  FFunctions.OverlayDrawText(10, 'A', 0, 0, 0);
  FFunctions.OverlayDrawLeftText(10, 'A', 0, 0);
  FFunctions.OverlayDrawRightText(10, 'A', 0, 0);
  FFunctions.OverlayDrawCenterText(10, 'A', 0, 0);
  Assert.AreEqual(9, FDrawer.NumDrawers);
end;

procedure TTestScriptHostOverlayFunctions.DovrebbeSvuotareLOverlayConOverlayClear;
begin
  FFunctions.OverlayDrawPixel(10, 1, 2, 3, 4, 5);
  FFunctions.OverlayClear;
  Assert.AreEqual(0, FDrawer.NumDrawers);
end;

procedure TTestScriptHostOverlayFunctions.DovrebbeNonFareNullaSeLOverlayNonCe;
var
  LFunctions: TScriptOverlayFunctions;
begin
  LFunctions := TScriptOverlayFunctions.Create(
    function: TOverlayDrawer
    begin
      Result := nil;
    end);
  try
    LFunctions.OverlayClear;
    LFunctions.OverlayDrawPatch(1, 'PATCH', 0, 0);
    LFunctions.OverlayDrawPatchStretched(1, 'PATCH', 0, 0, 1, 1);
    LFunctions.OverlayDrawPixel(1, 1, 1, 1, 0, 0);
    LFunctions.OverlayDrawRect(1, 1, 1, 1, 0, 0, 1, 1);
    LFunctions.OverlayDrawLine(1, 1, 1, 1, 0, 0, 1, 1);
    LFunctions.OverlayDrawText(1, 'A', 0, 0, 0);
    LFunctions.OverlayDrawLeftText(1, 'A', 0, 0);
    LFunctions.OverlayDrawRightText(1, 'A', 0, 0);
    LFunctions.OverlayDrawCenterText(1, 'A', 0, 0);
    Assert.AreEqual(0, FDrawer.NumDrawers);
  finally
    LFunctions.Free;
  end;
end;

procedure TTestScriptHostOverlayFunctions.DovrebbeChiedereLOverlayOgniVolta;
var
  LFirst, LSecond: TOverlayDrawer;
  LCurrent: TOverlayDrawer;
  LFunctions: TScriptOverlayFunctions;
begin
  LFirst := TOverlayDrawer.CreateWithCanvas(FCanvasRef);
  LSecond := TOverlayDrawer.CreateWithCanvas(FCanvasRef);
  LCurrent := LFirst;
  LFunctions := TScriptOverlayFunctions.Create(
    function: TOverlayDrawer
    begin
      Result := LCurrent;
    end);
  try
    LFunctions.OverlayDrawPixel(10, 1, 1, 1, 0, 0);
    LCurrent := LSecond;
    LFunctions.OverlayDrawPixel(10, 1, 1, 1, 0, 0);
    LFunctions.OverlayDrawPixel(10, 1, 1, 1, 1, 1);
    Assert.AreEqual(1, LFirst.NumDrawers);
    Assert.AreEqual(2, LSecond.NumDrawers);
  finally
    LFunctions.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptHostOverlayFunctions);

end.

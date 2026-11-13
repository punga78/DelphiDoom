{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the overlay drawer                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.OverlayDrawer;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Overlay.Drawer,
  DelphiDoom.ScriptHost.Overlay.Intf,
  DelphiDoom.ScriptHost.Overlay.Types,
  DelphiDoom.Tests.ScriptHost.OverlayFakes;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostOverlayDrawer = class(TObject)
  strict private
    FCanvas: TFakeOverlayCanvas;
    FCanvasRef: IOverlayCanvas;
    FDrawer: TOverlayDrawer;
    function Pixel(const X, Y: Integer): Byte;
    function CountPixels: Integer;
    function NewPatchLump(const AName: string; const AWidth, AHeight, ALeftOffset,
      ATopOffset: Integer; const APixels: array of Byte): Integer;
    function SavedBytes: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereIlRecordDelSalvataggioDi292Byte;
    [Test]
    procedure DovrebbeAvereICampiDelRecordAgliScostamentiDelVecchioRecord;
    [Test]
    procedure DovrebbeDareEccezioneSeIlCanvasENil;
    [Test]
    procedure DovrebbeCostruireUnOverlayDaScriptSenzaSchermoNeLump;
    [Test]
    procedure DovrebbeScartareITickNegativi;
    [Test]
    procedure DovrebbeDisegnareUnPixelConIlColoreDelCanvas;
    [Test]
    procedure DovrebbeIgnorareIPixelFuoriDalBuffer;
    [Test]
    procedure DovrebbeDisegnareUnRettangoloPieno;
    [Test]
    procedure DovrebbeLimitareIlRettangoloAlBuffer;
    [Test]
    procedure DovrebbeLimitareLeRigheDelRettangoloConLAltezzaNonConLaLarghezza;
    [Test]
    procedure DovrebbeDisegnareUnaLineaOrizzontale;
    [Test]
    procedure DovrebbeDisegnareUnaLineaVerticale;
    [Test]
    procedure DovrebbeDisegnareUnaLineaDiagonale;
    [Test]
    procedure DovrebbeDisegnareUnaLineaRipidaConGliEstremi;
    [Test]
    procedure DovrebbeNonScrivereFuoriDalBufferConUnaLineaCheEsceInAlto;
    [Test]
    procedure DovrebbeDisegnareUnaPatchConGliScostamenti;
    [Test]
    procedure DovrebbeSaltareLeColonneDellaPatchACuiMancaIlBuffer;
    [Test]
    procedure DovrebbeDisegnareUnaPatchStirata;
    [Test]
    procedure DovrebbeDisegnareUnaPatchStirataAlContrario;
    [Test]
    procedure DovrebbeRipulireIlBufferDiAppoggioTraDuePatchStirate;
    [Test]
    procedure DovrebbeNonAggiungereUnaPatchCheNonCeEAvvisare;
    [Test]
    procedure DovrebbeTroncareIlNomeDiUnaPatchOltreOttoCaratteriEAvvisare;
    [Test]
    procedure DovrebbeNonDisegnareUnaPatchStirataSeUnLatoENullo;
    [Test]
    procedure DovrebbeDisegnareUnTestoAllineatoASinistra;
    [Test]
    procedure DovrebbeDisegnareUnTestoAllineatoADestra;
    [Test]
    procedure DovrebbeDisegnareUnTestoCentrato;
    [Test]
    procedure DovrebbeAvanzareDiQuattroPixelPerUnCarattereSenzaGlifo;
    [Test]
    procedure DovrebbeScrivereIlTestoInMaiuscoloSoloPerLeLettereAsciiMinuscole;
    [Test]
    procedure DovrebbeToglierePrimaLiDrawerScadutiEAvvisareIlCanvasSoloSeCambia;
    [Test]
    procedure DovrebbeDisegnareUnDrawerFinoAlSuoUltimoTic;
    [Test]
    procedure DovrebbeTenerePiuDiOttoDrawer;
    [Test]
    procedure DovrebbeSvuotareIlBufferConClear;
    [Test]
    procedure DovrebbeScrivereIlSalvataggioByteAByte;
    [Test]
    procedure DovrebbeScrivereTestoEAllineamentoNelRecordDelSalvataggio;
    [Test]
    procedure DovrebbeRileggereIlSalvataggioEDisegnareLoStessoBuffer;
    [Test]
    procedure DovrebbeDareDimensioneDelSalvataggioEAvanzareIlPuntatore;
    [Test]
    procedure DovrebbeLeggereUnConteggioNegativoComeZero;
    [Test]
    procedure DovrebbeAvvisareDiUnDrawerDiTipoSconosciuto;
    [Test]
    procedure DovrebbeFareLaTabellaDeiPixelDelloSchermoPerUnoSchermoPiuGrande;
    [Test]
    procedure DovrebbeDareLAltezzaDelloSchermoCheLOverlayCopre;
    [Test]
    procedure DovrebbeNonMandareNullaAlloSchermoSeNonCiSonoDrawer;
    [Test]
    procedure DovrebbeDisegnareEMandareLAreaModificataAlCanvasAlPrimoFotogramma;
    [Test]
    procedure DovrebbeNonMandareNullaSeNonHaDisegnatoENonEIlPrimoFotogramma;
    [Test]
    procedure DovrebbeRifareLaTabellaQuandoLoSchermoCambia;
  end;

implementation

const
  PATCH_2X2: array[0..3] of Byte = (1, 2, 3, 4);

{ TTestScriptHostOverlayDrawer }

procedure TTestScriptHostOverlayDrawer.Setup;
begin
  FCanvas := TFakeOverlayCanvas.Create;
  FCanvasRef := FCanvas;
  FDrawer := TOverlayDrawer.CreateWithCanvas(FCanvasRef);
end;

procedure TTestScriptHostOverlayDrawer.TearDown;
begin
  FDrawer.Free;
  FCanvasRef := nil;
end;

function TTestScriptHostOverlayDrawer.Pixel(const X, Y: Integer): Byte;
begin
  Result := FDrawer.OverlayScreen^[X + Y * OVERLAYWIDTH];
end;

function TTestScriptHostOverlayDrawer.CountPixels: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to OVERLAYSIZE - 1 do
    if FDrawer.OverlayScreen^[LIndex] <> 0 then
      Inc(Result);
end;

function TTestScriptHostOverlayDrawer.NewPatchLump(const AName: string; const AWidth, AHeight,
  ALeftOffset, ATopOffset: Integer; const APixels: array of Byte): Integer;
begin
  Result := FCanvas.AddPatch(AName, TFakeOverlayCanvas.BuildPatch(AWidth, AHeight, ALeftOffset,
    ATopOffset, APixels));
end;

function TTestScriptHostOverlayDrawer.SavedBytes: TBytes;
var
  LCursor: Pointer;
begin
  SetLength(Result, FDrawer.SaveSize);
  LCursor := @Result[0];
  FDrawer.SaveToBuffer(LCursor);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeAvereIlRecordDelSalvataggioDi292Byte;
begin
  Assert.AreEqual(292, SizeOf(TOverlayDrawerRecord));
  Assert.AreEqual(OVERLAY_DRAWER_SIZE, SizeOf(TOverlayDrawerRecord));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeAvereICampiDelRecordAgliScostamentiDelVecchioRecord;
var
  LRecord: TOverlayDrawerRecord;
  LBase: NativeInt;
begin
  LBase := NativeInt(@LRecord);
  Assert.AreEqual(0, Integer(NativeInt(@LRecord.Kind) - LBase));
  Assert.AreEqual(4, Integer(NativeInt(@LRecord.Tick) - LBase));
  Assert.AreEqual(8, Integer(NativeInt(@LRecord.TextParameter) - LBase));
  Assert.AreEqual(264, Integer(NativeInt(@LRecord.X) - LBase));
  Assert.AreEqual(268, Integer(NativeInt(@LRecord.Y) - LBase));
  Assert.AreEqual(272, Integer(NativeInt(@LRecord.Parameter1) - LBase));
  Assert.AreEqual(276, Integer(NativeInt(@LRecord.Parameter2) - LBase));
  Assert.AreEqual(280, Integer(NativeInt(@LRecord.Parameter3) - LBase));
  Assert.AreEqual(284, Integer(NativeInt(@LRecord.X2) - LBase));
  Assert.AreEqual(288, Integer(NativeInt(@LRecord.Y2) - LBase));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDareEccezioneSeIlCanvasENil;
begin
  Assert.WillRaise(
    procedure
    begin
      TOverlayDrawer.CreateWithCanvas(nil).Free;
    end,
    EArgumentNilException);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeCostruireUnOverlayDaScriptSenzaSchermoNeLump;
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := TOverlayDrawer.Create;
  try
    LOverlay.AddText(10, 'abc', OVR_ALIGN_LEFT, 0, 0);
    LOverlay.AddPatch(10, 'NOPATCH', 0, 0);
    LOverlay.AddPixel(10, 1, 2, 3, 4, 5);
    LOverlay.DrawDrawers;
    // the text and the pixel are kept, the patch is not (no lumps), and nothing is drawn for the font
    Assert.AreEqual(2, LOverlay.NumDrawers);
  finally
    LOverlay.Free;
  end;
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeScartareITickNegativi;
begin
  NewPatchLump('PATCH', 1, 1, 0, 0, [9]);
  FDrawer.AddText(-1, 'A', OVR_ALIGN_LEFT, 0, 0);
  FDrawer.AddPatch(-1, 'PATCH', 0, 0);
  FDrawer.AddPatchStretched(-1, 'PATCH', 0, 0, 2, 2);
  FDrawer.AddPixel(-1, 1, 1, 1, 0, 0);
  FDrawer.AddRect(-1, 1, 1, 1, 0, 0, 1, 1);
  FDrawer.AddLine(-1, 1, 1, 1, 0, 0, 1, 1);
  FDrawer.AddLeftText(-1, 'A', 0, 0);
  FDrawer.AddRightText(-1, 'A', 0, 0);
  FDrawer.AddCenterText(-1, 'A', 0, 0);
  Assert.AreEqual(0, FDrawer.NumDrawers);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnPixelConIlColoreDelCanvas;
begin
  FDrawer.AddPixel(10, 1, 2, 3, 5, 6);
  FDrawer.DrawDrawers;
  Assert.AreEqual(Byte(7), Pixel(5, 6));
  Assert.AreEqual(1, CountPixels);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeIgnorareIPixelFuoriDalBuffer;
begin
  FDrawer.AddPixel(10, 1, 2, 3, -1, -1);
  FDrawer.AddPixel(10, 1, 2, 3, 5, 200);
  // 320 on the last row is the first position after the buffer
  FDrawer.AddPixel(10, 1, 2, 3, 320, 199);
  FDrawer.AddPixel(10, 1, 2, 3, 319, 199);
  FDrawer.DrawDrawers;
  Assert.AreEqual(1, CountPixels);
  Assert.AreEqual(Byte(7), Pixel(319, 199));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnRettangoloPieno;
begin
  FDrawer.AddRect(10, 10, 20, 30, 10, 10, 12, 11);
  FDrawer.DrawDrawers;
  Assert.AreEqual(6, CountPixels);
  Assert.AreEqual(Byte(61), Pixel(10, 10));
  Assert.AreEqual(Byte(61), Pixel(12, 11));
  Assert.AreEqual(Byte(0), Pixel(13, 11));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeLimitareIlRettangoloAlBuffer;
begin
  FDrawer.AddRect(10, 1, 1, 1, -5, -5, 2, 2);
  FDrawer.DrawDrawers;
  Assert.AreEqual(9, CountPixels);
  Assert.AreEqual(Byte(0), Pixel(3, 0));
  Assert.AreEqual(Byte(4), Pixel(0, 0));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeLimitareLeRigheDelRettangoloConLAltezzaNonConLaLarghezza;
begin
  // the old code clamped the rows to 319: a rectangle to row 300 wrote 100 rows past the buffer
  FDrawer.AddRect(10, 1, 1, 1, 0, 190, 1, 300);
  FDrawer.DrawDrawers;
  Assert.AreEqual(20, CountPixels);
  Assert.AreEqual(Byte(4), Pixel(1, 199));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnaLineaOrizzontale;
begin
  FDrawer.AddLine(10, 1, 1, 1, 0, 5, 4, 5);
  FDrawer.DrawDrawers;
  Assert.AreEqual(5, CountPixels);
  Assert.AreEqual(Byte(4), Pixel(4, 5));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnaLineaVerticale;
begin
  FDrawer.AddLine(10, 1, 1, 1, 5, 0, 5, 3);
  FDrawer.DrawDrawers;
  Assert.AreEqual(4, CountPixels);
  Assert.AreEqual(Byte(4), Pixel(5, 3));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnaLineaDiagonale;
var
  LIndex: Integer;
begin
  FDrawer.AddLine(10, 1, 1, 1, 0, 0, 3, 3);
  FDrawer.DrawDrawers;
  Assert.AreEqual(4, CountPixels);
  for LIndex := 0 to 3 do
    Assert.AreEqual(Byte(4), Pixel(LIndex, LIndex));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnaLineaRipidaConGliEstremi;
begin
  FDrawer.AddLine(10, 1, 1, 1, 0, 0, 1, 4);
  FDrawer.DrawDrawers;
  Assert.AreEqual(5, CountPixels);
  Assert.AreEqual(Byte(4), Pixel(0, 0));
  Assert.AreEqual(Byte(4), Pixel(1, 4));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeNonScrivereFuoriDalBufferConUnaLineaCheEsceInAlto;
begin
  // (0,-2) and (1,-1) are before the buffer: the old test (x >= 0 and y < size) wrote there
  FDrawer.AddLine(10, 1, 1, 1, 0, -2, 3, 1);
  FDrawer.DrawDrawers;
  Assert.AreEqual(2, CountPixels);
  Assert.AreEqual(Byte(4), Pixel(2, 0));
  Assert.AreEqual(Byte(4), Pixel(3, 1));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnaPatchConGliScostamenti;
begin
  NewPatchLump('PATCH', 2, 2, 1, 1, PATCH_2X2);
  FDrawer.AddPatch(10, 'patch', 10, 10);
  FDrawer.DrawDrawers;
  Assert.AreEqual(4, CountPixels);
  Assert.AreEqual(Byte(1), Pixel(9, 9));
  Assert.AreEqual(Byte(2), Pixel(9, 10));
  Assert.AreEqual(Byte(3), Pixel(10, 9));
  Assert.AreEqual(Byte(4), Pixel(10, 10));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeSaltareLeColonneDellaPatchACuiMancaIlBuffer;
begin
  NewPatchLump('PATCH', 2, 2, 0, 0, PATCH_2X2);
  FDrawer.AddPatch(10, 'PATCH', -1, 5);
  FDrawer.DrawDrawers;
  // the first column is at x = -1, the second at 0
  Assert.AreEqual(2, CountPixels);
  Assert.AreEqual(Byte(3), Pixel(0, 5));
  Assert.AreEqual(Byte(4), Pixel(0, 6));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnaPatchStirata;
begin
  NewPatchLump('PATCH', 2, 2, 0, 0, PATCH_2X2);
  FDrawer.AddPatchStretched(10, 'PATCH', 0, 0, 4, 4);
  FDrawer.DrawDrawers;
  Assert.AreEqual(16, CountPixels);
  Assert.AreEqual(Byte(1), Pixel(0, 0));
  Assert.AreEqual(Byte(1), Pixel(1, 1));
  Assert.AreEqual(Byte(3), Pixel(2, 0));
  Assert.AreEqual(Byte(3), Pixel(3, 1));
  Assert.AreEqual(Byte(2), Pixel(0, 2));
  Assert.AreEqual(Byte(2), Pixel(1, 3));
  Assert.AreEqual(Byte(4), Pixel(2, 2));
  Assert.AreEqual(Byte(4), Pixel(3, 3));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnaPatchStirataAlContrario;
begin
  NewPatchLump('PATCH', 2, 2, 0, 0, PATCH_2X2);
  FDrawer.AddPatchStretched(10, 'PATCH', 4, 0, 0, 4);
  FDrawer.DrawDrawers;
  // x goes 4, 3, 2, 1 while the column of the patch goes 0, 0, 1, 1
  Assert.AreEqual(Byte(1), Pixel(4, 0));
  Assert.AreEqual(Byte(1), Pixel(3, 0));
  Assert.AreEqual(Byte(3), Pixel(2, 0));
  Assert.AreEqual(Byte(3), Pixel(1, 0));
  Assert.AreEqual(Byte(0), Pixel(0, 0));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeRipulireIlBufferDiAppoggioTraDuePatchStirate;
begin
  NewPatchLump('PATCH', 2, 2, 0, 0, PATCH_2X2);
  FDrawer.AddPatchStretched(10, 'PATCH', 0, 0, 4, 4);
  FDrawer.AddPatchStretched(10, 'PATCH', 10, 10, 14, 14);
  FDrawer.DrawDrawers;
  Assert.AreEqual(32, CountPixels);
  Assert.AreEqual(Byte(4), Pixel(13, 13));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeNonAggiungereUnaPatchCheNonCeEAvvisare;
begin
  FDrawer.AddPatch(10, 'MISSING', 0, 0);
  FDrawer.AddPatchStretched(10, 'MISSING', 0, 0, 2, 2);
  Assert.AreEqual(0, FDrawer.NumDrawers);
  Assert.AreEqual(2, FCanvas.Warnings.Count);
  Assert.IsTrue(FCanvas.Warnings[0].Contains('Invalid patch "MISSING"'));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeTroncareIlNomeDiUnaPatchOltreOttoCaratteriEAvvisare;
begin
  NewPatchLump('ABCDEFGH', 1, 1, 0, 0, [9]);
  FDrawer.AddPatch(10, 'ABCDEFGHIJ', 3, 4);
  Assert.AreEqual(1, FDrawer.NumDrawers);
  Assert.AreEqual(1, FCanvas.Warnings.Count);
  Assert.IsTrue(FCanvas.Warnings[0].Contains('"ABCDEFGHIJ"'));
  Assert.IsTrue(FCanvas.Warnings[0].Contains('"ABCDEFGH"'));
  FDrawer.DrawDrawers;
  Assert.AreEqual(Byte(9), Pixel(3, 4));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeNonDisegnareUnaPatchStirataSeUnLatoENullo;
begin
  NewPatchLump('PATCH', 2, 2, 0, 0, PATCH_2X2);
  FDrawer.AddPatchStretched(10, 'PATCH', 5, 5, 5, 9);
  FDrawer.AddPatchStretched(10, 'PATCH', 5, 5, 9, 5);
  FDrawer.DrawDrawers;
  Assert.AreEqual(0, CountPixels);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnTestoAllineatoASinistra;
begin
  FDrawer.AddLeftText(10, 'AB', 10, 10);
  FDrawer.DrawDrawers;
  Assert.AreEqual(18, CountPixels);
  Assert.AreEqual(Byte(1), Pixel(10, 10));
  Assert.AreEqual(Byte(1), Pixel(12, 12));
  Assert.AreEqual(Byte(0), Pixel(13, 10));
  Assert.AreEqual(Byte(1), Pixel(14, 10));
  Assert.AreEqual(Byte(1), Pixel(16, 12));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnTestoAllineatoADestra;
begin
  FDrawer.AddRightText(10, 'AB', 20, 10);
  FDrawer.DrawDrawers;
  // the width is 2 * (3 + 1) = 8: the text starts at 12
  Assert.AreEqual(Byte(1), Pixel(12, 10));
  Assert.AreEqual(Byte(0), Pixel(11, 10));
  Assert.AreEqual(Byte(1), Pixel(18, 12));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnTestoCentrato;
begin
  FDrawer.AddCenterText(10, 'AB', 20, 10);
  FDrawer.DrawDrawers;
  Assert.AreEqual(Byte(1), Pixel(16, 10));
  Assert.AreEqual(Byte(0), Pixel(15, 10));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeAvanzareDiQuattroPixelPerUnCarattereSenzaGlifo;
begin
  FDrawer.AddLeftText(10, 'A~B', 0, 0);
  FDrawer.DrawDrawers;
  Assert.AreEqual(Byte(1), Pixel(2, 0));
  Assert.AreEqual(Byte(0), Pixel(4, 0));
  Assert.AreEqual(Byte(0), Pixel(7, 0));
  Assert.AreEqual(Byte(1), Pixel(8, 0));
  Assert.AreEqual(18, CountPixels);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeScrivereIlTestoInMaiuscoloSoloPerLeLettereAsciiMinuscole;
var
  LBytes: TBytes;
begin
  FDrawer.AddLeftText(10, 'aZ!', 0, 0);
  LBytes := SavedBytes;
  // the text of the record is a short string: length, then the characters
  Assert.AreEqual(Byte(3), LBytes[4 + 8]);
  Assert.AreEqual(Byte(Ord('A')), LBytes[4 + 9]);
  Assert.AreEqual(Byte(Ord('Z')), LBytes[4 + 10]);
  Assert.AreEqual(Byte(Ord('!')), LBytes[4 + 11]);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeToglierePrimaLiDrawerScadutiEAvvisareIlCanvasSoloSeCambia;
begin
  FCanvas.Time := 0;
  FDrawer.AddPixel(5, 1, 1, 1, 1, 1);
  FDrawer.AddPixel(20, 1, 1, 1, 2, 2);
  FDrawer.DrawDrawers;
  Assert.IsTrue(FDrawer.Modified);
  Assert.AreEqual(1, FCanvas.DirtyCount);
  FDrawer.DrawDrawers;
  Assert.IsFalse(FDrawer.Modified);
  Assert.AreEqual(1, FCanvas.DirtyCount);
  FCanvas.Time := 6;
  FDrawer.DrawDrawers;
  Assert.AreEqual(1, FDrawer.NumDrawers);
  Assert.IsTrue(FDrawer.Modified);
  Assert.AreEqual(2, FCanvas.DirtyCount);
  Assert.AreEqual(Byte(0), Pixel(1, 1));
  Assert.AreEqual(Byte(4), Pixel(2, 2));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareUnDrawerFinoAlSuoUltimoTic;
begin
  FCanvas.Time := 100;
  FDrawer.AddPixel(5, 1, 1, 1, 1, 1);
  FCanvas.Time := 105;
  FDrawer.DrawDrawers;
  Assert.AreEqual(Byte(4), Pixel(1, 1));
  FCanvas.Time := 106;
  FDrawer.DrawDrawers;
  Assert.AreEqual(0, FDrawer.NumDrawers);
  Assert.AreEqual(Byte(0), Pixel(1, 1));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeTenerePiuDiOttoDrawer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 19 do
    FDrawer.AddPixel(10, 1, 1, 1, LIndex, 0);
  FDrawer.DrawDrawers;
  Assert.AreEqual(20, FDrawer.NumDrawers);
  Assert.AreEqual(20, CountPixels);
  Assert.AreEqual(4 + 20 * 292, FDrawer.SaveSize);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeSvuotareIlBufferConClear;
begin
  FDrawer.AddPixel(10, 1, 1, 1, 1, 1);
  FDrawer.DrawDrawers;
  Assert.AreEqual(1, CountPixels);
  FDrawer.Clear;
  Assert.AreEqual(0, FDrawer.NumDrawers);
  Assert.AreEqual(0, CountPixels);
  Assert.AreEqual(4, FDrawer.SaveSize);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeScrivereIlSalvataggioByteAByte;
var
  LBytes: TBytes;
begin
  FCanvas.Time := 100;
  FDrawer.AddPixel(10, 1, 2, 3, 5, 6);
  LBytes := SavedBytes;
  Assert.AreEqual<Integer>(4 + 292, Length(LBytes));
  Assert.AreEqual(1, PInteger(@LBytes[0])^);
  Assert.AreEqual(OVR_DRAWPIXEL, PInteger(@LBytes[4])^);
  Assert.AreEqual(110, PInteger(@LBytes[4 + 4])^);
  Assert.AreEqual(5, PInteger(@LBytes[4 + 264])^);
  Assert.AreEqual(6, PInteger(@LBytes[4 + 268])^);
  Assert.AreEqual(1, PInteger(@LBytes[4 + 272])^);
  Assert.AreEqual(2, PInteger(@LBytes[4 + 276])^);
  Assert.AreEqual(3, PInteger(@LBytes[4 + 280])^);
  // the fields that the kind does not use are zero (the old class left the memory as it was)
  Assert.AreEqual(0, PInteger(@LBytes[4 + 284])^);
  Assert.AreEqual(0, PInteger(@LBytes[4 + 288])^);
  Assert.AreEqual(Byte(0), LBytes[4 + 8]);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeScrivereTestoEAllineamentoNelRecordDelSalvataggio;
var
  LBytes: TBytes;
begin
  FDrawer.AddCenterText(10, 'hi', 7, 8);
  LBytes := SavedBytes;
  Assert.AreEqual(OVR_DRAWTEXT, PInteger(@LBytes[4])^);
  Assert.AreEqual(Byte(2), LBytes[4 + 8]);
  Assert.AreEqual(Byte(Ord('H')), LBytes[4 + 9]);
  Assert.AreEqual(Byte(Ord('I')), LBytes[4 + 10]);
  Assert.AreEqual(7, PInteger(@LBytes[4 + 264])^);
  Assert.AreEqual(8, PInteger(@LBytes[4 + 268])^);
  Assert.AreEqual(OVR_ALIGN_CENTER, PInteger(@LBytes[4 + 272])^);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeRileggereIlSalvataggioEDisegnareLoStessoBuffer;
var
  LBytes: TBytes;
  LCursor: Pointer;
  LOther: TOverlayDrawer;
  LIndex: Integer;
begin
  NewPatchLump('PATCH', 2, 2, 1, 1, PATCH_2X2);
  FDrawer.AddLeftText(50, 'AB', 10, 10);
  FDrawer.AddPatch(50, 'PATCH', 40, 40);
  FDrawer.AddRect(50, 9, 9, 9, 100, 100, 105, 105);
  FDrawer.AddLine(50, 3, 3, 3, 0, 0, 50, 30);
  FDrawer.AddPatchStretched(50, 'PATCH', 200, 100, 210, 110);
  FDrawer.DrawDrawers;
  LBytes := SavedBytes;
  LOther := TOverlayDrawer.CreateWithCanvas(FCanvasRef);
  try
    LCursor := @LBytes[0];
    LOther.LoadFromBuffer(LCursor);
    LOther.DrawDrawers;
    Assert.AreEqual(FDrawer.NumDrawers, LOther.NumDrawers);
    for LIndex := 0 to OVERLAYSIZE - 1 do
      if FDrawer.OverlayScreen^[LIndex] <> LOther.OverlayScreen^[LIndex] then
        Assert.Fail('the pixel ' + IntToStr(LIndex) + ' is different');
  finally
    LOther.Free;
  end;
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDareDimensioneDelSalvataggioEAvanzareIlPuntatore;
var
  LBytes: TBytes;
  LCursor: Pointer;
begin
  FDrawer.AddPixel(10, 1, 1, 1, 1, 1);
  FDrawer.AddPixel(10, 1, 1, 1, 2, 2);
  Assert.AreEqual(4 + 2 * 292, FDrawer.SaveSize);
  SetLength(LBytes, FDrawer.SaveSize + 8);
  LCursor := @LBytes[0];
  FDrawer.SaveToBuffer(LCursor);
  Assert.AreEqual(FDrawer.SaveSize, Integer(PByte(LCursor) - PByte(@LBytes[0])));
  LCursor := @LBytes[0];
  FDrawer.Clear;
  FDrawer.LoadFromBuffer(LCursor);
  Assert.AreEqual(4 + 2 * 292, Integer(PByte(LCursor) - PByte(@LBytes[0])));
  Assert.AreEqual(2, FDrawer.NumDrawers);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeLeggereUnConteggioNegativoComeZero;
var
  LBytes: TBytes;
  LCursor: Pointer;
begin
  SetLength(LBytes, 8);
  PInteger(@LBytes[0])^ := -5;
  FDrawer.AddPixel(10, 1, 1, 1, 1, 1);
  LCursor := @LBytes[0];
  FDrawer.LoadFromBuffer(LCursor);
  Assert.AreEqual(0, FDrawer.NumDrawers);
  Assert.AreEqual(4, Integer(PByte(LCursor) - PByte(@LBytes[0])));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeAvvisareDiUnDrawerDiTipoSconosciuto;
var
  LBytes: TBytes;
  LCursor: Pointer;
begin
  SetLength(LBytes, 4 + 292);
  PInteger(@LBytes[0])^ := 1;
  PInteger(@LBytes[4])^ := 99;
  PInteger(@LBytes[8])^ := 1000;
  LCursor := @LBytes[0];
  FDrawer.LoadFromBuffer(LCursor);
  FDrawer.DrawDrawers;
  Assert.AreEqual(1, FCanvas.Warnings.Count);
  Assert.IsTrue(FCanvas.Warnings[0].Contains('Unknown drawer type "99"'));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeFareLaTabellaDeiPixelDelloSchermoPerUnoSchermoPiuGrande;
var
  LOther: TOverlayDrawer;
  LCanvas: TFakeOverlayCanvas;
  LCanvasRef: IOverlayCanvas;
begin
  LCanvas := TFakeOverlayCanvas.Create(640, 256);
  LCanvasRef := LCanvas;
  LCanvas.FirstInterpolation := True;
  LOther := TOverlayDrawer.CreateWithCanvas(LCanvasRef);
  try
    LOther.AddPixel(10, 1, 2, 3, 5, 4);
    LOther.FlashToScreen;
    Assert.AreEqual(1, LCanvas.FlashCount);
    // 640x256: the pixels 10..11 of the row 6 are the only ones that show the overlay pixel (5, 4)
    Assert.IsTrue(LCanvas.LastFlash.Lookup^[6 * 640 + 10] = @LOther.OverlayScreen^[5 + 4 * OVERLAYWIDTH]);
    Assert.AreEqual(6 * 640 + 10, LCanvas.LastFlash.FirstLookup^[5 + 4 * OVERLAYWIDTH]);
    Assert.AreEqual(6 * 640 + 11, LCanvas.LastFlash.LastLookup^[5 + 4 * OVERLAYWIDTH]);
  finally
    LOther.Free;
  end;
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDareLAltezzaDelloSchermoCheLOverlayCopre;
var
  LOther: TOverlayDrawer;
  LCanvasRef: IOverlayCanvas;
begin
  LCanvasRef := TFakeOverlayCanvas.Create(640, 256);
  LOther := TOverlayDrawer.CreateWithCanvas(LCanvasRef);
  try
    Assert.AreEqual(0, LOther.GetOverlayHeight);
    LOther.AddPixel(10, 1, 2, 3, 5, 4);
    LOther.DrawDrawers;
    Assert.AreEqual(7, LOther.GetOverlayHeight);
    LOther.AddPixel(10, 1, 2, 3, 319, 199);
    LOther.DrawDrawers;
    Assert.AreEqual(256, LOther.GetOverlayHeight);
  finally
    LOther.Free;
  end;
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeNonMandareNullaAlloSchermoSeNonCiSonoDrawer;
begin
  FCanvas.FirstInterpolation := True;
  FDrawer.FlashToScreen;
  Assert.AreEqual(0, FCanvas.FlashCount);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeDisegnareEMandareLAreaModificataAlCanvasAlPrimoFotogramma;
begin
  FCanvas.FirstInterpolation := True;
  FDrawer.AddPixel(10, 1, 2, 3, 5, 3);
  FDrawer.FlashToScreen;
  Assert.AreEqual(1, FCanvas.FlashCount);
  Assert.AreEqual(5 + 3 * OVERLAYWIDTH, FCanvas.LastFlash.Start);
  Assert.AreEqual(5 + 3 * OVERLAYWIDTH, FCanvas.LastFlash.Finish);
  Assert.AreEqual(Byte(7), Pixel(5, 3));
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeNonMandareNullaSeNonHaDisegnatoENonEIlPrimoFotogramma;
begin
  FCanvas.FirstInterpolation := False;
  FDrawer.AddPixel(10, 1, 2, 3, 5, 3);
  FDrawer.FlashToScreen;
  Assert.AreEqual(0, FCanvas.FlashCount);
  FDrawer.DrawDrawers;
  FDrawer.FlashToScreen;
  Assert.AreEqual(1, FCanvas.FlashCount);
end;

procedure TTestScriptHostOverlayDrawer.DovrebbeRifareLaTabellaQuandoLoSchermoCambia;
begin
  FCanvas.Width := 640;
  FCanvas.Height := 256;
  FDrawer.ReCalcOverlayLookUp;
  FCanvas.FirstInterpolation := True;
  FDrawer.AddPixel(10, 1, 2, 3, 5, 4);
  FDrawer.FlashToScreen;
  Assert.AreEqual(6 * 640 + 10, FCanvas.LastFlash.FirstLookup^[5 + 4 * OVERLAYWIDTH]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptHostOverlayDrawer);

end.

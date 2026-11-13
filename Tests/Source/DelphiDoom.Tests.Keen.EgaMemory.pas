{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the video memory, the capture of     }
{  the screen, the map that is played and the arithmetic of a 16 bit int        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.EgaMemory;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenEgaMemory = class(TObject)
  public
    [Test]
    procedure DovrebbeTenereQuattroPianiDa64KB;
    [Test]
    procedure DovrebbeFareIlGiroDeiPianiConUnOffsetPiuGrande;
    [Test]
    procedure DovrebbeCopiareITuttiEQuattroIPianiConLeLatch;
    [Test]
    procedure DovrebbeRiempireOgniPixelConIlColore;
    [Test]
    procedure DovrebbeDareUnaCopiaDiUnPiano;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenDisplayCapture = class(TObject)
  public
    [Test]
    procedure DovrebbeFareUnaImmagineDi320Per200;
    [Test]
    procedure DovrebbeLeggereDallIndirizzoDiPartenza;
    [Test]
    procedure DovrebbeSpostareASinistraConIlPelPanning;
    [Test]
    procedure DovrebbeUsareLaLarghezzaDellaRigaVirtuale;
    [Test]
    procedure DovrebbeMostrareCioCheIlVideoHaImpostato;
    [Test]
    procedure DovrebbeRifiutareUnaMemoriaNulla;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenWorkingMap = class(TObject)
  public
    [Test]
    procedure DovrebbeCopiareUnaMappaDelFile;
    [Test]
    procedure DovrebbeNonToccareLaMappaDelFile;
    [Test]
    procedure DovrebbeFareUnaMappaVuota;
    [Test]
    procedure DovrebbeRifiutareUnaMisuraNonValida;
    [Test]
    procedure DovrebbeRifiutareUnPianoCheNonEsiste;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenArithmetic = class(TObject)
  public
    [TestCase('positivo', '40,4,2')]
    [TestCase('negativo', '-40,4,-3')]
    [TestCase('meno uno', '-1,4,-1')]
    [TestCase('multiplo', '-32,4,-2')]
    procedure DovrebbeSpostareConIlSegno(AValue, AShift, AExpected: Integer);
    [Test]
    procedure DovrebbeFareIlGiroDelleVariabiliSenzaSegno;
    [Test]
    procedure DovrebbeFareIlGiroDelleVariabiliConSegno;
  end;

implementation

uses
  DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.Video, DelphiDoom.Keen.DisplayCapture, DelphiDoom.Keen.WorkingMap,
  DelphiDoom.Keen.Map, DelphiDoom.Keen.Arithmetic, DelphiDoom.Tests.Keen.VideoFakes;

{ TTestKeenEgaMemory }

procedure TTestKeenEgaMemory.DovrebbeTenereQuattroPianiDa64KB;
var
  LMemory: IKeenEgaMemory;
  LPlane: Integer;
begin
  LMemory := TKeenEgaMemory.Create;
  for LPlane := 0 to 3 do
  begin
    LMemory.WriteByte(LPlane, 5, Byte(LPlane + 1));
    Assert.AreEqual<Integer>(KEEN_EGA_PLANE_BYTES, Length(LMemory.PlaneBytes(LPlane)));
  end;
  for LPlane := 0 to 3 do
    Assert.AreEqual(LPlane + 1, Integer(LMemory.ReadByte(LPlane, 5)));
end;

procedure TTestKeenEgaMemory.DovrebbeFareIlGiroDeiPianiConUnOffsetPiuGrande;
var
  LMemory: IKeenEgaMemory;
begin
  LMemory := TKeenEgaMemory.Create;
  LMemory.WriteByte(2, $10003, 99);
  Assert.AreEqual(99, Integer(LMemory.ReadByte(2, 3)));
  Assert.AreEqual(99, Integer(LMemory.ReadByte(2, $20003)));
end;

procedure TTestKeenEgaMemory.DovrebbeCopiareITuttiEQuattroIPianiConLeLatch;
var
  LMemory: IKeenEgaMemory;
  LPlane: Integer;
begin
  LMemory := TKeenEgaMemory.Create;
  for LPlane := 0 to 3 do
    LMemory.WriteByte(LPlane, 100, Byte(LPlane * 10 + 1));
  LMemory.CopyByte(100, 200);
  for LPlane := 0 to 3 do
    Assert.AreEqual(LPlane * 10 + 1, Integer(LMemory.ReadByte(LPlane, 200)));
end;

procedure TTestKeenEgaMemory.DovrebbeRiempireOgniPixelConIlColore;
var
  LMemory: IKeenEgaMemory;
begin
  LMemory := TKeenEgaMemory.Create;
  LMemory.Fill(5);
  Assert.AreEqual(5, Integer(TFakeKeenPixels.Pixel(LMemory, 0, 64, 0, 0)));
  Assert.AreEqual(5, Integer(TFakeKeenPixels.Pixel(LMemory, 0, 64, 511, 127)));
end;

procedure TTestKeenEgaMemory.DovrebbeDareUnaCopiaDiUnPiano;
var
  LMemory: IKeenEgaMemory;
  LCopy: TBytes;
begin
  LMemory := TKeenEgaMemory.Create;
  LCopy := LMemory.PlaneBytes(1);
  LCopy[0] := 77;
  Assert.AreEqual(0, Integer(LMemory.ReadByte(1, 0)));
end;

{ TTestKeenDisplayCapture }

procedure TTestKeenDisplayCapture.DovrebbeFareUnaImmagineDi320Per200;
var
  LImage: TKeenChunkyImage;
begin
  LImage := TKeenDisplayCapture.Capture(TKeenEgaMemory.Create, 0, 0, 64);
  Assert.AreEqual(320, LImage.Width);
  Assert.AreEqual(200, LImage.Height);
  Assert.AreEqual<Integer>(64000, Length(LImage.Pixels));
end;

procedure TTestKeenDisplayCapture.DovrebbeLeggereDallIndirizzoDiPartenza;
var
  LMemory: IKeenEgaMemory;
  LImage: TKeenChunkyImage;
begin
  LMemory := TKeenEgaMemory.Create;
  LMemory.WriteByte(0, 1000, $80);
  LMemory.WriteByte(3, 1000, $80);
  LImage := TKeenDisplayCapture.Capture(LMemory, 1000, 0, 64);
  Assert.AreEqual(9, Integer(LImage.Pixels[0]));
  Assert.AreEqual(0, Integer(LImage.Pixels[1]));
end;

procedure TTestKeenDisplayCapture.DovrebbeSpostareASinistraConIlPelPanning;
var
  LMemory: IKeenEgaMemory;
  LImage: TKeenChunkyImage;
begin
  LMemory := TKeenEgaMemory.Create;
  // the pixel 6 of the first row is red (4)
  LMemory.WriteByte(2, 0, $02);
  LImage := TKeenDisplayCapture.Capture(LMemory, 0, 2, 64);
  Assert.AreEqual(4, Integer(LImage.Pixels[4]));
  Assert.AreEqual(0, Integer(LImage.Pixels[6]));
end;

procedure TTestKeenDisplayCapture.DovrebbeUsareLaLarghezzaDellaRigaVirtuale;
var
  LMemory: IKeenEgaMemory;
  LImage: TKeenChunkyImage;
begin
  LMemory := TKeenEgaMemory.Create;
  LMemory.WriteByte(1, 3 * 40, $80);
  LImage := TKeenDisplayCapture.Capture(LMemory, 0, 0, 40);
  Assert.AreEqual(2, Integer(LImage.Pixels[3 * 320]));
end;

procedure TTestKeenDisplayCapture.DovrebbeMostrareCioCheIlVideoHaImpostato;
var
  LMemory: IKeenEgaMemory;
  LVideo: IKeenVideo;
  LImage: TKeenChunkyImage;
begin
  LMemory := TKeenEgaMemory.Create;
  LVideo := TKeenVideo.Create(LMemory, nil, nil);
  LVideo.Plot(40, 3, 7);
  LVideo.SetScreen(5, 0);
  LImage := TKeenDisplayCapture.CaptureVideo(LVideo);
  // the pixel (40, 3) is the pixel 0 of the 5th byte of the row: the screen starts there
  Assert.AreEqual(7, Integer(LImage.Pixels[3 * 320 + 0]));
end;

procedure TTestKeenDisplayCapture.DovrebbeRifiutareUnaMemoriaNulla;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenDisplayCapture.Capture(nil, 0, 0, 64);
    end, EArgumentNilException);
end;

{ TTestKeenWorkingMap }

function MakeFileMap: IKeenMap;
var
  LHeader: TKeenMapHeader;
  LPlanes: array[0..2] of TArray<Word>;
  LPlane: Integer;
  LIndex: Integer;
begin
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Width := 4;
  LHeader.Height := 3;
  LHeader.Name[0] := 'M';
  for LPlane := 0 to 2 do
  begin
    SetLength(LPlanes[LPlane], 12);
    for LIndex := 0 to 11 do
      LPlanes[LPlane][LIndex] := Word(LPlane * 100 + LIndex);
  end;
  Result := TKeenMap.Create(7, LHeader, [LPlanes[0], LPlanes[1], LPlanes[2]]);
end;

procedure TTestKeenWorkingMap.DovrebbeCopiareUnaMappaDelFile;
var
  LMap: IKeenWorkingMap;
begin
  LMap := TKeenWorkingMap.Create(MakeFileMap);
  Assert.AreEqual(7, LMap.Number);
  Assert.AreEqual('M', LMap.Name);
  Assert.AreEqual(4, LMap.Width);
  Assert.AreEqual(3, LMap.Height);
  Assert.AreEqual(205, Integer(LMap.Planes[2][5]));
end;

procedure TTestKeenWorkingMap.DovrebbeNonToccareLaMappaDelFile;
var
  LFile: IKeenMap;
  LMap: IKeenWorkingMap;
begin
  LFile := MakeFileMap;
  LMap := TKeenWorkingMap.Create(LFile);
  LMap.Planes[0][3] := 999;
  Assert.AreEqual(3, Integer(LFile.Planes[0][3]));
  Assert.AreEqual(999, Integer(LMap.Planes[0][3]));
end;

procedure TTestKeenWorkingMap.DovrebbeFareUnaMappaVuota;
var
  LMap: IKeenWorkingMap;
begin
  LMap := TKeenWorkingMap.Create(10, 8);
  Assert.AreEqual<Integer>(80, Length(LMap.Planes[1]));
  Assert.AreEqual(0, Integer(LMap.Planes[1][79]));
end;

procedure TTestKeenWorkingMap.DovrebbeRifiutareUnaMisuraNonValida;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenWorkingMap.Create(0, 5);
    end, EKeenException);
  Assert.WillRaise(
    procedure
    begin
      TKeenWorkingMap.Create(5, KEEN_MAXMAPHEIGHT + 1);
    end, EKeenException);
end;

procedure TTestKeenWorkingMap.DovrebbeRifiutareUnPianoCheNonEsiste;
var
  LMap: IKeenWorkingMap;
begin
  LMap := TKeenWorkingMap.Create(3, 3);
  Assert.WillRaise(
    procedure
    begin
      LMap.Planes[3];
    end, EKeenDataException);
end;

{ TTestKeenArithmetic }

procedure TTestKeenArithmetic.DovrebbeSpostareConIlSegno(AValue, AShift, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TKeenArithmetic.ShiftRight(AValue, AShift));
end;

procedure TTestKeenArithmetic.DovrebbeFareIlGiroDelleVariabiliSenzaSegno;
begin
  Assert.AreEqual(Word(65535), TKeenArithmetic.ToWord(-1));
  Assert.AreEqual(Word(4), TKeenArithmetic.ToWord(65540));
end;

procedure TTestKeenArithmetic.DovrebbeFareIlGiroDelleVariabiliConSegno;
begin
  Assert.AreEqual(SmallInt(-1), TKeenArithmetic.ToInt16(65535));
  Assert.AreEqual(SmallInt(-32768), TKeenArithmetic.ToInt16(32768));
  Assert.AreEqual(SmallInt(32767), TKeenArithmetic.ToInt16(32767));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenEgaMemory);
  TDUnitX.RegisterTestFixture(TTestKeenDisplayCapture);
  TDUnitX.RegisterTestFixture(TTestKeenWorkingMap);
  TDUnitX.RegisterTestFixture(TTestKeenArithmetic);

end.

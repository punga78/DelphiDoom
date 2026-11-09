{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the video manager of the EGA         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Video;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenVideo = class(TObject)
  strict private
    FMemory: IKeenEgaMemory;
    FGraphics: IKeenGraphics;
    FSprites: IKeenSpriteCache;
    FVideo: IKeenVideo;
    function Pixel(AX, AY: Integer): Byte;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeUsareUnaRigaDi64Byte;
    [Test]
    procedure DovrebbeTabellareLeRigheConLaLarghezzaDellaRiga;
    [Test]
    procedure DovrebbeSegnareUnSoloPixelConPlot;
    [Test]
    procedure DovrebbeLasciareIlRestoDelByteConPlot;
    [Test]
    procedure DovrebbeTracciareUnaLineaOrizzontaleInUnSoloByte;
    [Test]
    procedure DovrebbeTracciareUnaLineaOrizzontaleSuPiuByte;
    [Test]
    procedure DovrebbeTracciareUnaLineaVerticale;
    [Test]
    procedure DovrebbeRiempireUnRettangoloComeIPixelUnoPerUno;
    [Test]
    procedure DovrebbeRiempireUnaBarraDiUnSoloByte;
    [Test]
    procedure DovrebbePartireDalBufferOfsConPlotEBar;
    [Test]
    procedure DovrebbeCopiareIPianiDaMemoriaASchermo;
    [Test]
    procedure DovrebbeRiportareInMemoriaCioCheSiTrovaSulloSchermo;
    [Test]
    procedure DovrebbeFareIlGiroDei64KBNelleCopie;
    [Test]
    procedure DovrebbeComporreUnaMascheraSulloSfondo;
    [Test]
    procedure DovrebbeNonDisegnareUnBloccoLargoZero;
    [Test]
    procedure DovrebbeRifiutareUnBloccoPiuCortoDelDovuto;
    [Test]
    procedure DovrebbeCopiareUnBloccoConLeLatch;
    [Test]
    procedure DovrebbeCopiareUnBloccoCheSiSovrappone;
    [Test]
    procedure DovrebbeColorareTuttoLoSchermo;
    [Test]
    procedure DovrebbeDisegnareUnTileDa8;
    [Test]
    procedure DovrebbeDisegnareUnTileDa16;
    [Test]
    procedure DovrebbeDisegnareUnTileMascheratoDa16;
    [Test]
    procedure DovrebbeDisegnareUnTileMascheratoDa8;
    [Test]
    procedure DovrebbeDisegnareUnaImmagine;
    [Test]
    procedure DovrebbeDisegnareUnaImmagineMascheraConLaSuaTabella;
    [Test]
    procedure DovrebbeSceglierelaCopiaScorrevoleDelloSprite;
    [Test]
    procedure DovrebbeDisegnareUnoSpriteConOrigine;
    [Test]
    procedure DovrebbeRicordareDoveLaSchedaMostraLoSchermo;
    [Test]
    procedure DovrebbeRifiutareDisegniSenzaGrafica;
  end;

implementation

uses
  DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.Video, DelphiDoom.Keen.SpriteCache,
  DelphiDoom.Keen.PlanarConverter, DelphiDoom.Tests.Keen.VideoFakes;

{ TTestKeenVideo }

procedure TTestKeenVideo.Setup;
begin
  FMemory := TKeenEgaMemory.Create;
  FGraphics := TFakeKeenGraphics.Create(7);
  FSprites := TKeenSpriteCache.Create(FGraphics);
  FVideo := TKeenVideo.Create(FMemory, FGraphics, FSprites);
end;

function TTestKeenVideo.Pixel(AX, AY: Integer): Byte;
begin
  Result := TFakeKeenPixels.Pixel(FMemory, 0, FVideo.LineWidth, AX, AY);
end;

procedure TTestKeenVideo.DovrebbeUsareUnaRigaDi64Byte;
begin
  Assert.AreEqual(64, FVideo.LineWidth);
end;

procedure TTestKeenVideo.DovrebbeTabellareLeRigheConLaLarghezzaDellaRiga;
begin
  FVideo.SetLineWidth(40);
  Assert.AreEqual(0, FVideo.YLookup(0));
  Assert.AreEqual(40, FVideo.YLookup(1));
  Assert.AreEqual(40 * 299, FVideo.YLookup(299));
  Assert.WillRaise(
    procedure
    begin
      FVideo.YLookup(300);
    end, EKeenException);
end;

procedure TTestKeenVideo.DovrebbeSegnareUnSoloPixelConPlot;
var
  LX: Integer;
  LY: Integer;
begin
  FVideo.Plot(13, 5, 9);
  for LY := 0 to 9 do
    for LX := 0 to 23 do
      if (LX = 13) and (LY = 5) then
        Assert.AreEqual(9, Integer(Pixel(LX, LY)))
      else
        Assert.AreEqual(0, Integer(Pixel(LX, LY)));
end;

procedure TTestKeenVideo.DovrebbeLasciareIlRestoDelByteConPlot;
begin
  FVideo.Bar(0, 0, 8, 1, 6);
  FVideo.Plot(3, 0, 15);
  Assert.AreEqual(6, Integer(Pixel(2, 0)));
  Assert.AreEqual(15, Integer(Pixel(3, 0)));
  Assert.AreEqual(6, Integer(Pixel(4, 0)));
end;

procedure TTestKeenVideo.DovrebbeTracciareUnaLineaOrizzontaleInUnSoloByte;
var
  LX: Integer;
begin
  FVideo.Hlin(9, 13, 2, 10);
  for LX := 0 to 23 do
    if (LX >= 9) and (LX <= 13) then
      Assert.AreEqual(10, Integer(Pixel(LX, 2)))
    else
      Assert.AreEqual(0, Integer(Pixel(LX, 2)));
end;

procedure TTestKeenVideo.DovrebbeTracciareUnaLineaOrizzontaleSuPiuByte;
var
  LX: Integer;
begin
  FVideo.Hlin(5, 42, 7, 3);
  for LX := 0 to 63 do
    if (LX >= 5) and (LX <= 42) then
      Assert.AreEqual(3, Integer(Pixel(LX, 7)), 'x=' + IntToStr(LX))
    else
      Assert.AreEqual(0, Integer(Pixel(LX, 7)), 'x=' + IntToStr(LX));
  Assert.AreEqual(0, Integer(Pixel(20, 6)));
  Assert.AreEqual(0, Integer(Pixel(20, 8)));
end;

procedure TTestKeenVideo.DovrebbeTracciareUnaLineaVerticale;
var
  LY: Integer;
begin
  FVideo.Vlin(3, 11, 21, 12);
  for LY := 0 to 14 do
    if (LY >= 3) and (LY <= 11) then
      Assert.AreEqual(12, Integer(Pixel(21, LY)))
    else
      Assert.AreEqual(0, Integer(Pixel(21, LY)));
  Assert.AreEqual(0, Integer(Pixel(20, 5)));
  Assert.AreEqual(0, Integer(Pixel(22, 5)));
end;

procedure TTestKeenVideo.DovrebbeRiempireUnRettangoloComeIPixelUnoPerUno;
var
  LOther: IKeenVideo;
  LOtherMemory: IKeenEgaMemory;
  LX: Integer;
  LY: Integer;
begin
  LOtherMemory := TKeenEgaMemory.Create;
  LOther := TKeenVideo.Create(LOtherMemory, nil, nil);
  FVideo.Bar(11, 4, 29, 6, 13);
  for LY := 4 to 9 do
    for LX := 11 to 39 do
      LOther.Plot(LX, LY, 13);
  Assert.AreEqual(TFakeKeenPixels.MemoryHash(LOtherMemory), TFakeKeenPixels.MemoryHash(FMemory));
end;

procedure TTestKeenVideo.DovrebbeRiempireUnaBarraDiUnSoloByte;
begin
  FVideo.Bar(10, 2, 4, 3, 5);
  Assert.AreEqual(0, Integer(Pixel(9, 3)));
  Assert.AreEqual(5, Integer(Pixel(10, 3)));
  Assert.AreEqual(5, Integer(Pixel(13, 3)));
  Assert.AreEqual(0, Integer(Pixel(14, 3)));
  Assert.AreEqual(0, Integer(Pixel(10, 1)));
  Assert.AreEqual(5, Integer(Pixel(10, 4)));
  Assert.AreEqual(0, Integer(Pixel(10, 5)));
end;

procedure TTestKeenVideo.DovrebbePartireDalBufferOfsConPlotEBar;
begin
  FVideo.BufferOfs := 1000;
  FVideo.Plot(0, 0, 15);
  FVideo.Bar(8, 1, 8, 1, 15);
  Assert.AreEqual(15, Integer(TFakeKeenPixels.Pixel(FMemory, 1000, 64, 0, 0)));
  Assert.AreEqual(15, Integer(TFakeKeenPixels.Pixel(FMemory, 1000, 64, 12, 1)));
  Assert.AreEqual(0, Integer(Pixel(0, 0)));
end;

procedure TTestKeenVideo.DovrebbeCopiareIPianiDaMemoriaASchermo;
var
  LSource: TBytes;
  LPlane: Integer;
  LIndex: Integer;
begin
  SetLength(LSource, 4 * 2 * 3);
  for LIndex := 0 to High(LSource) do
    LSource[LIndex] := Byte(LIndex + 1);
  FVideo.MemToScreen(LSource, 100, 2, 3);
  for LPlane := 0 to 3 do
  begin
    Assert.AreEqual(Integer(LSource[LPlane * 6 + 0]), Integer(FMemory.ReadByte(LPlane, 100)));
    Assert.AreEqual(Integer(LSource[LPlane * 6 + 1]), Integer(FMemory.ReadByte(LPlane, 101)));
    Assert.AreEqual(Integer(LSource[LPlane * 6 + 2]), Integer(FMemory.ReadByte(LPlane, 164)));
    Assert.AreEqual(Integer(LSource[LPlane * 6 + 5]), Integer(FMemory.ReadByte(LPlane, 229)));
  end;
  Assert.AreEqual(0, Integer(FMemory.ReadByte(0, 102)));
end;

procedure TTestKeenVideo.DovrebbeRiportareInMemoriaCioCheSiTrovaSulloSchermo;
var
  LSource: TBytes;
  LIndex: Integer;
begin
  SetLength(LSource, 4 * 3 * 5);
  for LIndex := 0 to High(LSource) do
    LSource[LIndex] := Byte(LIndex * 7 + 3);
  FVideo.MemToScreen(LSource, 640, 3, 5);
  Assert.AreEqual(TBytes(LSource), FVideo.ScreenToMem(640, 3, 5));
end;

procedure TTestKeenVideo.DovrebbeFareIlGiroDei64KBNelleCopie;
var
  LSource: TBytes;
  LIndex: Integer;
begin
  SetLength(LSource, 4 * 4 * 2);
  for LIndex := 0 to High(LSource) do
    LSource[LIndex] := Byte(LIndex + 100);
  // the block starts 2 bytes before the end of the plane: the next bytes are at the start
  FVideo.MemToScreen(LSource, $FFFE, 4, 2);
  Assert.AreEqual(Integer(LSource[0]), Integer(FMemory.ReadByte(0, $FFFE)));
  Assert.AreEqual(Integer(LSource[2]), Integer(FMemory.ReadByte(0, 0)));
  Assert.AreEqual(Integer(LSource[3]), Integer(FMemory.ReadByte(0, 1)));
  Assert.AreEqual(Integer(LSource[4]), Integer(FMemory.ReadByte(0, 62)));
  Assert.AreEqual(TBytes(LSource), FVideo.ScreenToMem($FFFE, 4, 2));
end;

procedure TTestKeenVideo.DovrebbeComporreUnaMascheraSulloSfondo;
var
  LData: TBytes;
  LPlane: Integer;
  LRow: Integer;
  LColumn: Integer;
  LExpected: Byte;
begin
  // all the pixels of the block are 15 (the planes at 255), so (screen and mask) is the mask
  FVideo.Bar(160, 0, 16, 4, 15);
  // a mask of 2 x 4 bytes (planes of 8 bytes) in 5 planes
  SetLength(LData, 8 * 5 + 3);
  for LRow := 0 to High(LData) do
    LData[LRow] := Byte(LRow * 37 + 11);
  FVideo.MaskBlock(LData, 3, 20, 2, 4, 8);
  for LPlane := 0 to 3 do
    for LRow := 0 to 3 do
      for LColumn := 0 to 1 do
      begin
        LExpected := Byte((255 and LData[3 + LRow * 2 + LColumn]) or LData[3 + 8 * (LPlane + 1) + LRow * 2 + LColumn]);
        Assert.AreEqual(Integer(LExpected), Integer(FMemory.ReadByte(LPlane, 20 + LRow * 64 + LColumn)));
      end;
end;

procedure TTestKeenVideo.DovrebbeNonDisegnareUnBloccoLargoZero;
var
  LBefore: Cardinal;
begin
  LBefore := TFakeKeenPixels.MemoryHash(FMemory);
  FVideo.MaskBlock(nil, 0, 0, 0, 4, 0);
  Assert.AreEqual(LBefore, TFakeKeenPixels.MemoryHash(FMemory));
end;

procedure TTestKeenVideo.DovrebbeRifiutareUnBloccoPiuCortoDelDovuto;
begin
  Assert.WillRaise(
    procedure
    begin
      FVideo.MaskBlock(TBytes.Create(1, 2, 3), 0, 0, 1, 1, 1);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      FVideo.MemToScreen(TBytes.Create(1, 2, 3), 0, 1, 1);
    end, EKeenDataException);
end;

procedure TTestKeenVideo.DovrebbeCopiareUnBloccoConLeLatch;
var
  LX: Integer;
  LY: Integer;
begin
  FVideo.Bar(8, 3, 16, 5, 11);
  FVideo.Plot(9, 4, 2);
  FVideo.ScreenToScreen(1 + 3 * 64, 20 + 40 * 64, 2, 5);
  for LY := 0 to 4 do
    for LX := 0 to 15 do
      Assert.AreEqual(Integer(Pixel(8 + LX, 3 + LY)), Integer(Pixel(160 + LX, 40 + LY)));
end;

procedure TTestKeenVideo.DovrebbeCopiareUnBloccoCheSiSovrappone;
begin
  // copies row after row, byte after byte, like movsb: a block that goes right over itself repeats
  FMemory.WriteByte(0, 10, $AA);
  FVideo.ScreenToScreen(10, 11, 4, 1);
  Assert.AreEqual($AA, Integer(FMemory.ReadByte(0, 11)));
  Assert.AreEqual($AA, Integer(FMemory.ReadByte(0, 14)));
end;

procedure TTestKeenVideo.DovrebbeColorareTuttoLoSchermo;
begin
  FVideo.ClearVideo(6);
  Assert.AreEqual(6, Integer(Pixel(0, 0)));
  Assert.AreEqual(6, Integer(Pixel(300, 100)));
  Assert.AreEqual($00, Integer(FMemory.ReadByte(0, 65535)));
  Assert.AreEqual($FF, Integer(FMemory.ReadByte(1, 65535)));
  Assert.AreEqual($FF, Integer(FMemory.ReadByte(2, 5)));
  Assert.AreEqual($00, Integer(FMemory.ReadByte(3, 5)));
end;

procedure TTestKeenVideo.DovrebbeDisegnareUnTileDa8;
var
  LImage: TKeenChunkyImage;
  LX: Integer;
  LY: Integer;
begin
  FVideo.DrawTile8(3, 10, 4);
  LImage := TKeenPlanarConverter.ToChunky(FGraphics.Tile8(4), 0, 1, 8);
  for LY := 0 to 7 do
    for LX := 0 to 7 do
      Assert.AreEqual(Integer(LImage.Pixels[LY * 8 + LX]), Integer(Pixel(24 + LX, 10 + LY)));
end;

procedure TTestKeenVideo.DovrebbeDisegnareUnTileDa16;
var
  LImage: TKeenChunkyImage;
  LX: Integer;
  LY: Integer;
begin
  FVideo.DrawTile16(5, 20, 9);
  LImage := TKeenPlanarConverter.ToChunky(FGraphics.Tile16(9), 0, 2, 16);
  for LY := 0 to 15 do
    for LX := 0 to 15 do
      Assert.AreEqual(Integer(LImage.Pixels[LY * 16 + LX]), Integer(Pixel(40 + LX, 20 + LY)));
end;

procedure TTestKeenVideo.DovrebbeDisegnareUnTileMascheratoDa16;
var
  LBack: TKeenChunkyImage;
  LFront: TKeenChunkyImage;
  LMask: TBytes;
  LX: Integer;
  LY: Integer;
begin
  FVideo.DrawTile16(0, 0, 3);
  FVideo.DrawTile16Masked(0, 0, 5);
  LBack := TKeenPlanarConverter.ToChunky(FGraphics.Tile16(3), 0, 2, 16);
  LFront := TKeenPlanarConverter.ToChunkyMasked(FGraphics.Tile16Masked(5), 0, 2, 16, LMask);
  for LY := 0 to 15 do
    for LX := 0 to 15 do
      Assert.AreEqual(Integer((LBack.Pixels[LY * 16 + LX] and LMask[LY * 16 + LX]) or LFront.Pixels[LY * 16 + LX]),
        Integer(Pixel(LX, LY)));
end;

procedure TTestKeenVideo.DovrebbeDisegnareUnTileMascheratoDa8;
var
  LBack: TKeenChunkyImage;
  LFront: TKeenChunkyImage;
  LMask: TBytes;
  LX: Integer;
  LY: Integer;
begin
  FVideo.DrawTile8(1, 8, 2);
  FVideo.DrawTile8Masked(1, 8, 6);
  LBack := TKeenPlanarConverter.ToChunky(FGraphics.Tile8(2), 0, 1, 8);
  LFront := TKeenPlanarConverter.ToChunkyMasked(FGraphics.Tile8Masked(6), 0, 1, 8, LMask);
  for LY := 0 to 7 do
    for LX := 0 to 7 do
      Assert.AreEqual(Integer((LBack.Pixels[LY * 8 + LX] and LMask[LY * 8 + LX]) or LFront.Pixels[LY * 8 + LX]),
        Integer(Pixel(8 + LX, 8 + LY)));
end;

procedure TTestKeenVideo.DovrebbeDisegnareUnaImmagine;
var
  LImage: TKeenChunkyImage;
  LX: Integer;
  LY: Integer;
begin
  FVideo.DrawPic(2, 5, KEEN_STARTPICS + 0);
  LImage := TKeenPlanarConverter.ToChunky(FGraphics.PicturePlanar(0), 0, 3, 8);
  for LY := 0 to 7 do
    for LX := 0 to 23 do
      Assert.AreEqual(Integer(LImage.Pixels[LY * 24 + LX]), Integer(Pixel(16 + LX, 5 + LY)));
end;

procedure TTestKeenVideo.DovrebbeDisegnareUnaImmagineMascheraConLaSuaTabella;
var
  LImage: TKeenChunkyImage;
  LX: Integer;
  LY: Integer;
begin
  // the masked pictures have the size of picmtable (3 x 4 bytes for the second)
  FVideo.DrawMaskedPic(0, 0, KEEN_STARTPICM + 1);
  LImage := TKeenPlanarConverter.ToChunkyTransparent(FGraphics.MaskedPicturePlanar(1), 0, 3, 4);
  for LY := 0 to 3 do
    for LX := 0 to 23 do
      if LImage.Pixels[LY * 24 + LX] <> KEEN_PIXEL_TRANSPARENT then
        Assert.AreEqual(Integer(LImage.Pixels[LY * 24 + LX]), Integer(Pixel(LX, LY)));
end;

procedure TTestKeenVideo.DovrebbeSceglierelaCopiaScorrevoleDelloSprite;
var
  LShift: Integer;
  LOther: IKeenEgaMemory;
  LOtherVideo: IKeenVideo;
  LSprite: TKeenSprite;
begin
  LSprite := FSprites.GetSprite(KEEN_STARTSPRITES);
  // x = 24 + 2 * shift: the byte 3 and the copy of the shift
  for LShift := 0 to 3 do
  begin
    LOther := TKeenEgaMemory.Create;
    LOtherVideo := TKeenVideo.Create(LOther, nil, nil);
    LOtherVideo.MaskBlock(LSprite.Data, LSprite.SourceOffset[LShift], 4 * 64 + 3, LSprite.Width[LShift], 20,
      LSprite.PlaneSize[LShift]);
    FVideo.ClearVideo(0);
    FVideo.DrawSprite(24 + LShift * 2, 4, KEEN_STARTSPRITES);
    Assert.AreEqual(TFakeKeenPixels.MemoryHash(LOther), TFakeKeenPixels.MemoryHash(FMemory), 'shift ' + IntToStr(LShift));
    // an odd pixel is drawn with the copy of the even pixel before it
    FVideo.ClearVideo(0);
    FVideo.DrawSprite(24 + LShift * 2 + 1, 4, KEEN_STARTSPRITES);
    Assert.AreEqual(TFakeKeenPixels.MemoryHash(LOther), TFakeKeenPixels.MemoryHash(FMemory), 'odd ' + IntToStr(LShift));
  end;
end;

procedure TTestKeenVideo.DovrebbeDisegnareUnoSpriteConOrigine;
var
  LOther: IKeenEgaMemory;
  LOtherVideo: IKeenVideo;
  LSprite: TKeenSprite;
begin
  // the sprite 3 has the origin (-40, 72) in 1/16 of a pixel: -3 pixels (the shift keeps the sign) and +4
  FVideo.DrawSprite(50, 20, KEEN_STARTSPRITES + 3);
  LSprite := FSprites.GetSprite(KEEN_STARTSPRITES + 3);
  LOther := TKeenEgaMemory.Create;
  LOtherVideo := TKeenVideo.Create(LOther, nil, nil);
  // x = 47: the byte 5 and the shift (47 and 7) / 2 = 3; y = 24
  LOtherVideo.MaskBlock(LSprite.Data, LSprite.SourceOffset[3], 24 * 64 + 5, LSprite.Width[3], 12, LSprite.PlaneSize[3]);
  Assert.AreEqual(TFakeKeenPixels.MemoryHash(LOther), TFakeKeenPixels.MemoryHash(FMemory));
end;

procedure TTestKeenVideo.DovrebbeRicordareDoveLaSchedaMostraLoSchermo;
begin
  FVideo.SetScreen(70000, 11);
  Assert.AreEqual(70000 and $FFFF, FVideo.CrtcStart);
  Assert.AreEqual(3, FVideo.PelPan);
end;

procedure TTestKeenVideo.DovrebbeRifiutareDisegniSenzaGrafica;
var
  LBare: IKeenVideo;
begin
  LBare := TKeenVideo.Create(FMemory, nil, nil);
  Assert.WillRaise(
    procedure
    begin
      LBare.DrawTile16(0, 0, 1);
    end, EKeenException);
  Assert.WillRaise(
    procedure
    begin
      LBare.DrawSprite(0, 0, KEEN_STARTSPRITES);
    end, EKeenException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenVideo);

end.

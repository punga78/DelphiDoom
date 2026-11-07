{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thumbnail of a saved game (Imaging library)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.SaveThumbnail;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.SaveThumbnail;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingSaveThumbnail = class(TObject)
  strict private
    FThumbnail: TImagingSaveThumbnail;
    function Pixels(ALength: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeAvereLaDimensioneDelSalvataggio;
    [Test]
    procedure DovrebbeAvereIlMarcatoreMenuScreenshot;
    [Test]
    procedure DovrebbeRiconoscereIlMarcatoreScrittoDaUnSalvataggio;
    [Test]
    procedure DovrebbeRifiutareUnaMiniaturaVuota;
    [Test]
    [TestCase('primo', '0')]
    [TestCase('mezzo', '7')]
    [TestCase('ultimo', '13')]
    procedure DovrebbeRifiutareUnMarcatoreConUnByteDiverso(AIndex: Integer);
    [Test]
    procedure DovrebbeIgnorareIPixelNelControllo;
    [Test]
    procedure DovrebbeScrivereMarcatoreEPixel;
    [Test]
    [TestCase('vuoto', '0')]
    [TestCase('corto', '3999')]
    [TestCase('lungo', '4001')]
    procedure DovrebbeRifiutareIPixelDiUnaDimensioneDiversa(ALength: Integer);
  end;

implementation

const
  // the first 14 bytes of the thumbnail in a savegame of the engine (old MNSCREENSHOT_MAGIC)
  OLD_SAVEGAME_MAGIC: array[0..13] of Byte = (
    $4D, $45, $4E, $55, $53, $43, $52, $45, $45, $4E, $53, $48, $4F, $54
  );

procedure TTestImagingSaveThumbnail.Setup;
begin
  FillChar(FThumbnail, SizeOf(FThumbnail), 0);
end;

function TTestImagingSaveThumbnail.Pixels(ALength: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ALength);
  for LIndex := 0 to ALength - 1 do
    Result[LIndex] := Byte((LIndex * 7 + 3) and $FF);
end;

procedure TTestImagingSaveThumbnail.DovrebbeAvereLaDimensioneDelSalvataggio;
begin
  Assert.AreEqual(4014, Integer(SizeOf(TImagingSaveThumbnail)),
    'dovrebbe avere i 4014 byte di menuscreenbuffer_t');
  Assert.AreEqual(80, IMAGING_SAVE_THUMBNAIL_WIDTH);
  Assert.AreEqual(50, IMAGING_SAVE_THUMBNAIL_HEIGHT);
  Assert.AreEqual(4000, IMAGING_SAVE_THUMBNAIL_SIZE);
  Assert.AreEqual(14, IMAGING_SAVE_THUMBNAIL_MAGIC_SIZE);
end;

procedure TTestImagingSaveThumbnail.DovrebbeAvereIlMarcatoreMenuScreenshot;
var
  LText: AnsiString;
begin
  SetLength(LText, IMAGING_SAVE_THUMBNAIL_MAGIC_SIZE);
  Move(IMAGING_SAVE_THUMBNAIL_MAGIC[0], LText[1], IMAGING_SAVE_THUMBNAIL_MAGIC_SIZE);
  Assert.AreEqual('MENUSCREENSHOT', string(LText));
end;

procedure TTestImagingSaveThumbnail.DovrebbeRiconoscereIlMarcatoreScrittoDaUnSalvataggio;
begin
  Move(OLD_SAVEGAME_MAGIC[0], FThumbnail.Header[0], SizeOf(OLD_SAVEGAME_MAGIC));
  Assert.IsTrue(TImagingSaveThumbnailFormat.IsValid(FThumbnail));
end;

procedure TTestImagingSaveThumbnail.DovrebbeRifiutareUnaMiniaturaVuota;
begin
  Assert.IsFalse(TImagingSaveThumbnailFormat.IsValid(FThumbnail));
end;

procedure TTestImagingSaveThumbnail.DovrebbeRifiutareUnMarcatoreConUnByteDiverso(AIndex: Integer);
begin
  Move(OLD_SAVEGAME_MAGIC[0], FThumbnail.Header[0], SizeOf(OLD_SAVEGAME_MAGIC));
  FThumbnail.Header[AIndex] := FThumbnail.Header[AIndex] xor $20;
  Assert.IsFalse(TImagingSaveThumbnailFormat.IsValid(FThumbnail));
end;

procedure TTestImagingSaveThumbnail.DovrebbeIgnorareIPixelNelControllo;
begin
  Move(OLD_SAVEGAME_MAGIC[0], FThumbnail.Header[0], SizeOf(OLD_SAVEGAME_MAGIC));
  FillChar(FThumbnail.Data, SizeOf(FThumbnail.Data), $FF);
  Assert.IsTrue(TImagingSaveThumbnailFormat.IsValid(FThumbnail));
end;

procedure TTestImagingSaveThumbnail.DovrebbeScrivereMarcatoreEPixel;
var
  LPixels: TBytes;
  LIndex: Integer;
begin
  LPixels := Pixels(IMAGING_SAVE_THUMBNAIL_SIZE);
  TImagingSaveThumbnailFormat.Fill(FThumbnail, LPixels);
  for LIndex := 0 to High(OLD_SAVEGAME_MAGIC) do
    Assert.AreEqual(OLD_SAVEGAME_MAGIC[LIndex], FThumbnail.Header[LIndex]);
  for LIndex := 0 to IMAGING_SAVE_THUMBNAIL_SIZE - 1 do
    if FThumbnail.Data[LIndex] <> LPixels[LIndex] then
      Assert.Fail(Format('pixel %d diverso', [LIndex]));
  Assert.IsTrue(TImagingSaveThumbnailFormat.IsValid(FThumbnail));
end;

procedure TTestImagingSaveThumbnail.DovrebbeRifiutareIPixelDiUnaDimensioneDiversa(ALength: Integer);
var
  LPixels: TBytes;
begin
  LPixels := Pixels(ALength);
  Assert.WillRaise(
    procedure
    begin
      TImagingSaveThumbnailFormat.Fill(FThumbnail, LPixels);
    end, EImagingException);
  Assert.IsFalse(TImagingSaveThumbnailFormat.IsValid(FThumbnail), 'non dovrebbe scrivere nulla');
end;

end.

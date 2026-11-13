{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - a map as a picture                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.MapRenderer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenMapRenderer = class(TObject)
  private
    FRenderer: IKeenMapRenderer;
    FGraphics: IKeenGraphics;
    function MakeMap(AWidth, AHeight: Word; const ABackground, AForeground: TArray<Word>): IKeenMap;
    function PixelAt(const AImage: TKeenChunkyImage; AX, AY: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareSedicipixelPerTile;
    [Test]
    procedure DovrebbeDisegnareITileDelloSfondo;
    [Test]
    procedure DovrebbeLasciareNeroUnTileSenzaDati;
    [Test]
    procedure DovrebbeSaltareITileNegativi;
    [Test]
    procedure DovrebbeDisegnareIlPrimoPianoConLaMaschera;
    [Test]
    procedure DovrebbeNonDisegnareIlTileZeroDelPrimoPiano;
    [Test]
    procedure DovrebbeLasciareLoSfondoSeIlTileDelPrimoPianoNonHaDati;
    [Test]
    procedure DovrebbeRifiutareUnTileFuoriDallaTabella;
    [Test]
    procedure DovrebbeVolereUnaMappaEIGrafici;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Keen.Map, DelphiDoom.Tests.Keen.Builders;

type
  /// <summary>Tiles that are a plain color: a background tile of the color of its number, a masked tile with an open row</summary>
  TFakeTiles = class(TInterfacedObject, IKeenGraphics)
  public
    function GetChunks: IKeenChunkSource;
    function GetPictureTable: TArray<TKeenPictureEntry>;
    function GetMaskedPictureTable: TArray<TKeenPictureEntry>;
    function GetSpriteTable: TArray<TKeenSpriteEntry>;
    function PicturePlanar(AIndex: Integer): TBytes;
    function MaskedPicturePlanar(AIndex: Integer): TBytes;
    function SpritePlanar(AIndex: Integer): TBytes;
    function Tile8(AIndex: Integer): TBytes;
    function Tile8Masked(AIndex: Integer): TBytes;
    function Tile16(AIndex: Integer): TBytes;
    function Tile16Masked(AIndex: Integer): TBytes;
  end;

{ TFakeTiles }

function TFakeTiles.GetChunks: IKeenChunkSource;
begin
  Result := nil;
end;

function TFakeTiles.GetPictureTable: TArray<TKeenPictureEntry>;
begin
  Result := nil;
end;

function TFakeTiles.GetMaskedPictureTable: TArray<TKeenPictureEntry>;
begin
  Result := nil;
end;

function TFakeTiles.GetSpriteTable: TArray<TKeenSpriteEntry>;
begin
  Result := nil;
end;

function TFakeTiles.PicturePlanar(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TFakeTiles.MaskedPicturePlanar(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TFakeTiles.SpritePlanar(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TFakeTiles.Tile8(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TFakeTiles.Tile8Masked(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TFakeTiles.Tile16(AIndex: Integer): TBytes;
var
  LPlane: Integer;
begin
  // tile 5 has no data (a sparse tile); the others are the plane bits of their number (1..15), solid
  Result := nil;
  if AIndex = 5 then
    Exit;
  SetLength(Result, KEEN_TILE16_BYTES);
  FillChar(Result[0], Length(Result), 0);
  for LPlane := 0 to 3 do
    if (AIndex and (1 shl LPlane)) <> 0 then
      FillChar(Result[LPlane * 32], 32, $FF);
end;

function TFakeTiles.Tile16Masked(AIndex: Integer): TBytes;
var
  LRow: Integer;
begin
  // the tile 9 has no data; the others: the mask keeps the left byte of every row (pixels 0..7), and the right
  // byte is drawn red (the plane 2, after the mask plane and the planes 0 and 1)
  Result := nil;
  if AIndex = 9 then
    Exit;
  SetLength(Result, KEEN_TILE16M_BYTES);
  FillChar(Result[0], Length(Result), 0);
  for LRow := 0 to 15 do
  begin
    Result[LRow * 2] := $FF;
    Result[32 + 2 * 32 + LRow * 2 + 1] := $FF;
  end;
end;

{ TTestKeenMapRenderer }

procedure TTestKeenMapRenderer.Setup;
begin
  FRenderer := TKeenFactory.CreateMapRenderer;
  FGraphics := TFakeTiles.Create;
end;

procedure TTestKeenMapRenderer.TearDown;
begin
  FGraphics := nil;
  FRenderer := nil;
end;

function TTestKeenMapRenderer.MakeMap(AWidth, AHeight: Word; const ABackground,
  AForeground: TArray<Word>): IKeenMap;
var
  LHeader: TKeenMapHeader;
  LInfo: TArray<Word>;
begin
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Width := AWidth;
  LHeader.Height := AHeight;
  SetLength(LInfo, AWidth * AHeight);
  Result := TKeenMap.Create(0, LHeader, [ABackground, AForeground, LInfo]);
end;

function TTestKeenMapRenderer.PixelAt(const AImage: TKeenChunkyImage; AX, AY: Integer): Integer;
begin
  Result := AImage.Pixels[AY * AImage.Width + AX];
end;

procedure TTestKeenMapRenderer.DovrebbeDareSedicipixelPerTile;
var
  LImage: TKeenChunkyImage;
begin
  LImage := FRenderer.Render(MakeMap(3, 2, [1, 2, 3, 4, 6, 7], [0, 0, 0, 0, 0, 0]), FGraphics);
  Assert.AreEqual(48, LImage.Width);
  Assert.AreEqual(32, LImage.Height);
  Assert.AreEqual<Integer>(48 * 32, Length(LImage.Pixels));
end;

procedure TTestKeenMapRenderer.DovrebbeDisegnareITileDelloSfondo;
var
  LImage: TKeenChunkyImage;
begin
  LImage := FRenderer.Render(MakeMap(3, 2, [1, 2, 3, 4, 6, 7], [0, 0, 0, 0, 0, 0]), FGraphics);
  Assert.AreEqual(1, PixelAt(LImage, 0, 0));
  Assert.AreEqual(1, PixelAt(LImage, 15, 15));
  Assert.AreEqual(2, PixelAt(LImage, 16, 0));
  Assert.AreEqual(3, PixelAt(LImage, 47, 15));
  Assert.AreEqual(4, PixelAt(LImage, 0, 16));
  Assert.AreEqual(7, PixelAt(LImage, 47, 31));
end;

procedure TTestKeenMapRenderer.DovrebbeLasciareNeroUnTileSenzaDati;
var
  LImage: TKeenChunkyImage;
begin
  LImage := FRenderer.Render(MakeMap(2, 1, [5, 3], [0, 0]), FGraphics);
  Assert.AreEqual(0, PixelAt(LImage, 3, 3));
  Assert.AreEqual(3, PixelAt(LImage, 20, 3));
end;

procedure TTestKeenMapRenderer.DovrebbeSaltareITileNegativi;
var
  LImage: TKeenChunkyImage;
begin
  LImage := FRenderer.Render(MakeMap(2, 1, [$FFFF, 3], [0, 0]), FGraphics);
  Assert.AreEqual(0, PixelAt(LImage, 3, 3), 'un tile negativo non si disegna mai');
  Assert.AreEqual(3, PixelAt(LImage, 20, 3));
end;

procedure TTestKeenMapRenderer.DovrebbeDisegnareIlPrimoPianoConLaMaschera;
var
  LImage: TKeenChunkyImage;
begin
  // background 1 (blue); the masked tile 3 keeps the screen where the mask is 1 and is red (4) elsewhere
  LImage := FRenderer.Render(MakeMap(1, 1, [8], [3]), FGraphics);
  Assert.AreEqual(8, PixelAt(LImage, 0, 0), 'maschera 1: resta lo sfondo');
  Assert.AreEqual(8, PixelAt(LImage, 7, 15));
  Assert.AreEqual(4, PixelAt(LImage, 8, 0), 'maschera 0: il colore del primo piano');
  Assert.AreEqual(4, PixelAt(LImage, 15, 15));
end;

procedure TTestKeenMapRenderer.DovrebbeNonDisegnareIlTileZeroDelPrimoPiano;
var
  LImage: TKeenChunkyImage;
begin
  LImage := FRenderer.Render(MakeMap(1, 1, [8], [0]), FGraphics);
  Assert.AreEqual(8, PixelAt(LImage, 12, 12));
end;

procedure TTestKeenMapRenderer.DovrebbeLasciareLoSfondoSeIlTileDelPrimoPianoNonHaDati;
var
  LImage: TKeenChunkyImage;
begin
  LImage := FRenderer.Render(MakeMap(1, 1, [8], [9]), FGraphics);
  Assert.AreEqual(8, PixelAt(LImage, 12, 12));
end;

procedure TTestKeenMapRenderer.DovrebbeRifiutareUnTileFuoriDallaTabella;
begin
  Assert.WillRaise(
    procedure
    begin
      FRenderer.Render(MakeMap(1, 1, [1440], [0]), FGraphics);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      FRenderer.Render(MakeMap(1, 1, [1], [1206]), FGraphics);
    end, EKeenDataException);
end;

procedure TTestKeenMapRenderer.DovrebbeVolereUnaMappaEIGrafici;
begin
  Assert.WillRaise(procedure begin FRenderer.Render(nil, FGraphics); end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      FRenderer.Render(MakeMap(1, 1, [1], [0]), nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenMapRenderer);

end.

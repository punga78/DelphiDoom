{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the graphics by kind                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Graphics;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf,
  DelphiDoom.Tests.Keen.Builders;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenGraphics = class(TObject)
  private
    FGame: TTestGame;
    FGraphics: IKeenGraphics;
    function SameBytes(const AExpected, AActual: TBytes): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLaTabellaDelleImmagini;
    [Test]
    procedure DovrebbeLeggereLaTabellaDelleImmaginiMascherateDellaSuaLunghezza;
    [Test]
    procedure DovrebbeLeggereLaTabellaDegliSprite;
    [Test]
    procedure DovrebbeDareIPianiDiUnaImmagine;
    [Test]
    procedure DovrebbeDareIPianiDiUnaImmagineMascherata;
    [Test]
    procedure DovrebbeDareIPianiDiUnoSprite;
    [Test]
    procedure DovrebbeTagliareITileDa8;
    [Test]
    procedure DovrebbeTagliareITileDa8Mascherati;
    [Test]
    procedure DovrebbeDareITileDa16;
    [Test]
    procedure DovrebbeDareUnTileDa16SenzaDatiVuoto;
    [Test]
    procedure DovrebbeRifiutareUnIndiceCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineDiDimensioneDiversaDallaTabella;
    [Test]
    procedure DovrebbeVolerUnFileGraficoCompleto;
  end;

implementation

uses
  DelphiDoom.Keen.Factory;

type
  /// <summary>A graphics file whose tables say one thing and whose pictures are another</summary>
  TFakeChunks = class(TInterfacedObject, IKeenChunkSource)
  public
    function GetChunkCount: Integer;
    function HasChunk(AIndex: Integer): Boolean;
    function ReadCompressed(AIndex: Integer): TBytes;
    function Read(AIndex: Integer): TBytes;
  end;

{ TFakeChunks }

function TFakeChunks.GetChunkCount: Integer;
begin
  Result := KEEN_NUMCHUNKS;
end;

function TFakeChunks.HasChunk(AIndex: Integer): Boolean;
begin
  Result := True;
end;

function TFakeChunks.ReadCompressed(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TFakeChunks.Read(AIndex: Integer): TBytes;
begin
  case AIndex of
    KEEN_STRUCTPIC: Result := TBytes.Create(1, 0, 2, 0);
    KEEN_STRUCTPICM: Result := TBytes.Create(1, 0, 1, 0);
    KEEN_STRUCTSPRITE: Result := TBytes.Create(1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0);
    KEEN_STARTPICS: SetLength(Result, 9);
    KEEN_STARTPICM: SetLength(Result, 4);
    KEEN_STARTSPRITES: SetLength(Result, 8);
  else
    Result := nil;
  end;
end;

{ TTestKeenGraphics }

procedure TTestKeenGraphics.Setup;
begin
  FGame := TTestGame.Create(2);
  FGraphics := TKeenFactory.OpenGameData(FGame.Files).Graphics;
end;

procedure TTestKeenGraphics.TearDown;
begin
  FGraphics := nil;
  FGame.Free;
end;

function TTestKeenGraphics.SameBytes(const AExpected, AActual: TBytes): Boolean;
begin
  Result := (Length(AExpected) = Length(AActual)) and
    ((Length(AExpected) = 0) or CompareMem(@AExpected[0], @AActual[0], Length(AExpected)));
end;

procedure TTestKeenGraphics.DovrebbeLeggereLaTabellaDelleImmagini;
var
  LTable: TArray<TKeenPictureEntry>;
begin
  LTable := FGraphics.PictureTable;
  Assert.AreEqual<Integer>(2, Length(LTable));
  Assert.AreEqual(1, Integer(LTable[0].Width));
  Assert.AreEqual(2, Integer(LTable[0].Height));
  Assert.AreEqual(2, Integer(LTable[1].Width));
  Assert.AreEqual(1, Integer(LTable[1].Height));
end;

procedure TTestKeenGraphics.DovrebbeLeggereLaTabellaDelleImmaginiMascherateDellaSuaLunghezza;
begin
  // the C expands this table with the length of the picture table: here the length of its own chunk
  Assert.AreEqual<Integer>(1, Length(FGraphics.MaskedPictureTable));
end;

procedure TTestKeenGraphics.DovrebbeLeggereLaTabellaDegliSprite;
var
  LTable: TArray<TKeenSpriteEntry>;
begin
  LTable := FGraphics.SpriteTable;
  Assert.AreEqual<Integer>(1, Length(LTable));
  Assert.AreEqual(1, Integer(LTable[0].Width));
  Assert.AreEqual(2, Integer(LTable[0].Height));
  Assert.AreEqual(3, Integer(LTable[0].OriginX));
  Assert.AreEqual(4, Integer(LTable[0].OriginY));
  Assert.AreEqual(5, Integer(LTable[0].XL));
  Assert.AreEqual(6, Integer(LTable[0].YL));
  Assert.AreEqual(7, Integer(LTable[0].XH));
  Assert.AreEqual(8, Integer(LTable[0].YH));
  Assert.AreEqual(4, Integer(LTable[0].Shifts));
end;

procedure TTestKeenGraphics.DovrebbeDareIPianiDiUnaImmagine;
begin
  Assert.IsTrue(SameBytes(FGame.Picture0, FGraphics.PicturePlanar(0)));
  Assert.IsTrue(SameBytes(FGame.Picture1, FGraphics.PicturePlanar(1)));
end;

procedure TTestKeenGraphics.DovrebbeDareIPianiDiUnaImmagineMascherata;
begin
  Assert.IsTrue(SameBytes(FGame.MaskedPicture0, FGraphics.MaskedPicturePlanar(0)));
end;

procedure TTestKeenGraphics.DovrebbeDareIPianiDiUnoSprite;
begin
  Assert.IsTrue(SameBytes(FGame.Sprite0, FGraphics.SpritePlanar(0)));
end;

procedure TTestKeenGraphics.DovrebbeTagliareITileDa8;
var
  LTile: TBytes;
begin
  LTile := FGraphics.Tile8(5);
  Assert.AreEqual<Integer>(KEEN_TILE8_BYTES, Length(LTile));
  Assert.IsTrue(SameBytes(Copy(FGame.Tile8All, 5 * 32, 32), LTile));
  Assert.IsTrue(SameBytes(Copy(FGame.Tile8All, 71 * 32, 32), FGraphics.Tile8(71)), 'l''ultimo');
end;

procedure TTestKeenGraphics.DovrebbeTagliareITileDa8Mascherati;
begin
  Assert.IsTrue(SameBytes(Copy(FGame.Tile8MaskedAll, 3 * 40, 40), FGraphics.Tile8Masked(3)));
  Assert.IsTrue(SameBytes(Copy(FGame.Tile8MaskedAll, 35 * 40, 40), FGraphics.Tile8Masked(35)));
end;

procedure TTestKeenGraphics.DovrebbeDareITileDa16;
begin
  Assert.IsTrue(SameBytes(FGame.Tile16Zero, FGraphics.Tile16(0)));
  Assert.IsTrue(SameBytes(FGame.Tile16MaskedZero, FGraphics.Tile16Masked(0)));
end;

procedure TTestKeenGraphics.DovrebbeDareUnTileDa16SenzaDatiVuoto;
begin
  Assert.AreEqual<Integer>(0, Length(FGraphics.Tile16(1)));
  Assert.AreEqual<Integer>(0, Length(FGraphics.Tile16Masked(1205)));
end;

procedure TTestKeenGraphics.DovrebbeRifiutareUnIndiceCheNonCe;
begin
  Assert.WillRaise(procedure begin FGraphics.PicturePlanar(2); end, EKeenDataException);
  Assert.WillRaise(procedure begin FGraphics.PicturePlanar(-1); end, EKeenDataException);
  Assert.WillRaise(procedure begin FGraphics.MaskedPicturePlanar(1); end, EKeenDataException);
  Assert.WillRaise(procedure begin FGraphics.SpritePlanar(1); end, EKeenDataException);
  Assert.WillRaise(procedure begin FGraphics.Tile8(72); end, EKeenDataException);
  Assert.WillRaise(procedure begin FGraphics.Tile8Masked(36); end, EKeenDataException);
  Assert.WillRaise(procedure begin FGraphics.Tile16(1440); end, EKeenDataException);
  Assert.WillRaise(procedure begin FGraphics.Tile16Masked(1206); end, EKeenDataException);
  Assert.WillRaise(procedure begin FGraphics.Tile16Masked(-1); end, EKeenDataException);
end;

procedure TTestKeenGraphics.DovrebbeRifiutareUnaImmagineDiDimensioneDiversaDallaTabella;
var
  LGraphics: IKeenGraphics;
begin
  LGraphics := TKeenFactory.CreateGraphics(TFakeChunks.Create);
  // the table says 1 x 2 bytes: 8 bytes of planes; the chunk has 9
  Assert.WillRaise(procedure begin LGraphics.PicturePlanar(0); end, EKeenDataException);
  // the sprite says 1 x 2: 10 bytes with the mask; the chunk has 8
  Assert.WillRaise(procedure begin LGraphics.SpritePlanar(0); end, EKeenDataException);
  // the masked picture is 1 x 1: 5 bytes; the chunk has 4
  Assert.WillRaise(procedure begin LGraphics.MaskedPicturePlanar(0); end, EKeenDataException);
end;

procedure TTestKeenGraphics.DovrebbeVolerUnFileGraficoCompleto;
var
  LChunks: IKeenChunkSource;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenFactory.CreateGraphics(nil);
    end, EArgumentNilException);
  // a file with fewer chunks than the game has
  LChunks := TKeenFactory.CreateAudioChunks(
    TKeenFactory.CreateOffsetTable(FGame.Files.ReadAll('AUDIOHHD.KDR'), 'AUDIOHHD.KDR'),
    TKeenFactory.CreateHuffman(FGame.Files.ReadAll('AUDIODCT.KDR')), FGame.Files.OpenStream('KDREAMS.AUD'));
  Assert.WillRaise(
    procedure
    begin
      TKeenFactory.CreateGraphics(LChunks);
    end, EKeenDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenGraphics);

end.

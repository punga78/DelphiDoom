{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of the graphic records with   }
{  the C of the remake on the real DATA.WAR                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.GraphicsParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Intf,
  DelphiDoom.War.Graphics.Types, DelphiDoom.War.Graphics.Intf, DelphiDoom.MathCore.Crc32,
  DelphiDoom.Tests.War.RealData;

type
  /// <summary>
  ///   graphics.golden.txt is the output of war_gfx_ref.exe: the loaders ORIGINAL of war_resources.c of war1
  ///   (wres_loadPaletteResource, wres_loadImageResource, wres_loadSpriteResource, wres_loadCursor,
  ///   wres_loadTiles, wres_loadTileset, with wres_getPalette), extracted as they are, compiled with gcc and run
  ///   on DATA.WAR in the order of the table (Tools\Verifica\192). One line per graphic record with the CRC-32 of
  ///   what it decoded: palette (768 bytes), image and cursor (RGBA pixels), sprite (the frame headers and the
  ///   pixels of all the frames), tiles (the bytes) and tileset (the 512 x 256 RGBA image)
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarGraphicsParity = class(TObject)
  private
    function Hex(const ABytes: TBytes): string;
    function CountOf(const ALines: TStringList; const APrefix: string): Integer;
    function LineOf(const AGraphics: IWarGraphics; const AEntry: TWarCatalogEntry): string;
    function Listing(const AArchive: IWarArchive; const ACatalog: IWarCatalog): TStringList;
    function ImageLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
    function SpriteLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
    function CursorLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
    function TilesLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
    function TilesetLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
    function PaletteLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
  public
    [Test]
    procedure DovrebbeDareLeStesseImprontedelCodiceOriginaleSuTuttiIRecordGrafici;
    [Test]
    procedure DovrebbeDecodificare184RecordGrafici;
    [Test]
    procedure DovrebbeDecodificareOgniTipoGrafico;
    [Test]
    procedure DovrebbeScrivereAlcuniPNGPerLIspezioneVisiva;
  end;

implementation

uses
  System.IOUtils, DUnitX.Exceptions, DelphiDoom.War.Factory, DelphiDoom.Tests.War.PngWriter;

const
  // a full screen image, a sprite of 65 frames of 48 x 48, a cursor and the image of a tileset
  IMAGE_SAMPLE = 216;
  SPRITE_SAMPLE = 279;
  CURSOR_SAMPLE = 265;
  TILESET_SAMPLE = 189;

{ TTestWarGraphicsParity }

function TTestWarGraphicsParity.Hex(const ABytes: TBytes): string;
var
  LCrc: TCrc32;
begin
  LCrc := TCrc32.Create;
  try
    if Length(ABytes) > 0 then
      LCrc.Update(ABytes[0], Length(ABytes));
    Result := LowerCase(TCrc32.ToHex(LCrc.Value));
  finally
    LCrc.Free;
  end;
end;

function TTestWarGraphicsParity.CountOf(const ALines: TStringList; const APrefix: string): Integer;
var
  LLine: string;
begin
  Result := 0;
  for LLine in ALines do
    if LLine.StartsWith(APrefix) then
      Inc(Result);
end;

function TTestWarGraphicsParity.PaletteLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
begin
  Result := Format('P %d %s', [AIndex, Hex(AGraphics.GetPalette(AIndex))]);
end;

function TTestWarGraphicsParity.ImageLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
var
  LImage: TWarImage;
begin
  LImage := AGraphics.GetImage(AIndex);
  Result := Format('I %d %d %d %s', [AIndex, LImage.Width, LImage.Height, Hex(LImage.Pixels)]);
end;

function TTestWarGraphicsParity.SpriteLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
var
  LSprite: TWarSprite;
  LHeads: TCrc32;
  LPixels: TCrc32;
  LFrame: Integer;
  LHeader: array[0..7] of Byte;
begin
  LSprite := AGraphics.GetSprite(AIndex);
  LHeads := TCrc32.Create;
  LPixels := TCrc32.Create;
  try
    for LFrame := 0 to High(LSprite.Frames) do
    begin
      LHeader[0] := Byte(LSprite.Frames[LFrame].Dx);
      LHeader[1] := Byte(LSprite.Frames[LFrame].Dy);
      LHeader[2] := Byte(LSprite.Frames[LFrame].Width);
      LHeader[3] := Byte(LSprite.Frames[LFrame].Height);
      LHeader[4] := Byte(LSprite.Frames[LFrame].Offset);
      LHeader[5] := Byte(LSprite.Frames[LFrame].Offset shr 8);
      LHeader[6] := Byte(LSprite.Frames[LFrame].Offset shr 16);
      LHeader[7] := Byte(LSprite.Frames[LFrame].Offset shr 24);
      LHeads.Update(LHeader[0], 8);
      if Length(LSprite.Frames[LFrame].Pixels) > 0 then
        LPixels.Update(LSprite.Frames[LFrame].Pixels[0], Length(LSprite.Frames[LFrame].Pixels));
    end;
    Result := Format('S %d %d %d %d %s %s', [AIndex, Length(LSprite.Frames), LSprite.FrameWidth, LSprite.FrameHeight,
      LowerCase(TCrc32.ToHex(LHeads.Value)), LowerCase(TCrc32.ToHex(LPixels.Value))]);
  finally
    LPixels.Free;
    LHeads.Free;
  end;
end;

function TTestWarGraphicsParity.CursorLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
var
  LCursor: TWarCursor;
begin
  LCursor := AGraphics.GetCursor(AIndex);
  Result := Format('C %d %d %d %d %d %s', [AIndex, LCursor.HotX, LCursor.HotY, LCursor.Width, LCursor.Height,
    Hex(LCursor.Pixels)]);
end;

function TTestWarGraphicsParity.TilesLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
var
  LTiles: TWarTiles;
begin
  LTiles := AGraphics.GetTiles(AIndex);
  Result := Format('T %d %d %d %d %s', [AIndex, LTiles.Palette1, LTiles.Palette2, Length(LTiles.Data),
    Hex(LTiles.Data)]);
end;

function TTestWarGraphicsParity.TilesetLine(const AGraphics: IWarGraphics; AIndex: Integer): string;
var
  LTileset: TWarTileset;
begin
  LTileset := AGraphics.GetTileset(AIndex);
  Result := Format('X %d %d %s', [AIndex, LTileset.TilesCount, Hex(LTileset.Pixels)]);
end;

function TTestWarGraphicsParity.LineOf(const AGraphics: IWarGraphics; const AEntry: TWarCatalogEntry): string;
begin
  case AEntry.RecordType of
    wrtPalette: Result := PaletteLine(AGraphics, AEntry.Index);
    wrtImage: Result := ImageLine(AGraphics, AEntry.Index);
    wrtSprite: Result := SpriteLine(AGraphics, AEntry.Index);
    wrtCursor: Result := CursorLine(AGraphics, AEntry.Index);
    wrtTiles: Result := TilesLine(AGraphics, AEntry.Index);
    wrtTileset: Result := TilesetLine(AGraphics, AEntry.Index);
  else
    Result := '';
  end;
end;

function TTestWarGraphicsParity.Listing(const AArchive: IWarArchive; const ACatalog: IWarCatalog): TStringList;
var
  LGraphics: IWarGraphics;
  LPosition: Integer;
  LLine: string;
begin
  LGraphics := TWarFactory.CreateGraphics(AArchive, ACatalog);
  Result := TStringList.Create;
  for LPosition := 0 to ACatalog.Count - 1 do
  begin
    LLine := LineOf(LGraphics, ACatalog.GetEntry(LPosition));
    if LLine <> '' then
      Result.Add(LLine);
  end;
end;

procedure TTestWarGraphicsParity.DovrebbeDareLeStesseImprontedelCodiceOriginaleSuTuttiIRecordGrafici;
var
  LCatalog: IWarCatalog;
  LGolden: TStringList;
  LActual: TStringList;
  LIndex: Integer;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('graphics.golden.txt'));
    LActual := Listing(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
    try
      Assert.AreEqual(LGolden.Count, LActual.Count);
      for LIndex := 0 to LGolden.Count - 1 do
        Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'riga ' + IntToStr(LIndex));
    finally
      LActual.Free;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarGraphicsParity.DovrebbeDecodificare184RecordGrafici;
var
  LCatalog: IWarCatalog;
  LActual: TStringList;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LActual := Listing(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
  try
    Assert.AreEqual(184, LActual.Count);
  finally
    LActual.Free;
  end;
end;

procedure TTestWarGraphicsParity.DovrebbeDecodificareOgniTipoGrafico;
var
  LCatalog: IWarCatalog;
  LActual: TStringList;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LActual := Listing(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
  try
    Assert.AreEqual(14, CountOf(LActual, 'P '));
    Assert.AreEqual(57, CountOf(LActual, 'I '));
    Assert.AreEqual(91, CountOf(LActual, 'S '));
    Assert.AreEqual(16, CountOf(LActual, 'C '));
    Assert.AreEqual(3, CountOf(LActual, 'T '));
    Assert.AreEqual(3, CountOf(LActual, 'X '));
  finally
    LActual.Free;
  end;
end;

procedure TTestWarGraphicsParity.DovrebbeScrivereAlcuniPNGPerLIspezioneVisiva;
var
  LCatalog: IWarCatalog;
  LGraphics: IWarGraphics;
  LFolder: string;
  LImage: TWarImage;
  LSprite: TWarSprite;
  LCursor: TWarCursor;
  LTileset: TWarTileset;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_WAR_PNG_OUT');
  if LFolder = '' then
    raise ETestIgnored.Create('DELPHIDOOM_WAR_PNG_OUT non e'' impostata: i PNG di ispezione non si scrivono (vanno fuori dal repository)');
  LCatalog := TWarFactory.CreateCatalog;
  LGraphics := TWarFactory.CreateGraphics(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
  ForceDirectories(LFolder);
  LImage := LGraphics.GetImage(IMAGE_SAMPLE);
  TWarPngWriter.Save(TPath.Combine(LFolder, 'image.png'), LImage.Width, LImage.Height, LImage.Pixels);
  LSprite := LGraphics.GetSprite(SPRITE_SAMPLE);
  TWarPngWriter.Save(TPath.Combine(LFolder, 'sprite_frame0.png'), LSprite.FrameWidth, LSprite.FrameHeight, LSprite.Frames[0].Pixels);
  LCursor := LGraphics.GetCursor(CURSOR_SAMPLE);
  TWarPngWriter.Save(TPath.Combine(LFolder, 'cursor.png'), LCursor.Width, LCursor.Height, LCursor.Pixels);
  LTileset := LGraphics.GetTileset(TILESET_SAMPLE);
  TWarPngWriter.Save(TPath.Combine(LFolder, 'tileset.png'), 512, 256, LTileset.Pixels);
end;

end.

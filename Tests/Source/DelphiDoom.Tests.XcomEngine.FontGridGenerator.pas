{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomFontGridGenerator (the characters of a        }
{  second source written as the pictures and the Font.dat of a mod)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.FontGridGenerator;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Factory, DelphiDoom.Png.Provider,
  DelphiDoom.Png.PaletteEncoder.Intf, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomSurface.Font,
  DelphiDoom.XcomSurface.Intf, DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.GlyphRasterizer.Intf,
  DelphiDoom.XcomSurface.FontOverlay.Intf, DelphiDoom.XcomEngine.FontRuleReader,
  DelphiDoom.XcomEngine.FontGridGenerator, DelphiDoom.Tests.XcomEngine.World,
  DelphiDoom.Tests.XcomSurface.FakeRasterizer, DelphiDoom.Tests.XcomEngine.FontFakes;

type
  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomFontGridGenerator = class
  strict private
    FFiles: TFakeFileSystem;
    FFilesRef: IXcomFileSystem;
    FRasterizer: TFakeGlyphRasterizer;
    FFactory: TFakeGlyphRasterizerFactory;
    FFactoryRef: IXcomGlyphRasterizerFactory;
    FOverlay: IXcomFontOverlay;
    FEncoder: IPngPaletteEncoder;
    function Rules(const AChars: string): TArray<TXcomFontRule>;
    function Generate(const ARules: TArray<TXcomFontRule>): Integer;
    function WrittenRules: TArray<TXcomFontRule>;
  public
    const
      FOLDER = 'out';
      LANGUAGE = 'out\Language\';
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereUnImmagineEIlFontDat;
    [Test]
    procedure DovrebbeElencarePrimaLeImmaginiOriginaliPoiQuelleNuove;
    [Test]
    procedure DovrebbeScrivereICaratteriCheVoglionoLEscape;
    [Test]
    procedure DovrebbeDareLoStessoFontDellaSorgenteInMemoria;
    [Test]
    procedure DovrebbeRiscrivereSoloIlFontDatSeNessunFontCambia;
    [Test]
    procedure DovrebbeScrivereIlMonospazio;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
  end;

implementation

uses
  DelphiDoom.Zlib.Provider, DelphiDoom.Png.PaletteEncoder, DelphiDoom.XcomEngine.RasterFontOverlay;

const
  FONT_ID = 'FONT_T';
  ORIGINAL_FILE = 'Original.png';

procedure TTestXcomFontGridGenerator.Setup;
begin
  FFiles := TFakeFileSystem.Create;
  FFilesRef := FFiles;
  FRasterizer := TFakeGlyphRasterizer.Create(3, 5, 2);
  FFactory := TFakeGlyphRasterizerFactory.Create;
  FFactoryRef := FFactory;
  FFactory.Rasterizer := FRasterizer;
  FOverlay := TXcomRasterFontOverlay.Create([TXcomFontOverlaySettings.Make(FONT_ID, 'Fake', 8)], FFactoryRef, nil);
  FEncoder := TPngPaletteEncoder.Create(TZlibProvider.Client);
end;

procedure TTestXcomFontGridGenerator.TearDown;
begin
  FEncoder := nil;
  FOverlay := nil;
  FFactoryRef := nil;
  FFilesRef := nil;
end;

function TTestXcomFontGridGenerator.Rules(const AChars: string): TArray<TXcomFontRule>;
begin
  SetLength(Result, 1);
  Result[0].Id := FONT_ID;
  Result[0].Width := TFontFixtures.CELL_WIDTH;
  Result[0].Height := TFontFixtures.CELL_HEIGHT;
  Result[0].Spacing := 1;
  Result[0].Definition.Monospace := False;
  SetLength(Result[0].Definition.Images, 1);
  Result[0].Definition.Images[0].Width := TFontFixtures.CELL_WIDTH;
  Result[0].Definition.Images[0].Height := TFontFixtures.CELL_HEIGHT;
  Result[0].Definition.Images[0].Spacing := 1;
  Result[0].Definition.Images[0].FileName := ORIGINAL_FILE;
  Result[0].Definition.Images[0].Chars := AChars;
end;

function TTestXcomFontGridGenerator.Generate(const ARules: TArray<TXcomFontRule>): Integer;
var
  LGenerator: TXcomFontGridGenerator;
begin
  // the original pictures are the ones of the fixtures (12 cells: enough for every test)
  LGenerator := TXcomFontGridGenerator.Create(FFilesRef, TFontTestLoader.Create(nil, '', nil, 12), FOverlay,
    FEncoder);
  try
    Result := LGenerator.Generate(ARules, FOLDER);
  finally
    LGenerator.Free;
  end;
end;

function TTestXcomFontGridGenerator.WrittenRules: TArray<TXcomFontRule>;
begin
  Result := TXcomFontRuleReader.Read(TYamlFactory.CreateParser.Load(FFiles.ReadAll(LANGUAGE + 'Font.dat')));
end;

procedure TTestXcomFontGridGenerator.DovrebbeScrivereUnImmagineEIlFontDat;
begin
  Assert.AreEqual(1, Generate(Rules('AB?')));
  Assert.IsTrue(FFiles.FileExists(LANGUAGE + 'Font.dat'));
  Assert.IsTrue(FFiles.FileExists(LANGUAGE + 'FONT_T_0.png'));
  Assert.AreEqual('FONT_T_0.png', TXcomFontGridGenerator.FileNameOf(FONT_ID, 0));
  // the picture is an indexed PNG: 16 cells of 3 x 5 in a row
  Assert.AreEqual(48, Integer(TPngProvider.Client.DecodeIndexed(FFiles.ReadAll(LANGUAGE + 'FONT_T_0.png')).Info.Width));
  Assert.AreEqual(5, Integer(TPngProvider.Client.DecodeIndexed(FFiles.ReadAll(LANGUAGE + 'FONT_T_0.png')).Info.Height));
end;

procedure TTestXcomFontGridGenerator.DovrebbeElencarePrimaLeImmaginiOriginaliPoiQuelleNuove;
var
  LRules: TArray<TXcomFontRule>;
begin
  Generate(Rules('BA?'));
  LRules := WrittenRules;
  Assert.AreEqual(1, Integer(Length(LRules)));
  Assert.AreEqual(FONT_ID, LRules[0].Id);
  // the font keeps the cell and the spacing of the original: the line height and the space come from them
  Assert.AreEqual(TFontFixtures.CELL_WIDTH, LRules[0].Width);
  Assert.AreEqual(TFontFixtures.CELL_HEIGHT, LRules[0].Height);
  Assert.AreEqual(1, LRules[0].Spacing);
  Assert.AreEqual(2, Integer(Length(LRules[0].Definition.Images)));
  Assert.AreEqual(ORIGINAL_FILE, LRules[0].Definition.Images[0].FileName);
  Assert.AreEqual('BA?', LRules[0].Definition.Images[0].Chars);
  Assert.AreEqual(TFontFixtures.CELL_WIDTH, LRules[0].Definition.Images[0].Width);
  Assert.AreEqual('FONT_T_0.png', LRules[0].Definition.Images[1].FileName);
  // the new picture has its own cell, and its characters in the order of the cells
  Assert.AreEqual(3, LRules[0].Definition.Images[1].Width);
  Assert.AreEqual(5, LRules[0].Definition.Images[1].Height);
  Assert.AreEqual(1, LRules[0].Definition.Images[1].Spacing);
  Assert.AreEqual('?AB', LRules[0].Definition.Images[1].Chars);
end;

procedure TTestXcomFontGridGenerator.DovrebbeScrivereICaratteriCheVoglionoLEscape;
var
  LRules: TArray<TXcomFontRule>;
  LChars: string;
begin
  // a quote, a backslash, a hash, a character outside the basic plane and the line feed of a folded scalar
  LChars := 'A"\#: ' + Char($D83D) + Char($DE00) + #10;
  Generate(Rules(LChars));
  LRules := WrittenRules;
  Assert.AreEqual(LChars, LRules[0].Definition.Images[0].Chars);
  // the space and the line feed are not characters to draw
  Assert.AreEqual('"#:A\' + Char($D83D) + Char($DE00), LRules[0].Definition.Images[1].Chars);
end;

procedure TTestXcomFontGridGenerator.DovrebbeDareLoStessoFontDellaSorgenteInMemoria;
var
  LMemory: TXcomFont;
  LLoaded: TXcomFont;
  LRules: TArray<TXcomFontRule>;
  LCode: Cardinal;
  LFirst: TXcomFontChar;
  LSecond: TXcomFontChar;
  LOriginals: IXcomSurfaceLoader;
  LFromFolder: IXcomSurfaceLoader;
  LX: Integer;
  LY: Integer;
begin
  LRules := Rules('AB?' + Char($C9) + 'g');
  FRasterizer.Define(Ord('g'), 2, 6, 3);
  FRasterizer.DefineRows($C9, 0, ['959', '000', '999', '900', '990', '900', '999']);
  FRasterizer.Remove(Ord('B'));
  Generate(LRules);
  LMemory := TXcomFont.Create;
  LLoaded := TXcomFont.Create;
  try
    // a loader passed as it is created to a const parameter would never be freed
    LOriginals := TFontTestLoader.Create(nil, '', nil, 12);
    LMemory.Load(LRules[0].Definition, LOriginals);
    FOverlay.Apply(FONT_ID, LMemory);
    // the folder as a mod: its Font.dat, the new picture from the folder and the original from the fixtures
    LFromFolder := TFontTestLoader.Create(FFilesRef, LANGUAGE, TPngProvider.Client, 12);
    LLoaded.Load(WrittenRules[0].Definition, LFromFolder);
    Assert.AreEqual(LMemory.ImageCount, LLoaded.ImageCount);
    Assert.AreEqual(LMemory.Height, LLoaded.Height);
    Assert.AreEqual(LMemory.Spacing, LLoaded.Spacing);
    for LCode in TXcomFont.CodePoints('AB?' + Char($C9) + 'g') do
    begin
      Assert.IsTrue(LMemory.TryGetChar(LCode, LFirst));
      Assert.IsTrue(LLoaded.TryGetChar(LCode, LSecond));
      Assert.AreEqual(LFirst.ImageIndex, LSecond.ImageIndex, Format('picture of %d', [LCode]));
      Assert.AreEqual(Integer(LFirst.Rect.X), Integer(LSecond.Rect.X), Format('x of %d', [LCode]));
      Assert.AreEqual(Integer(LFirst.Rect.Y), Integer(LSecond.Rect.Y), Format('y of %d', [LCode]));
      Assert.AreEqual(Integer(LFirst.Rect.W), Integer(LSecond.Rect.W), Format('width of %d', [LCode]));
      Assert.AreEqual(Integer(LFirst.Rect.H), Integer(LSecond.Rect.H), Format('height of %d', [LCode]));
      Assert.AreEqual(Integer(LMemory.GetCharSize(LCode).W), Integer(LLoaded.GetCharSize(LCode).W));
      for LY := 0 to LFirst.Rect.H - 1 do
        for LX := 0 to LFirst.Rect.W - 1 do
          Assert.AreEqual(
            Integer(LMemory.ImageSurface(LFirst.ImageIndex).GetPixel(LFirst.Rect.X + LX, LFirst.Rect.Y + LY)),
            Integer(LLoaded.ImageSurface(LSecond.ImageIndex).GetPixel(LSecond.Rect.X + LX, LSecond.Rect.Y + LY)),
            Format('pixel %d,%d of %d', [LX, LY, LCode]));
    end;
    // the character the second source does not have is the original one in both
    Assert.IsTrue(LLoaded.TryGetChar(Ord('B'), LSecond));
    Assert.AreEqual(0, LSecond.ImageIndex);
  finally
    LMemory.Free;
    LLoaded.Free;
  end;
end;

procedure TTestXcomFontGridGenerator.DovrebbeRiscrivereSoloIlFontDatSeNessunFontCambia;
var
  LRules: TArray<TXcomFontRule>;
begin
  LRules := Rules('AB?');
  // not the font of the options
  LRules[0].Id := 'FONT_OTHER';
  Assert.AreEqual(0, Generate(LRules));
  Assert.IsFalse(FFiles.FileExists(LANGUAGE + 'FONT_OTHER_0.png'));
  LRules := WrittenRules;
  Assert.AreEqual('FONT_OTHER', LRules[0].Id);
  Assert.AreEqual(1, Integer(Length(LRules[0].Definition.Images)));
  Assert.AreEqual('AB?', LRules[0].Definition.Images[0].Chars);
end;

procedure TTestXcomFontGridGenerator.DovrebbeScrivereIlMonospazio;
var
  LRules: TArray<TXcomFontRule>;
begin
  LRules := Rules('AB?');
  LRules[0].Definition.Monospace := True;
  Generate(LRules);
  Assert.IsTrue(WrittenRules[0].Definition.Monospace);
end;

procedure TTestXcomFontGridGenerator.DovrebbeRifiutareLeDipendenzeNil;
var
  LLoader: IXcomSurfaceLoader;
begin
  LLoader := TFontTestLoader.Create(nil, '', nil, 4);
  Assert.WillRaise(
    procedure
    begin
      TXcomFontGridGenerator.Create(nil, LLoader, FOverlay, FEncoder);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TXcomFontGridGenerator.Create(FFilesRef, nil, FOverlay, FEncoder);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TXcomFontGridGenerator.Create(FFilesRef, LLoader, nil, FEncoder);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TXcomFontGridGenerator.Create(FFilesRef, LLoader, FOverlay, nil);
    end, EArgumentNilException);
end;

end.

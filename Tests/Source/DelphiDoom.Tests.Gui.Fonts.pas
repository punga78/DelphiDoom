{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - fonts                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Fonts;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Gui.Font, DelphiDoom.Tests.Gui.Fakes;

type
  [TestFixture]
  [Category('gui')]
  TTestGuiFont = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereLeDimensioniDelFormatoSuDisco;
    [Test]
    procedure DovrebbeNascereDiZeri;
    [Test]
    procedure DovrebbeDareIlNomeDelloShaderFinoAlloZero;
    [Test]
    procedure DovrebbeDareIlNomeDelloShaderDi32CaratteriSenzaZero;
    [Test]
    procedure DovrebbeCopiareUnAltroFont;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiFontReader = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereIValoriInLittleEndian;
    [Test]
    procedure DovrebbeLeggereLaScalaEIlNome;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaSbagliata;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiFontRegistry = class(TObject)
  private
    FWorld: TGuiWorld;
    FFont: TGuiFont;
    procedure AddFontFile(const APointSize: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRegistrareUnFontEIlNomeDelFile;
    [Test]
    procedure DovrebbeRegistrareGliShaderDeiGlifiDa0A254;
    [Test]
    procedure DovrebbeUsareIlFontGiaRegistratoSenzaRileggere;
    [Test]
    procedure DovrebbeUsare12SeLaGrandezzaNonEPositiva;
    [Test]
    procedure DovrebbeRifiutareUnFileDiLunghezzaSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnFileMancante;
    [Test]
    procedure DovrebbeRifiutareIlSettimoFont;
    [Test]
    procedure DovrebbeDimenticareIFontConClear;
    [Test]
    procedure DovrebbeSegnalareSenzaLogSenzaErrori;
  end;

implementation

uses
  DelphiDoom.Gui.Types, DelphiDoom.Gui.Font.Types, DelphiDoom.Gui.FontReader, DelphiDoom.Gui.FontRegistry;

function MakeFontBytes(const AGlyphHandleBase: Integer): TBytes;
var
  LIndex: Integer;
  LOffset: Integer;
  LName: AnsiString;
  LScale: Single;
begin
  SetLength(Result, GUI_FONT_FILE_SIZE);
  FillChar(Result[0], Length(Result), 0);
  for LIndex := 0 to GUI_GLYPHS_PER_FONT - 1 do
  begin
    LOffset := LIndex * GUI_GLYPH_FILE_SIZE;
    // height 1 + index, top = $01020304 (bytes 04 03 02 01), glyph handle
    PInteger(@Result[LOffset])^ := 1 + LIndex;
    PInteger(@Result[LOffset + 4])^ := $01020304;
    PInteger(@Result[LOffset + 44])^ := AGlyphHandleBase + LIndex;
    LName := AnsiString('gfx/g') + AnsiString(IntToStr(LIndex));
    Move(LName[1], Result[LOffset + 48], Length(LName));
  end;
  LScale := 0.75;
  Move(LScale, Result[GUI_GLYPHS_PER_FONT * GUI_GLYPH_FILE_SIZE], SizeOf(LScale));
  LName := 'stored/name';
  Move(LName[1], Result[GUI_GLYPHS_PER_FONT * GUI_GLYPH_FILE_SIZE + 4], Length(LName));
end;

{ TTestGuiFont }

procedure TTestGuiFont.DovrebbeAvereLeDimensioniDelFormatoSuDisco;
begin
  Assert.AreEqual(80, SizeOf(TGuiGlyph));
  Assert.AreEqual(20480, GUI_GLYPHS_PER_FONT * SizeOf(TGuiGlyph));
  Assert.AreEqual(20548, GUI_FONT_FILE_SIZE);
end;

procedure TTestGuiFont.DovrebbeNascereDiZeri;
var
  LFont: TGuiFont;
begin
  LFont := TGuiFont.Create;
  try
    Assert.AreEqual(0, LFont.Glyphs[200].Height);
    Assert.AreEqual(Single(0), LFont.GlyphScale);
    Assert.AreEqual('', string(LFont.Name));
    Assert.AreEqual('', string(LFont.ShaderName(3)));
  finally
    LFont.Free;
  end;
end;

procedure TTestGuiFont.DovrebbeDareIlNomeDelloShaderFinoAlloZero;
var
  LFont: TGuiFont;
  LGlyph: TGuiGlyph;
begin
  LFont := TGuiFont.Create;
  try
    LGlyph := LFont.Glyphs[1];
    LGlyph.ShaderName[0] := 'a';
    LGlyph.ShaderName[1] := 'b';
    LFont.Glyphs[1] := LGlyph;
    Assert.AreEqual('ab', string(LFont.ShaderName(1)));
  finally
    LFont.Free;
  end;
end;

procedure TTestGuiFont.DovrebbeDareIlNomeDelloShaderDi32CaratteriSenzaZero;
var
  LFont: TGuiFont;
  LGlyph: TGuiGlyph;
  LIndex: Integer;
begin
  LFont := TGuiFont.Create;
  try
    LGlyph := LFont.Glyphs[1];
    for LIndex := 0 to 31 do
      LGlyph.ShaderName[LIndex] := 'x';
    LFont.Glyphs[1] := LGlyph;
    Assert.AreEqual(32, Length(LFont.ShaderName(1)));
  finally
    LFont.Free;
  end;
end;

procedure TTestGuiFont.DovrebbeCopiareUnAltroFont;
var
  LSource: TGuiFont;
  LCopy: TGuiFont;
  LGlyph: TGuiGlyph;
begin
  LSource := TGuiFont.Create;
  LCopy := TGuiFont.Create;
  try
    LGlyph := LSource.Glyphs[5];
    LGlyph.Height := 77;
    LSource.Glyphs[5] := LGlyph;
    LSource.GlyphScale := 2;
    LSource.Name := 'n';
    LCopy.Assign(LSource);
    Assert.AreEqual(77, LCopy.Glyphs[5].Height);
    Assert.AreEqual(Single(2), LCopy.GlyphScale);
    Assert.AreEqual('n', string(LCopy.Name));
  finally
    LCopy.Free;
    LSource.Free;
  end;
end;

{ TTestGuiFontReader }

procedure TTestGuiFontReader.DovrebbeLeggereIValoriInLittleEndian;
var
  LFont: TGuiFont;
begin
  LFont := TGuiFont.Create;
  try
    TGuiFontReader.Read(MakeFontBytes(1000), LFont);
    Assert.AreEqual(4, LFont.Glyphs[3].Height);
    Assert.AreEqual($01020304, LFont.Glyphs[3].Top);
    Assert.AreEqual(1003, LFont.Glyphs[3].Glyph);
    Assert.AreEqual('gfx/g3', string(LFont.ShaderName(3)));
  finally
    LFont.Free;
  end;
end;

procedure TTestGuiFontReader.DovrebbeLeggereLaScalaEIlNome;
var
  LFont: TGuiFont;
begin
  LFont := TGuiFont.Create;
  try
    TGuiFontReader.Read(MakeFontBytes(0), LFont);
    Assert.AreEqual(Single(0.75), LFont.GlyphScale);
    Assert.AreEqual('stored/name', string(LFont.Name));
  finally
    LFont.Free;
  end;
end;

procedure TTestGuiFontReader.DovrebbeRifiutareUnaLunghezzaSbagliata;
var
  LFont: TGuiFont;
  LBytes: TBytes;
begin
  LFont := TGuiFont.Create;
  try
    SetLength(LBytes, 20480);
    Assert.WillRaise(
      procedure
      begin
        TGuiFontReader.Read(LBytes, LFont);
      end, EGuiFontException);
  finally
    LFont.Free;
  end;
end;

{ TTestGuiFontRegistry }

procedure TTestGuiFontRegistry.Setup;
begin
  FWorld := TGuiWorld.Create;
  FFont := TGuiFont.Create;
end;

procedure TTestGuiFontRegistry.TearDown;
begin
  FFont.Free;
  FWorld.Free;
end;

procedure TTestGuiFontRegistry.AddFontFile(const APointSize: Integer);
begin
  FWorld.Files.Add(AnsiString(Format('fonts/fontImage_%d.dat', [APointSize])), MakeFontBytes(5000));
end;

procedure TTestGuiFontRegistry.DovrebbeRegistrareUnFontEIlNomeDelFile;
begin
  AddFontFile(16);
  Assert.IsTrue(FWorld.Fonts.Register('whatever.ttf', 16, FFont));
  Assert.AreEqual('fonts/fontImage_16.dat', string(FFont.Name));
  Assert.AreEqual(Single(0.75), FFont.GlyphScale);
  Assert.AreEqual(1, FWorld.Fonts.Count);
end;

procedure TTestGuiFontRegistry.DovrebbeRegistrareGliShaderDeiGlifiDa0A254;
begin
  AddFontFile(16);
  FWorld.Fonts.Register('x', 16, FFont);
  // the handles of the fake registry follow the order of the names: glyph 0 is the first one
  Assert.AreEqual(1, FFont.Glyphs[0].Glyph);
  Assert.AreEqual(255, FFont.Glyphs[254].Glyph);
  // glyph 255 keeps the handle that the file has
  Assert.AreEqual(5255, FFont.Glyphs[255].Glyph);
  Assert.AreEqual(255, FWorld.Transcript.Count);
end;

procedure TTestGuiFontRegistry.DovrebbeUsareIlFontGiaRegistratoSenzaRileggere;
var
  LSecond: TGuiFont;
begin
  AddFontFile(16);
  FWorld.Fonts.Register('x', 16, FFont);
  FWorld.Transcript.Clear;
  LSecond := TGuiFont.Create;
  try
    Assert.IsTrue(FWorld.Fonts.Register('y', 16, LSecond));
    Assert.AreEqual(FFont.Glyphs[70].Glyph, LSecond.Glyphs[70].Glyph);
    Assert.AreEqual(0, FWorld.Transcript.Count);
    Assert.AreEqual(1, FWorld.Fonts.Count);
  finally
    LSecond.Free;
  end;
end;

procedure TTestGuiFontRegistry.DovrebbeUsare12SeLaGrandezzaNonEPositiva;
begin
  AddFontFile(12);
  Assert.IsTrue(FWorld.Fonts.Register('x', 0, FFont));
  Assert.AreEqual('fonts/fontImage_12.dat', string(FFont.Name));
  Assert.IsTrue(FWorld.Fonts.Register('x', -9, FFont));
  Assert.AreEqual(1, FWorld.Fonts.Count);
end;

procedure TTestGuiFontRegistry.DovrebbeRifiutareUnFileDiLunghezzaSbagliata;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 100);
  FWorld.Files.Add('fonts/fontImage_24.dat', LBytes);
  FFont.Name := 'untouched';
  Assert.IsFalse(FWorld.Fonts.Register('x', 24, FFont));
  Assert.AreEqual('untouched', string(FFont.Name));
  Assert.AreEqual('log RE_RegisterFont: FreeType code not available', FWorld.Transcript[0]);
end;

procedure TTestGuiFontRegistry.DovrebbeRifiutareUnFileMancante;
begin
  Assert.IsFalse(FWorld.Fonts.Register('x', 33, FFont));
  Assert.AreEqual(0, FWorld.Fonts.Count);
end;

procedure TTestGuiFontRegistry.DovrebbeRifiutareIlSettimoFont;
var
  LSize: Integer;
begin
  for LSize := 1 to 7 do
    AddFontFile(LSize);
  for LSize := 1 to 6 do
    Assert.IsTrue(FWorld.Fonts.Register('x', LSize, FFont));
  FWorld.Transcript.Clear;
  Assert.IsFalse(FWorld.Fonts.Register('x', 7, FFont));
  Assert.AreEqual('log RE_RegisterFont: Too many fonts registered already.', FWorld.Transcript[0]);
  // a font that is there is still found
  Assert.IsFalse(FWorld.Fonts.Register('x', 7, FFont));
end;

procedure TTestGuiFontRegistry.DovrebbeDimenticareIFontConClear;
begin
  AddFontFile(16);
  FWorld.Fonts.Register('x', 16, FFont);
  FWorld.Fonts.Clear;
  Assert.AreEqual(0, FWorld.Fonts.Count);
end;

procedure TTestGuiFontRegistry.DovrebbeSegnalareSenzaLogSenzaErrori;
var
  LRegistry: TGuiFontRegistry;
begin
  LRegistry := TGuiFontRegistry.Create(nil, nil, nil);
  try
    Assert.IsFalse(LRegistry.Register('x', 16, FFont));
  finally
    LRegistry.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiFont);
  TDUnitX.RegisterTestFixture(TTestGuiFontReader);
  TDUnitX.RegisterTestFixture(TTestGuiFontRegistry);

end.

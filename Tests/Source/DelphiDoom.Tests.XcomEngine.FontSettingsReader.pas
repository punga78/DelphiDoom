{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomFontSettingsReader (fonts.cfg) and of         }
{  TXcomFontRuleReader (Font.dat)                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.FontSettingsReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomEngine.FontSettingsReader, DelphiDoom.XcomEngine.FontRuleReader,
  DelphiDoom.Tests.XcomEngine.FontFakes;

type
  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomFontSettingsReader = class
  strict private
    FLog: TFontTestLog;
    FLogRef: IXcomLog;
    function Document(const AText: string): IYamlNode;
    function Read(const AText: string): TArray<TXcomFontOverlaySettings>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereTutteLeOpzioniDiUnFont;
    [Test]
    procedure DovrebbeDareIPredefinitiAlleOpzioniNonScritte;
    [Test]
    procedure DovrebbeAccettareUnFileSenzaNome;
    [Test]
    procedure DovrebbeLeggereLaTolleranzaScrittaELaRiduzione;
    [Test]
    procedure DovrebbeLeggereIlContornoSpento;
    [Test]
    procedure DovrebbeLeggerePiuFontNellOrdineDelFile;
    [Test]
    [TestCase('senza id', 'name: Tahoma|size: 8,no id')]
    [TestCase('senza nome ne'' file', 'id: FONT_BIG|size: 8,neither name nor file')]
    [TestCase('senza dimensione', 'id: FONT_BIG|name: Tahoma,no size')]
    [TestCase('dimensione zero', 'id: FONT_BIG|name: Tahoma|size: 0,no size')]
    procedure DovrebbeSaltareConUnAvvisoUnaVoceInutilizzabile(const AFields, AReason: string);
    [Test]
    procedure DovrebbeDareUnElencoVuotoSenzaLaChiaveFonts;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomFontRuleReader = class
  strict private
    function Read(const AText: string): TArray<TXcomFontRule>;
  public
    [Test]
    procedure DovrebbeLeggereIFontNellOrdineDelFile;
    [Test]
    procedure DovrebbeDareAUnImmagineLeMisureDelFontSeNonHaLeSue;
    [Test]
    procedure DovrebbeLeggereIlMonospazio;
    [Test]
    procedure DovrebbeDareUnElencoVuotoSenzaFont;
  end;

implementation

{ TTestXcomFontSettingsReader }

procedure TTestXcomFontSettingsReader.Setup;
begin
  FLog := TFontTestLog.Create;
  FLogRef := FLog;
end;

procedure TTestXcomFontSettingsReader.TearDown;
begin
  FLogRef := nil;
end;

function TTestXcomFontSettingsReader.Document(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(AText));
end;

function TTestXcomFontSettingsReader.Read(const AText: string): TArray<TXcomFontOverlaySettings>;
begin
  Result := TXcomFontSettingsReader.Read(Document(AText), FLogRef);
end;

procedure TTestXcomFontSettingsReader.DovrebbeLeggereTutteLeOpzioniDiUnFont;
var
  LFonts: TArray<TXcomFontOverlaySettings>;
begin
  LFonts := Read(
    'fonts:'#10 +
    '  - id: FONT_SMALL'#10 +
    '    name: Tahoma'#10 +
    '    file: C:\fonts\my.ttf'#10 +
    '    size: 8'#10 +
    '    bold: true'#10 +
    '    antialias: false'#10 +
    '    outline: true'#10 +
    '    spacing: -1'#10 +
    '    tolerance: 40'#10 +
    '    offsetY: 2'#10);
  Assert.AreEqual(1, Integer(Length(LFonts)));
  Assert.AreEqual('FONT_SMALL', LFonts[0].FontId);
  Assert.AreEqual('Tahoma', LFonts[0].Face.Name);
  Assert.AreEqual('C:\fonts\my.ttf', LFonts[0].Face.FileName);
  Assert.AreEqual(8, LFonts[0].Face.Size);
  Assert.IsTrue(LFonts[0].Face.Bold);
  Assert.IsFalse(LFonts[0].Face.Antialias);
  Assert.AreEqual(Ord(goOn), Ord(LFonts[0].Outline));
  Assert.IsTrue(LFonts[0].HasSpacing);
  Assert.AreEqual(-1, LFonts[0].Spacing);
  Assert.AreEqual(40, LFonts[0].Tolerance);
  Assert.AreEqual(2, LFonts[0].OffsetY);
  Assert.AreEqual(0, FLog.Lines.Count);
end;

procedure TTestXcomFontSettingsReader.DovrebbeDareIPredefinitiAlleOpzioniNonScritte;
var
  LFonts: TArray<TXcomFontOverlaySettings>;
begin
  LFonts := Read('fonts:'#10'  - id: FONT_BIG'#10'    name: Consolas'#10'    size: 13'#10);
  Assert.AreEqual(1, Integer(Length(LFonts)));
  Assert.AreEqual('', LFonts[0].Face.FileName);
  Assert.IsFalse(LFonts[0].Face.Bold);
  Assert.IsTrue(LFonts[0].Face.Antialias);
  Assert.AreEqual(Ord(goAuto), Ord(LFonts[0].Outline));
  Assert.IsFalse(LFonts[0].HasSpacing);
  Assert.AreEqual(XCOM_FONT_AUTO_TOLERANCE, LFonts[0].Tolerance);
  Assert.IsFalse(LFonts[0].Shrink);
  Assert.AreEqual(0, LFonts[0].OffsetY);
end;

procedure TTestXcomFontSettingsReader.DovrebbeLeggereLaTolleranzaScrittaELaRiduzione;
var
  LFonts: TArray<TXcomFontOverlaySettings>;
begin
  LFonts := Read('fonts:'#10'  - id: FONT_BIG'#10'    name: Consolas'#10'    size: 13'#10'    tolerance: 0'#10 +
    '    shrink: true'#10'  - id: FONT_SMALL'#10'    name: Consolas'#10'    size: 9'#10'    tolerance: -30'#10);
  Assert.AreEqual(2, Integer(Length(LFonts)));
  // a tolerance that is written is a percent, also 0; a negative one is 0, not the default
  Assert.AreEqual(0, LFonts[0].Tolerance);
  Assert.IsTrue(LFonts[0].Shrink);
  Assert.AreEqual(0, LFonts[1].Tolerance);
  Assert.IsFalse(LFonts[1].Shrink);
end;

procedure TTestXcomFontSettingsReader.DovrebbeAccettareUnFileSenzaNome;
var
  LFonts: TArray<TXcomFontOverlaySettings>;
begin
  LFonts := Read('fonts:'#10'  - id: FONT_BIG'#10'    file: my.ttf'#10'    size: 13'#10);
  Assert.AreEqual(1, Integer(Length(LFonts)));
  Assert.AreEqual('', LFonts[0].Face.Name);
  Assert.AreEqual('my.ttf', LFonts[0].Face.FileName);
end;

procedure TTestXcomFontSettingsReader.DovrebbeLeggereIlContornoSpento;
var
  LFonts: TArray<TXcomFontOverlaySettings>;
begin
  LFonts := Read('fonts:'#10'  - id: FONT_BIG'#10'    name: Tahoma'#10'    size: 13'#10'    outline: false'#10);
  Assert.AreEqual(Ord(goOff), Ord(LFonts[0].Outline));
end;

procedure TTestXcomFontSettingsReader.DovrebbeLeggerePiuFontNellOrdineDelFile;
var
  LFonts: TArray<TXcomFontOverlaySettings>;
begin
  LFonts := Read(
    'fonts:'#10 +
    '  - id: FONT_GEO_BIG'#10'    name: Tahoma'#10'    size: 8'#10 +
    '  - id: FONT_BIG'#10'    name: Consolas'#10'    size: 14'#10);
  Assert.AreEqual(2, Integer(Length(LFonts)));
  Assert.AreEqual('FONT_GEO_BIG', LFonts[0].FontId);
  Assert.AreEqual('FONT_BIG', LFonts[1].FontId);
  Assert.AreEqual(14, LFonts[1].Face.Size);
end;

procedure TTestXcomFontSettingsReader.DovrebbeSaltareConUnAvvisoUnaVoceInutilizzabile(const AFields,
  AReason: string);
var
  LFonts: TArray<TXcomFontOverlaySettings>;
begin
  // the entry that cannot be used, then a good one
  LFonts := Read('fonts:'#10'  - ' + AFields.Replace('|', #10'    ') + #10 +
    '  - id: FONT_SMALL'#10'    name: Tahoma'#10'    size: 8'#10);
  Assert.AreEqual(1, Integer(Length(LFonts)));
  Assert.AreEqual('FONT_SMALL', LFonts[0].FontId);
  Assert.AreEqual(1, FLog.Count('WARN', 'entry 1 skipped (' + AReason + ')'));
end;

procedure TTestXcomFontSettingsReader.DovrebbeDareUnElencoVuotoSenzaLaChiaveFonts;
begin
  Assert.AreEqual(0, Integer(Length(Read('options:'#10'  language: en-US'#10))));
  Assert.AreEqual(0, Integer(Length(TXcomFontSettingsReader.Read(nil, FLogRef))));
  Assert.AreEqual(0, FLog.Lines.Count);
end;

procedure TTestXcomFontSettingsReader.DovrebbeFunzionareSenzaLog;
begin
  Assert.AreEqual(0, Integer(Length(TXcomFontSettingsReader.Read(Document('fonts:'#10'  - size: 8'#10)))));
end;

{ TTestXcomFontRuleReader }

function TTestXcomFontRuleReader.Read(const AText: string): TArray<TXcomFontRule>;
begin
  Result := TXcomFontRuleReader.Read(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(AText)));
end;

procedure TTestXcomFontRuleReader.DovrebbeLeggereIFontNellOrdineDelFile;
var
  LRules: TArray<TXcomFontRule>;
begin
  LRules := Read(
    'fonts:'#10 +
    '  - id: FONT_BIG'#10'    width: 16'#10'    height: 16'#10'    spacing: 0'#10'    images:'#10 +
    '      - file: FontBig.png'#10'        chars: "AB"'#10 +
    '  - id: FONT_SMALL'#10'    width: 8'#10'    height: 9'#10'    spacing: -1'#10'    images:'#10 +
    '      - file: FontSmall.png'#10'        chars: "xyz"'#10);
  Assert.AreEqual(2, Integer(Length(LRules)));
  Assert.AreEqual('FONT_BIG', LRules[0].Id);
  Assert.AreEqual('FONT_SMALL', LRules[1].Id);
  Assert.AreEqual(8, LRules[1].Width);
  Assert.AreEqual(9, LRules[1].Height);
  Assert.AreEqual(-1, LRules[1].Spacing);
  Assert.AreEqual('FontSmall.png', LRules[1].Definition.Images[0].FileName);
  Assert.AreEqual('xyz', LRules[1].Definition.Images[0].Chars);
  Assert.IsFalse(LRules[1].Definition.Monospace);
end;

procedure TTestXcomFontRuleReader.DovrebbeDareAUnImmagineLeMisureDelFontSeNonHaLeSue;
var
  LRules: TArray<TXcomFontRule>;
begin
  LRules := Read(
    'fonts:'#10 +
    '  - id: FONT_SMALL'#10'    width: 8'#10'    height: 9'#10'    spacing: -1'#10'    images:'#10 +
    '      - file: A.png'#10'        chars: "A"'#10 +
    '      - file: B.png'#10'        width: 10'#10'        spacing: 0'#10'        chars: "B"'#10);
  Assert.AreEqual(2, Integer(Length(LRules[0].Definition.Images)));
  Assert.AreEqual(8, LRules[0].Definition.Images[0].Width);
  Assert.AreEqual(-1, LRules[0].Definition.Images[0].Spacing);
  Assert.AreEqual(10, LRules[0].Definition.Images[1].Width);
  Assert.AreEqual(9, LRules[0].Definition.Images[1].Height);
  Assert.AreEqual(0, LRules[0].Definition.Images[1].Spacing);
end;

procedure TTestXcomFontRuleReader.DovrebbeLeggereIlMonospazio;
var
  LRules: TArray<TXcomFontRule>;
begin
  LRules := Read('fonts:'#10'  - id: FONT_T'#10'    monospace: true'#10'    images: []'#10);
  Assert.IsTrue(LRules[0].Definition.Monospace);
  Assert.AreEqual(0, Integer(Length(LRules[0].Definition.Images)));
end;

procedure TTestXcomFontRuleReader.DovrebbeDareUnElencoVuotoSenzaFont;
begin
  Assert.AreEqual(0, Integer(Length(Read('other: 1'#10))));
  Assert.AreEqual(0, Integer(Length(TXcomFontRuleReader.Read(nil))));
end;

end.

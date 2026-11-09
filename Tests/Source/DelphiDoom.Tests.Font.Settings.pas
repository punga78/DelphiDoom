{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFontSettings and TFontSettingsFormat (issue #167)      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.Settings;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.SettingsFormat;

type
  /// <summary>
  ///   The text of the settings is the one that TFontEngine.SaveToStream of the old DD_FONT wrote and read (golden
  ///   file made by the old code: fingerprints of what it wrote, the fields that it read)
  /// </summary>
  [TestFixture]
  [Category('font')]
  TTestFontSettings = class(TObject)
  strict private
    function Fields(const ASettings: TFontSettings): string;
    function TextBytes(const AText: string): TBytes;
  public
    [Test]
    procedure DovrebbeAvereLeImpostazioniDiUnNuovoProgetto;
    [Test]
    procedure DovrebbeAccendereESpegnereGliStili;
    [Test]
    procedure DovrebbeSeparareIColoriDiWindows;
    [Test]
    procedure DovrebbeConfrontareLeImpostazioni;
    [Test]
    procedure DovrebbeScrivereLoStessoTestoDelVecchio;
    [Test]
    procedure DovrebbeScrivereLeDodiciRigheNellOrdineDelVecchio;
    [Test]
    procedure DovrebbeLeggereCometoLeggevaIlVecchio;
    [Test]
    procedure DovrebbeRileggereCioCheHaScritto;
    [Test]
    procedure DovrebbeScrivereIColoriSenzaSegno;
    [Test]
    procedure DovrebbeLasciareLeImpostazioniChePartivanoSeIlTestoEVuoto;
    [Test]
    procedure DovrebbeIgnorareUnaPassoFuoriIntervallo;
    [Test]
    procedure DovrebbeLimitareLoStileAiQuattroBit;
    [Test]
    procedure DovrebbeLeggereUnFileUtf8ConIndicatoreDiCodifica;
  end;

implementation

uses
  DelphiDoom.Tests.Font.Golden,
  DelphiDoom.Tests.Font.Fakes,
  DelphiDoom.Tests.Font.Scenarios;

const
  GOLDEN_FILE = 'Font\font.golden.txt';

{ TTestFontSettings }

function TTestFontSettings.Fields(const ASettings: TFontSettings): string;
begin
  Result := Format('%d|%d|%d|%d|%s|%d|%d|%d|%d|%d|%d|%d', [ASettings.Height, Ord(ASettings.Pitch),
    ASettings.Style, ASettings.Charset, ASettings.FontName, ASettings.DrawWidth, ASettings.DrawHeight,
    ASettings.FontSize, ASettings.FrontColor, ASettings.BackColor, ASettings.GridWidth, ASettings.GridHeight]);
end;

function TTestFontSettings.TextBytes(const AText: string): TBytes;
begin
  Result := TEncoding.ANSI.GetBytes(AText);
end;

procedure TTestFontSettings.DovrebbeAvereLeImpostazioniDiUnNuovoProgetto;
var
  LSettings: TFontSettings;
begin
  LSettings := TFontSettings.Initial;
  Assert.AreEqual('Doom', LSettings.FontName);
  Assert.AreEqual(8, LSettings.FontSize);
  Assert.AreEqual(-11, LSettings.Height);
  Assert.AreEqual(16, LSettings.DrawWidth);
  Assert.AreEqual(16, LSettings.DrawHeight);
  Assert.AreEqual(16, LSettings.GridWidth);
  Assert.AreEqual(16, LSettings.GridHeight);
  Assert.AreEqual($FFFFFF, LSettings.FrontColor);
  Assert.AreEqual(0, LSettings.BackColor);
  Assert.AreEqual(Ord(fpmDefault), Ord(LSettings.Pitch));
  Assert.AreEqual(1, LSettings.Charset, 'DEFAULT_CHARSET');
  Assert.AreEqual(0, LSettings.Style);
end;

procedure TTestFontSettings.DovrebbeAccendereESpegnereGliStili;
var
  LSettings: TFontSettings;
begin
  LSettings := TFontSettings.Initial.WithStyle(FONT_STYLE_BOLD, True).WithStyle(FONT_STYLE_STRIKEOUT, True);
  Assert.IsTrue(LSettings.IsBold);
  Assert.IsFalse(LSettings.IsItalic);
  Assert.IsFalse(LSettings.IsUnderline);
  Assert.IsTrue(LSettings.IsStrikeOut);
  Assert.AreEqual(9, LSettings.Style);
  LSettings := LSettings.WithStyle(FONT_STYLE_BOLD, False);
  Assert.IsFalse(LSettings.IsBold);
  Assert.IsTrue(LSettings.IsStrikeOut);
end;

procedure TTestFontSettings.DovrebbeSeparareIColoriDiWindows;
begin
  // a color of Windows is $00BBGGRR: the red one is the low byte
  Assert.AreEqual(Integer($11), Integer(TFontSettings.RedOf($332211)));
  Assert.AreEqual(Integer($22), Integer(TFontSettings.GreenOf($332211)));
  Assert.AreEqual(Integer($33), Integer(TFontSettings.BlueOf($332211)));
  Assert.AreEqual(Cardinal($112233), TFontSettings.ToRgb($332211));
end;

procedure TTestFontSettings.DovrebbeConfrontareLeImpostazioni;
var
  LFirst: TFontSettings;
  LSecond: TFontSettings;
begin
  LFirst := TFontSettings.Initial;
  LSecond := TFontSettings.Initial;
  Assert.IsTrue(LFirst.Equals(LSecond));
  LSecond.FontName := 'Arial';
  Assert.IsFalse(LFirst.Equals(LSecond));
  LSecond := TFontSettings.Initial;
  LSecond.BackColor := 1;
  Assert.IsFalse(LFirst.Equals(LSecond));
end;

procedure TTestFontSettings.DovrebbeScrivereLoStessoTestoDelVecchio;
var
  LLine: string;
  LWords: TArray<string>;
  LIndex: Integer;
  LSettings: TFontSettings;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'SETTINGS') do
  begin
    LWords := TFontGolden.Words(LLine);
    LIndex := StrToInt(LWords[0]);
    if LIndex = 12 then
      LSettings := TFontSettings.Initial
    else
    begin
      LSettings := TFontScenarioBridge.Settings(TFontScenarios.Item(LIndex));
      LSettings.Height := -3 - LIndex;
      LSettings.Pitch := TFontPitchMode(LIndex mod 3);
      LSettings.Charset := LIndex * 20;
      LSettings.FontName := 'Font Number ' + IntToStr(LIndex);
      LSettings.GridWidth := 8 + LIndex;
      LSettings.GridHeight := 4 + LIndex;
    end;
    Assert.AreEqual(LWords[1], TFontDigests.OfBytes(TFontSettingsFormat.Save(LSettings)), 'impostazioni ' + LWords[0]);
    Inc(LCount);
  end;
  Assert.AreEqual(13, LCount);
end;

procedure TTestFontSettings.DovrebbeScrivereLeDodiciRigheNellOrdineDelVecchio;
var
  LText: string;
begin
  LText := TEncoding.ANSI.GetString(TFontSettingsFormat.Save(TFontSettings.Initial));
  Assert.AreEqual('Height=-11'#13#10'Pitch=0'#13#10'Style=0'#13#10'Charset=1'#13#10'FontName=Doom'#13#10 +
    'DrawWidth=16'#13#10'DrawHeight=16'#13#10'FontSize=8'#13#10'FrontColor=16777215'#13#10'BackColor=0'#13#10 +
    'GridWidth=16'#13#10'GridHeight=16'#13#10, LText);
end;

procedure TTestFontSettings.DovrebbeLeggereCometoLeggevaIlVecchio;
var
  LTexts: array[0..7] of string;
  LLine: string;
  LWords: TArray<string>;
  LIndex: Integer;
  LCount: Integer;
begin
  LTexts[0] := 'Height=-20'#13#10'FontName=Arial'#13#10;
  LTexts[1] := 'height=5'#13#10'FONTSIZE=9'#13#10'bold=1'#13#10;
  LTexts[2] := 'Pitch=2'#13#10'Style=15'#13#10'Charset=300'#13#10;
  LTexts[3] := 'Height=abc'#13#10'DrawWidth='#13#10'DrawHeight=7x'#13#10'FrontColor=4294967295'#13#10;
  LTexts[4] := 'FrontColor=-5'#13#10'BackColor=2147483647'#13#10'GridWidth=0'#13#10'GridHeight=99'#13#10;
  LTexts[5] := 'Style=3'#13#10'Style=8'#13#10'FontName=A=B'#13#10;
  LTexts[6] := 'Height = -9'#13#10'  FontSize=11'#13#10;
  LTexts[7] := '';
  LCount := 0;
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'LOAD') do
  begin
    LWords := LLine.Split([' '], 2);
    LIndex := StrToInt(LWords[0]);
    Assert.AreEqual(LWords[1], Fields(TFontSettingsFormat.Load(TextBytes(LTexts[LIndex]), TFontSettings.Initial)),
      'lettura ' + LWords[0]);
    Inc(LCount);
  end;
  Assert.AreEqual(8, LCount);
end;

procedure TTestFontSettings.DovrebbeRileggereCioCheHaScritto;
var
  LSettings: TFontSettings;
  LBack: TFontSettings;
begin
  LSettings := TFontSettings.Initial;
  LSettings.Height := -17;
  LSettings.Pitch := fpmFixed;
  LSettings.Style := 11;
  LSettings.Charset := 238;
  LSettings.FontName := 'Courier New';
  LSettings.DrawWidth := 21;
  LSettings.DrawHeight := 27;
  LSettings.FontSize := 14;
  LSettings.FrontColor := $102030;
  LSettings.BackColor := $FFEEDD;
  LSettings.GridWidth := 12;
  LSettings.GridHeight := 9;
  LBack := TFontSettingsFormat.Load(TFontSettingsFormat.Save(LSettings), TFontSettings.Initial);
  Assert.IsTrue(LSettings.Equals(LBack));
end;

procedure TTestFontSettings.DovrebbeScrivereIColoriSenzaSegno;
var
  LSettings: TFontSettings;
  LText: string;
begin
  LSettings := TFontSettings.Initial;
  LSettings.BackColor := -2147483643;
  LText := TEncoding.ANSI.GetString(TFontSettingsFormat.Save(LSettings));
  Assert.IsTrue(LText.Contains('BackColor=2147483653'#13#10), 'come un LongWord');
end;

procedure TTestFontSettings.DovrebbeLasciareLeImpostazioniChePartivanoSeIlTestoEVuoto;
var
  LStart: TFontSettings;
begin
  LStart := TFontSettings.Initial;
  LStart.FontName := 'Verdana';
  LStart.FontSize := 12;
  Assert.IsTrue(LStart.Equals(TFontSettingsFormat.Load(nil, LStart)));
end;

procedure TTestFontSettings.DovrebbeIgnorareUnaPassoFuoriIntervallo;
var
  LStart: TFontSettings;
  LLoaded: TFontSettings;
begin
  LStart := TFontSettings.Initial;
  LStart.Pitch := fpmVariable;
  // the old code stored any number in the enumeration: here a pitch that does not exist is not taken
  LLoaded := TFontSettingsFormat.Load(TextBytes('Pitch=7'#13#10), LStart);
  Assert.AreEqual(Ord(fpmVariable), Ord(LLoaded.Pitch));
  LLoaded := TFontSettingsFormat.Load(TextBytes('Pitch=-1'#13#10), LStart);
  Assert.AreEqual(Ord(fpmVariable), Ord(LLoaded.Pitch));
end;

procedure TTestFontSettings.DovrebbeLimitareLoStileAiQuattroBit;
var
  LLoaded: TFontSettings;
begin
  LLoaded := TFontSettingsFormat.Load(TextBytes('Style=255'#13#10), TFontSettings.Initial);
  Assert.AreEqual(15, LLoaded.Style);
end;

procedure TTestFontSettings.DovrebbeLeggereUnFileUtf8ConIndicatoreDiCodifica;
var
  LBytes: TBytes;
  LLoaded: TFontSettings;
begin
  // a file saved by another editor with a byte order mark: the first line must not be lost
  LBytes := TEncoding.UTF8.GetPreamble + TEncoding.UTF8.GetBytes('Height=-20'#13#10'FontSize=9'#13#10);
  LLoaded := TFontSettingsFormat.Load(LBytes, TFontSettings.Initial);
  Assert.AreEqual(-20, LLoaded.Height);
  Assert.AreEqual(9, LLoaded.FontSize);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - strings, words and values            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Reading;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf,
  DelphiDoom.Gui.StringPool, DelphiDoom.Gui.ValueReader;

type
  [TestFixture]
  [Category('gui')]
  TTestGuiStringPool = class(TObject)
  private
    FPool: TGuiStringPool;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLaStessaStringaEContareUnaVoltaSola;
    [Test]
    procedure DovrebbeContareLunghezzaPiuUnTerminatore;
    [Test]
    procedure DovrebbeDareVuotoPerLaStringaVuotaSenzaConsumare;
    [Test]
    procedure DovrebbeDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeRifiutareUnaStringaCheNonEntraEDarneVuoto;
    [Test]
    procedure DovrebbeSvuotarsiConClear;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiValueReader = class(TObject)
  private
    FLines: TStringList;
    FLog: IGuiLog;
    FPool: TGuiStringPool;
    FReader: TGuiValueReader;
    procedure Open(const AText: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereUnFloatEUnIntero;
    [Test]
    procedure DovrebbeLeggereUnNumeroNegativoDopoUnMeno;
    [Test]
    procedure DovrebbeLeggereIlMenoDoppioComeUnMenoSolo;
    [Test]
    procedure DovrebbeLasciareLaVariabileSeIlNumeroNonSiLegge;
    [Test]
    procedure DovrebbeSegnalareUnFloatCheNonELo;
    [Test]
    procedure DovrebbeSegnalareUnInteroCheNonELo;
    [Test]
    procedure DovrebbeDareFalsoAlFineDelFile;
    [Test]
    procedure DovrebbeDareFalsoSeDopoIlMenoNonCEnulla;
    [Test]
    procedure DovrebbeLeggereUnColoreMemorizzandoOgniComponente;
    [Test]
    procedure DovrebbeLeggereUnRettangolo;
    [Test]
    procedure DovrebbeLeggereUnaStringaSenzaVirgolette;
    [Test]
    procedure DovrebbeUnireLeStringheAdiacenti;
    [Test]
    procedure DovrebbeLeggereUnoScriptConLeVirgoletteSopraUnCarattere;
    [Test]
    procedure DovrebbeTagliareUnoScriptA1023Caratteri;
    [Test]
    procedure DovrebbeDareFalsoPerUnoScriptSenzaGraffa;
    [Test]
    procedure DovrebbeDareFalsoPerUnoScriptCheNonSiChiude;
    [Test]
    procedure DovrebbeMettereLeStringheNelPool;
    [Test]
    procedure DovrebbeLeggereUnEsponenteComeNumeroACapoDelloScannerDoom;
    [Test]
    procedure DovrebbeLeggereUnPuntoFinaleSenzaLeggereOltreLaFine;
    [Test]
    procedure DovrebbeSegnalareAvvisiAlLog;
  end;

implementation

uses
  DelphiDoom.Tests.Gui.Fakes;

{ TTestGuiStringPool }

procedure TTestGuiStringPool.Setup;
begin
  FPool := TGuiStringPool.Create(32);
end;

procedure TTestGuiStringPool.TearDown;
begin
  FPool.Free;
end;

procedure TTestGuiStringPool.DovrebbeDareLaStessaStringaEContareUnaVoltaSola;
begin
  Assert.AreEqual('abc', string(FPool.Alloc('abc')));
  Assert.AreEqual('abc', string(FPool.Alloc('abc')));
  Assert.AreEqual(4, FPool.Used);
end;

procedure TTestGuiStringPool.DovrebbeContareLunghezzaPiuUnTerminatore;
begin
  FPool.Alloc('ab');
  FPool.Alloc('cde');
  Assert.AreEqual(7, FPool.Used);
end;

procedure TTestGuiStringPool.DovrebbeDareVuotoPerLaStringaVuotaSenzaConsumare;
begin
  Assert.AreEqual('', string(FPool.Alloc('')));
  Assert.AreEqual(0, FPool.Used);
end;

procedure TTestGuiStringPool.DovrebbeDistinguereLeMaiuscole;
begin
  FPool.Alloc('abc');
  FPool.Alloc('ABC');
  Assert.AreEqual(8, FPool.Used);
end;

procedure TTestGuiStringPool.DovrebbeRifiutareUnaStringaCheNonEntraEDarneVuoto;
begin
  // the test of the original is "length + used + 1 < size": 31 bytes of text do not fit in 32
  Assert.AreEqual('', string(FPool.Alloc(AnsiString(StringOfChar('x', 31)))));
  Assert.AreEqual(1, FPool.Refused);
  Assert.AreEqual(0, FPool.Used);
  Assert.AreEqual(30, Length(FPool.Alloc(AnsiString(StringOfChar('x', 30)))));
  Assert.AreEqual(31, FPool.Used);
end;

procedure TTestGuiStringPool.DovrebbeSvuotarsiConClear;
begin
  FPool.Alloc('abc');
  FPool.Clear;
  Assert.AreEqual(0, FPool.Used);
end;

{ TTestGuiValueReader }

procedure TTestGuiValueReader.Setup;
begin
  FLines := TStringList.Create;
  FLog := TGuiFakeLog.Create(FLines);
  FPool := TGuiStringPool.Create;
end;

procedure TTestGuiValueReader.TearDown;
begin
  FreeAndNil(FReader);
  FPool.Free;
end;

procedure TTestGuiValueReader.Open(const AText: AnsiString);
begin
  FreeAndNil(FReader);
  FReader := TGuiValueReader.Create(OpenGuiSource(AText), FPool, FLog);
end;

procedure TTestGuiValueReader.DovrebbeLeggereUnFloatEUnIntero;
var
  LFloat: Single;
  LInt: Integer;
begin
  Open('1.5 42 0x10');
  Assert.IsTrue(FReader.ReadFloat(LFloat));
  Assert.AreEqual(Single(1.5), LFloat);
  Assert.IsTrue(FReader.ReadInt(LInt));
  Assert.AreEqual(42, LInt);
  Assert.IsTrue(FReader.ReadInt(LInt));
  Assert.AreEqual(16, LInt);
end;

procedure TTestGuiValueReader.DovrebbeLeggereUnNumeroNegativoDopoUnMeno;
var
  LFloat: Single;
  LInt: Integer;
begin
  Open('- 2.5 -7');
  Assert.IsTrue(FReader.ReadFloat(LFloat));
  Assert.AreEqual(Single(-2.5), LFloat);
  Assert.IsTrue(FReader.ReadInt(LInt));
  Assert.AreEqual(-7, LInt);
end;

procedure TTestGuiValueReader.DovrebbeLeggereIlMenoDoppioComeUnMenoSolo;
var
  LFloat: Single;
begin
  // the original looks at the first character of the token: "--" and "-=" are minus signs as well
  Open('-- 3 -= 4');
  Assert.IsTrue(FReader.ReadFloat(LFloat));
  Assert.AreEqual(Single(-3), LFloat);
  Assert.IsTrue(FReader.ReadFloat(LFloat));
  Assert.AreEqual(Single(-4), LFloat);
end;

procedure TTestGuiValueReader.DovrebbeLasciareLaVariabileSeIlNumeroNonSiLegge;
var
  LFloat: Single;
begin
  LFloat := 9;
  Open('abc');
  Assert.IsFalse(FReader.ReadFloat(LFloat));
  Assert.AreEqual(Single(9), LFloat);
end;

procedure TTestGuiValueReader.DovrebbeSegnalareUnFloatCheNonELo;
var
  LFloat: Single;
begin
  Open('abc');
  FReader.ReadFloat(LFloat);
  Assert.AreEqual('log ^1ERROR: test.menu, line 1: expected float but found abc', FLines[0]);
end;

procedure TTestGuiValueReader.DovrebbeSegnalareUnInteroCheNonELo;
var
  LInt: Integer;
begin
  Open('"text"');
  FReader.ReadInt(LInt);
  Assert.AreEqual('log ^1ERROR: test.menu, line 1: expected integer but found text', FLines[0]);
end;

procedure TTestGuiValueReader.DovrebbeDareFalsoAlFineDelFile;
var
  LFloat: Single;
  LText: AnsiString;
begin
  Open('');
  Assert.IsFalse(FReader.ReadFloat(LFloat));
  Assert.IsFalse(FReader.ReadString(LText));
  Assert.AreEqual(0, FLines.Count);
end;

procedure TTestGuiValueReader.DovrebbeDareFalsoSeDopoIlMenoNonCEnulla;
var
  LFloat: Single;
  LInt: Integer;
begin
  Open('-');
  Assert.IsFalse(FReader.ReadFloat(LFloat));
  Open('-');
  Assert.IsFalse(FReader.ReadInt(LInt));
end;

procedure TTestGuiValueReader.DovrebbeLeggereUnColoreMemorizzandoOgniComponente;
var
  LColor: TGuiColor;
begin
  LColor[0] := 9;
  LColor[1] := 9;
  LColor[2] := 9;
  LColor[3] := 9;
  Open('1 2 x');
  Assert.IsFalse(FReader.ReadColor(LColor));
  Assert.AreEqual(Single(1), LColor[0]);
  Assert.AreEqual(Single(2), LColor[1]);
  Assert.AreEqual(Single(9), LColor[2]);
  Open('0.5 0.25 0.125 1');
  Assert.IsTrue(FReader.ReadColor(LColor));
  Assert.AreEqual(Single(0.125), LColor[2]);
end;

procedure TTestGuiValueReader.DovrebbeLeggereUnRettangolo;
var
  LRect: TGuiRect;
begin
  LRect := Default(TGuiRect);
  Open('1 2 3 4');
  Assert.IsTrue(FReader.ReadRect(LRect));
  Assert.AreEqual(Single(3), LRect.W);
  Assert.AreEqual(Single(4), LRect.H);
  Open('1 2');
  Assert.IsFalse(FReader.ReadRect(LRect));
end;

procedure TTestGuiValueReader.DovrebbeLeggereUnaStringaSenzaVirgolette;
var
  LText: AnsiString;
begin
  Open('"hello world" word');
  Assert.IsTrue(FReader.ReadString(LText));
  Assert.AreEqual('hello world', string(LText));
  Assert.IsTrue(FReader.ReadString(LText));
  Assert.AreEqual('word', string(LText));
end;

procedure TTestGuiValueReader.DovrebbeUnireLeStringheAdiacenti;
var
  LText: AnsiString;
begin
  Open('"ab" "cd"');
  Assert.IsTrue(FReader.ReadString(LText));
  Assert.AreEqual('abcd', string(LText));
end;

procedure TTestGuiValueReader.DovrebbeLeggereUnoScriptConLeVirgoletteSopraUnCarattere;
var
  LText: AnsiString;
begin
  Open('{ show a ; setcolor "x y" 1 }');
  Assert.IsTrue(FReader.ReadScript(LText));
  Assert.AreEqual('"show" a ; "setcolor" "x y" 1 ', string(LText));
end;

procedure TTestGuiValueReader.DovrebbeTagliareUnoScriptA1023Caratteri;
var
  LText: AnsiString;
  LSource: string;
  LIndex: Integer;
begin
  LSource := '{';
  for LIndex := 1 to 300 do
    LSource := LSource + ' abcde';
  LSource := LSource + ' }';
  Open(AnsiString(LSource));
  Assert.IsTrue(FReader.ReadScript(LText));
  Assert.AreEqual(1023, Length(LText));
end;

procedure TTestGuiValueReader.DovrebbeDareFalsoPerUnoScriptSenzaGraffa;
var
  LText: AnsiString;
begin
  Open('show a');
  Assert.IsFalse(FReader.ReadScript(LText));
end;

procedure TTestGuiValueReader.DovrebbeDareFalsoPerUnoScriptCheNonSiChiude;
var
  LText: AnsiString;
begin
  Open('{ show a');
  Assert.IsFalse(FReader.ReadScript(LText));
end;

procedure TTestGuiValueReader.DovrebbeMettereLeStringheNelPool;
var
  LText: AnsiString;
begin
  Open('abc');
  FReader.ReadString(LText);
  Assert.AreEqual(4, FPool.Used);
end;

procedure TTestGuiValueReader.DovrebbeLeggereUnEsponenteComeNumeroACapoDelloScannerDoom;
var
  LFloat: Single;
begin
  // DIFFERENCE from the botlib precompiler, which reads "1e2" as the number 1 and the name e2:
  // idLexer, which the library uses, reads the number 100 (see README.md of the library)
  Open('1e2');
  Assert.IsTrue(FReader.ReadFloat(LFloat));
  Assert.AreEqual(Single(100), LFloat);
end;

procedure TTestGuiValueReader.DovrebbeLeggereUnPuntoFinaleSenzaLeggereOltreLaFine;
var
  LFloat: Single;
begin
  // DIFFERENCE: l_script.c NumberValue reads the terminator of "12." as a digit and gives 7.2 (and goes on
  // reading the buffer behind the token); here 12
  Open('12.');
  Assert.IsTrue(FReader.ReadFloat(LFloat));
  Assert.AreEqual(Single(12), LFloat);
end;

procedure TTestGuiValueReader.DovrebbeSegnalareAvvisiAlLog;
begin
  Open('x');
  FReader.SourceWarning('careful');
  FReader.SourceError('broken');
  Assert.AreEqual('log ^3WARNING: test.menu, line 1: careful', FLines[0]);
  Assert.AreEqual('log ^1ERROR: test.menu, line 1: broken', FLines[1]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiStringPool);
  TDUnitX.RegisterTestFixture(TTestGuiValueReader);

end.

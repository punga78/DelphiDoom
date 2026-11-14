{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the edit field of the Quake III console (DUnitX)  }
{                                                                              }
{  The parity with the real C code is in TTestQ3Golden (scenario field.scn);   }
{  these tests cover what a scenario cannot: errors and optional parts.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.Field;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf,
  DelphiDoom.Console.Q3.Field.Types, DelphiDoom.Console.Q3.Field.Editor, DelphiDoom.Console.Q3.Field.History,
  DelphiDoom.Tests.Console.Q3.Fakes, DelphiDoom.Tests.Console.Q3.FieldHost;

type
  [TestFixture]
  [Category('console')]
  TTestQ3EditField = class(TObject)
  public
    [Test]
    procedure DovrebbeTroncareUnTestoLungoEDirloAlLog;
    [Test]
    procedure DovrebbeAccodareSenzaSuperareLaLunghezzaMassima;
    [Test]
    procedure DovrebbeSvuotareTestoCursoreEScorrimentoLasciandoLaLarghezza;
  end;

  [TestFixture]
  [Category('console')]
  TTestQ3FieldEditor = class(TObject)
  strict private
    FEditor: TQ3FieldEditor;
    FField: TQ3EditField;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeInserireUnCarattereAlCursore;
    [Test]
    procedure DovrebbeSostituireIlCarattereInModoSovrascrittura;
    [Test]
    procedure DovrebbeIgnorareICaratteriDiControlloNonPrevisti;
    [Test]
    procedure DovrebbeRifiutareUnCursoreFuoriDalTesto;
    [Test]
    procedure DovrebbeNonIncollareSenzaAppunti;
    [Test]
    procedure DovrebbeCambiareModoConInsertSenzaTastoMaiuscolo;
    [Test]
    procedure DovrebbeNonSuperareLaLunghezzaMassimaInInserimento;
    [Test]
    procedure DovrebbeNonSuperareLaLunghezzaMassimaInSovrascrittura;
  end;

  [TestFixture]
  [Category('console')]
  TTestQ3FieldHistory = class(TObject)
  public
    [Test]
    procedure DovrebbeSvuotareLaRigaAndandoIndietroSenzaStoria;
    [Test]
    procedure DovrebbeRicordareSoloLeUltime32Righe;
    [Test]
    procedure DovrebbeFermarsiInFondoAndandoAvanti;
  end;

implementation

{ TTestQ3EditField }

procedure TTestQ3EditField.DovrebbeTroncareUnTestoLungoEDirloAlLog;
var
  LField: TQ3EditField;
  LLog: TFakeQ3Log;
  LLogIntf: IQ3ConsoleLog;
begin
  LLog := TFakeQ3Log.Create;
  LLogIntf := LLog;
  LField.Clear;
  LField.Assign(AnsiString(StringOfChar('a', 300)), LLogIntf);
  Assert.AreEqual(255, LField.Length);
  Assert.AreEqual('Com_sprintf: overflow of 300 in 256'#10, LLog.TakePrinted);
end;

procedure TTestQ3EditField.DovrebbeAccodareSenzaSuperareLaLunghezzaMassima;
var
  LField: TQ3EditField;
begin
  LField.Clear;
  LField.Assign(AnsiString(StringOfChar('a', 250)));
  LField.Append(AnsiString(StringOfChar('b', 20)));
  Assert.AreEqual(255, LField.Length);
  Assert.AreEqual('b', string(Copy(LField.Text, 255, 1)));
  LField.Append('zz');
  Assert.AreEqual(255, LField.Length);
end;

procedure TTestQ3EditField.DovrebbeSvuotareTestoCursoreEScorrimentoLasciandoLaLarghezza;
var
  LField: TQ3EditField;
begin
  LField.Clear;
  LField.Assign('abc');
  LField.Cursor := 3;
  LField.Scroll := 2;
  LField.WidthInChars := 40;
  LField.Clear;
  Assert.AreEqual('', string(LField.Text));
  Assert.AreEqual(0, LField.Cursor);
  Assert.AreEqual(0, LField.Scroll);
  Assert.AreEqual(40, LField.WidthInChars);
end;

{ TTestQ3FieldEditor }

procedure TTestQ3FieldEditor.Setup;
begin
  FEditor := TQ3FieldEditor.Create;
  FField.Clear;
  FField.WidthInChars := 20;
end;

procedure TTestQ3FieldEditor.TearDown;
begin
  FEditor.Free;
end;

procedure TTestQ3FieldEditor.DovrebbeInserireUnCarattereAlCursore;
begin
  FEditor.CharEvent(FField, Ord('a'));
  FEditor.CharEvent(FField, Ord('c'));
  FEditor.KeyDownEvent(FField, Q3_K_LEFTARROW);
  FEditor.CharEvent(FField, Ord('b'));
  Assert.AreEqual('abc', string(FField.Text));
  Assert.AreEqual(2, FField.Cursor);
end;

procedure TTestQ3FieldEditor.DovrebbeSostituireIlCarattereInModoSovrascrittura;
begin
  FEditor.Overstrike := True;
  FEditor.CharEvent(FField, Ord('a'));
  FEditor.CharEvent(FField, Ord('b'));
  FEditor.KeyDownEvent(FField, Q3_K_HOME);
  FEditor.CharEvent(FField, Ord('X'));
  Assert.AreEqual('Xb', string(FField.Text));
end;

procedure TTestQ3FieldEditor.DovrebbeIgnorareICaratteriDiControlloNonPrevisti;
begin
  FEditor.CharEvent(FField, 2);
  FEditor.CharEvent(FField, 31);
  FEditor.CharEvent(FField, -5);
  Assert.AreEqual('', string(FField.Text));
  Assert.AreEqual(0, FField.Cursor);
end;

procedure TTestQ3FieldEditor.DovrebbeRifiutareUnCursoreFuoriDalTesto;
begin
  FField.Cursor := 40;
  Assert.WillRaise(
    procedure
    begin
      FEditor.CharEvent(FField, Ord('a'));
    end, EQ3ConsoleException);
  FField.Cursor := -1;
  Assert.WillRaise(
    procedure
    begin
      FEditor.CharEvent(FField, Ord('a'));
    end, EQ3ConsoleException);
end;

procedure TTestQ3FieldEditor.DovrebbeNonIncollareSenzaAppunti;
begin
  FEditor.CharEvent(FField, 22);
  Assert.AreEqual('', string(FField.Text));
end;

procedure TTestQ3FieldEditor.DovrebbeCambiareModoConInsertSenzaTastoMaiuscolo;
begin
  FEditor.KeyDownEvent(FField, Q3_K_INS);
  Assert.IsTrue(FEditor.Overstrike);
  FEditor.KeyDownEvent(FField, Q3_K_INS);
  Assert.IsFalse(FEditor.Overstrike);
end;

procedure TTestQ3FieldEditor.DovrebbeNonSuperareLaLunghezzaMassimaInInserimento;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 300 do
    FEditor.CharEvent(FField, Ord('a'));
  Assert.AreEqual(255, FField.Length);
end;

procedure TTestQ3FieldEditor.DovrebbeNonSuperareLaLunghezzaMassimaInSovrascrittura;
var
  LIndex: Integer;
begin
  FEditor.Overstrike := True;
  for LIndex := 1 to 300 do
    FEditor.CharEvent(FField, Ord('a'));
  Assert.AreEqual(255, FField.Length);
  Assert.AreEqual(255, FField.Cursor);
end;

{ TTestQ3FieldHistory }

procedure TTestQ3FieldHistory.DovrebbeSvuotareLaRigaAndandoIndietroSenzaStoria;
var
  LHistory: TQ3FieldHistory;
  LField: TQ3EditField;
begin
  LHistory := TQ3FieldHistory.Create;
  try
    LField.Clear;
    LField.Assign('testo');
    LField.Cursor := 5;
    LHistory.Previous(LField);
    Assert.AreEqual('', string(LField.Text));
    Assert.AreEqual(0, LHistory.CurrentLine);
  finally
    LHistory.Free;
  end;
end;

procedure TTestQ3FieldHistory.DovrebbeRicordareSoloLeUltime32Righe;
var
  LHistory: TQ3FieldHistory;
  LField: TQ3EditField;
  LIndex: Integer;
begin
  LHistory := TQ3FieldHistory.Create;
  try
    for LIndex := 1 to 40 do
    begin
      LField.Clear;
      LField.Assign(AnsiString('riga ' + IntToStr(LIndex)));
      LHistory.Add(LField);
    end;
    Assert.AreEqual(40, LHistory.NextLine);
    for LIndex := 1 to 40 do
      LHistory.Previous(LField);
    Assert.AreEqual(8, LHistory.CurrentLine);
    Assert.AreEqual('riga 9', string(LField.Text));
  finally
    LHistory.Free;
  end;
end;

procedure TTestQ3FieldHistory.DovrebbeFermarsiInFondoAndandoAvanti;
var
  LHistory: TQ3FieldHistory;
  LField: TQ3EditField;
begin
  LHistory := TQ3FieldHistory.Create;
  try
    LField.Clear;
    LField.Assign('uno');
    LHistory.Add(LField);
    LField.Assign('modificata');
    LHistory.Next(LField);
    Assert.AreEqual('modificata', string(LField.Text));
    Assert.AreEqual(1, LHistory.CurrentLine);
  finally
    LHistory.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3EditField);
  TDUnitX.RegisterTestFixture(TTestQ3FieldEditor);
  TDUnitX.RegisterTestFixture(TTestQ3FieldHistory);

end.

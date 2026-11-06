{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Dehacked library - the lines of a patch            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Dehacked.LineSource;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Dehacked.Intf;

type
  [TestFixture]
  [Category('dehacked')]
  TTestDehackedLineSource = class(TObject)
  private
    function Source(const AText: string): IDehackedLineSource;
  public
    [Test]
    procedure TestLeRigheSonoMaiuscoleESenzaSpaziAiLati;
    [Test]
    procedure TestCommentiERigheVuoteSonoSaltati;
    [Test]
    procedure TestLeRigheDiUnTestoConservanoSpaziERigheVuote;
    [Test]
    procedure TestUnCommentoNelTestoRiportaAlSaltoDelleRigheVuote;
    [Test]
    procedure TestIlNumeroDiRigaPartDaUno;
    [Test]
    procedure TestFineDelTestoRestituisceFalseELasciaLUltimaRiga;
    [Test]
    procedure TestPushBackSiRicordaUnaSolaVolta;
    [Test]
    procedure TestSplitLinesTerminaSuUnCaratterePrivoDiSignificato;
    [Test]
    procedure TestSplitLinesAccettaCrLfELf;
  end;

implementation

uses
  DelphiDoom.Dehacked.LineSource, DelphiDoom.Dehacked.Text;

{ TTestDehackedLineSource }

function TTestDehackedLineSource.Source(const AText: string): IDehackedLineSource;
begin
  Result := TDehackedLineSource.Create(TDehackedText.SplitLines(AText));
end;

procedure TTestDehackedLineSource.TestLeRigheSonoMaiuscoleESenzaSpaziAiLati;
var
  LSource: IDehackedLineSource;
  LLine: string;
begin
  LSource := Source('  Hit points = 100  ');
  Assert.IsTrue(LSource.Next(LLine));
  Assert.AreEqual('HIT POINTS = 100', LLine);
end;

procedure TTestDehackedLineSource.TestCommentiERigheVuoteSonoSaltati;
var
  LSource: IDehackedLineSource;
  LLine: string;
begin
  LSource := Source('# uno'#13#10'// due'#13#10'   '#13#10'   // tre'#13#10'vera'#13#10'#fine');
  Assert.IsTrue(LSource.Next(LLine));
  Assert.AreEqual('VERA', LLine);
  Assert.IsFalse(LSource.Next(LLine));
end;

procedure TTestDehackedLineSource.TestLeRigheDiUnTestoConservanoSpaziERigheVuote;
var
  LSource: IDehackedLineSource;
  LLine: string;
begin
  LSource := Source('  a b  '#10#10'c');
  Assert.IsTrue(LSource.Next(LLine, False));
  Assert.AreEqual('  A B  ', LLine);
  Assert.IsTrue(LSource.Next(LLine, False));
  Assert.AreEqual('', LLine);
  Assert.IsTrue(LSource.Next(LLine, False));
  Assert.AreEqual('C', LLine);
end;

procedure TTestDehackedLineSource.TestUnCommentoNelTestoRiportaAlSaltoDelleRigheVuote;
var
  LSource: IDehackedLineSource;
  LLine: string;
begin
  // come il vecchio DEH_NextLine, che dopo un commento si richiamava con le impostazioni normali
  LSource := Source('# commento'#10'  x  ');
  Assert.IsTrue(LSource.Next(LLine, False));
  Assert.AreEqual('X', LLine);
end;

procedure TTestDehackedLineSource.TestIlNumeroDiRigaPartDaUno;
var
  LSource: IDehackedLineSource;
  LLine: string;
begin
  LSource := Source('# c'#10#10'a'#10'b');
  LSource.Next(LLine);
  Assert.AreEqual(3, LSource.LineNumber);
  LSource.Next(LLine);
  Assert.AreEqual(4, LSource.LineNumber);
end;

procedure TTestDehackedLineSource.TestFineDelTestoRestituisceFalseELasciaLUltimaRiga;
var
  LSource: IDehackedLineSource;
  LLine: string;
begin
  LSource := Source('a');
  LSource.Next(LLine);
  Assert.IsFalse(LSource.HasMoreLines);
  LLine := 'X';
  Assert.IsFalse(LSource.Next(LLine));
  Assert.AreEqual('A', LLine);
  Assert.AreEqual('A', LSource.LastLine);
end;

procedure TTestDehackedLineSource.TestPushBackSiRicordaUnaSolaVolta;
var
  LSource: IDehackedLineSource;
begin
  LSource := Source('a');
  Assert.IsFalse(LSource.TakePushBack);
  LSource.PushBack;
  Assert.IsTrue(LSource.TakePushBack);
  Assert.IsFalse(LSource.TakePushBack);
end;

procedure TTestDehackedLineSource.TestSplitLinesTerminaSuUnCaratterePrivoDiSignificato;
var
  LLines: TArray<string>;
begin
  LLines := TDehackedText.SplitLines('a'#10'b'#0'c'#10'd');
  Assert.AreEqual(2, Length(LLines));
  Assert.AreEqual('b', LLines[1]);
end;

procedure TTestDehackedLineSource.TestSplitLinesAccettaCrLfELf;
var
  LLines: TArray<string>;
begin
  LLines := TDehackedText.SplitLines('a'#13#10'b'#10'c'#13'd'#10#13'e');
  Assert.AreEqual(6, Length(LLines)); // a b c d (vuota) e
  Assert.AreEqual('', LLines[4]);
  Assert.AreEqual('e', LLines[5]);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEndoomTextPaste                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.TextPaste;

interface

uses
  System.SysUtils, System.Types, DUnitX.TestFramework,
  DelphiDoom.Endoom.Intf;

type
  /// <summary>
  ///   The PASTE lines of Tests\Data\Endoom\editor.golden.txt were written by the text branch of
  ///   Paste1Click of ENDEDIT (Tools\Verifica\164\H2Old.pas) on TEditorScenarios.PasteCases
  /// </summary>
  [TestFixture]
  [Category('endoom')]
  TTestEndoomTextPaste = class(TObject)
  strict private
    FScreen: IEndoomScreen;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeScrivereUnaRigaDalPuntoDato;
    [Test]
    procedure DovrebbeLasciareLoSfondoEIlLampeggio;
    [Test]
    procedure DovrebbeScrivereUnaRigaPerRiga;
    [Test]
    procedure DovrebbeTagliareLeRigheOltreLaColonnaOttanta;
    [Test]
    procedure DovrebbeTagliareLeRigheCheNonStannoSottoLUltimaRiga;
    [Test]
    procedure DovrebbeDareLaCellaDoveVaIlCursore;
    [Test]
    procedure DovrebbeNonMuovereIlCursoreInUnaNuovaRigaFinale;
    [Test]
    procedure DovrebbeUsareIlCodiceDelCarattereAnsi;
    [Test]
    procedure DovrebbeSostituireIlCarattereCheNonHaCodice;
    [Test]
    procedure DovrebbeNonScrivereNulleDiUnTestoVuoto;
    [Test]
    procedure DovrebbeIncollareGliStessiTestiDelVecchioEditor;
  end;

implementation

uses
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.EditorFactory, DelphiDoom.Endoom.TextPaste,
  DelphiDoom.Tests.Endoom.Digest, DelphiDoom.Tests.Endoom.EditorScenarios, DelphiDoom.Tests.Endoom.EditorHelper;

{ TTestEndoomTextPaste }

procedure TTestEndoomTextPaste.Setup;
begin
  FScreen := TEndoomEditorFactory.CreateScreen;
end;

procedure TTestEndoomTextPaste.DovrebbeScrivereUnaRigaDalPuntoDato;
begin
  TEndoomTextPaste.Apply(FScreen, 'Ciao', 5, 3, 14);
  Assert.AreEqual(Integer(Ord('C')), Integer(FScreen.GetCharacter(5, 3)));
  Assert.AreEqual(Integer(Ord('o')), Integer(FScreen.GetCharacter(8, 3)));
  Assert.AreEqual(14, FScreen.GetForeground(7, 3));
  Assert.AreEqual(0, Integer(FScreen.GetCharacter(9, 3)));
end;

procedure TTestEndoomTextPaste.DovrebbeLasciareLoSfondoEIlLampeggio;
begin
  FScreen.SetBackground(0, 0, 5);
  FScreen.SetBlink(0, 0, True);
  TEndoomTextPaste.Apply(FScreen, 'x', 0, 0, 3);
  Assert.AreEqual(5, FScreen.GetBackground(0, 0));
  Assert.IsTrue(FScreen.GetBlink(0, 0));
  Assert.AreEqual(3, FScreen.GetForeground(0, 0));
end;

procedure TTestEndoomTextPaste.DovrebbeScrivereUnaRigaPerRiga;
var
  LCursor: TPoint;
begin
  LCursor := TEndoomTextPaste.Apply(FScreen, 'uno' + #13#10 + 'due', 10, 2, 7);
  Assert.AreEqual(Integer(Ord('u')), Integer(FScreen.GetCharacter(10, 2)));
  // the next row starts from the first column
  Assert.AreEqual(Integer(Ord('d')), Integer(FScreen.GetCharacter(0, 3)));
  Assert.AreEqual(3, LCursor.X);
  Assert.AreEqual(3, LCursor.Y);
end;

procedure TTestEndoomTextPaste.DovrebbeTagliareLeRigheOltreLaColonnaOttanta;
var
  LCursor: TPoint;
begin
  LCursor := TEndoomTextPaste.Apply(FScreen, StringOfChar('a', 100), 75, 0, 1);
  Assert.AreEqual(Integer(Ord('a')), Integer(FScreen.GetCharacter(79, 0)));
  Assert.AreEqual(0, Integer(FScreen.GetCharacter(0, 1)));
  Assert.AreEqual(79, LCursor.X);
  Assert.AreEqual(0, LCursor.Y);
end;

procedure TTestEndoomTextPaste.DovrebbeTagliareLeRigheCheNonStannoSottoLUltimaRiga;
var
  LCursor: TPoint;
begin
  LCursor := TEndoomTextPaste.Apply(FScreen, 'a' + #13#10 + 'b' + #13#10 + 'c' + #13#10 + 'd', 0, 23, 1);
  Assert.AreEqual(Integer(Ord('a')), Integer(FScreen.GetCharacter(0, 23)));
  Assert.AreEqual(Integer(Ord('b')), Integer(FScreen.GetCharacter(0, 24)));
  Assert.AreEqual(0, LCursor.X);
  Assert.AreEqual(24, LCursor.Y);
end;

procedure TTestEndoomTextPaste.DovrebbeDareLaCellaDoveVaIlCursore;
var
  LCursor: TPoint;
begin
  LCursor := TEndoomTextPaste.Apply(FScreen, 'abc', 0, 0, 1);
  Assert.AreEqual(3, LCursor.X);
  Assert.AreEqual(0, LCursor.Y);
end;

procedure TTestEndoomTextPaste.DovrebbeNonMuovereIlCursoreInUnaNuovaRigaFinale;
var
  LCursor: TPoint;
begin
  // a line break at the end of the text does not start a new row (the old string list had no empty last line)
  LCursor := TEndoomTextPaste.Apply(FScreen, 'ab' + #13#10, 2, 2, 1);
  Assert.AreEqual(4, LCursor.X);
  Assert.AreEqual(2, LCursor.Y);
end;

procedure TTestEndoomTextPaste.DovrebbeUsareIlCodiceDelCarattereAnsi;
begin
  Assert.AreEqual(Integer($E8), Integer(TEndoomTextPaste.CodeOf(#$E8)));
  Assert.AreEqual(Integer(Ord('A')), Integer(TEndoomTextPaste.CodeOf('A')));
  Assert.AreEqual(Integer($FF), Integer(TEndoomTextPaste.CodeOf(#$FF)));
  Assert.AreEqual(0, Integer(TEndoomTextPaste.CodeOf(#0)));
end;

procedure TTestEndoomTextPaste.DovrebbeSostituireIlCarattereCheNonHaCodice;
begin
  Assert.AreEqual(Integer(Ord('?')), Integer(TEndoomTextPaste.CodeOf(#$20AC)));
  Assert.AreEqual(Integer(Ord('?')), Integer(TEndoomTextPaste.CodeOf(#$0100)));
  TEndoomTextPaste.Apply(FScreen, #$20AC, 0, 0, 1);
  Assert.AreEqual(Integer(Ord('?')), Integer(FScreen.GetCharacter(0, 0)));
end;

procedure TTestEndoomTextPaste.DovrebbeNonScrivereNulleDiUnTestoVuoto;
var
  LCursor: TPoint;
begin
  LCursor := TEndoomTextPaste.Apply(FScreen, '', 7, 7, 1);
  Assert.AreEqual(7, LCursor.X);
  Assert.AreEqual(7, LCursor.Y);
  Assert.IsTrue(FScreen.IsSameAs(TEndoomEditorFactory.CreateScreen));
end;

procedure TTestEndoomTextPaste.DovrebbeIncollareGliStessiTestiDelVecchioEditor;
var
  LGolden: TArray<string>;
  LCases: TArray<TEditorPasteCase>;
  LIndex: Integer;
  LCursor: TPoint;
begin
  LGolden := TEditorHelper.GoldenLines('PASTE');
  LCases := TEditorScenarios.PasteCases;
  Assert.AreEqual(Length(LCases), Length(LGolden));
  for LIndex := 0 to High(LCases) do
  begin
    FScreen.Clear;
    LCursor := TEndoomTextPaste.Apply(FScreen, LCases[LIndex].Text, LCases[LIndex].X, LCases[LIndex].Y,
      LCases[LIndex].Foreground);
    Assert.AreEqual(Format('%d %s %d %d', [LIndex, TEndoomDigest.OfBytes(FScreen.ToBytes), LCursor.X, LCursor.Y]),
      LGolden[LIndex]);
  end;
end;

end.

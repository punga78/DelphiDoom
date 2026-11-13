{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the layout of the text  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.TextLayout;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.Types, DelphiDoom.Hud.Layout, DelphiDoom.Hud.TextLine;

type
  [TestFixture]
  [Category('hud')]
  TTestHudTextLayout = class(TObject)
  private
    FLayout: THudLayout;
    FLine: THudTextLine;
    FWidths: THudFontWidths;
    function Glyphs: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMettereIGlifiUnoDopoLAltro;
    [Test]
    procedure DovrebbeMettereInMaiuscoleLeLettere;
    [Test]
    procedure DovrebbeSaltareQuattroColonneConLoSpazio;
    [Test]
    procedure DovrebbeTornareAlMargineConIlLineFeed;
    [Test]
    procedure DovrebbeScendereConIlCarriageReturn;
    [Test]
    procedure DovrebbeIgnorareICaratteriSenzaGlifo;
    [Test]
    procedure DovrebbeFermarsiAlBordoDelloSchermo;
    [Test]
    procedure DovrebbeFermarsiAlloSpazioSulBordo;
    [Test]
    procedure DovrebbeFermarsiPrimaDelLimiteDiStrife;
    [Test]
    procedure DovrebbeSaltareUnGlifoCheIlFontNonHa;
    [Test]
    procedure DovrebbeMettereIlCursoreSullaPrimaRiga;
    [Test]
    procedure DovrebbeNonMettereIlCursoreSeNonCiStaOSenzaGlifo;
    [Test]
    procedure DovrebbeUsareLaStessaListaPerPiuLayout;
    [Test]
    procedure DovrebbeAndareACapoAllIngressoDelBordoNelTestoACapo;
    [Test]
    procedure DovrebbeSaltareGliSpaziAlPrincipioDiUnaRigaNelTestoACapo;
    [Test]
    procedure DovrebbeTrattareLUnderscoreComeSpazioNelTestoACapo;
    [Test]
    procedure DovrebbeSaltareICaratteriFuoriDalFontNelTestoACapo;
    [Test]
    procedure DovrebbeAccendereLEvidenziazioneAlPrimoNumero;
    [Test]
    procedure DovrebbeNonEvidenziareSeNonRichiesto;
    [Test]
    procedure DovrebbeDareLaPosizioneFinaleDelTestoEvidenziato;
    [Test]
    procedure DovrebbeFermareIlTestoEvidenziatoAlBordo;
    [Test]
    procedure DovrebbeDareLaPosizioneDiPartenzaSeIlTestoEVuoto;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.TextLayout;

const
  START_CHAR = 33;
  FONT_GLYPHS = 63;

{ TTestHudTextLayout }

procedure TTestHudTextLayout.Setup;
var
  LIndex: Integer;
begin
  FLayout := THudLayout.Create;
  FLine := THudTextLine.Create(10, 20, START_CHAR);
  FWidths.Count := FONT_GLYPHS;
  for LIndex := 0 to HUD_MAX_GLYPHS - 1 do
    FWidths.Width[LIndex] := 6;
end;

procedure TTestHudTextLayout.TearDown;
begin
  FLine.Free;
  FLayout.Free;
end;

function TTestHudTextLayout.Glyphs: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FLayout.Count - 1 do
    Result := Result + Format('%d@%d,%d ', [FLayout.Glyphs[LIndex].Index, FLayout.Glyphs[LIndex].X,
      FLayout.Glyphs[LIndex].Y]);
  Result := Trim(Result);
end;

procedure TTestHudTextLayout.DovrebbeMettereIGlifiUnoDopoLAltro;
begin
  FLine.AddText('AB');
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), False, FLayout);
  Assert.AreEqual('32@10,20 33@16,20', Glyphs);
  Assert.AreEqual(22, FLayout.EndX);
  Assert.AreEqual(20, FLayout.EndY);
  Assert.IsFalse(FLayout.CursorFits);
end;

procedure TTestHudTextLayout.DovrebbeMettereInMaiuscoleLeLettere;
begin
  FLine.AddText('aB');
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), False, FLayout);
  Assert.AreEqual('32@10,20 33@16,20', Glyphs);
end;

procedure TTestHudTextLayout.DovrebbeSaltareQuattroColonneConLoSpazio;
begin
  FLine.AddText('A B');
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), False, FLayout);
  Assert.AreEqual('32@10,20 33@20,20', Glyphs);
end;

procedure TTestHudTextLayout.DovrebbeTornareAlMargineConIlLineFeed;
begin
  FLine.AddText('AB'#10'C');
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), False, FLayout);
  Assert.AreEqual('32@10,20 33@16,20 34@10,20', Glyphs);
end;

procedure TTestHudTextLayout.DovrebbeScendereConIlCarriageReturn;
begin
  FLine.AddText('A'#13#10'B');
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), False, FLayout);
  Assert.AreEqual('32@10,20 33@10,28', Glyphs);
  Assert.AreEqual(28, FLayout.EndY);
end;

procedure TTestHudTextLayout.DovrebbeIgnorareICaratteriSenzaGlifo;
begin
  FLine.AddText('A'#1'~{B');
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), False, FLayout);
  Assert.AreEqual('32@10,20 33@16,20', Glyphs);
end;

procedure TTestHudTextLayout.DovrebbeFermarsiAlBordoDelloSchermo;
begin
  FLine.AddText('AAAA');
  // the third glyph would end at 28: it is drawn only if the screen is 28 wide or more
  THudTextLayout.Line(FLine, FWidths, 26, Ord('_'), False, FLayout);
  Assert.AreEqual(2, FLayout.Count);
  THudTextLayout.Line(FLine, FWidths, 27, Ord('_'), False, FLayout);
  Assert.AreEqual(2, FLayout.Count);
  THudTextLayout.Line(FLine, FWidths, 28, Ord('_'), False, FLayout);
  Assert.AreEqual(3, FLayout.Count);
  THudTextLayout.Line(FLine, FWidths, 21, Ord('_'), False, FLayout);
  Assert.AreEqual(1, FLayout.Count);
end;

procedure TTestHudTextLayout.DovrebbeFermarsiAlloSpazioSulBordo;
begin
  FLine.AddText('A B');
  // the space brings x to 20, that is not less than the screen: the text ends
  THudTextLayout.Line(FLine, FWidths, 20, Ord('_'), False, FLayout);
  Assert.AreEqual(1, FLayout.Count);
  Assert.AreEqual(20, FLayout.EndX);
end;

procedure TTestHudTextLayout.DovrebbeFermarsiPrimaDelLimiteDiStrife;
begin
  FLine.AddText('A_');
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), False, FLayout);
  Assert.AreEqual(2, FLayout.Count);
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_') - 1, False, FLayout);
  Assert.AreEqual(1, FLayout.Count);
end;

procedure TTestHudTextLayout.DovrebbeSaltareUnGlifoCheIlFontNonHa;
begin
  FWidths.Count := 2;
  FLine.AddText('ABC');
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), False, FLayout);
  // the glyph of A is 32, the font has 0 and 1 only: nothing is drawn and the position stays
  Assert.AreEqual(0, FLayout.Count);
  Assert.AreEqual(10, FLayout.EndX);
end;

procedure TTestHudTextLayout.DovrebbeMettereIlCursoreSullaPrimaRiga;
begin
  FLine.AddText('A'#13#10'B');
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), True, FLayout);
  Assert.IsTrue(FLayout.CursorFits);
  Assert.AreEqual(16, FLayout.CursorX);
  Assert.AreEqual(20, FLayout.CursorY);
  Assert.AreEqual(28, FLayout.EndY);
end;

procedure TTestHudTextLayout.DovrebbeNonMettereIlCursoreSeNonCiStaOSenzaGlifo;
begin
  FLine.AddText('AB');
  THudTextLayout.Line(FLine, FWidths, 27, Ord('_'), True, FLayout);
  Assert.IsFalse(FLayout.CursorFits);
  THudTextLayout.Line(FLine, FWidths, 28, Ord('_'), True, FLayout);
  Assert.IsTrue(FLayout.CursorFits);
  FWidths.Count := 10;
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), True, FLayout);
  Assert.IsFalse(FLayout.CursorFits);
end;

procedure TTestHudTextLayout.DovrebbeUsareLaStessaListaPerPiuLayout;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 300 do
    FLine.AddChar('A');
  THudTextLayout.Line(FLine, FWidths, 2000, Ord('_'), False, FLayout);
  Assert.AreEqual(300, FLayout.Count);
  FLine.Clear;
  FLine.AddText('A');
  THudTextLayout.Line(FLine, FWidths, 320, Ord('_'), False, FLayout);
  Assert.AreEqual(1, FLayout.Count);
end;

procedure TTestHudTextLayout.DovrebbeAndareACapoAllIngressoDelBordoNelTestoACapo;
begin
  // right limit 24: a glyph that would end after it goes to the next row at the left margin
  THudTextLayout.Wrapped('AAA', 10, 20, FWidths, START_CHAR, 12, 24, FLayout);
  Assert.AreEqual('32@10,20 32@16,20 32@10,32', Glyphs);
  Assert.AreEqual(16, FLayout.EndX);
  Assert.AreEqual(32, FLayout.EndY);
end;

procedure TTestHudTextLayout.DovrebbeSaltareGliSpaziAlPrincipioDiUnaRigaNelTestoACapo;
begin
  THudTextLayout.Wrapped('  A'#10' B', 10, 20, FWidths, START_CHAR, 12, 300, FLayout);
  Assert.AreEqual('32@10,20 33@10,20', Glyphs);
end;

procedure TTestHudTextLayout.DovrebbeTrattareLUnderscoreComeSpazioNelTestoACapo;
begin
  // an underscore is a space of four columns even at the start of a row
  THudTextLayout.Wrapped('_A', 10, 20, FWidths, START_CHAR, 12, 300, FLayout);
  Assert.AreEqual('32@14,20', Glyphs);
  THudTextLayout.Wrapped('A_B', 10, 20, FWidths, START_CHAR, 12, 300, FLayout);
  Assert.AreEqual('32@10,20 33@20,20', Glyphs);
end;

procedure TTestHudTextLayout.DovrebbeSaltareICaratteriFuoriDalFontNelTestoACapo;
begin
  THudTextLayout.Wrapped('A'#1'B'#13'C', 10, 20, FWidths, START_CHAR, 12, 300, FLayout);
  // #1 is four columns, the carriage return goes down a row without going back
  Assert.AreEqual('32@10,20 33@20,20 34@26,32', Glyphs);
end;

procedure TTestHudTextLayout.DovrebbeAccendereLEvidenziazioneAlPrimoNumero;
begin
  THudTextLayout.Highlighted('K: 12 x', 10, 20, FWidths, START_CHAR, 12, 320, True, FLayout);
  Assert.IsFalse(FLayout.Glyphs[0].Highlighted);
  // from the first digit on every glyph is highlighted (the old code did not turn it off)
  Assert.IsTrue(FLayout.Glyphs[FLayout.Count - 1].Highlighted);
  Assert.IsTrue(FLayout.Glyphs[FLayout.Count - 2].Highlighted);
end;

procedure TTestHudTextLayout.DovrebbeNonEvidenziareSeNonRichiesto;
var
  LIndex: Integer;
begin
  THudTextLayout.Highlighted('K: 12', 10, 20, FWidths, START_CHAR, 12, 320, False, FLayout);
  for LIndex := 0 to FLayout.Count - 1 do
    Assert.IsFalse(FLayout.Glyphs[LIndex].Highlighted);
end;

procedure TTestHudTextLayout.DovrebbeDareLaPosizioneFinaleDelTestoEvidenziato;
begin
  THudTextLayout.Highlighted('AB'#13#10'C', 10, 20, FWidths, START_CHAR, 12, 320, False, FLayout);
  Assert.AreEqual('32@10,20 33@16,20 34@10,32', Glyphs);
  Assert.AreEqual(16, FLayout.EndX);
  Assert.AreEqual(32, FLayout.EndY);
end;

procedure TTestHudTextLayout.DovrebbeFermareIlTestoEvidenziatoAlBordo;
begin
  THudTextLayout.Highlighted('AAAA', 10, 20, FWidths, START_CHAR, 12, 27, False, FLayout);
  Assert.AreEqual(2, FLayout.Count);
  // a #0 ends the text, a character with no glyph is four columns
  THudTextLayout.Highlighted('A'#0'B', 10, 20, FWidths, START_CHAR, 12, 320, False, FLayout);
  Assert.AreEqual(1, FLayout.Count);
  THudTextLayout.Highlighted('A'#1'B', 10, 20, FWidths, START_CHAR, 12, 320, False, FLayout);
  Assert.AreEqual('32@10,20 33@20,20', Glyphs);
end;

procedure TTestHudTextLayout.DovrebbeDareLaPosizioneDiPartenzaSeIlTestoEVuoto;
begin
  THudTextLayout.Highlighted('', 7, 8, FWidths, START_CHAR, 12, 320, True, FLayout);
  Assert.AreEqual(0, FLayout.Count);
  Assert.AreEqual(7, FLayout.EndX);
  Assert.AreEqual(8, FLayout.EndY);
end;

end.

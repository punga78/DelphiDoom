{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the layout and the drawing of text   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Text;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Font.Types,
  DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform, DelphiDoom.War.Text.Types,
  DelphiDoom.War.Text.Renderer;

type
  [TestFixture]
  [Category('war')]
  TTestWarTextLayout = class(TObject)
  private
    FParams: TWarFontParams;
    function Advance(AChar: AnsiChar): Single;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareIlGlifoDalCodiceMenoTrentadue;
    [Test]
    procedure DovrebbeDareIlGlifoZeroPerSpazioZeroECodiciAlti;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnCarattereNonHaGlifo;
    [Test]
    procedure DovrebbeTenereIlSegnoDelloZeroNegativo;
    [Test]
    procedure DovrebbeMisurareUnaRigaSommandoLeLarghezze;
    [Test]
    procedure DovrebbeMisurareSoloIPrimiCaratteri;
    [Test]
    procedure DovrebbeContareUnATabulazioneComeDueSpazi;
    [Test]
    procedure DovrebbeContareUnAcapoComeUnPassoDiAvanzamento;
    [Test]
    procedure DovrebbeScalareLaMisuraConLaDimensioneDelFont;
    [Test]
    procedure DovrebbeDividereIlTestoAgliAcapo;
    [Test]
    procedure DovrebbeANdareACapoDoveNonCeSpazioSeLInterruzioneEPerCarattere;
    [Test]
    procedure NonDovrebbeAndareACapoSenzaInterruzione;
    [Test]
    procedure DovrebbeTagliareSpaziETabulazioniAgliEstremi;
    [Test]
    procedure DovrebbeTagliareSoloGliSpaziSeLaPotaturaELimitata;
    [Test]
    procedure NonDovrebbeFareOltreIlNumeroMassimoDiRighe;
    [Test]
    procedure DovrebbeMisurareLeRighe;
    [Test]
    procedure DovrebbeUsareLAltezzaDiRigaDellaFont;
    [Test]
    procedure DovrebbeAllinearePerOrizzontaleEVerticale;
    [Test]
    procedure DovrebbeAllinearePerRiga;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarTextRenderer = class(TObject)
  private
    FBlits: TList<TWarBlit>;
    FTransform: TWarRenderTransform;
    FRenderer: TWarTextRenderer;
    FParams: TWarFontParams;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFareUnBlitPerOgniGlifoEUnoNoPerLoSpazio;
    [Test]
    procedure DovrebbeMettereIGlifiUnoDopoLAltroConLAvanzamento;
    [Test]
    procedure DovrebbeUsareIlColoreDelTestoENonLasciarloAcceso;
    [Test]
    procedure DovrebbeColorareLEvidenziazione;
    [Test]
    procedure DovrebbeColorareTuttoConLEvidenziazioneTotale;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLEvidenziazioneVaOltreIlTesto;
    [Test]
    procedure DovrebbeTrattareGliAcapoComeSpaziInUnaRiga;
    [Test]
    procedure DovrebbeFermarsiAlBordoDelLimite;
    [Test]
    procedure DovrebbeScalareIGlifiConLaDimensione;
    [Test]
    procedure DovrebbeDisegnareUnaRigaPerVolta;
    [Test]
    procedure DovrebbeFermarsiQuandoLeRigheSuperanoLaAltezza;
    [Test]
    procedure DovrebbeEvidenziareTraPiuRighe;
    [Test]
    procedure DovrebbeTenereLaPilaInPareggio;
  end;

implementation

uses
  DelphiDoom.War.Factory, DelphiDoom.War.Intf, DelphiDoom.War.Font.Intf, DelphiDoom.War.Text.Layout;

function DefaultParams: TWarFontParams;
var
  LMetrics: IWarFontMetrics;
begin
  LMetrics := TWarFactory.CreateFontMetrics;
  Result := Default(TWarFontParams);
  LMetrics.TryGetFont(0, Result.FontData);
  Result.FontSize := Result.FontData.LineHeight;
  Result.FontColor.R := 10;
  Result.FontColor.G := 20;
  Result.FontColor.B := 30;
  Result.FontColor.A := 255;
  Result.HighlightColor.R := 200;
  Result.HighlightColor.G := 210;
  Result.HighlightColor.B := 220;
  Result.HighlightColor.A := 255;
  Result.HighlightIndex := WAR_NO_HIGHLIGHT;
end;

{ TTestWarTextLayout }

procedure TTestWarTextLayout.Setup;
begin
  FParams := DefaultParams;
end;

function TTestWarTextLayout.Advance(AChar: AnsiChar): Single;
begin
  Result := TWarTextLayout.GlyphOf(FParams.FontData, AChar).Width + FParams.FontData.Advance;
end;

procedure TTestWarTextLayout.DovrebbeDareIlGlifoDalCodiceMenoTrentadue;
begin
  Assert.AreEqual<Integer>(33, TWarTextLayout.GlyphIndex('A'));
  Assert.AreEqual<Integer>(1, TWarTextLayout.GlyphIndex('!'));
  Assert.AreEqual<Integer>(94, TWarTextLayout.GlyphIndex('~'));
  Assert.AreEqual<Integer>(Integer(FParams.FontData.Glyphs[33].X), Integer(TWarTextLayout.GlyphOf(FParams.FontData, 'A').X));
end;

procedure TTestWarTextLayout.DovrebbeDareIlGlifoZeroPerSpazioZeroECodiciAlti;
begin
  Assert.AreEqual<Integer>(0, TWarTextLayout.GlyphIndex(' '));
  Assert.AreEqual<Integer>(0, TWarTextLayout.GlyphIndex(#0));
  Assert.AreEqual<Integer>(0, TWarTextLayout.GlyphIndex(AnsiChar($E9)));
  Assert.AreEqual<Integer>(0, TWarTextLayout.GlyphIndex(AnsiChar($80)));
end;

procedure TTestWarTextLayout.DovrebbeSollevareEccezioneSeUnCarattereNonHaGlifo;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarTextLayout.GlyphOf(FParams.FontData, #5);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarTextLayout.GlyphOf(FParams.FontData, #127);
    end, EWarException);
end;

procedure TTestWarTextLayout.DovrebbeTenereIlSegnoDelloZeroNegativo;
var
  LValue: Single;
  LBits: Cardinal;
begin
  LValue := TWarTextLayout.CeilFloat(-0.3);
  Move(LValue, LBits, 4);
  Assert.AreEqual<Cardinal>($80000000, LBits);
  LValue := TWarTextLayout.CeilFloat(0);
  Move(LValue, LBits, 4);
  Assert.AreEqual<Cardinal>(0, LBits);
  Assert.AreEqual<Double>(3.0, Double(TWarTextLayout.CeilFloat(2.1)));
  Assert.AreEqual<Double>(-2.0, Double(TWarTextLayout.CeilFloat(-2.9)));
end;

procedure TTestWarTextLayout.DovrebbeMisurareUnaRigaSommandoLeLarghezze;
var
  LSize: TWarTextSize;
begin
  LSize := TWarTextLayout.MeasureSingle('AB', -1, FParams);
  Assert.AreEqual(Double(Advance('A') + Advance('B')), Double(LSize.X));
  Assert.AreEqual(Double(TWarTextLayout.GlyphOf(FParams.FontData, 'A').Height), Double(LSize.Y));
  LSize := TWarTextLayout.MeasureSingle('', -1, FParams);
  Assert.AreEqual<Double>(0.0, Double(LSize.X));
end;

procedure TTestWarTextLayout.DovrebbeMisurareSoloIPrimiCaratteri;
begin
  Assert.AreEqual(Double(Advance('A')), Double(TWarTextLayout.MeasureSingle('ABC', 1, FParams).X));
  Assert.AreEqual(Double(Advance('A') + Advance('B') + Advance('C')), Double(TWarTextLayout.MeasureSingle('ABC', 10, FParams).X));
  Assert.AreEqual<Double>(0.0, Double(TWarTextLayout.MeasureSingle('ABC', 0, FParams).X));
end;

procedure TTestWarTextLayout.DovrebbeContareUnATabulazioneComeDueSpazi;
var
  LSpace: Single;
begin
  LSpace := TWarTextLayout.GlyphOf(FParams.FontData, ' ').Width;
  Assert.AreEqual(Double(2 * LSpace + FParams.FontData.Advance), Double(TWarTextLayout.MeasureSingle(#9, -1, FParams).X));
end;

procedure TTestWarTextLayout.DovrebbeContareUnAcapoComeUnPassoDiAvanzamento;
begin
  Assert.AreEqual(Double(FParams.FontData.Advance), Double(TWarTextLayout.MeasureSingle(#10, -1, FParams).X));
  Assert.AreEqual<Double>(0.0, Double(TWarTextLayout.MeasureSingle(#10, -1, FParams).Y));
end;

procedure TTestWarTextLayout.DovrebbeScalareLaMisuraConLaDimensioneDelFont;
var
  LNormal: TWarTextSize;
  LHalf: TWarTextSize;
begin
  LNormal := TWarTextLayout.MeasureSingle('AB', -1, FParams);
  FParams.FontSize := FParams.FontSize / 2;
  LHalf := TWarTextLayout.MeasureSingle('AB', -1, FParams);
  Assert.AreEqual(Double(LNormal.X / 2), Double(LHalf.X));
  Assert.AreEqual(Double(LNormal.Y / 2), Double(LHalf.Y));
end;

procedure TTestWarTextLayout.DovrebbeDividereIlTestoAgliAcapo;
var
  LLines: TArray<TWarTextSpan>;
begin
  LLines := TWarTextLayout.SplitIntoLines('AB'#10'C'#10#10'D', WAR_MAX_LINES, 1000, FParams);
  Assert.AreEqual<Integer>(4, Length(LLines));
  Assert.AreEqual<Integer>(0, LLines[0].Start);
  Assert.AreEqual<Integer>(2, LLines[0].Length);
  Assert.AreEqual(Double(Advance('A') + Advance('B')), Double(LLines[0].Width));
  Assert.AreEqual<Integer>(3, LLines[1].Start);
  Assert.AreEqual<Integer>(0, LLines[2].Length);
  Assert.AreEqual<Integer>(1, LLines[3].Length);
  Assert.AreEqual<Integer>(0, Length(TWarTextLayout.SplitIntoLines('', WAR_MAX_LINES, 100, FParams)));
end;

procedure TTestWarTextLayout.DovrebbeANdareACapoDoveNonCeSpazioSeLInterruzioneEPerCarattere;
var
  LLines: TArray<TWarTextSpan>;
begin
  FParams.Wrapping := wtwChar;
  LLines := TWarTextLayout.SplitIntoLines('AAAA', WAR_MAX_LINES, Advance('A') * 2 + 1, FParams);
  Assert.AreEqual<Integer>(2, Length(LLines));
  Assert.AreEqual<Integer>(2, LLines[0].Length);
  Assert.AreEqual<Integer>(2, LLines[1].Start);
  Assert.AreEqual(Double(Advance('A') * 2), Double(LLines[1].Width));
  // a tab that does not fit goes to the next line
  LLines := TWarTextLayout.SplitIntoLines('AAAA'#9, WAR_MAX_LINES, Advance('A') * 4 + 1, FParams);
  Assert.AreEqual<Integer>(2, Length(LLines));
  Assert.AreEqual<Integer>(4, LLines[1].Start);
end;

procedure TTestWarTextLayout.NonDovrebbeAndareACapoSenzaInterruzione;
var
  LLines: TArray<TWarTextSpan>;
begin
  LLines := TWarTextLayout.SplitIntoLines('AAAA', WAR_MAX_LINES, 10, FParams);
  Assert.AreEqual<Integer>(1, Length(LLines));
  Assert.AreEqual<Integer>(4, LLines[0].Length);
end;

procedure TTestWarTextLayout.DovrebbeTagliareSpaziETabulazioniAgliEstremi;
var
  LLines: TArray<TWarTextSpan>;
begin
  FParams.Trimming := wttAll;
  LLines := TWarTextLayout.SplitIntoLines('  '#9'A '#9' ', WAR_MAX_LINES, 1000, FParams);
  Assert.AreEqual<Integer>(1, Length(LLines));
  Assert.AreEqual<Integer>(1, LLines[0].Length);
  Assert.AreEqual<Integer>(3, LLines[0].Start);
  // the width loses two spaces for each tab and not the width of the tab itself (a tab is two glyphs and one advance
  // wide): as in the original, the two tabs leave the width two advances short of the one of the A
  Assert.AreEqual(Double(Advance('A') - 2 * FParams.FontData.Advance), Double(LLines[0].Width));
  // a line of only spaces has nothing left
  LLines := TWarTextLayout.SplitIntoLines('   ', WAR_MAX_LINES, 1000, FParams);
  Assert.AreEqual<Integer>(0, LLines[0].Length);
end;

procedure TTestWarTextLayout.DovrebbeTagliareSoloGliSpaziSeLaPotaturaELimitata;
var
  LLines: TArray<TWarTextSpan>;
begin
  FParams.Trimming := wttSpaces;
  LLines := TWarTextLayout.SplitIntoLines(' '#9'A'#9' ', WAR_MAX_LINES, 1000, FParams);
  // the space at the start goes, the tab stops the cut; the tab before the space at the end stops it
  Assert.AreEqual<Integer>(1, LLines[0].Start);
  Assert.AreEqual<Integer>(3, LLines[0].Length);
end;

procedure TTestWarTextLayout.NonDovrebbeFareOltreIlNumeroMassimoDiRighe;
var
  LLines: TArray<TWarTextSpan>;
  LText: AnsiString;
  LIndex: Integer;
begin
  LText := '';
  for LIndex := 1 to 60 do
    LText := LText + 'A'#10;
  LLines := TWarTextLayout.SplitIntoLines(LText, WAR_MAX_LINES, 100, FParams);
  Assert.AreEqual<Integer>(WAR_MAX_LINES, Length(LLines));
  LLines := TWarTextLayout.SplitIntoLines(LText, 5, 100, FParams);
  Assert.AreEqual<Integer>(5, Length(LLines));
end;

procedure TTestWarTextLayout.DovrebbeMisurareLeRighe;
var
  LSize: TWarTextSize;
begin
  FParams.BoundingsX := 1000;
  LSize := TWarTextLayout.MeasureMulti('AB'#10'C', FParams);
  Assert.AreEqual(Double(Advance('A') + Advance('B')), Double(LSize.X));
  Assert.AreEqual<Double>(Double(FParams.FontData.LineHeight) * 2, Double(LSize.Y));
end;

procedure TTestWarTextLayout.DovrebbeUsareLAltezzaDiRigaDellaFont;
var
  LSize: TWarTextSize;
begin
  FParams.BoundingsX := 1000;
  FParams.LineHeight := FParams.FontData.LineHeight * 2;
  LSize := TWarTextLayout.MeasureMulti('A'#10'B', FParams);
  Assert.AreEqual<Double>(Double(FParams.FontData.LineHeight) * 4, Double(LSize.Y));
end;

procedure TTestWarTextLayout.DovrebbeAllinearePerOrizzontaleEVerticale;
var
  LSize: TWarTextSize;
  LOffset: TWarTextSize;
begin
  LSize.X := 100;
  LSize.Y := 30;
  LOffset := TWarTextLayout.AlignmentOffset(wtaLeft, wtaTop, 300, 100, LSize);
  Assert.AreEqual<Double>(0.0, Double(LOffset.X));
  Assert.AreEqual<Double>(0.0, Double(LOffset.Y));
  LOffset := TWarTextLayout.AlignmentOffset(wtaCenter, wtaMiddle, 300, 100, LSize);
  Assert.AreEqual<Double>(100.0, Double(LOffset.X));
  Assert.AreEqual<Double>(35.0, Double(LOffset.Y));
  // the right alignment is the same as the center in the original
  LOffset := TWarTextLayout.AlignmentOffset(wtaRight, wtaBottom, 300, 100, LSize);
  Assert.AreEqual<Double>(100.0, Double(LOffset.X));
  Assert.AreEqual<Double>(70.0, Double(LOffset.Y));
end;

procedure TTestWarTextLayout.DovrebbeAllinearePerRiga;
begin
  Assert.AreEqual<Double>(0.0, Double(TWarTextLayout.LineAlignmentOffset(wtaLeft, 100, 40)));
  Assert.AreEqual<Double>(30.0, Double(TWarTextLayout.LineAlignmentOffset(wtaCenter, 100, 40)));
  Assert.AreEqual<Double>(60.0, Double(TWarTextLayout.LineAlignmentOffset(wtaRight, 100, 40)));
  Assert.AreEqual<Double>(0.0, Double(TWarTextLayout.LineAlignmentOffset(wtaTop, 100, 40)));
end;

{ TTestWarTextRenderer }

procedure TTestWarTextRenderer.Setup;
begin
  FBlits := TList<TWarBlit>.Create;
  FTransform := TWarRenderTransform.Create(FBlits);
  FRenderer := TWarTextRenderer.Create(FTransform);
  FParams := DefaultParams;
end;

procedure TTestWarTextRenderer.TearDown;
begin
  FRenderer.Free;
  FTransform.Free;
  FBlits.Free;
end;

procedure TTestWarTextRenderer.DovrebbeFareUnBlitPerOgniGlifoEUnoNoPerLoSpazio;
begin
  FRenderer.RenderSingle('A B', 0, 0, FParams);
  Assert.AreEqual<Integer>(2, FBlits.Count);
  Assert.AreEqual<Integer>(Integer(FParams.FontData.Glyphs[33].X), Round(FBlits[0].Source.X));
  Assert.AreEqual<Integer>(Integer(FParams.FontData.Glyphs[34].X), Round(FBlits[1].Source.X));
end;

procedure TTestWarTextRenderer.DovrebbeMettereIGlifiUnoDopoLAltroConLAvanzamento;
var
  LFirstWidth: Single;
begin
  FRenderer.RenderSingle('AB', 5, 7, FParams);
  LFirstWidth := FParams.FontData.Glyphs[33].Width + FParams.FontData.Advance;
  Assert.AreEqual<Double>(5.0, Double(FBlits[0].Destination.X));
  Assert.AreEqual<Double>(7.0, Double(FBlits[0].Destination.Y));
  Assert.AreEqual(Double(5 + LFirstWidth), Double(FBlits[1].Destination.X));
end;

procedure TTestWarTextRenderer.DovrebbeUsareIlColoreDelTestoENonLasciarloAcceso;
begin
  FRenderer.RenderSingle('A', 0, 0, FParams);
  Assert.AreEqual<Integer>(10, FBlits[0].Color.R);
  Assert.AreEqual<Integer>(30, FBlits[0].Color.B);
  // the next image is drawn white again
  FTransform.SubImage(FBlits[0].Source, FBlits[0].Source, 1, 1);
  Assert.AreEqual<Integer>(255, FBlits[1].Color.R);
end;

procedure TTestWarTextRenderer.DovrebbeColorareLEvidenziazione;
begin
  FParams.HighlightIndex := 1;
  FParams.HighlightCount := 2;
  FRenderer.RenderSingle('ABCD', 0, 0, FParams);
  Assert.AreEqual<Integer>(4, FBlits.Count);
  Assert.AreEqual<Integer>(10, FBlits[0].Color.R);
  Assert.AreEqual<Integer>(200, FBlits[1].Color.R);
  Assert.AreEqual<Integer>(200, FBlits[2].Color.R);
  Assert.AreEqual<Integer>(10, FBlits[3].Color.R);
end;

procedure TTestWarTextRenderer.DovrebbeColorareTuttoConLEvidenziazioneTotale;
begin
  FParams.HighlightIndex := WAR_ALL_HIGHLIGHT;
  FRenderer.RenderSingle('AB', 0, 0, FParams);
  Assert.AreEqual<Integer>(200, FBlits[0].Color.R);
  Assert.AreEqual<Integer>(200, FBlits[1].Color.R);
end;

procedure TTestWarTextRenderer.DovrebbeSollevareEccezioneSeLEvidenziazioneVaOltreIlTesto;
begin
  FParams.HighlightIndex := 1;
  FParams.HighlightCount := 5;
  Assert.WillRaise(
    procedure
    begin
      FRenderer.RenderSingle('ABC', 0, 0, FParams);
    end, EWarException);
  FParams.HighlightIndex := 9;
  FParams.HighlightCount := 0;
  Assert.WillRaise(
    procedure
    begin
      FRenderer.RenderSingle('ABC', 0, 0, FParams);
    end, EWarException);
end;

procedure TTestWarTextRenderer.DovrebbeTrattareGliAcapoComeSpaziInUnaRiga;
begin
  FRenderer.RenderSingle('A'#10'B'#9'C', 0, 0, FParams);
  Assert.AreEqual<Integer>(3, FBlits.Count);
  Assert.IsTrue(FBlits[1].Destination.X > FBlits[0].Destination.X);
end;

procedure TTestWarTextRenderer.DovrebbeFermarsiAlBordoDelLimite;
begin
  FParams.BoundingsX := 5;
  FParams.BoundingsY := 1000;
  FRenderer.RenderSingle('AAAAAAAA', 0, 0, FParams);
  Assert.IsTrue(FBlits.Count < 8);
  Assert.IsTrue(FBlits.Count >= 1);
end;

procedure TTestWarTextRenderer.DovrebbeScalareIGlifiConLaDimensione;
begin
  FParams.FontSize := FParams.FontData.LineHeight * 2;
  FRenderer.RenderSingle('A', 10, 10, FParams);
  Assert.AreEqual<Double>(Double(FParams.FontData.Glyphs[33].Width) * 2, Double(FBlits[0].Destination.Width));
  Assert.AreEqual<Double>(10.0, Double(FBlits[0].Destination.X));
end;

procedure TTestWarTextRenderer.DovrebbeDisegnareUnaRigaPerVolta;
begin
  FParams.BoundingsX := 1000;
  FParams.BoundingsY := 1000;
  FRenderer.RenderMulti('A'#10'B', 0, 0, FParams);
  Assert.AreEqual<Integer>(2, FBlits.Count);
  Assert.AreEqual<Double>(0.0, Double(FBlits[0].Destination.Y));
  Assert.AreEqual(Double(FParams.FontData.LineHeight), Double(FBlits[1].Destination.Y));
end;

procedure TTestWarTextRenderer.DovrebbeFermarsiQuandoLeRigheSuperanoLaAltezza;
begin
  FParams.BoundingsX := 1000;
  FParams.BoundingsY := FParams.FontData.LineHeight;
  FRenderer.RenderMulti('A'#10'B'#10'C', 0, 0, FParams);
  Assert.AreEqual<Integer>(2, FBlits.Count);
end;

procedure TTestWarTextRenderer.DovrebbeEvidenziareTraPiuRighe;
begin
  FParams.BoundingsX := 1000;
  FParams.BoundingsY := 1000;
  FParams.HighlightIndex := 1;
  FParams.HighlightCount := 5;
  FRenderer.RenderMulti('ABC'#10'DEF', 0, 0, FParams);
  Assert.AreEqual<Integer>(6, FBlits.Count);
  Assert.AreEqual<Integer>(10, FBlits[0].Color.R);
  Assert.AreEqual<Integer>(200, FBlits[1].Color.R);
  Assert.AreEqual<Integer>(200, FBlits[2].Color.R);
  // the line feed is not counted in the position of the highlight (as in the original): it covers the second line
  Assert.AreEqual<Integer>(200, FBlits[3].Color.R);
  Assert.AreEqual<Integer>(200, FBlits[4].Color.R);
  Assert.AreEqual<Integer>(200, FBlits[5].Color.R);
  FBlits.Clear;
  FParams.HighlightIndex := WAR_ALL_HIGHLIGHT;
  FRenderer.RenderMulti('AB', 0, 0, FParams);
  Assert.AreEqual<Integer>(200, FBlits[0].Color.R);
end;

procedure TTestWarTextRenderer.DovrebbeTenereLaPilaInPareggio;
begin
  FRenderer.RenderSingle('AB', 0, 0, FParams);
  FParams.BoundingsX := 100;
  FParams.BoundingsY := 100;
  FRenderer.RenderMulti('AB'#10'CD', 0, 0, FParams);
  Assert.AreEqual<Integer>(0, FTransform.Depth);
end;

end.

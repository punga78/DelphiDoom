{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEndoomDrawing                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.Drawing;

interface

uses
  System.SysUtils, System.Types, DUnitX.TestFramework,
  DelphiDoom.Endoom.Intf, DelphiDoom.Tests.Endoom.EditorScenarios;

type
  /// <summary>
  ///   The DRAW lines of Tests\Data\Endoom\editor.golden.txt were written by the tools of the main window of
  ///   ENDEDIT (copied in Tools\Verifica\164\H2Old.pas) on the cases of TEditorScenarios.DrawCases: groups of
  ///   100 cases, one fingerprint of the 4000 bytes of each result
  /// </summary>
  [TestFixture]
  [Category('endoom')]
  TTestEndoomDrawing = class(TObject)
  strict private
    FScreen: IEndoomScreen;
    procedure CheckTool(ATool: Integer);
    function BackgroundsOf(AColor: Integer): Integer;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeSeguireLaLineaDelVecchioEditor;
    [Test]
    procedure DovrebbeTracciareUnaCellaSola;
    [Test]
    procedure DovrebbeTracciareUnaLineaOrizzontaleEUnaVerticale;
    [Test]
    procedure DovrebbeTracciareInEntrambiIVersi;
    [Test]
    procedure DovrebbeDisegnareUnaLinea;
    [Test]
    procedure DovrebbeDisegnareIlContornoDiUnRettangolo;
    [Test]
    procedure DovrebbeRiempireUnRettangolo;
    [Test]
    procedure DovrebbeDisegnareUnRettangoloAUnaRigaSola;
    [Test]
    procedure DovrebbeDisegnareUnaEllissePiena;
    [Test]
    procedure DovrebbeIgnorareLeCelleFuoriDalloSchermo;
    [Test]
    procedure DovrebbeRiempireSoloLAreaConnessa;
    [Test]
    procedure DovrebbeNonFareNullaSeIlColoreEGiaQuello;
    [Test]
    procedure DovrebbeRiempireUnIntero;
    [Test]
    procedure DovrebbeDisegnareLeCorniciDiCaratteri;
    [Test]
    procedure DovrebbeDareGliStessiRettangoliDelVecchioEditor;
    [Test]
    procedure DovrebbeDareGliStessiRettangoliPieniDelVecchioEditor;
    [Test]
    procedure DovrebbeDareLeStesseEllissiDelVecchioEditor;
    [Test]
    procedure DovrebbeDareLeStesseEllissiPieneDelVecchioEditor;
    [Test]
    procedure DovrebbeDareLeStesseLineeDelVecchioEditor;
    [Test]
    procedure DovrebbeDareLeStesseRiempimentiDelVecchioEditor;
    [Test]
    procedure DovrebbeDareLeStesseCorniciDelVecchioEditor;
  end;

implementation

uses
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.Factory, DelphiDoom.Endoom.Drawing,
  DelphiDoom.Tests.Endoom.Digest, DelphiDoom.Tests.Endoom.EditorHelper;

{ TTestEndoomDrawing }

procedure TTestEndoomDrawing.Setup;
begin
  FScreen := TEndoomFactory.CreateScreen;
end;

function TTestEndoomDrawing.BackgroundsOf(AColor: Integer): Integer;
var
  LX: Integer;
  LY: Integer;
begin
  Result := 0;
  for LY := 0 to ENDOOM_ROWS - 1 do
    for LX := 0 to ENDOOM_COLUMNS - 1 do
      if FScreen.GetBackground(LX, LY) = AColor then
        Inc(Result);
end;

procedure TTestEndoomDrawing.CheckTool(ATool: Integer);
const
  GROUPSIZE = 100;
var
  LGolden: TArray<string>;
  LCases: TArray<TEditorDrawCase>;
  LBase: IEndoomScreen;
  LAccumulated: TBytes;
  LBytes: TBytes;
  LCase: TEditorDrawCase;
  LIndex: Integer;
  LGroup: Integer;
  LWanted: string;

  function MatchTrue(const ALines: TArray<string>; const AValue: string): Boolean;
  var
    LLine: string;
  begin
    for LLine in ALines do
      if LLine = AValue then
        Exit(True);
    Result := False;
  end;

begin
  LGolden := TEditorHelper.GoldenLines('DRAW');
  LCases := TEditorScenarios.DrawCases(ATool);
  LBase := TEndoomFactory.CreateScreen;
  TEditorHelper.ApplyOps(LBase, TEditorScenarios.BaseOps);
  LGroup := 0;
  LAccumulated := nil;
  for LIndex := 0 to High(LCases) do
  begin
    LCase := LCases[LIndex];
    FScreen.AssignFrom(LBase);
    case ATool of
      EDITOR_TOOL_RECTANGLE:
        TEndoomDrawing.Rectangle(FScreen, LCase.DownX, LCase.DownY, LCase.UpX, LCase.UpY, LCase.Background);
      EDITOR_TOOL_FILL_RECTANGLE:
        TEndoomDrawing.FillRectangle(FScreen, LCase.DownX, LCase.DownY, LCase.UpX, LCase.UpY, LCase.Background);
      EDITOR_TOOL_ELLIPSE:
        TEndoomDrawing.EllipseOutline(FScreen, LCase.DownX, LCase.DownY, LCase.UpX, LCase.UpY, LCase.Background);
      EDITOR_TOOL_FILLED_ELLIPSE:
        TEndoomDrawing.EllipseFilled(FScreen, LCase.DownX, LCase.DownY, LCase.UpX, LCase.UpY, LCase.Background);
      EDITOR_TOOL_LINE:
        TEndoomDrawing.Line(FScreen, LCase.DownX, LCase.DownY, LCase.UpX, LCase.UpY, LCase.Background);
      EDITOR_TOOL_FLOOD_FILL:
        TEndoomDrawing.FloodFill(FScreen, LCase.DownX, LCase.DownY, LCase.Background);
    else
      TEndoomDrawing.CharacterFrame(FScreen, LCase.DownX, LCase.DownY, LCase.UpX, LCase.UpY,
        TEndoomFrameStyle(ATool - EDITOR_TOOL_FRAME), LCase.Foreground);
    end;
    LBytes := FScreen.ToBytes;
    SetLength(LAccumulated, Length(LAccumulated) + Length(LBytes));
    Move(LBytes[0], LAccumulated[Length(LAccumulated) - Length(LBytes)], Length(LBytes));
    if ((LIndex + 1) mod GROUPSIZE = 0) or (LIndex = High(LCases)) then
    begin
      LWanted := Format('%d %d %s', [ATool, LGroup, TEndoomDigest.OfBytes(LAccumulated)]);
      Assert.IsTrue(MatchTrue(LGolden, LWanted),
        Format('tool %d group %d (case %d): %s is not in the golden file', [ATool, LGroup, LIndex, LWanted]));
      Inc(LGroup);
      LAccumulated := nil;
    end;
  end;
  LWanted := IntToStr(ATool) + ' ';
  LGroup := 0;
  for LIndex := 0 to High(LGolden) do
    if LGolden[LIndex].StartsWith(LWanted) then
      Inc(LGroup);
  Assert.AreEqual((Length(LCases) + GROUPSIZE - 1) div GROUPSIZE, LGroup, 'groups of the golden file');
end;

procedure TTestEndoomDrawing.DovrebbeSeguireLaLineaDelVecchioEditor;
var
  LCells: TArray<TPoint>;
begin
  LCells := TEndoomDrawing.TraceCells(0, 0, 4, 2);
  Assert.AreEqual(5, Length(LCells));
  Assert.AreEqual(0, LCells[0].X);
  Assert.AreEqual(0, LCells[0].Y);
  Assert.AreEqual(4, LCells[4].X);
  Assert.AreEqual(2, LCells[4].Y);
end;

procedure TTestEndoomDrawing.DovrebbeTracciareUnaCellaSola;
var
  LCells: TArray<TPoint>;
begin
  LCells := TEndoomDrawing.TraceCells(7, 9, 7, 9);
  Assert.AreEqual(1, Length(LCells));
  Assert.AreEqual(7, LCells[0].X);
  Assert.AreEqual(9, LCells[0].Y);
end;

procedure TTestEndoomDrawing.DovrebbeTracciareUnaLineaOrizzontaleEUnaVerticale;
begin
  Assert.AreEqual(10, Length(TEndoomDrawing.TraceCells(2, 5, 11, 5)));
  Assert.AreEqual(8, Length(TEndoomDrawing.TraceCells(3, 1, 3, 8)));
end;

procedure TTestEndoomDrawing.DovrebbeTracciareInEntrambiIVersi;
var
  LCells: TArray<TPoint>;
begin
  LCells := TEndoomDrawing.TraceCells(10, 10, 4, 7);
  Assert.AreEqual(7, Length(LCells));
  Assert.AreEqual(10, LCells[0].X);
  Assert.AreEqual(4, LCells[High(LCells)].X);
  Assert.AreEqual(7, LCells[High(LCells)].Y);
end;

procedure TTestEndoomDrawing.DovrebbeDisegnareUnaLinea;
begin
  TEndoomDrawing.Line(FScreen, 0, 0, 10, 0, 4);
  Assert.AreEqual(11, BackgroundsOf(4));
  Assert.AreEqual(4, FScreen.GetBackground(5, 0));
end;

procedure TTestEndoomDrawing.DovrebbeDisegnareIlContornoDiUnRettangolo;
begin
  TEndoomDrawing.Rectangle(FScreen, 10, 10, 14, 13, 2);
  Assert.AreEqual(2 * 5 + 2 * 2, BackgroundsOf(2));
  Assert.AreEqual(0, FScreen.GetBackground(12, 11));
  Assert.AreEqual(2, FScreen.GetBackground(10, 11));
end;

procedure TTestEndoomDrawing.DovrebbeRiempireUnRettangolo;
begin
  TEndoomDrawing.FillRectangle(FScreen, 14, 13, 10, 10, 2);
  Assert.AreEqual(5 * 4, BackgroundsOf(2));
end;

procedure TTestEndoomDrawing.DovrebbeDisegnareUnRettangoloAUnaRigaSola;
begin
  TEndoomDrawing.Rectangle(FScreen, 3, 3, 9, 3, 5);
  Assert.AreEqual(7, BackgroundsOf(5));
end;

procedure TTestEndoomDrawing.DovrebbeDisegnareUnaEllissePiena;
begin
  TEndoomDrawing.EllipseFilled(FScreen, 40, 12, 50, 17, 3);
  Assert.AreEqual(3, FScreen.GetBackground(40, 12));
  Assert.AreEqual(3, FScreen.GetBackground(40, 7));
  Assert.AreEqual(0, FScreen.GetBackground(60, 12));
  // the outline of the same ellipse leaves the middle alone
  FScreen.Clear;
  TEndoomDrawing.EllipseOutline(FScreen, 40, 12, 50, 17, 3);
  Assert.AreEqual(0, FScreen.GetBackground(40, 12));
  Assert.AreEqual(3, FScreen.GetBackground(40, 7));
end;

procedure TTestEndoomDrawing.DovrebbeIgnorareLeCelleFuoriDalloSchermo;
begin
  TEndoomDrawing.Line(FScreen, -5, -5, 3, 3, 1);
  Assert.AreEqual(1, FScreen.GetBackground(0, 0));
  Assert.AreEqual(1, FScreen.GetBackground(3, 3));
  TEndoomDrawing.Rectangle(FScreen, 70, 20, 100, 40, 2);
  TEndoomDrawing.CharacterFrame(FScreen, 75, 20, 90, 30, efsSingle, 4);
  Assert.AreEqual(2, FScreen.GetBackground(70, 20));
  Assert.AreEqual(Integer($DA), Integer(FScreen.GetCharacter(75, 20)));
  FScreen.Clear;
  TEndoomDrawing.EllipseFilled(FScreen, 0, 0, 30, 20, 3);
  Assert.AreEqual(3, FScreen.GetBackground(0, 0));
  Assert.AreEqual(3, FScreen.GetBackground(10, 5));
end;

procedure TTestEndoomDrawing.DovrebbeRiempireSoloLAreaConnessa;
begin
  TEndoomDrawing.Rectangle(FScreen, 10, 5, 20, 15, 1);
  TEndoomDrawing.FloodFill(FScreen, 15, 10, 6);
  Assert.AreEqual(6, FScreen.GetBackground(11, 6));
  Assert.AreEqual(1, FScreen.GetBackground(10, 5));
  Assert.AreEqual(0, FScreen.GetBackground(5, 5));
  Assert.AreEqual(9 * 9, BackgroundsOf(6));
end;

procedure TTestEndoomDrawing.DovrebbeNonFareNullaSeIlColoreEGiaQuello;
begin
  TEndoomDrawing.FloodFill(FScreen, 3, 3, 0);
  Assert.AreEqual(ENDOOM_CELLS, BackgroundsOf(0));
end;

procedure TTestEndoomDrawing.DovrebbeRiempireUnIntero;
begin
  TEndoomDrawing.FloodFill(FScreen, 0, 0, 7);
  Assert.AreEqual(ENDOOM_CELLS, BackgroundsOf(7));
  TEndoomDrawing.FloodFill(FScreen, -1, 0, 1);
  TEndoomDrawing.FloodFill(FScreen, 0, 25, 1);
  Assert.AreEqual(ENDOOM_CELLS, BackgroundsOf(7));
end;

procedure TTestEndoomDrawing.DovrebbeDisegnareLeCorniciDiCaratteri;
begin
  TEndoomDrawing.CharacterFrame(FScreen, 2, 2, 6, 5, efsDouble, 14);
  Assert.AreEqual(Integer($C9), Integer(FScreen.GetCharacter(2, 2)));
  Assert.AreEqual(Integer($BB), Integer(FScreen.GetCharacter(6, 2)));
  Assert.AreEqual(Integer($C8), Integer(FScreen.GetCharacter(2, 5)));
  Assert.AreEqual(Integer($BC), Integer(FScreen.GetCharacter(6, 5)));
  Assert.AreEqual(Integer($CD), Integer(FScreen.GetCharacter(4, 2)));
  Assert.AreEqual(Integer($BA), Integer(FScreen.GetCharacter(2, 3)));
  Assert.AreEqual(14, FScreen.GetForeground(4, 5));
  Assert.AreEqual(0, Integer(FScreen.GetCharacter(4, 3)));
  TEndoomDrawing.CharacterFrame(FScreen, 10, 10, 12, 12, efsBlock, 1);
  Assert.AreEqual(Integer($DB), Integer(FScreen.GetCharacter(11, 10)));
  TEndoomDrawing.CharacterFrame(FScreen, 20, 10, 22, 12, efsDoubleHorizontal, 1);
  Assert.AreEqual(Integer($D5), Integer(FScreen.GetCharacter(20, 10)));
  TEndoomDrawing.CharacterFrame(FScreen, 30, 10, 32, 12, efsDoubleVertical, 1);
  Assert.AreEqual(Integer($D6), Integer(FScreen.GetCharacter(30, 10)));
end;

procedure TTestEndoomDrawing.DovrebbeDareGliStessiRettangoliDelVecchioEditor;
begin
  CheckTool(EDITOR_TOOL_RECTANGLE);
end;

procedure TTestEndoomDrawing.DovrebbeDareGliStessiRettangoliPieniDelVecchioEditor;
begin
  CheckTool(EDITOR_TOOL_FILL_RECTANGLE);
end;

procedure TTestEndoomDrawing.DovrebbeDareLeStesseEllissiDelVecchioEditor;
begin
  CheckTool(EDITOR_TOOL_ELLIPSE);
end;

procedure TTestEndoomDrawing.DovrebbeDareLeStesseEllissiPieneDelVecchioEditor;
begin
  CheckTool(EDITOR_TOOL_FILLED_ELLIPSE);
end;

procedure TTestEndoomDrawing.DovrebbeDareLeStesseLineeDelVecchioEditor;
begin
  CheckTool(EDITOR_TOOL_LINE);
end;

procedure TTestEndoomDrawing.DovrebbeDareLeStesseRiempimentiDelVecchioEditor;
begin
  CheckTool(EDITOR_TOOL_FLOOD_FILL);
end;

procedure TTestEndoomDrawing.DovrebbeDareLeStesseCorniciDelVecchioEditor;
var
  LStyle: Integer;
begin
  for LStyle := 0 to 4 do
    CheckTool(EDITOR_TOOL_FRAME + LStyle);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEndoomScreen                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.Screen;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.Intf;

type
  /// <summary>
  ///   The MODEL and LOAD lines of Tests\Data\Endoom\editor.golden.txt were written by the TEndScreen of
  ///   ENDEDIT (ee_screen.pas) on the changes of cells of TEditorScenarios (Tools\Verifica\164\H2.dpr)
  /// </summary>
  [TestFixture]
  [Category('endoom')]
  TTestEndoomScreen = class(TObject)
  strict private
    FScreen: IEndoomScreen;
    procedure ExpectError(const AProc: TProc);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeEssereVuotaAllaNascita;
    [Test]
    procedure DovrebbeTenereIlCarattereIColoriEIlLampeggio;
    [Test]
    procedure DovrebbeCambiareUnSoloCampoDellAttributo;
    [Test]
    procedure DovrebbeRifiutareUnaCellaFuoriDalloSchermo;
    [Test]
    procedure DovrebbeRifiutareUnColoreCheNonEsiste;
    [Test]
    procedure DovrebbeSvuotareTutto;
    [Test]
    procedure DovrebbeRiempireSfondoPrimoPianoECarattere;
    [Test]
    procedure DovrebbeIgnorareLaParteFuoriDalloSchermoNeiRiempimenti;
    [Test]
    procedure DovrebbeRiempireConGliAngoliInQualsiasiOrdine;
    [Test]
    procedure DovrebbeCopiareEIncollareUnBlocco;
    [Test]
    procedure DovrebbeTagliareUnBloccoCheEscePerLoSchermo;
    [Test]
    procedure DovrebbeDareUnBloccoVuotoFuoriDalloSchermo;
    [Test]
    procedure DovrebbeRifiutareUnBloccoCoerente;
    [Test]
    procedure DovrebbeDareLeQuattromilaByteDelLump;
    [Test]
    procedure DovrebbeLeggereLeQuattromilaByteDiUnFile;
    [Test]
    procedure DovrebbeLeggereSoloLeQuattromilaByteDiUnFilePiuLungo;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeCopiareUnaSchermataEConfrontarla;
    [Test]
    procedure DovrebbeRifiutareUnaSorgenteNil;
    [Test]
    procedure DovrebbeAvereLaCellaDiDueByte;
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioTEndScreen;
    [Test]
    procedure DovrebbeLeggereGliStessiByteDelVecchioTEndScreen;
  end;

implementation

uses
  DelphiDoom.Endoom.EditorFactory, DelphiDoom.Endoom.Screen,
  DelphiDoom.Tests.Endoom.Digest, DelphiDoom.Tests.Endoom.Fixtures, DelphiDoom.Tests.Endoom.EditorScenarios,
  DelphiDoom.Tests.Endoom.EditorHelper;

{ TTestEndoomScreen }

procedure TTestEndoomScreen.Setup;
begin
  FScreen := TEndoomEditorFactory.CreateScreen;
end;

procedure TTestEndoomScreen.ExpectError(const AProc: TProc);
begin
  Assert.WillRaise(AProc, EEndoomException);
end;

procedure TTestEndoomScreen.DovrebbeEssereVuotaAllaNascita;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  LBytes := FScreen.ToBytes;
  Assert.AreEqual(ENDOOM_LUMP_SIZE, Length(LBytes));
  for LIndex := 0 to High(LBytes) do
    Assert.AreEqual(0, Integer(LBytes[LIndex]));
end;

procedure TTestEndoomScreen.DovrebbeTenereIlCarattereIColoriEIlLampeggio;
begin
  FScreen.SetCharacter(3, 4, 65);
  FScreen.SetForeground(3, 4, 14);
  FScreen.SetBackground(3, 4, 5);
  FScreen.SetBlink(3, 4, True);
  Assert.AreEqual(65, Integer(FScreen.GetCharacter(3, 4)));
  Assert.AreEqual(14, FScreen.GetForeground(3, 4));
  Assert.AreEqual(5, FScreen.GetBackground(3, 4));
  Assert.IsTrue(FScreen.GetBlink(3, 4));
  Assert.AreEqual(65, Integer(FScreen.GetCell(3, 4).Code));
  Assert.AreEqual($80 or $50 or $0E, Integer(FScreen.GetCell(3, 4).Attributes));
  Assert.AreEqual(0, Integer(FScreen.GetCell(4, 4).Code));
end;

procedure TTestEndoomScreen.DovrebbeCambiareUnSoloCampoDellAttributo;
begin
  FScreen.SetForeground(0, 0, 15);
  FScreen.SetBackground(0, 0, 7);
  FScreen.SetBlink(0, 0, True);
  FScreen.SetForeground(0, 0, 1);
  Assert.AreEqual(7, FScreen.GetBackground(0, 0));
  Assert.IsTrue(FScreen.GetBlink(0, 0));
  FScreen.SetBackground(0, 0, 2);
  Assert.AreEqual(1, FScreen.GetForeground(0, 0));
  FScreen.SetBlink(0, 0, False);
  Assert.IsFalse(FScreen.GetBlink(0, 0));
  Assert.AreEqual(2, FScreen.GetBackground(0, 0));
  Assert.AreEqual(1, FScreen.GetForeground(0, 0));
end;

procedure TTestEndoomScreen.DovrebbeRifiutareUnaCellaFuoriDalloSchermo;
begin
  ExpectError(procedure begin FScreen.GetCell(-1, 0); end);
  ExpectError(procedure begin FScreen.GetCell(80, 0); end);
  ExpectError(procedure begin FScreen.GetCharacter(0, 25); end);
  ExpectError(procedure begin FScreen.SetCharacter(0, -1, 1); end);
  ExpectError(procedure begin FScreen.SetBlink(80, 25, True); end);
  ExpectError(procedure begin FScreen.GetForeground(99, 0); end);
  ExpectError(procedure begin FScreen.GetBackground(0, 99); end);
  ExpectError(procedure begin FScreen.SetCell(80, 0, Default(TEndoomCell)); end);
end;

procedure TTestEndoomScreen.DovrebbeRifiutareUnColoreCheNonEsiste;
begin
  ExpectError(procedure begin FScreen.SetForeground(0, 0, 16); end);
  ExpectError(procedure begin FScreen.SetForeground(0, 0, -1); end);
  ExpectError(procedure begin FScreen.SetBackground(0, 0, 8); end);
  ExpectError(procedure begin FScreen.FillBackground(TEndoomRect.Between(0, 0, 1, 1), 8); end);
  ExpectError(procedure begin FScreen.FillForeground(TEndoomRect.Between(0, 0, 1, 1), 16); end);
end;

procedure TTestEndoomScreen.DovrebbeSvuotareTutto;
begin
  FScreen.SetCharacter(10, 10, 1);
  FScreen.SetBlink(79, 24, True);
  FScreen.Clear;
  Assert.AreEqual(0, Integer(FScreen.GetCharacter(10, 10)));
  Assert.IsFalse(FScreen.GetBlink(79, 24));
end;

procedure TTestEndoomScreen.DovrebbeRiempireSfondoPrimoPianoECarattere;
var
  LRect: TEndoomRect;
begin
  LRect := TEndoomRect.Between(2, 3, 4, 5);
  FScreen.FillBackground(LRect, 6);
  FScreen.FillForeground(LRect, 9);
  FScreen.FillCharacter(LRect, 177);
  Assert.AreEqual(6, FScreen.GetBackground(2, 3));
  Assert.AreEqual(6, FScreen.GetBackground(4, 5));
  Assert.AreEqual(9, FScreen.GetForeground(3, 4));
  Assert.AreEqual(177, Integer(FScreen.GetCharacter(4, 3)));
  Assert.AreEqual(0, FScreen.GetBackground(5, 3));
  Assert.AreEqual(0, Integer(FScreen.GetCharacter(1, 3)));
  Assert.AreEqual(0, FScreen.GetForeground(2, 6));
end;

procedure TTestEndoomScreen.DovrebbeIgnorareLaParteFuoriDalloSchermoNeiRiempimenti;
begin
  FScreen.FillBackground(TEndoomRect.Between(78, 23, 90, 40), 3);
  Assert.AreEqual(3, FScreen.GetBackground(79, 24));
  Assert.AreEqual(3, FScreen.GetBackground(78, 23));
  Assert.AreEqual(0, FScreen.GetBackground(77, 23));
  FScreen.FillCharacter(TEndoomRect.Between(-5, -5, 0, 0), 7);
  Assert.AreEqual(7, Integer(FScreen.GetCharacter(0, 0)));
  // a rectangle that is all outside does nothing
  FScreen.FillForeground(TEndoomRect.Between(100, 100, 120, 120), 5);
  FScreen.FillCharacter(TEndoomRect.Between(-9, 3, -2, 4), 9);
  Assert.AreEqual(0, Integer(FScreen.GetCharacter(0, 3)));
end;

procedure TTestEndoomScreen.DovrebbeRiempireConGliAngoliInQualsiasiOrdine;
begin
  FScreen.FillBackground(TEndoomRect.Between(5, 5, 3, 3), 4);
  Assert.AreEqual(4, FScreen.GetBackground(3, 3));
  Assert.AreEqual(4, FScreen.GetBackground(5, 5));
  Assert.AreEqual(3, TEndoomRect.Between(5, 5, 3, 3).Width);
  Assert.AreEqual(3, TEndoomRect.Between(5, 5, 3, 3).Height);
  Assert.IsTrue(TEndoomRect.Between(5, 5, 3, 3).Contains(4, 4));
  Assert.IsFalse(TEndoomRect.Between(5, 5, 3, 3).Contains(6, 4));
  Assert.IsFalse(TEndoomRect.Between(5, 5, 3, 3).Contains(4, 2));
end;

procedure TTestEndoomScreen.DovrebbeCopiareEIncollareUnBlocco;
var
  LBlock: TEndoomBlock;
begin
  FScreen.SetCharacter(10, 10, 65);
  FScreen.SetBackground(11, 10, 3);
  FScreen.SetForeground(10, 11, 12);
  LBlock := FScreen.CopyBlock(TEndoomRect.Between(10, 10, 11, 11));
  Assert.AreEqual(2, LBlock.Width);
  Assert.AreEqual(2, LBlock.Height);
  Assert.AreEqual(4, Length(LBlock.Cells));
  FScreen.PasteBlock(LBlock, 50, 20);
  Assert.AreEqual(65, Integer(FScreen.GetCharacter(50, 20)));
  Assert.AreEqual(3, FScreen.GetBackground(51, 20));
  Assert.AreEqual(12, FScreen.GetForeground(50, 21));
  // the source is not changed
  Assert.AreEqual(65, Integer(FScreen.GetCharacter(10, 10)));
end;

procedure TTestEndoomScreen.DovrebbeTagliareUnBloccoCheEscePerLoSchermo;
var
  LBlock: TEndoomBlock;
begin
  FScreen.SetCharacter(79, 24, 9);
  LBlock := FScreen.CopyBlock(TEndoomRect.Between(78, 23, 85, 30));
  Assert.AreEqual(2, LBlock.Width);
  Assert.AreEqual(2, LBlock.Height);
  Assert.AreEqual(9, Integer(LBlock.Cells[3].Code));
  // pasted over the edge, only what fits stays
  FScreen.PasteBlock(LBlock, 79, 24);
  Assert.AreEqual(0, Integer(FScreen.GetCharacter(79, 24)));
  FScreen.PasteBlock(LBlock, -1, -1);
  Assert.AreEqual(9, Integer(FScreen.GetCharacter(0, 0)));
end;

procedure TTestEndoomScreen.DovrebbeDareUnBloccoVuotoFuoriDalloSchermo;
var
  LBlock: TEndoomBlock;
begin
  LBlock := FScreen.CopyBlock(TEndoomRect.Between(90, 30, 95, 35));
  Assert.AreEqual(0, LBlock.Width);
  Assert.AreEqual(0, Length(LBlock.Cells));
  FScreen.PasteBlock(LBlock, 0, 0);
  Assert.AreEqual(0, Integer(FScreen.GetCharacter(0, 0)));
end;

procedure TTestEndoomScreen.DovrebbeRifiutareUnBloccoCoerente;
var
  LBlock: TEndoomBlock;
begin
  LBlock.Width := 3;
  LBlock.Height := 2;
  SetLength(LBlock.Cells, 5);
  ExpectError(procedure begin FScreen.PasteBlock(LBlock, 0, 0); end);
end;

procedure TTestEndoomScreen.DovrebbeDareLeQuattromilaByteDelLump;
var
  LBytes: TBytes;
begin
  FScreen.SetCharacter(1, 0, 66);
  FScreen.SetBackground(1, 0, 1);
  LBytes := FScreen.ToBytes;
  // the second cell: the character and the attribute, row after row
  Assert.AreEqual(66, Integer(LBytes[2]));
  Assert.AreEqual($10, Integer(LBytes[3]));
  FScreen.SetCharacter(0, 1, 67);
  Assert.AreEqual(67, Integer(FScreen.ToBytes[ENDOOM_COLUMNS * 2]));
end;

procedure TTestEndoomScreen.DovrebbeLeggereLeQuattromilaByteDiUnFile;
var
  LOther: IEndoomScreen;
begin
  LOther := TEndoomEditorFactory.CreateScreen;
  LOther.LoadFromBytes(TEndoomFixtures.Screen(2));
  Assert.AreEqual(TEndoomDigest.OfBytes(TEndoomFixtures.Screen(2)), TEndoomDigest.OfBytes(LOther.ToBytes));
end;

procedure TTestEndoomScreen.DovrebbeLeggereSoloLeQuattromilaByteDiUnFilePiuLungo;
var
  LBytes: TBytes;
begin
  LBytes := TEndoomFixtures.Screen(0);
  SetLength(LBytes, ENDOOM_LUMP_SIZE + 100);
  LBytes[ENDOOM_LUMP_SIZE] := 99;
  FScreen.LoadFromBytes(LBytes);
  Assert.AreEqual(ENDOOM_LUMP_SIZE, Length(FScreen.ToBytes));
end;

procedure TTestEndoomScreen.DovrebbeRifiutareUnFileTroppoCorto;
begin
  ExpectError(procedure begin FScreen.LoadFromBytes(nil); end);
  ExpectError(procedure begin FScreen.LoadFromBytes(TBytes.Create(1, 2, 3)); end);
  Assert.WillRaise(
    procedure
    var
      LBytes: TBytes;
    begin
      SetLength(LBytes, ENDOOM_LUMP_SIZE - 1);
      FScreen.LoadFromBytes(LBytes);
    end, EEndoomException);
end;

procedure TTestEndoomScreen.DovrebbeCopiareUnaSchermataEConfrontarla;
var
  LCopy: IEndoomScreen;
begin
  LCopy := TEndoomEditorFactory.CreateScreen;
  FScreen.SetCharacter(5, 5, 5);
  Assert.IsFalse(FScreen.IsSameAs(LCopy));
  LCopy.AssignFrom(FScreen);
  Assert.IsTrue(FScreen.IsSameAs(LCopy));
  LCopy.SetBlink(0, 0, True);
  Assert.IsFalse(FScreen.IsSameAs(LCopy));
  Assert.IsFalse(FScreen.IsSameAs(nil));
  // AssignFrom copies the other into this one: the source does not change
  Assert.AreEqual(5, Integer(FScreen.GetCharacter(5, 5)));
end;

procedure TTestEndoomScreen.DovrebbeRifiutareUnaSorgenteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      FScreen.AssignFrom(nil);
    end, EArgumentNilException);
end;

procedure TTestEndoomScreen.DovrebbeAvereLaCellaDiDueByte;
begin
  Assert.AreEqual(2, SizeOf(TEndoomCell));
  Assert.AreEqual(ENDOOM_LUMP_SIZE, ENDOOM_CELLS * SizeOf(TEndoomCell));
end;

procedure TTestEndoomScreen.DovrebbeDareGliStessiByteDelVecchioTEndScreen;
var
  LGolden: TArray<string>;
  LSeed: Integer;
  LScreen: IEndoomScreen;
begin
  LGolden := TEditorHelper.GoldenLines('MODEL');
  Assert.AreEqual(6, Length(LGolden));
  for LSeed := 1 to 6 do
  begin
    LScreen := TEndoomEditorFactory.CreateScreen;
    TEditorHelper.ApplyOps(LScreen, TEditorScenarios.ModelOps(Cardinal(LSeed * 1000 + 7), 600 * LSeed));
    Assert.AreEqual(Format('%d %s', [LSeed, TEndoomDigest.OfBytes(LScreen.ToBytes)]), LGolden[LSeed - 1]);
  end;
end;

procedure TTestEndoomScreen.DovrebbeLeggereGliStessiByteDelVecchioTEndScreen;
var
  LGolden: TArray<string>;
  LKind: Integer;
begin
  LGolden := TEditorHelper.GoldenLines('LOAD');
  Assert.AreEqual(3, Length(LGolden));
  for LKind := 0 to 2 do
  begin
    FScreen.LoadFromBytes(TEndoomFixtures.Screen(LKind));
    Assert.AreEqual(Format('%d %s', [LKind, TEndoomDigest.OfBytes(FScreen.ToBytes)]), LGolden[LKind]);
  end;
end;

end.

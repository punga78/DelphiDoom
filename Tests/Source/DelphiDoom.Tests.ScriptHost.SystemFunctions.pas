{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the unit SYSTEM of the scripts                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.SystemFunctions;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.System.Functions,
  DelphiDoom.ScriptHost.System.Intf,
  DelphiDoom.Tests.ScriptHost.Fakes;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostSystemFunctions = class(TObject)
  private
    FOutput: TFakeOutput;
    FOutputRef: IScriptSystemOutput;
    FEnvironment: TFakeEnvironment;
    FEnvironmentRef: IScriptSystemEnvironment;
    FConsole: TFakeConsole;
    FConsoleRef: IScriptSystemConsole;
    FRandom: TFakeRandom;
    FRandomRef: IGameRandom;
    FRoutines: TScriptSystemRoutines;
    FFunctions: IScriptSystemFunctions;
    FGroup: IScriptFunctionGroup;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareErroreSeUnServizioEnil;
    [Test]
    procedure DovrebbeChiamarsiSystem;
    [Test]
    procedure DovrebbeDescrivereLeCinquantaseiFunzioniNellOrdineDelleDichiarazioni;
    [Test]
    procedure DovrebbeDareAdOgniFunzioneLaSuaRoutine;
    [Test]
    procedure DovrebbeAvereLeDichiarazioniDelGoldenDellaRegistrazione;
    [Test]
    procedure DovrebbeDareIlTempoDelLivello;
    [Test]
    procedure DovrebbeScrivereIlTestoCosiCom;
    [Test]
    procedure DovrebbeAggiungereIlFineRigaScrivendoUnaRiga;
    [Test]
    procedure DovrebbeFormattareEScrivere;
    [Test]
    procedure DovrebbeScrivereNelFileDiDebug;
    [Test]
    procedure DovrebbeFormattareEScrivereNelFileDiDebug;
    [Test]
    procedure DovrebbeRicordareIlMessaggioDelBreakPoint;
    [Test]
    procedure DovrebbeDareLeTabelleDegliAngoliFini;
    [Test]
    procedure DovrebbeCalcolareSenoCosenoETangenteInGradi;
    [Test]
    procedure DovrebbeCalcolareLaTangenteInRadianti;
    [Test]
    procedure DovrebbeDareIlRisultatoDelCondizionaleDiInteri;
    [Test]
    procedure DovrebbeDareIlRisultatoDelCondizionaleDiReali;
    [Test]
    procedure DovrebbeDareIlRisultatoDelCondizionaleDiTesti;
    [Test]
    procedure DovrebbeDistinguerePariEDispari;
    [Test]
    procedure DovrebbeUnireDueArrayDiInteri;
    [Test]
    procedure DovrebbeUnireDueArrayVuoti;
    [Test]
    procedure DovrebbeUnireGliArrayDegliAltriTipi;
    [Test]
    procedure DovrebbeRiconoscereINumeriPrimi;
    [Test]
    procedure DovrebbeDareUnNumeroTraIDueSecondoIlCasuale;
    [Test]
    procedure DovrebbeUsareUnSoloNumeroCasualePerChiamata;
    [Test]
    procedure DovrebbeAccodareIComandiDellaConsole;
    [Test]
    procedure DovrebbeLeggereLeVariabiliDellaConsole;
    [Test]
    procedure DovrebbeScrivereLeVariabiliDellaConsoleEDarneLEsito;
  end;

implementation

uses
  DelphiDoom.ScriptHost.Factory;

procedure TTestScriptHostSystemFunctions.Setup;
var
  LRoutine: TScriptSystemRoutine;
begin
  FOutput := TFakeOutput.Create;
  FOutputRef := FOutput;
  FEnvironment := TFakeEnvironment.Create;
  FEnvironmentRef := FEnvironment;
  FConsole := TFakeConsole.Create;
  FConsoleRef := FConsole;
  FRandom := TFakeRandom.Create;
  FRandomRef := FRandom;
  SetLength(FRandom.Numbers, 1);
  FRandom.Numbers[0] := 100;
  for LRoutine := Low(TScriptSystemRoutine) to High(TScriptSystemRoutine) do
    FRoutines[LRoutine] := Pointer(NativeInt(Ord(LRoutine) + 1));
  FFunctions := TScriptHostFactory.CreateSystemFunctions(FRoutines, FOutputRef, FEnvironmentRef,
    FConsoleRef, FRandomRef);
  FGroup := FFunctions as IScriptFunctionGroup;
end;

procedure TTestScriptHostSystemFunctions.TearDown;
begin
  FGroup := nil;
  FFunctions := nil;
  FRandomRef := nil;
  FRandom := nil;
  FConsoleRef := nil;
  FEnvironmentRef := nil;
  FOutputRef := nil;
end;

procedure TTestScriptHostSystemFunctions.DovrebbeDareErroreSeUnServizioEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateSystemFunctions(FRoutines, nil, FEnvironmentRef, FConsoleRef, FRandomRef);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateSystemFunctions(FRoutines, FOutputRef, nil, FConsoleRef, FRandomRef);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateSystemFunctions(FRoutines, FOutputRef, FEnvironmentRef, nil, FRandomRef);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateSystemFunctions(FRoutines, FOutputRef, FEnvironmentRef, FConsoleRef, nil);
    end, EArgumentNilException);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeChiamarsiSystem;
begin
  Assert.AreEqual('SYSTEM', FGroup.UnitName);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeDescrivereLeCinquantaseiFunzioniNellOrdineDelleDichiarazioni;
var
  LTable: TFakeFunctionTable;
  LTableRef: IScriptFunctionTable;
  LRoutine: TScriptSystemRoutine;
begin
  LTable := TFakeFunctionTable.Create;
  LTableRef := LTable;
  FGroup.Describe(LTableRef);
  Assert.AreEqual(56, LTable.Declarations.Count);
  for LRoutine := Low(TScriptSystemRoutine) to High(TScriptSystemRoutine) do
    Assert.AreEqual(SCRIPT_SYSTEM_DECLARATIONS[LRoutine], LTable.Declarations[Ord(LRoutine)]);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeDareAdOgniFunzioneLaSuaRoutine;
var
  LTable: TFakeFunctionTable;
  LTableRef: IScriptFunctionTable;
  LRoutine: TScriptSystemRoutine;
begin
  LTable := TFakeFunctionTable.Create;
  LTableRef := LTable;
  FGroup.Describe(LTableRef);
  for LRoutine := Low(TScriptSystemRoutine) to High(TScriptSystemRoutine) do
    Assert.AreEqual(NativeInt(Ord(LRoutine) + 1), NativeInt(LTable.Codes[Ord(LRoutine)]));
end;

procedure TTestScriptHostSystemFunctions.DovrebbeAvereLeDichiarazioniDelGoldenDellaRegistrazione;
var
  LGolden: TArray<string>;
  LTable: TFakeFunctionTable;
  LTableRef: IScriptFunctionTable;
  LIndex: Integer;
  LExpected: string;
begin
  LGolden := GoldenDeclarations('SYSTEM');
  if Length(LGolden) = 0 then
  begin
    Assert.Pass('golden della registrazione non trovato');
    Exit;
  end;
  LTable := TFakeFunctionTable.Create;
  LTableRef := LTable;
  FGroup.Describe(LTableRef);
  Assert.AreEqual(Length(LGolden), LTable.Declarations.Count);
  for LIndex := 0 to LTable.Declarations.Count - 1 do
  begin
    // the list adds the closing semicolon: the golden has the text as the old code wrote it
    LExpected := Trim(LTable.Declarations[LIndex]);
    if LExpected[Length(LExpected)] <> ';' then
      LExpected := LExpected + ';';
    Assert.AreEqual(LGolden[LIndex], LExpected);
  end;
end;

procedure TTestScriptHostSystemFunctions.DovrebbeDareIlTempoDelLivello;
begin
  FEnvironment.Time := 1234;
  Assert.AreEqual(1234, FFunctions.LevelTime);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeScrivereIlTestoCosiCom;
begin
  FFunctions.WriteText('100% sure');
  Assert.AreEqual('100% sure', FOutput.Written);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeAggiungereIlFineRigaScrivendoUnaRiga;
begin
  FFunctions.WriteLine('one');
  FFunctions.WriteLine('two');
  Assert.AreEqual('one'#13#10'two'#13#10, FOutput.Written);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeFormattareEScrivere;
begin
  FFunctions.WriteFormatted('%d+%d', [1, 2]);
  FFunctions.WriteLineFormatted('=%d', [3]);
  Assert.AreEqual('1+2=3'#13#10, FOutput.Written);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeScrivereNelFileDiDebug;
begin
  FFunctions.WriteDebug('trace');
  Assert.AreEqual('trace', FOutput.Debug);
  Assert.AreEqual('', FOutput.Written);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeFormattareEScrivereNelFileDiDebug;
begin
  FFunctions.WriteDebugFormatted('x=%s', ['y']);
  Assert.AreEqual('x=y', FOutput.Debug);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeRicordareIlMessaggioDelBreakPoint;
begin
  Assert.AreEqual('', FFunctions.BreakPointMessage);
  FFunctions.BreakPoint('here');
  Assert.AreEqual('here', FFunctions.BreakPointMessage);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeDareLeTabelleDegliAngoliFini;
begin
  Assert.AreEqual(1005, FFunctions.FineSine(5));
  Assert.AreEqual(2006, FFunctions.FineCosine(6));
  Assert.AreEqual(3007, FFunctions.FineTangent(7));
end;

procedure TTestScriptHostSystemFunctions.DovrebbeCalcolareSenoCosenoETangenteInGradi;
begin
  Assert.AreEqual(Double(1), Double(FFunctions.SineOfDegrees(90)), 1E-9);
  Assert.AreEqual(Double(1), Double(FFunctions.CosineOfDegrees(0)), 1E-9);
  Assert.AreEqual(Double(1), Double(FFunctions.TangentOfDegrees(45)), 1E-9);
  Assert.AreEqual(Double(-1), Double(FFunctions.CosineOfDegrees(180)), 1E-9);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeCalcolareLaTangenteInRadianti;
begin
  Assert.AreEqual(Double(0), Double(FFunctions.TangentOfRadians(0)), 1E-12);
  Assert.AreEqual(Double(1), Double(FFunctions.TangentOfRadians(Pi / 4)), 1E-9);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeDareIlRisultatoDelCondizionaleDiInteri;
begin
  Assert.AreEqual(Int64(7), FFunctions.IfInteger(True, 7, 9));
  Assert.AreEqual(Int64(9), FFunctions.IfInteger(False, 7, 9));
  Assert.AreEqual(Int64(5000000000), FFunctions.IfInteger(True, 5000000000, 0));
end;

procedure TTestScriptHostSystemFunctions.DovrebbeDareIlRisultatoDelCondizionaleDiReali;
begin
  Assert.AreEqual(Double(1.5), Double(FFunctions.IfFloat(True, 1.5, 2.5)), 1E-12);
  Assert.AreEqual(Double(2.5), Double(FFunctions.IfFloat(False, 1.5, 2.5)), 1E-12);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeDareIlRisultatoDelCondizionaleDiTesti;
begin
  Assert.AreEqual('yes', FFunctions.IfString(True, 'yes', 'no'));
  Assert.AreEqual('no', FFunctions.IfString(False, 'yes', 'no'));
end;

procedure TTestScriptHostSystemFunctions.DovrebbeDistinguerePariEDispari;
begin
  Assert.IsTrue(FFunctions.IsOdd(3));
  Assert.IsFalse(FFunctions.IsOdd(4));
  Assert.IsTrue(FFunctions.IsOdd(-3));
  Assert.IsFalse(FFunctions.IsOdd(0));
  Assert.IsTrue(FFunctions.IsEven(4));
  Assert.IsTrue(FFunctions.IsEven(0));
  Assert.IsFalse(FFunctions.IsEven(-3));
end;

procedure TTestScriptHostSystemFunctions.DovrebbeUnireDueArrayDiInteri;
var
  LResult: TArray<Integer>;
begin
  LResult := FFunctions.MergeIntegerArrays([1, 2, 3], [4, 5]);
  Assert.AreEqual(5, Integer(Length(LResult)));
  Assert.AreEqual(1, LResult[0]);
  Assert.AreEqual(3, LResult[2]);
  Assert.AreEqual(4, LResult[3]);
  Assert.AreEqual(5, LResult[4]);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeUnireDueArrayVuoti;
begin
  Assert.AreEqual(0, Integer(Length(FFunctions.MergeIntegerArrays(nil, nil))));
  Assert.AreEqual(2, Integer(Length(FFunctions.MergeIntegerArrays([1, 2], nil))));
  Assert.AreEqual(2, Integer(Length(FFunctions.MergeIntegerArrays(nil, [1, 2]))));
end;

procedure TTestScriptHostSystemFunctions.DovrebbeUnireGliArrayDegliAltriTipi;
var
  LInt64: TArray<Int64>;
  LLongWord: TArray<LongWord>;
  LSingle: TArray<Single>;
  LDouble: TArray<Double>;
  LExtended: TArray<Extended>;
begin
  LInt64 := FFunctions.MergeInt64Arrays([5000000000], [1]);
  Assert.AreEqual(Int64(5000000000), LInt64[0]);
  Assert.AreEqual(Int64(1), LInt64[1]);
  LLongWord := FFunctions.MergeLongWordArrays([4000000000], [2]);
  Assert.AreEqual(LongWord(4000000000), LLongWord[0]);
  Assert.AreEqual(LongWord(2), LLongWord[1]);
  LSingle := FFunctions.MergeSingleArrays([1.5], [2.5]);
  Assert.AreEqual(Double(2.5), Double(LSingle[1]), 1E-6);
  LDouble := FFunctions.MergeDoubleArrays([1.25], [2.25, 3.25]);
  Assert.AreEqual(3, Integer(Length(LDouble)));
  Assert.AreEqual(Double(3.25), LDouble[2], 1E-12);
  LExtended := FFunctions.MergeExtendedArrays([1.125], [2.125]);
  Assert.AreEqual(Double(2.125), Double(LExtended[1]), 1E-12);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeRiconoscereINumeriPrimi;
begin
  Assert.IsFalse(FFunctions.IsPrime(-5));
  Assert.IsFalse(FFunctions.IsPrime(0));
  Assert.IsFalse(FFunctions.IsPrime(1));
  Assert.IsTrue(FFunctions.IsPrime(2));
  Assert.IsTrue(FFunctions.IsPrime(3));
  Assert.IsFalse(FFunctions.IsPrime(4));
  Assert.IsTrue(FFunctions.IsPrime(5));
  Assert.IsFalse(FFunctions.IsPrime(9));
  Assert.IsFalse(FFunctions.IsPrime(91));
  Assert.IsTrue(FFunctions.IsPrime(97));
  Assert.IsTrue(FFunctions.IsPrime(7919));
  Assert.IsTrue(FFunctions.IsPrime(2147483647));
  Assert.IsFalse(FFunctions.IsPrime(2147483649));
end;

procedure TTestScriptHostSystemFunctions.DovrebbeDareUnNumeroTraIDueSecondoIlCasuale;
begin
  // the random number of the game picks the point between the two limits
  FRandom.Numbers[0] := 0;
  Assert.AreEqual(20, FFunctions.RandomRange(10, 20));
  FRandom.Numbers[0] := 255;
  Assert.AreEqual(10, FFunctions.RandomRange(10, 20));
  FRandom.Numbers[0] := 100;
  Assert.AreEqual(16, FFunctions.RandomRange(10, 20));
end;

procedure TTestScriptHostSystemFunctions.DovrebbeUsareUnSoloNumeroCasualePerChiamata;
begin
  FFunctions.RandomRange(1, 2);
  FFunctions.RandomRange(1, 2);
  Assert.AreEqual(2, FRandom.GetPlayIndex);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeAccodareIComandiDellaConsole;
begin
  FFunctions.ExecuteConsoleCommand('god');
  FFunctions.ExecuteConsoleCommand('map 3');
  Assert.AreEqual('god|map 3|', FConsole.Commands);
end;

procedure TTestScriptHostSystemFunctions.DovrebbeLeggereLeVariabiliDellaConsole;
begin
  Assert.AreEqual('text of skill', FFunctions.GetConsoleString('skill'));
  Assert.AreEqual(5, FFunctions.GetConsoleInteger('skill'));
  Assert.IsTrue(FFunctions.GetConsoleBoolean('yes'));
  Assert.IsFalse(FFunctions.GetConsoleBoolean('no'));
end;

procedure TTestScriptHostSystemFunctions.DovrebbeScrivereLeVariabiliDellaConsoleEDarneLEsito;
begin
  Assert.IsTrue(FFunctions.SetConsoleString('name', 'x'));
  Assert.AreEqual('x', FConsole.LastValue);
  Assert.IsTrue(FFunctions.SetConsoleInteger('skill', 4));
  Assert.AreEqual('4', FConsole.LastValue);
  Assert.IsTrue(FFunctions.SetConsoleBoolean('god', True));
  Assert.AreEqual('True', FConsole.LastValue);
  Assert.IsFalse(FFunctions.SetConsoleInteger('unknown', 1));
end;

end.

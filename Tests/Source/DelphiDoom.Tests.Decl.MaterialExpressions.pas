{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the registers, the expression parser and the           }
{  evaluator of the material declaration                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.MaterialExpressions;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.Decl.Intf, DelphiDoom.Decl.Material.Types, DelphiDoom.Decl.Material.Registers,
  DelphiDoom.Decl.Material.ExpressionParser, DelphiDoom.Decl.Material.Evaluator,
  DelphiDoom.Tests.Scanner.IdFakes, DelphiDoom.Tests.Decl.MaterialSupport;

type
  [TestFixture]
  [Category('Decl')]
  TTestMaterialRegisterTable = class
  strict private
    FLogObject: TFakeIdLibLog;
    FLog: IIdLibLog;
    FTable: TMaterialRegisterTable;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePartireDaiRegistriPredefiniti;
    [Test]
    procedure DovrebbeCondividereLeCostanti;
    [Test]
    procedure DovrebbeFondereLeSommeDiCostanti;
    [Test]
    procedure DovrebbeTogliereLaSommaConZero;
    [Test]
    procedure DovrebbeSemplificareLeMoltiplicazioniPerUnoEPerZero;
    [Test]
    procedure DovrebbeFondereLeMoltiplicazioniDiCostanti;
    [Test]
    procedure DovrebbeEmettereUnaOperazioneConUnTemporaneo;
    [Test]
    procedure DovrebbeSegnalareIlLimiteDelleCostanti;
    [Test]
    procedure DovrebbeSegnalareIlLimiteDeiTemporanei;
    [Test]
    procedure DovrebbeCopiareValoriEOperazioni;
    [Test]
    procedure DovrebbePartireCostanteSoloSeRichiesto;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestMaterialExpressionParser = class
  strict private
    FKit: TMaterialTestKit;
    FLogObject: TFakeIdLibLog;
    FLog: IIdLibLog;
    FTable: TMaterialRegisterTable;
    FParser: TMaterialExpressionParser;
    function Parse(const AText: string): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFondereUnaEspressioneDiCostanti;
    [Test]
    procedure DovrebbeDareLaPrecedenzaAllaMoltiplicazione;
    [Test]
    procedure DovrebbeRispettareLeParentesi;
    [Test]
    procedure DovrebbeLeggereUnNumeroNegativo;
    [Test]
    procedure DovrebbeSegnalareUnNumeroNegativoSbagliato;
    [Test]
    procedure DovrebbeLeggereIRegistriDelTempoEDeiParametri;
    [Test]
    procedure DovrebbeSegnareCheIRegistriNonSonoCostanti;
    [Test]
    procedure DovrebbeLeggereUnaTabella;
    [Test]
    procedure DovrebbeSegnalareUnTermineSconosciuto;
    [Test]
    procedure DovrebbeSegnalareUnaParentesiMancante;
    [Test]
    procedure DovrebbeLeggereIlTermineSound;
    [Test]
    procedure DovrebbeLeggereIlTermineFragmentPrograms;
    [Test]
    procedure DovrebbeFermarsiAlPrimoTokenCheNonEUnOperatore;
    [Test]
    procedure DovrebbeEmettereTuttiGliOperatori;
  end;

  /// <summary>A finder that knows nothing: the evaluator asks it for a table</summary>
  TNoTableFinder = class(TInterfacedObject, IDeclFinder)
  public
    function FindType(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean = True): IDecl;
    function FindDeclWithoutParsing(const AType: Integer; const AName: AnsiString;
      const AMakeDefault: Boolean = True): IDecl;
    function GetNumDecls(const AType: Integer): Integer;
    function DeclByIndex(const AType, AIndex: Integer; const AForceParse: Boolean = True): IDecl;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestMaterialExpressionEvaluator = class
  strict private
    FKit: TMaterialTestKit;
    FEvaluator: TMaterialExpressionEvaluator;
    function Run(const AOpType: TMaterialOpType; const AA, AB: Single): Single;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCopiareTempoEParametri;
    [Test]
    procedure DovrebbeFareLeQuattroOperazioni;
    [Test]
    procedure DovrebbeDareInfinitoDividendoPerZero;
    [Test]
    procedure DovrebbeDareNanDividendoZeroPerZero;
    [TestCase('resto', '7,3,1')]
    [TestCase('restoNegativo', '-7,3,-1')]
    [TestCase('restoConDivisoreNegativo', '7,-3,1')]
    [TestCase('restoPerZero', '7,0,0')]
    [TestCase('restoPerMenoUno', '7,-1,0')]
    [TestCase('restoTroncaIDecimali', '7.9,3.9,1')]
    procedure DovrebbeCalcolareIlResto(const AA, AB, AExpected: Single);
    [Test]
    procedure DovrebbeTroncareUnValoreFuoriScalaComeIlProcessore;
    [Test]
    procedure DovrebbeConfrontare;
    [Test]
    procedure DovrebbeFareAndEOr;
    [Test]
    procedure DovrebbeLeggereUnaTabella;
    [Test]
    procedure DovrebbeLeggereLAmpiezzaDelSuono;
    [Test]
    procedure DovrebbeDareZeroSenzaSuono;
    [Test]
    procedure DovrebbeFallireSenzaLaTabella;
    [Test]
    procedure DovrebbeRipristinareLeEccezioniInVirgolaMobile;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Token, DelphiDoom.Decl.Types;

procedure AssertSingle(const AExpected, AActual: Single; const ATolerance: Double);
begin
  Assert.AreEqual(Double(AExpected), Double(AActual), ATolerance);
end;

function MakeLexer(const AText: string; const ALog: IIdLibLog): TIdLexer;
begin
  Result := TIdLexer.Create(0, ALog);
  Result.LoadMemory(AnsiString(AText), Length(AText), 'test');
  Result.Flags := DECL_LEXER_FLAGS;
end;

{ TTestMaterialRegisterTable }

procedure TTestMaterialRegisterTable.Setup;
begin
  FLogObject := TFakeIdLibLog.Create;
  FLog := FLogObject;
  FTable := TMaterialRegisterTable.Create('m/test', FLog, False);
end;

procedure TTestMaterialRegisterTable.TearDown;
begin
  FTable.Free;
  FLog := nil;
end;

procedure TTestMaterialRegisterTable.DovrebbePartireDaiRegistriPredefiniti;
begin
  Assert.AreEqual(EXP_REG_NUM_PREDEFINED, FTable.NumRegisters);
  Assert.AreEqual(0, FTable.NumOps);
  Assert.IsFalse(FTable.IsConstant(EXP_REG_TIME));
  Assert.IsFalse(FTable.IsConstant(EXP_REG_GLOBAL7));
  Assert.IsFalse(FTable.Defaulted);
end;

procedure TTestMaterialRegisterTable.DovrebbeCondividereLeCostanti;
var
  LOne, LTwo: Integer;
begin
  LOne := FTable.GetConstant(2.5);
  Assert.AreEqual(EXP_REG_NUM_PREDEFINED, LOne);
  Assert.AreEqual(LOne, FTable.GetConstant(2.5));
  LTwo := FTable.GetConstant(3);
  Assert.AreEqual(LOne + 1, LTwo);
  Assert.IsTrue(FTable.IsConstant(LOne));
  AssertSingle(2.5, FTable.GetValue(LOne), 0);
end;

procedure TTestMaterialRegisterTable.DovrebbeFondereLeSommeDiCostanti;
var
  LResult: Integer;
begin
  LResult := FTable.EmitOp(FTable.GetConstant(1.5), FTable.GetConstant(2), TMaterialOpType.Add);
  Assert.AreEqual(0, FTable.NumOps);
  AssertSingle(3.5, FTable.GetValue(LResult), 0);
end;

procedure TTestMaterialRegisterTable.DovrebbeTogliereLaSommaConZero;
var
  LZero: Integer;
begin
  LZero := FTable.GetConstant(0);
  Assert.AreEqual(EXP_REG_PARM0, FTable.EmitOp(LZero, EXP_REG_PARM0, TMaterialOpType.Add));
  Assert.AreEqual(EXP_REG_PARM1, FTable.EmitOp(EXP_REG_PARM1, LZero, TMaterialOpType.Add));
  Assert.AreEqual(0, FTable.NumOps);
end;

procedure TTestMaterialRegisterTable.DovrebbeSemplificareLeMoltiplicazioniPerUnoEPerZero;
var
  LOne, LZero: Integer;
begin
  LOne := FTable.GetConstant(1);
  LZero := FTable.GetConstant(0);
  Assert.AreEqual(EXP_REG_PARM0, FTable.EmitOp(LOne, EXP_REG_PARM0, TMaterialOpType.Multiply));
  Assert.AreEqual(EXP_REG_PARM0, FTable.EmitOp(EXP_REG_PARM0, LOne, TMaterialOpType.Multiply));
  Assert.AreEqual(LZero, FTable.EmitOp(LZero, EXP_REG_PARM0, TMaterialOpType.Multiply));
  Assert.AreEqual(LZero, FTable.EmitOp(EXP_REG_PARM0, LZero, TMaterialOpType.Multiply));
  Assert.AreEqual(0, FTable.NumOps);
end;

procedure TTestMaterialRegisterTable.DovrebbeFondereLeMoltiplicazioniDiCostanti;
var
  LResult: Integer;
begin
  LResult := FTable.EmitOp(FTable.GetConstant(3), FTable.GetConstant(4), TMaterialOpType.Multiply);
  AssertSingle(12, FTable.GetValue(LResult), 0);
  Assert.AreEqual(0, FTable.NumOps);
end;

procedure TTestMaterialRegisterTable.DovrebbeEmettereUnaOperazioneConUnTemporaneo;
var
  LResult: Integer;
  LOp: TMaterialOp;
begin
  LResult := FTable.EmitOp(EXP_REG_TIME, FTable.GetConstant(2), TMaterialOpType.Divide);
  Assert.AreEqual(1, FTable.NumOps);
  LOp := FTable.GetOp(0);
  Assert.AreEqual(Ord(TMaterialOpType.Divide), Ord(LOp.OpType));
  Assert.AreEqual(EXP_REG_TIME, LOp.A);
  Assert.AreEqual(LResult, LOp.C);
  Assert.IsFalse(FTable.IsConstant(LResult));
  // an add of a register and a constant that is not zero is an operation as well
  FTable.EmitOp(EXP_REG_PARM0, FTable.GetConstant(5), TMaterialOpType.Add);
  Assert.AreEqual(2, FTable.NumOps);
end;

procedure TTestMaterialRegisterTable.DovrebbeSegnalareIlLimiteDelleCostanti;
var
  LIndex: Integer;
begin
  for LIndex := EXP_REG_NUM_PREDEFINED to MAX_EXPRESSION_REGISTERS - 1 do
    Assert.AreEqual(LIndex, FTable.GetConstant(LIndex));
  Assert.IsFalse(FTable.Defaulted);
  Assert.AreEqual(0, FTable.GetConstant(-1));
  Assert.IsTrue(FTable.Defaulted);
  Assert.IsTrue(Pos('GetExpressionConstant: material ''m/test'' hit MAX_EXPRESSION_REGISTERS',
    FLogObject.Lines.Text) > 0);
end;

procedure TTestMaterialRegisterTable.DovrebbeSegnalareIlLimiteDeiTemporanei;
var
  LIndex: Integer;
begin
  for LIndex := EXP_REG_NUM_PREDEFINED to MAX_EXPRESSION_REGISTERS - 1 do
    FTable.GetTemporary;
  Assert.AreEqual(0, FTable.GetTemporary);
  Assert.IsTrue(FTable.Defaulted);
  Assert.IsTrue(Pos('GetExpressionTemporary: material ''m/test'' hit MAX_EXPRESSION_REGISTERS',
    FLogObject.Lines.Text) > 0);
end;

procedure TTestMaterialRegisterTable.DovrebbeCopiareValoriEOperazioni;
var
  LValues: TArray<Single>;
  LOps: TArray<TMaterialOp>;
begin
  FTable.GetConstant(9);
  FTable.EmitOp(EXP_REG_TIME, EXP_REG_PARM0, TMaterialOpType.Subtract);
  LValues := FTable.CopyValues;
  LOps := FTable.CopyOps;
  Assert.AreEqual<Integer>(FTable.NumRegisters, Length(LValues));
  AssertSingle(9, LValues[EXP_REG_NUM_PREDEFINED], 0);
  Assert.AreEqual<Integer>(1, Length(LOps));
end;

procedure TTestMaterialRegisterTable.DovrebbePartireCostanteSoloSeRichiesto;
var
  LConstant: TMaterialRegisterTable;
begin
  Assert.IsFalse(FTable.RegistersAreConstant);
  LConstant := TMaterialRegisterTable.Create('m/test', FLog, True);
  try
    Assert.IsTrue(LConstant.RegistersAreConstant);
  finally
    LConstant.Free;
  end;
end;

procedure TTestMaterialRegisterTable.DovrebbeFunzionareSenzaLog;
var
  LTable: TMaterialRegisterTable;
  LIndex: Integer;
begin
  LTable := TMaterialRegisterTable.Create('m/test', nil, False);
  try
    for LIndex := EXP_REG_NUM_PREDEFINED to MAX_EXPRESSION_REGISTERS do
      LTable.GetConstant(LIndex);
    Assert.IsTrue(LTable.Defaulted);
  finally
    LTable.Free;
  end;
end;

{ TTestMaterialExpressionParser }

procedure TTestMaterialExpressionParser.Setup;
begin
  FKit := TMaterialTestKit.Create('');
  FLogObject := TFakeIdLibLog.Create;
  FLog := FLogObject;
  FTable := TMaterialRegisterTable.Create('m/test', FLog, True);
  FParser := TMaterialExpressionParser.Create(FTable, FKit.Kit.Manager, FLog, 'm/test', True);
end;

procedure TTestMaterialExpressionParser.TearDown;
begin
  FParser.Free;
  FTable.Free;
  FLog := nil;
  FKit.Free;
end;

function TTestMaterialExpressionParser.Parse(const AText: string): Integer;
var
  LLexer: TIdLexer;
begin
  LLexer := MakeLexer(AText, FLog);
  try
    Result := FParser.ParseExpression(LLexer);
  finally
    LLexer.Free;
  end;
end;

procedure TTestMaterialExpressionParser.DovrebbeFondereUnaEspressioneDiCostanti;
var
  LRegister: Integer;
begin
  LRegister := Parse('1 + 2 * 3 + 4');
  AssertSingle(11, FTable.GetValue(LRegister), 0);
  Assert.AreEqual(0, FTable.NumOps);
end;

procedure TTestMaterialExpressionParser.DovrebbeDareLaPrecedenzaAllaMoltiplicazione;
var
  LRegister: Integer;
begin
  Parse('time + parm0 * 2');
  // the product is made first, then the sum
  Assert.AreEqual(2, FTable.NumOps);
  Assert.AreEqual(Ord(TMaterialOpType.Multiply), Ord(FTable.GetOp(0).OpType));
  Assert.AreEqual(Ord(TMaterialOpType.Add), Ord(FTable.GetOp(1).OpType));
  LRegister := FTable.GetOp(1).C;
  Assert.AreEqual(FTable.GetOp(0).C, FTable.GetOp(1).B);
  Assert.IsTrue(LRegister > 0);
end;

procedure TTestMaterialExpressionParser.DovrebbeRispettareLeParentesi;
begin
  AssertSingle(9, FTable.GetValue(Parse('( 1 + 2 ) * 3')), 0);
end;

procedure TTestMaterialExpressionParser.DovrebbeLeggereUnNumeroNegativo;
begin
  AssertSingle(-2.5, FTable.GetValue(Parse('-2.5')), 0);
  // a subtraction is not folded: it is an operation on two constants
  Parse('3 - -2');
  Assert.AreEqual(1, FTable.NumOps);
  Assert.AreEqual(Ord(TMaterialOpType.Subtract), Ord(FTable.GetOp(0).OpType));
  AssertSingle(-2, FTable.GetValue(FTable.GetOp(0).B), 0);
end;

procedure TTestMaterialExpressionParser.DovrebbeSegnalareUnNumeroNegativoSbagliato;
begin
  Assert.AreEqual(0, Parse('- x'));
  Assert.IsTrue(FTable.Defaulted);
  Assert.IsTrue(Pos('Bad negative number ''x''', FLogObject.Lines.Text) > 0);
end;

procedure TTestMaterialExpressionParser.DovrebbeLeggereIRegistriDelTempoEDeiParametri;
begin
  Assert.AreEqual(EXP_REG_TIME, Parse('time'));
  Assert.AreEqual(EXP_REG_PARM0, Parse('PARM0'));
  Assert.AreEqual(EXP_REG_PARM11, Parse('parm11'));
  Assert.AreEqual(EXP_REG_GLOBAL0, Parse('global0'));
  Assert.AreEqual(EXP_REG_GLOBAL7, Parse('global7'));
end;

procedure TTestMaterialExpressionParser.DovrebbeSegnareCheIRegistriNonSonoCostanti;
begin
  Parse('2 * 3');
  Assert.IsTrue(FTable.RegistersAreConstant);
  Parse('global2');
  Assert.IsFalse(FTable.RegistersAreConstant);
end;

procedure TTestMaterialExpressionParser.DovrebbeLeggereUnaTabella;
begin
  Parse('ramp[ time ]');
  Assert.AreEqual(1, FTable.NumOps);
  Assert.AreEqual(Ord(TMaterialOpType.Table), Ord(FTable.GetOp(0).OpType));
  Assert.AreEqual(EXP_REG_TIME, FTable.GetOp(0).B);
  Assert.AreEqual('ramp', string(FKit.Kit.Manager.DeclByIndex(DECL_TABLE, FTable.GetOp(0).A).GetName));
end;

procedure TTestMaterialExpressionParser.DovrebbeSegnalareUnTermineSconosciuto;
begin
  Assert.AreEqual(0, Parse('noSuchThing'));
  Assert.IsTrue(FTable.Defaulted);
  Assert.IsTrue(Pos('Bad term ''noSuchThing''', FLogObject.Lines.Text) > 0);
end;

procedure TTestMaterialExpressionParser.DovrebbeSegnalareUnaParentesiMancante;
begin
  Parse('( 1 + 2');
  Assert.IsTrue(FTable.Defaulted);
  Assert.IsTrue(Pos('file test, line 1: couldn''t find expected '')''', FLogObject.Lines.Text) > 0);
end;

procedure TTestMaterialExpressionParser.DovrebbeLeggereIlTermineSound;
begin
  Parse('sound * 2');
  Assert.AreEqual(Ord(TMaterialOpType.Sound), Ord(FTable.GetOp(0).OpType));
  Assert.IsFalse(FTable.RegistersAreConstant);
end;

procedure TTestMaterialExpressionParser.DovrebbeLeggereIlTermineFragmentPrograms;
var
  LOther: TMaterialExpressionParser;
  LLexer: TIdLexer;
  LRegister: Integer;
begin
  AssertSingle(1, FTable.GetValue(Parse('fragmentPrograms')), 0);
  LOther := TMaterialExpressionParser.Create(FTable, FKit.Kit.Manager, FLog, 'm/test', False);
  LLexer := MakeLexer('fragmentPrograms', FLog);
  try
    LRegister := LOther.ParseExpression(LLexer);
    AssertSingle(0, FTable.GetValue(LRegister), 0);
  finally
    LLexer.Free;
    LOther.Free;
  end;
end;

procedure TTestMaterialExpressionParser.DovrebbeFermarsiAlPrimoTokenCheNonEUnOperatore;
var
  LLexer: TIdLexer;
  LToken: TIdToken;
begin
  LLexer := MakeLexer('parm0 parm1', FLog);
  try
    Assert.AreEqual(EXP_REG_PARM0, FParser.ParseExpression(LLexer));
    LToken := TIdToken.Create;
    Assert.IsTrue(LLexer.ReadToken(LToken));
    Assert.AreEqual('parm1', string(LToken.Text));
  finally
    LLexer.Free;
  end;
end;

procedure TTestMaterialExpressionParser.DovrebbeEmettereTuttiGliOperatori;
const
  TEXTS: array[0..11] of string = ('parm0 / parm1', 'parm0 % parm1', 'parm0 - parm1', 'parm0 > parm1',
    'parm0 >= parm1', 'parm0 < parm1', 'parm0 <= parm1', 'parm0 == parm1', 'parm0 != parm1', 'parm0 && parm1',
    'parm0 || parm1', 'parm0 + parm1');
  EXPECTED: array[0..11] of TMaterialOpType = (TMaterialOpType.Divide, TMaterialOpType.Modulo,
    TMaterialOpType.Subtract, TMaterialOpType.GreaterThan, TMaterialOpType.GreaterOrEqual,
    TMaterialOpType.LessThan, TMaterialOpType.LessOrEqual, TMaterialOpType.Equal, TMaterialOpType.NotEqual,
    TMaterialOpType.LogicalAnd, TMaterialOpType.LogicalOr, TMaterialOpType.Add);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(TEXTS) do
  begin
    Parse(TEXTS[LIndex]);
    Assert.AreEqual(Ord(EXPECTED[LIndex]), Ord(FTable.GetOp(FTable.NumOps - 1).OpType), TEXTS[LIndex]);
  end;
end;

{ TNoTableFinder }

function TNoTableFinder.FindType(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean): IDecl;
begin
  Result := nil;
end;

function TNoTableFinder.FindDeclWithoutParsing(const AType: Integer; const AName: AnsiString;
  const AMakeDefault: Boolean): IDecl;
begin
  Result := nil;
end;

function TNoTableFinder.GetNumDecls(const AType: Integer): Integer;
begin
  Result := 0;
end;

function TNoTableFinder.DeclByIndex(const AType, AIndex: Integer; const AForceParse: Boolean): IDecl;
begin
  Result := nil;
end;

{ TTestMaterialExpressionEvaluator }

procedure TTestMaterialExpressionEvaluator.Setup;
begin
  FKit := TMaterialTestKit.Create('');
  FEvaluator := TMaterialExpressionEvaluator.Create(FKit.Kit.Manager);
end;

procedure TTestMaterialExpressionEvaluator.TearDown;
begin
  FEvaluator.Free;
  FKit.Free;
end;

function TTestMaterialExpressionEvaluator.Run(const AOpType: TMaterialOpType; const AA, AB: Single): Single;
var
  LConstants: TArray<Single>;
  LOps: TArray<TMaterialOp>;
  LRegisters: TArray<Single>;
  LInput: TMaterialEvaluationInput;
begin
  // registers 21 and 22 hold the operands, the result is in 23
  SetLength(LConstants, EXP_REG_NUM_PREDEFINED + 3);
  LConstants[EXP_REG_NUM_PREDEFINED] := AA;
  LConstants[EXP_REG_NUM_PREDEFINED + 1] := AB;
  SetLength(LOps, 1);
  LOps[0].OpType := AOpType;
  LOps[0].A := EXP_REG_NUM_PREDEFINED;
  LOps[0].B := EXP_REG_NUM_PREDEFINED + 1;
  LOps[0].C := EXP_REG_NUM_PREDEFINED + 2;
  LInput := Default(TMaterialEvaluationInput);
  FEvaluator.Evaluate(LConstants, LOps, LInput, LRegisters);
  Result := LRegisters[EXP_REG_NUM_PREDEFINED + 2];
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeCopiareTempoEParametri;
var
  LConstants: TArray<Single>;
  LRegisters: TArray<Single>;
  LInput: TMaterialEvaluationInput;
  LIndex: Integer;
begin
  SetLength(LConstants, EXP_REG_NUM_PREDEFINED + 1);
  LConstants[EXP_REG_NUM_PREDEFINED] := 42;
  LInput := Default(TMaterialEvaluationInput);
  LInput.Time := 1.5;
  for LIndex := 0 to MAX_ENTITY_SHADER_PARMS - 1 do
    LInput.Parms[LIndex] := 10 + LIndex;
  for LIndex := 0 to MAX_GLOBAL_SHADER_PARMS - 1 do
    LInput.GlobalParms[LIndex] := 100 + LIndex;
  FEvaluator.Evaluate(LConstants, nil, LInput, LRegisters);
  AssertSingle(1.5, LRegisters[EXP_REG_TIME], 0);
  AssertSingle(10, LRegisters[EXP_REG_PARM0], 0);
  AssertSingle(21, LRegisters[EXP_REG_PARM11], 0);
  AssertSingle(100, LRegisters[EXP_REG_GLOBAL0], 0);
  AssertSingle(107, LRegisters[EXP_REG_GLOBAL7], 0);
  AssertSingle(42, LRegisters[EXP_REG_NUM_PREDEFINED], 0);
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeFareLeQuattroOperazioni;
begin
  AssertSingle(7.5, Run(TMaterialOpType.Add, 5, 2.5), 0);
  AssertSingle(2.5, Run(TMaterialOpType.Subtract, 5, 2.5), 0);
  AssertSingle(12.5, Run(TMaterialOpType.Multiply, 5, 2.5), 0);
  AssertSingle(2, Run(TMaterialOpType.Divide, 5, 2.5), 0);
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeDareInfinitoDividendoPerZero;
begin
  Assert.IsTrue(IsInfinite(Run(TMaterialOpType.Divide, 5, 0)));
  Assert.IsTrue(Run(TMaterialOpType.Divide, -5, 0) < 0);
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeDareNanDividendoZeroPerZero;
begin
  Assert.IsTrue(IsNan(Run(TMaterialOpType.Divide, 0, 0)));
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeCalcolareIlResto(const AA, AB, AExpected: Single);
begin
  AssertSingle(AExpected, Run(TMaterialOpType.Modulo, AA, AB), 0);
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeTroncareUnValoreFuoriScalaComeIlProcessore;
begin
  // (int) of 1e20 is the "integer indefinite" value, -2147483648, and -2147483648 % 3 is -2
  AssertSingle(-2, Run(TMaterialOpType.Modulo, 1E20, 3), 0);
  AssertSingle(-2, Run(TMaterialOpType.Modulo, NaN, 3), 0);
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeConfrontare;
begin
  AssertSingle(1, Run(TMaterialOpType.GreaterThan, 3, 2), 0);
  AssertSingle(0, Run(TMaterialOpType.GreaterThan, 2, 2), 0);
  AssertSingle(1, Run(TMaterialOpType.GreaterOrEqual, 2, 2), 0);
  AssertSingle(1, Run(TMaterialOpType.LessThan, 1, 2), 0);
  AssertSingle(0, Run(TMaterialOpType.LessThan, 2, 2), 0);
  AssertSingle(1, Run(TMaterialOpType.LessOrEqual, 2, 2), 0);
  AssertSingle(1, Run(TMaterialOpType.Equal, 2, 2), 0);
  AssertSingle(0, Run(TMaterialOpType.Equal, 2, 3), 0);
  AssertSingle(1, Run(TMaterialOpType.NotEqual, 2, 3), 0);
  AssertSingle(0, Run(TMaterialOpType.NotEqual, 2, 2), 0);
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeFareAndEOr;
begin
  AssertSingle(1, Run(TMaterialOpType.LogicalAnd, 3, 0.5), 0);
  AssertSingle(0, Run(TMaterialOpType.LogicalAnd, 3, 0), 0);
  AssertSingle(1, Run(TMaterialOpType.LogicalOr, 0, -1), 0);
  AssertSingle(0, Run(TMaterialOpType.LogicalOr, 0, 0), 0);
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeLeggereUnaTabella;
var
  LConstants: TArray<Single>;
  LOps: TArray<TMaterialOp>;
  LRegisters: TArray<Single>;
  LInput: TMaterialEvaluationInput;
  LRamp: Integer;
begin
  LRamp := FKit.Kit.Manager.FindType(DECL_TABLE, 'ramp', False).GetIndex;
  SetLength(LConstants, EXP_REG_NUM_PREDEFINED + 2);
  SetLength(LOps, 1);
  LOps[0].OpType := TMaterialOpType.Table;
  LOps[0].A := LRamp;
  LOps[0].B := EXP_REG_TIME;
  LOps[0].C := EXP_REG_NUM_PREDEFINED;
  LInput := Default(TMaterialEvaluationInput);
  // the table is clamped: 0, 0.25, 1 read at 0.25 gives the middle of the first half
  LInput.Time := 0.25;
  FEvaluator.Evaluate(LConstants, LOps, LInput, LRegisters);
  AssertSingle(0.125, LRegisters[EXP_REG_NUM_PREDEFINED], 0.0001);
  LInput.Time := 7;
  FEvaluator.Evaluate(LConstants, LOps, LInput, LRegisters);
  AssertSingle(1, LRegisters[EXP_REG_NUM_PREDEFINED], 0.0001);
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeLeggereLAmpiezzaDelSuono;
var
  LConstants: TArray<Single>;
  LOps: TArray<TMaterialOp>;
  LRegisters: TArray<Single>;
  LInput: TMaterialEvaluationInput;
begin
  SetLength(LConstants, EXP_REG_NUM_PREDEFINED + 1);
  SetLength(LOps, 1);
  LOps[0].OpType := TMaterialOpType.Sound;
  LOps[0].C := EXP_REG_NUM_PREDEFINED;
  LInput := Default(TMaterialEvaluationInput);
  LInput.HasSoundEmitter := True;
  LInput.SoundAmplitude := 0.75;
  FEvaluator.Evaluate(LConstants, LOps, LInput, LRegisters);
  AssertSingle(0.75, LRegisters[EXP_REG_NUM_PREDEFINED], 0);
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeDareZeroSenzaSuono;
var
  LConstants: TArray<Single>;
  LOps: TArray<TMaterialOp>;
  LRegisters: TArray<Single>;
  LInput: TMaterialEvaluationInput;
begin
  SetLength(LConstants, EXP_REG_NUM_PREDEFINED + 1);
  SetLength(LOps, 1);
  LOps[0].OpType := TMaterialOpType.Sound;
  LOps[0].C := EXP_REG_NUM_PREDEFINED;
  LInput := Default(TMaterialEvaluationInput);
  LInput.SoundAmplitude := 0.75;
  FEvaluator.Evaluate(LConstants, LOps, LInput, LRegisters);
  AssertSingle(0, LRegisters[EXP_REG_NUM_PREDEFINED], 0);
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeFallireSenzaLaTabella;
var
  LEvaluator: TMaterialExpressionEvaluator;
  LConstants: TArray<Single>;
  LOps: TArray<TMaterialOp>;
  LRegisters: TArray<Single>;
  LInput: TMaterialEvaluationInput;
  LRaised: Boolean;
begin
  LEvaluator := TMaterialExpressionEvaluator.Create(TNoTableFinder.Create);
  try
    SetLength(LConstants, EXP_REG_NUM_PREDEFINED + 1);
    SetLength(LOps, 1);
    LOps[0].OpType := TMaterialOpType.Table;
    LOps[0].A := 3;
    LOps[0].C := EXP_REG_NUM_PREDEFINED;
    LInput := Default(TMaterialEvaluationInput);
    LRaised := False;
    try
      LEvaluator.Evaluate(LConstants, LOps, LInput, LRegisters);
    except
      on EDeclMaterialException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestMaterialExpressionEvaluator.DovrebbeRipristinareLeEccezioniInVirgolaMobile;
var
  LBefore: TArithmeticExceptionMask;
begin
  LBefore := GetExceptionMask;
  Run(TMaterialOpType.Divide, 1, 0);
  Assert.IsTrue(LBefore = GetExceptionMask);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMaterialRegisterTable);
  TDUnitX.RegisterTestFixture(TTestMaterialExpressionParser);
  TDUnitX.RegisterTestFixture(TTestMaterialExpressionEvaluator);

end.

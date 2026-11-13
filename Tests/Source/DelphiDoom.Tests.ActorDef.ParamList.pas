{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parameters of an action (DUnitX)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ActorDef.ParamList;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.ActorDef.ParamList,
  DelphiDoom.Scanner.ContextEvaluator.Intf,
  DelphiDoom.Tests.InfoTables.Fakes;

type
  [TestFixture]
  [Category('actordef')]
  TTestActorDefParamList = class
  strict private
    FEvaluator: TFakeEvaluator;
    FEvaluatorRef: IContextExpressionEvaluator;
    FRandom: TFakeParamRandom;
    function Make(const ADeclaration: string): TActorDefParamList;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereINumeriInteri;
    [Test]
    procedure DovrebbeLeggereIDecimaliComeFissi;
    [Test]
    procedure DovrebbeLeggereUnTestoTraVirgolette;
    [Test]
    procedure DovrebbeLeggereEsadecimaliENegativi;
    [Test]
    procedure DovrebbeDareZeroFuoriDall_Elenco;
    [Test]
    procedure DovrebbePescareUnNumeroPerOgniLetturaDiRandom;
    [Test]
    procedure DovrebbeUsareLimitiDiRandomPredefiniti;
    [Test]
    procedure DovrebbeCalcolareLeEspressioniSull_Attore;
    [Test]
    procedure DovrebbeTrattareEvalConSpazioComeForzata;
    [Test]
    procedure DovrebbeTrattareLeVariabiliDiMappaComeEspressioni;
    [Test]
    procedure DovrebbeTroncareIlTestoACentoCinquantacinqueCaratteri;
    [Test]
    procedure DovrebbeImpostareInteriEDecimaliComeCalcolati;
    [Test]
    procedure DovrebbeLeggereUnBooleano;
    [Test]
    procedure DovrebbeDareLeStesseRispostePerLeCasiDelCorpusDelVecchioCodice;
    [Test]
    procedure DovrebbeDareLeStesseRispostePerDichiarazioniCasuali;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.ActorDef.ParamList.Intf,
  DelphiDoom.Tests.InfoTables.LegacyParams;

const
  Corpus: array[0..49] of string = (
    '', '1', '-5', '1.5', '"hello"', '1, 2, 3', 'RANDOM', 'RANDOM 5', 'RANDOM 1 5',
    'random(1, 5)', 'RANDOM 1 2 3', 'RANDOM a', 'FRANDOM 1.5 2.5', 'FLOATRANDOM 3', 'FRANDOM',
    'frandom(0.5, 1)', 'EVAL (1+2)', 'EVAL(1+2)', 'MAPSTR "x"', 'MAPINT "y"', 'WORLDFLOAT "z"',
    'CUSTOMPARAM "w"', 'TARGETCUSTOMPARAM x', 'MASTERCUSTOMPARAM "m"', 'foo', 'bar', 'baz',
    'x + 1', '(1, (2, 3), "a, b")', '0x10', '-0x10', '#12', '1,5', '100000000000', '16777217',
    '2.50', '"RANDOMPICK(a,b)"', 'TRUE', '"true"', 'Func(1, 2)', '1.0', '-0.5', '.5', '5.',
    'S_PLAY, 3', 'MAPSTR', 'WORLDSTR 5', '( )', ',', '"a" , "b"');

  Pieces: array[0..19] of string = (
    '1', '-7', '2.5', '"s"', 'RANDOM 1 9', 'RANDOM', 'FRANDOM 0.5 1.5', 'EVAL (x)', 'foo', 'baz + 1',
    'MAPINT "v"', 'CUSTOMPARAM "c"', '0x20', 'S_BAR', 'x * 2', 'FLOATRANDOM 4', 'TRUE', '(1+2)', '"t(1)"', '3');

procedure TTestActorDefParamList.Setup;
begin
  FEvaluator := TFakeEvaluator.Create;
  FEvaluatorRef := FEvaluator;
  FRandom := TFakeParamRandom.Create(5);
end;

function TTestActorDefParamList.Make(const ADeclaration: string): TActorDefParamList;
begin
  Result := TActorDefParamList.Create(ADeclaration, FEvaluator, FRandom);
end;

procedure TTestActorDefParamList.DovrebbeLeggereINumeriInteri;
var
  LList: TActorDefParamList;
begin
  LList := Make('10, -3, 0');
  try
    Assert.AreEqual(3, LList.Count);
    Assert.AreEqual(10, LList.GetInteger(0));
    Assert.AreEqual(-3, LList.GetInteger(1));
    Assert.IsTrue(LList.IsComputed(2));
    Assert.AreEqual(10 * 65536, LList.GetFixed(0));
    Assert.AreEqual(Single(10), LList.GetFloat(0));
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeLeggereIDecimaliComeFissi;
var
  LList: TActorDefParamList;
begin
  LList := Make('1.5, 2');
  try
    Assert.AreEqual(98304, LList.GetFixed(0));
    Assert.AreEqual(98304, LList.GetMBF21Fixed(0));
    Assert.AreEqual(2, LList.GetMBF21Fixed(1));
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeLeggereUnTestoTraVirgolette;
var
  LList: TActorDefParamList;
begin
  LList := Make('"hello world", name');
  try
    Assert.AreEqual('hello world', LList.GetString(0));
    Assert.AreEqual('name', LList.GetString(1));
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeLeggereEsadecimaliENegativi;
var
  LList: TActorDefParamList;
begin
  LList := Make('0x10, -0x10, #12');
  try
    Assert.AreEqual(16, LList.GetInteger(0));
    Assert.AreEqual(-16, LList.GetInteger(1));
    Assert.AreEqual(12, LList.GetInteger(2));
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeDareZeroFuoriDall_Elenco;
var
  LList: TActorDefParamList;
begin
  LList := Make('1');
  try
    Assert.AreEqual(0, LList.GetInteger(-1));
    Assert.AreEqual(0, LList.GetInteger(1));
    Assert.AreEqual('', LList.GetString(5));
    Assert.IsFalse(LList.GetBool(5));
    Assert.IsFalse(LList.IsComputed(5));
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbePescareUnNumeroPerOgniLetturaDiRandom;
var
  LList: TActorDefParamList;
  LValue: Integer;
begin
  LList := Make('RANDOM 10 20');
  try
    LValue := LList.GetInteger(0);
    Assert.IsTrue((LValue >= 10) and (LValue <= 20));
    Assert.AreEqual(1, FRandom.Draws);
    LList.GetFixed(0);
    LList.GetFloat(0);
    Assert.AreEqual(3, FRandom.Draws);
    Assert.IsFalse(LList.IsComputed(0));
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeUsareLimitiDiRandomPredefiniti;
var
  LList: TActorDefParamList;
  LValue: Integer;
begin
  LList := Make('RANDOM, RANDOM 40');
  try
    Assert.AreEqual(2, LList.Count);
    LValue := LList.GetInteger(1);
    Assert.IsTrue((LValue >= 0) and (LValue <= 40));
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeCalcolareLeEspressioniSull_Attore;
var
  LList: TActorDefParamList;
begin
  LList := Make('x + 1');
  try
    LList.Context := Pointer(7);
    LList.GetInteger(0);
    Assert.AreEqual('7|x + 1', FEvaluator.Log[FEvaluator.Log.Count - 1]);
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeTrattareEvalConSpazioComeForzata;
var
  LList: TActorDefParamList;
begin
  LList := Make('EVAL (1)');
  try
    Assert.AreEqual(1, LList.Count);
    LList.GetString(0);
    // GetString computes a forced expression, and only that kind
    Assert.AreEqual('0|EVAL (1)', FEvaluator.Log[FEvaluator.Log.Count - 1]);
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeTrattareLeVariabiliDiMappaComeEspressioni;
var
  LList: TActorDefParamList;
begin
  // the kinds that read a map variable were never stored: the text goes to the evaluator
  LList := Make('MAPINT "score"');
  try
    LList.GetInteger(0);
    Assert.AreEqual('0|MAPINT score', FEvaluator.Log[FEvaluator.Log.Count - 1]);
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeTroncareIlTestoACentoCinquantacinqueCaratteri;
var
  LList: TActorDefParamList;
begin
  LList := Make('"' + StringOfChar('a', 300) + '"');
  try
    Assert.AreEqual(255, Length(LList.GetString(0)));
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeImpostareInteriEDecimaliComeCalcolati;
var
  LList: TActorDefParamList;
begin
  LList := Make('1, foo');
  try
    LList.SetInteger(0, 42);
    Assert.AreEqual(42, LList.GetInteger(0));
    LList.SetFloat(0, 1.5);
    Assert.AreEqual(98304, LList.GetFixed(0));
    Assert.IsTrue(LList.IsComputed(0));
  finally
    LList.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeLeggereUnBooleano;
var
  LList: TActorDefParamList;
begin
  LList := Make('x');
  try
    // the fake evaluator answers "true" for a text of 1 character
    Assert.IsTrue(LList.GetBool(0));
  finally
    LList.Free;
  end;
end;

procedure CompareLists(const ADeclaration: string; const ASeed: Cardinal);
var
  LNewEvaluator: TFakeEvaluator;
  LNewRef: IContextExpressionEvaluator;
  LOldEvaluator: TFakeEvaluator;
  LOldRef: IContextExpressionEvaluator;
  LNewRandom: TFakeParamRandom;
  LNewRandomRef: IActorDefParamRandom;
  LOldRandom: TFakeParamRandom;
  LOldRandomRef: IActorDefParamRandom;
  LNew: TActorDefParamList;
  LOld: TLegacyParamList;
  LIndex: Integer;
  LText: string;

  procedure Check(const AWhat: string; const AOld, ANew: Variant);
  begin
    Assert.AreEqual(string(AOld), string(ANew), LText + ' ' + AWhat + ' ' + IntToStr(LIndex));
  end;

begin
  LNewEvaluator := TFakeEvaluator.Create;
  LNewRef := LNewEvaluator;
  LOldEvaluator := TFakeEvaluator.Create;
  LOldRef := LOldEvaluator;
  LNewRandom := TFakeParamRandom.Create(ASeed);
  LNewRandomRef := LNewRandom;
  LOldRandom := TFakeParamRandom.Create(ASeed);
  LOldRandomRef := LOldRandom;
  Legacy_NRandomSource := function: Integer begin Result := LOldRandom.Next; end;
  LText := '[' + ADeclaration + ']';

  LOld := TLegacyParamList.Create(ADeclaration, LOldRef);
  LNew := TActorDefParamList.Create(ADeclaration, LNewRef, LNewRandomRef);
  try
    LOld.Actor := Pointer(9);
    LNew.Context := Pointer(9);
    Assert.AreEqual(LOld.Count, LNew.Count, LText + ' count');
    for LIndex := -1 to LOld.Count do
    begin
      if (LIndex >= 0) and (LIndex < LOld.Count) then
        Check('computed', LOld.IsComputed[LIndex], LNew.IsComputed(LIndex));
      Check('int', LOld.IntVal[LIndex], LNew.GetInteger(LIndex));
      Check('float', LOld.FloatVal[LIndex], LNew.GetFloat(LIndex));
      Check('fixed', LOld.FixedVal[LIndex], LNew.GetFixed(LIndex));
      Check('mbf21', LOld.MBF21FixedVal[LIndex], LNew.GetMBF21Fixed(LIndex));
      Check('bool', LOld.BoolVal[LIndex], LNew.GetBool(LIndex));
      Check('str', LOld.StrVal[LIndex], LNew.GetString(LIndex));
      Check('evalstr', LOld.EvaluateStrVal[LIndex], LNew.GetEvaluatedString(LIndex));
    end;
    // writes, then reads again
    for LIndex := 0 to LOld.Count - 1 do
    begin
      LOld.IntVal[LIndex] := 100 + LIndex;
      LNew.SetInteger(LIndex, 100 + LIndex);
      LOld.FloatVal[LIndex] := 0.25 * LIndex;
      LNew.SetFloat(LIndex, 0.25 * LIndex);
      Check('computed2', LOld.IsComputed[LIndex], LNew.IsComputed(LIndex));
      Check('int2', LOld.IntVal[LIndex], LNew.GetInteger(LIndex));
      Check('fixed2', LOld.FixedVal[LIndex], LNew.GetFixed(LIndex));
      Check('float2', LOld.FloatVal[LIndex], LNew.GetFloat(LIndex));
    end;
    Assert.AreEqual(LOldEvaluator.Log.Text, LNewEvaluator.Log.Text, LText + ' evaluator log');
    Assert.AreEqual(LOldRandom.Draws, LNewRandom.Draws, LText + ' draws');
    Assert.AreEqual(LOld.Declaration, LNew.Declaration);
  finally
    LNew.Free;
    LOld.Free;
  end;
end;

procedure TTestActorDefParamList.DovrebbeDareLeStesseRispostePerLeCasiDelCorpusDelVecchioCodice;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(Corpus) do
    CompareLists(Corpus[LIndex], 100 + LIndex);
end;

procedure TTestActorDefParamList.DovrebbeDareLeStesseRispostePerDichiarazioniCasuali;
var
  LRound: Integer;
  LCount: Integer;
  LPart: Integer;
  LText: string;
begin
  RandSeed := 189;
  for LRound := 1 to 1500 do
  begin
    LCount := 1 + Random(4);
    LText := '';
    for LPart := 1 to LCount do
    begin
      if LPart > 1 then
        LText := LText + ', ';
      LText := LText + Pieces[Random(Length(Pieces))];
    end;
    if Random(5) = 0 then
      LText := '(' + LText + ')';
    CompareLists(LText, LRound);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestActorDefParamList);

end.

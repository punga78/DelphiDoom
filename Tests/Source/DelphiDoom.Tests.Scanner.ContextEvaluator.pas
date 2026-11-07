{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - the expressions on a context      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.ContextEvaluator;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Scanner.Expression.Intf, DelphiDoom.Scanner.ContextEvaluator.Intf,
  DelphiDoom.Scanner.ContextEvaluator;

type
  /// <summary>The variables A = 10 and B = 20, with the number of times a value was asked</summary>
  TFakeExpressionVariables = class(TInterfacedObject, IExpressionVariables)
  public
    ValueCalls: Integer;
    function Contains(const AName: string): Boolean;
    function ValueOf(const AName: string): string;
  end;

  /// <summary>What the functions of the tests read through the context</summary>
  TFakeActor = record
    Health: Integer;
    Name: string;
  end;
  PFakeActor = ^TFakeActor;

  [TestFixture]
  [Category('scanner')]
  TTestScannerContextEvaluator = class(TObject)
  private
    FEvaluator: TContextExpressionEvaluator;
    FEvaluatorIntf: IContextExpressionEvaluator;
    FRegistry: IContextFunctionRegistry;
    FVariables: TFakeExpressionVariables;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePassareIlContestoAllaFunzione;
    [Test]
    procedure DovrebbeUsareIlContestoDellUltimaValutazione;
    [Test]
    procedure DovrebbePassareGliArgomentiAllaFunzione;
    [Test]
    procedure DovrebbeLeggereLeVariabili;
    [Test]
    procedure DovrebbeCalcolareLeEspressioniConLeFunzioni;
    [Test]
    procedure DovrebbeDareIlTestoSeLaFunzioneSollevaUnEccezione;
    [Test]
    procedure DovrebbeDareIlTestoConUnContestoNilCheNonSiPuoLeggere;
    [Test]
    procedure DovrebbeRiconoscereLeFunzioniSenzaArgomentiComeTokenSingoli;
    [Test]
    procedure DovrebbeNonRiconoscereComeTokenSingoliLeFunzioniConArgomenti;
    [Test]
    procedure DovrebbeNonRiconoscereUnNomeSconosciuto;
    [Test]
    procedure DovrebbeDareErroreConUnaFunzioneNil;
    [Test]
    procedure DovrebbeDareErroreConUnNomeRipetuto;
    [Test]
    procedure DovrebbeFunzionareSenzaLogNeVariabili;
  end;

implementation

{ TFakeExpressionVariables }

function TFakeExpressionVariables.Contains(const AName: string): Boolean;
begin
  Result := (AName = 'A') or (AName = 'B');
end;

function TFakeExpressionVariables.ValueOf(const AName: string): string;
begin
  Inc(ValueCalls);
  if AName = 'A' then
    Result := '10'
  else
    Result := '20';
end;

{ TTestScannerContextEvaluator }

procedure TTestScannerContextEvaluator.Setup;
begin
  FVariables := TFakeExpressionVariables.Create;
  FEvaluator := TContextExpressionEvaluator.Create(nil, FVariables);
  FEvaluatorIntf := FEvaluator;
  FRegistry := FEvaluator;
  FRegistry.AddFunction('HEALTH',
    function(AContext: Pointer; const AParams: TArray<string>): string
    begin
      Result := IntToStr(PFakeActor(AContext).Health);
    end, 0);
  FRegistry.AddFunction('JOIN',
    function(AContext: Pointer; const AParams: TArray<string>): string
    begin
      Result := '"' + string.Join('|', AParams) + '"';
    end, -1);
  FRegistry.AddFunction('FAIL',
    function(AContext: Pointer; const AParams: TArray<string>): string
    begin
      raise EInvalidOpException.Create('failure');
    end, 0);
end;

procedure TTestScannerContextEvaluator.TearDown;
begin
  FRegistry := nil;
  FEvaluatorIntf := nil;
  FEvaluator := nil;
end;

procedure TTestScannerContextEvaluator.DovrebbePassareIlContestoAllaFunzione;
var
  LActor: TFakeActor;
begin
  LActor.Health := 75;
  Assert.AreEqual('75', FEvaluatorIntf.Evaluate(@LActor, 'HEALTH'));
end;

procedure TTestScannerContextEvaluator.DovrebbeUsareIlContestoDellUltimaValutazione;
var
  LFirst, LSecond: TFakeActor;
begin
  LFirst.Health := 1;
  LSecond.Health := 2;
  Assert.AreEqual('1', FEvaluatorIntf.Evaluate(@LFirst, 'HEALTH'));
  Assert.AreEqual('2', FEvaluatorIntf.Evaluate(@LSecond, 'HEALTH'));
  Assert.AreEqual('1', FEvaluatorIntf.Evaluate(@LFirst, 'HEALTH'));
end;

procedure TTestScannerContextEvaluator.DovrebbePassareGliArgomentiAllaFunzione;
begin
  Assert.AreEqual('"1|2|3"', FEvaluatorIntf.Evaluate(nil, 'JOIN(1, 2, 3)'));
end;

procedure TTestScannerContextEvaluator.DovrebbeLeggereLeVariabili;
begin
  Assert.AreEqual('30', FEvaluatorIntf.Evaluate(nil, 'A + B'));
  Assert.IsTrue(FVariables.ValueCalls >= 2);
end;

procedure TTestScannerContextEvaluator.DovrebbeCalcolareLeEspressioniConLeFunzioni;
var
  LActor: TFakeActor;
begin
  LActor.Health := 40;
  Assert.AreEqual('50', FEvaluatorIntf.Evaluate(@LActor, 'HEALTH + A'));
  Assert.AreEqual('TRUE', FEvaluatorIntf.Evaluate(@LActor, 'HEALTH > 30'));
end;

procedure TTestScannerContextEvaluator.DovrebbeDareIlTestoSeLaFunzioneSollevaUnEccezione;
begin
  Assert.AreEqual('FAIL + 1', FEvaluatorIntf.Evaluate(nil, 'FAIL + 1'));
end;

procedure TTestScannerContextEvaluator.DovrebbeDareIlTestoConUnContestoNilCheNonSiPuoLeggere;
begin
  // the old SC_EvaluateActorExpression gave the text back also on an access violation
  Assert.AreEqual('HEALTH', FEvaluatorIntf.Evaluate(nil, 'HEALTH'));
end;

procedure TTestScannerContextEvaluator.DovrebbeRiconoscereLeFunzioniSenzaArgomentiComeTokenSingoli;
begin
  Assert.IsTrue(FEvaluatorIntf.IsSingleToken('HEALTH'));
  Assert.IsTrue(FEvaluatorIntf.IsSingleToken('health'));
  Assert.IsTrue(FEvaluatorIntf.IsSingleToken('Fail'));
end;

procedure TTestScannerContextEvaluator.DovrebbeNonRiconoscereComeTokenSingoliLeFunzioniConArgomenti;
begin
  Assert.IsFalse(FEvaluatorIntf.IsSingleToken('JOIN'));
end;

procedure TTestScannerContextEvaluator.DovrebbeNonRiconoscereUnNomeSconosciuto;
begin
  Assert.IsFalse(FEvaluatorIntf.IsSingleToken('ARMOR'));
  Assert.IsFalse(FEvaluatorIntf.IsSingleToken(''));
end;

procedure TTestScannerContextEvaluator.DovrebbeDareErroreConUnaFunzioneNil;
var
  LRegistry: IContextFunctionRegistry;
  LFunction: TContextExpressionFunction;
begin
  LRegistry := FRegistry;
  LFunction := nil;
  Assert.WillRaise(
    procedure
    begin
      LRegistry.AddFunction('EMPTY', LFunction, 0);
    end, EArgumentNilException);
  Assert.IsFalse(FEvaluatorIntf.IsSingleToken('EMPTY'));
end;

procedure TTestScannerContextEvaluator.DovrebbeDareErroreConUnNomeRipetuto;
var
  LRegistry: IContextFunctionRegistry;
  LFunction: TContextExpressionFunction;
begin
  LRegistry := FRegistry;
  LFunction :=
    function(AContext: Pointer; const AParams: TArray<string>): string
    begin
      Result := '';
    end;
  Assert.WillRaise(
    procedure
    begin
      LRegistry.AddFunction('join', LFunction, 0);
    end, EExpressionException);
  // as the old AddFunc, the single token is declared before the function is added
  Assert.IsTrue(FEvaluatorIntf.IsSingleToken('JOIN'));
end;

procedure TTestScannerContextEvaluator.DovrebbeFunzionareSenzaLogNeVariabili;
var
  LEvaluator: IContextExpressionEvaluator;
begin
  LEvaluator := TContextExpressionEvaluator.Create(nil, nil);
  Assert.AreEqual('7', LEvaluator.Evaluate(nil, '3 + 4'));
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptVarDef,      }
{  TDoomScriptVarDefName and TDoomScriptFunction                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.VarDef;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs,
  DelphiDoom.Tests.DoomScript.Support;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptVarDef = class
  private
    FNamespaceType: TDoomScriptTypeDef;
    FFloatType: TDoomScriptTypeDef;
    FRoot: TDoomScriptVarDef;
    FName: TDoomScriptVarDefName;
    FFirst: TDoomScriptVarDef;
    FSecond: TDoomScriptVarDef;
    FThird: TDoomScriptVarDef;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMettereInTestaIlDefPiuRecente;
    [Test]
    procedure DovrebbeTogliereIlDefInTesta;
    [Test]
    procedure DovrebbeTogliereIlDefInMezzo;
    [Test]
    procedure DovrebbeTogliereIlDefInCoda;
    [Test]
    procedure DovrebbeIgnorareUnDefCheNonEInLista;
    [Test]
    procedure DovrebbeTogliersiDalNomeQuandoVieneLiberato;
    [Test]
    procedure DovrebbeDareErrorePerIlNomeDiUnDefPredefinito;
    [Test]
    procedure DovrebbeComporreIlNomeGlobaleConGliScope;
    [Test]
    procedure DovrebbeDareIlGenereDelTipoOVoid;
    [Test]
    procedure DovrebbeContareLaProfonditaDelloScope;
    [Test]
    procedure DovrebbeDiventareCostanteConLaFunzione;
    [Test]
    procedure DovrebbePartireNonInizializzato;
    [Test]
    procedure DovrebbeSvuotareUnaFunzione;
  end;

implementation

procedure TTestDoomScriptVarDef.Setup;
begin
  FNamespaceType := TDoomScriptTypeDef.Create(evNamespace, nil, 'namespace', 4, nil);
  FFloatType := TDoomScriptTypeDef.Create(evFloat, nil, 'float', 4, nil);
  // def_namespace of the original: built in, without a name
  FRoot := TDoomScriptVarDef.Create(FNamespaceType, True);
  FName := TDoomScriptVarDefName.Create('value');
  FFirst := TDoomScriptVarDef.Create(FFloatType);
  FSecond := TDoomScriptVarDef.Create(FFloatType);
  FThird := TDoomScriptVarDef.Create(FFloatType);
end;

procedure TTestDoomScriptVarDef.TearDown;
begin
  FThird.Free;
  FSecond.Free;
  FFirst.Free;
  FName.Free;
  FRoot.Free;
  FFloatType.Free;
  FNamespaceType.Free;
end;

procedure TTestDoomScriptVarDef.DovrebbeMettereInTestaIlDefPiuRecente;
begin
  Assert.IsNull(FName.Defs);
  FName.AddDef(FFirst);
  FName.AddDef(FSecond);
  FName.AddDef(FThird);
  Assert.AreEqual('value', string(FName.Name));
  Assert.AreSame(FThird, FName.Defs);
  Assert.AreSame(FSecond, FThird.Next);
  Assert.AreSame(FFirst, FSecond.Next);
  Assert.IsNull(FFirst.Next);
  Assert.AreEqual('value', string(FFirst.Name));
end;

procedure TTestDoomScriptVarDef.DovrebbeTogliereIlDefInTesta;
begin
  FName.AddDef(FFirst);
  FName.AddDef(FSecond);
  FName.AddDef(FThird);
  FName.RemoveDef(FThird);
  Assert.AreSame(FSecond, FName.Defs);
  Assert.IsNull(FThird.Next);
  Assert.AreSame(FFirst, FSecond.Next);
end;

procedure TTestDoomScriptVarDef.DovrebbeTogliereIlDefInMezzo;
begin
  FName.AddDef(FFirst);
  FName.AddDef(FSecond);
  FName.AddDef(FThird);
  FName.RemoveDef(FSecond);
  Assert.AreSame(FThird, FName.Defs);
  Assert.AreSame(FFirst, FThird.Next);
  Assert.IsNull(FSecond.Next);
end;

procedure TTestDoomScriptVarDef.DovrebbeTogliereIlDefInCoda;
begin
  FName.AddDef(FFirst);
  FName.AddDef(FSecond);
  FName.AddDef(FThird);
  FName.RemoveDef(FFirst);
  Assert.AreSame(FThird, FName.Defs);
  Assert.AreSame(FSecond, FThird.Next);
  Assert.IsNull(FSecond.Next);
  // down to nothing
  FName.RemoveDef(FSecond);
  FName.RemoveDef(FThird);
  Assert.IsNull(FName.Defs);
end;

procedure TTestDoomScriptVarDef.DovrebbeIgnorareUnDefCheNonEInLista;
begin
  FName.AddDef(FFirst);
  FName.AddDef(FSecond);
  FName.RemoveDef(FThird);
  Assert.AreSame(FSecond, FName.Defs);
  Assert.AreSame(FFirst, FSecond.Next);
  // also with an empty list
  FName.RemoveDef(FSecond);
  FName.RemoveDef(FFirst);
  FName.RemoveDef(FThird);
  Assert.IsNull(FName.Defs);
end;

procedure TTestDoomScriptVarDef.DovrebbeTogliersiDalNomeQuandoVieneLiberato;
var
  LDef: TDoomScriptVarDef;
begin
  FName.AddDef(FFirst);
  LDef := TDoomScriptVarDef.Create(FFloatType);
  FName.AddDef(LDef);
  Assert.AreSame(LDef, FName.Defs);
  LDef.Free;
  Assert.AreSame(FFirst, FName.Defs);
end;

procedure TTestDoomScriptVarDef.DovrebbeDareErrorePerIlNomeDiUnDefPredefinito;
begin
  // a crash in the original (the name pointer is NULL)
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FRoot.Name;
    end, EDoomScriptError, 'idVarDef: a built-in definition has no name');
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      FRoot.GlobalName;
    end, EDoomScriptError);
  Assert.IsTrue(FRoot.Builtin);
  Assert.IsFalse(FFirst.Builtin);
end;

procedure TTestDoomScriptVarDef.DovrebbeComporreIlNomeGlobaleConGliScope;
var
  LSpaceName: TDoomScriptVarDefName;
  LInnerName: TDoomScriptVarDefName;
  LSpace: TDoomScriptVarDef;
  LInner: TDoomScriptVarDef;
begin
  LSpaceName := TDoomScriptVarDefName.Create('outer');
  LInnerName := TDoomScriptVarDefName.Create('inner');
  LSpace := TDoomScriptVarDef.Create(FNamespaceType);
  LInner := TDoomScriptVarDef.Create(FNamespaceType);
  try
    LSpaceName.AddDef(LSpace);
    LInnerName.AddDef(LInner);
    FName.AddDef(FFirst);
    // without a scope the name alone
    Assert.AreEqual('value', string(FFirst.GlobalName));
    // in the global namespace: the name alone
    FFirst.Scope := FRoot;
    Assert.AreEqual('value', string(FFirst.GlobalName));
    LSpace.Scope := FRoot;
    LInner.Scope := LSpace;
    FFirst.Scope := LInner;
    Assert.AreEqual('outer', string(LSpace.GlobalName));
    Assert.AreEqual('outer::inner', string(LInner.GlobalName));
    Assert.AreEqual('outer::inner::value', string(FFirst.GlobalName));
  finally
    FName.RemoveDef(FFirst);
    LInner.Free;
    LSpace.Free;
    LInnerName.Free;
    LSpaceName.Free;
  end;
end;

procedure TTestDoomScriptVarDef.DovrebbeDareIlGenereDelTipoOVoid;
var
  LDef: TDoomScriptVarDef;
begin
  Assert.IsTrue(FFirst.Kind = evFloat);
  Assert.IsTrue(FRoot.Kind = evNamespace);
  LDef := TDoomScriptVarDef.Create(nil);
  try
    Assert.IsTrue(LDef.Kind = evVoid);
    LDef.TypeDef := FFloatType;
    Assert.IsTrue(LDef.Kind = evFloat);
    Assert.AreSame(FFloatType, LDef.TypeDef);
  finally
    LDef.Free;
  end;
end;

procedure TTestDoomScriptVarDef.DovrebbeContareLaProfonditaDelloScope;
var
  LSpace: TDoomScriptVarDef;
  LInner: TDoomScriptVarDef;
begin
  LSpace := TDoomScriptVarDef.Create(FNamespaceType);
  LInner := TDoomScriptVarDef.Create(FNamespaceType);
  try
    LSpace.Scope := FRoot;
    LInner.Scope := LSpace;
    // a def of the global namespace seen from deeper and deeper scopes
    FFirst.Scope := FRoot;
    Assert.AreEqual(1, FFirst.DepthOfScope(FRoot));
    Assert.AreEqual(2, FFirst.DepthOfScope(LSpace));
    Assert.AreEqual(3, FFirst.DepthOfScope(LInner));
    // a def of an inner namespace is not visible from outside
    FSecond.Scope := LInner;
    Assert.AreEqual(1, FSecond.DepthOfScope(LInner));
    Assert.AreEqual(0, FSecond.DepthOfScope(LSpace));
    Assert.AreEqual(0, FSecond.DepthOfScope(FRoot));
    Assert.AreEqual(0, FSecond.DepthOfScope(nil));
  finally
    LInner.Free;
    LSpace.Free;
  end;
end;

procedure TTestDoomScriptVarDef.DovrebbeDiventareCostanteConLaFunzione;
var
  LFunction: TDoomScriptFunction;
begin
  LFunction := TDoomScriptFunction.Create;
  try
    FFirst.SetFunction(LFunction);
    Assert.IsTrue(FFirst.Initialized = diInitializedConstant);
    Assert.AreSame(LFunction, FFirst.FunctionPtr);
  finally
    LFunction.Free;
  end;
end;

procedure TTestDoomScriptVarDef.DovrebbePartireNonInizializzato;
begin
  Assert.IsTrue(FFirst.Initialized = diUninitialized);
  Assert.AreEqual(0, FFirst.Num);
  Assert.AreEqual(0, FFirst.Value);
  Assert.AreEqual(0, FFirst.NumUsers);
  Assert.IsNull(FFirst.Scope);
  Assert.IsNull(FFirst.FunctionPtr);
  Assert.IsNull(FFirst.Next);
end;

procedure TTestDoomScriptVarDef.DovrebbeSvuotareUnaFunzione;
var
  LFunction: TDoomScriptFunction;
begin
  LFunction := TDoomScriptFunction.Create;
  try
    LFunction.Name := 'ns::f';
    LFunction.Def := FFirst;
    LFunction.TypeDef := FFloatType;
    LFunction.FirstStatement := 10;
    LFunction.NumStatements := 5;
    LFunction.ParmTotal := 8;
    LFunction.Locals := 16;
    LFunction.FileNum := 2;
    LFunction.Index := 7;
    SetLength(LFunction.ParmSize, 2);
    LFunction.Clear;
    Assert.AreEqual('', string(LFunction.Name));
    Assert.IsNull(LFunction.Def);
    Assert.IsNull(LFunction.TypeDef);
    Assert.IsNull(LFunction.EventDef);
    Assert.AreEqual(0, LFunction.FirstStatement);
    Assert.AreEqual(0, LFunction.NumStatements);
    Assert.AreEqual(0, LFunction.ParmTotal);
    Assert.AreEqual(0, LFunction.Locals);
    Assert.AreEqual(0, LFunction.FileNum);
    Assert.AreEqual<Integer>(0, Length(LFunction.ParmSize));
    // the position in the table of the program is not part of the contents
    Assert.AreEqual(7, LFunction.Index);
  finally
    LFunction.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptVarDef);

end.

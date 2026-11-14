{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptTypeDef      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.TypeDef;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.DoomScript.Types,
  DelphiDoom.DoomScript.Defs, DelphiDoom.Tests.DoomScript.Support;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptTypeDef = class
  private
    // freed in reverse order of creation: a def must go before the name that lists it
    FOwned: TList<TObject>;
    FFloat: TDoomScriptTypeDef;
    FVector: TDoomScriptTypeDef;
    FString: TDoomScriptTypeDef;
    FVoid: TDoomScriptTypeDef;
    FObject: TDoomScriptTypeDef;
    FBase: TDoomScriptTypeDef;
    FChild: TDoomScriptTypeDef;
    function NewType(const AKind: TDoomScriptEType; const AName: AnsiString; const ASize: Integer;
      const AAux: TDoomScriptTypeDef): TDoomScriptTypeDef;
    function NewFunction(const AName: AnsiString; const AType: TDoomScriptTypeDef): TDoomScriptFunction;
    function MethodType(const ASelf: TDoomScriptTypeDef; const AExtra: TDoomScriptTypeDef = nil): TDoomScriptTypeDef;
    procedure ExpectCompileError(const AProc: TProc; const AMessage: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRiconoscereGliAntenatiDiUnOggetto;
    [Test]
    procedure DovrebbeNonEreditareSeNonEUnOggetto;
    [Test]
    procedure DovrebbeConfrontareITipiPerGenereAusiliarioEParametri;
    [Test]
    procedure DovrebbeAccettareUnMetodoVirtualeColSelfDerivato;
    [Test]
    procedure DovrebbeRifiutareUnMetodoVirtualeDiverso;
    [Test]
    procedure DovrebbeAggiungereIParametriSoloAUnaFunzione;
    [Test]
    procedure DovrebbeFarCrescereLOggettoConICampi;
    [Test]
    procedure DovrebbeRifiutareUnCampoSuUnNonOggetto;
    [Test]
    procedure DovrebbeRifiutareUnOggettoTroppoGrande;
    [Test]
    procedure DovrebbeDareIlSupertipoSoloDiUnOggetto;
    [Test]
    procedure DovrebbeDareIlTipoDiRitornoSoloDiUnaFunzione;
    [Test]
    procedure DovrebbeDareIlTipoDelCampoSoloDiUnCampo;
    [Test]
    procedure DovrebbeDareIlTipoPuntatoSoloDiUnPuntatore;
    [Test]
    procedure DovrebbeRifiutareUnParametroFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnaFunzioneFuoriIntervallo;
    [Test]
    procedure DovrebbeSostituireIlMetodoEreditato;
    [Test]
    procedure DovrebbeAccodareUnMetodoNuovoOConFirmaDiversa;
    [Test]
    procedure DovrebbeSaltareUnaFunzioneSvuotata;
    [Test]
    procedure DovrebbeCopiareTutto;
    [Test]
    procedure DovrebbeEsporreLeProprieta;
  end;

implementation

procedure TTestDoomScriptTypeDef.Setup;
begin
  FOwned := TList<TObject>.Create;
  FVoid := NewType(evVoid, 'void', 0, nil);
  FFloat := NewType(evFloat, 'float', 4, nil);
  FVector := NewType(evVector, 'vector', 12, nil);
  FString := NewType(evString, 'string', DS_MAX_STRING_LEN, nil);
  FObject := NewType(evObject, 'object', 4, nil);
  FBase := NewType(evObject, 'base', 0, FObject);
  FChild := NewType(evObject, 'child', 0, FBase);
end;

procedure TTestDoomScriptTypeDef.TearDown;
var
  LIndex: Integer;
begin
  for LIndex := FOwned.Count - 1 downto 0 do
    FOwned[LIndex].Free;
  FOwned.Free;
end;

function TTestDoomScriptTypeDef.NewType(const AKind: TDoomScriptEType; const AName: AnsiString; const ASize: Integer;
  const AAux: TDoomScriptTypeDef): TDoomScriptTypeDef;
begin
  Result := TDoomScriptTypeDef.Create(AKind, nil, AName, ASize, AAux);
  FOwned.Add(Result);
end;

function TTestDoomScriptTypeDef.MethodType(const ASelf, AExtra: TDoomScriptTypeDef): TDoomScriptTypeDef;
begin
  Result := NewType(evFunction, 'method', 4, FVoid);
  Result.AddFunctionParm(ASelf, 'self');
  if Assigned(AExtra) then
    Result.AddFunctionParm(AExtra, 'extra');
end;

function TTestDoomScriptTypeDef.NewFunction(const AName: AnsiString; const AType: TDoomScriptTypeDef): TDoomScriptFunction;
var
  LName: TDoomScriptVarDefName;
  LDef: TDoomScriptVarDef;
begin
  LName := TDoomScriptVarDefName.Create(AName);
  FOwned.Add(LName);
  LDef := TDoomScriptVarDef.Create(AType);
  FOwned.Add(LDef);
  LName.AddDef(LDef);
  Result := TDoomScriptFunction.Create;
  FOwned.Add(Result);
  Result.Name := AName;
  Result.Def := LDef;
  Result.TypeDef := AType;
  LDef.SetFunction(Result);
end;

procedure TTestDoomScriptTypeDef.ExpectCompileError(const AProc: TProc; const AMessage: string);
begin
  TDoomScriptTestSupport.ExpectError(AProc, EDoomScriptCompileError, AMessage);
end;

procedure TTestDoomScriptTypeDef.DovrebbeRiconoscereGliAntenatiDiUnOggetto;
begin
  Assert.IsTrue(FChild.Inherits(FChild));
  Assert.IsTrue(FChild.Inherits(FBase));
  Assert.IsTrue(FChild.Inherits(FObject));
  Assert.IsFalse(FBase.Inherits(FChild));
  Assert.IsFalse(FChild.Inherits(FFloat));
  Assert.IsFalse(FChild.Inherits(nil));
end;

procedure TTestDoomScriptTypeDef.DovrebbeNonEreditareSeNonEUnOggetto;
begin
  // as in the original, a type that is not an object does not even inherit from itself
  Assert.IsFalse(FFloat.Inherits(FFloat));
  Assert.IsFalse(FFloat.Inherits(FObject));
  Assert.IsFalse(FFloat.IsObject);
  Assert.IsTrue(FBase.IsObject);
end;

procedure TTestDoomScriptTypeDef.DovrebbeConfrontareITipiPerGenereAusiliarioEParametri;
var
  LFirst: TDoomScriptTypeDef;
  LSecond: TDoomScriptTypeDef;
  LOtherReturn: TDoomScriptTypeDef;
  LField: TDoomScriptTypeDef;
begin
  LFirst := NewType(evFunction, 'f', 4, FVoid);
  LSecond := NewType(evFunction, 'g', 4, FVoid);
  Assert.IsTrue(LFirst.MatchesType(LFirst));
  // the name does not count
  Assert.IsTrue(LFirst.MatchesType(LSecond));
  LOtherReturn := NewType(evFunction, 'f', 4, FFloat);
  Assert.IsFalse(LFirst.MatchesType(LOtherReturn), 'aux');
  LField := NewType(evField, 'f', 4, FVoid);
  Assert.IsFalse(LFirst.MatchesType(LField), 'kind');
  LFirst.AddFunctionParm(FFloat, 'a');
  Assert.IsFalse(LFirst.MatchesType(LSecond), 'count');
  LSecond.AddFunctionParm(FVector, 'a');
  Assert.IsFalse(LFirst.MatchesType(LSecond), 'parm type');
  LSecond := NewType(evFunction, 'h', 4, FVoid);
  LSecond.AddFunctionParm(FFloat, 'other name');
  Assert.IsTrue(LFirst.MatchesType(LSecond));
end;

procedure TTestDoomScriptTypeDef.DovrebbeAccettareUnMetodoVirtualeColSelfDerivato;
var
  LBaseMethod: TDoomScriptTypeDef;
  LChildMethod: TDoomScriptTypeDef;
begin
  LBaseMethod := MethodType(FBase, FFloat);
  LChildMethod := MethodType(FChild, FFloat);
  Assert.IsTrue(LChildMethod.MatchesVirtualFunction(LBaseMethod));
  Assert.IsTrue(LBaseMethod.MatchesVirtualFunction(LBaseMethod));
  // the other way round the self does not inherit
  Assert.IsFalse(LBaseMethod.MatchesVirtualFunction(LChildMethod));
  // without parameters there is nothing to compare
  Assert.IsTrue(NewType(evFunction, 'a', 4, FVoid).MatchesVirtualFunction(NewType(evFunction, 'b', 4, FVoid)));
end;

procedure TTestDoomScriptTypeDef.DovrebbeRifiutareUnMetodoVirtualeDiverso;
var
  LBaseMethod: TDoomScriptTypeDef;
  LOther: TDoomScriptTypeDef;
begin
  LBaseMethod := MethodType(FBase, FFloat);
  Assert.IsFalse(MethodType(FChild, FVector).MatchesVirtualFunction(LBaseMethod), 'parm type');
  Assert.IsFalse(MethodType(FChild).MatchesVirtualFunction(LBaseMethod), 'count');
  LOther := NewType(evFunction, 'method', 4, FFloat);
  LOther.AddFunctionParm(FChild, 'self');
  LOther.AddFunctionParm(FFloat, 'extra');
  Assert.IsFalse(LOther.MatchesVirtualFunction(LBaseMethod), 'return type');
  Assert.IsFalse(NewType(evField, 'method', 4, FVoid).MatchesVirtualFunction(NewType(evFunction, 'm', 4, FVoid)),
    'kind');
end;

procedure TTestDoomScriptTypeDef.DovrebbeAggiungereIParametriSoloAUnaFunzione;
var
  LFunction: TDoomScriptTypeDef;
begin
  LFunction := NewType(evFunction, 'f', 4, FVoid);
  LFunction.AddFunctionParm(FFloat, 'x');
  LFunction.AddFunctionParm(FVector, 'v');
  Assert.AreEqual(2, LFunction.NumParameters);
  Assert.AreSame(FFloat, LFunction.GetParmType(0));
  Assert.AreSame(FVector, LFunction.GetParmType(1));
  Assert.AreEqual('x', string(LFunction.GetParmName(0)));
  Assert.AreEqual('v', string(LFunction.GetParmName(1)));
  // the size of a function type does not change
  Assert.AreEqual(4, LFunction.Size);
  ExpectCompileError(
    procedure
    begin
      FFloat.AddFunctionParm(FFloat, 'x');
    end, 'idTypeDef::AddFunctionParm : tried to add parameter on non-function type');
end;

procedure TTestDoomScriptTypeDef.DovrebbeFarCrescereLOggettoConICampi;
begin
  FBase.AddField(NewType(evField, 'float field', 4, FFloat), 'x');
  Assert.AreEqual(4, FBase.Size);
  FBase.AddField(NewType(evField, 'vector field', 4, FVector), 'v');
  Assert.AreEqual(16, FBase.Size);
  FBase.AddField(NewType(evField, 'string field', 4, FString), 's');
  Assert.AreEqual(16 + DS_MAX_STRING_LEN, FBase.Size);
  // a field that is an object holds the entity number, whatever the size of the object
  FBase.AddField(NewType(evField, 'child field', 4, FChild), 'o');
  Assert.AreEqual(20 + DS_MAX_STRING_LEN, FBase.Size);
  Assert.AreEqual(4, FBase.NumParameters);
  Assert.AreEqual('s', string(FBase.GetParmName(2)));
end;

procedure TTestDoomScriptTypeDef.DovrebbeRifiutareUnCampoSuUnNonOggetto;
var
  LField: TDoomScriptTypeDef;
begin
  LField := NewType(evField, 'float field', 4, FFloat);
  ExpectCompileError(
    procedure
    begin
      FFloat.AddField(LField, 'x');
    end, 'idTypeDef::AddField : tried to add field to non-object type');
  // the type of the field must be a field type
  ExpectCompileError(
    procedure
    begin
      FBase.AddField(FFloat, 'x');
    end, 'idTypeDef::FieldType: tried to get field type on non-field type');
end;

procedure TTestDoomScriptTypeDef.DovrebbeRifiutareUnOggettoTroppoGrande;
var
  LHuge: TDoomScriptTypeDef;
  LField: TDoomScriptTypeDef;
begin
  LHuge := NewType(evString, 'huge', DS_MAX_OBJECT_SIZE, nil);
  LField := NewType(evField, 'huge field', 4, LHuge);
  // exactly the limit is allowed
  FBase.AddField(LField, 'a');
  Assert.AreEqual(DS_MAX_OBJECT_SIZE, FBase.Size);
  ExpectCompileError(
    procedure
    begin
      FBase.AddField(NewType(evField, 'float field', 4, FFloat), 'b');
    end, Format('object type ''base'' is larger than %d bytes', [DS_MAX_OBJECT_SIZE]));
end;

procedure TTestDoomScriptTypeDef.DovrebbeDareIlSupertipoSoloDiUnOggetto;
begin
  Assert.AreSame(FBase, FChild.SuperClass);
  Assert.AreSame(FObject, FBase.SuperClass);
  ExpectCompileError(
    procedure
    begin
      FFloat.SuperClass;
    end, 'idTypeDef::SuperClass : tried to get superclass of a non-object type');
end;

procedure TTestDoomScriptTypeDef.DovrebbeDareIlTipoDiRitornoSoloDiUnaFunzione;
var
  LFunction: TDoomScriptTypeDef;
begin
  LFunction := NewType(evFunction, 'f', 4, FVoid);
  Assert.AreSame(FVoid, LFunction.ReturnType);
  LFunction.SetReturnType(FFloat);
  Assert.AreSame(FFloat, LFunction.ReturnType);
  ExpectCompileError(
    procedure
    begin
      FFloat.ReturnType;
    end, 'idTypeDef::ReturnType: tried to get return type on non-function type');
  ExpectCompileError(
    procedure
    begin
      FFloat.SetReturnType(FVoid);
    end, 'idTypeDef::SetReturnType: tried to set return type on non-function type');
end;

procedure TTestDoomScriptTypeDef.DovrebbeDareIlTipoDelCampoSoloDiUnCampo;
var
  LField: TDoomScriptTypeDef;
begin
  LField := NewType(evField, '', 0, nil);
  Assert.IsNull(LField.FieldType);
  LField.SetFieldType(FVector);
  Assert.AreSame(FVector, LField.FieldType);
  ExpectCompileError(
    procedure
    begin
      FFloat.FieldType;
    end, 'idTypeDef::FieldType: tried to get field type on non-field type');
  // the message of the original names the wrong thing
  ExpectCompileError(
    procedure
    begin
      FFloat.SetFieldType(FVoid);
    end, 'idTypeDef::SetFieldType: tried to set return type on non-function type');
end;

procedure TTestDoomScriptTypeDef.DovrebbeDareIlTipoPuntatoSoloDiUnPuntatore;
var
  LPointer: TDoomScriptTypeDef;
begin
  LPointer := NewType(evPointer, 'pointer', 4, nil);
  Assert.IsNull(LPointer.PointerType);
  LPointer.SetPointerType(FFloat);
  Assert.AreSame(FFloat, LPointer.PointerType);
  ExpectCompileError(
    procedure
    begin
      FFloat.PointerType;
    end, 'idTypeDef::PointerType: tried to get pointer type on non-pointer');
  ExpectCompileError(
    procedure
    begin
      FFloat.SetPointerType(FVoid);
    end, 'idTypeDef::SetPointerType: tried to set type on non-pointer');
end;

procedure TTestDoomScriptTypeDef.DovrebbeRifiutareUnParametroFuoriIntervallo;
var
  LFunction: TDoomScriptTypeDef;
begin
  LFunction := NewType(evFunction, 'f', 4, FVoid);
  LFunction.AddFunctionParm(FFloat, 'x');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      LFunction.GetParmType(1);
    end, EDoomScriptMemoryError, 'idTypeDef: parameter 1 out of range in type ''f''');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      LFunction.GetParmName(-1);
    end, EDoomScriptMemoryError, 'idTypeDef: parameter -1 out of range in type ''f''');
end;

procedure TTestDoomScriptTypeDef.DovrebbeRifiutareUnaFunzioneFuoriIntervallo;
begin
  Assert.AreEqual(0, FBase.NumFunctions);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FBase.GetFunction(0);
    end, EDoomScriptMemoryError, 'idTypeDef: function 0 out of range in type ''base''');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FBase.GetFunction(-1);
    end, EDoomScriptMemoryError, 'idTypeDef: function -1 out of range in type ''base''');
end;

procedure TTestDoomScriptTypeDef.DovrebbeSostituireIlMetodoEreditato;
var
  LBaseMethod: TDoomScriptFunction;
  LChildMethod: TDoomScriptFunction;
  LOther: TDoomScriptFunction;
begin
  LBaseMethod := NewFunction('think', MethodType(FBase));
  LOther := NewFunction('other', MethodType(FBase));
  LChildMethod := NewFunction('think', MethodType(FChild));
  FChild.AddFunction(LOther);
  FChild.AddFunction(LBaseMethod);
  Assert.AreEqual(1, FChild.GetFunctionNumber(LBaseMethod));
  FChild.AddFunction(LChildMethod);
  // the override takes the slot of the inherited method: the index in the virtual table stays
  Assert.AreEqual(2, FChild.NumFunctions);
  Assert.AreSame(LChildMethod, FChild.GetFunction(1));
  Assert.AreEqual(-1, FChild.GetFunctionNumber(LBaseMethod));
  Assert.AreEqual(1, FChild.GetFunctionNumber(LChildMethod));
  Assert.AreSame(LOther, FChild.GetFunction(0));
end;

procedure TTestDoomScriptTypeDef.DovrebbeAccodareUnMetodoNuovoOConFirmaDiversa;
var
  LFirst: TDoomScriptFunction;
  LSameNameOtherSignature: TDoomScriptFunction;
  LNew: TDoomScriptFunction;
begin
  LFirst := NewFunction('think', MethodType(FBase));
  LSameNameOtherSignature := NewFunction('think', MethodType(FChild, FFloat));
  LNew := NewFunction('walk', MethodType(FChild));
  FChild.AddFunction(LFirst);
  FChild.AddFunction(LSameNameOtherSignature);
  FChild.AddFunction(LNew);
  Assert.AreEqual(3, FChild.NumFunctions);
  Assert.AreSame(LFirst, FChild.GetFunction(0));
  Assert.AreSame(LSameNameOtherSignature, FChild.GetFunction(1));
  Assert.AreSame(LNew, FChild.GetFunction(2));
end;

procedure TTestDoomScriptTypeDef.DovrebbeSaltareUnaFunzioneSvuotata;
var
  LCleared: TDoomScriptFunction;
  LNew: TDoomScriptFunction;
begin
  // a function a restart of the program removed has no def any more
  LCleared := NewFunction('think', MethodType(FBase));
  FChild.AddFunction(LCleared);
  LCleared.Clear;
  LNew := NewFunction('think', MethodType(FChild));
  FChild.AddFunction(LNew);
  Assert.AreEqual(2, FChild.NumFunctions);
  Assert.AreSame(LCleared, FChild.GetFunction(0));
  Assert.AreSame(LNew, FChild.GetFunction(1));
end;

procedure TTestDoomScriptTypeDef.DovrebbeCopiareTutto;
var
  LSource: TDoomScriptTypeDef;
  LCopy: TDoomScriptTypeDef;
  LTarget: TDoomScriptTypeDef;
  LMethod: TDoomScriptFunction;
  LDef: TDoomScriptVarDef;
begin
  LMethod := NewFunction('think', MethodType(FBase));
  LDef := TDoomScriptVarDef.Create(nil);
  FOwned.Add(LDef);
  LSource := NewType(evObject, 'source', 0, FBase);
  LSource.Def := LDef;
  LSource.AddField(NewType(evField, 'float field', 4, FFloat), 'x');
  LSource.AddFunction(LMethod);
  LCopy := TDoomScriptTypeDef.CreateCopy(LSource);
  FOwned.Add(LCopy);
  Assert.IsTrue(LCopy.Kind = evObject);
  Assert.AreEqual('source', string(LCopy.Name));
  Assert.AreEqual(4, LCopy.Size);
  Assert.AreSame(FBase, LCopy.AuxType);
  Assert.AreSame(LDef, LCopy.Def);
  Assert.AreEqual(1, LCopy.NumParameters);
  Assert.AreEqual('x', string(LCopy.GetParmName(0)));
  Assert.AreSame(LMethod, LCopy.GetFunction(0));
  // the copy has its own lists
  LCopy.AddField(NewType(evField, 'float field', 4, FFloat), 'y');
  Assert.AreEqual(1, LSource.NumParameters);
  Assert.AreEqual(4, LSource.Size);
  // Assign replaces what the target had
  LTarget := NewType(evFunction, 'target', 4, FVoid);
  LTarget.AddFunctionParm(FVector, 'old');
  LTarget.Assign(LSource);
  Assert.IsTrue(LTarget.Kind = evObject);
  Assert.AreEqual(1, LTarget.NumParameters);
  Assert.AreEqual('x', string(LTarget.GetParmName(0)));
  Assert.AreEqual(1, LTarget.NumFunctions);
  Assert.IsTrue(LTarget.MatchesType(LSource));
end;

procedure TTestDoomScriptTypeDef.DovrebbeEsporreLeProprieta;
begin
  Assert.IsTrue(FVector.Kind = evVector);
  Assert.AreEqual('vector', string(FVector.Name));
  Assert.AreEqual(12, FVector.Size);
  Assert.IsNull(FVector.AuxType);
  Assert.IsNull(FVector.Def);
  FVector.Name := 'renamed';
  Assert.AreEqual('renamed', string(FVector.Name));
  Assert.AreEqual(0, FVector.NumParameters);
  Assert.AreEqual(0, FVector.NumFunctions);
  Assert.AreEqual(-1, FVector.GetFunctionNumber(nil));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptTypeDef);

end.

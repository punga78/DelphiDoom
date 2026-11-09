{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the unit PS_FIXED of the scripts                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.FixedFunctions;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.Tests.ScriptHost.Fakes;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostFixedFunctions = class(TObject)
  public
    [Test]
    procedure DovrebbeChiamarsiPsFixed;
    [Test]
    procedure DovrebbeDescrivereLeNoveFunzioniNellOrdineDelleDichiarazioni;
    [Test]
    procedure DovrebbeDareAdOgniFunzioneLaSuaRoutine;
    [Test]
    procedure DovrebbeAvereLeDichiarazioniDelGoldenDellaRegistrazione;
  end;

implementation

uses
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.Fixed.Functions;

{ TTestScriptHostFixedFunctions }

procedure TTestScriptHostFixedFunctions.DovrebbeChiamarsiPsFixed;
var
  LRoutines: TScriptFixedRoutines;
begin
  FillChar(LRoutines, SizeOf(LRoutines), 0);
  Assert.AreEqual('PS_FIXED', TScriptHostFactory.CreateFixedGroup(LRoutines).UnitName);
end;

procedure TTestScriptHostFixedFunctions.DovrebbeDescrivereLeNoveFunzioniNellOrdineDelleDichiarazioni;
var
  LRoutines: TScriptFixedRoutines;
  LTable: TFakeFunctionTable;
  LTableRef: IScriptFunctionTable;
  LRoutine: TScriptFixedRoutine;
begin
  FillChar(LRoutines, SizeOf(LRoutines), 0);
  LTable := TFakeFunctionTable.Create;
  LTableRef := LTable;
  TScriptHostFactory.CreateFixedGroup(LRoutines).Describe(LTableRef);
  Assert.AreEqual(9, LTable.Declarations.Count);
  for LRoutine := Low(TScriptFixedRoutine) to High(TScriptFixedRoutine) do
    Assert.AreEqual(SCRIPT_FIXED_DECLARATIONS[LRoutine], LTable.Declarations[Ord(LRoutine)]);
end;

procedure TTestScriptHostFixedFunctions.DovrebbeDareAdOgniFunzioneLaSuaRoutine;
var
  LRoutines: TScriptFixedRoutines;
  LTable: TFakeFunctionTable;
  LTableRef: IScriptFunctionTable;
  LRoutine: TScriptFixedRoutine;
begin
  for LRoutine := Low(TScriptFixedRoutine) to High(TScriptFixedRoutine) do
    LRoutines[LRoutine] := Pointer(NativeInt(Ord(LRoutine) + 100));
  LTable := TFakeFunctionTable.Create;
  LTableRef := LTable;
  TScriptHostFactory.CreateFixedGroup(LRoutines).Describe(LTableRef);
  for LRoutine := Low(TScriptFixedRoutine) to High(TScriptFixedRoutine) do
    Assert.AreEqual(NativeInt(Ord(LRoutine) + 100), NativeInt(LTable.Codes[Ord(LRoutine)]));
end;

procedure TTestScriptHostFixedFunctions.DovrebbeAvereLeDichiarazioniDelGoldenDellaRegistrazione;
var
  LGolden: TArray<string>;
  LRoutine: TScriptFixedRoutine;
begin
  LGolden := GoldenDeclarations('PS_FIXED');
  if Length(LGolden) = 0 then
  begin
    Assert.Pass('golden della registrazione non trovato');
    Exit;
  end;
  Assert.AreEqual(9, Integer(Length(LGolden)));
  for LRoutine := Low(TScriptFixedRoutine) to High(TScriptFixedRoutine) do
    Assert.AreEqual(LGolden[Ord(LRoutine)], SCRIPT_FIXED_DECLARATIONS[LRoutine]);
end;

end.

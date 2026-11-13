{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - the lists of the library panels      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.LibraryTables;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Tests.Ide.FakeGameLibrary;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeLibraryTables = class(TObject)
  strict private
    FLibrary: TFakeIdeGameLibrary;
    FLibraryIntf: IIdeGameLibrary;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereNomeEValoreDelleCostanti;
    [Test]
    procedure DovrebbeOrdinareLeCostantiPerValoreNumerico;
    [Test]
    procedure DovrebbeMettereIValoriNonNumericiPrimaDeiNumeri;
    [Test]
    procedure DovrebbeOrdinareLeVariabiliPerTestoAnchePerValore;
    [Test]
    procedure DovrebbeFiltrareSenzaMaiuscoleEIgnorandoGliSpazi;
    [Test]
    procedure DovrebbeScrivereLaDichiarazioneDiOgniLista;
    [Test]
    procedure DovrebbeTenereLeVecchieVociSeLaLibreriaNonHaIlGioco;
    [Test]
    procedure DovrebbeTogliereIlPrefissoAUnderscoreDalleFunzioniDegliActor;
    [Test]
    procedure DovrebbeScrivereTipoUnitaENomeDelleFunzioni;
    [Test]
    procedure DovrebbeTenereLOrdineSeDuePosizioniSonoUguali;
  end;

implementation

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.NameValueTable,
  DelphiDoom.Ide.ActorDefFunctionTable,
  DelphiDoom.Ide.UnitFunctionTable;

{ TTestIdeLibraryTables }

procedure TTestIdeLibraryTables.Setup;
begin
  FLibrary := TFakeIdeGameLibrary.Create;
  FLibraryIntf := FLibrary;
end;

procedure TTestIdeLibraryTables.TearDown;
begin
  FLibraryIntf := nil;
end;

procedure TTestIdeLibraryTables.DovrebbeLeggereNomeEValoreDelleCostanti;
var
  LTable: TIdeNameValueTable;
  LRows: TArray<TIdeRow>;
begin
  FLibrary.SetLines(ldConstants, 'doom', ['A=10', ' B = 2 ', 'C']);
  LTable := TIdeNameValueTable.Create(nvConstants);
  try
    Assert.IsTrue(LTable.Load(FLibraryIntf, 'doom'));
    LRows := LTable.Rows('', 0);
    Assert.AreEqual<Integer>(3, Length(LRows));
    Assert.AreEqual('B', LRows[1].Caption);
    Assert.AreEqual('2', LRows[1].Values[0]);
    Assert.AreEqual('', LRows[2].Values[0]);
  finally
    LTable.Free;
  end;
end;

procedure TTestIdeLibraryTables.DovrebbeOrdinareLeCostantiPerValoreNumerico;
var
  LTable: TIdeNameValueTable;
  LRows: TArray<TIdeRow>;
begin
  FLibrary.SetLines(ldConstants, 'doom', ['A=10', 'B=2', 'C=1.5', 'D=2']);
  LTable := TIdeNameValueTable.Create(nvConstants);
  try
    LTable.Load(FLibraryIntf, 'doom');
    LRows := LTable.Rows('', 1);
    // 1.5, 2, 2 (in the order they came), 10
    Assert.AreEqual('C', LRows[0].Caption);
    Assert.AreEqual('B', LRows[1].Caption);
    Assert.AreEqual('D', LRows[2].Caption);
    Assert.AreEqual('A', LRows[3].Caption);
  finally
    LTable.Free;
  end;
end;

procedure TTestIdeLibraryTables.DovrebbeMettereIValoriNonNumericiPrimaDeiNumeri;
var
  LTable: TIdeNameValueTable;
  LRows: TArray<TIdeRow>;
begin
  FLibrary.SetLines(ldConstants, 'doom', ['A=5', 'B=text', 'C=1']);
  LTable := TIdeNameValueTable.Create(nvConstants);
  try
    LTable.Load(FLibraryIntf, 'doom');
    LRows := LTable.Rows('', 1);
    Assert.AreEqual('B', LRows[0].Caption);
    Assert.AreEqual('C', LRows[1].Caption);
    Assert.AreEqual('A', LRows[2].Caption);
  finally
    LTable.Free;
  end;
end;

procedure TTestIdeLibraryTables.DovrebbeOrdinareLeVariabiliPerTestoAnchePerValore;
var
  LTable: TIdeNameValueTable;
  LRows: TArray<TIdeRow>;
begin
  FLibrary.SetLines(ldVariables, 'doom', ['A=10', 'B=9']);
  LTable := TIdeNameValueTable.Create(nvVariables);
  try
    LTable.Load(FLibraryIntf, 'doom');
    LRows := LTable.Rows('', 1);
    // as text "10" comes before "9"
    Assert.AreEqual('A', LRows[0].Caption);
  finally
    LTable.Free;
  end;
end;

procedure TTestIdeLibraryTables.DovrebbeFiltrareSenzaMaiuscoleEIgnorandoGliSpazi;
var
  LTable: TIdeNameValueTable;
begin
  FLibrary.SetLines(ldConstants, 'doom', ['MAXHEALTH=100', 'MinHealth=1', 'ARMOR=2']);
  LTable := TIdeNameValueTable.Create(nvConstants);
  try
    LTable.Load(FLibraryIntf, 'doom');
    Assert.AreEqual<Integer>(2, Length(LTable.Rows('  health ', 0)));
    // the filter looks at the name, not at the value
    Assert.AreEqual<Integer>(0, Length(LTable.Rows('100', 0)));
    Assert.AreEqual<Integer>(3, Length(LTable.Rows('   ', 0)));
  finally
    LTable.Free;
  end;
end;

procedure TTestIdeLibraryTables.DovrebbeScrivereLaDichiarazioneDiOgniLista;
var
  LConstants, LVariables, LTypes: TIdeNameValueTable;
begin
  FLibrary.SetLines(ldConstants, 'doom', ['MAX=10']);
  FLibrary.SetLines(ldVariables, 'doom', ['Actors=!TActors']);
  FLibrary.SetLines(ldTypes, 'doom', ['Integer=Int']);
  LConstants := TIdeNameValueTable.Create(nvConstants);
  LVariables := TIdeNameValueTable.Create(nvVariables);
  LTypes := TIdeNameValueTable.Create(nvTypes);
  try
    LConstants.Load(FLibraryIntf, 'doom');
    LVariables.Load(FLibraryIntf, 'doom');
    LTypes.Load(FLibraryIntf, 'doom');
    Assert.AreEqual('MAX = 10;', LConstants.Declaration(0));
    Assert.AreEqual('Actors: !TActors;', LVariables.Declaration(0));
    Assert.AreEqual('Integer (Int)', LTypes.Declaration(0));
    Assert.AreEqual('MAX', LConstants.NameOf(0));
  finally
    LTypes.Free;
    LVariables.Free;
    LConstants.Free;
  end;
end;

procedure TTestIdeLibraryTables.DovrebbeTenereLeVecchieVociSeLaLibreriaNonHaIlGioco;
var
  LTable: TIdeNameValueTable;
begin
  FLibrary.SetLines(ldConstants, 'doom', ['A=1']);
  LTable := TIdeNameValueTable.Create(nvConstants);
  try
    LTable.Load(FLibraryIntf, 'doom');
    Assert.IsFalse(LTable.Load(FLibraryIntf, 'quake'));
    Assert.AreEqual(1, LTable.Count);
  finally
    LTable.Free;
  end;
end;

procedure TTestIdeLibraryTables.DovrebbeTogliereIlPrefissoAUnderscoreDalleFunzioniDegliActor;
var
  LTable: TIdeActorDefFunctionTable;
  LRows: TArray<TIdeRow>;
begin
  FLibrary.SetLines(ldActorDefFunctions, 'doom', ['A_Look()', 'a_chase(speed: Integer)', 'Plain', ' ']);
  LTable := TIdeActorDefFunctionTable.Create;
  try
    LTable.Load(FLibraryIntf, 'doom');
    LRows := LTable.Rows('', 0);
    // the empty one is dropped; "a_" in any case is removed
    Assert.AreEqual<Integer>(3, Length(LRows));
    Assert.AreEqual('chase', LRows[0].Caption);
    Assert.AreEqual('Look', LRows[1].Caption);
    Assert.AreEqual('Plain', LRows[2].Caption);
    Assert.AreEqual('A_Look()', LTable.Declaration(LRows[1].Tag));
  finally
    LTable.Free;
  end;
end;

procedure TTestIdeLibraryTables.DovrebbeScrivereTipoUnitaENomeDelleFunzioni;
var
  LTable: TIdeUnitFunctionTable;
  LUnits: TArray<TIdeUnitDeclarations>;
  LRows: TArray<TIdeRow>;
begin
  SetLength(LUnits, 1);
  LUnits[0].UnitName := 'PS_FIXED';
  LUnits[0].Declarations := TArray<string>.Create('function FixedMul(const a, b: fixed_t): fixed_t;',
    'procedure Stop;');
  FLibrary.SetUnits('doom', LUnits);
  LTable := TIdeUnitFunctionTable.Create;
  try
    LTable.Load(FLibraryIntf, 'doom');
    LRows := LTable.Rows('', 0);
    Assert.AreEqual('FixedMul', LRows[0].Caption);
    Assert.AreEqual('function', LRows[0].Values[0]);
    Assert.AreEqual('PS_FIXED', LRows[0].Values[1]);
    Assert.AreEqual('Stop', LRows[1].Caption);
    Assert.AreEqual('procedure', LRows[1].Values[0]);
  finally
    LTable.Free;
  end;
end;

procedure TTestIdeLibraryTables.DovrebbeTenereLOrdineSeDuePosizioniSonoUguali;
var
  LTable: TIdeNameValueTable;
  LRows: TArray<TIdeRow>;
begin
  FLibrary.SetLines(ldTypes, 'doom', ['B=X', 'a=Y', 'A=Z']);
  LTable := TIdeNameValueTable.Create(nvTypes);
  try
    LTable.Load(FLibraryIntf, 'doom');
    LRows := LTable.Rows('', 0);
    // "a" and "A" are equal for the sort: they stay as they came
    Assert.AreEqual('a', LRows[0].Caption);
    Assert.AreEqual('A', LRows[1].Caption);
    Assert.AreEqual('B', LRows[2].Caption);
  finally
    LTable.Free;
  end;
end;

end.

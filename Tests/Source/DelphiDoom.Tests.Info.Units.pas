{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the small classes of the info tables library (DUnitX)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Info.Units;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('info')]
  TTestInfoUnits = class
  public
    [Test]
    procedure DovrebbeLeggereUnIndiceDiSpriteInDecimale;
    [Test]
    procedure DovrebbeTrattareUnTestoCheNonEUnIndiceComeNome;
    [Test]
    procedure DovrebbeDareIlCodiceDiQuattroCaratteriEIlNome;
    [Test]
    procedure DovrebbeRifiutareUnNomeDiSpriteDiUnaLunghezzaSbagliata;
    [Test]
    procedure DovrebbeAcettareLimitiInEntrambiGliOrdini;
    [Test]
    procedure DovrebbeTrovareUnAliasAggiuntoPerUltimo;
    [Test]
    procedure DovrebbeLeggereDehActorComeNumeroDiCosa;
    [Test]
    procedure DovrebbeNonRipetereLaStessaCoppiaDiAlias;
    [Test]
    procedure DovrebbeTrovareUnaCosaConUnNumeroNegativoSenzaScrivereFuoriDallaTabella;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
    [Test]
    procedure DovrebbeRifiutareUnMostroACasoNonPreparato;
    [Test]
    procedure DovrebbeRifiutareSogliePerClassiSbagliate;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Info.DoomedNumbers,
  DelphiDoom.Info.GroupNames,
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.MobjAliases,
  DelphiDoom.Info.MobjLookup,
  DelphiDoom.Info.Range,
  DelphiDoom.Info.RandomMonsters,
  DelphiDoom.Info.SpriteNames,
  DelphiDoom.Info.SpriteStates,
  DelphiDoom.Info.StateNames,
  DelphiDoom.Info.StateWalker,
  DelphiDoom.Info.Types,
  DelphiDoom.Tests.InfoTables.Fakes,
  DelphiDoom.Tests.InfoTables.LegacyInfo,
  DelphiDoom.Tests.InfoTables.Tables;

type
  TOneThreshold = class(TInterfacedObject, IInfoRandomRules)
  public
    function Thresholds: TArray<Integer>;
    function IsMonster(const AMobj: TInfoMobj): Boolean;
    function IsValidThing(const ADoomedNum: Integer): Boolean;
    function DiscardCount: Integer;
  end;

function TOneThreshold.Thresholds: TArray<Integer>;
begin
  Result := [1];
end;

function TOneThreshold.IsMonster(const AMobj: TInfoMobj): Boolean;
begin
  Result := True;
end;

function TOneThreshold.IsValidThing(const ADoomedNum: Integer): Boolean;
begin
  Result := True;
end;

function TOneThreshold.DiscardCount: Integer;
begin
  Result := 0;
end;

procedure TTestInfoUnits.DovrebbeLeggereUnIndiceDiSpriteInDecimale;
var
  LIndex: Integer;
begin
  Assert.IsTrue(TInfoSpriteNames.TryParseIndex('3', 5, LIndex));
  Assert.AreEqual(3, LIndex);
  Assert.IsFalse(TInfoSpriteNames.TryParseIndex('7', 5, LIndex));
  Assert.IsFalse(TInfoSpriteNames.TryParseIndex('03', 5, LIndex));
end;

procedure TTestInfoUnits.DovrebbeTrattareUnTestoCheNonEUnIndiceComeNome;
var
  LIndex: Integer;
begin
  Assert.IsFalse(TInfoSpriteNames.TryParseIndex('PLAY', 5, LIndex));
  Assert.AreEqual(-1, LIndex);
end;

procedure TTestInfoUnits.DovrebbeDareIlCodiceDiQuattroCaratteriEIlNome;
var
  LCode: Integer;
begin
  Assert.IsTrue(TInfoSpriteNames.TryCode('play', LCode));
  Assert.AreEqual(Ord('P') + Ord('L') shl 8 + Ord('A') shl 16 + Ord('Y') shl 24, LCode);
  Assert.AreEqual('PLAY', TInfoSpriteNames.NameOfCode(LCode));
end;

procedure TTestInfoUnits.DovrebbeRifiutareUnNomeDiSpriteDiUnaLunghezzaSbagliata;
var
  LCode: Integer;
begin
  Assert.IsFalse(TInfoSpriteNames.TryCode('PLA', LCode));
  Assert.IsFalse(TInfoSpriteNames.TryCode('PLAYX', LCode));
end;

procedure TTestInfoUnits.DovrebbeAcettareLimitiInEntrambiGliOrdini;
begin
  Assert.IsTrue(TInfoRange.Contains(3, 1, 5));
  Assert.IsTrue(TInfoRange.Contains(3, 5, 1));
  Assert.IsFalse(TInfoRange.Contains(6, 5, 1));
  Assert.IsTrue(TInfoRange.Contains(0, 0, -1));
end;

procedure TTestInfoUnits.DovrebbeTrovareUnAliasAggiuntoPerUltimo;
var
  LAliases: TInfoMobjAliases;
begin
  LAliases := TInfoMobjAliases.Create;
  try
    LAliases.Add('Big Guy', 3);
    LAliases.Add('big guy', 4);
    Assert.AreEqual(4, LAliases.Find('BIGGUY', 10));
    Assert.AreEqual(-1, LAliases.Find('other', 10));
  finally
    LAliases.Free;
  end;
end;

procedure TTestInfoUnits.DovrebbeLeggereDehActorComeNumeroDiCosa;
var
  LAliases: TInfoMobjAliases;
begin
  LAliases := TInfoMobjAliases.Create;
  try
    Assert.AreEqual(5, LAliases.Find('deh_actor_5', 10));
    Assert.AreEqual(-1, LAliases.Find('DEH_ACTOR_50', 10));
  finally
    LAliases.Free;
  end;
end;

procedure TTestInfoUnits.DovrebbeNonRipetereLaStessaCoppiaDiAlias;
var
  LAliases: TInfoMobjAliases;
begin
  LAliases := TInfoMobjAliases.Create;
  try
    LAliases.Add('x', 1);
    LAliases.Add('X', 1);
    Assert.AreEqual(1, LAliases.Count);
  finally
    LAliases.Free;
  end;
end;

procedure TTestInfoUnits.DovrebbeTrovareUnaCosaConUnNumeroNegativoSenzaScrivereFuoriDallaTabella;
var
  LTables: IInfoMobjSource;
  LDoomed: TInfoDoomedNumbers;
  LFirst: Integer;
begin
  BuildScenario(77);
  try
    LTables := TTestInfoTables.Create;
    LDoomed := TInfoDoomedNumbers.Create(LTables);
    try
      LFirst := LDoomed.ThingForNumber(-1);
      Assert.AreEqual(LFirst, LDoomed.ThingForNumber(-1));
      Assert.AreEqual(-1, LDoomed.ThingForNumber(99999));
    finally
      LDoomed.Free;
    end;
    LTables := nil;
  finally
    FreeScenario;
  end;
end;

procedure TTestInfoUnits.DovrebbeRifiutareLeDipendenzeNil;
begin
  Assert.WillRaise(procedure begin TInfoDoomedNumbers.Create(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TInfoMobjLookup.Create(nil, nil, 30); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TInfoStateWalker.Create(nil, nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TInfoSpriteStates.Create(nil, nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TInfoGroupNames.Create('X_', 0, nil, nil, nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TInfoRandomMonsters.Create(nil, nil, nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TInfoStateNames.Create(nil, nil, nil, nil); end, EArgumentNilException);
end;

procedure TTestInfoUnits.DovrebbeRifiutareUnMostroACasoNonPreparato;
var
  LTables: IInfoMobjSource;
  LMonsters: TInfoRandomMonsters;
begin
  BuildScenario(78);
  try
    LTables := TTestInfoTables.Create;
    LMonsters := TInfoRandomMonsters.Create(LTables, TOneThreshold.Create, TFakeParamRandom.Create(1));
    try
      Assert.WillRaise(procedure begin LMonsters.Select(0); end, EInfoException);
    finally
      LMonsters.Free;
    end;
    LTables := nil;
  finally
    FreeScenario;
  end;
end;

procedure TTestInfoUnits.DovrebbeRifiutareSogliePerClassiSbagliate;
var
  LTables: IInfoMobjSource;
  LMonsters: TInfoRandomMonsters;
begin
  BuildScenario(79);
  try
    LTables := TTestInfoTables.Create;
    LMonsters := TInfoRandomMonsters.Create(LTables, TOneThreshold.Create, TFakeParamRandom.Create(1));
    try
      Assert.WillRaise(procedure begin LMonsters.Initialize; end, EInfoException);
    finally
      LMonsters.Free;
    end;
    LTables := nil;
  finally
    FreeScenario;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestInfoUnits);

end.

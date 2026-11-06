{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the definitions library - the terrain table            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Definitions.TerrainTable;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Definitions.Types, DelphiDoom.Definitions.Intf;

type
  [TestFixture]
  [Category('definitions')]
  TTestTerrainTable = class(TObject)
  private
    FTable: IDefTerrainTable;
    function Entry(const AName: string; AKind: TDefTerrainKind): TDefTerrainEntry;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestUnFlatDellaTabellaDaIlSuoTerreno;
    [Test]
    procedure TestIlNomeNonDistingueLeMaiuscole;
    [Test]
    procedure TestUnFlatSconosciutoESolido;
    [Test]
    procedure TestUnNomeVuotoESolido;
    [Test]
    procedure TestUnNomeParzialeNonCorrisponde;
    [Test]
    procedure TestVinceLaPrimaVoceConLoStessoNome;
    [Test]
    procedure TestLeVociSonoQuelleDataESiLeggonoPerIndice;
    [Test]
    procedure TestUnaTabellaVuotaDaSempreSolido;
  end;

implementation

uses
  DelphiDoom.Definitions.Factory;

{ TTestTerrainTable }

function TTestTerrainTable.Entry(const AName: string; AKind: TDefTerrainKind): TDefTerrainEntry;
begin
  Result.Name := AName;
  Result.Kind := AKind;
end;

procedure TTestTerrainTable.Setup;
begin
  FTable := TDefinitionsFactory.CreateTerrainTableFrom([Entry('WATER1', TDefTerrainKind.Water),
    Entry('LAVA1', TDefTerrainKind.Lava), Entry('WATER1', TDefTerrainKind.Ice)]);
end;

procedure TTestTerrainTable.TearDown;
begin
  FTable := nil;
end;

procedure TTestTerrainTable.TestUnFlatDellaTabellaDaIlSuoTerreno;
begin
  Assert.IsTrue(FTable.KindForName('LAVA1') = TDefTerrainKind.Lava);
end;

procedure TTestTerrainTable.TestIlNomeNonDistingueLeMaiuscole;
begin
  Assert.IsTrue(FTable.KindForName('lava1') = TDefTerrainKind.Lava);
  Assert.IsTrue(FTable.KindForName('Lava1') = TDefTerrainKind.Lava);
end;

procedure TTestTerrainTable.TestUnFlatSconosciutoESolido;
begin
  Assert.IsTrue(FTable.KindForName('FLOOR0_1') = TDefTerrainKind.Solid);
end;

procedure TTestTerrainTable.TestUnNomeVuotoESolido;
begin
  Assert.IsTrue(FTable.KindForName('') = TDefTerrainKind.Solid);
end;

procedure TTestTerrainTable.TestUnNomeParzialeNonCorrisponde;
begin
  Assert.IsTrue(FTable.KindForName('LAVA') = TDefTerrainKind.Solid);
  Assert.IsTrue(FTable.KindForName('LAVA12') = TDefTerrainKind.Solid);
end;

procedure TTestTerrainTable.TestVinceLaPrimaVoceConLoStessoNome;
begin
  Assert.IsTrue(FTable.KindForName('WATER1') = TDefTerrainKind.Water);
end;

procedure TTestTerrainTable.TestLeVociSonoQuelleDataESiLeggonoPerIndice;
begin
  Assert.AreEqual(3, FTable.Count);
  Assert.AreEqual('LAVA1', FTable.Entry(1).Name);
  Assert.IsTrue(FTable.Entry(2).Kind = TDefTerrainKind.Ice);
end;

procedure TTestTerrainTable.TestUnaTabellaVuotaDaSempreSolido;
begin
  Assert.IsTrue(TDefinitionsFactory.CreateTerrainTableFrom(nil).KindForName('WATER1') = TDefTerrainKind.Solid);
end;

end.

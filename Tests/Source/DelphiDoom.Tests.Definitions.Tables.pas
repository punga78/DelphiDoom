{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the definitions library - the tables of the games      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Definitions.Tables;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Definitions.Types;

type
  [TestFixture]
  [Category('definitions')]
  TTestDefinitionsTables = class(TObject)
  public
    [Test]
    procedure TestLeTabelleDegliInterruttoriHannoLeVociDelGioco;
    [Test]
    procedure TestNessunaTabellaHaIlTerminatore;
    [Test]
    procedure TestOgniVoceHaDueNomiDiOttoCaratteriAlMassimo;
    [Test]
    procedure TestInDoomGliEpisodiVannoDaUnoATre;
    [Test]
    procedure TestInHereticGliEpisodiSonoZero;
    [Test]
    procedure TestInHexenEInStrifeLaSuoneriaHaIlNomeDellaCostante;
    [Test]
    procedure TestInDoomLaSuoneriaNonCE;
    [Test]
    procedure TestIlTerrenoDiHexenHaIlGhiaccio;
    [Test]
    procedure TestHereticNonHaNukage;
    [Test]
    procedure TestInDoomLaSelezioneDellaTabellaFissaPortaTutteLeVociDelPrimoEpisodio;
    [Test]
    procedure TestLeTabelleDelTerrenoHannoLeVociDelGioco;
    [Test]
    procedure TestDueRichiesteDannoCopieIndipendenti;
  end;

implementation

uses
  DelphiDoom.Definitions.Intf, DelphiDoom.Definitions.Factory;

{ TTestDefinitionsTables }

procedure TTestDefinitionsTables.TestLeTabelleDegliInterruttoriHannoLeVociDelGioco;
begin
  Assert.AreEqual<Integer>(40, Length(TDefinitionsFactory.CreateSwitchTable(TDefGame.Doom)));
  Assert.AreEqual<Integer>(2, Length(TDefinitionsFactory.CreateSwitchTable(TDefGame.Heretic)));
  Assert.AreEqual<Integer>(10, Length(TDefinitionsFactory.CreateSwitchTable(TDefGame.Hexen)));
  Assert.AreEqual<Integer>(69, Length(TDefinitionsFactory.CreateSwitchTable(TDefGame.Strife)));
end;

procedure TTestDefinitionsTables.TestNessunaTabellaHaIlTerminatore;
var
  LGame: TDefGame;
  LPair: TDefSwitchPair;
begin
  for LGame := Low(TDefGame) to High(TDefGame) do
    for LPair in TDefinitionsFactory.CreateSwitchTable(LGame) do
    begin
      Assert.IsTrue(LPair.Name1 <> '');
      Assert.IsTrue(LPair.Name2 <> '');
      Assert.AreNotEqual(-1, Integer(LPair.Episode));
    end;
end;

procedure TTestDefinitionsTables.TestOgniVoceHaDueNomiDiOttoCaratteriAlMassimo;
var
  LGame: TDefGame;
  LPair: TDefSwitchPair;
begin
  for LGame := Low(TDefGame) to High(TDefGame) do
    for LPair in TDefinitionsFactory.CreateSwitchTable(LGame) do
    begin
      Assert.IsTrue(Length(LPair.Name1) <= DEFINITIONS_NAME_LENGTH, LPair.Name1);
      Assert.IsTrue(Length(LPair.Name2) <= DEFINITIONS_NAME_LENGTH, LPair.Name2);
    end;
end;

procedure TTestDefinitionsTables.TestInDoomGliEpisodiVannoDaUnoATre;
var
  LPair: TDefSwitchPair;
begin
  for LPair in TDefinitionsFactory.CreateSwitchTable(TDefGame.Doom) do
    Assert.IsTrue((LPair.Episode >= 1) and (LPair.Episode <= 3), LPair.Name1);
end;

procedure TTestDefinitionsTables.TestInHereticGliEpisodiSonoZero;
var
  LPair: TDefSwitchPair;
begin
  for LPair in TDefinitionsFactory.CreateSwitchTable(TDefGame.Heretic) do
    Assert.AreEqual(0, Integer(LPair.Episode));
end;

procedure TTestDefinitionsTables.TestInHexenEInStrifeLaSuoneriaHaIlNomeDellaCostante;
var
  LPair: TDefSwitchPair;
begin
  for LPair in TDefinitionsFactory.CreateSwitchTable(TDefGame.Hexen) do
    Assert.IsTrue(LPair.SoundName <> '', LPair.Name1);
  for LPair in TDefinitionsFactory.CreateSwitchTable(TDefGame.Strife) do
    Assert.IsTrue(LPair.SoundName <> '', LPair.Name1);
end;

procedure TTestDefinitionsTables.TestInDoomLaSuoneriaNonCE;
var
  LPair: TDefSwitchPair;
begin
  for LPair in TDefinitionsFactory.CreateSwitchTable(TDefGame.Doom) do
    Assert.AreEqual('', LPair.SoundName);
end;

procedure TTestDefinitionsTables.TestIlTerrenoDiHexenHaIlGhiaccio;
begin
  Assert.IsTrue(TDefinitionsFactory.CreateTerrainTable(TDefGame.Hexen).KindForName('F_033') = TDefTerrainKind.Ice);
end;

procedure TTestDefinitionsTables.TestHereticNonHaNukage;
var
  LTable: IDefTerrainTable;
  LIndex: Integer;
begin
  LTable := TDefinitionsFactory.CreateTerrainTable(TDefGame.Heretic);
  for LIndex := 0 to LTable.Count - 1 do
    Assert.IsTrue(LTable.Entry(LIndex).Kind <> TDefTerrainKind.Nukage);
end;

procedure TTestDefinitionsTables.TestInDoomLaSelezioneDellaTabellaFissaPortaTutteLeVociDelPrimoEpisodio;
var
  LTable: TArray<TDefSwitchPair>;
  LPair: TDefSwitchPair;
  LCount: Integer;
begin
  LTable := TDefinitionsFactory.CreateSwitchTable(TDefGame.Doom);
  LCount := 0;
  for LPair in LTable do
    if LPair.Episode = 1 then
      Inc(LCount);
  Assert.AreEqual(19, LCount);
end;

procedure TTestDefinitionsTables.TestLeTabelleDelTerrenoHannoLeVociDelGioco;
begin
  Assert.AreEqual(23, TDefinitionsFactory.CreateTerrainTable(TDefGame.Doom).Count);
  Assert.AreEqual(5, TDefinitionsFactory.CreateTerrainTable(TDefGame.Heretic).Count);
  Assert.AreEqual(4, TDefinitionsFactory.CreateTerrainTable(TDefGame.Hexen).Count);
  Assert.AreEqual(12, TDefinitionsFactory.CreateTerrainTable(TDefGame.Strife).Count);
end;

procedure TTestDefinitionsTables.TestDueRichiesteDannoCopieIndipendenti;
var
  LFirst: TArray<TDefSwitchPair>;
begin
  LFirst := TDefinitionsFactory.CreateSwitchTable(TDefGame.Doom);
  LFirst[0].Name1 := 'CAMBIATO';
  Assert.AreEqual('SW1BRCOM', TDefinitionsFactory.CreateSwitchTable(TDefGame.Doom)[0].Name1);
end;

end.

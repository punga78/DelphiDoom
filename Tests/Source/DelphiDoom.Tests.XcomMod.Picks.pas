{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ruleset library - the random picks of     }
{  the map scripts and of the mission scripts                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.Picks;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.MapScript, DelphiDoom.XcomMod.RuleTerrain,
  DelphiDoom.XcomMod.RuleMissionScript, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.RuleRegistry, DelphiDoom.XcomMod.MapDataSet, DelphiDoom.Tests.XcomMod.Globe;

type
  [TestFixture]
  [Category('xcom-mod')]
  [Category('xcom-mod-picks')]
  TTestXcomPicks = class(TObject)
  strict private
    function Parse(const AText: string): IYamlNode;
    function Command(const AText: string): TXcomMapScript;
  public
    [Test]
    procedure DovrebbeDareIlGruppoPredefinitoSenzaGruppi;
    [Test]
    procedure DovrebbeScegliereIlBloccoPerFrequenza;
    [Test]
    procedure DovrebbeTogliereIlBloccoQuandoHaFinitoGliUsi;
    [Test]
    procedure DovrebbeDareNonDefinitoQuandoLeFrequenzeSonoFinite;
    [Test]
    procedure DovrebbeRipartireDaCapoConInit;
    [Test]
    procedure DovrebbeDareNilSeIlNumeroDelBloccoNonEsiste;
    [Test]
    procedure DovrebbeScegliereLeMissioniDelMeseGiusto;
    [Test]
    procedure DovrebbeSollevareErroreSenzaPesiPerIlMese;
    [Test]
    procedure DovrebbeGenerareDaiPesiDelMese;
  end;

implementation

{ TTestXcomPicks }

function TTestXcomPicks.Parse(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(AText));
end;

function TTestXcomPicks.Command(const AText: string): TXcomMapScript;
begin
  Result := TXcomMapScript.Create;
  Result.Load(Parse(AText));
  Result.Init;
end;

procedure TTestXcomPicks.DovrebbeDareIlGruppoPredefinitoSenzaGruppi;
var
  LCommand: TXcomMapScript;
begin
  LCommand := Command('{type: addBlock, blocks: [3, 4]}');
  try
    Assert.AreEqual(0, LCommand.GetGroupNumber(TXcomFixedRandom.Create(1)));
  finally
    LCommand.Free;
  end;
end;

procedure TTestXcomPicks.DovrebbeScegliereIlBloccoPerFrequenza;
var
  LCommand: TXcomMapScript;
begin
  LCommand := Command('{type: addBlock, blocks: [3, 4, 5], freqs: [2, 1, 3]}');
  try
    // the picks 0..1 are the first block, 2 the second, 3..5 the third
    Assert.AreEqual(3, LCommand.GetBlockNumber(TXcomFixedRandom.Create(1)));
    Assert.AreEqual(4, LCommand.GetBlockNumber(TXcomFixedRandom.Create(2)));
    Assert.AreEqual(5, LCommand.GetBlockNumber(TXcomFixedRandom.Create(5)));
  finally
    LCommand.Free;
  end;
end;

procedure TTestXcomPicks.DovrebbeTogliereIlBloccoQuandoHaFinitoGliUsi;
var
  LCommand: TXcomMapScript;
begin
  LCommand := Command('{type: addBlock, blocks: [3, 4], freqs: [1, 1], maxUses: [1, -1]}');
  try
    Assert.AreEqual(3, LCommand.GetBlockNumber(TXcomFixedRandom.Create(0)));
    // the first block is gone: every pick is the second
    Assert.AreEqual(4, LCommand.GetBlockNumber(TXcomFixedRandom.Create(0)));
    Assert.AreEqual(4, LCommand.GetBlockNumber(TXcomFixedRandom.Create(0)));
  finally
    LCommand.Free;
  end;
end;

procedure TTestXcomPicks.DovrebbeDareNonDefinitoQuandoLeFrequenzeSonoFinite;
var
  LCommand: TXcomMapScript;
begin
  LCommand := Command('{type: addBlock, blocks: [3], maxUses: [1]}');
  try
    Assert.AreEqual(3, LCommand.GetBlockNumber(TXcomFixedRandom.Create(0)));
    Assert.AreEqual(-1, LCommand.GetBlockNumber(TXcomFixedRandom.Create(0)));
  finally
    LCommand.Free;
  end;
end;

procedure TTestXcomPicks.DovrebbeRipartireDaCapoConInit;
var
  LCommand: TXcomMapScript;
begin
  LCommand := Command('{type: addBlock, blocks: [3], maxUses: [1]}');
  try
    LCommand.GetBlockNumber(TXcomFixedRandom.Create(0));
    LCommand.Init;
    Assert.AreEqual(3, LCommand.GetBlockNumber(TXcomFixedRandom.Create(0)));
  finally
    LCommand.Free;
  end;
end;

procedure TTestXcomPicks.DovrebbeDareNilSeIlNumeroDelBloccoNonEsiste;
var
  LCommand: TXcomMapScript;
  LTerrain: TXcomRuleTerrain;
begin
  LCommand := Command('{type: addBlock, blocks: [7]}');
  LTerrain := TXcomRuleTerrain.Create('T');
  try
    Assert.IsNull(LCommand.GetNextBlock(LTerrain, TXcomFixedRandom.Create(0)));
  finally
    LTerrain.Free;
    LCommand.Free;
  end;
end;

procedure TTestXcomPicks.DovrebbeScegliereLeMissioniDelMeseGiusto;
var
  LScript: TXcomRuleMissionScript;
begin
  LScript := TXcomRuleMissionScript.Create('S');
  try
    LScript.Load(Parse('{missionWeights: {0: {A: 1}, 6: {B: 1}, 12: {C: 1}}, regionWeights: {3: {R: 1}}}'));
    Assert.AreEqual('A', string.Join(',', LScript.GetMissionTypes(-5)));
    Assert.AreEqual('A', string.Join(',', LScript.GetMissionTypes(5)));
    Assert.AreEqual('B', string.Join(',', LScript.GetMissionTypes(6)));
    Assert.AreEqual('C', string.Join(',', LScript.GetMissionTypes(40)));
    // before the first month of the regions the first set is used (the C++ walks to the start and steps back)
    Assert.AreEqual('R', string.Join(',', LScript.GetRegions(0)));
  finally
    LScript.Free;
  end;
end;

procedure TTestXcomPicks.DovrebbeSollevareErroreSenzaPesiPerIlMese;
var
  LScript: TXcomRuleMissionScript;
begin
  LScript := TXcomRuleMissionScript.Create('S');
  try
    Assert.WillRaise(procedure begin LScript.GetMissionTypes(0); end, EXcomModException);
    Assert.WillRaise(procedure begin LScript.Generate(0, 1, TXcomFixedRandom.Create(0)); end, EXcomModException);
    LScript.Load(Parse('{missionWeights: {6: {B: 1}}}'));
    // no set at or before month 3: the C++ reads before the start of the vector
    Assert.WillRaise(procedure begin LScript.Generate(3, 1, TXcomFixedRandom.Create(0)); end, EXcomModException);
  finally
    LScript.Free;
  end;
end;

procedure TTestXcomPicks.DovrebbeGenerareDaiPesiDelMese;
var
  LScript: TXcomRuleMissionScript;
begin
  LScript := TXcomRuleMissionScript.Create('S');
  try
    LScript.Load(Parse('{missionWeights: {0: {A: 1}, 6: {B: 1}}, raceWeights: {0: {X: 1}}, regionWeights: {0: {R: 1}}}'));
    Assert.AreEqual('A', LScript.Generate(2, 1, TXcomFixedRandom.Create(0)));
    Assert.AreEqual('B', LScript.Generate(9, 1, TXcomFixedRandom.Create(0)));
    Assert.AreEqual('X', LScript.Generate(9, 2, TXcomFixedRandom.Create(0)));
    Assert.AreEqual('R', LScript.Generate(9, 0, TXcomFixedRandom.Create(0)));
  finally
    LScript.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomPicks);

end.

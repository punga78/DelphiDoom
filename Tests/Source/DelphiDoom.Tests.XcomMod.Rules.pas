{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom ruleset library - the rules one by one         }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.Rules;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Areas,
  DelphiDoom.XcomMod.WeightedOptions, DelphiDoom.XcomMod.RuleInventory, DelphiDoom.XcomMod.RuleCountry,
  DelphiDoom.XcomMod.RuleRegion, DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomMod.RuleManufacture,
  DelphiDoom.XcomMod.AlienRace, DelphiDoom.XcomMod.UfoTrajectory, DelphiDoom.XcomMod.RuleMusic,
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.RuleCommendations;

type
  [TestFixture]
  [Category('xcom-mod')]
  TTestXcomModRules = class(TObject)
  private
    function Node(const AText: string): IYamlNode;
  public
    [Test]
    procedure DovrebbeTenereLeChiaviInOrdineDiByteUtf8;
    [Test]
    procedure DovrebbeSostituireIlValoreDiUnaChiaveEsistente;
    [Test]
    procedure DovrebbeCopiareEdEliminareLeChiavi;
    [Test]
    procedure DovrebbeConfrontareIByteUtf8NonLeUnitaUtf16;
    [Test]
    procedure DovrebbeGenerareLaSerieDiXorshift;
    [Test]
    procedure DovrebbeRifiutareUnIntervalloVuoto;
    [Test]
    procedure DovrebbeDareIlMinimoSeIlIntervalloRealeEVuoto;
    [Test]
    procedure DovrebbeLeggereIlSeme;
    [Test]
    procedure DovrebbeUsareIlPredefinitoSeLaChiaveMancaOHaUnTipoSbagliato;
    [Test]
    procedure DovrebbeLeggereLeListeDiTesto;
    [Test]
    procedure DovrebbeLeggereUnaMappaDiTestoEInteri;
    [Test]
    procedure DovrebbeRifiutareUnaRigaChePariNonEUnaSequenza;
    [Test]
    procedure DovrebbeConvertireGradiERadianti;
    [Test]
    procedure DovrebbeInvertireLaLatitudineDiUnaAreaRovesciata;
    [Test]
    procedure DovrebbeRifiutareUnAreaCortaDiUnPaese;
    [Test]
    procedure DovrebbeTrovareUnPuntoInUnaAreaCheAttraversaIlMeridiano;
    [Test]
    procedure DovrebbeDareIlCostoDiUnaSezioneDellInventario;
    [Test]
    procedure DovrebbeRifiutareUnCostoSconosciuto;
    [Test]
    procedure DovrebbeRiconoscereLaManoELaTerra;
    [Test]
    procedure DovrebbeRifiutareUnoSlotNonValido;
    [Test]
    procedure DovrebbeScegliereLOpzioneConPesoEMostrarneINomi;
    [Test]
    procedure DovrebbeLevareUnOpzioneConPesoZero;
    [Test]
    procedure DovrebbeLeggereLaRegioneEIPuntiCasuali;
    [Test]
    procedure DovrebbeRifiutareUnaZonaCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnaRicercaConRequisitiECosto;
    [Test]
    procedure DovrebbeUsareLOrdineDellaListaSeNonLoDaLaRegola;
    [Test]
    procedure DovrebbeRinominareLaProduzioneConLProgetto;
    [Test]
    procedure DovrebbeLeggereIlMembroDiUnaRazza;
    [Test]
    procedure DovrebbeRifiutareUnMembroFuoriDallaLista;
    [Test]
    procedure DovrebbeLeggereLeTappeDiUnaTraiettoria;
    [Test]
    procedure DovrebbeScalareLaVelocitaDiUnaTappa;
    [Test]
    procedure DovrebbeDareIlTipoComeNomeDellaMusicaSenzaNome;
    [Test]
    procedure DovrebbeLeggereLaNormalizzazioneDellaMusica;
    [Test]
    procedure DovrebbeRifiutareUnBloccoCheNonESuMultipliDiDieci;
    [Test]
    procedure DovrebbeLeggereIGruppiComeListaOComeNumero;
    [Test]
    procedure DovrebbeLeggereLePosizioniDegliOggettiDelBlocco;
    [Test]
    procedure DovrebbeLeggereICriteriDiUnaMenzione;
    [Test]
    procedure DovrebbeRifiutareUnaCondizioneDiUccisioneNonValida;
  end;

implementation

{ TTestXcomModRules }

function TTestXcomModRules.Node(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(YamlStringToText(AText));
end;

procedure TTestXcomModRules.DovrebbeTenereLeChiaviInOrdineDiByteUtf8;
var
  LMap: TXcomStringMap<Integer>;
begin
  LMap := TXcomStringMap<Integer>.Create;
  try
    LMap.SetValue('b', 2);
    LMap.SetValue('a', 1);
    LMap.SetValue('c', 3);
    Assert.AreEqual(3, LMap.Count);
    Assert.AreEqual('a', LMap.Key(0));
    Assert.AreEqual('c', LMap.Key(2));
    Assert.AreEqual(2, LMap.Value(1));
  finally
    LMap.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeSostituireIlValoreDiUnaChiaveEsistente;
var
  LMap: TXcomStringMap<Integer>;
  LValue: Integer;
begin
  LMap := TXcomStringMap<Integer>.Create;
  try
    LMap.SetValue('a', 1);
    LMap.SetValue('a', 5);
    Assert.AreEqual(1, LMap.Count);
    Assert.IsTrue(LMap.TryGetValue('a', LValue));
    Assert.AreEqual(5, LValue);
    Assert.IsFalse(LMap.TryGetValue('b', LValue));
    Assert.IsTrue(LMap.ContainsKey('a'));
  finally
    LMap.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeCopiareEdEliminareLeChiavi;
var
  LMap, LCopy: TXcomStringMap<Integer>;
begin
  LMap := TXcomStringMap<Integer>.Create;
  try
    LMap.SetValue('a', 1);
    LMap.SetValue('b', 2);
    LCopy := LMap.Copy;
    try
      LMap.Remove('a');
      LMap.Remove('zz');
      Assert.AreEqual(1, LMap.Count);
      Assert.AreEqual(2, LCopy.Count);
      LCopy.Clear;
      Assert.AreEqual(0, LCopy.Count);
    finally
      LCopy.Free;
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeConfrontareIByteUtf8NonLeUnitaUtf16;
begin
  // U+FF5E is one UTF-16 unit below the surrogates of U+1F600 but its UTF-8 bytes go before them
  Assert.IsTrue(XcomCompareUtf8(string(Char($FF5E)), string(Char($D83D) + Char($DE00))) < 0);
  Assert.IsTrue(XcomCompareUtf8('ab', 'abc') < 0);
  Assert.AreEqual(0, XcomCompareUtf8('x', 'x'));
end;

procedure TTestXcomModRules.DovrebbeGenerareLaSerieDiXorshift;
var
  LFirst, LSecond: IXcomRandom;
  LIndex: Integer;
begin
  LFirst := TXcomRandom.Create(1);
  LSecond := TXcomRandom.Create(1);
  for LIndex := 1 to 20 do
    Assert.AreEqual(LFirst.Generate(0, 99), LSecond.Generate(0, 99));
  Assert.IsTrue(LFirst.Seed <> 1);
  LFirst.SetSeed(1);
  Assert.AreEqual(UInt64(1), LFirst.Seed);
end;

procedure TTestXcomModRules.DovrebbeRifiutareUnIntervalloVuoto;
var
  LRandom: IXcomRandom;
begin
  LRandom := TXcomRandom.Create(5);
  Assert.WillRaise(
    procedure
    begin
      LRandom.Generate(5, 4);
    end, EXcomModException);
end;

procedure TTestXcomModRules.DovrebbeDareIlMinimoSeIlIntervalloRealeEVuoto;
var
  LRandom: IXcomRandom;
begin
  LRandom := TXcomRandom.Create(5);
  Assert.AreEqual(Double(2.5), LRandom.Generate(Double(2.5), Double(2.5)));
  Assert.IsTrue(LRandom.Generate(Double(1.0), Double(2.0)) >= 1.0);
end;

procedure TTestXcomModRules.DovrebbeLeggereIlSeme;
var
  LRandom: IXcomRandom;
begin
  LRandom := TXcomRandom.Create(12345);
  Assert.AreEqual(UInt64(12345), LRandom.Seed);
end;

procedure TTestXcomModRules.DovrebbeUsareIlPredefinitoSeLaChiaveMancaOHaUnTipoSbagliato;
var
  LNode: IYamlNode;
begin
  LNode := Node('a: [1, 2]' + #10 + 'b: abc' + #10 + 'c: 7' + #10 + 'd: yes' + #10 + 'e: 1.5' + #10 + 'f: 9');
  Assert.AreEqual(3, TXcomNodeReader.ReadInteger(LNode, 'a', 3));
  Assert.AreEqual(3, TXcomNodeReader.ReadInteger(LNode, 'b', 3));
  Assert.AreEqual(3, TXcomNodeReader.ReadInteger(LNode, 'missing', 3));
  Assert.AreEqual(7, TXcomNodeReader.ReadInteger(LNode, 'c', 3));
  Assert.IsTrue(TXcomNodeReader.ReadBoolean(LNode, 'd', False));
  Assert.AreEqual(Double(1.5), TXcomNodeReader.ReadDouble(LNode, 'e', 0));
  Assert.AreEqual(Cardinal(9), TXcomNodeReader.ReadSize(LNode, 'f', 0));
  Assert.AreEqual('abc', TXcomNodeReader.ReadString(LNode, 'b', 'x'));
  Assert.AreEqual('x', TXcomNodeReader.ReadString(LNode, 'a', 'x'));
end;

procedure TTestXcomModRules.DovrebbeLeggereLeListeDiTesto;
var
  LNode: IYamlNode;
  LValues: TArray<string>;
begin
  LNode := Node('a: [x, y, z]' + #10 + 'b: scalar' + #10 + 'c: [x, [1]]');
  LValues := TXcomNodeReader.ReadStrings(LNode, 'a', nil);
  Assert.AreEqual<Integer>(3, Length(LValues));
  Assert.AreEqual('y', LValues[1]);
  Assert.AreEqual<Integer>(0, Length(TXcomNodeReader.ReadStrings(LNode, 'b', nil)));
  Assert.WillRaise(
    procedure
    begin
      TXcomNodeReader.ReadStrings(LNode, 'c', nil);
    end, EYamlBadConversion);
end;

procedure TTestXcomModRules.DovrebbeLeggereUnaMappaDiTestoEInteri;
var
  LNode: IYamlNode;
  LMap: TXcomStringMap<Integer>;
begin
  LNode := Node('m: {b: 2, a: 1}' + #10 + 'n: [1]' + #10 + 'bad: {a: x}');
  LMap := TXcomStringMap<Integer>.Create;
  try
    TXcomNodeReader.ReadStringIntMap(LNode, 'm', LMap);
    Assert.AreEqual(2, LMap.Count);
    Assert.AreEqual('a', LMap.Key(0));
    TXcomNodeReader.ReadStringIntMap(LNode, 'n', LMap);
    Assert.AreEqual(2, LMap.Count, 'una sequenza lascia la mappa com''e''');
    Assert.WillRaise(
      procedure
      begin
        TXcomNodeReader.ReadStringIntMap(LNode, 'bad', LMap);
      end, EYamlBadConversion);
  finally
    LMap.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRifiutareUnaRigaChePariNonEUnaSequenza;
var
  LNode: IYamlNode;
begin
  LNode := Node('rows: [1, 2]' + #10 + 'ok: [[1, 2], [3]]');
  Assert.WillRaise(
    procedure
    begin
      TXcomNodeReader.ReadDoubleRows(LNode, 'rows', nil);
    end, EYamlBadConversion);
  Assert.AreEqual<Integer>(2, Length(TXcomNodeReader.ReadDoubleRows(LNode, 'ok', nil)));
  Assert.AreEqual<Integer>(0, Length(TXcomNodeReader.ReadDoubleRows(LNode, 'missing', nil)));
end;

procedure TTestXcomModRules.DovrebbeConvertireGradiERadianti;
begin
  Assert.AreEqual(Double(0), XcomDegToRad(0));
  Assert.AreEqual(Double(XCOM_PI), XcomDegToRad(180));
  Assert.AreEqual(Double(180), XcomRadToDeg(XCOM_PI));
end;

procedure TTestXcomModRules.DovrebbeInvertireLaLatitudineDiUnaAreaRovesciata;
var
  LRule: TXcomRuleRegion;
begin
  LRule := TXcomRuleRegion.Create('STR_R');
  try
    LRule.Load(Node('areas: [[0, 90, 40, -40]]'));
    Assert.IsTrue(LRule.IsInside(1.0, 0.1));
    Assert.IsFalse(LRule.IsInside(1.0, 1.5));
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRifiutareUnAreaCortaDiUnPaese;
var
  LRule: TXcomRuleCountry;
begin
  LRule := TXcomRuleCountry.Create('STR_X');
  try
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('areas: [[1, 2]]'));
      end, EXcomModException);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeTrovareUnPuntoInUnaAreaCheAttraversaIlMeridiano;
var
  LRule: TXcomRuleCountry;
begin
  LRule := TXcomRuleCountry.Create('STR_X');
  try
    LRule.Load(Node('type: STR_Y' + #10 + 'fundingBase: 4' + #10 + 'fundingCap: 9' + #10 + 'labelLon: 90' +
      #10 + 'labelLat: 45' + #10 + 'areas: [[300, 30, -10, 10]]'));
    Assert.AreEqual('STR_Y', LRule.CountryType);
    Assert.AreEqual(9, LRule.FundingCap);
    Assert.AreEqual(Double(XCOM_PI / 2), LRule.LabelLongitude);
    Assert.IsTrue(LRule.IsInside(0.1, 0.0));
    Assert.IsTrue(LRule.IsInside(6.0, 0.0), 'prima della fine del cerchio');
    Assert.IsFalse(LRule.IsInside(3.0, 0.0));
    Assert.IsTrue(LRule.GenerateFunding(TXcomRandom.Create(3)) mod 1000 = 0);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeDareIlCostoDiUnaSezioneDellInventario;
var
  LRule, LOther: TXcomRuleInventory;
begin
  LRule := TXcomRuleInventory.Create('STR_A');
  LOther := TXcomRuleInventory.Create('STR_B');
  try
    LRule.Load(Node('costs: {STR_B: 6}'), 2);
    Assert.AreEqual(6, LRule.GetCost(LOther));
    Assert.AreEqual(0, LRule.GetCost(LRule));
    Assert.IsTrue(LRule.HasCostFor('STR_B'));
    Assert.IsFalse(LRule.HasCostFor('STR_C'));
    Assert.AreEqual(2, LRule.ListOrder);
  finally
    LOther.Free;
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRifiutareUnCostoSconosciuto;
var
  LRule, LOther: TXcomRuleInventory;
begin
  LRule := TXcomRuleInventory.Create('STR_A');
  LOther := TXcomRuleInventory.Create('STR_B');
  try
    Assert.WillRaise(
      procedure
      begin
        LRule.GetCost(LOther);
      end, EXcomModException);
  finally
    LOther.Free;
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRiconoscereLaManoELaTerra;
var
  LHand, LGround: TXcomRuleInventory;
begin
  LHand := TXcomRuleInventory.Create('STR_HAND');
  LGround := TXcomRuleInventory.Create('STR_GROUND');
  try
    LHand.Load(Node('x: 10' + #10 + 'y: 20' + #10 + 'type: 1'), 0);
    LGround.Load(Node('x: 100' + #10 + 'y: 50' + #10 + 'type: 2'), 0);
    Assert.IsTrue(LHand.IsSlotInPosition(10, 20));
    Assert.IsTrue(LHand.IsSlotInPosition(10 + 2 * 16 - 1, 20 + 3 * 16 - 1));
    Assert.IsFalse(LHand.IsSlotInPosition(10 + 2 * 16, 20));
    Assert.IsTrue(LGround.IsSlotInPosition(319, 199));
    Assert.IsFalse(LGround.IsSlotInPosition(99, 60));
    Assert.IsFalse(LGround.IsSlotInPosition(100, 200));
  finally
    LGround.Free;
    LHand.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRifiutareUnoSlotNonValido;
var
  LRule: TXcomRuleInventory;
begin
  LRule := TXcomRuleInventory.Create('STR_A');
  try
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('slots: [[1, 2, 3]]'), 0);
      end, EYamlBadConversion);
    LRule.Load(Node('slots: [[1, 2], [3, 4]]'), 0);
    Assert.AreEqual<Integer>(2, Length(LRule.Slots));
    Assert.AreEqual(4, LRule.Slots[1].Y);
    Assert.IsTrue(LRule.IsSlotInPosition(3 * 16, 4 * 16));
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeScegliereLOpzioneConPesoEMostrarneINomi;
var
  LOptions: TXcomWeightedOptions;
  LRandom: IXcomRandom;
  LName: string;
begin
  LOptions := TXcomWeightedOptions.Create;
  try
    Assert.IsTrue(LOptions.IsEmpty);
    LRandom := TXcomRandom.Create(7);
    Assert.AreEqual('', LOptions.Choose(LRandom));
    LOptions.SetWeight('b', 3);
    LOptions.SetWeight('a', 1);
    LOptions.SetWeight('b', 2);
    Assert.AreEqual<Integer>(2, Length(LOptions.Names));
    Assert.AreEqual('a', LOptions.Names[0]);
    LName := LOptions.Choose(LRandom);
    Assert.IsTrue((LName = 'a') or (LName = 'b'));
    Assert.IsFalse(LOptions.IsEmpty);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeLevareUnOpzioneConPesoZero;
var
  LOptions: TXcomWeightedOptions;
begin
  LOptions := TXcomWeightedOptions.Create;
  try
    LOptions.SetWeight('a', 4);
    LOptions.SetWeight('a', 0);
    LOptions.SetWeight('b', 0);
    Assert.IsTrue(LOptions.IsEmpty);
    Assert.AreEqual<Integer>(0, Length(LOptions.Names));
    LOptions.Load(Node('{x: 1, y: 2}'));
    Assert.AreEqual<Integer>(2, Length(LOptions.Names));
    LOptions.Load(Node('[]'));
    LOptions.Load(Node('scalar'));
    Assert.WillRaise(
      procedure
      begin
        LOptions.Load(Node('[1]'));
      end, EYamlInvalidNode);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeLeggereLaRegioneEIPuntiCasuali;
var
  LRule: TXcomRuleRegion;
  LLongitude, LLatitude: Double;
begin
  LRule := TXcomRuleRegion.Create('STR_R');
  try
    LRule.Load(Node('type: STR_R2' + #10 + 'cost: 500' + #10 + 'regionWeight: 12' + #10 +
      'missionRegion: STR_M' + #10 + 'missionWeights: {STR_A: 4}' + #10 +
      'missionZones: [[[10, 20, 30, 40, 2, CITY]], [[170, -170, -5, 5]]]'));
    Assert.AreEqual(500, LRule.BaseCost);
    Assert.AreEqual(Cardinal(12), LRule.Weight);
    Assert.AreEqual<Integer>(2, Length(LRule.MissionZones));
    Assert.AreEqual('CITY', LRule.MissionZones[0].Areas[0].Name);
    Assert.AreEqual(2, LRule.MissionZones[0].Areas[0].Texture);
    LRule.GetRandomPoint(1, TXcomRandom.Create(5), LLongitude, LLatitude);
    Assert.IsTrue(LLatitude >= XcomDegToRad(-5));
    Assert.IsTrue(LLatitude <= XcomDegToRad(5));
    Assert.AreEqual('STR_A', LRule.MissionWeights.Choose(TXcomRandom.Create(1)));
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRifiutareUnaZonaCheNonEsiste;
var
  LRule: TXcomRuleRegion;
  LLongitude, LLatitude: Double;
begin
  LRule := TXcomRuleRegion.Create('STR_R');
  try
    LRule.Load(Node('missionZones: [[]]'));
    Assert.WillRaise(
      procedure
      begin
        LRule.GetRandomPoint(3, TXcomRandom.Create(1), LLongitude, LLatitude);
      end, EXcomModException);
    Assert.WillRaise(
      procedure
      begin
        LRule.GetRandomPoint(0, TXcomRandom.Create(1), LLongitude, LLatitude);
      end, EXcomModException);
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('missionZones: [[[1, 2]]]'));
      end, EYamlBadConversion);
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('missionZones: [3]'));
      end, EYamlBadConversion);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRifiutareUnaRicercaConRequisitiECosto;
var
  LRule: TXcomRuleResearch;
begin
  LRule := TXcomRuleResearch.Create('STR_TOPIC');
  try
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('cost: 5' + #10 + 'requires: [STR_X]'), 1);
      end, EXcomModException);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeUsareLOrdineDellaListaSeNonLoDaLaRegola;
var
  LRule: TXcomRuleResearch;
begin
  LRule := TXcomRuleResearch.Create('STR_TOPIC');
  try
    LRule.Load(Node('cost: 5' + #10 + 'points: 2' + #10 + 'needItem: true' + #10 + 'lookup: STR_L'), 7);
    Assert.AreEqual(7, LRule.ListOrder);
    Assert.IsTrue(LRule.NeedItem);
    Assert.IsFalse(LRule.DestroyItem);
    Assert.AreEqual('STR_L', LRule.Lookup);
    Assert.AreEqual('', LRule.Cutscene);
    LRule.Load(Node('listOrder: 3'), 9);
    Assert.AreEqual(3, LRule.ListOrder);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRinominareLaProduzioneConLProgetto;
var
  LRule: TXcomRuleManufacture;
begin
  LRule := TXcomRuleManufacture.Create('STR_OLD');
  try
    LRule.Load(Node('name: STR_NEW' + #10 + 'space: 3'), 4);
    Assert.AreEqual('STR_NEW', LRule.Name);
    Assert.AreEqual(1, LRule.ProducedItems.Count);
    Assert.AreEqual('STR_NEW', LRule.ProducedItems.Key(0));
    Assert.AreEqual(4, LRule.ListOrder);
    LRule.Load(Node('producedItems: {STR_A: 2, STR_B: 1}'), 5);
    Assert.AreEqual(2, LRule.ProducedItems.Count);
    LRule.Load(Node('name: STR_THIRD'), 5);
    Assert.AreEqual(2, LRule.ProducedItems.Count, 'due oggetti prodotti non si rinominano');
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeLeggereIlMembroDiUnaRazza;
var
  LRule: TXcomAlienRace;
begin
  LRule := TXcomAlienRace.Create('STR_SECTOID');
  try
    LRule.Load(Node('members: [STR_ONE, STR_TWO]'));
    Assert.AreEqual('STR_TWO', LRule.GetMember(1));
    Assert.AreEqual('STR_SECTOID', LRule.Id);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRifiutareUnMembroFuoriDallaLista;
var
  LRule: TXcomAlienRace;
begin
  LRule := TXcomAlienRace.Create('STR_SECTOID');
  try
    Assert.WillRaise(
      procedure
      begin
        LRule.GetMember(0);
      end, EXcomModException);
    Assert.WillRaise(
      procedure
      begin
        LRule.GetMember(-1);
      end, EXcomModException);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeLeggereLeTappeDiUnaTraiettoria;
var
  LRule: TXcomUfoTrajectory;
begin
  LRule := TXcomUfoTrajectory.Create('STR_T');
  try
    Assert.AreEqual(Cardinal(5), LRule.GroundTimer);
    LRule.Load(Node('groundTimer: 9' + #10 + 'waypoints: [[1, 2, 50], [-1, 0, 100]]'));
    Assert.AreEqual(Cardinal(9), LRule.GroundTimer);
    Assert.AreEqual(2, LRule.WaypointCount);
    Assert.AreEqual(Cardinal(High(Cardinal)), LRule.Waypoints[1].Zone, 'un numero negativo avvolge');
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('waypoints: [[1, 2]]'));
      end, EYamlBadConversion);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeDareIlTipoComeNomeDellaMusicaSenzaNome;
var
  LRule: TXcomRuleMusic;
begin
  LRule := TXcomRuleMusic.Create('STR_TYPE');
  try
    Assert.AreEqual('STR_TYPE', LRule.Name);
    Assert.AreEqual('STR_TYPE', LRule.MusicType);
    Assert.AreEqual(MaxInt, LRule.CatPos);
    LRule.Load(Node('name: GMTACTIC'));
    Assert.AreEqual('GMTACTIC', LRule.Name);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeLeggereLaNormalizzazioneDellaMusica;
var
  LRule: TXcomRuleMusic;
begin
  LRule := TXcomRuleMusic.Create('STR_TYPE');
  try
    Assert.AreEqual(Single(0.76), LRule.Normalization);
    LRule.Load(Node('catPos: 4' + #10 + 'normalization: 0.5'));
    Assert.AreEqual(4, LRule.CatPos);
    Assert.AreEqual(Single(0.5), LRule.Normalization);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRifiutareUnBloccoCheNonESuMultipliDiDieci;
var
  LRule: TXcomMapBlock;
begin
  LRule := TXcomMapBlock.Create('BLOCK');
  try
    Assert.AreEqual(10, LRule.SizeX);
    Assert.AreEqual(4, LRule.SizeZ);
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('width: 15'));
      end, EXcomModException);
    LRule.Load(Node('width: 20' + #10 + 'length: 30' + #10 + 'height: 2'));
    Assert.AreEqual(30, LRule.SizeY);
    LRule.SizeZ := 7;
    Assert.AreEqual(7, LRule.SizeZ);
    Assert.AreEqual('BLOCK', LRule.Name);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeLeggereIGruppiComeListaOComeNumero;
var
  LRule: TXcomMapBlock;
begin
  LRule := TXcomMapBlock.Create('BLOCK');
  try
    Assert.IsTrue(LRule.IsInGroup(0));
    LRule.Load(Node('groups: [1, 2]' + #10 + 'revealedFloors: 3'));
    Assert.IsTrue(LRule.IsInGroup(2));
    Assert.IsFalse(LRule.IsInGroup(0));
    Assert.IsTrue(LRule.IsFloorRevealed(3));
    LRule.Load(Node('groups: 5'));
    Assert.AreEqual<Integer>(1, Length(LRule.Groups));
    Assert.IsTrue(LRule.IsInGroup(5));
    LRule.Load(Node('groups: abc'));
    Assert.IsTrue(LRule.IsInGroup(0), 'un testo vale 0');
    Assert.AreEqual<Integer>(1, Length(LRule.RevealedFloors));
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeLeggereLePosizioniDegliOggettiDelBlocco;
var
  LRule: TXcomMapBlock;
begin
  LRule := TXcomMapBlock.Create('BLOCK');
  try
    LRule.Load(Node('items: {STR_B: [[1, 2, 3]], STR_A: []}'));
    Assert.AreEqual(2, LRule.Items.Count);
    Assert.AreEqual('STR_A', LRule.Items.Key(0));
    Assert.AreEqual(3, LRule.Items.Value(1)[0].Z);
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('items: {STR_B: [[1, 2]]}'));
      end, EYamlBadConversion);
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('items: {STR_B: 4}'));
      end, EYamlBadConversion);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeLeggereICriteriDiUnaMenzione;
var
  LRule: TXcomRuleCommendations;
begin
  LRule := TXcomRuleCommendations.Create;
  try
    LRule.Load(Node('description: STR_D' + #10 + 'sprite: 3' + #10 + 'criteria: {STR_KILLS: [10, 20]}' + #10 +
      'killCriteria: [[[2, [STR_A, STR_B]], [1, []]], [[5, [STR_C]]]]'));
    Assert.AreEqual('STR_D', LRule.Description);
    Assert.AreEqual(3, LRule.Sprite);
    Assert.AreEqual(1, LRule.Criteria.Count);
    Assert.AreEqual(20, LRule.Criteria.Value(0)[1]);
    Assert.AreEqual<Integer>(2, Length(LRule.KillCriteria));
    Assert.AreEqual<Integer>(2, Length(LRule.KillCriteria[0]));
    Assert.AreEqual('STR_B', LRule.KillCriteria[0][0].Names[1]);
    Assert.AreEqual(5, LRule.KillCriteria[1][0].Count);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeRifiutareUnaCondizioneDiUccisioneNonValida;
var
  LRule: TXcomRuleCommendations;
begin
  LRule := TXcomRuleCommendations.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('killCriteria: [[[1]]]'));
      end, EYamlBadConversion);
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('killCriteria: [3]'));
      end, EYamlBadConversion);
    Assert.WillRaise(
      procedure
      begin
        LRule.Load(Node('criteria: {STR_X: 4}'));
      end, EYamlBadConversion);
  finally
    LRule.Free;
  end;
end;

procedure TTestXcomModRules.DovrebbeScalareLaVelocitaDiUnaTappa;
var
  LRule: TXcomUfoTrajectory;
begin
  LRule := TXcomUfoTrajectory.Create('STR_T');
  try
    LRule.Load(Node('waypoints: [[0, 0, 50]]'));
    Assert.AreEqual(500, LRule.ApplySpeedPercentage(0, 1000));
  finally
    LRule.Free;
  end;
end;

end.

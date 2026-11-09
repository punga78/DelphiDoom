{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom saved game library - the strategy of the  }
{  aliens, the missions, the diary of a soldier and the targets that move       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.Strategy;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleCommendations,
  DelphiDoom.XcomSave.Types, DelphiDoom.XcomSave.AlienStrategy, DelphiDoom.XcomSave.SoldierDiary,
  DelphiDoom.XcomSave.SoldierCommendation, DelphiDoom.XcomSave.MissionStatistics, DelphiDoom.XcomSave.Target,
  DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.MovingTarget, DelphiDoom.XcomSave.Transfer,
  DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomSave.City;

type
  /// <summary>A moving target of the tests</summary>
  TXcomTestMover = class(TXcomMovingTarget)
  public
    function TargetType: string; override;
    function Marker: Integer; override;
  end;

  [TestFixture]
  [Category('xcom-save')]
  [Category('xcom-save-strategy')]
  TTestXcomStrategy = class(TObject)
  strict private
    function Parse(const AText: string): IYamlNode;
    function Dump(const ANode: IYamlNode): string;
  public
    [Test]
    procedure DovrebbeSalvareEdarCaricareLaStrategia;
    [Test]
    procedure DovrebbeCancellareLaPrimaVariabileDelleLocalitaNonLaPrimaLocalita;
    [Test]
    procedure DovrebbeContareLeEsecuzioniDelleMissioni;
    [Test]
    procedure DovrebbeLevareLaRegioneQuandoNonHaPiuMissioni;
    [Test]
    procedure DovrebbeSollevareErroreSeLaRegioneNonHaMissioni;
    [Test]
    procedure DovrebbeSalvareEdarCaricareIlDiario;
    [Test]
    procedure DovrebbeIgnorareUnaMenzioneObsoleta;
    [Test]
    procedure DovrebbeSalvareLaMenzioneSenzaNomeSeIlNomeNonCe;
    [Test]
    procedure DovrebbeSalvareEdarCaricareLeStatisticheDellaMissione;
    [Test]
    procedure DovrebbeSeguireEPerdereLaDestinazione;
    [Test]
    procedure DovrebbeSalvareLaVelocitaEdIlPuntoDiDestinazione;
    [Test]
    procedure DovrebbeSalvareUnSoloContenutoDelTrasferimento;
    [Test]
    procedure DovrebbeFareUnaCittaSenzaTipoConIlSuoMarcatore;
  end;

implementation

type
  TXcomTestSettings = class(TInterfacedObject, IXcomSaveSettings)
  public
    function SoldierDiaries: Boolean;
    function AllowPsiStrengthImprovement: Boolean;
    function PsiStrengthEval: Boolean;
  end;

  TXcomFixedGenerator = class(TInterfacedObject, IXcomRandom)
  public
    function Generate(AMin, AMax: Integer): Integer; overload;
    function Generate(AMin, AMax: Double): Double; overload;
    function Seed: UInt64;
    procedure SetSeed(AValue: UInt64);
  end;

function TXcomTestSettings.SoldierDiaries: Boolean;
begin
  Result := True;
end;

function TXcomTestSettings.AllowPsiStrengthImprovement: Boolean;
begin
  Result := False;
end;

function TXcomTestSettings.PsiStrengthEval: Boolean;
begin
  Result := False;
end;

function TXcomFixedGenerator.Generate(AMin, AMax: Integer): Integer;
begin
  Result := AMin;
end;

function TXcomFixedGenerator.Generate(AMin, AMax: Double): Double;
begin
  Result := AMin;
end;

function TXcomFixedGenerator.Seed: UInt64;
begin
  Result := 0;
end;

procedure TXcomFixedGenerator.SetSeed(AValue: UInt64);
begin
end;

{ TXcomTestMover }

function TXcomTestMover.TargetType: string;
begin
  Result := 'STR_TEST';
end;

function TXcomTestMover.Marker: Integer;
begin
  Result := 1;
end;

{ TTestXcomStrategy }

function TTestXcomStrategy.Parse(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(AText));
end;

function TTestXcomStrategy.Dump(const ANode: IYamlNode): string;
begin
  Result := string(TYamlFactory.Dump(ANode));
end;

procedure TTestXcomStrategy.DovrebbeSalvareEdarCaricareLaStrategia;
var
  LStrategy, LLoaded: TXcomAlienStrategy;
  LText: string;
begin
  LStrategy := TXcomAlienStrategy.Create;
  LLoaded := TXcomAlienStrategy.Create;
  try
    LStrategy.Load(Parse('{regions: {R1: 3, R2: 4}, possibleMissions: [{region: R1, missions: {M1: 2}}, ' +
      '{region: R2, missions: {M2: 1, M3: 5}}], missionLocations: {v: [[R1, 2], [R2, 0]]}, missionsRun: {a: 3}}'));
    LText := Dump(LStrategy.Save);
    LLoaded.Load(LStrategy.Save);
    Assert.AreEqual(LText, Dump(LLoaded.Save));
    Assert.IsTrue(LLoaded.ValidMissionRegion('R2'));
    Assert.IsFalse(LLoaded.ValidMissionRegion('R3'));
    Assert.AreEqual(3, LLoaded.MissionsRun('a'));
    Assert.AreEqual(0, LLoaded.MissionsRun('b'));
    Assert.IsFalse(LLoaded.ValidMissionLocation('v', 'R1', 2));
    Assert.IsTrue(LLoaded.ValidMissionLocation('v', 'R1', 3));
    Assert.IsTrue(LLoaded.ValidMissionLocation('w', 'R1', 2));
    Assert.AreEqual('M1', LLoaded.ChooseRandomMission('R1', TXcomFixedGenerator.Create));
  finally
    LLoaded.Free;
    LStrategy.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeCancellareLaPrimaVariabileDelleLocalitaNonLaPrimaLocalita;
var
  LStrategy: TXcomAlienStrategy;
begin
  LStrategy := TXcomAlienStrategy.Create;
  try
    LStrategy.AddMissionLocation('b', 'R1', 1, 2);
    LStrategy.AddMissionLocation('a', 'R1', 2, 2);
    // the list of "a" has one place: nothing is erased
    Assert.AreEqual(2, LStrategy.MissionLocations.Count);
    LStrategy.AddMissionLocation('b', 'R1', 3, 2);
    LStrategy.AddMissionLocation('b', 'R1', 4, 2);
    // the list of "b" went over the maximum: the C++ erases the first variable of the map ("a"), as written
    Assert.IsFalse(LStrategy.MissionLocations.ContainsKey('a'));
    Assert.IsTrue(LStrategy.MissionLocations.ContainsKey('b'));
    LStrategy.AddMissionLocation('c', 'R1', 1, 0);
    Assert.IsFalse(LStrategy.MissionLocations.ContainsKey('c'));
  finally
    LStrategy.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeContareLeEsecuzioniDelleMissioni;
var
  LStrategy: TXcomAlienStrategy;
begin
  LStrategy := TXcomAlienStrategy.Create;
  try
    LStrategy.AddMissionRun('', 5);
    Assert.AreEqual(0, LStrategy.MissionRuns.Count);
    LStrategy.AddMissionRun('x', 2);
    LStrategy.AddMissionRun('x', 3);
    Assert.AreEqual(5, LStrategy.MissionsRun('x'));
  finally
    LStrategy.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeLevareLaRegioneQuandoNonHaPiuMissioni;
var
  LStrategy: TXcomAlienStrategy;
begin
  LStrategy := TXcomAlienStrategy.Create;
  try
    LStrategy.Load(Parse('{regions: {R1: 3, R2: 4}, possibleMissions: [{region: R1, missions: {M1: 2}}, ' +
      '{region: R2, missions: {M2: 1}}]}'));
    Assert.IsFalse(LStrategy.RemoveMission('R1', 'M1'));
    Assert.IsFalse(LStrategy.ValidMissionRegion('R1'));
    Assert.AreEqual(1, Length(LStrategy.RegionChances.Names));
    Assert.IsTrue(LStrategy.RemoveMission('R2', 'M2'));
    // a region that is not there changes nothing; true because none are left
    Assert.IsTrue(LStrategy.RemoveMission('R9', 'M2'));
  finally
    LStrategy.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeSollevareErroreSeLaRegioneNonHaMissioni;
var
  LStrategy: TXcomAlienStrategy;
begin
  LStrategy := TXcomAlienStrategy.Create;
  try
    Assert.WillRaise(procedure begin LStrategy.ChooseRandomMission('R1', TXcomFixedGenerator.Create); end,
      EXcomSaveException);
    Assert.WillRaise(procedure begin LStrategy.Load(Parse('{possibleMissions: [{missions: {}}]}')); end,
      EYamlBadConversion);
  finally
    LStrategy.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeSalvareEdarCaricareIlDiario;
var
  LDiary, LLoaded: TXcomSoldierDiary;
  LRules: TXcomStringMap<TXcomRuleCommendations>;
begin
  LRules := TXcomStringMap<TXcomRuleCommendations>.Create;
  LDiary := TXcomSoldierDiary.Create;
  LLoaded := TXcomSoldierDiary.Create;
  try
    LDiary.SetCounter('hitCounterTotal', 7);
    LDiary.SetCounter('slaveKillsTotal', 2);
    LDiary.SetCounter('globeTrotter', 1);
    LDiary.AddMonthlyService;
    LDiary.MissionIdList := TArray<Integer>.Create(3, 5);
    Assert.AreEqual(2, LDiary.MissionTotal);
    LLoaded.Load(LDiary.Save, LRules);
    Assert.AreEqual(Dump(LDiary.Save), Dump(LLoaded.Save));
    Assert.AreEqual(7, LLoaded.Counter('hitCounterTotal'));
    Assert.AreEqual(2, LLoaded.SlaveKillsTotal);
    Assert.AreEqual(1, LLoaded.MonthsService);
    Assert.WillRaise(procedure begin LDiary.Counter('nothing'); end, EXcomModException);
  finally
    LLoaded.Free;
    LDiary.Free;
    LRules.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeIgnorareUnaMenzioneObsoleta;
var
  LDiary: TXcomSoldierDiary;
  LRules: TXcomStringMap<TXcomRuleCommendations>;
begin
  LRules := TXcomStringMap<TXcomRuleCommendations>.Create;
  LDiary := TXcomSoldierDiary.Create;
  try
    LDiary.Load(Parse('{commendations: [{commendationName: STR_OLD, decorationLevel: 1}]}'), LRules);
    Assert.AreEqual(0, LDiary.Commendations.Count);
    LRules.SetValue('STR_OLD', nil);
    LDiary.Load(Parse('{commendations: [{commendationName: STR_OLD, decorationLevel: 1}]}'), LRules);
    Assert.AreEqual(1, LDiary.Commendations.Count);
    Assert.AreEqual('noNoun', LDiary.Commendations[0].Noun);
    Assert.IsFalse(LDiary.Commendations[0].IsNew);
  finally
    LDiary.Free;
    LRules.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeSalvareLaMenzioneSenzaNomeSeIlNomeNonCe;
var
  LCommendation: TXcomSoldierCommendation;
begin
  LCommendation := TXcomSoldierCommendation.Create('STR_X', 'noNoun');
  try
    Assert.IsTrue(LCommendation.IsNew);
    LCommendation.AddDecoration;
    Assert.AreEqual(1, LCommendation.DecorationLevel);
    LCommendation.MakeOld;
    Assert.IsFalse(LCommendation.IsNew);
    Assert.IsFalse(Pos('noun', Dump(LCommendation.Save)) > 0);
  finally
    LCommendation.Free;
  end;
  LCommendation := TXcomSoldierCommendation.Create('STR_X', 'cat');
  try
    Assert.IsTrue(Pos('noun: cat', Dump(LCommendation.Save)) > 0);
  finally
    LCommendation.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeSalvareEdarCaricareLeStatisticheDellaMissione;
var
  LStatistics, LLoaded: TXcomMissionStatistics;
begin
  LStatistics := TXcomMissionStatistics.Create;
  LLoaded := TXcomMissionStatistics.Create;
  try
    LStatistics.Load(Parse('{id: 4, markerName: STR_UFO_, markerId: 2, time: {year: 1999, month: 3}, ' +
      'type: STR_UFO_CRASH_RECOVERY, success: true, score: 50, injuryList: {3: 1, 1: 2}, lootValue: 90, valiantCrux: true}'));
    Assert.AreEqual(2, Length(LStatistics.InjuryList));
    Assert.AreEqual(1, LStatistics.InjuryList[0].Wounds);
    LLoaded.Load(LStatistics.Save);
    Assert.AreEqual(Dump(LStatistics.Save), Dump(LLoaded.Save));
    Assert.IsFalse(LLoaded.IsUfoMission);
    Assert.AreEqual('STR_REGION_UNKNOWN', LLoaded.LocationString);
  finally
    LLoaded.Free;
    LStatistics.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeSeguireEPerdereLaDestinazione;
var
  LMover: TXcomTestMover;
  LWaypoint: TXcomWaypoint;
begin
  LMover := TXcomTestMover.Create;
  LWaypoint := TXcomWaypoint.Create;
  try
    LMover.SetSpeed(100);
    LMover.SetDestination(LWaypoint);
    Assert.AreEqual(1, LWaypoint.Followers.Count);
    LMover.SetDestination(nil);
    Assert.AreEqual(0, LWaypoint.Followers.Count);
    Assert.AreEqual(Double(0), LMover.SpeedLon, 0.0);
  finally
    LMover.Free;
    LWaypoint.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeSalvareLaVelocitaEdIlPuntoDiDestinazione;
var
  LMover: TXcomTestMover;
  LWaypoint: TXcomWaypoint;
  LNode: IYamlNode;
begin
  LMover := TXcomTestMover.Create;
  LWaypoint := TXcomWaypoint.Create;
  try
    LWaypoint.SetLongitude(1.0);
    LWaypoint.SetLatitude(0.5);
    LWaypoint.Id := 4;
    LMover.SetSpeed(200);
    LMover.SetDestination(LWaypoint);
    Assert.IsTrue(LMover.SpeedLon > 0);
    LNode := LMover.Save;
    Assert.IsTrue(LNode.Find(YamlStringToText('dest')).IsDefined);
    Assert.AreEqual(200, LNode.Find(YamlStringToText('speed')).AsInteger);
    LMover.Move;
    Assert.IsTrue(LMover.Longitude > 0);
    Assert.IsFalse(LMover.ReachedDestination);
  finally
    LMover.Free;
    LWaypoint.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeSalvareUnSoloContenutoDelTrasferimento;
var
  LTransfer: TXcomTransfer;
  LNode: IYamlNode;
begin
  LTransfer := TXcomTransfer.Create(12);
  try
    LTransfer.SetItems('STR_ITEM', 3);
    LTransfer.Scientists := 5;
    LNode := LTransfer.Save(TXcomTestSettings.Create);
    Assert.IsTrue(LNode.Find(YamlStringToText('itemId')).IsDefined);
    Assert.IsFalse(LNode.Find(YamlStringToText('scientists')).IsDefined);
    Assert.IsFalse(LNode.Find(YamlStringToText('delivered')).IsDefined);
    LTransfer.Delivered := True;
    Assert.IsTrue(LTransfer.Save(TXcomTestSettings.Create).Find(YamlStringToText('delivered')).IsDefined);
  finally
    LTransfer.Free;
  end;
end;

procedure TTestXcomStrategy.DovrebbeFareUnaCittaSenzaTipoConIlSuoMarcatore;
var
  LCity: TXcomCity;
begin
  LCity := TXcomCity.Create('STR_PARIS', 0.5, -0.25);
  try
    Assert.AreEqual('', LCity.TargetType);
    Assert.AreEqual(8, LCity.Marker);
    Assert.AreEqual('STR_PARIS', LCity.CityName);
    Assert.AreEqual(Double(0.5), LCity.Longitude, 0.0);
    Assert.AreEqual(Double(-0.25), LCity.Latitude, 0.0);
  finally
    LCity.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomStrategy);

end.

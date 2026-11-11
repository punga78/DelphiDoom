{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom geoscape library - the defenses of a      }
{  base that fire at a UFO, the base that is destroyed and the confirmation of  }
{  the last mission (with the fake game of the engine tests)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.BaseDefense;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomGeoscape.BaseDefenseState,
  DelphiDoom.Tests.XcomEngine.World;

type
  [TestFixture]
  [Category('xcom-geoscape')]
  TTestXcomBaseDefense = class(TObject)
  strict private
    FWorld: TTestWorld;
    FRuleset: TXcomRuleset;
    FSave: TXcomSavedGame;
    FBase: TXcomBase;
    FUfo: TXcomUfo;
    FAttacks: Integer;
    procedure MakeUfo(const AType: string);
    /// <summary>Shows the screen of the defenses and lets them all fire</summary>
    function Defend(const AFacilities: array of string; AGravShields: Integer): TXcomBaseDefenseState;
    procedure ClickButton(AButton: TXcomTextButton);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSparareUnaVoltaConOgniDifesaEPoiMostrareOk;
    [Test]
    procedure DovrebbeMancareSempreConUnaDifesaChEHaProbabilitaZero;
    [Test]
    procedure DovrebbeSparareDiNuovoPerOgniScudo;
    [Test]
    procedure DovrebbeFermarsiQuandoLUfoEDistrutto;
    [Test]
    procedure DovrebbeAttaccareLaBaseSeLUfoSopravvive;
    [Test]
    procedure DovrebbeNascondereOkFinoAllaFine;
    [Test]
    procedure DovrebbeFinireLaRitorsioneDellaRegioneQuandoLaBaseEDistrutta;
    [Test]
    procedure DovrebbeLasciareLeMissioniDelleAltreRegioni;
    [Test]
    procedure DovrebbeTogliereLaBaseConOk;
    [Test]
    procedure DovrebbeScegliereLaDestinazioneFinaleDelleRegole;
    [Test]
    procedure DovrebbeAvviareLUltimaMissioneConSi;
    [Test]
    procedure DovrebbeTornareAllaSceltaDellaDestinazioneConNo;
  end;

implementation

uses
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.ModOffsets, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleCraft,
  DelphiDoom.XcomSave.Region, DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomGeoscape.BaseDestroyedState, DelphiDoom.XcomGeoscape.ConfirmCydoniaState,
  DelphiDoom.XcomGeoscape.MissionLauncher.Intf, DelphiDoom.Tests.XcomGeoscape.MissionLauncher;

type
  /// <summary>The sizes of the shared sets that a ruleset asks for (none of the rules of the test uses them)</summary>
  TFixedShared = class(TInterfacedObject, IXcomSharedResources)
  public
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

const
  RULES =
    'facilities: [{type: STR_GUN, defense: 100, hitRatio: 100}, {type: STR_BLIND_GUN, defense: 100, hitRatio: 0}], ' +
    'ufos: [{type: STR_BIG, damageMax: 100000}, {type: STR_SMALL, damageMax: 10}], ' +
    'ufoTrajectories: [{id: P0, groundTimer: 10, waypoints: [[0, 0, 10]]}], ' +
    'regions: [{type: STR_HERE, areas: [[0, 90, -45, 45]]}, {type: STR_THERE, areas: [[180, 270, -45, 45]]}], ' +
    'alienMissions: [{type: STR_REVENGE, objective: 4}, {type: STR_SCOUT, objective: 0}], ' +
    'alienDeployments: [{type: STR_FIRST}, {type: STR_LAST, finalDestination: true, race: STR_BOSS}, ' +
    '{type: STR_LATER, finalDestination: true, race: STR_OTHER}]';
  // the whole sequence of the defenses of these tests is over well before
  LONG_ENOUGH = 20000;

{ TFixedShared }

function TFixedShared.MaxSharedSounds(const ASet: string): Integer;
begin
  Result := 20;
end;

function TFixedShared.MaxSharedFrames(const ASet: string): Integer;
begin
  Result := 100;
end;

{ TTestXcomBaseDefense }

procedure TTestXcomBaseDefense.Setup;
begin
  FWorld := TTestWorld.Create;
  FRuleset := TXcomRuleset.Create(TFixedShared.Create);
  FRuleset.SetMods(TArray<TXcomModData>.Create(TXcomModData.Make('master', 0, 1000)), 0);
  FRuleset.LoadFile(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes('{' + RULES + '}')));
  FSave := TXcomSavedGame.Create;
  FBase := TXcomBase.Create;
  FBase.Name := 'Atlantis';
  // inside STR_HERE
  FBase.SetLongitude(0.5);
  FBase.SetLatitude(0.1);
  FSave.Bases.Add(FBase);
  FSave.Regions.Add(TXcomRegion.Create(FRuleset.Regions.Find('STR_HERE')));
  FSave.Regions.Add(TXcomRegion.Create(FRuleset.Regions.Find('STR_THERE')));
  FAttacks := 0;
  FUfo := nil;
end;

procedure TTestXcomBaseDefense.TearDown;
begin
  FWorld.Free;
  FreeAndNil(FUfo);
  FSave.Free;
  FRuleset.Free;
end;

procedure TTestXcomBaseDefense.MakeUfo(const AType: string);
begin
  FUfo := TXcomUfo.Create(FRuleset.Ufos.Find(AType));
end;

function TTestXcomBaseDefense.Defend(const AFacilities: array of string;
  AGravShields: Integer): TXcomBaseDefenseState;
var
  LRules: TArray<TXcomRuleBaseFacility>;
  LIndex: Integer;
begin
  SetLength(LRules, Length(AFacilities));
  for LIndex := 0 to High(AFacilities) do
    LRules[LIndex] := FRuleset.Facilities.Find(AFacilities[LIndex]);
  Result := TXcomBaseDefenseState.Create(FWorld.Game, FBase, FUfo, LRules, AGravShields, TXcomRandom.Create(1761),
    procedure
    begin
      Inc(FAttacks);
    end);
  FWorld.Game.PushState(Result);
  FWorld.Wait(LONG_ENOUGH);
end;

procedure TTestXcomBaseDefense.ClickButton(AButton: TXcomTextButton);
begin
  FWorld.Click((AButton.X + AButton.Width div 2) * 2, (AButton.Y + AButton.Height div 2) * 2);
end;

procedure TTestXcomBaseDefense.DovrebbeSparareUnaVoltaConOgniDifesaEPoiMostrareOk;
var
  LState: TXcomBaseDefenseState;
begin
  MakeUfo('STR_BIG');
  LState := Defend(['STR_GUN', 'STR_GUN'], 0);
  Assert.AreEqual(2, LState.Defenses.GetRows);
  Assert.AreEqual('STR_GUN', LState.Defenses.GetCellText(0, 0));
  Assert.AreEqual('STR_FIRING', LState.Defenses.GetCellText(1, 1));
  Assert.AreEqual('STR_HIT', LState.Defenses.GetCellText(1, 2));
  Assert.IsTrue(LState.InitText.Visible);
  Assert.IsTrue(LState.OkButton.Visible);
  // every hit does from half the defense value to one and a half
  Assert.IsTrue((FUfo.Damage >= 100) and (FUfo.Damage <= 300), IntToStr(FUfo.Damage));
end;

procedure TTestXcomBaseDefense.DovrebbeMancareSempreConUnaDifesaChEHaProbabilitaZero;
var
  LState: TXcomBaseDefenseState;
begin
  MakeUfo('STR_BIG');
  LState := Defend(['STR_BLIND_GUN'], 0);
  Assert.AreEqual('STR_MISSED', LState.Defenses.GetCellText(0, 2));
  Assert.AreEqual(0, FUfo.Damage);
end;

procedure TTestXcomBaseDefense.DovrebbeSparareDiNuovoPerOgniScudo;
var
  LState: TXcomBaseDefenseState;
begin
  MakeUfo('STR_BIG');
  LState := Defend(['STR_GUN'], 2);
  // shot, shield, shot, shield, shot
  Assert.AreEqual(5, LState.Defenses.GetRows);
  Assert.AreEqual('STR_GRAV_SHIELD_REPELS_UFO', LState.Defenses.GetCellText(1, 0));
  Assert.AreEqual('STR_GUN', LState.Defenses.GetCellText(4, 0));
  Assert.IsTrue(FUfo.Damage >= 150);
end;

procedure TTestXcomBaseDefense.DovrebbeFermarsiQuandoLUfoEDistrutto;
var
  LState: TXcomBaseDefenseState;
begin
  MakeUfo('STR_SMALL');
  LState := Defend(['STR_GUN', 'STR_GUN', 'STR_GUN'], 1);
  Assert.AreEqual(TXcomUfo.STATUS_DESTROYED, FUfo.Status);
  // the first shot and the line that says so: the other defenses do not fire
  Assert.AreEqual(2, LState.Defenses.GetRows);
  Assert.AreEqual('STR_UFO_DESTROYED', LState.Defenses.GetCellText(1, 0));
  ClickButton(LState.OkButton);
  Assert.IsFalse(FWorld.Game.IsState(LState));
  Assert.AreEqual(0, FAttacks, 'un UFO distrutto non attacca la base');
end;

procedure TTestXcomBaseDefense.DovrebbeAttaccareLaBaseSeLUfoSopravvive;
var
  LState: TXcomBaseDefenseState;
begin
  MakeUfo('STR_BIG');
  LState := Defend(['STR_GUN'], 0);
  ClickButton(LState.OkButton);
  Assert.IsFalse(FWorld.Game.IsState(LState));
  Assert.AreEqual(1, FAttacks);
end;

procedure TTestXcomBaseDefense.DovrebbeNascondereOkFinoAllaFine;
var
  LState: TXcomBaseDefenseState;
begin
  MakeUfo('STR_BIG');
  LState := TXcomBaseDefenseState.Create(FWorld.Game, FBase, FUfo, [FRuleset.Facilities.Find('STR_GUN')], 0,
    TXcomRandom.Create(1), nil);
  FWorld.Game.PushState(LState);
  // the first step only says that the defenses are on
  FWorld.Wait(300);
  Assert.IsTrue(LState.InitText.Visible);
  Assert.IsFalse(LState.OkButton.Visible);
  Assert.AreEqual(0, LState.Defenses.GetRows);
  FWorld.Wait(300);
  Assert.AreEqual(1, LState.Defenses.GetRows);
  Assert.IsFalse(LState.OkButton.Visible);
end;

procedure TTestXcomBaseDefense.DovrebbeFinireLaRitorsioneDellaRegioneQuandoLaBaseEDistrutta;
var
  LMission: TXcomAlienMission;
  LUfo, LOther: TXcomUfo;
  LRemoved: Integer;
  LState: TXcomBaseDestroyedState;
begin
  LMission := TXcomAlienMission.Create(FRuleset.AlienMissions.Find('STR_REVENGE'));
  LMission.SetRegion('STR_HERE', FRuleset.Regions.Find('STR_HERE'));
  FSave.ActiveMissions.Add(LMission);
  LUfo := TXcomUfo.Create(FRuleset.Ufos.Find('STR_BIG'));
  LUfo.SetMissionInfo(LMission, FRuleset.UfoTrajectories.Find('P0'));
  FSave.Ufos.Add(LUfo);
  // a UFO of no mission stays
  LOther := TXcomUfo.Create(FRuleset.Ufos.Find('STR_SMALL'));
  FSave.Ufos.Add(LOther);
  LRemoved := 0;
  LState := TXcomBaseDestroyedState.Create(FWorld.Game, FSave, FBase,
    procedure(AUfo: TXcomUfo)
    begin
      Inc(LRemoved);
    end);
  FWorld.Game.PushState(LState);
  Assert.AreEqual(1, FSave.Ufos.Count);
  Assert.IsTrue(FSave.Ufos[0] = LOther);
  Assert.AreEqual(0, FSave.ActiveMissions.Count);
  Assert.AreEqual(1, LRemoved, 'chi usa l''UFO lo sa prima che sia liberato');
end;

procedure TTestXcomBaseDefense.DovrebbeLasciareLeMissioniDelleAltreRegioni;
var
  LFar, LScout: TXcomAlienMission;
begin
  // a retaliation of another region and a mission of the region that is not a retaliation
  LFar := TXcomAlienMission.Create(FRuleset.AlienMissions.Find('STR_REVENGE'));
  LFar.SetRegion('STR_THERE', FRuleset.Regions.Find('STR_THERE'));
  FSave.ActiveMissions.Add(LFar);
  LScout := TXcomAlienMission.Create(FRuleset.AlienMissions.Find('STR_SCOUT'));
  LScout.SetRegion('STR_HERE', FRuleset.Regions.Find('STR_HERE'));
  FSave.ActiveMissions.Add(LScout);
  FWorld.Game.PushState(TXcomBaseDestroyedState.Create(FWorld.Game, FSave, FBase));
  Assert.AreEqual(2, FSave.ActiveMissions.Count);
end;

procedure TTestXcomBaseDefense.DovrebbeTogliereLaBaseConOk;
var
  LState: TXcomBaseDestroyedState;
begin
  LState := TXcomBaseDestroyedState.Create(FWorld.Game, FSave, FBase);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  Assert.AreEqual(1, FSave.Bases.Count, 'la base resta finche'' il giocatore non ha letto');
  ClickButton(LState.OkButton);
  Assert.IsFalse(FWorld.Game.IsState(LState));
  Assert.AreEqual(0, FSave.Bases.Count);
end;

procedure TTestXcomBaseDefense.DovrebbeScegliereLaDestinazioneFinaleDelleRegole;
var
  LRules: TXcomRuleCraft;
  LCraft: TXcomCraft;
  LState: TXcomConfirmCydoniaState;
  LRequest: TXcomMissionRequest;
begin
  LRules := TXcomRuleCraft.Create('STR_SHIP');
  LCraft := TXcomCraft.Create(LRules, nil, 1);
  LState := TXcomConfirmCydoniaState.Create(FWorld.Game, LCraft, FRuleset, nil);
  try
    LRequest := LState.Request;
    // the first deployment of the list that is a final destination
    Assert.AreEqual('STR_LAST', LRequest.MissionType);
    Assert.AreEqual('STR_BOSS', LRequest.AlienRace);
    Assert.IsTrue(LRequest.Craft = LCraft);
    Assert.AreEqual(-1, LRequest.WorldTexture);
    Assert.IsFalse(Assigned(LRequest.Ufo) or Assigned(LRequest.Site) or Assigned(LRequest.AlienBase) or
      Assigned(LRequest.Base));
  finally
    LState.Free;
    LCraft.Free;
    LRules.Free;
  end;
end;

procedure TTestXcomBaseDefense.DovrebbeAvviareLUltimaMissioneConSi;
var
  LRules: TXcomRuleCraft;
  LCraft: TXcomCraft;
  LLauncher: TFakeLauncher;
  LLauncherRef: IXcomMissionLauncher;
  LBelow, LBottom: TXcomState;
  LState: TXcomConfirmCydoniaState;
begin
  LRules := TXcomRuleCraft.Create('STR_SHIP');
  LCraft := TXcomCraft.Create(LRules, nil, 1);
  try
    LLauncher := TFakeLauncher.Create;
    LLauncherRef := LLauncher;
    // the geoscape and the choice of the destination, as far as this screen knows
    LBottom := TXcomState.Create(FWorld.Game);
    FWorld.Game.PushState(LBottom);
    LBelow := TXcomState.Create(FWorld.Game);
    FWorld.Game.PushState(LBelow);
    LState := TXcomConfirmCydoniaState.Create(FWorld.Game, LCraft, FRuleset, LLauncherRef);
    FWorld.Game.PushState(LState);
    FWorld.Wait(400);
    ClickButton(LState.YesButton);
    Assert.AreEqual(1, Length(LLauncher.Requests));
    Assert.AreEqual('STR_LAST', LLauncher.Requests[0].MissionType);
    Assert.IsFalse(FWorld.Game.IsState(LState));
    Assert.IsFalse(FWorld.Game.IsState(LBelow), 'anche la scelta della destinazione e'' chiusa');
    Assert.IsTrue(FWorld.Game.TopState = LBottom);
  finally
    LLauncherRef := nil;
    LCraft.Free;
    LRules.Free;
  end;
end;

procedure TTestXcomBaseDefense.DovrebbeTornareAllaSceltaDellaDestinazioneConNo;
var
  LRules: TXcomRuleCraft;
  LCraft: TXcomCraft;
  LBelow: TXcomState;
  LState: TXcomConfirmCydoniaState;
begin
  LRules := TXcomRuleCraft.Create('STR_SHIP');
  LCraft := TXcomCraft.Create(LRules, nil, 1);
  try
    LBelow := TXcomState.Create(FWorld.Game);
    FWorld.Game.PushState(LBelow);
    LState := TXcomConfirmCydoniaState.Create(FWorld.Game, LCraft, FRuleset, nil);
    FWorld.Game.PushState(LState);
    FWorld.Wait(400);
    ClickButton(LState.NoButton);
    Assert.IsTrue(FWorld.Game.TopState = LBelow);
  finally
    LCraft.Free;
    LRules.Free;
  end;
end;

end.

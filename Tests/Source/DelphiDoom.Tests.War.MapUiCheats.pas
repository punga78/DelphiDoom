{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the cheats of the map                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiCheats;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Types,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.Intf, DelphiDoom.War.MapUi.CheatEffects,
  DelphiDoom.Tests.War.CommandRig;

type
  /// <summary>A map that records what the cheats ask of it</summary>
  TCheatTargetSpy = class(TInterfacedObject, IWarMapCheatTarget)
  public
    Concluded: TWarLevelResult;
    DemoEnds: Integer;
    FogToggles: Integer;
    SkippedRace: TWarRace;
    SkippedMap: Integer;
    Skips: Integer;
    Mode: TWarMapEditMode;
    UnitType: Integer;
    constructor Create;
    procedure ConcludeMap(AResult: TWarLevelResult);
    procedure ShowDemoEnd;
    procedure ToggleFog;
    procedure SkipToBriefing(ARace: TWarRace; AMapType: Integer);
    procedure SetEditing(AMode: TWarMapEditMode; AUnitType: Integer);
    function GetEditMode: TWarMapEditMode;
  end;

  /// <summary>The effects that come after the map ones: they answer with what they were asked</summary>
  TNextEffectsSpy = class(TInterfacedObject, IWarCheatEffects)
  public
    LastName: string;
    LastArgument: AnsiString;
    function Apply(const AName: string; const AArgument: AnsiString): AnsiString;
  end;

  /// <summary>What the cheats do on a map (war_cheats.c) and the flags of the debug drawing</summary>
  [TestFixture]
  [Category('war')]
  TTestWarMapCheats = class(TObject)
  strict private
    FRig: TCommandRig;
    FTarget: TCheatTargetSpy;
    FTargetRef: IWarMapCheatTarget;
    FNext: TNextEffectsSpy;
    FNextRef: IWarCheatEffects;
    FSettings: IWarGameSettings;
    FDebug: IWarDebugRender;
    FEffects: IWarCheatEffects;
    function Apply(const AName: string; const AArgument: AnsiString = ''): AnsiString;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareOroELegnaAlGiocatore;
    [Test]
    procedure DovrebbePermettereTuttiGliIncantesimiEiMiglioramenti;
    [Test]
    procedure DovrebbePermettereIMiglioramentiDelleArmi;
    [Test]
    procedure DovrebbeAccendereESpegnereGodModeEVelocita;
    [Test]
    procedure DovrebbeChiedereAllaMappaLaFineLaNebbiaEIlSalto;
    [Test]
    procedure DovrebbeSaltareSoloALivelloUnoEDue;
    [Test]
    procedure DovrebbeScegliereIModiDiModifica;
    [Test]
    procedure DovrebbeCapireIlTrucoAggiungiUnita;
    [Test]
    procedure DovrebbeTenerePerBuonoIlMessaggioConIlResto;
    [Test]
    procedure DovrebbeNonFareNienteSeITrucchiSonoSpentiEDareCorwinAlleImpostazioni;
    [Test]
    procedure DovrebbeDareAlleImpostazioniQuelloCheNonE;
    [Test]
    procedure DovrebbeUsareIlDebugRender;
    [Test]
    procedure DovrebbeAccendereUnFlagConIlNomeELoSpegnereConZero;
    [Test]
    procedure DovrebbeConservareLaDifferenzaDeiNomiDeiFlag;
    [Test]
    procedure DovrebbeRifiutareUnNomeEUnValore;
    [Test]
    procedure DovrebbeContareIFlagAcceso;
    [Test]
    procedure DovrebbeAccendereUnFlagSoloConCtrlEMaiusc;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Input,
  DelphiDoom.War.Ui.GameSettings, DelphiDoom.War.Ui.DebugRender, DelphiDoom.War.MapUi.CommandData.Data,
  DelphiDoom.War.MapUi.UnitNames.Data;

{ TCheatTargetSpy }

constructor TCheatTargetSpy.Create;
begin
  inherited Create;
  Concluded := wlrNone;
end;

procedure TCheatTargetSpy.ConcludeMap(AResult: TWarLevelResult);
begin
  Concluded := AResult;
end;

procedure TCheatTargetSpy.ShowDemoEnd;
begin
  Inc(DemoEnds);
end;

procedure TCheatTargetSpy.ToggleFog;
begin
  Inc(FogToggles);
end;

procedure TCheatTargetSpy.SkipToBriefing(ARace: TWarRace; AMapType: Integer);
begin
  Inc(Skips);
  SkippedRace := ARace;
  SkippedMap := AMapType;
end;

procedure TCheatTargetSpy.SetEditing(AMode: TWarMapEditMode; AUnitType: Integer);
begin
  Mode := AMode;
  if AMode = wemAddUnit then
    UnitType := AUnitType;
end;

function TCheatTargetSpy.GetEditMode: TWarMapEditMode;
begin
  Result := Mode;
end;

{ TNextEffectsSpy }

function TNextEffectsSpy.Apply(const AName: string; const AArgument: AnsiString): AnsiString;
begin
  LastName := AName;
  LastArgument := AArgument;
  Result := 'next';
end;

{ TTestWarMapCheats }

procedure TTestWarMapCheats.Setup;
begin
  FRig := TCommandRig.Create;
  FTarget := TCheatTargetSpy.Create;
  FTargetRef := FTarget;
  FNext := TNextEffectsSpy.Create;
  FNextRef := FNext;
  FSettings := TWarGameSettings.Create;
  FDebug := TWarDebugRender.Create;
  FEffects := TWarMapCheatEffects.Create(FRig.Context, FRig.World.Economy, FTargetRef, FSettings, FDebug, FNextRef);
end;

procedure TTestWarMapCheats.TearDown;
begin
  FEffects := nil;
  FDebug := nil;
  FSettings := nil;
  FNextRef := nil;
  FTargetRef := nil;
  FRig.Free;
end;

function TTestWarMapCheats.Apply(const AName: string; const AArgument: AnsiString): AnsiString;
begin
  Result := FEffects.Apply(AName, AArgument);
end;

procedure TTestWarMapCheats.DovrebbeDareOroELegnaAlGiocatore;
var
  LGold: Integer;
  LWood: Integer;
begin
  LGold := FRig.Context.Players[0]^.Gold;
  LWood := FRig.Context.Players[0]^.Wood;
  Assert.AreEqual('cheat enabled you wascally wabbit', string(Apply('Pot of gold')));
  Assert.AreEqual(LGold + 10000, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual(LWood + 5000, FRig.Context.Players[0]^.Wood);
end;

procedure TTestWarMapCheats.DovrebbePermettereTuttiGliIncantesimiEiMiglioramenti;
var
  LPlayer: PWarPlayerInfo;
begin
  LPlayer := FRig.Context.Players[0];
  Apply('Eye of newt');
  Assert.AreEqual(1, Integer(LPlayer^.Features[WAR_FEATURE_SPELL_HEALING div 2]));
  Assert.AreEqual(1, Integer(LPlayer^.Features[WAR_FEATURE_SPELL_DAEMON div 2]));
  Assert.AreEqual(1, Integer(LPlayer^.Upgrades[WAR_UPGRADE_HEALING div 2].Allowed));
  Assert.AreEqual(1, Integer(LPlayer^.Upgrades[WAR_UPGRADE_HEALING div 2].Level));
  Assert.AreEqual(1, Integer(LPlayer^.Upgrades[WAR_UPGRADE_UNHOLY_ARMOR div 2].Level));
  // done twice it finds the upgrades at their level: nothing more to give
  Apply('Eye of newt');
  Assert.AreEqual(1, Integer(LPlayer^.Upgrades[WAR_UPGRADE_DAEMON div 2].Level));
end;

procedure TTestWarMapCheats.DovrebbePermettereIMiglioramentiDelleArmi;
var
  LPlayer: PWarPlayerInfo;
begin
  LPlayer := FRig.Context.Players[0];
  Apply('Iron forge');
  Assert.AreEqual(2, Integer(LPlayer^.Upgrades[WAR_UPGRADE_SWORDS div 2].Allowed));
  Assert.AreEqual(2, Integer(LPlayer^.Upgrades[WAR_UPGRADE_SWORDS div 2].Level));
  Assert.AreEqual(2, Integer(LPlayer^.Upgrades[WAR_UPGRADE_SHIELD div 2].Level));
  Assert.AreEqual(2, Integer(LPlayer^.Upgrades[WAR_UPGRADE_ARROWS div 2].Level));
end;

procedure TTestWarMapCheats.DovrebbeAccendereESpegnereGodModeEVelocita;
begin
  Assert.IsFalse(FRig.Context.Players[0]^.GodMode);
  Apply('There can be only one');
  Assert.IsTrue(FRig.Context.Players[0]^.GodMode);
  Apply('There can be only one');
  Assert.IsFalse(FRig.Context.Players[0]^.GodMode);
  Assert.IsFalse(FRig.Context.HurryUp);
  Apply('Hurry up guys');
  Assert.IsTrue(FRig.Context.HurryUp);
  Apply('Hurry up guys');
  Assert.IsFalse(FRig.Context.HurryUp);
end;

procedure TTestWarMapCheats.DovrebbeChiedereAllaMappaLaFineLaNebbiaEIlSalto;
begin
  Apply('Yours truly');
  Assert.IsTrue(FTarget.Concluded = wlrWin);
  Apply('Crushing defeat');
  Assert.IsTrue(FTarget.Concluded = wlrLose);
  // the end of the demo shows no message
  Assert.AreEqual('', string(Apply('Ides of march')));
  Assert.AreEqual(1, FTarget.DemoEnds);
  Apply('Sally Shears');
  Assert.AreEqual(1, FTarget.FogToggles);
end;

procedure TTestWarMapCheats.DovrebbeSaltareSoloALivelloUnoEDue;
begin
  Apply('Human', '1');
  Assert.IsTrue(FTarget.SkippedRace = wraHumans);
  Assert.AreEqual(117, FTarget.SkippedMap);
  Apply('Human', '2');
  Assert.AreEqual(119, FTarget.SkippedMap);
  Apply('Orc', '1');
  Assert.IsTrue(FTarget.SkippedRace = wraOrcs);
  Assert.AreEqual(118, FTarget.SkippedMap);
  Apply('Orc', '2');
  Assert.AreEqual(120, FTarget.SkippedMap);
  Assert.AreEqual(4, FTarget.Skips);
  // 0, 3 and what is not a number do nothing
  Apply('Human', '3');
  Apply('Orc', '0');
  Apply('Orc', 'due');
  Apply('Human', '');
  Assert.AreEqual(4, FTarget.Skips);
end;

procedure TTestWarMapCheats.DovrebbeScegliereIModiDiModifica;
begin
  Assert.AreEqual('Edit trees on', string(Apply('Edit', 'trees')));
  Assert.IsTrue(FTarget.Mode = wemTrees);
  Assert.AreEqual('Edit walls on', string(Apply('Edit', 'WALLS')));
  Assert.IsTrue(FTarget.Mode = wemWalls);
  Assert.AreEqual('Edit roads on', string(Apply('Edit', 'roads')));
  Assert.IsTrue(FTarget.Mode = wemRoads);
  Assert.AreEqual('Edit ruins on', string(Apply('Edit', 'ruins')));
  Assert.IsTrue(FTarget.Mode = wemRuins);
  Assert.AreEqual('Edit off', string(Apply('Edit', 'off')));
  Assert.IsTrue(FTarget.Mode = wemNone);
  // something that is not a mode turns the editing off and shows nothing
  Apply('Edit', 'trees');
  Assert.AreEqual('', string(Apply('Edit', 'frogs')));
  Assert.IsTrue(FTarget.Mode = wemNone);
  // the spells of the cheats toggle
  Assert.AreEqual('Rain of fire on', string(Apply('Rain of fire')));
  Assert.IsTrue(FTarget.Mode = wemRainOfFire);
  Assert.AreEqual('Rain of fire off', string(Apply('Rain of fire')));
  Assert.IsTrue(FTarget.Mode = wemNone);
  Assert.AreEqual('Poison cloud on', string(Apply('Poison cloud')));
  Assert.IsTrue(FTarget.Mode = wemPoisonCloud);
  Assert.AreEqual('Poison cloud off', string(Apply('Poison cloud')));
  Assert.AreEqual('Raise dead on', string(Apply('Raise dead')));
  Assert.IsTrue(FTarget.Mode = wemRaiseDead);
  Assert.AreEqual('Raise dead off', string(Apply('Raise dead')));
  // one mode replaces the other
  Apply('Rain of fire');
  Assert.AreEqual('Poison cloud on', string(Apply('Poison cloud')));
  Assert.IsTrue(FTarget.Mode = wemPoisonCloud);
end;

procedure TTestWarMapCheats.DovrebbeCapireIlTrucoAggiungiUnita;
var
  LIndex: Integer;
begin
  // the original takes the INDEX of the row of the table as the type of the unit: it is the type up to the 29th row; from
  // there the table is not in the order of the types and a name gives another unit (a defect of the original, kept)
  for LIndex := 0 to 28 do
    Assert.AreEqual(LIndex, WAR_UNIT_NAMES[LIndex].UnitType, 'row ' + IntToStr(LIndex));
  Assert.AreNotEqual(29, WAR_UNIT_NAMES[29].UnitType);
  Apply('Add unit', 'church');
  Assert.IsTrue(FTarget.Mode = wemAddUnit);
  Assert.AreEqual(33, FTarget.UnitType);
  Assert.AreEqual('CHURCH', string(WAR_UNIT_NAMES[33].Name));
  Assert.AreNotEqual(WAR_UNIT_CHURCH, FTarget.UnitType);
  Assert.AreEqual('Add unit ', string(Apply('Add unit', 'footman')));
  Assert.IsTrue(FTarget.Mode = wemAddUnit);
  Assert.AreEqual(WAR_UNIT_FOOTMAN, FTarget.UnitType);
  Apply('Add unit', 'catapult orcs');
  Assert.AreEqual(WAR_UNIT_CATAPULT_ORCS, FTarget.UnitType);
  Apply('Add unit', 'CATAPULT HUMANS');
  Assert.AreEqual(WAR_UNIT_CATAPULT_HUMANS, FTarget.UnitType);
  Apply('Add unit', 'farm orcs');
  Assert.AreEqual(WAR_UNIT_FARM_ORCS, FTarget.UnitType);
  Apply('Add unit', 'barracks humans');
  Assert.AreEqual(WAR_UNIT_BARRACKS_HUMANS, FTarget.UnitType);
  Apply('Add unit', 'tower orcs');
  Assert.AreEqual(WAR_UNIT_TOWER_ORCS, FTarget.UnitType);
  Apply('Add unit', 'town hall orcs');
  Assert.AreEqual(WAR_UNIT_TOWNHALL_ORCS, FTarget.UnitType);
  Apply('Add unit', 'mill humans');
  Assert.AreEqual(WAR_UNIT_LUMBERMILL_HUMANS, FTarget.UnitType);
  Apply('Add unit', 'blacksmith orcs');
  Assert.AreEqual(WAR_UNIT_BLACKSMITH_ORCS, FTarget.UnitType);
  Apply('Add unit', 'corpse humans');
  Assert.AreEqual(WAR_UNIT_HUMAN_CORPSE, FTarget.UnitType);
  Apply('Add unit', 'corpse orcs');
  Assert.AreEqual(WAR_UNIT_ORC_CORPSE, FTarget.UnitType);
  Apply('Add unit', 'grunt');
  Assert.AreEqual(WAR_UNIT_GRUNT, FTarget.UnitType);
  // without the race, or with a name that is not one: the mode is off and nothing is shown
  Assert.AreEqual('', string(Apply('Add unit', 'farm')));
  Assert.IsTrue(FTarget.Mode = wemNone);
  Assert.AreEqual('', string(Apply('Add unit', 'town hall')));
  Assert.AreEqual('', string(Apply('Add unit', 'town')));
  Assert.AreEqual('', string(Apply('Add unit', 'dragon')));
  Assert.AreEqual('', string(Apply('Add unit', '')));
  Assert.IsTrue(FTarget.Mode = wemNone);
  Assert.AreEqual('Add unit off', string(Apply('Add unit', 'off')));
end;

procedure TTestWarMapCheats.DovrebbeTenerePerBuonoIlMessaggioConIlResto;
begin
  // the message shows what the two words did not take (the original does this)
  Assert.AreEqual('Add unit  words', string(Apply('Add unit', 'footman extra words')));
  Assert.AreEqual('Add unit ', string(Apply('Add unit', '   footman   ')));
end;

procedure TTestWarMapCheats.DovrebbeNonFareNienteSeITrucchiSonoSpentiEDareCorwinAlleImpostazioni;
var
  LGold: Integer;
begin
  LGold := FRig.Context.Players[0]^.Gold;
  FSettings.CheatsEnabled := False;
  Assert.AreEqual('next', string(Apply('Pot of gold')));
  Assert.AreEqual(LGold, FRig.Context.Players[0]^.Gold);
  Assert.AreEqual('Pot of gold', FNext.LastName);
  // "Corwin of Amber" is for the next effects (the settings) in any case
  Apply('Corwin of Amber');
  Assert.AreEqual('Corwin of Amber', FNext.LastName);
  FSettings.CheatsEnabled := True;
  Apply('Pot of gold');
  Assert.AreEqual(LGold + 10000, FRig.Context.Players[0]^.Gold);
end;

procedure TTestWarMapCheats.DovrebbeDareAlleImpostazioniQuelloCheNonE;
begin
  Assert.AreEqual('next', string(Apply('Music vol', '50')));
  Assert.AreEqual('Music vol', FNext.LastName);
  Assert.AreEqual('50', string(FNext.LastArgument));
end;

procedure TTestWarMapCheats.DovrebbeUsareIlDebugRender;
var
  LEffects: IWarCheatEffects;
begin
  Assert.AreEqual('map-grid on', string(Apply('Debug render', 'map-grid')));
  Assert.IsTrue(FDebug.Flag[wdrMapGrid]);
  // with no flags to change it does nothing
  LEffects := TWarMapCheatEffects.Create(FRig.Context, FRig.World.Economy, FTargetRef, FSettings, nil, nil);
  Assert.AreEqual('', string(LEffects.Apply('Debug render', 'map-grid')));
  // and with no next effects what is not the map's gives nothing
  Assert.AreEqual('', string(LEffects.Apply('Music vol', '50')));
end;

procedure TTestWarMapCheats.DovrebbeAccendereUnFlagConIlNomeELoSpegnereConZero;
begin
  Assert.AreEqual('passable-info on', string(FDebug.ApplyCheat('  Passable-Info  ')));
  Assert.IsTrue(FDebug.Flag[wdrPassableInfo]);
  Assert.AreEqual('passable-info off', string(FDebug.ApplyCheat('passable-info')));
  Assert.IsFalse(FDebug.Flag[wdrPassableInfo]);
  Assert.AreEqual('spatial-grid on', string(FDebug.ApplyCheat('spatial-grid 1')));
  Assert.IsTrue(FDebug.Flag[wdrSpatialGrid]);
  Assert.AreEqual('spatial-grid on', string(FDebug.ApplyCheat('spatial-grid 1')));
  Assert.AreEqual('spatial-grid off', string(FDebug.ApplyCheat('spatial-grid 0')));
  Assert.IsFalse(FDebug.Flag[wdrSpatialGrid]);
end;

procedure TTestWarMapCheats.DovrebbeConservareLaDifferenzaDeiNomiDeiFlag;
begin
  // twelve names for thirteen flags: from "unit-info" on the name toggles the flag before the one it names
  FDebug.ApplyCheat('unit-info');
  Assert.IsTrue(FDebug.Flag[wdrUnitPaths]);
  Assert.IsFalse(FDebug.Flag[wdrUnitInfo]);
  FDebug.ApplyCheat('rvo');
  Assert.IsTrue(FDebug.Flag[wdrFlowField]);
  Assert.IsFalse(FDebug.Flag[wdrRvo]);
  FDebug.ApplyCheat('state-machine');
  Assert.IsTrue(FDebug.Flag[wdrRvo]);
  // the last flag has no name: an empty one finds it, and it is printed as a null pointer
  Assert.AreEqual('(null) on', string(FDebug.ApplyCheat('')));
  Assert.IsTrue(FDebug.Flag[wdrStateMachine]);
end;

procedure TTestWarMapCheats.DovrebbeRifiutareUnNomeEUnValore;
begin
  Assert.AreEqual('Unknown debug render flag: foo', string(FDebug.ApplyCheat('foo')));
  Assert.AreEqual('Invalid value: 7 (use 0 or 1)', string(FDebug.ApplyCheat('map-grid 7')));
  Assert.IsFalse(FDebug.Flag[wdrMapGrid]);
end;

procedure TTestWarMapCheats.DovrebbeContareIFlagAcceso;
begin
  Assert.AreEqual('0/13 debug render flags on (see log)', string(FDebug.ApplyCheat('status')));
  FDebug.ApplyCheat('map-grid');
  FDebug.ApplyCheat('near-units');
  Assert.AreEqual('2/13 debug render flags on (see log)', string(FDebug.ApplyCheat('STATUS')));
end;

procedure TTestWarMapCheats.DovrebbeAccendereUnFlagSoloConCtrlEMaiusc;
var
  LInput: TWarUiInput;
  LRef: IWarUiInput;
begin
  LInput := TWarUiInput.Create;
  LRef := LInput;
  // the key alone, or with only one of the two, does nothing
  LInput.SetKey(wkG, True);
  FDebug.UpdateShortcuts(LRef);
  Assert.IsFalse(FDebug.Flag[wdrMapGrid]);
  LInput.BeginFrame;
  LInput.SetKey(wkCtrl, True);
  LInput.SetKey(wkG, False);
  LInput.BeginFrame;
  LInput.SetKey(wkG, True);
  FDebug.UpdateShortcuts(LRef);
  Assert.IsFalse(FDebug.Flag[wdrMapGrid]);
  LInput.BeginFrame;
  LInput.SetKey(wkG, False);
  LInput.SetKey(wkShift, True);
  LInput.BeginFrame;
  LInput.SetKey(wkG, True);
  FDebug.UpdateShortcuts(LRef);
  Assert.IsTrue(FDebug.Flag[wdrMapGrid]);
  // the keys of the table go to their own flags (not the ones of the names)
  LInput.BeginFrame;
  LInput.SetKey(wkG, False);
  LInput.SetKey(wkI, True);
  FDebug.UpdateShortcuts(LRef);
  Assert.IsTrue(FDebug.Flag[wdrUnitInfo]);
  Assert.IsFalse(FDebug.Flag[wdrUnitPaths]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapCheats);

end.

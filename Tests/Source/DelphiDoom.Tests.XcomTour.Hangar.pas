{******************************************************************************}
{                                                                              }
{  DelphiDoom: the screens of a craft (weapons, crew, equipment) and of the    }
{  psionic training of the basescape of OpenXcom, on the game the program      }
{  composes                                                                    }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Hangar;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSave.Craft, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>
  ///   The crafts of the first base of a new game (TRITON-1 with the eight aquanauts, two BARRACUDA with their
  ///   weapons) and a psionic laboratory added to the base. The tests are ignored when the data of the game is not
  ///   there
  /// </summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourHangar = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    function Ready: Boolean;
    /// <summary>From the geoscape to the screen of the craft of the list of the base</summary>
    procedure OpenCraft(const AName: string);
    function Craft(AIndex: Integer): TXcomCraft;
    /// <summary>A finished psionic laboratory in the base; the number of soldiers it trains</summary>
    function AddPsiLaboratory: Integer;
    procedure OpenPsiTraining;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSmontareERimontareLArmaDiUnVelivolo;
    [Test]
    procedure DovrebbeTogliereERimettereUnSoldatoNellEquipaggio;
    [Test]
    procedure DovrebbeRiordinareISoldatiConLeFrecce;
    [Test]
    procedure DovrebbeOrdinareISoldatiPerStatistica;
    [Test]
    procedure DovrebbeAprireLaSchedaDelSoldatoColTastoDestro;
    [Test]
    procedure DovrebbeCaricareEScaricareLEquipaggiamento;
    [Test]
    procedure DovrebbeRipetereLaFrecciaDellEquipaggiamentoTenutaPremuta;
    [Test]
    procedure DovrebbeCaricareUnVeicoloConLeSueMunizioni;
    [Test]
    procedure DovrebbeMettereETogliereUnSoldatoDallAddestramentoPsi;
    [Test]
    procedure DovrebbeFermarsiQuandoIlLaboratorioPsiEPieno;
    [Test]
    procedure DovrebbeMostrareLaForzaPsiQuandoLaRicercaLaRivela;
    [Test]
    procedure DovrebbeElencareLeBasiConUnLaboratorioPsiAFineMese;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.RuleAdapters, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomBasescape.PsiTrainingState, DelphiDoom.XcomBasescape.PsiRequirements;

const
  BASESCAPE = 'TXcomBasescapeState';
  CRAFT_INFO = 'TXcomCraftInfoState';
  /// <summary>The button of the first weapon of TXcomCraftInfoState in the pixels of the window</summary>
  WEAPON_1_X = 52;
  WEAPON_1_Y = 128;

procedure TTestXcomTourHangar.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourHangar.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourHangar.Ready: Boolean;
begin
  Result := FWorld.HasData;
  if Result then
    FWorld.StartNewGame
  else
    Assert.Pass('i dati di TFTD non ci sono');
end;

procedure TTestXcomTourHangar.OpenCraft(const AName: string);
begin
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  Assert.AreEqual(BASESCAPE, FWorld.Top);
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_CRAFTS_Y);
  FWorld.ClickRow(AName, 100);
  Assert.AreEqual(CRAFT_INFO, FWorld.Top);
end;

function TTestXcomTourHangar.Craft(AIndex: Integer): TXcomCraft;
begin
  Result := FWorld.FirstBase.Crafts[AIndex];
end;

function TTestXcomTourHangar.AddPsiLaboratory: Integer;
var
  LRuleset: TXcomRuleset;
  LIndex: Integer;
  LFacility: TXcomBaseFacility;
begin
  LRuleset := TXcomStrategy.Ruleset(FWorld.Game);
  for LIndex := 0 to LRuleset.Facilities.Count - 1 do
    if LRuleset.Facilities.Rule(LIndex).PsiLaboratories > 0 then
    begin
      // built: no days left
      LFacility := TXcomBaseFacility.Create(TXcomFacilityRuleAdapter.Create(LRuleset.Facilities.Rule(LIndex)));
      LFacility.X := 0;
      LFacility.Y := 0;
      FWorld.FirstBase.Facilities.Add(LFacility);
      Exit(LRuleset.Facilities.Rule(LIndex).PsiLaboratories);
    end;
  Assert.Fail('le regole non hanno un laboratorio psi');
  Result := 0;
end;

procedure TTestXcomTourHangar.OpenPsiTraining;
begin
  FWorld.Game.Options.SetBool('anytimePsiTraining', True);
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_SOLDIERS_Y);
  FWorld.ClickButton('M.C. Training');
  Assert.AreEqual('TXcomAllocatePsiTrainingState', FWorld.Top);
end;

procedure TTestXcomTourHangar.DovrebbeSmontareERimontareLArmaDiUnVelivolo;
var
  LLaunchers: Integer;
begin
  if not Ready then
    Exit;
  LLaunchers := FWorld.FirstBase.StorageItems.GetItem('STR_AJAX_LAUNCHER');
  OpenCraft('BARRACUDA-1');
  Assert.IsNotNull(Craft(1).Weapons[0], 'il velivolo parte armato');
  FWorld.Click(WEAPON_1_X, WEAPON_1_Y);
  Assert.AreEqual('TXcomCraftWeaponsState', FWorld.Top);
  FWorld.ClickRow('NONE', 200);
  Assert.AreEqual(CRAFT_INFO, FWorld.Top);
  Assert.IsNull(Craft(1).Weapons[0], 'l''arma e'' smontata');
  FWorld.Click(WEAPON_1_X, WEAPON_1_Y);
  Assert.AreEqual(IntToStr(LLaunchers + 1), FWorld.RowCell('AJAX', 1), 'il lanciatore smontato e'' in magazzino');
  FWorld.ClickRow('AJAX', 200);
  Assert.IsNotNull(Craft(1).Weapons[0]);
  Assert.AreEqual('STR_AJAX', Craft(1).Weapons[0].Rules.WeaponType);
  Assert.IsTrue(Craft(1).Weapons[0].Rearming, 'l''arma nuova va caricata');
  Assert.AreEqual('STR_REARMING', Craft(1).Status);
  Assert.AreEqual(LLaunchers, FWorld.FirstBase.StorageItems.GetItem('STR_AJAX_LAUNCHER'),
    'il lanciatore rimontato esce dal magazzino');
  FWorld.Click(WEAPON_1_X, WEAPON_1_Y);
  FWorld.ClickButton('CANCEL');
  Assert.AreEqual('STR_AJAX', Craft(1).Weapons[0].Rules.WeaponType, 'Cancel non cambia nulla');
end;

procedure TTestXcomTourHangar.DovrebbeTogliereERimettereUnSoldatoNellEquipaggio;
var
  LSoldier: TXcomSoldier;
begin
  if not Ready then
    Exit;
  LSoldier := FWorld.FirstBase.Soldiers[2];
  OpenCraft('TRITON-1');
  FWorld.ClickButton('CREW');
  Assert.IsTrue(FWorld.Shows('SPACE USED>8'), FWorld.Describe);
  FWorld.ClickRow(LSoldier.Name, 100);
  Assert.IsNull(LSoldier.Craft, 'il clic toglie il soldato dal velivolo');
  Assert.AreEqual('NONE', FWorld.RowCell(LSoldier.Name, 2));
  Assert.IsTrue(FWorld.Shows('SPACE USED>7'), FWorld.Describe);
  FWorld.ClickRow(LSoldier.Name, 100);
  Assert.AreSame(Craft(0), LSoldier.Craft, 'un altro clic lo rimette');
  Assert.AreEqual('TRITON-1', FWorld.RowCell(LSoldier.Name, 2));
  FWorld.ClickButton('OK');
  Assert.AreEqual(CRAFT_INFO, FWorld.Top);
end;

procedure TTestXcomTourHangar.DovrebbeRiordinareISoldatiConLeFrecce;
var
  LFirst, LSecond, LThird: TXcomSoldier;
begin
  if not Ready then
    Exit;
  LFirst := FWorld.FirstBase.Soldiers[0];
  LSecond := FWorld.FirstBase.Soldiers[1];
  LThird := FWorld.FirstBase.Soldiers[2];
  OpenCraft('TRITON-1');
  FWorld.ClickButton('CREW');
  // the second arrow moves a soldier down, the first one up
  FWorld.ClickRow(LFirst.Name, FWorld.RowArrowX(True));
  Assert.AreSame(LSecond, FWorld.FirstBase.Soldiers[0]);
  Assert.AreSame(LFirst, FWorld.FirstBase.Soldiers[1]);
  FWorld.ClickRow(LFirst.Name, FWorld.RowArrowX(False));
  Assert.AreSame(LFirst, FWorld.FirstBase.Soldiers[0], 'la freccia in su lo riporta in testa');
  // the right button sends a soldier to the bottom or to the top
  FWorld.ClickRow(LFirst.Name, FWorld.RowArrowX(True), XCOM_BUTTON_RIGHT);
  Assert.AreSame(LFirst, FWorld.FirstBase.Soldiers.Last, 'il tasto destro lo manda in fondo');
  FWorld.ClickRow(LThird.Name, FWorld.RowArrowX(False), XCOM_BUTTON_RIGHT);
  Assert.AreSame(LThird, FWorld.FirstBase.Soldiers[0], 'e in cima');
  Assert.AreSame(Craft(0), LThird.Craft, 'le frecce non cambiano l''equipaggio');
end;

procedure TTestXcomTourHangar.DovrebbeOrdinareISoldatiPerStatistica;
var
  LIndex: Integer;
  LStats: TXcomUnitStats;
begin
  if not Ready then
    Exit;
  // the first soldier is the one with the most time units
  LStats := FWorld.FirstBase.Soldiers.First.CurrentStats;
  LStats.TimeUnits := 99;
  FWorld.FirstBase.Soldiers.First.CurrentStats := LStats;
  OpenCraft('TRITON-1');
  FWorld.ClickButton('CREW');
  FWorld.ChooseCombo('TIME UNITS');
  for LIndex := 1 to FWorld.FirstBase.Soldiers.Count - 1 do
    Assert.IsTrue(FWorld.FirstBase.Soldiers[LIndex - 1].CurrentStats.TimeUnits <= FWorld.FirstBase.Soldiers[LIndex].CurrentStats.TimeUnits,
      Format('i soldati sono in ordine crescente di unita'' di tempo (%d): %s', [LIndex, FWorld.Describe]));
  Assert.AreEqual(99, FWorld.FirstBase.Soldiers.Last.CurrentStats.TimeUnits);
end;

procedure TTestXcomTourHangar.DovrebbeAprireLaSchedaDelSoldatoColTastoDestro;
begin
  if not Ready then
    Exit;
  OpenCraft('TRITON-1');
  FWorld.ClickButton('CREW');
  FWorld.ClickRow(FWorld.FirstBase.Soldiers[1].Name, 100, XCOM_BUTTON_RIGHT);
  Assert.AreEqual('TXcomSoldierInfoState', FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  Assert.AreEqual('TXcomCraftSoldiersState', FWorld.Top);
  Assert.AreSame(Craft(0), FWorld.FirstBase.Soldiers[1].Craft, 'il tasto destro non cambia l''equipaggio');
end;

procedure TTestXcomTourHangar.DovrebbeCaricareEScaricareLEquipaggiamento;
var
  LStored, LLoaded: Integer;
begin
  if not Ready then
    Exit;
  LStored := FWorld.FirstBase.StorageItems.GetItem('STR_DART_PISTOL');
  LLoaded := Craft(0).Items.GetItem('STR_DART_PISTOL');
  Assert.IsTrue(LStored >= 2, 'il magazzino ha due Dart Gun');
  OpenCraft('TRITON-1');
  FWorld.ClickButton('EQUIPMENT');
  Assert.AreEqual('TXcomCraftEquipmentState', FWorld.Top);
  // the second arrow loads the craft, the first one unloads it
  FWorld.ClickRow('Dart Gun', FWorld.RowArrowX(True));
  FWorld.ClickRow('Dart Gun', FWorld.RowArrowX(True));
  Assert.AreEqual(LLoaded + 2, Craft(0).Items.GetItem('STR_DART_PISTOL'));
  Assert.AreEqual(LStored - 2, FWorld.FirstBase.StorageItems.GetItem('STR_DART_PISTOL'));
  Assert.AreEqual(IntToStr(LStored - 2), FWorld.RowCell('Dart Gun', 1), 'la riga mostra il magazzino');
  Assert.AreEqual(IntToStr(LLoaded + 2), FWorld.RowCell('Dart Gun', 2), 'e il velivolo');
  FWorld.ClickRow('Dart Gun', FWorld.RowArrowX(False));
  Assert.AreEqual(LLoaded + 1, Craft(0).Items.GetItem('STR_DART_PISTOL'));
  // the right button moves everything
  FWorld.ClickRow('Dart Gun', FWorld.RowArrowX(True), XCOM_BUTTON_RIGHT);
  Assert.AreEqual(0, FWorld.FirstBase.StorageItems.GetItem('STR_DART_PISTOL'), 'il tasto destro carica tutto');
  FWorld.ClickRow('Dart Gun', FWorld.RowArrowX(False), XCOM_BUTTON_RIGHT);
  Assert.AreEqual(0, Craft(0).Items.GetItem('STR_DART_PISTOL'), 'e scarica tutto');
  Assert.AreEqual(LStored + LLoaded, FWorld.FirstBase.StorageItems.GetItem('STR_DART_PISTOL'));
  FWorld.ClickButton('OK');
  Assert.AreEqual(CRAFT_INFO, FWorld.Top);
end;

procedure TTestXcomTourHangar.DovrebbeRipetereLaFrecciaDellEquipaggiamentoTenutaPremuta;
var
  LStored, LLoaded, LY: Integer;
begin
  if not Ready then
    Exit;
  FWorld.FirstBase.StorageItems.AddItem('STR_DART_PISTOL', 20);
  LStored := FWorld.FirstBase.StorageItems.GetItem('STR_DART_PISTOL');
  LLoaded := Craft(0).Items.GetItem('STR_DART_PISTOL');
  OpenCraft('TRITON-1');
  FWorld.ClickButton('EQUIPMENT');
  Assert.IsTrue(FWorld.FindRow('Dart Gun', LY) >= 0);
  FWorld.Press(FWorld.RowArrowX(True), LY);
  FWorld.Wait(1000);
  FWorld.Release(FWorld.RowArrowX(True), LY);
  Assert.IsTrue(Craft(0).Items.GetItem('STR_DART_PISTOL') > LLoaded + 5,
    Format('la freccia tenuta premuta carica col tempo (%d)', [Craft(0).Items.GetItem('STR_DART_PISTOL')]));
  Assert.AreEqual(LStored + LLoaded, FWorld.FirstBase.StorageItems.GetItem('STR_DART_PISTOL') +
    Craft(0).Items.GetItem('STR_DART_PISTOL'), 'nulla si perde');
  FWorld.Press(FWorld.RowArrowX(False), LY);
  FWorld.Wait(3000);
  FWorld.Release(FWorld.RowArrowX(False), LY);
  Assert.AreEqual(0, Craft(0).Items.GetItem('STR_DART_PISTOL'), 'e quella a sinistra scarica tutto');
  // the wheel over the arrows, when the option gives it a step
  FWorld.Game.Options.ChangeValueByMouseWheel := 3;
  FWorld.Press(FWorld.RowArrowX(True), LY, XCOM_BUTTON_WHEELUP);
  FWorld.Release(FWorld.RowArrowX(True), LY, XCOM_BUTTON_WHEELUP);
  Assert.AreEqual(3, Craft(0).Items.GetItem('STR_DART_PISTOL'), 'la rotella in su carica');
  FWorld.Press(FWorld.RowArrowX(True), LY, XCOM_BUTTON_WHEELDOWN);
  FWorld.Release(FWorld.RowArrowX(True), LY, XCOM_BUTTON_WHEELDOWN);
  Assert.AreEqual(0, Craft(0).Items.GetItem('STR_DART_PISTOL'), 'la rotella in giu'' scarica');
end;

procedure TTestXcomTourHangar.DovrebbeCaricareUnVeicoloConLeSueMunizioni;
begin
  if not Ready then
    Exit;
  // a tank without its ammunition does not go on board
  FWorld.FirstBase.StorageItems.AddItem('STR_COELACANTH_GAUSS', 1);
  OpenCraft('TRITON-1');
  FWorld.ClickButton('EQUIPMENT');
  FWorld.ClickRow('Coelacanth/Gauss', FWorld.RowArrowX(True));
  Assert.AreEqual('TXcomErrorMessageState', FWorld.Top, 'senza munizioni: ' + FWorld.Describe);
  FWorld.ClickButton('OK');
  Assert.AreEqual(0, Craft(0).Vehicles.Count);
  FWorld.FirstBase.StorageItems.AddItem('STR_GAUSS_CANNON_AMMO', 100);
  FWorld.ClickRow('Coelacanth/Gauss', FWorld.RowArrowX(True));
  Assert.AreEqual(1, Craft(0).Vehicles.Count, 'con le munizioni il veicolo sale: ' + FWorld.Describe);
  Assert.AreEqual(0, FWorld.FirstBase.StorageItems.GetItem('STR_COELACANTH_GAUSS'));
  FWorld.ClickRow('Coelacanth/Gauss', FWorld.RowArrowX(False));
  Assert.AreEqual(0, Craft(0).Vehicles.Count, 'e scende');
  Assert.AreEqual(1, FWorld.FirstBase.StorageItems.GetItem('STR_COELACANTH_GAUSS'));
  Assert.AreEqual(100, FWorld.FirstBase.StorageItems.GetItem('STR_GAUSS_CANNON_AMMO'), 'con le sue munizioni');
end;

procedure TTestXcomTourHangar.DovrebbeMettereETogliereUnSoldatoDallAddestramentoPsi;
var
  LSoldier: TXcomSoldier;
  LCapacity: Integer;
begin
  if not Ready then
    Exit;
  LCapacity := AddPsiLaboratory;
  LSoldier := FWorld.FirstBase.Soldiers[1];
  OpenPsiTraining;
  Assert.AreEqual('NO', FWorld.RowCell(LSoldier.Name, 3));
  Assert.AreEqual('Unknown', FWorld.RowCell(LSoldier.Name, 1), 'la forza non e'' nota senza la ricerca');
  Assert.IsTrue(FWorld.Shows(Format('capacity> %d', [LCapacity])), FWorld.Describe);
  FWorld.ClickRow(LSoldier.Name, 100);
  Assert.IsTrue(LSoldier.PsiTraining, 'il clic mette il soldato in addestramento');
  Assert.AreEqual('YES', FWorld.RowCell(LSoldier.Name, 3));
  Assert.IsTrue(FWorld.Shows(Format('capacity> %d', [LCapacity - 1])), FWorld.Describe);
  // the right button does nothing
  FWorld.ClickRow(LSoldier.Name, 100, XCOM_BUTTON_RIGHT);
  Assert.IsTrue(LSoldier.PsiTraining);
  FWorld.ClickRow(LSoldier.Name, 100);
  Assert.IsFalse(LSoldier.PsiTraining, 'un altro clic lo toglie');
  Assert.AreEqual('NO', FWorld.RowCell(LSoldier.Name, 3));
  Assert.IsTrue(FWorld.Shows(Format('capacity> %d', [LCapacity])), FWorld.Describe);
  FWorld.ClickButton('OK');
  Assert.AreEqual('TXcomSoldiersState', FWorld.Top);
end;

procedure TTestXcomTourHangar.DovrebbeFermarsiQuandoIlLaboratorioPsiEPieno;
var
  LCapacity, LIndex: Integer;
  LLast: TXcomSoldier;
begin
  if not Ready then
    Exit;
  LCapacity := AddPsiLaboratory;
  // more soldiers than the laboratory trains: the first ones fill it
  while FWorld.FirstBase.Soldiers.Count <= LCapacity do
    FWorld.FirstBase.Soldiers.Add(TXcomSoldier.Create(FWorld.FirstBase.Soldiers[0].Rules,
      FWorld.FirstBase.Soldiers[0].Armor, 900 + FWorld.FirstBase.Soldiers.Count, TXcomStrategy.Random(FWorld.Game)));
  for LIndex := 0 to LCapacity - 1 do
    FWorld.FirstBase.Soldiers[LIndex].PsiTraining := True;
  LLast := FWorld.FirstBase.Soldiers[LCapacity];
  LLast.Name := 'Ultimo Arrivato';
  OpenPsiTraining;
  Assert.IsTrue(FWorld.Shows('capacity> 0'), FWorld.Describe);
  FWorld.ClickRow(LLast.Name, 100);
  Assert.IsFalse(LLast.PsiTraining, 'il laboratorio pieno non prende altri soldati');
  Assert.AreEqual('NO', FWorld.RowCell(LLast.Name, 3));
end;

procedure TTestXcomTourHangar.DovrebbeMostrareLaForzaPsiQuandoLaRicercaLaRivela;
var
  LSoldier: TXcomSoldier;
  LRuleset: TXcomRuleset;
  LRequired: string;
  LStats: TXcomUnitStats;
begin
  if not Ready then
    Exit;
  AddPsiLaboratory;
  LRuleset := TXcomStrategy.Ruleset(FWorld.Game);
  for LRequired in TXcomPsiRequirements.Resolve(LRuleset) do
    FWorld.Save.Discovered.Add(LRuleset.Research.Find(LRequired));
  FWorld.Game.Options.SetBool('psiStrengthEval', True);
  LSoldier := FWorld.FirstBase.Soldiers[0];
  LStats := LSoldier.CurrentStats;
  LStats.PsiStrength := 77;
  LStats.PsiSkill := 21;
  LSoldier.CurrentStats := LStats;
  OpenPsiTraining;
  Assert.AreEqual('77', FWorld.RowCell(LSoldier.Name, 1).Trim, 'la forza del soldato');
  Assert.AreEqual('21/+0', FWorld.RowCell(LSoldier.Name, 2), 'abilita'' e miglioramento del mese');
  Assert.AreNotEqual('Unknown', FWorld.RowCell(FWorld.FirstBase.Soldiers[1].Name, 1),
    'la ricerca rivela la forza anche di chi non ha abilita''');
end;

procedure TTestXcomTourHangar.DovrebbeElencareLeBasiConUnLaboratorioPsiAFineMese;
begin
  if not Ready then
    Exit;
  AddPsiLaboratory;
  // what the monthly report opens when a base has a laboratory
  FWorld.Game.PushState(TXcomPsiTrainingState.Create(FWorld.Game));
  FWorld.Wait(500);
  Assert.AreEqual('TXcomPsiTrainingState', FWorld.Top);
  Assert.IsTrue(FWorld.HasButton('ab'), 'la base col laboratorio ha il suo pulsante: ' + FWorld.Describe);
  FWorld.ClickButton('ab');
  Assert.AreEqual('TXcomAllocatePsiTrainingState', FWorld.Top);
  FWorld.ClickButton('OK');
  Assert.AreEqual('TXcomPsiTrainingState', FWorld.Top);
  FWorld.ClickButton('OK');
  Assert.AreEqual('TXcomGeoscapeState', FWorld.Top);
end;

end.

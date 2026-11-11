{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom debriefing library - the screens that     }
{  follow the debriefing and their order (with the fake game of the engine     }
{  tests and a ruleset made from a few lines)                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomDebriefing.FollowUp;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Session.Intf, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomDebriefing.Types,
  DelphiDoom.Tests.XcomEngine.World;

type
  [TestFixture]
  [Category('xcom-debriefing')]
  TTestXcomDebriefingFollowUp = class(TObject)
  strict private
    FWorld: TTestWorld;
    FRuleset: TXcomRuleset;
    FSave: TXcomSavedGame;
    FBase: TXcomBase;
    FReport: TXcomDebriefingReport;
    FSoldiers: TObjectList<TXcomSoldier>;
    function NewSoldier(const AName: string): TXcomSoldier;
    procedure AddCommendation(ASoldier: TXcomSoldier; const AType, ANoun: string; ALevel: Integer);
    /// <summary>The class names of the states that were pushed, from the top (the first that the player sees)</summary>
    function PushedStates(AStorageLimits: Boolean; const AMainMenu: TFunc<TXcomState>): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('primo livello', '0,STR_AWARD_0')]
    [TestCase('soglia ripetuta', '2,STR_AWARD_1')]
    [TestCase('dopo la soglia ripetuta', '3,STR_AWARD_2')]
    procedure DovrebbeSaltareLeSoglieRipetuteNelNomeDelLivello(ALevel: Integer; const AExpected: string);
    [Test]
    procedure DovrebbeElencareLeMedagliePerTipoConISoldatiCheLeHannoAvute;
    [Test]
    procedure DovrebbeRendereVecchieLeMedaglieMostrate;
    [Test]
    procedure DovrebbeElencareIMortiConGradoUccisioniEMedaglie;
    [Test]
    procedure DovrebbeElencareIPromossiUnaVoltaSola;
    [Test]
    procedure DovrebbeElencareGliAlieniViviDellaBase;
    [Test]
    procedure DovrebbeTrasformareInCadaveriGliAlieniRimossi;
    [Test]
    procedure DovrebbeLasciareGliAlieniSeSiAnnulla;
    [Test]
    procedure DovrebbeMettereLeSchermateNellOrdineDelDebriefingVero;
    [Test]
    procedure DovrebbeMostrareSoloLeMedaglieSeLaBaseEPersa;
    [Test]
    procedure DovrebbeTornareAlMenuPrincipaleFuoriDaUnaCampagna;
    [Test]
    procedure DovrebbeNonMettereNullaSeIlResocontoNonHaNulla;
    [Test]
    procedure DovrebbeSalvareLaPartitaIronmanPerUltima;
    [Test]
    procedure DovrebbeFareIlSalvataggioAutomaticoSeLOpzioneEAccesa;
    [Test]
    procedure DovrebbeDireUnaVoltaSolaCheLAlienoEMortoSenzaContenimento;
  end;

implementation

uses
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.RuleCommendations, DelphiDoom.XcomSave.SoldierCommendation, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.ErrorMessageState,
  DelphiDoom.XcomMenu.SaveGameState, DelphiDoom.XcomDebriefing.CommendationNames,
  DelphiDoom.XcomDebriefing.CommendationState, DelphiDoom.XcomDebriefing.CommendationLateState,
  DelphiDoom.XcomDebriefing.PromotionsState, DelphiDoom.XcomDebriefing.ManageAlienContainmentState,
  DelphiDoom.XcomDebriefing.DebriefingState, DelphiDoom.XcomDebriefing.FollowUp;

type
  TStateSurfaces = class(TXcomState);

  /// <summary>The sizes of the shared sets that a ruleset asks for (none of the rules of the test uses them)</summary>
  TFixedShared = class(TInterfacedObject, IXcomSharedResources)
  public
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

  /// <summary>A saved game that can be saved: only the ironman flag matters to the follow up</summary>
  TFakeSaver = class(TInterfacedObject, IXcomSavedGameSaver)
  strict private
    FIronman: Boolean;
  public
    constructor Create(AIronman: Boolean);
    function IsIronman: Boolean;
    procedure SetName(const AName: string);
    function GetName: string;
    procedure SaveGame(const AFileName: string);
    procedure AbandonGame;
  end;

const
  RULES =
    'items: [{type: STR_ALIEN_A, liveAlien: true, costSell: 100}, {type: STR_ALIEN_B, liveAlien: true}, ' +
    '{type: STR_CORPSE_A}, {type: STR_RIFLE}], ' +
    'units: [{type: STR_ALIEN_A, armor: ARMOR_A}], ' +
    'armors: [{type: ARMOR_A, corpseGeo: STR_CORPSE_A}], ' +
    'commendations: [{type: STR_MEDAL_KILLS, criteria: {totalKills: [1, 2, 2, 5]}}, ' +
    '{type: STR_MEDAL_RACE, criteria: {totalMissions: [3, 6]}}]';

{ TFixedShared }

function TFixedShared.MaxSharedSounds(const ASet: string): Integer;
begin
  Result := 20;
end;

function TFixedShared.MaxSharedFrames(const ASet: string): Integer;
begin
  Result := 100;
end;

{ TFakeSaver }

constructor TFakeSaver.Create(AIronman: Boolean);
begin
  inherited Create;
  FIronman := AIronman;
end;

function TFakeSaver.IsIronman: Boolean;
begin
  Result := FIronman;
end;

procedure TFakeSaver.SetName(const AName: string);
begin
end;

function TFakeSaver.GetName: string;
begin
  Result := 'ironman';
end;

procedure TFakeSaver.SaveGame(const AFileName: string);
begin
end;

procedure TFakeSaver.AbandonGame;
begin
end;

{ TTestXcomDebriefingFollowUp }

procedure TTestXcomDebriefingFollowUp.Setup;
begin
  FWorld := TTestWorld.Create;
  FRuleset := TXcomRuleset.Create(TFixedShared.Create);
  FRuleset.SetMods(TArray<TXcomModData>.Create(TXcomModData.Make('master', 0, 1000)), 0);
  FRuleset.LoadFile(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes('{' + RULES + '}')));
  FSave := TXcomSavedGame.Create;
  FSave.MonthsPassed := 0;
  FBase := TXcomBase.Create;
  FBase.Name := 'Atlantis';
  FSave.Bases.Add(FBase);
  FReport := TXcomDebriefingReport.Create;
  FReport.Base := FBase;
  // the soldiers that no base owns (the dead ones of the report)
  FSoldiers := TObjectList<TXcomSoldier>.Create(True);
end;

procedure TTestXcomDebriefingFollowUp.TearDown;
begin
  FWorld.Free;
  FReport.Free;
  FSoldiers.Free;
  FSave.Free;
  FRuleset.Free;
end;

function TTestXcomDebriefingFollowUp.NewSoldier(const AName: string): TXcomSoldier;
begin
  Result := TXcomSoldier.Create(nil, nil, 0, nil);
  Result.Name := AName;
end;

procedure TTestXcomDebriefingFollowUp.AddCommendation(ASoldier: TXcomSoldier; const AType, ANoun: string;
  ALevel: Integer);
var
  LCommendation: TXcomSoldierCommendation;
  LIndex: Integer;
begin
  LCommendation := TXcomSoldierCommendation.Create(AType, ANoun);
  for LIndex := 1 to ALevel do
    LCommendation.AddDecoration;
  ASoldier.Diary.Commendations.Add(LCommendation);
end;

function TTestXcomDebriefingFollowUp.PushedStates(AStorageLimits: Boolean;
  const AMainMenu: TFunc<TXcomState>): string;
var
  LFollowUp: TXcomDebriefingFollowUp;
  LBottom: TXcomState;
  LColors: TXcomColors;
begin
  // a state under the ones that are pushed: the list ends there
  LBottom := TXcomState.Create(FWorld.Game);
  FWorld.Game.PushState(LBottom);
  FillChar(LColors, SizeOf(LColors), 0);
  LFollowUp := TXcomDebriefingFollowUp.Create(FWorld.Game, FSave, FRuleset, AStorageLimits, AMainMenu);
  try
    LFollowUp.Push(FReport, @LColors);
  finally
    LFollowUp.Free;
  end;
  Result := '';
  while (FWorld.Game.TopState <> nil) and (FWorld.Game.TopState <> LBottom) do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + FWorld.Game.TopState.ClassName;
    FWorld.Game.PopState;
  end;
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeSaltareLeSoglieRipetuteNelNomeDelLivello(ALevel: Integer;
  const AExpected: string);
var
  LCommendation: TXcomSoldierCommendation;
  LRule: TXcomRuleCommendations;
  LIndex: Integer;
begin
  Assert.IsTrue(FRuleset.Commendations.TryGetValue('STR_MEDAL_KILLS', LRule));
  LCommendation := TXcomSoldierCommendation.Create('STR_MEDAL_KILLS', TXcomCommendationNames.NO_NOUN);
  try
    for LIndex := 1 to ALevel do
      LCommendation.AddDecoration;
    // le soglie sono 1, 2, 2, 5: la terza ripete la seconda e non ha un nome suo
    Assert.AreEqual(AExpected, TXcomCommendationNames.LevelKey(LRule, LCommendation));
  finally
    LCommendation.Free;
  end;
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeElencareLeMedagliePerTipoConISoldatiCheLeHannoAvute;
var
  LState: TXcomCommendationState;
  LFirst, LSecond: TXcomSoldier;
begin
  LFirst := NewSoldier('Ada');
  LSecond := NewSoldier('Bruno');
  FBase.Soldiers.Add(LFirst);
  FBase.Soldiers.Add(LSecond);
  AddCommendation(LFirst, 'STR_MEDAL_KILLS', TXcomCommendationNames.NO_NOUN, 0);
  AddCommendation(LSecond, 'STR_MEDAL_KILLS', TXcomCommendationNames.NO_NOUN, 2);
  AddCommendation(LSecond, 'STR_MEDAL_RACE', 'STR_GILLMAN', 0);
  FReport.SoldiersCommended.Add(LFirst);
  FReport.SoldiersCommended.Add(LSecond);
  LState := TXcomCommendationState.Create(FWorld.Game, FReport.SoldiersCommended, FRuleset.Commendations);
  FWorld.Game.PushState(LState);
  // il nome della medaglia, poi chi l'ha avuta; la medaglia con un nome proprio ha la sua riga; l'ultima riga vuota
  // e' quella che il vero programma lascia per il titolo dopo
  Assert.AreEqual(6, LState.List.GetRows);
  Assert.AreEqual('STR_MEDAL_KILLS', LState.List.GetCellText(0, 0));
  Assert.AreEqual('   Ada', LState.List.GetCellText(1, 0));
  Assert.AreEqual('STR_AWARD_0', LState.List.GetCellText(1, 1));
  Assert.AreEqual('   Bruno', LState.List.GetCellText(2, 0));
  Assert.AreEqual('STR_AWARD_1', LState.List.GetCellText(2, 1));
  Assert.AreEqual('STR_MEDAL_RACE', LState.List.GetCellText(3, 0));
  Assert.AreEqual('   Bruno', LState.List.GetCellText(4, 0));
  Assert.AreEqual('', LState.List.GetCellText(5, 0));
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeRendereVecchieLeMedaglieMostrate;
var
  LState: TXcomCommendationState;
  LSoldier: TXcomSoldier;
begin
  LSoldier := NewSoldier('Ada');
  FBase.Soldiers.Add(LSoldier);
  AddCommendation(LSoldier, 'STR_MEDAL_KILLS', TXcomCommendationNames.NO_NOUN, 0);
  FReport.SoldiersCommended.Add(LSoldier);
  LState := TXcomCommendationState.Create(FWorld.Game, FReport.SoldiersCommended, FRuleset.Commendations);
  try
    Assert.IsFalse(LSoldier.Diary.Commendations[0].IsNew);
  finally
    LState.Free;
  end;
  // una seconda schermata non ha piu' medaglie nuove da mostrare: resta la riga vuota del primo titolo
  LState := TXcomCommendationState.Create(FWorld.Game, FReport.SoldiersCommended, FRuleset.Commendations);
  try
    Assert.AreEqual(1, LState.List.GetRows);
  finally
    LState.Free;
  end;
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeElencareIMortiConGradoUccisioniEMedaglie;
var
  LState: TXcomCommendationLateState;
  LSoldier: TXcomSoldier;
begin
  LSoldier := NewSoldier('Carla');
  FSoldiers.Add(LSoldier);
  AddCommendation(LSoldier, 'STR_MEDAL_RACE', 'STR_GILLMAN', 1);
  FReport.DeadSoldiersCommended.Add(LSoldier);
  LState := TXcomCommendationLateState.Create(FWorld.Game, FReport.DeadSoldiersCommended, FRuleset.Commendations);
  FWorld.Game.PushState(LState);
  Assert.AreEqual(2, LState.List.GetRows);
  Assert.AreEqual('Carla', LState.List.GetCellText(0, 0));
  Assert.AreEqual('STR_ROOKIE', LState.List.GetCellText(0, 2));
  Assert.AreEqual('STR_KILLS', LState.List.GetCellText(0, 4));
  Assert.AreEqual('   STR_MEDAL_RACE', LState.List.GetCellText(1, 0));
  Assert.AreEqual('STR_AWARD_1', LState.List.GetCellText(1, 4));
  Assert.IsFalse(LSoldier.Diary.Commendations[0].IsNew);
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeElencareIPromossiUnaVoltaSola;
var
  LState: TXcomPromotionsState;
  LPromoted, LOther: TXcomSoldier;
begin
  LPromoted := NewSoldier('Dario');
  LOther := NewSoldier('Elsa');
  FBase.Soldiers.Add(LPromoted);
  FBase.Soldiers.Add(LOther);
  // da recluta a sergente: sopra il primo grado la promozione si annuncia
  LPromoted.PromoteRank;
  LPromoted.PromoteRank;
  LState := TXcomPromotionsState.Create(FWorld.Game, FSave);
  try
    Assert.AreEqual(1, LState.List.GetRows);
    Assert.AreEqual('Dario', LState.List.GetCellText(0, 0));
    Assert.AreEqual('STR_SERGEANT', LState.List.GetCellText(0, 1));
    Assert.AreEqual('Atlantis', LState.List.GetCellText(0, 2));
  finally
    LState.Free;
  end;
  LState := TXcomPromotionsState.Create(FWorld.Game, FSave);
  try
    Assert.AreEqual(0, LState.List.GetRows);
  finally
    LState.Free;
  end;
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeElencareGliAlieniViviDellaBase;
var
  LState: TXcomManageAlienContainmentState;
begin
  FBase.StorageItems.AddItem('STR_ALIEN_A', 3);
  FBase.StorageItems.AddItem('STR_ALIEN_B', 1);
  FBase.StorageItems.AddItem('STR_RIFLE', 5);
  LState := TXcomManageAlienContainmentState.Create(FWorld.Game, FBase, FSave, FRuleset, ooBattlescape);
  FWorld.Game.PushState(LState);
  // solo gli alieni vivi, nell'ordine degli oggetti del regolamento: nome, quanti, quanti da togliere, interrogati
  Assert.AreEqual(2, LState.List.GetRows);
  Assert.AreEqual('STR_ALIEN_A', LState.List.GetCellText(0, 0));
  Assert.AreEqual('3', LState.List.GetCellText(0, 1));
  Assert.AreEqual('0', LState.List.GetCellText(0, 2));
  Assert.AreEqual('0', LState.List.GetCellText(0, 3));
  Assert.AreEqual('STR_ALIEN_B', LState.List.GetCellText(1, 0));
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeTrasformareInCadaveriGliAlieniRimossi;
var
  LState: TXcomManageAlienContainmentState;
  LButton: TXcomTextButton;
begin
  FBase.StorageItems.AddItem('STR_ALIEN_A', 3);
  LState := TXcomManageAlienContainmentState.Create(FWorld.Game, FBase, FSave, FRuleset, ooBattlescape);
  FWorld.Game.PushState(LState);
  FWorld.Wait(100);
  // due clic sulla freccia destra della prima riga: due alieni da togliere
  FWorld.Click((LState.List.GetArrowsRightEdge - 4) * 2, (LState.List.Y + 4) * 2);
  FWorld.Click((LState.List.GetArrowsRightEdge - 4) * 2, (LState.List.Y + 4) * 2);
  Assert.AreEqual(2, LState.AliensSold);
  Assert.AreEqual('1', LState.List.GetCellText(0, 1));
  Assert.AreEqual('2', LState.List.GetCellText(0, 2));
  // un clic sulla freccia sinistra ne rimette uno
  FWorld.Click((LState.List.GetArrowsLeftEdge + 4) * 2, (LState.List.Y + 4) * 2);
  Assert.AreEqual(1, LState.AliensSold);
  LButton := LState.OkButton;
  FWorld.Click((LButton.X + LButton.Width div 2) * 2, (LButton.Y + LButton.Height div 2) * 2);
  Assert.AreEqual(2, FBase.StorageItems.GetItem('STR_ALIEN_A'));
  Assert.AreEqual(1, FBase.StorageItems.GetItem('STR_CORPSE_A'));
  Assert.IsFalse(FWorld.Game.IsState(LState));
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeLasciareGliAlieniSeSiAnnulla;
var
  LState: TXcomManageAlienContainmentState;
  LWidget: TXcomWidget;
  LCancel: TXcomTextButton;
begin
  FBase.StorageItems.AddItem('STR_ALIEN_A', 3);
  LState := TXcomManageAlienContainmentState.Create(FWorld.Game, FBase, FSave, FRuleset, ooBattlescape);
  FWorld.Game.PushState(LState);
  FWorld.Wait(100);
  FWorld.Click((LState.List.GetArrowsRightEdge - 4) * 2, (LState.List.Y + 4) * 2);
  LCancel := nil;
  for LWidget in TStateSurfaces(LState).Surfaces do
    if (LWidget is TXcomTextButton) and (LWidget <> LState.OkButton) then
      LCancel := TXcomTextButton(LWidget);
  Assert.IsNotNull(LCancel);
  FWorld.Click((LCancel.X + LCancel.Width div 2) * 2, (LCancel.Y + LCancel.Height div 2) * 2);
  Assert.AreEqual(3, FBase.StorageItems.GetItem('STR_ALIEN_A'));
  Assert.AreEqual(0, FBase.StorageItems.GetItem('STR_CORPSE_A'));
  Assert.IsFalse(FWorld.Game.IsState(LState));
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeMettereLeSchermateNellOrdineDelDebriefingVero;
var
  LAlive, LDead: TXcomSoldier;
  LMissing: TXcomReequipStat;
begin
  LAlive := NewSoldier('Ada');
  FBase.Soldiers.Add(LAlive);
  LDead := NewSoldier('Carla');
  FSoldiers.Add(LDead);
  FReport.SoldiersCommended.Add(LAlive);
  FReport.DeadSoldiersCommended.Add(LDead);
  FReport.Promotions := True;
  LMissing.Item := 'STR_RIFLE';
  LMissing.Quantity := 1;
  LMissing.CraftName := 'TRITON-1';
  FReport.MissingItems.Add(LMissing);
  FReport.ManageContainment := True;
  // dall'alto (la prima che il giocatore vede): il messaggio, il contenimento, gli oggetti mancanti, le promozioni,
  // le medaglie e per ultime quelle dei caduti
  Assert.AreEqual('TXcomErrorMessageState,TXcomManageAlienContainmentState,TXcomCannotReequipState,' +
    'TXcomPromotionsState,TXcomCommendationState,TXcomCommendationLateState', PushedStates(False, nil));
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeMostrareSoloLeMedaglieSeLaBaseEPersa;
var
  LDead: TXcomSoldier;
  LMissing: TXcomReequipStat;
begin
  LDead := NewSoldier('Carla');
  FSoldiers.Add(LDead);
  FReport.DeadSoldiersCommended.Add(LDead);
  FReport.Promotions := True;
  LMissing.Item := 'STR_RIFLE';
  LMissing.Quantity := 1;
  LMissing.CraftName := 'TRITON-1';
  FReport.MissingItems.Add(LMissing);
  FReport.ManageContainment := True;
  FReport.DestroyBase := True;
  Assert.AreEqual('TXcomCommendationLateState', PushedStates(False, nil));
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeTornareAlMenuPrincipaleFuoriDaUnaCampagna;
var
  LMenu: TXcomState;
  LFollowUp: TXcomDebriefingFollowUp;
  LColors: TXcomColors;
begin
  // la battaglia di New Battle: monthsPassed = -1
  FSave.MonthsPassed := -1;
  FReport.Promotions := True;
  LMenu := nil;
  FillChar(LColors, SizeOf(LColors), 0);
  FWorld.Game.PushState(TXcomState.Create(FWorld.Game));
  LFollowUp := TXcomDebriefingFollowUp.Create(FWorld.Game, FSave, FRuleset, False,
    function: TXcomState
    begin
      LMenu := TXcomState.Create(FWorld.Game);
      Result := LMenu;
    end);
  try
    LFollowUp.Push(FReport, @LColors);
  finally
    LFollowUp.Free;
  end;
  Assert.IsNotNull(LMenu);
  FWorld.Wait(20);
  // SetState: il menu e' il solo stato rimasto
  Assert.IsTrue(FWorld.Game.IsState(LMenu));
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeNonMettereNullaSeIlResocontoNonHaNulla;
begin
  Assert.AreEqual('', PushedStates(True, nil));
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeSalvareLaPartitaIronmanPerUltima;
begin
  FWorld.Game.SetSavedGameSaver(TFakeSaver.Create(True));
  FReport.Promotions := True;
  // l'ultima messa e' la prima che si vede: il salvataggio, poi le promozioni
  Assert.AreEqual('TXcomSaveGameState,TXcomPromotionsState', PushedStates(False, nil));
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeFareIlSalvataggioAutomaticoSeLOpzioneEAccesa;
begin
  FWorld.Game.SetSavedGameSaver(TFakeSaver.Create(False));
  FWorld.Game.Options.SetValue('autosave', 0);
  Assert.AreEqual('', PushedStates(False, nil));
  FWorld.Game.Options.SetValue('autosave', 1);
  Assert.AreEqual('TXcomSaveGameState', PushedStates(False, nil));
end;

procedure TTestXcomDebriefingFollowUp.DovrebbeDireUnaVoltaSolaCheLAlienoEMortoSenzaContenimento;
var
  LState: TXcomDebriefingState;
begin
  FReport.Title := 'STR_ALIENS_DEFEATED';
  FReport.Rating := 'STR_RATING_OK';
  FReport.NoContainment := True;
  LState := TXcomDebriefingState.Create(FWorld.Game, FReport, nil);
  FWorld.Game.PushState(LState);
  // il primo giro del gioco chiama Init, che mette il messaggio sopra
  FWorld.Wait(20);
  Assert.IsTrue(FWorld.Game.TopState is TXcomErrorMessageState);
  FWorld.Game.PopState;
  // tornata in cima, la schermata non lo ripete
  FWorld.Wait(20);
  Assert.IsTrue(FWorld.Game.IsState(LState));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomDebriefingFollowUp);

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: the screens of a soldier (card, armor, diary), the grid of the  }
{  base and the scientists of a research of the basescape of OpenXcom, on the  }
{  game the program composes                                                   }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Barracks;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSave.Base, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>
  ///   The saved game with a diary of Tests\Data\XcomSave\variants (its first soldier has three missions) and the
  ///   one with two bases. The tests are ignored when the data of the game is not there
  /// </summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourBarracks = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    function Ready(const AVariant: string): Boolean;
    procedure OpenBases;
    procedure OpenFirstSoldier;
    /// <summary>The middle of the square of the grid of the base, in the pixels of the window</summary>
    procedure RightClickSquare(AX, AY: Integer);
    /// <summary>The square of the first facility of the base that the rule accepts</summary>
    function FindFacility(const AAccept: TFunc<string, Boolean>; out AX, AY: Integer): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScorrereISoldatiDallaScheda;
    [Test]
    procedure DovrebbeRinominareUnSoldato;
    [Test]
    procedure DovrebbeAprireLaVenditaSeIlMagazzinoEPienoAllUscitaDallaScheda;
    [Test]
    procedure DovrebbeCambiareLaCorazzaDiUnSoldato;
    [Test]
    procedure DovrebbeMostrareNeutralizzazioniEMissioniDelDiario;
    [Test]
    procedure DovrebbeScorrereISoldatiDalDiario;
    [Test]
    procedure DovrebbeScorrereLeMissioniDelDiario;
    [TestCase('hangar col velivolo', 'crafts,TXcomCraftInfoState')]
    [TestCase('magazzino', 'storage,TXcomSellState')]
    [TestCase('alloggi', 'personnel,TXcomSoldiersState')]
    [TestCase('laboratorio', 'laboratories,TXcomResearchState')]
    [TestCase('officina', 'workshops,TXcomManufactureState')]
    [TestCase('ascensore', 'lift,TXcomGeoscapeState')]
    procedure DovrebbeAprireLaSchermataDellaStrutturaColTastoDestro(const AKind, AExpected: string);
    [Test]
    procedure DovrebbeAprireLeInformazioniDellaBaseColTastoDestroSulVuoto;
    [Test]
    procedure DovrebbePassareAllAltraBaseDallaMiniMappa;
    [Test]
    procedure DovrebbeRinominareLaBase;
    [Test]
    procedure DovrebbeAssegnareGliScienziatiConFrecceTenutePremuteTastoDestroERotella;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleBaseFacility,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.BaseFacility;

const
  BASESCAPE = 'TXcomBasescapeState';
  SOLDIER_INFO = 'TXcomSoldierInfoState';

procedure TTestXcomTourBarracks.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourBarracks.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourBarracks.Ready(const AVariant: string): Boolean;
begin
  Result := FWorld.HasData and FWorld.LoadVariant(AVariant);
  if not Result then
    Assert.Pass('i dati di TFTD o il salvataggio non ci sono');
end;

procedure TTestXcomTourBarracks.OpenBases;
begin
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  Assert.AreEqual(BASESCAPE, FWorld.Top);
end;

procedure TTestXcomTourBarracks.OpenFirstSoldier;
begin
  OpenBases;
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_SOLDIERS_Y);
  FWorld.ClickRow(FWorld.FirstBase.Soldiers[0].Name, 100);
  Assert.AreEqual(SOLDIER_INFO, FWorld.Top);
end;

procedure TTestXcomTourBarracks.RightClickSquare(AX, AY: Integer);
begin
  // the grid starts 16 pixels under the top of the window and its squares are 64 pixels wide
  FWorld.RightClick(AX * 64 + 32, 16 + AY * 64 + 32);
end;

function TTestXcomTourBarracks.FindFacility(const AAccept: TFunc<string, Boolean>; out AX, AY: Integer): Boolean;
var
  LFacility: TXcomBaseFacility;
begin
  for LFacility in FWorld.FirstBase.Facilities do
    if AAccept(LFacility.Rules.FacilityType) then
    begin
      AX := LFacility.X;
      AY := LFacility.Y;
      Exit(True);
    end;
  AX := 0;
  AY := 0;
  Result := False;
end;

procedure TTestXcomTourBarracks.DovrebbeScorrereISoldatiDallaScheda;
var
  LFirst, LSecond, LLast: string;
begin
  if not Ready('save02_diary') then
    Exit;
  LFirst := FWorld.FirstBase.Soldiers[0].Name;
  LSecond := FWorld.FirstBase.Soldiers[1].Name;
  LLast := FWorld.FirstBase.Soldiers.Last.Name;
  OpenFirstSoldier;
  Assert.IsTrue(FWorld.Shows(LFirst), FWorld.Describe);
  FWorld.ClickButton('>>');
  Assert.AreEqual(SOLDIER_INFO, FWorld.Top);
  Assert.IsTrue(FWorld.Shows(LSecond), 'la freccia passa al soldato dopo');
  FWorld.ClickButton('<<');
  Assert.IsTrue(FWorld.Shows(LFirst), 'si torna al primo');
  // before the first one comes the last
  FWorld.ClickButton('<<');
  Assert.IsTrue(FWorld.Shows(LLast));
  FWorld.ClickButton('>>');
  Assert.IsTrue(FWorld.Shows(LFirst), 'dopo l''ultimo viene il primo');
  FWorld.ClickButton('OK');
  Assert.AreEqual('TXcomSoldiersState', FWorld.Top);
end;

procedure TTestXcomTourBarracks.DovrebbeRinominareUnSoldato;
var
  LSoldier: TXcomSoldier;
  LIndex: Integer;
begin
  if not Ready('save02_diary') then
    Exit;
  LSoldier := FWorld.FirstBase.Soldiers[0];
  OpenFirstSoldier;
  // the name at the top of the card
  FWorld.Click(290, 34);
  for LIndex := 1 to 30 do
    FWorld.Key(XCOM_KEY_BACKSPACE);
  FWorld.TypeText('rex');
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual('rex', LSoldier.Name.ToLower);
end;

procedure TTestXcomTourBarracks.DovrebbeAprireLaVenditaSeIlMagazzinoEPienoAllUscitaDallaScheda;
begin
  if not Ready('save02_diary') then
    Exit;
  FWorld.Game.Options.SetBool('storageLimitsEnforced', True);
  FWorld.FirstBase.StorageItems.AddItem('STR_DART_PISTOL', 100000);
  OpenFirstSoldier;
  FWorld.ClickButton('OK');
  Assert.AreEqual('TXcomErrorMessageState', FWorld.Top, 'il magazzino e'' oltre il limite');
  FWorld.ClickButton('OK');
  Assert.AreEqual('TXcomSellState', FWorld.Top, 'sotto il messaggio c''e'' la vendita');
end;

procedure TTestXcomTourBarracks.DovrebbeCambiareLaCorazzaDiUnSoldato;
var
  LSoldier: TXcomSoldier;
  LRuleset: TXcomRuleset;
  LIndex: Integer;
begin
  if not Ready('save02_diary') then
    Exit;
  // every research is done and the stores have one of each armor
  LRuleset := TXcomStrategy.Ruleset(FWorld.Game);
  for LIndex := 0 to LRuleset.Research.Count - 1 do
    FWorld.Save.Discovered.Add(LRuleset.Research.Rule(LIndex));
  FWorld.FirstBase.StorageItems.AddItem('STR_PLASTIC_AQUA_ARMOR', 1);
  LSoldier := FWorld.FirstBase.Soldiers[0];
  Assert.AreEqual('STR_NONE_UC', LSoldier.Armor.ArmorType);
  OpenFirstSoldier;
  FWorld.Click(370, 80);
  Assert.AreEqual('TXcomSoldierArmorState', FWorld.Top);
  FWorld.ClickRow('PLASTIC AQUA ARMOR', 200);
  Assert.AreEqual(SOLDIER_INFO, FWorld.Top, FWorld.Describe);
  Assert.AreEqual('STR_PLASTIC_AQUA_ARMOR_UC', LSoldier.Armor.ArmorType, 'il soldato indossa la corazza scelta');
  Assert.AreEqual(0, FWorld.FirstBase.StorageItems.GetItem('STR_PLASTIC_AQUA_ARMOR'), 'che esce dal magazzino');
  // back to no armor: the armor goes back to the stores
  FWorld.Click(370, 80);
  FWorld.ClickRow('NONE', 200);
  Assert.AreEqual('STR_NONE_UC', LSoldier.Armor.ArmorType);
  Assert.AreEqual(1, FWorld.FirstBase.StorageItems.GetItem('STR_PLASTIC_AQUA_ARMOR'));
end;

procedure TTestXcomTourBarracks.DovrebbeMostrareNeutralizzazioniEMissioniDelDiario;
var
  LY: Integer;
begin
  if not Ready('save02_diary') then
    Exit;
  OpenFirstSoldier;
  FWorld.ClickButton('DIARY');
  FWorld.ClickButton('COMBAT');
  Assert.AreEqual('TXcomSoldierDiaryPerformanceState', FWorld.Top);
  Assert.IsTrue(FWorld.FindRow('NEUTRALIZATIONS BY RACE', LY) >= 0, FWorld.Describe);
  Assert.AreEqual('STUNS> 1', FWorld.RowCell('KILLS> 4', 1), 'i totali del soldato');
  // the other page from inside the screen
  FWorld.ClickButton('PERFORMANCE');
  Assert.AreEqual('TXcomSoldierDiaryPerformanceState', FWorld.Top);
  Assert.IsTrue(FWorld.FindRow('MISSIONS BY TYPE', LY) >= 0, FWorld.Describe);
  Assert.AreEqual(-1, FWorld.FindRow('NEUTRALIZATIONS BY RACE', LY));
  FWorld.ClickButton('COMBAT');
  Assert.IsTrue(FWorld.FindRow('NEUTRALIZATIONS BY WEAPON', LY) >= 0);
  FWorld.ClickButton('OK');
  Assert.AreEqual('TXcomSoldierDiaryOverviewState', FWorld.Top);
end;

procedure TTestXcomTourBarracks.DovrebbeScorrereISoldatiDalDiario;
var
  LFirst, LSecond, LLast: string;
begin
  if not Ready('save02_diary') then
    Exit;
  LFirst := FWorld.FirstBase.Soldiers[0].Name;
  LSecond := FWorld.FirstBase.Soldiers[1].Name;
  LLast := FWorld.FirstBase.Soldiers.Last.Name;
  OpenFirstSoldier;
  FWorld.ClickButton('DIARY');
  Assert.IsTrue(FWorld.Shows(LFirst));
  FWorld.ClickButton('>>');
  Assert.IsTrue(FWorld.Shows(LSecond), 'la freccia passa al soldato dopo: ' + FWorld.Describe);
  FWorld.ClickButton('<<');
  FWorld.ClickButton('<<');
  Assert.IsTrue(FWorld.Shows(LLast), 'prima del primo viene l''ultimo');
  FWorld.ClickButton('>>');
  // the same arrows in the page of the performance
  FWorld.ClickButton('PERFORMANCE');
  Assert.IsTrue(FWorld.Shows(LFirst));
  FWorld.ClickButton('>>');
  Assert.IsTrue(FWorld.Shows(LSecond), FWorld.Describe);
  FWorld.ClickButton('<<');
  Assert.IsTrue(FWorld.Shows(LFirst));
  FWorld.ClickButton('<<');
  Assert.IsTrue(FWorld.Shows(LLast));
  FWorld.ClickButton('OK');
  // the card under the diary follows the soldier that was chosen
  Assert.AreEqual('TXcomSoldierDiaryOverviewState', FWorld.Top);
  Assert.IsTrue(FWorld.Shows(LLast), 'il diario resta sul soldato scelto');
end;

procedure TTestXcomTourBarracks.DovrebbeScorrereLeMissioniDelDiario;
begin
  if not Ready('save02_diary') then
    Exit;
  OpenFirstSoldier;
  FWorld.ClickButton('DIARY');
  FWorld.ClickRow('ALIEN SUB CRASH RECOVERY', 100);
  Assert.AreEqual('TXcomSoldierDiaryMissionState', FWorld.Top);
  Assert.IsTrue(FWorld.Shows('SCORE> 95'));
  FWorld.ClickButton('>>');
  Assert.IsFalse(FWorld.Shows('SCORE> 95'), 'la freccia passa a un''altra missione');
  FWorld.ClickButton('<<');
  Assert.IsTrue(FWorld.Shows('SCORE> 95'), 'e torna');
  FWorld.ClickButton('<<');
  Assert.IsFalse(FWorld.Shows('SCORE> 95'), 'prima della prima viene l''ultima');
  FWorld.ClickButton('OK');
  Assert.AreEqual('TXcomSoldierDiaryOverviewState', FWorld.Top);
end;

procedure TTestXcomTourBarracks.DovrebbeAprireLaSchermataDellaStrutturaColTastoDestro(const AKind, AExpected: string);
var
  LRuleset: TXcomRuleset;
  LX, LY: Integer;
  LFound: Boolean;
begin
  if not Ready('save02_twobases') then
    Exit;
  LRuleset := TXcomStrategy.Ruleset(FWorld.Game);
  LFound := FindFacility(
    function(AType: string): Boolean
    var
      LRule: TXcomRuleBaseFacility;
    begin
      LRule := LRuleset.Facilities.Find(AType);
      if AKind = 'crafts' then
        Result := LRule.Crafts > 0
      else if AKind = 'storage' then
        Result := LRule.Storage > 0
      else if AKind = 'personnel' then
        Result := LRule.Personnel > 0
      else if AKind = 'laboratories' then
        Result := LRule.Laboratories > 0
      else if AKind = 'workshops' then
        Result := LRule.Workshops > 0
      else
        Result := LRule.IsLift;
    end, LX, LY);
  Assert.IsTrue(LFound, 'la base ha la struttura');
  OpenBases;
  RightClickSquare(LX, LY);
  Assert.AreEqual(AExpected, FWorld.Top);
end;

procedure TTestXcomTourBarracks.DovrebbeAprireLeInformazioniDellaBaseColTastoDestroSulVuoto;
var
  LRuleset: TXcomRuleset;
  LFacility: TXcomBaseFacility;
  LX, LY, LSize: Integer;
  LTaken: array[0..5, 0..5] of Boolean;
begin
  if not Ready('save02_twobases') then
    Exit;
  // the squares of the grid that a facility takes (a hangar takes two by two)
  LRuleset := TXcomStrategy.Ruleset(FWorld.Game);
  FillChar(LTaken, SizeOf(LTaken), 0);
  for LFacility in FWorld.FirstBase.Facilities do
  begin
    LSize := LRuleset.Facilities.Find(LFacility.Rules.FacilityType).Size;
    for LX := LFacility.X to LFacility.X + LSize - 1 do
      for LY := LFacility.Y to LFacility.Y + LSize - 1 do
        LTaken[LX, LY] := True;
  end;
  OpenBases;
  for LX := 0 to 5 do
    for LY := 0 to 5 do
      if not LTaken[LX, LY] then
      begin
        RightClickSquare(LX, LY);
        Assert.AreEqual('TXcomBaseInfoState', FWorld.Top, 'un quadrato vuoto apre le informazioni');
        Exit;
      end;
  Assert.Fail('la base non ha quadrati vuoti');
end;

procedure TTestXcomTourBarracks.DovrebbePassareAllAltraBaseDallaMiniMappa;
var
  LY: Integer;
begin
  if not Ready('save02_twobases') then
    Exit;
  OpenBases;
  // the second of the small bases under the name: 32 pixels each
  FWorld.Click(384 + 32 + 16, 98);
  Assert.AreEqual(BASESCAPE, FWorld.Top);
  // the transfer from the base on the screen goes to the other one: the first base is now the destination
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_TRANSFER_Y);
  Assert.AreEqual('TXcomTransferBaseState', FWorld.Top);
  Assert.IsTrue(FWorld.FindRow(FWorld.Save.Bases[0].Name, LY) >= 0, 'la base sullo schermo e'' la seconda: ' +
    FWorld.Describe);
  Assert.AreEqual(-1, FWorld.FindRow(FWorld.Save.Bases[1].Name, LY));
end;

procedure TTestXcomTourBarracks.DovrebbeRinominareLaBase;
var
  LIndex: Integer;
begin
  if not Ready('save02_twobases') then
    Exit;
  OpenBases;
  // the name of the base over the buttons
  FWorld.Click(500, 16);
  for LIndex := 1 to 20 do
    FWorld.Key(XCOM_KEY_BACKSPACE);
  FWorld.TypeText('atlantis');
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual('atlantis', FWorld.FirstBase.Name.ToLower);
end;

procedure TTestXcomTourBarracks.DovrebbeAssegnareGliScienziatiConFrecceTenutePremuteTastoDestroERotella;
var
  LScientists: Integer;
begin
  if not Ready('save02_twobases') then
    Exit;
  FWorld.Game.Options.ChangeValueByMouseWheel := 2;
  LScientists := FWorld.FirstBase.Scientists;
  OpenBases;
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_RESEARCH_Y);
  FWorld.ClickButton('New Project');
  FWorld.Click(300, 140);
  Assert.AreEqual('TXcomResearchInfoState', FWorld.Top);
  // the arrow that adds, held down
  FWorld.Press(402, 213);
  FWorld.Wait(3000);
  FWorld.Release(402, 213);
  Assert.AreEqual(0, FWorld.FirstBase.Scientists, 'la freccia tenuta premuta assegna tutti gli scienziati');
  FWorld.Press(402, 257);
  FWorld.Wait(3000);
  FWorld.Release(402, 257);
  Assert.AreEqual(LScientists, FWorld.FirstBase.Scientists, 'e quella in giu'' li libera');
  FWorld.RightClick(402, 213);
  Assert.AreEqual(0, FWorld.FirstBase.Scientists, 'il tasto destro li assegna tutti');
  FWorld.RightClick(402, 257);
  Assert.AreEqual(LScientists, FWorld.FirstBase.Scientists);
  FWorld.Press(300, 230, XCOM_BUTTON_WHEELUP);
  FWorld.Release(300, 230, XCOM_BUTTON_WHEELUP);
  Assert.AreEqual(LScientists - 2, FWorld.FirstBase.Scientists, 'la rotella in su ne assegna due');
  FWorld.Press(300, 230, XCOM_BUTTON_WHEELDOWN);
  FWorld.Release(300, 230, XCOM_BUTTON_WHEELDOWN);
  Assert.AreEqual(LScientists, FWorld.FirstBase.Scientists);
  // Cancel leaves no project
  FWorld.ClickButton('Cancel');
  Assert.AreEqual(0, FWorld.FirstBase.Research.Count, FWorld.Describe);
end;

end.

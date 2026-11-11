{******************************************************************************}
{                                                                              }
{  DelphiDoom: what a base loses with a destroyed facility (Base::             }
{  destroyFacility of OpenXcom after a base defense), on the first base of a   }
{  new game with the rules of the game                                         }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Demolition;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleBaseFacility,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomDebriefing.BaseFacilityRemover, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>
  ///   TXcomBaseFacilityRemover on the first base of a new game of TFTD. The tests are ignored when the data of the
  ///   game is not there
  /// </summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourDemolition = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    FRuleset: TXcomRuleset;
    FRemover: TXcomBaseFacilityRemover;
    function Ready: Boolean;
    function Base: TXcomBase;
    /// <summary>The index of the first facility of the base whose rule is accepted; fails without it</summary>
    function FacilityWith(const AAccept: TFunc<TXcomRuleBaseFacility, Boolean>): Integer;
    /// <summary>Destroys every facility of the base whose rule is accepted</summary>
    procedure DestroyAll(const AAccept: TFunc<TXcomRuleBaseFacility, Boolean>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLiberareGliScienziatiSenzaLaboratorio;
    [Test]
    procedure DovrebbeFermareLeProduzioniSenzaOfficina;
    [Test]
    procedure DovrebbeTogliereISoldatiDallAddestramentoSenzaLaboratorioPsi;
    [Test]
    procedure DovrebbeAnnullareLaProduzioneDiUnVelivoloSenzaHangar;
    [Test]
    procedure DovrebbePerdereIlVelivoloInArrivoSenzaHangar;
    [Test]
    procedure DovrebbePerdereGliOggettiInArrivoSenzaMagazzino;
    [Test]
    procedure DovrebbePerdereIlPersonaleInArrivoSenzaAlloggi;
    [Test]
    procedure DovrebbeStaccareTutteLeStruttureSenzaLAscensore;
    [Test]
    procedure DovrebbeDistruggereSoloLeStruttureStaccate;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.RuleAdapters,
  DelphiDoom.XcomSave.ResearchProject, DelphiDoom.XcomSave.Production, DelphiDoom.XcomSave.Transfer,
  DelphiDoom.XcomSave.Craft;

procedure TTestXcomTourDemolition.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourDemolition.TearDown;
begin
  FRemover.Free;
  FWorld.Free;
end;

function TTestXcomTourDemolition.Ready: Boolean;
begin
  Result := FWorld.HasData;
  if not Result then
  begin
    Assert.Pass('i dati di TFTD non ci sono');
    Exit;
  end;
  FWorld.StartNewGame;
  FRuleset := TXcomStrategy.Ruleset(FWorld.Game);
  FRemover := TXcomBaseFacilityRemover.Create(FRuleset);
end;

function TTestXcomTourDemolition.Base: TXcomBase;
begin
  Result := FWorld.FirstBase;
end;

function TTestXcomTourDemolition.FacilityWith(const AAccept: TFunc<TXcomRuleBaseFacility, Boolean>): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to Base.Facilities.Count - 1 do
    if AAccept(FRuleset.Facilities.Find(Base.Facilities[LIndex].Rules.FacilityType)) then
      Exit(LIndex);
  Assert.Fail('la base non ha la struttura');
  Result := -1;
end;

procedure TTestXcomTourDemolition.DestroyAll(const AAccept: TFunc<TXcomRuleBaseFacility, Boolean>);
var
  LIndex: Integer;
begin
  for LIndex := Base.Facilities.Count - 1 downto 0 do
    if AAccept(FRuleset.Facilities.Find(Base.Facilities[LIndex].Rules.FacilityType)) then
      FRemover.DestroyFacility(Base, LIndex);
end;

procedure TTestXcomTourDemolition.DovrebbeLiberareGliScienziatiSenzaLaboratorio;
var
  LScientists, LFacilities: Integer;
  LFirst, LSecond: TXcomResearchProject;
begin
  if not Ready then
    Exit;
  LScientists := Base.Scientists;
  LFacilities := Base.Facilities.Count;
  // two projects take every scientist of the base
  LFirst := TXcomResearchProject.Create(FRuleset.Research.Rule(0), 100);
  LFirst.Assigned := 3;
  Base.AddResearch(LFirst);
  LSecond := TXcomResearchProject.Create(FRuleset.Research.Rule(1), 100);
  LSecond.Assigned := LScientists - 3;
  Base.AddResearch(LSecond);
  Base.Scientists := 0;
  FRemover.DestroyFacility(Base, FacilityWith(
    function(ARule: TXcomRuleBaseFacility): Boolean
    begin
      Result := ARule.Laboratories > 0;
    end));
  Assert.AreEqual(LFacilities - 1, Base.Facilities.Count, 'la struttura lascia la base');
  Assert.AreEqual(LScientists, Base.Scientists, 'senza laboratorio gli scienziati tornano liberi');
  Assert.AreEqual(0, LFirst.Assigned);
  Assert.AreEqual(0, LSecond.Assigned);
  Assert.AreEqual(2, Base.Research.Count, 'i progetti restano, senza scienziati');
end;

procedure TTestXcomTourDemolition.DovrebbeFermareLeProduzioniSenzaOfficina;
var
  LEngineers: Integer;
  LProduction: TXcomProduction;
begin
  if not Ready then
    Exit;
  LEngineers := Base.Engineers;
  LProduction := TXcomProduction.Create(FRuleset.Manufacture.Find('STR_GAUSS_PISTOL'), 5);
  LProduction.AssignedEngineers := LEngineers;
  Base.AddProduction(LProduction);
  Base.Engineers := 0;
  FRemover.DestroyFacility(Base, FacilityWith(
    function(ARule: TXcomRuleBaseFacility): Boolean
    begin
      Result := ARule.Workshops > 0;
    end));
  Assert.AreEqual(0, Base.Productions.Count, 'senza officina la produzione e'' annullata');
  Assert.AreEqual(LEngineers, Base.Engineers, 'e i tecnici tornano liberi');
end;

procedure TTestXcomTourDemolition.DovrebbeTogliereISoldatiDallAddestramentoSenzaLaboratorioPsi;
var
  LIndex, LLab: Integer;
  LFacility: TXcomBaseFacility;
begin
  if not Ready then
    Exit;
  LLab := -1;
  for LIndex := 0 to FRuleset.Facilities.Count - 1 do
    if FRuleset.Facilities.Rule(LIndex).PsiLaboratories > 0 then
      LLab := LIndex;
  Assert.IsTrue(LLab >= 0, 'le regole hanno un laboratorio psi');
  LFacility := TXcomBaseFacility.Create(TXcomFacilityRuleAdapter.Create(FRuleset.Facilities.Rule(LLab)));
  LFacility.X := 0;
  LFacility.Y := 0;
  Base.Facilities.Add(LFacility);
  Base.Soldiers[0].PsiTraining := True;
  Base.Soldiers[1].PsiTraining := True;
  // the laboratory has room for more: only the soldiers over what is left lose their place
  FRemover.DestroyFacility(Base, Base.Facilities.Count - 1);
  Assert.IsFalse(Base.Soldiers[0].PsiTraining, 'senza laboratorio i soldati lasciano l''addestramento');
  Assert.IsFalse(Base.Soldiers[1].PsiTraining);
end;

procedure TTestXcomTourDemolition.DovrebbeAnnullareLaProduzioneDiUnVelivoloSenzaHangar;
var
  LEngineers: Integer;
  LProduction: TXcomProduction;
begin
  if not Ready then
    Exit;
  // the three hangars are taken: a craft in production has no place when one goes
  LEngineers := Base.Engineers;
  LProduction := TXcomProduction.Create(FRuleset.Manufacture.Find('STR_MANTA'), 1);
  LProduction.AssignedEngineers := 4;
  Base.AddProduction(LProduction);
  Base.Engineers := LEngineers - 4;
  FRemover.DestroyFacility(Base, FacilityWith(
    function(ARule: TXcomRuleBaseFacility): Boolean
    begin
      Result := ARule.Crafts > 0;
    end));
  Assert.AreEqual(0, Base.Productions.Count, 'la produzione del velivolo e'' annullata');
  Assert.AreEqual(LEngineers, Base.Engineers);
end;

procedure TTestXcomTourDemolition.DovrebbePerdereIlVelivoloInArrivoSenzaHangar;
var
  LTransfer: TXcomTransfer;
  LCraft: TXcomCraft;
begin
  if not Ready then
    Exit;
  // the third craft of the base is on its way from another base
  LCraft := Base.Crafts.Extract(Base.Crafts[2]);
  LTransfer := TXcomTransfer.Create(24);
  LTransfer.Craft := LCraft;
  Base.Transfers.Add(LTransfer);
  FRemover.DestroyFacility(Base, FacilityWith(
    function(ARule: TXcomRuleBaseFacility): Boolean
    begin
      Result := ARule.Crafts > 0;
    end));
  Assert.AreEqual(0, Base.Transfers.Count, 'senza hangar il velivolo in arrivo e'' perso');
  Assert.AreEqual(2, Base.Crafts.Count, 'quelli della base restano');
end;

procedure TTestXcomTourDemolition.DovrebbePerdereGliOggettiInArrivoSenzaMagazzino;
var
  LTransfer: TXcomTransfer;
  LGuns: Integer;
begin
  if not Ready then
    Exit;
  LGuns := Base.StorageItems.GetItem('STR_DART_PISTOL');
  LTransfer := TXcomTransfer.Create(24);
  LTransfer.SetItems('STR_DART_PISTOL', 3);
  Base.Transfers.Add(LTransfer);
  LTransfer := TXcomTransfer.Create(24);
  LTransfer.Scientists := 2;
  Base.Transfers.Add(LTransfer);
  DestroyAll(
    function(ARule: TXcomRuleBaseFacility): Boolean
    begin
      Result := ARule.Storage > 0;
    end);
  Assert.AreEqual(1, Base.Transfers.Count, 'senza magazzino gli oggetti in arrivo sono persi');
  Assert.AreEqual(2, Base.Transfers[0].Scientists, 'il personale in arrivo no');
  Assert.AreEqual(LGuns, Base.StorageItems.GetItem('STR_DART_PISTOL'), 'gli oggetti della base restano');
end;

procedure TTestXcomTourDemolition.DovrebbePerdereIlPersonaleInArrivoSenzaAlloggi;
var
  LTransfer: TXcomTransfer;
  LSoldiers: Integer;
begin
  if not Ready then
    Exit;
  LSoldiers := Base.Soldiers.Count;
  LTransfer := TXcomTransfer.Create(24);
  LTransfer.Scientists := 2;
  Base.Transfers.Add(LTransfer);
  LTransfer := TXcomTransfer.Create(24);
  LTransfer.Engineers := 2;
  Base.Transfers.Add(LTransfer);
  LTransfer := TXcomTransfer.Create(24);
  LTransfer.SetItems('STR_DART_PISTOL', 1);
  Base.Transfers.Add(LTransfer);
  DestroyAll(
    function(ARule: TXcomRuleBaseFacility): Boolean
    begin
      Result := ARule.Personnel > 0;
    end);
  Assert.AreEqual(1, Base.Transfers.Count, 'senza alloggi scienziati e tecnici in arrivo sono persi');
  Assert.AreEqual(1, Base.Transfers[0].ItemQty, 'gli oggetti in arrivo no');
  Assert.AreEqual(LSoldiers, Base.Soldiers.Count, 'chi e'' nella base resta');
end;

procedure TTestXcomTourDemolition.DovrebbeStaccareTutteLeStruttureSenzaLAscensore;
var
  LLift: Integer;
  LDisconnected: TArray<Integer>;
begin
  if not Ready then
    Exit;
  Assert.AreEqual(0, Integer(Length(FRemover.DisconnectedFacilities(Base))), 'la base nuova e'' tutta collegata');
  LLift := FacilityWith(
    function(ARule: TXcomRuleBaseFacility): Boolean
    begin
      Result := ARule.IsLift;
    end);
  LDisconnected := FRemover.DisconnectedFacilities(Base, Base.Facilities[LLift]);
  Assert.AreEqual(Base.Facilities.Count - 1, Integer(Length(LDisconnected)),
    'tolto l''ascensore ogni altra struttura e'' staccata');
end;

procedure TTestXcomTourDemolition.DovrebbeDistruggereSoloLeStruttureStaccate;
var
  LFacility: TXcomBaseFacility;
  LCount, LIndex: Integer;
  LRuleIndex: Integer;
begin
  if not Ready then
    Exit;
  LCount := Base.Facilities.Count;
  // a facility in a corner that touches nothing: the corner of the grid that is free and has free neighbours
  LRuleIndex := -1;
  for LIndex := 0 to FRuleset.Facilities.Count - 1 do
    if (FRuleset.Facilities.Rule(LIndex).Size = 1) and (FRuleset.Facilities.Rule(LIndex).Storage > 0) then
      LRuleIndex := LIndex;
  Assert.IsTrue(LRuleIndex >= 0);
  LFacility := TXcomBaseFacility.Create(TXcomFacilityRuleAdapter.Create(FRuleset.Facilities.Rule(LRuleIndex)));
  LFacility.X := 0;
  LFacility.Y := 5;
  Base.Facilities.Add(LFacility);
  if Length(FRemover.DisconnectedFacilities(Base)) = 0 then
  begin
    // that corner was next to the base: the opposite one
    LFacility.X := 5;
    LFacility.Y := 0;
  end;
  Assert.AreEqual(1, Integer(Length(FRemover.DisconnectedFacilities(Base))), 'solo la struttura isolata e'' staccata');
  Assert.AreEqual(LCount, FRemover.DisconnectedFacilities(Base)[0]);
  FRemover.DestroyDisconnectedFacilities(Base);
  Assert.AreEqual(LCount, Base.Facilities.Count, 'la struttura staccata e'' distrutta, le altre restano');
end;

end.

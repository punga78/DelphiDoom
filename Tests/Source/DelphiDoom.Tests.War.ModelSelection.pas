{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the selection and its rules           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelSelection;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.Selection, DelphiDoom.Tests.War.CommandRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarSelection = class(TObject)
  private
    FSelection: TWarSelection;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAggiungereUnIdUnaSolaVolta;
    [Test]
    procedure DovrebbeFermarsiATrentadueSelezionati;
    [Test]
    procedure DovrebbeTogliereUnIdTenendoLOrdineDegliAltri;
    [Test]
    procedure DovrebbeDareFalsoSeSiToglieUnIdNonSelezionato;
    [Test]
    procedure DovrebbeDareZeroFuoriDallaSelezione;
    [Test]
    procedure DovrebbeSostituireLaSelezioneConAssign;
    [Test]
    procedure DovrebbeRicordareLaSelezioneInUnGruppo;
    [Test]
    procedure DovrebbeTenereIlGruppoQuandoLaSelezioneCambia;
    [Test]
    procedure DovrebbeRifiutareUnGruppoCheNonEsiste;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarSelectionCommands = class(TObject)
  private
    FRig: TCommandRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePoterSelezionareUnaUnitaViva;
    [Test]
    procedure DovrebbeRifiutareUnoSlotVuoto;
    [Test]
    procedure DovrebbeRifiutareUnaUnitaCheMuore;
    [Test]
    procedure DovrebbeRifiutareUnCadavere;
    [Test]
    procedure DovrebbeRifiutareUnEdificioCheCrolla;
    [Test]
    procedure DovrebbeRifiutareUnLavoratoreDentroLaMiniera;
    [Test]
    procedure DovrebbeRifiutareCioCheIlGiocatoreNonVede;
    [Test]
    procedure DovrebbeSelezionareOgniCandidatoUnaSolaVolta;
    [Test]
    procedure DovrebbeLasciareFuoriGliEdificiSeCiSonoUnitaMobili;
    [Test]
    procedure DovrebbeTenereSoloIlPrimoEdificio;
    [Test]
    procedure DovrebbeTenereAlMassimoTrentadueUnita;
    [Test]
    procedure DovrebbeVuotareLaSelezioneSeNessunCandidatoVaBene;
    [Test]
    procedure DovrebbeRichiamareUnGruppoSenzaIMorti;
    [Test]
    procedure DovrebbeLasciareLaSelezioneSeIlGruppoEVuoto;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.State.GatherFactory;

{ TTestWarSelection }

procedure TTestWarSelection.Setup;
begin
  FSelection := TWarSelection.Create;
end;

procedure TTestWarSelection.TearDown;
begin
  FSelection.Free;
end;

procedure TTestWarSelection.DovrebbeAggiungereUnIdUnaSolaVolta;
begin
  Assert.IsTrue(FSelection.Add(7));
  Assert.IsFalse(FSelection.Add(7));
  Assert.AreEqual(1, FSelection.Count);
  Assert.IsTrue(FSelection.Contains(7));
  Assert.AreEqual(0, FSelection.IndexOf(7));
  Assert.AreEqual(-1, FSelection.IndexOf(8));
end;

procedure TTestWarSelection.DovrebbeFermarsiATrentadueSelezionati;
var
  LId: Integer;
begin
  for LId := 1 to 40 do
    FSelection.Add(Word(LId));
  Assert.AreEqual(WAR_MODEL_MAX_SELECTED, FSelection.Count);
  Assert.IsFalse(FSelection.Contains(33));
  Assert.AreEqual(32, Integer(FSelection[31]));
end;

procedure TTestWarSelection.DovrebbeTogliereUnIdTenendoLOrdineDegliAltri;
begin
  FSelection.Assign([5, 6, 7]);
  Assert.IsTrue(FSelection.Remove(6));
  Assert.AreEqual(2, FSelection.Count);
  Assert.AreEqual(5, Integer(FSelection[0]));
  Assert.AreEqual(7, Integer(FSelection[1]));
end;

procedure TTestWarSelection.DovrebbeDareFalsoSeSiToglieUnIdNonSelezionato;
begin
  FSelection.Add(5);
  Assert.IsFalse(FSelection.Remove(9));
  Assert.AreEqual(1, FSelection.Count);
end;

procedure TTestWarSelection.DovrebbeDareZeroFuoriDallaSelezione;
begin
  FSelection.Add(5);
  Assert.AreEqual(0, Integer(FSelection[1]));
  Assert.AreEqual(0, Integer(FSelection[-1]));
end;

procedure TTestWarSelection.DovrebbeSostituireLaSelezioneConAssign;
begin
  FSelection.Assign([1, 2]);
  FSelection.Assign([9, 9, 8]);
  Assert.AreEqual(2, FSelection.Count);
  Assert.AreEqual(9, Integer(FSelection[0]));
  Assert.AreEqual(8, Integer(FSelection[1]));
  FSelection.Clear;
  Assert.AreEqual(0, FSelection.Count);
end;

procedure TTestWarSelection.DovrebbeRicordareLaSelezioneInUnGruppo;
begin
  FSelection.Assign([3, 4]);
  FSelection.StoreGroup(8);
  Assert.AreEqual(2, FSelection.GroupCount(8));
  Assert.AreEqual(3, Integer(FSelection.GroupItem(8, 0)));
  Assert.AreEqual(4, Integer(FSelection.GroupItem(8, 1)));
  Assert.AreEqual(0, Integer(FSelection.GroupItem(8, 2)));
  Assert.AreEqual(0, FSelection.GroupCount(0));
end;

procedure TTestWarSelection.DovrebbeTenereIlGruppoQuandoLaSelezioneCambia;
begin
  FSelection.Assign([3, 4]);
  FSelection.StoreGroup(0);
  FSelection.Assign([5]);
  Assert.AreEqual(2, FSelection.GroupCount(0));
  FSelection.StoreGroup(0);
  Assert.AreEqual(1, FSelection.GroupCount(0));
  Assert.AreEqual(5, Integer(FSelection.GroupItem(0, 0)));
end;

procedure TTestWarSelection.DovrebbeRifiutareUnGruppoCheNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FSelection.StoreGroup(9);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FSelection.GroupCount(-1);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FSelection.GroupItem(9, 0);
    end, EWarException);
end;

{ TTestWarSelectionCommands }

procedure TTestWarSelectionCommands.Setup;
begin
  FRig := TCommandRig.Create;
end;

procedure TTestWarSelectionCommands.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarSelectionCommands.DovrebbePoterSelezionareUnaUnitaViva;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  Assert.IsTrue(FRig.Commands.Selecting.IsSelectable(LFootman));
  Assert.AreEqual(1, FRig.Commands.Selecting.Select([LFootman]));
  Assert.AreEqual(Integer(FRig.IdOf(LFootman)), Integer(FRig.Context.Selection[0]));
end;

procedure TTestWarSelectionCommands.DovrebbeRifiutareUnoSlotVuoto;
begin
  Assert.IsFalse(FRig.Commands.Selecting.IsSelectable(0));
  Assert.IsFalse(FRig.Commands.Selecting.IsSelectable(500));
end;

procedure TTestWarSelectionCommands.DovrebbeRifiutareUnaUnitaCheMuore;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Select([LFootman]);
  FRig.World.Combat.TakeDamage(LFootman, 500, 0);
  // going to die, then dead: in both cases it can not be selected, and its death takes it out of the selection
  Assert.IsFalse(FRig.Commands.Selecting.IsSelectable(LFootman));
  FRig.Tick;
  Assert.IsFalse(FRig.Commands.Selecting.IsSelectable(LFootman));
  Assert.AreEqual(0, FRig.Context.Selection.Count);
end;

procedure TTestWarSelectionCommands.DovrebbeRifiutareUnCadavere;
begin
  Assert.IsFalse(FRig.Commands.Selecting.IsSelectable(FRig.AddCorpse(12, 12)));
end;

procedure TTestWarSelectionCommands.DovrebbeRifiutareUnEdificioCheCrolla;
var
  LFarm: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  Assert.IsTrue(FRig.Commands.Selecting.IsSelectable(LFarm));
  FRig.Select([LFarm]);
  FRig.World.Combat.TakeDamage(LFarm, 5000, 0);
  Assert.IsFalse(FRig.Commands.Selecting.IsSelectable(LFarm));
  FRig.Tick;
  Assert.IsFalse(FRig.Commands.Selecting.IsSelectable(LFarm));
  Assert.AreEqual(0, FRig.Context.Selection.Count, 'il crollo toglie l''edificio dalla selezione');
end;

procedure TTestWarSelectionCommands.DovrebbeRifiutareUnLavoratoreDentroLaMiniera;
var
  LPeasant: Integer;
  LMine: Integer;
  LState: PWarStateMining;
begin
  LMine := FRig.AddMine(14, 10, 500);
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 13, 10);
  FRig.Select([LPeasant]);
  LState := TWarGatherStateFactory.NewMining(FRig.Machine, LPeasant, FRig.IdOf(LMine));
  FRig.Machine.ResetState(LPeasant, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  FRig.Tick;
  Assert.IsTrue(FRig.Machine.IsInsideBuilding(LPeasant));
  Assert.IsFalse(FRig.Commands.Selecting.IsSelectable(LPeasant));
  Assert.AreEqual(0, FRig.Context.Selection.Count, 'chi entra nella miniera esce dalla selezione');
end;

procedure TTestWarSelectionCommands.DovrebbeRifiutareCioCheIlGiocatoreNonVede;
var
  LRig: TCommandRig;
  LFootman: Integer;
begin
  LRig := TCommandRig.Create(1, True);
  try
    LFootman := LRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
    Assert.IsFalse(LRig.Commands.Selecting.IsSelectable(LFootman), 'tutto e'' sconosciuto');
    LRig.Reveal(10, 10);
    Assert.IsTrue(LRig.Commands.Selecting.IsSelectable(LFootman));
  finally
    LRig.Free;
  end;
end;

procedure TTestWarSelectionCommands.DovrebbeSelezionareOgniCandidatoUnaSolaVolta;
var
  LFirst: Integer;
  LSecond: Integer;
begin
  LFirst := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LSecond := FRig.AddDude(WAR_UNIT_ARCHER, 12, 10);
  Assert.AreEqual(2, FRig.Commands.Selecting.Select([LSecond, LFirst, LSecond]));
  Assert.AreEqual(Integer(FRig.IdOf(LSecond)), Integer(FRig.Context.Selection[0]));
  Assert.AreEqual(Integer(FRig.IdOf(LFirst)), Integer(FRig.Context.Selection[1]));
end;

procedure TTestWarSelectionCommands.DovrebbeLasciareFuoriGliEdificiSeCiSonoUnitaMobili;
var
  LFarm: Integer;
  LFootman: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 14, 10);
  Assert.AreEqual(1, FRig.Commands.Selecting.Select([LFarm, LFootman]));
  Assert.AreEqual(Integer(FRig.IdOf(LFootman)), Integer(FRig.Context.Selection[0]));
end;

procedure TTestWarSelectionCommands.DovrebbeTenereSoloIlPrimoEdificio;
var
  LFarm: Integer;
  LOther: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LOther := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 14, 10);
  Assert.AreEqual(1, FRig.Commands.Selecting.Select([LOther, LFarm]));
  Assert.AreEqual(Integer(FRig.IdOf(LOther)), Integer(FRig.Context.Selection[0]));
end;

procedure TTestWarSelectionCommands.DovrebbeTenereAlMassimoTrentadueUnita;
var
  LSlots: TArray<Integer>;
  LIndex: Integer;
begin
  SetLength(LSlots, 36);
  for LIndex := 0 to High(LSlots) do
    LSlots[LIndex] := FRig.World.Entities.CreateDude(WAR_UNIT_FOOTMAN, 4 + LIndex, 20, 0, False);
  for LIndex := 0 to High(LSlots) do
    FRig.World.Entities.SetInitialIdle(LSlots[LIndex]);
  FRig.Tick;
  Assert.AreEqual(WAR_MODEL_MAX_SELECTED, FRig.Commands.Selecting.Select(LSlots));
end;

procedure TTestWarSelectionCommands.DovrebbeVuotareLaSelezioneSeNessunCandidatoVaBene;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Select([LFootman]);
  Assert.AreEqual(0, FRig.Commands.Selecting.Select([FRig.AddCorpse(12, 12)]));
  Assert.AreEqual(0, FRig.Context.Selection.Count);
end;

procedure TTestWarSelectionCommands.DovrebbeRichiamareUnGruppoSenzaIMorti;
var
  LFirst: Integer;
  LSecond: Integer;
begin
  LFirst := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LSecond := FRig.AddDude(WAR_UNIT_ARCHER, 12, 10);
  FRig.Select([LFirst, LSecond]);
  FRig.Commands.Selecting.StoreGroup(2);
  FRig.Select([]);
  FRig.World.Entities.RemoveEntity(LFirst);
  Assert.AreEqual(1, FRig.Commands.Selecting.RecallGroup(2));
  Assert.AreEqual(Integer(FRig.IdOf(LSecond)), Integer(FRig.Context.Selection[0]));
  Assert.AreEqual(2, FRig.Context.Selection.GroupCount(2), 'il gruppo ricorda anche chi non c''e'' piu''');
end;

procedure TTestWarSelectionCommands.DovrebbeLasciareLaSelezioneSeIlGruppoEVuoto;
var
  LFootman: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  FRig.Select([LFootman]);
  Assert.AreEqual(1, FRig.Commands.Selecting.RecallGroup(4));
  Assert.AreEqual(1, FRig.Context.Selection.Count);
end;

end.

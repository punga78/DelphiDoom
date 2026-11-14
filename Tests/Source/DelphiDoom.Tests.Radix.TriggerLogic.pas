{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixTriggerLogic                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.TriggerLogic;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.LevelLogic.Types, DelphiDoom.Radix.TriggerGrid,
  DelphiDoom.Radix.TriggerLogic;

type
  /// <summary>
  ///   A level with four actions (0 runs from the start, 1 and 2 wait for a trigger, 3 is not
  ///   enabled) and three triggers: 0 wakes up the action 1 and toggles the 2, 1 (suspended)
  ///   suspends the action 0, 2 wakes up the action 3. The grid has the trigger 0 in the cell 5,
  ///   the 2 in the cell 6 and the 1 in the cell 7
  /// </summary>
  [TestFixture]
  [Category('radix')]
  TTestRadixTriggerLogic = class(TObject)
  strict private
    FLogic: TRadixTriggerLogic;
    FGrid: TRadixTriggerGrid;
    class function Cells(const ACells: array of Integer): TRadixGridPositions; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEseguireSoloLeAzioniAbilitateENonSospese;
    [Test]
    procedure DovrebbeDareLaProssimaAzioneDaEseguire;
    [Test]
    procedure DovrebbeSvegliareLeAzioniDiUnTrigger;
    [Test]
    procedure DovrebbeAlternareUnAzioneAOgniEsecuzioneDelTrigger;
    [Test]
    procedure DovrebbeAbilitareUnAzioneDisabilitataQuandoIlTriggerLaSveglia;
    [Test]
    procedure DovrebbeNonEseguireUnTriggerSospeso;
    [Test]
    procedure DovrebbeEseguireUnTriggerDopoAverloAttivato;
    [Test]
    procedure DovrebbeSospendereUnTrigger;
    [Test]
    procedure DovrebbeSospendereUnAzioneFinita;
    [Test]
    procedure DovrebbeIgnorareTriggerEAzioniCheIlLivelloNonHa;
    [Test]
    procedure DovrebbeFarScattareIlTriggerDellaCella;
    [Test]
    procedure DovrebbeNonFarScattareDueVolteLoStessoTriggerFinoAQuandoLaNavettaNonEsce;
    [Test]
    procedure DovrebbeFarScattarePiuTriggerNelloStessoTic;
    [Test]
    procedure DovrebbeEseguireUnTriggerUnaSolaVoltaPerTic;
    [Test]
    procedure DovrebbeSaltareLeCelleFuoriDallaGriglia;
    [Test]
    procedure DovrebbeNonFarScattareIlTriggerZeroAllaNascita;
    [Test]
    procedure DovrebbeTenereUnUltimoTriggerPerGiocatore;
    [Test]
    procedure DovrebbeDireSeIlLivelloHaUnTipoDiAzione;
    [Test]
    procedure DovrebbeElencareIMuriCheSparanoUnaVoltaSola;
    [Test]
    procedure DovrebbeDireSeUnTriggerHaUnAzioneDiUnTipo;
    [Test]
    procedure DovrebbeLasciareAllAzioneISuoiParametri;
  end;

implementation

const
  CELL_TRIGGER_0 = 5;
  CELL_TRIGGER_2 = 6;
  CELL_TRIGGER_1 = 7;
  CELL_EMPTY = 8;
  PLAYERS = 2;
  WAITING = -1;

{ TTestRadixTriggerLogic }

class function TTestRadixTriggerLogic.Cells(const ACells: array of Integer): TRadixGridPositions;
var
  LIndex: Integer;
begin
  Result := TRadixGridPositions.Empty;
  for LIndex := 0 to High(ACells) do
  begin
    Result.Cells[LIndex] := ACells[LIndex];
    Result.Count := LIndex + 1;
  end;
end;

procedure TTestRadixTriggerLogic.Setup;
var
  LActions: TArray<TRadixLevelAction>;
  LTriggers: TArray<TRadixLevelTrigger>;
  LData: TRadixTriggerGridData;
  LIndex: Integer;
begin
  SetLength(LActions, 4);
  LActions[0].Enabled := 1;
  LActions[0].ActionType := RADIX_ACTION_COMPLETE_MISSILE_WALL;
  LActions[0].Params[0] := 40;
  LActions[1].Enabled := 1;
  LActions[1].Suspend := WAITING;
  LActions[1].ActionType := RADIX_ACTION_FLOOR_MISSILE_WALL;
  LActions[1].Params[0] := 41;
  LActions[2].Enabled := 1;
  LActions[2].Suspend := WAITING;
  LActions[2].ActionType := RADIX_ACTION_SEEK_COMPLETE_MISSILE_WALL;
  LActions[2].Params[0] := 40;
  LActions[3].Enabled := 0;
  LActions[3].Suspend := WAITING;
  LActions[3].ActionType := RADIX_ACTION_PLANE_TRANSPO;
  LActions[3].Params[5] := 1234;

  SetLength(LTriggers, 3);
  LTriggers[0].NumActions := 2;
  LTriggers[0].Actions[0].ActionId := 1;
  LTriggers[0].Actions[0].ActivationFlags := RADIX_TRIGGER_ACTIVATE;
  LTriggers[0].Actions[1].ActionId := 2;
  LTriggers[0].Actions[1].ActivationFlags := RADIX_TRIGGER_TOGGLE;
  LTriggers[1].Suspended := 1;
  LTriggers[1].NumActions := 1;
  LTriggers[1].Actions[0].ActionId := 0;
  LTriggers[1].Actions[0].ActivationFlags := RADIX_TRIGGER_DEACTIVATE;
  LTriggers[2].NumActions := 2;
  LTriggers[2].Actions[0].ActionId := 3;
  LTriggers[2].Actions[0].ActivationFlags := RADIX_TRIGGER_ACTIVATE;
  // an action that the level does not have, and one that does nothing
  LTriggers[2].Actions[1].ActionId := 99;
  LTriggers[2].Actions[1].ActivationFlags := RADIX_TRIGGER_ACTIVATE_ON_SPACE;

  FLogic := TRadixTriggerLogic.Create(LActions, LTriggers, PLAYERS);

  LData.Width := 320;
  LData.Height := 128;
  SetLength(LData.Cells, RADIX_GRID_SIZE);
  for LIndex := 0 to RADIX_GRID_SIZE - 1 do
    LData.Cells[LIndex] := RADIX_NO_TRIGGER;
  LData.Cells[CELL_TRIGGER_0] := 0;
  LData.Cells[CELL_TRIGGER_2] := 2;
  LData.Cells[CELL_TRIGGER_1] := 1;
  FGrid := TRadixTriggerGrid.Create(LData, nil);
end;

procedure TTestRadixTriggerLogic.TearDown;
begin
  FGrid.Free;
  FLogic.Free;
end;

procedure TTestRadixTriggerLogic.DovrebbeEseguireSoloLeAzioniAbilitateENonSospese;
begin
  Assert.AreEqual(4, FLogic.ActionCount);
  Assert.AreEqual(3, FLogic.TriggerCount);
  Assert.IsTrue(FLogic.IsActionRunnable(0));
  Assert.IsFalse(FLogic.IsActionRunnable(1));
  Assert.IsFalse(FLogic.IsActionRunnable(2));
  Assert.IsFalse(FLogic.IsActionRunnable(3));
  Assert.IsFalse(FLogic.IsActionRunnable(-1));
  Assert.IsFalse(FLogic.IsActionRunnable(4));
end;

procedure TTestRadixTriggerLogic.DovrebbeDareLaProssimaAzioneDaEseguire;
begin
  Assert.AreEqual(0, FLogic.NextRunnable(0));
  Assert.AreEqual(4, FLogic.NextRunnable(1));
  FLogic.RunTrigger(0);
  Assert.AreEqual(1, FLogic.NextRunnable(1));
  Assert.AreEqual(2, FLogic.NextRunnable(2));
  Assert.AreEqual(4, FLogic.NextRunnable(3));
  Assert.AreEqual(0, FLogic.NextRunnable(-5));
  Assert.AreEqual(4, FLogic.NextRunnable(50));
end;

procedure TTestRadixTriggerLogic.DovrebbeSvegliareLeAzioniDiUnTrigger;
begin
  Assert.IsTrue(FLogic.RunTrigger(0));
  Assert.IsTrue(FLogic.IsActionRunnable(1));
  Assert.IsTrue(FLogic.IsActionRunnable(2));
end;

procedure TTestRadixTriggerLogic.DovrebbeAlternareUnAzioneAOgniEsecuzioneDelTrigger;
begin
  FLogic.RunTrigger(0);
  FLogic.RunTrigger(0);
  // the first is woken up again, the second is toggled back
  Assert.IsTrue(FLogic.IsActionRunnable(1));
  Assert.IsFalse(FLogic.IsActionRunnable(2));
  FLogic.RunTrigger(0);
  Assert.IsTrue(FLogic.IsActionRunnable(2));
end;

procedure TTestRadixTriggerLogic.DovrebbeAbilitareUnAzioneDisabilitataQuandoIlTriggerLaSveglia;
begin
  Assert.AreEqual(0, Integer(FLogic.Action(3).Enabled));
  FLogic.RunTrigger(2);
  Assert.AreEqual(1, Integer(FLogic.Action(3).Enabled));
  Assert.IsTrue(FLogic.IsActionRunnable(3));
end;

procedure TTestRadixTriggerLogic.DovrebbeNonEseguireUnTriggerSospeso;
begin
  Assert.IsTrue(FLogic.IsTriggerSuspended(1));
  Assert.IsFalse(FLogic.RunTrigger(1));
  Assert.IsTrue(FLogic.IsActionRunnable(0));
end;

procedure TTestRadixTriggerLogic.DovrebbeEseguireUnTriggerDopoAverloAttivato;
begin
  FLogic.ActivateTrigger(1);
  // activated, not run
  Assert.IsFalse(FLogic.IsTriggerSuspended(1));
  Assert.IsTrue(FLogic.IsActionRunnable(0));
  Assert.IsTrue(FLogic.RunTrigger(1));
  Assert.IsFalse(FLogic.IsActionRunnable(0));
end;

procedure TTestRadixTriggerLogic.DovrebbeSospendereUnTrigger;
begin
  FLogic.DeactivateTrigger(0);
  Assert.IsTrue(FLogic.IsTriggerSuspended(0));
  Assert.IsFalse(FLogic.RunTrigger(0));
  Assert.IsFalse(FLogic.IsActionRunnable(1));
  FLogic.ActivateAndRunTrigger(0);
  Assert.IsTrue(FLogic.IsActionRunnable(1));
end;

procedure TTestRadixTriggerLogic.DovrebbeSospendereUnAzioneFinita;
begin
  FLogic.SuspendAction(0);
  Assert.IsFalse(FLogic.IsActionRunnable(0));
  Assert.AreEqual(1, FLogic.Action(0).Suspend);
  Assert.AreEqual(4, FLogic.NextRunnable(0));
end;

procedure TTestRadixTriggerLogic.DovrebbeIgnorareTriggerEAzioniCheIlLivelloNonHa;
begin
  Assert.IsFalse(FLogic.RunTrigger(-1));
  Assert.IsFalse(FLogic.RunTrigger(3));
  Assert.IsTrue(FLogic.IsTriggerSuspended(3));
  Assert.IsTrue(FLogic.Action(4) = nil);
  Assert.IsTrue(FLogic.Action(-1) = nil);
  Assert.IsTrue(FLogic.Trigger(3) = nil);
  Assert.IsTrue(FLogic.Trigger(2) <> nil);
  FLogic.ActivateTrigger(7);
  FLogic.DeactivateTrigger(-3);
  FLogic.ActivateAndRunTrigger(12);
  FLogic.SuspendAction(44);
  // the trigger 2 names the action 99: the others are applied
  Assert.IsTrue(FLogic.RunTrigger(2));
  Assert.IsTrue(FLogic.IsActionRunnable(3));
end;

procedure TTestRadixTriggerLogic.DovrebbeFarScattareIlTriggerDellaCella;
begin
  Assert.AreEqual(1, FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_2])));
  Assert.IsTrue(FLogic.IsActionRunnable(3));
  Assert.AreEqual(2, FLogic.LastTrigger(0));
end;

procedure TTestRadixTriggerLogic.DovrebbeNonFarScattareDueVolteLoStessoTriggerFinoAQuandoLaNavettaNonEsce;
begin
  // the trigger 2 of the cell before it, so that the trigger 0 is not the one of the birth
  FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_2]));
  Assert.AreEqual(1, FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_0])));
  Assert.IsTrue(FLogic.IsActionRunnable(2));
  // still there: the toggle is not applied again
  Assert.AreEqual(0, FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_0])));
  Assert.IsTrue(FLogic.IsActionRunnable(2));
  // out and in again
  Assert.AreEqual(0, FLogic.PlayerCrosses(0, FGrid, Cells([CELL_EMPTY])));
  Assert.AreEqual(RADIX_NO_TRIGGER, FLogic.LastTrigger(0));
  Assert.AreEqual(1, FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_0])));
  Assert.IsFalse(FLogic.IsActionRunnable(2));
end;

procedure TTestRadixTriggerLogic.DovrebbeFarScattarePiuTriggerNelloStessoTic;
begin
  Assert.AreEqual(2, FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_2, CELL_TRIGGER_0])));
  Assert.IsTrue(FLogic.IsActionRunnable(3));
  Assert.IsTrue(FLogic.IsActionRunnable(1));
  Assert.AreEqual(0, FLogic.LastTrigger(0));
end;

procedure TTestRadixTriggerLogic.DovrebbeEseguireUnTriggerUnaSolaVoltaPerTic;
begin
  // in, out and in again in the three places of one tic: the toggle is applied once
  Assert.AreEqual(1, FLogic.PlayerCrosses(1, FGrid, Cells([CELL_TRIGGER_2])));
  Assert.AreEqual(1, FLogic.PlayerCrosses(1, FGrid, Cells([CELL_TRIGGER_0, CELL_EMPTY, CELL_TRIGGER_0])));
  Assert.IsTrue(FLogic.IsActionRunnable(2));
end;

procedure TTestRadixTriggerLogic.DovrebbeSaltareLeCelleFuoriDallaGriglia;
begin
  FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_2]));
  Assert.AreEqual(0, FLogic.PlayerCrosses(0, FGrid, Cells([-4, RADIX_GRID_SIZE])));
  // not even "no trigger": the last one stays
  Assert.AreEqual(2, FLogic.LastTrigger(0));
  Assert.AreEqual(0, FLogic.PlayerCrosses(5, FGrid, Cells([CELL_TRIGGER_0])));
  Assert.AreEqual(0, FLogic.PlayerCrosses(-1, FGrid, Cells([CELL_TRIGGER_0])));
end;

procedure TTestRadixTriggerLogic.DovrebbeNonFarScattareIlTriggerZeroAllaNascita;
begin
  // kept from the old code: a craft is born with the trigger 0 as its last one
  Assert.AreEqual(TRadixTriggerLogic.SPAWN_LAST_TRIGGER, FLogic.LastTrigger(0));
  Assert.AreEqual(0, FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_0])));
  Assert.IsFalse(FLogic.IsActionRunnable(1));
  FLogic.PlayerCrosses(0, FGrid, Cells([CELL_EMPTY]));
  Assert.AreEqual(1, FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_0])));
  FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_2]));
  FLogic.ResetPlayer(0);
  Assert.AreEqual(TRadixTriggerLogic.SPAWN_LAST_TRIGGER, FLogic.LastTrigger(0));
end;

procedure TTestRadixTriggerLogic.DovrebbeTenereUnUltimoTriggerPerGiocatore;
begin
  FLogic.PlayerCrosses(0, FGrid, Cells([CELL_TRIGGER_2]));
  Assert.AreEqual(2, FLogic.LastTrigger(0));
  Assert.AreEqual(TRadixTriggerLogic.SPAWN_LAST_TRIGGER, FLogic.LastTrigger(1));
  Assert.AreEqual(RADIX_NO_TRIGGER, FLogic.LastTrigger(2));
  // the second craft sets off the same trigger again
  Assert.AreEqual(1, FLogic.PlayerCrosses(1, FGrid, Cells([CELL_TRIGGER_2])));
end;

procedure TTestRadixTriggerLogic.DovrebbeDireSeIlLivelloHaUnTipoDiAzione;
begin
  Assert.IsTrue(FLogic.HasActionOfKind(RADIX_ACTION_PLANE_TRANSPO));
  Assert.IsFalse(FLogic.HasActionOfKind(RADIX_ACTION_SECONDARY_OBJECTIVE));
end;

procedure TTestRadixTriggerLogic.DovrebbeElencareIMuriCheSparanoUnaVoltaSola;
var
  LWalls: TArray<Integer>;
begin
  LWalls := FLogic.MissileWalls;
  Assert.AreEqual(2, Integer(Length(LWalls)));
  Assert.AreEqual(40, LWalls[0]);
  Assert.AreEqual(41, LWalls[1]);
  FLogic.Action(1).Params[0] := -1;
  Assert.AreEqual(1, Integer(Length(FLogic.MissileWalls)));
end;

procedure TTestRadixTriggerLogic.DovrebbeDireSeUnTriggerHaUnAzioneDiUnTipo;
begin
  Assert.IsTrue(FLogic.TriggerHasActionOfKind(2, RADIX_ACTION_PLANE_TRANSPO));
  Assert.IsFalse(FLogic.TriggerHasActionOfKind(0, RADIX_ACTION_PLANE_TRANSPO));
  Assert.IsFalse(FLogic.TriggerHasActionOfKind(9, RADIX_ACTION_PLANE_TRANSPO));
end;

procedure TTestRadixTriggerLogic.DovrebbeLasciareAllAzioneISuoiParametri;
begin
  // the code of an action keeps its state in the parameters of the record
  Assert.AreEqual(1234, Integer(FLogic.Action(3).Params[5]));
  FLogic.Action(3).Params[20] := 77;
  FLogic.RunTrigger(2);
  Assert.AreEqual(77, Integer(FLogic.Action(3).Params[20]));
  Assert.AreEqual(1234, Integer(FLogic.Action(3).Params[5]));
end;

end.

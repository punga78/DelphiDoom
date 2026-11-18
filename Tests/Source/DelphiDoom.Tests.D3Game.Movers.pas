{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - the physics of a mover, the  }
{  binary mover, the door and idMover, on a game with fakes                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.Movers;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.D3Game.WorldRig;

type
  [TestFixture]
  [Category('D3Game')]
  TTestD3GameMovers = class
  strict private
    FRig: TD3WorldRig;
    function OriginZ(const AName: AnsiString): Single;
    procedure AreNear(const AExpected, AActual: Single); overload;
    procedure AreNear(const AExpected, AActual: Single; const AMessage: string); overload;
    procedure AreNear(const AExpected, AActual, ATolerance: Single); overload;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlTempoDiUnaMossaDovrebbeEssereArrotondatoAiFotogrammiDiFisica;
    [Test]
    procedure UnaPortaDovrebbeAvereLeDueDirezioniELaDurataDaVelocita;
    [Test]
    procedure UnaPortaAttivataDovrebbeAprirsiAttendereERichiudersi;
    [Test]
    procedure UnaPortaConTimeDovrebbeUsareIlTempoDato;
    [Test]
    procedure UnaPortaStartOpenDovrebbeScambiareLePosizioni;
    [Test]
    procedure UnaPortaCheSiRichiudeAMetaDovrebbeInvertireLaMossa;
    [Test]
    procedure UnaPortaBloccataDovrebbeChiudersiEDireIlBlocco;
    [Test]
    procedure UnaPortaSenzaAttesaNegativaNonDovrebbeRichiudersi;
    [Test]
    procedure UnaSquadraDiPorteDovrebbeMuoversiInsiemeAlMaster;
    [Test]
    procedure UnaPortaDovrebbeSparareITriggerOpenedEClosed;
    [Test]
    procedure EventEnableDiUnMoverBinaryDovrebbeSpegnereComeLOriginale;
    [Test]
    procedure UnMoverDovrebbeAndareAUnaPosizioneEDirloAlThread;
    [Test]
    procedure UnMoverConAccelerazioneEDecelerazioneDovrebbeFareTreFasi;
    [Test]
    procedure UnMoverDovrebbeFermarsiConStopMoving;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.DoomScript.Types, DelphiDoom.D3Game.Types,
  DelphiDoom.D3Game.Entity, DelphiDoom.D3Game.MoverBinary, DelphiDoom.D3Game.Door, DelphiDoom.D3Game.Mover,
  DelphiDoom.D3Game.PhysicsTime;

const
  SDoorKeys: array[0..11] of AnsiString = ('classname', 'func_door', 'name', 'door1', 'size', '8 64 128',
    'angle', '-1', 'wait', '1', 'origin', '0 0 0');

function VectorArg(const AX, AY, AZ: Single): TDoomScriptEventArgs;
begin
  Result := Default(TDoomScriptEventArgs);
  Result[0].Kind := DS_EVENT_VECTOR;
  Result[0].VectorValue := TIdVec3.Create(AX, AY, AZ);
end;

procedure TTestD3GameMovers.Setup;
begin
  FRig := TD3WorldRig.Create;
  FRig.World.AddDef('info_recorder', ['spawnclass', 'idRecorder']);
  FRig.World.AddDef('func_door', ['spawnclass', 'idDoor']);
  FRig.World.AddDef('func_mover', ['spawnclass', 'idMover']);
  FRig.World.AddDef('trigger_relay', ['spawnclass', 'idTrigger_Multi', 'wait', '0', 'noTouch', '1']);
end;

procedure TTestD3GameMovers.TearDown;
begin
  FRig.Free;
end;

procedure TTestD3GameMovers.AreNear(const AExpected, AActual: Single);
begin
  Assert.AreEqual(Double(AExpected), Double(AActual), 0.0001);
end;

procedure TTestD3GameMovers.AreNear(const AExpected, AActual: Single; const AMessage: string);
begin
  Assert.AreEqual(Double(AExpected), Double(AActual), 0.0001, AMessage);
end;

procedure TTestD3GameMovers.AreNear(const AExpected, AActual, ATolerance: Single);
begin
  Assert.AreEqual(Double(AExpected), Double(AActual), Double(ATolerance));
end;

function TTestD3GameMovers.OriginZ(const AName: AnsiString): Single;
begin
  Result := FRig.Game.FindEntity(AName).GetPhysics.GetOrigin.Z;
end;

procedure TTestD3GameMovers.IlTempoDiUnaMossaDovrebbeEssereArrotondatoAiFotogrammiDiFisica;
begin
  Assert.AreEqual(0, TD3PhysicsTime.SnapToFrame(0));
  Assert.AreEqual(16, TD3PhysicsTime.SnapToFrame(1));
  Assert.AreEqual(16, TD3PhysicsTime.SnapToFrame(16));
  Assert.AreEqual(32, TD3PhysicsTime.SnapToFrame(17));
  Assert.AreEqual(304, TD3PhysicsTime.SnapToFrame(300));
  Assert.AreEqual(1008, TD3PhysicsTime.SnapToFrame(1000));
end;

procedure TTestD3GameMovers.UnaPortaDovrebbeAvereLeDueDirezioniELaDurataDaVelocita;
var
  LDoor: TD3Door;
begin
  LDoor := TD3Door(FRig.Spawn(SDoorKeys));
  // up (angle -1): the size in z (128) minus the lip (8)
  AreNear(0, LDoor.Pos1.Z);
  AreNear(120, LDoor.Pos2.Z);
  // no "time": the speed (400) gives 300 ms, snapped to 304
  Assert.AreEqual(304, LDoor.Duration);
  Assert.AreEqual(Ord(msPos1), Ord(LDoor.MoverState));
  Assert.AreSame(LDoor, LDoor.MoveMaster);
end;

procedure TTestD3GameMovers.UnaPortaAttivataDovrebbeAprirsiAttendereERichiudersi;
var
  LDoor: TD3Door;
begin
  LDoor := TD3Door(FRig.Spawn(SDoorKeys));
  FRig.Frame;
  LDoor.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  // starts one physics frame after the time
  Assert.AreEqual(Ord(ms1To2), Ord(LDoor.MoverState));
  Assert.AreEqual(32, LDoor.StateStartTime);
  FRig.RunUntil(200);
  Assert.IsTrue(OriginZ('door1') > 0, 'si muove');
  Assert.IsTrue(OriginZ('door1') < 120, 'non e arrivata');
  FRig.RunUntil(352);
  Assert.AreEqual(Ord(msPos2), Ord(LDoor.MoverState), 'aperta');
  AreNear(120, OriginZ('door1'), 0.01);
  Assert.IsFalse(LDoor.IsActive, 'la fisica e a riposo');
  // wait of 1 second, then it goes back
  FRig.RunUntil(1400);
  Assert.AreEqual(Ord(ms2To1), Ord(LDoor.MoverState), 'in chiusura');
  FRig.RunUntil(1800);
  Assert.AreEqual(Ord(msPos1), Ord(LDoor.MoverState), 'chiusa');
  AreNear(0, OriginZ('door1'), 0.01);
end;

procedure TTestD3GameMovers.UnaPortaConTimeDovrebbeUsareIlTempoDato;
var
  LDoor: TD3Door;
begin
  LDoor := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'door1', 'size', '8 64 128', 'angle', '-1',
    'time', '2']));
  Assert.AreEqual(2000, LDoor.Duration, 'duemila ms sono gia un multiplo di fotogramma');
end;

procedure TTestD3GameMovers.UnaPortaStartOpenDovrebbeScambiareLePosizioni;
var
  LDoor: TD3Door;
begin
  LDoor := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'door1', 'size', '8 64 128', 'angle', '-1',
    'start_open', '1']));
  Assert.AreEqual('<spawnDoorTrigger>@0 <startOpen>@1', FRig.Queue.Pending);
  FRig.Frame;
  AreNear(120, LDoor.Pos1.Z, 'pos1 e quella alta');
  AreNear(0, LDoor.Pos2.Z);
  AreNear(120, OriginZ('door1'), 'e partita aperta');
end;

procedure TTestD3GameMovers.UnaPortaCheSiRichiudeAMetaDovrebbeInvertireLaMossa;
var
  LDoor: TD3Door;
  LOpenedAt: Single;
begin
  LDoor := TD3Door(FRig.Spawn(SDoorKeys));
  LDoor.ProcessEvent(FRig.EntityEvents.DoorOpen);
  FRig.RunUntil(160);
  LOpenedAt := OriginZ('door1');
  Assert.IsTrue((LOpenedAt > 0) and (LOpenedAt < 120));
  LDoor.ProcessEvent(FRig.EntityEvents.DoorClose);
  Assert.AreEqual(Ord(ms2To1), Ord(LDoor.MoverState), 'inversione');
  FRig.RunUntil(1000);
  Assert.AreEqual(Ord(msPos1), Ord(LDoor.MoverState), 'chiusa');
end;

procedure TTestD3GameMovers.UnaPortaBloccataDovrebbeChiudersiEDireIlBlocco;
var
  LDoor: TD3Door;
begin
  LDoor := TD3Door(FRig.Spawn(SDoorKeys));
  LDoor.ProcessEvent(FRig.EntityEvents.DoorOpen);
  FRig.RunUntil(400);
  Assert.AreEqual(Ord(msPos2), Ord(LDoor.MoverState));
  LDoor.Lock(1);
  Assert.AreEqual(1, LDoor.IsLocked, 'bloccata');
  FRig.RunUntil(900);
  Assert.AreEqual(Ord(msPos1), Ord(LDoor.MoverState), 'chiusa dal blocco');
  LDoor.SetBlocked(True);
  Assert.IsTrue(LDoor.IsBlocked);
end;

procedure TTestD3GameMovers.UnaPortaSenzaAttesaNegativaNonDovrebbeRichiudersi;
var
  LDoor: TD3Door;
begin
  LDoor := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'door1', 'size', '8 64 128', 'angle', '-1',
    'wait', '-1']));
  LDoor.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  FRig.RunUntil(5000);
  Assert.AreEqual(Ord(msPos2), Ord(LDoor.MoverState), 'resta aperta');
  // activated again while open: wait -1 means nothing happens
  LDoor.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  FRig.RunUntil(6000);
  Assert.AreEqual(Ord(msPos2), Ord(LDoor.MoverState));
end;

procedure TTestD3GameMovers.UnaSquadraDiPorteDovrebbeMuoversiInsiemeAlMaster;
var
  LMaster: TD3Door;
  LSlave: TD3Door;
begin
  LMaster := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'a', 'size', '8 64 128', 'angle', '-1',
    'team', 'pair']));
  LSlave := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'b', 'size', '8 64 128', 'angle', '-1',
    'team', 'PAIR', 'origin', '50 0 0']));
  Assert.AreSame(LMaster, LSlave.MoveMaster);
  Assert.AreSame(LSlave, LMaster.ActivateChain);
  // the slave sends the use to the master
  LSlave.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(Ord(ms1To2), Ord(LMaster.MoverState));
  Assert.AreEqual(Ord(ms1To2), Ord(LSlave.MoverState));
  FRig.RunUntil(400);
  Assert.AreEqual(Ord(msPos2), Ord(LSlave.MoverState));
  // deleting the master hands the team to the next one
  FRig.Game.RemoveEntity(LMaster.EntityNumber);
  Assert.AreSame(LSlave, LSlave.MoveMaster, 'lo schiavo diventa master');
end;

procedure TTestD3GameMovers.UnaPortaDovrebbeSparareITriggerOpenedEClosed;
var
  LDoor: TD3Door;
begin
  FRig.Spawn(['classname', 'info_recorder', 'name', 'r1']);
  FRig.Spawn(['classname', 'info_recorder', 'name', 'r2']);
  LDoor := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'door1', 'size', '8 64 128', 'angle', '-1',
    'wait', '0', 'triggerOpened', 'r1', 'triggerClosed', 'r2']));
  LDoor.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  FRig.RunUntil(1000);
  Assert.IsTrue(FRig.Log.Text.Contains('ACTIVATE r1'), FRig.Log.Text);
  Assert.IsTrue(FRig.Log.Text.Contains('ACTIVATE r2'), FRig.Log.Text);
end;

procedure TTestD3GameMovers.EventEnableDiUnMoverBinaryDovrebbeSpegnereComeLOriginale;
var
  LDoor: TD3Door;
begin
  LDoor := TD3Door(FRig.Spawn(SDoorKeys));
  Assert.IsTrue(LDoor.Enabled);
  // idMover_Binary::Event_Enable calls Enable( false ) (a defect of the original)
  LDoor.ProcessEvent(FRig.EntityEvents.Enable);
  Assert.IsFalse(LDoor.Enabled);
  LDoor.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(Ord(msPos1), Ord(LDoor.MoverState), 'disabilitata: non si apre');
end;

procedure TTestD3GameMovers.UnMoverDovrebbeAndareAUnaPosizioneEDirloAlThread;
var
  LMover: TD3Mover;
  LArgs: TDoomScriptEventArgs;
begin
  LMover := TD3Mover(FRig.Spawn(['classname', 'func_mover', 'name', 'm1', 'move_time', '1',
    'origin', '0 0 0']));
  LArgs := VectorArg(0, 0, 100);
  LMover.ProcessEvent(FRig.EntityEvents.MoveToPos, LArgs);
  // the move time is snapped to 1008 ms, in one linear stage
  Assert.AreEqual(1008, LMover.MoveTime);
  FRig.Threads.Current := 7;
  LMover.ProcessEvent(FRig.EntityEvents.SetCallback);
  Assert.AreEqual('d 1', FRig.Threads.Returned[FRig.Threads.Returned.Count - 1], 'il thread aspetta');
  FRig.RunUntil(2000);
  AreNear(100, OriginZ('m1'), 0.01);
  Assert.AreEqual(1, FRig.Threads.MoveDone.Count, 'finita');
  Assert.AreEqual(Format('7 %d', [LMover.EntityNumber]), FRig.Threads.MoveDone[0]);
  Assert.IsFalse(LMover.IsActive);
end;

procedure TTestD3GameMovers.UnMoverConAccelerazioneEDecelerazioneDovrebbeFareTreFasi;
var
  LMover: TD3Mover;
  LArgs: TDoomScriptEventArgs;
begin
  LMover := TD3Mover(FRig.Spawn(['classname', 'func_mover', 'name', 'm1', 'move_time', '2',
    'accel_time', '0.5', 'decel_time', '0.5']));
  LArgs := VectorArg(0, 0, 200);
  LMover.ProcessEvent(FRig.EntityEvents.MoveToPos, LArgs);
  // accel 512 (500 snapped), decel 512, total 2000 + 12 + 12 = snapped
  Assert.AreEqual(Ord(mvLinear), Ord(LMover.Move.Stage), 'dopo la prima fase pianificata');
  Assert.AreEqual(512, LMover.Move.Acceleration);
  Assert.AreEqual(512, LMover.Move.Deceleration);
  FRig.RunUntil(4000);
  AreNear(200, OriginZ('m1'), 0.05);
end;

procedure TTestD3GameMovers.UnMoverDovrebbeFermarsiConStopMoving;
var
  LMover: TD3Mover;
  LArgs: TDoomScriptEventArgs;
begin
  LMover := TD3Mover(FRig.Spawn(['classname', 'func_mover', 'name', 'm1', 'move_time', '2']));
  LArgs := VectorArg(0, 0, 100);
  LMover.ProcessEvent(FRig.EntityEvents.MoveToPos, LArgs);
  FRig.RunUntil(500);
  LMover.ProcessEvent(FRig.EntityEvents.StopMoving);
  FRig.RunUntil(3000);
  Assert.IsTrue(OriginZ('m1') < 100, 'si e fermato prima');
  Assert.IsTrue(OriginZ('m1') > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3GameMovers);

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - the base entity (hide,       }
{  targets, events) and the triggers, on a game with fakes                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.Triggers;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.D3Game.WorldRig;

type
  [TestFixture]
  [Category('D3Game')]
  TTestD3GameTriggers = class
  strict private
    FRig: TD3WorldRig;
    procedure AddDefs;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnaEntitaNascostaDovrebbeRisultareNascostaEMostrarsi;
    [Test]
    procedure UnTargetDiUnaEntitaDovrebbeEssereTrovatoQuandoIlGiocoEAttivo;
    [Test]
    procedure UnaEntitaCheMiraSeStessaDovrebbeDareErrore;
    [Test]
    procedure UnTriggerMultiDovrebbeAttivareIBersagliEAspettareIlTempoDiAttesa;
    [Test]
    procedure UnTriggerOnceDovrebbeSparareUnaSolaVoltaERimuoversi;
    [Test]
    procedure UnTriggerMultiConRitardoDovrebbePostareLAzioneEAttenderla;
    [Test]
    procedure UnTriggerMultiConTriggerFirstDovrebbeIgnorareLaPrimaAttivazione;
    [Test]
    procedure UnTriggerMultiDovrebbeChiamareLaFunzioneDiScript;
    [Test]
    procedure UnTriggerConUnaFunzioneIgnotaDovrebbeAvvisare;
    [Test]
    procedure UnTriggerTimerDovrebbeSparareARitmoDellAttesa;
    [Test]
    procedure UnTriggerTimerDovrebbeFermarsiConDisableERipartireConEnable;
    [Test]
    procedure UnTriggerTimerAttivatoDovrebbeInvertireLoStato;
    [Test]
    procedure UnTriggerCountDovrebbeSparareAlRaggiungimentoDelConteggio;
    [Test]
    procedure UnTriggerHurtDovrebbeDanneggiareUnaVoltaPerIntervallo;
    [Test]
    procedure UnTriggerFadeSenzaGiocatoreNonDovrebbeFareNulla;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.D3Game.Types, DelphiDoom.D3Game.Entity,
  DelphiDoom.D3Game.Trigger.Multi, DelphiDoom.D3Game.Trigger.Timer, DelphiDoom.D3Game.Trigger.Count,
  DelphiDoom.D3Game.Trigger.Hurt;

procedure TTestD3GameTriggers.Setup;
begin
  FRig := TD3WorldRig.Create;
  AddDefs;
end;

procedure TTestD3GameTriggers.TearDown;
begin
  FRig.Free;
end;

procedure TTestD3GameTriggers.AddDefs;
begin
  // the entityDefs the game data has for these classes (trigger_once and trigger_relay are entityDefs of
  // idTrigger_Multi: there is no class of their own in the source; the keys here are the ones of the assumption)
  FRig.World.AddDef('info_recorder', ['spawnclass', 'idRecorder']);
  FRig.World.AddDef('trigger_multi', ['spawnclass', 'idTrigger_Multi']);
  FRig.World.AddDef('trigger_once', ['spawnclass', 'idTrigger_Multi', 'wait', '-1']);
  FRig.World.AddDef('trigger_relay', ['spawnclass', 'idTrigger_Multi', 'wait', '0', 'noTouch', '1']);
  FRig.World.AddDef('trigger_timer', ['spawnclass', 'idTrigger_Timer']);
  FRig.World.AddDef('trigger_count', ['spawnclass', 'idTrigger_Count']);
  FRig.World.AddDef('trigger_hurt', ['spawnclass', 'idTrigger_Hurt']);
  FRig.World.AddDef('trigger_fade', ['spawnclass', 'idTrigger_Fade']);
  FRig.World.AddFunction('openSesame');
end;

procedure TTestD3GameTriggers.UnaEntitaNascostaDovrebbeRisultareNascostaEMostrarsi;
var
  LEntity: TD3Entity;
begin
  LEntity := FRig.Spawn(['classname', 'info_recorder', 'name', 'r1', 'hide', '1']);
  Assert.IsTrue(LEntity.IsHidden, 'nascosta alla nascita');
  Assert.AreEqual('hide@0', FRig.Queue.Pending, 'evento di hide');
  FRig.Frame;
  Assert.IsTrue(LEntity.IsHidden);
  LEntity.ProcessEvent(FRig.EntityEvents.Show);
  Assert.IsFalse(LEntity.IsHidden, 'show');
  LEntity.ProcessEvent(FRig.EntityEvents.Hide);
  Assert.IsTrue(LEntity.IsHidden, 'hide');
end;

procedure TTestD3GameTriggers.UnTargetDiUnaEntitaDovrebbeEssereTrovatoQuandoIlGiocoEAttivo;
var
  LRecorder: TD3Entity;
  LTrigger: TD3Entity;
begin
  LRecorder := FRig.Spawn(['classname', 'info_recorder', 'name', 'r1']);
  LTrigger := FRig.Spawn(['classname', 'trigger_relay', 'name', 't1', 'target', 'r1', 'target1', 'nobody']);
  Assert.AreEqual(1, LTrigger.NumTargets, 'un solo bersaglio esistente');
  Assert.AreSame(LRecorder, LTrigger.GetTarget(0));
  Assert.IsNull(LTrigger.GetTarget(1));
end;

procedure TTestD3GameTriggers.UnaEntitaCheMiraSeStessaDovrebbeDareErrore;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Spawn(['classname', 'trigger_relay', 'name', 't1', 'target', 't1']);
    end, ED3GameException);
end;

procedure TTestD3GameTriggers.UnTriggerMultiDovrebbeAttivareIBersagliEAspettareIlTempoDiAttesa;
var
  LTrigger: TD3Entity;
begin
  FRig.Spawn(['classname', 'info_recorder', 'name', 'r1']);
  LTrigger := FRig.Spawn(['classname', 'trigger_multi', 'name', 't1', 'target', 'r1', 'wait', '0.5',
    'random', '0']);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(1, FRig.Log.Count, 'prima attivazione');
  Assert.AreEqual('ACTIVATE r1 by (none) t=0', FRig.Log[0]);
  Assert.AreEqual(500, TD3TriggerMulti(LTrigger).NextTriggerTime, 'attesa di mezzo secondo');
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(1, FRig.Log.Count, 'ancora in attesa');
  FRig.RunUntil(512);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(2, FRig.Log.Count, 'finita l''attesa');
end;

procedure TTestD3GameTriggers.UnTriggerOnceDovrebbeSparareUnaSolaVoltaERimuoversi;
var
  LTrigger: TD3Entity;
begin
  FRig.Spawn(['classname', 'info_recorder', 'name', 'r1']);
  LTrigger := FRig.Spawn(['classname', 'trigger_once', 'name', 't1', 'target', 'r1']);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(1, FRig.Log.Count);
  Assert.AreEqual(1, TD3TriggerMulti(LTrigger).NextTriggerTime, 'un millisecondo di blocco');
  Assert.IsNotNull(FRig.Game.FindEntity('t1'), 'ancora presente prima del fotogramma');
  FRig.Frame;
  Assert.IsNull(FRig.Game.FindEntity('t1'), 'rimosso dall''evento');
  Assert.AreEqual(1, FRig.Log.Count);
end;

procedure TTestD3GameTriggers.UnTriggerMultiConRitardoDovrebbePostareLAzioneEAttenderla;
var
  LTrigger: TD3Entity;
begin
  FRig.Spawn(['classname', 'info_recorder', 'name', 'r1']);
  LTrigger := FRig.Spawn(['classname', 'trigger_multi', 'name', 't1', 'target', 'r1', 'delay', '0.1',
    'wait', '0.5']);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(0, FRig.Log.Count, 'nulla subito');
  Assert.AreEqual('<triggerAction>@100', FRig.Queue.Pending);
  FRig.RunUntil(112);
  Assert.AreEqual(1, FRig.Log.Count, 'dopo il ritardo');
  Assert.AreEqual('ACTIVATE r1 by (none) t=112', FRig.Log[0]);
end;

procedure TTestD3GameTriggers.UnTriggerMultiConTriggerFirstDovrebbeIgnorareLaPrimaAttivazione;
var
  LTrigger: TD3Entity;
begin
  FRig.Spawn(['classname', 'info_recorder', 'name', 'r1']);
  LTrigger := FRig.Spawn(['classname', 'trigger_multi', 'name', 't1', 'target', 'r1', 'triggerFirst', '1',
    'wait', '0']);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(0, FRig.Log.Count, 'ignorata');
  Assert.IsFalse(TD3TriggerMulti(LTrigger).TriggerFirst);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(1, FRig.Log.Count, 'la seconda passa');
end;

procedure TTestD3GameTriggers.UnTriggerMultiDovrebbeChiamareLaFunzioneDiScript;
var
  LTrigger: TD3Entity;
begin
  LTrigger := FRig.Spawn(['classname', 'trigger_multi', 'name', 't1', 'call', 'openSesame']);
  FRig.World.Trace.Clear;
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.IsTrue(FRig.World.Trace.Text.Contains('CALL idThread openSesame'), 'thread avviato');
  Assert.IsTrue(FRig.World.Trace.Text.Contains('CALL idThread.DelayedStart 0'));
end;

procedure TTestD3GameTriggers.UnTriggerConUnaFunzioneIgnotaDovrebbeAvvisare;
begin
  FRig.World.Trace.Clear;
  FRig.Spawn(['classname', 'trigger_multi', 'name', 't1', 'call', 'nothing', 'origin', '1 2 3']);
  Assert.IsTrue(FRig.World.Trace.Text.Contains('WARNING trigger ''t1'' at (1 2 3) calls unknown function ''nothing'''),
    FRig.World.Trace.Text);
end;

procedure TTestD3GameTriggers.UnTriggerTimerDovrebbeSparareARitmoDellAttesa;
begin
  FRig.Spawn(['classname', 'info_recorder', 'name', 'r1']);
  FRig.Spawn(['classname', 'trigger_timer', 'name', 't1', 'target', 'r1', 'start_on', '1', 'wait', '0.5',
    'random', '0']);
  Assert.AreEqual('<timer>@0', FRig.Queue.Pending);
  FRig.RunUntil(1000);
  Assert.AreEqual(2, FRig.Log.Count);
  Assert.AreEqual('ACTIVATE r1 by t1 t=16', FRig.Log[0]);
  Assert.AreEqual('ACTIVATE r1 by t1 t=528', FRig.Log[1]);
end;

procedure TTestD3GameTriggers.UnTriggerTimerDovrebbeFermarsiConDisableERipartireConEnable;
var
  LTimer: TD3Entity;
begin
  FRig.Spawn(['classname', 'info_recorder', 'name', 'r1']);
  LTimer := FRig.Spawn(['classname', 'trigger_timer', 'name', 't1', 'target', 'r1', 'start_on', '1',
    'wait', '0.5', 'random', '0']);
  Assert.IsTrue(TD3TriggerTimer(LTimer).IsOn);
  LTimer.ProcessEvent(FRig.EntityEvents.Disable);
  Assert.IsFalse(TD3TriggerTimer(LTimer).IsOn);
  Assert.AreEqual(0, FRig.Queue.Count, 'evento cancellato');
  FRig.Frame(10);
  Assert.AreEqual(0, FRig.Log.Count);
  LTimer.ProcessEvent(FRig.EntityEvents.Enable);
  Assert.IsTrue(TD3TriggerTimer(LTimer).IsOn);
  FRig.Frame(2);
  Assert.AreEqual(1, FRig.Log.Count);
end;

procedure TTestD3GameTriggers.UnTriggerTimerAttivatoDovrebbeInvertireLoStato;
var
  LTimer: TD3Entity;
  LOther: TD3Entity;
begin
  LTimer := FRig.Spawn(['classname', 'trigger_timer', 'name', 't1', 'wait', '1', 'random', '0']);
  LOther := FRig.Spawn(['classname', 'info_recorder', 'name', 'r1']);
  Assert.IsFalse(TD3TriggerTimer(LTimer).IsOn);
  LTimer.ProcessEntityEvent(FRig.EntityEvents.Activate, LOther);
  Assert.IsTrue(TD3TriggerTimer(LTimer).IsOn, 'acceso');
  LTimer.ProcessEntityEvent(FRig.EntityEvents.Activate, LOther);
  Assert.IsFalse(TD3TriggerTimer(LTimer).IsOn, 'spento');
end;

procedure TTestD3GameTriggers.UnTriggerCountDovrebbeSparareAlRaggiungimentoDelConteggio;
var
  LTrigger: TD3Entity;
begin
  FRig.Spawn(['classname', 'info_recorder', 'name', 'r1']);
  LTrigger := FRig.Spawn(['classname', 'trigger_count', 'name', 't1', 'target', 'r1', 'count', '2']);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(1, TD3TriggerCount(LTrigger).Count);
  Assert.AreEqual(0, FRig.Queue.Count);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(-1, TD3TriggerCount(LTrigger).Goal, 'esaurito');
  Assert.AreEqual('<triggerAction>@0', FRig.Queue.Pending);
  FRig.Frame;
  Assert.AreEqual(1, FRig.Log.Count, 'bersagli attivati');
  Assert.IsNull(FRig.Game.FindEntity('t1'), 'rimosso');
end;

procedure TTestD3GameTriggers.UnTriggerHurtDovrebbeDanneggiareUnaVoltaPerIntervallo;
var
  LTrigger: TD3Entity;
  LVictim: TD3Entity;
begin
  LTrigger := FRig.Spawn(['classname', 'trigger_hurt', 'name', 't1', 'delay', '1']);
  LVictim := FRig.Spawn(['classname', 'info_recorder', 'name', 'v1']);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Touch, LVictim);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Touch, LVictim);
  Assert.AreEqual(1, FRig.Log.Count, 'un solo colpo');
  Assert.AreEqual('DAMAGE v1 damage_painTrigger', FRig.Log[0]);
  FRig.RunUntil(1008);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Touch, LVictim);
  Assert.AreEqual(2, FRig.Log.Count, 'passato l''intervallo');
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.IsFalse(TD3TriggerHurt(LTrigger).IsOn, 'spento');
end;

procedure TTestD3GameTriggers.UnTriggerFadeSenzaGiocatoreNonDovrebbeFareNulla;
var
  LTrigger: TD3Entity;
begin
  LTrigger := FRig.Spawn(['classname', 'trigger_fade', 'name', 't1']);
  LTrigger.ProcessEntityEvent(FRig.EntityEvents.Activate, nil);
  Assert.AreEqual(0, FRig.Queue.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3GameTriggers);

end.

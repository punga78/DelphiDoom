{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptSysEvents    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.SysEvents;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.Thread, DelphiDoom.Tests.DoomScript.Rig;

type
  /// <summary>The events of the threads the library implements, each one from a script</summary>
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptSysEvents = class
  strict private
    FRig: TDoomScriptTestRig;
    /// <summary>Compiles "void main() { body }", runs it and gives what it printed after the compilation</summary>
    function RunBody(const ABody: AnsiString; const AName: AnsiString = 'main'): string;
    function WorldCalls: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeStampareConESenzaFineRiga;
    [Test]
    procedure DovrebbeIgnorareAssertComeUnaBuildDiRilascio;
    [Test]
    procedure DovrebbeFermareIlThreadConPauseEWait;
    [Test]
    procedure DovrebbeTerminareUnThreadPerNumero;
    [Test]
    procedure DovrebbeUccidereIThreadPerNome;
    [Test]
    procedure DovrebbeCambiareIlNomeDelThread;
    [Test]
    procedure DovrebbeAspettareUnAltroThread;
    [Test]
    procedure DovrebbeAvvisareSeIlThreadDaAspettareNonCESoloConIlDebug;
    [Test]
    procedure DovrebbeAspettareUnEntitaSoloSeAccettaLaRichiesta;
    [Test]
    procedure DovrebbeDareIlTempoEIlFotogrammaDellHost;
    [Test]
    procedure DovrebbeDareNumeriCasualiDellHost;
    [Test]
    procedure DovrebbeCalcolareSenoCosenoERadice;
    [Test]
    procedure DovrebbeCalcolareConIVettori;
    [Test]
    procedure DovrebbeConvertireGliAngoliInDirezioni;
    [Test]
    procedure DovrebbeTagliareLeStringhe;
    [Test]
    procedure DovrebbeTagliareLeStringheAiLimiti;
    [Test]
    procedure DovrebbeTroncareLeStringheA127Caratteri;
    [Test]
    procedure DovrebbeConvertireUnaStringaInNumero;
    [Test]
    procedure DovrebbeTenereGliArgomentiDiSpawnDelThread;
    [Test]
    procedure DovrebbeCreareUnEntitaConGliArgomentiDelThread;
    [Test]
    procedure DovrebbeCopiareGliArgomentiDiUnEntita;
    [Test]
    procedure DovrebbeTrovareUnEntitaPerNomeEPerNumero;
    [Test]
    procedure DovrebbeDareErrorePerUnNumeroDiEntitaFuoriIntervallo;
    [Test]
    procedure DovrebbeRegistrareETogliereUnSegnale;
    [Test]
    procedure DovrebbeDareErrorePerUnSegnaleOUnaFunzioneNonValidi;
    [Test]
    procedure DovrebbeDareErroreEAvvisoDalloScript;
    [Test]
    procedure DovrebbeRimuovereIlThreadConRemove;
    [Test]
    procedure DovrebbeLasciareSenzaGestoreGliEventiDiMondo;
    [Test]
    procedure DovrebbeLasciareSenzaGestoreGliEventiDelMondoSeIlMondoNonCE;
    [Test]
    procedure DovrebbeAccettareIlGestoreDiUnEventoDiMondoDallHost;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Random, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventTarget;

procedure TTestDoomScriptSysEvents.Setup;
begin
  FRig := TDoomScriptTestRig.Create;
end;

procedure TTestDoomScriptSysEvents.TearDown;
begin
  FRig.Free;
end;

function TTestDoomScriptSysEvents.RunBody(const ABody: AnsiString; const AName: AnsiString): string;
var
  LBefore: Integer;
begin
  FRig.Compile('void ' + AName + '() { ' + ABody + ' }'#10);
  LBefore := Length(FRig.Printed);
  FRig.Run(AName);
  Result := Copy(FRig.Printed, LBefore + 1, MaxInt);
end;

function TTestDoomScriptSysEvents.WorldCalls: Integer;
var
  LIndex: Integer;
begin
  // the calls to the world, without the developer text of the compilations
  Result := 0;
  for LIndex := 0 to FRig.Host.Calls.Count - 1 do
    if FRig.Host.Calls[LIndex].StartsWith('HOST ') then
      Inc(Result);
end;

procedure TTestDoomScriptSysEvents.DovrebbeStampareConESenzaFineRiga;
begin
  Assert.AreEqual('one two'#10'three', RunBody('sys.print( "one " ); sys.println( "two" ); sys.print( "three" );'));
end;

procedure TTestDoomScriptSysEvents.DovrebbeIgnorareAssertComeUnaBuildDiRilascio;
begin
  Assert.AreEqual('after', RunBody('sys.assert( 0 ); sys.print( "after" );'));
end;

procedure TTestDoomScriptSysEvents.DovrebbeFermareIlThreadConPauseEWait;
var
  LThread: TDoomScriptThread;
begin
  FRig.Compile('void main() { sys.print( "a" ); sys.pause(); sys.print( "b" ); sys.wait( 0.05 ); sys.print( "c" ); ' +
    'sys.waitFrame(); sys.print( "d" ); }'#10);
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  LThread.ManualDelete;
  Assert.IsFalse(LThread.Start);
  Assert.EndsWith('a', FRig.Printed);
  Assert.AreEqual(0, LThread.WaitingUntil);
  Assert.IsFalse(LThread.Execute);
  Assert.EndsWith('ab', FRig.Printed);
  Assert.AreEqual(50, LThread.WaitingUntil);
  FRig.Frame(50);
  Assert.EndsWith('abc', FRig.Printed);
  Assert.AreEqual(66, LThread.WaitingUntil);
  FRig.Frame(16);
  Assert.EndsWith('abcd', FRig.Printed);
  Assert.IsTrue(LThread.IsDying);
end;

procedure TTestDoomScriptSysEvents.DovrebbeTerminareUnThreadPerNumero;
var
  LVictim: TDoomScriptThread;
begin
  LVictim := FRig.Machine.CreateThread;
  Assert.AreEqual(1, LVictim.ThreadNum);
  RunBody('sys.terminate( 1 ); sys.terminate( 77 );');
  Assert.IsTrue(LVictim.IsDying);
end;

procedure TTestDoomScriptSysEvents.DovrebbeUccidereIThreadPerNome;
var
  LFirst: TDoomScriptThread;
  LSecond: TDoomScriptThread;
begin
  LFirst := FRig.Machine.CreateThread;
  LFirst.SetThreadName('gate_a');
  LSecond := FRig.Machine.CreateThread;
  LSecond.SetThreadName('other');
  RunBody('sys.killthread( "gate*" );');
  Assert.IsTrue(LFirst.IsDying);
  Assert.IsFalse(LSecond.IsDying);
end;

procedure TTestDoomScriptSysEvents.DovrebbeCambiareIlNomeDelThread;
var
  LThread: TDoomScriptThread;
begin
  FRig.Compile('void main() { sys.threadname( "worker" ); sys.pause(); }'#10);
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  LThread.Start;
  Assert.AreEqual('worker', string(LThread.GetThreadName));
end;

procedure TTestDoomScriptSysEvents.DovrebbeAspettareUnAltroThread;
var
  LThread: TDoomScriptThread;
begin
  FRig.Compile(
    'void slow() { sys.wait( 0.1 ); sys.print( "slow done " ); }'#10 +
    'void main() { float t = thread slow(); sys.waitForThread( t ); sys.print( "main done" ); }'#10);
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  LThread.ManualDelete;
  Assert.IsFalse(LThread.Start);
  Assert.IsNotNull(LThread.WaitingOnThread);
  Assert.AreEqual('slow', string(LThread.WaitingOnThread.GetThreadName));
  FRig.Frame(100);
  FRig.Frame(16);
  Assert.EndsWith('slow done main done', FRig.Printed);
end;

procedure TTestDoomScriptSysEvents.DovrebbeAvvisareSeIlThreadDaAspettareNonCESoloConIlDebug;
begin
  Assert.AreEqual('on', RunBody('sys.waitForThread( 55 ); sys.print( "on" );'));
  Assert.AreEqual('', FRig.Warnings);
  FRig.Machine.RestartThreads;
  FRig.Host.DebugScriptOn := True;
  FRig.Compile('void again() { sys.waitForThread( 55 ); }'#10);
  FRig.Run('again');
  Assert.Contains(FRig.Warnings, 'Thread 55 not running');
end;

procedure TTestDoomScriptSysEvents.DovrebbeAspettareUnEntitaSoloSeAccettaLaRichiesta;
var
  LThread: TDoomScriptThread;
  LAccept: Boolean;
begin
  FRig.AddEntity(5, 'mover');
  FRig.Compile('void main() { sys.waitFor( $mover ); sys.print( "moved" ); }'#10);
  // an entity that does not know the request: the thread goes on
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  Assert.IsTrue(LThread.Start);
  Assert.EndsWith('moved', FRig.Printed);
  // the entity answers the request through the returned value
  LAccept := False;
  FRig.EntityClass.AddEvent(FRig.Machine.Context.EvSetCallback,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      FRig.Machine.ScriptProgram.ReturnFloat(Ord(LAccept));
    end);
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  Assert.IsTrue(LThread.Start, 'refused: the thread goes on');
  LAccept := True;
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  Assert.IsFalse(LThread.Start);
  Assert.IsTrue(LThread.IsWaitingFor(5));
end;

procedure TTestDoomScriptSysEvents.DovrebbeDareIlTempoEIlFotogrammaDellHost;
begin
  FRig.Host.RealClientTime := 2500;
  FRig.Host.FrameMsec := 20;
  Assert.AreEqual('2.500000 0.020000 60',
    RunBody('sys.print( sys.getTime() + " " + sys.getFrameTime() + " " + sys.getTicsPerSecond() );'));
end;

procedure TTestDoomScriptSysEvents.DovrebbeDareNumeriCasualiDellHost;
var
  LRandom: TIdRandom;
  LFirst: Single;
  LExpected: Single;
begin
  // the fake host has the idRandom of the game with seed 0
  LRandom := TIdRandom.Create(0);
  LFirst := LRandom.RandomFloat;
  LExpected := 10 * LFirst;
  FRig.Compile('float out; void main() { out = sys.random( 10 ); }'#10);
  FRig.Run('main');
  Assert.AreEqual(LExpected, PSingle(FRig.Machine.ScriptProgram.GlobalPtr(
    FRig.Machine.ScriptProgram.GetDef(nil, 'out', FRig.Machine.ScriptProgram.DefNamespace).Value, 4))^);
end;

procedure TTestDoomScriptSysEvents.DovrebbeCalcolareSenoCosenoERadice;
begin
  Assert.AreEqual('0.500000 0.500000 3 1 0',
    RunBody('sys.print( sys.sin( 30 ) + " " + sys.cos( 60 ) + " " + sys.sqrt( 9 ) + " " + sys.sin( 90 ) + " " + ' +
    'sys.sin( 0 ) );'));
end;

procedure TTestDoomScriptSysEvents.DovrebbeCalcolareConIVettori;
begin
  // the pitch of a horizontal vector is a negative zero: "%.2f" writes its sign
  Assert.AreEqual('5 0.6 0.8 0|11|0 0 1|-0 90 0',
    RunBody('vector v = ''3 4 0''; sys.print( sys.vecLength( v ) + " " + sys.vecNormalize( v ) + "|" + ' +
    'sys.DotProduct( v, ''1 2 3'' ) + "|" + sys.CrossProduct( ''1 0 0'', ''0 1 0'' ) + "|" + ' +
    'sys.VecToAngles( ''0 1 0'' ) );'));
end;

procedure TTestDoomScriptSysEvents.DovrebbeConvertireGliAngoliInDirezioni;
begin
  // no angle: forward is x, right is -y, up is z (the zeros that come from "-sin" keep their sign)
  Assert.AreEqual('1 0 -0|0 -1 -0|0 0 1',
    RunBody('sys.print( sys.angToForward( ''0 0 0'' ) + "|" + sys.angToRight( ''0 0 0'' ) + "|" + ' +
    'sys.angToUp( ''0 0 0'' ) );'));
end;

procedure TTestDoomScriptSysEvents.DovrebbeTagliareLeStringhe;
begin
  Assert.AreEqual('5|he|lo|llo|ell',
    RunBody('string s = "hello"; sys.print( sys.strLength( s ) + "|" + sys.strLeft( s, 2 ) + "|" + ' +
    'sys.strRight( s, 2 ) + "|" + sys.strSkip( s, 2 ) + "|" + sys.strMid( s, 1, 3 ) );'));
end;

procedure TTestDoomScriptSysEvents.DovrebbeTagliareLeStringheAiLimiti;
begin
  // a negative or too large count never reads outside the string; 2147483647 is 2^31 as a float, which
  // becomes a negative integer (the "integer indefinite" of the x86): no characters
  Assert.AreEqual('[]' + '[hello]' + '[]' + '[hello]' + '[hello]' + '[]' + '[]' + '[hello]' + '[]' + '[]' + '[hello]' +
    '[lo]',
    RunBody('string s = "hello"; sys.print( ' +
    '"[" + sys.strLeft( s, -1 ) + "]" + "[" + sys.strLeft( s, 99 ) + "]" + ' +
    '"[" + sys.strRight( s, -1 ) + "]" + "[" + sys.strRight( s, 99 ) + "]" + ' +
    '"[" + sys.strSkip( s, -1 ) + "]" + "[" + sys.strSkip( s, 99 ) + "]" + ' +
    '"[" + sys.strMid( s, 1, -1 ) + "]" + "[" + sys.strMid( s, -5, 99 ) + "]" + ' +
    '"[" + sys.strMid( s, 3, 2147483647 ) + "]" + "[" + sys.strMid( s, 99, 2 ) + "]" + ' +
    '"[" + sys.strLeft( s, 5 ) + "]" + "[" + sys.strMid( s, 3, 1000000 ) + "]" );'));
  FRig.Machine.RestartThreads;
  Assert.AreEqual('0[][][][]',
    RunBody('string e; sys.print( sys.strLength( e ) + "[" + sys.strLeft( e, 3 ) + "]" + "[" + sys.strRight( e, 3 ) + ' +
    '"]" + "[" + sys.strSkip( e, 3 ) + "]" + "[" + sys.strMid( e, 0, 3 ) + "]" );', 'empty'));
end;

procedure TTestDoomScriptSysEvents.DovrebbeTroncareLeStringheA127Caratteri;
var
  LLong: AnsiString;
  LPrinted: string;
begin
  // a string of the script is a buffer of 128 bytes
  LLong := AnsiString(StringOfChar('x', 100));
  LPrinted := RunBody('string a = "' + LLong + '"; string b = a + a; sys.print( sys.strLength( b ) + ":" + ' +
    'sys.strLength( sys.strLeft( b, 500 ) ) + ":" ); sys.print( b );');
  Assert.AreEqual('127:127:' + StringOfChar('x', 127), LPrinted);
end;

procedure TTestDoomScriptSysEvents.DovrebbeConvertireUnaStringaInNumero;
begin
  Assert.AreEqual('12.500000 -3 0 7',
    RunBody('sys.print( sys.strToFloat( "12.5" ) + " " + sys.strToFloat( "-3" ) + " " + sys.strToFloat( "abc" ) + " " + ' +
    'sys.strToFloat( "7up" ) );'));
end;

procedure TTestDoomScriptSysEvents.DovrebbeTenereGliArgomentiDiSpawnDelThread;
begin
  Assert.AreEqual('red|none|2.500000|9|1 2 3|4 5 6',
    RunBody('sys.setSpawnArg( "color", "red" ); sys.setSpawnArg( "size", "2.5" ); sys.setSpawnArg( "at", "1 2 3" ); ' +
    'sys.print( sys.SpawnString( "color", "none" ) + "|" + sys.SpawnString( "missing", "none" ) + "|" + ' +
    'sys.SpawnFloat( "size", 9 ) + "|" + sys.SpawnFloat( "missing", 9 ) + "|" + ' +
    'sys.SpawnVector( "at", ''4 5 6'' ) + "|" + sys.SpawnVector( "missing", ''4 5 6'' ) );'));
end;

procedure TTestDoomScriptSysEvents.DovrebbeCreareUnEntitaConGliArgomentiDelThread;
var
  LThread: TDoomScriptThread;
begin
  FRig.AddEntity(40, 'made');
  FRig.Host.NextSpawn := 40;
  FRig.Compile('entity made; void main() { sys.setSpawnArg( "color", "red" ); made = sys.spawn( "light" ); ' +
    'sys.pause(); }'#10);
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  LThread.Start;
  Assert.IsTrue(FRig.Host.Calls.IndexOf('HOST SpawnEntity color=red classname=light') >= 0, FRig.Host.Calls.Text);
  Assert.AreEqual(0, LThread.SpawnArgs.GetNumKeyVals, 'the arguments are used up');
  Assert.AreEqual(41, PInteger(FRig.Machine.ScriptProgram.GlobalPtr(
    FRig.Machine.ScriptProgram.GetDef(nil, 'made', FRig.Machine.ScriptProgram.DefNamespace).Value, 4))^);
  // nothing spawned: no entity
  FRig.Host.NextSpawn := -1;
  FRig.Machine.CreateThread(FRig.FindFunction('main')).Start;
  Assert.AreEqual(0, PInteger(FRig.Machine.ScriptProgram.GlobalPtr(
    FRig.Machine.ScriptProgram.GetDef(nil, 'made', FRig.Machine.ScriptProgram.DefNamespace).Value, 4))^);
end;

procedure TTestDoomScriptSysEvents.DovrebbeCopiareGliArgomentiDiUnEntita;
begin
  FRig.AddEntity(8, 'source');
  Assert.AreEqual('8', RunBody('sys.copySpawnArgs( $source ); sys.print( sys.SpawnString( "copied", "" ) );'));
  Assert.IsTrue(FRig.Host.Calls.IndexOf('HOST CopyEntitySpawnArgs 8') >= 0);
end;

procedure TTestDoomScriptSysEvents.DovrebbeTrovareUnEntitaPerNomeEPerNumero;
begin
  FRig.AddEntity(8, 'eight');
  FRig.Host.FoundEntity := 8;
  Assert.AreEqual('1 1 0 1',
    RunBody('entity a = sys.getEntity( "anything" ); entity b = sys.getEntity( "*8" ); ' +
    'entity c = sys.getEntity( "*9" ); sys.print( ( a == $eight ) + " " + ( b == $eight ) + " " + ' +
    '( c == $eight ) + " " + ( c == $null_entity ) );'));
  Assert.IsTrue(FRig.Host.Calls.IndexOf('HOST FindEntity anything') >= 0);
  Assert.AreEqual(1, WorldCalls, 'a number is not asked to the host');
end;

procedure TTestDoomScriptSysEvents.DovrebbeDareErrorePerUnNumeroDiEntitaFuoriIntervallo;
begin
  FRig.Compile('void high() { sys.getEntity( "*4096" ); }'#10'void low() { sys.getEntity( "*-1" ); }'#10);
  Assert.Contains(FRig.RunError('high'), 'Entity number in string out of range.');
  Assert.Contains(FRig.RunError('low'), 'Entity number in string out of range.');
end;

procedure TTestDoomScriptSysEvents.DovrebbeRegistrareETogliereUnSegnale;
begin
  FRig.AddEntity(8, 'eight');
  FRig.Compile('void handler() { }'#10'void main() { sys.onSignal( 2, $eight, "handler" ); ' +
    'sys.clearSignalThread( 3, $eight ); }'#10);
  FRig.Run('main');
  Assert.IsTrue(FRig.Host.Calls.IndexOf('HOST SetSignal 8 2 1 handler') >= 0, FRig.Host.Calls.Text);
  Assert.IsTrue(FRig.Host.Calls.IndexOf('HOST ClearSignalThread 8 3 1') >= 0, FRig.Host.Calls.Text);
end;

procedure TTestDoomScriptSysEvents.DovrebbeDareErrorePerUnSegnaleOUnaFunzioneNonValidi;
begin
  FRig.AddEntity(8, 'eight');
  FRig.Compile(
    'void handler() { }'#10 +
    'void highSignal() { sys.onSignal( 10, $eight, "handler" ); }'#10 +
    'void lowSignal() { sys.onSignal( -1, $eight, "handler" ); }'#10 +
    'void noFunction() { sys.onSignal( 1, $eight, "nothing" ); }'#10 +
    'void clearHigh() { sys.clearSignalThread( 10, $eight ); }'#10 +
    'void clearLow() { sys.clearSignalThread( -1, $eight ); }'#10);
  Assert.Contains(FRig.RunError('highSignal'), 'Signal out of range');
  Assert.Contains(FRig.RunError('lowSignal'), 'Signal out of range');
  Assert.Contains(FRig.RunError('noFunction'), 'Function ''nothing'' not found');
  Assert.Contains(FRig.RunError('clearHigh'), 'Signal out of range');
  Assert.Contains(FRig.RunError('clearLow'), 'Signal out of range');
  Assert.AreEqual(0, WorldCalls, 'nothing reached the world');
end;

procedure TTestDoomScriptSysEvents.DovrebbeDareErroreEAvvisoDalloScript;
begin
  FRig.Compile('void main() {'#10'  sys.warning( "watch out" );'#10'  sys.error( "all wrong" );'#10'}'#10);
  Assert.AreEqual('EDoomScriptError: test.script(3): Thread ''main'': all wrong'#10, FRig.RunError('main'));
  Assert.AreEqual('test.script(2): Thread ''main'': watch out'#10, FRig.Warnings);
  // the error prints the stack of the calls first
  Assert.Contains(FRig.Printed, ' test.script : main'#10);
end;

procedure TTestDoomScriptSysEvents.DovrebbeRimuovereIlThreadConRemove;
var
  LThread: TDoomScriptThread;
begin
  FRig.Compile('void main() { sys.remove(); sys.pause(); }'#10);
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  Assert.IsFalse(LThread.Start);
  Assert.AreEqual(1, FRig.Machine.NumThreads);
  // the removal is an event: the thread goes at the next service
  FRig.Machine.ServiceEvents;
  Assert.AreEqual(0, FRig.Machine.NumThreads);
end;

procedure TTestDoomScriptSysEvents.DovrebbeLasciareSenzaGestoreGliEventiDiMondo;
begin
  // the events that need the game (say, trigger, cvars, camera, traces, fades, music, damage, debug drawing)
  // are defined and have no handler until the host gives one: the compiler refuses the call
  Assert.IsNotNull(FRig.Machine.SysEvents.Say);
  Assert.IsFalse(FRig.Machine.Context.ThreadClass.RespondsTo(FRig.Machine.SysEvents.Say));
  Assert.IsFalse(FRig.Machine.Context.ThreadClass.RespondsTo(FRig.Machine.SysEvents.Trace));
  Assert.IsFalse(FRig.Machine.Context.ThreadClass.RespondsTo(FRig.Machine.SysEvents.SetCvar));
  Assert.IsFalse(FRig.Machine.Context.ThreadClass.RespondsTo(FRig.Machine.SysEvents.DrawText));
  Assert.Contains(FRig.CompileError('void main() { sys.say( "hi" ); }'#10),
    '"say" is not callable as a ''sys'' function');
  Assert.AreEqual('say', string(FRig.Machine.SysEvents.Say.Name));
  Assert.AreEqual('vvvvde', string(FRig.Machine.SysEvents.Trace.ArgFormat));
  Assert.AreEqual(AnsiChar('f'), FRig.Machine.SysEvents.Trace.ReturnType);
end;

procedure TTestDoomScriptSysEvents.DovrebbeLasciareSenzaGestoreGliEventiDelMondoSeIlMondoNonCE;
var
  LRig: TDoomScriptTestRig;
begin
  LRig := TDoomScriptTestRig.Create(False);
  try
    Assert.IsFalse(LRig.Machine.Context.ThreadClass.RespondsTo(LRig.Machine.SysEvents.GetEntity));
    Assert.IsFalse(LRig.Machine.Context.ThreadClass.RespondsTo(LRig.Machine.SysEvents.Spawn));
    Assert.IsFalse(LRig.Machine.Context.ThreadClass.RespondsTo(LRig.Machine.SysEvents.OnSignal));
    Assert.IsTrue(LRig.Machine.Context.ThreadClass.RespondsTo(LRig.Machine.SysEvents.Print));
    Assert.Contains(LRig.CompileError('void main() { sys.getEntity( "x" ); }'#10),
      '"getEntity" is not callable as a ''sys'' function');
  finally
    LRig.Free;
  end;
end;

procedure TTestDoomScriptSysEvents.DovrebbeAccettareIlGestoreDiUnEventoDiMondoDallHost;
var
  LSaid: string;
begin
  FRig.Machine.Context.ThreadClass.AddEvent(FRig.Machine.SysEvents.Say,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LSaid := string(AArgs[0].StringValue) + ' from ' + string(TDoomScriptThread(ATarget).GetThreadName);
    end);
  RunBody('sys.say( "hello" );');
  Assert.AreEqual('hello from main', LSaid);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptSysEvents);

end.

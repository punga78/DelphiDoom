{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptMachine,     }
{  script objects and saved state                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.MachineState;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.Thread, DelphiDoom.Tests.DoomScript.Rig;

type
  /// <summary>
  ///   The facade of the machine: script objects of the entities and the composite save. A damaged save may
  ///   only give an error of the machine: never a read or a write outside its memory.
  /// </summary>
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptMachineState = class
  strict private
    FRig: TDoomScriptTestRig;
    procedure PrepareGame;
    function SaveGame: TBytes;
    function TryRestore(const AData: TBytes): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCostruireLOggettoDiUnEntitaEdEseguireInit;
    [Test]
    procedure DovrebbeCostruireUnOggettoSenzaInitSenzaThread;
    [Test]
    procedure DovrebbeRifiutareUnTipoSconosciutoOUnEntitaCheNonCE;
    [Test]
    procedure DovrebbeEseguireDestroyQuandoLOggettoVieneSmontato;
    [Test]
    procedure DovrebbeCreareUnThreadSuUnMetodoDellOggetto;
    [Test]
    procedure DovrebbeControllareGliArgomentiDiUnEventoMandatoDallHost;
    [Test]
    procedure DovrebbeSalvareERipristinareUnOggettoSenzaCampi;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiThreadFuoriLimite;
    [Test]
    procedure DovrebbeSalvareERipristinareThreadEventiEVariabili;
    [Test]
    procedure DovrebbeScrivereGliOggettiComeLHarness;
    [Test]
    procedure DovrebbeDareErroreDedicatoPerOgniSalvataggioTronco;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiThreadNonValido;
    [Test]
    procedure DovrebbeRifiutareUnRiferimentoAUnThreadCheNonCE;
    [Test]
    procedure DovrebbeSopravvivereAUnSalvataggioGuastoInOgniPunto;
    [Test]
    procedure DovrebbeNonSalvareGliArgomentiStringaDegliEventiComeLOriginale;
    [Test]
    procedure DovrebbeConsegnareNessunaEntitaSeQuellaDellEventoEStataSostituita;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventTarget,
  DelphiDoom.DoomScript.ScriptObject, DelphiDoom.DoomScript.ScriptProgram, DelphiDoom.DoomScript.SaveStream,
  DelphiDoom.DoomScript.Entities,
  DelphiDoom.DoomScript.Machine, DelphiDoom.Tests.DoomScript.Support;

const
  GAME: AnsiString =
    'float counter = 1;'#10 +
    'string label = "start";'#10 +
    'object thing {'#10 +
    '  float count; string name;'#10 +
    '  void init(); void destroy(); void bump();'#10 +
    '};'#10 +
    'void thing::init() { count = 10; name = "made"; sys.print( "init " ); }'#10 +
    'void thing::destroy() { sys.print( "destroy " + count + " " ); }'#10 +
    'void thing::bump() { count = count + 1; sys.wait( 0.2 ); count = count + 100; }'#10 +
    'object plain { float only; };'#10 +
    'void sleeper( float step ) { counter = counter + step; sys.wait( 0.1 ); counter = counter + step; ' +
    'label = "slept"; }'#10 +
    'void starter() { thread sleeper( 5 ); sys.waitFrame(); counter = counter * 2; }'#10;

procedure TTestDoomScriptMachineState.Setup;
begin
  FRig := TDoomScriptTestRig.Create;
  FRig.Compile(GAME);
  FRig.Machine.ScriptProgram.FinishCompilation;
end;

procedure TTestDoomScriptMachineState.TearDown;
begin
  FRig.Free;
end;

procedure TTestDoomScriptMachineState.PrepareGame;
var
  LEntity: TDoomScriptEventTarget;
  LThread: TDoomScriptThread;
begin
  // two threads that wait, an entity with an object and a method that waits, events with arguments
  LEntity := FRig.AddEntity(3, 'three');
  Assert.IsTrue(FRig.Machine.ConstructScriptObject(3, 'thing', LThread));
  FRig.Machine.CreateThread(FRig.FindFunction('starter')).Start;
  FRig.Machine.CreateObjectThread(3, FRig.Machine.Entities.ObjectOf(3).GetFunction('bump')).Start;
  FRig.Machine.Queue.PostEventMS(LEntity, FRig.Machine.Events.FindEvent('ping'), 500,
    [TDoomScriptConvert.FloatArg(1.5)]);
  FRig.Machine.Queue.PostEventMS(LEntity, FRig.Machine.SysEvents.Activate, 600, [TDoomScriptConvert.EntityArg(3)]);
end;

function TTestDoomScriptMachineState.SaveGame: TBytes;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    FRig.Machine.Save(LStream);
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

function TTestDoomScriptMachineState.TryRestore(const AData: TBytes): Boolean;
var
  LStream: TBytesStream;
begin
  // true = restored, false = refused with an error of the machine; anything else is not caught
  LStream := TBytesStream.Create(AData);
  try
    try
      FRig.Machine.Restore(LStream);
      Result := True;
    except
      on E: EIdLibException do
        Result := False;
    end;
  finally
    LStream.Free;
  end;
end;

procedure TTestDoomScriptMachineState.DovrebbeCostruireLOggettoDiUnEntitaEdEseguireInit;
var
  LThread: TDoomScriptThread;
  LObject: TDoomScriptObject;
begin
  FRig.AddEntity(3, 'three');
  Assert.IsTrue(FRig.Machine.ConstructScriptObject(3, 'thing', LThread));
  Assert.IsNotNull(LThread);
  Assert.AreEqual('three', string(LThread.GetThreadName));
  Assert.IsTrue(LThread.IsManualControl);
  Assert.IsFalse(LThread.Interpreter.TerminateOnExit, 'the host frees the thread of the constructor');
  Assert.Contains(FRig.Printed, 'init ');
  LObject := FRig.Machine.Entities.ObjectOf(3);
  Assert.AreEqual('thing', string(LObject.GetTypeName));
  Assert.AreEqual(Single(10), PSingle(LObject.DataPtr(LObject.GetVariable('count', evFloat), 4))^);
  Assert.AreEqual('made', string(TDoomScriptMemory.ReadString(LObject.DataPtr(LObject.GetVariable('name', evString),
    DS_MAX_STRING_LEN))));
  Assert.AreEqual(-1, LObject.GetVariable('count', evString), 'another kind');
  Assert.AreEqual(-1, LObject.GetVariable('nothing', evFloat));
  LThread.Free;
end;

procedure TTestDoomScriptMachineState.DovrebbeCostruireUnOggettoSenzaInitSenzaThread;
var
  LThread: TDoomScriptThread;
begin
  FRig.AddEntity(3, 'three');
  Assert.IsTrue(FRig.Machine.ConstructScriptObject(3, 'plain', LThread));
  Assert.IsNull(LThread);
  Assert.AreEqual(4, FRig.Machine.Entities.ObjectOf(3).DataSize);
  Assert.AreEqual(0, FRig.Machine.NumThreads);
  // no destructor: nothing runs
  FRig.Machine.DeconstructScriptObject(3);
  Assert.AreEqual(0, FRig.Machine.NumThreads);
end;

procedure TTestDoomScriptMachineState.DovrebbeRifiutareUnTipoSconosciutoOUnEntitaCheNonCE;
var
  LThread: TDoomScriptThread;
begin
  FRig.AddEntity(3, 'three');
  Assert.IsFalse(FRig.Machine.ConstructScriptObject(3, 'no_such_type', LThread));
  Assert.IsNull(LThread);
  Assert.Contains(FRig.Warnings, 'idScriptObject::SetType: Unknown type ''no_such_type''');
  // a type of the program that is not an object type (the type of the float fields of the objects)
  Assert.IsFalse(FRig.Machine.ConstructScriptObject(3, 'float field', LThread));
  Assert.Contains(FRig.Warnings, 'Can''t create object of type ''float field''.  Must be an object type.');
  Assert.IsFalse(FRig.Machine.ConstructScriptObject(4, 'thing', LThread), 'no entity 4');
  Assert.IsFalse(FRig.Machine.ConstructScriptObject(-1, 'thing', LThread));
  Assert.IsFalse(FRig.Machine.ConstructScriptObject(DS_MAX_GENTITIES, 'thing', LThread));
  // nothing to deconstruct either
  FRig.Machine.DeconstructScriptObject(4);
  FRig.Machine.DeconstructScriptObject(3);
end;

procedure TTestDoomScriptMachineState.DovrebbeEseguireDestroyQuandoLOggettoVieneSmontato;
var
  LThread: TDoomScriptThread;
begin
  FRig.AddEntity(3, 'three');
  FRig.Machine.ConstructScriptObject(3, 'thing', LThread);
  LThread.Free;
  FRig.Machine.DeconstructScriptObject(3);
  Assert.Contains(FRig.Printed, 'destroy 10 ');
  Assert.AreEqual(0, FRig.Machine.NumThreads, 'the thread of the destructor is gone');
end;

procedure TTestDoomScriptMachineState.DovrebbeCreareUnThreadSuUnMetodoDellOggetto;
var
  LThread: TDoomScriptThread;
  LObject: TDoomScriptObject;
begin
  FRig.AddEntity(3, 'three');
  FRig.Machine.ConstructScriptObject(3, 'thing', LThread);
  LThread.Free;
  LObject := FRig.Machine.Entities.ObjectOf(3);
  LThread := FRig.Machine.CreateObjectThread(3, LObject.GetFunction('bump'));
  LThread.ManualDelete;
  Assert.AreEqual('three', string(LThread.GetThreadName));
  Assert.IsFalse(LThread.Start);
  Assert.AreEqual(Single(11), PSingle(LObject.DataPtr(0, 4))^);
  FRig.Frame(200);
  Assert.AreEqual(Single(111), PSingle(LObject.DataPtr(0, 4))^);
  Assert.IsNull(LObject.GetFunction('nothing'));
end;

procedure TTestDoomScriptMachineState.DovrebbeControllareGliArgomentiDiUnEventoMandatoDallHost;
var
  LEntity: TDoomScriptEventTarget;
  LSeen: Integer;
  LActivate: TDoomScriptEventDef;
  LOwner: TDoomScriptEventDef;
begin
  LEntity := FRig.AddEntity(3, 'three');
  LActivate := FRig.Machine.SysEvents.Activate;
  LOwner := FRig.Machine.Events.Define('setOwner', 'E');
  LSeen := -2;
  FRig.EntityClass.AddEvent(LActivate,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LSeen := AArgs[0].IntValue;
    end);
  FRig.EntityClass.AddEvent(LOwner,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LSeen := AArgs[0].IntValue;
    end);
  Assert.IsTrue(LEntity.ProcessHostEvent(LActivate, [TDoomScriptConvert.EntityArg(3)]));
  Assert.AreEqual(3, LSeen);
  // NULL passed as the integer 0 for an 'e' argument is no entity
  Assert.IsTrue(LEntity.ProcessHostEvent(LActivate, [TDoomScriptConvert.IntArg(0)]));
  Assert.AreEqual(-1, LSeen);
  // an event the class does not answer is ignored, whatever the arguments
  Assert.IsFalse(LEntity.ProcessHostEvent(FRig.Machine.SysEvents.Wait, []));
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      LEntity.ProcessHostEvent(LActivate, []);
    end, EDoomScriptError, 'idEvent::CopyArgs : Wrong number of args for ''activate'' event.');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      LEntity.ProcessHostEvent(LActivate, [TDoomScriptConvert.FloatArg(1)]);
    end, EDoomScriptError, 'idEvent::CopyArgs : Wrong type passed in for arg # 0 on ''activate'' event.');
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      LEntity.ProcessHostEvent(LActivate, [TDoomScriptConvert.IntArg(5)]);
    end, EDoomScriptError);
  // kept from the original: an entity given by the host has the kind 'e' and never matches an 'E' argument,
  // so an event with one cannot be sent or posted by the host
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      LEntity.ProcessHostEvent(LOwner, [TDoomScriptConvert.EntityArg(3)]);
    end, EDoomScriptError, 'idEvent::CopyArgs : Wrong type passed in for arg # 0 on ''setOwner'' event.');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FRig.Machine.Queue.PostEventMS(LEntity, LOwner, 0, [TDoomScriptConvert.EntityArg(3)]);
    end, EDoomScriptError, 'idEvent::Alloc : Wrong type passed in for arg # 0 on ''setOwner'' event.');
end;

procedure TTestDoomScriptMachineState.DovrebbeSalvareERipristinareUnOggettoSenzaCampi;
var
  LThread: TDoomScriptThread;
  LObject: TDoomScriptObject;
  LStream: TBytesStream;
begin
  FRig.Machine.ScriptProgram.CompileText('empty.script', 'object hollow { void nothing(); };'#10 +
    'void hollow::nothing() { }'#10, False);
  FRig.AddEntity(3, 'three');
  Assert.IsTrue(FRig.Machine.ConstructScriptObject(3, 'hollow', LThread));
  LObject := FRig.Machine.Entities.ObjectOf(3);
  Assert.IsTrue(LObject.HasObject);
  Assert.AreEqual(0, LObject.DataSize);
  // as Mem_Alloc( 0 ) of the original: the interpreter sees no object to call methods on
  Assert.IsNull(FRig.Machine.Entities.GetScriptObject(4));
  LStream := TBytesStream.Create;
  try
    LObject.Save(LStream);
    LObject.FreeObject;
    Assert.IsFalse(LObject.HasObject);
    LStream.Position := 0;
    LObject.Restore(LStream);
    Assert.AreEqual(LStream.Size, LStream.Position);
    Assert.AreEqual('hollow', string(LObject.GetTypeName));
    // an object without a type is an empty name, and restores as nothing
    LObject.FreeObject;
    LStream.Clear;
    LObject.Save(LStream);
    Assert.AreEqual(Int64(4), LStream.Size);
    LStream.Position := 0;
    LObject.Restore(LStream);
    Assert.IsFalse(LObject.HasObject);
  finally
    LStream.Free;
  end;
end;

procedure TTestDoomScriptMachineState.DovrebbeRifiutareUnIndiceDiThreadFuoriLimite;
begin
  FRig.Machine.CreateThread;
  TDoomScriptTestSupport.ExpectClass(procedure begin FRig.Machine.ThreadAt(1); end, EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FRig.Machine.ThreadAt(-1); end, EDoomScriptMemoryError);
end;

procedure TTestDoomScriptMachineState.DovrebbeSalvareERipristinareThreadEventiEVariabili;
var
  LData: TBytes;
  LProgram: TDoomScriptProgram;
  LCounter: PSingle;
  LThreads: Integer;
  LEvents: Integer;
begin
  PrepareGame;
  LProgram := FRig.Machine.ScriptProgram;
  LCounter := PSingle(LProgram.GlobalPtr(LProgram.GetDef(nil, 'counter', LProgram.DefNamespace).Value, 4));
  Assert.AreEqual(Single(6), LCounter^);
  LThreads := FRig.Machine.NumThreads;
  LEvents := FRig.Machine.Queue.Count;
  LData := SaveGame;
  // the game goes on, then goes back to the save
  FRig.Frame(16);
  FRig.Frame(200);
  Assert.AreEqual(Single(17), LCounter^);
  FRig.Host.Time := 0;
  Assert.IsTrue(TryRestore(LData));
  Assert.AreEqual(Single(6), LCounter^);
  Assert.AreEqual(LThreads, FRig.Machine.NumThreads);
  Assert.AreEqual(LEvents, FRig.Machine.Queue.Count);
  Assert.AreEqual(LThreads, FRig.Machine.Context.ThreadIndex, 'as in the original: the number of restored threads');
  // the thread of the constructor, the starter, the sleeper it started, the method of the object
  Assert.AreEqual('sleeper', string(FRig.Machine.ThreadAt(2).GetThreadName));
  Assert.AreEqual(100, FRig.Machine.ThreadAt(2).WaitingUntil);
  // and plays the same way again
  FRig.Frame(16);
  FRig.Frame(200);
  Assert.AreEqual(Single(17), LCounter^);
  Assert.AreEqual('slept', string(TDoomScriptMemory.ReadString(LProgram.GlobalPtr(
    LProgram.GetDef(nil, 'label', LProgram.DefNamespace).Value, DS_MAX_STRING_LEN))));
  // the events of the entity are delivered with their arguments
  FRig.Frame(400);
  Assert.IsTrue(FRig.Host.Calls.IndexOf('ping 3 1.5') >= 0, FRig.Host.Calls.Text);
  // a saved state gives the same bytes when it is saved again
  FRig.Host.Time := 0;
  Assert.IsTrue(TryRestore(LData));
  Assert.AreEqual(Length(LData), Length(SaveGame));
  Assert.IsTrue(CompareMem(@LData[0], @SaveGame[0], Length(LData)), 'save, restore, save');
end;

procedure TTestDoomScriptMachineState.DovrebbeScrivereGliOggettiComeLHarness;
var
  LStream: TBytesStream;
  LThread: TDoomScriptThread;
  LEntity: TDoomScriptEventTarget;
begin
  LEntity := FRig.AddEntity(3, 'three');
  LThread := FRig.Machine.CreateThread;
  FRig.Machine.CreateThread;
  LStream := TBytesStream.Create;
  try
    FRig.Machine.WriteObject(LStream, nil);
    FRig.Machine.WriteObject(LStream, LThread);
    FRig.Machine.WriteObject(LStream, FRig.Machine.ThreadAt(1));
    FRig.Machine.WriteObject(LStream, LEntity);
    // an object the machine does not know is no object
    FRig.Machine.WriteObject(LStream, FRig);
    LStream.Position := 0;
    Assert.AreEqual(-1, TDoomScriptSaveStream.ReadInt(LStream));
    Assert.AreEqual(1, TDoomScriptSaveStream.ReadInt(LStream));
    Assert.AreEqual(2, TDoomScriptSaveStream.ReadInt(LStream));
    Assert.AreEqual(DS_SAVE_ENTITY_FLAG or 3, TDoomScriptSaveStream.ReadInt(LStream));
    Assert.AreEqual(-1, TDoomScriptSaveStream.ReadInt(LStream));
    LStream.Position := 0;
    Assert.IsNull(FRig.Machine.ReadObject(LStream));
    Assert.AreSame(LThread, FRig.Machine.ReadObject(LStream));
    Assert.AreSame(FRig.Machine.ThreadAt(1), FRig.Machine.ReadObject(LStream));
    Assert.AreSame(LEntity, FRig.Machine.ReadObject(LStream));
  finally
    LStream.Free;
  end;
end;

procedure TTestDoomScriptMachineState.DovrebbeDareErroreDedicatoPerOgniSalvataggioTronco;
var
  LData: TBytes;
  LLength: Integer;
begin
  PrepareGame;
  LData := SaveGame;
  for LLength := 0 to Length(LData) - 1 do
    Assert.IsFalse(TryRestore(Copy(LData, 0, LLength)), Format('a save cut at %d of %d bytes', [LLength,
      Length(LData)]));
  Assert.IsTrue(TryRestore(LData));
end;

procedure TTestDoomScriptMachineState.DovrebbeRifiutareUnNumeroDiThreadNonValido;
var
  LStream: TBytesStream;
  LCount: Integer;
begin
  for LCount in TArray<Integer>.Create(-1, 65537, MaxInt, Low(Integer)) do
  begin
    LStream := TBytesStream.Create;
    try
      FRig.Machine.ScriptProgram.Save(LStream);
      TDoomScriptSaveStream.WriteInt(LStream, LCount);
      Assert.IsFalse(TryRestore(Copy(LStream.Bytes, 0, LStream.Size)), IntToStr(LCount));
      Assert.AreEqual(0, FRig.Machine.NumThreads);
    finally
      LStream.Free;
    end;
  end;
end;

procedure TTestDoomScriptMachineState.DovrebbeRifiutareUnRiferimentoAUnThreadCheNonCE;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    TDoomScriptSaveStream.WriteInt(LStream, 5);
    LStream.Position := 0;
    TDoomScriptTestSupport.ExpectClass(procedure begin FRig.Machine.ReadObject(LStream); end, EDoomScriptError);
    // an entity that is not there is no object, as in the harness
    LStream.Clear;
    TDoomScriptSaveStream.WriteInt(LStream, DS_SAVE_ENTITY_FLAG or 77);
    TDoomScriptSaveStream.WriteInt(LStream, 0);
    LStream.Position := 0;
    Assert.IsNull(FRig.Machine.ReadObject(LStream));
    Assert.IsNull(FRig.Machine.ReadObject(LStream));
  finally
    LStream.Free;
  end;
end;

procedure TTestDoomScriptMachineState.DovrebbeSopravvivereAUnSalvataggioGuastoInOgniPunto;
const
  Values: array[0..6] of Cardinal = ($7FFFFFFF, $80000000, $FFFFFFFF, 64, 4095, 6144, $00010000);
var
  LData: TBytes;
  LDamaged: TBytes;
  LOffset: Integer;
  LValue: Cardinal;
  LRefused: Integer;
  LFrame: Integer;
begin
  // Every 4 bytes of a real save replaced, one position at a time, by values that are limits of the machine.
  // The restore and three frames of the game after it may fail only with an error of the machine: any other
  // exception (an access violation, a range error) ends the test.
  PrepareGame;
  LData := SaveGame;
  LRefused := 0;
  for LOffset := 0 to Length(LData) - 4 do
    for LValue in Values do
    begin
      LDamaged := Copy(LData);
      PCardinal(@LDamaged[LOffset])^ := LValue;
      FRig.Host.Time := 0;
      if not TryRestore(LDamaged) then
        Inc(LRefused);
      for LFrame := 1 to 3 do
        try
          FRig.Frame(100);
        except
          on E: EIdLibException do
            ;
        end;
    end;
  Assert.IsTrue(LRefused > 100, Format('only %d damaged saves were refused', [LRefused]));
  // the machine still works
  FRig.Host.Time := 0;
  Assert.IsTrue(TryRestore(LData));
end;

procedure TTestDoomScriptMachineState.DovrebbeNonSalvareGliArgomentiStringaDegliEventiComeLOriginale;
var
  LData: TBytes;
  LThread: TDoomScriptThread;
begin
  // kept from the original: idEvent::Save does not write the string arguments (after a restore the original
  // delivers uninitialized memory; here the string is empty)
  LThread := FRig.Machine.CreateThread;
  LThread.ManualDelete;
  FRig.Machine.Queue.PostEventMS(LThread, FRig.Machine.SysEvents.Print, 50, [TDoomScriptConvert.StringArg('lost')]);
  LData := SaveGame;
  Assert.IsTrue(TryRestore(LData));
  Assert.AreEqual(1, FRig.Machine.Queue.Count);
  Assert.AreEqual('', string(FRig.Machine.Queue.GetEvent(0).Args[0].StringValue));
  FRig.Frame(50);
  Assert.IsFalse(FRig.Printed.Contains('lost'));
end;

procedure TTestDoomScriptMachineState.DovrebbeConsegnareNessunaEntitaSeQuellaDellEventoEStataSostituita;
var
  LListener: TDoomScriptEventTarget;
  LSeen: Integer;
begin
  // the entity argument of a queued event is an idEntityPtr: the handle and the spawn id. Another entity in
  // the same slot is not the one the event was posted with.
  LListener := FRig.AddEntity(3, 'listener');
  FRig.AddEntity(4, 'first');
  LSeen := -2;
  FRig.EntityClass.AddEvent(FRig.Machine.SysEvents.Activate,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LSeen := AArgs[0].IntValue;
    end);
  FRig.Machine.Queue.PostEventMS(LListener, FRig.Machine.SysEvents.Activate, 10, [TDoomScriptConvert.EntityArg(4)]);
  FRig.Frame(10);
  Assert.AreEqual(4, LSeen);
  FRig.Machine.Queue.PostEventMS(LListener, FRig.Machine.SysEvents.Activate, 10, [TDoomScriptConvert.EntityArg(4)]);
  FRig.Machine.Entities.Remove(4);
  FRig.AddEntity(4, 'second');
  FRig.Frame(10);
  Assert.AreEqual(-1, LSeen);
  Assert.AreEqual(3, FRig.Machine.Entities.SpawnIdOf(3));
  Assert.AreEqual(5, FRig.Machine.Entities.SpawnIdOf(4), 'the third entity added');
  Assert.AreEqual(-1, FRig.Machine.Entities.SpawnIdOf(5));
  Assert.AreEqual((5 shl 12) or 4, FRig.Machine.Entities.EntityPtr(4));
  Assert.AreEqual(0, FRig.Machine.Entities.EntityPtr(5));
  Assert.AreEqual(4, FRig.Machine.Entities.ResolveEntityPtr((5 shl 12) or 4));
  Assert.AreEqual(-1, FRig.Machine.Entities.ResolveEntityPtr((4 shl 12) or 4));
  Assert.AreEqual(-1, FRig.Machine.Entities.ResolveEntityPtr(0));
  Assert.AreEqual(-1, FRig.Machine.Entities.ResolveEntityPtr(-1));
  FRig.Machine.Entities.Rename(4, 'renamed');
  Assert.AreEqual('renamed', string(FRig.Machine.Entities.NameOf(4)));
  Assert.AreEqual(6, FRig.Machine.Entities.SpawnCount);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptMachineState);

end.

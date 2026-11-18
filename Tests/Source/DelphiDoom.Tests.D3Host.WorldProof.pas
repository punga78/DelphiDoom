{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 host library - the proof without game data, |
{  second part (phase 4c of docs\DOOM3_CENSIMENTO.md): a synthetic map with a  }
{  trigger and doors of the entity classes of IdTech4\D3Game, a script whose   }
{  main fires the trigger and opens a door and waits for them, run by the      }
{  life cycle of D3Host with the game time and the script time as one          }
{                                                                              }
{  There is no C++ golden for the whole: the pieces have their own parity      }
{  (the triggers, the movers and the event queue: Tests\Data\D3World).         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Host.WorldProof;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.MapFile.Map, DelphiDoom.Decl.Intf,
  DelphiDoom.D3Host.Session.Intf, DelphiDoom.D3Game.ClassSystem, DelphiDoom.D3Game.Local,
  DelphiDoom.D3Game.ScriptBridge, DelphiDoom.D3Game.EntityEvents;

type
  /// <summary>
  ///   The game of the proof with the entity classes of the library: the map, the entityDefs and the script are the
  ///   proof's, the classes are declared by <c>TD3WorldClasses</c> and every services of the game is the script bridge.
  ///   A frame moves the game time, lets the entities think and serves the events, with the time of the script machine
  ///   set to the game's (as <c>gameLocal.time</c> is both in the original).
  /// </summary>
  TProofWorldGame = class(TInterfacedObject, ID3MapLoader, ID3GameRunner)
  strict private
    FRig: TObject;
    FMap: TMapFile;
    FManager: IDeclManager;
    FBridge: TD3ScriptBridge;
    FEvents: TD3EntityEvents;
    FClasses: TD3ClassSystem;
    FGame: TD3GameLocal;
    FFrames: Integer;
  public
    destructor Destroy; override;
    procedure LoadMap(const AMapName: AnsiString);
    procedure UnloadMap;
    procedure RunFrame(const ATicNumber: Integer);
    function Printed: string;
    property Frames: Integer read FFrames;
    property Game: TD3GameLocal read FGame;
  end;

  [TestFixture]
  [Category('D3Host')]
  TTestD3HostWorldProof = class
  public
    [Test]
    procedure UnTriggerEUnaPortaDovrebbeAprirsiEIlMainDovrebbeAspettarli;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Factory, DelphiDoom.Decl.Types, DelphiDoom.Decl.Source.Memory,
  DelphiDoom.Decl.Factory, DelphiDoom.Tests.DoomScript.Rig, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Session,
  DelphiDoom.Tests.D3Host.HostScenario, DelphiDoom.D3Game.Types, DelphiDoom.D3Game.Intf,
  DelphiDoom.D3Game.DeclEntityDefs, DelphiDoom.D3Game.MapFileSource, DelphiDoom.D3Game.Settings,
  DelphiDoom.D3Game.LogPrinter, DelphiDoom.D3Game.WorldClasses, DelphiDoom.D3Game.Entity,
  DelphiDoom.D3Game.MoverBinary;

const
  SMap = 'Version 2'#10 +
    '// entity 0'#10 +
    '{'#10 +
    '"classname" "worldspawn"'#10 +
    '"script" "proof"'#10 +
    '}'#10 +
    '// entity 1'#10 +
    '{'#10 +
    '"classname" "func_door"'#10 +
    '"name" "door1"'#10 +
    '"size" "8 64 128"'#10 +
    '"angle" "-1"'#10 +
    '"wait" "-1"'#10 +
    '}'#10 +
    '// entity 2'#10 +
    '{'#10 +
    '"classname" "func_door"'#10 +
    '"name" "door2"'#10 +
    '"size" "8 64 128"'#10 +
    '"angle" "-1"'#10 +
    '"wait" "-1"'#10 +
    '"origin" "200 0 0"'#10 +
    '}'#10 +
    '// entity 3'#10 +
    '{'#10 +
    '"classname" "trigger_once"'#10 +
    '"name" "t1"'#10 +
    '"target" "door1"'#10 +
    '}'#10;
  // trigger_once is an entityDef of idTrigger_Multi with wait -1 (the data of the game is not here: assumed)
  SDecls = 'entityDef worldspawn { "spawnclass" "idWorldspawn" }'#10 +
    'entityDef func_door { "spawnclass" "idDoor" }'#10 +
    'entityDef trigger_once { "spawnclass" "idTrigger_Multi" "wait" "-1" }'#10;
  SScript = 'scriptEvent void open();'#10 +
    'scriptEvent void activate( entity activator );'#10 +
    'void main() {'#10 +
    '  sys.println( "main started" );'#10 +
    '  $t1.activate( $door1 );'#10 +
    '  sys.waitFor( $door1 );'#10 +
    '  sys.println( "door1 reached" );'#10 +
    '  $door2.open();'#10 +
    '  sys.waitFor( $door2 );'#10 +
    '  sys.println( "door2 reached" );'#10 +
    '}'#10;

{ TProofWorldGame }

destructor TProofWorldGame.Destroy;
begin
  UnloadMap;
  inherited Destroy;
end;

procedure TProofWorldGame.LoadMap(const AMapName: AnsiString);
var
  LRig: TDoomScriptTestRig;
  LFiles: IIdLibFileSystem;
  LLog: IIdLibLog;
  LSource: TDeclMemorySource;
  LSourceRef: IInterface;
  LServices: TD3GameServices;
begin
  UnloadMap;
  LRig := TDoomScriptTestRig.Create;
  FRig := LRig;
  LFiles := LRig.Files;
  LLog := LRig.Log;
  FMap := TMapFileFactory.CreateReader(LFiles, LLog).ParseText(SMap, AMapName + '.map');
  LSource := TDeclMemorySource.Create;
  LSourceRef := LSource;
  LSource.Add('def/proof.def', SDecls);
  FManager := TDeclFactory.CreateStandardManager(LSource, LLog, True);
  FManager.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);

  // the events of the entity classes exist before the script that names them is compiled
  FEvents := TD3EntityEvents.Create(LRig.Machine.Events);
  LRig.Compile(SScript);

  FBridge := TD3ScriptBridge.Create(LRig.Machine);
  LServices := Default(TD3GameServices);
  LServices.Printer := TD3GameLogPrinter.Create(LRig.Log);
  LServices.EntityDefs := TD3DeclEntityDefs.Create(FManager);
  LServices.SpawnFunctions := FBridge;
  LServices.ScriptNames := FBridge;
  LServices.Settings := TD3GameSettings.Create;
  LServices.MapSteps := FBridge;
  LServices.EventCanceller := FBridge;
  LServices.EntityObserver := FBridge;
  LServices.Events := FEvents;
  LServices.EventQueue := FBridge;
  LServices.ScriptFunctions := FBridge;
  LServices.ScriptThreads := FBridge;
  FClasses := TD3ClassSystem.Create(LServices.Printer, LRig.Machine.Events, FBridge);
  FGame := TD3GameLocal.Create(LServices, FClasses);
  FBridge.Attach(FGame);
  TD3WorldClasses.Declare(FClasses, FEvents, FGame);
  FClasses.Init;
  FBridge.BindClasses(FClasses);

  // idGameLocal::InitFromNewMap and MapPopulate: the entities of the map file, the events of their spawn
  FGame.NewMap;
  FGame.MapSource := TD3MapFileSource.Create(FMap);
  FGame.MapPopulate;
  // the main script of the level (idWorldspawn starts it in the original; not ported)
  LRig.Run('main');
end;

procedure TProofWorldGame.UnloadMap;
begin
  // the game goes first: its entities are in the script table and the queue of the machine
  FreeAndNil(FGame);
  FreeAndNil(FClasses);
  FreeAndNil(FBridge);
  FreeAndNil(FEvents);
  FreeAndNil(FRig);
  FManager := nil;
  FreeAndNil(FMap);
end;

procedure TProofWorldGame.RunFrame(const ATicNumber: Integer);
var
  LRig: TDoomScriptTestRig;
begin
  if not Assigned(FRig) then
    Exit;
  LRig := TDoomScriptTestRig(FRig);
  // the time of the script machine is the game time of the frame while the entities think
  LRig.Host.Time := FGame.Time + FGame.Msec;
  LRig.Host.RealClientTime := LRig.Host.Time;
  FGame.RunFrameThink;
  LRig.Machine.ServiceEvents;
  Inc(FFrames);
end;

function TProofWorldGame.Printed: string;
begin
  if Assigned(FRig) then
    Result := TDoomScriptTestRig(FRig).Printed
  else
    Result := '';
end;

{ TTestD3HostWorldProof }

procedure TTestD3HostWorldProof.UnTriggerEUnaPortaDovrebbeAprirsiEIlMainDovrebbeAspettarli;
var
  LRunner: THostScenarioRunner;
  LGame: TProofWorldGame;
  LGameRef: IInterface;
  LSession: TD3Session;
  LSessionRef: IInterface;
  LStep: Integer;
  LDoor1: TD3MoverBinary;
  LDoor2: TD3MoverBinary;
begin
  LRunner := THostScenarioRunner.Create;
  try
    LGame := TProofWorldGame.Create;
    LGameRef := LGame;
    LSession := TD3Session.Create(LRunner.State, LGame, LGame);
    LSessionRef := LSession;
    LRunner.Prepare(LSession, LSession);
    LRunner.Lifecycle.Init([]);
    LSession.Map('maps/proof');
    Assert.AreEqual(Ord(ssInGame), Ord(LSession.Status));

    LDoor1 := TD3MoverBinary(LGame.Game.FindEntity('door1'));
    LDoor2 := TD3MoverBinary(LGame.Game.FindEntity('door2'));
    Assert.IsNotNull(LDoor1, 'porta 1');
    Assert.IsNotNull(LDoor2, 'porta 2');
    Assert.AreEqual('idTrigger_Multi', string(LGame.Game.FindEntity('t1').GetClassname));
    // the main ran up to the wait: the trigger fired its target (found by the event of the startup), door1 is moving
    Assert.IsTrue(LGame.Printed.Contains('main started'));
    Assert.IsFalse(LGame.Printed.Contains('door1 reached'));
    Assert.AreEqual(Ord(ms1To2), Ord(LDoor1.MoverState), 'la porta si apre');
    Assert.AreEqual(Ord(msPos1), Ord(LDoor2.MoverState), 'la seconda e chiusa');

    // frames of the life cycle: the doors move while the game time passes
    for LStep := 1 to 12 do
    begin
      LRunner.World.Time := LRunner.World.Time + 16;
      LRunner.Lifecycle.Async;
      LRunner.Lifecycle.Frame;
    end;
    Assert.IsTrue(LDoor1.GetPhysics.GetOrigin.Z > 0, 'si e mossa');
    Assert.IsFalse(LGame.Printed.Contains('door1 reached'), 'ancora in corsa');

    for LStep := 1 to 60 do
    begin
      LRunner.World.Time := LRunner.World.Time + 16;
      LRunner.Lifecycle.Async;
      LRunner.Lifecycle.Frame;
    end;
    Assert.AreEqual(Ord(msPos2), Ord(LDoor1.MoverState), 'porta 1 aperta');
    Assert.AreEqual(Ord(msPos2), Ord(LDoor2.MoverState), 'porta 2 aperta dal main');
    Assert.AreEqual(120.0, Double(LDoor1.GetPhysics.GetOrigin.Z), 0.01);
    Assert.AreEqual(120.0, Double(LDoor2.GetPhysics.GetOrigin.Z), 0.01);
    // the trigger was a once trigger: it removed itself
    Assert.IsNull(LGame.Game.FindEntity('t1'), 'trigger rimosso');
    // the thread of main woke up for each door, in order
    Assert.IsTrue(LGame.Printed.Contains('door1 reached'), LGame.Printed);
    Assert.IsTrue(LGame.Printed.Contains('door2 reached'), LGame.Printed);
    Assert.IsTrue(LGame.Printed.IndexOf('door1 reached') < LGame.Printed.IndexOf('door2 reached'));

    LSession.Stop;
    LRunner.Lifecycle.Shutdown;
  finally
    LSessionRef := nil;
    LGameRef := nil;
    LRunner.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3HostWorldProof);

end.

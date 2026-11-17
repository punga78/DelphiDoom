{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 host library - the proof without game data  }
{  (phase 5c of docs\DOOM3_CENSIMENTO.md): a synthetic map, synthetic          }
{  declarations and a synthetic script, loaded by the game of IdTech4\D3Game   }
{  (entities spawned from the entityDefs) and run by the life cycle            }
{                                                                              }
{  There is no C++ golden for the whole: the pieces have their own parity      }
{  (MapFile, Decl, DoomScript, D3Host, D3Game); this proves that they work     }
{  together.                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Host.Proof;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.MapFile.Map, DelphiDoom.Decl.Intf,
  DelphiDoom.D3Host.Session.Intf, DelphiDoom.D3Game.ClassSystem, DelphiDoom.D3Game.Local,
  DelphiDoom.D3Game.ScriptBridge;

type
  /// <summary>
  ///   The game of the proof: loads a map (MapFile), the entity declarations of its entities (Decl) and the script of
  ///   the level (DoomScript, on its test rig); the game of <c>D3Game</c> spawns the entities of the map from their
  ///   entityDefs (the script machine sees them as its entities) and a frame of the script machine runs for every frame
  ///   of the session
  /// </summary>
  TProofGame = class(TInterfacedObject, ID3MapLoader, ID3GameRunner)
  strict private
    FMapText: AnsiString;
    FDeclText: AnsiString;
    FScriptText: AnsiString;
    FRig: TObject;
    FMap: TMapFile;
    FManager: IDeclManager;
    FBridge: TD3ScriptBridge;
    FClasses: TD3ClassSystem;
    FGame: TD3GameLocal;
    FSpawnClasses: TStringList;
    FEntityCount: Integer;
    FFrames: Integer;
  public
    constructor Create(const AMapText, ADeclText, AScriptText: AnsiString);
    destructor Destroy; override;
    procedure LoadMap(const AMapName: AnsiString);
    procedure UnloadMap;
    procedure RunFrame(const ATicNumber: Integer);
    function Printed: string;
    function Calls: string;
    /// <summary>"name=spawnclass" for every named entity of the map</summary>
    property SpawnClasses: TStringList read FSpawnClasses;
    property EntityCount: Integer read FEntityCount;
    property Frames: Integer read FFrames;
    property Game: TD3GameLocal read FGame;
  end;

  [TestFixture]
  [Category('D3Host')]
  TTestD3HostProof = class
  public
    [Test]
    procedure UnaMappaSinteticaDovrebbeEssereCaricataEIlMainEseguitoDalCicloDiD3Host;
    [Test]
    procedure LaSessioneSenzaMappaNonDovrebbeEseguireIlGioco;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Types, DelphiDoom.MapFile.Entity,
  DelphiDoom.MapFile.Intf, DelphiDoom.MapFile.Factory, DelphiDoom.Decl.Types, DelphiDoom.Decl.Source.Memory,
  DelphiDoom.Decl.EntityDef, DelphiDoom.Decl.Factory, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.Tests.IdLib.Fakes, DelphiDoom.Tests.DoomScript.Fakes, DelphiDoom.Tests.DoomScript.Rig,
  DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Input.Types, DelphiDoom.D3Host.Session,
  DelphiDoom.Tests.D3Host.HostScenario, DelphiDoom.D3Game.Types, DelphiDoom.D3Game.Intf,
  DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.Entity, DelphiDoom.D3Game.DeclEntityDefs,
  DelphiDoom.D3Game.MapFileSource, DelphiDoom.D3Game.Settings, DelphiDoom.D3Game.LogPrinter;

const
  SMap = 'Version 2'#10 +
    '// entity 0'#10 +
    '{'#10 +
    '"classname" "worldspawn"'#10 +
    '"script" "proof"'#10 +
    '}'#10 +
    '// entity 1'#10 +
    '{'#10 +
    '"classname" "info_player_start"'#10 +
    '"name" "start1"'#10 +
    '"origin" "0 0 64"'#10 +
    '}'#10 +
    '// entity 2'#10 +
    '{'#10 +
    '"classname" "func_door"'#10 +
    '"name" "door1"'#10 +
    '"origin" "100 0 0"'#10 +
    '}'#10;
  SDecls = 'entityDef worldspawn { "spawnclass" "idWorldspawn" }'#10 +
    'entityDef info_player_start { "spawnclass" "idPlayerStart" }'#10 +
    'entityDef func_door { "spawnclass" "idDoor" "speed" "2" }'#10;
  SScript = 'void main() {'#10 +
    '  sys.println( "level main started" );'#10 +
    '  $door1.ping( 7 );'#10 +
    '  sys.wait( 0.05 );'#10 +
    '  sys.println( "after wait" );'#10 +
    '  $start1.ping( 1 );'#10 +
    '}'#10;

type
  /// <summary>An entity of the proof: a class of the game that answers <c>ping</c> as the rig's test entity did</summary>
  TProofEntity = class(TD3Entity)
  end;

{ TProofGame }

constructor TProofGame.Create(const AMapText, ADeclText, AScriptText: AnsiString);
begin
  inherited Create;
  FMapText := AMapText;
  FDeclText := ADeclText;
  FScriptText := AScriptText;
  FSpawnClasses := TStringList.Create;
end;

destructor TProofGame.Destroy;
begin
  UnloadMap;
  FSpawnClasses.Free;
  inherited Destroy;
end;

procedure TProofGame.LoadMap(const AMapName: AnsiString);
var
  LRig: TDoomScriptTestRig;
  LFiles: IIdLibFileSystem;
  LLog: IIdLibLog;
  LSource: TDeclMemorySource;
  LSourceRef: IInterface;
  LDef: IDeclEntityDef;
  LIndex: Integer;
  LName: AnsiString;
  LClass: AnsiString;
  LServices: TD3GameServices;
  LGame: TD3GameLocal;
  LCalls: TStringList;
begin
  UnloadMap;
  LRig := TDoomScriptTestRig.Create;
  FRig := LRig;
  LFiles := LRig.Files;
  LLog := LRig.Log;
  // the map: the entities of the .map text
  FMap := TMapFileFactory.CreateReader(LFiles, LLog).ParseText(FMapText, AMapName + '.map');
  FEntityCount := FMap.GetNumEntities;
  // the declarations of the classes of the entities
  LSource := TDeclMemorySource.Create;
  LSourceRef := LSource;
  LSource.Add('def/proof.def', FDeclText);
  FManager := TDeclFactory.CreateStandardManager(LSource, LLog, True);
  // the game registers its own folders (Game_local.cpp)
  FManager.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);
  FSpawnClasses.Clear;
  for LIndex := 1 to FMap.GetNumEntities - 1 do
  begin
    LName := FMap.GetEntity(LIndex).Epairs.GetString('name');
    LClass := FMap.GetEntity(LIndex).Epairs.GetString('classname');
    if Supports(FManager.FindType(DECL_ENTITYDEF, LClass), IDeclEntityDef, LDef) then
      FSpawnClasses.Add(string(LName) + '=' + string(LDef.GetDict.GetString('spawnclass')));
  end;
  // the script of the level (compiled first: its $names exist when the entities are named)
  LRig.Compile(FScriptText);

  // the game: the script machine of the rig is the script system, the log of the rig is the output
  FBridge := TD3ScriptBridge.Create(LRig.Machine);
  LServices.Printer := TD3GameLogPrinter.Create(LRig.Log);
  LServices.EntityDefs := TD3DeclEntityDefs.Create(FManager);
  LServices.SpawnFunctions := FBridge;
  LServices.ScriptNames := FBridge;
  LServices.Settings := TD3GameSettings.Create;
  LServices.MapSteps := FBridge;
  LServices.EventCanceller := FBridge;
  LServices.EntityObserver := FBridge;
  FClasses := TD3ClassSystem.Create(LServices.Printer, LRig.Machine.Events, FBridge);
  FGame := TD3GameLocal.Create(LServices, FClasses);
  FBridge.Attach(FGame);
  LGame := FGame;
  LCalls := LRig.Host.Calls;
  // the classes of the entities (CLASS_DECLARATION); worldspawn and the others answer ping like the rig's test entity
  FClasses.Declare('idEntity', 'idClass', nil, TD3Entity.SpawnClass, True);
  FClasses.Declare('idWorldspawn', 'idEntity',
    function: TD3Class
    begin
      Result := TProofEntity.Create(LGame, LGame);
    end, TD3Entity.SpawnClass);
  FClasses.Declare('idPlayerStart', 'idEntity',
    function: TD3Class
    begin
      Result := TProofEntity.Create(LGame, LGame);
    end, TD3Entity.SpawnClass);
  FClasses.Declare('idDoor', 'idEntity',
    function: TD3Class
    begin
      Result := TProofEntity.Create(LGame, LGame);
    end, TD3Entity.SpawnClass);
  FClasses.GetClass('idDoor').AddEvent(LRig.Machine.Events.FindEvent('ping'),
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LCalls.Add(Format('ping %d %g', [TD3Entity(ATarget).EntityNumber, AArgs[0].FloatValue],
        TFormatSettings.Invariant));
    end);
  FClasses.GetClass('idPlayerStart').AddEvent(LRig.Machine.Events.FindEvent('ping'),
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LCalls.Add(Format('ping %d %g', [TD3Entity(ATarget).EntityNumber, AArgs[0].FloatValue],
        TFormatSettings.Invariant));
    end);
  FClasses.Init;
  FBridge.BindClasses(FClasses);

  // idGameLocal::InitFromNewMap and MapPopulate: the entities of the map file
  FGame.NewMap;
  FGame.MapSource := TD3MapFileSource.Create(FMap);
  FGame.MapPopulate;
  // the main script of the level (idWorldspawn starts it in the original; not ported)
  LRig.Run('main');
end;

procedure TProofGame.UnloadMap;
begin
  // the game goes first: its entities are in the script table and the queue of the machine
  FreeAndNil(FGame);
  FreeAndNil(FClasses);
  FreeAndNil(FBridge);
  FreeAndNil(FRig);
  FManager := nil;
  FreeAndNil(FMap);
  FSpawnClasses.Clear;
  FEntityCount := 0;
end;

procedure TProofGame.RunFrame(const ATicNumber: Integer);
begin
  if Assigned(FRig) then
    TDoomScriptTestRig(FRig).Frame(USERCMD_MSEC);
  Inc(FFrames);
end;

function TProofGame.Printed: string;
begin
  if Assigned(FRig) then
    Result := TDoomScriptTestRig(FRig).Printed
  else
    Result := '';
end;

function TProofGame.Calls: string;
begin
  if Assigned(FRig) then
    Result := TDoomScriptTestRig(FRig).Host.Calls.Text
  else
    Result := '';
end;

{ TTestD3HostProof }

procedure TTestD3HostProof.UnaMappaSinteticaDovrebbeEssereCaricataEIlMainEseguitoDalCicloDiD3Host;
var
  LRunner: THostScenarioRunner;
  LGame: TProofGame;
  LGameRef: IInterface;
  LSession: TD3Session;
  LSessionRef: IInterface;
  LStep: Integer;
begin
  LRunner := THostScenarioRunner.Create;
  try
    LGame := TProofGame.Create(SMap, SDecls, SScript);
    LGameRef := LGame;
    LSession := TD3Session.Create(LRunner.State, LGame, LGame);
    LSessionRef := LSession;
    LRunner.Prepare(LSession, LSession);
    LRunner.Lifecycle.Init([]);
    Assert.IsTrue(LRunner.Lifecycle.IsInitialized, 'avvio completo');
    Assert.AreEqual(Ord(ssIdle), Ord(LSession.Status));
    // the map command
    LSession.Map('maps/proof');
    Assert.AreEqual(Ord(ssInGame), Ord(LSession.Status));
    Assert.AreEqual(3, LGame.EntityCount, 'entita della mappa');
    Assert.AreEqual('start1=idPlayerStart', LGame.SpawnClasses[0]);
    Assert.AreEqual('door1=idDoor', LGame.SpawnClasses[1]);
    // the entities that the game spawned: the world in its own number, the others from the first free one
    Assert.IsNotNull(LGame.Game.Entities[D3_ENTITYNUM_WORLD], 'worldspawn');
    Assert.AreEqual('idWorldspawn', string(LGame.Game.Entities[D3_ENTITYNUM_WORLD].GetClassname));
    Assert.AreEqual('start1', string(LGame.Game.Entities[D3_MAX_CLIENTS].GetName));
    Assert.AreEqual('door1', string(LGame.Game.Entities[D3_MAX_CLIENTS + 1].GetName));
    Assert.AreEqual('func_door', string(LGame.Game.Entities[D3_MAX_CLIENTS + 1].GetEntityDefName));
    Assert.AreEqual(2, LGame.Game.Entities[D3_MAX_CLIENTS + 1].SpawnArgs.GetInt('speed'), 'default dell''entityDef');
    // the main script ran up to its wait, on the entities of the game
    Assert.IsTrue(LGame.Printed.Contains('level main started'));
    Assert.IsFalse(LGame.Printed.Contains('after wait'));
    Assert.IsTrue(LGame.Calls.Contains('ping 33 7'), 'ping alla porta');
    // the frames of the life cycle: every 16 ms a tic and a frame
    for LStep := 1 to 5 do
    begin
      LRunner.World.Time := LRunner.World.Time + 16;
      LRunner.Lifecycle.Async;
      LRunner.Lifecycle.Frame;
    end;
    Assert.AreEqual(5, LSession.GameFrames);
    Assert.IsTrue(LRunner.State.TicNumber >= 4, 'tic');
    Assert.IsTrue(LGame.Printed.Contains('after wait'), 'dopo l''attesa');
    Assert.IsTrue(LGame.Calls.Contains('ping 32 1'), 'ping alla partenza');
    // leaving the map and the life cycle
    LSession.Stop;
    Assert.AreEqual(Ord(ssIdle), Ord(LSession.Status));
    Assert.AreEqual('', LGame.Printed);
    LRunner.Lifecycle.Shutdown;
    Assert.IsTrue(LRunner.Lifecycle.ShuttingDown);
  finally
    LSessionRef := nil;
    LGameRef := nil;
    LRunner.Free;
  end;
end;

procedure TTestD3HostProof.LaSessioneSenzaMappaNonDovrebbeEseguireIlGioco;
var
  LRunner: THostScenarioRunner;
  LGame: TProofGame;
  LGameRef: IInterface;
  LSession: TD3Session;
  LSessionRef: IInterface;
begin
  LRunner := THostScenarioRunner.Create;
  try
    LGame := TProofGame.Create(SMap, SDecls, SScript);
    LGameRef := LGame;
    LSession := TD3Session.Create(LRunner.State, LGame, LGame);
    LSessionRef := LSession;
    LRunner.Prepare(LSession, LSession);
    LRunner.Lifecycle.Init([]);
    LRunner.World.Time := 16;
    LRunner.Lifecycle.Frame;
    Assert.AreEqual(0, LSession.GameFrames);
    Assert.AreEqual(0, LGame.Frames);
    Assert.IsTrue(LSession.ScreenUpdates >= 1, 'schermo aggiornato');
  finally
    LSessionRef := nil;
    LGameRef := nil;
    LRunner.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3HostProof);

end.

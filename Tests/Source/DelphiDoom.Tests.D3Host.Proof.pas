{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 host library - the proof without game data  }
{  (phase 5c of docs\DOOM3_CENSIMENTO.md): a synthetic map, synthetic          }
{  declarations and a synthetic script, loaded and run by the life cycle       }
{                                                                              }
{  There is no C++ golden: the pieces have their own parity (MapFile, Decl,    }
{  DoomScript, D3Host); this proves that they work together.                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Host.Proof;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.D3Host.Session.Intf;

type
  /// <summary>
  ///   The game of the proof: loads a map (MapFile), the entity declarations of its entities (Decl) and the script
  ///   of the level (DoomScript, on its test rig), and runs a frame of the script machine for every frame of the
  ///   session
  /// </summary>
  TProofGame = class(TInterfacedObject, ID3MapLoader, ID3GameRunner)
  strict private
    FMapText: AnsiString;
    FDeclText: AnsiString;
    FScriptText: AnsiString;
    FRig: TObject;
    FSpawnClasses: TStringList;
    FEntityCount: Integer;
    FFrames: Integer;
    function Rig: TObject;
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
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Types, DelphiDoom.MapFile.Map,
  DelphiDoom.MapFile.Entity, DelphiDoom.MapFile.Intf, DelphiDoom.MapFile.Factory, DelphiDoom.Decl.Types,
  DelphiDoom.Decl.Intf, DelphiDoom.Decl.Source.Memory, DelphiDoom.Decl.EntityDef, DelphiDoom.Decl.Factory,
  DelphiDoom.Tests.IdLib.Fakes, DelphiDoom.Tests.DoomScript.Fakes, DelphiDoom.Tests.DoomScript.Rig,
  DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Input.Types, DelphiDoom.D3Host.Session, DelphiDoom.Tests.D3Host.HostScenario;

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
  SDecls = 'entityDef info_player_start { "spawnclass" "idPlayerStart" }'#10 +
    'entityDef func_door { "spawnclass" "idDoor" "speed" "2" }'#10;
  SScript = 'void main() {'#10 +
    '  sys.println( "level main started" );'#10 +
    '  $door1.ping( 7 );'#10 +
    '  sys.wait( 0.05 );'#10 +
    '  sys.println( "after wait" );'#10 +
    '  $start1.ping( 1 );'#10 +
    '}'#10;

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
  FRig.Free;
  FSpawnClasses.Free;
  inherited Destroy;
end;

function TProofGame.Rig: TObject;
begin
  Result := FRig;
end;

procedure TProofGame.LoadMap(const AMapName: AnsiString);
var
  LRig: TDoomScriptTestRig;
  LFiles: IIdLibFileSystem;
  LLog: IIdLibLog;
  LMap: TMapFile;
  LSource: TDeclMemorySource;
  LSourceRef: IInterface;
  LManager: IDeclManager;
  LDef: IDeclEntityDef;
  LIndex: Integer;
  LName: AnsiString;
  LClass: AnsiString;
begin
  UnloadMap;
  LRig := TDoomScriptTestRig.Create;
  FRig := LRig;
  LFiles := LRig.Files;
  LLog := LRig.Log;
  // the map: the entities of the .map text
  LMap := TMapFileFactory.CreateReader(LFiles, LLog).ParseText(FMapText, AMapName + '.map');
  try
    FEntityCount := LMap.GetNumEntities;
    // the declarations of the classes of the entities
    LSource := TDeclMemorySource.Create;
    LSourceRef := LSource;
    LSource.Add('def/proof.def', FDeclText);
    LManager := TDeclFactory.CreateStandardManager(LSource, LLog, True);
    // the game registers its own folders (Game_local.cpp)
    LManager.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);
    FSpawnClasses.Clear;
    for LIndex := 1 to LMap.GetNumEntities - 1 do
    begin
      LName := LMap.GetEntity(LIndex).Epairs.GetString('name');
      LClass := LMap.GetEntity(LIndex).Epairs.GetString('classname');
      if Supports(LManager.FindType(DECL_ENTITYDEF, LClass), IDeclEntityDef, LDef) then
        FSpawnClasses.Add(string(LName) + '=' + string(LDef.GetDict.GetString('spawnclass')));
      // the entities of the level, with the number that the script sees
      LRig.AddEntity(LIndex, LName);
    end;
  finally
    LMap.Free;
  end;
  // the script of the level
  LRig.Compile(FScriptText);
  LRig.Run('main');
end;

procedure TProofGame.UnloadMap;
begin
  FreeAndNil(FRig);
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
    // the main script ran up to its wait
    Assert.IsTrue(LGame.Printed.Contains('level main started'));
    Assert.IsFalse(LGame.Printed.Contains('after wait'));
    Assert.IsTrue(LGame.Calls.Contains('ping 2 7'));
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
    Assert.IsTrue(LGame.Calls.Contains('ping 1 1'));
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

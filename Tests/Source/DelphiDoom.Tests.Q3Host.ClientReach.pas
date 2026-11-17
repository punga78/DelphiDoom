{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - how far cgame and ui of    }
{  OpenArena 0.8.8 get with the client services of phase 2c: the file system of  }
{  Framework\Wad on the real folder, the map oa_dm1, a qagame that ran          }
{  GAME_INIT and told its configstrings to the client, a recording renderer.    }
{  cgame: CG_INIT and the first CG_DRAW_ACTIVE_FRAME; ui: UI_INIT and UI_REFRESH. }
{  The golden (Tests\Data\Q3Host\reach-client.golden.txt) has the calls served,   }
{  the renderer calls and the first call nobody answers. Ignored if the          }
{  OpenArena folder is not there                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.ClientReach;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Host')]
  [Category('OpenArena')]
  TTestQ3ClientReach = class
  public
    [Test]
    procedure CgameEUiDovrebberoArrivareAlPuntoDelGolden;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Factory,
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Factory, DelphiDoom.Console.Q3.Factory,
  DelphiDoom.Scanner.Q3.GlobalDefines, DelphiDoom.Scanner.Q3.SourceHandles, DelphiDoom.Scanner.Q3.ScriptLoader,
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.Factory,
  DelphiDoom.Q3Host.GameFiles, DelphiDoom.Q3Host.ClipMap, DelphiDoom.Q3Host.MapLoader, DelphiDoom.Q3Host.ServerState,
  DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Client.Services, DelphiDoom.Q3Host.ClientState,
  DelphiDoom.Q3Host.ClientKeys, DelphiDoom.Q3Host.ClientCdKey, DelphiDoom.Q3Host.ClientRecordingRenderer,
  DelphiDoom.Q3Host.LanServers, DelphiDoom.Q3Host.ScriptFiles, DelphiDoom.Q3Host.ScriptLog,
  DelphiDoom.Tests.Q3Host.Support, DelphiDoom.Tests.Q3Host.Services, DelphiDoom.Tests.Q3Host.ClientSupport,
  DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden, DelphiDoom.Tests.Shared.Skip,
  DelphiDoom.Tests.Qvm.Support, DelphiDoom.Q3Host.Opcodes;

const
  UIMENU_MAIN = 1;
  CA_DISCONNECTED = 1;

function OpenArenaFolder: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (Result = '') or not TDirectory.Exists(Result) then
    Result := TTestFiles.FindFolderUp('Reference\openarena\openarena-0.8.8');
  if (Result = '') or not TFile.Exists(TPath.Combine(Result, 'baseoa\pak0.pk3')) then
    TTestSkip.Ignore('OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena)');
end;

function StartFileSystem(const AFolder, AGame: string): IGameFileSystem;
var
  LSettings: TGameFsSettings;
begin
  LSettings := Default(TGameFsSettings);
  LSettings.BasePath := AFolder;
  LSettings.SavePath := TPath.Combine(TPath.GetTempPath, 'ddq3reachclient');
  LSettings.GameBase := 'baseoa';
  LSettings.Game := AGame;
  LSettings.PakExtension := '.pk3';
  Result := TGameFileSystemFactory.CreateOnDisk(LSettings);
  Result.Startup;
end;

function MapOf(const AFiles: IGameFileSystem): AnsiString;
var
  LNames: TArray<string>;
  LName: string;
begin
  LNames := AFiles.ListFiles('maps', '.bsp', True);
  Assert.IsTrue(Length(LNames) > 0, 'no map in the paks');
  for LName in LNames do
    if SameText(LName, 'oa_dm1.bsp') then
      Exit('maps/' + AnsiString(LName));
  Result := 'maps/' + AnsiString(LNames[0]);
end;

function StopOf(const E: Exception; const ACount: Integer; const AStage: string): string;
var
  LMessage: string;
  LStart: Integer;
begin
  if E is EQ3UnhandledSyscallException then
  begin
    LMessage := E.Message;
    LStart := Pos('System trap ', LMessage) + Length('System trap ');
    Exit(Format('served=%d stop=%s in %s', [ACount - 1, Copy(LMessage, LStart, Pos(' (', LMessage) - LStart),
      AStage]));
  end;
  if E is EQ3ModuleErrorException then
    Exit(Format('served=%d error=%s in %s', [ACount, Trim(E.Message), AStage]));
  Result := Format('served=%d exception=%s: %s in %s', [ACount, E.ClassName, Trim(E.Message), AStage]);
end;

// one run of the three modules on the same console, clipmap and files, as the engine has them
function Measure(const AFiles: IGameFileSystem; const AMap: AnsiString; ALines: TStrings; const AGame: string): string;
var
  LConsole: TQ3Console;
  LClipMap: IQ3HostClipMap;
  LServerState: TQ3HostServerState;
  LClient: TQ3ClientState;
  LGlobals: TQ3GlobalDefines;
  LSources: TQ3SourceHandles;
  LRenderer: TQ3RecordingRenderer;
  LSound: TQ3FakeSound;
  LConnection: TQ3FakeConnection;
  LKeys: TQ3ClientKeys;
  LLan: TQ3LanServers;
  LCdKey: TQ3ClientCdKey;
  LBase, LServices: TQ3HostServices;
  LClientServices: TQ3HostClientServices;
  LHost: IQ3SyscallHost;
  LFingerprint: TQ3FingerprintHost;
  LKeeper: IQvmHost;
  LMachine: IQvmMachine;
  LData: TBytes;
  LStage: string;
  LFrame, LIndex: Integer;
  LUiState: TQ3HostUiClientState;
  LSnapshot: TQ3ClientSnapshot;
  LCommand: TQ3HostUserCmd;
  LStateIntf: IQ3HostServerState;
  LDrawsBefore, LScenesBefore: Integer;
begin
  LConsole := TQ3Console.Create;
  try
    LConsole.Init;
    LConsole.CVars.Get('sv_maxclients', '8', 0);
    LClipMap := TQ3HostClipMap.Create(TQ3HostMapLoader.Create(AFiles));
    LClipMap.Load(AMap);
    LGlobals := TQ3GlobalDefines.Create;
    LSources := TQ3SourceHandles.Create(TQ3ScriptLoader.Create(TQ3HostScriptFiles.Create(AFiles), nil), nil, LGlobals);
    LClient := TQ3ClientState.Create(LConsole.Arguments);
    LRenderer := TQ3RecordingRenderer.Create;
    LSound := TQ3FakeSound.Create;
    LConnection := TQ3FakeConnection.Create;
    LKeys := TQ3ClientKeys.Create(LConsole.CVars);
    LLan := TQ3LanServers.Create;
    LCdKey := TQ3ClientCdKey.Create;
    LServerState := TQ3HostServerState.Create(LConsole.CVars);
    LStateIntf := LServerState;
    try
      // what the server tells the clients: every configstring that changes
      LServerState.OnConfigstringChanged :=
        procedure(AIndex: Integer; const AValue: AnsiString)
        begin
          LClient.ConfigstringModified(AIndex, AValue);
        end;

      LBase := Default(TQ3HostServices);
      LBase.CVars := LConsole.CVars;
      LBase.Arguments := LConsole.Arguments;
      LBase.Buffer := LConsole.Buffer;
      LBase.Commands := LConsole.Commands;
      LBase.Files := TQ3GameHostFiles.Create(AFiles, nil);
      LBase.ClipMap := LClipMap;
      LBase.State := LServerState;
      LBase.ServerCommands := TQ3RecordingServerCommands.Create;
      LBase.Calendar := TQ3FixedCalendar.Create;

      LClientServices := Default(TQ3HostClientServices);
      LClientServices.State := LClient;
      LClientServices.Connection := LConnection;
      LClientServices.ClientSystem := TQ3FakeClientSystem.Create;
      LClientServices.Keys := LKeys;
      LClientServices.Sound := LSound;
      LClientServices.Cinematics := TQ3FakeCinematics.Create;
      LClientServices.Renderer := LRenderer;
      LClientServices.Lan := LLan;
      LClientServices.CdKey := LCdKey;
      LClientServices.Sources := LSources;
      LClientServices.Math := True;

      // 1. the server game: GAME_INIT, a client that connects and begins, three frames
      LServices := LBase;
      LHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.Game, TQ3RecordingConsole.Create(nil),
        TQ3FixedTime.Create(0), LServices);
      Assert.IsTrue(AFiles.ReadFile('vm/qagame.qvm', LData));
      LMachine := TQvmFactory.CreateMachine('qagame', LData, LHost);
      LMachine.Call(0, [1000, 12345, 0]);
      LServerState.SetUserinfo(0, '\name\Tester\model\sarge\skill\3\rate\25000\cl_voip\0');
      LServerState.SetClientActive(0, True);
      LMachine.Call(2, [0, 1, 0]);
      LMachine.Call(3, [0]);
      for LFrame := 1 to 3 do
        LMachine.Call(8, [1000 + 100 * LFrame]);
      // sv_init sets these two before the game starts
      LClient.ConfigstringModified(0, AnsiString('\sv_hostname\Test\mapname\' + Copy(AMap, 6, Length(AMap) - 9) +
        '\sv_maxclients\8\g_gametype\0\timelimit\0\fraglimit\20\capturelimit\8\g_maxGameClients\0'));
      LClient.ConfigstringModified(1, '\sv_serverid\1234\sv_pure\0');

      // 2. cgame: CG_INIT, one snapshot and a few user commands, the first frame
      LServices := LBase;
      LServices.Client := LClientServices;
      LHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.CGame, TQ3RecordingConsole.Create(nil),
        TQ3FixedTime.Create(5000), LServices);
      LFingerprint := TQ3FingerprintHost.Create(LHost);
      LKeeper := LFingerprint;
      Assert.IsTrue(AFiles.ReadFile('vm/cgame.qvm', LData));
      LMachine := TQvmFactory.CreateMachine('cgame', LData, LKeeper);
      LStage := 'init';
      try
        LMachine.Call(0, [0, 0, 0]);
        LStage := 'frame';
        LSnapshot := Default(TQ3ClientSnapshot);
        LSnapshot.MessageNum := 1;
        LSnapshot.ServerTime := 1300;
        LSnapshot.PlayerState[0] := Byte(1300 and $FF);
        LSnapshot.PlayerState[1] := Byte(1300 shr 8);
        LClient.AddSnapshot(LSnapshot, nil);
        for LIndex := 1 to 70 do
        begin
          LCommand := Default(TQ3HostUserCmd);
          PInteger(@LCommand[0])^ := 1300 + 8 * LIndex;
          LClient.AddUserCommand(LCommand);
        end;
        LMachine.Call(3, [1400, 0, 0]);
        Result := Format('served=%d finished', [LFingerprint.Count]);
      except
        on E: Exception do
          Result := StopOf(E, LFingerprint.Count, LStage);
      end;
      Result := AGame + '/cgame ' + Result + Format(' | shaders=%d models=%d scenes=%d draws=%d sounds=%d',
        [Length(LRenderer.RegisteredNames(TQ3RecordingRenderer.KIND_SHADER)),
        Length(LRenderer.RegisteredNames(TQ3RecordingRenderer.KIND_MODEL)), LRenderer.CallCount('RenderScene'),
        LRenderer.CallCount('DrawStretchPic'), LSound.Calls.Count]);
      ALines.Add(Result);

      // 3. ui: UI_INIT, the main menu, a refresh
      LDrawsBefore := LRenderer.CallCount('DrawStretchPic');
      LScenesBefore := LRenderer.CallCount('RenderScene');
      LUiState := Default(TQ3HostUiClientState);
      LUiState.ConnectionState := CA_DISCONNECTED;
      LConnection.State := LUiState;
      LRenderer.Log.Clear;
      LServices := LBase;
      LServices.Client := LClientServices;
      LHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.Ui, TQ3RecordingConsole.Create(nil),
        TQ3FixedTime.Create(5000), LServices);
      LFingerprint := TQ3FingerprintHost.Create(LHost);
      LKeeper := LFingerprint;
      Assert.IsTrue(AFiles.ReadFile('vm/ui.qvm', LData));
      LMachine := TQvmFactory.CreateMachine('ui', LData, LKeeper);
      LStage := 'init';
      try
        LMachine.Call(0, []);
        LMachine.Call(1, [0]);
        LStage := 'menu';
        LMachine.Call(UI_SET_ACTIVE_MENU, [UIMENU_MAIN]);
        LStage := 'refresh';
        for LFrame := 1 to 3 do
          LMachine.Call(5, [6000 + 20 * LFrame]);
        Result := Format('served=%d finished', [LFingerprint.Count]);
      except
        on E: Exception do
          Result := StopOf(E, LFingerprint.Count, LStage);
      end;
      Result := AGame + '/ui ' + Result + Format(' | shaders=%d draws=%d scenes=%d',
        [Length(LRenderer.RegisteredNames(TQ3RecordingRenderer.KIND_SHADER)),
        LRenderer.CallCount('DrawStretchPic') - LDrawsBefore, LRenderer.CallCount('RenderScene') - LScenesBefore]);
      ALines.Add(Result);
    finally
      LStateIntf := nil;
      LClient := nil;
      LSources.Free;
      LGlobals.Free;
      LCdKey.Free;
    end;
  finally
    LConsole.Free;
  end;
end;

procedure TTestQ3ClientReach.CgameEUiDovrebberoArrivareAlPuntoDelGolden;
var
  LFolder, LGame, LOut: string;
  LFiles: IGameFileSystem;
  LActual, LGolden: TStringList;
begin
  LFolder := OpenArenaFolder;
  LActual := TStringList.Create;
  try
    for LGame in ['baseoa', 'missionpack'] do
    begin
      LFiles := StartFileSystem(LFolder, LGame);
      Measure(LFiles, MapOf(LFiles), LActual, LGame);
      LFiles.Shutdown;
    end;
    LOut := GetEnvironmentVariable('DELPHIDOOM_Q3_REACH_CLIENT_OUT');
    if LOut <> '' then
      LActual.SaveToFile(LOut);
    TQvmScenarioRunner.Report(StringReplace(Trim(LActual.Text), sLineBreak, ' | ', [rfReplaceAll]));
    if TFile.Exists(TTestFiles.DataFile('Q3Host', 'reach-client.golden.txt')) then
    begin
      LGolden := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'reach-client.golden.txt'));
      try
        TTestGolden.AssertSameLines(LGolden, LActual);
      finally
        LGolden.Free;
      end;
    end;
  finally
    LActual.Free;
  end;
end;

end.

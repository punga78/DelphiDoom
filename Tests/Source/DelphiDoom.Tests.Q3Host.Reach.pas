{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - how far the 12 .qvm of     }
{  OpenArena 0.8.8 get in their first run (GAME_INIT, CG_INIT, UI_INIT) with    }
{  the services of phase 2b: the file system of Framework\Wad on the real       }
{  folder, the console, the map from the pk3, the state of the server. The      }
{  run ends at the first system call nobody answers yet; the golden             }
{  (Tests\Data\Q3Host\reach.golden.txt) has the number of calls served and the  }
{  name of that call. Ignored if the OpenArena folder is not there              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Reach;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Host')]
  [Category('OpenArena')]
  TTestQ3HostReach = class
  public
    [Test]
    procedure IModuliDovrebberoArrivareAllaStessaTrappaDelGolden;
    [Test]
    procedure IlSeekInUnFileDiUnPakDovrebbeRileggereDallInizio;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Factory,
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Factory, DelphiDoom.Console.Q3.Factory,
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.Factory,
  DelphiDoom.Q3Host.GameFiles, DelphiDoom.Q3Host.ClipMap, DelphiDoom.Q3Host.MapLoader, DelphiDoom.Q3Host.ServerState,
  DelphiDoom.Tests.Q3Host.Support, DelphiDoom.Tests.Q3Host.Services, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Golden, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Tests.Qvm.Support;

const
  MODULES: array[0..2] of string = ('qagame', 'cgame', 'ui');

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
  LSettings.SavePath := TPath.Combine(TPath.GetTempPath, 'ddq3reach');
  LSettings.GameBase := 'baseoa';
  LSettings.Game := AGame;
  LSettings.PakExtension := '.pk3';
  Result := TGameFileSystemFactory.CreateOnDisk(LSettings);
  Result.Startup;
end;

function FirstMap(const AFiles: IGameFileSystem): AnsiString;
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

// runs the first entry points of a module until a system call has no handler
function Measure(const AFiles: IGameFileSystem; AModule: Integer; const AMap: AnsiString): string;
var
  LConsole: TQ3Console;
  LHost: IQ3SyscallHost;
  LFingerprint: TQ3FingerprintHost;
  LKeeper: IQvmHost;
  LMachine: IQvmMachine;
  LClipMap: IQ3HostClipMap;
  LServices: TQ3HostServices;
  LData: TBytes;
  LMessage, LStage: string;
  LStart, LFrame: Integer;
  LState: TQ3HostServerState;
begin
  LConsole := TQ3Console.Create;
  try
    LConsole.Init;
    LConsole.CVars.Get('sv_maxclients', '8', 0);
    LClipMap := TQ3HostClipMap.Create(TQ3HostMapLoader.Create(AFiles));
    LClipMap.Load(AMap);
    LServices := Default(TQ3HostServices);
    LServices.CVars := LConsole.CVars;
    LServices.Arguments := LConsole.Arguments;
    LServices.Buffer := LConsole.Buffer;
    LServices.Commands := LConsole.Commands;
    LServices.Files := TQ3GameHostFiles.Create(AFiles, nil);
    LServices.ClipMap := LClipMap;
    LState := TQ3HostServerState.Create(LConsole.CVars);
    LServices.State := LState;
    LServices.ServerCommands := TQ3RecordingServerCommands.Create;
    LServices.Calendar := TQ3FixedCalendar.Create;
    LHost := TQ3HostFactory.CreateHostWithServices(TQ3Module(AModule), TQ3RecordingConsole.Create(nil),
      TQ3FixedTime.Create(0), LServices);
    LFingerprint := TQ3FingerprintHost.Create(LHost);
    LKeeper := LFingerprint;
    Assert.IsTrue(AFiles.ReadFile('vm/' + MODULES[AModule] + '.qvm', LData), MODULES[AModule]);
    LMachine := TQvmFactory.CreateMachine('reach', LData, LKeeper);
    Result := '';
    LStage := 'init';
    try
      case AModule of
        0:
          begin
            // GAME_INIT, then a client that connects and begins (the server of the C does it with the user
            // info of the client and a game that runs on a clock of 100 ms), then 100 frames
            LMachine.Call(0, [1000, 12345, 0]);
            LStage := 'connect';
            LState.SetUserinfo(0, '\name\Tester\model\sarge\skill\3\rate\25000\cl_voip\0');
            LState.SetClientActive(0, True);
            LMachine.Call(2, [0, 1, 0]);
            LStage := 'begin';
            LMachine.Call(3, [0]);
            LStage := 'frames';
            for LFrame := 1 to 100 do
              LMachine.Call(8, [1000 + 100 * LFrame]);
          end;
        1:
          LMachine.Call(0, [0, 0, 0]);
      else
        begin
          LMachine.Call(0, []);
          LMachine.Call(1, []);
        end;
      end;
      Result := Format('served=%d finished', [LFingerprint.Count]);
    except
      on E: EQ3UnhandledSyscallException do
      begin
        LMessage := E.Message;
        LStart := Pos('System trap ', LMessage) + Length('System trap ');
        Result := Format('served=%d stop=%s in %s', [LFingerprint.Count - 1,
          Copy(LMessage, LStart, Pos(' (', LMessage) - LStart), LStage]);
      end;
      on E: EQ3ModuleErrorException do
        Result := Format('served=%d error=%s in %s', [LFingerprint.Count, Trim(E.Message), LStage]);
      on E: Exception do
        Result := Format('served=%d exception=%s: %s in %s', [LFingerprint.Count, E.ClassName, Trim(E.Message),
          LStage]);
    end;
  finally
    LConsole.Free;
  end;
end;

procedure TTestQ3HostReach.IModuliDovrebberoArrivareAllaStessaTrappaDelGolden;
var
  LFolder, LGame, LOut: string;
  LFiles: IGameFileSystem;
  LActual, LGolden: TStringList;
  LModule: Integer;
  LMap: AnsiString;
begin
  LFolder := OpenArenaFolder;
  LActual := TStringList.Create;
  try
    for LGame in ['baseoa', 'missionpack'] do
    begin
      LFiles := StartFileSystem(LFolder, LGame);
      LMap := FirstMap(LFiles);
      for LModule := 0 to 2 do
        LActual.Add(Format('%s/%s %s', [LGame, MODULES[LModule], Measure(LFiles, LModule, LMap)]));
      LFiles.Shutdown;
    end;
    LOut := GetEnvironmentVariable('DELPHIDOOM_Q3_REACH_OUT');
    if LOut <> '' then
      LActual.SaveToFile(LOut);
    TQvmScenarioRunner.Report(StringReplace(Trim(LActual.Text), sLineBreak, ' | ', [rfReplaceAll]));
    if TFile.Exists(TTestFiles.DataFile('Q3Host', 'reach.golden.txt')) then
    begin
      LGolden := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'reach.golden.txt'));
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

procedure TTestQ3HostReach.IlSeekInUnFileDiUnPakDovrebbeRileggereDallInizio;
var
  LFiles: IGameFileSystem;
  LHost: IQ3HostFileSystem;
  LHandle: Integer;
  LLength: Integer;
  LAll, LBuffer: TBytes;
begin
  LFiles := StartFileSystem(OpenArenaFolder, 'baseoa');
  LHost := TQ3GameHostFiles.Create(LFiles, nil);
  LLength := LHost.Open('vm/qagame.qvm', 0, LHandle);
  Assert.IsTrue(LLength > 100);
  Assert.IsTrue(LFiles.ReadFile('vm/qagame.qvm', LAll));
  SetLength(LBuffer, 8);
  // the file is in a pak: a seek of 10 from the current position reads 10 bytes from the start
  LHost.Read(LHandle, @LBuffer[0], 4);
  Assert.AreEqual(10, LHost.Seek(LHandle, 10, 0));
  LHost.Read(LHandle, @LBuffer[0], 8);
  Assert.IsTrue(CompareMem(@LBuffer[0], @LAll[10], 8));
  Assert.AreEqual(0, LHost.Seek(LHandle, 0, 2));
  LHost.Read(LHandle, @LBuffer[0], 8);
  Assert.IsTrue(CompareMem(@LBuffer[0], @LAll[0], 8));
  // 65536 or more is the fatal error of the C
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      LHost.Seek(LHandle, 65536, 2);
    end, EQ3HostException));
  LHost.Close(LHandle);
end;

end.

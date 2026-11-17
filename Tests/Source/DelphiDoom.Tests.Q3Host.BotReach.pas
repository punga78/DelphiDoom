{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - qagame of OpenArena 0.8.8  }
{  with bots: GAME_INIT with bot_enable 1 (the botlib is set up, the map and    }
{  its .aas are loaded), a client that begins, two bots added with the          }
{  "addbot" command and 300 frames, each with BOTAI_START_FRAME first as the    }
{  server does. The run counts the BOTLIB system calls by name and ends at the  }
{  first system call nobody answers or at the end of the frames; the golden     }
{  (Tests\Data\Q3Host\reach.bots.golden.txt) has the result. Ignored if the     }
{  OpenArena folder is not there                                                }
{                                                                               }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                               }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.BotReach;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Host')]
  [Category('Q3HostBot')]
  [Category('OpenArena')]
  TTestQ3HostBotReach = class
  public
    [Test]
    procedure QagameConIBotDovrebbeArrivareFinoInFondoComeIlGolden;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, System.Generics.Defaults,
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Factory, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Wad.Fs.Factory, DelphiDoom.Console.Q3.Factory, DelphiDoom.Collision.Q3.Intf,
  DelphiDoom.IdLib.Hashing.Md4, DelphiDoom.Net.Q3.ConsoleInfoWriter, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.OpcodeCatalog,
  DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.Factory, DelphiDoom.Q3Host.GameFiles,
  DelphiDoom.Q3Host.ClipMap, DelphiDoom.Q3Host.MapLoader, DelphiDoom.Q3Host.ServerState, DelphiDoom.Q3Host.Bot.Intf,
  DelphiDoom.Q3Host.Bot.Files, DelphiDoom.Q3Host.Bot.Server, DelphiDoom.Tests.Q3Host.Support,
  DelphiDoom.Tests.Q3Host.Services, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.Shared.Skip, DelphiDoom.Tests.Qvm.Support;

const
  MAP_NAME = 'oa_dm1';
  FRAMES = 300;
  BOT_NAMES: array[0..1] of string = ('Sarge', 'Major');

type
  /// <summary>Counts every system call by name and passes it on</summary>
  TCountingHost = class(TInterfacedObject, IQvmHost)
  strict private
    FInner: IQvmHost;
    FNames: TDictionary<string, Integer>;
    FTotal: Integer;
    FTrace: TStrings;
    FVerbose: Boolean;
  public
    /// <summary>Every call goes to the trace, in order</summary>
    property Verbose: Boolean read FVerbose write FVerbose;
    constructor Create(const AInner: IQvmHost);
    destructor Destroy; override;
    /// <summary>Where the trace lines go; may be nil</summary>
    property Trace: TStrings read FTrace write FTrace;
    function SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
    function Names: TArray<string>;
    function CountOf(const AName: string): Integer;
    property Total: Integer read FTotal;
  end;

constructor TCountingHost.Create(const AInner: IQvmHost);
begin
  inherited Create;
  FInner := AInner;
  FNames := TDictionary<string, Integer>.Create;
end;

destructor TCountingHost.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

function TCountingHost.SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
var
  LName: string;
  LCount: Integer;
begin
  Inc(FTotal);
  if TQ3OpcodeCatalog.TryImportName(TQ3Module.Game, AArguments[0], LName) then
  begin
    FNames.TryGetValue(LName, LCount);
    FNames.AddOrSetValue(LName, LCount + 1);
  end;
  Result := FInner.SystemCall(AMachine, AArguments);
  // for the one who reads a run: what the game asks of the cvars and of the command line
  if Assigned(FTrace) and FVerbose and (LName <> '') then
    FTrace.Add('# order ' + LName + ' ' + IntToStr(Result));
  if Assigned(FTrace) then
    case AArguments[0] of
      G_CVAR_VARIABLE_INTEGER_VALUE:
        FTrace.Add(Format('# trace G_CVAR_VARIABLE_INTEGER_VALUE %s = %d',
          [AMachine.Memory.ReadString(AArguments[1]), Result]));
      G_ARGV:
        FTrace.Add(Format('# trace G_ARGV %d = "%s"', [AArguments[1], AMachine.Memory.ReadString(AArguments[2])]));
      G_ARGC:
        FTrace.Add(Format('# trace G_ARGC = %d', [Result]));
      G_SEND_SERVER_COMMAND:
        FTrace.Add(Format('# trace G_SEND_SERVER_COMMAND %d %s', [AArguments[1],
          AMachine.Memory.ReadString(AArguments[2])]));
      G_BOT_ALLOCATE_CLIENT:
        FTrace.Add(Format('# trace G_BOT_ALLOCATE_CLIENT = %d', [Result]));
    end;
end;

function TCountingHost.Names: TArray<string>;
begin
  Result := FNames.Keys.ToArray;
  TArray.Sort<string>(Result);
end;

function TCountingHost.CountOf(const AName: string): Integer;
begin
  if not FNames.TryGetValue(AName, Result) then
    Result := 0;
end;

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
  LSettings.SavePath := TPath.Combine(TPath.GetTempPath, 'ddq3botreach');
  LSettings.GameBase := 'baseoa';
  LSettings.Game := AGame;
  LSettings.PakExtension := '.pk3';
  Result := TGameFileSystemFactory.CreateOnDisk(LSettings);
  Result.Startup;
end;

// SV_BotInitCvars: the variables of the bots with the values the server gives them
procedure RegisterBotCvars(const AConsole: TQ3Console);
const
  NAMES: array[0..30] of string = ('bot_enable', 'bot_developer', 'bot_debug', 'bot_maxdebugpolys',
    'bot_groundonly', 'bot_reachability', 'bot_visualizejumppads', 'bot_forceclustering', 'bot_forcereachability',
    'bot_forcewrite', 'bot_aasoptimize', 'bot_saveroutingcache', 'bot_thinktime', 'bot_reloadcharacters',
    'bot_testichat', 'bot_testrchat', 'bot_testsolid', 'bot_testclusters', 'bot_fastchat', 'bot_nochat', 'bot_pause',
    'bot_report', 'bot_grapple', 'bot_rocketjump', 'bot_challenge', 'bot_minplayers', 'bot_interbreedchar',
    'bot_interbreedbots', 'bot_interbreedcycle', 'bot_interbreedwrite', 'bot_memorydump');
  VALUES: array[0..30] of string = ('1', '0', '0', '2', '1', '0', '0', '0', '0', '0', '0', '0', '100', '0', '0', '0',
    '0', '0', '0', '0', '0', '0', '0', '1', '0', '0', '', '10', '20', '', '0');
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(NAMES) do
    AConsole.CVars.Get(AnsiString(NAMES[LIndex]), AnsiString(VALUES[LIndex]), 0);
end;

// the run: the text of the result lines, and the counts of the BOTLIB calls by name
procedure RunGame(const AFiles: IGameFileSystem; const AGame: string; const ALines: TStrings);
var
  LConsole: TQ3Console;
  LHost: IQ3SyscallHost;
  LCounting: TCountingHost;
  LKeeper: IQvmHost;
  LMachine: IQvmMachine;
  LClipMap: IQ3HostClipMap;
  LServices: TQ3HostServices;
  LData: TBytes;
  LMapBytes: TBytes;
  LState: TQ3HostServerState;
  LStateIntf: IQ3HostServerState;
  LServer: TQ3HostBotServer;
  LServerIntf: IInterface;
  LPrinted: TQ3RecordingConsole;
  LPrintedIntf: IQ3HostConsole;
  LStage, LResult, LName, LMessage: string;
  LFrame, LStart, LBotlib, LDistinct, LErrors: Integer;
  LText: string;
  LLimits: TQvmLimits;
begin
  // the info strings of the server (the missionpack game asks for the server info) are written by the net library
  LConsole := TQ3Console.Create(nil, nil, nil, TQ3ConsoleInfoWriter.Create);
  try
    LConsole.Init;
    LConsole.CVars.Get('sv_maxclients', '8', 0);
    LConsole.CVars.Get('mapname', MAP_NAME, 0);
    RegisterBotCvars(LConsole);
    // SV_SpawnServer: the checksum of the BSP is the one the .aas was made for
    Assert.IsTrue(AFiles.ReadFile('maps/' + MAP_NAME + '.bsp', LMapBytes), 'bsp');
    LConsole.CVars.Get('sv_mapChecksum', AnsiString(IntToStr(Integer(TIdMd4.BlockChecksum(LMapBytes[0],
      Length(LMapBytes))))), 0);
    LClipMap := TQ3HostClipMap.Create(TQ3HostMapLoader.Create(AFiles));
    LClipMap.Load('maps/' + MAP_NAME + '.bsp');
    LState := TQ3HostServerState.Create(LConsole.CVars);
    LStateIntf := LState;
    LServer := TQ3HostBotServer.Create(LState,
      procedure(const AMachine: IQvmMachine; AClient: Integer; const ACommand: AnsiString)
      begin
        // SV_ExecuteClientCommand: the line is tokenized and the game gets it
        LConsole.Arguments.Tokenize(ACommand);
        AMachine.Call(GAME_CLIENT_COMMAND, [AClient]);
      end);
    LServerIntf := LServer;
    LPrinted := TQ3RecordingConsole.Create(nil);
    LPrintedIntf := LPrinted;
    LServices := Default(TQ3HostServices);
    LServices.CVars := LConsole.CVars;
    LServices.Arguments := LConsole.Arguments;
    LServices.Buffer := LConsole.Buffer;
    LServices.Commands := LConsole.Commands;
    LServices.Files := TQ3GameHostFiles.Create(AFiles, nil);
    LServices.ClipMap := LClipMap;
    LServices.State := LStateIntf;
    LServices.ServerCommands := LServer;
    LServices.Calendar := TQ3FixedCalendar.Create;
    LServices.Bot.Files := TQ3BotFileSource.Create(AFiles);
    LServices.Bot.Server := LServer;
    LHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.Game, LPrintedIntf, TQ3FixedTime.Create(0), LServices);
    LCounting := TCountingHost.Create(LHost);
    LKeeper := LCounting;
    if GetEnvironmentVariable('DELPHIDOOM_Q3_BOTS_PRINT') <> '' then
      LCounting.Trace := LPrinted.Texts;
    Assert.IsTrue(AFiles.ReadFile('vm/qagame.qvm', LData), 'qagame');
    // OpenArena runs on ioquake3: a bot's qagame copies a literal that does not start on a dword
    LLimits := TQvmLimits.Default;
    LLimits.UnalignedBlockCopy := True;
    LMachine := TQvmFactory.CreateMachine('botreach', LData, LKeeper, LLimits);
    LStage := 'init';
    LResult := 'finished';
    try
      // GAME_INIT, a client that connects and begins, two bots, then the frames; BOTAI_START_FRAME comes before
      // GAME_RUN_FRAME as SV_Frame does it
      LMachine.Call(GAME_INIT, [1000, 12345, 0]);
      LStage := 'connect';
      LState.SetUserinfo(0, '\name\Tester\model\sarge\skill\3\rate\25000\cl_voip\0');
      LState.SetClientActive(0, True);
      LMachine.Call(GAME_CLIENT_CONNECT, [0, 1, 0]);
      LStage := 'begin';
      LMachine.Call(GAME_CLIENT_BEGIN, [0]);
      LStage := 'frames';
      for LFrame := 1 to FRAMES do
      begin
        LMachine.Call(BOTAI_START_FRAME, [1000 + 100 * LFrame]);
        LMachine.Call(GAME_RUN_FRAME, [1000 + 100 * LFrame]);
        // the game adds a bot only when the AAS is initialized, which the first frame finishes
        if LFrame = 1 then
        begin
          LStage := 'addbot';
          LCounting.Verbose := Assigned(LCounting.Trace);
          for LName in BOT_NAMES do
          begin
            LConsole.Arguments.Tokenize(AnsiString('addbot ' + LName + ' 3'));
            LMachine.Call(GAME_CONSOLE_COMMAND, []);
          end;
          LStage := 'frames';
        end;
      end;
    except
      on E: EQ3UnhandledSyscallException do
      begin
        LMessage := E.Message;
        LStart := Pos('System trap ', LMessage) + Length('System trap ');
        LResult := 'stop=' + Copy(LMessage, LStart, Pos(' (', LMessage) - LStart);
      end;
      on E: EQ3ModuleErrorException do
        LResult := 'error=' + Trim(E.Message);
      on E: Exception do
        LResult := 'exception=' + E.ClassName + ': ' + Trim(E.Message);
    end;
    // DELPHIDOOM_Q3_BOTS_PRINT: where the game and the library printed, for the one who reads the run
    if GetEnvironmentVariable('DELPHIDOOM_Q3_BOTS_PRINT') <> '' then
      for LName in LCounting.Names do
        LPrinted.Texts.Add(Format('# call %s %d', [LName, LCounting.CountOf(LName)]));
    if GetEnvironmentVariable('DELPHIDOOM_Q3_BOTS_PRINT') <> '' then
      LPrinted.Texts.SaveToFile(GetEnvironmentVariable('DELPHIDOOM_Q3_BOTS_PRINT') + '.' + AGame + '.txt');
    LBotlib := 0;
    LDistinct := 0;
    for LName in LCounting.Names do
      if LName.StartsWith('BOTLIB_') then
      begin
        Inc(LBotlib, LCounting.CountOf(LName));
        Inc(LDistinct);
      end;
    LErrors := 0;
    for LText in LPrinted.Texts do
      if LText.StartsWith('^1Error') or LText.StartsWith('^1Fatal') then
        Inc(LErrors);
    ALines.Add(Format('%s/qagame+bots total=%d botlib=%d distinct=%d frames=%d library_errors=%d %s in %s',
      [AGame, LCounting.Total, LBotlib, LDistinct, FRAMES, LErrors, LResult, LStage]));
    for LName in LCounting.Names do
      if LName.StartsWith('BOTLIB_') then
        ALines.Add(Format('%s %s %d', [AGame, LName, LCounting.CountOf(LName)]));
    // what the botlib printed that was an error, to see what stopped the bots
    for LText in LPrinted.Texts do
      if LText.StartsWith('^1Error') or LText.StartsWith('^1Fatal') then
        ALines.Add(Format('%s PRINT %s', [AGame, TrimRight(LText)]));
  finally
    LMachine := nil;
    LKeeper := nil;
    LHost := nil;
    LConsole.Free;
  end;
end;

procedure TTestQ3HostBotReach.QagameConIBotDovrebbeArrivareFinoInFondoComeIlGolden;
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
      RunGame(LFiles, LGame, LActual);
      LFiles.Shutdown;
    end;
    LOut := GetEnvironmentVariable('DELPHIDOOM_Q3_REACH_BOTS_OUT');
    if LOut <> '' then
      LActual.SaveToFile(LOut);
    TQvmScenarioRunner.Report(LActual[0] + ' | ' + LActual[LActual.Count - 1]);
    if TFile.Exists(TTestFiles.DataFile('Q3Host', 'reach.bots.golden.txt')) then
    begin
      LGolden := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'reach.bots.golden.txt'));
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

initialization
  TDUnitX.RegisterTestFixture(TTestQ3HostBotReach);

end.

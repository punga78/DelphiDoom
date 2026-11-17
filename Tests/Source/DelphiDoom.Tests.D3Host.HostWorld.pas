{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 host library - the fakes of the engine for  }
{  the keys, the edit field, usercmd, console and life cycle scenarios         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Host.HostWorld;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Text.CmdArgs,
  DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.D3Host.Types,
  DelphiDoom.D3Host.Intf, DelphiDoom.D3Host.Input.Types, DelphiDoom.D3Host.Input.Intf,
  DelphiDoom.D3Host.Lifecycle.Intf, DelphiDoom.D3Host.Lifecycle, DelphiDoom.Tests.D3Host.World;

type
  /// <summary>
  ///   The engine of the second parity harness (Tools\Verifica\255\harness_host.cpp) as objects that trace every
  ///   call with the same lines; the classes under test get its small interfaces
  /// </summary>
  THostWorld = class
  strict private
    FTrace: TStringList;
    FFailAt: string;
    FVars: TDictionary<string, string>;
    FModifiedFlags: Integer;
    FSimdModified: Boolean;
    FCommands: TList<TPair<string, TCmdFunction>>;
    FCmdNames: TArray<AnsiString>;
    FCVarNames: TArray<AnsiString>;
    FArgCompletions: TDictionary<string, TArray<AnsiString>>;
    FCVarArgCompletions: TDictionary<string, TArray<AnsiString>>;
    FKeyQueue: TList<TPair<Integer, Boolean>>;
    FMouseQueue: TList<TPair<Integer, Integer>>;
    FKeyBatch: TArray<TPair<Integer, Boolean>>;
    FMouseBatch: TArray<TPair<Integer, Integer>>;
    FInterfaces: TList<IInterface>;
  public
    Time: Integer;
    EventMs: Integer;
    Already: Boolean;
    StartupCmds: Boolean;
    SafeMode: Boolean;
    FpuEmpty: Boolean;
    SoundWorld: Boolean;
    SpecFile: Boolean;
    Net: Boolean;
    ConsoleKeyA: Integer;
    ConsoleKeyB: Integer;
    HasClipboard: Boolean;
    Clipboard: AnsiString;
    constructor Create;
    destructor Destroy; override;
    procedure Line(const AText: string);
    procedure Outs(const ATag: string; const AText: AnsiString);
    /// <summary>A trace point: "CALL name", and an ED3HostException if the scenario made it fail (name!: leaves the program)</summary>
    procedure Tr(const AName: string);
    /// <summary>Only the failure of a trace point, for the ones that print their own line</summary>
    procedure FailCheck(const AName: string);
    procedure SetFailAt(const AName: string);
    function GetVar(const AName: string): string;
    procedure SetVar(const AName, AValue: string);
    procedure SetModified;
    property Trace: TStringList read FTrace;
    property Vars: TDictionary<string, string> read FVars;
    property ModifiedFlags: Integer read FModifiedFlags write FModifiedFlags;
    property SimdModified: Boolean read FSimdModified write FSimdModified;
    property Commands: TList<TPair<string, TCmdFunction>> read FCommands;
    property CmdNames: TArray<AnsiString> read FCmdNames write FCmdNames;
    property CVarNames: TArray<AnsiString> read FCVarNames write FCVarNames;
    property ArgCompletions: TDictionary<string, TArray<AnsiString>> read FArgCompletions;
    property CVarArgCompletions: TDictionary<string, TArray<AnsiString>> read FCVarArgCompletions;
    property KeyQueue: TList<TPair<Integer, Boolean>> read FKeyQueue;
    property MouseQueue: TList<TPair<Integer, Integer>> read FMouseQueue;
    property KeyBatch: TArray<TPair<Integer, Boolean>> read FKeyBatch write FKeyBatch;
    property MouseBatch: TArray<TPair<Integer, Integer>> read FMouseBatch write FMouseBatch;
    /// <summary>Keeps an interface alive as long as the world</summary>
    procedure Keep(const AItem: IInterface);
    // the interfaces that the classes under test get
    function Subsystem(const AInitName, AShutdownName: string): ID3Subsystem;
    function Printer: ID3Printer;
    function Reporter: ID3ErrorReporter;
    function FatalSink: ID3FatalErrorSink;
    function Warnings: ID3WarningSink;
    function KeyText: ID3KeyText;
    function Clip: ID3Clipboard;
    function Debug: ID3DebugOutput;
    function ConsolePlatform: ID3ConsolePlatform;
    function EventClock: ID3EventClock;
    function Screen: ID3ScreenUpdater;
    function Devices: ID3InputDevices;
    function AsyncState: ID3AsyncState;
    function CVarServices: ID3CVarServices;
    function CVarValues: ID3CVarValues;
    function CommonCVars: ID3CommonCVars;
    function CommandsIntf: ICmdCommands;
    function Buffer: ICmdBuffer;
    function FilesIntf: ID3CommonFileSystem;
    function NewFile(const AName: string): ID3CommonFile;
    function Services: TD3LifecycleServices;
  end;

implementation

type
  TFake = class(TInterfacedObject)
  protected
    FWorld: THostWorld;
  public
    constructor Create(const AWorld: THostWorld);
  end;

  TFakeSubsystem = class(TFake, ID3Subsystem)
  strict private
    FInitName: string;
    FShutdownName: string;
  public
    constructor Create(const AWorld: THostWorld; const AInitName, AShutdownName: string);
    procedure Init;
    procedure Shutdown;
  end;

  TFakeReporter = class(TFake, ID3Printer, ID3ErrorReporter, ID3FatalErrorSink, ID3WarningSink)
  public
    procedure Printf(const AText: AnsiString);
    procedure DPrintf(const AText: AnsiString);
    procedure Error(const AText: AnsiString);
    procedure FatalError(const AText: AnsiString);
    procedure Warning(const AText: AnsiString);
  end;

  TFakeMisc = class(TFake, ID3KeyText, ID3Clipboard, ID3DebugOutput, ID3ConsolePlatform, ID3EventClock,
    ID3ScreenUpdater, ID3AsyncState)
  public
    function MapCharForKey(const AKey: Integer): AnsiChar;
    function LanguageString(const AId: AnsiString): AnsiString;
    function GetClipboardData(out AText: AnsiString): Boolean;
    procedure DebugPrintf(const AText: AnsiString);
    function GetConsoleKey(const AShifted: Boolean): Integer;
    procedure GrabMouseCursor(const AGrab: Boolean);
    function EventMilliseconds: Integer;
    procedure UpdateScreen(const AOutOfSequence: Boolean);
    function IsActive: Boolean;
  end;

  TFakeDevices = class(TFake, ID3InputDevices)
  public
    function PollKeyboardEvents: Integer;
    function ReturnKeyboardEvent(const AIndex: Integer; out AKey: Integer; out AState: Boolean): Boolean;
    procedure EndKeyboardEvents;
    function PollMouseEvents: Integer;
    function ReturnMouseEvent(const AIndex: Integer; out AAction: Integer; out AValue: Integer): Boolean;
    procedure EndMouseEvents;
  end;

  TFakeCVars = class(TFake, ID3CommonCVars, ID3CVarServices, ID3CVarValues)
  public
    function IsInitialized: Boolean;
    function GetCVarInteger(const AName: AnsiString): Integer;
    function GetCVarBool(const AName: AnsiString): Boolean;
    procedure SetCVarBool(const AName: AnsiString; const AValue: Boolean);
    procedure SetCVarString(const AName, AValue: AnsiString);
    procedure CommandCompletion(const ACallback: TCmdCompletionCallback);
    procedure ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
    procedure SetModifiedFlags(const AFlags: Integer);
    function GetModifiedFlags: Integer;
    procedure ClearModifiedFlags(const AFlags: Integer);
    procedure SetCVarInteger(const AName: AnsiString; const AValue: Integer);
    function GetCVarString(const AName: AnsiString): AnsiString;
    function GetFloat(const AName: AnsiString): Single;
    function GetInteger(const AName: AnsiString): Integer;
    function GetBool(const AName: AnsiString): Boolean;
  end;

  TFakeCommands = class(TFake, ICmdCommands, ICmdBuffer)
  public
    procedure AddCommand(const ACommandName: AnsiString; const AFunction: TCmdFunction; const AFlags: Integer;
      const ADescription: AnsiString); overload;
    procedure AddCommand(const ACommandName: AnsiString; const AFunction: TCmdFunction; const AFlags: Integer;
      const ADescription: AnsiString; const AArgCompletion: TCmdArgCompletion); overload;
    procedure RemoveCommand(const ACommandName: AnsiString);
    procedure RemoveFlaggedCommands(const AFlags: Integer);
    procedure CommandCompletion(const ACallback: TCmdCompletionCallback);
    procedure ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
    function Commands: TArray<TCmdInfo>;
    procedure BufferCommandText(const AExecution: TCmdExecution; const AText: AnsiString);
    procedure BufferCommandArgs(const AExecution: TCmdExecution; const AArgs: TIdCmdArgs);
    procedure ExecuteCommandBuffer;
    procedure SetWait(const AFrames: Integer);
    procedure SetupReloadEngine(const AArgs: TIdCmdArgs);
    function PostReloadEngine: Boolean;
  end;

  TFakeFile = class(TFake, ID3CommonFile)
  strict private
    FName: string;
  public
    constructor Create(const AWorld: THostWorld; const AName: string);
    function Write(const ABuffer; ACount: Integer): Integer;
    function Read(var ABuffer; ACount: Integer): Integer;
    procedure Flush;
    procedure ForceFlush;
    property Name: string read FName;
  end;

  TFakeFiles = class(TFake, ID3CommonFileSystem, ID3FileSystemSetup)
  public
    function IsInitialized: Boolean;
    function OpenFileWrite(const AName, APath: AnsiString): ID3CommonFile;
    function OpenFileRead(const AName: AnsiString): ID3CommonFile;
    procedure CloseFile(const AFile: ID3CommonFile);
    procedure Init;
    procedure Shutdown(const AReloading: Boolean);
    function OpenExplicitFileRead(const AOSPath: AnsiString): ID3CommonFile;
    function RelativePathToOSPath(const ARelativePath, ABasePath: AnsiString): AnsiString;
  end;

  TFakeSession = class(TFake, ID3SessionLifecycle)
  public
    procedure Init;
    procedure Shutdown;
    procedure Frame;
    procedure GuiFrameEvents;
    procedure StartMenu(const APlayIntro: Boolean);
    procedure WriteCDKey;
  end;

  TFakeSound = class(TFake, ID3SoundSystem)
  public
    procedure Init;
    procedure Shutdown;
    procedure ClearBuffer;
    function HasPlayingSoundWorld: Boolean;
    procedure StopAllSounds;
    procedure AsyncUpdate(const ATime: Integer);
    procedure AsyncUpdateWrite(const ATime: Integer);
  end;

  TFakeNet = class(TFake, ID3AsyncNetwork)
  public
    procedure Init;
    procedure Shutdown;
    procedure RunFrame;
    function IsActive: Boolean;
    function ServerDedicated: Integer;
    procedure KillServer;
    procedure ShutdownClient;
    procedure InitServerPort;
  end;

  TFakeEvents = class(TFake, ID3EventLoopControl)
  public
    procedure Init;
    procedure Shutdown;
    function RunEventLoop(const ACommandExecution: Boolean): Integer;
  end;

  TFakeSys = class(TFake, ID3SystemLifecycle)
  public
    procedure Init;
    procedure InitNetworking;
    function AlreadyRunning: Boolean;
    procedure Shutdown;
    procedure DoPreferences;
    procedure GenerateEvents;
    procedure EnterCriticalSection;
    procedure LeaveCriticalSection;
    function FPUStackIsEmpty: Boolean;
    function FPUState: AnsiString;
    procedure EnableLeakTest(const AName: AnsiString);
  end;

  TFakeSystem = class(TFake, ID3CommonSystem)
  public
    function Milliseconds: Integer;
    procedure Printf(const AText: AnsiString);
    procedure SetClipboardData(const AText: AnsiString);
    procedure SetFatalError(const AText: AnsiString);
    procedure Quit;
    procedure Error(const AText: AnsiString);
  end;

  TFakeCommandLine = class(TFake, ID3CommandLineControl)
  public
    procedure ParseCommandLine(const AArguments: TArray<AnsiString>);
    procedure ClearCommandLine;
    function SafeMode: Boolean;
    procedure CheckToolMode;
    procedure StartupVariable(const AMatch: AnsiString; const AOnce: Boolean);
    procedure StartupAllVariables(const AOnce: Boolean);
    function AddStartupCommands: Boolean;
  end;

  TFakeWarnings = class(TFake, ID3WarningControl, ID3LogFileControl)
  public
    procedure ClearWarnings(const AReason: AnsiString);
    procedure PrintWarnings;
    procedure ClearCaptionAndErrors;
    procedure CloseLogFile;
  end;

  TFakeSteps = class(TFake, ID3StartupSteps, ID3FrameSteps)
  public
    procedure InitSIMD;
    procedure RegisterStaticVars;
    procedure InitCommands;
    procedure InitLanguageDict;
    procedure InitRenderSystem;
    procedure LoadGameDLL;
    procedure UnloadGameDLL;
    procedure SetMachineSpec;
    procedure ExecMachineSpec;
    procedure PrintLoadingMessage(const AText: AnsiString);
    procedure WriteConfiguration;
    function IsSIMDModified: Boolean;
  end;

function AtoiText(const AText: string): Integer;
begin
  Result := TD3CNumbers.Atoi(AnsiString(AText));
end;

{ TFake }

constructor TFake.Create(const AWorld: THostWorld);
begin
  inherited Create;
  FWorld := AWorld;
end;

{ THostWorld }

constructor THostWorld.Create;
var
  LDefault: TD3CVarDefault;
begin
  inherited Create;
  FTrace := TStringList.Create;
  FVars := TDictionary<string, string>.Create;
  FCommands := TList<TPair<string, TCmdFunction>>.Create;
  FArgCompletions := TDictionary<string, TArray<AnsiString>>.Create;
  FCVarArgCompletions := TDictionary<string, TArray<AnsiString>>.Create;
  FKeyQueue := TList<TPair<Integer, Boolean>>.Create;
  FMouseQueue := TList<TPair<Integer, Integer>>.Create;
  FInterfaces := TList<IInterface>.Create;
  for LDefault in D3_USERCMD_CVARS do
    FVars.AddOrSetValue(string(LDefault.Name), string(LDefault.Value));
  FVars.AddOrSetValue('con_speed', '3');
  FVars.AddOrSetValue('com_forceGenericSIMD', '0');
  FVars.AddOrSetValue('com_speeds', '0');
  FVars.AddOrSetValue('com_asyncInput', '0');
  FVars.AddOrSetValue('com_asyncSound', '1');
  FVars.AddOrSetValue('com_preciseTic', '1');
  FVars.AddOrSetValue('timescale', '1');
  FVars.AddOrSetValue('net_serverDedicated', '0');
  FpuEmpty := True;
  ConsoleKeyA := 96;
  ConsoleKeyB := 126;
end;

destructor THostWorld.Destroy;
begin
  FInterfaces.Free;
  FMouseQueue.Free;
  FKeyQueue.Free;
  FCVarArgCompletions.Free;
  FArgCompletions.Free;
  FCommands.Free;
  FVars.Free;
  FTrace.Free;
  inherited Destroy;
end;

procedure THostWorld.Keep(const AItem: IInterface);
begin
  FInterfaces.Add(AItem);
end;

procedure THostWorld.Line(const AText: string);
begin
  FTrace.Add(AText);
end;

procedure THostWorld.Outs(const ATag: string; const AText: AnsiString);
begin
  FTrace.Add(ATag + ' ' + TD3Escape.Escape(AText));
end;

procedure THostWorld.Tr(const AName: string);
begin
  Outs('CALL', AnsiString(AName));
  FailCheck(AName);
end;

procedure THostWorld.FailCheck(const AName: string);
begin
  if FFailAt = AName then
    raise ED3HostException.Create('injected failure');
  if FFailAt = AName + '!' then
    raise ETestExit.CreateWhy('exit');
end;

procedure THostWorld.SetFailAt(const AName: string);
begin
  if AName = 'none' then
    FFailAt := ''
  else
    FFailAt := AName;
end;

function THostWorld.GetVar(const AName: string): string;
begin
  if not FVars.TryGetValue(AName, Result) then
    Result := '';
end;

procedure THostWorld.SetVar(const AName, AValue: string);
begin
  FVars.AddOrSetValue(AName, AValue);
  if AName = 'com_forceGenericSIMD' then
    FSimdModified := True;
end;

procedure THostWorld.SetModified;
begin
  FSimdModified := True;
end;

function THostWorld.Subsystem(const AInitName, AShutdownName: string): ID3Subsystem;
begin
  Result := TFakeSubsystem.Create(Self, AInitName, AShutdownName);
  Keep(Result);
end;

function THostWorld.Printer: ID3Printer;
begin
  Result := TFakeReporter.Create(Self);
  Keep(Result);
end;

function THostWorld.Reporter: ID3ErrorReporter;
begin
  Result := TFakeReporter.Create(Self);
  Keep(Result);
end;

function THostWorld.FatalSink: ID3FatalErrorSink;
begin
  Result := TFakeReporter.Create(Self);
  Keep(Result);
end;

function THostWorld.Warnings: ID3WarningSink;
begin
  Result := TFakeReporter.Create(Self);
  Keep(Result);
end;

function THostWorld.KeyText: ID3KeyText;
begin
  Result := TFakeMisc.Create(Self);
  Keep(Result);
end;

function THostWorld.Clip: ID3Clipboard;
begin
  Result := TFakeMisc.Create(Self);
  Keep(Result);
end;

function THostWorld.Debug: ID3DebugOutput;
begin
  Result := TFakeMisc.Create(Self);
  Keep(Result);
end;

function THostWorld.ConsolePlatform: ID3ConsolePlatform;
begin
  Result := TFakeMisc.Create(Self);
  Keep(Result);
end;

function THostWorld.EventClock: ID3EventClock;
begin
  Result := TFakeMisc.Create(Self);
  Keep(Result);
end;

function THostWorld.Screen: ID3ScreenUpdater;
begin
  Result := TFakeMisc.Create(Self);
  Keep(Result);
end;

function THostWorld.AsyncState: ID3AsyncState;
begin
  Result := TFakeMisc.Create(Self);
  Keep(Result);
end;

function THostWorld.Devices: ID3InputDevices;
begin
  Result := TFakeDevices.Create(Self);
  Keep(Result);
end;

function THostWorld.CVarServices: ID3CVarServices;
begin
  Result := TFakeCVars.Create(Self);
  Keep(Result);
end;

function THostWorld.CVarValues: ID3CVarValues;
begin
  Result := TFakeCVars.Create(Self);
  Keep(Result);
end;

function THostWorld.CommonCVars: ID3CommonCVars;
begin
  Result := TFakeCVars.Create(Self);
  Keep(Result);
end;

function THostWorld.CommandsIntf: ICmdCommands;
begin
  Result := TFakeCommands.Create(Self);
  Keep(Result);
end;

function THostWorld.Buffer: ICmdBuffer;
begin
  Result := TFakeCommands.Create(Self);
  Keep(Result);
end;

function THostWorld.FilesIntf: ID3CommonFileSystem;
begin
  Result := TFakeFiles.Create(Self);
  Keep(Result);
end;

function THostWorld.NewFile(const AName: string): ID3CommonFile;
begin
  Result := TFakeFile.Create(Self, AName);
  Keep(Result);
end;

function THostWorld.Services: TD3LifecycleServices;
var
  LFiles: TFakeFiles;
  LFilesRef: IInterface;
begin
  LFiles := TFakeFiles.Create(Self);
  LFilesRef := LFiles;
  Keep(LFilesRef);
  Result.IdLib := Subsystem('idlib.Init', 'idlib.ShutDown');
  Result.CmdSystem := Subsystem('cmd.Init', 'cmd.Shutdown');
  Result.CVarSystem := Subsystem('cvar.Init', 'cvar.Shutdown');
  Result.Decl := Subsystem('decl.Init', 'decl.Shutdown');
  Result.UI := Subsystem('ui.Init', 'ui.Shutdown');
  Result.Render := Subsystem('render.Init', 'render.Shutdown');
  Result.Session := TFakeSession.Create(Self);
  Keep(Result.Session);
  Result.Screen := Screen;
  Result.Sound := TFakeSound.Create(Self);
  Keep(Result.Sound);
  Result.Net := TFakeNet.Create(Self);
  Keep(Result.Net);
  Result.FileSetup := LFiles;
  Result.Files := LFiles;
  Result.Events := TFakeEvents.Create(Self);
  Keep(Result.Events);
  Result.Sys := TFakeSys.Create(Self);
  Keep(Result.Sys);
  Result.System := TFakeSystem.Create(Self);
  Keep(Result.System);
  Result.CVarServices := CVarServices;
  Result.CVarValues := CVarValues;
  Result.CommonCVars := CommonCVars;
  Result.Buffer := Buffer;
  Result.CommandLine := TFakeCommandLine.Create(Self);
  Keep(Result.CommandLine);
  Result.Warnings := TFakeWarnings.Create(Self);
  Keep(Result.Warnings);
  Result.LogFile := Result.Warnings as ID3LogFileControl;
  Result.Printer := Printer;
  Result.Errors := FatalSink;
  Result.Language := KeyText;
  Result.Startup := TFakeSteps.Create(Self);
  Keep(Result.Startup);
  Result.FrameSteps := Result.Startup as ID3FrameSteps;
end;

{ TFakeSubsystem }

constructor TFakeSubsystem.Create(const AWorld: THostWorld; const AInitName, AShutdownName: string);
begin
  inherited Create(AWorld);
  FInitName := AInitName;
  FShutdownName := AShutdownName;
end;

procedure TFakeSubsystem.Init;
begin
  FWorld.Tr(FInitName);
end;

procedure TFakeSubsystem.Shutdown;
begin
  FWorld.Tr(FShutdownName);
end;

{ TFakeReporter }

procedure TFakeReporter.Printf(const AText: AnsiString);
begin
  FWorld.Outs('PRINTF', AText);
end;

procedure TFakeReporter.DPrintf(const AText: AnsiString);
begin
  FWorld.Outs('DPRINTF', AText);
end;

procedure TFakeReporter.Error(const AText: AnsiString);
begin
  FWorld.Outs('ERROR', AText);
  raise ED3HostException.Create(string(AText));
end;

procedure TFakeReporter.FatalError(const AText: AnsiString);
begin
  FWorld.Outs('FATALERROR', AText);
  raise ETestExit.CreateWhy('fatal');
end;

procedure TFakeReporter.Warning(const AText: AnsiString);
begin
  FWorld.Outs('WARNING', AText);
end;

{ TFakeMisc }

function TFakeMisc.MapCharForKey(const AKey: Integer): AnsiChar;
begin
  Result := AnsiChar(Byte(AKey));
end;

function TFakeMisc.LanguageString(const AId: AnsiString): AnsiString;
begin
  Result := '<' + AId + '>';
end;

function TFakeMisc.GetClipboardData(out AText: AnsiString): Boolean;
begin
  Result := FWorld.HasClipboard;
  if Result then
    AText := FWorld.Clipboard
  else
    AText := '';
end;

procedure TFakeMisc.DebugPrintf(const AText: AnsiString);
begin
  FWorld.Outs('DEBUGPRINT', AText);
end;

function TFakeMisc.GetConsoleKey(const AShifted: Boolean): Integer;
begin
  if AShifted then
    Result := FWorld.ConsoleKeyB
  else
    Result := FWorld.ConsoleKeyA;
end;

procedure TFakeMisc.GrabMouseCursor(const AGrab: Boolean);
begin
  FWorld.Line('SYS grabmouse ' + IntToStr(Ord(AGrab)));
end;

function TFakeMisc.EventMilliseconds: Integer;
begin
  Result := FWorld.EventMs;
end;

procedure TFakeMisc.UpdateScreen(const AOutOfSequence: Boolean);
begin
  FWorld.Line('SESSION update ' + IntToStr(Ord(AOutOfSequence)));
end;

function TFakeMisc.IsActive: Boolean;
begin
  Result := FWorld.Net;
end;

{ TFakeDevices }

function TFakeDevices.PollKeyboardEvents: Integer;
begin
  FWorld.KeyBatch := FWorld.KeyQueue.ToArray;
  FWorld.KeyQueue.Clear;
  Result := Length(FWorld.KeyBatch);
end;

function TFakeDevices.ReturnKeyboardEvent(const AIndex: Integer; out AKey: Integer; out AState: Boolean): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Length(FWorld.KeyBatch));
  if Result then
  begin
    AKey := FWorld.KeyBatch[AIndex].Key;
    AState := FWorld.KeyBatch[AIndex].Value;
  end;
end;

procedure TFakeDevices.EndKeyboardEvents;
begin
  FWorld.KeyBatch := nil;
end;

function TFakeDevices.PollMouseEvents: Integer;
begin
  FWorld.MouseBatch := FWorld.MouseQueue.ToArray;
  FWorld.MouseQueue.Clear;
  Result := Length(FWorld.MouseBatch);
end;

function TFakeDevices.ReturnMouseEvent(const AIndex: Integer; out AAction: Integer; out AValue: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Length(FWorld.MouseBatch));
  if Result then
  begin
    AAction := FWorld.MouseBatch[AIndex].Key;
    AValue := FWorld.MouseBatch[AIndex].Value;
  end;
end;

procedure TFakeDevices.EndMouseEvents;
begin
  FWorld.MouseBatch := nil;
end;

{ TFakeCVars }

function TFakeCVars.IsInitialized: Boolean;
begin
  Result := True;
end;

function TFakeCVars.GetCVarString(const AName: AnsiString): AnsiString;
begin
  Result := AnsiString(FWorld.GetVar(string(AName)));
end;

function TFakeCVars.GetCVarInteger(const AName: AnsiString): Integer;
begin
  Result := TD3CNumbers.Atoi(GetCVarString(AName));
end;

function TFakeCVars.GetCVarBool(const AName: AnsiString): Boolean;
begin
  Result := GetCVarInteger(AName) <> 0;
end;

procedure TFakeCVars.SetCVarString(const AName, AValue: AnsiString);
begin
  FWorld.Outs('CVARSET', AName + ' ' + AValue);
  FWorld.SetVar(string(AName), string(AValue));
end;

procedure TFakeCVars.SetCVarBool(const AName: AnsiString; const AValue: Boolean);
begin
  FWorld.Line('CVARSETB ' + string(AName) + ' ' + IntToStr(Ord(AValue)));
  FWorld.SetVar(string(AName), IntToStr(Ord(AValue)));
end;

procedure TFakeCVars.SetCVarInteger(const AName: AnsiString; const AValue: Integer);
begin
  FWorld.Line('CVARSETI ' + string(AName) + ' ' + IntToStr(AValue));
  FWorld.SetVar(string(AName), IntToStr(AValue));
end;

procedure TFakeCVars.CommandCompletion(const ACallback: TCmdCompletionCallback);
var
  LName: AnsiString;
begin
  for LName in FWorld.CVarNames do
    ACallback(LName);
end;

procedure TFakeCVars.ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
var
  LArgs: TIdCmdArgs;
  LValues: TArray<AnsiString>;
  LValue: AnsiString;
begin
  LArgs := TIdCmdArgs.Create;
  try
    LArgs.TokenizeString(ACommandString, False);
    if FWorld.CVarArgCompletions.TryGetValue(string(LArgs.Argv(0)), LValues) then
      for LValue in LValues do
        ACallback(LValue);
  finally
    LArgs.Free;
  end;
end;

procedure TFakeCVars.SetModifiedFlags(const AFlags: Integer);
begin
  FWorld.ModifiedFlags := FWorld.ModifiedFlags or AFlags;
  FWorld.Line('MODFLAGS set ' + IntToStr(AFlags));
end;

function TFakeCVars.GetModifiedFlags: Integer;
begin
  Result := FWorld.ModifiedFlags;
end;

procedure TFakeCVars.ClearModifiedFlags(const AFlags: Integer);
begin
  FWorld.ModifiedFlags := FWorld.ModifiedFlags and (not AFlags);
  FWorld.Line('MODFLAGS clear ' + IntToStr(AFlags));
end;

function TFakeCVars.GetFloat(const AName: AnsiString): Single;
begin
  Result := TD3CNumbers.Atof(GetCVarString(AName));
end;

function TFakeCVars.GetInteger(const AName: AnsiString): Integer;
begin
  Result := GetCVarInteger(AName);
end;

function TFakeCVars.GetBool(const AName: AnsiString): Boolean;
begin
  Result := GetCVarInteger(AName) <> 0;
end;

{ TFakeCommands }

procedure TFakeCommands.AddCommand(const ACommandName: AnsiString; const AFunction: TCmdFunction;
  const AFlags: Integer; const ADescription: AnsiString);
var
  LIndex: Integer;
begin
  FWorld.Line('ADDCMD ' + string(ACommandName) + ' ' + IntToStr(AFlags));
  for LIndex := 0 to FWorld.Commands.Count - 1 do
    if FWorld.Commands[LIndex].Key = string(ACommandName) then
      Exit;
  FWorld.Commands.Add(TPair<string, TCmdFunction>.Create(string(ACommandName), AFunction));
end;

procedure TFakeCommands.AddCommand(const ACommandName: AnsiString; const AFunction: TCmdFunction;
  const AFlags: Integer; const ADescription: AnsiString; const AArgCompletion: TCmdArgCompletion);
begin
  AddCommand(ACommandName, AFunction, AFlags, ADescription);
end;

procedure TFakeCommands.RemoveCommand(const ACommandName: AnsiString);
var
  LIndex: Integer;
begin
  FWorld.Line('RMCMD ' + string(ACommandName));
  for LIndex := 0 to FWorld.Commands.Count - 1 do
    if FWorld.Commands[LIndex].Key = string(ACommandName) then
    begin
      FWorld.Commands.Delete(LIndex);
      Exit;
    end;
end;

procedure TFakeCommands.RemoveFlaggedCommands(const AFlags: Integer);
begin
end;

procedure TFakeCommands.CommandCompletion(const ACallback: TCmdCompletionCallback);
var
  LName: AnsiString;
begin
  for LName in FWorld.CmdNames do
    ACallback(LName);
end;

procedure TFakeCommands.ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
var
  LArgs: TIdCmdArgs;
  LValues: TArray<AnsiString>;
  LValue: AnsiString;
begin
  LArgs := TIdCmdArgs.Create;
  try
    LArgs.TokenizeString(ACommandString, False);
    if FWorld.ArgCompletions.TryGetValue(string(LArgs.Argv(0)), LValues) then
      for LValue in LValues do
        ACallback(LValue);
  finally
    LArgs.Free;
  end;
end;

function TFakeCommands.Commands: TArray<TCmdInfo>;
begin
  Result := nil;
end;

procedure TFakeCommands.BufferCommandText(const AExecution: TCmdExecution; const AText: AnsiString);
const
  Names: array[TCmdExecution] of string = ('now', 'insert', 'append');
begin
  FWorld.Outs('BUFTEXT ' + Names[AExecution], AText);
end;

procedure TFakeCommands.BufferCommandArgs(const AExecution: TCmdExecution; const AArgs: TIdCmdArgs);
begin
end;

procedure TFakeCommands.ExecuteCommandBuffer;
begin
  FWorld.Line('BUFEXEC');
end;

procedure TFakeCommands.SetWait(const AFrames: Integer);
begin
end;

procedure TFakeCommands.SetupReloadEngine(const AArgs: TIdCmdArgs);
begin
end;

function TFakeCommands.PostReloadEngine: Boolean;
begin
  Result := False;
end;

{ TFakeFile }

constructor TFakeFile.Create(const AWorld: THostWorld; const AName: string);
begin
  inherited Create(AWorld);
  FName := AName;
end;

function TFakeFile.Write(const ABuffer; ACount: Integer): Integer;
var
  LText: AnsiString;
begin
  SetLength(LText, ACount);
  if ACount > 0 then
    Move(ABuffer, LText[1], ACount);
  FWorld.Outs('FW ' + FName, LText);
  Result := ACount;
end;

function TFakeFile.Read(var ABuffer; ACount: Integer): Integer;
begin
  Result := 0;
end;

procedure TFakeFile.Flush;
begin
end;

procedure TFakeFile.ForceFlush;
begin
end;

{ TFakeFiles }

function TFakeFiles.IsInitialized: Boolean;
begin
  Result := True;
end;

function TFakeFiles.OpenFileWrite(const AName, APath: AnsiString): ID3CommonFile;
begin
  FWorld.Line('OPENW ' + string(AName) + ' ' + string(APath));
  Result := FWorld.NewFile(string(AName));
end;

function TFakeFiles.OpenFileRead(const AName: AnsiString): ID3CommonFile;
begin
  Result := nil;
end;

procedure TFakeFiles.CloseFile(const AFile: ID3CommonFile);
begin
  if Assigned(AFile) then
    FWorld.Line('CLOSE ' + (AFile as TObject as TFakeFile).Name)
  else
    FWorld.Line('CLOSE (null)');
end;

procedure TFakeFiles.Init;
begin
  FWorld.Tr('files.Init');
end;

procedure TFakeFiles.Shutdown(const AReloading: Boolean);
begin
  FWorld.Line('CALL files.Shutdown ' + IntToStr(Ord(AReloading)));
  FWorld.FailCheck('files.Shutdown');
end;

function TFakeFiles.OpenExplicitFileRead(const AOSPath: AnsiString): ID3CommonFile;
begin
  if not FWorld.SpecFile then
  begin
    FWorld.Line('OPENX ' + string(AOSPath) + ' fail');
    Exit(nil);
  end;
  FWorld.Line('OPENX ' + string(AOSPath) + ' ok');
  Result := FWorld.NewFile(string(AOSPath));
end;

function TFakeFiles.RelativePathToOSPath(const ARelativePath, ABasePath: AnsiString): AnsiString;
begin
  Result := 'OS:' + ABasePath + '/' + ARelativePath;
end;

{ TFakeSession }

procedure TFakeSession.Init;
begin
  FWorld.Tr('session.Init');
end;

procedure TFakeSession.Shutdown;
begin
  FWorld.Tr('session.Shutdown');
end;

procedure TFakeSession.Frame;
begin
  FWorld.Tr('session.Frame');
end;

procedure TFakeSession.GuiFrameEvents;
begin
  FWorld.Line('SESSION guiframeevents');
end;

procedure TFakeSession.StartMenu(const APlayIntro: Boolean);
begin
  FWorld.Line('SESSION startmenu ' + IntToStr(Ord(APlayIntro)));
end;

procedure TFakeSession.WriteCDKey;
begin
  FWorld.Line('SESSION writecdkey');
end;

{ TFakeSound }

procedure TFakeSound.Init;
begin
  FWorld.Tr('sound.Init');
end;

procedure TFakeSound.Shutdown;
begin
  FWorld.Tr('sound.Shutdown');
end;

procedure TFakeSound.ClearBuffer;
begin
  FWorld.Line('SOUND clearbuffer');
end;

function TFakeSound.HasPlayingSoundWorld: Boolean;
begin
  Result := FWorld.SoundWorld;
end;

procedure TFakeSound.StopAllSounds;
begin
  FWorld.Line('SOUND stopall');
end;

procedure TFakeSound.AsyncUpdate(const ATime: Integer);
begin
  FWorld.Line('SOUND asyncupdate ' + IntToStr(ATime));
end;

procedure TFakeSound.AsyncUpdateWrite(const ATime: Integer);
begin
  FWorld.Line('SOUND asyncupdatewrite ' + IntToStr(ATime));
end;

{ TFakeNet }

procedure TFakeNet.Init;
begin
  FWorld.Tr('net.Init');
end;

procedure TFakeNet.Shutdown;
begin
  FWorld.Tr('net.Shutdown');
end;

procedure TFakeNet.RunFrame;
begin
  FWorld.Line('NET RunFrame');
end;

function TFakeNet.IsActive: Boolean;
begin
  Result := FWorld.Net;
end;

function TFakeNet.ServerDedicated: Integer;
begin
  Result := AtoiText(FWorld.GetVar('net_serverDedicated'));
end;

procedure TFakeNet.KillServer;
begin
  FWorld.Line('NET server.Kill');
end;

procedure TFakeNet.ShutdownClient;
begin
  FWorld.Line('NET client.Shutdown');
end;

procedure TFakeNet.InitServerPort;
begin
  FWorld.Line('NET server.InitPort');
end;

{ TFakeEvents }

procedure TFakeEvents.Init;
begin
  FWorld.Tr('events.Init');
end;

procedure TFakeEvents.Shutdown;
begin
  FWorld.Tr('events.Shutdown');
end;

function TFakeEvents.RunEventLoop(const ACommandExecution: Boolean): Integer;
begin
  FWorld.Line('EVENTS run ' + IntToStr(Ord(ACommandExecution)));
  Result := 0;
end;

{ TFakeSys }

procedure TFakeSys.Init;
begin
  FWorld.Tr('sys.Init');
end;

procedure TFakeSys.InitNetworking;
begin
  FWorld.Tr('sys.InitNetworking');
end;

function TFakeSys.AlreadyRunning: Boolean;
begin
  FWorld.Line('SYS AlreadyRunning ' + IntToStr(Ord(FWorld.Already)));
  Result := FWorld.Already;
end;

procedure TFakeSys.Shutdown;
begin
  FWorld.Tr('sys.Shutdown');
end;

procedure TFakeSys.DoPreferences;
begin
  FWorld.Tr('sys.DoPreferences');
end;

procedure TFakeSys.GenerateEvents;
begin
  FWorld.Tr('sys.GenerateEvents');
end;

procedure TFakeSys.EnterCriticalSection;
begin
  FWorld.Line('SYS enter');
end;

procedure TFakeSys.LeaveCriticalSection;
begin
  FWorld.Line('SYS leave');
end;

function TFakeSys.FPUStackIsEmpty: Boolean;
begin
  Result := FWorld.FpuEmpty;
end;

function TFakeSys.FPUState: AnsiString;
begin
  Result := 'FPU state' + #10;
end;

procedure TFakeSys.EnableLeakTest(const AName: AnsiString);
begin
  FWorld.Outs('MEMLEAKTEST', AName);
end;

{ TFakeSystem }

function TFakeSystem.Milliseconds: Integer;
begin
  Result := FWorld.Time;
end;

procedure TFakeSystem.Printf(const AText: AnsiString);
begin
end;

procedure TFakeSystem.SetClipboardData(const AText: AnsiString);
begin
end;

procedure TFakeSystem.SetFatalError(const AText: AnsiString);
begin
end;

procedure TFakeSystem.Quit;
begin
  FWorld.Line('SYSQUIT');
  raise ETestExit.CreateWhy('quit');
end;

procedure TFakeSystem.Error(const AText: AnsiString);
begin
  FWorld.Outs('SYSERR', AText);
  raise ETestExit.CreateWhy('error');
end;

{ TFakeCommandLine }

procedure TFakeCommandLine.ParseCommandLine(const AArguments: TArray<AnsiString>);
var
  LText: AnsiString;
  LIndex: Integer;
begin
  LText := '';
  for LIndex := 0 to High(AArguments) do
  begin
    if LIndex > 0 then
      LText := LText + '|';
    LText := LText + AArguments[LIndex];
  end;
  FWorld.Outs('CALL ParseCommandLine', LText);
end;

procedure TFakeCommandLine.ClearCommandLine;
begin
  FWorld.Tr('ClearCommandLine');
end;

function TFakeCommandLine.SafeMode: Boolean;
begin
  FWorld.Line('CALL SafeMode -> ' + IntToStr(Ord(FWorld.SafeMode)));
  Result := FWorld.SafeMode;
end;

procedure TFakeCommandLine.CheckToolMode;
begin
  FWorld.Tr('CheckToolMode');
end;

procedure TFakeCommandLine.StartupVariable(const AMatch: AnsiString; const AOnce: Boolean);
begin
  FWorld.Line('STARTUPVAR ' + string(AMatch) + ' ' + IntToStr(Ord(AOnce)));
end;

procedure TFakeCommandLine.StartupAllVariables(const AOnce: Boolean);
begin
  FWorld.Line('STARTUPVAR (null) ' + IntToStr(Ord(AOnce)));
end;

function TFakeCommandLine.AddStartupCommands: Boolean;
begin
  FWorld.Line('CALL AddStartupCommands -> ' + IntToStr(Ord(FWorld.StartupCmds)));
  Result := FWorld.StartupCmds;
end;

{ TFakeWarnings }

procedure TFakeWarnings.ClearWarnings(const AReason: AnsiString);
begin
  FWorld.Outs('CALL ClearWarnings', AReason);
end;

procedure TFakeWarnings.PrintWarnings;
begin
  FWorld.Tr('PrintWarnings');
end;

procedure TFakeWarnings.ClearCaptionAndErrors;
begin
end;

procedure TFakeWarnings.CloseLogFile;
begin
  FWorld.Tr('CloseLogFile');
end;

{ TFakeSteps }

procedure TFakeSteps.InitSIMD;
begin
  FWorld.Tr('InitSIMD');
  FWorld.SimdModified := False;
end;

procedure TFakeSteps.RegisterStaticVars;
begin
  FWorld.Tr('cvar.RegisterStaticVars');
end;

procedure TFakeSteps.InitCommands;
begin
  FWorld.Tr('InitCommands');
end;

procedure TFakeSteps.InitLanguageDict;
begin
  FWorld.Tr('InitLanguageDict');
end;

procedure TFakeSteps.InitRenderSystem;
begin
  FWorld.Tr('InitRenderSystem');
end;

procedure TFakeSteps.LoadGameDLL;
begin
  FWorld.Tr('LoadGameDLL');
end;

procedure TFakeSteps.UnloadGameDLL;
begin
  FWorld.Tr('UnloadGameDLL');
end;

procedure TFakeSteps.SetMachineSpec;
begin
  FWorld.Tr('SetMachineSpec');
end;

procedure TFakeSteps.ExecMachineSpec;
begin
  FWorld.Tr('Com_ExecMachineSpec_f');
end;

procedure TFakeSteps.PrintLoadingMessage(const AText: AnsiString);
begin
  FWorld.Outs('CALL PrintLoadingMessage', AText);
end;

procedure TFakeSteps.WriteConfiguration;
begin
  FWorld.Tr('WriteConfiguration');
end;

function TFakeSteps.IsSIMDModified: Boolean;
begin
  Result := FWorld.SimdModified;
end;

end.

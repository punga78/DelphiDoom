{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - the life cycle of idCommon                }
{                                                                              }
{  Port of Doom 3 (id Software): framework\Common.cpp (idCommonLocal::Init,    }
{  Shutdown, InitGame, ShutdownGame, Frame, GUIFrame, SingleAsyncTic, Async,   }
{  Quit): the order in which the systems are started, run and stopped.         }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.Lifecycle;

interface

uses
  System.SysUtils, DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Intf,
  DelphiDoom.D3Host.Input.Intf, DelphiDoom.D3Host.Lifecycle.Intf;

type
  /// <summary>Every system that the life cycle drives, as small interfaces</summary>
  TD3LifecycleServices = record
    IdLib: ID3Subsystem;
    CmdSystem: ID3Subsystem;
    CVarSystem: ID3Subsystem;
    Decl: ID3Subsystem;
    UI: ID3Subsystem;
    Render: ID3Subsystem;
    Keys: ID3Subsystem;
    Console: ID3ConsoleControl;
    Usercmd: ID3UsercmdGenerator;
    Session: ID3SessionLifecycle;
    Screen: ID3ScreenUpdater;
    Sound: ID3SoundSystem;
    Net: ID3AsyncNetwork;
    FileSetup: ID3FileSystemSetup;
    Files: ID3CommonFileSystem;
    Events: ID3EventLoopControl;
    Sys: ID3SystemLifecycle;
    System: ID3CommonSystem;
    CVarServices: ID3CVarServices;
    CVarValues: ID3CVarValues;
    CommonCVars: ID3CommonCVars;
    Buffer: ICmdBuffer;
    CommandLine: ID3CommandLineControl;
    Warnings: ID3WarningControl;
    LogFile: ID3LogFileControl;
    Printer: ID3Printer;
    Errors: ID3FatalErrorSink;
    Language: ID3KeyText;
    Startup: ID3StartupSteps;
    FrameSteps: ID3FrameSteps;
  end;

  /// <summary>
  ///   The life cycle of idCommonLocal: Init and Shutdown start and stop the systems in the order of the original,
  ///   InitGame and ShutdownGame the ones that a restart of the game reloads, Frame runs a frame, Async and
  ///   SingleAsyncTic the 60 Hz tics. The tic and frame numbers are in TD3CommonState; the "async stats" ring of
  ///   the original is kept (1024 tics) and readable. Config files are the ones of Doom 3 (config.spec,
  ///   DoomConfig.cfg). An exception that is a drop (ED3HostException) ends Init with Sys_Error and Frame quietly;
  ///   a fatal error does not return.
  /// </summary>
  TD3Lifecycle = class(TInterfacedObject, ID3CommonLifecycle)
  strict private
    type
      TAsyncStat = record
        Milliseconds: Integer;
        DeltaMsec: Integer;
        TimeConsumed: Integer;
      end;
    const
      MaxAsyncStats = 1024;
    var
      FState: TD3CommonState;
      FServices: TD3LifecycleServices;
      FGameName: AnsiString;
      FVersion: AnsiString;
      FFullyInitialized: Boolean;
      FShuttingDown: Boolean;
      FLastTicMsec: Integer;
      FLastFrameTime: Integer;
      FAsyncStats: array[0..MaxAsyncStats - 1] of TAsyncStat;
    procedure LoadingMessage(const AId: AnsiString);
  public
    constructor Create(const AState: TD3CommonState; const AServices: TD3LifecycleServices;
      const AGameName, AVersion: AnsiString);
    /// <summary>
    ///   idCommonLocal::Init: the arguments without the program name (or, with ACommandLine, the tokens of that text)
    ///   start idLib, the command line, the cmd and cvar systems, the keys, the console, the system, InitGame and the
    ///   startup commands (or the menu); any drop ends in Sys_Error
    /// </summary>
    procedure Init(const AArguments: TArray<AnsiString>; const ACommandLine: AnsiString = '';
      const AHasCommandLine: Boolean = False);
    /// <summary>idCommonLocal::Shutdown (also the Shutdown of ID3CommonLifecycle that Error calls)</summary>
    procedure Shutdown;
    /// <summary>idCommonLocal::Quit: Shutdown unless inside an error, then Sys_Quit</summary>
    procedure Quit;
    procedure InitGame;
    procedure ShutdownGame(const AReloading: Boolean);
    /// <summary>idCommonLocal::Frame: events, the configuration, the event loop, the session, the screen; a drop is swallowed</summary>
    procedure Frame;
    /// <summary>idCommonLocal::GUIFrame: a frame for a menu or a loading screen</summary>
    procedure GUIFrame(const AExecCmd, ANetwork: Boolean);
    /// <summary>idCommonLocal::SingleAsyncTic: input and sound of one tic, then com_ticNumber + 1</summary>
    procedure SingleAsyncTic;
    /// <summary>idCommonLocal::Async: the tics that are due (a single one without com_preciseTic), at most 10 behind</summary>
    procedure Async;
    function IsInitialized: Boolean;
    function ShuttingDown: Boolean;
    function LastTicMsec: Integer;
    function AsyncMilliseconds(const ATic: Integer): Integer;
    function AsyncDelta(const ATic: Integer): Integer;
    function AsyncConsumed(const ATic: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CmdSystem.Types, DelphiDoom.D3Host.Input.Types;

const
  CONFIG_SPEC = 'config.spec';
  CONFIG_FILE = 'DoomConfig.cfg';
  CVAR_ARCHIVE_FLAG = 64;
  SInitError = 'Error during initialization';
  SFpuMessage = 'idCommon::Frame: the FPU stack is not empty at the end of the frame' + #10;
  SSavePath = 'fs_savepath';

constructor TD3Lifecycle.Create(const AState: TD3CommonState; const AServices: TD3LifecycleServices;
  const AGameName, AVersion: AnsiString);
begin
  inherited Create;
  FState := AState;
  FServices := AServices;
  FGameName := AGameName;
  FVersion := AVersion;
end;

procedure TD3Lifecycle.LoadingMessage(const AId: AnsiString);
begin
  FServices.Startup.PrintLoadingMessage(FServices.Language.LanguageString(AId));
end;

procedure TD3Lifecycle.Init(const AArguments: TArray<AnsiString>; const ACommandLine: AnsiString;
  const AHasCommandLine: Boolean);
var
  LArguments: TArray<AnsiString>;
  LArgs: TIdCmdArgs;
  LIndex: Integer;
begin
  try
    // initialize idLib
    FServices.IdLib.Init;
    // clear warning buffer
    FServices.Warnings.ClearWarnings(FGameName + ' initialization');
    // parse command line options
    LArguments := AArguments;
    if AHasCommandLine then
    begin
      // tokenize if the OS doesn't do it for us
      LArgs := TIdCmdArgs.Create;
      try
        LArgs.TokenizeString(ACommandLine, True);
        SetLength(LArguments, LArgs.Argc);
        for LIndex := 0 to LArgs.Argc - 1 do
          LArguments[LIndex] := LArgs.Argv(LIndex);
      finally
        LArgs.Free;
      end;
    end;
    FServices.CommandLine.ParseCommandLine(LArguments);
    // init console command system
    FServices.CmdSystem.Init;
    // init CVar system
    FServices.CVarSystem.Init;
    // start file logging right away, before early console or whatever
    FServices.CommandLine.StartupVariable('win_outputDebugString', False);
    // register all static CVars
    FServices.Startup.RegisterStaticVars;
    // print engine version
    FServices.Printer.Printf(FVersion + #10);
    // initialize key input/binding, done early so bind command exists
    FServices.Keys.Init;
    // init the console so we can take prints
    FServices.Console.Init;
    // get architecture info
    FServices.Sys.Init;
    // initialize networking
    FServices.Sys.InitNetworking;
    // override cvars from command line
    FServices.CommandLine.StartupAllVariables(False);
    if (FServices.Net.ServerDedicated = 0) and FServices.Sys.AlreadyRunning then
      FServices.System.Quit;
    // initialize processor specific SIMD implementation
    FServices.Startup.InitSIMD;
    // init commands
    FServices.Startup.InitCommands;
    // game specific initialization
    InitGame;
    if not FServices.CommandLine.AddStartupCommands then
      // if the user didn't give any commands, run default action
      FServices.Session.StartMenu(True);
    FServices.Printer.Printf('--- Common Initialization Complete ---' + #10);
    // print all warnings queued during initialization
    FServices.Warnings.PrintWarnings;
    // remove any prints from the notify lines
    FServices.Console.ClearNotifyLines;
    FServices.CommandLine.ClearCommandLine;
    FFullyInitialized := True;
  except
    on ED3HostException do
      FServices.System.Error(SInitError);
  end;
end;

procedure TD3Lifecycle.Shutdown;
begin
  FShuttingDown := True;
  FServices.Net.KillServer;
  FServices.Net.ShutdownClient;
  // game specific shut down
  ShutdownGame(False);
  // shut down non-portable system services
  FServices.Sys.Shutdown;
  // shut down the console
  FServices.Console.Shutdown;
  // shut down the key system
  FServices.Keys.Shutdown;
  // shut down the cvar system
  FServices.CVarSystem.Shutdown;
  // shut down the console command system
  FServices.CmdSystem.Shutdown;
  // free any buffered warning messages
  FServices.Warnings.ClearWarnings(FGameName + ' shutdown');
  FServices.Warnings.ClearCaptionAndErrors;
  // enable leak test
  FServices.Sys.EnableLeakTest('doom');
  // shutdown idLib
  FServices.IdLib.Shutdown;
end;

procedure TD3Lifecycle.Quit;
begin
  // don't try to shutdown if we are in a recursive error
  if FState.ErrorEntered = 0 then
    Shutdown;
  FServices.System.Quit;
end;

procedure TD3Lifecycle.InitGame;
var
  LFile: ID3CommonFile;
  LSysDetect: Boolean;
begin
  // initialize the file system
  FServices.FileSetup.Init;
  // initialize the declaration manager
  FServices.Decl.Init;
  // force r_fullscreen 0 if running a tool
  FServices.CommandLine.CheckToolMode;
  LFile := FServices.FileSetup.OpenExplicitFileRead(FServices.FileSetup.RelativePathToOSPath(CONFIG_SPEC, SSavePath));
  LSysDetect := not Assigned(LFile);
  if Assigned(LFile) then
    FServices.Files.CloseFile(LFile)
  else
  begin
    LFile := FServices.Files.OpenFileWrite(CONFIG_SPEC, SSavePath);
    FServices.Files.CloseFile(LFile);
  end;
  if LSysDetect then
  begin
    FServices.Startup.SetMachineSpec;
    FServices.Startup.ExecMachineSpec;
  end;
  // initialize the renderSystem data structures, but don't start OpenGL yet
  FServices.Render.Init;
  // initialize string database right off so we can use it for loading messages
  FServices.Startup.InitLanguageDict;
  LoadingMessage('#str_04344');
  // init journalling, etc
  FServices.Events.Init;
  LoadingMessage('#str_04345');
  // exec the startup scripts
  FServices.Buffer.BufferCommandText(ceAppend, 'exec editor.cfg' + #10);
  FServices.Buffer.BufferCommandText(ceAppend, 'exec default.cfg' + #10);
  // skip the config file if "safe" is on the command line
  if not FServices.CommandLine.SafeMode then
    FServices.Buffer.BufferCommandText(ceAppend, 'exec ' + CONFIG_FILE + #10);
  FServices.Buffer.BufferCommandText(ceAppend, 'exec autoexec.cfg' + #10);
  // reload the language dictionary now that we've loaded config files
  FServices.Buffer.BufferCommandText(ceAppend, 'reloadLanguage' + #10);
  // run cfg execution
  FServices.Buffer.ExecuteCommandBuffer;
  // re-override anything from the config files with command line args
  FServices.CommandLine.StartupAllVariables(False);
  // if any archived cvars are modified after this, we will trigger a writing of the config file
  FServices.CVarServices.ClearModifiedFlags(CVAR_ARCHIVE_FLAG);
  // cvars are initialized, but not the rendering system. Allow preference startup dialog
  FServices.Sys.DoPreferences;
  // init the user command input code
  FServices.Usercmd.Init;
  LoadingMessage('#str_04346');
  // start the sound system, but don't do any hardware operations yet
  FServices.Sound.Init;
  LoadingMessage('#str_04347');
  // init async network
  FServices.Net.Init;
  if FServices.Net.ServerDedicated = 1 then
  begin
    FServices.Net.InitServerPort;
    FServices.CommonCVars.SetCVarBool('s_noSound', True);
  end
  else
  begin
    // init OpenGL, which will open a window and connect sound and input hardware
    LoadingMessage('#str_04348');
    FServices.Startup.InitRenderSystem;
  end;
  LoadingMessage('#str_04349');
  // initialize the user interfaces
  FServices.UI.Init;
  LoadingMessage('#str_04350');
  // load the game dll
  FServices.Startup.LoadGameDLL;
  LoadingMessage('#str_04351');
  // init the session
  FServices.Session.Init;
  // have to do this twice: the first sets the correct r_mode for the renderer init, this time the backend is set up
  if LSysDetect then
  begin
    FServices.Startup.SetMachineSpec;
    FServices.Startup.ExecMachineSpec;
    FServices.CVarServices.SetCVarInteger('s_numberOfSpeakers', 6);
    FServices.Buffer.BufferCommandText(ceNow, 's_restart' + #10);
    FServices.Buffer.ExecuteCommandBuffer;
  end;
end;

procedure TD3Lifecycle.ShutdownGame(const AReloading: Boolean);
begin
  // kill sound first
  if FServices.Sound.HasPlayingSoundWorld then
    FServices.Sound.StopAllSounds;
  FServices.Sound.ClearBuffer;
  FServices.Net.ShutdownClient;
  // shut down the session
  FServices.Session.Shutdown;
  // shut down the user interfaces
  FServices.UI.Shutdown;
  // shut down the sound system
  FServices.Sound.Shutdown;
  // shut down async networking
  FServices.Net.Shutdown;
  // shut down the user command input code
  FServices.Usercmd.Shutdown;
  // shut down the event loop
  FServices.Events.Shutdown;
  // shut down the renderSystem
  FServices.Render.Shutdown;
  // shutdown the decl manager
  FServices.Decl.Shutdown;
  // unload the game dll
  FServices.Startup.UnloadGameDLL;
  // (the dump of the warnings to warnings.txt is a debug build feature of the original)
  // only shut down the log file after all output is done
  FServices.LogFile.CloseLogFile;
  // shut down the file system
  FServices.FileSetup.Shutdown(AReloading);
end;

procedure TD3Lifecycle.Frame;
var
  LNow: Integer;
  LFrameMsec: Integer;
begin
  try
    // pump all the events
    FServices.Sys.GenerateEvents;
    // write config file if anything changed
    FServices.FrameSteps.WriteConfiguration;
    // change SIMD implementation if required
    if FServices.FrameSteps.IsSIMDModified then
      FServices.FrameSteps.InitSIMD;
    FServices.Events.RunEventLoop(True);
    FState.FrameTime := FState.TicNumber * USERCMD_MSEC;
    FServices.Net.RunFrame;
    if FServices.Net.IsActive then
    begin
      if FServices.Net.ServerDedicated <> 1 then
      begin
        FServices.Session.GuiFrameEvents;
        FServices.Screen.UpdateScreen(False);
      end;
    end
    else
    begin
      FServices.Session.Frame;
      // normal, in-sequence screen update
      FServices.Screen.UpdateScreen(False);
    end;
    // report timing information
    if FServices.CVarValues.GetBool('com_speeds') then
    begin
      LNow := FServices.System.Milliseconds;
      LFrameMsec := LNow - FLastFrameTime;
      FLastFrameTime := LNow;
      FServices.Printer.Printf(Format('frame:%d all:%3d gfr:%3d rf:%3d bk:%3d' + #10,
        [FState.FrameNumber, LFrameMsec, FState.TimeGameFrame, FState.TimeFrontend, FState.TimeBackend]));
      FState.TimeGameFrame := 0;
      FState.TimeGameDraw := 0;
    end;
    FState.FrameNumber := FState.FrameNumber + 1;
    // the FPU stack better be empty at this point or some bad code or compiler bug left values on the stack
    if not FServices.Sys.FPUStackIsEmpty then
    begin
      FServices.Printer.Printf(FServices.Sys.FPUState);
      FServices.Errors.FatalError(SFpuMessage);
    end;
  except
    on ED3HostException do
      Exit; // an ERP_DROP was thrown
  end;
end;

procedure TD3Lifecycle.GUIFrame(const AExecCmd, ANetwork: Boolean);
begin
  FServices.Sys.GenerateEvents;
  FServices.Events.RunEventLoop(AExecCmd); // and execute any commands
  FState.FrameTime := FState.TicNumber * USERCMD_MSEC;
  if ANetwork then
    FServices.Net.RunFrame;
  FServices.Session.Frame;
  FServices.Screen.UpdateScreen(False);
end;

procedure TD3Lifecycle.SingleAsyncTic;
var
  LIndex: Integer;
  LPrevious: Integer;
begin
  // main thread code can prevent this from happening while modifying critical data structures
  FServices.Sys.EnterCriticalSection;
  LIndex := FState.TicNumber and (MaxAsyncStats - 1);
  LPrevious := (FState.TicNumber - 1) and (MaxAsyncStats - 1);
  FAsyncStats[LIndex] := Default(TAsyncStat);
  FAsyncStats[LIndex].Milliseconds := FServices.System.Milliseconds;
  FAsyncStats[LIndex].DeltaMsec := FAsyncStats[LIndex].Milliseconds - FAsyncStats[LPrevious].Milliseconds;
  if Assigned(FServices.Usercmd) and FServices.CVarValues.GetBool('com_asyncInput') then
    FServices.Usercmd.UsercmdInterrupt;
  case FServices.CVarValues.GetInteger('com_asyncSound') of
    1:
      FServices.Sound.AsyncUpdate(FAsyncStats[LIndex].Milliseconds);
    3:
      FServices.Sound.AsyncUpdateWrite(FAsyncStats[LIndex].Milliseconds);
  end;
  // we update com_ticNumber after all the background tasks have completed their work for this tic
  FState.TicNumber := FState.TicNumber + 1;
  FAsyncStats[LIndex].TimeConsumed := FServices.System.Milliseconds - FAsyncStats[LIndex].Milliseconds;
  FServices.Sys.LeaveCriticalSection;
end;

procedure TD3Lifecycle.Async;
var
  LMsec: Integer;
  LTicMsec: Integer;
  LTimescale: Single;
begin
  if FShuttingDown then
    Exit;
  LMsec := FServices.System.Milliseconds;
  if FLastTicMsec = 0 then
    FLastTicMsec := LMsec - USERCMD_MSEC;
  if not FServices.CVarValues.GetBool('com_preciseTic') then
  begin
    // just run a single tic, even if the exact msec isn't precise
    SingleAsyncTic;
    Exit;
  end;
  LTicMsec := USERCMD_MSEC;
  // the number of msec per tic can be varied with the timescale cvar
  LTimescale := FServices.CVarValues.GetFloat('timescale');
  if LTimescale <> 1.0 then
  begin
    LTicMsec := Trunc(Double(LTicMsec) / LTimescale);
    if LTicMsec < 1 then
      LTicMsec := 1;
  end;
  // don't skip too many
  if LTimescale = 1.0 then
    if FLastTicMsec + 10 * USERCMD_MSEC < LMsec then
      FLastTicMsec := LMsec - 10 * USERCMD_MSEC;
  while FLastTicMsec + LTicMsec <= LMsec do
  begin
    SingleAsyncTic;
    Inc(FLastTicMsec, LTicMsec);
  end;
end;

function TD3Lifecycle.IsInitialized: Boolean;
begin
  Result := FFullyInitialized;
end;

function TD3Lifecycle.ShuttingDown: Boolean;
begin
  Result := FShuttingDown;
end;

function TD3Lifecycle.LastTicMsec: Integer;
begin
  Result := FLastTicMsec;
end;

function TD3Lifecycle.AsyncMilliseconds(const ATic: Integer): Integer;
begin
  Result := FAsyncStats[ATic and (MaxAsyncStats - 1)].Milliseconds;
end;

function TD3Lifecycle.AsyncDelta(const ATic: Integer): Integer;
begin
  Result := FAsyncStats[ATic and (MaxAsyncStats - 1)].DeltaMsec;
end;

function TD3Lifecycle.AsyncConsumed(const ATic: Integer): Integer;
begin
  Result := FAsyncStats[ATic and (MaxAsyncStats - 1)].TimeConsumed;
end;

end.

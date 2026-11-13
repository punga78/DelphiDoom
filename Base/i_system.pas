//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  System specific interface stuff.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_system;

interface

uses
  DelphiDoom.Engine.Net.Intf,
  DelphiDoom.Engine.Configuration.Intf,
  d_delphi,
  d_ticcmd,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Video.Intf,
  DelphiDoom.Input.Intf,
  DelphiDoom.Platform.Intf,
  DelphiDoom.EngineSystem.Intf;

//==============================================================================
//
// I_Init
//
//==============================================================================
procedure I_Init;

//==============================================================================
//
// I_ConfigureInput
// The poller of the keyboard, the mouse and the joystick: I_Init starts it, every frame and
// every tic read it, I_Destroy stops it. The composition root calls it; without it I_Init
// stops with I_Error
//
//==============================================================================
procedure I_ConfigureInput(const APoller: IInputPoller);

//==============================================================================
//
// I_GetSysTime
//
// Called by D_DoomLoop,
// Called by HU_DoFPSStuff
// returns current time in tics.
//
//==============================================================================
function I_GetSysTime: extended;

//==============================================================================
//
// I_GetTime
//
//==============================================================================
function I_GetTime: integer;

//==============================================================================
//
// I_GetFracTime
//
//==============================================================================
function I_GetFracTime: integer;

//==============================================================================
// I_StartFrame
//
//  Called by D_DoomLoop,
//  called before processing any tics in a frame
//  (just after displaying a frame).
//  Time consuming syncronous operations
//  are performed here (joystick reading).
//  Can call D_PostEvent.
//
//==============================================================================
procedure I_StartFrame;

//==============================================================================
//
// I_StartTic
//
//  Called by D_DoomLoop, }
//  called before processing each tic in a frame.
//  Quick syncronous operations are performed here.
//  Can call D_PostEvent.
//
//==============================================================================
procedure I_StartTic;

//==============================================================================
//
// I_BaseTiccmd
//
//  Asynchronous interrupt functions should maintain private queues
//  that are read by the synchronous functions
//  to be converted into events.
//  Either returns a null ticcmd,
//  or calls a loadable driver to build it.
//  This ticcmd will then be modified by the gameloop
//  for normal input.
//
//==============================================================================
function I_BaseTiccmd: Pticcmd_t;

//==============================================================================
//
// I_BaseTiccmd202
//
//==============================================================================

//==============================================================================
//
// I_Quit
//
//  Called by M_Responder when quit is selected.
//  Clean exit, displays sell blurb.
//
//==============================================================================
procedure I_Quit;

//==============================================================================
//
// I_Destroy
//
//==============================================================================
procedure I_Destroy(const code: integer);

//==============================================================================
//
// I_FlashCachedOutput
//
//==============================================================================
procedure I_FlashCachedOutput;

//==============================================================================
//
// I_ConfigureLog
// Gives the unit the log it writes warnings and errors to. The composition root calls it
//
//==============================================================================
procedure I_ConfigureLog(const ALog: ILog);

//==============================================================================
//
// I_ConfigureClock
// Gives the unit the clock behind I_GetTime and the waits. The composition root calls it
//
//==============================================================================
procedure I_ConfigureClock(const AClock: IClock);

//==============================================================================
//
// I_ConfigureVideo
// Gives the units of the video (software and OpenGL) the services that do not depend on the
// graphics API: the palette, the limit of the window, the memory stall hack.
// The composition root calls it
//
//==============================================================================
procedure I_ConfigureVideo(const AServices: IVideoServices);

//==============================================================================
//
// I_VideoServices
//
//==============================================================================
function I_VideoServices: IVideoServices;

//==============================================================================
//
// I_Error
//
//==============================================================================
procedure I_Error(const error: string; const Args: array of const); overload;

//==============================================================================
//
// I_Error
//
//==============================================================================
procedure I_Error(const error: string); overload;

//==============================================================================
//
// I_DevError
//
//==============================================================================
procedure I_DevError(const error: string; const Args: array of const); overload;

//==============================================================================
//
// I_DevError
//
//==============================================================================
procedure I_DevError(const error: string); overload;

//==============================================================================
//
// I_Warning
//
//==============================================================================
procedure I_Warning(const warning: string; const Args: array of const); overload;

//==============================================================================
//
// I_Warning
//
//==============================================================================
procedure I_Warning(const warning: string); overload;

//==============================================================================
//
// I_DevWarning
//
//==============================================================================
procedure I_DevWarning(const error: string; const Args: array of const); overload;

//==============================================================================
//
// I_DevWarning
//
//==============================================================================
procedure I_DevWarning(const error: string); overload;

//==============================================================================
//
// I_GameFinished
//
//==============================================================================
function I_GameFinished: boolean;

//==============================================================================
//
// I_ProcessWindows
//
//==============================================================================
procedure I_ProcessWindows;

//==============================================================================
//
// I_WaitVBL
//
//==============================================================================
procedure I_WaitVBL(const count: integer);

//==============================================================================
//
// I_Sleep
//
//==============================================================================
procedure I_Sleep(const msecs: integer);

var
  zonesize: integer;
  mb_used: integer;
  InBackground: boolean = true;
  in_i_error: boolean = false;

//==============================================================================
//
// I_BeginDiskBusy
//
//==============================================================================
procedure I_BeginDiskBusy;

//==============================================================================
//
// I_IsCDRomDrive
//
//==============================================================================
function I_IsCDRomDrive(const drive: char = #0): boolean;

//==============================================================================
//
// I_GetExeImageSize
//
//==============================================================================
function I_GetExeImageSize(fname: string = ''): LongWord;

//==============================================================================
//
// I_VersionBuilt
//
//==============================================================================
function I_VersionBuilt(fname: string = ''): string;

//==============================================================================
//
// I_DirectoryExists
//
//==============================================================================
function I_DirectoryExists(const Name: string): Boolean;

//==============================================================================
//
// I_SetCriticalCPUPriority
//
//==============================================================================
procedure I_SetCriticalCPUPriority;

//==============================================================================
//
// I_SetNormalCPUPriority
//
//==============================================================================
procedure I_SetNormalCPUPriority;

//==============================================================================
//
// I_DetectOS
//
//==============================================================================
procedure I_DetectOS;

//==============================================================================
//
// I_DetectCPU
//
//==============================================================================
procedure I_DetectCPU;

//==============================================================================
//
// I_GetNumCPUs
//
//==============================================================================
function I_GetNumCPUs: integer;

//==============================================================================
//
// I_ClearInterface
//
//==============================================================================
procedure I_ClearInterface(var Dest: IInterface);

type
  process_t = function(p: pointer): LongInt; stdcall;

//==============================================================================
//
// I_CreateProcess
//
//==============================================================================

//==============================================================================
//
// I_WaitForProcess
//
//==============================================================================

//==============================================================================
//
// I_GoToWebPage
//
//==============================================================================
procedure I_GoToWebPage(const cmd: string);

type
  osplatform_t = (os_unknown, os_Win95, os_WinNT4, os_Win2k);

var
  osplatform: osplatform_t;

var
  isdiskbusy: boolean = false;

var
  safemode: boolean = false;
  usemmx: boolean = true;
  usemultithread: boolean;
  criticalcpupriority: boolean;
  win_vista_or_newer: boolean = true;

//==============================================================================
//
// I_ScreenWidth
//
//==============================================================================
function I_ScreenWidth: integer;

//==============================================================================
//
// I_ScreenHeight
//
//==============================================================================
function I_ScreenHeight: integer;

//==============================================================================
//
// I_SetDPIAwareness
//
//==============================================================================
function I_SetDPIAwareness: boolean;

//==============================================================================
//
// I_GetWindowDPI
//
//==============================================================================
function I_GetWindowDPI(const h: THandle): integer;

//==============================================================================
//
// I_GetTickCount
//
//==============================================================================
function I_GetTickCount: LongWord;

//==============================================================================
//
// I_ConfigurePlatform
// Gives the unit the services about the machine: operating system, processor,
// executable files, drives, DPI and thread priority. The composition root calls it
//
//==============================================================================
procedure I_ConfigurePlatform(const AServices: IPlatformServices);

//==============================================================================
//
// I_ConfigureNetGame
// The network, given by the composition root
//
//==============================================================================
procedure I_ConfigureNetGame(const ANetGame: IEngineNetGame);

//==============================================================================
//
// I_ConfigureDefaults
// The defaults, given by the composition root
//
//==============================================================================
procedure I_ConfigureDefaults(const ADefaults: IEngineDefaults);

//==============================================================================
//
// I_ConfigureShutdown
// The shutdown of the engine, given by the composition root: I_Destroy runs it
//
//==============================================================================
procedure I_ConfigureShutdown(const ASequence: IShutdownSequence);

//==============================================================================
//
// I_ConfigureFatalError
// The handler of the fatal errors, given by the composition root: I_Error calls it
//
//==============================================================================
procedure I_ConfigureFatalError(const AHandler: IFatalErrorHandler);

implementation

uses
  DelphiDoom.Console.Numbers,
  DelphiDoom.Platform.Types,
  DelphiDoom.EngineSystem.Types,
  DelphiDoom.EngineSystem.MachineProfileBuilder,
{$IFDEF FPC}
  d_fpc,
{$ENDIF}
  c_cmds,
  Windows,
  Messages,
  doomdef,
  m_misc,
  m_fixed,
  s_sound,
  i_io,
  DelphiDoom.Input.Types,
  i_mainwindow,
  d_main,
  m_base;

var
  // given by the composition root; they can be missing when an error stops the start
  // before ComposeEngine is done: I_Destroy then skips them, as the old code did
  i_netgame_ref: IEngineNetGame = nil;
  i_defaults_ref: IEngineDefaults = nil;
  // the shutdown and the handler of the fatal errors (Libs\EngineSystem)
  system_shutdown: IShutdownSequence = nil;
  system_fatalerror: IFatalErrorHandler = nil;

//==============================================================================
//
// I_ConfigureNetGame
//
//==============================================================================
procedure I_ConfigureNetGame(const ANetGame: IEngineNetGame);
begin
  i_netgame_ref := ANetGame;
end;

//==============================================================================
//
// I_ConfigureDefaults
//
//==============================================================================
procedure I_ConfigureDefaults(const ADefaults: IEngineDefaults);
begin
  i_defaults_ref := ADefaults;
end;

//==============================================================================
//
// I_ConfigureShutdown
//
//==============================================================================
procedure I_ConfigureShutdown(const ASequence: IShutdownSequence);
begin
  system_shutdown := ASequence;
end;

//==============================================================================
//
// I_ConfigureFatalError
//
//==============================================================================
procedure I_ConfigureFatalError(const AHandler: IFatalErrorHandler);
begin
  system_fatalerror := AHandler;
end;

var
  finished: boolean = false;

//==============================================================================
//
// I_GameFinished
//
//==============================================================================
function I_GameFinished: boolean;
begin
  result := finished or ((system_shutdown <> nil) and system_shutdown.IsFinished);
end;

var
  // given by the composition root (I_ConfigureInput)
  system_input: IInputPoller = nil;

//==============================================================================
//
// I_ConfigureInput
//
//==============================================================================
procedure I_ConfigureInput(const APoller: IInputPoller);
begin
  system_input := APoller;
end;

//==============================================================================
//
// I_StartFrame
//
//==============================================================================
procedure I_StartFrame;
begin
  I_ProcessWindows;
  S_ProcessMusic;
  // the poller reads nothing before I_Init
  if system_input <> nil then
    system_input.Process;
end;

//==============================================================================
//
// I_StartTic
//
//==============================================================================
procedure I_StartTic;
begin
  if not InBackground then        // JVAL ?
    if system_input <> nil then   // JVAL ?
      system_input.Process;
end;

var
  emptycmd: ticcmd_t;

//==============================================================================
//
// I_BaseTiccmd
//
//==============================================================================
function I_BaseTiccmd: Pticcmd_t;
begin
  result := @emptycmd;
end;

var
  emptycmd202: ticcmd_t202;

//
// I_GetTime
// returns time in 1/70th second tics
//
var
  // given by the composition root (I_ConfigureClock)
  engine_clock: IClock = nil;

//==============================================================================
//
// I_ConfigureClock
//
//==============================================================================
procedure I_ConfigureClock(const AClock: IClock);
begin
  engine_clock := AClock;
end;

var
  // given by the composition root (I_ConfigureVideo)
  engine_video: IVideoServices = nil;

//==============================================================================
//
// I_ConfigureVideo
//
//==============================================================================
procedure I_ConfigureVideo(const AServices: IVideoServices);
begin
  engine_video := AServices;
end;

//==============================================================================
//
// I_VideoServices
//
//==============================================================================
function I_VideoServices: IVideoServices;
begin
  result := engine_video;
end;

//==============================================================================
//
// I_GetSysTime
//
//==============================================================================
function I_GetSysTime: extended;
begin
  result := engine_clock.Seconds;
end;

//==============================================================================
//
// I_GetTime
//
//==============================================================================
function I_GetTime: integer;
begin
  result := engine_clock.Steps(TICRATE);
end;

//==============================================================================
//
// I_GetFracTime
//
//==============================================================================
function I_GetFracTime: integer;
begin
  result := engine_clock.ScaledSteps(TICRATE, FRACUNIT);
end;

//==============================================================================
//
// I_CmdUseMMX
//
//==============================================================================
procedure I_CmdUseMMX(const parm: string = '');
var
  newusemmx: boolean;
begin
  if parm = '' then
  begin
    printf('Current setting: usemmx = %s.'#13#10, [truefalseStrings[usemmx]]);
    exit;
  end;

  newusemmx := TConsoleNumbers.EvaluateBoolean(parm, usemmx);
  if usemmx <> newusemmx then
  begin
    usemmx := newusemmx;
    if usemmx then
      I_DetectCPU
    else
    begin
      mmxmachine := 0;
      AMD3DNowMachine := 0;
    end;
  end;
  I_CmdUseMMX;
end;

//==============================================================================
//
// I_Init
//
//==============================================================================
procedure I_Init;
begin
  printf('I_DetectOS: Detecting operating system.'#13#10);
  I_DetectOS;
  printf('I_InitSound: Initializing DirectSound.'#13#10);
  S_InitSoundDevice;
  printf('I_InitMusic: Initializing music.'#13#10);
  S_InitMusicDevice;
  printf('I_InitInput: Initializing Input Devices.'#13#10);
  if system_input = nil then
    I_Error('I_InitInput(): the input was not configured');
  try
    system_input.Initialize;
  except
    on E: EInputDeviceException do
      I_Error('%s', [E.Message]);
  end;

  C_AddCmd('usemmx, mmx', @I_CmdUseMMX);
end;

//==============================================================================
//
// I_Quit
//
//==============================================================================
procedure I_Quit;
begin
  PostMessage(hMainWnd, WM_DESTROY, 0, 0);
end;

//==============================================================================
//
// I_RestoreDesktop
//
//==============================================================================
procedure I_RestoreDesktop;
begin
  InvalidateRect(0, nil, true)
end;

//==============================================================================
//
// I_Destroy
//
//==============================================================================
procedure I_Destroy(const code: integer);
begin
  // the sequence of Libs\EngineSystem writes what it does and ends the process; without it (an error
  // before ComposeEngine) there is nothing to shut down
  finished := true;
  if system_shutdown <> nil then
    system_shutdown.Run(code);
  Halt(code);
end;

//==============================================================================
//
// I_FlashCachedOutput
//
//==============================================================================
procedure I_FlashCachedOutput;
begin
  if stdoutbuffer <> nil then
    stdoutbuffer.SaveToFile({$IFDEF OPENGL}'GL' + {$ENDIF}_GAME + '_stdout.cachedbuffer.txt');
end;

var
  // given by the composition root (I_ConfigureLog)
  engine_log: ILog = nil;

//==============================================================================
//
// I_ConfigureLog
//
//==============================================================================
procedure I_ConfigureLog(const ALog: ILog);
begin
  engine_log := ALog;
end;

//==============================================================================
//
// I_Error
//
//==============================================================================
procedure I_Error(const error: string; const Args: array of const);
var
  msg: string;
begin
// JVAL: Avoid recursive calls
  if in_i_error then
    exit;

  sprintf(msg, error, Args);

  // the order of the steps is TFatalErrorHandler of Libs\EngineSystem; without it (an error before
  // ComposeEngine) the message goes to the output and the game stops
  if system_fatalerror <> nil then
    system_fatalerror.Handle(msg)
  else
  begin
    in_i_error := true;
    printf('I_Error: ' + msg + #13#10);
    I_Destroy(1);
  end;
end;

//==============================================================================
//
// I_Error
//
//==============================================================================
procedure I_Error(const error: string);
begin
  I_Error(error, []);
end;

//==============================================================================
//
// I_DevError
//
//==============================================================================
procedure I_DevError(const error: string; const Args: array of const);
begin
  if devparm then
    I_Warning(error, Args)
  else
    I_Error(error + #13#10#13#10'Specify -devparm from the command line if you want this error to be ignored', Args);
end;

//==============================================================================
//
// I_DevError
//
//==============================================================================
procedure I_DevError(const error: string);
begin
  I_DevError(error, []);
end;

//==============================================================================
//
// I_Warning
//
//==============================================================================
procedure I_Warning(const warning: string; const Args: array of const);
var
  msg: string;
begin
  sprintf(msg, warning, Args);
  I_Warning(msg);
end;

//==============================================================================
//
// I_Warning
//
//==============================================================================
procedure I_Warning(const warning: string);
begin
  if engine_log <> nil then
    engine_log.Warning(warning)
  else
    printf('I_Warning: ' + warning);
end;

//==============================================================================
//
// I_DevWarning
//
//==============================================================================
procedure I_DevWarning(const error: string; const Args: array of const);
begin
  if devparm then
    I_Warning(error, Args);
end;

//==============================================================================
//
// I_DevWarning
//
//==============================================================================
procedure I_DevWarning(const error: string);
begin
  if devparm then
    I_Warning(error);
end;

//==============================================================================
//
// I_ProcessWindows
//
//==============================================================================
procedure I_ProcessWindows;
var
  msg: TMsg;
begin
  while PeekMessage(msg, 0, 0, 0, PM_REMOVE) do
  begin
    if msg.message <> WM_QUIT then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  end;
end;

//==============================================================================
//
// I_WaitVBL
// Wait for vertical retrace or pause a bit.
//
//==============================================================================
procedure I_WaitVBL(const count: integer);
begin
  engine_clock.Wait(count);
end;

//==============================================================================
//
// I_Sleep
//
//==============================================================================
procedure I_Sleep(const msecs: integer);
begin
  engine_clock.Sleep(msecs);
end;

//==============================================================================
//
// I_BeginDiskBusy
//
//==============================================================================
procedure I_BeginDiskBusy;
begin
  isdiskbusy := true;
end;

var
  // given by the composition root (I_ConfigurePlatform)
  engine_platform: IPlatformServices = nil;

//==============================================================================
//
// I_ConfigurePlatform
//
//==============================================================================
procedure I_ConfigurePlatform(const AServices: IPlatformServices);
begin
  engine_platform := AServices;
end;

//==============================================================================
//
// I_PlatformServices
//
//==============================================================================
function I_PlatformServices: IPlatformServices;
begin
  if not Assigned(engine_platform) then
    I_Error('The services of the platform were not configured (I_ConfigurePlatform)');
  result := engine_platform;
end;

//==============================================================================
//
// I_IsCDRomDrive
//
//==============================================================================
function I_IsCDRomDrive(const drive: char = #0): boolean;
begin
  if drive = #0 then
    result := I_PlatformServices.Drives.IsProgramOnCdRom(ParamStr(0))
  else
    result := I_PlatformServices.Drives.IsCdRomDrive(drive);
end;

//==============================================================================
//
// I_GetExeImageSize
//
//==============================================================================
function I_GetExeImageSize(fname: string = ''): LongWord;
begin
  if fname = '' then
    fname := ParamStr(0);
  result := I_PlatformServices.Executable.ImageSize(fname);
end;

//==============================================================================
//
// I_VersionBuilt
//
//==============================================================================
function I_VersionBuilt(fname: string = ''): string;
begin
  if fname = '' then
    fname := ParamStr(0);
  result := I_PlatformServices.Executable.FileVersion(fname);
end;

//==============================================================================
//
// I_DirectoryExists
//
//==============================================================================
function I_DirectoryExists(const Name: string): Boolean;
var
  Code: Integer;
begin
  Code := GetFileAttributes(PChar(Name));
  result := (Code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
end;

//==============================================================================
//
// I_SetCriticalCPUPriority
//
//==============================================================================
procedure I_SetCriticalCPUPriority;
begin
  I_PlatformServices.Priority.RaiseToCritical;
end;

//==============================================================================
//
// I_SetNormalCPUPriority
//
//==============================================================================
procedure I_SetNormalCPUPriority;
begin
  I_PlatformServices.Priority.Restore;
end;

//==============================================================================
//
// I_DetectOS
//
//==============================================================================
procedure I_DetectOS;
var
  desc: TOperatingSystemDescription;
  i: integer;
begin
  desc := I_PlatformServices.OperatingSystem.Describe;
  case desc.Kind of
    oskWindows95: osplatform := os_Win95;
    oskWindowsNT4: osplatform := os_WinNT4;
    oskWindows2000: osplatform := os_Win2k;
  else
    osplatform := os_unknown;
  end;
  win_vista_or_newer := desc.IsVistaOrNewer;
  for i := 0 to Length(desc.Lines) - 1 do
    printf('%s'#13#10, [desc.Lines[i]]);
end;

var
  numcpus: Integer = 0;

//==============================================================================
//
// I_DetectCPU
//
//==============================================================================
procedure I_DetectCPU;
var
  profile: TMachineProfile;
  i: integer;
begin
  profile := TMachineProfileBuilder.Detect(I_PlatformServices.Cpu,
    (i_defaults_ref = nil) or i_defaults_ref.ConfigNotFound, usemultithread);
  if profile.HasMmx then
    mmxMachine := 1
  else
    mmxMachine := 0;
  if profile.Has3DNow then
    AMD3DNowMachine := 1
  else
    AMD3DNowMachine := 0;
  numcpus := profile.ProcessorCount;
  usemultithread := profile.UseMultithread;
  for i := 0 to Length(profile.Lines) - 1 do
    printf('%s', [profile.Lines[i]]);
end;

//==============================================================================
//
// I_GetNumCPUs
//
//==============================================================================
function I_GetNumCPUs: integer;
begin
  result := numcpus;
end;

//==============================================================================
//
// I_ClearInterface
//
//==============================================================================
procedure I_ClearInterface(var Dest: IInterface);
var
  P: Pointer;
begin
  if safemode then
    exit;
  if Dest <> nil then
  begin
    P := Pointer(Dest);
    Pointer(Dest) := nil;
    IInterface(P)._Release;
  end;
end;

type
  shellexecute_t = function (hWnd: HWND; Operation, FileName, Parameters,
    Directory: PChar; ShowCmd: Integer): HINST; stdcall;

//==============================================================================
//
// I_GoToWebPage
//
// JVAL:
//  Dynamically get ShellExecute function to avoid malicius detection of
//  some antivirus programs
//
//==============================================================================
procedure I_GoToWebPage(const cmd: string);
var
  shellexecutefunc: shellexecute_t;
  inst: THandle;
begin
  inst := LoadLibrary('shell32');
  shellexecutefunc := GetProcAddress(inst, 'ShellExecuteA');
  shellexecutefunc(0, 'open', PChar(cmd), nil, nil, SW_SHOWNORMAL);
  FreeLibrary(inst);
end;

//==============================================================================
//
// I_ScreenWidth
//
//==============================================================================
function I_ScreenWidth: integer;
begin
  result := GetSystemMetrics(SM_CXSCREEN);
end;

//==============================================================================
//
// I_ScreenHeight
//
//==============================================================================
function I_ScreenHeight: integer;
begin
  result := GetSystemMetrics(SM_CYSCREEN);
end;

//==============================================================================
//
// I_SetDPIAwareness
//
//==============================================================================
function I_SetDPIAwareness: boolean;
begin
  result := I_PlatformServices.Dpi.SetAwareness;
end;

//==============================================================================
//
// I_GetWindowDPI
//
//==============================================================================
function I_GetWindowDPI(const h: THandle): integer;
begin
  result := I_PlatformServices.Dpi.WindowDpi(h);
end;

//==============================================================================
//
// I_GetTickCount
//
//==============================================================================
function I_GetTickCount: LongWord;
begin
  Result := GetTickCount;
end;

end.

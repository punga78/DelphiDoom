{******************************************************************************}
{                                                                              }
{  Xcom32: OpenXcom (UFO: Enemy Unknown and Terror from the Deep) without SDL,  }
{  on the data of an installed game (issues 176 and 180). One program, two      }
{  modes, chosen by the command line                                            }
{                                                                              }
{  The game (the default): a window of Windows (GDI, or OpenGL with the option  }
{  useOpenGL: issue 182) or, with -shot or                                      }
{  -script, no window and screenshots as PNG files. Without -data and -game     }
{  the data are next to the executable (common\ and standard\, TFTD\ or UFO\)   }
{  and the user folder is user\ next to it                                      }
{                                                                              }
{    Xcom32 [-data <folder with common\ and standard\>]                         }
{           [-game <folder of the game: GEODATA, GEOGRAPH...>]                  }
{           [-user <folder with options.cfg>] [-mod xcom2|xcom1]                }
{           [-shot <file.png> [-ms <n>]] [-script step;step...]                 }
{           [-seed <n>] [-quitafter <ms>] [-audiostats] [-listmodes]            }
{           [-version <text>] [-dospath <text>] [-hold]                         }
{                                                                              }
{  The export: when the command line has -pck, -dat, -scr or -map, a data file  }
{  of the game is decoded and saved as a PNG. Here -data (it can be repeated)   }
{  is a folder of the game, the same as -game: see TXcomExportArguments         }
{                                                                              }
{    Xcom32 [-data <folder of the game>]... [-pal <n>] [-png <file>]            }
{           -pck <file> [-tab <file>] [-w <n>] [-h <n>] [-columns <n>]         }
{         | -dat <file> [-w <n>] [-h <n>] [-columns <n>]                        }
{         | -scr <file> [-w <n>] [-h <n>]     (.SCR, .SPK or .BDY)              }
{         | -map <file> [-rmp <file>] [-z <n>]                                  }
{                                                                              }
{  The program has no console: what it says goes to the standard output when    }
{  there is one (redirected, or the console of the parent)                      }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this program                   }
{                                                                              }
{******************************************************************************}
program Xcom32;

{$APPTYPE GUI}

uses
  Winapi.Windows,
  System.SysUtils,
  DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Game,
  DelphiDoom.XcomEngine.ManualClock,
  DelphiDoom.XcomEngine.QueueEventSource,
  DelphiDoom.XcomEngine.MemoryVideoDevice,
  DelphiDoom.Xcom.ImageExporter,
  DelphiDoom.Xcom.Composition in 'DelphiDoom.Xcom.Composition.pas',
  DelphiDoom.Xcom.ExportArguments in 'DelphiDoom.Xcom.ExportArguments.pas',
  DelphiDoom.Xcom.ExportTool in 'DelphiDoom.Xcom.ExportTool.pas',
  DelphiDoom.Xcom.GameComposition in 'DelphiDoom.Xcom.GameComposition.pas',
  DelphiDoom.Xcom.ShotRunner in 'DelphiDoom.Xcom.ShotRunner.pas',
  DelphiDoom.Xcom.DelegateLog in 'DelphiDoom.Xcom.DelegateLog.pas',
  DelphiDoom.Xcom.VideoDevice.Types in 'DelphiDoom.Xcom.VideoDevice.Types.pas',
  DelphiDoom.Xcom.VideoDeviceSelector in 'DelphiDoom.Xcom.VideoDeviceSelector.pas',
  DelphiDoom.Xcom.Win.Window in 'DelphiDoom.Xcom.Win.Window.pas',
  DelphiDoom.Xcom.Win.WindowDevice in 'DelphiDoom.Xcom.Win.WindowDevice.pas',
  DelphiDoom.Xcom.Win.VideoDevice in 'DelphiDoom.Xcom.Win.VideoDevice.pas',
  DelphiDoom.Xcom.Win.OpenGlVideoDevice in 'DelphiDoom.Xcom.Win.OpenGlVideoDevice.pas',
  DelphiDoom.Xcom.Win.Clock in 'DelphiDoom.Xcom.Win.Clock.pas',
  DelphiDoom.Xcom.Win.DisplayModes in 'DelphiDoom.Xcom.Win.DisplayModes.pas',
  DelphiDoom.Xcom.Win.FolderOpener in 'DelphiDoom.Xcom.Win.FolderOpener.pas',
  DelphiDoom.Xcom.Win.PcmOutput in 'DelphiDoom.Xcom.Win.PcmOutput.pas',
  DelphiDoom.XcomAudio.Intf;

const
  DEFAULT_VERSION = '1.0 git 2026-06-05 22:05';

type
  TArguments = record
    Settings: TXcomGameSettings;
    ShotFile: string;
    Milliseconds: Integer;
    Script: string;
    /// <summary>Quits by itself after this many milliseconds (0: when the window closes)</summary>
    QuitAfter: Integer;
    /// <summary>Prints what the mixer played when the program ends</summary>
    AudioStatistics: Boolean;
  end;

/// <summary>
/// The program has no console of its own (no black window behind the game): a line goes to the standard output when
/// there is one (redirected, or the console of the parent), otherwise nowhere.
/// </summary>
procedure Say(const AText: string; AError: Boolean = False);
var
  LHandle: THandle;
  LBytes: TBytes;
  LWritten: DWORD;
begin
  if AError then
    LHandle := GetStdHandle(STD_ERROR_HANDLE)
  else
    LHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  if (LHandle = 0) or (LHandle = INVALID_HANDLE_VALUE) then
  begin
    if not AttachConsole(ATTACH_PARENT_PROCESS) then
      Exit;
    if AError then
      LHandle := GetStdHandle(STD_ERROR_HANDLE)
    else
      LHandle := GetStdHandle(STD_OUTPUT_HANDLE);
    if (LHandle = 0) or (LHandle = INVALID_HANDLE_VALUE) then
      Exit;
  end;
  LBytes := TEncoding.UTF8.GetBytes(AText + sLineBreak);
  WriteFile(LHandle, LBytes[0], Length(LBytes), LWritten, nil);
end;

procedure ShowUsage;
begin
  Say('Xcom32 [-data <common+standard folder>] [-game <game folder>] [-user <folder>] [-mod xcom2]      (the game)');
  Say('  without -data and -game: common + standard and TFTD (or UFO) next to the executable');
  Say('         [-shot <file.png> [-ms <n>]] [-script wait:ms;click:x,y;key:n;shot:file;...]');
  Say('         [-seed <n>] [-quitafter <ms>] [-audiostats] [-listmodes]');
  Say('         [-version <text>] [-dospath <text>] [-hold]');
  TXcomExportTool.ShowUsage(
    procedure(AText: string)
    begin
      Say(AText);
    end);
end;

/// <summary>The arguments of the program, without its name</summary>
function CommandLineArguments: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, ParamCount);
  for LIndex := 1 to ParamCount do
    Result[LIndex - 1] := ParamStr(LIndex);
end;

/// <summary>
/// Without -data and -game, looks next to the executable: the data folder is the one that has common\ and
/// standard\ (the executable folder or its data\ subfolder), the game folder is TFTD\, UFO\ or the executable
/// folder itself when it has GEODATA\.
/// </summary>
procedure ApplyDefaultFolders(var ASettings: TXcomGameSettings);
var
  LBase: string;

  function Sub(const AName: string): string;
  begin
    Result := LBase + AName;
  end;

begin
  LBase := ExtractFilePath(ParamStr(0));
  if ASettings.DataFolder = '' then
  begin
    if DirectoryExists(Sub('common')) and DirectoryExists(Sub('standard')) then
      ASettings.DataFolder := LBase
    else if DirectoryExists(Sub('data\common')) and DirectoryExists(Sub('data\standard')) then
      ASettings.DataFolder := Sub('data');
  end;
  if ASettings.GameFolder = '' then
  begin
    if DirectoryExists(Sub('TFTD\GEODATA')) then
      ASettings.GameFolder := Sub('TFTD')
    else if DirectoryExists(Sub('UFO\GEODATA')) then
    begin
      ASettings.GameFolder := Sub('UFO');
      // The ruleset follows the game found: only UFO next to the executable means xcom1.
      if SameText(ASettings.ModId, 'xcom2') then
        ASettings.ModId := 'xcom1';
    end
    else if DirectoryExists(Sub('GEODATA')) then
      ASettings.GameFolder := LBase;
  end;
  // options.cfg and the saved games: the user folder next to the executable, as OpenXcom does when it is there
  if ASettings.UserFolder = '' then
  begin
    ASettings.UserFolder := Sub('user');
    ForceDirectories(ASettings.UserFolder);
  end;
end;

function ParseArguments(out AArguments: TArguments): Boolean;
var
  LIndex: Integer;
  LName: string;

  function NextValue: string;
  begin
    if LIndex >= ParamCount then
      raise Exception.CreateFmt('%s needs a value', [LName]);
    Inc(LIndex);
    Result := ParamStr(LIndex);
  end;

begin
  AArguments := Default(TArguments);
  AArguments.Settings.ModId := 'xcom2';
  AArguments.Settings.VersionText := DEFAULT_VERSION;
  AArguments.Settings.LoadMode := lmThread;
  AArguments.Milliseconds := 3000;
  LIndex := 1;
  while LIndex <= ParamCount do
  begin
    LName := ParamStr(LIndex).ToLowerInvariant;
    if LName = '-data' then
      AArguments.Settings.DataFolder := NextValue
    else if LName = '-game' then
      AArguments.Settings.GameFolder := NextValue
    else if LName = '-user' then
      AArguments.Settings.UserFolder := NextValue
    else if LName = '-mod' then
      AArguments.Settings.ModId := NextValue
    else if LName = '-shot' then
      AArguments.ShotFile := NextValue
    else if LName = '-ms' then
      AArguments.Milliseconds := StrToInt(NextValue)
    else if LName = '-script' then
      AArguments.Script := NextValue
    else if LName = '-version' then
      AArguments.Settings.VersionText := NextValue
    else if LName = '-dospath' then
      AArguments.Settings.DosPath := NextValue
    else if LName = '-listmodes' then
      AArguments.Settings.ListModes := True
    else if LName = '-seed' then
      AArguments.Settings.Seed := StrToUInt64(NextValue)
    else if LName = '-quitafter' then
      AArguments.QuitAfter := StrToInt(NextValue)
    else if LName = '-audiostats' then
      AArguments.AudioStatistics := True
    else if LName = '-hold' then
      AArguments.Settings.LoadMode := lmHeld
    else
      Exit(False);
    Inc(LIndex);
  end;
  ApplyDefaultFolders(AArguments.Settings);
  Result := (AArguments.Settings.DataFolder <> '') and (AArguments.Settings.GameFolder <> '');
end;

procedure PrintAudio(const AMeter: IXcomMixerMeter; const AOutput: TXcomWinPcmOutput);
var
  LStatistics: TXcomMixerStatistics;
begin
  LStatistics := AMeter.Statistics;
  Say(Format('audio: %d bytes rendered, rms %.1f, peak %d, sounds %d, buffers completed by the device %d',
    [LStatistics.RenderedBytes, LStatistics.Rms, LStatistics.Peak, LStatistics.SoundsStarted,
    AOutput.CompletedBuffers]));
end;

procedure RunWindow(const AArguments: TArguments);
var
  LEvents: TXcomQueueEventSource;
  LEventsRef: IXcomEventSource;
  LWindow: TXcomWinWindow;
  LDevice: IXcomVideoDevice;
  LGame: TXcomGame;
  LSettings: TXcomGameSettings;
  LOutput: TXcomWinPcmOutput;
  LOutputRef: IXcomPcmOutput;
  LMeter: IXcomMixerMeter;
  LStart: Cardinal;
begin
  LEvents := TXcomQueueEventSource.Create;
  LEventsRef := LEvents;
  LOutput := TXcomWinPcmOutput.Create;
  LOutputRef := LOutput;
  LSettings := AArguments.Settings;
  LSettings.WindowMode := True;
  LSettings.AudioOutput := LOutputRef;
  LSettings.OnAudio := procedure(const AMeter: IXcomMixerMeter)
    begin
      LMeter := AMeter;
    end;
  LGame := nil;
  LWindow := TXcomWinWindow.Create('OpenXcom ' + AArguments.Settings.VersionText, LEvents);
  try
    // GDI, or OpenGL when the options ask for it: which OpenGL is found, or why it is not used, is said
    LDevice := TXcomGameComposition.CreateWindowDevice(LWindow, TXcomDelegateLog.Create(
      procedure(const ALine: string)
      begin
        Say(ALine);
      end));
    LGame := TXcomGameComposition.CreateGame(LSettings, LDevice, TXcomWinClock.Create, LEvents);
    LStart := GetTickCount;
    while LWindow.Pump and not LGame.IsQuitting do
    begin
      LGame.RunFrame;
      Sleep(1);
      if (AArguments.QuitAfter > 0) and (GetTickCount - LStart > Cardinal(AArguments.QuitAfter)) then
        Break;
    end;
    if AArguments.AudioStatistics and (LMeter <> nil) then
      PrintAudio(LMeter, LOutput);
  finally
    LGame.Free;
    LMeter := nil;
    // the display draws in the window: its last reference goes before the window
    LDevice := nil;
    LWindow.Free;
  end;
end;

procedure RunShot(const AArguments: TArguments);
var
  LClock: TXcomManualClock;
  LClockRef: IXcomClock;
  LEvents: TXcomQueueEventSource;
  LEventsRef: IXcomEventSource;
  LDevice: TXcomMemoryVideoDevice;
  LDeviceRef: IXcomVideoDevice;
  LGame: TXcomGame;
  LRunner: TXcomShotRunner;
  LExporter: TXcomImageExporter;
  LSettings: TXcomGameSettings;
begin
  LClock := TXcomManualClock.Create;
  LClockRef := LClock;
  LEvents := TXcomQueueEventSource.Create;
  LEventsRef := LEvents;
  LDevice := TXcomMemoryVideoDevice.Create;
  LDeviceRef := LDevice;
  LSettings := AArguments.Settings;
  // the loading must be over when the clock says so: the task runs at once unless -hold asks otherwise
  if LSettings.LoadMode <> lmHeld then
    LSettings.LoadMode := lmImmediate;
  LGame := TXcomGameComposition.CreateGame(LSettings, LDevice, LClock, LEvents);
  LExporter := TXcomComposition.CreateImageExporter;
  LRunner := TXcomShotRunner.Create(LGame, LClock, LEvents, LDevice, LExporter);
  try
    if AArguments.Script <> '' then
      LRunner.Run(AArguments.Script.Split([';']))
    else
      LRunner.Wait(AArguments.Milliseconds);
    if AArguments.ShotFile <> '' then
      LRunner.Shot(AArguments.ShotFile);
  finally
    LRunner.Free;
    LExporter.Free;
    LGame.Free;
  end;
end;

/// <summary>The export mode: a data file of the game as a PNG, no window and no game</summary>
procedure RunExport(const AArguments: TXcomExportArguments);
var
  LTool: TXcomExportTool;
begin
  LTool := TXcomExportTool.Create(
    procedure(AText: string)
    begin
      Say(AText);
    end, ExtractFilePath(ParamStr(0)));
  try
    LTool.Run(AArguments);
  finally
    LTool.Free;
  end;
end;

var
  LArguments: TArguments;
  LExportArguments: TXcomExportArguments;
  LExport: Boolean;

begin
  LExport := False;
  try
    // -pck, -dat, -scr or -map choose the export; there -data is a folder of the game (TXcomExportArguments)
    LExport := TXcomExportArguments.IsExport(CommandLineArguments);
    if LExport then
    begin
      if TXcomExportArguments.TryParse(CommandLineArguments, LExportArguments) then
        RunExport(LExportArguments)
      else
      begin
        ShowUsage;
        System.ExitCode := 2;
      end;
      Exit;
    end;
    if not ParseArguments(LArguments) then
    begin
      ShowUsage;
      System.ExitCode := 2;
      Exit;
    end;
    if (LArguments.ShotFile <> '') or (LArguments.Script <> '') then
      RunShot(LArguments)
    else
      RunWindow(LArguments);
  except
    on E: Exception do
    begin
      Say(E.ClassName + ': ' + E.Message, True);
      // the address in the terms of the .map of the executable (the image can be relocated)
      if ExceptAddr <> nil then
        Say('map address: ' + IntToHex(NativeUInt(ExceptAddr) - NativeUInt(HInstance) + $400000, 8), True);
      // in the window mode nobody reads the standard error: the player must see why the game closed
      if not LExport and (LArguments.ShotFile = '') and (LArguments.Script = '') then
        MessageBox(0, PChar(E.ClassName + ': ' + E.Message), 'OpenXcom', MB_OK or MB_ICONERROR);
      System.ExitCode := 1;
    end;
  end;
end.

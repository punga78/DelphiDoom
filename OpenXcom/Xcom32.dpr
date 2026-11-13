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
{           [-fonts <file>] [-modfolder <folder>]... [-fontgrid <folder>]      }
{           [-truecolor]                                                       }
{                                                                              }
{  -fonts: the fonts of Windows that replace the pictures of the characters     }
{  (default: fonts.cfg of the user folder; see Libs\XcomSurface\CLAUDE.md).     }
{  -modfolder: a folder laid over the data (a Language\Font.dat of its own).    }
{  -fontgrid: no game; writes those fonts as the pictures and the Font.dat of   }
{  a mod in <folder>\Language (to load with -modfolder <folder>)                }
{                                                                              }
{  -truecolor (or "trueColor: true" in options.cfg; issue 183): the game stays   }
{  at 8 bits and the screen composes the final frame in true color; a shot is   }
{  then an RGB picture. Without it the 8 bit path of OpenXcom, unchanged        }
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
  System.SysUtils, System.Classes, System.IOUtils,
  DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Game,
  DelphiDoom.XcomEngine.DiskFileSystem,
  DelphiDoom.XcomEngine.ErrorLog,
  DelphiDoom.XcomEngine.ErrorLog.Types,
  DelphiDoom.XcomEngine.QueueEventSource,
  DelphiDoom.XcomEngine.MemoryVideoDevice,
  DelphiDoom.XcomEngine.MemoryTrueColorVideoDevice,
  DelphiDoom.XcomEngine.TrueColor.Intf,
  DelphiDoom.XcomEngine.Screen,
  DelphiDoom.Png.Provider,
  DelphiDoom.Platform.Factory,
  DelphiDoom.Xcom.ImageExporter,
  DelphiDoom.Xcom.Composition in 'DelphiDoom.Xcom.Composition.pas',
  DelphiDoom.Xcom.ExportArguments in 'DelphiDoom.Xcom.ExportArguments.pas',
  DelphiDoom.Xcom.ExportTool in 'DelphiDoom.Xcom.ExportTool.pas',
  DelphiDoom.Xcom.GameComposition in 'DelphiDoom.Xcom.GameComposition.pas',
  DelphiDoom.Xcom.ShotRunner in 'DelphiDoom.Xcom.ShotRunner.pas',
  DelphiDoom.Xcom.TrueColorShot in 'DelphiDoom.Xcom.TrueColorShot.pas',
  DelphiDoom.Xcom.TrueColorOption in 'DelphiDoom.Xcom.TrueColorOption.pas',
  DelphiDoom.Xcom.StackScan in 'DelphiDoom.Xcom.StackScan.pas',
  DelphiDoom.Xcom.MemoryCount in 'DelphiDoom.Xcom.MemoryCount.pas',
  DelphiDoom.Xcom.ScriptPcmOutput in 'DelphiDoom.Xcom.ScriptPcmOutput.pas',
  DelphiDoom.Xcom.LoggingBattleAudio in 'DelphiDoom.Xcom.LoggingBattleAudio.pas',
  DelphiDoom.Xcom.DelegateLog in 'DelphiDoom.Xcom.DelegateLog.pas',
  DelphiDoom.Xcom.HostLog in 'DelphiDoom.Xcom.HostLog.pas',
  DelphiDoom.Xcom.HostShaderLoader in 'DelphiDoom.Xcom.HostShaderLoader.pas',
  DelphiDoom.Xcom.HostVideoDevice in 'DelphiDoom.Xcom.HostVideoDevice.pas',
  DelphiDoom.Xcom.HostEventSink in 'DelphiDoom.Xcom.HostEventSink.pas',
  DelphiDoom.GameHost.Factory,
  DelphiDoom.GameHost.Win.Window,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Clock.Factory,
  DelphiDoom.Clock.ManualClock,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.CommandLine.ProgramFactory,
  DelphiDoom.Xcom.Win.DisplayModes in 'DelphiDoom.Xcom.Win.DisplayModes.pas',
  DelphiDoom.Xcom.Win.FolderOpener in 'DelphiDoom.Xcom.Win.FolderOpener.pas',
  DelphiDoom.Xcom.Win.GdiGlyphRasterizer in 'DelphiDoom.Xcom.Win.GdiGlyphRasterizer.pas',
  DelphiDoom.Xcom.Win.GdiGlyphRasterizerFactory in 'DelphiDoom.Xcom.Win.GdiGlyphRasterizerFactory.pas',
  DelphiDoom.Xcom.Win.GdiSystemFonts in 'DelphiDoom.Xcom.Win.GdiSystemFonts.pas',
  DelphiDoom.Xcom.HostPcmOutput in 'DelphiDoom.Xcom.HostPcmOutput.pas',
  DelphiDoom.GameHost.Audio.Intf,
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
    /// <summary>
    ///   With -script: the file that gets a line for every sound of the battle ("ms play depth sound angle") and,
    ///   at the end, what the mixer rendered (the sounds go through the mixer, on an output without a device)
    /// </summary>
    SoundLog: string;
    /// <summary>-memstats: the memory still allocated after the game of a script was freed (to find leaks)</summary>
    MemoryStatistics: Boolean;
    /// <summary>-fontgrid: no game; the fonts of the options are written in this folder as pictures and a Font.dat</summary>
    FontGridFolder: string;
    /// <summary>-optionslog: every read and write of options.cfg is added to options.log of the user folder</summary>
    OptionsLog: Boolean;
    /// <summary>-saveoptions: a -script or -shot run writes the options when it ends, as the game does when it closes</summary>
    SaveOptions: Boolean;
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

var
  /// <summary>The error that reached the main loop is already in xcom_errors.log (written where the game was alive)</summary>
  GErrorLogged: Boolean = False;

/// <summary>
/// Adds the error to xcom_errors.log of the user folder (issue 187), besides the message box. Called inside the
/// except block, where the address of the exception and the callers are still known. Never raises.
/// </summary>
procedure LogError(E: Exception; const AStates: TArray<string>; const AUserFolder, AVersion: string);
var
  LEntry: TXcomErrorEntry;
  LLog: TXcomErrorLog;
begin
  GErrorLogged := True;
  if AUserFolder = '' then
    Exit;
  try
    LEntry.ExceptionClass := E.ClassName;
    LEntry.ExceptionMessage := E.Message;
    LEntry.MapAddress := '';
    if ExceptAddr <> nil then
      LEntry.MapAddress := IntToHex(NativeUInt(ExceptAddr) - NativeUInt(HInstance) + $400000, 8);
    LEntry.CallStack := TXcomStackScan.MapAddresses(E);
    LEntry.States := AStates;
    LEntry.Version := AVersion;
    ForceDirectories(AUserFolder);
    LLog := TXcomErrorLog.Create(TXcomDiskFileSystem.Create, TPath.Combine(AUserFolder, 'xcom_errors.log'),
      function: string
      begin
        Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
      end);
    try
      if not LLog.Write(LEntry) then
        Say('error log not written: ' + LLog.LastError, True);
    finally
      LLog.Free;
    end;
  except
    // the file of errors must never hide the error that is being reported
    on EWrite: Exception do
      Say('error log not written: ' + EWrite.Message, True);
  end;
end;

procedure ShowUsage;
begin
  Say('Xcom32 [-data <common+standard folder>] [-game <game folder>] [-user <folder>] [-mod xcom2]      (the game)');
  Say('  without -data and -game: common + standard and TFTD (or UFO) next to the executable');
  Say('         [-shot <file.png> [-ms <n>]] [-script wait:ms;click:x,y;key:n;shot:file;...]');
  Say('         [-scriptfile <file with a step per line>]   (also trace:1, state:label, until:Name,ms, on:Name=step+step)');
  Say('         [-seed <n>] [-quitafter <ms>] [-audiostats] [-memstats] [-leaks] [-listmodes]');
  Say('         [-version <text>] [-dospath <text>] [-hold]');
  Say('         [-fonts <fonts.cfg: fonts of Windows in place of the pictures>] [-modfolder <folder over the data>]...');
  Say('         [-fontgrid <folder>]   (no game: the fonts of fonts.cfg as pictures and a Font.dat in <folder>\Language)');
  Say('         [-truecolor]   (the final frame composed in true color; default: the 8 bit path)');
  Say('         [-optionslog]   (every read and write of options.cfg, who asked and which keys change: <user>\options.log)');
  Say('         [-saveoptions]   (with -script or -shot: the options are written when the script ends)');
  TXcomExportTool.ShowUsage(
    procedure(AText: string)
    begin
      Say(AText);
    end);
end;

/// <summary>The arguments of the program, without its name</summary>
function ArgumentsOf(const ACommandLine: ICommandLine): TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, ACommandLine.Count - 1);
  for LIndex := 1 to ACommandLine.Count - 1 do
    Result[LIndex - 1] := ACommandLine[LIndex];
end;

/// <summary>
/// Without -data and -game, looks next to the executable: the data folder is the one that has common\ and
/// standard\ (the executable folder or its data\ subfolder), the game folder is TFTD\, UFO\ or the executable
/// folder itself when it has GEODATA\.
/// </summary>
procedure ApplyDefaultFolders(const AProgramFile: string; var ASettings: TXcomGameSettings);
var
  LBase: string;

  function Sub(const AName: string): string;
  begin
    Result := LBase + AName;
  end;

begin
  LBase := ExtractFilePath(AProgramFile);
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

function ParseArguments(const ACommandLine: ICommandLine; out AArguments: TArguments): Boolean;
var
  LCursor: ICommandLineCursor;
  LName: string;

  function NextValue: string;
  begin
    // the message and the class the program has always printed for an argument without its value
    if LCursor.Remaining = 0 then
      raise Exception.CreateFmt('%s needs a value', [LName]);
    Result := LCursor.Value;
  end;

begin
  AArguments := Default(TArguments);
  AArguments.Settings.ModId := 'xcom2';
  AArguments.Settings.VersionText := DEFAULT_VERSION;
  AArguments.Settings.LoadMode := lmThread;
  AArguments.Milliseconds := 3000;
  LCursor := TProgramCommandLineFactory.CreateCursor(ACommandLine);
  while LCursor.Next(LName) do
  begin
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
    else if LName = '-scriptfile' then
      AArguments.Script := TXcomShotRunner.ScriptOfFile(NextValue)
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
    else if LName = '-memstats' then
      AArguments.MemoryStatistics := True
    else if LName = '-leaks' then
    begin
      // the report of the memory manager at the end, on the standard error and not in a message box
      ReportMemoryLeaksOnShutdown := True;
      IsConsole := True;
    end
    else if LName = '-soundlog' then
      AArguments.SoundLog := NextValue
    else if LName = '-optionslog' then
      AArguments.OptionsLog := True
    else if LName = '-saveoptions' then
      AArguments.SaveOptions := True
    else if LName = '-truecolor' then
      AArguments.Settings.TrueColor := True
    else if LName = '-fonts' then
      AArguments.Settings.FontsFile := NextValue
    else if LName = '-modfolder' then
      AArguments.Settings.ModFolders := AArguments.Settings.ModFolders + [NextValue]
    else if LName = '-fontgrid' then
      AArguments.FontGridFolder := NextValue
    else if LName = '-hold' then
      AArguments.Settings.LoadMode := lmHeld
    else
      Exit(False);
  end;
  ApplyDefaultFolders(ACommandLine[0], AArguments.Settings);
  Result := (AArguments.Settings.DataFolder <> '') and (AArguments.Settings.GameFolder <> '');
end;

procedure PrintAudio(const AMeter: IXcomMixerMeter; const AOutput: IGameHostPcmOutput);
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
  LWindow: TGameHostWinWindow;
  LDevice: IXcomVideoDevice;
  LGame: TXcomGame;
  LSettings: TXcomGameSettings;
  LOutput: IGameHostPcmOutput;
  LOutputRef: IXcomPcmOutput;
  LMeter: IXcomMixerMeter;
  LClock: IClock;
  LStart: Double;
  LShot: TXcomTrueColorShot;
begin
  LShot := nil;
  LEvents := TXcomQueueEventSource.Create;
  LEventsRef := LEvents;
  // waveOut of Libs\GameHost, which the mixer of the game sees through its adapter
  LOutput := TGameHostFactory.CreatePcmOutput;
  LOutputRef := TXcomHostPcmOutput.Create(LOutput);
  LSettings := AArguments.Settings;
  LSettings.WindowMode := True;
  LSettings.AudioOutput := LOutputRef;
  LSettings.OnAudio := procedure(const AMeter: IXcomMixerMeter)
    begin
      LMeter := AMeter;
    end;
  LGame := nil;
  // the window of Libs\GameHost: its events reach the queue of the game as SDL made them, the cursor is the game's
  LWindow := TGameHostFactory.CreateWindow('OpenXcom ' + AArguments.Settings.VersionText,
    TXcomHostEventSink.Create(LEvents), True);
  try
    // GDI, or OpenGL when the options ask for it: which OpenGL is found, or why it is not used, is said
    LDevice := TXcomGameComposition.CreateWindowDevice(LWindow, LSettings, TXcomDelegateLog.Create(
      procedure(const ALine: string)
      begin
        Say(ALine);
      end));
    // the clock of Libs\Clock, for the game and for the loop
    LClock := TClockFactory.CreateClock(nil);
    LGame := TXcomGameComposition.CreateGame(LSettings, LDevice, LClock, LEvents);
    // the screenshot key (F12 by default): screenNNN.png in the folder of the user, as OpenXcom does
    LShot := TXcomTrueColorShot.Create(TPngProvider.Client, TPlatformFactory.CreateFileStore);
    LGame.OnScreenshot := procedure(AScreen: TXcomScreen)
      var
        LPixels: TXcomTrueColorPixels;
        LWidth: Integer;
        LHeight: Integer;
        LNumber: Integer;
        LName: string;
      begin
        if not AScreen.Snapshot(LPixels, LWidth, LHeight) then
          Exit;
        LNumber := 0;
        repeat
          LName := TPath.Combine(LSettings.UserFolder, Format('screen%.3d.png', [LNumber]));
          Inc(LNumber);
        until not TFile.Exists(LName);
        LShot.Save(LName, LPixels, LWidth, LHeight);
        Say('Screenshot saved: ' + LName);
      end;
    LStart := LClock.Seconds;
    try
      while LWindow.Pump and not LGame.IsQuitting do
      begin
        LGame.RunFrame;
        LClock.Sleep(LGame.FrameDelay);
        if (AArguments.QuitAfter > 0) and ((LClock.Seconds - LStart) * 1000 > AArguments.QuitAfter) then
          Break;
      end;
    except
      on E: Exception do
      begin
        // the file of errors first: the game is alive here (its states are told) and nothing below can lose the entry
        LogError(E, LGame.StateNames, AArguments.Settings.UserFolder, AArguments.Settings.VersionText);
        // an error in a frame: the options the player set are written all the same, and the error goes on to the window
        LGame.SaveOptionsAfterFailure;
        if LGame.OptionsSaveError <> '' then
          Say('options not saved after the error: ' + LGame.OptionsSaveError, True);
        raise;
      end;
    end;
    // Options::save at the end of Game::run: also the size of a window that was resized
    LGame.SaveOptions;
    if AArguments.AudioStatistics and (LMeter <> nil) then
      PrintAudio(LMeter, LOutput);
  finally
    LGame.Free;
    LShot.Free;
    LMeter := nil;
    // the display draws in the window: its last reference goes before the window
    LDevice := nil;
    LWindow.Free;
  end;
end;

procedure RunShot(const AArguments: TArguments);
var
  LClock: TManualClock;
  LClockRef: IClock;
  LEvents: TXcomQueueEventSource;
  LEventsRef: IXcomEventSource;
  LDevice: TXcomMemoryVideoDevice;
  LDeviceRef: IXcomVideoDevice;
  LGame: TXcomGame;
  LRunner: TXcomShotRunner;
  LExporter: TXcomImageExporter;
  LSettings: TXcomGameSettings;
  LOutput: TXcomScriptPcmOutput;
  LOutputRef: IXcomPcmOutput;
  LMeter: IXcomMixerMeter;
  LSounds: TStringList;
  LStatistics: TXcomMixerStatistics;
  LTrueColorShot: TXcomTrueColorShot;
begin
  if AArguments.MemoryStatistics then
    TXcomMemoryCount.Install;
  LOutput := nil;
  LSounds := nil;
  LClock := TManualClock.Create;
  LClockRef := LClock;
  LEvents := TXcomQueueEventSource.Create;
  LEventsRef := LEvents;
  // also a display of colors: the composition chooses the path, the display serves both
  LDevice := TXcomMemoryTrueColorVideoDevice.Create;
  LDeviceRef := LDevice;
  LSettings := AArguments.Settings;
  // the loading must be over when the clock says so: the task runs at once unless -hold asks otherwise
  if LSettings.LoadMode <> lmHeld then
    LSettings.LoadMode := lmImmediate;
  if AArguments.SoundLog <> '' then
  begin
    // the sounds go through the real mixer, on an output that asks the samples as the script time passes
    LSounds := TStringList.Create;
    LOutput := TXcomScriptPcmOutput.Create;
    LOutputRef := LOutput;
    LSettings.AudioOutput := LOutputRef;
    LSettings.OnAudio := procedure(const AMeter: IXcomMixerMeter)
      begin
        LMeter := AMeter;
      end;
    LSettings.BattleSoundLog := procedure(const ALine: string)
      var
        LActive: Integer;
        LStarted: Integer;
      begin
        LActive := 0;
        LStarted := 0;
        if LMeter <> nil then
        begin
          LActive := LMeter.ActiveChannels;
          LStarted := LMeter.Statistics.SoundsStarted;
        end;
        LSounds.Add(Format('%d %s (channels playing %d, sounds started %d)', [LClock.Milliseconds, ALine, LActive,
          LStarted]));
      end;
  end;
  LGame := TXcomGameComposition.CreateGame(LSettings, LDevice, LClockRef, LEvents);
  LExporter := TXcomComposition.CreateImageExporter;
  LRunner := TXcomShotRunner.Create(LGame, LClock, LEvents, LDevice, LExporter);
  LTrueColorShot := TXcomTrueColorShot.Create(TPngProvider.Client, TPlatformFactory.CreateFileStore);
  LRunner.TrueColorSaver := procedure(const AFileName: string; const APixels: TXcomTrueColorPixels; AWidth,
      AHeight: Integer)
    begin
      LTrueColorShot.Save(AFileName, APixels, AWidth, AHeight);
    end;
  LRunner.OnSay := procedure(ALine: string)
    begin
      Say(ALine);
    end;
  if Assigned(LOutput) then
    LRunner.OnTick := procedure
      begin
        LOutput.Pull(1);
      end;
  try
    if AArguments.Script <> '' then
      LRunner.Run(AArguments.Script.Split([';']))
    else
      LRunner.Wait(AArguments.Milliseconds);
    if AArguments.ShotFile <> '' then
      LRunner.Shot(AArguments.ShotFile);
    if AArguments.SaveOptions then
      LGame.SaveOptions;
    if Assigned(LSounds) then
    begin
      if LMeter <> nil then
      begin
        LStatistics := LMeter.Statistics;
        LSounds.Add(Format('mixer: %d bytes rendered, rms %.1f, peak %d, sounds started %d',
          [LStatistics.RenderedBytes, LStatistics.Rms, LStatistics.Peak, LStatistics.SoundsStarted],
          TFormatSettings.Invariant));
      end
      else
        LSounds.Add('mixer: none');
      LSounds.SaveToFile(AArguments.SoundLog);
    end;
  finally
    LRunner.Free;
    LTrueColorShot.Free;
    LExporter.Free;
    LGame.Free;
    LMeter := nil;
    LSounds.Free;
    // compared between two scripts, what is left is what leaked (the program keeps a few blocks for itself)
    if AArguments.MemoryStatistics then
      Say(Format('memory: %d blocks still allocated after the game was freed', [TXcomMemoryCount.Blocks]));
  end;
end;

/// <summary>The export mode: a data file of the game as a PNG, no window and no game</summary>
procedure RunExport(const AProgramFile: string; const AArguments: TXcomExportArguments);
var
  LTool: TXcomExportTool;
begin
  LTool := TXcomExportTool.Create(
    procedure(AText: string)
    begin
      Say(AText);
    end, ExtractFilePath(AProgramFile));
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
  LCommandLine: ICommandLine;

begin
  LExport := False;
  TXcomStackScan.Install;
  try
    // the arguments as they were written: -version is drawn in the menu, -script names states and files
    LCommandLine := TProgramCommandLineFactory.CreateProcessCommandLine;
    // -pck, -dat, -scr or -map choose the export; there -data is a folder of the game (TXcomExportArguments)
    LExport := TXcomExportArguments.IsExport(ArgumentsOf(LCommandLine));
    if LExport then
    begin
      if TXcomExportArguments.TryParse(ArgumentsOf(LCommandLine), LExportArguments) then
        RunExport(LCommandLine[0], LExportArguments)
      else
      begin
        ShowUsage;
        System.ExitCode := 2;
      end;
      Exit;
    end;
    if not ParseArguments(LCommandLine, LArguments) then
    begin
      ShowUsage;
      System.ExitCode := 2;
      Exit;
    end;
    // what the start has to say (a font of the options that is not used) goes to the standard output
    LArguments.Settings.Log := TXcomDelegateLog.Create(
      procedure(const ALine: string)
      begin
        Say(ALine);
      end);
    if LArguments.OptionsLog then
      LArguments.Settings.OptionsLog := TXcomDelegateLog.Create(
        procedure(const ALine: string)
        begin
          ForceDirectories(LArguments.Settings.UserFolder);
          TFile.AppendAllText(TPath.Combine(LArguments.Settings.UserFolder, 'options.log'), ALine + sLineBreak,
            TEncoding.UTF8);
        end);
    if LArguments.FontGridFolder <> '' then
    begin
      Say(Format('fontgrid: %d pictures and Font.dat written in %s\Language', [
        TXcomGameComposition.GenerateFontGrids(LArguments.Settings, LArguments.FontGridFolder),
        LArguments.FontGridFolder]));
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
      // the callers, nearest first (return addresses found on the stack when the exception was raised)
      if TXcomStackScan.MapAddresses(E) <> '' then
        Say('stack: ' + TXcomStackScan.MapAddresses(E), True);
      // every error of the program is also in xcom_errors.log (the one of the game loop is there already)
      if not LExport and not GErrorLogged then
        LogError(E, nil, LArguments.Settings.UserFolder, LArguments.Settings.VersionText);
      // in the window mode nobody reads the standard error: the player must see why the game closed
      if not LExport and (LArguments.ShotFile = '') and (LArguments.Script = '') then
        MessageBox(0, PChar(E.ClassName + ': ' + E.Message), 'OpenXcom', MB_OK or MB_ICONERROR);
      System.ExitCode := 1;
    end;
  end;
end.

{******************************************************************************}
{                                                                              }
{  XcomGame: the menus of OpenXcom (UFO: Enemy Unknown and Terror from the      }
{  Deep), without SDL. The start screen, the main menu and the options of the   }
{  original, on the data of an installed game; with a window of Windows (GDI)   }
{  or, with -shot, without one and saving screenshots (issue 176)               }
{                                                                              }
{  Usage:  XcomGame -data <folder with common\ and standard\>                   }
{                   -game <folder of the game: GEODATA, GEOGRAPH...>            }
{                  [-user <folder with options.cfg>] [-mod xcom2|xcom1]         }
{                  [-shot <file.png> [-ms <n>] [-script step;step...]]          }
{                  [-version <text>] [-dospath <text>] [-hold]                  }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this program                   }
{                                                                              }
{******************************************************************************}
program XcomGame;

{$APPTYPE CONSOLE}

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
  DelphiDoom.Xcom.GameComposition in 'DelphiDoom.Xcom.GameComposition.pas',
  DelphiDoom.Xcom.ShotRunner in 'DelphiDoom.Xcom.ShotRunner.pas',
  DelphiDoom.Xcom.Win.VideoDevice in 'DelphiDoom.Xcom.Win.VideoDevice.pas',
  DelphiDoom.Xcom.Win.Clock in 'DelphiDoom.Xcom.Win.Clock.pas',
  DelphiDoom.Xcom.Win.DisplayModes in 'DelphiDoom.Xcom.Win.DisplayModes.pas';

const
  DEFAULT_VERSION = '1.0 git 2026-06-05 22:05';

type
  TArguments = record
    Settings: TXcomGameSettings;
    ShotFile: string;
    Milliseconds: Integer;
    Script: string;
  end;

procedure ShowUsage;
begin
  Writeln('XcomGame -data <common+standard folder> -game <game folder> [-user <folder>] [-mod xcom2]');
  Writeln('         [-shot <file.png> [-ms <n>] [-script wait:ms;click:x,y;key:n;shot:file;...]]');
  Writeln('         [-version <text>] [-dospath <text>] [-hold]');
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
  Result := True;
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
    else if LName = '-hold' then
      AArguments.Settings.LoadMode := lmHeld
    else
      Exit(False);
    Inc(LIndex);
  end;
  Result := (AArguments.Settings.DataFolder <> '') and (AArguments.Settings.GameFolder <> '');
end;

procedure RunWindow(const ASettings: TXcomGameSettings);
var
  LEvents: TXcomQueueEventSource;
  LEventsRef: IXcomEventSource;
  LDevice: TXcomWinVideoDevice;
  LDeviceRef: IXcomVideoDevice;
  LGame: TXcomGame;
begin
  LEvents := TXcomQueueEventSource.Create;
  LEventsRef := LEvents;
  LDevice := TXcomWinVideoDevice.Create('OpenXcom ' + ASettings.VersionText, LEvents);
  LDeviceRef := LDevice;
  LGame := TXcomGameComposition.CreateGame(ASettings, LDevice, TXcomWinClock.Create, LEvents);
  try
    while LDevice.Pump and not LGame.IsQuitting do
    begin
      LGame.RunFrame;
      Sleep(1);
    end;
  finally
    LGame.Free;
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

var
  LArguments: TArguments;

begin
  try
    if not ParseArguments(LArguments) then
    begin
      ShowUsage;
      System.ExitCode := 2;
      Exit;
    end;
    if (LArguments.ShotFile <> '') or (LArguments.Script <> '') then
      RunShot(LArguments)
    else
      RunWindow(LArguments.Settings);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.

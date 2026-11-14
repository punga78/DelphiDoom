{******************************************************************************}
{                                                                              }
{  Keen32: Commander Keen in Keen Dreams, port of the source code of           }
{  id Software (1991) to Delphi. Without arguments it is the game, in a window: }
{  the start screens, the control panel, the levels. With -list, -map, -view or  }
{  -png it writes the maps of the game as text or as PNG pictures and stops;    }
{  with -sound it plays a sound effect and writes what the mixer did; with      }
{  -script the game runs without a window, driven by a file of keys             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program Keen32;

{$APPTYPE CONSOLE}

{$R 'Keen32_Icon.res' 'Keen32_Icon.rc'}

uses
  System.SysUtils,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.CommandLine.ProgramFactory,
  DelphiDoom.Keen.Types in '..\Libs\Keen\DelphiDoom.Keen.Types.pas',
  DelphiDoom.Keen.GameTypes in '..\Libs\Keen\DelphiDoom.Keen.GameTypes.pas',
  DelphiDoom.Keen.Intf in '..\Libs\Keen\DelphiDoom.Keen.Intf.pas',
  DelphiDoom.Keen.HostAudio in 'DelphiDoom.Keen.HostAudio.pas',
  DelphiDoom.Keen.HostClock in 'DelphiDoom.Keen.HostClock.pas',
  DelphiDoom.Keen.HostEvents in 'DelphiDoom.Keen.HostEvents.pas',
  DelphiDoom.Keen.GameRunner in 'DelphiDoom.Keen.GameRunner.pas',
  DelphiDoom.Keen.Composition in 'DelphiDoom.Keen.Composition.pas';

procedure ShowUsage;
begin
  Writeln('Keen32 [-data <folder>]... [-map <number>] [-png <file>] [-list] [-view <tile x> <tile y>]');
  Writeln('  -view   the screen of the game (320x200, the video manager and the refresh manager) with the origin at a tile');
  Writeln('  -data   a folder with KDREAMS.EGA, KDREAMS.MAP, KDREAMS.AUD and the .KDR headers (default: the current one)');
  Writeln('  -map    the map to draw (default 0)');
  Writeln('  -png    the file to write (default keen_map<number>.png)');
  Writeln('  -list   write the maps of the game and stop');
  Writeln('  -sound  play a sound effect (0..27) and write what the mixer did; -pcspeaker for the PC speaker instead of');
  Writeln('          the AdLib card, -nodevice to leave the sound output of the machine closed');
  Writeln('Without -list, -map, -png, -view and -sound the game starts (the data next to the program if no -data):');
  Writeln('  -scale <n>       the size of a pixel in the window (default 3)');
  Writeln('  -save <folder>   where KDREAMS.CFG and the saved games go (default: the first data folder)');
  Writeln('  -nodevice        no sound device');
  Writeln('  -comp            the compatibility mode of the original for the scrolling');
  Writeln('  -warp <level>    start a game at a level (0 is the world map)');
  Writeln('  -quitafter <s>   close the window after some seconds');
  Writeln('  -script <file>   no window: the keys and the pictures of a script, a tic of the game for each wait');
  Writeln('  -shots <folder>  where the pictures of the script go');
  Writeln('  -report          write the state of the game and of the mixer at the end');
end;

var
  LFolders: TArray<string>;
  LMapNumber: Integer;
  LPng: string;
  LList: Boolean;
  LView: Boolean;
  LViewX: Integer;
  LViewY: Integer;
  LArgument: string;
  LCursor: ICommandLineCursor;
  LData: IKeenGameData;
  LMap: IKeenMap;
  LNumber: Integer;
  LSound: Integer;
  LSoundMode: TKeenSoundMode;
  LUseDevice: Boolean;
  LExport: Boolean;
  LOptions: TKeenRunOptions;
  LProgramFolder: string;

begin
{$IFDEF DEBUG}
  // a debug build says what it did not free when it ends
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  try
    LMapNumber := 0;
    LPng := '';
    LList := False;
    LView := False;
    LViewX := 0;
    LViewY := 0;
    LSound := -1;
    LSoundMode := ksmAdLib;
    LUseDevice := True;
    LExport := False;
    LOptions := TKeenRunOptions.Defaults;
    LCursor := TProgramCommandLineFactory.CreateCursor(TProgramCommandLineFactory.CreateProcessCommandLine);
    while LCursor.Next(LArgument) do
    begin
      if (LArgument = '-data') and (LCursor.Remaining >= 1) then
      begin
        SetLength(LFolders, Length(LFolders) + 1);
        LFolders[High(LFolders)] := LCursor.Value;
      end
      else if (LArgument = '-map') and (LCursor.Remaining >= 1) then
      begin
        LMapNumber := StrToInt(LCursor.Value);
        LExport := True;
      end
      else if (LArgument = '-png') and (LCursor.Remaining >= 1) then
      begin
        LPng := LCursor.Value;
        LExport := True;
      end
      else if (LArgument = '-view') and (LCursor.Remaining >= 2) then
      begin
        // the screen of the game with the origin at a tile of the map
        LView := True;
        LViewX := StrToInt(LCursor.Value) * 256;
        LViewY := StrToInt(LCursor.Value) * 256;
        LExport := True;
      end
      else if (LArgument = '-sound') and (LCursor.Remaining >= 1) then
        LSound := StrToInt(LCursor.Value)
      else if LArgument = '-pcspeaker' then
        LSoundMode := ksmPC
      else if LArgument = '-nodevice' then
      begin
        LUseDevice := False;
        LOptions.UseSoundDevice := False;
      end
      else if LArgument = '-list' then
      begin
        LList := True;
        LExport := True;
      end
      else if (LArgument = '-scale') and (LCursor.Remaining >= 1) then
        LOptions.Scale := StrToInt(LCursor.Value)
      else if (LArgument = '-save') and (LCursor.Remaining >= 1) then
        LOptions.SaveFolder := LCursor.Value
      else if LArgument = '-comp' then
        LOptions.Compatibility := True
      else if (LArgument = '-warp') and (LCursor.Remaining >= 1) then
        LOptions.StartLevel := StrToInt(LCursor.Value)
      else if (LArgument = '-quitafter') and (LCursor.Remaining >= 1) then
        LOptions.QuitAfterSeconds := StrToFloat(LCursor.Value, TFormatSettings.Invariant)
      else if (LArgument = '-script') and (LCursor.Remaining >= 1) then
        LOptions.ScriptFile := LCursor.Value
      else if (LArgument = '-shots') and (LCursor.Remaining >= 1) then
        LOptions.ShotFolder := LCursor.Value
      else if LArgument = '-report' then
        LOptions.Report := True
      else
      begin
        ShowUsage;
        System.ExitCode := 2;
        Exit;
      end;
    end;
    if (not LExport) and (LSound < 0) then
    begin
      // the game: the data next to the program when no folder is given, as the original has them
      if Length(LFolders) = 0 then
      begin
        LProgramFolder := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
        if FileExists(LProgramFolder + PathDelim + 'KDREAMS.EGA') then
          LFolders := [LProgramFolder]
        else
          LFolders := [GetCurrentDir];
      end;
      LOptions.Folders := LFolders;
      System.ExitCode := TKeenGameRunner.Run(LOptions);
      Exit;
    end;
    if Length(LFolders) = 0 then
      LFolders := [GetCurrentDir];
    if LPng = '' then
      LPng := Format('keen_map%d.png', [LMapNumber]);

    LData := TKeenComposition.OpenGameData(LFolders);
    if LList then
    begin
      for LNumber in LData.Maps.MapNumbers do
      begin
        LMap := LData.Maps.LoadMap(LNumber);
        Writeln(Format('%2d  %-18s %3d x %3d', [LNumber, LMap.Name, LMap.Width, LMap.Height]));
      end;
      Exit;
    end;
    if LSound >= 0 then
    begin
      Writeln(TKeenComposition.PlaySoundReport(LData, LSound, LSoundMode, LUseDevice));
      Exit;
    end;
    if LView then
    begin
      TKeenComposition.CreateViewExporter(LData).SaveViewPicture(LMapNumber, LViewX, LViewY, [], LPng);
      Writeln('View of the map ', LMapNumber, ' saved in ', LPng);
      Exit;
    end;
    TKeenComposition.CreateMapExporter(LData).SaveMapPicture(LMapNumber, LPng);
    Writeln('Map ', LMapNumber, ' saved in ', LPng);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.

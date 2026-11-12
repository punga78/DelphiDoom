{******************************************************************************}
{                                                                              }
{  Greed32: In Pursuit of Greed (Raven 3D engine, Softdisk 1996), the source    }
{  port xGreed of Jim Valavanis in the class system of DelphiDoom. It opens     }
{  GREED.BLO, saves a map or an image as a PNG, or plays a map with the game    }
{  of Libs\Greed (issue 175): the level with its monsters, items, doors,        }
{  elevators, scripts, weapons and sounds; no status bar and no menus yet       }
{                                                                              }
{  Usage:  Greed32 [-data <folder>]... [-list] [-map <number>] [-lump <name>]   }
{                  [-png <file>] [-play <number> ...]                           }
{          the folders hold GREED.BLO and, for the demos, the LEVEL*.LAY files  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program Greed32;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.IOUtils,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.CommandLine.ProgramFactory,
  DelphiDoom.Greed.Types in '..\Libs\Greed\DelphiDoom.Greed.Types.pas',
  DelphiDoom.Greed.Intf in '..\Libs\Greed\DelphiDoom.Greed.Intf.pas',
  DelphiDoom.Greed.Composition in 'DelphiDoom.Greed.Composition.pas';

procedure ShowUsage;
begin
  Writeln('Greed32                  with no arguments: the game, from its menu, with GREED.BLO next to the program');
  Writeln('Greed32 [-data <folder>]... [-list] [-map <number>] [-lump <name or number>] [-png <file>]');
  Writeln('  the game (none of -list, -map, -lump, -play): the titles, the menu, the briefings, the game, the endings;');
  Writeln('          xGreed.ini and the saved games are in the folder DATA next to the program');
  Writeln('  -skipintro  the game starts at once on the first map (with -play N on the map N), without titles and menu;');
  Writeln('          with -script the keys go to the menus and to the game alike (see -script below)');
  Writeln('  -nobriefing  no screens before a map');
  Writeln('  -game1, -game2, -game3  the game (episode) of the full data');
  Writeln('  -shotat  with -shot: the tics at which a picture is saved, as a list 100,300 (file_100.png ...)');
  Writeln('  -data   a folder with GREED.BLO (and the LEVEL*.LAY maps of the demos); default the current one');
  Writeln('  -list   write the lumps of the archive with their kind and stop');
  Writeln('  -map    the map to draw as a PNG (the first is 0)');
  Writeln('  -lump   a picture, flat, wall or sprite to save as a PNG, by name or by number');
  Writeln('  -png    the file to write (default greed_map<number>.png or greed_<lump>.png)');
  Writeln('  -play   opens a window and plays the map (the first is 0) with the keys of the original: arrows to');
  Writeln('          walk and turn, Ctrl fires, Space uses, Alt strafes, Shift runs, Z jumps, 1..5 the weapons,');
  Writeln('          X uses the item of the inventory (Insert and Delete choose it), Escape quits');
  Writeln('  -character, -difficulty  with -play: the character (0..5) and the difficulty of the new player');
  Writeln('  -seed   with -play: where the game starts in its table of random numbers');
  Writeln('  -ticks  with -play: stops after that number of tics (70 a second)');
  Writeln('  -autoplay  with -play: the player walks, turns, uses and shoots by itself');
  Writeln('  -script with the game (no -play): a file of keys for the menus and the game, a line "tic key down|up" where the');
  Writeln('          tic is the one of the program (the first is 1, 70 a second, every screen counts) and the key is up, down,');
  Writeln('          left, right, enter, esc, backspace, space, a letter or a digit (the keys of the menus) or one of the');
  Writeln('          commands below (the keys of the game); "tic type TEXT" types a secret code. The same keys with -dump');
  Writeln('          show where the program is (application.mode, screens.menu.level and cursor, ...)');
  Writeln('  -script with -play: a file of commands, a line "tic command down|up" or "tic type TEXT" each');
  Writeln('          (the commands: north east south west fire strafe use run jump useitem lookup lookdown');
  Writeln('          centerview slideleft slideright inventoryleft inventoryright weapon1..weapon5 mapmode');
  Writeln('          heatmode goalitem menu ...; space is use and restart, shift run, alt strafe)');
  Writeln('  -headless  with -play: no window, no sound device and no clock: as fast as the machine goes, and');
  Writeln('          the same options always give the same game');
  Writeln('  -lowres    with -play: the view is 320 x 200 instead of 640 x 400');
  Writeln('  -topdown   with -play: the view from above instead of the first person view');
  Writeln('  -musicvol, -sfxvol  with -play: the volumes of the music and of the effects, 0..255');
  Writeln('  -audiostats  with -play: writes at the end what the mixer of the sound did');
  Writeln('  -messages  with -play: writes the messages of the game on the console');
  Writeln('  -shot   with -play: saves the last picture as a PNG');
  Writeln('  -dump   with -play: writes the state of the game at the end in a text file');
end;

const
  KIND_NAMES: array[TGreedLumpKind] of string = ('', 'palette', 'picture', 'flat', 'wall', 'sprite');

var
  LFolders: TArray<string>;
  LMapNumber: Integer;
  LLump: string;
  LPng: string;
  LList: Boolean;
  LArgument: string;
  LCursor: ICommandLineCursor;
  LArchive: IGreedArchive;
  LClassifier: IGreedLumpClassifier;
  LNumber: Integer;
  LLumpIndex: Integer;
  LPlay: TGreedPlayOptions;
  LPlayed: Integer;
  LProgram: Boolean;
  LText: string;

begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  try
    LPlay := TGreedPlayOptions.Standard;
    LPlay.MapNumber := -1;
    LMapNumber := -1;
    LLump := '';
    LPng := '';
    LList := False;
    LCursor := TProgramCommandLineFactory.CreateCursor(TProgramCommandLineFactory.CreateProcessCommandLine);
    while LCursor.Next(LArgument) do
    begin
      if (LArgument = '-data') and (LCursor.Remaining >= 1) then
      begin
        SetLength(LFolders, Length(LFolders) + 1);
        LFolders[High(LFolders)] := LCursor.Value;
      end
      else if (LArgument = '-map') and (LCursor.Remaining >= 1) then
        LMapNumber := StrToInt(LCursor.Value)
      else if (LArgument = '-lump') and (LCursor.Remaining >= 1) then
        LLump := LCursor.Value
      else if (LArgument = '-png') and (LCursor.Remaining >= 1) then
        LPng := LCursor.Value
      else if (LArgument = '-play') and (LCursor.Remaining >= 1) then
        LPlay.MapNumber := StrToInt(LCursor.Value)
      else if (LArgument = '-ticks') and (LCursor.Remaining >= 1) then
        LPlay.MaxTics := StrToInt(LCursor.Value)
      else if (LArgument = '-character') and (LCursor.Remaining >= 1) then
        LPlay.Character := StrToInt(LCursor.Value)
      else if (LArgument = '-difficulty') and (LCursor.Remaining >= 1) then
        LPlay.Difficulty := StrToInt(LCursor.Value)
      else if (LArgument = '-seed') and (LCursor.Remaining >= 1) then
        LPlay.Seed := StrToInt(LCursor.Value)
      else if (LArgument = '-script') and (LCursor.Remaining >= 1) then
        LPlay.ScriptPath := LCursor.Value
      else if (LArgument = '-shot') and (LCursor.Remaining >= 1) then
        LPlay.ShotPath := LCursor.Value
      else if (LArgument = '-dump') and (LCursor.Remaining >= 1) then
        LPlay.DumpPath := LCursor.Value
      else if LArgument = '-autoplay' then
        LPlay.AutoPlay := True
      else if LArgument = '-headless' then
        LPlay.Headless := True
      else if LArgument = '-lowres' then
        LPlay.LowResolution := True
      else if LArgument = '-topdown' then
        LPlay.TopDown := True
      else if (LArgument = '-musicvol') and (LCursor.Remaining >= 1) then
        LPlay.MusicVolume := StrToInt(LCursor.Value)
      else if (LArgument = '-sfxvol') and (LCursor.Remaining >= 1) then
        LPlay.SfxVolume := StrToInt(LCursor.Value)
      else if LArgument = '-audiostats' then
        LPlay.AudioStatistics := True
      else if LArgument = '-messages' then
        LPlay.EchoMessages := True
      else if LArgument = '-list' then
        LList := True
      else if LArgument = '-skipintro' then
        LPlay.SkipIntro := True
      else if LArgument = '-nobriefing' then
        LPlay.NoBriefing := True
      else if LArgument = '-game1' then
        LPlay.Game := 1
      else if LArgument = '-game2' then
        LPlay.Game := 2
      else if LArgument = '-game3' then
        LPlay.Game := 3
      else if (LArgument = '-shotat') and (LCursor.Remaining >= 1) then
      begin
        for LText in LCursor.Value.Split([',']) do
        begin
          SetLength(LPlay.ShotTics, Length(LPlay.ShotTics) + 1);
          LPlay.ShotTics[High(LPlay.ShotTics)] := StrToInt(LText);
        end;
      end
      else
      begin
        ShowUsage;
        System.ExitCode := 2;
        Exit;
      end;
    end;
    // the data are next to the program, or in the current folder
    if Length(LFolders) = 0 then
      LFolders := [ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))), GetCurrentDir];
    LProgram := (not LList) and (LMapNumber < 0) and (LLump = '') and
      ((LPlay.MapNumber < 0) or LPlay.SkipIntro);
    LArchive := TGreedComposition.OpenArchive(LFolders);
    if LProgram then
    begin
      LPlayed := TGreedComposition.RunProgram(LArchive, LFolders,
        TPath.Combine(ExtractFilePath(ParamStr(0)), 'DATA'), LPlay);
      Writeln('Ran ', LPlayed, ' tics');
      Exit;
    end;
    if LPlay.MapNumber >= 0 then
    begin
      LPlayed := TGreedComposition.Play(LArchive, LFolders, LPlay);
      Writeln('Played ', LPlayed, ' tics');
      Exit;
    end;
    if LList then
    begin
      LClassifier := TGreedComposition.CreateClassifier(LArchive);
      for LNumber := 0 to LArchive.LumpCount - 1 do
        Writeln(Format('%4d  %-16s %8d  %s', [LNumber, LArchive.GetLumpName(LNumber), LArchive.GetLumpSize(LNumber),
          KIND_NAMES[LClassifier.Classify(LNumber)]]));
      Exit;
    end;
    if LMapNumber >= 0 then
    begin
      if LPng = '' then
        LPng := Format('greed_map%d.png', [LMapNumber]);
      TGreedComposition.CreateExporter(LArchive, LFolders).SaveMap(LMapNumber, LPng);
      Writeln('Map ', LMapNumber, ' saved in ', LPng);
    end
    else
    begin
      if not TryStrToInt(LLump, LLumpIndex) then
        LLumpIndex := LArchive.RequireIndexOf(LLump);
      if LPng = '' then
        LPng := Format('greed_lump%d.png', [LLumpIndex]);
      TGreedComposition.CreateExporter(LArchive, LFolders).SaveLump(LLumpIndex, LPng);
      Writeln('Lump ', LLumpIndex, ' saved in ', LPng);
    end;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.

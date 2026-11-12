{******************************************************************************}
{                                                                              }
{  Greed32: In Pursuit of Greed (Raven 3D engine, Softdisk 1996), the source    }
{  port xGreed of Jim Valavanis in the class system of DelphiDoom. For now a    }
{  program that opens GREED.BLO and saves a map or an image as a PNG (a proof   }
{  of the data layer, slices G0-G4 of the issue 175): no window, no game yet    }
{                                                                              }
{  Usage:  Greed32 [-data <folder>]... [-list] [-map <number>] [-lump <name>]   }
{                  [-png <file>]                                                }
{          the folders hold GREED.BLO and, for the demos, the LEVEL*.LAY files  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program Greed32;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.CommandLine.ProgramFactory,
  DelphiDoom.Greed.Types in '..\Libs\Greed\DelphiDoom.Greed.Types.pas',
  DelphiDoom.Greed.Intf in '..\Libs\Greed\DelphiDoom.Greed.Intf.pas',
  DelphiDoom.Greed.Composition in 'DelphiDoom.Greed.Composition.pas';

procedure ShowUsage;
begin
  Writeln('Greed32 [-data <folder>]... [-list] [-map <number>] [-lump <name or number>] [-png <file>]');
  Writeln('  -data   a folder with GREED.BLO (and the LEVEL*.LAY maps of the demos); default the current one');
  Writeln('  -list   write the lumps of the archive with their kind and stop');
  Writeln('  -map    the map to draw as a PNG (the first is 0)');
  Writeln('  -lump   a picture, flat, wall or sprite to save as a PNG, by name or by number');
  Writeln('  -png    the file to write (default greed_map<number>.png or greed_<lump>.png)');
  Writeln('  -play   opens a window and plays the map (the first is 0), seen from above: arrows or W S, Q E to turn,');
  Writeln('          A D to step aside, Shift to run, Escape to quit. The first person view; -topdown shows the map from above');
  Writeln('  -ticks  with -play: stops after that number of tics (70 a second)');
  Writeln('  -autoplay  with -play: the player walks by itself');
  Writeln('  -topdown   with -play: the view from above instead of the first person view');
  Writeln('  -musicvol, -sfxvol  with -play: the volumes of the music and of the effects, 0..255');
  Writeln('  -audiostats  with -play: writes at the end what the mixer of the sound did');
  Writeln('  -shot   with -play: saves the last picture as a PNG');
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
  LPlayMap: Integer;
  LTicks: Integer;
  LMusicVolume: Integer;
  LSfxVolume: Integer;
  LAudioStatistics: Boolean;
  LPlayed: Integer;
  LAutoPlay: Boolean;
  LTopDown: Boolean;
  LShot: string;

begin
  try
    LPlayMap := -1;
    LTicks := 0;
    LMusicVolume := -1;
    LSfxVolume := -1;
    LAudioStatistics := False;
    LAutoPlay := False;
    LTopDown := False;
    LShot := '';
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
        LPlayMap := StrToInt(LCursor.Value)
      else if (LArgument = '-ticks') and (LCursor.Remaining >= 1) then
        LTicks := StrToInt(LCursor.Value)
      else if (LArgument = '-shot') and (LCursor.Remaining >= 1) then
        LShot := LCursor.Value
      else if LArgument = '-autoplay' then
        LAutoPlay := True
      else if LArgument = '-topdown' then
        LTopDown := True
      else if LArgument = '-musicvol' then
        LMusicVolume := StrToInt(LCursor.Value)
      else if LArgument = '-sfxvol' then
        LSfxVolume := StrToInt(LCursor.Value)
      else if LArgument = '-audiostats' then
        LAudioStatistics := True
      else if LArgument = '-list' then
        LList := True
      else
      begin
        ShowUsage;
        System.ExitCode := 2;
        Exit;
      end;
    end;
    if Length(LFolders) = 0 then
      LFolders := [GetCurrentDir];
    if (not LList) and (LMapNumber < 0) and (LLump = '') and (LPlayMap < 0) then
    begin
      ShowUsage;
      System.ExitCode := 2;
      Exit;
    end;

    LArchive := TGreedComposition.OpenArchive(LFolders);
    if LPlayMap >= 0 then
    begin
      LPlayed := TGreedComposition.Play(LArchive, LFolders, LPlayMap, LTicks, LAutoPlay, LShot, not LTopDown,
        LMusicVolume, LSfxVolume, LAudioStatistics);
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

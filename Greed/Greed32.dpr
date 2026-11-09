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
  Writeln('          A D to step aside, Shift to run, Escape to quit. The renderer of the game is not ported yet');
  Writeln('  -ticks  with -play: stops after that number of tics (70 a second)');
  Writeln('  -autoplay  with -play: the player walks by itself');
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
  LIndex: Integer;
  LArgument: string;
  LArchive: IGreedArchive;
  LClassifier: IGreedLumpClassifier;
  LNumber: Integer;
  LLumpIndex: Integer;
  LPlayMap: Integer;
  LTicks: Integer;
  LAutoPlay: Boolean;
  LShot: string;

begin
  try
    LPlayMap := -1;
    LTicks := 0;
    LAutoPlay := False;
    LShot := '';
    LMapNumber := -1;
    LLump := '';
    LPng := '';
    LList := False;
    LIndex := 1;
    while LIndex <= ParamCount do
    begin
      LArgument := ParamStr(LIndex).ToLowerInvariant;
      if (LArgument = '-data') and (LIndex < ParamCount) then
      begin
        Inc(LIndex);
        SetLength(LFolders, Length(LFolders) + 1);
        LFolders[High(LFolders)] := ParamStr(LIndex);
      end
      else if (LArgument = '-map') and (LIndex < ParamCount) then
      begin
        Inc(LIndex);
        LMapNumber := StrToInt(ParamStr(LIndex));
      end
      else if (LArgument = '-lump') and (LIndex < ParamCount) then
      begin
        Inc(LIndex);
        LLump := ParamStr(LIndex);
      end
      else if (LArgument = '-png') and (LIndex < ParamCount) then
      begin
        Inc(LIndex);
        LPng := ParamStr(LIndex);
      end
      else if (LArgument = '-play') and (LIndex < ParamCount) then
      begin
        Inc(LIndex);
        LPlayMap := StrToInt(ParamStr(LIndex));
      end
      else if (LArgument = '-ticks') and (LIndex < ParamCount) then
      begin
        Inc(LIndex);
        LTicks := StrToInt(ParamStr(LIndex));
      end
      else if (LArgument = '-shot') and (LIndex < ParamCount) then
      begin
        Inc(LIndex);
        LShot := ParamStr(LIndex);
      end
      else if LArgument = '-autoplay' then
        LAutoPlay := True
      else if LArgument = '-list' then
        LList := True
      else
      begin
        ShowUsage;
        System.ExitCode := 2;
        Exit;
      end;
      Inc(LIndex);
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
      Writeln('Played ', TGreedComposition.Play(LArchive, LFolders, LPlayMap, LTicks, LAutoPlay, LShot), ' tics');
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

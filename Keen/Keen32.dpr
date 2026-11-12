{******************************************************************************}
{                                                                              }
{  Keen32: Commander Keen in Keen Dreams, port of the source code of           }
{  id Software (1991) to Delphi. For now a program that opens the data files    }
{  and saves a map as a PNG (a proof of the data layer, slices K0-K4 of the     }
{  plan of the issue 165): no window, no game yet                               }
{                                                                              }
{  Usage:  Keen32 [-data <folder>]... [-map <number>] [-png <file>] [-list]     }
{          the folders hold KDREAMS.EGA, .MAP, .AUD and the .KDR headers        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program Keen32;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.CommandLine.ProgramFactory,
  DelphiDoom.Keen.Types in '..\Libs\Keen\DelphiDoom.Keen.Types.pas',
  DelphiDoom.Keen.Intf in '..\Libs\Keen\DelphiDoom.Keen.Intf.pas',
  DelphiDoom.Keen.Composition in 'DelphiDoom.Keen.Composition.pas';

procedure ShowUsage;
begin
  Writeln('Keen32 [-data <folder>]... [-map <number>] [-png <file>] [-list] [-view <tile x> <tile y>]');
  Writeln('  -view   the screen of the game (320x200, the video manager and the refresh manager) with the origin at a tile');
  Writeln('  -data   a folder with KDREAMS.EGA, KDREAMS.MAP, KDREAMS.AUD and the .KDR headers (default: the current one)');
  Writeln('  -map    the map to draw (default 0)');
  Writeln('  -png    the file to write (default keen_map<number>.png)');
  Writeln('  -list   write the maps of the game and stop');
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

begin
  try
    LMapNumber := 0;
    LPng := '';
    LList := False;
    LView := False;
    LViewX := 0;
    LViewY := 0;
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
      else if (LArgument = '-png') and (LCursor.Remaining >= 1) then
        LPng := LCursor.Value
      else if (LArgument = '-view') and (LCursor.Remaining >= 2) then
      begin
        // the screen of the game with the origin at a tile of the map
        LView := True;
        LViewX := StrToInt(LCursor.Value) * 256;
        LViewY := StrToInt(LCursor.Value) * 256;
      end
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
